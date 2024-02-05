# Testovanie v jazyku Go

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-api-050`

---

Testovanie je integrálnou súčasťou programovania s rovnakou dôležitosťou ako samotný zdrojový kód.

V jazyku [Go](https://go.dev/doc/tutorial/add-a-test) je zaintegrovaný jednoduchý framework na podporu testovania, ktorý pozostáva z príkazu [go test](https://pkg.go.dev/cmd/go#hdr-Test_packages) a balíka [testing](https://pkg.go.dev/testing).
Príkazom `go test` sa spustia všetky funkcie, ktoré spĺňajú nasledovné podmienky:

* Funkcia má signatúru `func (t *testing.T)`.
* Meno funkcie začína `Test` a pokračuje akýmkoľvek textom začínajúcim veľkým písmenom, napríklad `TestExample`.
* Názov súboru končí príponou `_test.go`, napríklad `api-admins_test.go`.

>info:> Okrem funkcií začínajúcich na `Test` spúšťa `go test` príkaz aj [iné typy funkcií](https://pkg.go.dev/cmd/go#hdr-Testing_functions) a to takzvané `benchmark` a `example` funkcie.

Tak ako v prípade vývoja web komponentu, aj tu si ukážeme len príklad vytvorenia jednotkového testu. Použijeme pri tom knižnicu [testify](https://pkg.go.dev/github.com/stretchr/testify#section-directories), ktorá poskytuje rozšírenia nad balíkom `testing`, najmä s ohľadom na vyhodnocovanie výsledkov testov a vytváranie  zástupných inštancií - _mockov_. Pokúsime sa aj ukázať odporúčaný postup pri vytváraní testov, vhodný aj na vytváranie testov metódou [Test Driven Development](https://en.wikipedia.org/wiki/Test-driven_development).

1. Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_waiting_list_test.go` s nasledujúcim obsahom:

    ```go
    package ambulance_wl

    import (
        "testing"

        "github.com/stretchr/testify/suite"
    )

    type AmbulanceWlSuite struct {
        suite.Suite
    }

    func TestAmbulanceWlSuite(t *testing.T) {
        suite.Run(t, new(AmbulanceWlSuite))
    }

    func (suite *AmbulanceWlSuite) Test_UpdateWl_DbServiceUpdateCalled() {
        // ARRANGE

        // ACT

        // ASSERT
    }
    ```

   Vytvorili sme základnú štruktúru nášho testu a testovacej zostavy. Súbor `impl_ambulance_waiting_list_test.go` je ukončený príponou `_test.go`, čo umožní nástrojom jazyka GO rozoznať ho ako súbor obsahujúci testovacie funkcie. Funkcia `TestAmbulanceWlSuite(t *testing.T)` zasa dodržuje pravidlá pre testovacie funkcie, ktoré sme spomínali vyššie. Funkcia `Test_UpdateWl_DbServiceUpdateCalled()` je našou testovacou funkciou, ktorá zasa spĺňa interné požiadavky knižnice _testify_.

   Testovaciu funkciu sme najprv rozdelili do sekcií `// ARRANGE`, `// ACT`, a `// ASSERT`. Tento prístup je odporúčaný, pretože zvyšuje čitateľnosť testovacej funkcie a zároveň umožňuje jednoduchšie vytváranie testov. V sekcii `// ARRANGE` vytvoríme všetky potrebné objekty a nastavíme ich do požadovaného stavu. V sekcii `// ACT` vykonáme _akciu_ alebo sadu akcií, ktorých funkcionalitu sa snažíme overiť.

   >info:> Pokiaľ sa Vám v nasledujúcich krokoch zobrazujú v editore chyby spôsobené neprítomnosťou knižníc, môžete ich kedykoľvek pridať medzi závislosti a doinštalovať ich príkazom `go mod tidy`. Tento príkaz tiež vykonáme v kroku 7.

