# Smerovanie požiadaviek s použitím Gateway API

---

```ps
devcontainer templates apply -t registry-1.docker.io/milung/wac-mesh-010
```

---

Naše služby sú obsluhované z rôznych subdomén - rôznych adries hosťujúceho počítača - frontend je nasadení na adrese `http://localhost:30331` a WebAPI na adrese `http://localhost:30081`. Vo väčších systémoch s desiatkami mikroslužieb by tento prístup bol neudržateľný. Väčšina sietí filtruje HTTP protocol na portoch odlišných od portov `80` alebo `443`, čo by znamenalo, že každá mikroslužba musí mať vlastnú subdoménu. To by vyžadovalo správu desiatok domén a ich zabezpečenie, a tiež by znižoval flexibilitu pri evolúcii systémov. Jedným zo spôsobov ako tento problém adresovať, je zaintegrovať do systému takzvanú [_reverse proxy_](https://en.wikipedia.org/wiki/Reverse_proxy), niekedy tiež označovanú ako _Gateway_, alebo aj [_API Gateway_](https://www.redhat.com/en/topics/api/what-does-an-api-gateway-do). Označenia sa líšia ako aj rozsah funkcionality obsiahnutý za týmito službami. Pre náš účel je dôležité, aby táto služba dokázala presmerovať požiadavky na jednotlivé mikro služby na základe určitých pravidiel, typicky na základe cesty URL uvedenej v požiadavke.

Typickými reprezentantmi takýchto reverse proxy sú aplikácie [_nginx_](https://www.nginx.com) a [_Envoy Proxy_](https://www.envoyproxy.io/), nie sú ale zďaleka jediné. Keďže smerovanie požiadaviek je jednou zo základných funkcionalít pri orchestrácii mikro služieb, uviedol tím kubernetes štandardizované api [_Ingress_][ingress], ktorého implementáciu ale prenechal tretím stranám. Toto API ale nepokrývalo v základnej verzii všetky prípady reálnej praxe, jednotlivé implementácie preto API rozširujú proprietárnymi anotáciami.

Na základe skúseností z implementácie [Ingress API][ingress], sa začala pripravovať nová sada [Gateway API]. Hoci je [Ingress API][ingress] zatiaľ najviac rozšíreným spôsobom riadenia smerovania požiadaviek v systémoch kubernetes, my si ukážeme spôsob založený na [Gateway API].

[Gateway API] poskytuje viacero zdrojov pre konfiguráciu systémov. V produkčnom nasadení sa predpokladá, že typ `Gateway Class` dodá poskytovateľ infraštruktúry - napríklad prevádzkovateľ verejného datového centra, typ `Gateway` poskytne správca klastru - napríklad informačné oddelenie zákazníka. Vývojari samotnej aplikácie budú typicky poskytovať zdroje typu `HTTPRoute`. Pre potreby lokálneho vývoja je ale potrebné nasadiť všetky typy zdrojov.

## Nasadenie Gateway API

1. V tomto kroku vytvoríme konfiguráciu pre nasadenie [Envoy Gateway] implementácia [Gateway API]. Vytvorte adresár `${WAC_ROOT}/ambulance_gitops/infrastructure/envoy-gateway` a v ňom vytvorte súbor `gateway-class.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: gateway.networking.k8s.io/v1beta1
   kind: GatewayClass
   metadata:
     name: wac-hospital-gateway-class
   spec:
     controllerName: gateway.envoyproxy.io/gatewayclass-controller
   ```

   [Envoy Gateway] controller umožnuje priradenie práve jednej inštancie [GatewayClass](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/). Je možné nasadiť viacero radičov [Envoy Gateway], každý by musel mať ale priradený iný názov `controllerName`. V našom prípade použijeme názov `gateway.envoyproxy.io/gatewayclass-controller`, ktorý je používaný v štandardnej konfigurácii [Envoy Gateway].

2. Ďalej vytvorte súbor: `${WAC_ROOT}/ambulance_gitops/infrastructure/envoy-gateway/gateway.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: gateway.networking.k8s.io/v1beta1
   kind: Gateway
   metadata:
   name: wac-hospital-gateway
   namespace: wac-hospital
   spec:
   gatewayClassName: wac-hospital-gateway-class
   listeners:
       - name: http
         protocol: HTTP
         port: 80
   ```

   Táto konfigurácia vytvorí v rámci klastra bod pripojenia na ktorom bude implementácia [Gateway API] čakať na prichádzajúce požiadavky a spracovávať ich podľa pravidiel definovaných v zdrojoch typu [`HTTPRoute`](https://gateway-api.sigs.k8s.io/api-types/httproute/).

3. Vytvorte súbor: `${WAC_ROOT}/ambulance_gitops/infrastructure/envoy-gateway/kustomization.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - https://github.com/envoyproxy/gateway/releases/download/latest/install.yaml
   - gateway-class.yaml
   - gateway.yaml
   ```

   Tento manifest obsahuje zdroje potrebné pre nasadenie [Envoy Gateway] implementácia [Gateway API] a prípravu klastra pre potreby nasadenia jednotlivých mikroslužieb.

4. Upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/prepare/kustomization.yaml`

   ```yaml
   ...
   
   resources:
   ...
   - ../../../infrastructure/envoy-gateway @_add_@
   
   patches: 
   ...
   ```

5. Upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/gitops/prepare.kustomization.yaml`

   ```yaml
   ...
   spec:
     wait: true @_remove_@
     # targeted healthcheck
     healthChecks:    @_add_@
       - apiVersion: apps/v1    @_add_@
         kind: Deployment    @_add_@
         name: envoy-gateway    @_add_@
         namespace: envoy-gateway-system    @_add_@
       - apiVersion: apps/v1    @_add_@
         kind: Deployment    @_add_@
         name: ufe-controller    @_add_@
         namespace: wac-hospital         @_add_@
     interval: 42s
     ...
   ```

   Dôvodom pre túto úpravu je, že [Flux CD] nevie správne vyhodnotiť stav nasadenia zdrojov typu [_Job_](https://kubernetes.io/docs/concepts/workloads/controllers/job/), ktoré sú z Kubernetes API zmazané po ich úspešnom vykonaní. Vlastnosť `wait: true` určovala, aby overil či sú všetky zdroje ktoré sú súčasťou konfigurácie v stave _Ready_. [Envoy Gateway]  implementácia obsahuje aj zdroje typu _Job_ ktoré sa vykonajú a ktoré Flux CD nevie následne overiť, či sú v stave _Ready_. Vyššie uvedenou úpravou sme túto vlastnosť vypli a namiesto nej sme pridali explicitný zoznam zdrojov, ktoré budú overované.

6. Uložte zmeny do vzidaleného repozitára:

   ```ps
   git add .
   git commit -m "Add Gateway API"
   git push
   ```

   Potom čo [Flux CD] aplikuje zmeny, môžete skontrolovať, či boli zdroje úspešne nasadené:

   ```ps
   kubectl get gatewayclass
   kubectl get gateway
   ```

   a prípadne otvoriť v prehliadači stránku `http://localhost`, ktorá ale bude zatiaľ poskytovať len chybové hlásenie `404 Not Found`

## Smerovanie požiadaviek

V našom klastri máme k dispozícii tieto služby, ku ktorým by sme sa mohli pripojiť z vonkajšej siete:

* **ufe-controller** - poskytuje naše používateľské rozhranie
* **ambulance-webapi** - poskytuje rozhranie pre prístup k dátam
* **swagger-ui** - poskytuje popis nášho web api

Postupne vytvoríme cesty - `HTTPRoute` - pre všetky služby, ktoré budú dostupné z vonkajšej siete.

1. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/ufe-controller/http-route.yaml`

   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: ufe-controller
   spec:
     parentRefs:
       - name: wac-hospital-gateway
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /ui
         backendRefs:
           - group: ""
             kind: Service
             name: ufe-controller
             port: 80
         
       - matches:
         - path:
             type: Exact
             value: /
         filters:
         - type: RequestRedirect
           requestRedirect:
             path:
               type: ReplaceFullPath
               replaceFullPath: /ui
   ```

   Vo všeobecnosti platí, že každá požiadavka musí byť spracovaná jedným alebo žiadny pravidlom uvedeným v zdrojoch `HTTRoute` pre daný `Gateway` objekt.  Tento manifest špecifikuje, že všetky požiadavky pri ktorých cesta zdroja začína segmentom `/ui` budú presmerované na službu `ufe-controller`. Požiadavky na root dokument `/` budú vrátene klientovi so stavom `303 -Redirect` a presmerovaním na cestu `/ui`.

   Potrebuje upraviť [_base URL_] pre službu `ufe-controller`, ktorá bude teraz dostupná z koreňového adresáre '/' požiadaviek, ale z podadresára `/ui/`. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/ufe-controller/patches/ufe-controller.deployment.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: ufe-controller
   spec:
     template: 
       spec:
         containers:
         - name: ufe-controller
           env:
             - name: BASE_URL
               value: /ui/
   ```

   a nakoniec upravte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/ufe-controller/kustomization.yaml`:

   ```yaml
   ...
   resources:
   - https://github.com/milung/ufe-controller//configs/k8s/kustomize
   - http-route.yaml @_add_@
   @_add_@
   patches: @_add_@
   - path: patches/ufe-controller.deployment.yaml @_add_@
   ```

2. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-webapi/http-route.yaml`

   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
   name: <pfx>-ambulance-webapi
   spec:
   parentRefs:
       - name: wac-hospital-gateway
   rules:
       - matches:
           - path:
               type: PathPrefix
               value: /<pfx>-api
       backendRefs:
           - group: ""
           kind: Service
           name: <pfx>-ambulance-webapi
           port: 80
       - matches:
           - path:
               type: PathPrefix
               value: /<pfx>-openapi
       backendRefs:
           - group: ""
           kind: Service
           name: <pfx>-openapi
           port: 80
    ```

    Tento manifest špecifikuje, že všetky požiadavky pri ktorých cesta zdroja začína segmentom `/api` budú presmerované na službu `ambulance-webapi`. Požiadavky na cestu `/openapi` budú presmerované na službu `<pfx>-openapi`, ktorú ešte musíme nakonfigurovať. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/<pfx>-ambulance-webapi/openapi-service.yaml`:

    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: <pfx>-openapi
    spec:  
      selector:
        pod: <pfx>-ambulance-webapi-label
      ports:
      - name: http
        protocol: TCP
        port: 80  
        targetPort: 8081
    ```

    Nakoniec upravte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-webapi/kustomization.yaml`:

    ```yaml
    ...
    resources:
    - 'https://github.com/milung/ambulance-webapi//deployments/kustomize/install' # ?ref=v1.0.1
    - openapi.service.yaml @_add_@
    - http-route.yaml @_add_@
    ```

    >homework:> Upravte manifesty v repozitári `ambulance-webapi` tak, aby obsahovali tu pridané konfigurácie pre objekt  _Service_ `<pfx>-openapi` a pre objekt _HTTPRoute_ `<pfx>-ambulance-webapi`, pričom _HttpRoute_ objekt bude voliteľný konfiguračný komponent `with-gateway-api`. Následne upravte konfiguráciu v repozitári `ambulance-gitops` tak, aby sa tieto konfigurácie aplikovali.

3. Nakoniec upravíme deklaráciu našej mikro front-end aplikácie, tak aby jej atribút `api-base` ukazoval na cestu webapi na to istom hostiteľskom počítači. :

   ```yaml
   ...
     navigation:
       - element: <pfx>-ambulance-wl-app
         ...
         attributes:
           - name: api-base
             value: http://localhost:5000/api @_remove_@
             # use absolute path on the same host
             value: /<pfx>-api @_add_@
    ...
   ```

4. Overte správnosť Vašej konfigurácie:

    ```ps
    kubectl kustomize ambulance-gitops/clusters/localhost/prepare
    kubectl kustomize ambulance-gitops/clusters/localhost/install
    kubectl kustomize ambulance-gitops/clusters/localhost
    ```

4. Archivujte zmeny do vzdialeného repozitára

   ```ps
   git add .
   git commit -m "Add HTTPRoutes"
   git push
   ```

   Potom čo [FluxCD] aplikuje zmeny vo Vašom lokálnom klastri, otvorte v prehliadači stránku [http://localhost](http://localhost). Mali by ste vidieť našu aplikáciu, ktorá je schopná komunikovať s WebAPI. Pokiaľ prejdete na stránku [http://localhost/<pfx>-openapi](http://localhost/<pfx>-openapi), mali by ste vidieť popis nášho WebAPI v rozhraní [Swagger UI](https://swagger.io/tools/swagger-ui/).
