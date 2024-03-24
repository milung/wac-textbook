# Smerovanie požiadaviek s použitím Gateway API

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-mesh-010`

---

Naše služby sú obsluhované z rôznych subdomén - rôznych adries hosťujúceho počítača - frontend je nasadený na adrese `http://localhost:30331` a WebAPI na adrese `http://localhost:30081`. Vo väčších systémoch s desiatkami mikroslužieb by tento prístup bol neudržateľný. Väčšina sietí filtruje HTTP protocol na portoch odlišných od portov `80` alebo `443`, čo by znamenalo, že každá mikroslužba musí mať vlastnú subdoménu. To by vyžadovalo správu desiatok domén a ich zabezpečenie, a tiež by znižovalo flexibilitu pri evolúcii systémov. Jedným zo spôsobov ako tento problém adresovať, je zaintegrovať do systému takzvanú [_reverse proxy_](https://en.wikipedia.org/wiki/Reverse_proxy), niekedy tiež označovanú ako _Gateway_, alebo aj [_API Gateway_](https://www.redhat.com/en/topics/api/what-does-an-api-gateway-do). Označenia, ako aj rozsah funkcionality obsiahnutý za týmito službami, sa líšia. Pre náš účel je dôležité, aby táto služba dokázala presmerovať požiadavky na jednotlivé mikro služby na základe určitých pravidiel, typicky na základe cesty URL uvedenej v požiadavke.

