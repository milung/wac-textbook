# API pre úpravu záznamov

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-ufe-101`

---

V tejto časti budeme pokračovať v definícii API špecifikácie a úprave komponentu na editáciu záznamov, čím umožníme našim používateľom pracovať s dátami v aplikácii. Stále budeme používať len experimentálnu simuláciu WEB api.

1. Otvorte súbor `${WAC_ROOT}/ambulance-ufe/api/ambulance-wl.openapi.yaml` a do sekcie `paths` doplňte ďalšie operácie:

  ```yaml
  ...
  paths:
    "/waiting-list/{ambulanceId}/entries":
    ...
    "/waiting-list/{ambulanceId}/entries/{entryId}":       @_add_@
      get:        @_add_@
        tags:       @_add_@
          - ambulanceWaitingList       @_add_@
        summary: Provides details about waiting list entry       @_add_@
        operationId: getWaitingListEntry       @_add_@
        description: >-       @_add_@
          By using ambulanceId and entryId you can details of particular entry       @_add_@
          item ambulance.       @_add_@
        parameters:       @_add_@
          - in: path       @_add_@
            name: ambulanceId       @_add_@
            description: pass the id of the particular ambulance       @_add_@
            required: true       @_add_@
            schema:       @_add_@
              type: string       @_add_@
          - in: path       @_add_@
            name: entryId       @_add_@
            description: pass the id of the particular entry in the waiting list       @_add_@
            required: true       @_add_@
            schema:       @_add_@
              type: string       @_add_@
        responses:       @_add_@
          "200":       @_add_@
            description: value of the waiting list entries       @_add_@
            content:       @_add_@
              application/json:       @_add_@
                schema:       @_add_@
                  $ref: "#/components/schemas/WaitingListEntry"       @_add_@
                examples:       @_add_@
                  response:       @_add_@
                    $ref: "#/components/examples/WaitingListEntryExample"       @_add_@
          "404":       @_add_@
            description: Ambulance or Entry with such ID does not exists       @_add_@
      put:       @_add_@
        tags:       @_add_@
          - ambulanceWaitingList       @_add_@
        summary: Updates specific entry       @_add_@
        operationId: updateWaitingListEntry       @_add_@
        description: Use this method to update content of the waiting list entry.       @_add_@
        parameters:       @_add_@
          - in: path       @_add_@
            name: ambulanceId       @_add_@
            description: pass the id of the particular ambulance       @_add_@
            required: true       @_add_@
            schema:       @_add_@
              type: string       @_add_@
          - in: path       @_add_@
            name: entryId       @_add_@
            description: pass the id of the particular entry in the waiting list       @_add_@
            required: true       @_add_@
            schema:       @_add_@
              type: string       @_add_@
        requestBody:       @_add_@
          content:       @_add_@
            application/json:       @_add_@
              schema:       @_add_@
                $ref: "#/components/schemas/WaitingListEntry"       @_add_@
              examples:       @_add_@
                request:       @_add_@
                  $ref: "#/components/examples/WaitingListEntryExample"       @_add_@
          description: Waiting list entry to update       @_add_@
          required: true       @_add_@
        responses:       @_add_@
          "200":       @_add_@
            description: >-       @_add_@
              value of the waiting list entry with re-computed estimated time of       @_add_@
              ambulance entry       @_add_@
            content:       @_add_@
              application/json:       @_add_@
                schema:       @_add_@
                  $ref: "#/components/schemas/WaitingListEntry"       @_add_@
                examples:       @_add_@
                  response:       @_add_@
                    $ref: "#/components/examples/WaitingListEntryExample"       @_add_@
          "403":       @_add_@
            description: >-       @_add_@
              Value of the entryID and the data id is mismatching. Details are       @_add_@
              provided in the response body.       @_add_@
          "404":       @_add_@
            description: Ambulance or Entry with such ID does not exists       @_add_@
      delete:       @_add_@
        tags:       @_add_@
          - ambulanceWaitingList       @_add_@
        summary: Deletes specific entry       @_add_@
        operationId: deleteWaitingListEntry       @_add_@
        description: Use this method to delete the specific entry from the waiting list.       @_add_@
        parameters:       @_add_@
          - in: path       @_add_@
            name: ambulanceId       @_add_@
            description: pass the id of the particular ambulance       @_add_@
            required: true       @_add_@
            schema:       @_add_@
              type: string       @_add_@
          - in: path       @_add_@
            name: entryId       @_add_@
            description: pass the id of the particular entry in the waiting list       @_add_@
            required: true       @_add_@
            schema:       @_add_@
              type: string       @_add_@
        responses:       @_add_@
          "204":       @_add_@
            description: Item deleted       @_add_@
          "404":       @_add_@
            description: Ambulance or Entry with such ID does not exists       @_add_@
  ```

Pridali sme nový _endpoint_ `/waiting-list/{ambulanceId}/entries/{entryId}` pre získanie detailu záznamu, jeho aktualizáciu a vymazanie a zodpovedajúco k tomu sme nazvali aj operácie a adaptovali odozvy.  V prípade metódy `PUT` sme pridali aj `requestBody`, ktoré bude obsahovať aktualizovanú verziu záznamu, ktorý chceme aktualizovať.

Teraz v priečinku `${WAC_ROOT}/ambulance-ufe` spustite príkaz na generovanie kódu pre prístup k API:

  ```ps
    npm run openapi
  ```

2. Otvorte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-editor/<pfx>-ambulance-wl-editor.tsx` a pridajte kód, ktorý načíta záznam z API servera a ošetrí správnosť údajov:

   ```tsx
   ...
   import { AmbulanceWaitingListApiFactory, WaitingListEntry } from '../../api/ambulance-wl'; @_add_@
   ...
   export class <Pfx>AmbulanceWlEditor {

      @Prop() entryId: string;
      @Prop() ambulanceId: string; @_add_@
      @Prop() apiBase: string;  @_add_@

      @Event({eventName: "editor-closed"}) editorClosed: EventEmitter<string>;
      @State() private duration = 15;

      @State() entry: WaitingListEntry;  @_add_@
      @State() errorMessage:string;  @_add_@
      @State() isValid: boolean;  @_add_@

      private formElement: HTMLFormElement;  @_add_@

      private async getWaitingEntryAsync(): Promise<WaitingListEntry> {   @_add_@
         if ( !this.entryId ) {   @_add_@
            this.isValid = false;   @_add_@
            return undefined   @_add_@
         }   @_add_@
         try {   @_add_@
            const response  @_add_@
                = await AmbulanceWaitingListApiFactory(undefined, this.apiBase)  @_add_@
                  .getWaitingListEntry(this.ambulanceId, this.entryId)   @_add_@
             @_add_@
            if (response.status < 299) {   @_add_@
               this.entry = response.data;   @_add_@
               this.isValid = true;   @_add_@
            } else {   @_add_@
               this.errorMessage = `Cannot retrieve list of waiting patients: ${response.statusText}`   @_add_@
            }   @_add_@
         } catch (err: any) {   @_add_@
            this.errorMessage = `Cannot retrieve list of waiting patients: ${err.message || "unknown"}`   @_add_@
         }   @_add_@
         return undefined;   @_add_@
      }   @_add_@

      async componentWillLoad() {  @_add_@
         this.getWaitingEntryAsync();  @_add_@
      }  @_add_@

      ...
   ```

   Funkcionalita je obdobná ako v prípade metódy `getWaitingListAsync` v komponente `<pfx>-ambulance-wl-list`. V tomto prípade však načítame iba jeden záznam a to ten, ktorý chceme upraviť. Všimnite si, že metóda `componentWillLoad()` nepoužíva _async/await_. Dôsledkom je, že sa komponent najprv vyrenderuje - prázdny -  a polia sa vyplnia až po získaní údajov z API. Z toho dôvodu sme označili aj pole `entry` dekorátorom `@State()`. Správanie pri načítavaní zoznamu a editora tak bude mierne odlišné, v prvom prípade je UI blokované až kým sa nezískajú údaje, v druhom prípade sa UI vykreslí bez údajov a až neskôr sa doplnia údaje z API. Ani jedno riešenie nie je ideálne, náš kód by mal byť doplnený o stav `dataLoading` a počas tohto stavu by sme mali zobraziť zodpovedajúci indikátor napríklad text "Načítavam údaje...". Túto zmenu ponecháme na Vašu samostatnú prácu.

   Ďalej v súbore `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-editor/<pfx>-ambulance-wl-editor.tsx` upravíme funkciu `render()`:

   ```tsx
   ...
   render() {
      if(this.errorMessage) { @_add_@
         return ( @_add_@
         <Host> @_add_@
            <div class="error">{this.errorMessage}</div> @_add_@
         </Host> @_add_@
         ) @_add_@
      } @_add_@
      return (
         <Host>
            <form ref={el => this.formElement = el}> @_add_@
             <md-filled-text-field label="Meno a Priezvisko" 
               required value={this.entry?.name} @_add_@
               oninput={ (ev: InputEvent) => {  @_add_@
                  if(this.entry) {this.entry.name = this.handleInputEvent(ev)}  @_add_@
               } }>  @_add_@
               <md-icon slot="leading-icon">person</md-icon>
             </md-filled-text-field>

             <md-filled-text-field label="Registračné číslo pacienta" 
               required value={this.entry?.patientId} @_add_@
               oninput={ (ev: InputEvent) => { @_add_@
                  if(this.entry) {this.entry.patientId = this.handleInputEvent(ev)}  @_add_@
               } }>  @_add_@
               <md-icon slot="leading-icon">fingerprint</md-icon>
             </md-filled-text-field>

             <md-filled-text-field label="Čakáte od" disabled 
               value={this.entry?.waitingSince}> @_add_@
               <md-icon slot="leading-icon">watch_later</md-icon>
             </md-filled-text-field>

             <md-filled-select label="Dôvod návštevy" 
               value={this.entry?.condition?.code} @_add_@
               oninput = { (ev: InputEvent) => { @_add_@
                  if(this.entry) {this.entry.condition.code = this.handleInputEvent(ev)} @_add_@
               } }>  @_add_@
               <md-icon slot="leading-icon">sick</md-icon>
               <md-select-option value="folowup">
                 <div slot="headline">Kontrola</div>
               </md-select-option>
               <md-select-option value="nausea">
                 <div slot="headline">Nevoľnosť</div>
               </md-select-option>
               <md-select-option value="fever">
                 <div slot="headline">Horúčka</div>
               </md-select-option>
               <md-select-option value="ache-in-throat">
                 <div slot="headline">Bolesti hrdla</div>
               </md-select-option>
             </md-filled-select>
           </form> @_add_@

           <div class="duration-slider">
             <span class="label">Predpokladaná doba trvania:&nbsp; </span>
             <span class="label">{this.duration}</span>
             <span class="label">&nbsp;minút</span>
             <md-slider
               min="2" max="45" value={this.entry?.estimatedDurationMinutes || 15} ticks labeled @_add_@
               oninput={ (ev:InputEvent) => { @_add_@
                 if(this.entry) { @_add_@
                  this.entry.estimatedDurationMinutes  @_add_@
                     = Number.parseInt(this.handleInputEvent(ev))}; @_add_@
                 this.handleSliderInput(ev) @_add_@
               } }></md-slider> @_add_@
           </div>

           <md-divider inset></md-divider>

           <div class="actions">
             <md-filled-tonal-button id="delete" disabled={ !this.entry }  @_important_@
               onClick={() => this.deleteEntry()} >  @_important_@
               <md-icon slot="icon">delete</md-icon>
               Zmazať
             </md-filled-tonal-button>
             <span class="stretch-fill"></span>
             <md-outlined-button id="cancel"
               onClick={() => this.editorClosed.emit("cancel")}>
               Zrušiť
             </md-outlined-button>
             <md-filled-button id="confirm" disabled={ !this.isValid }  @_important_@
               onClick={() => this.updateEntry() }  @_important_@
               >
               <md-icon slot="icon">save</md-icon>
               Uložiť
             </md-filled-button>
           </div>
         </Host>
       );
   }  
   ```

   Pri tejto zmene sme nastavili hodnoty jednotlivých vstupných polí a upravili reakcie na zmenu hodnôt. Tlačidlá `Zmazať` a `Uložiť` sú aktívne iba vtedy, ak je záznam načítaný a je platný. Všimnite si, ako sme pomocou atribútu `ref` získali referenciu na element `form`. Doplníme teraz metódy pre obsluhu udalostí, ktoré sme použili v metóde `render()`:

   ```tsx
   ...
   render() {
      ...
   }
   
   private handleInputEvent( ev: InputEvent): string {  @_add_@
      const target = ev.target as HTMLInputElement;  @_add_@
      // check validity of elements  @_add_@
      this.isValid = true;  @_add_@
      for (let i = 0; i < this.formElement.children.length; i++) {  @_add_@
         const element = this.formElement.children[i]  @_add_@
         if ("reportValidity" in element) {  @_add_@
         const valid = (element as HTMLInputElement).reportValidity();  @_add_@
         this.isValid &&= valid;  @_add_@
         }  @_add_@
      }  @_add_@
      return target.value  @_add_@
   }  @_add_@

   private async updateEntry() {      @_add_@
      try {  @_add_@
          const response = await AmbulanceWaitingListApiFactory(undefined, this.apiBase) @_add_@
            .updateWaitingListEntry(this.ambulanceId, this.entryId, this.entry)  @_add_@
          if (response.status < 299) {  @_add_@
            this.editorClosed.emit("store")  @_add_@
          } else {  @_add_@
            this.errorMessage = `Cannot store entry: ${response.statusText}`  @_add_@
          }  @_add_@
        } catch (err: any) {  @_add_@
          this.errorMessage = `Cannot store entry: ${err.message || "unknown"}`  @_add_@
        }        @_add_@
    }  @_add_@

   private async deleteEntry() { @_add_@
      try { @_add_@
         const response = await AmbulanceWaitingListApiFactory(undefined, this.apiBase) @_add_@
            .deleteWaitingListEntry(this.ambulanceId, this.entryId) @_add_@
         if (response.status < 299) { @_add_@
         this.editorClosed.emit("delete") @_add_@
         } else { @_add_@
         this.errorMessage = `Cannot delete entry: ${response.statusText}` @_add_@
         } @_add_@
      } catch (err: any) { @_add_@
         this.errorMessage = `Cannot delete entry: ${err.message || "unknown"}` @_add_@
      } @_add_@
   } @_add_@

   ```

   V metóde `handleInputEvent()` sme doplnili kontrolu platnosti jednotlivých vstupných polí. K tomu sme využili metódu [`reportValidity()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/reportValidity), ktorá skontroluje nastavené ohraničenia na našom elemente a v prípade neplatnej hodnoty zobrazí pri elemente chybové hlásenie. Táto metóda zároveň uloží aktuálnu hodnotu do objektu `entry`.

   Metódy `updateEntry()` a `deleteEntry()` volajú príslušné metódy z API klienta.

3. Upravte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-editor/<pfx>-ambulance-wl-editor.css` a upravte štýly komponentu do podoby:

   ```css
   :host {
      --_wl-editor_gap: var(--wl-gap, 0.5rem);
      width: 100%;  @_add_@
      height: 100%;  @_add_@

      display: flex;  @_remove_@
      flex-direction: column;  @_remove_@
      gap: var(--_wl-editor_gap);  @_remove_@
      padding: var(--_wl_editor_gap);  @_remove_@
   }

   form{  @_add_@
      display: flex;  @_add_@
      flex-direction: column;    @_add_@
      gap: var(--_wl-editor_gap);  @_add_@
      padding: var(--_wl-editor_gap);  @_add_@
      }  @_add_@

   .error {  @_add_@
      margin: auto;  @_add_@
      color: red;  @_add_@
      font-size: 2rem;  @_add_@
      font-weight: 900;  @_add_@
      text-align: center;  @_add_@
      }  @_add_@

   .duration-slider {
      ...
   ```

4. Upravte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-app/<pfx>-ambulance-wl-app.tsx`, vo funkcii `render()` doplňte atribúty pre element `<pfx>--ambulance-wl-editor`:

   ```tsx
   ...
   render() {
      ...
      return (
         { element === "editor" 
         ? <<pfx>-ambulance-wl-editor entry-id={entryId}
            ambulance-id={this.ambulanceId} api-base={this.apiBase} @_add_@
            oneditor-closed={ () => navigate("./list")}
         ></<pfx>-ambulance-wl-editor>
         : <<pfx>-ambulance-wl-list  ambulance-id={this.ambulanceId} api-base={this.apiBase}
            onentry-clicked={ (ev: CustomEvent<string>)=> navigate("./entry/" + ev.detail) } >
            </<pfx>-ambulance-wl-list>
         }
         </Host>
         );
   ...
   }
   ```

5. Poslednú úpravu vykonáme v súbore `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-list/<pfx>-ambulance-wl-list.tsx` a to takú, že nastavíme správne id pri výbere položky zoznamu:

   ```tsx
   ...
   render() {
      ...
      {this.waitingPatients.map((patient) => @_important_@
        <md-list-item onClick={ () => this.entryClicked.emit(patient.id)}> @_important_@
          <div slot="headline">{patient.name}</div>
          <div slot="supporting-text">{"Predpokladaný vstup: " + this.isoDateToLocale(patient.estimatedStart)}</div>
            <md-icon slot="start">person</md-icon>
        </md-list-item>
      ...
   ```

6. V priečinku `${WAC_ROOT}/ambulance-ufe` naštartujte vývojový server príkazom:

   ```ps
   npm run start
   ```

   a v prehliadači prejdite na stránku [http://localhost:3333](http://localhost:3333) a overte funkcionalitu. Stále používame len simulované údaje, preto sa naše údaje po obnove nemenia a pri výbere položky vidíme len ukážkový záznam. V prehliadači otvorte _Nástroje pre vývojárov_/_Developer tools_ (_F12_) a prejdite do záložky _Sieť_/_Network_ a sledujte komunikáciu s API serverom.

7. Zostáva nám ešte vyriešiť načítanie zoznamu možných problémov - `conditions` pre rozbaľovací zoznam a vytvorenie nového záznamu. Opäť začneme úpravou API špecifikácie v súbore `${WAC_ROOT}/ambulance-ufe/api/ambulance-wl.openapi.yaml`. Do hlavnej sekcie `tags` doplňte nasledujúci záznam:

  ```yaml
  ...
  tags:
    - name: ambulanceWaitingList
      description: Ambulance Waiting List API
    - name: ambulanceConditions @_add_@
      description: Patient conditions and symptoms handled in the ambulance @_add_@
  ...
  ```

  a v sekcii `paths` doplňte nasledujúce operácie:

  ```yaml
  ...
  paths:
    "/waiting-list/{ambulanceId}/entries":
      get:
        ...
      post:  @_add_@
        tags: @_add_@
          - ambulanceWaitingList  @_add_@
        summary: Saves new entry into waiting list @_add_@
        operationId: createWaitingListEntry @_add_@
        description: Use this method to store new entry into the waiting list. @_add_@
        parameters: @_add_@
          - in: path @_add_@
            name: ambulanceId @_add_@
            description: pass the id of the particular ambulance @_add_@
            required: true @_add_@
            schema: @_add_@
              type: string @_add_@
        requestBody: @_add_@
          content: @_add_@
            application/json: @_add_@
              schema: @_add_@
                $ref: "#/components/schemas/WaitingListEntry" @_add_@
              examples: @_add_@
                request-sample:  @_add_@
                  $ref: "#/components/examples/WaitingListEntryExample" @_add_@
          description: Waiting list entry to store @_add_@
          required: true @_add_@
        responses: @_add_@
          "200": @_add_@
            description: >- @_add_@
              Value of the waiting list entry with re-computed estimated time of @_add_@
              ambulance entry @_add_@
            content: @_add_@
              application/json: @_add_@
                schema: @_add_@
                  $ref: "#/components/schemas/WaitingListEntry" @_add_@
                examples: @_add_@
                  updated-response:  @_add_@
                    $ref: "#/components/examples/WaitingListEntryExample" @_add_@
          "400": @_add_@
            description: Missing mandatory properties of input object. @_add_@
          "404": @_add_@
            description: Ambulance with such ID does not exists @_add_@
          "409": @_add_@
            description: Entry with the specified id already exists @_add_@
    "/waiting-list/{ambulanceId}/entries/{entryId}":
      ...
    "/waiting-list/{ambulanceId}/condition": @_add_@
      get: @_add_@
        tags: @_add_@
          - ambulanceConditions @_add_@
        summary: Provides the list of conditions associated with ambulance @_add_@
        operationId: getConditions @_add_@
        description: By using ambulanceId you get list of predefined conditions @_add_@
        parameters: @_add_@
          - in: path @_add_@
            name: ambulanceId @_add_@
            description: pass the id of the particular ambulance @_add_@
            required: true @_add_@
            schema: @_add_@
              type: string @_add_@
        responses: @_add_@
          "200": @_add_@
            description: value of the predefined conditions @_add_@
            content: @_add_@
              application/json: @_add_@
                schema: @_add_@
                  type: array @_add_@
                  items: @_add_@
                    $ref: "#/components/schemas/Condition" @_add_@
                examples: @_add_@
                  response: @_add_@
                    $ref: "#/components/examples/ConditionsListExample" @_add_@
          "404": @_add_@
            description: Ambulance with such ID does not exists   @_add_@
  ...
  ```

   V prípade operácie `GET` pre nový endpoint `/waiting-list/{ambulanceId}/condition`, ktorý vráti zoznam možných problémov, sme použili nový tag `ambulanceConditions`. To bude mať za následok vygenerovanie novej triedy a [_factory_ funkcie](https://en.wikipedia.org/wiki/Factory_method_pattern). Nakoniec doplníme nový príklad odozvy `ConditionsListExample`:

  ```yaml
  ...
  components:
    schemas:
    ...
    examples:
      ...
      ConditionsListExample:  @_add_@
        summary: Sample of GP ambulance conditions  @_add_@
        description: |  @_add_@
          Example list of possible conditions, symptoms, and visit reasons  @_add_@
        value:  @_add_@
          - value: Teploty  @_add_@
            code: subfebrilia  @_add_@
            reference: "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/"  @_add_@
            typicalDurationMinutes: 20  @_add_@
          - value: Nevoľnosť  @_add_@
            code: nausea  @_add_@
            reference: "https://zdravoteka.sk/priznaky/nevolnost/"  @_add_@
            typicalDurationMinutes: 45  @_add_@
          - value: Kontrola  @_add_@
            code: followup  @_add_@
            typicalDurationMinutes: 15  @_add_@
          - value: Administratívny úkon  @_add_@
            code: administration  @_add_@
            typicalDurationMinutes: 10  @_add_@
          - value: Odber krvi  @_add_@
            code: blood-test  @_add_@
            typicalDurationMinutes: 10  @_add_@
  ```

8. Uložte zmeny a v priečinku  `${WAC_ROOT}/ambulance-ufe` vykonajte príkaz:

   ```ps
   npm run openapi
   ```

9. Aby sme v editore odlíšili vytváranie nového záznamu od úpravy existujúceho záznamu, budeme používať špeciálne vyhradené id `@new`. Upravte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-editor/<pfx>-ambulance-wl-editor.tsx`:

   ```tsx
   ...
   export class <Pfx>AmbulanceWlEditor {
      ...
      private async getWaitingEntryAsync(): Promise<WaitingListEntry> {
         if(this.entryId === "@new") {  @_add_@
            this.isValid = false;  @_add_@
            this.entry = {  @_add_@
              id: "@new",  @_add_@
              patientId: "",  @_add_@
              waitingSince: "",  @_add_@
              estimatedDurationMinutes: 15  @_add_@
            };  @_add_@
            return this.entry;  @_add_@
          }  @_add_@
         ...
      }

      render() {
         ...
          <md-filled-tonal-button id="delete" disabled={!this.entry || this.entry?.id === "@new" } @_important_@
         ...
      }

      private async updateEntry() {
         try {
            const response = await AmbulanceWaitingListApiFactory(undefined, this.apiBase) @_remove_@
               .updateWaitingListEntry(this.ambulanceId, this.entryId, this.entry)  @_remove_@
            // store or update
            const api = AmbulanceWaitingListApiFactory(undefined, this.apiBase);  @_add_@
            const response   @_add_@
               = this.entryId === "@new"   @_add_@
               ? await api.createWaitingListEntry(this.ambulanceId, this.entry)  @_add_@
               : await api.updateWaitingListEntry(this.ambulanceId, this.entryId, this.entry);  @_add_@
            ...
      }
      ...
   ```

   V tejto verzii pokiaľ zistíme, že `entryId` parameter je nastavený na hodnotu `@new`, tak namiesto načítania  `entry` z API vytvoríme nový záznam a pri ukladaní záznamu použijeme zodpovedajúcu metódu nášho API klienta. Tlačidlo `delete` bude zakázané pre scenár vytvárania nového záznamu.

   Teraz upravte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-list/<pfx>-ambulance-wl-list.tsx` a doplňte do neho ovládací prvok pre vytvorenie nového záznamu:

   ```tsx
   ...
   render() {
    return (
      <Host>
        {this.errorMessage
          ...
        }
        <md-filled-icon-button class="add-button"  @_add_@
          onclick={() => this.entryClicked.emit("@new")}>  @_add_@
          <md-icon>add</md-icon>  @_add_@
        </md-filled-icon-button>  @_add_@
      </Host>
      );
   }
   ```

   Použili sme nový element z knižnice `@material/web`, doplňte preto do súboru `${WAC_ROOT}/ambulance-ufe/src/global/app.ts`:

   ```tsx
   import '@material/web/iconbutton/filled-icon-button' @_add_@
   ...
   ```

   Ešte upravíme štýl pre nový element v súbore `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-list/<pfx>-ambulance-wl-list.css`:

  ```css
  :host {
    display: block;
    width: 100%;
    height: 100%;  
    position: relative; @_add_@
    padding-bottom: 2rem; @_add_@
  }

  .error {
    ...
  }

  .add-button {  @_add_@
    position: absolute;  @_add_@
    right: 1rem;  @_add_@
    bottom: 0;  @_add_@
    --md-filled-icon-button-container-size: 4rem;  @_add_@
    --md-filled-icon-button-icon-size: 3rem;  @_add_@
  }  @_add_@
  ```

   Tlačidlo _+_ je umiestnené naspodku vpravo nášho elementu. Pretože používame pozíciu `absolute`, musíme nastaviť aj `position` na `relative` pre element `<pfx>-ambulance-wl-list`, ináč by sa pozícia tlačidla upravovala vzhľadom k pozícii a veľkosti stránky alebo vzhľadom k pozícii najbližšieho iného predka, ktorého pozícia by bola relatívna.

   Funkcionalitu môžete overiť, mali by ste vidieť zoznam s tlačidlom _+_ a po kliknutí na tlačidlo by sa mal zobraziť editor pre vytvorenie nového záznamu.

   ![Zoznam s tlačidlom pridania nového záznamu](./img/102-01-AddEntry.png)

10. Zoznam príčin návštevy je zatiaľ statický, pričom chceme dosiahnuť, aby sme mali špecifický zoznam pre každú ambulanciu. Otvorte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-editor/<pfx>-ambulance-wl-editor.tsx` a upravte ho:

    ```tsx
    import { AmbulanceConditionsApiFactory, AmbulanceWaitingListApiFactory, Condition, WaitingListEntry } from '../../api/ambulance-wl'; @_important_@
    ...
    export class <Pfx>AmbulanceWlEditor {  
      ... 
      @State() entry: WaitingListEntry;
      @State() conditions: Condition[];  @_add_@
      ...

      private async getWaitingEntryAsync(): Promise<WaitingListEntry> {
         ...
      }

      private async getConditions(): Promise<Condition[]> {  @_add_@
         try {  @_add_@
            const response = await AmbulanceConditionsApiFactory(undefined, this.apiBase).getConditions(this.ambulanceId);  @_add_@
            if (response.status < 299) {  @_add_@
            this.conditions = response.data;  @_add_@
            }  @_add_@
         } catch (err: any) {  @_add_@
            // no strong dependency on conditions  @_add_@
         }  @_add_@
         // always have some fallback condition  @_add_@
         return this.conditions || [{  @_add_@
            code: "fallback",  @_add_@
            value: "Neurčený dôvod návštevy",  @_add_@
            typicalDurationMinutes: 15,  @_add_@
         }];  @_add_@
      }  @_add_@

      componentWillLoad() {
         this.getWaitingEntryAsync();
         this.getConditions(); @_add_@
      }  
    ```

    Doplnili sme načítanie zoznamu príčin návštevy ambulancie. V prípade, že sa nám načítanie nepodarí, použijeme fallback hodnotu, ktorá je pre bežné fungovanie ambulanice stále dostačujúca. Upravíme teraz spôsob zobrazenia zoznamu príčin návštevy v súbore `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-editor/<pfx>-ambulance-wl-editor.tsx`:

    ```tsx
    ...
    render() {
      ....
      return (
          ....
          <md-filled-select label="Dôvod návštevy"  @_remove_@
               ... @_remove_@
          </md-filled-select> @_remove_@
          <!-- pre prehľadnosť použijeme pomocnú metódu -->
          {this.renderConditions()} @_add_@
        </form>
       ...
      );
    }

    private renderConditions() {   @_add_@
      let conditions = this.conditions || [];   @_add_@
      // we want to have this.entry`s condition in the selection list   @_add_@
      if (this.entry?.condition) {   @_add_@
        const index = conditions.findIndex(condition => condition.code === this.entry.condition.code)   @_add_@
        if (index < 0) {   @_add_@
        conditions = [this.entry.condition, ...conditions]   @_add_@
        }   @_add_@
      }   @_add_@
      return (   @_add_@
        <md-filled-select label="Dôvod návštevy"   @_add_@
          display-text={this.entry?.condition?.value}   @_add_@
          oninput={(ev: InputEvent) => this.handleCondition(ev)} >   @_add_@
        <md-icon slot="leading-icon">sick</md-icon>   @_add_@
        {this.entry?.condition?.reference ? @_add_@
          <md-icon slot="trailing-icon" class="link"   @_add_@
            onclick={()=> window.open(this.entry.condition.reference, "_blank")}>   @_add_@
              open_in_new   @_add_@
          </md-icon>   @_add_@
        : undefined   @_add_@
        }   @_add_@
        {conditions.map(condition => {   @_add_@
            return (   @_add_@
              <md-select-option   @_add_@
              value={condition.code} @_add_@
              selected={condition.code === this.entry?.condition?.code}> @_add_@
                  <div slot="headline">{condition.value}</div> @_add_@
              </md-select-option> @_add_@
            )   @_add_@
        })}   @_add_@
        </md-filled-select>   @_add_@
      );   @_add_@
    } @_add_@
    

    private handleCondition(ev: InputEvent) {  @_add_@
      if(this.entry) {  @_add_@
        const code = this.handleInputEvent(ev)   @_add_@
        const condition = this.conditions.find(condition => condition.code === code);   @_add_@
        this.entry.condition = Object.assign({}, condition);   @_add_@
        this.entry.estimatedDurationMinutes = condition.typicalDurationMinutes;   @_add_@
        this.duration = condition.typicalDurationMinutes;   @_add_@
      }  @_add_@
    }  @_add_@
    ```

    Vykreslovanie a ovládanie zoznamu príčin návštevy sme presunuli do samostatnej metódy. V metóde `renderConditions()` sme najprv zistili, či máme v zozname príčin návštevy aj príčinu návštevy aktuálneho záznamu. Ak nie, pridáme ju na začiatok zoznamu. Potom vykreslíme zoznam príčin návštevy a nastavíme aktuálnu hodnotu záznamu ako vybratú. V metóde `handleCondition()` sme zabezpečili, aby sa pri výbere špecifickej príčiny aj náležite upravila hodnota predpokladaného trvania návštevy. Túto dobu potom môže používateľ ďalej upravovať. Navyše sme umožnili používateľovi, aby sa pred samotnou návštevou oboznámil s opisom príčiny návštevy. Preto sme pridali ikonku `open_in_new`, ktorá otvorí nové okno s popisom príčiny návštevy.  Efektom tohto prvku môže byť napríklad to, že pacient pri vstupe bude už predbežne poučený o tom, čo môže očakávať a celé vyšetrenie môže prebehnúť efektívnejšie.

11. Overte funkcionalitu. Pokiaľ Váš vývojový server nebeží, vykonajte v priečinku `${WAC_ROOT}/ambulance-ufe` príkaz 

    ```ps
    npm run start
    ```

    a otvorte v prehliadači stránku [http://localhost:3333](http://localhost:3333). Majte na pamäti, že stále používame len simuláciu WEB API.

12. Rozšírime testy editora o jednoduchý test správnosti poľa _Meno a Priezvisko_. Otvorte súbor `${WAC_ROOT}/ambulance-ufe/src/components/<pfx>-ambulance-wl-editor/test/<pfx>-ambulance-wl-editor.spec.tsx` a upravte ho:

    ```tsx
    import { newSpecPage } from '@stencil/core/testing';
    import { <Pfx>AmbulanceWlEditor } from '../<pfx>-ambulance-wl-editor'; 
    import axios from "axios";  @_add_@
    import MockAdapter from "axios-mock-adapter";  @_add_@
    import { Condition, WaitingListEntry } from '../../../api/ambulance-wl';  @_add_@

    describe('<pfx>-ambulance-wl-editor', () => { 
      const sampleEntry: WaitingListEntry = {  @_add_@
         id: "entry-1",  @_add_@
         patientId: "p-1",  @_add_@
         name: "Juraj Prvý",  @_add_@
         waitingSince: "20240203T12:00",  @_add_@
         estimatedDurationMinutes: 20,  @_add_@
         condition: {  @_add_@
            "value": "Nevoľnosť",  @_add_@
            "code": "nausea",  @_add_@
            "reference": "https://zdravoteka.sk/priznaky/nevolnost/"  @_add_@
         }  @_add_@
      };  @_add_@
      @_add_@
      const sampleConditions: Condition[] = [  @_add_@
         {  @_add_@
            "value": "Teploty",  @_add_@
            "code": "subfebrilia",  @_add_@
            "reference": "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/",  @_add_@
            "typicalDurationMinutes": 20  @_add_@
         },  @_add_@
         {  @_add_@
            "value": "Nevoľnosť",  @_add_@
            "code": "nausea",  @_add_@
            "reference": "https://zdravoteka.sk/priznaky/nevolnost/",  @_add_@
            "typicalDurationMinutes": 45  @_add_@
         },  @_add_@
      ];  @_add_@
      @_add_@
      let delay = async (miliseconds: number) => await new Promise<void>(resolve => {  @_add_@
            setTimeout(() => resolve(), miliseconds);  @_add_@
      })  @_add_@
       @_add_@
      let mock: MockAdapter;  @_add_@
      @_add_@
      beforeAll(() => { mock = new MockAdapter(axios); });  @_add_@
      afterEach(() => { mock.reset(); });  @_add_@

      it('buttons shall be of different type', async () => {
         mock.onGet(/^.*\/entries\/.+/).reply(200, sampleEntry);  @_add_@
         mock.onGet(/^.*\/condition$/).reply(200, sampleConditions);  @_add_@

         const page = await newSpecPage({
            components: [<Pfx>AmbulanceWlEditor], 
            html: `<<pfx>-ambulance-wl-editor entry-id="test-entry"   @_important_@
               ambulance-id="test-ambulance" api-base="http://sample.test/api">  @_important_@
            </<pfx>-ambulance-wl-editor>`,  @_important_@
         });
         await delay(300); @_add_@
         await page.waitForChanges(); @_add_@
         let items: any = await page.root.shadowRoot.querySelectorAll("md-filled-button");
         expect(items.length).toEqual(1);
         ...
      });

      it('first text field is patient name', async () => {           @_add_@
         mock.onGet(/^.*\/entries\/.+/).reply(200, sampleEntry);  @_add_@
         mock.onGet(/^.*\/condition$/).reply(200, sampleConditions);  @_add_@
         @_add_@
         const page = await newSpecPage({  @_add_@
            components: [PfxAmbulanceWlEditor],  @_add_@
            html: `<<pfx>-ambulance-wl-editor entry-id="test-entry" ambulance-id="test-ambulance" api-base="http://sample.test/api"></<pfx>-ambulance-wl-editor>`,  @_add_@
         });  @_add_@
         let items: any = await page.root.shadowRoot.querySelectorAll("md-filled-text-field");  @_add_@
         @_add_@
         await delay(300);  @_add_@
         await page.waitForChanges();  @_add_@
           @_add_@
         expect(items.length).toBeGreaterThanOrEqual(1);  @_add_@
         expect(items[0].getAttribute("value")).toEqual(sampleEntry.name);  @_add_@
      });  @_add_@

    });
    ```

    V tomto prípade simulujeme odozvy z dvoch rôznych _endpoint_-ov, preto pri volaní metódy `onGet()` používame regulárny výraz aby sme jednotlivé požiadavky odlíšili. Taktiež v tomto prípade musíme predpokladať, že pri úvodnom vykreslení po zavolaní funkcie `newSpecPage` ešte nebolo ukončené asynchrónne načítanie údajov. Volaním `await delay(300)` umožníme, aby sa asynchrónne volanie zrealizovalo a spracovalo, následne volaním `await page.waitForChanges()` zabezpečíme, že sa vykonajú všetky potrebné aktualizácie elementov a následne overíme výsledný stav. Obdobne ako v predchádzajúcich prípadoch uvádzame iba príklad testu, vypracovanie ďalších testov ponecháme na Vašu samostatnú prácu.

    Overte funkčnosť testov vykonaním príkazu:

    ```ps
    npm run test
    ```

13. Archivujte zmeny kód:

    ```ps
    git add .
    git commit -m "Ambulance waiting list CRUD operations"
    git push
    ```
