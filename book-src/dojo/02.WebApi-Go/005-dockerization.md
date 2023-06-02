## Kontajnerizovanie aplikácie - webového api

Podarilo sa nám vytvoriť funkčné webové API.
Pred tým, než aplikáciu nasadíme, zabezpečíme jej kontajnerizáciu prostredníctvom
technológie Docker.

Jednou z hlavných výhod kontajnerizovanej aplikácie je jej ľahké (a do veľkej miery
jednodné naprieč poskytovateľmi) nasadenie.

### Vytvorenie obrazu (image) aplikácie webového api

1. Prejdite do adresára `.../ambulance-webapi` a otvorte súbor `Dockerfile` (bol vygenerovaný Swagger-om).
    Obsah súboru upravte nasledovne:

    ```docker
    # stiahne package podľa aktuálnej architektúry dockeru (windows/linux/...)
    FROM golang:1.19.4 AS build
    WORKDIR /app
    COPY models ./models
    COPY rest-api ./rest-api
    COPY router ./router
    COPY main.go .

    # zabezpečí statické linkovanie knižníc do výsledného programu
    ENV CGO_ENABLED=0

    RUN go mod init ambulance-webapi
    RUN go mod tidy

    # výsledkom príkazu je vykonávateľný súbor ambulance-webapi
    RUN go build -a -o ambulance-webapi .

    FROM scratch
    # nasledujúci riadok treba odkomentovať v prípade produkčnej verzie
    #ENV GIN_MODE=release
    COPY --from=build /app/ambulance-webapi ./
    EXPOSE 8080/tcp
    ENTRYPOINT ["./ambulance-webapi"]
    ```

    > Pozn: Odporúčame teraz vykonať kroky v bode 2 nižšie a potom sa vrátiť k opisu obsahu súboru.
    > Prvá kompilácia príkazu bude potrebovať získať väčšie množstvo dát (>500MB).

    Všimnite si, že sa v tomto prípade jedná o viac-krokové vytvorenie obrazu - _multistage build_.
    Počas prvého kroku použijeme ako základnú vrstvu obraz `golang:1.19.4`,
    ktorý nám umožní vygenerovať artefakty projektu z jeho zdrojového kódu. Najprv
    skopírujeme všetok zdrojový kód, teda priečinky `models`, `rest-api`, `router` a súbor `main.go`. Nastavíme premennú `CGO_ENABLED` na hodnotu `0`. Takéto nastavenie zabezpečí statické linkovanie knižníc do exe súboru. Potom spustíme 3 príkazy jazyka go:
    * `go mod init ambulance-webapi`
    * `go mod tidy`
    * `go build -a -o ambulance-webapi .`

    Výsledkom je súbor vykonávateľného programu `ambulance-webapi`, ktorý použijeme v druhom kroku.

    Počas druhého kroku použijeme ako základnú vrstvu obraz `scratch`. Je to prázdny obraz, ktorý nám umožní ušetriť mnoho priestoru a niekedy tiež vyhnúť sa riešeniu licenčných podmienok rôzných linuxových distribúcií. Použitie obrazu `scratch` je pri aplikáciách písaných v jazyku `Go` veľmi časté. Dôvodom je, že pre spustenie skompilovanej `Go` aplikácie nepotrebujeme žiadne podporné nástroje jazyka `Go` (ktoré sú obsiahnuté v obraze `golang`). Stačí nám nakopírovať skompilovaný súbor `ambulance-webapi`.

    V posledných krokoch zadefinujeme `port` kontajneru (nie je nevyhnutné), na ktorom bude výsledný kontajner počúvať a určíme vstupný proces pre beh kontajneru.

    > Pozn: Každý z horeuvedených krokov vytvorí novú vrstvu v Union File System,
    používanom Docker. Pri ďalšom vytváraní obrazu zo súboru `Dockerfile`,
    systém detekuje, či došlo k zmenám v danej vrstve a pokiaľ
    nie, tak použije vrstvu vygenerovanú počas predchádzajúceho behu.

2. Uložte súbor `Dockerfile` a synchronizujte ho do vzdialeneho repozitára.

   ```bash
   git pull
   git add .
   git commit -m 'dockerfile'
   git push
   ```

   Potom, v príkazovom riadku prejdite do adresára `ambulance-webapi` a vykonajte príkaz

    ```ps
    docker build -t ambulance-webapi:latest .
    ```

    Po jeho úspešnom behu naštartujte kontajner s namapovaním portu 8888 (tento port si môžte vybrať) na port
    kontajnera 8080, na ktorom by mal počúvať náš web server.

    ```ps
    docker run --name ambulance-webapi-instance -p 8888:8080 ambulance-webapi:latest
    ```

    V konzole sa zobrazí hlásenie (dátum a čas budú samozrejme iné):

    ```ps
    2021/12/23 07:39:32 Server started
    ```

    Vo webovom prehliadači zadajte adresu `http://localhost:8888/api`. V prehliadači sa zobrazí text `Hello World!`.

### Publikovanie obrazu pomocou Docker Hub

1. Doteraz sme používali iba lokálne dostupný obraz kontajneru. Pokiaľ ho chcete
    použiť v ľubovoľnom prostredí, najprv ho označte svojím repozitárom:

    ```docker
    docker tag ambulance-webapi:latest <docker-account>/ambulance-webapi:latest
    ```

    Pokiaľ nie ste prihlásený do svojho repozitára, tak sa prihláste, napríklad
    pomocou príkazu docker login:

    ```docker
    docker login
    ```

    Obraz zverejníte pomocou príkazu:

    ```docker
    docker push <docker-account>/ambulance-webapi:latest
    ```

    Po prihlásení do Docker Hub by ste mali v zozname repozitárov vidieť nový repozitár
    `<docker-account>/ambulance-webapi:latest`.
    ![Webapi na Docker Hube](../img/dojo-19-dockerhub-repo.png)

V tejto chvíli máte plne kontajnerizovanú verziu webového api pripravenú na použitie.
Obraz webovej služby sa nachádza v repozitári Docker Hub, ktorý bude v ďalšej časti cvičení
dôležitý pri automatickej priebežnej integrácii a automatickom priebežnom nasadení.
