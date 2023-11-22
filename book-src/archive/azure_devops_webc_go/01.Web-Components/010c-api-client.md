## Použitie API klienta

Teraz, keď máme k dispozícii implementáciu nášho API, upravíme zoznam čakajúcich v súbore `.../ambulance-list/src/components/<pfx>-ambulance-wl-list/<pfx>-ambulance-wl-list.tsx`:
   * Vymažeme metódu `getWaitingPatientsAsync`.
   * Doplníme vlastnosť používateľského elementu, ktorá nám umožní špecifikovať _id_ ambulancie, ku ktorej tento zoznam prislúcha.
   * Zmeníme typ členskej premennej `waitingPatients` na `WaitingListEntry[]`.
   * Zadefinujeme a vytvoríme členskú premennú typu `AmbulanceDevelopersApi` a použijeme ju na naplnenie zoznamu pacientov.

1. V súbore  `.../ambulance-list/src/components/<pfx>-ambulance-wl-list/.<pfx>-ambulance-wl-list.tsx` vykonajte úpravy tak, aby mal nasledujúci obsah:

    ```tsx
    import { Component, Host, h, Prop } from '@stencil/core';
    import { AmbulanceDevelopersApi, WaitingListEntry } from '../../api';
    
    @Component({
      tag: '<pfx>-ambulance-wl-list',
      styleUrl: '<pfx>-ambulance-wl-list.css',
      shadow: true,
    })
    export class <Pfx>AmbulanceWlList {
    
      @Prop()
      ambulance: string = "";
    
      waitingPatients: WaitingListEntry[];
    
      private developerApiClient = new AmbulanceDevelopersApi();
    
      async componentWillLoad() {
        this.waitingPatients = await this.developerApiClient
          .getWaitingListEntries(this.ambulance)
          .then(_ => _.data);
      }
    
      private isoDateToLocale(iso:string) {
        if(!iso) return '';
        return new Date(Date.parse(iso)).toLocaleTimeString()
      }
    
      render() {
        return (
          <Host>
            <mwc-list>
              { this.waitingPatients.map( entry => 
                <mwc-list-item graphic="avatar" twoline>
                  <span>{entry.name}</span>
                  <span slot="secondary">Predpokladaný vstup: {this.isoDateToLocale(entry. estimatedStart)}</span>
                  <mwc-icon slot="graphic">person</mwc-icon>
                </mwc-list-item>
              )}
            </mwc-list>
          </Host>
        );
      }
    }
    ```

    >info:> Jeden z nepovinných parametrov konštruktora `AmbulanceDevelopersApi` je `BASE_PATH`, ktorá definuje adresu, na ktorej sa nachádza naše WebAPI. Momentálne je cesta nastavená v súbore `base.ts` a smeruje na náš swagger mock.

   Funkciu render v súbore `.../ambulance-list/src/components/<pfx>-ambulance-wl-app/<pfx>-ambulance-wl-app.tsx` upravte nasledovne:

    ```tsx
    ...
    export class <Pfx>AmbulanceWlApp {
    
    ...
    
    render() {
       return (
         <Host>
           ...
             <Route path={this.rebase("/")}>
               <<pfx>-ambulance-wl-list        // upravený element ambulance-wl-list
                   ambulance={this.ambulance}>
               </<pfx>-ambulance-wl-list>
             </Route>
           ...
         </Host>
       );
     }
    }
    ```

   Pokiaľ váš vývojový web server nebeží, naštartujte ho príkazom `npm run start` a v prehliadači prejdite na stránku [http://localhost:3333/ambulance-wl/](http://localhost:3333/ambulance-wl/). Otvorte v prehliadači `Nástroje vývojára` (F12) a v záložke `Sieť` si všimnite adresu, z ktorej je zoznam pacientov načítaný.

2. Doplníme udalosť a vlastnosť elementu, pomocou ktorej môžme určiť alebo nastaviť práve zvolený záznam zo zoznamu.

    >info:> Hoci by sme mohli v tomto elemente realizovať aj logiku navigácie, snažíme sa funkcionalitu tohto elementu ohraničiť len na zobrazovanie relevantnej informácie - zoznamu čakajúcich v určenej ambulancii. To nám umožní v budúcnosti znovu použiť takýto komponent v iných kontextoch alebo pri požiadavke na zmenu zobrazenia stránky. Vo všeobecnosti sa snažíme rozlišovať funkcionalitu medzi informačnými kontajnermi - komponenty zobrazujúce nejaký druh informácie, ale neimplementujúce aplikačnú logiku ako takú a komponenty, ktoré takéto informačné kontajnery využívajú a pomocou aplikačnej logiky riadia, ktorý z nich má čo a kedy zobraziť.

   V súbore  `.../ambulance-list/src/components/<pfx>-ambulance-wl-list/<pfx>-ambulance-wl-list.tsx` pridajte nasledovný obsah:

    ```tsx
    ...   
      @Prop({ attribute: "selected-entry-id", mutable: true, reflect: true})
      selectedEntryId: string
    
      @Event()
      wlEntrySelected: EventEmitter<string>;
    
      handleEntrySelection(entryId: string, event: CustomEvent) {
        if(event.detail.source === "interaction") { // see mwc-list for details of the  request-selected event
          this.selectedEntryId = entryId;
          this.wlEntrySelected.emit(entryId);
        }
      }
    
      render() {
        return (
          <Host>
            <mwc-list>
              { this.waitingPatients.map( entry => 
                <mwc-list-item graphic="avatar" twoline // upravený element mwc-list-item
                               selected={entry.id === this.selectedEntryId ? true : false}
                               activated={entry.id === this.selectedEntryId ? true : false}
                               onRequest-selected={ev => this.handleEntrySelection(entry.id,  ev)}>
                  <span>{entry.name}</span>
                  <span slot="secondary">Predpokladaný vstup: {this.isoDateToLocale(entry. estimatedStart)}</span>
                  <mwc-icon slot="graphic">person</mwc-icon>
                </mwc-list-item>
              )}
            </mwc-list>
          </Host>
        );
      }
    }
    ```

   Pridajte chýbajúce importy.

   Ďalej upravte súbor `.../ambulance-list/src/components/<pfx>-ambulance-wl-app/<pfx>-ambulance-wl-app.tsx` tak, aby trieda obsahovala novú funkciu `handleEntrySelection` a upravte funkciu render:

    ```tsx
    ...
    export class <Pfx>AmbulanceWlApp {
      
    ...
   
    handleEntrySelection(e: CustomEvent) {
       <Pfx>AmbulanceWlApp.Router.push(this.rebase(`/entry/${e.detail}`));
    }
   
    render() {
       return (
         <Host>
           ...
             <Route path={this.rebase("/")}>
               <<pfx>-ambulance-wl-list        // upravený element ambulance-wl-list
                   ambulance={this.ambulance} 
                   onWlChange={this.handleEntrySelection.bind(this)}>
               </<pfx>-ambulance-wl-list>
             </Route>
           ...
         </Host>
       );
     }
    }
    ```

   Všimnite si, že sme doplnili spracovanie udalosti `wlChange`, ktoré vedie k presmerovaniu stránky na adresu práve zvoleného elementu.

   Pokiaľ váš vývojový web server nebeží, naštartujte ho príkazom `npm run start` a v prehliadači prejdite na stránku [http://localhost:3333/ambulance-wl/](http://localhost:3333/ambulance-wl/). Stlačte na niektorú položku zoznamu.  

3. Upravíme testy.

   Už sme spomínali, že testovací framework pre `Stencil` je `Jest`. Ich konfigurácia sa upravuje v súbore `stencil.config.ts`. Jest má problém s nainštalovanou knižnicou `axios` a nasledujúca úprava konfigurácie to rieši:

    ```tsx
    import { Config } from '@stencil/core';

    export const config: Config = {
      namespace: 'ambulance-list',
      sourceMap: true,
      globalScript: 'src/utils/global.ts',
      testing: { @_add_@ 
        transform: { @_add_@
          '^.+\\.(ts|tsx|js|jsx|css)$': "@stencil/core/testing/jest-preprocessor" @_add_@
        }, @_add_@
        transformIgnorePatterns: [`/node_modules/(?!axios)`] @_add_@
      }, @_add_@
      outputTargets: [
        {
          type: 'dist',
          esmLoaderPath: '../loader',
        },
        {
          type: 'dist-custom-elements',
        },
        {
          type: 'docs-readme',
        },
        {
          type: 'www',
          serviceWorker: null, // disable service workers
        },
      ],
    };
    ```

   Spustíme testy `npm un test`. Jeden test padá. Upravíme *expect* testu v súbore `.../ambulance-list/src/components/<pfx>-ambulance-wl-list/test/<pfx>-ambulance-wl-list.spec.tsx` na **2** a overíme, či sú všetky testy zelené.

4. Synchronizujte zmeny so vzdialeným repozitárom.

5. Následne upravíme náš editor záznamov tak, aby načítaval a ukladal zmeny do nášho REST API. Editor má byť schopný aj upraviť nové položky, preto pre neho pridáme aj špeciálnu funkcionalitu pre takýto prípad použitia a ošetríme udalosti, ktoré indikujú zmenu hodnoty záznamu, ako aj udalosti jednotlivých tlačidiel. Podobne ako v prípade zoznamu, je editor len informačným kontajnerom, a nerieši navigáciu medzi jednotlivými pohľadmi aplikácie.

   Upravte obsah súboru `.../ambulance-list/src/components/<pfx>-ambulance-wl-editor/<pfx>-ambulance-wl-editor.tsx` do nasledujúceho tvaru:

    ```tsx
    import { Component, Host, h, Prop, State, Event, EventEmitter } from '@stencil/core';
    import { AmbulanceDevelopersApi, Condition, WaitingListEntry } from '../../api';
    
    @Component({
      tag: '<pfx>-ambulance-wl-editor',
      styleUrl: '<pfx>-ambulance-wl-editor.css',
      shadow: true,
    })
    export class <Pfx>AmbulanceWlEditor {
    
      @Prop({ attribute: "entry-id"})
      entryId: string;
    
      @Prop()
      ambulance: string = "";
    
      @Event()
      wlChange: EventEmitter<WaitingListEntry>;
    
      @Event()
      canceled: EventEmitter<WaitingListEntry>;
    
      @Event()
      deleted: EventEmitter<WaitingListEntry>;
    
      @State()
      entry: WaitingListEntry;
    
      private originalSnapshot: WaitingListEntry;
    
      private ambulanceConditions: Condition[];
    
      private developerApiClient = new AmbulanceDevelopersApi();
    
      private get isNewEntry() { return !this.entryId || this.entryId === "@new"}
    
      private patientNameEl!: HTMLInputElement;
      private patientIdEl!: HTMLInputElement;
      
      async componentWillLoad() {       
        this.ambulanceConditions = await this.developerApiClient
          .getConditions(this.ambulance)
          .then( _ => _.data);
        @_empty_line_@
        if(this.isNewEntry) {
          // preinitialize new entry
          this.entry = {        
            name: "",
            patientId: "",
            waitingSince: new Date().toISOString(),
            estimatedDurationMinutes: this.ambulanceConditions[0].typicalDurationMinutes, 
            condition: this.ambulanceConditions[0]
          } as WaitingListEntry
            @_empty_line_@
        } else {
          this.entry = await this.developerApiClient
            .getWaitingListEntry(this.ambulance, this.entryId)
            .then( _ => _.data);
        }
        // keep snapshot 
        this.originalSnapshot = this.entry;
      }
    
      handleSliderInput(event: Event )
      {
          // it is necessary to update state object, not only its element to 
          // ensure component will rerender
          this.entry = {
            ...this.entry, 
            estimatedDurationMinutes: +(event.target as HTMLInputElement).value
          };
          event.stopPropagation();
      }
    
      handleDataChange() {
        this.entry = {
          ...this.entry,
          name: this.patientNameEl.value,
          patientId: this.patientIdEl.value
        };
      }
    
      handleConditionChange(ev: Event) {
        // was duration manually altered? if so keep them, otherwise reflect condition preset
        const selectedValue = (ev.target as HTMLSelectElement).value;
        const newCondition = this.ambulanceConditions.find(_ => _.code === selectedValue);
        
        const duration 
          = this.entry.condition.typicalDurationMinutes === this.entry.estimatedDurationMinutes
          ? ( newCondition.typicalDurationMinutes || this.entry.estimatedDurationMinutes)
          : this.entry.estimatedDurationMinutes;
        // update entry
        this.entry = {
          ...this.entry,
          name: this.patientNameEl.value,
          patientId: this.patientIdEl.value,
          condition: newCondition,
          estimatedDurationMinutes: duration
        };
      }
    
      async handleConfirm() {
        if(this.isNewEntry) {
          await this.developerApiClient.storeWaitingListEntry(this.ambulance, this. entry);      
        } else {
          await this.developerApiClient.updateWaitingListEntry(this.ambulance, this.entryId,  this.entry);
        }
        this.originalSnapshot = this.entry;
        this.wlChange.emit(this.entry);
      }
    
      handleCancel()
      {
        // revert changes 
        this.entry = this.originalSnapshot;
        this.canceled.emit(this.entry);
      }
    
      async handleDelete()
      {
        await this.developerApiClient.deleteWaitingListEntry(this.ambulance, this.entryId)
        this.deleted.emit(this.entry);
      }
    
      private isoDateToLocale(iso:string) {
        if(!iso) return '';
        return new Date(Date.parse(iso)).toLocaleTimeString()
      }
    
      render() {
        return (
          <Host>
            <mwc-textfield icon="person" 
                           label="Meno a Priezvisko"
                           ref={(el) => this.patientNameEl = el}
                           onChange={this.handleDataChange.bind(this)}
                           value={this.entry.name}>
            </mwc-textfield>
            <mwc-textfield icon="fingerprint" 
                           label="Registračné číslo pacienta"
                           ref={(el) => this.patientIdEl = el}
                           onChange={this.handleDataChange.bind(this)}
                           value={this.entry.patientId}>
            </mwc-textfield>
            <mwc-textfield icon="watch_later" disabled
                           label="Čakáte od" 
                           value={this.isoDateToLocale(this.entry?.waitingSince)}>
            </mwc-textfield>
            <mwc-select icon="sick" 
                        label="Dôvod návštevy"
                        onChange={this.handleConditionChange.bind(this)}>
                { this.ambulanceConditions.map(condition => 
                    <mwc-list-item value={condition.code}
                                   selected={condition.code === this.entry?.condition?.code}
                    >{condition.value}</mwc-list-item>
                )}
            </mwc-select>
            @_empty_line_@
            <div class="duration-slider">
              <span class="label">Predpokladaná doba trvania:&nbsp; </span>
              <span class="label">{this.entry.estimatedDurationMinutes}</span>
              <span class="label">&nbsp;minút</span>
              <mwc-slider discrete withTickMarks step="5" max="45"
                          value={this.entry.estimatedDurationMinutes} 
                          oninput={this.handleSliderInput.bind(this)}
                          onchange={(e) => {e.stopPropagation()}}></mwc-slider>
            </div>
            @_empty_line_@
            <div class="actions">
              <mwc-button id="delete"  icon="delete" 
                       label="Zmazať"
                       disabled={ this.isNewEntry}
                       onClick={this.handleDelete.bind(this)}>
                </mwc-button>
            <span class="stretch-fill"></span>
              <mwc-button id="cancel" 
                       label="Zrušiť"
                       onClick={this.handleCancel.bind(this)}> 
              </mwc-button>
              <mwc-button id="confirm" icon="save" 
                       label="Uložit"
                       disabled={ ! this.entry?.patientId}
                       onClick={this.handleConfirm.bind(this)}> 
              </mwc-button>
            </div>
          </Host>
        );
      } 
    }
    ```

   Vyššie uvedený kód zároveň ukazuje niektoré techniky, ako sa zaregistrovať na udalosti vložených elementov, respektíve ako
   aktualizovať stav komponentu. Ďalej upravíme obsah súboru  `.../ambulance-list/src/components/<pfx>-ambulance-wl-app/<pfx>-ambulance-wl-app.tsx`. Okrem navigácie späť na zoznam čakajúcich, pridáme aj element pre vytvorenie nového záznamu -  navigáciu na cestu `/entry/@new`.

    ```tsx
    ...
    export class <Pfx>AmbulanceWlApp {
      ...
      
      handleEntrySelection(e: CustomEvent) { 
        <Pfx>AmbulanceWlApp.Router.push(this.rebase(`/entry/${e.detail}`));
      }
      
      handleNewEntry(){ <Pfx>AmbulanceWlApp.Router.push(this.rebase(`/entry/@new`));}
 
      handleEditorClosed() {window.history.back();}
  
      render() {
        return (
          <Host>
            <<Pfx>AmbulanceWlApp.Router.Switch>
              <Route path={match(this.rebase("/entry/:id"))}
                     render={(params) => (
                       <<pfx>-ambulance-wl-editor 
                         entry-id={params.id} 
                         ambulance={this.ambulance}
                         onWlChange={this.handleEditorClosed.bind(this)}
                         onDeleted={this.handleEditorClosed.bind(this)}
                         onCanceled={this.handleEditorClosed.bind(this)}></ <pfx>-ambulance-wl-editor>
                     )} />
              <Route  path={this.rebase("/")}>
                   <<pfx>-ambulance-wl-list ambulance={this.ambulance} 
                                      onWlEntrySelected={this.handleEntrySelection.bind(this)} ></<pfx>-ambulance-wl-list>
                   <mwc-fab id="add-entry" icon="add" // << new element to create a new entry
                            onCLick={this.handleNewEntry.bind(this)}></mwc-fab>     
              </Route>
              <Route
                path={this.rebase("")} to={this.rebase("/")}>
              </Route>
            </<Pfx>AmbulanceWlApp.Router.Switch>
          </Host>
        );
      }
    ...
    ```

   Všimnite si, že navigácia po potvrdení/zrušení zmien záznamu využíva funkcionalitu `window.history.back()`, teda ja ekvivalentná stlačeniu
   tlačidla _Späť_ v aplikácii prehliadača. Týmto spôsobom máme zabezpečenú navigáciu našimi stránkami. Z pohľadu používateľa je naša aplikácia viac predvídateľná.

   Nakoniec upravte súbor `.../ambulance-list/src/components/<pfx>-ambulance-wl-app/<pfx>-ambulance-wl-app.css` do tvaru

    ```css
    :host {
     display: block;
     border-radius: 4px;
     background-color: #fff;
     background-color: var(--mdc-theme-surface, #fff);
     box-shadow: 0px 2px 1px -1px rgba(0, 0, 0, 0.2),0px 1px 1px 0px rgba(0, 0, 0, 0.14),0px  1px 3px 0px rgba(0,0,0,.12);
     margin: 0.5rem;
     padding: 0.3rem;
    }
    
    mwc-fab#add-entry {
      position: relative;
      top: -2rem;
      left: -2rem;
      float: right;
    }
    ```

   Spustite aplikáciu príkazom `npm run start` a prejdite na stránku http://localhost:3333/ambulance-wl/. Vyskúšajte vložiť, upraviť, prípadne zmazať záznam. Vzhľadom k tomu, že funkcionalita na strane servera je zatiaľ obmedzená na predpripravené návratové hodnoty zo swaggera, je správanie zjednodušené. To znamená, ze napríklad v prípade zmazania záznamu nám server vráti kód 200 (t.j. úspešné zmazanie), ale nasledovné prečítanie záznamov nám vráti pôvodné dva záznamy.

6. Overte, že testovaciu sadu možno úspešne vykonať príkazom:

    ```ps
    npm run test
    ```

   a odovzdajte vaše zmeny do archívu:

    ```ps
    git add .
    git commit -m "routing and editing"
    git push
    ```

7. Počkajte, kým sa ukončí priebežná integrácia odovzdaného kódu a flux aktualizuje verziu docker obrazu použitého v klastri. Postupne skontrolujte:
   * Prešiel CI build.
   * Bol aktualizovaný obraz na docker hube.
   * Históriu `ambulance-gitops` repozitára. Flux zmenil poslednú verziu.
   * Pod `<pfx>-ambulance-ufe-deployment` v kubernetes klastri používa danú verziu.

   V aplikácii Lens reštartujte `ufe-controller` deployment, aby sa aktualizovali verzie web komponentov.

   Otvorte aplikáciu na adrese [http://localhost:30331/ambulance-wl](http://localhost:30331/ambulance-wl). V konzole vidíte chybu naznačujúcu, že sa klient nevie pripojiť na webapi kvôli zle nastavenej CSP (Content security policy). Vytvorte súbor `.../webcloud-gitops/infrastructure/ufe-controller/configmap.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: ufe-controller
    data:
      HTTP_CSP_HEADER: default-src 'self' 'unsafe-inline' https://fonts.googleapis.com/  https://fonts.gstatic.com/; font-src 'self' https://fonts.googleapis.com/ https://fonts. gstatic.com/; script-src 'nonce-{NONCE_VALUE}'; connect-src 'self' https://virtserver. swaggerhub.com/
    ```

   Typ `ConfigMap` nám umožní vytvoriť páry kľúč-hodnota, ktoré môžeme využiť napr. ako premenné prostredia. Upravte súbor `.../webcloud-gitops/infrastructure/ufe-controller/deployment.yaml` tak, aby obsahoval nasledujúci kód:

    ```yaml
    ...
    spec:
      ...
      template: 
        ...
        spec:
          containers:
          - name: ufe-controller
            ...
            env:
              - name: BASE_URL
                value: /
              - name: HTTP_PORT
                value: "7180"
            envFrom:                                   # pridajte referenciu na premenné z  ConfigMap
              - configMapRef:
                  name:  ufe-controller
           ...
       ...
    ```

   Parameter `envFrom` spolu s parametrom `configMapRef` zabezpečí, že sa hodnoty z `ConfigMap` s menom _ufe-controller_ pretransformujú na premenné postredia v rámci daného kontajnera. Aplikácia bežiaca v kontajneri ich
   použije a v našom prípade sa prejavia ako názov aplikácie na stránke.

   Ešte v súbore `.../webcloud-gitops/infrastructure/ufe-controller/kustomization.yaml` doplňte referenciu na novo vytvorený súbor:

    ```yaml
    ...
    resources:
    - crd.yaml
    - deployment.yaml
    - service.yaml
    - configmap.yaml   # <-- pridaný súbor @_add_@
    ...
    ```

   Stiahnite zmeny zo vzdialeného repozitára, komitnite a odovzdajte svoje zmeny do repozitára príkazmi v priečinku `.../webcloud-gitops`:

    ```ps
    git pull
    git add .
    git commit -m "shell customization and webcomponent update"
    git push
    ```

   Pokiaľ máte nastavené v lokálnom klastri kontinuálne nasadenie (Flux), tak po krátkej chvíli prejdite na stránku [http://localhost:30331](http://localhost:30331). Stále vidíme iba zoznam pacientov, editor nie je prítomný, lebo konfigurácia web komponentu sa stále odkazuje na `ambulance-wl-list`. Musíme upraviť manifest pre web komponent aplikáciu v našom integrovanom prostredí mikro-aplikácii. Otvorte súbor `.../webcloud-gitops/apps/<pfx>-ambulance-ufe/webcomponent.yaml` a upravte ho do tvaru

    ```yaml
    apiVersion: fe.milung.eu/v1
    kind: WebComponent
    metadata: 
      name: <pfx>-ambulance-ufe
    spec:   
      module-uri: http://<pfx>-ambulance-ufe.wac-hospital/build/ambulance-list.esm.js
      navigation:
        - element: <pfx>-ambulance-wl-app
          path: <pfx>-ambulance-wl            
          title: Zoznam čakajúcich 
          details: Spravuje zoznam pacientov čakajúcich na vyšetrenie v ambulancii     
          attributes:                   
            - name: base-path
              value: /<pfx>-ambulance-wl/
            - name: ambulance
              value: bobulova
      preload: false                    
      proxy: true                                           
      hash-suffix: v1alpha2                        
    ```

   Ďalej doplníme konfiguráciu mikro-front-end radiča, aby bola naša zostava viac špecifická. Upravte súbor `.../webcloud-gitops/infrastructure/ufe-controller/configmap.yaml`. Do časti `data` pridajte nasledujúce tri hodnoty:

    ```yaml
    ...
    data:
      APPLICATION_TITLE: Nemocnica WAC <Pfx>
      APPLICATION_DESCRIPTION: Ukážková aplikácia pre nasadenie mikro-front-end applikácií
      APPLICATION_TITLE_SHORT: WAC <Pfx>
    ...
    ```

   Počkajte, kým Flux synchronizuje zmeny a prejdite na stránku [http://localhost:30331](http://localhost:30331). Vyskúšajte navigáciu cez jednotlivé elementy a funkčnosť aplikačnej logiky. Vyskúšajte pohyb pomocou tlačidiel _Späť_ a _Dopredu_ vo vašom prehliadači, ako aj ukladanie záložiek, prípadne ich opätovné načítanie.
   V niektorých prehliadačoch je nutné urobiť _hard reload_, aby sa zmeny prejavili.

    >info:> Pokiaľ nemáte nasadený systém flux, tak zmeny môžete aplikovať manuálne vykonaním  nasledujúcich príkazov v priečinku `.../webcloud-gitops`
    >
    > ```ps
    > kubectl config use-context docker-desktop
    > kubectl delete -k clusters/localhost
    > kubectl apply -k clusters/localhost
    > ```
