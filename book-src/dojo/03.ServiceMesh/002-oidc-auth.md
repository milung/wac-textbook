## Autentifikácia používateľov pomocou OpenID Connect

V tejto kapitole si ukážeme, ako zabezpečiť identifikáciu používateľov pomocou protokolu [OpenID Connect](https://openid.net/connect/). Nebudeme tu vykonávať autorizáciu používateľov, teda nebudeme ešte riadiť prístup používateľov k jednotlivým zdrojom, len zabezpečíme, že všetci používatelia pristupujúci do klastra sa musia identifikovať a to tak, aby sme vedeli jednoznačne určiť ich identity. Ako poskytovateľa identít použijeme platformu [GitHub](https://github.com/), ale obdobným spôsobom by sme dokázali použiť aj iných poskytovateľov identít, ako napríklad Google, Microsoft, Facebook, a podobne. Pokiaľ by sme si chceli zriadiť vlastného poskytovateľa identít, mohli by sme zaintegrovať do nášho systému niektorú z implementácií [Identity Provider](https://en.wikipedia.org/wiki/Identity_provider) služby. V oblasti menších projektov je napríklad populárna implementácia [dex](https://dexidp.io/), ale k dispozícii je [mnoho ďalších implementácií a knižníc](https://openid.net/developers/certified/).

Pre účely autentifikácie použijeme službu [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/), ktorú použijeme ako vstupnú bránu do nášho _service mesh_.

1. Dôležitým aspektom protokolu OIDC je predpoklad použitia štandardného prehliadača odolného voči rôznym bezpečnostným útokom. Prehliadač naviguje používateľa medzi rôznymi poskytovateľmi - webová aplikácia, poskytovateľ identít, poskytovateľ chránených zdrojov. Protokol predpokladá vytvorenie viacstranného kontraktu medzi jednotlivými entitami. V tomto prostredí je preto potrebné používať jednoznačné označenia entít, čo neplatí pre doménu `localhost`.  Nášmu lokálnemu počítaču musíme preto priradiť iné označenia - _Fully Qualified Domain Name (FQDN)_.

   Zistite IP adresu, ktorá je vášmu počítaču priradená, napríklad príkazom `ipconfig`, alebo `ifconfig` v prípade OS Linux. Otvorte súbor `C:\Windows\System32\drivers\etc\hosts` (`/etc/hosts` na systémoch linux) a vytvorte v ňom nový záznam

   ```plain
   <vaša IP adresa>  wac-hospital.loc
   ```

   Súbor uložte - budete vyzvaný na prechod do privilegovaného módu, respektíve musíte tento súbor otvoriť a upraviť s administrátorskými oprávneniami.

   > IP adresa pridelená Vášmu počítaču sa môže zmeniť, pri každom ďalšom sedení preto musíte overiť, aká IP adresa je vášmu počítaču pridelená a zmeniť záznam v tomto súbore. V niektorých sieťach majú jednotlivé zariadenia, vrátane pracovných počítačov, pridelené stále FQDN. V týchto prípadoch môžete použiť toto označenie a nemusíte upravovať súbor `etc/hosts`. Použitie označenia `localhost` v ďalšom cvičení ale nebude fungovať.

2. Aby sme získali prístup k identite používateľov platformy GitHub, musíme na tejto platforme zaregistrovať našu aplikáciu. Používatelia budú neskôr vyzvaní na poskytnutie súhlasu so zdieľaním ich identity s našou aplikáciou. Prihláste sa so svojim účtom do platformy GitHub a prejdite na stránku [https://github.com/settings/developers](https://github.com/settings/developers). Zvoľte voľbu _Register a new application_. Vyplňte formulár na zobrazenej stránke:

   * _Application name_: `WAC hospital`
   * _Homepage URL_: `https://wac-hospital.loc`
   * _Application description_: `Aplikácia vytvorená na cvičeniach WAC - <vaše meno>`
   * _Authorization callback URL_: `https://wac-hospital.loc/authn/callback`

   Prvé tri položky budú prezentované používateľom pri poskytovaní súhlasu so zdieľaním informácií. Posledná položka je dôležitá v samotnom protokole OIDC - používatelia budú po autentifikácii na stránke GitHub presmerovaní jedine na túto URL, a poskytovateľ identít akceptuje jedine požiadavky o autentifikovanie používateľov, ktoré presmerujú používateľa na niektorú z registrovaných _authorization callback_ URL. Týmto spôsobom je zabránené, aby sa škodlivá stránka mohla vydávať za vašu aplikáciu a získať prístup k údajom používateľa bez jeho predchadzajúceho súhlasu.

   ![Registrácia aplikácie v GitHub](../img/github-oauth-app.png)

   Po vyplnení stlačte ovládací prvok  _Register Application_ a na ďalšej stránke stlačte na ovládací prvok _Generate a new client secret_. Poznačte si identifikátor klienta - _Client ID_, a zobrazené heslo - _Client Secret_. Nakoniec stlačte tlačidlo _Update application_.

   > Návody a odkazy na konfiguráciu použitej služby s inými poskytovateľmi identít nájdete [tu](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider).

3. Vytvorte súbor `.../webcloud-gitops/clusters/localhost-infra/.secrets/client.env` s nasledujúcim obsahom (musíte použiť hodnoty špecifické pre vašu individuálnu konfiguráciu):

    ```env
    client-id=<client id z kroku 2>
    client-secret=<client secret z kroku 2>
    cookie-secret=<náhodný reťazec, napr. z https://www.random.org/strings/; musí mať presne 8,16 alebo 32 bytov (znakov)>
    ```

    a skontrolujte, či súbor `.../webcloud-gitops/.gitignore` obsahuje riadok

    ```plain
    .secrets
    ```

    Heslá a identifikátory klientov nechceme z pochopiteľných dôvodov ukladať bez ďalšej ochrany priamo v git repozitári. Je nutné mať vytvorený systém na správu a ochranu hesiel. Až doteraz sme tento aspekt neriešili, v zásade ale všetky prednastavené štandardné heslá - napr. pre prístup do mongo db - je potrebné v produkčnom prostredí zmeniť. Pre účely lokálneho klastra používaného vývojárom táto požiadavka nie je nutná, napriek tomu heslo klienta registrované v platforme GitHub už chrániť chceme. Tu použijeme jednoduchú techniku ručného pridania _Secret_ zdrojov do príslušného klastra. Stránka [fluxcd.io](https://fluxcd.io/docs/guides/mozilla-sops/) popisuje ďalšie možné techniky ako ukladať a zabezpečiť heslá pri nasadení aplikácie technikou gitops.

4. Teraz vytvoríme konfiguráciu pre mikro službu [ouath2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/). Vytvorte adresár `.../webcloud-gitops/infrastructure/oauth2-proxy` a v ňom súbor `.../webcloud-gitops/infrastructure/oauth2-proxy/deployment.yaml` s obsahom

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:  
     name: oauth2-proxy  
   spec:
     replicas: 1  
     selector:
       matchLabels:
         pod: oauth2-proxy
     template:
       metadata:
         labels: 
           pod: oauth2-proxy
       spec:
         containers:
         - name: oaurh2-proxy  
           image: quay.io/oauth2-proxy/oauth2-proxy
           env:
           - name: OAUTH2_PROXY_CLIENT_ID
             valueFrom:
               secretKeyRef:
                   name: github-client
                   key: client-id
           - name: OAUTH2_PROXY_CLIENT_SECRET
             valueFrom:
               secretKeyRef:
                   name: github-client
                   key: client-secret
           - name: OAUTH2_PROXY_COOKIE_SECRET
             valueFrom:
               secretKeyRef:
                   name: github-client
                   key: cookie-secret
           envFrom:
             - configMapRef: 
                name: oauth2-proxy
           volumeMounts:
             - mountPath: /etc/oauth2
               name: tls
               readOnly: true
           ports:
           - name: https-authn
             containerPort: 4443
           resources:
             limits:
               cpu: '0.5'
               memory: '320M'
             requests:
               cpu: '0.1'
               memory: '128M'
         volumes:
         - name: tls
           secret:
             secretName: oauth2-tls  
    ```

    Všimnite se, že referencujeme hodnoty zo _Secret_-u `github-client`, a `oauth-tls`, ktoré budeme vytvárať v klastri bez použitia gitops automatizácie. Ďalej vytvorte súbor `...\webcloud-gitops\infrastructure\oauth2-proxy\service.yaml`

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: oauth2-proxy 
    spec: 
      type: LoadBalancer
      selector:
          pod: oauth2-proxy
      ports:
      - name: https
        port: 443
        protocol: TCP
        targetPort: 4443
    ```

    Tu si všimnite, že sme použili typ služby `LoadBalancer`, čo v praxy znamená, že táto služba bude prístupná z externých sietí na príslušnej IP adrese. Konkrétna implementácia sa líši od poskytovateľov kubernetes klastra, v prípade Docker for Desktop je táto služba dostupná na sieťovom rozhraní nášho počítača a na uvedených číslach `port`-ov.

    Ďalej vytvorte súbor `...\webcloud-gitops\infrastructure\oauth2-proxy\params\params.env`, ktorý obsahuje [konfiguráciu pre službu oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview)

    ```env
    OAUTH2_PROXY_COOKIE_DOMAINS=wac-hospital.loc
    OAUTH2_PROXY_COOKIE_NAME=__wac-hospital.loc-b2F1dGgyIHNlc3Npb24
    OAUTH2_PROXY_COOKIE_SAMESITE=lax
    OAUTH2_PROXY_EMAIL_DOMAINS=*
    OAUTH2_PROXY_PROVIDER=github
    OAUTH2_PROXY_PROXY_PREFIX=/authn
    OAUTH2_PROXY_REDIRECT_URL=https://wac-hospital.loc/authn/callback
    OAUTH2_PROXY_TLS_CERT_FILE=/etc/oauth2/tls.crt
    OAUTH2_PROXY_TLS_KEY_FILE=/etc/oauth2/tls.key
    OAUTH2_PROXY_UPSTREAMS=http://ingress-nginx-controller/
    OAUTH2_PROXY_HTTPS_ADDRESS=:4443
    OAUTH2_PROXY_SCOPE=user:email
    ```

    Všimnite si voľbu `OAUTH2_PROXY_EMAIL_DOMAINS=*`. Toto nastavenie umožňuje, aby do systému vstúpili ľubovoľní autentifikovaní používatelia. Ak by sme ju zmenili napríklad na `OAUTH2_PROXY_EMAIL_DOMAINS=stuba.sk`, obmedzili by sme prístup len pre používateľov, ktorí sú vlastníkmi elektronických schránok spravovaných v doméne `stuba.sk`, to znamená pre študentov a zamestnancov STU Bratislava.  Premenná `OAUTH2_PROXY_AUTHENTICATED_EMAILS_FILE` by nám umožnila ďalej limitovať prístup len pre konkrétnych používateľov, v cvičení túto možnosť ale nepoužijeme.

    Premenné začínajúce `OAUTH2_PROXY_COOKIE` určujú, aké cookie bude naša stránka používať pre identifikáciu sedenia, v ktorom je používateľ uz autentifikovaný. Snažime sa čo najviac redukovať rozsah platnosti tohto cookie a to len na doménu našej aplikácie. Tým zabránime zdieľaniu s inými stránkami, o ktorých účele nevieme.

    Premenná `OAUTH2_PROXY_UPSTREAMS=http://ingress-nginx-controller/` hovorí, že požiadavky autentifikovaných používateľov sú ďalej predané nášmu radiču _Ingress_ zdrojov, ktorý sme konfigurovali v predchádzajúcej kapitole, a ktorý zabezpečuje ďalšie smerovanie požiadaviek.

    Nakoniec vytvorte súbor `...\webcloud-gitops\infrastructure\oauth2-proxy\kustomization.yaml`

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources: 
    - deployment.yaml
    - service.yaml

    namespace: ingress-nginx

    commonLabels:
      app: oauth2-proxy

    configMapGenerator:
    - name: oauth2-proxy
      envs:
      - params/params.env
    ```

5. Naša aplikácia bude dostupná cez zabezpečený protokol SSL. K tomu budeme potrebovať vytvoriť certifikáty nášho servera. V cvičení použijeme takzvané _self-signed_ certifikáty, ktoré sice nie sú všeobecne dôveryhodné, ale pre účely softvérového vývoja sú postačujúce. Iným spôsobom ako získať vydanie dôveryhodných certifikátov je napríklad použitie služby [Let's encrypt](https://letsencrypt.org/) alebo využiť služby niektorej z globálne uznávaných [certifikačných autorít](https://en.wikipedia.org/wiki/Certificate_authority).

   Nainštalujte aplikáciu [openssl](https://www.openssl.org/), napríklad s použitím príkazu `choco install openssl`. V príkazovom riadku prejdite do priečinka `.../webcloud-gitops/clusters/localhost-infra/.secrets` a vygenerujte si  certifikát a privátny kľúč pomocou príkazu:

   ```ps
   openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out tls.crt -keyout tls.key
   ```

    Zadajte nasledujúce hodnoty na otázky počas vytvárania certifikátu:

    * _Country Name_:  `SK`
    * _State or Province Name_: `Slovakia`
    * _Locality Name_: `Bratislava`
    * _Organization Name_: `FIIT STU BA`
    * _Organizational Unit Name_: `WAC_I`
    * _Common Name (e.g. server __FQDN__ or YOUR name)_: `wac-hospital.loc`
    * _Email Address_: `<vaša@elektronická.schránka>`

    Najdôležitejšou časťou je špecifikácia _Common Name_, ktoré musí byť zhodné s hostiteľskou doménou (FQDN), na ktorej bude naša aplikácia dostupná. V adresári `.../webcloud-gitops/clusters/localhost-infra/.secrets` by ste mali teraz vidieť súbory `tls.crt` a `tls.key`. Vytvorte súbor `.../webcloud-gitops/clusters/localhost-infra/.secrets/kustomization.yaml` s obsahom:

     ```yaml
     apiVersion: kustomize.config.k8s.io/v1beta1
     kind: Kustomization

     namespace: ingress-nginx

     secretGenerator:
     - name: github-client
       type: Opaque
       envs:
       - client.env
       options: 
         disableNameSuffixHash: true
     - name: oauth2-tls
       type: Opaque
       files:
       - tls.crt
       - tls.key
       options:
         disableNameSuffixHash: true
     ```

    V adresári `.../webcloud-gitops/clusters/localhost-infra/.secrets` na príkazovom riadku vykonajte nasledujúce príkazy, ktoré vytvoria príslušné zdroje typu _Secret_

    ```ps
    kubectl config use-context docker-desktop
    kubectl apply -k .
    ```
    
    Pridajte referenciu na novovytvorený súbor do kustomizácie flux systému .../webcloud-gitops/flux-system/kustomization.yaml pre potreby obnovi klastra (hoci nemá nič spoločné s flux systémom rozhodli sme sa pre zjednodušenie použiť rovnaký súbor):
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
    - ../clusters/localhost-infra/.secrets
    ```

6. Upravte súbor `...\webcloud-gitops\clusters\localhost-infra\kustomization.yaml` a doplňte do neho referenciu na `oauth2-proxy`

   ```yaml
   ...
   resources: 
   ...
   - ../../infrastructure/oauth2-proxy  
   ```

   Synchronizujte repozitár `...\webcloud-gitops` s jeho vzdialenou verziou - _commit_, _push_. Pomocou príkazu `kubectl -n ingress-nginx get pods -w` overíte, kedy bude pod `oauth2-proxy` nasadený do Vášho systému a v stave _Running_. Pomocou príkazu `kubectl -n ingress-nginx get services -w` overíte, kedy bude služba `oauth2-proxy` nasadená do Vášho systému a v stave _Active_.

   > __Dôležitá poznámka__: Ak sa nenaštartuje service _oauth2-proxy_ môže to znamenať, že na porte 443 alebo 80 vášho počítača počúva iný proces. Použite Google (alebo rovno tool [CurrPorts](https://www.nirsoft.net/utils/cports.html#DownloadLinks)) na zistenie, ktorá aplikácia to je a zastavte ju. V systémoch _Windows_ to môže byť obtiažne, najčastejšie je to však _Internet Information Service_. Na jeho zastavenie spustite _Internet Information Services Manager_ a servis zastavte stlačením tlačidla _Stop_.

   ![Internet Information Services Manager](../img/iss-manager.png)

7. Otvorte v prehliadači novú záložku a otvorte _Nástroje pre vývojárov -> Sieť_.  V tejto záložke prejdite na stránku [https://wac-hospital.loc](https://wac-hospital.loc). Nezabudnite, že v súbore `etc/host` musíte mať správne pridelenú IP adresu k záznamu `wac-hospital.loc`. Prehliadač vás upozorní na bezpečnostné riziko z dôvodu použitia neovereného TLS certifikátu. Zvoľte _Pokračovať_ a _Rozumiem bezpečnostnému riziku_.

    > V niektorých prípadoch môže byť voľba _Pokračovať_ nedostupná. V takom prípade, ponechajte okno prehliadača ako aktívnu aplikáciu a na klávesnici vyťukajte `THISISUNSAFE`. Táto možnosť (_back-doors_) je v prehliadačoch Google ponechaná pre dobre informovaných profesionálov, akými sú napríklad softvéroví inžinieri.

    Na obrazovke vidíte prihlasovaciu stránku _OAuth2 Proxy_ (našej konfigurovanej služby) s voľbou _Sign in with GitHub_. Stlačte na túto voľbu.

    ![Prihlasovacia stránka OAuth2 Proxy](../img/oauth2-sign-in.png)

    > Konfiguráciou služby OAuth2 Proxy možno prihlasovaciu stránku zmeniť, prípadne tento krok preskočiť a byť presmerovaný priamo na stránky GitHub.

    Následne budete presmerovaný na stránku GitHub, kde budete vyzvaný na udelenie súhlasu so zdieľaním vašich identifikačných údajov s aplikáciou _WAC Hospital_. Súhlas udeľte, po čom budete presmerovaný do aplikácie vo vašom klastri.

    Prezrite si záznam sieťovej komunikácie v _Nástroji vývojárov_. Môžete vidieť, ako je prehliadač niekoľkokrát presmerovaný medzi jednotlivými entitami OIDC protokolu. Časť protokolu pritom prebieha na pozadí medzi _OAuth2 Proxy_ a poskytovateľom identít Git Hub.

    OAuth2 Proxy si teraz bude pamätať Vaše prihlásenie počas nasledujúcich 168 hodín (platnosť cookie) a platforma GitHub si pamätá udelenie oprávnenia pre Vašu aplikáciu. Pri opätovnom načítaní preto budete automaticky presmerovaný na stránky aplikácie a iba pri dlhšom nepoužívaní aplikácie budete opätovne vyzvaný na prihlásenie. Alternatívne sa môžete skúsiť prihlásiť z nového súkromneho okna prehliadača, ktoré nezdieľa vašu identitu (cookies a pod) s ostatnymi  oknami prehliadača.

8. Mikro služba _oauth2-proxy_ poskytuje identitu prihláseného používateľa v hlavičkách preposielaných požiadaviek. Aby sme si to overili, doplníme do nášho klastra jednoduchú službu [http-echo](https://github.com/mendhak/docker-http-https-echo). Vytvorte súbor `.../webcloud-gitops/infrastructure/http-echo/deployment.yaml`

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:  
     name: http-echo
     annotations: 
       linkerd.io/inject: ingress
   spec:
     replicas: 1  
     selector:
       matchLabels:
         pod: http-echo
     template:
       metadata:
         labels: 
           pod: http-echo 
       spec:
         containers:
         - image: mendhak/http-https-echo
           name: http-echo        
           ports:
           - name: http
             containerPort: 80
           resources:
             limits:
               cpu: '0.5'
               memory: '320M'
             requests:
               cpu: '0.1'
               memory: '128M'
   ```

   Vytvorte súbor `.../webcloud-gitops/infrastructure/http-echo/service.yaml`

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: http-echo
   spec:
     ports:
     - name: http
       port: 80
       protocol: TCP
       targetPort: 80
   ```

   Vytvorte súbor `.../webcloud-gitops/infrastructure/http-echo/ingress.yaml`:

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: http-echo
     annotations:
       nginx.ingress.kubernetes.io/rewrite-target: /
   spec:
     ingressClassName: wac-hospital
     rules:
     - http:
         paths:
         - path: /http-echo
           pathType: Prefix
           backend:
             service:
               name: http-echo
               port:
                 number: 80
    ```

    a súbor `.../webcloud-gitops/infrastructure/http-echo/kustomization.yaml`:

    ```yaml
    resources: 
    - deployment.yaml
    - service.yaml
    - ingress.yaml
    
    namespace: default
    
    commonLabels: 
      app: http-echo
    ```

    a nakoniec v súbore `...\webcloud-gitops\clusters\localhost-infra\kustomization.yaml` doplňte referenciu na túto službu:

    ```yaml
    ...
    resources: 
    ...
    - ../../infrastructure/http-echo
    ...
    ```

    Zmeny synchronizujte so vzdialeným repozitárom - _commit_, _push_ a vyčkajte, kým nebudú aplikované vo Vašom lokálnom klastri. Potom prejdite na stránku [https://wac-hospital.loc/http-echo](https://wac-hospital.loc/http-echo) a prezrite si vygenerovaný JSON súbor. V časti `headers` si všimnite hlavičky `x-forwarded-email`, a `x-forwarded-user`, ktoré boli do požiadavky doplnené službou `oauth2-proxy`.

    > Mená týchto hlavičiek možno upraviť konfiguráciou, tiež je možné nakonfigurovať preposlanie autentifikačného [JWT](https://datatracker.ietf.org/doc/html/rfc7519)  [_ID token_-u](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

    <p/>

    > Odporúčame nainštalovať si do prehliadača niektorý z prídavkov pre zobrazovanie JSON súborov, ktorý je užitočným nástrojom pri vývoji webových aplikácii.

9. Naša aplikácia je teraz schopná identifikovať používateľov a v určitom rozsahu aj kontrolovať, kto môže k našim stránkam pristúpiť. V predchádzajúcej kapitole sme ale pristupovali k jednotlivým službam prostredníctvom konfigurácie služieb na typ `NodePort`. To predstavuje možnosť ako obísť vstupnú autentifikačnú bránu.  
__Samostatne teraz upravte konfiguráciu Vášho klastra tak, aby tieto prístupy neboli umožnené (odstráňte jednotlivé _patch_-e vo Vašej konfigurácii)__
