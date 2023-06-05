# Nasadenie do klastra kubernetes (Kontinuálne nasadenie cez Flux)

Rovnako ako v prípade web aplikácie si ukážeme ako nasadiť náš web servis do klastra Kubernetes. Keďže už máme rozchodené kontinuálne nasadenie s využitím aplikácie [Flux], bude nám stačiť pripraviť niekoľko yaml súborov a dať ich do správnych priečinkov. Nasadenie do klastra následne prebehne automaticky.

1. Vo VS Code otvorte priečinok s názvom `.../webcloud-gitops`.

2. V priečinku `.../webcloud-gitops/apps` vytvorte nový priečinok `<pfx>-ambulance-webapi`.

3. V priečinku `.../webcloud-gitops/apps/<pfx>-ambulance-webapi` vytvorte súbor `deployment.yaml` s nasledujúcim obsahom:

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
             - name: <pfx>-ambulance-webapi-container
               image: <your-account>/ambulance-webapi:latest
               imagePullPolicy: Always
               ports:
               - name: webapi-port
                 containerPort: 8080
               resources:
                 requests:
                   memory: "32Mi"
                   cpu: "0.1"
                 limits:
                   memory: "128Mi"
                   cpu: "0.3"
     ```

    Súbor `deployment.yaml` je deklaráciou nasadenia našej služby - tzv. _workload_ - do klastra. Všimnite si, že požaduje nasadenie jednej repliky - čo znamená, že v klastri bude vytvorený jeden _pod_.

4. Teraz vytvorte súbor `.../webcloud-gitops/apps/<pfx>-ambulance-webapi/service.yaml` s obsahom:

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: <pfx>-ambulance-webapi
    spec:
      type: ClusterIP
      selector:
        pod: <pfx>-ambulance-webapi-label
      ports:
      - name: webapi-s-port
        protocol: TCP
        port: 80
        targetPort: 8080
    ```

    Tento zdroj v systéme kubernetes deklaruje sieťovú službu, ktorá zároveň implementuje jednoduchý _load balancer_ pre distribúciu HTTP požiadaviek medzi dve repliky našej webovej služby.  Meno služby `<pfx>-ambulance-webapi` zároveň reprezentuje DNS záznam v rámci virtuálnej siete, a teda naša webová služba bude interne v rámci systému kubernetes dostupná na adrese `http://<pfx>-ambulance-webapi` v rámci toho istého _namespace_ alebo na adrese `http://<pfx>-ambulance-webapi.<namespace>` z ľubovoľného _namespace_.

5. Nakoniec vytvoríme súbor `.../webcloud-gitops/apps/<pfx>-ambulance-webapi/kustomization.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    - deployment.yaml
    - service.yaml
    commonLabels:
      app: <pfx>-ambulance-webapi
    ```

6. V predchádzajúcich krokoch sme vytvorili deklarácie pre našu aplikáciu `ambulance-webapi`. Teraz prejdeme k
deklarácii konfigurácie do špecifických prostredí - klastrov.

   V súbore `.../webcloud-gitops/clusters/localhost/kustomization.yaml` doplňte do časti `resources` nasledujúci riadok:

    ```yaml
    ...
    resources:
    ...
    - ../../apps/<pfx>-ambulance-webapi                  #  kustomization pre ambulance-webapi
    ...
    ```

