# Návrh API špecifikácie

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-ufe-101`

---

V predchádzajúcej sekcii ste si určite všimli, že náš editor sa vždy zobrazuje prázdny a zmeny sa nedajú uložiť. Síce by sme mohli upravovať záznamy priamo v pamäti, z praktického hľadiska bude však výhodnejšie, keď začneme pracovať s údajmi, ktoré budeme získavať a ukladať pomocou [RESTfull Web API][REST API]. Momentálne ale žiadnu službu poskytujúcu potrebné API nemáme. Máme dve možnosti ako postupovať - vytvoriť službu poskytujúcu potrebné REST API a následne toto API implementovať v našej jednostránkovej aplikácii alebo zadefinovať, ako by dané API malo vyzerať pomocou [OpenAPI] špecifikácie a následne vygenerovať potrebnú implementáciu pomocou [nástrojov OpenAPI][openapi-generator]. Prednosťou druhého spôsobu je, že môžeme ďalej pokračovať vo vývoji našej aplikácie, definovať API podľa reálnych požiadaviek klienta a zároveň automatizovať generovanie implementácie služby ako na strane klienta, tak aj na strane servera. Táto technika sa vo všeobecnosti nazýva [_API First Design_][api-first]. Pre lepšie pochopenie princípu budeme toto API vytvárať postupne a priebežne upravovať našu aplikáciu na použitie so vzniknutým API.

>info:> Pre prácu s [openapi] súbormi odporúčame nainštalovať do prostredia Visual Studio Code rozšírenia [openapi-lint](https://marketplace.visualstudio.com/items?itemName=mermade.openapi-lint) a [openapi-designer](https://marketplace.visualstudio.com/items?itemName=philosowaffle.openapi-designer).

1. Vytvorte súbor `${WAC_ROOT}/ambulance-ufe/api/ambulance-wl.openapi.yaml`. Vložte do neho nasledujúci kód:

   ```yaml
   openapi: 3.0.0
   servers:
     - description: Cluster Endpoint
       url: /api @_important_@
   info:
     description: Ambulance Waiting List management for Web-In-Cloud system
     version: "1.0.0"
     title: Waiting List Api
     contact:
       email: <your_email>
     license:
       name: CC BY 4.0
       url: "https://creativecommons.org/licenses/by/4.0/"
   tags:
    - name: ambulanceWaitingList  @_important_@
      description: Ambulance Waiting List API
   ```

   V tomto kroku sme zadefinovali základnú štruktúru [openapi] súboru. V sekcii `servers` sme zadefinovali, kde bude naša služba dostupná - túto hodnotu môžeme neskôr v implementácii zmeniť, tu uvedená bude použitá ako štandardná hodnota. V sekcii `info` sme zadefinovali základné informácie o našej službe. V sekcii `tags` sme zadefinovali zoznam tagov, ktoré budeme používať na kategorizáciu jednotlivých endpointov. Tagy sú dôležité pri generovaní kódu, zvyčajne sa pre každý tag vygeneruje samostatná trieda obsahujúca všetky cesty a metódy, ktoré sú danému tagu priradené.

2. Ďalej do súboru doplníme špecifikácu pre cestu `/waiting-list/{ambulance-id}`:

   ```yaml
   paths:
    "/waiting-list/{ambulanceId}/entries":
      get:
        tags:
          - ambulanceWaitingList @_important_@
        summary: Provides the ambulance waiting list
        operationId: getWaitingListEntries  @_important_@
        description: By using ambulanceId you get list of entries in ambulance waiting list
        parameters:
          - in: path @_important_@
            name: ambulanceId @_important_@
            description: pass the id of the particular ambulance
            required: true
            schema:
              type: string
        responses:
          "200":
            description: value of the waiting list entries
            content:
              application/json:
                schema:
                  type: array
                  items:
                    $ref: "#/components/schemas/WaitingListEntry" @_important_@
                examples:
                  response:
                    $ref: "#/components/examples/WaitingListEntriesExample" @_important_@
          "404":
            description: Ambulance with such ID does not exist
   ```

   Táto špecifikácia určuje, že na ceste `/waiting-list/{ambulanceId}/entries`, kde `{ambulanceId}` je premenná hodnota typu string, môžeme vyvolať požiadavku typu [HTTP GET](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET), ktorej odozva môže nadobudnúť hodnotu [200](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/200) alebo [404](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404), pričom v prvom prípade bude obsahovať pole objektov typu `WaitingListEntry`. Tiež sme určili meno operácie `getWaitingListEntries`. Toto meno určuje názov metód a funkcií pri generovaní kódu. Názov `operationId` musí byť v rámci špecifikácie jedinečný. Všimnite si tiež, že sme použili referencie na sekciu `components`. Vložme teraz do súboru [JSON schému][jsonschema] pre objekt `WaitingListEntry` a pre objekty, na ktorých je závislý:

   ```yaml
   components:
    schemas:
      WaitingListEntry: @_important_@
        type: object
        required: [id, patientId, waitingSince, estimatedDurationMinutes]  @_important_@
        properties:
          id:
            type: string
            example: x321ab3
            description: Unique id of the entry in this waiting list
          name:
            type: string
            example: Jožko Púčik
            description: Name of patient in waiting list
          patientId:
            type: string
            example: 460527-jozef-pucik
            description: Unique identifier of the patient known to Web-In-Cloud system
          waitingSince:
            type: string
            format: date-time
            example: "2038-12-24T10:05:00Z"
            description: Timestamp since when the patient entered the waiting list
          estimatedStart:
            type: string
            format: date-time
            example: "2038-12-24T10:35:00Z"
            description: Estimated time of entering ambulance. Ignored on post.
          estimatedDurationMinutes:
            type: integer
            format: int32
            example: 15
            description: >-
              Estimated duration of ambulance visit. If not provided then it will
              be computed based on condition and ambulance settings
          condition:
            $ref: "#/components/schemas/Condition" @_important_@
        example: 
          $ref: "#/components/examples/WaitingListEntryExample" @_important_@
      Condition: @_important_@
        description: "Describes disease, symptoms, or other reasons of patient   visit"
        required:
          - value  @_important_@
        properties:
          value:
            type: string
            example: Teploty
          code:
            type: string
            example: subfebrilia
          reference:
            type: string
            format: url
            example: "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/"
            description: Link to encyclopedical explanation of the patient's condition
          typicalDurationMinutes:
            type: integer
            format: int32
            example: 20
        example: 
          $ref: "#/components/examples/ConditionExample" @_important_@
   ```

    V tejto špecifikácii sme zadefinovali objekt `WaitingListEntry`, ktorý obsahuje všetky potrebné informácie o zozname čakajúcich pacientov a opis zdravotného problému pacienta definovaný typom `Condition`. Technicky by sme mohli schému vnoreného typu `Condition` definovať priamo v objekte `WaitingListEntry`. Pre účely generovania kódu a pre prehľadnosť ale odporúčame vždy používať referencie na samostatne definované typy. Dôležitým aspektom špecifikácie je uvádzanie povinných polí pomocou kľúčového slova `required`. Toto kľúčové slovo je dôležité pre generovanie kódu, ktorý bude validovať vstupné dáta. V prípade, že vstupné dáta nebudú obsahovať povinné polia, tak požiadavka bude typicky odmietnutá so stavovým kódom [400 - Bad Request](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/400).

    V špecifikácii konzistentne uvádzame príklady s použitím kľúčového slova `example`. Tieto príklady sú dôležité pre generovanie dokumentácie a sú tiež dôležité pre vytvorenie experimentálnej služby (_mock_), ktorú budeme používať pri lokálnom vývoji. Doplňte do súboru nasledujúce príklady do sekcie `components.examples`:

    ```yaml
    components: 
    ...
      examples:
        WaitingListEntryExample: 
          summary: Ľudomír Zlostný waiting
          description: |
            Entry represents a patient waiting in the ambulance prep room with
            defined symptoms
          value:
            id: x321ab3
            name: Ľudomír Zlostný
            patientId: 74895-ludomir-zlostny
            waitingSince: "2038-12-24T10:05:00.000Z"
            estimatedStart: "2038-12-24T10:35:00.000Z"
            estimatedDurationMinutes: 15
            condition:
              value: Nevoľnosť
              code: nausea
              reference: "https://zdravoteka.sk/priznaky/nevolnost/"
        ConditionExample:
          summary: Conditions and symptoms
          description: list of few symptoms that can be chosen by patients
          value: 
            valuee: Teploty
            code: subfebrilia
            reference: >-
              https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/
        WaitingListEntriesExample:
          summary: List of waiting patients 
          description: |
            Example waiting list containing 2 patients
          value:
          - id: x321ab3
            name: Jožko Púčik
            patientId: 460527-jozef-pucik
            waitingSince: "2038-12-24T10:05:00.000Z"
            estimatedStart: "2038-12-24T10:35:00.000Z"
            estimatedDurationMinutes: 15
            condition:
              value: Teploty
              code: subfebrilia
              reference: "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/"
          - id: x321ab4
            name: Ferdinand Trety
            patientId: 780907-ferdinand-tre
            waitingSince: "2038-12-24T10:25:00.000Z"
            estimatedStart: "2038-12-24T10:50:00.000Z"
            estimatedDurationMinutes: 25
            condition:
              value: Nevoľnosť
              code: nausea
              reference: "https://zdravoteka.sk/priznaky/nevolnost/"
    ```

   Naša špecifikácia teraz popisuje akým spôsobom môžeme získať zoznam čakajúcich pacientov v ambulancii. Pristúpime k integrácii s našou aplikáciou.

   >info:> Naše API `getWaitingListEntries` vracia priamo pole záznamov, čo je v prípade WebAPI považované za chybu návrhu. Naše API by malo byť pripravené aj pre väčší rozsah dát a podporovať získanie len ich [čiastočného rozsahu](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design#filter-and-paginate-data). Pre zjednodušenie ale tento aspekt nebudeme v našej aplikácii riešiť, pri návrhu konkrétneho API v praxi sa ale najprv zoznámte so [zásadami návrhu RESTfull API](https://book.restfulnode.com/).

3. V prvom kroku si pripravíme experimentálny - _mock_ - server poskytujúci špecifikované API na základe príkladov v špecifikácii. Nainštalujte do projektu nové závislosti potrebné pre vývoj aplikácie spustením nasledovného príkazu v priečinku `${WAC_ROOT}/ambulance-ufe`:

   ```ps
   npm install --save-dev js-yaml open-api-mocker npm-run-all 
   ```

   V súbore `${WAC_ROOT}/ambulance-ufe/package.json` doplňte nové skripty a upravte script `start`:
  
   ```json
   ...
    "scripts": {
      "convert-openapi": "js-yaml  ./api/ambulance-wl.openapi.yaml > .openapi.json", @_add_@
      "mock-api": "open-api-mocker --schema .openapi.json --port 5000", @_add_@
      "start:app": "stencil build --dev --watch --serve", @_add_@
      "start:mock": "run-s convert-openapi mock-api", @_add_@
      "start": "run-p -r start:mock start:app", @_add_@
      "build": "stencil build --docs",
      "start": "stencil build --dev --watch --serve", @_remove_@
      ...
   ```

   >$apple:> Na niektorých Mac zariadeniach môže na porte 5000 bežať airplay server. V takomto prípade zmeňte port mock serveru na iný voľný port.

   Skript `convert-openapi` premení špecifikáciu vo formáte YAML na JSON - `open-api-mocker` vyžaduje špecifikáciu vo formáte JSON. Skript `mock-api` spustí mock server, ktorý bude poskytovať API podľa špecifikácie. Skript `start:mock` spustí oba predchádzajúce príkazy sekvenčne. Skript `start:app` obsahuje príkaz, pôvodne použitý v skripte `start`, teda skompiluje našu aplikáciu a naštartuje vývojový server. Skript `start` sme upravili, aby paralelne spustil náš mock API server a vývojový server našej aplikácie. Tieto úpravy nám umožnia lokálny vývoj aplikácie bez nutnosti pripojenia na skutočný API server.

   Upravte súbor `${WAC_ROOT}/ambulance-ufe/.gitignore` a pridajte riadok `.openapi.json`.

   ```text
   ...
   .openapi.json @_add_@
   ```

   V priečinku `${WAC_ROOT}/ambulance-ufe` vykonajte nasledujúci príkaz:

   ```ps
    npm run start:mock
    ```

    Otvorte nový príkazový riadok a zadajte nasledujúci príkaz:

    ```ps
    curl http://localhost:5000/api/waiting-list/bobulova/entries
    ```

    Na výstupe sa objaví výpis vo formáte JSON obsahujúci zoznam čakajúcich pacientov v ambulancii. Tento výpis je generovaný na základe príkladu v špecifikácii. Teraz máme k dispozícii službu, ktorá je schopná simulovať naše REST API. Zastavte spustené mock API (_CTRL+C_).

4. V ďalšom kroku prejdeme k vygenerovaniu kódu pre klienta. K tomu využijeme nástroj [openapi-generator]. Nainštalujte si tento nástroj do projektu:

   ```ps
   npm install --save-dev @openapitools/openapi-generator-cli
   ```

   Vytvorte súbor `${WAC_ROOT}/ambulance-ufe/openapitools.json` a vložte do neho nasledujúci obsah:

   ```json
   {
      "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
      "generator-cli": {
          "useDocker": true,
          "version": "6.6.0",
          "generators": {
              "ambulance-wl": {
                  "generatorName": "typescript-axios", @_important_@
                  "glob": "api/ambulance-wl.openapi.yaml", @_important_@
                  "output": "#{cwd}/src/api/ambulance-wl", @_important_@
                  "additionalProperties": {
                      "supportsES6": "true",
                      "withInterfaces": true,
                      "enablePostProcessFile": true
                  }
              }
          }
      }
   }
   ```

   Tento súbor konfiguruje beh generátoru kódu. Budeme používať Docker verziu generátora, preto je nutné pri generovaní kódu mať aktívny docker démon, napríklad [Docker for Desktop][docker-desktop]. Alternatívne riešenie vyžaduje mať nainštalovaný systém JAVA SDK. Okrem iných parametrov určuje cestu k našej špecifikácii - `glob` - a tiež cestu - `output` - kde sa bude generovať klient typu `typescript-axios`. Ďalej vytvorte súbor `${WAC_ROOT}/ambulance-ufe/src/api/ambulance-wl/.openapi-generator-ignore` a vložte do neho nasledujúci obsah:

   ```text
   .npmignore
   *.sh
   ```

   Tento súbor určuje, ktoré súbory sa počas generovania nebudú ukladať do cieľového priečinku. V našom prípade to sú pomocné súbory `.npmignore` a `git-push.sh`, ktoré nepotrebujeme.

   Do súboru `${WAC_ROOT}/ambulance-ufe/package.json` doplňte nový skript:

   ```json
   ...
   "scripts": {
     ...
     "openapi": "openapi-generator-cli generate" @_add_@
   },
   ...
   ```

   a v adresári `${WAC_ROOT}/ambulance-ufe` vykonajte nasledujúci príkaz:

   ```ps
   npm run openapi
   ```

   V priečinku `${WAC_ROOT}/ambulance-ufe/src/api/ambulance-wl` teraz nájdete nový kód, ktorý obsahuje implementáciu klienta pre nami špecifikované API v programovacom jazyku [TypeScript] s využitím knižnice [Axios].

   >info:> V našom prípade generujeme klientský kód ako súčasť našej aplikácie. Často sa ale generuje klientský kód vo forme knižníc, aby sa API dalo používať medzi rôznymi aplikáciami, najmä ak naše API je všeobecne použiteľné. V takom prípade by sme vytvorili samostatný projekt, ktorého obsah by bol generovaný zo špecifikácie, napríklad z odkazu na URL tejto špecifikácie, a tento projekt by sme publikovali do [npmjs.com]. Vhodnou automatizáciou by sme boli schopní automaticky vytvárať rôzne knižnice v rôznych jazykoch pre tú istú špecifikáciu.

   &nbsp;

   >info:> Bolo by vhodné upraviť aj skript `build` tak, aby sa zakaždým pred spustením kompilácie aplikácie vygeneroval kód klienta. Túto úpravu ponecháme na Vašu samostatnú prácu.

5. Vygenerované API použijeme v našej aplikácii. Najprv doinštalujeme knižnicu [Axios], ktorú využíva  vygenerovaný klientský kód:

   ```ps
   npm install --save axios@1.6.0
   ```

   Otvorte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-list/<pfx>-ambulance-wl-list.tsx` a upravte kód:

   ```tsx
   import { Component, Event, EventEmitter, Host, Prop, State, h } from '@stencil/core';  @_important_@
   import { AmbulanceWaitingListApiFactory, WaitingListEntry } from '../../api/ambulance-wl'; @_add_@
   ...
   export class <Pfx>AmbulanceWlList { 

      @Event({ eventName: "entry-clicked" }) entryClicked: EventEmitter<string> 
      @Prop() apiBase: string; @_add_@
      @Prop() ambulanceId: string; @_add_@
      @State() errorMessage: string; @_add_@

      waitingPatients: WaitingListEntry[]; @_important_@

      private async getWaitingPatientsAsync(): Promise<WaitingListEntry[]> {   @_important_@
        ... odstránte pôvodný kód ... @_remove_@
        // be prepared for connectivitiy issues
        try { @_add_@
          const response = await @_add_@
            AmbulanceWaitingListApiFactory(undefined, this.apiBase). @_add_@
              getWaitingListEntries(this.ambulanceId) @_add_@
          if (response.status < 299) { @_add_@
            return response.data; @_add_@
          } else { @_add_@
            this.errorMessage = `Cannot retrieve list of waiting patients: ${response.statusText}`  @_add_@
          } @_add_@
        } catch (err: any) { @_add_@
          this.errorMessage = `Cannot retrieve list of waiting patients: ${err.message || "unknown"}`  @_add_@
        } @_add_@
        return []; @_add_@
      } 
    ...
    ```

    V tomto kroku sme upravili spôsob získania zoznamu pacientov - zoznam pacientov teraz získaveme pomocou klientského kódu z nášho API. Zaviedli sme nové premenné - atribúty elementu - `apiBase` a `ambulanceId`, ktoré využijeme na pripojenie sa k API. V kóde tiež riešime možnosť, že sa nám nepodarí pripojiť k API, alebo že sa nám nepodarí získať zoznam pacientov. V takom prípade zobrazíme chybové hlásenie. V tom istom súbore upravte metódu `render`:

    ```tsx
    render() {
      return (
        <Host>
          {this.errorMessage @_add_@
            ? <div class="error">{this.errorMessage}</div>  @_add_@
            :  @_add_@
             <md-list> 
              ...
            </md-list>
          }  @_add_@
        </Host>
      );
    }
    ```

6. Upravte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-app/<pfx>-ambulance-wl-app.tsx` a doplňte obdobné atribúty elementu, ktoré sa predajú do elementu `<pfx>-ambulance-wl-list`:

   ```tsx
    ...
    export class <Pfx>AmbulanceWlApp { 
      @State() private relativePath = "";
      @Prop() basePath: string="";
      @Prop() apiBase: string; @_add_@
      @Prop() ambulanceId: string; @_add_@
      ...  
      render() {
        ...
        return (
          <Host>
            { element === "editor" 
            ? <pfx-ambulance-wl-editor entry-id={entryId}
              oneditor-closed={ () => navigate("./list")}
            ></pfx-ambulance-wl-editor>
            : <pfx-ambulance-wl-list  ambulance-id={this.ambulanceId} api-base={this.apiBase} @_important_@
              onentry-clicked={ (ev: CustomEvent<string>)=> navigate("./entry/" + ev.detail) } >
              </pfx-ambulance-wl-list>
            }
          </Host>
      ...
   ```

   Nakoniec upravte súbor `${WAC_ROOT}/ambulance-ufe/src/index.html` a doplňte atribúty elementu `<pfx>-ambulance-wl-app`:

   ```html
   <body style="font-family: 'Roboto'; ">
      <<pfx>-ambulance-wl-app ambulance-id="bobulova" api-base="http://localhost:5000/api" base-path="/ambulance-wl/"></<pfx>-ambulance-wl-app> @_important_@
   </body>
   ```

7. Naštartujte vývojový server vykonaním príkazu v priečinku `${WAC_ROOT}/ambulance-ufe`:

   ```ps
   npm run start
   ```

   a prejdite na stránku [http://localhost:3333](http://localhost:3333). Mali by ste vidieť stránku so zoznamom pacientov zodpovedajúci nášmu príkladu v [OpenAPI] špecifikácii. Môžete vyskúšať aj činnosť aplikácie bez prístupu k WEB API pomocou príkazu `npm run start:app`. V tomto prípade sa zobrazí chybové hlásenie, že sa nepodarilo pripojiť k API. Aby bolo hlásenie zreteľnejšie upravte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-list/<pfx>-ambulance-wl-list.css` :

   ```css
   :host {
      display: block;
      width: 100%;
      height: 100%;
   }

   .error {
      margin: auto;
      color: red;
      font-size: 2rem;
      font-weight: 900;
      text-align: center;
   }
   ```

8. Pred archiváciou zmien musíme ešte opraviť naše testy. Pokiaľ teraz vykonáte v priečinku `${WAC_ROOT}/ambulance-ufe` príkaz:

   ```ps
   npm run test
   ```

   zobrazí sa Vám vo výpise chyba _SyntaxError: Cannot use import statement outside a module_ odkazujúca na kód z knižnice [axios]. Táto chyba je obdobná ako v prípade použitia
   knižnice [@material/web][md-webc], spôsobená rôznymi predpokladmi o používanej verzii jazyka ECMScript a podpore najnovších spôsobov načítavania modulov medzi týmito knižnicami a testovacou knižnicou [Jest]. Knižnicu [Jest] môžme nakonfigurovať pomocou použitia tzv. [Transformerov kódu - _Code Transformers_](https://jestjs.io/docs/code-transformation).

   Najprv si doinštalujeme potrebné balíčky. V adresári `${WAC_ROOT}/ambulance-ufe` vykonajte nasledujúci príkaz:

   ```ps
   npm install --save-dev @babel/preset-env babel-jest
   ```

   Vytvorte súbor `${WAC_ROOT}/ambulance-ufe/babel.config.cjs` a vložte do neho nasledujúci obsah:

   ```js
   module.exports = {
    presets: [ '@babel/preset-env' ]
   }
   ```

   [Babel] je [transpilátor](https://en.wikipedia.org/wiki/Source-to-source_compiler) jazyka JavaScript, umožňuje preložiť kód ECMAScript do rôznych cieľových verzií jazyka, používa sa napríklad v prípadoch, keď počas vývoja chceme využívať najmodernejšie vlastnosti jazyka a zároveň chceme podporovať staršie verzie jazyka - napríklad staršie, ešte nezmodernizované prehliadače.

   Ďalej upravte súbor `${WAC_ROOT}/ambulance-ufe/stencil.config.ts` a do sekcie `testing` doplňte nové pravidlá transformovania kódu:

   ```js
   ...
   export const config: Config = {
    ...
    testing: {      @_add_@
        transformIgnorePatterns: ["/node_modules/(?!axios)"], @_add_@
        transform: { @_add_@
          "^.+\\.(js|jsx)$": "babel-jest", @_add_@
        },  @_add_@
    }
    ...
   ```

   Opäť vykonajte príkaz `npm run test` a tentokrát by testy mali prebehnúť úspešne.

9. Pokiaľ si prezrieme test v súbore `${WAC_ROOT}/ambulance-ufe/src/components/pfx-ambulance-wl-list/test/pfx-ambulance-wl-list.spec.tsx`, pochopíme, že náš test bude úspešný aj pri neúspešnom pripojení sa k serveru, kedy je zoznam pacientov prázdny. Bolo by preto vhodnejšie, keby sme boli schopní simulovať spojenie s API serverom. Na to použijeme knižnicu [axios-mock-adapter](https://github.com/ctimmerm/axios-mock-adapter). Nainštalujte si túto knižnicu do projektu:

   ```ps
   npm install --save-dev axios-mock-adapter
   ```

   Otvorte súbor `${WAC_ROOT}/ambulance-ufe/src/components/pfx-ambulance-wl-list/test/pfx-ambulance-wl-list.spec.tsx` a upravte jeho obsah:

   ```tsx
   import { newSpecPage } from '@stencil/core/testing';
   import { <Pfx>AmbulanceWlList } from '../<pfx>-ambulance-wl-list';
   import axios from "axios"; @_add_@
   import MockAdapter from "axios-mock-adapter"; @_add_@
   import { WaitingListEntry } from '../../../api/ambulance-wl'; @_add_@

   describe('<pfx>-ambulance-wl-list', () => {

      const sampleEntries: WaitingListEntry[] = [ @_add_@
        { @_add_@
          id: "entry-1", @_add_@
          patientId: "p-1", @_add_@
          name: "Juraj Prvý", @_add_@
          waitingSince: "20240203T12:00", @_add_@
          estimatedDurationMinutes: 20 @_add_@
        }, { @_add_@
          id: "entry-2", @_add_@
          patientId: "p-2", @_add_@
          name: "James Druhý", @_add_@
          waitingSince: "20240203T12:05", @_add_@
          estimatedDurationMinutes: 5 @_add_@
        }]; @_add_@
        @_add_@
      let mock: MockAdapter; @_add_@
      @_add_@
      beforeAll(() => { mock = new MockAdapter(axios); }); @_add_@
      afterEach(() => { mock.reset(); }); @_add_@

      it('renders sample entries', async () => { @_important_@
        // simulate API response using sampleEntries 
        mock.onGet().reply(200, sampleEntries); @_add_@

        // set proper attributes
        const page = await newSpecPage({
          components: [<Pfx>AmbulanceWlList],
          html: `<<pfx>-ambulance-wl-list ambulance-id="test-ambulance" api-base="http://test/api"></<pfx>-ambulance-wl-list>`, @_important_@
        });
        const wlList = page.rootInstance as <Pfx>AmbulanceWlList;
        const expectedPatients = wlList?.waitingPatients?.length;

        const items = page.root.shadowRoot.querySelectorAll("md-list-item");
        // use sample entries as expectation
        expect(expectedPatients).toEqual(sampleEntries.length); @_important_@
        expect(items.length).toEqual(expectedPatients);
      });
    ...
    ```

    V tomto kroku sme upravili test tak, aby sme mohli simulovať odpoveď z API serveru. Vytvorili sme si zoznam pacientov, ktorý použijeme ako očakávaný výsledok. V teste sme použili metódu `reply` na simuláciu odpovede z API serveru. V teste sme tiež upravili očakávaný výsledok tak, aby očakával počet elementov `md-list-item` rovný počtu pacientov v simulovanom zozname odpovede `sampleEntries`.

    Test rozšírime tak, aby overil aj reakciu komponentu v prípade chybovej odpovede. V tom istom súbore doplňte nový test:

    ```tsx
    ...
    describe('<pfx>-ambulance-wl-list', () => {
      ...
      it('renders sample entries', async () => { 
        ...
      });

      it('renders error message on network issues', async () => {  @_add_@
        mock.onGet().networkError();  @_add_@
        const page = await newSpecPage({  @_add_@
          components: [<Pfx>AmbulanceWlList],  // @_add_@
          html: `<pfx-ambulance-wl-list ambulance-id="test-ambulance" api-base="http://test/api"></pfx-ambulance-wl-list>`,  // @_add_@
        });  @_add_@
          @_add_@
        const wlList = page.rootInstance as <Pfx>AmbulanceWlList; // @_add_@
        const expectedPatients = wlList?.waitingPatients?.length  @_add_@
        @_add_@
        const errorMessage =  page.root.shadowRoot.querySelectorAll(".error");  @_add_@
        const items = page.root.shadowRoot.querySelectorAll("md-list-item");  @_add_@
          @_add_@
        expect(errorMessage.length).toBeGreaterThanOrEqual(1)  @_add_@
        expect(expectedPatients).toEqual(0);  @_add_@
        expect(items.length).toEqual(expectedPatients);  @_add_@
      });  @_add_@
    ...
    ```

   Všimnite si ako simulujeme chybovú odpoveď z API serveru pomocou metódy `networkError`. V teste očakávame, že sa zobrazí chybové hlásenie a že sa nezobrazí žiadny záznam v zozname pacientov.

   >info:> Testovaniu negatívnych scenárov - takzvaných _rainy days use cases_ - je v praxi potrebné venovať náležitú pozornosť. Vývoj častokrát prebieha v umelých prostrediach, za ideálnych podmienok sieťového pripojenia a pri dostatku systémových objektov. Obmedzenia v reálnych prostrediach môžu mať za dôsledok oneskorenie dodania produktu alebo úplné odmietnutie produktu zo strany používateľov. Ako bolo uvedené, v tomto cvičení sa testovaniu venujeme len okrajovo, rozsah tu uvedených testov by bol v praxi nedostatočný.

10. (_Voliteľné_) Pokiaľ chcete využívať testovacie prostredie [Jest] priamo, napríklad chcete využiť niektoré z populárnych rozšírení ako napríklad [vscode-jest](https://marketplace.visualstudio.com/items?itemName=Orta.vscode-jest), doplňte do projektu konfiguráciu pre správny beh [jest cli](https://jestjs.io/docs/cli) nástrojov. Vytvorte súbor `${WAC_ROOT}/ambulance-ufe/jest.config.js` s nasledujúcim obsahom:

    ```js
    module.exports = {
       "roots": [
           "<rootDir>/src"
       ],
       "transform": {
           "^.+\\.(ts|tsx)$": "<rootDir>/node_modules/@stencil/core/testing/jest-preprocessor.js",
           "^.+\\.(js|jsx)$": "babel-jest",
       },
       transformIgnorePatterns: ["/node_modules/(?!axios)"],
       "testRegex": "(/__tests__/.*|\\.(test|spec))\\.(tsx?|jsx?)$",
       "moduleFileExtensions": [
           "ts",
           "tsx",
           "js",
           "json",
           "jsx"
       ]
    }
    ```

    V súbore `${WAC_ROOT}/ambulance-ufe/package.json` doplňte nový skript:

    ```json
    ...
    "scripts": {
      ...
      "test:jest": "jest --config ./jest.config.js" @_add_@
    },
    ```

    Funkcionalita príkazu je obdobná ako v prípade príkazu `npm run test`. Výhodou je, že môžeme využívať rozšírenia pre [Jest] v našom vývojovom prostredí alebo niektoré  predpripravené [GitHub Akcie](https://github.com/marketplace?type=actions&query=jest+) v priebežnej integrácii.

11. Archivujte svoj kód príkazmi:

   ```ps
   git add .
   git commit -m "Added ambulance waiting list API"
   git push
   ```

   Po vytvorení novej verzie obrazu sa táto nasadí na server. Pokiaľ máte klaster naštartovaný, môžete overiť funkcionalitu na stránke [http://localhost:30331](http://localhost:30331). V tomto prípade ale ešte nemáme nastavené správne atribúty pre našu aplikáciu. Otvorte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-ufe/webcomponent.yaml` a pridajte atribúty `api-base` a `ambulance-id`:

   ```yaml
    ...
    navigation:
      - element: <pfx>-ambulance-wl-app
        attributes:                    @_add_@
        - name: api-base @_add_@
          value: http://localhost:5000/api @_add_@
        - name: ambulance-id @_add_@
          value: bobulova @_add_@
        ...
        hash-suffix: v1alpha2 @_important_@
   ```

   >$apple:> Ak ste predtým zmenili číslo portu, nezabudnite aj tu nastaviť správny port.

   Následne v priečinku `${WAC_ROOT}/ambulance-gitops` vykonajte komit a push:

   ```ps
    git add .
    git commit -m "Added ambulance waiting list API"
    git push
   ```

   Po uplynutí času nutného na aplikovanie zmien do klastra overte funkcionalitu na stránke [http://localhost:30331](http://localhost:30331). Na obrazovke vidíte chybové hlásenie. Dôvodom je, že neprechádza volanie na server. Presvedčte sa o tom skontrolovaním záložky `Sieť` v paneli `Nástroj pre vývojárov`, kde môžte vidieť neúspešné volanie API `http://localhost:5000/api/waiting-list/bobulova/entries`. Volanie zlyhá z dôvodu porušenia CSP pravidiel (vysvetlíme a vyriešime v ďalších kapitolách).

   Avšak aj v prípade, ak by sme vyriešili CSP problém, volanie na server nebude funkčné. Dôvodom je, že na adrese `localhost:5000` nie je spustený server. Môžeme ho simulovať spustením príkazu `npm run start:mock`.
