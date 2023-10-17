## Nasadenie Web Api na produkčný kubernetes klaster

Rovnako ako v prípade web klienta, aj pre webapi bola infraštruktúra nasadená centrálne. To znamená, že v klastri bežia kontajnery _MongoDb_ a _Mongo Express_.

Zároveň sú na produkčnom klastri nasadené všetky service mesh komponenty z predchádzajúcich častí (ingress, oauth, opa).

Na Mongo Express bolo vytvorené ingress pravidlo, aplikácia je prístupná na adrese [https://wac-2023.germanywestcentral.cloudapp.azure.com/mongoexpress](https://wac-2023.germanywestcentral.cloudapp.azure.com/mongoexpress).
Keďže ide o verejne prístupný zdroj, prístup je chránený menom a heslom, ktoré sa dozviete od cvičiaceho.

1. Overte, či stále funguje vaša klient aplikácia (webkomponent) na adrese [https://wac-2023.germanywestcentral.cloudapp.azure.com/ui](https://wac-2023.germanywestcentral.cloudapp.azure.com/ui).

2. Zvýšime manuálne verziu klienta na poslednú, ktorú máme otestovanú lokálne a ktorej obraz je prístupný na dockerhub, t.j. upravte súbor v gitlab repozitári [https://github.com/SevcikMichal/WACAppsRepo](https://github.com/SevcikMichal/WACAppsRepo). Vojdite do priečinku vašej aplikácie a v ňom je súbor `<pfx>-ambulance-ufe/deployment.yaml`. Upravte riadok

   ```yaml
   ...
   image: <dockerid>/ambulance-ufe:<posledný-tag-z-dockerhub>
   ...
   ```

   Komit, push a vytvorte pull request.

3. V rovnakom priečinku upravte súbor `webcomponent.yaml`. Ako vzor použite rovnaký súbor vo svojom `webcloud-gitops` repozitári, t.j. pridajte do časti _attributes_:

   ```yaml
   ...
   attributes:                   
     - name: api-uri
       value: /<pfx>-waiting-list-api
   ...
   ```

   Parametrom `api-uri` sme nastavili nášmu web komponentu adresu, na ktorej má pristupovať k web api. V kubernetes klastri je adresa meno servisu, pod ktorým beží webapi kontajner.

4. Stále v gitlab repozitári, v priečinku vašej aplikácie vytvorte nový priečinok `<pfx>-ambulance-webapi` a prekopírujte tam obsah rovnakého priečinku z vášho `webcloud-gitops` repozitára. Mali by tam byť 4 súbory - `deployment.yaml, service.yaml, ingress.yaml a kustomization.yaml`.

    Upravte verziu docker obrazu v súbore `deployment.yaml` na poslednú.

5. Stále v gitlab repozitári v priečinku vašej aplikácie upravte súbor `kustomization.yaml`

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - <pfx>-ambulance-ufe
     - <pfx>-ambulance-webapi
   ```

6. Komit, push a vytvorte pull request.

   Keď sa zmeny dostanú do `main` vetvy a flux nasadí nové komponenty, overte, že vaše pody bežia - buď cez _Lens_ tool alebo _kubectl_ príkaz. (Nezabudnite zmeniť kontext!)

   ```ps
   kubectl config get-contexts
   kubectl config use-context <meno-kontextu-na-produkcny-k8s>
   kubectl get pods -n wac-hospital
   ```

7. Môžete skúsiť pristúpiť na váš web komponent cez stránku [https://wac-2023.germanywestcentral.cloudapp.azure.com/ui](https://wac-2023.germanywestcentral.cloudapp.azure.com/ui), ale s najväčšou pravdepodobnosťou volanie webapi zlyhá z dôvodu, že nie je inicializovaná databáza.

   Keďže webapi je prístupné iba cez autentifikáciu, musíme znovu využiť funkciu port forward. Zoberte si celé meno svojho webapi podu z predchádzajúceho výpisu a použite ho v nasledujúcom príkaze:

   ```ps
   kubectl port-forward pod/<CELE-MENO-PODU> -n wac-hospital 8222:8080
   ```

   Použite aplikáciu Postman a inicializujte databázu poslaním POST požiadavky na adresu `http://localhost:8222/api/waiting-list/bobulova` s obsahom json:

    ```json
    {
      "id": "bobulova",
      "name": "Ambulancia všeobecného lekára Dr. Bobulová",
      "roomNumber": "211 - 2.posch",
      "predefinedConditions": [
        {
          "value": "Teploty",
          "code": "subfebrilia",
          "reference": "https://zdravoteka.sk/priznaky/zvysena-telesna-teplota/",
          "typicalDurationMinutes": 20
        },
        {
          "code": "folowup",
          "value": "Kontrola",
          "typicalDurationMinutes": 15
        },
        {
          "code": "nausea",
          "value": "Nevoľnosť",
          "typicalDurationMinutes": 45,
          "reference": "https://zdravoteka.sk/priznaky/nevolnost/"
        }
      ]
    }
    ```

8. Cez mongo express [https://wac-2023.germanywestcentral.cloudapp.azure.com/mongoexpress](https://wac-2023.germanywestcentral.cloudapp.azure.com/mongoexpress) skontrolujte, či sa databáza vytvorila.

   Znovu pristúpte na váš web komponent cez stránku [https://wac-2023.germanywestcentral.cloudapp.azure.com/ui](https://wac-2023.germanywestcentral.cloudapp.azure.com/ui) a otestujte funkcionalitu - pridanie, zmenu a odobratie pacienta zo zoznamu.

-------------

Integrácia frontendu s backendom je ukončená.
