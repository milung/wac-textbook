## Vedľajšie efekty a navigácia z kódu

V tomto kroku si ukážeme ako uložiť novú položku a akým spôsobom vykonať vedľajšie
efekty nad úložiskom stavu aplikácie.

1.  Naviažte `click` udalosť tlačidla _Uložiť_ v súbore `src\app\waiting-entry-editor\waiting-entry-editor.component.html`.
    Upravte tiež polohu elementu `<ng-container ...` tak, aby bolo možné použiť parameter `data`.

    ```html
    <mat-card>
        <mat-card-header>
            <mat-card-title>Informácie o čakajúcom</mat-card-title>
        </mat-card-header>
        <ng-container *ngIf="data$ | async as data">
            <mat-card-content>
            ...
            </mat-card-content>
            <mat-card-actions>
                <button mat-button (click)="onUpsertEntry(data)">Uložiť</button>
                <button mat-button [routerLink]="['/patients-list']">Zrušiť</button>
            </mat-card-actions>
        </ng-container>
    </mat-card>
    ```
    
    Do súboru `src\app\store\waiting-entry-model\waiting-entry-model.actions.ts` pridajte nový typ akcie:
    ```ts
    ...
    export const upsertWaitingEntryModel = createAction(
      '[WaitingEntryModel] Upsert WaitingEntryModel',
      props<{ waitingEntryModel: WaitingEntryModel }>()
    );
    ```
     
    a vo `src\app\store\waiting-entry-model\waiting-entry-model.reducer.ts` definujeme novú prechodovú funkciu:
    ```ts
    ...
    on(WaitingEntryModelActions.upsertWaitingEntryModel,
      (state, action) => adapter.upsertOne(action.waitingEntryModel, state)
    ),
    ```

    V súbore `src\app\waiting-entry-editor\waiting-entry-editor.component.ts` doplňte do triedy `WaitingEntryEditorComponent` novú metódu

    ```ts
    ...
    import { upsertWaitingEntryModel } from '../store/waiting-entry-model/waiting-entry-model.actions';
    import { ActivatedRoute, Router } from '@angular/router';
    ...
    export class WaitingEntryEditorComponent implements OnInit {
        ...
        constructor(
            private readonly route: ActivatedRoute,
            private readonly store: Store<AmbulanceState>,
            private readonly router: Router) {
            this.knownConditions$ = of([
                { concept: 'folowup', display: 'Kontrola' },
                { concept: 'nausea', display: 'Nevoľnosť' },
                { concept: 'fever', display: 'Teploty' },
                { concept: 'ache-in-throat', display: 'Bolesti hrdla' }
            ]);
        }
        ...
        public onUpsertEntry(waitingEntryModel: WaitingEntryModel): void {
            this.store.dispatch(
                upsertWaitingEntryModel({ waitingEntryModel }));
            this.router.navigate(['/', 'patients-list']);
        }
    }
    ```

    V tejto chvíli môžme vytvárať nové záznamy, údaje nového záznamu sa dočasne 
    ukladajú v rámci `ngrx Store`. Nevýhodou tohto riešenia je,
    že vieme vytvoriť iba jednu inštanciu, nakoľko parameter `id` nového záznamu
    zostáva nedefinovaný. Tento problém vyriešime o chvíľu, najprv však pomocou 
    `RouterStoreModule` prepojíme stav Angular router-a s úložiskom aplikačného stavu.
    Samotný `RouterStoreModule` neprináša možnosť navigácie, umožňuje ale sledovať
    zmeny navigácie.
    Navyše umožňuje vykonávať efekty v závislosti od toho, na ktorej stránke sa aplikácia
    nachádza, napríklad načítať údaje zo servera až vtedy, keď ich používateľ naozaj
    potrebuje.

2. Pridajte do projektu nový balík [@ngrx/router-store](https://ngrx.io/guide/router-store)

    ```powershell
    npm install @ngrx/router-store --save
    ```

    Upravte súbor `src\app\store\index.ts`

    ```ts
    ...
    import { routerReducer, RouterReducerState, SerializedRouterStateSnapshot }
    from '@ngrx/router-store';

    export interface AmbulanceState {
        router: RouterReducerState<SerializedRouterStateSnapshot>;
        [fromWaitingEntryModel.waitingEntryModelsFeatureKey]: fromWaitingEntryModel.State; 
    }

    export const reducers: ActionReducerMap<AmbulanceState> = {
        router: routerReducer,
        [fromWaitingEntryModel.waitingEntryModelsFeatureKey]: fromWaitingEntryModel.reducer
    };
    ...
    ```

    a súbor `src\app\app.module.ts`

    ```ts
    ...
    import { StoreRouterConnectingModule } from '@ngrx/router-store';

    @NgModule({
        declarations: [ ... ],
        imports: [
            ...
            StoreRouterConnectingModule.forRoot()
            ],
        providers: [],
        bootstrap: [AppComponent]
    })
    export class AppModule { }
    ```

    Odteraz vidíme v paneli _Redux_ aj akcie navigácie medzi jednotlivými stránkami aplikácie.

3. Teraz vyriešime horeuvedený problém s vytváraním iba jednej inštancie. 
   V súbore `src\app\store\waiting-entry-model\waiting-entry-model.actions.ts` pridajte
   novú akciu

    ```ts
    ...
    export const uploadWaitingEntryModel = createAction(
      '[WaitingEntryModel] Upload WaitingEntryModel',
      props<{ waitingEntryModel: WaitingEntryModel }>()
    );
    ```

    v súbore `src\app\effects\app.effects.ts` doplňte nový efekt

    ```ts
    ...
    import {
      loadWaitingEntryModels, uploadWaitingEntryModel,
      upsertWaitingEntryModel
    } from '../store/waiting-entry-model/waiting-entry-model.actions';
    import { map } from 'rxjs/operators';

    @Injectable()
    export class AppEffects {
      constructor(private actions$: Actions) {}

      // we will delete this later
      private idCounter = 100;

      computeId$ = createEffect(() => this.actions$.pipe(
        ofType(uploadWaitingEntryModel),
        map((action) => {
          let waitingEntryModel = action.waitingEntryModel;
          if (!waitingEntryModel.id) {
            waitingEntryModel = Object.assign({}, waitingEntryModel, { id: ++this.idCounter });
          }
          return upsertWaitingEntryModel({ waitingEntryModel });
        })));
    ...
    ```

    a upravte obslužný kód tlačidla _Uložiť_ v súbore `src\app\waiting-entry-editor\waiting-entry-editor.component.ts`

    ```ts
    public onUpsertEntry(waitingEntryModel: WaitingEntryModel): void {
      this.store.dispatch(uploadWaitingEntryModel({ waitingEntryModel }));
      this.router.navigate(['/', 'patients-list']);
    }
    ```

    V tejto chvíli už môžme vytvárať a ukladať nové záznamy. Vyskúšajte vytvoriť
    aspoň dva nové záznamy a sledujte aktivitu aplikácie v paneli _Nástroje
    vývojára - Redux_.

    Skontrolujte funkčnosť testov, komitnite a pushnite do repozitára.