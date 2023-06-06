# Cvičenie 2: Vytvorenie webovej služby s použitím ASP.NET Core 5.0

## <a name="ciel"></a>Cieľ cvičenia

Cieľom cvičenia je vytvoriť webovú RESTful službu pre aplikáciu správy čakárne popísanú
v predchádzajúcom cvičení. Základná funkcionalita:

* Aplikáciu používajú dve persóny: Pacient, a Ambulantná sestra
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

Navyše je určená ďalšia persóna "Správca nemocnice", a "Vývojár aplikácie".
Funkcionalita aplikácie je definovaná pre tieto persóny nasledovne:

* Správca nemocnice (_nebudeme implementovať počas cvičenia_)
  * Ako správca nemopcnice chcem získať výpis všetkých ambulancií v nemocnici,
    súčasný počet čakajúcich pri každej ambulancii, ako aj priemernú dobu čakania
    za obdobie posledných desať dní.
    * Ako správca nemocnice chcem vytvoriť novú ambulanciu
    * Ako správca nemocnice, chcem byť schopný nastaviť základné parametre ambulancie
    ako jej názov, číslo dverí, ošetrujúcich lekárov, otváracie hodiny a podobne.
* Vývojar aplikácie
  * Ako vývojar softverového systému chcem vedieť akú funkcionalitu mi webová služba
  poskytuje a aké parametre požaduje, respektíve aké návratové hodnoty mám očakávať
  * Ako vývojar aplikácie chcem mať možnosť jednoduchým spôsobom vyskúšať a overiť
  funkcionalitu webovej služby

Technické ohraničenia:

* Aplikácia je vytvorená v jazyku [C#](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/)
  s použitím knižnice [ASP.NET Core](https://dotnet.microsoft.com/download)
* Aplikačné rozhranie je popísané vo formáte [OpenAPI](https://www.openapis.org/about),
  s použitím nástrojov [Swagger](https://swagger.io/docs/specification/about/)
* Stav čakajúcich a informácie o pacientoch sú uložené v lokálnej No-SQL databáze
  vytvorenej pomocou knižnice [LiteDB](https://www.litedb.org/)

## <a name="priprava"></a>Príprava na cvičenie

* Vytvorená aplikácia podľa pokynov v cvičení
  [_Web aplikácia pomocou knižnice Angular_](../../01.SPA/dojo/00-README.md)
* Nainštalované [.NET SDK 5.0](https://dotnet.microsoft.com/download)
* Nainštalovanú aplikáciu [Postman](https://www.getpostman.com/)
* Vytvorený účet na stránke [Swagger Hub](https://app.swaggerhub.com)
* Zoznámenie sa s jazykom [C#](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/)
* Zoznámenie sa s jazykom [YAML](https://yaml.org/)
