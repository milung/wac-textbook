## Formy realizácie dynamického obsahu na webe

Ako bolo uvedené, prvotnou formou interakcie a dynamiky obsahu bola navigácia
prostredníctvom hypertextových odkazov a načítaním nového dokumentu. Táto forma
dynamiky je stále základom interakcie používateľa s informáciami na Internete.
Úlohou vývojového týmu je v tomto prípade vhodne a prehľadne štrukturovať
informácie a zabezpečiť takú formu navigácie medzi dokumentami, ktorá čo najlepšie
zodpovedá správaniu sa a kognitívnemu spracovaniu informácií používateľmi.
Množstvo informácií vyžaduje poskytnutie prehľadu o obsahu portálu - _site maps_
 alebo nasadnie nástrojov na vyhľadávanie informácií.

S príchodom JavaScriptu vznikla nová forma interakcie, kedy skript obsiahnutý
v dokumente alebo referencovaný dokumentom po svojej aktivácii (napríklad
stlačením tlačidla) modifikoval model dokumentu (_DOM - Document Object Model_).
Vývojový tím sa v tej dobe rozhodoval, ktoré informácie zahrnúť do dokumentu a zobraziť
dynamicky, čím sa zredukoval počet dotazov na server, a ktoré informácie poskytnúť
formou navigácie na nový dokument získaný zo servera. Veľkú časť úsilia pritom bolo
nutné venovať rozdielom v implementácii jazyka medzi hlavnými prehliadačmi.

Súčasťou kódu skriptu boli aj informácie, ktoré riadili obsah a spôsob modifikácií.
Tieto doplňujúce informácie sú často závislé od stavu aplikácie alebo od identity
používateľa. HTTP protokol sa preto doplnil o možnosť špecifikovania a identifikácie
stavu aplikácie, či už formou parametrov požiadavky (_query parameters_) alebo pomocou
takzvaných _cookies_, čo sú informácie persistentne uložené v prehliadači a doplnené
do požiadavky protokolu HTTP. Vygenerovaný dokument potom obsahoval informácie
v závislosti od stavu aplikácie a používateľa a bol závislý od aplikačnej logiky.
To viedlo k vzniku jazykov, ktoré kombinovali programovací jazyk používaný na strane
servera, s kódom dokumentu - HTML a JavaScript - používaným na strane prehliadača.
Typickými predstaviteľmi týchto jazykov boli _Java Server Pages - JSP_,
_Active Server Pages - ASP_, alebo jazyk _PHP_. Skutočná zmena obsahu stránky alebo
jeho obnovenie ale stále vyžadovali navigáciu a načítanie celého dokumentu.

Požiadavka obnoviť len časť obsahu dokumentu bez nutnosti jeho obnovenia, ktoré 
pôsobilo rušivo, viedla k zavedeniu protokolu _AJAX - Asynchronous JavaScript + XML_,
dnes označovanom ako _XHR - XML Http Request_. Tento protokol, alebo rozšírenie jazyka,
umožnil kódu
JavaScript dynamicky vyvolať a spracovať HTTP požiadavku, ktorej odpoveď bola v
tej dobe typicky poskytovaná vo forme XML dokumentu. V počiatkoch bol vývoj zameraný
na oddelenie statického obsahu a dynamického obsahu a začali vznikať prvé webové
služby a ich štandardy. Tento prístup ale umožnil využiť HTTP a HTML štandardy
spôsobom dovtedy skôr známym pri vývoji desktopových aplikácií. Načítaný dokument
obsahoval len vizuálnu formu aplikácie, a obsah - údaje - sa načítali na základe
aplikačnej logiky pomocou protokolu XHR. Prvé aplikácie tohto druhu ešte stále
využívali navigáciu k zmene vizuálnej formy aplikácie, ale už pomohli posunúť
vývoj štandardov pre rozvoj aplikácií, v tej dobe známych ako HTML5+CSS3+JavaScript.
Možnosť dynamického načítania blokov kódu JavaScript umožnila zmenu vizuálnej formy
na pozadí, bez nutnosti načítania dokumentu a rušivého obnovenia celej stránky. Vznikli
prvé knižnice pre vývoj aplikácií na jednej stránke - _Single Page Application_ -
ako napríklad ExtJS, a postupne vznikli ďalšie knižnice. Medzi najznámejšie z nich
dnes patria Angular, React, alebo Vue.js. Vývojový tým pri tomto spôsobe vývoja oddeľuje
časť aplikácie viditeľnej v prehliadači od vývoja webovej služby alebo služieb,
ktoré poskytujú údaje pre aplikáciu. Interakcia a logika aplikácie je riadená
z prehliadača, zatiaľ čo webové služby sú primárne vyvíjané ako bezstavové. V súčasnosti
je tento spôsob vývoja výužívaný pri väčšine nových aplikácií určených pre prehliadače.

Narastajúca komplexnosť takýchto aplikácií ale so sebou prináša aj určité nevýhody.
Zväčšujúci sa objem kódu so sebou prináša nutnosť zdĺhavého načítavania kódu pred
tým, než je ho možné reálne začať vykonávať a zobraziť obsah aplikácie používateľovi.
Zároveň, v porovnaní s desktopovými aplikáciami, je nedostatkom webových aplikácií
ich závislosť na dostupnosti Internetového pripojenia. Oba tieto nedostatky adresujú
štandardy označované ako progresívne webové aplikácie - _Progressive Web Applications_.
Tieto štandardy umožňujú uložiť obsah a kód aplikácie v prehliadači alebo plne načítať
webovú stránku a údaje z vyrovnávacej pamäte prehliadača, bez potreby aktívneho pripojenia
k internetu. Zároveň umožnujú lepšiu integráciu s grafickým rozhraním operačného
systému. Z pohľadu používateľa poskytujú takmer okamžité načítanie stránky a
obsahu aplikácie, možnosť práce aj pri nedostupnosti pripojenia k Internetu, a
sú pre neho takmer nerozoznateľné od natívnych aplikácií operačného systému.
Momentálne sa začínajú tieto druhy aplikácií objavovať a sú využívané v najmodernejších
verziách používateľsky populárnych aplikácií ako sú sociálne siete. Očakáva sa,
že tento typ aplikácií začne celkovo prevládať, tiež z dôvodu jeho nezávislosti
od aktuálneho druhu operačného systému, čo znižuje náklady na strane výrobcu softvéru,
keďže môže jednou implementáciou adresovať rôzne cieľové platformy. Operačným
systémom z pohľadu softvérového vývojára sú tu potom štandardy poskytované
prehliadačom, súhrnne označované ako _Web APIs_, a webové služby dostupné
prostredníctvom siete Internet.

Posledným krokom pre plnú emancipáciu webových aplikácií s desktopovými, je poskytnutie
štandardu, ktorý by umožnil využívať možnosti výpočtových prostriedkov na úrovni
blízkej strojovému jazyku. Týmto štandardom je v súčasnosti  rozvíjajúci sa
_WebAssembly_, ktorý je už dostupný v hlavných prehliadačoch a umožňuje vývoj
aplikácií, donedávna dostupných len formou natívnych desktopových aplikácií.
Štandard _WebAssembly_ umožňuje plne využiť výpočtové prostriedky počítača na úrovni
nemenežovaného kódu.