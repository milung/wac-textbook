# Implementácia WEB API a perzistencie údajov

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-api-040`

---

Dokumentové databázy ukladajú vo svojej podstate dokumenty, ktoré sú zoradené do kolekcií a tie potom do databáz. Dokumenty sú vlastne JSON objekty, ktoré môžu obsahovať ľubovoľnú štruktúru. V našom prípade budeme ukladať objekty typu `Ambulance` do kolekcie `ambulances`. Tieto objekty budú obsahovať jednak údaje o danej ambulancii pre potreby našej aplikácie, ako aj údaje o zozname čakajúcich pacientov a o zozname symptómov, z ktorého si pacienti vyberajú položku pri registrácii sa do zoznamu čakajúcich. Všetky požiadavky na naše WEB API potom budú pracovať s príslušným dokumentom, ktorý zodpovedá vybranej ambulancii.

1. V prvom kroku upravíme naše API tak, aby obsahovalo definíciu príslušného objektu a umožnilo vytvoriť alebo odstrániť záznam o príslušnej ambulancii. Otvorte súbor `${WAC_ROOT}/ambulance-webapi/api/ambulance-wl.openapi.yaml` a do sekcie `components/schemas` doplňte nový typ `Ambulance`

    ```yaml
    ...
    components:
      schemas:
        WaitingListEntry: 
          ...
        Condition:
          ...
        Ambulance:   @_add_@
          type: object   @_add_@
          required: [ "id", "name", "roomNumber"]   @_add_@
          properties:   @_add_@
            id:   @_add_@
              type: string   @_add_@
              example: dentist-warenova   @_add_@
              description: Unique identifier of the ambulance   @_add_@
            name:   @_add_@
              type: string   @_add_@
              example: Zubná ambulancia Dr. Warenová   @_add_@
              description: Human readable display name of the ambulance   @_add_@
            roomNumber:   @_add_@
              type: string   @_add_@
              example: 356 - 3.posch   @_add_@
            waitingList:   @_add_@
              type: array   @_add_@
              items:   @_add_@
                $ref: '#/components/schemas/WaitingListEntry'   @_add_@
            predefinedConditions:   @_add_@
              type: array   @_add_@
              items:   @_add_@
                $ref: '#/components/schemas/Condition'   @_add_@
          example:   @_add_@
            $ref: "#/components/examples/AmbulanceExample"   @_add_@
    examples: 
      ...
    ```

    Ďalej do sekcie `examples` doplňte príklad pre typ `Ambulance`

    ```yaml
    ...
    components: 
    ....
    examples: 
        ...
        WaitingListEntriesExample:
        ...
        AmbulanceExample:           @_add_@
          summary: Sample GP ambulance          @_add_@
          description: |            @_add_@
            Example of GP ambulance with waiting list and predefined conditions         @_add_@
          value:            @_add_@
            id: gp-warenova         @_add_@
            name: Ambulancia všeobecného lekárstva Dr. Warenová         @_add_@
            roomNumber: 356 - 3.posch           @_add_@
            waitingList:            @_add_@
              - id: x321ab3         @_add_@
                name: Jožko Púčik           @_add_@
                patientId: 460527-jozef-pucik           @_add_@
                waitingSince: "2038-12-24T10:05:00.000Z"            @_add_@
                estimatedStart: "2038-12-24T10:35:00.000Z"          @_add_@
                estimatedDurationMinutes: 15            @_add_@
                condition:          @_add_@
                value: Teploty            @_add_@
                code: subfebrilia         @_add_@
                reference: "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/"          @_add_@
              - id: x321ab4         @_add_@
                name: Ferdinand Trety           @_add_@
                patientId: 780907-ferdinand-tre         @_add_@
                waitingSince: "2038-12-24T10:25:00.000Z"            @_add_@
                estimatedStart: "2038-12-24T10:50:00.000Z"          @_add_@
                estimatedDurationMinutes: 25            @_add_@
                condition:          @_add_@
                value: Nevoľnosť          @_add_@
                code: nausea          @_add_@
                reference: "https://zdravoteka.sk/priznaky/nevolnost/"            @_add_@
            predefinedConditions:           @_add_@
              - value: Teploty          @_add_@
                code: subfebrilia           @_add_@
                reference: "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/"            @_add_@
                typicalDurationMinutes: 20          @_add_@
              - value: Nevoľnosť            @_add_@
                code: nausea            @_add_@
                reference: "https://zdravoteka.sk/priznaky/nevolnost/"          @_add_@
                typicalDurationMinutes: 45          @_add_@
              - value: Kontrola         @_add_@
                code: followup          @_add_@
                typicalDurationMinutes: 15          @_add_@
              - value: Administratívny úkon         @_add_@
                code: administration            @_add_@
                typicalDurationMinutes: 10          @_add_@
              - value: Odber krvi           @_add_@
                code: blood-test            @_add_@
                typicalDurationMinutes: 10          @_add_@
    ```

    Do sekcie `tags` doplňte nový tag `ambulances`

    ```yaml
    ...
    tags:
    - name: ambulanceWaitingList
      description: Ambulance Waiting List API
    - name: ambulanceConditions
      description: Patient conditions and synptoms handled in the ambulance
    - name: ambulances @_add_@
      description: Ambulance details   @_add_@
    ```

    a do sekcie `paths` doplňte novú cesty a operácie:

    ```yaml
    ...
    paths:
    ...
      "/waiting-list/{ambulanceId}/condition":
        ...
      "/ambulance":     @_add_@
        post:     @_add_@
          tags:     @_add_@
            - ambulances     @_add_@
          summary: Saves new ambulance definition     @_add_@
          operationId: createAmbulance     @_add_@
          description: Use this method to initialize new ambulance in the system     @_add_@
          requestBody:     @_add_@
            content:     @_add_@
              application/json:     @_add_@
                schema:     @_add_@
                  $ref: "#/components/schemas/Ambulance"     @_add_@
                examples:     @_add_@
                  request-sample:      @_add_@
                    $ref: "#/components/examples/AmbulanceExample"     @_add_@
            description: Ambulance details to store     @_add_@
            required: true     @_add_@
          responses:     @_add_@
            "200":     @_add_@
              description: >-     @_add_@
                Value of stored ambulance     @_add_@
              content:     @_add_@
                application/json:     @_add_@
                  schema:     @_add_@
                    $ref: "#/components/schemas/Ambulance"     @_add_@
                  examples:     @_add_@
                    updated-response:      @_add_@
                      $ref: "#/components/examples/AmbulanceExample"     @_add_@
            "400":     @_add_@
              description: Missing mandatory properties of input object.     @_add_@
            "409":     @_add_@
              description: Entry with the specified id already exists     @_add_@
      "/ambulance/{ambulanceId}":     @_add_@
        delete:     @_add_@
          tags:     @_add_@
            - ambulances     @_add_@
          summary: Deletes specific ambulance     @_add_@
          operationId: deleteAmbulance     @_add_@
          description: Use this method to delete the specific ambulance from the system.     @_add_@
          parameters:     @_add_@
            - in: path     @_add_@
              name: ambulanceId     @_add_@
              description: pass the id of the particular ambulance     @_add_@
              required: true     @_add_@
              schema:     @_add_@
                type: string     @_add_@
          responses:     @_add_@
            "204":     @_add_@
              description: Item deleted     @_add_@
            "404":     @_add_@
              description: Ambulance with such ID does not exist     @_add_@
    ```

2. Vygenerujte novú verziu skeletonu pre serverovú časť nášho WEB API. V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte nasledujúci príkaz:

    ```ps
    ./scripts/run.ps1 openapi
    ```

   V projekte sa Vám objaví nový súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/api_ambulances.go` Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulances.go` s obsahom:

   ```go
   package ambulance_wl
   
   import (
    "net/http"
   
    "github.com/gin-gonic/gin"
   )
   
   // Kópia zakomentovanej časti z api_ambulances.go
   // CreateAmbulance - Saves new ambulance definition
   func (this *implAmbulancesAPI) CreateAmbulance(ctx *gin.Context) {
      ctx.AbortWithStatus(http.StatusNotImplemented)
   }
   
   // DeleteAmbulance - Deletes specific ambulance
   func (this *implAmbulancesAPI) DeleteAmbulance(ctx *gin.Context) {
      ctx.AbortWithStatus(http.StatusNotImplemented)
   }
   ```

   Táto implementácia je dočasná, pred jej dokončením pripravíme pomocnú triedu, ktorá bude zodpovedná za prístup k databáze.

3. Za účelom prístupu k dokumentom a práce s nimi vytvoríme nové triedy v samostatnom  _package_ `db_service`. K serializácii objektov bude využívať anotácie vygenerované openapi generátorom kódu. Napríklad typ `Condition` v súbore `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/model_condition.go` je definovaný takto

   ```go
   type Condition struct {

        Value string `json:"value"`

        Code string `json:"code,omitempty"`

        // Link to encyclopedical explanation of the patient's condition
        string `json:"reference,omitempty"`

        TypicalDurationMinutes int32 `json:"typicalDurationMinutes,omitempty"`
    }
   ```

   Anotácia `json:"value"` určuje, že vlastnosť `Value` sa bude do JSON objektu serializovať pod kľúčom `value`. Knižnica mongo podporuje `json` aj `bson` (binary JSON) anotácie. Vďaka tomu bude možné použiť túto triedu priamo na serializáciu a deserializáciu objektov z databázy.

   > Pretože programovací jazyk [Go] nedovoľuje vytvárať cyklické závislosti medzi jednotlivými balíčkami, bude implementácia `db_service` používať šablóny typov - [generics], to znamená, že nebude používať žiadne typy z balíčka `ambulance_wl`.

   Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/db_service/mongo_svc.go` s obsahom:

    ```go
    package db_service

    import (
        "context"
        "fmt"
        "log"
        "os"
        "strconv"
        "sync"
        "sync/atomic"
        "time"

        "go.mongodb.org/mongo-driver/bson"
        "go.mongodb.org/mongo-driver/mongo"
        "go.mongodb.org/mongo-driver/mongo/options"
    )

    type DbService[DocType interface{}] interface {
        CreateDocument(ctx context.Context, id string, document *DocType) error
        FindDocument(ctx context.Context, id string) (*DocType, error)
        UpdateDocument(ctx context.Context, id string, document *DocType) error
        DeleteDocument(ctx context.Context, id string) error
        Disconnect(ctx context.Context) error
    }

    var ErrNotFound = fmt.Errorf("document not found")
    var ErrConflict = fmt.Errorf("conflict: document already exists")

    type MongoServiceConfig struct {
        ServerHost string
        ServerPort int
        UserName   string
        Password   string
        DbName     string
        Collection string
        Timeout    time.Duration
    }

    type mongoSvc[DocType interface{}] struct {
        MongoServiceConfig
        client     atomic.Pointer[mongo.Client]
        clientLock sync.Mutex
    }
    ```

   Rozhranie DbService je generickým rozhraním, konkrétny typ inštancie bude určený pri jej vytváraní naviazaním na typ `DocType`. Vo zvyšku našej implementácie budeme predpokladať, že pracujeme s [dokumentovou databázou](https://en.wikipedia.org/wiki/Document-oriented_database), ale nebudeme zavádzať explicitné závislosti na konkrétnej implementácii. V našom prípade bude konkrétnou implementáciou trieda `mongoSvc`, ktorá bude využívať knižnicu [mongo-go-driver](https://github.com/mongodb/mongo-go-driver). Všimnite si, že tento typ nie je mimo package `db_service` viditeľný (začína malým písmenom), čo znamená, že ho budeme môcť použiť iba v rámci tohto balíčka.

4. Typ `mongoSvc` bude zdieľaný medzi jednotlivými požiadavkami prichádzajúcimi na náš server. Preto bude obsahovať aj synchronizačný mechanizmus, ktorý zabezpečí, že v jednom okamihu bude existovať iba jedna inštancia triedy `mongo.Client`. Kód triedy `mongo.Client` je reentrantný, prístup k metódam tejto triedy preto nie je potrebné synchronizovať.

   Pri vytváraní novej inštancie použijeme buď explicitne dodané parametre v type `MongoServiceConfig` alebo, ak nie sú poskytnuté, pokúsime sa ich načítať z premenných prostredia alebo použijeme predvolené hodnoty. Doplňte na koniec súboru `${WAC_ROOT}/ambulance-webapi/internal/db_service/mongo_svc.go` nasledujúci kód:

   ```go
   func NewMongoService[DocType interface{}](config MongoServiceConfig) DbService[DocType] {
        enviro := func(name string, defaultValue string) string {
            if value, ok := os.LookupEnv(name); ok {
                return value
            }
            return defaultValue
        }

        svc := &mongoSvc[DocType]{}
        svc.MongoServiceConfig = config

        if svc.ServerHost == "" {
            svc.ServerHost = enviro("AMBULANCE_API_MONGODB_HOST", "localhost")
        }

        if svc.ServerPort == 0 {
            port := enviro("AMBULANCE_API_MONGODB_PORT", "27017")
            if port, err := strconv.Atoi(port); err == nil {
                svc.ServerPort = port
            } else {
                log.Printf("Invalid port value: %v", port)
                svc.ServerPort = 27017
            }
        }

        if svc.UserName == "" {
            svc.UserName = enviro("AMBULANCE_API_MONGODB_USERNAME", "")
        }

        if svc.Password == "" {
            svc.Password = enviro("AMBULANCE_API_MONGODB_PASSWORD", "")
        }

        if svc.DbName == "" {
            svc.DbName = enviro("AMBULANCE_API_MONGODB_DATABASE", "<pfx>-ambulance-wl")
        }

        if svc.Collection == "" {
            svc.Collection = enviro("AMBULANCE_API_MONGODB_COLLECTION", "ambulance")
        }

        if svc.Timeout == 0 {
            seconds := enviro("AMBULANCE_API_MONGODB_TIMEOUT_SECONDS", "10")
            if seconds, err := strconv.Atoi(seconds); err == nil {
                svc.Timeout = time.Duration(seconds) * time.Second
            } else {
                log.Printf("Invalid timeout value: %v", seconds)
                svc.Timeout = 10 * time.Second
            }
        }

        log.Printf(
            "MongoDB config: //%v@%v:%v/%v/%v",
            svc.UserName,
            svc.ServerHost,
            svc.ServerPort,
            svc.DbName,
            svc.Collection,
        )
        return svc
    }
   ```

   >info:> Odporúčame Vám zoznámiť sa s knižnicou [viper], ktorá poskytuje flexibilnejšie spôsoby konfigurácie aplikácie v cieľovom prostredí.

5. Ďalej do súboru  `${WAC_ROOT}/ambulance-webapi/internal/db_service/mongo_svc.go` doplňte pomocné funkcie na pripojenie sa a odpojenie sa od databázy. Všimnite si akým spôsobom zabezpečuje synchronizáciu prístupu k inštancii triedy `mongo.Client`. Hoci by sme mohli univerzálne používať mutex `clientLock`, prístup k nemu by mohol vyvolať prerušenie daného vlákna výpočtu, čo by z hľadiska celkového výkonu bolo neefektívne. Preto používame [atomic pointer](https://pkg.go.dev/sync/atomic#Pointer), ktorý umožňuje atomické načítanie a zápis hodnoty, a len v prípade kedy musíme vytvoriť novú inštanciu klienta, alebo ju odstrániť, vstúpime do kritickej sekcie riadenej mutexom. Pretože priebeh výpočtu môže byť ukončený náhlou výnimkou, používame konštrukt `defer`, ktorý zabezpečí, že sa uvedený výraz vykoná vždy, keď opustíme danú funkciu.

    ```go
    func (this *mongoSvc[DocType]) connect(ctx context.Context) (*mongo.Client, error) {
        // optimistic check
        client := this.client.Load()
        if client != nil {
            return client, nil
        }

        this.clientLock.Lock()
        defer this.clientLock.Unlock()
        // pesimistic check
        client = this.client.Load()
        if client != nil {
            return client, nil
        }

        ctx, contextCancel := context.WithTimeout(ctx, this.Timeout)
        defer contextCancel()

        var uri = fmt.Sprintf("mongodb://%v:%v", this.ServerHost, this.ServerPort)
        log.Printf("Using URI: " + uri)

        if len(this.UserName) != 0 {
            uri = fmt.Sprintf("mongodb://%v:%v@%v:%v", this.UserName, this.Password, this.ServerHost, this.ServerPort)
        }

        if client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri).SetConnectTimeout(10*time.Second)); err != nil {
            return nil, err
        } else {
            this.client.Store(client)
            return client, nil
        }
    }

    func (this *mongoSvc[DocType]) Disconnect(ctx context.Context) error {
        client := this.client.Load()

        if client != nil {
            this.clientLock.Lock()
            defer this.clientLock.Unlock()

            client = this.client.Load()
            defer this.client.Store(nil)
            if client != nil {
                if err := client.Disconnect(ctx); err != nil {
                    return err
                }
            }
        }
        return nil
    }
    ```

6. Následne do súboru  `${WAC_ROOT}/ambulance-webapi/internal/db_service/mongo_svc.go` doplníme implementáciu rozhrania `DbService` nad typom `mongoSvc`. Vo všetkých metódach sa pokúsime načítať dokument (ambulanciu) s príslušným id a pokiaľ sa v databáze nenachádza, vrátime preddefinovanú inštanciu typu `error` `ErrNotFoundE`, respektíve v prípade vytvárania dokumentu vrátime chybu `ErrConflict` ak taký dokument už existuje.

   Všimnite si používanie typu [`context.Context`](https://pkg.go.dev/context). Tento typ je štandardne použitý ako prvý parameter funkcií, ktoré využívajú asynchrónne spracovanie údajov alebo implementujú dlhotrvajúci výpočet. `Context` umožňuje propagovať žiadosť o predčasné ukončenie výpočtu do svojich podriadených kontextov, vytvorených jeho metódami `With...`. Tiež umožňuje predávať medzi vláknami údaje, ktoré sú spoločné pre celý výpočet. V našom prípade používame `Context` na to, aby sme časovo ohraničili dobu, počas ktorej sa má klient pokúšať získať odpoveď z pripojenej databázy.

   Volanie `context.Cancel()` nastaví _context_ do stavu `Done`, čo môžeme použiť, ak by sme čakali na dokončenie výpočtu asynchrónnym spôsobom alebo ak by sme chceli _context_ - teda výpočet riadený týmto _context_-om - predčasne ukončiť z iného vlákna. Túto možnosť tu ale nevyužívame. Nezabudnite, že novovytvorené inštancie typu `context.Context` sú vždy v stave `Done` a preto je potrebné ich vytvárať pomocou metód `context.With...`, a na konci ich životného cyklu je potrebné zavolať funkciu `context.Cancel()`. V našom prípade to robíme pomocou konštruktu `defer` a volaním poskytnutej funkcie `contextCancel()`, ktorá interne prevolá spomenutú metódu `context.Cancel()`.

    ```go
    func (this *mongoSvc[DocType]) CreateDocument(ctx context.Context, id string, document *DocType) error {
        ctx, contextCancel := context.WithTimeout(ctx, this.Timeout)
        defer contextCancel()
        client, err := this.connect(ctx)
        if err != nil {
            return err
        }
        db := client.Database(this.DbName)
        collection := db.Collection(this.Collection)
        result := collection.FindOne(ctx, bson.D{{Key: "id", Value: id}})
        switch result.Err() {
        case nil: // no error means there is conflicting document
            return ErrConflict
        case mongo.ErrNoDocuments:
            // do nothing, this is expected
        default: // other errors - return them
            return result.Err()
        }

        _, err = collection.InsertOne(ctx, document)
        return err
    }

    func (this *mongoSvc[DocType]) FindDocument(ctx context.Context, id string) (*DocType, error) {
        ctx, contextCancel := context.WithTimeout(ctx, this.Timeout)
        defer contextCancel()
        client, err := this.connect(ctx)
        if err != nil {
            return nil, err
        }
        db := client.Database(this.DbName)
        collection := db.Collection(this.Collection)
        result := collection.FindOne(ctx, bson.D{{Key: "id", Value: id}})
        switch result.Err() {
        case nil:
        case mongo.ErrNoDocuments:
            return nil, ErrNotFound
        default: // other errors - return them
            return nil, result.Err()
        }
        var document *DocType
        if err := result.Decode(&document); err != nil {
            return nil, err
        }
        return document, nil
    }

    func (this *mongoSvc[DocType]) UpdateDocument(ctx context.Context, id string, document *DocType) error {
        ctx, contextCancel := context.WithTimeout(ctx, this.Timeout)
        defer contextCancel()
        client, err := this.connect(ctx)
        if err != nil {
            return err
        }
        db := client.Database(this.DbName)
        collection := db.Collection(this.Collection)
        result := collection.FindOne(ctx, bson.D{{Key: "id", Value: id}})
        switch result.Err() {
        case nil:
        case mongo.ErrNoDocuments:
            return ErrNotFound
        default: // other errors - return them
            return result.Err()
        }
        _, err = collection.ReplaceOne(ctx, bson.D{{Key: "id", Value: id}}, document)
        return err
    }

    func (this *mongoSvc[DocType]) DeleteDocument(ctx context.Context, id string) error {
        ctx, contextCancel := context.WithTimeout(ctx, this.Timeout)
        defer contextCancel()
        client, err := this.connect(ctx)
        if err != nil {
            return err
        }
        db := client.Database(this.DbName)
        collection := db.Collection(this.Collection)
        result := collection.FindOne(ctx, bson.D{{Key: "id", Value: id}})
        switch result.Err() {
        case nil:
        case mongo.ErrNoDocuments:
            return ErrNotFound
        default: // other errors - return them
            return result.Err()
        }
        _, err = collection.DeleteOne(ctx, bson.D{{Key: "id", Value: id}})
        return err
    }
    ```

    Týmto máme náš prístup k databáze naimplementovaný.

7. Aby sme mohli naše rozhranie `DbService` využiť v kóde obsluhy požiadaviek, ktorý sme vygenerovali v _package_ `ambulance_wl`, pridáme jeho inštanciu do _context_-u, ktorý je predaný vygenerovaným funkciám ako argument. K tomu využijeme [_middleware_](https://gin-gonic.com/docs/examples/custom-middleware/) funkciu, ktorú zaregistrujeme do _router_-a knižnice `gin`. Zároveň pridáme CORS configuráciu.

   Otvorte súbor `${WAC_ROOT}/workspaces/wac-test/ambulance-webapi/cmd/ambulance-api-service/main.go` a do funkcie `main` doplňte uvedený kód:

    ```go
    package main
    
    import (
        ...
        "github.com/<github_id>/ambulance-webapi/internal/db_service" @_add_@
        "context" @_add_@
        "time" @_add_@
        "github.com/gin-contrib/cors" @_add_@
    )
    
    func main() {
        ...
        engine := gin.New()
        engine.Use(gin.Recovery())

        corsMiddleware := cors.New(cors.Config{     @_add_@
            AllowOrigins:     []string{"*"},     @_add_@
            AllowMethods:     []string{"GET", "PUT", "POST", "DELETE", "PATCH"},     @_add_@
            AllowHeaders:     []string{"Origin", "Authorization", "Content-Type"},     @_add_@
            ExposeHeaders:    []string{""},     @_add_@
            AllowCredentials: false,     @_add_@
            MaxAge: 12 * time.Hour,     @_add_@
        })     @_add_@
        engine.Use(corsMiddleware)     @_add_@
    
        // setup context update  middleware     @_add_@
        dbService := db_service.NewMongoService[ambulance_wl.Ambulance](db_service.MongoServiceConfig{})     @_add_@
        defer dbService.Disconnect(context.Background())     @_add_@
        engine.Use(func(ctx *gin.Context) {     @_add_@
            ctx.Set("db_service", dbService)     @_add_@
            ctx.Next()     @_add_@
        })     @_add_@
        // request routings
        ambulance_wl.AddRoutes(engine)
        ...
    }
    ```

8. Teraz pristúpime k implementácii obsluhy požiadaviek. Začneme s triedou `implAmbulancesAPI`. Otvorte súbor `${WAC_ROOT}\ambulance-webapi\internal\ambulance_wl\impl_ambulances.go` a upravte metódu `CreateAmbulance`:

    ```go
    package ambulance_wl

    import (
        "net/http"

        "github.com/gin-gonic/gin"
        "github.com/google/uuid" @_add_@
        "github.com/<github_id>/ambulance-webapi/internal/db_service" @_add_@
    )

    // CreateAmbulance - Saves new ambulance definition
    func (this *implAmbulancesAPI) CreateAmbulance(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented)  @_remove_@
        // get db service from context
        value, exists := ctx.Get("db_service")    @_add_@
        if !exists {   @_add_@
            ctx.JSON(   @_add_@
                http.StatusInternalServerError,   @_add_@
                gin.H{   @_add_@
                    "status":  "Internal Server Error",   @_add_@
                    "message": "db not found",   @_add_@
                    "error":   "db not found",   @_add_@
                })   @_add_@
            return   @_add_@
        }   @_add_@
    @_add_@
        db, ok := value.(db_service.DbService[Ambulance])   @_add_@
        if !ok {   @_add_@
            ctx.JSON(   @_add_@
                http.StatusInternalServerError,   @_add_@
                gin.H{   @_add_@
                    "status":  "Internal Server Error",   @_add_@
                    "message": "db context is not of required type",   @_add_@
                    "error":   "cannot cast db context to db_service.DbService",   @_add_@
                })   @_add_@
            return   @_add_@
        }   @_add_@
    @_add_@
        ambulance := Ambulance{}   @_add_@
        err := ctx.BindJSON(&ambulance)   @_add_@
        if err != nil {   @_add_@
            ctx.JSON(   @_add_@
                http.StatusBadRequest,   @_add_@
                gin.H{   @_add_@
                    "status":  "Bad Request",   @_add_@
                    "message": "Invalid request body",   @_add_@
                    "error":   err.Error(),   @_add_@
                })   @_add_@
            return   @_add_@
        }   @_add_@
    @_add_@
        if ambulance.Id == "" {   @_add_@
            ambulance.Id = uuid.New().String()   @_add_@
        }   @_add_@
    @_add_@
        err = db.CreateDocument(ctx, ambulance.Id, &ambulance)   @_add_@
    @_add_@
        switch err {   @_add_@
        case nil:   @_add_@
            ctx.JSON(   @_add_@
                http.StatusCreated,   @_add_@
                ambulance,   @_add_@
            )   @_add_@
        case db_service.ErrConflict:   @_add_@
            ctx.JSON(   @_add_@
                http.StatusConflict,   @_add_@
                gin.H{   @_add_@
                    "status":  "Conflict",   @_add_@
                    "message": "Ambulance already exists",   @_add_@
                    "error":   err.Error(),   @_add_@
                },   @_add_@
            )   @_add_@
        default:   @_add_@
            ctx.JSON(   @_add_@
                http.StatusBadGateway,   @_add_@
                gin.H{   @_add_@
                    "status":  "Bad Gateway",   @_add_@
                    "message": "Failed to create ambulance in database",   @_add_@
                    "error":   err.Error(),   @_add_@
                },   @_add_@
            )   @_add_@
        }   @_add_@
    }
    ```

    V tejto metóde najprv získame inštanciu `DbService` z _context_-u, ktorý sme doňho predtým uložili.  Následne získame objekt `Ambulance` z tela požiadavky a pokúsime sa ho uložiť do databázy. Všimnite si, že značná časť kódu je venovaná ošetreniu možných chýb a signalizovaniu danej chyby v odpovedi na požiadavku.

    >info:> Naša špecifikácia openapi neuvádza všetky hodnoty stavových chýb a návratový objekt, ktorý tu používame. Samostatne upravte špecifikáciu tak, aby obsahovala všetky možné chyby a návratové objekty.

    Ďalej v tom istom súbore upravte metódu `DeleteAmbulance`:

    ```go
    ...
    func (this *implAmbulancesAPI) DeleteAmbulance(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented) @_remove_@
        // get db service from context
        value, exists := ctx.Get("db_service")    @_add_@
        if !exists {    @_add_@
            ctx.JSON(    @_add_@
                http.StatusInternalServerError,    @_add_@
                gin.H{    @_add_@
                    "status":  "Internal Server Error",    @_add_@
                    "message": "db_service not found",    @_add_@
                    "error":   "db_service not found",    @_add_@
                })    @_add_@
            return    @_add_@
        }    @_add_@
        @_add_@
        db, ok := value.(db_service.DbService[Ambulance])    @_add_@
        if !ok {    @_add_@
            ctx.JSON(    @_add_@
                http.StatusInternalServerError,    @_add_@
                gin.H{    @_add_@
                    "status":  "Internal Server Error",    @_add_@
                    "message": "db_service context is not of type db_service.DbService",    @_add_@
                    "error":   "cannot cast db_service context to db_service.DbService",    @_add_@
                })    @_add_@
            return    @_add_@
        }    @_add_@
        @_add_@
        ambulanceId := ctx.Param("ambulanceId")    @_add_@
        err := db.DeleteDocument(ctx, ambulanceId)    @_add_@
        @_add_@
        switch err {    @_add_@
        case nil:    @_add_@
            ctx.AbortWithStatus(http.StatusNoContent)    @_add_@
        case db_service.ErrNotFound:    @_add_@
            ctx.JSON(    @_add_@
                http.StatusNotFound,    @_add_@
                gin.H{    @_add_@
                    "status":  "Not Found",    @_add_@
                    "message": "Ambulance not found",    @_add_@
                    "error":   err.Error(),    @_add_@
                },    @_add_@
            )    @_add_@
        default:    @_add_@
            ctx.JSON(    @_add_@
                http.StatusBadGateway,    @_add_@
                gin.H{    @_add_@
                    "status":  "Bad Gateway",    @_add_@
                    "message": "Failed to delete ambulance from database",    @_add_@
                    "error":   err.Error(),    @_add_@
                })    @_add_@
        }    @_add_@
    ```

9. Uložte zmeny. V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte nasledujúce príkazy:

    ```ps
    go mod tidy
    ./scripts/run.ps1 start
    ```

   Otvorte nový príkazový riadok powershell a vykonajte nasledujúce príkazy:

   ```ps
   $Body = @{
       id = "bobulova"
       name = "Dr.Bobulová"
       roomNumber = "123"
       predefinedConditions = @(
           @{ value = "Nádcha"; code = "rhinitis" },
           @{ value = "Kontrola"; code = "checkup" }
       )
   }

    Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/ambulance -Body ($Body | ConvertTo-Json) -ContentType "application/json"
    ```

    Výsledkom by mal byť výpis v tejto podobe:

    ```text
    id       name         roomNumber predefinedConditions
    --       ----         ---------- --------------------
    bobulova Dr.Bobulov?? 123        {@{value=N??dcha; code=rhinitis}, @{value=Kontrola; code=checkup}}
    ```

    >$linux:> V prípade linuxu/mac použite príkaz `curl`:
    >
    > ```sh
    > curl -X POST -H "Content-Type: application/json" -d '{"id":"bobulova","name":"Dr.Bobulová","roomNumber":"123","predefinedConditions":>    [{"value":"Nádcha","code":"rhinitis"},{"value":"Kontrola","code":"checkup"}]}' http://localhost:8080/ambulance
    > ```

   Týmto sme overili funkčnosť doteraz implmentovného kódu a zároveň sme vytvorili novú ambulanciu. V prehliadači otvorte stánku `http://localhost:8081/db/<pfx>-ambulance-wl/ambulance` a v zozname dokumentov stlačte na prvý záznam.

10. V prípade zostávajúcich obslužných metód bude ich funkcionalita v mnohom podobná. Najprv musíme získať dokument pre danú ambulanciu, upraviť ho a následne ho pozmenený uložiť do databázy. Popritom musíme ošetriť možné chybové stavy. Aby sme zredukovali duplicitu kódu, pomôžeme si pomocnou funkciou. Vytvorte súbor `${WAC_ROOT}//ambulance-webapi/internal/ambulance_wl/utils_ambulance_updater.go` s nasledujúcim obsahom:

    ```go
    package ambulance_wl

    import (
        "net/http"

        "github.com/gin-gonic/gin"
        "github.com/<github-id>/ambulance-webapi/internal/db_service"
    )

    type ambulanceUpdater = func( @_important_@
        ctx *gin.Context,  @_important_@
        ambulance *Ambulance,  @_important_@
    ) (updatedAmbulance *Ambulance, responseContent interface{}, status int)  @_important_@

    func updateAmbulanceFunc(ctx *gin.Context, updater ambulanceUpdater) {
        value, exists := ctx.Get("db_service")
        if !exists {
            ctx.JSON(
                http.StatusInternalServerError,
                gin.H{
                    "status":  "Internal Server Error",
                    "message": "db_service not found",
                    "error":   "db_service not found",
                })
            return
        }

        db, ok := value.(db_service.DbService[Ambulance])
        if !ok {
            ctx.JSON(
                http.StatusInternalServerError,
                gin.H{
                    "status":  "Internal Server Error",
                    "message": "db_service context is not of type db_service.DbService",
                    "error":   "cannot cast db_service context to db_service.DbService",
                })
            return
        }

        ambulanceId := ctx.Param("ambulanceId")

        ambulance, err := db.FindDocument(ctx, ambulanceId)

        switch err {
        case nil:
            // continue
        case db_service.ErrNotFound:
            ctx.JSON(
                http.StatusNotFound,
                gin.H{
                    "status":  "Not Found",
                    "message": "Ambulance not found",
                    "error":   err.Error(),
                },
            )
            return
        default:
            ctx.JSON(
                http.StatusBadGateway,
                gin.H{
                    "status":  "Bad Gateway",
                    "message": "Failed to load ambulance from database",
                    "error":   err.Error(),
                })
            return
        }

        if !ok {
            ctx.JSON(
                http.StatusInternalServerError,
                gin.H{
                    "status":  "Internal Server Error",
                    "message": "Failed to cast ambulance from database",
                    "error":   "Failed to cast ambulance from database",
                })
            return
        }

        updatedAmbulance, responseObject, status := updater(ctx, ambulance)

        if updatedAmbulance != nil {
            err = db.UpdateDocument(ctx, ambulanceId, updatedAmbulance)
        } else {
            err = nil // redundant but for clarity
        }

        switch err {
        case nil:
            if responseObject != nil {
                ctx.JSON(status, responseObject)
            } else {
                ctx.AbortWithStatus(status)
            }
        case db_service.ErrNotFound:
            ctx.JSON(
                http.StatusNotFound,
                gin.H{
                    "status":  "Not Found",
                    "message": "Ambulance was deleted while processing the request",
                    "error":   err.Error(),
                },
            )
        default:
            ctx.JSON(
                http.StatusBadGateway,
                gin.H{
                    "status":  "Bad Gateway",
                    "message": "Failed to update ambulance in database",
                    "error":   err.Error(),
                })
        }

    }
    ```

    Všimnite si, že funkcia `updateAmbulanceFunc` akceptuje ako vstupný argument inú funkciu, deklarovanú ako `ambulanceUpdater`. Funkcie sú v jazyku [go] plnohodnotnými typmi a preto ich je možné používať ako typy.

11. Teraz otvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_conditions.go` a upravte ho:

    ```go
    ...

    // GetConditions - Provides the list of conditions associated with ambulance
    func (this *implAmbulanceConditionsAPI) GetConditions(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented) @_remove_@
        // update ambulance document
        updateAmbulanceFunc(ctx, func(    @_add_@
            ctx *gin.Context,    @_add_@
            ambulance *Ambulance,    @_add_@
        ) (updatedAmbulance *Ambulance, responseContent interface{}, status int) {    @_add_@
            result := ambulance.PredefinedConditions   @_add_@
            if result == nil {   @_add_@
                result = []Condition{}   @_add_@
            }   @_add_@
            return nil, result, http.StatusOK   @_add_@
        })    @_add_@
    }
    ```

    V tejto metóde sme použili funkciu `updateAmbulanceFunc` a ako jej argument sme poskytli anonymnú funkciu, ktorá vracia zoznam podmienok, ktoré sú priradené k ambulancii. Všimnite si, že v prípade, že ambulancia nemá priradené žiadne podmienky, vraciame prázdny zoznam.

12. Trieda `implAmbulanceWaitingListAPI` upravuje zoznam čakajúcich v zvolenej ambulancii. Súčasťou aplikačnej logiky je zabezpečenie konzistentného zoznamu, to znamená, že po každej úprave potrebujeme upraviť dobu predpokladaného vstupu do ambulancie, ktorá nesmie byť skôr ako je daný okamžik a ani sa nesmie prekrývať medzi dvoma pacientami. Toto zabezpečíme pomocou metódy `reconcileWaitingList`, ktorú naimplementujeme v triede `Ambulance`. Metódu vložíme do nového súboru, aby sme si neprepísali ručne vytvorený kód pri ďalšom použití nástroja [openapi-generator]. Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/ext_model_ambulance.go` a vložte do neho nasledujúci kód:

    ```go
    package ambulance_wl

    import (
        "time"

        "slices"
    )

    func (this *Ambulance) reconcileWaitingList() {
        slices.SortFunc(this.WaitingList, func(left, right WaitingListEntry) int {
            if left.WaitingSince.Before(right.WaitingSince) {
                return -1
            } else if left.WaitingSince.After(right.WaitingSince) {
                return 1
            } else {
                return 0
            }
        })

        // we assume the first entry EstimatedStart is the correct one (computed before previous entry was deleted)
        // but cannot be before current time
        // for sake of simplicity we ignore concepts of opening hours here

        if this.WaitingList[0].EstimatedStart.Before(this.WaitingList[0].WaitingSince) {
            this.WaitingList[0].EstimatedStart = this.WaitingList[0].WaitingSince
        }

        if this.WaitingList[0].EstimatedStart.Before(time.Now()) {
            this.WaitingList[0].EstimatedStart = time.Now()
        }

        nextEntryStart :=
            this.WaitingList[0].EstimatedStart.
                Add(time.Duration(this.WaitingList[0].EstimatedDurationMinutes) * time.Minute)
        for _, entry := range this.WaitingList[1:] {
            if entry.EstimatedStart.Before(nextEntryStart) {
                entry.EstimatedStart = nextEntryStart
            }
            if entry.EstimatedStart.Before(entry.WaitingSince) {
                entry.EstimatedStart = entry.WaitingSince
            }

            nextEntryStart =
                entry.EstimatedStart.
                    Add(time.Duration(entry.EstimatedDurationMinutes) * time.Minute)
        }
    }

    ```

    >info:> V nových vydania jazyka go je balík `slices` súčasťou štandardnej distribúcie. V prípade, že import balíka `slices` nie je rozpoznaný, zrejme používate staršiu verziu jazyka go. V takom prípade buď prejdite na novšiu verziu alebo zameňte import balíka `slices` za `golang.org/x/exp/slices`. Za účelom získania knižnice `golang.org/x/exp/slices` vykonajte na príkazovom riadku v priečinku `${WAC_ROOT}/ambulance-webapi` príkaz `go mod tidy`.

13. Teraz otvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_waiting_list.go` a upravte metódu `CreateWaitingList`:

    ```go
    package ambulance_wl

    import (
        "net/http" 

        "github.com/gin-gonic/gin"
        "github.com/google/uuid"  @_add_@
        "slices"  @_add_@
    )

    // CreateWaitingListEntry - Saves new entry into waiting list
    func (this *implAmbulanceWaitingListAPI) CreateWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented) @_remove_@
        // update ambulance document
        updateAmbulanceFunc(ctx, func(c *gin.Context, ambulance *Ambulance) (*Ambulance,  interface{},  int){    @_add_@
            var entry WaitingListEntry    @_add_@
        @_add_@
            if err := c.ShouldBindJSON(&entry); err != nil {    @_add_@
                return nil, gin.H{    @_add_@
                    "status": http.StatusBadRequest,    @_add_@
                    "message": "Invalid request body",    @_add_@
                    "error": err.Error(),    @_add_@
                }, http.StatusBadRequest    @_add_@
            }    @_add_@
        @_add_@
            if entry.PatientId == "" {    @_add_@
                return nil, gin.H{    @_add_@
                    "status": http.StatusBadRequest,    @_add_@
                    "message": "Patient ID is required",    @_add_@
                }, http.StatusBadRequest    @_add_@
            }    @_add_@
        @_add_@
            if entry.Id == "" || entry.Id == "@new" {    @_add_@
                entry.Id = uuid.NewString()    @_add_@
            }    @_add_@
        @_add_@
            conflictIndx := slices.IndexFunc( ambulance.WaitingList, func(waiting WaitingListEntry) bool {    @_add_@
                return entry.Id == waiting.Id || entry.PatientId == waiting.PatientId     @_add_@
            })    @_add_@
        @_add_@
            if conflictIndx >= 0 {    @_add_@
                return nil, gin.H{    @_add_@
                    "status": http.StatusConflict,    @_add_@
                    "message": "Entry already exists",    @_add_@
                }, http.StatusConflict    @_add_@
            }    @_add_@
        @_add_@
            ambulance.WaitingList = append(ambulance.WaitingList, entry)    @_add_@
            ambulance.reconcileWaitingList()    @_add_@
            // entry was copied by value return reconciled value from the list    @_add_@
            entryIndx := slices.IndexFunc( ambulance.WaitingList, func(waiting WaitingListEntry) bool {    @_add_@
                return entry.Id == waiting.Id    @_add_@
            })    @_add_@
            if entryIndx < 0 {    @_add_@
                return nil, gin.H{    @_add_@
                    "status": http.StatusInternalServerError,    @_add_@
                    "message": "Failed to save entry",    @_add_@
                }, http.StatusInternalServerError    @_add_@
            }    @_add_@
            return ambulance, ambulance.WaitingList[entryIndx], http.StatusOK    @_add_@
        })    @_add_@
    }
    ```

    V tejto funkcii postupujeme obdobne ako v prípade funkcie `GetConditions`, musíme ale ošetriť situácie, kedy je požiadavka neprípustná, napríklad odmietneme požiadavku na registráciu už čakajúceho pacienta, alebo požiadavku s duplikátnym identifikátorom. V prípade úspešného vytvorenia záznamu v zozname čakajúcich zavoláme metódu `reconcileWaitingList` na objekte `Ambulance`, ktorá zabezpečí konzistentnosť časových značiek zoznamu.

    Ďalej v tom istom súbore upravte metódu `DeleteWaitingListEntry`:

    ```go
    ...
    // DeleteWaitingListEntry - Deletes specific entry
    func (this *implAmbulanceWaitingListAPI) DeleteWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented) @_remove_@
        // update ambulance document
        updateAmbulanceFunc(ctx, func(c *gin.Context, ambulance *Ambulance) (*Ambulance, interface{}, int) {    @_add_@
            entryId := ctx.Param("entryId")    @_add_@
        @_add_@
            if entryId == "" {    @_add_@
                return nil, gin.H{    @_add_@
                    "status":  http.StatusBadRequest,    @_add_@
                    "message": "Entry ID is required",    @_add_@
                }, http.StatusBadRequest    @_add_@
            }    @_add_@
        @_add_@
            entryIndx := slices.IndexFunc(ambulance.WaitingList, func(waiting WaitingListEntry) bool {    @_add_@
                return entryId == waiting.Id    @_add_@
            })    @_add_@
        @_add_@
            if entryIndx < 0 {    @_add_@
                return nil, gin.H{    @_add_@
                    "status":  http.StatusNotFound,    @_add_@
                    "message": "Entry not found",    @_add_@
                }, http.StatusNotFound    @_add_@
            }    @_add_@
        @_add_@
            ambulance.WaitingList = append(ambulance.WaitingList[:entryIndx], ambulance.WaitingList[entryIndx+1:]...)    @_add_@
            ambulance.reconcileWaitingList()    @_add_@
            return ambulance, nil, http.StatusNoContent    @_add_@
        })    @_add_@
    }
    ```

    V tomto prípade nás zaujíma najmä či daný záznam existuje, pokiaľ áno, tak ho odstránime zo zoznamu a zavoláme metódu `reconcileWaitingList` na objekte `Ambulance`.

    Metódy `GetWaitingList` a `GetWaitingListEntry` sú pomerne priamočiare - vrátia aktuálny zoznam čakajúcich alebo požadovaný záznam pokiaľ existuje:

    ```go
    // GetWaitingListEntries - Provides the ambulance waiting list
    func (this *implAmbulanceWaitingListAPI) GetWaitingListEntries(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented) @_remove_@
        // update ambulance document
        updateAmbulanceFunc(ctx, func(c *gin.Context, ambulance *Ambulance) (*Ambulance, interface{}, int) {  @_add_@
            result := ambulance.WaitingList     @_add_@
            if result == nil {     @_add_@
                result = []WaitingListEntry{}     @_add_@
            }     @_add_@
            // return nil ambulance - no need to update it in db   @_add_@
            return nil, result, http.StatusOK     @_add_@
        })   @_add_@
    }

    // GetWaitingListEntry - Provides details about waiting list entry
    func (this *implAmbulanceWaitingListAPI) GetWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented) @_remove_@
        // update ambulance document
        updateAmbulanceFunc(ctx, func(c *gin.Context, ambulance *Ambulance) (*Ambulance, interface{}, int) {   @_add_@
            entryId := ctx.Param("entryId")   @_add_@
            @_add_@
            if entryId == "" {   @_add_@
                return nil, gin.H{   @_add_@
                    "status":  http.StatusBadRequest,   @_add_@
                    "message": "Entry ID is required",   @_add_@
                }, http.StatusBadRequest   @_add_@
            }   @_add_@
                @_add_@
            entryIndx := slices.IndexFunc(ambulance.WaitingList, func(waiting WaitingListEntry) bool {   @_add_@
                return entryId == waiting.Id   @_add_@
            })   @_add_@
            @_add_@
            if entryIndx < 0 {   @_add_@
                return nil, gin.H{   @_add_@
                    "status":  http.StatusNotFound,   @_add_@
                    "message": "Entry not found",   @_add_@
                }, http.StatusNotFound   @_add_@
            }   @_add_@
            @_add_@
            // return nil ambulance - no need to update it in db   @_add_@
            return nil, ambulance.WaitingList[entryIndx], http.StatusOK   @_add_@
        })   @_add_@
    }
    ```

    Nakoniec upravte implementáciu metódy `UpdateWaitingListEntry`:

    ```go
    // UpdateWaitingListEntry - Updates specific entry
    func (this *implAmbulanceWaitingListAPI) UpdateWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented) @_remove_@
        // update ambulance document
        updateAmbulanceFunc(ctx, func(c *gin.Context, ambulance *Ambulance) (*Ambulance, interface{}, int) {        @_add_@
            var entry WaitingListEntry      @_add_@
            @_add_@
            if err := c.ShouldBindJSON(&entry); err != nil {        @_add_@
                return nil, gin.H{      @_add_@
                    "status":  http.StatusBadRequest,       @_add_@
                    "message": "Invalid request body",      @_add_@
                    "error":   err.Error(),     @_add_@
                }, http.StatusBadRequest        @_add_@
            }       @_add_@
            @_add_@
            entryId := ctx.Param("entryId")     @_add_@
            @_add_@
            if entryId == "" {      @_add_@
                return nil, gin.H{      @_add_@
                    "status":  http.StatusBadRequest,       @_add_@
                    "message": "Entry ID is required",      @_add_@
                }, http.StatusBadRequest        @_add_@
            }       @_add_@
            @_add_@
            entryIndx := slices.IndexFunc(ambulance.WaitingList, func(waiting WaitingListEntry) bool {      @_add_@
                return entryId == waiting.Id        @_add_@
            })      @_add_@
            @_add_@
            if entryIndx < 0 {      @_add_@
                return nil, gin.H{      @_add_@
                    "status":  http.StatusNotFound,     @_add_@
                    "message": "Entry not found",       @_add_@
                }, http.StatusNotFound      @_add_@
            }       @_add_@
            @_add_@
            if entry.PatientId != "" {      @_add_@
                ambulance.WaitingList[entryIndx].PatientId = entry.PatientId        @_add_@
            }       @_add_@
            @_add_@
            if entry.Id != "" {     @_add_@
                ambulance.WaitingList[entryIndx].Id = entry.Id      @_add_@
            }       @_add_@
                    @_add_@
            if entry.WaitingSince.After(time.Time{}) {      @_add_@
                ambulance.WaitingList[entryIndx].WaitingSince = entry.WaitingSince      @_add_@
            }       @_add_@
            @_add_@
            if entry.EstimatedDurationMinutes > 0 {     @_add_@
                ambulance.WaitingList[entryIndx].EstimatedDurationMinutes = entry.EstimatedDurationMinutes      @_add_@
            }       @_add_@
            @_add_@
            ambulance.reconcileWaitingList()        @_add_@
            return ambulance, ambulance.WaitingList[entryIndx], http.StatusOK       @_add_@
        })      @_add_@
    }
    ```

    Všimnite si, že podobne ako v ostatných metódach sa snažíme zabezpečiť platnosť vlastností `PatientId` a `Id` objektu `WaitingListEntry`. Z našej schémy ale vyplýva,
    že tieto vlastnosti sú povinné, takže tento krok sa javí ako redundandný. Alternatívnym riešením by bolo použiť knižnicu na validáciu objektov podľa [JSONSchema] špecifikácii použitých v OpenAPI špecifikácii,
    ideálne už v kóde vygenerovanom nástrojom [openapi-generator]. Príkladom takejto knižnice je [github.com/santhosh-tekuri/jsonschema/v5](https://github.com/santhosh-tekuri/jsonschema).
    V každom prípade venujte konzistencii dát v databáze dostatočnú pozornosť.

14. Zmeny uložte a archivujte ich do git repozitára. V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkazy:

    ```ps
    git add .
    git commit -m "ambulance waiting list"
    git push
    ```

   Teraz máme naše WEB API implementované a môžeme ho použiť. V ďalšom kroku si pripravíme predpis pre jeho priebežnú integráciu a potom ho nasadíme do Kubernetes klastra.

   >home_work:> V tomto cvičení sme implementovali metódy potrebné pre funkcionalitu nášho web komponentu. Samostatne doplňte špecifikáciu a implementáciu pre úpravu a získanie ambulancie a pre prácu so zoznamom `predefinedConditions`.
