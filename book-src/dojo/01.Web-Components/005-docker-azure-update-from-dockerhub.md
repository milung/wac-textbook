## Polo-automatické nasadenie (automatická aktualizácia docker obrazu z dockerhub)

---

```ps
devcontainer templates apply -t registry-1.docker.io/milung/wac-ufe-004b
```

---

V predchádzajúcej časti sme manuálne nasadili kontajnerizovanú web aplikáciu na
Azure cloud. Teraz si ukážeme jednoduchý spôsob, ako nastaviť, aby sa aplikácia automaticky
aktualizovala, keď sa zmení jej docker obraz na Docker Hube.

1. Vráťte sa do portálu [Azure][azure-portal], do vašej web aplikácie a
   v záložke _Deployment Center_ prepnite voľbu _Continuous deployment_ na `On` a
   skopírujte hodnotu z políčka _Webhook URL_. Uložte nastavenie stlačením tlačidla _Save_:

    ![Deplyment Center Web Aplikácie Azure](./img/dojo-azurewebapp-cd.png)

    Prejdite na stránku [Docker Hub][docker-hub], otvorte detaily vášho obrazu
    `ambulance-ufe` a prejdite do záložky _Webhooks_. Vytvorte nový webhook, pomenujte ho
    _Azure WebApp_ a ako URL nastavte hodnotu skopírovanú z Azure portálu.

    ![Vytvorenie web-hook záznamu na DockerHub](./img/dojo-dockerhub-webhook.png)

    Týmto nastavením sme zabezpečili, že kedykoľvek sa do registra Docker Hub zapíše nový
    obraz s označením `<your-account>/ambulance-ufe:latest`, webová služba vytvorená na
    platforme Microsoft Azure automaticky získa najnovší obraz kontajnera s týmto
    označením.

