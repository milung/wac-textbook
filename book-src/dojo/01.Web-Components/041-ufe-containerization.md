## Kontajnerizácia aplikácie

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-ufe-041`

---

[Softvérový kontajner][containers] si možno predstaviť aj ako obraz virtuálneho zariadenia, ktorý so sebou prináša všetky knižnice a závislosti potrebné k behu programu bez toho, aby ovplyvňoval alebo bol ovplyvňovaný špecifickými požiadavkami ostatných susbsystémov prítomných na tom istom fyzickom zariadení. Na rozdiel od technológie virtuálnych počítačov ale jednotlivé kontajnery zdieľajú jadro operačného systému, čím sú menej náročné na administráciu a dostupnosť fyzických prostriedkov.

V tomto cvičení budeme používať platformu softvérových kontajnerov [Docker][docker-containers], predpokladom je nainštalovaný systém [Docker Desktop][docker-desktop] na operačnom systéme Windows a Mac, alebo docker balík na systémoch Linux.

>info:> Docker Desktop je od Januára 2022 spoplatnený pre komerčné používanie. Cena je síce prijateľná pre väčšinu komerčných využití, pokiaľ hľadáte voľnú alternatívu, môžete použiť napríklad [Rancher Desktop][rancher-desktop]

Softvérové kontajnery sú vytvárané z ich obrazov, čo je binárna forma reprezentujúca stav operačného systému potrebného pre beh daného programu. Obraz - _image_ -  je možné vytvoriť rôznymi spôsobmi. Najbežnejší spôsob je vytvorenie obrazu kompiláciou súboru nazývaného `Dockerfile`. V tejto sekcii si úkažeme ako sa dá takýto obraz vytvoriť.

1. V adresári `${WAC_ROOT}/ambulance-ufe` vytvorte priečinok `${WAC_ROOT}/ambulance-ufe/build/docker` a v ňom vytvorte súbor s názvom [`Dockerfile`](https://docs.docker.com/engine/reference/builder/) a nasledujúcim obsahom

   ```dockerfile
   ### compilation stage
   FROM node:latest AS build
 
   RUN mkdir /build
   WORKDIR /build
   
   COPY package.json .
   RUN npm install 
 
   COPY . .
   RUN npm run build
 
   ### prepare go embedding of SPA server 
   FROM milung/spa-server as spa-build 

   COPY --from=build /build/www public
   RUN ./build.sh

   ### scratch image - no additional dependencies only server process
   FROM scratch
   ENV CSP_HEADER=false

   COPY --from=spa-build /app/server /server
   CMD ["/server"]
   EXPOSE 8080
   ```

   Tento dockerfile využíva takzvané viacstupňové vytváranie obrazov. Každý stupeň začína príkazom  `FROM <base-image>`. Obraz kontajnera je tvorený vrstvami súborového systému, kde každá nová  vrstva modifikuje obsah predchádzajúcej vrstvy viditeľný z pohľadu bežiaceho programu v takzvanej  _runtime layer_ aktívneho kontajnera. Všetky predchádzajúce vrstvy musia byť dostupné, z čoho  vyplýva, že vymazanie súboru v novej vrstve nezmenšuje konečnú veľkosť obrazu, len mení  viditeľnosť súborov. Z praktického hľadiska možno každý príkaz v súbore `Dockerfile` - napr.  `COPY` alebo `RUN` - považovať za vytvorenie novej vrstvy.

   V našom prípade potrebujeme systém [Node JS][nodejs] len počas kompilácie, k vytvoreniu súborov poskytovaných webovým serverom. Samotný program bude vykonávaný webovým  prehliadačom na prostriedkoch koncového používateľa. Z toho dôvodu je prvý stupeň - identifikovaný  príkazom `FROM node:latest AS build` - takzvaný dočasný obraz, oddelený od druhého stupňa.

   Druhý stupeň - začínajúci príkazom `FROM milung/spa-server` - potom predstavuje ďalší stupeň vytvárania obrazu. V tomto kroku sú statické súbory skopírované do adresára public v pracovnom priečinku kontajnera milung/spa-server a príkaz `build.sh` vykoná kompiláciu predpripraveného programu vytvoreného v jazyku [Golang][go]. Účelom tohto kroku je zminimalizovať výslednú veľkosť cieľového obrazu a množstvo jeho závislostí. Viac informácií o tomto obraze nájdete v repozitári [SirCremefresh/spa-server](https://github.com/SirCremefresh/spa-server). _(Obraz `milung/spa-server` je len multiplatformovou verziou tohto obrazu, ktorý je dostupný aj pre procesory s architektúrou ARM64.)_

   Finálny obraz je založený na takzvanej _scratch_ vrstve, čo je v zásade prázdna vrstva kontajnera. Tým pádom už neobsahuje žiadne ďalšie závislosti, ale len komunikuje s vrstvou hostiteľského počítača. Do tejto vrstvy potom kopírujeme náš výsledný proces, ktorý implementuje HTTP službu upravenú pre potreby _Single Page Application_ funkcionality. V tomto stupni sme použili aj definíciu premennej prostredia `CSP_HEADER` ktorá je implicitne nastavená na hodnotu `false`. Takéto premenné prostredia sú viditeľné v procesoch, ktoré bežia v kontajneri (nie počas vytvárania kontajnera), a ich aktuálnu hodnotu možno upraviť pri vytváraní inštancie príslušného kontajnera z predom vytvoreného obrazu.

   Teoreticky by bolo možné použiť len jediný stupeň vytvárania obrazu, napríklad doplnením príkazu `CMD npm run start` v prvom stupni. Takto vytvorený obraz by bol však zbytočne veľký - obsahoval by celý subsystém [Node.js][nodejs] ako aj všetky závislosti našej aplikácie v priečinku _node_modules_. Viacero stupňov vytvárania výsledného obrazu a kompilácia programu priamo pri jeho vytváraní zabezpečuje prenositeľnosť a reprodukovateľnosť celého procesu.

   Tiež si všimnite, že v prvom kroku kompilácie kopírujeme len súbor `package.json` a vykonávame  príkaz `npm install`, ktorý nainštaluje všetky balíčky potrebné k behu našej aplikácie. Systém  docker pri vytváraní jednotlivých vrstiev porovná hash kód kopírovaných súborov (vrstvy po  aplikovaní príkazu `COPY`) a pokiaľ nedošlo k zmene obsahu, vynechá vytváranie nasledujúcej vrstvy  s príkazom `RUN`. Keďže zmena obsahu súboru `package.json` je zriedkavá v porovnaní s frekvenciou  zmien zdrojových súborov našej aplikácie, je inštalácia balíčkov po prvotnom vytvorení vrstvy len  znovupoužitá, čo skracuje čas kompilácie obrazu pri opakovaných behoch. V zásade sa snažíme radiť  príkazy v súbore `Dockerfile` takým spôsobom, aby sa artefakty s väčšou frekvenciou zmien spracovávali neskôr počas behu kompilácie.

2. Vytvorte nový súbor `${WAC_ROOT}/ambulance-ufe/.dockerignore` s obsahom

   ```plain
   dist
   www
   loader
   node_modules
   ```

    Počas kompilácie súboru `Dockerfile` je do vyrovnávacej pamäte rekurzívne kopírovaný obsah aktuálneho priečinku (priečinku _context_-u). Súbor `.dockerignore` umožňuje  špecifikovať, ktoré súbory alebo priečinky nie sú pre kompiláciu potrebné, čo  najmä v prípade priečinka `node_modules` značne skráti čas inicializácie kompilácie.

3. Komitnite a synchronizujte zmeny so vzdialeným repozitárom.

    ```ps
    git add .
    git commit -m 'dockerfile for ambulance waiting list web component'
    git push
    ```

4. Skompilujte súbor `Dockerfile` do nového obrazu `ambulance-ufe` príkazom:

   ```ps
   docker build -t ambulance-ufe -f build/docker/Dockerfile .
   ```

   >$apple:> V prípade, že máte procesor s arm64 architektúrou a build docker obrazu skončí neúspešne s hláškou: `The chromium binary is not available for arm64.`, treba pred riadok v  Dockerfile: `COPY package.json .` pridať riadok: `ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true`.

   Inštalácia balíčkov môže byť pri prvom vykonaní tohto príkazu zdĺhavá a závislá od rýchlosti  sieťového pripojenia, v nasledujúcich kompiláciách sa ale bude vytváranie tejto vrstvy  preskakovať, pokiaľ nedôjde k zmene súboru `package.json`. Po úspešnom vykonaní príkazu môžete  naštartovať kontajner príkazom

   ```ps
   docker run -p 8000:8080 --name ambulance-ufe-server ambulance-ufe
   ```

   a prejdite do webového prehliadača na stránku [http://localhost:8000](http://localhost:8000), kde  by ste mali vidieť zoznam čakajúcich pacientov.

   >info:> Voľba `-p 8000:8080` určuje, že port `8000` hostiteľského počítača - `localhost` bude presmerovaný  na port `8080` virtuálneho sieťového rozhrania bežiaceho kontajnera. Port `8000` môže byť v  niektorých prípadoch už rezervovaný iným programom. V takom prípade číslo tohto portu upravte a  prejdite na stránku so zodpovedajúcim portom.

    Kontajner môžete zastaviť a vymazať príkazom

    ```ps
    docker rm -f ambulance-ufe-server
    ```

5. Pokiaľ ešte nie ste registrovaný na stránke [Docker Hub][docker-hub], prejdite tam a zaregistrujte sa. Všimnite si, aké máte priradené používateľské meno. V ďalších príkazoch musíte zameniť vlastným používateľským menom reťazec `<your-account>`.

6. Označte obraz kontajnera novým názvom, zahrňujúcim vaše meno používateľa zo stránky Docker Hub a zverejnite ho nasledujúcimi príkazmi:

    ```ps
    docker tag ambulance-ufe <your-account>/ambulance-ufe:latest
    docker login
    docker push <your-account>/ambulance-ufe:latest
    ```

    >info:> Názov za dvojbodkou typicky určuje verziu obrazu kontajnera. Pokiaľ nie je uvedený, tak je  automaticky doplnený názvom `latest`. V predchádzajúcom príkaze by preto jeho uvádzanie nebolo  potrebné a príkaz kombinuje variant s explicitne aj implicitne uvedenou verziou `latest`.

    Na stránke [Docker Hub][docker-hub] by ste po ukončení týchto príkazov mali vidieť  váš nový obraz softvérového kontajnera

    ![Zverejnený obraz kontajnera](./img/041-01-novy-kontajner.png)

    >info:> V prípade, že sa vám nepodarí zverejniť obraz kontajnera, skontrolujte, či ste sa  úspešne prihlásili na stránke [Docker Hub][docker-hub] a či ste použili správne používateľské meno.
