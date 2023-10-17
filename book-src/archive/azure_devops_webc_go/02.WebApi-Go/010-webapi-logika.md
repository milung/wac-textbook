## Základná logika a persistencia údajov web služby

V tejto kapitole si ukážeme, ako spracovať rôzne typy HTML požiadavok (POST/GET/DELETE). Na ukladanie údajov budeme používať databázu [MongoDB].

1. Skôr, než začneme, upravíme si modely. Otvorte súbor `model_ambulance.go`, ktorý bol vygenerovaný cez _Open API Generator_. Súbor obsahuje model ambulancie. _Open API Generator_ pridal ku každej členskej premennej značku `json:"id"`, čo znamená, že pri konvertovaní štruktúry `ambulance` do formátu _json_ bude táto premenná vystupovať pod menom _id_. Rovnaký postup treba zvoliť pri konvertovaní do databázového formátu. V tomto prípade sa jedná o kľúčové slovo _bson_. Upravte štruktúru nasledovne:

    ```go
    type Ambulance struct {
        // Unique identifier of the ambulance
        Id string `json:"id" bson:"Id"`
        // Human readable display name of the ambulance
        Name string `json:"name" bson:"Name,omitempty"`
        @_empty_line_@
        RoomNumber string `json:"roomNumber" bson:"RoomNumber,omitempty"`
        @_empty_line_@
        WaitingList []WaitingListEntry `json:"waitingList,omitempty" bson:"WaitingList,omitempty"`
        @_empty_line_@
        PredefinedConditions []Condition `json:"predefinedConditions,omitempty" bson:"PredefinedConditions,omitempty"`
    }
    ```

    >info:> Rovnako upravte aj ostatné modely.

2. Vzhľadom k tomu, že začíname s prázdnou databázou, prvou obslužnou funkciou, ktorú naimplementujeme, bude _CreateAmbulanceDetails_. Táto funkcia bude obsluhovať HTTP požiadavku typu POST. Otvorte súbor `rest-api\api_ambulance_admins.go` a upravte funkciu _CreateAmbulanceDetails_ nasledovne:

    ```go
    func CreateAmbulanceDetails(c *gin.Context) {
        var ambulance models.Ambulance
        if err := c.ShouldBindJSON(&ambulance); err != nil {
            log.Println(err)
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
        @_empty_line_@
        err := dbservice.CreateAmbulance(&ambulance)
        if err != nil {
            log.Println(err)
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
        @_empty_line_@
        log.Println("CreateAmbulanceDetails successfully created ambulance with id: ", ambulance.Id)
        c.JSON(http.StatusCreated, gin.H{"ambulanceId": ambulance.Id})
    }
    ```

   Prejdime si teraz jednotlivé časti kódu.

   * Metóda _ShouldBindJSON_ sa pokúsi naplniť objekt _ambulance_ dátami z tela príslušnej HTTP požiadavky. V prípade, že sa objekt naplniť nepodarí, web služba signalizuje chybové hlásenie typu _400: Bad Request_.

        ```go
        var ambulance models.Ambulance
        if err := c.ShouldBindJSON(&ambulance); err != nil {
            log.Println(err)
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
        ```

   * V prípade, že sa objekt _ambulance_ podarilo naplniť, posielame objekt do databázového servisu (ten zatiaľ nemáme naimplementovaný, pozri krok 2) s požiadavkou na vytvorenie ambulancie. Pokiaľ sa z akéhokoľvek dôvodu ambulanciu vytvoriť nepodarí (návratová hodnota obsahuje chybu), web služba signalizuje chybové hlásenie typu _400: Bad Request_.

        ```go
        err := dbservice.CreateAmbulance(&ambulance)
        if err != nil {
            log.Println(err)
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
        ```

   * Ak sa ambulanciu podarilo vytvoriť, web služba signalizuje úspešné vytvorenie hlásením typu _201: Created_.

        ```go
        log.Println("CreateAmbulanceDetails successfully created ambulance with id: ", ambulance.Id)
        c.JSON(http.StatusCreated, gin.H{"ambulanceId": ambulance.Id})
        ```

