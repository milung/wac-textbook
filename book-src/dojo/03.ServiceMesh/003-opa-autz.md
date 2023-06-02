## Autorizácia používateľov s Open Policy Agent

Autentifikácia používateľov ešte nerieši riadenie prístupu k jednotlivým zdrojom. V praxi môžeme napríklad požadovať, aby k jednotlivým ambulanciám mali prístup len používatelia s rolou `hospital-supervisor` alebo `general-practitioner` - takzvané _Role-Based Access Control_, alebo aby sa do čakárne mohli v určitý deň prihlasovať len pacienti s príznakom `pregnant-women` - takzvaný Attribute-Based Access Control.

Pre riadenie politiky prístupu, nielen v rámci autorizácie používateľov, ale pre definovanie _policy rules_ vo všeobecnosti, sa dnes čoraz častejšie používa [Open Policy Agent](https://www.openpolicyagent.org/). Ukážeme si ako použiť toto riešenie v móde gateway proxy, ktorú zaradíme medzi našu OIDC proxy a radič Ingress.

> Pôvodné riešenie [opa-envoy-plugin](https://github.com/open-policy-agent/opa-envoy-plugin) predpokladá použitie ako _side-car_ špecifickej služby, to znamená kontrolu dodržania politiky prístupu tesne pred prístupom k špecifickej mikroslužbe, čo z hľadiska bezpečnosti zabráni, aby škodliví aktéri obišli našu autorizáciu. Neskôr si ukážeme ako zabrániť nežiadúcej komunikácii v rámci nášho service mesh-u. Konkrétne riešenie a konfigurácia systému sa v praxi budú líšiť v závislosti od konkrétnych požiadaviek riešenia.

1. Vytvorte súbor `.../webcloud-gitops/infrastructure/opa-proxy/deployment.yaml` s nasledujúcim obsahom:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: opa-proxy
   spec:
     replicas: 1
     selector:
       matchLabels:
         pod: opa-proxy
     template:
       metadata:
         labels:
           pod: opa-proxy
       spec:
         containers:
           - name: envoy-proxy
             image: envoyproxy/envoy:v1.21-latest
             securityContext:
               runAsUser: 1111
             volumeMounts:
               - readOnly: true
                 mountPath: /config
                 name: proxy-config
             args:
               - "envoy"
               - "--config-path"
               - "/config/envoy.yaml"
             ports: 
               - name: http
                 containerPort: 8000
             resources:
               limits:
                 cpu: '0.1'
                 memory: '128M'
               requests:
                 cpu: '0.05'
                 memory: '64M'
   
           - name: opa-envoy-plugin
             image: openpolicyagent/opa:latest-envoy
             securityContext:
               runAsUser: 1111
             volumeMounts:
               - readOnly: true
                 mountPath: /policy
                 name: opa-policy
               - readOnly: true
                 mountPath: /config
                 name: opa-config
             args:
               - "run"
               - "--server"
               - "--config-file=/config/config.yaml"
               - "--addr=localhost:8181"
               - "--diagnostic-addr=0.0.0.0:8282"
               - "--ignore=.*"
               - "/policy/policy.rego"
             resources:
               limits:
                 cpu: '0.5'
                 memory: '320M'
               requests:
                 cpu: '0.1'
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
         volumes:
           - name: proxy-config
             configMap:
               name: opa-envoy-proxy-config
           - name: opa-policy
             configMap:
               name: opa-policy
           - name: opa-config
             configMap:
               name: opa-config
   ```

   V tomto manifeste používame dva kontajnery - `envoy-proxy` a `opa-envoy-plugin`, ktoré navzájom komunikujú, konkrétne `envoy-proxy` bude konfigurovaný aby posielal autorizačné požiadavky do kontajnera `opa-envoy-plugin`. Všimnite si položky `volumes` a `volumeMounts`, ktoré budú priraďovať konfiguračné mapy do súborového systému.

   Vytvorte súbor  `.../webcloud-gitops/infrastructure/opa-proxy/service.yaml`

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: opa-proxy 
   spec: 
     selector:
         pod: opa-proxy
     ports:
     - name: http
       port: 80
       protocol: TCP
       targetPort: 8000
    ```

2. Teraz pristúpime ku konfigurácii `opa-envoy-plugin`. Vytvorte súbor `.../webcloud-gitops/infrastructure/opa-proxy/params/opa-config.yaml`. Všimnite si, že sme priradili port `9191` pre `envoy_ext_authz_grpc` plugin a nastavili sme cestu k pravidlu vyhodnotenia autorizačnej politiky (_policy_).

    ```yaml
    plugins:
      envoy_ext_authz_grpc:
        addr: :9191
        path: wac/authz/allow
    decision_logs:
      console: true  # v produkčnom prostredí nastavte na false
    ```

    Ďalej vytvoríme [konfiguráciu](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/overview) pre `envoy-proxy`. Vytvorte súbor `.../webcloud-gitops/infrastructure/opa-proxy/params/envoy.yaml`. V konfigurácii si všimnite definíciu `cluster` pomenovanú `ingress-controller`, ktorej `endpoint` ukazuje na službu `ingress-nginx-controller`. Ďalej si všimnite v sekcii `http_filters`, že `ExtAuthz` filter je nakonfigurovaný aby posielal požiadavku na lokálny port `9191`, ktorý sme nastavili v konfigurácii pre `opa-envoy-plugin` kontajner.

    ```yaml
    node:
      cluster: opa-proxy
      id: opa-proxy

    static_resources:
      clusters:
      - name: ingress-controller
        connect_timeout: 0.25s
        lb_policy: ROUND_ROBIN
        type: LOGICAL_DNS
        dns_lookup_family: V4_ONLY
        load_assignment:
          cluster_name: ingress-controller
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: ingress-nginx-controller
                    port_value: 80
      listeners:
      - address:
          socket_address:
            address: 0.0.0.0
            port_value: 8000
        filter_chains:
        - filters:
          - name: envoy.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              upgrade_configs:
              -  upgrade_type: websocket
              codec_type: auto
              stat_prefix: ingress_http
              route_config:
                name: local_route
                virtual_hosts:
                - name: backend
                  domains:
                  - "*"
                  routes:
                  - match:
                      prefix: "/"
                    route:
                      cluster: ingress-controller
              http_filters:
              - name: envoy.ext_authz
                typed_config:
                  "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
                  transport_api_version: V3
                  with_request_body:
                    max_request_bytes: 8192
                    allow_partial_message: true
                  failure_mode_allow: false
                  grpc_service:
                    google_grpc:
                      target_uri: 127.0.0.1:9191
                      stat_prefix: ext_authz
                    timeout: 30s
              - name: envoy.filters.http.router
    
    admin:
      access_log_path: "/dev/null"
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 8001
    ```

3. Teraz si zadefinujeme politiku oprávnených prístupov pre náš systém. Keďže pracujeme na lokálnom klastri s pomerne jednoduchou aplikáciou, bude naša politika slúžiť len ako ukážka pre účely jej otestovania. Budeme kontrolovať prístup k aplikácii `http-echo`, ku ktorej povolíme prístup len niektorým zo svojich kolegov, alebo prístup pre požiadavky so špeciálnym obsahom. Vytvorte súbor `...\webcloud-gitops\infrastructure\opa-proxy\params\policy.rego` a v jazyku [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) zadefinujeme našu testovaciu politiku:

    ```rego
    package wac.authz
    import input.attributes.request.http as http_request
    
    default allow = false
    
    is_valid_user = true { http_request.headers["x-forwarded-email"] }
    
    user = { "valid": valid, "email": email, "name": name} {
        valid := is_valid_user
        email := http_request.headers["x-forwarded-email"]
        name := http_request.headers["x-forwarded-user"]
    }
    
    allow {
        user.valid
        action_allowed
    }
    
    action_allowed {
        not glob.match("/http-echo*", [], http_request.path)
    }
    
    action_allowed {
        glob.match("/http-echo*", [], http_request.path)
        [_, query] := split(http_request.path, "?")
        glob.match("am-i-admin=yes", [], query)
    }
    
    action_allowed {
        glob.match("/http-echo*", [], http_request.path)
        user.email == "<kolegov@email>"
    }
    ```

4. Nakoniec vytvorte súbor `.../webcloud-gitops/infrastructure/opa-proxy/kustomization.yaml`

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    
    namespace: ingress-nginx
    
    commonLabels: 
      app: opa-proxy
      
    resources: 
    - deployment.yaml
    - service.yaml
    
    configMapGenerator:
      - name: opa-config
        files:
          - config.yaml=params/opa-config.yaml
      - name: opa-envoy-proxy-config
        files: 
        - params/envoy.yaml
      - name: opa-policy
        files: 
        - params/policy.rego
    ```

    a do súboru `../webcloud-gitops/clusters/localhost-infra/kustomization.yaml` pridáme referenciu na aplikáciu `opa-proxy`

    ```yaml
    ...
    resources: 
    ...
    - ../../infrastructure/opa-proxy 

    ...
    ```

    Nakoniec v súbore `.../webcloud-gitops/infrastructure/oauth2-proxy/params/params.env` nastavíme parameter `OAUTH2_PROXY_UPSTREAMS` tak, aby boli autentifikované požiadavky smerované na nášho _Open Policy Agent_-a:

    ```env
    ...
    OAUTH2_PROXY_UPSTREAMS=http://opa-proxy/
    ...
    ```

    Zmeny archivujeme a synchronizujeme so vzdialeným repozitárom - _commit_, _push_. Počkáme, kým systém flux aplikuje zmeny do nášho klastra.

5. V prehliadači prejdite na stránku [https://wac-hospital.loc](https://wac-hospital.loc), ktorá by mala byť zobrazená bez zmeny. Teraz prejdite na stránku [https://wac-hospital.loc/http-echo](https://wac-hospital.loc/http-echo) - stránka je prázdna a v _Nástrojoch vývojarov -> Sieť_ možete vidieť odpoveď `403 Unauthorized`. Prejdite na stránku [https://wac-hospital.loc/http-echo?am-i-admin=yes](https://wac-hospital.loc/http-echo?am-i-admin=yes). V tomto prípade sa zobrazí odozva mikroslužby `http-echo`. Podobne môžete otvoriť v prehliadači súkromné okno a požiadať kolegu, ktorého e-mail ste zadali v politike prístupov, aby sa prihlásil na stránku [https://wac-hospital.loc/http-echo](https://wac-hospital.loc/http-echo). V tomto prípade by mal tiež vidieť odozvu služby `http-echo`.

> Rýchlosť predspracovania požiadavky by bolo možné zlúčením kontajnerov z aplikácií `oauth2-proxy`, `opa-proxy` a `ingress-nginx-controller` do jedného podu, kde by medzi sebou komunikovali na _loopback_ sieťovom rozhraní podu. Zároveň by komunikácia prebiehala interne v pode, čím by sa zväčšila bezpečnosť riešenia. Tiež by bolo možné konfigurovať tieto služby rôznym spôsobom, napr. ingress by mohol predávať riadenie autentifikačnej a autorizačnej služby pre účely overenia používateľov. Súčasnú konfiguráciu využijeme na demonštrovanie niektorých aspektov aplikovania implementácie [_Service Mesh Interface_](https://smi-spec.io/) do klastra kubernetes.
