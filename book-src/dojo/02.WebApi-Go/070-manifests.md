# Vytvorenie znovupoužiteľných manifestov pre nasadenie mikroslužby WEB API do klastra Kubernetes

---

```ps
devcontainer templates apply -t registry-1.docker.io/milung/wac-api-060
```

---

Ďalším logickým krokom po vytvorení predpisu priebežnej integrácie je zabezpečenie priebežného nasadenia našej služby WEB API a jej integrácia s front-end aplikáciou. Priebežné nasadenie budeme riešiť formou gitops, podobne ako tomu bola pri front-end aplikácii. Pri samotnom nasadzovaní si zároveň ukážeme niektoré techniky ako rozšíriť náš kubernetes deployment/pod o dodatočné služby.

Samotnú integráciu v tomto cvičení budeme riešiť len čiastočne, úplnú integráciu do cieľového klastra si potom ukážeme v ďaľšom cvičení, kde budeme vytvárať takzvané [Service Mesh](https://buoyant.io/service-mesh-manifesto) riešenie.

Na rozdiel od prvého cvičenia nezačneme naše manifesty vytvárať priamo v repozitári `${WAC_ROOT}/ambulance-gitops`, ale ich vytvoríme ako súčasť nášho projektu v adresári `${WAC_ROOT}/ambulance-webapi`. Tu ich ale nevytvárame ako konfiguráciu systému, ale skôr ako knižnicu pre vytváranie konfigurácie v cieľových prostrediach.

1. Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install/deployment.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: <pfx>-ambulance-webapi 
    spec:
      replicas: 1
      selector:
          matchLabels:
            pod: <pfx>-ambulance-webapi-label 
      template:
          metadata:
            labels:
              pod: <pfx>-ambulance-webapi-label 
          spec:
            containers:
            - name: <pfx>-ambulance-wl-webapi-container 
              image: <pfx>/ambulance-wl-webapi:latest 
              imagePullPolicy: Always
              ports:
              - name: webapi-port
                containerPort: 8080
              env:
                - name: AMBULANCE_API_ENVIRONMENT
                  value: production
                - name: AMBULANCE_API_PORT
                  value: "8080"
                - name: AMBULANCE_API_MONGODB_HOST
                  value: mongo
                - name: AMBULANCE_API_MONGODB_PORT
                  value: "27017"
                  # change to actual value
                - name: AMBULANCE_API_MONGODB_USERNAME
                  value: ""
                  #change to actual value
                - name: AMBULANCE_API_MONGODB_PASSWORD
                  value: ""
                - name: AMBULANCE_API_MONGODB_DATABASE
                  value: <pfx>-ambulances
                - name: AMBULANCE_API_MONGODB_COLLECTION
                  value: ambulances
                - name: AMBULANCE_API_MONGODB_TIMEOUT_SECONDS
                  value: "5"
              resources:
                requests:
                  memory: "64Mi"
                  cpu: "0.01"
                limits:
                  memory: "512Mi"
                  cpu: "0.3"

    ```

   Štruktúru manifestu už poznáme z predchádzajúceho manifestu pre front-end aplikáciu. V tomto prípade sme ale pridali aj definíciu environmentálnych premenných, ktoré budú použité pri spustení kontajnera. Vymenovanie všetkých prememných uľahčí prácu používateľom, ktorý nepoznajú implementáciu našej služby. Všetky hodnoty v sekcii `env` musia byť typu string, preto je nutné uviesť aj číselné hodnoty v úvodzovkách.

2. Súčasťou požiadaviek na našu službu je aj možnosť získať prehľad o funkcionalite WEB API služby a možnosť si vyskúšať prácu s ňou. K tomu využijeme obraz kontajnerizovanej aplikácie [swaggerapi/swagger-ui](https://hub.docker.com/r/swaggerapi/swagger-ui). Môžeme ju nasadiť samostatne ako voliteľný komponent, alebo ju môžeme nasadiť ako [_sidecar_](https://learn.microsoft.com/en-us/azure/architecture/patterns/sidecar) k našej službe. Zvolíme si druhú možnosť a do zoznamu kontajnerov nášho podu pridáme ďalší kontajner.

   >info:> Všetky kontajneri v rámci toho istého podu sa správajú akoby boli na tom isto zariadení v rámci virtuálnej siete, ktorá je vytvorená pre daný kluster

   Do súboru `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install/deployment.yaml` pridajte nasledujúci kód:

    ```yaml
    ...
        spec:
            containers:
            - name: <pfx>-ambulance-wl-webapi-container
            ...
            - name: openapi-ui   @_add_@
            image: swaggerapi/swagger-ui   @_add_@
            imagePullPolicy: Always   @_add_@
            ports:   @_add_@
            - name: api-ui   @_add_@
                containerPort: "8080"   @_add_@
            env:           @_add_@
              - name: PORT   @_add_@
                value: "8081"   @_add_@
              - name:   URL   @_add_@
                value: http://localhost:8080/.openapi/   @_add_@
              - name: BASE_URL   @_add_@
                value: /openapi-ui   @_add_@
              - name: FILTER   @_add_@
                value: 'true'   @_add_@
              - name: DISPLAY_OPERATION_ID   @_add_@
                value: 'true'   @_add_@
            resources:   @_add_@
                requests:   @_add_@
                    memory: "16M"   @_add_@
                    cpu: "0.01"   @_add_@
                limits:   @_add_@
                    memory: "64M"   @_add_@
                    cpu: "0.1"   @_add_@
    ```

   Adresa `http://localhost:8080/.openapi/` ukazuje z pohľadu podu na to isté zariadenie, to znamená ten istý pod, akurát sa použije iný socket port.

3. Naša aplikácia predpokladá existenciu databázy určenej premennou prostredia `AMBULANCE_API_MONGODB_DATABASE` ako aj existenciu kolekcie dokumentov pomenou premennou prostredia `AMBULANCE_API_MONGODB_COLLECTION`. Aby sme sa vyhli nutnosti manuálneho vytvárania tejto databázy/kolekcie, pomožeme si [inicializačným kontajnerom](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/). Procesy inicializačné kontajnerov sú vykonané pred štartom procesov samotných kontajnerov podu, ktoré sa vytvoria len za predpokladu, že procesy inicializačných kontajnerov boli ukončené so stavovým kódom indikujúcim úspešné vykonanie procesu. V našom prípade chceme vykonať proces, ktorý overí či príslušná databáza a kolekcia údajov existuje a pokiaľ tomu tak nie je tak ich vytvorí a vloží do databázy počiatočné údaje. K tomu využijeme nástroj [MongoDb-Shell](https://www.mongodb.com/docs/mongodb-shell/), ktorý je súčasťou kontajnera [mongo](https://hub.docker.com/_/mongo). Do súboru `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install/deployment.yaml` pridajte nasledujúci kód:

   >info:> Alternatívnym spôsobom by bolo vytvoriť manifest pre [Kubernetes job](https://kubernetes.io/docs/concepts/workloads/controllers/job/). V tomto prípade by sme ale museli riešiť synchronizáciu medzi jobom a kontajnerom s našou službou a kontajnerov obsahujúcim databázu MongoDB, tak aby sme zabezpečili, že job sa spustí avždy keď vznikne nová inštancia databázy a skôr ako bude náš kontajner naštartovaný. V niektorých prípadoch je možné tieto predpoklady pokladať za splnené.

   ```yaml
   ...
   spec:
     ...
     template:
         ...
         spec:
           volumes:    @_add_@
            - name: init-scripts     @_add_@
              configMap:    @_add_@
                name: <pfx>-ambulance-webapi-mongodb-init @_add_@
           initContainers:        @_add_@
           - name: init-mongodb        @_add_@
             image: mongo:latest        @_add_@
             imagePullPolicy: Always        @_add_@
             command: ['mongosh', '-f', '/scripts/init-db.js']        @_add_@
             volumeMounts:        @_add_@
             - name: init-scripts        @_add_@
               mountPath: /scripts        @_add_@
             env:        @_add_@
                - name: AMBULANCE_API_PORT    @_add_@@_add_@
                  value: "8080"   @_add_@
                - name: AMBULANCE_API_MONGODB_HOST    @_add_@
                  value: mongo    @_add_@
                - name: AMBULANCE_API_MONGODB_PORT    @_add_@
                  value: "27017"    @_add_@
                - name: AMBULANCE_API_MONGODB_USERNAME    @_add_@
                  value: ""   @_add_@
                - name: AMBULANCE_API_MONGODB_PASSWORD    @_add_@
                  value: ""   @_add_@
                - name: AMBULANCE_API_MONGODB_DATABASE    @_add_@
                  value: <pfx>-ambulances   @_add_@
                - name: AMBULANCE_API_MONGODB_COLLECTION    @_add_@
                  value: ambulances   @_add_@
                - name: RETRY_CONNECTION_SECONDS    @_add_@
                  value: "5"    @_add_@
             resources:        @_add_@
               requests:        @_add_@
                 memory: "16Mi"        @_add_@
                 cpu: "0.01"        @_add_@
               limits:        @_add_@
                 memory: "64Mi"        @_add_@
                 cpu: "0.1"        @_add_@
           containers:
            ...
   ```

   Inicializačný proces je určený príkazom `command: ['mongosh', '-f', '/scripts/init-db.js']` a referuje na inicializačný skript v súbore `/scripts/init-db.js`. Tento súbor musí byť dostupný v rámci kontajnera, preto je potrebné ho pridať ako zdieľaný zdroj pomocou `volumeMounts`, ktorý mapuje na adresár `/scripts` obsah zdroja `<pfx>-ambulance-webapi-mongodb-init`.

   Samotný inicializačný skript zatiaľ uložíme do súboru ``${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install/params/init-db.js` a obsahuje nasledujúci kód:

   ```js
   const mongoHost = process.env.AMBULANCE_API_MONGODB_HOST
   const mongoPort = process.env.AMBULANCE_API_MONGODB_PORT
   
   const mongoUser = process.env.AMBULANCE_API_MONGODB_USERNAME
   const mongoPassword = process.env.AMBULANCE_API_MONGODB_PASSWORD
   
   const database = process.env.AMBULANCE_API_MONGODB_DATABASE
   const collection = process.env.AMBULANCE_API_MONGODB_COLLECTION
   
   const retrySeconds = parseInt(process.env.RETRY_CONNECTION_SECONDS || "5") || 5;
   
   // try to connect to mongoDB until it is not available
   let connection;
   while(true) {
       try {
           connection = Mongo(`mongodb://${mongoUser}:${mongoPassword}@${mongoHost}:${mongoPort}`);
           break;
       } catch (exception) {
           print(`Cannot connect to mongoDB: ${exception}`);
           print(`Will retry after ${retrySeconds} seconds`)
           sleep(retrySeconds * 1000);
       }
   }
   
   // if database and collection exists, exit with success - already initialized
   const databases = connection.getDBNames()
   if (databases.includes(database)) {    
       const dbInstance = connection.getDB(database)
       collections = dbInstance.getCollectionNames()
       if (collections.includes(collection)) {
           process.exit(0);
       }
   }
   
   // initialize
   // create database and collection
   const db = connection.getDB(database)
   db.createCollection(collection)
   
   // create indexes
   db[collection].createIndex({ "ambulance": "id" })
   
   //insert sample data
   db[collection].insertMany([
       {   
           id: "bobulova",
           name: "Dr.Bobulová",
               roomNumber: "123",
               predefinedConditions: (
                   { value: "Nádcha", code: "rhinitis" },
                   { value: "Kontrola", code: "checkup" }
               )
           
       }
   ]);
   
   // exit with success
   process.exit(0);
   ```

   Tento kód načíta konfiguráciu prostredia a pokúsi sa pripojiť k databáze. Po úspešnom pripojení sa, overí či predpísana databáza a kolekcia existujú, prípadne ich vytvorí a naplní počiatočnými údajmi.

4. Ďalej vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install/service.yaml` s nasledujúcim obsahom, ktorý určuje definíciu zdroja [_Service_](https://kubernetes.io/docs/concepts/services-networking/service/), ktorý bude použitý na zabezpečenie prístupu k našej službe z iných zdrojov v rámci klastra Kubernetes:

   ```yaml
   kind: Service
   apiVersion: v1
   metadata:
     name: <pfx>-ambulance-webapi   
   spec:  
     selector:
       pod: <pfx>-ambulance-webapi-label
     ports:
     - name: http
       protocol: TCP
       port: 80  
       targetPort: webapi-port
   ```

5. Teraz vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install/kustomization.yaml`, ktorý vyššie uvedené konfigurácie. Navyše v ňom budeme definovať zdroj [_ConfigMap_](https://kubernetes.io/docs/concepts/configuration/configmap/) pre inicializačný skript databázy a zdroj [_ConfigMap_](https://kubernetes.io/docs/concepts/configuration/configmap/) pre konfiguráciu našej služby:

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - deployment.yaml
   - service.yaml
   
   configMapGenerator:
     - name: <pfx>-ambulance-webapi-mongodb-init 
       files:
         - params/init-db.js
     - name: <pfx>-ambulance-webapi-config
       literals:
         - database=ambulance
         - collection=ambulance
   ```

6. Pretože vytvárame znovupoužiteľnú konfiguráciu, vytvoríme aj konfiguráciu pre nasadenie mongodb do klastra. V tomto prípade, ale nevieme či je databáza [MongoDB] už dostupná na predinštalovanom systéme, prípadne či nebude prístupna inou formou. Konfiguráciu preto definujeme ako [komponent systému Kustomize](https://kubectl.docs.kubernetes.io/guides/config_management/components/). Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/components/mongodb/deployment.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: &PODNAME mongodb   @_important_@
   spec:
     replicas: 1
     selector:
         matchLabels:
           pod: *PODNAME  @_important_@
     template:
         metadata:
           labels:
             pod: *PODNAME  @_important_@
         spec:
           volumes: 
           - name: db-data
             persistentVolumeClaim: @_important_@
               claimName: mongodb-pvc @_important_@
           containers:
           - name: *PODNAME
             image: mongo:latest
             imagePullPolicy: Always
             ports:
             - name: mongodb-port
               containerPort: 27017
             volumeMounts: @_important_@
             - name: db-data
               mountPath: /data/db
             env:
              - name: MONGO_INITDB_ROOT_USERNAME
                valueFrom:
                   secretKeyRef: 
                    name: mongodb-auth
                    key: username
              - name: MONGO_INITDB_ROOT_PASSWORD
                valueFrom:
                   secretKeyRef: 
                    name: mongodb-auth
                    key: password
             resources:
               requests:
                 memory: "1GB"
                 cpu: "0.1"
               limits:
                 memory: "4GB"
                 cpu: "0.5"
   ```

   Všimnite si ako deklarujeme názov podu, ktorý je použitý v rámci konfigurácie ako premenná YAML. Tiež si všimnite, že sme použili zdroj [_PersistentVolumeClaim_](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) pre zabezpečenie perzistentného úložiska pre databázu. Tiež si všimnite, že pre získanie autorizačných hodnôt pre prístup k databáze sme použili hodnoty načítavané zo zdrojov typu [_Secret_](https://kubernetes.io/docs/concepts/configuration/secret/) a niektoré premenné prostredia sú získane z rôznych zdrojov typu [_ConfigMap_](https://kubernetes.io/docs/concepts/configuration/configmap/), čo umožňuje ich centrálne nastavenie a použitie na rôznych miestach v rámci našej konfigurácie.

   Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/components/mongodb/pvc.yaml` s nasledujúcim obsahom:

   ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: mongo-pvc
    spec:
      # storageClassName: default 
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
   ```

   Zdroj [_PersistentVolumeClaim_](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) je použitý na definovanie požiadaviek na perzistentné úložisko. Samotný zdroj úložiska musí byť poskytnutý buď manuálnou alokáciou priestoru pomocou zdroja [_PersistentVolume_](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) alebo pomocou zdroja [_StorageClass_](https://kubernetes.io/docs/concepts/storage/storage-classes/). Zdroj úložiska sa určuje vlastnosťou `storageClassName`. V našom prípade sme použili preddefinovaný zdroj `default`, ktorý je dostupný na väčšine inštalácií Kubernetes. Ak by sme chceli použiť iný zdroj, museli by sme ho najprv vytvoriť.

   Teraz vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/components/mongodb/service.yaml` s nasledujúcim obsahom:

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
       name: &PODNAME mongodb
    spec:  
       selector:
         pod: *PODNAME
       ports:
       - name: mongo
         protocol: TCP
         port: 27017
       targetPort: mongodb-port
    ```

    a nakoniec vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/components/mongodb/kustomization.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1alpha1
    kind: Component

    resources:
    - deployment.yaml
    - service.yaml
    - pvc.yaml

    configMapGenerator:
    - name: mongodb-connection
      literals:
        - host=mongodb
        - port=27017

    secretGenerator:
      - name: mongodb-auth
        literals:
        - username=admin
        - password=admin

    - path: patches/webapi.deployment.patch.yaml
      target:
        group: apps
        version: v1
        kind: Deployment
        name: ${templateOption:pfx}-ambulance-webapi
    ```

   Okrem referencie na zdrojové manifesty konfigurácie obsahuje tento súbor aj deklaráciu [konfiguračnej mapy - _ConfigMap_](https://kubernetes.io/docs/concepts/configuration/configmap/) a zdroja [_Secret_](https://kubernetes.io/docs/concepts/configuration/secret/). Ďalej obsahuje referenciu na úpravu manifestu pre nasadenie nášho webapi - `patches/webapi.deployment.patch.yaml`. Táto úprava je potrebná preto, aby sme mohli použiť hodnoty z konfiguračnej mapy a zdroja [_Secret_](https://kubernetes.io/docs/concepts/configuration/secret/) v rámci konfigurácie našej služby. V tomto prípade realizujem úpravu pomocou manifestu typu [JSONPatch]. Dôvodom je najmä fakt, že potrebujeme zmazať pôvodné vlastnosti `value` v definíciach premenných prostredia.

   >info:> Alternatívou by bolo vytvoriť dve záplaty typu [_strategic merge_](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patchesstrategicmerge/), pričom prvá by zmazala pôvodné záznamy v sekcii `env` pomocou `$patch: delete` directívy, a druhá záplata by ich pridala s použitím záznamov s vlatnosťou `valueFrom`. Z dôvodu ukážky použitia [JSONPatch]  sme tento spôsob nezvolili, hoci z hľadiska dlhodobého vývoja by bol asi primeranejší.

   Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/components/mongodb/patches/webapi.deployment.patch.yaml` s nasledujúcim obsahom:

   ```yaml
    - op: replace
      path: /spec/template/spec/initContainers/0/env
      value: 
        - name: AMBULANCE_API_MONGODB_HOST
          valueFrom:
            configMapKeyRef:
              name: mongodb-connection
              key: host
        - name: AMBULANCE_API_MONGODB_PORT
          valueFrom:
            configMapKeyRef:
              name: mongodb-connection
              key: port
        - name: AMBULANCE_API_MONGODB_USERNAME
          valueFrom:
            secretKeyRef: 
              name: mongodb-auth
              key: username
        - name: AMBULANCE_API_MONGODB_PASSWORD
          valueFrom:
            secretKeyRef: 
              name: mongodb-auth
              key: password
        - name: AMBULANCE_API_MONGODB_DATABASE
          valueFrom:
            configMapKeyRef:
              name: milung-ambulance-webapi-config
              key: database
        - name: AMBULANCE_API_MONGODB_COLLECTION
          valueFrom:
            configMapKeyRef:
              name: milung-ambulance-webapi-config 
              key: collection
    - op: replace
      path: /spec/template/spec/containers/0/env
      value:
        - name: AMBULANCE_API_ENVIRONMENT
          value: production
        - name: AMBULANCE_API_PORT
          value: "8080"
        - name: AMBULANCE_API_MONGODB_HOST
          valueFrom:
            configMapKeyRef:
              name: mongodb-connection
              key: host
        - name: AMBULANCE_API_MONGODB_PORT
          valueFrom:
            configMapKeyRef:
              name: mongodb-connection
              key: port
        - name: AMBULANCE_API_MONGODB_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-auth
              key: username
        - name: AMBULANCE_API_MONGODB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-auth
              key: password
        - name: AMBULANCE_API_MONGODB_DATABASE
          valueFrom:
            configMapKeyRef:
              name: milung-ambulance-webapi-config 
              key: database
        - name: AMBULANCE_API_MONGODB_COLLECTION
          valueFrom:
            configMapKeyRef:
              name: milung-ambulance-webapi-config 
              key: collection
        - name: AMBULANCE_API_MONGODB_TIMEOUT_SECONDS
          value: "5"

   ```

   V podstate sa jedná o zápis príkazov na prepísanie hodnôt `env` v inicialzačnom kontajnery a v prvom z kontajnerovo v našom pôvodnom zdroji `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install/deployment.yaml` s upravenými hodnotami príslušných premenných prostredia, ktoré sa načítavajú z konfiguračnej mapy a zdroja [_Secret_](https://kubernetes.io/docs/concepts/configuration/secret/). Keďže sa jedna o konfiguráciu typu [_Component_](https://kubectl.docs.kubernetes.io/guides/config_management/components/), tak pôvodný zdroj nemusí byť súčasťou konfigurácie tohto komponentu, tzn. nemusí byť deklarovaný v niektorom z pôvodných zdrojov načítaných prostredníctvom záznamov pod sekciou `resources`, ale môže byť definovaný ako súčasť inej konfigurácie, ktorá použije náš komponent. 

   Nakoniec vytvoríme novú konfiguráciu, ktorá tento komponent použije. Vytvorte súbor `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/with-mongo/kustomization.yaml` s týmto obsahom:

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - ../install
   
   components:
   - ../components/mongodb
   ```

   Táto konfigurácia je odvodená od tej v adresári `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install` na ktorú aplikujeme komponent `${WAC_ROOT}/ambulance-webapi/deployments/kustomize/components/mongodb.

7. Overte správnosť konfigurácie vykonaním príkazov:

   ```ps
   kubectl kustomize ${WAC_ROOT}/ambulance-webapi/deployments/kustomize/install
   kubectl kustomize ${WAC_ROOT}/ambulance-webapi/deployments/kustomize/with-mongo
   ```

   a následne archivujte svoj kód:

   ```ps
   git add .
   git commit -m "Added kustomize configuration for webapi"
   git push
   ```

   V prehliadači prejdite do svojho repozitára na stránke [GitHub]. V repozitári prejdite do záložky _Code_, stlačte na odkaz _1 tags_, a následne na tlačidlo _Create new release_. Zadajte do poľa _Choose tag_ hodnotu `v1.0.1`, do poľa _Release Title_ zadajte text `v1.0.1` a do poľa _Describe this release_ zadajte text `Manifests for webapi deployment`. Stlačte na tlačidlo _Publish release_.

   >info:> Pokiaľ ste už vytvorili tag s väčšou sémantickou verziou, tak použite tag ktorý pokračuje v číslovaní.

>warning:> V reálnom prostredí musí byť správnosť manifestov overená aj ich nasadením do testovacieho klastra v rámci automatizovaných integračných testov.
