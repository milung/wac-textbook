## Autorizácia používateľov s Open Policy Agent

Autentifikácia používateľov ešte nerieši riadenie prístupu k jednotlivým zdrojom v našej aplikácii. V praxi môžeme napríklad požadovať, aby k jednotlivým ambulanciám mali prístup len používatelia s rolou `hospital-supervisor` alebo `general-practitioner` - takzvané [_Role-Based Access Control_](https://en.wikipedia.org/wiki/Role-based_access_control), alebo aby sa do čakárne mohli v určitý deň prihlasovať len pacienti s príznakom `pregnant-women` - takzvaný [_Attribute-Based Access Control_](https://en.wikipedia.org/wiki/Attribute-based_access_control).

Pre riadenie politiky prístupu, nielen v rámci autorizácie používateľov, ale pre definovanie takzvaných _policy rules_ vo všeobecnosti, použijeme [Open Policy Agent](https://www.openpolicyagent.org/). V našom prípade sa pokusíme nastaviť politiku, ktorá zabráni prístupu k mikroslužbe `http-echo` pre všetkých používateľov, okrem tých, ktorý majú našou politikou prístupu priradenú rolu "admin".

>info:> Službu [OPA Envoy Plugin](https://www.openpolicyagent.org/docs/latest/envoy-introduction/) možno použitie ako _side-car_ špecifickej služby, to znamená kontrolu dodržania politiky prístupu tesne pred prístupom k špecifickej mikroslužbe, čo z hľadiska bezpečnosti zabráni, aby škodliví aktéri obišli našu autorizáciu. Neskôr si ukážeme ako zabrániť nežiadúcej komunikácii v rámci nášho service mesh-u. Konkrétne riešenie a konfigurácia systému sa v praxi budú líšiť v závislosti od konkrétnych požiadaviek riešenia, častokrát to bude kombinácia rôznych politík a mechanizmov riadenia prístupov.

1. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/opa-plugin/deployment.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: &PODNAME opa-plugin
   spec:
     replicas: 1
     selector:
       matchLabels:
         pod: *PODNAME
     template:
       metadata: 
         labels:
           pod: *PODNAME
       spec:
         volumes:   
         - name: opa-policy 
           configMap:
             name: opa-policy
         - name: opa-config
           configMap:
             name: opa-config
         containers:
         - name: *PODNAME
           image: openpolicyagent/opa:latest-envoy  @_important_@
           securityContext:
             runAsUser: 1111
           volumeMounts:
             - readOnly: true
               mountPath: /policy  @_important_@
               name: opa-policy
             - readOnly: true
               mountPath: /config
               name: opa-config @_important_@
           args:
             - "run"
             - "--server"
             - "--config-file=/config/config.yaml"  @_important_@
             - "--addr=localhost:8181"
             - "--diagnostic-addr=0.0.0.0:8282"
             - "--ignore=.*"
             - "/policy/policy.rego"  @_important_@
           ports: 
             - containerPort: 8181
               name: opa-rest
             - containerPort: 8282
               name: opa-diag
             - containerPort: 9191
               name: envoy-plugin   
           resources:
             limits:
               cpu: '0.5'
               memory: '320M'
             requests:
               cpu: '0.01'
               memory: '128M'
           livenessProbe:
             httpGet:
               path: /health?plugins
               scheme: HTTP
               port: 8282
             initialDelaySeconds: 5
             periodSeconds: 5
           readinessProbe:
             httpGet:
               path: /health?plugins
               scheme: HTTP
               port: 8282
             initialDelaySeconds: 5
             periodSeconds: 5
        
   ```

   Všimnite si položky `volumes` a `volumeMounts`, ktoré budú priraďovať konfiguračné mapy do súborového systému.

   Vytvorte súbor  `${WAC_ROOT}/ambulance-gitops/infrastructure/opa-plugin/service.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: opa-plugin
   spec: 
     ports:
     - name: http
       port: 9191
       targetPort: 9191
    ```

2. Teraz pristúpime ku konfigurácii `opa-envoy-plugin` služby. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/opa-plugin/params/opa-config.yaml`. Všimnite si, že sme priradili port `9191` pre `envoy_ext_authz_grpc` plugin a nastavili sme cestu k pravidlu vyhodnotenia autorizačnej politiky (_policy_).

   ```yaml
   plugins:
     envoy_ext_authz_grpc:
       addr: :9191
       path: wac/authz/result @_important_@
   decision_logs:
     console: true  # v produkčnom prostredí nastavte na false
   ```

   Všimnite si, že sme priradili port `9191` pre `envoy_ext_authz_grpc` plugin - rovnaký port ako je uvedený v objekte typu [_Service_](https://kubernetes.io/docs/concepts/services-networking/service/) a nastavili sme cestu k pravidlu vyhodnotenia autorizačnej politiky (_policy_) - `wac/authz/result`.

   Teraz si zadefinujeme túto politiku oprávnených prístupov pre náš systém. Keďže pracujeme na lokálnom klastri s pomerne jednoduchou aplikáciou, bude naša politika slúžiť len ako ukážka pre účely jej otestovania. Budeme kontrolovať prístup k aplikácii `http-echo`, ku ktorej povolíme prístup len niektorým zo svojich kolegov, alebo prístup pre požiadavky so špeciálnym príznakom. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/opa-plugin/params/policy.rego` a v jazyku [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) zadefinujeme našu testovaciu politiku:

   >info:> Pre pokročilejšiu práco s Rego jazykom môžete využiť [Visual Studio Code rozšírenie](https://marketplace.visualstudio.com/items?itemName=tsandall.opa).

   ```rego
   package wac.authz @_important_@
   import input.attributes.request.http as http_request
   
   default allow = false
   
   is_valid_user = true { http_request.headers["x-auth-request-email"] }
   
   user = { "valid": valid, "email": email, "name": name} {
       valid := is_valid_user
       email := http_request.headers["x-auth-request-email"]
       name := http_request.headers["x-auth-request-user"] 
   }
   
   headers["x-validated-by"] := "opa-checkpoint"
   
   user_role["user"] { 
       user.valid
   }
   
   user_role[ "admin" ] { 
       [_, query] := split(http_request.path, "?")
       glob.match("am-i-admin=yes", [], query) @_important_@
   }
   
   user_role[ "admin" ] { 
       user.email == "<kolegov@email>" @_important_@
   }
   
   action_allowed {
       # authenticated user can visit any page, but not /http-echo
       not glob.match("/http-echo*", [], http_request.path) @_important_@
   }
   
   action_allowed {
       user_role["admin"] @_important_@
   }
   
   allow { @_important_@
       user.valid
       action_allowed @_important_@
   }
   
   headers["x-auth-request-roles"] := concat(" ", [ role | 
       some r
       user_role[r] 
       role := r
   ])
   
   result["allowed"] := allow
   result["headers"] := headers
   ```

   Ako ste už mohli postrehnúť, pri full-stack vývoji potrebuje byť softvérový inžinier zbehlý v rôznych programovacích jazykov. [Rego] je logický a _rule-based_ programovací jazyk vychádzajúci z jazyka datalog. Vo vyššie uvedenom programe sú sady pravidiel, pomocou ktorých sa snažíme dospieť k výsledku pravidla `allow` - buď `true` alebo `false`. Vysledná hodnota určí, či bude povolené pokračovať v spracovaní požiadavky. Zároveň sa snažíme vytvoriť hlavičky odpovede, ktoré budú obsahovať informácie o používateľovi a jeho oprávneniach.

   Všimnite si prvé pravidlo `action_allowed`. To určuje, že všetky požiadovky, ktoré nesmerujú na cestu `/http-echo` sú povolené. Druhé pravidlo  `action_allowed` určuje, že všetky požiadavky sú povolené, pokiaľ je splnené pravidlo `user_role["admin"]`. Pri bližšej analýze, zistíte, že toto pravidlo je splnené, pokiaľ je v časti [_Query_ parametrov](https://en.wikipedia.org/wiki/Query_string) obsiahnutý reťazec `am-i-admin=yes` (len pre demonštračné účely!), alebo pokiaľ je k Vášmu klastru prihlásený kolega s emailom `<kolegov@email>`. Ďaľšie detaily ako nakonfiguravať politiku prístupov nájdete v [dokumentácii](https://www.openpolicyagent.org/docs/latest/policy-language).

3. Nakoniec vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/opa-plugin/kustomization.yaml`

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   namespace: wac-hospital
   
   commonLabels:
     app.kubernetes.io/part-of: wac-hospital
     app.kubernetes.io/component: opa-plugin
   
   resources:
   - deployment.yaml
   - service.yaml
   
   configMapGenerator:
   - name: opa-config
     files:
       - config.yaml=params/opa-config.yaml
   - name: opa-policy
     files: 
     - params/policy.rego
   ```

    a do súboru `${WAC_ROOT}/ambulance-gitops/clusters/localhost/prepare/kustomization.yaml` pridajte referenciu:

    ```yaml
    ...
    resources: 
    ...
    - ../../../infrastructure/opa-plugin @_add_@

    ...
    ```

4. Podobne ako v prípade autentifikácie pomocou `oauth2-proxy`, pridáme aj autorizáciu medzi zoznam filtrov v [Envoy Proxy]. Upravte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/envoy-gateway/envoy-patch-policy.yaml`:

    ```yaml
    ...
    spec:
      ...
      jsonPatches:
        - type: "type.googleapis.com/envoy.config.listener.v3.Listener"
        ...
        - type: "type.googleapis.com/envoy.config.listener.v3.Listener"             @_add_@
          name:  wac-hospital/wac-hospital-gateway/fqdn             @_add_@
          operation:             @_add_@
            op: add             @_add_@
            path: "/filter_chains/0/filters/0/typed_config/http_filters/1"             @_add_@
            value:             @_add_@
              name: authorization.ext_authz             @_add_@
              typed_config:             @_add_@
                "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz             @_add_@
                transport_api_version: V3             @_add_@
                grpc_service:             @_add_@
                  google_grpc:             @_add_@
                    stat_prefix: opa             @_add_@
                    target_uri: opa-plugin.wac-hospital:9191             @_add_@
                  timeout: 3s             @_add_@
    ```

5. Uložte zmeny a archivujte ich vo vzdialenom repozitári:

   ```ps
    git add .
    git commit -m "Add oauth2-proxy"
    git push
   ```

   Overte, že sa aplikujú najnovšie zmeny vo Vašom klastri

    ```ps
    kubectl -n wac-hospital get kustomization -w
    ```

    Overte, že stav objektu _Envoy Patch Policy_ je `Programmed`

    ```ps
    kubectl -n wac-hospital get epp
    ```

6. V prehliadači prejdite na stránku [https://wac-hospital.loc](https://wac-hospital.loc), ktorá by mala byť zobrazená bez zmeny. Teraz prejdite na stránku [https://wac-hospital.loc/http-echo](https://wac-hospital.loc/http-echo) - stránka je prázdna a v _Nástrojoch vývojarov -> Sieť_ možete vidieť odpoveď `403 Unauthorized`. Prejdite na stránku [https://wac-hospital.loc/http-echo?am-i-admin=yes](https://wac-hospital.loc/http-echo?am-i-admin=yes). V tomto prípade sa zobrazí odozva mikroslužby `http-echo`. Podobne môžete otvoriť v prehliadači súkromné okno a požiadať kolegu, ktorého e-mail ste zadali v politike prístupov, aby sa prihlásil na stránku [https://wac-hospital.loc/http-echo](https://wac-hospital.loc/http-echo). V tomto prípade by mal tiež vidieť odozvu služby `http-echo`.

   Prezrite si odozvu zo služby `http-echo`. Medzi hlavičkami požiadavky, prichádzajúcej na službu `http-echo` by ste mali nájsť aj nasledovné:

   ```json
   ...
   "x-auth-request-email": "<your github email>",
   "x-auth-request-user": "<your github user id>",
   "x-auth-request-roles": "admin user",
   ...
   ```

Vygenerované hlavičky môžeme ďalej využívať buď na detailnejšie smerovanie požiadaviek v objektoch typu [_HTTPRoute_](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1alpha2.HTTPRoute), alebo môžeme nasadiť [OPA Envoy Plugin](https://www.openpolicyagent.org/docs/latest/envoy-introduction/) ako sidecar k niektorej z naších služieb a ďalej riadiť politiky prístupov v rámci nášho service mesh-u. Pre dynamickú správu priradených rôl by sme náš klaster museli rozšíriť o službu, ktorú by [OPA Envoy Plugin](https://www.openpolicyagent.org/docs/latest/envoy-introduction/) mohol použiť na dynamické načítanie politiky prístupv.
