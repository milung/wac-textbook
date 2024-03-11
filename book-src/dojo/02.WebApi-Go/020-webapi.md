# Generovanie kostry obslužného kódu Web API

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-api-020`

---

Podobne ako pri generovaní kódu klienta v predchádzajúcom cvičení, aj pri generovaní kostry obslužného kódu API využijeme nástroje OpenAPI. Rozdiel v tomto prípade spočíva najmä v tom, že v prípade servera generátor nevie určiť požadovanú aplikačnú logiku a preto vygeneruje len základný skeleton, ktorého aktuálnu funkcionalitu musíme doimplementovať.

Na generovanie kódu využijeme generátor [go-gin-server](https://openapi-generator.tech/docs/generators/go-gin-server). Hoci by bola funkcionalita generovaná týmto generátorom pre potreby cvičenia postačujúca, ukážeme si ako upraviť šablóny generátora tak, aby generoval abstraktné typy a aby sme dosiahli opakované generovanie kódu pri prípadnej zmene API špecifikácie bez nutnosti manuálneho prepisovania už existujúceho kódu.

1. Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/scripts/run.ps1` s nasledujúcim obsahom:

    ```ps
    param (
        $command
    )

    if (-not $command)  {
        $command = "start"
    }

    $ProjectRoot = "${PSScriptRoot}/.."

    $env:AMBULANCE_API_ENVIRONMENT="Development"
    $env:AMBULANCE_API_PORT="8080"  

    switch ($command) {
        "start" {
            go run ${ProjectRoot}/cmd/ambulance-api-service
        }
        "openapi" {
            docker run --rm -ti -v ${ProjectRoot}:/local openapitools/openapi-generator-cli generate -c /local/scripts/generator-cfg.yaml 
        }
        default {
            throw "Unknown command: $command"
        }
    }
    ```

   V tomto projekte nebudeme používať `openapi-generator-cli` prostredníctvom npm balíčka, ale budeme priamo využívať jeho implementáciu dodanú ako softvérový obraz. Skript `run.ps1` budeme ďalej rozširovať za účelom automatizácie často vykonávaných príkazov počas vývoja. Teraz vytvorte súbor `${WAC_ROOT}/ambulance-webapi/scripts/generator-cfg.yaml` s nasledujúcim obsahom:

   ```yaml
   generatorName: go-gin-server
   outputDir: /local
   inputSpec: /local/api/ambulance-wl.openapi.yaml
   enablePostProcessFile: true
   additionalProperties:
     apiPath: internal/ambulance_wl
     packageName: ambulance_wl
   ```

   Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/.openapi-generator-ignore` s obsahom:

   ```text
   main.go
   go.mod
   Dockerfile
   README.md
   api/openapi.yaml
   ```

   Týmto predpisom zakážeme generovanie súborov, ktoré nechceme vygenerovať.

2. Uložte súbory a v priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkaz

   ```ps
   ./scripts/run.ps1 openapi
   ```

   Po jeho ukončení sa v priečinku `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl` objavia súbory, ktoré obsahujú obslužné rutiny pre spracovanie požiadaviek prichádzajúcich na API. Napríklad v súbore `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/api_ambulance_waiting_list.go` sa nachádzajú funkcie ako

   ```go
   ...
   // CreateWaitingListEntry - Saves new entry into waiting list
   func CreateWaitingListEntry(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{})
   }
   ...
   ```

   >info:> Adresár s menom `internal` zabraňuje prístupu k definíciám v ňom obsiahnutých typov z iných modulov.  _Package_, ktorého implementácia je v priečinku, ktorého ľubovoľný nadradený priečinok sa volá internal, poskytuje svoje zverejnené typy len v rámci modulu, v ktorom je implementovaný.

3. Vyššie uvedené funkcie by sme mohli upraviť a použiť ich potom v súbore `${WAC_ROOT}/ambulance-webapi/cmd/ambulance-api-service/main.go`, respektíve by sme mohli použiť hodnotu premennej `routes` zo súboru `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/routers.go`. Avšak v prípade úpravy špecifikácie by sme pri opätovnom generovaní kostry buď prepísali zmenené súbory, alebo by sme museli zmeny prepísať do existujúcich súborov ručne. Aby sme tomu predišli, vytvoríme si vlastné šablóny pre generovanie kódu.

   Na príkazovom riadku v priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkaz:

   ```ps
   docker run --rm -ti -v ${PWD}:/local openapitools/openapi-generator-cli author template --generator-name go-gin-server --output /local/scripts/templates
   ```

   Tento príkaz vytvorí kópie interných šablón generátora - [mustache][mustache] súborov - v priečinku `${WAC_ROOT}/ambulance-webapi/scripts/templates`. V tomto priečinku vymažte všetky súbory okrem:

    * `controller-api.mustache`
    * `routers.mustache`

   Vymazané súbory sú pre generátor stále dostupné v jeho internej databáze šablón.  Aby sa naše šablóny použili prednostne, musíme upraviť súbor  `${WAC_ROOT}/ambulance-webapi/scripts/generator-cfg.yaml` a doplniť nasledujúcu predvoľbu:

    ```yaml
    generatorName: go-gin-server
    templateDir: /local/scripts/templates @_add_@
    ...
    ```

4. Súbor `${WAC_ROOT}/ambulance-webapi/scripts/templates/controller-api.mustache` slúži ako predloha pre generovanie kódu pre jednotlivé _radiče_ - v praxi je to jeden súbor alebo jedna trieda pre každý _tag_ v [OpenAPI špecifikácii][openapi-spec]. Vymažte obsah tohto súboru a vložte nasledujúci text:

   ```mustache
   {{>partial_header}}
    package {{packageName}}

   {{#operations}}
   import (
      "net/http"

      "github.com/gin-gonic/gin"
   )

   type {{classname}} interface { @_important_@

      // internal registration of api routes
      addRoutes(routerGroup *gin.RouterGroup)

      {{#operation}}
       // {{nickname}} - {{{summary}}}{{#isDeprecated}}
      // Deprecated{{/isDeprecated}}
      {{nickname}}(ctx *gin.Context)

      {{/operation}}
    }

   {{/operations}}
   ```

   V tejto šablóne definujeme rozhranie, ktoré bude reprezentovať príslušnú časť - _tag_ - našej špecifikácie a v ňom deklarujeme metódy zodpovedajúce jednotlivým operáciám z našej špecifikácie.

   Ďalej do toho istého súboru vložte šablónu pre implementáciu tohto rozhrania. Implementácia pritom nie je kompletná, metódy pre jednotlivé operácie chýbajú a očakáva sa, že budú implementované mimo generovaný kód:

    ```mustache
    ...
    {{#operations}}
      ...
    type {{classname}} interface {
      ...
    }

    // partial implementation of {{classname}} - all functions must be implemented in add on files    @_add_@
    type impl{{classname}} struct {    @_add_@
    @_add_@
    }    @_add_@
    @_add_@
    func new{{classname}}() {{classname}} {    @_add_@
      return &impl{{classname}}{}    @_add_@
    }    @_add_@
    @_add_@
    func (this *impl{{classname}}) addRoutes(routerGroup *gin.RouterGroup) {    @_add_@
      {{#operation}}    @_add_@
      routerGroup.Handle( http.Method{{httpMethod}}, "{{{path}}}", this.{{nickname}})     @_add_@
      {{/operation}}    @_add_@
    }    @_add_@

    {{/operations}}
    ```

   Nakoniec do súboru `${WAC_ROOT}/ambulance-webapi/scripts/templates/controller-api.mustache` vložte kód, ktorý vygeneruje (zakomentovanú) ukážku implementácie metód pre jednotlivé operácie:

    ```mustache
    ...
    func (this *impl{{classname}}) addRoutes(routerGroup *gin.RouterGroup) {
      ...
    }

    // Copy following section to separate file, uncomment, and implement accordingly    @_add_@
    {{#operation}}    @_add_@
    // // {{nickname}} - {{{summary}}}{{#isDeprecated}}    @_add_@
    // // Deprecated{{/isDeprecated}}    @_add_@
    // func (this *impl{{classname}}) {{nickname}}(ctx *gin.Context) {    @_add_@
    //  	ctx.AbortWithStatus(http.StatusNotImplemented)    @_add_@
    // }    @_add_@
    //    @_add_@
    {{/operation}}    @_add_@
    ```

5. Súbor `${WAC_ROOT}/ambulance-webapi/scripts/templates/routers.mustache` integruje jednotlivé _radiče_ generované predchádzajúcou šablónou. Vymažte pôvodný obsah tohto súboru a nahraďte ho týmto kódom:

    ```mustache
    {{>partial_header}}
    package {{packageName}}

    import (
        "github.com/gin-gonic/gin"
    )
    
    func AddRoutes(engine *gin.Engine) {
      group := engine.Group("{{{basePathWithoutHost}}}")
      {{#apiInfo}}{{#apis}}
      {
        api := new{{classname}}()
        api.addRoutes(group)
      }
      {{/apis}}{{/apiInfo}}
    }
    ```

6. Uložte súbory a v priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkaz

   ```ps
   ./scripts/run.ps1 openapi
   ```

   Po jeho vykonaní sa obnoví obsah súborov v priečinku `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/`. Kód ale nie je kompilovateľný a hlási chyby odkazujúce na chýbajúcu implementáciu metód v triedach `implAmbulanceConditionsAPI` a `implAmbulanceWaitingListAPI`.

   Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_conditions.go` a vložte do neho nasledujúci kód:

    ```go
    package ambulance_wl

    import (
      "net/http"

      "github.com/gin-gonic/gin"
    )

    // Nasledujúci kód je kópiou vygenerovaného a zakomentovaného kódu zo súboru api_ambulance_conditions.go
    func (this *implAmbulanceConditionsAPI) GetConditions(ctx *gin.Context) {
      ctx.AbortWithStatus(http.StatusNotImplemented)
    }
   ```

    Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/internal/ambulance_wl/impl_ambulance_waiting_list.go` a vložte do neho nasledujúci kód:
  
      ```go
      package ambulance_wl
  
      import (
        "net/http"
  
        "github.com/gin-gonic/gin"
      )
  
      // Nasledujúci kód je kópiou vygenerovaného a zakomentovaného kódu zo súboru api_ambulance_waiting_list.go

      // CreateWaitingListEntry - Saves new entry into waiting list
      func (this *implAmbulanceWaitingListAPI) CreateWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented)
      }

      // DeleteWaitingListEntry - Deletes specific entry
      func (this *implAmbulanceWaitingListAPI) DeleteWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented)
      }

      // GetWaitingListEntries - Provides the ambulance waiting list
      func (this *implAmbulanceWaitingListAPI) GetWaitingListEntries(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented)
      }

      // GetWaitingListEntry - Provides details about waiting list entry
      func (this *implAmbulanceWaitingListAPI) GetWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented)
      }

      // UpdateWaitingListEntry - Updates specific entry
      func (this *implAmbulanceWaitingListAPI) UpdateWaitingListEntry(ctx *gin.Context) {
        ctx.AbortWithStatus(http.StatusNotImplemented)
      }
      ```

7. Upravte obsah súboru  `${WAC_ROOT}/ambulance-webapi/cmd/ambulance-api-service/main.go`: 

    ```go
    package main

    import (
       ...
      "github.com/<github_id>/ambulance-webapi/internal/ambulance_wl" @_add_@
    )

    func main() {
      ...
      // request routings
      ambulance_wl.AddRoutes(engine) @_add_@
      engine.GET("/openapi", api.HandleOpenApi)
      engine.Run(":" + port)
    }
   ```

8. V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkaz

   ```ps
   go run cmd/ambulance-api-service/main.go
   ```

   a potom v druhom termináli vykonajte príkaz

   ```ps
   curl -v http://localhost:8080/api/waiting-list/bobulova/condition
   ```

   Výsledok by mal byť podobný tomuto:

   ```text
   *   Trying 127.0.0.1:8080...
   * Connected to localhost (127.0.0.1) port 8080 (#0)
   > GET /api/waiting-list/bobulova/condition HTTP/1.1
   > Host: localhost:8080
   > User-Agent: curl/7.74.0
   > Accept: */*
   > 
   * Mark bundle as not supporting multiuse
   < HTTP/1.1 501 Not Implemented   @_implemented_@
   < Date: Fri, 11 Aug 2023 15:26:48 GMT
   < Content-Length: 0
   < 
   * Connection #0 to host localhost left intact
   ```

   Náš server síce vracia len chybové hlásenie `501 Not Implemented`, ale to je v poriadku, pretože sme vytvorili len kostru servera, ktorý ešte nie je implementovaný. V nasledujúcich krokoch sa budeme venovať implementácii servera. Môžeme ale bez problémov doplniť špecifikáciu a nanovo vygenerovať kostru servera bez toho, aby sme si prepisovali existujúci kód. Navyše, kód nebude kompilovateľný pokiaľ nebudeme mať implementované všetky operácie nášho API.

   >info:> Šablóny by sa dali ešte ďalej rozvíjať, napríklad sme mohli poskytnúť parametre ako vstupné argumenty do metód, ktoré musíme implementovať, čo by zredukovalo opakujúce sa bloky kódu v jednotlivých metódach. Kvôli prehľadnosti a ľahšiemu pochopeniu ďalšieho postupu sme sa ale rozhodli pre jednoduchšiu ale funkčnú implementáciu šablón. Rôzne (aj pokročilejšie techniky) pre generovanie kódu nájdete v [repozitári generátorov pre openapi-generator-cli](https://github.com/OpenAPITools/openapi-generator/tree/v7.0.0-beta/modules/openapi-generator/src/main/resources).

9. Archivujte zmeny v git repozitári. V priečinku `${WAC_ROOT}/ambulance-webapi` vykonajte príkazy:

   ```ps
   git add .
   git commit -m "Kostra servera"
   git push
   ```