7. Vzhľadom k tomu, že systém Flux už máme lokálne nasadený, stačí nám hore uvedené zmeny archivovať do vzdialeného repozitára. Od tohto momentu sa Flux postará o nasadenie do lokálneho Kubernetes klastra.

   Archivujte zmeny.

    ```powershell
    git add .
    git commit -m 'pridane yaml pre ambulance-webapi'
    git pull
    git push
    ```

   Po pár minútach overte, že pody pre web servis sú vytvorené a sú v stave `Running` príkazom:
  
    ```ps
    kubectl get pods -n wac-hospital
    ```

   Výpis indikuje, že v našom klastri máme teraz bežiace dva pody `<pfx>-ambulance-webapi` - zjednodušene dva virtuálne počítače pripojené k virtuálnej sieti kubernetes klastra. Momentálne sú tieto pody dostupné len na virtuálnej sieti systému kubernetes. Pokiaľ k nim chceme pristúpiť, môžeme využiť funkciu presmerovania portov z lokálneho systému na cieľový _service_ (prípadne _pod_) aktívneho klastra.

    ```powershell
    kubectl port-forward service/<pfx>-ambulance-webapi -n wac-hospital 8111:80
    ```

   a v prehliadači otvorte stránku [http://localhost:8111/api], na ktorej uvidíte správu "Hello World!".

8. Ešte nastavíme sledovanie zmien verzie docker obrazu a ich aplikovanie do klastra obdobne ako pre webcomponent. Potrebujeme tri komponenty:

   * `ImageRepository` Flux komponent  
      Nastavuje, ktorý docker obraz má Flux sledovať - _ambulance-webapi_. Vytvorte súbor `.../webcloud-gitops/flux-system/ambulance-webapi-image-repo.yaml` s obsahom:

        ```yaml
        apiVersion: image.toolkit.fluxcd.io/v1beta1
        kind: ImageRepository
        metadata:
          name: ambulance-webapi
          namespace: flux-system
        spec:
          image: <vase-docker-id>/ambulance-webapi
          interval: 1m0s
        ```

        >warning:> Zameňte vase-docker-id !

      A aplikujte komponent do klustra (Fluxu):

        ```ps
        kubectl apply -f flux-system/ambulance-webapi-image-repo.yaml
        ```

   * `ImagePolicy` Flux komponent  
      Nastavuje kritérium, podľa ktorého sa vyberie verzia docker obrazu. Vytvorte súbor `.../webcloud-gitops/flux-system/ambulance-webapi-image-policy.yaml` s obsahom:

        ```yaml
        apiVersion: image.toolkit.fluxcd.io/v1beta1
        kind: ImagePolicy
        metadata:
          name: ambulance-webapi
          namespace: flux-system
        spec:
          imageRepositoryRef:
            name: ambulance-webapi
          policy:
            semver:
              range: '^1.0.0-0'  # selects latest version matching 1.0.0-<number>
        ```

        A aplikujte komponent do klastra (Fluxu):

         ```ps
         kubectl apply -f ./flux-system/ambulance-webapi-image-policy. yaml
         ```

        Skontrolujeme, aká verzia docker obrazu bola vybraná:

         ```ps
         flux get image policy ambulance-webapi
         ```

        Výpis by mal obsahovať riadok:

         ```powershell
         imagepolicy/ambulance-webapi       True    Latest image tag  for '<docker_id>/ambulance-webapi' resolved to: 1.0. 0-<posledne cislo buildu>
         ```

   * Upravíme všetky súbory, kde chceme aby Flux aktualizoval verziu docker obrazu. Robí sa to pridaním špeciálneho markeru `_# {"$imagepolicy": "POLICY_NAMESPACE:POLICY_NAME"}_` na riadok, ktorý sa má upravovať.

      My upravíme iba súbor `.../webcloud-gitops/clusters/localhost/kustomization.yaml` rovnako ako v prípade webkomponentu. Do časti `images:` pridajte:

        ```yaml
        ...
        - name: <docker_id>/ambulance-webapi
          newName: <docker_id>/ambulance-webapi # {"$imagepolicy": "flux-system:ambulance-webapi:name"}
          newTag: 1.0.0-1 # {"$imagepolicy": "flux-system:ambulance-webapi:tag"}
        ```

   * `ImageUpdateAutomation` Flux komponent nie je treba vytvárať. Ten, ktorý sme vytvorili pre webkomponent sleduje všetky `imagepolicy` v rovnakom namespace. A git repozitár a priečinok kde sa nachádza súbor, v ktorom treba robiť zmeny, je ten istý.

   Pridajte referenciu na novovytvorené súbory do kustomizácie flux systému `.../webcloud-gitops/flux-system/kustomization.yaml` pre potreby obnovi klastra:
   
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
    ```

   Urobte `git pull` a potom archivujte zmeny a synchronizujte so vzdialeným repozitárom.

   Ak máte na DockerHub novšiu verziu obrazu ako 1.0.0-1, ktorú sme špecifikovali v `.../webcloud-gitops/clusters/localhost/kustomization.yaml`, tak by sa mala po chvíli automaticky zvýšiť na poslednú. Skontroluje komity v repozitári, prípadne verziu použitého obrazu cez Lens tool.
