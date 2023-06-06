## Smerovanie a navigácia medzi panelmi aplikácie

V tejto kapitole si ukážeme, ako angular zabezpečuje navigáciu medzi panelmi aplikácie (komponentami).
Momentálne máme vytvorený len jeden panel, zobrazujúci aktuálny stav čakajúcich.
Najprv si vygenerujeme kostru nového komponentu, ktorý nám bude umožňovať zadanie novej položky 
a jej editáciu na samostatnom paneli. Tento komponent si naimplementujeme v ďalšej kapitole.
Na prepínanie medzi komponentami použijeme navigáciu (routing).

1. Vygenerujte nový komponent `WaitingEntryEditor`:
   ```powershell
   ng generate component WaitingEntryEditor
   ```

2. V Angulari je úzus vytvoriť pre potreby navigácie nový modul najvyššej úrovne. Tento modul sa podľa konvencie 
   zvykne volať `AppRoutingModule`.
   Vygenerujte preto nový modul príkazom:
   ```powershell
   ng generate module app-routing --flat --module=app
   ```
   
   Prepínač `--flat` zabezpečí, že sa pre novovytvorený súbor `app-routing.module.ts` nevytvorí nový adresár.
   Miesto toho sa súbor umiestni do adresára `src/app`.
   Prepínačom `--module=app` zabezpečíme naimportovanie `AppRoutingModule` do `AppModule`.

3. V súbore `src\app\app-routing.module.ts` vyrobte zoznam ciest:

   ```ts
   import { NgModule } from '@angular/core';
   import { Routes } from '@angular/router';
   import { PatientsListComponent } from './patients-list/patients-list.component';
   import { WaitingEntryEditorComponent } from './waiting-entry-editor/waiting-entry-editor.component';

   export const routes: Routes = [
       { path: 'patients-list', component: PatientsListComponent },
       { path: 'patients-list/:id', component: WaitingEntryEditorComponent },
       {
           path: '',
           redirectTo: '/patients-list',
           pathMatch: 'full'
       }
   ];
  
   @NgModule({
    declarations: [],
   })
   export class AppRoutingModule { }

   ```
   Zoznam `routes` priraďuje každej ceste komponent, ktorý sa použije na vizualizáciu stránky.

3. Doplňte závislosť na `RouterModule` a pridajte požadované importy a exporty.

   ```ts
   ...
   import { Routes, RouterModule } from '@angular/router';

   @NgModule({
   ...
   imports: [RouterModule.forRoot(routes, { enableTracing: true })], // <-- enableTracing: true is there only for debugging purposes 
   exports: [RouterModule]
   ...
   ```

    Vyskúšajte prejsť na odkaz [http://localhost:4200](http://localhost:4200).
    Stránka stále funguje, všimnite si, že sme boli presmerovaní na stránku [http://localhost:4200/patients-list](http://localhost:4200/patients-list).
    Na prvý pohľad sa teda zdá, že navigácia funguje.
    Vyskúšajte prejsť na odkaz [http://localhost:4200/patients-list/1](http://localhost:4200/patients-list/1).
    Očakávame, že bude zobrazená stránka komponentu `WaitingEntryEditor`. Vidíme ale stále zobrazenú stránku so zoznamom pacientov.

    Ak chceme, aby sa nám zobrazila stránka, na ktorú sa odkazujeme v rámci `routes`, musíme použiť element `<router-outlet>`.

4. V súbore `src\app\app.component.html` vymažte element
  `<app-patients-list></app-patients-list>` a pridajte element `<router-outlet></router-outlet>`. Opäť
   vyskúšajte oba odkazy [http://localhost:4200/patients-list](http://localhost:4200/patients-list)
   a [http://localhost:4200/patients-list/1](http://localhost:4200/patients-list/1).

5. Upravte padajúce testy:
    Do súborov `src\app\patients-list\patients-list.component.spec.ts` a `src\app\app.component.spec.ts` 
    pridajte 
   ```ts
   ...
   import { RouterTestingModule } from '@angular/router/testing';
   ...
     imports: [
        MatIconModule,
        MatToolbarModule,
        MatExpansionModule,
        MatFormFieldModule,
        RouterTestingModule
     ],
   ...   
   ```

   Submitnite a pushnite zmeny do repozitára. Overte funkčnosť na cloude. 

   >warning:> Na cloude navigácia z prehliadača nefunguje, napr. pri obnovení stránky alebo ručnom prepísaní adresy 
   na `...azurewebsites.net/patients-list/1` sa vypíše chybové hlásenie.
   To je spôsobené tým, že v tomto prípade neobsluhuje routing samotná aplikácia, ale prehliadač priamo posiela požiadavku
   na server. Avšak na serveri daná adresa neexistuje a vráti chybu 404. Riešením je povedať serveru, aby vracal `index.html`.
   To sa robí rôznym spôsobom pre každý server, pre IIS, ktorý beží na azure, je to nasledovne. (Viac informácií 
   nájdete tu: [https://angular.io/guide/deployment#server-configuration](https://angular.io/guide/deployment#server-configuration)).

   >info:> Lokálne beží `Angular Live Development Server`.

   Do adresára `src` pridajte súbor `web.config` s nasledovným obsahom:

   ```html
   <?xml version="1.0" encoding="UTF-8"?>
   <configuration>
   <system.webServer>
       <rewrite>
       <rules>
           <rule name="Angular Routes" stopProcessing="true">
           <match url=".*" />
           <conditions logicalGrouping="MatchAll">
               <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
               <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
           </conditions>
           <action type="Rewrite" url="/index.html" />
           </rule>
       </rules>
       </rewrite>
   </system.webServer>
   </configuration>
   ```

   A do súboru `angular.json` do položky `assets` pridajte riadok `"src/web.config"`, aby bol súbor deploynutý.

   Submitnite a pushnite zmeny do repozitára a znovu overte funkčnosť na cloude. 
