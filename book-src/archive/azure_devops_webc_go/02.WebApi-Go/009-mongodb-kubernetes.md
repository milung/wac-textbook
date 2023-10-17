## Nasadenie MongoDB do Kubernetes klastra

Aj pri nasadení do Kubernetes chceme, aby bol prístup do databázy chránený prístupom cez meno a heslo. Na bezpečné ukladanie prihlasovacích údajov slúži v Kubernetes typ `Secret`. Prihlasovacie údaje sa v ňom ukladajú enkódované do base64. Vyrobíme ho pomocou funkcie zabudovanej do _Kustomization_, ktorá sa volá `secretGenerator`.

### MongoDb

1. Otvorte priečinok `webcloud-gitops` vo VS Code a vytvorte súbor `.../webcloud-gitops/infrastructure/mongo/.secrets/kustomization.yaml` s obsahom:

    ```yaml
      apiVersion: kustomize.config.k8s.io/v1beta1
      kind: Kustomization
      namespace: wac-hospital

      secretGenerator:
        - name: mongodb-secret
          type: Opaque
          literals:
            - mongo-root-username=mongo-user
            - mongo-root-password=mongo-password
          options:
            disableNameSuffixHash: true
    ```

    Funkcia _secretGenerator_ vytvorí v klastri objekt typu _Secret_ s menom `mongodb-secret` s danými hodnotami pre používateľa a heslo.

    Aplikujte súbor do klastra:

    ```ps
    kubectl apply -k ./infrastructure/mongo/.secrets
    ```

    >info:> Funkcia _secretGenerator_ automaticky zakódovala meno aj heslo do formátu _base64_.

    Pridajte referenciu na novovytvorený súbor do kustomizácie flux systému `.../webcloud-gitops/flux-system/kustomization.yaml` pre potreby obnovi klastra (hoci nemá nič spoločné s flux systémom rozhodli sme sa pre zjednodušenie použiť rovnaký súbor):
   
    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - .secrets
    - gotk-components.yaml
    - ambulance-gitops-repo.yaml
    - ambulance-localhost-kustomization.yaml 
    - ambulance-ufe-image-policy.yaml
    - ambulance-ufe-image-repo.yaml
    - ambulance-ufe-imageupdateautomation.yaml
    - ambulance-webapi-image-policy.yaml
    - ambulance-webapi-image-repo.yaml
    - ../infrastructure/mongo/.secrets
    ```

2. Mongo potrebuje priestor na perzistentné ukladanie databázových údajov. V Kubernetes sa na tento účel používa objekt typu _persistent volume_. Viac k úložiskám v Kubernetes si môžte prečítať [tu](https://kubernetes.io/docs/concepts/storage/).

    Vytvoríme manifesty pre 2 objekty - _persistent volume_ (PV) a _persistent volume claim_ (PVC). PV nám definuje diskový priestor. PVC je požiadavka na vyhradenie konkrétnej časti diskového priestoru z PV, ktorá bude použitá v kontajneri.

    V priečinku `.../webcloud-gitops/infrastructure/mongo/` vytvorte súbor `mongo-persistent-volume.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: mongo-pv
    spec:
      storageClassName: manual
      capacity:
        storage: 2Gi
      accessModes:
        - ReadWriteOnce
      hostPath:
        path: "/mnt/data"
    ```

    Táto konfigurácia špecifikuje volume, ktorý sa bude nachádzať v priečinku `/mnt/data` na Node v klastri a ktorý bude mať veľkosť 2 Gibibyty a prístupový mód `ReadWriteOnce`, čo znamená, že môže byť namountovaný ako read-write iba na jednu Nodu.

    > Poznámka: Volume typu `hostPath` je vhodný na lokálne testovanie na klastri s jednou nódou. Na produkčnom klastri vytvorí administrátor volume iného, vhodnejšieho typu. Zoznam typov, tzv. `Storage Class` nájdete napr. [tu](https://kubernetes.io/docs/concepts/storage/storage-classes/)

    V priečinku `.../webcloud-gitops/infrastructure/mongo/` vytvorte súbor `mongo-persistent-volume-claim.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: mongo-pvc
    spec:
      storageClassName: manual # hodnota sa musí zhodovať so storageClassName v manifeste pre persistent volume
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
    ```

3. V priečinku `.../webcloud-gitops/infrastructure/mongo/` vytvorte súbor `mongodb-deployment.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mongodb
    spec:
      replicas: 1
      selector:
        matchLabels:
          instance: mongodb
      template:
        metadata:
          labels:
            instance: mongodb
        spec:
          volumes:
            - name: mongo-storage
              persistentVolumeClaim:
                claimName: mongo-pvc
          containers:
          - name: mongodb-container
            image: mongo:6.0.3
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 27017
            volumeMounts:
            - mountPath: "/data/db"
              name: mongo-storage
            # following 2 environment variables are defined by MongoDB in order to protect access
            env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-username
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-password
            resources:
              limits:
                memory: 2Gi
                cpu: "1"
              requests:
                memory: 1Gi
                cpu: "0.1"
    ```

    Premenné prostredia sú kontajneru nastavené v časti _env_, pričom hodnoty sú čítané zo _secret_ objektu vytvoreného v kroku 1. Diskový priestor je namapovaný v časti _volumeMounts_.

4. Teraz vytvorte servis pre mongodb pod, kde špecifikujeme sieťový prístup. Pre mongodb bude typu _ClusterIP_, čo znamená iba interný prístup v rámci klastra. Vytvorte súbor `.../webcloud-gitops/infrastructure/mongo/mongodb-service.yaml` s obsahom:

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: mongodb-service
    spec:
      type: ClusterIP
      selector:
        instance: mongodb
      ports:
      - protocol: TCP
        port: 27017
        targetPort: 27017
    ```

