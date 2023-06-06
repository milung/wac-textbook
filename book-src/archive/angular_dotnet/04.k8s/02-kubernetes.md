## Nasadenie služieb do kubernetes klastra

V predchádzajúcom kroku sme vytvorili všetky potrebné kontajneri, následne
pre ne vytvoríme manifesty pre nasadenie do kubernetes clustra. Pre každú
mikro službu vytvoríme _Deployment_ a _Service_ manifest, ktorý budeme postupne
aplikovať v našom klastri.


1. Prejdite do priečinka `reverse-proxy` a vytvorte v ňom súbor
   `hospital-gateway.k8s.yaml` s nasledujúcim obsahom

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: hospital-gateway-svc
      labels:
        microservice: hospital-gateway
        subdomain: platform
        tier: backend
    spec:
      type: NodePort
      selector:
        instance: hospital-gateway-pod
      ports:
      - protocol: TCP
        port: 80
        targetPort: 80
        nodePort: 30088
        name: http
    ​---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hospital-gateway-dpl
      labels:
        microservice: hospital-gateway
        tier: backend
        subdomain: platform
    spec:
      replicas: 2
      selector:
        matchLabels:
          instance: hospital-gateway-pod
      template:
        metadata:
          labels:
            instance: hospital-gateway-pod
        spec:
          containers:
          - name: hospital-gateway-container
            image: hospital-gateway:latest
            imagePullPolicy: Never
            env:
            - name: CLUSTER_SUBDOMAIN
              value: hospital.svc.cluster.local
            ports:
            - containerPort: 80
    ```

    Tento manifest popisuje deklaráciu služby, ktorá je zverejnená na porte
    uzla - `type: NodePort; nodePort: 30080`. Za deklaráciou služby nasleduje
    deklarácia _Deplyment_-u. Oddelenie manifestov je pomocou riadku s troma
    pomĺčkami. Rovnako by sme mohli použiť dva rôzne súbory. _Deployment_ určuje,
    že chceme vytvoriť dve inštancie našej služby, a pri tom použiť kontajner
    s označením `hospital-gateway:latest`. Obraz kontajnera nikdy nezískavame
    z repository ale použijeme len lokálnu kópiu. V praxi je ale reálnejšia
    situácia, že náš obraz kontajnera získavame priamo z repozitára. Do premennej
    prostredia zároveň zadávame subdoménu `hospital.svc.cluster.local`, ktorá
    zodpovedá skutočnosti, že naše služby nasadzujeme do priestoru mien nazvaného
    `hospital`

2. Vytvorte v klastri dedikovaný _namespace_. Vytvorenie _Namespace_ nie je povinné,
   pri prototypovej práci to pomáha oddeliť jednotlivé aplikačné systémy. Neodporúča
   sa ich využívať na iné účely než oddelenie rôznych systémov alebo nasadzovanie
   rôznych prostredí toho istého systému.

    ```ps
    kubectl create namespace hospital
    ```

    Následne v príkazovom riadku prejdite do adresára `reverse-proxy` a do tohto
    priestoru nasaďte mikro službu _hospital-gateway_

    ```ps
    kubectl --namespace hospital apply -f hospital-gateway.k8s.yaml
    ```

    Použitím príkazu `kubectl apply` zároveň zabezpečíme, že sa v systéme uloží
    kópia nášho manifestu. Pri opätovnom volaní tohto príkazu, kubernetes rozpozná
    aké zmeny sme v súbore vykonali a bude aplikovať len príslušné zmeny, bez nutnosti
    odstraňovania alebo reštartu služieb v prípadoch, kde to nie je potrebné. Overte
    či sú nové inštancie podov dostupné pomocou príkazu

    ```ps
    :> kubectl -n hospital get pods

    NAME                                    READY   STATUS    RESTARTS   AGE
    hospital-gateway-dpl-76556599d9-j5bl4   1/1     Running   0          50s
    hospital-gateway-dpl-76556599d9-rf5rh   1/1     Running   0          50s
    ```

    V prehliadači otvorte stránku `http://localhost:30088`. Pri správnom fungovaní
    by ste mali byť presmerovaní na stránku `http://localhost:30088/ambulancie/cakaren?ambulanceId=practitioner-bobulova`,
    na ktorej dostanete chybovú správu `502 Bad Gateway`, čo je spôsobené faktom,
    že sme zatiaľ nenasadili ostatné služby.

    V konzole môžete ešte vyskúšať nasledujúci príkaz pre sledovanie výpisov
    jednotlivých podov (pod id zvoľte podľa aktuálneho výpisu pri predchádzajúcom
    príkaze):

    ```ps
    kubectl -n hospital logs -f hospital-gateway-dpl-76556599d9-fjfp6
    ```

