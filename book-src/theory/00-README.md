## Moderné webové aplikácie (_Single Page Applications_)

* [História webových aplikácií](./00-README.md)
* [Formy realizácie dynamického obsahu na webe](./01-dynamics.md)

### História webových aplikácií

Pôvodný zámer pri vytváraní protokolu HTTP bol vytvoriť systém hyper-textových
dokumentov, ktoré by na seba navzájom odkazovali v distribuovanom sieťovom
prostredí siete Internet. Obsah dokumentov bol pôvodne odborný, obsahujúci
vedecké a odborné informácie s jednoduchým spôsobom dohľadávania referencovaných
informácii. Praktickosť tohto protokolu bola rýchlo využitá aj na prepájanie
neodborných informácií, diskusií v rôznych fórach a na populárne informácie.

S príchodom prvých grafických prehliadačov (Netscape Mosaic, Internet Explorer)
začala internet a HTTP protokol využívať aj laická verejnosť a došlo ku komerčnému
využívaniu informácií, ktoré boli odrazu ľahko dostupné širokej verejnosti. To
vyvolalo ešte väčší záujem o prístup k internetu aj z prostredia domácnosti a viedlo
ku dnes už pomerne samozrejnému univerzálnemu prístupu k Internetu ako médiu na
poskytovanie, zdieľanie a vyhľadávanie informácií.

Pôvodne boli dokumenty plne statické, obsahujúce len text v prirodzenom jazyku a
pokyny pre spôsob formátovania obsiahnutého textu. K zmene obsahu v prehliadači
dochádzalo len prechodom na novú stránku po aktivovaní hypertextového odkazu. Táto
forma interakcie prevažuje na internete dodnes, najmä pri vyhľadávaní a prepájaní
informačných zdrojov. Vzhľadom na pomerne dlhé sieťové odozvy v počiatkoch vývoja
Internetu, však táto interakcia bola nedostatočná a neumožňovala efektívne využívať
možnosti Internetu napríklad pri zbere informácií od používateľov akými sú vypĺňanie
a validácia formulárov, či riadenie navigácie v závislosti od indikovaných preferencií
používateľa. Tento problém sa pokúsili adresovať dva konkurenčné návrhy pre zahrnutie
programovacích makier do obsahu hypertextového dokument. Ako protinávrh na skriptovací
jazyk založený na jazyku Basic od firmy Microsoft - VBScript, prišla firma Netscape
s návrhom jazyka JavaScript, dnes oficiálne pomenovaného ako ECMAScript. Tým sa začala
éra dynamických stránok, v tej dobe označovaných ako DHTML. Štandard
HTTP potom umožnil zahrnúť do dokumentu časti kódu v ľubovoľnom jazyku, z dlhodobého
hľadiska sa však presadilo používanie jazyka neoficiálne nazývaného JavaScript.

JavaScript jazyk bol pomerne jednoduchý a dlhý čas trpel najmä na rozdielnosť
jeho implementácie v rôznych prehliadačoch, k čomu prispievala aj nejednoznačnosť
jeho štandardu a neochota hlavných hráčov na trhu - Microsoft a Mozilla - prispôsobiť
a upraviť svoje implementácie. To generovalo množstvo obmedzení pri tvorbe dynamického
obsahu a obmedzovalo plné využitie jazyka. Zároveň bol jazyk interpretovaný a na
vtedajších výpočtových prostriedkoch pomerne pomalý, preto sa využíval len na veľmi
základnú dynamiku obsahu a dynamické zmeny vizuálneho kontextu. Operácie aj relatívne
mierne náročné na rýchlosť výpočtu sa potom vykonávali na strane servera.

K prekonaniu nejednoznačnej implementácie jazyka pomohli knižnice, ktoré unifikovali
prácu s obsahom dokumentu a údajmi medzi rôznymi priehladačmi tým, že poskytli vlastné
programové rozhranie nad štandardom a dynamicky sa prispôsobili implementácii jazyka
v danom prehliadači. Asi najznámejšou takouto knižnicou je dodnes používana knižnica
[_jQuery_][jquery].

Súboj medzi prehliadačmi obsahu pomohol adresovať druhú nevýhodu, ktorou bola rýchlosť
interpretácie jazyka JavaScript. Zatiaľ, čo spočiatku súťaž prebiehala len medzi Microsoftom
poskytovaným prehliadačom Internet Explorer a komerčne znevýhodneným prehliadačom
Mozilla Firefox, bola motivácia na investície do implementácie prehliadača relatívne
nízka. Vstup tretieho veľkého hráča - Google Chrome - a následné oživenie prehliadača
Safari od firmy Apple, túto súťaž oživili a donútili hráčov investovať aj do rýchlosti
samotného prehliadača. Zároveň sa s príchodom mobilných platforiem zmenil aj spôsob
prístupu k informáciám, čo donútilo výrobcov prehliadačov viac sa prispôsobiť
štandardu, pokiaľ nechceli riskovať zbytočnosť svojej platformy v prostredí, ktoré
začali ovládať najmä poskytovatelia obsahu, a v ktorom sa operačný systém alebo
typ prehliadača webového obsahu stali komoditou.

V súčasnosti sú webové aplikácie vyvíjané najmä pre takzvané moderné
prehliadače - _Modern Browsers_, ktoré sa vyznačujú striktnejším dodržiavaním štandardu,
rýchlou adaptáciou na novo vydávané verzie štandardu a vysokým výkonom pri vykonávaní
inštrukcií jazyka, porovnateľným s výkonom iných manažovaných jazykov, ako sú napríklad
Java a C#. Tomu zodpovedá aj fakt, že zatiaľ, čo medzi verziou EcmaScript 3 a
EcmaScript 5 uplynolo desať rokov (1999-2009, verzia 4 nebola nikdy vydaná), v rokoch
2015 až 2018 vznikli štyri nové verzie a možno očakávať pokračovanie tohto trendu.