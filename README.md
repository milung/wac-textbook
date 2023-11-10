# Zdrojové materiály k skriptám k predmetu Vývoj webových aplikácii v prostredí Cloud

__English summary__: This repository contains the source materials for the book "Vývoj webových aplikácii v prostredí Cloud" (Development of web applications in the Cloud environment) written in Slovak language. The book is available at http://wac-fiit.milung.eu/ .

Materials are licensed under the [Creative Commons Attribution 4.0 International (CC BY 4.0) license](https://creativecommons.org/licenses/by/4.0/).

Markdown súbory a obrázky pre generovanie skrípt "Vývoj webových aplikácii v prostredí Cloud" (WAC).

## Postup pri práci s repozitárom

V adresári `book-src` sú uložené všetky podklady. Každá sekcia skrípt je uložená v samostatnom adresári. V adresári `book-src` je tiež súbor `_toc.md` s obsahom knihy. Ten obsahuje relatívne odkazy na jednotlivé kapitoly. Každá sekcia má potom vlastný súbor `_toc.md` s odkazmi na kapitoly v tejto sekcii. Obsah podsekcie možno do obsahu knihy alebo nadradenej sekcie zahrnúť pomocou príkazu `[#include sekcia/_toc.md]`. Tento príkaz, zároveň zabezpečí, že kapitoly podsekcie budu v navigačnom panely viditeľné, len ak je zobrazená podsekcia aj v hlavnom panely.

V adresári `book-src` je tiež súbor `_links.md` s odkazmi na zdroje. Tento súbor sa automaticky pridá do každej kapitoly a uvedené linky potom možno používať len pomocou symbolických mien. Odporúčam používať na miestach kde sa odkazuje na externé zdroje, pokiaľ tieto zdroje nie sú veľmi špecifické. To umožní generovať zoznam literatúry, ako aj upraviť odkazy na jednom mieste.

## Prispievanie do knihy

Najvhodnejším spôsobom je využitie [Development Container](https://containers.dev/overview) pri práci s knihou, napríklad vytvorenie nového [Github Codespaces](https://github.com/features/codespaces) alebo otvorenie Development Container-u pomocou [Visual Studio Code Remote - Containers](https://code.visualstudio.com/docs/remote/containers).

Vývojový kontajner vytvorí `postStartCommand` proces, ktorý vytvorí http server počúvajúci na porte `3380`. Po otvorení portu (v záložke _Ports_) uvidíte aktuálnu verziu skrípt v prehliadači. Aby sa Vaše zmeny ihneď prejavili, musíte v prehliadači otvoriť _Vývojarské nástroje_ a zakázať vyrovnávaciu pamäť v záložke _Sieť_.

V prípade, že proces zlyhá - napríklad generovanie nového obsahu nie je automaticky reflektované, prerušte proces `postStartCommand`, otvorte nový Powershell terminál, prejdite do priečinka `wac-textbook` a vykonajte príkaz

```ps
./scripts/run.ps1 devc-start
```

## Generovanie knihy

Novú verziu knihy možno vygenerovať pomocou komitu zmien do vetvy `main` a vytvorením nového release-u s tagom vo formáte `v1.*.*`. Tento tag spustí GitHub Action, ktorý vygeneruje novú verziu knihy a zverejní ju na stránke http://wac-fiit.milung.eu/.

## Špecifické rozšírenie v markdown:

V súboroch `_toc.html` môžete definovať vlastné ikony kapitoly pomocou nasledujúcej syntaxe: `[$icon-name> Label](<link-url>)`. Názov ikony je názov ikony z knižnice [fontawesome](https://fontawesome.com/icons?d=gallery). Za názvom ikony nasleduje znak `>` a pred ním je znak `$`. `label` je text hypertextového odkazu. Ak názvu ikony nie je predradený znak `$`, potom sa ikona prevezme z knižnice [Material Symbols](https://fonts.google.com/icons). Názov ikony používa pomlčku `-` namiesto podčiarkovníka `_`, tak ako v knižnici fontawesome.

Príklad `_toc.md`:

```markdown
[$graduation-cap> Úvod](./README.md)
[Prológ](./prologue.md)

<hr />
## [language> Kapitola 1: Vývoj webu](dojo/web/000-README.md)

[#include dojo/web/_toc.md]
<hr />
```

### Poznámky s ikonami

Blokovú citáciu s ikonou môžete umiestniť pomocou nasledujúcej syntaxe: `>$icon-name:> Text blokovej citácie`. Názov ikony je názov ikony z knižnice [fontawesome](https://fontawesome.com/icons?d=gallery). Za menom ikony nasledujú znaky `:>` a pred ním je znak `$`.  Ak názov ikony nie je prefixovaný znakom `$`, potom je ikona prevzatá z knižnice [Material Symbols](https://fonts.google.com/icons).

Používajte tieto ikony:

- `>info:>` pre doplňujúce informácie
- `>warning:>` pre dôležité informácie
- `>build_circle:>` pre riešenie možných problémov
- `>$apple:>` pre Mac Os špecifické informácie
- `>homework:>` pre označenie samostatnej práce

### Zvýraznené bloky kódu

 Vo vnútri bloku môžete označiť riadok ako vložený umiestnením textu `@_add_@` na tento riadok; alebo môžete označiť riadok ako odstránený umiestnením textu `@_remove_@` na tento riadok; alebo môžete označiť riadok ako dôležitý umiestnením textu `@_important_@` na tento riadok. Vykreslenie tohto riadku sa zvýrazní príslušnou farbou, samotné značky ako aj odstránené riadky nie sú pri kopírovaní vložené do schránky.