3. Prejdite do adresára ambulance-spa, vytvorte v ňom súbor `waiting-list-spa.k8s.yaml`
   s nasledujúcim obsahom:

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: waiting-list-spa
      labels:
        microservice: waiting-list
        subdomain: ambulance
        tier: frontend
    spec:
      type: ClusterIP
      selector:
        instance: waiting-list-spa
      ports:
      - protocol: TCP
        port: 80
        targetPort: 80
        name: http
    ​​---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: waiting-list-spa
      labels:
        microservice: waiting-list-spa
        tier: frontend
        subdomain: ambulance
    spec:
      replicas: 1
      selector:
        matchLabels:
          instance: waiting-list-spa
      template:
        metadata:
          labels:
            instance: waiting-list-spa
        spec:
          containers:
          - name: waiting-list-spa
            image: ambulance-spa:latest
            imagePullPolicy: Never
            env:
            - name: BASE_HREF
              value: /ambulancie/cakaren/
            - name: API_BASE_URI
              value: /api
            ports:
            - containerPort: 80
    ```

    Oproti predchádzajúcej službe (`hospital-gateway`), je tento manifest
    rozdielny len v skutočnosti, že používa `type: CLusterIP`, čo znamená,
    že k službe možno priamo pristúpiť len v rámci internej virtuálnej sieti.
    Kľúčové je aby meno služby `Service` a meno uvedené pri presmerovaní
    v súbore `nginx.conf` služby `hospital-gateway` boli zhodné.

    V okne príkazového riadku prejdite do priečinku `ambulance-spa` a vykonajte
    príkaz:

    ```ps
    kubectl -n hospital apply -f .\waiting-list-spa.k8s.yaml
    ```

    Prejdite do okna prehliadača, otvorte _Nástroje pre vývojarov_, panel _Sieť/Network_,
    a prejdite na stránku <http://localhost:30088/ambulancie/cakaren/patients-list.>
    V prehliadači sa Vám zobrazí Vaša už známa aplikácia. Zatiaľ ešte nie je plne
    funkčná, pretože pri komunikácii s Web API serverom dostávame chybové
    hlásenie `502 Bad Gateway`.

4. Prejdite do priečinku `ambulance-api` a vytvorte v ňom súbor `waiting-list-api.k8s.yaml`
   s nasledujúcim obsahom.

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: waiting-list-api
      labels:
        microservice: waiting-list-api
        subdomain: ambulance
        tier: webapi
    spec:
      type: ClusterIP
      selector:
        instance: waiting-list-api
      ports:
      - protocol: TCP
        port: 80
        targetPort: 8080
        name: http
    ​​---
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: waiting-list-claim
    spec:
      storageClassName: hospital
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
    ​​---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: waiting-list-api
      labels: 
        microservice: waiting-list-api
        tier: webapi
        subdomain: ambulance
    spec:
      replicas: 1
      selector: 
        matchLabels: 
          instance: waiting-list-api
      template:
        metadata:
          labels:        
            instance: waiting-list-api
        spec:
          volumes:
          - name: waiting-list-storage
            persistentVolumeClaim:
              claimName: waiting-list-claim
          containers:
          - name: waiting-list-api
            image: ambulance-api:latest
            imagePullPolicy: Never
            ports:
            - containerPort: 8080
            volumeMounts:
              - mountPath: /srv/hospital-data
                name: waiting-list-storage
    ```

    Špecifickým pri tejto službe je práca s pripojenými zväzkami. V manifeste sme vytvorili nový objekt typu _PersistentVolumeClaim_ s požiadavkou na 2GB storage zo storage triedy - _storageClass_ -  označenej ako `hospital`. Tento _PersistentVolumeClaim_ sa pripojí k najvhodnejšiemu objektu _PersistentVolume_ s rovnakým označením _storageClass_. Následne pri deploymente definujeme nový zväzok, ktorý použije tento _PersistentVolumeClaim_ a pri špecifikácii kontajnera tento zväzok pripojíme k príslušnej ceste. 

    V adresári `ambulance-api` vytvorte nový súbor `hostPath-persistentVolume.k8s.yaml` s obsahom  

    ```yaml
    kind: PersistentVolume
    apiVersion: v1
    metadata:
      name: hospital-data-block-a
      labels:
        type: local
    spec:
      storageClassName: hospital
      persistentVolumeReclaimPolicy: Delete
      capacity:
        storage: 2Gi
      accessModes:
        - ReadWriteOnce
      hostPath:
        path: "/srv/hospital-data"
    ```

    Tento manifest vytvorí nový objekt _PersistentVolume_, triedy `hospital`, a alokuje capacitu 2GB na hosčovskom zariadení. _PersistentVolume_ typu _hostPath_ nie je síce vhodným riešením v produkčnom systéme, je však najjednoduchším spôsobom vytvorenia perzistentného úložiska pre lokálny vývoj. 

    V okne príkazového riadku prejdite do priečinka `ambulance-api` a vykonajte nasledujúce príkazy:

    ```ps
    kubectl -n hospital apply -f .\hostPath-persistentVolume.k8s.yaml
    kubectl -n hospital apply -f .\waiting-list-api.k8s.yaml
    ```

    Prejdite do aplikácie _Postman_ a vytvorte novú ambulanciu podľa pokynov v predchádzajúcej časti. Následne v prehliadači prejdite na stránku http://localhost:30088/ambulancie/cakaren/patients-list a overte funkcionalitu. 

    Údaje o pacientoch sú uchované aj pri reštarte aplikácie alebo pri zmazaní a obnovení podov. Pokiaľ chcete údaje zmazať z perzistentného úložiska, vymažte objekt _PersistentVolumeClaim_ a znovu ho vytvorte. V prípade, že chcete údaje z tohto úložiska skopírovať, môžete využiť príkaz `kubectl cp`.

