# Cvičenie 2: Vytvorenie webovej služby s použitím jazyka Go

## <a name="ciel"></a>Cieľ cvičenia

Cieľom cvičenia je vytvoriť webovú RESTful službu pre aplikáciu správy čakárne popísanú
v predchádzajúcom cvičení. Základná funkcionalita:

* Aplikáciu používajú dvaja užívatelia: Pacient a Ambulantná sestra
* Pacient
  * Ako pacient chcem, aby som po príchode do čakárne zadal svoje rodné číslo (alebo číslo pacienta)
  a aby ma následne systém zaradil do poradia čakajúcich. Chcem, aby mi systém oznámil moje poradie a
  orientačnú dobu, kedy budem vyšetrený.
  * Ako pacient s akútnym ochorením - úraz, vysoká teplota, tehotenstvo - a nárokom
  na prednostné ošetrenie chcem, aby som po príchode do čakárne zadal svoje rodné
  čislo (alebo číslo pacienta) a aby ma následne systém zaradil do zoznamu čakajúcich s prednostným ošetrením.
  * Ako pacient čakajúci v ambulancii chcem mať vizuálny prehľad o aktuálnom stave
  môjho poradia.
* Ambulantná sestra
  * Ako setra ambulancie chcem mať prehľad o počte a identite čakajúcich pacientov
  a ďalšom pacientovi v poradí.
  * Ako sestra ambulancie chcem vedieť koľko a ktorí pacienti čakajú na lekárske
  vyšetrenie, ktorí čakajú na prednostné ošetrenie, a ktorí čakajú na vybavenie
  administratívneho úkonu.
  * Ako sestra ambulancie, v prípade posúdenia vážneho stavu pacienta, chcem
  mať možnosť zmeniť poradie čakajúcich.

Navyše sú určení ďalší užívatelia: "Správca nemocnice" a "Vývojár aplikácie".
Funkcionalita aplikácie je definovaná nasledovne:

* Správca nemocnice (_nebudeme implementovať počas cvičenia_)
  * Ako správca nemocnice chcem získať výpis všetkých ambulancií v nemocnici,
    súčasný počet čakajúcich pri každej ambulancii, ako aj priemernú dobu čakania
    za obdobie posledných desať dní.
  * Ako správca nemocnice chcem vytvoriť novú ambulanciu.
  * Ako správca nemocnice chcem byť schopný nastaviť základné parametre ambulancie,
    ako jej názov, číslo dverí, ošetrujúcich lekárov, otváracie hodiny a podobne.
* Vývojár aplikácie
  * Ako vývojár softvérového systému chcem vedieť, akú funkcionalitu mi webová služba
  poskytuje a aké parametre požaduje, respektíve aké návratové hodnoty mám očakávať.
  * Ako vývojár aplikácie chcem mať možnosť jednoduchým spôsobom vyskúšať a overiť
  funkcionalitu webovej služby.

Technické ohraničenia:

* Aplikácia je vytvorená v jazyku [Go](https://go.dev/)
  s použitím [Gin Web Framework](https://gin-gonic.com/docs/)
* Aplikačné rozhranie je popísané vo formáte [OpenAPI](https://www.openapis.org/about),
  s použitím nástroja [Swagger](https://swagger.io/docs/specification/about/)
* Stav čakajúcich a informácie o pacientoch sú uložené v  No-SQL databáze
  vytvorenej pomocou knižnice [MongoDB](https://www.mongodb.com/)

## <a name="priprava"></a>Príprava na cvičenie

* Vytvorená aplikácia podľa pokynov v cvičení
  [_Web aplikácia pomocou knižnice Stencil JS_](/v2/01.Web-Components/dojo/000-README.md)
* Nainštalovaný programovací jazyk [Go](https://go.dev/doc/install)
* Nainštalovanú aplikáciu [Postman](https://www.getpostman.com/)
* Vytvorený účet na stránke [Swagger Hub](https://app.swaggerhub.com)
* Zoznámenie sa s jazykom Go, napr. [GOLANGBOT.COM](https://golangbot.com/learn-golang-series/)
* Zoznámenie sa s jazykom [YAML](https://yaml.org/)