3. Ďalším krokom je naimplementovanie databázového servisu. Vytvorte nový priečinok `db-service` a v ňom súbor `db-service\mongodb_service.go`
  s nasledujúcim obsahom:

    ```go
    package dbservice
    @_empty_line_@
    import (
        "ambulance-webapi/models"
        "context"
        "errors"
        "log"
        "os"
        "time"
    @_empty_line_@
        "go.mongodb.org/mongo-driver/bson"
        "go.mongodb.org/mongo-driver/mongo"
        "go.mongodb.org/mongo-driver/mongo/options"
    )

    var myMongoDbClient *mongo.Client
    var myDBName string = <UNIKATNE_MENO_STRING> @_important_@
    @_empty_line_@
    func Connect() {
        ctx, contextCancel := context.WithTimeout(context.Background(), 10*time.Second)
        defer contextCancel()
            @_empty_line_@
        var monogdbUserName = os.Getenv("MONGODB_USERNAME")
        var mongodbPassword = os.Getenv("MONGODB_PASSWORD")
        var mongodbURI = os.Getenv("MONGODB_URI")
        if len(mongodbURI) == 0 {
            mongodbURI = "localhost:27017"
        }
        var uri = "mongodb://" + mongodbURI
        if len(monogdbUserName) != 0 && len(mongodbPassword) != 0 {
            uri = "mongodb://" + monogdbUserName + ":" + mongodbPassword + "@" + mongodbURI
        }
        log.Printf("Using URI: " + uri)
            @_empty_line_@
        client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri).SetConnectTimeout(10*time.Second))
        if err != nil {
            panic(err)
        }
    @_empty_line_@
        myMongoDbClient = client
    }
    @_empty_line_@
    func Disconnect() {
        if myMongoDbClient != nil {
            if err := myMongoDbClient.Disconnect(context.Background()); err != nil {
                panic(err)
            }
        }
    }
    @_empty_line_@
    func CreateAmbulance(ambulance *models.Ambulance) error {
        ctx, contextCancel := context.WithTimeout(context.Background(), 30*time.Second)
        defer contextCancel()
    @_empty_line_@
        defaultDb := myMongoDbClient.Database(myDBName)
        collection := defaultDb.Collection("Ambulances")
        cursor, err := collection.Find(ctx, bson.D{{Key:"Id", Value:ambulance.Id}})
        if err != nil {
            return err
        }
        var ambulances []models.Ambulance
        err = cursor.All(ctx, &ambulances)
        if err != nil {
            return err
        }
        @_empty_line_@
        if len(ambulances) > 0 {
            errorMessage := "Ambulance with following id already exists: " + ambulance.Id
            return errors.New(errorMessage)
        }
            @_empty_line_@
        _, err = collection.InsertOne(ctx, ambulance)
        return err
    }    
    ```

   Nahraďte `UNIKATNE_MENO_STRING` jednoznačným identifikátorom vašej databázy, napr. "MenoPriezviskoDB".

   V kóde nám pribudli importy na mongodb balíky, stiahnime si ich lokálne do projektu. V priečinku `ambulance-webapi` vykonajte príkaz:

    ```powershell
    go mod tidy
    ```

   Opäť si prejdime jednotlivé časti kódu.

   * Prvým riadkom sme zadefinovali nový balík - _package_. Balíky v jazyku _Go_ sú zoskupením súborov v určitom adresári. Plnia podobnú úlohu ako balíky v jazyku _Java_ a teda vytvárajú štruktúru vášho programu.

        ```go
        package dbservice
        ```

   * Nasleduje časť, v ktorej povieme, aké iné balíky budeme potrebovať. Čiže napríklad ak potrebujeme funkciu, ktorá je zadefinovaná v balíku `xyz`, musíme daný balík uviesť v takzvanej _import declaration_ časti.

        ```go
        import (
            "ambulance-webapi/models"
            "context"
            "errors"
            "log"
            "os"
            "time"
                @_empty_line_@
            "go.mongodb.org/mongo-driver/bson"
            "go.mongodb.org/mongo-driver/mongo"
            "go.mongodb.org/mongo-driver/mongo/options"
        )
        ```

   * Zadefinujeme privátnu premennú typu `*mongo.Client`.

     >info:> Na rozdiel od mnohých iných jazykov (napr. _C#_, _Java_), v ktorých sa na obmedzenie prístupu k objektom používa kľúčové slovo (napr. _private_ v prípade spomínaných _C#_ a _Java_), je v jazyku _Go_ objekt verejne dostupný (mimo balík, v ktorom je zadefinovaný), pokiaľ sa jeho meno začína veľkým písmenom. V prípade, že sa meno začína malým písmenom, objekt je dostupný len v rámci balíka.

     Premenná `myMongoDbClient` nám vytvorí prepojenie na databázu.

      ```go
      var myMongoDbClient *mongo.Client
      ```

   * Funkcia _Connect_ slúži na pripojenie sa na databázového klienta. Všimnite si použitie premenných prostredia, ktoré poslúžia na správne pripojenie sa na klienta. Zároveň môžte postrehnúť použitie dvoch nových kľúčových slov: _defer_ a _panic_.

     Funkcia uvedená za príkazom _defer_ sa vykoná vždy tesne pred ukončením funkcie, v ktorej sa vykonáva príkaz _defer_.

     Kľúčové slovo _panic_ slúži na vyvolanie okamžitého ukončenia programu. Jeho použitie treba zvážiť. V našom prípade nie je možné pokračovať ďalej, ak sa nepodarí pripojiť na mongo klienta, preto program ukončíme.

        ```go
        func Connect() {
            ctx, contextCancel := context.WithTimeout(context.Background(), 10*time.Second)
            defer contextCancel()
                @_empty_line_@
            var monogdbUserName = os.Getenv("MONGODB_USERNAME")
            var mongodbPassword = os.Getenv("MONGODB_PASSWORD")
            var mongodbURI = os.Getenv("MONGODB_URI")
            if len(mongodbURI) == 0 {
                mongodbURI = "localhost:27017"
            }
            var uri = "mongodb://" + mongodbURI
            if len(monogdbUserName) != 0 && len(mongodbPassword) != 0 {
                uri = "mongodb://" + monogdbUserName + ":" + mongodbPassword + "@" + mongodbURI
            }
            log.Printf("Using URI: " + uri)
                @_empty_line_@
            client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri).SetConnectTimeout(10*time.Second))
            if err != nil {
                panic(err)
            }
            @_empty_line_@
            myMongoDbClient = client
        }
        ```

        >info:> Samotné pripojenie sa na klienta (t.j., že metóda _mongo.Connect_ vrátila validný objekt _mongo.Client_) ešte neznamená, že pripojenie na databázu  bude úspešné (t.j. validný _mongo.Client_ objekt nerovná sa validnému napojeniu sa na databázu). Jedným z častých problémov býva použitie nesprávnej konfigurácie. Na overenie, či sa na databázu dá napojiť, sa dá použiť funkcia _Client.Ping_. Jej použitie však treba zvážiť. Treba si uvedomiť, že funkcia _Client.Ping_ môže skončiť chybou aj v prípade, že je mongo server len dočasne nedostupný (napríklad počas automatického škálovania v dôsledku zvýšenia zaťaženia servera). Pružnosť aplikácie sa použitím funkcie _Client.Ping_ znižuje, my sme sa rozhodli ju nepoužiť.

   * Funkcia _Disconnect_ je symetrická k predchádzajúcej funkcii _Connect_ a slúži na odpojenie sa od databázového klienta.

        ```go
        func Disconnect() {
            if myMongoDbClient != nil {
                if err := myMongoDbClient.Disconnect(context.Background()); err != nil {
                    panic(err)
                }
            }
        }
        ```

   * No a napokon funkcia _CreateAmbulance_.

     >info:> Jej volanie sme videli v obslužnom kóde HTTP požiadavky. V tomto kroku treba upraviť _import_ v súbore `api_ambulance_admins.go` tak, aby vedel pracovať s metódou _CreateAmbulance_.

     Všimnite si, že tu už pracujeme s funkciami, metódami a štruktúrami, ktoré sa nachádzajú v balíkoch _go.mongodb.org_. Najprv zisťujeme, či sa už ambulancia s rovnakým _id_ nenachádza v databáze. Ak nie, ambulanciu vložíme do databázy.

      ```go
        func CreateAmbulance(ambulance *models.Ambulance) error {
            ctx, contextCancel := context.WithTimeout(context.Background(), 30*time.Second)
            defer contextCancel()
                @_empty_line_@
            defaultDb := myMongoDbClient.Database(myDBName)
            collection := defaultDb.Collection("Ambulances")
            cursor, err := collection.Find(ctx, bson.D{{Key:"Id", Value:ambulance.Id}})
            if err != nil {
                return err
            }
            var ambulances []models.Ambulance
            err = cursor.All(ctx, &ambulances)
            if err != nil {
                return err
            }
            @_empty_line_@
            if len(ambulances) > 0 {
                errorMessage := "Ambulance with following id already exists: " + ambulance.Id
                return errors.New(errorMessage)
            }
                        @_empty_line_@
            _, err = collection.InsertOne(ctx, ambulance)
            return err
        }
      ```

4. Ako ste už iste postrehli, metódy _Connect_ a _Disconnect_ z databázového servisu ešte nie sú použité. Otvorte súbor `main.go` a upravte ho nasledovne:

    ```go
    package main
            @_empty_line_@
    import (
        "ambulance-webapi/db-service"
        "ambulance-webapi/router"
        "log"
    )
            @_empty_line_@
    func main() {
        log.Printf("Server started")
            @_empty_line_@
        dbservice.Connect()
        defer dbservice.Disconnect()
            @_empty_line_@
        router := router.NewRouter()
            @_empty_line_@
        log.Fatal(router.Run(":8080"))
    }
    ```

    >info:> Po týchto úpravách je naša webová služba schopná prijať a spracovať požiadavku na vytvorenie novej ambulancie. Vytvorenú ambulanciu následne uloží do databázy.

5. Ďalším logickým krokom je spracovanie požiadavky typu GET, ktorá nám vráti detaily ambulancie, ktorej _id_ príde ako parameter v URL príslušnej požiadavky. V súbore `api_ambulance_developers.go` upravte funkciu _GetAmbulanceDetails_ (nezabudnite upraviť časť _import_):

    ```go
    func GetAmbulanceDetails(c *gin.Context) {
        ambulance, err := dbservice.GetAmbulance(c.Param("ambulanceId"))
        if err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
            @_empty_line_@
        c.JSON(http.StatusOK, ambulance)
    }
    ```

   V tomto stave nám VS Code ukazuje chybu - metóda _GetAmbulance_ neexistuje. Naimplementujte túto metódu v súbore `mongodb_service.go` (opäť nezabudnite upraviť časť _import_):

    ```go
    func GetAmbulance(id string) (models.Ambulance, error) {
        ctx, contextCancel := context.WithTimeout(context.Background(), 30*time.Second)
        defer contextCancel()
            @_empty_line_@
        defaultDb := myMongoDbClient.Database(myDBName)
        collection := defaultDb.Collection("Ambulances")
        cursor, err := collection.Find(ctx, bson.D{{Key:"Id", Value:id}})
        if err != nil {
            return models.Ambulance{}, err
        }
            @_empty_line_@
        var ambulances []models.Ambulance
        err = cursor.All(ctx, &ambulances)
        if err != nil {
            return models.Ambulance{}, err
        }
            @_empty_line_@
        countOfAmbulancesWithGivenId := len(ambulances)
        if countOfAmbulancesWithGivenId == 0 {
            errorMessage := "Ambulance with following id does not exist: " + id
            return models.Ambulance{}, errors.New(errorMessage)
        }
            @_empty_line_@
        if countOfAmbulancesWithGivenId > 1 {
            errorMessage := "There are" + strconv.Itoa(countOfAmbulancesWithGivenId) + "ambulances with following id:" + id
            return models.Ambulance{}, errors.New(errorMessage)
        }
            @_empty_line_@
        return ambulances[0], nil
    }   
    ```

6. Teraz už vieme pridať novú ambulanciu, vieme si vypýtať detaily ambulancie, nasleduje pridanie pacienta do zoznamu čakajúcich. V súbore `api_ambulance_developers.go` naimplementujte funkciu _StoreWaitingListEntry_:

    ```go
    func StoreWaitingListEntry(c *gin.Context) {
        ambulance, err := dbservice.GetAmbulance(c.Param("ambulanceId"))
        if err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
            @_empty_line_@
        var waitingListEntry models.WaitingListEntry
        if err := c.ShouldBindJSON(&waitingListEntry); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
            @_empty_line_@
        if ambulance.ContainsWaitingListEntry(waitingListEntry) {
            errorMessage := "Patient with PatientId " + waitingListEntry.PatientId + " already in waiting list"
            c.JSON(http.StatusBadRequest, gin.H{"error": errorMessage})
            return
        }
            @_empty_line_@
        updatedWaitingList := append(ambulance.WaitingList, waitingListEntry)
        if err := dbservice.UpdateWaitingListForAmbulance(ambulance.Id, updatedWaitingList); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
            @_empty_line_@
        c.JSON(http.StatusOK, gin.H{})
    }
    ```

    V súbore `mongodb_service.go` naimplementujte funkciu _UpdateWaitingListForAmbulance_:

    ```go
    func UpdateWaitingListForAmbulance(ambulanceId string, waitingList []models.WaitingListEntry) error {
        ctx, contextCancel := context.WithTimeout(context.Background(), 30*time.Second)
        defer contextCancel()
            @_empty_line_@
        defaultDb := myMongoDbClient.Database(myDBName)
        collection := defaultDb.Collection("Ambulances")
            @_empty_line_@
        _, err := collection.UpdateOne(
            ctx,
            bson.M{"Id": ambulanceId},
            bson.M{"$set": bson.M{"WaitingList": waitingList}},
        )
            @_empty_line_@
        if err != nil {
            return err
        }
            @_empty_line_@
        return nil
    }
    ```

    >info:> Všimnite si volanie funkcie _UpdateOne_. Druhým parametrom povieme, aký záznam v databáze chceme meniť, v našom prípade to bude ambulancia s príslušným Id. Tretím parametrom špecifikujeme, aká modifikácia sa má vykonať. Nami použitý operátor _set_ prepíše hodnotu vstupného parametra v databáze. V prípade, že príslušné pole v databáze ešte neexistuje, vytvorí sa preň nová položka s hodnotou, ktorú do funkcie posielame.

    Určite ste si vo funkcii _StoreWaitingListEntry_ všimli volanie:

    ```go
    ambulance.ContainsWaitingListEntry(waitingListEntry)
    ```

    Premenná _ambulance_ je typu _Ambulance_, pričom _Ambulance_ je obyčajná štruktúra. Ako je teda možné volať funkciu nad štruktúrou? Jazyk `go` umožňuje zadefinovať takzvané _metódy_ nad akýmkoľvek typom, ktoré následne môžme volať rovnakým spôsobom, ako voláme funkcie. Je to obdoba `extension` metód, ktoré môžte poznať z jazyka _C#_. V súbore `model_ambulance.go` doplňte metódu _ContainsWaitingListEntry_:

    ```go
    func (ambulance *Ambulance) ContainsWaitingListEntry(waitingListEntry WaitingListEntry) bool {
        for _, entry := range ambulance.WaitingList {
            if entry.PatientId == waitingListEntry.PatientId {
                return true
            }
        }
            @_empty_line_@
        return false
    }
    ```

7. Ďalšou požiadavkou, ktorú si spolu naimplementujeme, je požiadavka typu DELETE, ktorá vymaže pacienta zo zoznamu čakajúcich. Naimplementujte funkciu _DeleteWaitingListEntry_ v súbore `api_ambulance_developers.go`:

    ```go
    func DeleteWaitingListEntry(c *gin.Context) {
        err := dbservice.DeleteWaitingListEntry(c.Param("ambulanceId"), c.Param("entryId"))
        if err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusOK, gin.H{})
    }
    ```

    Následne naimplementujte funkciu _DeleteWaitingListEntry_ v súbore `mongodb_service.go`. Súčasťou implementácie budú aj ďalšie úpravy, takzvaný `refaktoring`.

    >info:> Refaktoring je častý postup používaný pri vývoji, kedy sa existujúci kód upravuje na základe novovzniknutých potrieb. Nevyhnutnou podmienkou pre úspešný refaktoring je mať dobre napísané testy, aby sa tak predišlo zavedeniu zmien vedúcich k chybám. V našom prípade túto zásadu porušíme (ako už bolo spomínané, táto verzia skrípt sa zameriava na iné aspekty, viac o testovaní si môžete prečítať v predchádzajúcej verzii).

    ```go
    func GetAmbulance(id string) (models.Ambulance, error) {
        ambulance, _, err := getAmbulance(id)
        return ambulance, err
    }
                @_empty_line_@
    func getAmbulance(id string) (models.Ambulance, *mongo.Collection, error) {
        ctx, contextCancel := context.WithTimeout(context.Background(), 30*time.Second)
        defer contextCancel()
            @_empty_line_@
        defaultDb := myMongoDbClient.Database(myDBName)
        collection := defaultDb.Collection("Ambulances")
        cursor, err := collection.Find(ctx, bson.D{{Key: "Id", Value: id}})
        if err != nil {
            return models.Ambulance{}, nil, err
        }
            @_empty_line_@
        var ambulances []models.Ambulance
        err = cursor.All(ctx, &ambulances)
        if err != nil {
            return models.Ambulance{}, nil, err
        }
            @_empty_line_@
        countOfAmbulancesWithGivenId := len(ambulances)
        if countOfAmbulancesWithGivenId == 0 {
            errorMessage := "Ambulance with following id does not exist: " + id
            return models.Ambulance{}, nil, errors.New(errorMessage)
        }
            @_empty_line_@
        if countOfAmbulancesWithGivenId > 1 {
            errorMessage := "There are" + strconv.Itoa(countOfAmbulancesWithGivenId) + "ambulances with following id:" + id
            return models.Ambulance{}, nil, errors.New(errorMessage)
        }
            @_empty_line_@
        return ambulances[0], collection, nil
    }
            @_empty_line_@
    func DeleteWaitingListEntry(ambulanceId string, entryId string) error {
        ambulance, collection, err := getAmbulance(ambulanceId)
        if err != nil {
            return err
        }
            @_empty_line_@
        for index, entry := range ambulance.WaitingList {
            if entry.Id == entryId {
                ctx, contextCancel := context.WithTimeout(context.Background(), 30*time.Second)
                defer contextCancel()
            @_empty_line_@
                waitingList := removeEntry(ambulance.WaitingList, index)
                _, err := collection.UpdateOne(
                    ctx,
                    bson.M{"Id": ambulanceId},
                    bson.M{"$set": bson.M{"WaitingList": waitingList}},
                )
            @_empty_line_@
                if err != nil {
                    return err
                }
                return nil
            }
        }
        errorMessage := "There is no entry with id: " + entryId + " for ambulance with following id: " + ambulanceId
        return errors.New(errorMessage)
    }
            @_empty_line_@
    func removeEntry(waitingList []models.WaitingListEntry, index int) []models.WaitingListEntry {
        return append(waitingList[:index], waitingList[index+1:]...)
    }
    ```

8. Aby bola naša webová služba plne funkčná a aby podporovala všetky metódy použité v našich web komponentoch, potrebujeme ešte naimplementovať nasledovné funkcie:
   * GetWaitingListEntries
   * GetWaitingListEntry
   * UpdateWaitingListEntry
   * GetConditions

   Bez bližšieho popisu uvádzame prvé tri:

   ```go
   func GetWaitingListEntries(c *gin.Context) {
     ambulance, err := dbservice.GetAmbulance(c.Param("ambulanceId"))
     if err != nil {
         c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
         return
     }
                  @_empty_line_@
     // v pripade, ze je zoznam prazdny(nil), vratime prazdne pole, aby klient nemal problem
     if ambulance.WaitingList == nil {
       ambulance.WaitingList = []models.WaitingListEntry{}
     }
                  @_empty_line_@
     c.JSON(http.StatusOK, ambulance.WaitingList)
   }
            @_empty_line_@
   func GetWaitingListEntry(c *gin.Context) {
     ambulanceId := c.Param("ambulanceId")
     entryId := c.Param("entryId")
                  @_empty_line_@
     ambulance, err := dbservice.GetAmbulance(ambulanceId)
     if err != nil {
         c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
         return
     }
            @_empty_line_@
     for _, entry := range ambulance.WaitingList {
       if entry.Id == entryId {
         c.JSON(http.StatusOK, entry)
         return
       }
     }
            @_empty_line_@
     c.JSON(http.StatusBadRequest, gin.H{"error": "Given entryId not found in DB"})
   }
            @_empty_line_@
   func UpdateWaitingListEntry(c *gin.Context) {
     ambulanceId := c.Param("ambulanceId")
     entryId := c.Param("entryId")
                  @_empty_line_@
     var entry models.WaitingListEntry
     if err := c.ShouldBindJSON(&entry); err != nil {
         c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
         return
     }
            @_empty_line_@
     ambulance, err := dbservice.GetAmbulance(ambulanceId)
     if err != nil {
         c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
         return
     }
            @_empty_line_@
     foundIndex := -1
     for index, entry := range ambulance.WaitingList {
       if entry.Id == entryId {
           foundIndex = index
       }
     }
            @_empty_line_@
     if foundIndex == -1 {
       errorMessage := "Patient with id " + entryId + " is not in the database!"
       c.JSON(http.StatusBadRequest, gin.H{"error": errorMessage})
       return
     }
            @_empty_line_@
     ambulance.WaitingList[foundIndex] = entry
            @_empty_line_@
     if err := dbservice.UpdateWaitingListForAmbulance(ambulance.Id, ambulance.WaitingList); err != nil {
       c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
       return
     }
            @_empty_line_@
     c.JSON(http.StatusOK, gin.H{})
   }
   ```

9. Poslednú potrebnú funkciu obsluhujúcu požiadavku typu GET pre URI `/api/waiting-list/:ambulanceId/condition`, funkciu _GetConditions_, si vyskúšajte naimplementovať sami.

10. Zostávajúce nenaimplementované funkcie v súboroch `api_ambulance_developers.go` a `api_ambulance_admins.go` upravte tak, aby vracali **Not Implemented** status.

    ```go
    c.JSON(http.StatusNotImplemented, gin.H{})
    ```

11. Ako posledný krok adaptujeme Dockerfile, keďže sme pridali nový priečinok `db-service`.

    ```yaml
    ...
    COPY models ./models
    COPY rest-api ./rest-api
    COPY router ./router
    COPY db-service ./db-service  #  <-- pridany riadok
    COPY main.go .
    ...
    ```

    Vyskúšajte zbuildovať docker image. V priečinku `...    \ambulance-webapi` vykonajte príkaz

    ```ps
    docker build -t ambulance-webapi-test:latest .
    ```

    Archivujte váš kód do vzdialeného repozitára a skontrolujte, či     prebehol CI build a či sa aktualizoval pod (verzia docker obrazu) v     lokálnom kubernetes klastri.

    V ďalšom kroku vyskúšame funkčnosť a inicializujeme databázu s  využitím nástroja [Postman](https://www.getpostman.com/).
