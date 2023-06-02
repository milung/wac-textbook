# Cvičná aplikácia

Cieľom cvičnej aplikácie je ukázať postupy vývoja na konkrétnom príklade, ktorý
je možné prepojiť s reálnou praxou. Cvičná aplikácia pozostáva z viacerých
mikro-aplikácií \(možno chápať ako mikro-služby v rámci [12faktorovej][twelves] aplikácie\),
ktoré sú v závere prepojené do uceleného systému.

## Definícia problému

Spádová nemocnica momentálne nedisponuje žiadnym centrálnym informačným systémom,
čo spôsobuje neefektivitu pri správe jej operácií a nespokojnosť na strane zákazníkov.
Nemocnica sa preto rozhodla pre investíciu do centrálneho informačného systému,
ktorý by v konečnej konfigurácii pokrýval všetky aspekty jej činností.  Z ekonomického
hľadiska je požiadavkou na implementáciu systému, aby systém bol modulárny, mohol
byť vyvíjaný postupne a zároveň priebežne obnovovaný na základe aktuálnych požiadaviek
a so zapojením viacerých dodávateľov v rôznych časových obdobiach. Ďalšou požiadavkou
je, aby systém bolo možné nasadiť do dátoveho centra, ktorý má nemocnica k dispozícii
(_tu je špecifikácia úmyselne nechaná otvorená, postupne sa budeme zaoberať rôznymi
možnosťami nasadenia systému_).

Z funkčného hľadiska má systém zahrňovať nasledujúce aplikácie:

* Správu čakárne pre jednotlivé ambulancie.
* Objednávací systém na základe požiadavky pacienta, vysielajúceho lekára alebo
  požiadavky odborného lekára (napríklad pravidelné prehliadky).
* Správa lekárskej dokumentácie v rámci jednotlivých ambulancií.
* Správa lekárskej dokumentácie prichádzajúcej z externých ambulancií v
  elektronickej forme, jej spracovanie, (automatizovaná) kontrola a pridelenie
  k príslušným  ambulanciám.
* Správa lôžkovej časti nemocnice podľa jednotlivých oddelení a ich aktuálne a
  plánované obsadenie pacientami.
* Správa liekov na ambulanciách, ich vydávanie pacientom a objednávanie
  v nemocničnej lekárni.
* Sledovanie výkonov v rámci jednotlivých ambulancií a ich ekonomické náklady.
* Portál pre pacientov, na ktorom môžu získať prehľad o svojich akútnych a
  chronických chorobách a uskutočnených ako aj plánovaných návštevách nemocnice.
* Odborné online poradenstvo zodpovedajúce aktuálnemu zdravotnému stavu
  registrovaného alebo cudzieho pacienta.
* Podpora pre vzdialené vyšetrenie pri vybraných ochoreniach a/alebo
  u špecifických pacientov.
* Evidenciu a objednávanie vybavenia nemocnice a ambulancií, s prehľadom umiestnenia
  a životnosti jednotlivých položiek.
* Evidenciu priestorov nemocnice a ich pridelenie k jednotlivým ambulanciám
  alebo oddeleniam.
* Personálna správa, prehľad o zamestnancoch nemocnice, ich priradenie k ambulanciám
  a nemocničným oddeleniam, prehľad o výkonoch a správa osobnej dokumentácie.

Niektoré z týchto aplikácií sú čiastočne pokryté v rámci tejto učebnice. Študenti
majú možnosť vybrať si niektorú z aplikácií pre svoju samostatnú prácu počas cvičení,
a tiež ako zadanie pre konečné vyhodnotenie zvládnutia problematiky štúdia.