4. Doteraz sme používali iba lokálne dostupne obrazy kontajnerov. Pokiaľ ich chcete použiť v ľubovoľnom prostredí, najprv ich označte svojim repozitárom: 

    ```ps
    docker tag ambulance-spa:latest <docker-account>/ambulance-spa:latest
    docker tag ambulance-api:latest <docker-account>/ambulance-api:latest
    docker tag hospital-gateway:latest <docker-account>/hospital-gateway:latest
    ```

    Pokiaľ nieste prihlásený do svojho repozitára tak sa prihláste, napríklad pomocou príkazu `docker login` a zverejníte vytvorené obrazy pomocou príkazov

    ```ps
    docker push <docker-account>/ambulance-spa:latest
    docker push <docker-account>/ambulance-api:latest
    docker push <docker-account>/hospital-gateway:latest
    ```
    
    V manifestoch vytvorených v predchadzajúcich krokoch upravte názvy kontajnerov, a zmeňte parameter `imagePullPolicy` z hodnoty `Never` na `Always` napríklad v prípade WEB API:

    ```yaml
    ...
     containers:
      - name: waiting-list-api
        image: <docker-account>/ambulance-api:latest
        imagePullPolicy: Always       
        ports:
    ...
    ```

    Takto upravené manifesty môžte zverejniť v ľubovoľnom klastri, napríklad ich môžete nasadiť vrámci služby [Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/). 
