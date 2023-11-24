# Cvičenie: Web aplikácia pomocou knižnice Stencil JS

## <a name="ciel"></a>Cieľ cvičenia

Pri cvičení sa naučíte vytvoriť jednoduchú aplikáciu založenú na technológii [WebComponents][webc].
Naučíte sa ako túto aplikáciu zapúzdriť do samostatného softvérového kontajnera a ako túto aplikáciu
nasadiť do existujúcej webovej stránky bežiacej na platforme Kubernetes. Tiež sa naučíte využívať
knižnicu [Material Design Web Components][md-webc] na štylizovanie vizuálnej podoby aplikácie a vytvoriť
API špecifikáciu a vygenerovať klienta pre túto špecifikáciu pomocou nástroja [OpenAPI][openapi].

## Použité technológie

Aplikácia:

* je implementovaná v jazyku [TypeScript][typescript] s využitím aplikačnej knižnice [Stencil JS][stencil] 
vo forme [webových komponentov][webc],
* je vytvorená technikou micro Front End a integrovaná do existujúceho webového aplikačného rozhrania formou dynamicky načítavaných webových komponentov,
* je nasadená ako sada softvérových kontajnerov v systéme [Kubernetes][kubernetes],
* využíva knižnicu webových komponentov [Material Design Web Components][md-webc] za účelom štylizovania vizuálnej podoby aplikácie.

Pri voľbe technológií sme sa snažili o to, aby sme použili technológie, ktoré sú v súčasnosti využívané v praxi
a zároveň spĺňajú ciele cvičenia. Pre väčšinu technológií existujú aj iné alternatívy a v prípade záujmu ich
môžete použiť namiesto tých, ktoré sú v tomto cvičení použité. Podmienkou je, aby výsledná aplikácia bola vytvorená
ako [webový komponent][webc] a bola nasadená ako softvérový kontajner v systéme [Kubernetes][kubernetes]. Najmä v prípade,
ak sa rozhodnete použiť inú technológiu ako [Stencil JS][stencil] na vytvorenie webového komponentu, je potrebné aby výsledná
implementácia používala [Shadow DOM][shadow-dom] a [Custom Elements][custom-elements] špecifikáciu.

V prípade zvolených technológií sa najčastejšie vyskytuje otázka, prečo sme zvolili [Stencil JS][stencil] namiesto
iných alternatív ako napríklad [Angular][angular], [React][react] alebo [Vue][vue]. Dôvodom je, že [Stencil JS][stencil]
je knižnica, ktorá je primárne zameraná na vytváranie webových komponentov a je založená na štandardoch [WebComponents][webc],
zatiaľ čo v iných alternatívach je vývoj webových komponentov len "pridaná možnosť".
Hoci je teda možné použiť aj iné knižnice, v prípade [Stencil JS][stencil] je výhodou,
že sa jedná o pomerne jednoduchú nadstavbu nad technológiou [WebComponents][webc], čo nám umožní viac sa zamerať na ostatné 
aspekty full-stack vývoja a zároveň si plne osvojiť technológiu [WebComponents][webc].

## <a name="zadanie"></a>Zadanie cvičenia

Vytvorenie web rozhrania pre správu čakárne ambulancie. Základná funkcionalita:

Aplikáciu používajú dvaja používatelia: Pacient a Ambulantná sestra

* Pacient
  * Ako pacient chcem prísť do ambulancie, zadať svoje rodné číslo (alebo číslo
  pacienta) a zaradiť sa do poradia čakajúcich. Chcem, aby mi systém oznámil
  moje poradie a orientačnú dobu, kedy budem vyšetrený.
  * Ako pacient s akútnym ochorením (úraz, vysoká teplota) alebo s nárokom
  na prednostné ošetrenie (napríklad tehotenstvo) chcem, aby som po príchode do
  čakárne zadal svoje rodné číslo a zaradil sa do zoznamu čakajúcich s prednostným
  ošetrením.
  * Ako pacient čakajúci v ambulancii chcem mať vizuálny prehľad o aktuálnom
  stave môjho poradia.
