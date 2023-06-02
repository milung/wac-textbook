
## Inicializácia databázy pre Webapi bežiace v kontajneri v lokálnom kubernetes klastri

V lokálnom kubernetes klastri sa na obsah databázy môžeme pozrieť cez MongoExpress container, ktorý je z vonku prístupný cez Nodeport na [localhost:30003](http://localhost:30003). Zoznam by **nemal** obsahovať vašu databázu, lebo sme ju zatiaľ nevytvorili.

Naše webapi nie je prístupné zvonku k8s klastra, lebo jeho `service` má nastavený port typu `ClusterIP`. Na prístup k nemu využijeme funkciu Port Forward, buď cez aplikáciu Lens alebo z príkazového riadku:

```ps
kubectl port-forward service/<pfx>-ambulance-webapi -n wac-hospital 8111:80
```

Overíme si, že je webapi prístupné - v prehliadači otvorte stránku [http://localhost:8111/api](http://localhost:8111/api), na ktorej uvidíte správu "Hello World!".

Ďalej postupujeme analogicky ako predtým:

1. Otvorte aplikáciu Postman, v kolekcii _Web In Cloud_ pridajte novú požiadavku a nazvite ju _Create ambulance - local kubernetes_.

   Zvoľte typ požiadavky `POST`, _URL_ zadajte  `http://localhost:8111/api/waiting-list/bobulova`.
  Prejdite na záložku _Body_, zvoľte formát dát _raw_ a vyberte typ obsahu (_Content-Type_) ako `JSON`. Do tela požiadavky zapíšte údaje o novej ambulancii:

    ```json
    {
      "id": "bobulova",
      "name": "Ambulancia všeobecného lekára Dr. Bobulová",
      "roomNumber": "211 - 2.posch",
      "predefinedConditions": [
        {
          "value": "Teploty",
          "code": "subfebrilia",
          "reference": "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/",
          "typicalDurationMinutes": 20
        },
        {
          "code": "folowup",
          "value": "Kontrola",
          "typicalDurationMinutes": 15
        },
        {
          "code": "nausea",
          "value": "Nevoľnosť",
          "typicalDurationMinutes": 45,
          "reference": "https://zdravoteka.sk/priznaky/nevolnost/"
        }
      ]
    }
    ```

    Nakoniec zvoľte tlačidlo _Save_ a uložte túto požiadavku.

2. Stlačte tlačidlo _Send_. V časti odozvy požiadavky by ste mali vidieť reťazec _Status: 201 Created_. Týmto sme v databáze vytvorili novú ambulanciu.

3. Skontrolujte obsah databázy - pripojte sa na MongoExpress container ([localhost:30003](http://localhost:30003)) a pozrite si obsah vašej databázy. Mal by obsahovať jeden záznam.