5. V tom istom adresári vytvorte súbor `mongodb-configmap.yaml`

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mongodb-configmap
    data:
      mongodb_uri: mongodb-service
    ```

    V tejto config mape sme si zadefinovali key-value pár, pre kľúč `mongodb_uri` máme hodnotu `mongodb-service`, čo je adresa servisu, na ktorej je dostupný mongodb kontainer. Odteraz, v každom kontajneri, kde potrebujeme pristupovať na mongodb, použijeme hodnotu z config mapy.

### Mongo Express

1. Pripravíme si manifesty pre [MongoExpress] - deployment a servis.

    V tom istom adresári vytvorte súbor `mongo-express-deployment.yaml`

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mongo-express
    spec:
      replicas: 1
      selector:
        matchLabels:
          instance: mongo-express
      template:
        metadata:
          labels:
            instance: mongo-express
        spec:
          volumes:
            - name: mongo-storage
              persistentVolumeClaim:
                claimName: mongo-pvc
          containers:
          - name: mongo-express
            image: mongo-express:1.0.0-alpha
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 8081
            volumeMounts:
            - mountPath: "/data/db"
              name: mongo-storage
            env:
            - name: ME_CONFIG_MONGODB_ADMINUSERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-username
            - name: ME_CONFIG_MONGODB_ADMINPASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-password
            - name: ME_CONFIG_MONGODB_SERVER # tu nastavíme adresu na mongodb servis
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: mongodb_uri
            resources:
              limits:
                memory: 1Gi
                cpu: "0.5"
              requests:
                memory: 256Mi
                cpu: "0.1"
    ```

    V tom istom adresári vytvorte súbor `mongo-express-service.yaml`

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: mongo-express-service
    spec:
      type: NodePort
      selector:
        instance: mongo-express
      ports:
      - protocol: TCP
        port: 8081
        targetPort: 8081
        nodePort: 30003
    ```

### Nasadenie cez Flux

1. Pridajte súbor `.../webcloud-gitops/infrastructure/mongo/kustomization.yaml`, kam pridáme všetky zdroje, ktoré sme vytvorili pred chvíľou:

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - mongodb-configmap.yaml
    - mongo-persistent-volume.yaml
    - mongo-persistent-volume-claim.yaml
    - mongodb-deployment.yaml
    - mongodb-service.yaml
    - mongo-express-deployment.yaml
    - mongo-express-service.yaml
    ```

2. Teraz nami vytvorenú mongo "infraštruktúru" nasadíme do lokálneho Kubernetes klastra. V súbore `.../webcloud-gitops/clusters/localhost/kustomization.yaml` doplňte do časti `resources` nasledujúci riadok:

    ```yaml
    ...
    resources:
    ...
    - ../../infrastructure/mongo
    ...
    ```

   Vzhľadom k tomu, že systém Flux už máme lokálne nasadený, stačí nám hore uvedené zmeny archivovať do vzdialeného repozitára. Od tohto momentu sa Flux postará o nasadenie do lokálneho Kubernetes klastra.

   Archivujte zmeny.

    ```powershell
    git add .
    git commit -m 'pridane yaml pre mongo'
    git pull
    git push
    ```

   Po pár minútach overte, že pody pre mongo a mongo express sú vytvorené a sú v stave `Running` príkazom:
  
    ```ps
    kubectl get pods -n wac-hospital
    ```

   V prehliadači otvorte stránku [http://localhost:30003]. Následne môžte otestovať funkčnosť databázy.