* Ambulantná sestra
  * Ako sestra ambulancie chcem mať prehľad o počte a identite čakajúcich pacientov a ďalšom pacientovi v poradí.
  * Ako sestra ambulancie chcem vedieť, koľko a ktorí pacienti čakajú na lekárske
   vyšetrenie, ktorí čakajú na prednostné ošetrenie, a ktorí čakajú na vybavenie
    administratívneho úkonu.
  * Ako sestra ambulancie, v prípade posúdenia vážneho stavu pacienta, chcem mať možnosť zmeniť poradie čakajúcich.

## Technické ohraničenia:

* Aplikácia je implementovaná v programovacom jazyku TypeScript s využitím
  aplikačnej knižnice [Stencil JS][stencil] vo forme [webových komponentov][webc].
* Aplikácia je vytvorená technikou micro Front End a integrovaná do existujúceho
  webového aplikačného rozhrania formou dynamicky načítavaných webových komponentov.
* Aplikácia je nasadená ako sada softvérových kontajnerov v systéme
  [Kubernetes][kubernetes].
* Aplikácia využíva knižnicu webových komponentov [Material Design Web Components][md-webc] za účelom štylizovania vizuálnej podoby aplikácie.

## <a name="priprava"></a>Príprava na cvičenie

* Inštalácia [Node JS][nodejs], latest version
  * Odporúčame pozrieť nástroj **nvm** na správu verzií NodeJS (v praxi sa môžete stretnúť s projektami vyžadujúcimi rôzne verzie)
* Inštalácia [Visual Studio Code][vscode]
* Nainštalované rozšírenia vo Visual Studio Code:
  * [ESLint (dbaeumer.vscode-eslint)](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)
* Inštalácia [Git][git]
* Vytvorený účet na [GitHub]
* Vytvorený účet na [Microsoft Azure Cloud](https://azure.microsoft.com/en-us/free/students/)
* Predbežné zoznámenie sa s jazykom [TypeScript][typescript]
  a s knižnicou [Stencil JS][stencil]
* Nainštalovaný systém [Docker Desktop][docker-desktop] s aktivovaným subsystémom [kubernetes][kubernetes], prípadne funkčná inštalácia balíčka docker a minikube na systéme Linux.
* Vytvorený účet na stránke [Docker Hub][docker-hub]

## Pracovné prostredie

V cvičeniach prepokladáme, že všetky aktivity budete realizovať pod jedným adresárom, ktorý je v texte označený ako `${WAC_ROOT}`. V tomto adresári budú vytvorené všetky repozitáre, ktoré budú vytvorené počas cvičenia a budú do neho umiestňované aj pomocné súbory. Odporúčame mať v tomto priečinku aj uložený workspace pre Visual Studio Code.

Príkazy, ktoré používame na príkazovom riadku predpokladajú použitie [PowerShell] prostredia, ktoré je štandardne dostupné na platforme Windows. Hoci väčšina príkazov je funkčná bez zmeny aj v prostredí [Bash], odporúčame používať [PowerShell] prostredie aj na platforme Linux a MacOS. Postup inštalácie je popísaný na stránke [Install PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell).

## Development Containers

Na začiatku jednotlivých kapitol sú uvedené príkazy na aplikáciu šablón predvytvorených kontajnerov typu [Development Containers]. Tieto slúžia na inicializáciu projektu na začiatku kapitoly do predpokladaného stavu. Uvedený príkaz nie je za bežných okolností potrebný, slúži najmä na synchronizáciu stavu projektu medzi jednotlivými cvičeniami v prípade technických problémov. Podrobný postup je uvedený v kapitole [Riešenie Problémov](../99.Problems-Resolutions/01.development-containers.md).
