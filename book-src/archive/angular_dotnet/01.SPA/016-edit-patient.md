## Editovanie údajov pacienta

Určite ste si všimli, že nefunguje editovanie údajov pacienta, či už sa jedná o pacienta získaného počas 
inicializácie alebo o pacienta pridaného v rámci behu aplikácie.

1.  Vyskúšajte zmeniť a uložiť údaje na stránke http://localhost:4200/patients-list/3.

    Vidíte, že po uložení údaje nie sú zmenené. Skúste to opraviť.

    >tips_and_updates:> Dáta v editor componente sú pri inicializácii označené ako readonly, čo zabraňuje
    > ich úprave. Podobný problém sme už riešili aj pri implementácii služby `AmbulancePatientsListService`.

2.  Teraz pridajte nového pacienta a následne skúste zmeniť a uložiť jeho údaje na stránke http://localhost:4200/patients-list/4.

    Napriek tomu, že údaje pacientov získaných počas inicializácie už aplikácia meniť dokáže, 
    údaje novovytvorených pacientov sa meniť nedajú. Dôvodom je, že priamym prístupom cez linku prehliadača
    dochádza znovu k inicializácii komponentov, následkom čoho sa inicializovalo taktiež pole pacientov a 
    údaje o novopridaných pacientoch už nie sú k dispozícii.

    Aby sme mohli meniť aj údaje nových pacientov, pridajte tlačidlo _Editovať záznam_ do súboru
    `\src\app\waiting-entry\waiting-entry.component.html`.

    Skontrolujte funkčnosť aplikácie. Opravte testy, submitnite a pushnite zmeny do repozitára.