2. Do _CI pipeline_ pridáme krok na zverejnenie novej verzie docker obrazu po úspešnom
   builde. Tentoraz budeme ručne upravovať predpis priebežnej integrácie.

   V kapitole [Kontajnerizácie aplikácie](./004a-ufe-containerization.md) sme vytvorili obraz pomocou príkazu `docker build`. Tento príkaz vytvoril obraz pre aktuálnu platformu nášho prostredia - `linux/amd64` v prostredí Windows alebo linux na procesoroch Intel/AMD, alebo `linux/arm64/v8` na novších modeloch Apple Mac. Aby bol náš generovaný obraz použiteľný na rôznych platformách, musíme vytvoriť takzvanú [viac-platformovú zostavu](https://docs.docker.com/build/building/multi-platform/), ktorá vytvorí rôzne obrazy a zaregisturje ich v registry pod spoločným názvom (tzv. manifest s viacerími odkazmi). Lokálne by sme k tomu použili príkaz `docker buildx build --platform linux/amd64,linux/arm64/v8 --push -t <pfx>/ambulance-ufe .`. Detaily o tomto postupe nájdete [tu](https://docs.docker.com/build/building/multi-platform/).  V priebežnej integrácii budeme výtvarať práve takéto viac-platformové obrazy.

   Otvorte súbor `${WAC_ROOT}/ambulance-ufe/.github/workflows/ci.yml` a na jeho konci pridajte nové kroky predpisu:

   ```yaml
   ...
        - run: npm test

        - name: Set up QEMU @_add_@
          uses: docker/setup-qemu-action@v1  @_add_@
          @_add_@
        - name: Set up Docker Buildx @_add_@
          id: buildx @_add_@
          uses: docker/setup-buildx-action@v1   @_add_@
    ```

   Tieto kroky pridajú do pipeline podporu pre viac-platformové zostavy. V ďaľšom kroku pridáme  príkaz na prihlásenia sa do registra Docker Hub:

   ```yaml
   ...
   - name: Login to DockerHub
     uses: docker/login-action@v1 
     with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
   ```

   Premenné `secrets.DOCKERHUB_USERNAME` a `secrets.DOCKERHUB_TOKEN` nastavíme v krokoch nižšie.

   Ďalej pridáme krok na vytvorenie viac-platformového obrazu:

   ```yaml
    ...
    - uses: docker/build-push-action@v2
        with:
          context: .
          platforms: linux/amd64,linux/arm64/v8
          file: ./build/docker/Dockerfile
          push: true
          tags: <pfx>/ambulance-ufe:latest 
   ```

   >info:> V tomto cvičení vytvárame vždy obraz s tagom `<pfx>/ambulance-ufe:latest` pre zjednodušenie ďalšieho postupu. V reálnym projektoch sa bežne stretnete s nastavením `tags: {{ steps.meta.outputs.tags}}` pričom použitá premenná je generovaná GitHub akciou [docker/metadata-action](https://github.com/docker/metadata-action) a umožňuje generovať rôzne tagy v závislosti od udalosti vykonanej nad našim repozitárom (napr _pull request_, alebo vytvorenie _release_-u).

3. Pre úspešny beh priebežnej integrácie je nutné ešte nastaviť premenné `secrets.DOCKERHUB_USERNAME` a `secrets.DOCKERHUB_TOKEN`. Prejdite na stránku [Docker Hub], Rozbaľte menu označené názvom Vášho účtu a zvoľte _Account Settings_. V záložke _Security_ nájdete tlačidlo _New Access Token_.

   ![Vytvorenie nového tokena pre Docker Hub](./img/005-01-AccountSecurity.png)

   Vytvorte nový token s názvom `ambulance-ufe CI` a priradte mu práva `Read, Write, Delete` a stlačte tlačidlo _Generate_. Vygenerovaný token si skopírujte do schránky.

   Teraz prejdite do Vášho repozitára `<pfx>/ambulance-ufe` na stránke [GitHub]. V hornej lište zvoľte záložku _Settings_ a následne na bočnom panely zvoľte položku _Secrets and Variables_ -> _Actions_.
   Na tejto stánke stlačte na tlačidlo _New repository secret_ a vytvorte novú premennú s názvom `DOCKERHUB_TOKEN` a ako hodnotu vložte zo schránky skopírovaný token. Opäť stlačte na tlačidlo _New repository secret_ a vytvorte premmenú s názvom `DOCKERHUB_USERNAME` a ako hodnotu vložte svoje používateľské meno na Docker Hub.

   ![Premmenné a kľúče pre beh priebežnej integrácie](./img/005-02-GithubSecrets.png)

   Vytvorené premenné sú k dispozícii pre ďaľší beh našej priebežnej integrácie.

4. V priečinku `${WAC_ROOT}/ambulance-ufe` zverejnite zmeny zdrojového kódu príkazmi:

    ```ps
    git add .
    git commit -m "ci - publish docker image"
    git push
    ```

5. Zverejnite zmeny zdrojového kódu príkazmi:

    ```ps
    git add .
    git commit -m "docker file"
    git push
    ```

6. Na stránke [GitHub] vo Vašom repozitári `<pfx>/ambulance-ufe` prejdite do záložky _Actions_ a skontrolujte, že sa nový beh priebežnej integrácie úspešne dokončí. Po jej ukončení si môžete overiť aj stav obrazu na stránke Docker Hub, kde môžete vidieť nové označenia verzie a platformy pre váš image.

Týmto spôsobom sme vlastne zabezpečili kontinuálne nasadenie tejto webovej aplikácie do prostredia [Azure][azure-portal]. Obdobným spôsobom by sme vedeli nasadzovať ďaľšie služby respektíve využívať už existujúce služby poskytované na platforme Azure. Detailné návody ako postupovať, pokiaľ chcete primárne vytvárať riešenia nad už existujúcimi službami Azure najdete napríklad [tu](https://learn.microsoft.com/en-us/azure/architecture/).

Ďalej si v tomto cvičení ukážeme postup ako  vytvoriť aplikáciu technikou mikro Front End a nasadiť ju do prostredia [Kubernetes] s využitím [GitOps](https://www.gitops.tech/) techniky.