2. Začíname v sekcii `// ASSERT`, kde sa snažíme určiť spôsob, akým overíme, či výsledok alebo vedľajšie efekty zodpovedajú naším očakávaniam. V tomto prípade chceme overiť, že po požiadavke na aktualizáciu zoznamu čakajúcich je volaná funkcia `UpdateDocument` triedy `DbService` (kde miesto reálnej inštancie `DbService` použijeme jej `mock`). Doplňte do sekcie `// ARRANGE` nasledujúci kód

   ```go
   ...
   func (suite *AmbulanceWlSuite) Test_UpdateWl_DbServiceUpdateCalled() {
      // ARRANGE

      // ACT

      // ASSERT
      suite.dbServiceMock.AssertCalled(suite.T(), "UpdateDocument", mock.Anything, "test-ambulance", mock.Anything)  @_add_@
    }
    ```

   >info:> Význam volania funkcie ozrejmíme neskôr. Na začiatku vytvárania testu môžete kľudne improvizovať, pri technike [TDD] je to dokonca žiadúce, pretože otázky typu _Ako overím funkcionalitu?_, _Ako požadovanú funkcionalitu vyvolám?_, alebo _Ako pripravím prostredie pre vykonanie požadovanej funkcionality?_ pomáhajú vytvoriť zrozumiteľnú, zmysluplnú, a najmä testovateľnú štruktúru výsledného kódu.

3. Ďalej pokračujeme sekciou `// ACT`, kde určíme ako sa má vyvolať požadovaná funkcionalita - v našom prípade to bude volanie funkcie `UpdateWaitingListEntry` našej triedy `implAmbulanceWaitingListAPI`. V tejto sekcii vždy používame funkcie, ktorých volanie je očakávané od externých subjektov - subjektov mimo našej testovanej jednotky. Typicky to sú funkcie označované ako aplikačné rozhranie, verejné metódy a podobne. Vytvorte v sekcii `// ACT` nasledujúci kód:

   ```go
   func (suite *AmbulanceWlSuite) Test_UpdateWl_DbServiceUpdateCalled() {
        // ARRANGE

        // ACT
        sut.UpdateWaitingListEntry(ctx) @_add_@

        // ASSERT
        suite.dbServiceMock.AssertCalled(suite.T(), "UpdateDocument", mock.Anything, "test-ambulance", mock.Anything)
   }
   ```

