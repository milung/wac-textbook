## Integrácia web služby s používateľským web rozhraním

V tejto chvíli máme vytvorenú web aplikáciu v [_Angular 11_](https://angular.io/),
a zároveň web službu v [ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/?view=aspnetcore-2.2).
Pred samotným nasadením web služby potrebujeme ešte overiť funkcionalitu pri spojení
s používateľským rozhraním a zároveň toto rozhranie upraviť tak, aby web službu aj
skutočne využívalo.

1. Pre prepojenie web aplikácie s web službou musíme najprv nakonfigurovať akým
   spôsobom sa bude web aplikácia pripájať k web službe. V prípade Angular aplikácie
   sa konfigurácia realizuje prostredníctvom súborov
   `ambulance-spa\src\environments\environment.<verzia>.ts`. Počas kompilácie potom
   môžme určiť, ktorá verzia - ktoré prostredie - sa má použiť.

   Upravte objekt `environment` v súbore `ambulance-spa\src\environments\environment.ts`:

    ```ts
    export const environment = {
        production: false,
        apiBaseUrl: '/api',
        ambulanceId: 'practitioner-bobulova'
    };
    ```

    Toto nastavenie predpokladá, že naša web služba je umiestnená na tom istom
    serveri ako web aplikácia pod cestou `/api`. Počas vývoja ale bude obsluhovaná
    iným serverom, na inom porte ako angular aplikácia. Vytvoríme si preto pomocnú
    konfiguráciu proxy, ktorá sa bude používať počas vývoja. Vytvorte súbor `ambulance-spa\proxy.config.json`
    s nasledovným obsahom:

    ```ts
    {
       "/api": {
            "target": "http://127.0.0.1:8080",
            "pathRewrite" : {"^/api" : "/api" },
            "secure": false
        }
    }
    ```

    V súbore `package.json` upravte skript na rozbehnutie vývojového servera, tak
    aby používal našu konfiguráciu proxy:

    ```json
     "start": "ng serve --proxy-config proxy.config.json",
    ```

2. V príkazovom riadku zastavte server `ambulance-api` a `ambulance-api.tests`,
   pokiaľ ešte bežia.

    Odstráňte súbor `ambulance-api\data-repository.litedb`. V príkazovom riadku,
    v priečinku `ambulance-api` znovu vykonajte príkaz

    ```powershell
    dotnet watch run
    ```

    V aplikácii _Postman_ odošlite _Post_ požiadavku na URL `http://localhost:8080/api/waiting-list/practitioner-bobulova`
    s nasledujúcim obsahom

    ```json
    {
        "id": "practitioner-bobulova",
        "name": "Ambulancia všeobecného lekára Dr. Bobulová",
        "roomNumber": "211 - 2.posch",
        "predefinedConditions": [{
            "code": "folowup",
            "value": "Kontrola",
            "typicalDurationMinutes": 15
        }, {
            "code": "nausea",
            "value": "Nevoľnosť",
            "typicalDurationMinutes": 45,
            "reference": "https://zdravoteka.sk/priznaky/nevolnost/"
        }, {
            "code": "fever",
            "value": "Teploty",
            "typicalDurationMinutes": 20,
            "reference": "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/"
        }, {
            "code": "ache-in-throat",
            "value": "Bolesti hrdla",  
            "typicalDurationMinutes": 20,
            "reference": "https://zdravoteka.sk/priznaky/bolest-pri-prehltani/"
        }]
    }
    ```

3. Do súboru `ambulance-spa\src\app\app.module.ts` doplňte použitie `HttpClientModule`:

    ```ts
    ....
    import { HttpClientModule } from '@angular/common/http';

    @NgModule({
    declarations: [ ... ],
    imports: [ BrowserModule, HttpClientModule, ...
    ...
    ```

   Upravte kód v súbore `ambulance-spa\src\app\services\ambulance-patients-list.service.ts`
   tak, aby využíval reálnu web službu pomocou asynchrónnej HTTP komunikácie:

    ```ts
    import { Injectable } from '@angular/core';
    import { WaitingEntryModel } from '../store/waiting-entry-model/waiting-entry-model.model';
    import { Observable, of } from 'rxjs';
    import { HttpClient } from '@angular/common/http';
    import { map, catchError } from 'rxjs/operators';
    import { environment } from 'src/environments/environment';

    @Injectable({ providedIn: 'root' })
    export class AmbulancePatientsListService {

      public constructor(private httpClient: HttpClient) { }

      private get baseUrl() {
        const baseUrl = environment.apiBaseUrl || '/api';
        const ambulance = environment.ambulanceId || 'ambulance';
        return `${baseUrl}/waiting-list/${ambulance}`;
      }

      /** retrieves list of all patients currently waiting at ambulance
       *
       * @returns observable with one item of the list
       */
      public getAllPatientsEntries(): Observable<WaitingEntryModel[]> {
        return this.httpClient
          .get(this.baseUrl)
          .pipe(map(response => (response as any).waitingList as Array<WaitingEntryModel>));
      }

      /** updates or inserts new entry in the waiting list
       *
       * @param entry - new or updates entry
       *
       * @returns observable of the entry after it is updated at the server
       */
      public upsertEntry(entry: WaitingEntryModel): Observable<WaitingEntryModel> {
        entry = Object.assign({}, entry); // create clone to avoid mutation of input

        let url = `${this.baseUrl}/entry`;
        if (entry.id) {
            url =  `${url}/${entry.id}`;
        } else {
            entry.id = 'new-entry'; // entry.id is Required
        }

        return this.httpClient
            .post(url, entry)
            .pipe(map(response => response as WaitingEntryModel));
      }

      /** removes an entry from the waiting list
       *
       * @param entryId - id of entry to delete
       *
       * @returns observable referring to existence of item in the list before
       *          its removal
       */
      public deleteEntry(entryId: string): Observable<boolean> {
        return this.httpClient
          .delete(`${this.baseUrl}/entry/${entryId}`)
          .pipe(
            map(_ => true),
            catchError(err => {
              if (err.error instanceof Error) {
                console.error(`Error deleting entry ${entryId}: ${err.error.message}`);
              } else {
                console.error(`Error deleting entry ${entryId}: ${err.status}: ${err.error}`);
              }
              return of(false);
            }));
      }

      /** list of predefined ambulance visits reasons and associated typical
       *  visit times
       *
       * @returns observable of predefined reasons
       */
      public getWaitingReasons(): Observable<Array<{
        value: string,
        code: string,
        typicalDurationMinutes: number,
        reference: string
      }>> {
        return this.httpClient
          .get(this.baseUrl)
          .pipe(map(response => (response as any).predefinedConditions as Array<{
            value: string,
            code: string,
            typicalDurationMinutes: number,
            reference: string}>));
      }
    }
    ```

   V predchádzajúcom súbore sme vykonali dve dôležité zmeny - vynechali sme parameter
   `ambulanceId` a zmenili sme typ `condition`. Takéto drobné úpravy sú v
   počiatočných fázach vývoja bežné. Zmeňte volania služby v súbore `ambulance-spa\src\app\effects\app.effects.ts`

    ```ts
    ...
    mergeMap(_ => this.patientListService.getAllPatientsEntries()),
    ...
    mergeMap((action) =>
      this.patientListService.upsertEntry(action.waitingEntryModel)),
    ...
    mergeMap((action) =>
      this.patientListService.deleteEntry(action.id))),
    ...
    ```

4. Produkčný kód máme teraz kompilovateľný. V tejto chvíli ešte aplikácia
   nie je funkčná, čo si môžete overiť. Dôvodom je, že model na frontedne a
   backende je rozdielny.

   Zadefinujte interface `Condition` a upravte deklaráciu typu `WaitingEntryModel` v súbore `ambulance-spa\src\app\store\waiting-entry-model\waiting-entry-model.model.ts`

      ```ts
      export interface Condition {
        value: string,
        code: string,
        typicalDurationMinutes: number,
        reference: string
      };

      export interface WaitingEntryModel {
        id: string | undefined;
        name: string;
        patientId: string;
        waitingSince: Date;
        estimatedStart: Date;
        estimatedDurationMinutes: number;
        condition: Condition;
      }
      ```

    Vo funkcii `getWaitingReasons` v súbore `ambulance-spa\src\app\services\ambulance-patients-list.service.ts`
    využijeme nový `Condition` interface:
    ```ts
    ...
    public getWaitingReasons(): Observable<Array<Condition>> {
      return this.httpClient
        .get(this.baseUrl)
        .pipe(map(response => (response as any).predefinedConditions as Array<Condition>));
    }
    ...
    ```

    V súbore `ambulance-spa\src\app\waiting-entry-editor\waiting-entry-editor.component.ts`
    upravte kód

      ```ts
      ...
      export class WaitingEntryEditorComponent implements OnInit {

      private static newEntryPlaceholder: WaitingEntryModel = {
        id: undefined,
        name: '',
        patientId: '',
        waitingSince: new Date(Date.now()),
        estimatedStart: new Date(Date.now()),
        estimatedDurationMinutes: 20,
        condition: { value: 'unknown', code: 'unknown', typicalDurationMinutes: 10, reference: 'none'}
      };

      public readonly knownConditions$: Observable<Array<Condition>>;

      public data$: Observable<WaitingEntryModel> | undefined;

      constructor(
        private readonly route: ActivatedRoute,
        private readonly store: Store<AmbulanceState>,
        private readonly router: Router,
        api: AmbulancePatientsListService) {
          this.knownConditions$ = api.getWaitingReasons();
        }

      public compareConditionsFn(firstCondition: Condition, secondCondition: Condition): boolean {
        return firstCondition.code === secondCondition.code;
      }
      ...
      ```

    a upravte šablónu `ambulance-spa\src\app\waiting-entry-editor\waiting-entry-editor.component.html`

      ```html
      ...
      <mat-select placeholder="Dôvod návštevy"
                  [(value)]="data.condition"
                  [compareWith]="compareConditionsFn">
          <mat-option *ngFor="let condition of knownConditions$|async"
                      [value]="condition">
          {{condition.value}}
          </mat-option>
      </mat-select>
      ```

    a tiež upravte šablónu `ambulance-spa\src\app\waiting-entry\waiting-entry.component.html`

      ```html
      ...
      <mat-form-field>
        <input matInput
              placeholder="Dôvod návštevy"
              [value]="data?.condition?.value"
              readonly>
      </mat-form-field>
      ...
      ```

    >info:> V tomto prípade sme postupovali úpravou existujúcej služby v rámci
    > aplikácie Angular. Alternatívnym, a možno vhodnejším spôsobom by bolo vygenerovanie
    > klientskej služby pomocou nástroja _Swagger_, alebo pomocou nástrojov _OpenApiTools_.
    > Samotná voľba ale nie je kritická, jedná sa skôr o implementačný detail.
    > V našom prípade sme poukázali na typickú aktivitu úpravy kódu v agilnom prostredí.

5. V internetovom prehliadači sa navigujte na adresu `http://localhost:4200`.
 Predpokladom je stále bežiaci príkaz `npm run start`. Mali by ste vidieť vašu
 aplikáciu s prázdnym zoznamom. Vytvorte novú položku pomocou tlačidla _+_ a
 overte funkcionalitu aplikácie.

6. Zastavte príkaz `dotnet watch run` v priečinku `ambulance-api` a overte
 funkčnosť unit testov vykonaním príkazu `npm run test` v priečinku
 `ambulance-spa`. Za normálnych okolností sú teraz testy nekompilovateľné.
 Väčšina testov pre `AmbulancePatientsListService` je zbytočná, keďže logika
 služby bola presunutá do webovej služby, ktorá má vlastnú sadu testov.
 Jedinou logikou, ktorú sme v tomto type implementovali je rozhodnutie o
 uložení novej položky alebo obnovení existujúcej položky.

   Najprv upravte ostatné testy, aby boli vykonané v súlade s predchádzajúcimi
   zmenami v kóde. V súbore `ambulance-spa\src\app\waiting-entry\waiting-entry.component.spec.ts`
   upravte inicializáciu `condition`

    ```ts
    ...
    describe('WaitingEntryComponent', () => {
    ...
      condition: {
        value: 'Testovanie',
        code: 'testing',
        reference: 'none',
        typicalDurationMinutes: 10
      }
    ...
    ```

   V súbore `ambulance-spa\src\app\waiting-entry-editor\waiting-entry-editor.component.spec.ts`
   doplňte testovaciu implementáciu `HttpClientModule`

    ```ts
    ...
    import { HttpClientTestingModule } from '@angular/common/http/testing';
    ...
    describe('WaitingEntryEditorComponent', () => {
    ...
        beforeEach(async(() => {
            TestBed.configureTestingModule({
                imports: [
                    HttpClientTestingModule,
    ...
    ```

7. Vymažte nerelevantné testy v súbore
   `ambulance-spa\src\app\services\ambulance-patients-list.service.spec.ts` a
   vytvorte skeleton nového testu

    ```ts
    import { TestBed } from '@angular/core/testing';
    import { AmbulancePatientsListService } from './ambulance-patients-list.service';
    import { WaitingEntryModel } from './store/waiting-entry-model/waiting-entry-model.model';
    import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
    import { environment } from 'src/environments/environment';

    describe('AmbulancePatientsListService', () => {
      let service: AmbulancePatientsListService;

      beforeEach(() => {
        TestBed.configureTestingModule({
          imports: [HttpClientTestingModule]
        });
        service = TestBed.inject(AmbulancePatientsListService);
      });

      it('should be created', () => {
        expect(service).toBeTruthy();
      });

      it(`should post to creating API if id is not specified`,  () => {
        // given

        // when

        // then

      });
    });
    ```

   Doplňte podmienku testu. Tu otestujte, že voláme správne API metódou POST.
   Tiež overujeme, že nevoláme žiadne ďalšie Web API, čo však nemusí byť
   nevyhnutná požiadavka.

    ```ts
        /// then
        const testingHttpClient: HttpTestingController = TestBed.inject(HttpTestingController);
        const testRequest = testingHttpClient.expectOne(
          `${environment.apiBaseUrl}/waiting-list/${environment.ambulanceId}/entry`);

        expect(testRequest.request.method).toBe('POST');
        testRequest.flush({}); // return some dummy data
        testingHttpClient.verify(); // verify no other requests are made
    ```

   Doplňte spôsob vyvolania testu. Pri `Observable` je nutné vykonať subscribe,
   inak nedôjde k vyvolaniu požiadavky na testovacej implementácii `HttpClient`-a.
   Chýbajúce spracovanie odozvy môže byť dôvodom chýb, kedy sa nevykonajú očakávané
   operácie nad typom `Observable` alebo `Enumerable`.

    ```ts
        // when
        service.upsertEntry(entry).subscribe( _ => {} );
    ```

   Nakoniec doplňte inicializáciu kontextu testu

    ```ts
        // given
        const entry: WaitingEntryModel = {
        name: `Test Patient`,
        patientId: '12345',
        condition: {
            value: 'Testing',
            code: 'tested',
            reference: 'none',
            typicalDurationMinutes: 15
        },
        estimatedStart: new Date(Date.now()),
        estimatedDurationMinutes: 20,
        waitingSince: new Date(Date.now()),
        id: undefined
        };
    ```

   Po uložení a vykonaní testov sú vaše testy opäť úspešné.

   >info:> V tomto prípade sme vytvárali testy až po implementácii funkcionality.
   > V praxi by bolo vhodnejšie tieto testy priebežne vytvárať metódou TDD, napríklad
   > v momente, kedy identifikujeme, že musíme doplniť aplikačnú logiku. Tiež je
   > vhodné mať vykonávanie unit testov zapnuté počas celého vývoja.
   >
   > _Úloha_: Doplňte obdobný test pre prípad, kedy je záznam už existujúci.

8. V tomto stave máme zrealizovanú integráciu použivateľského rozhrania s našou
   web službou. Ešte overíme, či táto integrácia bude funkčná, pokiaľ bude web
   služba umiestnená na inom serveri ako server používateľskej aplikácie. Upravte
   súbor `ambulance-spa\src\environments\environment.ts`

    ```ts
    ...
    export const environment = {
        production: false,
        apiBaseUrl: 'http://localhost:8080/api',
        ambulanceId: 'practitioner-bobulova'
    };
    ...
    ```

    V príkazovom riadku, v priečinku `ambulance-api`, znovu vykonajte príkaz
    `dotnet watch run`. Obdobne, pokiaľ už nemáte bežiaci  vývojový server webovej
    aplikácie, v priečinku `ambulance-spa` vykonajte príkaz `npm run start`.
    V prehliadači otvorte _Nástroje vývojára_ (F12), prejdite na panel _Sieť_
    a navigujte sa na adresu `http://localhost:4200`.

    Po navigácii budete v konzole vidieť chybovú správu

    ```powershell
    _Access to XMLHttpRequest at 'http://localhost:8080/api/waiting-list/practitioner-bobulova'
    from origin 'http://localhost:4200' has been blocked by CORS policy: No
    'Access-Control-Allow-Origin' header is present on the requested resource.
    ```

9. Z bezpečnostných dôvodov všetky
   moderné prehliadače za normálnych okolností bránia skriptom, aby pristupovali
   k odlišným serverom ako je server, z ktorého bola získaná HTML stránka. Takýto
   prístup sa nazýva [_Cross-Origin Resource Sharing_](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS),
   skrátene _CORS_. Prehliadač najprv overí, či server
   požiadavku na daný zdroj povoľuje aj zo stránok, ktoré neboli poskytnuté tým
   istým serverom. Server vtedy môže rozhodnúť, z akých domén je daný zdroj prístupný.

   Doplňte podporu pre _CORS_ dotazy v súbore `ambulance-api\Startup.cs`

    ```csharp
    ...
    using Microsoft.AspNetCore.Mvc;
    ...

    private readonly string myCorsPolicyAllowAll = "AllowAll";

    ...

    public void ConfigureServices(IServiceCollection services)
    {
      ...
      services.AddCors(_ =>
      {
          _.AddPolicy(myCorsPolicyAllowAll,
              builder =>
              {
                  builder
                  .AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
              });
      });
      ...
    }
    ...

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILoggerFactory loggerFactory)
    {
      app.UseRouting();
      //TODO: Uncomment this if you need wwwroot folder
      // app.UseStaticFiles();
      app.UseCors(myCorsPolicyAllowAll);  // <-- pridany riadok
      app.UseAuthorization();
      ...
    }
    ```

   V tomto prípade sme umožnili prístup zo všetkých domén a na všetky zdroje
   našej webovej služby. V praxi vezmite do úvahy reálne potreby aplikácie a obmedzte
   prístup k zdrojom len na domény, ktoré takýto prístup reálne vyžadujú. Umožnite
   definovať tieto domény pomocou konfigurácie aplikácie.

10. Opätovne pristúpte na stránku `http://localhost:4200`. V tomto prípade by ste
    mali mať aplikáciu opäť funkčnú. Vráťte nastavenie v `ambulance-spa\src\environments\environment.ts`
    na pôvodnú hodnotu

    ```ts
    ...
    export const environment = {
        production: false,
        apiBaseUrl: '/api',
        ambulanceId: 'practitioner-bobulova'
    };
    ...
    ```

11. Nakoniec upravíme produkčný environment, aby naša aplikácia fungovala aj na
    cloude. Momentálne nám produkčný build padá,
    Vyskúšajte:

    ```powershell
    ng build --prod
    ```

    Upravte súbor `environments\environment.prod.ts` nasledovne, aby SPA aplikácia
    pristupovala na webapi (adresu nastavte na svoje deploynuté webapi):

    ```ts
    ...
    export const environment = {
        production: true,
        apiBaseUrl: 'https://ambulance-api-<inicialy>.azurewebsites.net/api',
        ambulanceId: 'practitioner-bobulova'
    };
    ...
    ```

    Archivujte váš kód do vzdialeného repozitára a počkajte kým dobehne release build.

    Medzitým pustite aplikáciu Postman a overte, či je ambulancia na webapi inicializovaná.
    Vytvorte nový GET request na adresu `https://ambulance-api-<inicialy>.azurewebsites.net/api/waiting-list/practitioner-bobulova`
    a spustite ho.

    Ak ambulancia neexistuje, použite na inicializáciu existujúci POST request
    s menom `Create ambulance`.

    Po dobehnutí release buildu otvorte stránku SPA aplikácie a vyskúšajte jej
    funkčnosť.
