## Smerovanie vstupných požiadaviek pomocou Ingress

Naše služby sú obsluhované z rôznych subdomén - rôznych adries hosťujúceho počítača. Vo väčších systémoch s desiatkami mikroslužieb by tento prístup bol neudržateľný. Jednak by vyžadoval správu desiatok domén a ich zabezpečenie, a tiež by znižoval flexibilitu pri evolúcii systémov. Jedným zo spôsobov ako tento problém adresovať, je zaintegrovať do systému takzvanú [_reverse proxy_](https://en.wikipedia.org/wiki/Reverse_proxy), niekedy tiež označovanú ako _Gateway_, alebo aj [_API Gateway_](https://www.redhat.com/en/topics/api/what-does-an-api-gateway-do). Označenia sa líšia a tiež rozsah funkcionality. Pre náš účel je dôležité, aby táto služba dokázala presmerovať požiadavky na jednotlivé mikro služby na základe určitých pravidiel, typicky na základe cesty URL uvedenej v požiadavke.

Typickými reprezentantmi takýchto reverse proxy sú aplikácie [_nginx_](https://www.nginx.com) a [_Envoy Proxy_](https://www.envoyproxy.io/), nie sú ale zďaleka jediné. Keďže smerovanie požiadaviek je jednou zo základných funkcionalít pri orchestrácii mikro služieb, uviedol tím kubernetes štandardizované api [_Ingress_](https://kubernetes.io/docs/concepts/services-networking/ingress/), ktorého implementáciu ale prenechal tretím stranám. Toto API ale nepokrývalo v základnej verzii všetky prípady reálnej praxe, jednotlivé implementácie preto API rozširujú proprietárnymi anotáciami. Na základe skúseností z implementácie Ingress API, sa začala pripravovať nová sada [Gateway API](https://gateway-api.sigs.k8s.io/), ktoré je ešte príliš čerstvé a implementácie zatiaľ nie sú kompletné a dostatočne stabilné (Február 2022).

V cvičení použijeme implementáciu [Ingress-Nginx](https://kubernetes.github.io/ingress-nginx/), ktorá patrí medzi najrozšírenejšie s najviac podporovanou sadou anotácií v rôznych predpripravených zostavách (_nezamieňať za implementáciu nginx-ingress_).

1. Vytvorte priečinok `.../webcloud-gitops/infrastructure/ingress-nginx` a v príkazovom riadku prejdite do tohto priečinka. Stiahnite manifest zdrojov pre nasadenie ingress-nginx do systému kubernetes pomocou príkazu

   ```ps
   curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml > ingress-nginx.yaml
   ```

   Tento manifest obsahuje všetky potrebné zdroje pre implementáciu Ingress API. V systéme môže byť viac implementácií tohto API, priradenie Ingress zdrojov k jednotlivým implementáciám je možné pomocou špecifikácie tzv. _IngressClass_. Jednej implementácii možno priradiť viacero tried typu _IngressClass_ (pozor na chybu v niektorých implementáciách). Vytvorte súbor `.../webcloud-gitops/infrastructure/ingress-nginx/ingressclass.yaml` s týmto obsahom:

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: IngressClass
   metadata:
     name: wac-hospital
     namespace: ingress-nginx
   spec:
     controller: k8s.io/ingress-nginx   # <== priraďuje triedu "wac-hospital" konkrétnemu radiču
   ```

   Ďalej vytvoríme patch pre triedu pomenovanú `nginx` (z manifestu `ingress-nginx.yaml`) a nastavíme túto triedu ako prednastavenú. Vytvorte súbor `.../webcloud-gitops/infrastructure/ingress-nginx/patches/nginx.ingressclass.yaml`

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: IngressClass
   metadata:
     name: nginx
     namespace: ingress-nginx
     annotations: 
       ingressclass.kubernetes.io/is-default-class: "true"
   ```

   Štandardná konfigurácia nastavuje služby ingress radiča na typ `LoadBalancer`, čím je táto služba zverejnená na štandardných portoch adresy priradenej hostiteľom, a služba je vstupnou bránou do celého systému. V našom prípade ale pred ingress ešte zaradíme centrálnu službu pre autentifikáciu používateľov, preto upravíme nastavenie služby `ingress-nginx-controller`. Vytvorte patch súbor `.../webcloud-gitops/infrastructure/ingress-nginx/patches/ingress-nginx-controller.service.yaml` s obsahom

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: ingress-nginx-controller
     namespace: ingress-nginx
   spec:
     type: ClusterIP
     externalTrafficPolicy: null  # <== vymaže konfliktné polia, 
                                  # platné len pre typ LoadBalancer
     ipFamilyPolicy: null
     ipFamilies: null
   ```

   Teraz vytvorte súbor `.../webcloud-gitops/infrastructure/ingress-nginx/kustomization.yaml`

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization

   resources: 
   - ingress-nginx.yaml
   - ingressclass.yaml
   
   patchesStrategicMerge: 
   - patches/ingress-nginx-controller.service.yaml
   - patches/nginx.ingressclass.yaml
   ```

2. Vyššie nakonfigurované zdroje teraz nasadíme do nášho klastra. Tieto zdroje ale chceme ponechať v samostatnom _namespace_, preto vytvoríme nový adresár `.../webcloud-gitops/clusters/localhost-infra`, z ktorého budeme integrovať infraštruktúru v rôznych _namespace_. Vytvorte súbor `.../webcloud-gitops/clusters/localhost-infra/kustomization.yaml` s obsahom

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources: 
   - ../../infrastructure/ingress-nginx
   ```
  
   Repozitár `...\webcloud-gitops` synchronizujte so vzdialenou verziou - _commit_, _push_

3. Vytvoríme novú _Flux Kustomization_, ktorá bude sledovať priečinok `localhost-infra`.  
   V príkazovom riadku prejdite do adresára `.../webcloud-gitops/flux-system`. Príkazom `kubectl config current-context` sa uistite, že používate správny context pre svoj lokálny klaster, a vykonajte nasledujúce príkazy

   ```ps
   flux create kustomization ambulance-localhost-infra-kustomization --source=ambulance-gitops-repo --path="./clusters/localhost-infra" --prune=true --interval=120s

   flux export kustomization ambulance-localhost-infra-kustomization > ambulance-localhost-infra-kustomization.yaml
   ```

   Yaml súbor vyzerá nasledovne:

   ```yaml
   ---
   apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
   kind: Kustomization
   metadata:
     name: ambulance-localhost-infra-kustomization
     namespace: flux-system
   spec:
     interval: 2m0s
     path: ./clusters/localhost-infra
     prune: true
     sourceRef:
       kind: GitRepository
       name: ambulance-gitops-repo
   ```
   Pridajte referenciu na novovytvorený súbor do kustomizácie flux systému `.../webcloud-gitops/flux-system/kustomization.yaml` pre potreby obnovi klastra:

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
   - ambulance-localhost-infra-kustomization.yaml
   ```

   Pomocou príkazu `kubectl -n ingress-nginx get pods -w` vyčkajte kým `pod` `ingress-nginx-controller-...` nedosiahne stav `running`. Týmto ste dosiahli stav, kedy je váš klaster pripravený na nasadenie zdrojov typu `Ingress`.

4. Z troch našich mikro služieb - UI, WEB API, MongoDB - potrebujeme mimo klaster sprístupniť dve: UI a WEB API. Zadeklarujeme pre nich popis zdrojov pre smerovanie požiadaviek.  Vytvorte súbor `.../webcloud-gitops/apps/<pfx>-ambulance-webapi/ingress.yaml` s obsahom

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: <pfx>-ambulance-webapi
     annotations:
       nginx.ingress.kubernetes.io/rewrite-target: /api/$2
       nginx.ingress.kubernetes.io/use-regex: "true"
   spec:
     ingressClassName: wac-hospital
     rules:
     - http:
         paths:
         - path: /<pfx>-waiting-list-api(/|$)(.*)
           pathType: Prefix
           backend:
             service:
               name: <pfx>-ambulance-webapi
               port:
                 name: webapi-s-port
   ```

   Všimnite si implementáciu prepisu url - [_url rewriting_](https://www.nginx.com/blog/creating-nginx-rewrite-rules/). Museli sme použiť neštandardnú anotáciu zdroja, pretože v špecifikácii Ingress API táto funkcionalita nie je obsiahnutá.

   Upravte súbor `.../webcloud-gitops/apps/<pfx>-ambulance-webapi/kustomization.yaml`

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - deployment.yaml
   - service.yaml
   - ingress.yaml
   
   commonLabels:
     app: <pfx>-ambulance-webapi
   ```

   Teraz vytvorte súbor `.../webcloud-gitops/infrastructure/ufe-controller/ingress.yaml`

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: ufe-controller
   spec:
     ingressClassName: wac-hospital
     rules:
     - http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: ufe-controller
               port:
                 name: http
    ```

    a upravte súbor `.../webcloud-gitops/infrastructure/ufe-controller/kustomization.yaml`

    ```yaml
    ...
    resources:
    ...
    - ingress.yaml

    ...
    ```

    Ďalej odstráňte patch webkomponentu v súbore `.../webcloud-gitops/clusters/localhost/kustomization.yaml` - odstráňte celú sekciu začínajúcu riadkom `patchesJson6902:`. Štandardná konfigurácia `WebComponent` zdroja je po zavedení ingress zdrojov postačujúca. Úplný obsah súboru  `.../webcloud-gitops/clusters/localhost/kustomization.yaml` po úpravach je uvedený tu:

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    - namespace.yaml
    - ../../infrastructure/ufe-controller
    - ../../infrastructure/mongo
    - ../../apps/<pfx>-ambulance-ufe
    - ../../apps/<pfx>-ambulance-webapi
    commonLabels:
      system: wac-hospital

    namespace: wac-hospital

    patchesStrategicMerge:
    - patches/ufe-controller.service.yaml
    - patches/ambulance-webapi.service.yaml

    # the markers (comments) below, marks the lines which will be automatically updated by flux
    images:
    - name: <dockerid>/ambulance-ufe
      newName: <dockerid>/ambulance-ufe # {"$imagepolicy": "flux-system:ambulance-ufe:name"}
      newTag: 1.0.0-1251 # {"$imagepolicy": "flux-system:ambulance-ufe:tag"}
    - name: <dockerid>/ambulance-webapi-test
      newName: <dockerid>/ambulance-webapi-test # {"$imagepolicy": "flux-system:ambulance-webapi:name"}
      newTag: 1.0.0-35 # {"$imagepolicy": "flux-system:ambulance-webapi:tag"}
    ```

5. Pre lokálny kluster si ešte pripravíme ingress konfiguráciu pre Mongo Express, aby bol prístupný mimo klaster.

   Do priečinku `.../webcloud-gitops/infrastructure/mongo/` pridajte nový súbor `ingress.yaml` s obsahom:

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: mongo-express
   spec:
     ingressClassName: wac-hospital
     rules:
     - http:
         paths:
         - path: /mongoexpress
           pathType: Prefix
           backend:
             service:
               name: mongo-express-service
               port: 
                 number: 8081
   ```

   Konfigurácia hovorí, že Mongo Express service bude prístupný na ceste _/mongoexpress_.

   Túto cestu musíme nastaviť aj do Mongo Express kontajnera. Do súboru `.../webcloud-gitops/infrastructure/mongo/mongo-express-deployment.yaml` pridajte novú premennú prostredia:

   ```yaml
   ...
   env:
   - name: ME_CONFIG_SITE_BASEURL
     value: /mongoexpress/
   ...
   ```

   Nakoniec pridajte referenciu na nový súbor do `.../webcloud-gitops/infrastructure/mongo/kustomization.yaml`:

   ```yaml
   ...
   resources:
   - ingress.yaml
   ...
   ```

6. Synchronizujte vzdialený repozitár s `.../webcloud-gitops` (_commit_, _push_).  
   Príkazom `kubectl get ingress --all-namespaces -w` sledujte, kedy flux zosynchronizuje stav vášho klastra.

7. Nakoniec sa pripojte k službe `nginx-ingress-controller` pomocou príkazu

    ```ps
    kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8088:80
    ```

    a v prehliadači prejdite na stránku [http://localhost:8088](http://localhost:8088) a overte funkčnosť aplikácie.
