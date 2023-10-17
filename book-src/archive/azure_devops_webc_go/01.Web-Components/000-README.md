# Cvičenie 1: Web aplikácia pomocou knižnice Stencil JS

## <a name="ciel"></a>Cieľ cvičenia

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
  * Ako sestra ambulancie, v prípade posúdenia vážneho stavu pacienta, chcem  
  mať možnosť zmeniť poradie čakajúcich.

Technické ohraničenia:

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
  * [TSLint (ms-vscode.vscode-typescript-tslint-plugin)](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-typescript-tslint-plugin)
* Inštalácia [Git][git]
* Vytvorený účet a organizáciu s administrátorskými právami na stránke
  [Microsoft Azure DevOps Services][azure-devops]
* Vytvorený účet na [Microsoft Azure Cloud](https://azure.microsoft.com/en-us/free/students/)
* Predbežné zoznámenie sa s jazykom [TypeScript][typescript]
  a s knižnicou [Stencil JS][stencil]
* Nainštalovaný systém [Docker Desktop][docker-desktop] s aktivovaným subsystémom [kubernetes][kubernetes], prípadne funkčná inštalácia balíčka docker a minikube na systéme Linux.
* Vytvorený účet na stránke [Docker Hub][docker-hub]
