## Služby aplikácie - _Angular Services_

Vytvoríme službu, ktorá bude reprezentovať náš server. V tejto časti síce ešte
nebude prepojená na reálny server, umožní nám ale oddeliť aspekty komunikácie
po sieti od aspektov používateľského rozhrania.

[Služby (services)](https://angular.io/guide/architecture-services) slúžia na odľahčenie
komponentov a predstavujú ideálny spôsob ako zdieľať informácie medzi triedami, ktoré
sa navzájom nepoznajú.

1. Vygenerujte novú službu príkazom _Angular-CLI_

    ```powershell
    ng generate service services/ambulance-patients-list
    ```

2. Naimplementujte služby v súbore `src\app\services\ambulance-patients-list.service.ts`

    ```ts
    import { Injectable } from '@angular/core';
    import { Observable, of } from 'rxjs';
    import { WaitingEntryModel } from '../store/waiting-entry-model/waiting-entry-model.model';
    import { PatientsListMock } from '../patients-list/patients-list-mock';
    import { delay } from 'rxjs/operators';

    @Injectable({ providedIn: 'root' })
    export class AmbulancePatientsListService {

      public constructor() { }
  
      /** retrieves list of all patients currently waiting at ambulance
       *
       * @param ambulanceId - identification of the ambulance
       * @returns observable with one item of the list
       */
      public getAllPatientsEntries(ambulanceId: string): Observable<WaitingEntryModel[]>
      {
          return of(PatientsListMock.patients).pipe(delay(750)); // simulated delay over network
      }
  
      /** updates or inserts new entry in the patients list
       *
       * @param ambulanceId - identification of the ambulance
       * @param entry - new or updated entry
       *
       * @returns observable of the entry after it is updated at the server
       */
      public upsertEntry(ambulanceId: string, entry: WaitingEntryModel): Observable<WaitingEntryModel> {
          entry = Object.assign({}, entry); // create clone to avoid mutation of input
  
          if (!entry.id) {
            entry.id = `${PatientsListMock.patients.length + 1}`;
            PatientsListMock.patients.push(entry);
          } else {
            PatientsListMock.patients = PatientsListMock.patients.map(
              element => (element.id !== entry.id) ? element : entry);
          }
          return of(entry).pipe(delay(250));
      }
  
      /** removes an entry from the patients list
       *
       * @param ambulanceId - identification of the ambulance
       * @param entryId - id of entry to delete
       *
       * @returns observable referring to existence of item in
       *          the list before its removal
       */
      public deleteEntry(ambulanceId: string, entryId: string): Observable<boolean> {
          const exists = PatientsListMock.patients.findIndex(
              element => element.id === entryId) >= 0;
          PatientsListMock.patients = PatientsListMock.patients.filter(
              element => (element.id !== entryId));
          return of(exists).pipe(delay(300));
      }
  
      /** list of predefined ambulance visits reasons
       * and associated typical visit times
       *
       * @param ambulanceId - identification of the ambulance
       *
       * @returns observable of predefined reasons
       */
      public getWaitingReasons(ambulanceId: string): Observable< Array< {
          reasonCode: string,
          display: string,
          estimatedVisitMinutes: number} >> {
          return of([
              { reasonCode: 'folowup', display: 'Kontrola', estimatedVisitMinutes: 15 },
              { reasonCode: 'nausea', display: 'Nevoľnosť', estimatedVisitMinutes: 45 },
              { reasonCode: 'fever', display: 'Teploty', estimatedVisitMinutes: 20 },
              { reasonCode: 'ache-in-throat', display: 'Bolesti hrdla', estimatedVisitMinutes: 20 }
          ])
          .pipe(delay(200));
      }

    }
    ```

    Jednotlivé metódy úmyselne vracajú výsledky s oneskorením, aby sme sa čo najviac
    priblížili reálnej komunikácii so serverom.

3. Upravte súbor `src\app\effects\app.effects.ts`:

    ```ts
    import { Injectable } from '@angular/core';
    import { Actions, ofType, ROOT_EFFECTS_INIT, createEffect } from '@ngrx/effects';
    import { map, mergeMap } from 'rxjs/operators';
    import {
      loadWaitingEntryModels, uploadWaitingEntryModel,
      upsertWaitingEntryModel, deleteWaitingEntryModel
    } from '../store/waiting-entry-model/waiting-entry-model.actions';
    import { AmbulancePatientsListService } from '../services/ambulance-patients-list.service';

    @Injectable()
    export class AppEffects {

      constructor(private actions$: Actions,
                  private patientListService: AmbulancePatientsListService) { }

      init$ = createEffect(() => this.actions$.pipe(
        ofType(ROOT_EFFECTS_INIT),
        mergeMap(_ => this.patientListService.getAllPatientsEntries('ambulance')),
        map(patientListEntries => loadWaitingEntryModels({ waitingEntryModels: patientListEntries }))));

      upsert$ = createEffect(() => this.actions$.pipe(
        ofType(uploadWaitingEntryModel),
        mergeMap((action) =>
          this.patientListService.upsertEntry('ambulance', action.waitingEntryModel)),
        map(waitingEntryModel => upsertWaitingEntryModel({ waitingEntryModel }))));

      delete$ = createEffect(() => this.actions$.pipe(
        ofType(deleteWaitingEntryModel),
        mergeMap((action) =>
          this.patientListService.deleteEntry('ambulance', action.id))),
          { dispatch: false });

    }
    ```

    >info:> Všimnite si, že efekt vždy spracúva akciu a vracia novú akciu.
    > Keď nechceme, aby efekt vracal akciu, oznámime to parametrom `{ dispatch: false }`
    > ako v prípade poslednej akcie `delete`.

    >warning:> Žiaden z našich efektov nemá v poriadku error handling. Zamyslite
    > sa, čo sa stane, ak volanie na `patientListService` zlyhá.
    > Pre viac detajlov (aj s error handlingom) si pozrite stránku
    > [_ngrx/effects_](https://ngrx.io/guide/effects).

    Pridanie nového pacienta stále nefunguje. Konzola v prehliadači (F12) píše chybovú hlášku:
    _ERROR TypeError: Cannot add property 3, object is not extensible_.

    Je to spôsobené tým, že `ngrx` označí pole pacientov, ktoré vkladáme do jeho Stavu, ako readonly (pretože
    stav v Reduxe musí byť nemenný!).
    Metóda `AmbulancePatientsListService.getAllPatientsEntries` je volaná z `AppEffects.init$`...

    Napravíme to tak, že v metóde `AmbulancePatientsListService.getAllPatientsEntries` urobíme kópiu poľa:

    ```ts
      public getAllPatientsEntries(ambulanceId: string): Observable<WaitingEntryModel[]>
      {
        return of(Object.assign([], PatientsListMock.patients)).pipe(delay(750)); // simulated delay over network
        // return of([...PatientsListMock.patients]).pipe(delay(750)); // simulated delay over network
      }
    ```

    >info:> Zakomentovaný riadok používa tzv. `object spread` ako alternatívu k Object.assign().

    Overte funkcionalitu aplikácie, skontrolujte funkčnosť testov, submitnite 
    a pushnite zmeny do repozitára.

Pomocou debuggera overte v paneli
_Nástroje vývojára_ funkcionalitu vytvorenej služby - umiestnite body
prerušenia do jednotlivých metód a krokovaním sledujte, ako sa tieto metódy
vykonávajú. Počas krokovania si všimnite asynchrónne správanie sa metód.
Uvedená služba je
stále len náhradou reálnej práce so vzdialeným serverom. Tiež si môžete všimnúť,
že nová služba je automaticky dostupná ďalším objektom
v rámci Angular aplikácie - v našom prípade napríklad triede `AppEffects`.
K tomu postačuje dekorátor `Injectable`, bez použitia ktorého by inverzné
riadenie závislosti skončilo neúspešne (anglicky _Inversion of Control_,
pozri tiež [_Dependency Injection_](https://angular.io/guide/dependency-injection)).
