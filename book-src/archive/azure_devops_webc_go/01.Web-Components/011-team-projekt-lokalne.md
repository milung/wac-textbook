# Zdieľanie nasadenia tímového projektu na lokálnom klastri

V tejto chvíli nasadzujeme našu ambulance-list aplikáciu ako na lokálnom klastri, tak aj na produkčnom klastri, pričom je náš deployment aplikácie rozdelený do rôznych repozitárov a v zásade duplikovaný. Pre potreby cvičného príkladu v tomto móde zostaneme - budeme sa sústrediť najmä na lokálny klaster tak, aby každý mohol postupovať samostatne. Tento postup je ale z hľadiska tímovej prace neefektívny a preto si ukážeme ako pracovať s tímovým semestrálnym projektom tak, aby bol deployment aplikácie použitý zo spoločného repozitára.

>info:> Táto kapitola slúži len ako ukážka, nebude na cvičeniach preberaná.

## Vytvorenie bázovej konfigurácie pre tím

>warning:> V nasledujúcom texte nahraďte reťazec `<pfx>` vhodným názvom tímu.

Predpokladajme tím `<pfx>`, ktorý pracuje na aplikácii pre výdaj liekov na ambulanciách. Konečným výsledkom preto bude aplikácia (_deployment_) pre front-end web komponent `<pfx>-pharmas-ufe` a s ním asociované web api `<pfx>-pharmas-webapi`. Aby sme dosiahli nejakú nezávislosť tímu, tím bude pracovať na git vetve `<pfx>/dev-stage` a vždy, keď bude jeho vývojový inkrement pripravený na nasadenie, vytvorí merge request medzi vetvou `<pfx>/dev-stage` a vetvou `main` (je v zodpovednosti tímu aby si vetvu `<pfx>/dev-stage` nezmazal a aby si tím zvolil vhodný proces ako prispievať do tejto vetvy).

Naklonujte si [Gitops repozitár pre spoločný klaster][gitops-class] do vášho pracovného adresára.

Následne prejdite do adresára `.../<gitops-repo>/` a pomocou príkazu

```sh
git switch <pfx>/dev-stage
```

vytvorte a prepnite sa do novej git vetvy. Teraz vytvorte adresárovú štruktúru:

```plain
WAC2022AppsRepo
|- <pfx>-team
    |- <pfx>-pharmas-ufe
    |- <pfx>-pharmas-webapi
    |_ kustomization.yaml
```

V týchto adresároch vytvorte príslušné manifesty a nakoniec upravte súbor `.../<gitops-repo>/clusters/prod/kustomization.yaml` tak, aby referencoval adresár `<pfx>-team`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
...
- ../../<pfx>-team @_add_@
```

Funkčnosť konfigurácie môžete tiež overiť z príkazového riadku na úrovni adresára `.../<gitops-repo>/` pomocou príkazu

```sh
kubectl kustomize <pfx>-team
```

Po aplikovaní zmien (_merge_)  do vetvy `main` v repozitári [Gitops repozitár pre spoločný klaster][gitops-class] by sa mali tímové aplikácie objaviť v produkčnom klastri. Nasledujúca sekcia popisuje ako overiť funkčnosť v rámci lokálneho klastra.

## Flux konfigurácia

Základom pre konfiguráciu lokálneho klastra zostanú individuálne repozitáre, ktoré používame na cvičeniach. Chceme dosiahnuť aby flux systém nasadzoval automatizovaným spôsobom okrem lokálnej infraštruktúry a aplikácie `ambulance-list` a `ambulance-web-api` aj tímovú aplikáciu.

1. Na stránke [Personal Access Tokens](https://gitlab.com/-/profile/personal_access_tokens) vytvorte nový Personal Access Token, pomenujte ho `webcloud-local-flux` a povoľte mu rozsah prístupu `read_repository` a `write_repository` (v prípade ak sa rozhodnete pre _image update automation_). Nastavte vhodnú dobu platnosti.

2. Na príkazovom riadku prejdite do priečinka `.../webcloud-gitops/flux-system`. V prvom kroku chceme aby flux controller mal prístup k repozitáru `WAC2022AppsRepo`. Vykonajte preto príkaz

    ```sh
    $pat="<vygenerovaný personal access token>"
    $giturl="https://gitlab.com/cagardap/wac2022appsrepo.git"
    $branch="<pfx>/dev-stage"
    flux create source git prod-gitops-repo --git-implementation=libgit2 --url=$giturl --branch=$branch --username=git --password=$pat --interval=60s 
    ```
 
    >info:> V prípade, že nepoužívate PowerShell konzolu, upravte príkazy podľa syntaxe Vášho interpretera

   Overte, že bol git source vytvorený

    ```sh
    flux get sources all
    ```

   a uložte si konfiguráciu

    ```sh
    flux export source git prod-gitops-repo > prod-gitops-repo.yaml
    ```

3. Ďalej chceme vytvoriť _Kustomize_ objekt, ktorý bude sledovať konfiguráciu pre aplikácie tímu z adresára `...\<gitops-repo>/<pfx>-team`, a z git vetvy `<pfx>/dev-stage`.

    ```sh
    flux create kustomization <pfx>-team-localhost-kustomization --source=prod-gitops-repo --path="./ <pfx>-team" --prune=true --interval=40s
    ```

   Overíme, či bol vytvorený

    ```sh
    flux get kustomizations
    ```

   a uložíme si jeho konfiguráciu

    ```sh
    flux export kustomization <pfx>-team-localhost-kustomization > <pfx>-team-localhost-kustomization.yaml
    ```

Po týchto krokoch začne flux controller sledovať konfiguráciu tímu na vetve `<pfx>/dev-stage` a aplikuje ju v rámci lokálneho klastra. Infraštrukturálna služba `ufe-controller` zareaguje na nový _custom resource_ WebComponent a na úvodnej stránke zobrazí odkaz na tímovú aplikáciu.
