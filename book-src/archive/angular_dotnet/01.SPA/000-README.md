# Cvičenie 1: Web aplikácia pomocou knižnice Angular 11

## <a name="ciel"></a>Cieľ cvičenia

Vytvorenie web rozhrania pre správu čakárne ambulancie. Základná funkcionalita:

* Aplikáciu používajú dve persony: Pacient, a Ambulantná sestra
* Pacient
  * Ako pacient chcem prísť do ambulancie, zadať svoje rodné číslo (alebo číslo
  pacienta), a zaradiť sa do poradia čakajúcich. Chcem, aby mi systém oznámil
  moje poradie a orientačnú dobu kedy budem vyšetrený.
  * Ako pacient s akútnym ochorením - úraz, vysoká teplota, alebo s nárokom
  na prednostné ošetrenie - napríklad tehotenstvo - chcem, aby som po príchode do
  čakárne zadal svoje rodné čislo a zaradil sa do zoznamu čakajúcich s prednostným
  ošetrením.
  * Ako pacient čakajúci v ambulancii, chcem mať vizuálny prehľad o aktuálnom
  stave môjho poradia.
* Ambulantná sestra
  * Ako sestra ambulancie chcem mať prehľad o počte a identite čakajúcich pacientov,
   a ďalšom pacientovi v poradí.
  * Ako sestra ambulancie chcem vedieť koľko a ktorí pacienti čakajú na lekárske
   vyšetrenie, ktorí čakajú na prednostné ošetrenie, a ktorí čakajú na vybavenie
    administratívneho úkonu.
  * Ako sestra ambulancie, v prípade posúdenia vážneho stavu pacienta, chcem  
  mať možnosť zmeniť poradie čakajúcich.

Technické ohraničenia:

* Aplikácia je implementovaná v programovacom jazyku TypeScript s využitím
  aplikačnej knižnice [Angular 11](https://angular.io/) (prípadne novšia verzia)
* Aplikácia využíva knižnicu [Angular Material](https://material.angular.io/).
* Aplikácia využíva knižnicu  [NgRx](https://github.com/ngrx) implementujúcu
  architektonický návrhový vzor [Redux](https://redux.js.org/introduction/motivation)
  pre správu stavu aplikácie.

## <a name="priprava"></a>Príprava na cvičenie

* Inštalácia [Node JS](https://nodejs.org/en/), latest version
* Inštalácia [Visual Studio Code](https://code.visualstudio.com/)
* Nainštalované rozšírenia vo Visual Studio Code:
  * [Angular Language Service (angular.ng-template)](https://marketplace.visualstudio.com/items?itemName=Angular.ng-template)
  * [TSLint (ms-vscode.vscode-typescript-tslint-plugin)](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-typescript-tslint-plugin)
* Inštalácia [Git](https://git-scm.com/)
* Vytvorený účet a organizáciu s administrátorskými právami na stránke
  [Microsoft Azure DevOps Services](https://azure.microsoft.com/en-us/services/devops/)
* Vytvorený účet na [Microsoft Azure Cloud](https://azure.microsoft.com/en-us/free/students/)
* Predbežné zoznámenie sa s jazykom [TypeScript](https://www.typescriptlang.org/),
  a s knižnicou [Angular](https://angular.io/)
* Git repository na [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/)
