# Integrácia mikro služieb do Service Mesh

Náš systém pozostáva z jednotlivých mikroslužieb, ktoré navzájom spolupracujú a sú koordinované deklaratívnym spôsobom v systéme kubernetes. Z externého pohľadu sa ale javia ako sada rôznych služieb, nasadených v iných subdoménach, ktoré spája len ad-hoc konfigurácia. V tejto časti cvičenia tieto mikro služby zapojíme do jednej zostavy, a pridáme ďalšie vrstvy koordinácie, ktoré nám pomôžu vytvoriť ucelenejší celok nášho systému.

_Obrázok znázorňuje žiadaný stav._

![Prepojenie komponentov](../img/prepojenie-komponentov.png)