Typickými reprezentantmi takýchto reverse proxy sú aplikácie [_nginx_](https://www.nginx.com) a [_Envoy Proxy_](https://www.envoyproxy.io/), nie sú ale zďaleka jediné. Keďže smerovanie požiadaviek je jednou zo základných funkcionalít pri orchestrácii mikro služieb, uviedol tím kubernetes štandardizované api [_Ingress_], ktorého implementáciu ale prenechal tretím stranám. Toto API ale nepokrývalo v základnej verzii všetky prípady reálnej praxe, jednotlivé implementácie preto API rozširujú proprietárnymi anotáciami.

Na základe skúseností z implementácie [_Ingress_], sa začala pripravovať nová sada [Gateway API]. Hoci je [_Ingress_] zatiaľ najviac rozšíreným spôsobom riadenia smerovania požiadaviek v systémoch kubernetes, my si ukážeme spôsob založený na [Gateway API].

[Gateway API] poskytuje viacero objektov pre konfiguráciu systémov. V produkčnom nasadení sa predpokladá, že typ `Gateway Class` dodá poskytovateľ infraštruktúry - napríklad prevádzkovateľ verejného datového centra, typ `Gateway` poskytne správca klastru - napríklad informačné oddelenie zákazníka. Vývojári samotnej aplikácie budú typicky poskytovať objekty typu `HTTPRoute`. Pre potreby lokálneho vývoja je ale potrebné nasadiť všetky typy objektov.

## Nasadenie Gateway API

1. V tomto kroku vytvoríme konfiguráciu pre nasadenie [Envoy Gateway] implementácie [Gateway API]. Vytvorte adresár `${WAC_ROOT}/ambulance_gitops/infrastructure/envoy-gateway` a v ňom vytvorte súbor `gateway-class.yaml` s nasledujúcim obsahom:

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

   Táto konfigurácia vytvorí v rámci klastra bod pripojenia, na ktorom bude implementácia [Gateway API] čakať na prichádzajúce požiadavky a spracovávať ich podľa pravidiel definovaných v objektoch typu [`HTTPRoute`](https://gateway-api.sigs.k8s.io/api-types/httproute/).

3. Vytvorte súbor: `${WAC_ROOT}/ambulance_gitops/infrastructure/envoy-gateway/kustomization.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
   - https://github.com/envoyproxy/gateway/releases/download/latest/install.yaml
   - gateway-class.yaml
   - gateway.yaml
   ```

   Tento manifest obsahuje objekty potrebné pre nasadenie [Envoy Gateway] implementácie [Gateway API] a prípravu klastra pre potreby nasadenia jednotlivých mikroslužieb.

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
     interval: 120s
     ...
   ```

   Dôvodom pre túto úpravu je, že [Flux CD] nevie správne vyhodnotiť stav nasadenia objektov typu [_Job_](https://kubernetes.io/docs/concepts/workloads/controllers/job/), ktoré sú z Kubernetes API zmazané po ich úspešnom vykonaní. Vlastnosť `wait: true` určovala, aby Flux CD overil, či sú všetky objekty, ktoré sú súčasťou konfigurácie, v stave _Ready_. [Envoy Gateway]  implementácia obsahuje aj objekty typu _Job_, ktoré sa vykonajú a ktoré Flux CD nevie následne overiť, či sú v stave _Ready_. Vyššie uvedenou úpravou sme túto vlastnosť vypli a namiesto nej sme pridali explicitný zoznam objektov, ktoré budú overované.

6. Uložte zmeny do vzdialeného repozitára:

   ```ps
   git add .
   git commit -m "Add Gateway API"
   git push
   ```

   Potom, čo [Flux CD] aplikuje zmeny, môžete skontrolovať, či boli objekty úspešne nasadené:

   ```ps
   kubectl get gatewayclass
   kubectl get gateway -A
   ```

   a prípadne otvoriť v prehliadači stránku `http://localhost`, ktorá ale bude zatiaľ poskytovať len chybové hlásenie `404 Not Found`

   >info:> Na získanie IP adresy prístupnej mimo cluster [Envoy Gateway] využíva servis typu `loadbalancer`. Ak kluster ktorý používate nemá nastavený východzí loadbalancer, bude ho potrebné nakonfigurovať. Napríklad pre kluster typu __microk8s__ je potrebné loadbalancer povoliť pomocou príkazu `microk8s enable metallb:127.0.0.1-127.0.0.1` (rozsah IP adries môžete zmeniť podľa ich dostupnosti na lokálnej sieti).

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
      namespace: wac-hospital
    - name: wac-hospital-gateway  # Hack to make it work for common cluster
      namespace: wac-hospital-system
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

   Vo všeobecnosti platí, že každá požiadavka musí byť spracovaná jedným alebo žiadny pravidlom uvedeným v objektoch `HTTRoute` pre daný `Gateway` objekt.  Tento manifest špecifikuje, že všetky požiadavky pri ktorých cesta začína segmentom `/ui` budú presmerované na službu `ufe-controller`. Požiadavky na root dokument `/` budú vrátené klientovi so stavom `303 -Redirect` a presmerovaním na cestu `/ui`.

   Ďalej potrebujeme upraviť [_base URL_] pre službu `ufe-controller`, ktorá nebude teraz dostupná z koreňového adresára `/` požiadaviek, ale z podadresára `/ui/`. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/ufe-controller/patches/ufe-controller.deployment.yaml` s nasledujúcim obsahom:

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
        namespace: wac-hospital
      - name: wac-hospital-gateway  # Hack to make it work for common cluster
        namespace: wac-hospital-system
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /<pfx>-api
        filters: 
          - type: URLRewrite    @_important_@
            urlRewrite:    @_important_@
              path:    @_important_@
                type: ReplacePrefixMatch    @_important_@
                replacePrefixMatch: /api    @_important_@
        backendRefs:
          - group: ""
            kind: Service
            name: <pfx>-ambulance-webapi
            port: 80
    ```

   Tento manifest špecifikuje, že všetky požiadavky, pri ktorých cesta začína segmentom `/<pfx>-api`, budú presmerované na službu `<pfx>-ambulance-webapi`.
   Všimnite si časť `filters` - tu špecifikujeme, že sa má cesta `/<pfx>-api` zameniť za `/api` pred tým, ako sa požiadavka odovzdá službe `<pfx>-ambulance-webapi`. Toto je potrebné, pretože služba `<pfx>-ambulance-webapi` očakáva, že API požiadavky budú zasielané na cestu `/api`.

   Ďalej do toho istého súboru doplňte nové pravidlo:

   ```yaml
   ...
   spec:
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /<pfx>-api
         ...
       - matches:    @_add_@
           - path:    @_add_@
               type: PathPrefix    @_add_@
               value: /<pfx>-openapi-ui    @_add_@
         backendRefs:    @_add_@
           - group: ""    @_add_@
             kind: Service    @_add_@
             name: <pfx>-openapi-ui    @_add_@
             port: 80    @_add_@
   ```

   Požiadavky na cestu `/<pfx>-openapi-ui` budú presmerované na službu `<pfx>-openapi-ui`, ktorú ešte musíme nakonfigurovať - jedná sa o službu, ktorá sprístupní [Swagger UI] kontajner, nakonfigurovaný v našich manifestoch webapi služby. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-webapi/openapi-ui.service.yaml`:

   ```yaml
   kind: Service
   apiVersion: v1
   metadata:
     name: <pfx>-openapi-ui
   spec:  
     selector:
       pod: <pfx>-ambulance-webapi-label
     ports:
     - name: http
       protocol: TCP
       port: 80  
       targetPort: 8081
   ```

   Ešte raz upravte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-webapi/http-route.yaml`, tentoraz pridáme obsluhu na cestu `/<pfx>-openapi`, z ktorej bude swagger ui načítavať OpenAPI špecifikáciu:

   ```yaml
   ...
   spec:
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /<pfx>-api
         ...
       - matches:
           - path:
               type: PathPrefix
               value: /<pfx>-openapi-ui
         ...
       - matches:   @_add_@
           - path:   @_add_@
               type: Exact   @_add_@
               value: /<pfx>-openapi   @_add_@
         filters:    @_add_@
         - type: URLRewrite   @_add_@
           urlRewrite:   @_add_@
             path:   @_add_@
               type: ReplaceFullPath   @_add_@
               replaceFullPath: /openapi   @_add_@
         backendRefs:   @_add_@
           - group: ""   @_add_@
             kind: Service   @_add_@
             name: <pfx>-ambulance-webapi   @_add_@
             port: 80   @_add_@
   ```

   Pretože sme oproti manifestom v repozitári `ambulance-webapi` upravili cestu z ktorej bude [Swagger UI] načítavať OpenAPI špecifikáciu a na ktorej bude obsluhovaný, musíme upraviť aj konfiguráciu [Swagger UI] kontajnera. Tieto úpravy sú potrebné, aby sme vedeli nasadiť naše služby do spoločného klastra bez konfliktov so službami ostatných študentov. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-webapi/patches/ambulance-webapi.deployment.yaml`:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: <pfx>-ambulance-webapi 
   spec:
     template:
       spec:
         containers:
           - name: openapi-ui
             env:
               - name: URL
                 value: /<pfx>-openapi
               - name: BASE_URL
                 value: /<pfx>-openapi-ui
   ```

   Nakoniec upravte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-webapi/kustomization.yaml`:

   ```yaml
   ...
   resources:
   - 'https://github.com/milung/ambulance-webapi//deployments/kustomize/install' # ?ref=v1.0.1
   - openapi-ui.service.yaml @_add_@
   - http-route.yaml @_add_@
    @_add_@
   patches: @_add_@
   - path: patches/ambulance-webapi.deployment.yaml @_add_@
   ```

   >homework:> Upravte manifesty v repozitári `ambulance-webapi` tak, aby obsahovali tu pridané konfigurácie pre objekt  _Service_ `<pfx>-openapi` a pre objekt _HTTPRoute_ `<pfx>-ambulance-webapi`, pričom _HttpRoute_ objekt bude voliteľný konfiguračný komponent `with-gateway-api`. Následne upravte konfiguráciu v repozitári `ambulance-gitops` tak, aby sa tieto konfigurácie aplikovali.

3. Nakoniec upravíme deklaráciu našej mikro front-end aplikácie v súbore `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-ufe/webcomponent.yaml` tak, aby jej atribút `api-base` ukazoval na cestu webapi na tom istom hostiteľskom počítači:

   ```yaml
   ...
     navigation:
       - element: <pfx>-ambulance-wl-app
         ...
         attributes:
           - name: api-base
             value: http://localhost:30081/api @_remove_@
             # use absolute path on the same host
             value: /<pfx>-api @_add_@
    ...
   ```

4. Overte správnosť Vašej konfigurácie:

    ```ps
    kubectl kustomize clusters/localhost/prepare
    kubectl kustomize clusters/localhost/install
    kubectl kustomize clusters/localhost
    ```

5. Archivujte zmeny do vzdialeného repozitára

   ```ps
   git add .
   git commit -m "Add HTTPRoutes"
   git push
   ```

   Potom, čo [flux] aplikuje zmeny vo Vašom lokálnom klastri, otvorte v prehliadači stránku [http://localhost](http://localhost). Mali by ste vidieť našu aplikáciu, ktorá je schopná komunikovať s WebAPI. Pokiaľ prejdete na stránku `http://localhost/<pfx>-openapi-ui`, mali by ste vidieť popis nášho WebAPI v rozhraní [Swagger UI](https://swagger.io/tools/swagger-ui/).
