## Zhrnutie

Ukázali sme si základný postup ako vytvoriť jednostránkovú Web aplikáciu s použitím techniky web komponentov a mikro-front-end integrácie. Využili sme k tomu knižnicu Stencil JS a radič mikro-front-end aplikácií vytvorený pre potreby tohto projektu.

Vytvorená aplikácia je značne zjednodušená a pre účely ušetrenia času sme neukázali mnohé techniky, ktoré pri reálnych projektoch môžu byť zásadné. Okrem knižnice Stencil JS môžme pre potreby tvorby využiť aj iné knižnice, odporúčame pozrieť si napríklad knižnicu [Lit]. Tvorba web komponentov je ale podporovaná aj v ostatných rozšírených knižniciach ako je [Angular], [React], alebo [Vue].

V cvičení sme neriešili správu stavu aplikácie, čo v prípade väčších aplikačných systémov môže byť zásadné. Odporúčame preto naštudovať niektorú z implementácií návrhového vzoru [Redux]. Taktiež sme neriešili problematiku riadenia závislostí medzi triedami systému - záme ako _Inversion of Control_, čo v praxi môže sťažiť testovanie aplikácie a spomaliť vývoj pri budúcej evolúcii systému. V súčasnosti sa čoraz populárnejšou stáva knižnica [Inversify], ktorú je možné použiť za týmto účelom.

Pokiaľ neplánujete použiť techniku mikro-front-end a skôr máte záujem o vytvorenie Single Page aplikácie s knižnicou, ktorá adresuje rôzne aspekty architektúry a údržby moderných aplikácií vyvíjaných tímovým spôsobom, odporúčame vyskúšať knižnicu [Angular].
