# Nasadenie tímového projektu na lokálnom klastri

>info:> Táto kapitola je len zhrnutím postupu pre prácu študentov, nebude na cvičeniach preberaná.

Súčasťou semestrálneho projektu je jeho nasadenie na spoločnom klastri. Postup je v zásade obdobný ako v prípade aplikácie _<pfx>-ambulance-ufe_.

1. Vytvorte samostatný repozitár pre web komponent Vašej aplikácie, neskôr aj pre webapi Vašej aplikácie a implementujte tieto služby, ako to je ukázané na cvičeniach. Pripravte nové vydanie aplikácie.

2. Vytvorte nový repozitár pre nasadenie - gitops - Vašej aplikácie. Pokiaľ pracujete samostatne, môžete použit aj repozitár `ambulance-gitops` vytvorený na cvičeniach a len ho rozšíriť - doplniť konfigurácie Vašej aplikácie v príslušných adresároch `${WAC_ROOT}/ambulance-gitops/apps`,
`${WAC_ROOT}/ambulance-gitops/clusters/localhost/install` a `${WAC_ROOT}/ambulance-gitops/clusters/wac-aks/install`. V prípade tímovej práce odporúčame vytvoriť nový repozitár so zdieľaním prístupom členov tímu.

3. Obdobne ako je uvedené v kapitole [Nasadenie aplikácie na produkčný kubernetes klaster](./111-production-deployment), nasaďte Váš projekt do spoločného klastra.

>warning:> Spoločný klaster má nastavené striktné pravidlá v hlavičke [Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP). Pokiaľ chcete použiť nejaké externé zdroje - napríklad knižnicu dostupnú z CDN - tak prehliadač prístup na takúto adresu zablokuje. Všetky zdroje musia byť preto súčasťou vášho kódu.