4. Nakoniec pripravíme podmienky pre testovanie. V sekcii `// ARRANGE` vytvoríme inštanciu triedy `implAmbulanceWaitingListAPI`. Vytvoríme inštanciu triedy `gin.Context` a upravíme jej vlastnosti tak, aby zodpovedali reálnemu volaniu metódy `UpdateWaitingListEntry`. V kóde použijeme zástupné objekty poskytované knižnicou [gin], ako aj zástupné objekty z knižnice [httptest](https://pkg.go.dev/net/http/httptest). Vytvorte v sekcii `// ARRANGE` nasledujúci kód:

   ```go
   func (suite *AmbulanceWlSuite) Test_UpdateWl_DbServiceUpdateCalled() {
        // ARRANGE
        json := `{ @_add_@
          "id": "test-entry", @_add_@
          "patientId": "test-patient", @_add_@
          "estimatedDurationMinutes": 42 @_add_@
        }`    @_add_@
        @_add_@
        gin.SetMode(gin.TestMode) @_add_@
        recorder := httptest.NewRecorder() @_add_@
        ctx, _ := gin.CreateTestContext(recorder) @_add_@
        ctx.Set("db_service", suite.dbServiceMock) @_add_@
	    ctx.Params = []gin.Param{ @_add_@
		    {Key: "ambulanceId", Value: "test-ambulance"}, @_add_@
		    {Key: "entryId", Value: "test-entry"}, @_add_@
	    } @_add_@
        ctx.Request = httptest.NewRequest("POST", "/ambulance/test-ambulance/waitinglist/test-entry", strings.NewReader(json)) @_add_@

        sut := implAmbulanceWaitingListAPI{} @_add_@

        // ACT
        sut.UpdateWaitingListEntry(ctx)

        // ASSERT
        suite.dbServiceMock.AssertCalled(suite.T(), "UpdateDocument", mock.Anything, "test-ambulance", mock.Anything)
    }
   ```

5. V sekcii `\\ ASSERT` sme použili objekt `suite.dbServiceMock`. Tu si ukážeme, ako vytvoriť zástupný objekt - _mock_ - a ako zjednodušiť písanie testu umiestnením spoločnej inicializácie do metódy `SetupTest`. V súbore `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_waiting_list_test.go` deklarujte novú štruktúru `DbServiceMock` a implementujte na nej metódy rozhrania `db_service.DbService`. Štruktúra `DbServiceMock` bude pritom odvodená od typu - _obsahuje_ - [mock.Mock](https://pkg.go.dev/github.com/stretchr/testify@v1.8.4/mock#Mock).

    ```go
    ...
    type AmbulanceWlSuite struct {
      suite.Suite
      dbServiceMock *DbServiceMock[Ambulance] @_add_@
    }

    func TestAmbulanceWlSuite(t *testing.T) {
        suite.Run(t, new(AmbulanceWlSuite))
    }

    type DbServiceMock[DocType interface{}] struct {    @_add_@
        mock.Mock              @_add_@
    }              @_add_@
               @_add_@
    func (this *DbServiceMock[DocType]) CreateDocument(ctx context.Context, id string, document *DocType) error {              @_add_@
        args := this.Called(ctx, id, document)             @_add_@
        return args.Error(0)               @_add_@
    }              @_add_@
               @_add_@
    func (this *DbServiceMock[DocType]) FindDocument(ctx context.Context, id string) (*DocType, error) {               @_add_@
        args := this.Called(ctx, id)               @_add_@
        return args.Get(0).(*DocType), args.Error(1)               @_add_@
    }              @_add_@
               @_add_@
    func (this *DbServiceMock[DocType]) UpdateDocument(ctx context.Context, id string, document *DocType) error {              @_add_@
        args := this.Called(ctx, id, document)             @_add_@
        return args.Error(0)               @_add_@
    }              @_add_@
               @_add_@
    func (this *DbServiceMock[DocType]) DeleteDocument(ctx context.Context, id string) error {             @_add_@
        args := this.Called(ctx, id)               @_add_@
        return args.Error(0)               @_add_@
    }              @_add_@
               @_add_@
    func (this *DbServiceMock[DocType]) Disconnect(ctx context.Context) error {            @_add_@
        args := this.Called(ctx)               @_add_@
        return args.Error(0)               @_add_@
    }              @_add_@

    func (suite *AmbulanceWlSuite) Test_UpdateWl_DbServiceUpdateCalled() {
    ...
    ```

    Implementované metódy len prevolávajú funkciu `Called`, ktorej implementácia je poskytnutá obsiahnutým objektom `mock.Mock`. Samotný výsledok je typu `mock.Arguments` a je určený pomocou metódy `mock.Mock.On`, ktorú použijeme v ďalšom kroku.

6. Väčšina našich testov bude používať rovnaký objekt `dbServiceMock`, preto ho vytvoríme v metóde `SetupTest`, taktiež v ňom pripravíme odpoveď pre volanie metódy `FindDocument`, kde poskytneme nejakú jednoduchú inštanciu typu `Ambulance`. V súbore `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_waiting_list_test.go` doplňte nasledujúci kód:

    ```go
    ...
    func (this *DbServiceMock[DocType]) Disconnect(ctx context.Context) error {
        ...
    }

    func (suite *AmbulanceWlSuite) SetupTest() {    @_add_@
        suite.dbServiceMock = &DbServiceMock[Ambulance]{}                @_add_@
                 @_add_@
        // Compile time Assert that the mock is of type db_service.DbService[Ambulance]              @_add_@
        var _ db_service.DbService[Ambulance] = suite.dbServiceMock              @_add_@
                 @_add_@
        suite.dbServiceMock.                 @_add_@
            On("FindDocument", mock.Anything, mock.Anything).                @_add_@
            Return(              @_add_@
                &Ambulance{              @_add_@
                    Id: "test-ambulance",                @_add_@
                    WaitingList: []WaitingListEntry{                 @_add_@
                        {                @_add_@
                            Id:                       "test-entry",              @_add_@
                            PatientId:                "test-patient",                @_add_@
                            WaitingSince:             time.Now(),                @_add_@
                            EstimatedDurationMinutes: 101,               @_add_@
                        },               @_add_@
                    },               @_add_@
                },               @_add_@
                nil,                 @_add_@
            )                @_add_@
    }                @_add_@
    
    func (suite *AmbulanceWlSuite) Test_UpdateWl_DbServiceUpdateCalled() {
    ...
    ```

    Podobne, ako sme pripravili volanie metódy `FindDocument`, pripravíme aj volanie metódy `UpdateDocument`, tentoraz túto prípravu vykonáme v sekcii `// ARRANGE` nášho testu:

    ```go
    func (suite *AmbulanceWlSuite) Test_UpdateWl_DbServiceUpdateCalled() {
      // ARRANGE
      suite.dbServiceMock.  @_add_@
          On("UpdateDocument", mock.Anything, mock.Anything, mock.Anything).  @_add_@
          Return(nil)  @_add_@

      json := `{
      ...
    ```

    Je na nás, ktoré metódy pripravíme v metóde `SetupTest` a ktoré v sekcii `// ARRANGE`. Všeobecne platí, že metódy, ktoré budú použité vo väčšine testov, je vhodné pripraviť v metóde `SetupTest`, ostatné metódy pripravíme v sekcii `// ARRANGE`. V prípade, že v danom teste potrebujeme odlišné správanie danej metódy, môžeme vyvolať fukciu `Unset` na objekte navrátenom pri volaní metódy `On`.
  
7. V súbore `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_waiting_list_test.go` upravte referencie na externé knižnice:

    ```go
    package ambulance_wl

    import (
        "context"   @_add_@
        "net/http/httptest"   @_add_@
        "strings"   @_add_@
        "testing"
        "time"    @_add_@
        
        "github.com/gin-gonic/gin"    @_add_@
        "github.com/stretchr/testify/mock"    @_add_@
        "github.com/<github-id>/ambulance-webapi/internal/db_service"    @_add_@
        "github.com/stretchr/testify/suite"
    )
    ```

   V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkaz

   ```ps
    go mod tidy
   ```

8. Overte, či vykonanie testov skončí úspešne:  V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkaz

   ```ps
   go test ./...
   ```

   Mali by ste vidieť výsledky obdobné tomuto:

   ```text
   ?       github.com/milung/ambulance-webapi/api  [no test files]
   ?       github.com/milung/ambulance-webapi/cmd/ambulance-api-service    [no test files]
   ?       github.com/milung/ambulance-webapi/internal/db_service  [no test files]
   ok      github.com/milung/ambulance-webapi/internal/ambulance_wl        0.031s @_important_@
   ```

   >info:> Pokiaľ máte vo Visual Studio Code nainštalované rozšírenie [golang.go](https://marketplace.visualstudio.com/items?itemName=golang.Go), tak môžete testy vykonávať alebo ladiť priamo z prostredia VS Code.

   Pokiaľ by sme postupovali striktne metódou [TDD], tak by v tomto kroku ešte nebola naša metóda `UpdateWaitingListEntry` implementovaná - vracala by chybový kód `501 - Not Implemented`. Funkcionalitu by sme postupne pridávali len na základe nových požiadaviek, k čomu by sme vytvárali potrebné testy a prípadne by sme refaktorovali zdrojový kód pri súčasnom zachovaní pôvodnej požadovanej funkcionality - overenej už existujúcimi testami. Testy by zároveň odrážali, aká funkcionalita je požadavaná a implementovaná. Častým nedostatkom nekvalitných testovacích sád je, že sa len snažia opísať a verifikovať ako je kód implementovaný, ale nezohľadňujú, či je implementovaný kód vôbec požadovaný a z akej požadovanej funkcionality daná implementácia vychádza.

9. Upravte súbor `${WAC_ROOT}/ambulance-webapi/scripts/run.ps1` - doplňte príkaz na vykonávanie testov:

   ```ps
   ...
   switch ($command) {
       ...
       "start" {
           ...
       }
       "test" {     @_add_@
           go test -v ./...     @_add_@
       }     @_add_@
       "mongo" {
       ...
   ```

10. Zmeny uložte a archivujte ich do git repozitára. V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkazy:

    ```ps
    git add .
    git commit -m "ambulance waiting list first test"
    git push

>homework:> Samostatne doplňte aspoň jeden test pre službu `ambulance-webapi`
