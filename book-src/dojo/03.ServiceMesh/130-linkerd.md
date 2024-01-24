# Správca Service Mesh - Linkerd

---

```ps
devcontainer templates apply -t registry-1.docker.io/milung/wac-mesh-130
```

---

V predchadzajúcich sekciach sme si ukázali ako zabezpečiť náš systém zložený z viacerých mikroslužieb a ako zabezpečiť smerovanie požiadaviek a sledovanie činnosti systému. Každáz týchto vlastností zároveň pridáva vlastnú sadu mikroslužieb. Náš systém je preto vhodné chápať ako konštrukt navzájom prepojených (mikro-)služieb, kde každá z týchto služieb reprezentuje jeden stavebný prvok systému, ktorý je samostatne verzionovateľný a nasaditeľný v rôznych systémoch a prostrediach. Takýto systém prepojených služieb sa nazýva aj [_Service Mesh_](https://en.wikipedia.org/wiki/Service_mesh).

V tejto sekcii si ukážeme ako nasadiť doplňujúce nástroje pre správu _Service Mesh_-u do nášho klastra. Tieto nástroje sa označujú rovnakým názvom - _Service Mesh_,  je dobré v praxi explicitne rozlišovať či pod pojmom _Service_mesh_ máte na mysli softvérový architektonický vzor, alebo konkrétny nástroj na správu systéme. V našom prípade použijeme nástroj  [Linkerd], ktorá je jednou z najpoužívanejších služieb pre správu [_Service Mesh_](https://en.wikipedia.org/wiki/Service_mesh) v klastri Kubernetes. Ďaľšie populárne nástroje sú napríklad [Istio](https://istio.io/latest/) alebo [Open Service Mesh](https://openservicemesh.io/), ale aj ďalšie, ktoré môžete nájsť na stránkach [CNCF Landscape](https://landscape.cncf.io/card-mode?category=service-mesh&grouping=category).

Nástroje typu _Service Mesh_ poskytujú rôzne doplňujúce služby pre systémy založené na mikroslužbách, konkrétny zoznam je závislí od použitého nástroja. Medzi spoločné črty patrí riadenie toku požiadaviek medzi službami, odolnosť voči poruchám, automatické zabezpečenie komunikácie, riadeni prístupu k požiadavkám, či sledovanie systému. V cvičení si ukážeme ako nasadiť nástroj [Linkerd] do nášho klastra a ako pomocou neho zabezpečiť zvýšenú spoľahlivosť systému a zabezpečiť komunikáciu medzi službami. Linkerd nám automaticky poskytne aj sledovanie komunikácie na úrovni toku údajov medzi jednotlivými službami, ktoré doplní naše distribuované trasovanie z predchádzajúcich častí o ďaľšie informácie.

Pri inštalácii [Linkerd] budeme postupovať podľa návodu na stránke [_Installing Linkerd with Helm_](https://linkerd.io/2.14/tasks/install-helm/). 

1. Vytvorte priečinok `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd` a v ňom súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/helm-repository.yaml` s obsahom

   ```yaml
   apiVersion: helm.fluxcd.io/v1
   kind: HelmRepository
   metadata:
     name: linkerd
     namespace: linkerd
   spec:
     interval: 1m
     url: https://helm.linkerd.io/stable
   ```

   Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/crds.helm-release.yaml` s obsahom

   ```yaml
   apiVersion: helm.toolkit.fluxcd.io/v2beta1
   kind: HelmRelease
   metadata:
     name: linkerd-crds
     namespace: linkerd
   spec:
     interval: 1m
     chart:
       spec:
         chart: linkerd-crds
         sourceRef:
           kind: HelmRepository
           name: linkerd
           namespace: linkerd
         interval: 1m
         reconcileStrategy: Revision
     values:
       # we already have Gateway API subsystem installed
       enableHttpRoutes: false
   ```

   Tento súbor zabezpečí [_Custom Resource Definition_](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) pre službu [Linkerd]. Tieto definície rozširujú základnú funkcionalitu Kubernetes o nové objekty, a tým spristupní funkcionalitu nástroja [Linkerd] formou deklaratívnej konfigurácie.

     Tento súbor zabezpečí [_Custom Resource Definition_](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) pre službu [Linkerd]. Tieto definície rozširujú základnú funkcionalitu Kubernetes o nové objekty, a tým spristupní funkcionalitu nástroja [Linkerd] formou deklaratívnej konfigurácie.

   Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/control-plane.helm-release.yaml` s obsahom

   ```yaml
   apiVersion: helm.toolkit.fluxcd.io/v2beta1
   kind: HelmRelease
   metadata:
     name: linkerd-control-plane
     namespace: linkerd
   spec:
     interval: 1m
     dependsOn:  @_important_@
     - name: linkerd-crds @_important_@
     chart:
       spec:
         chart: linkerd-control-plane
         sourceRef:
           kind: HelmRepository
           name: linkerd
           namespace: linkerd
         interval: 1m
         reconcileStrategy: Revision
     values:
        prometheusUrl: http://prometheus-server.wac-hospital
     valuesFrom:
       valuesFrom:
       # identity trust anchor certificate (shared accross clusters)
       - kind: Secret
         name: linkerd-trust-anchor
         valuesKey: tls.crt
         targetPath: identityTrustAnchorsPEM
   ```

   Pri inštalácii služby [Linkerd] je potrebné špecifikovať certifikáty [_certifikačných autorít_](https://en.wikipedia.org/wiki/Certificate_authority), ktoré budú použité na overenie pravosti certifikátov vydávaných službami [Linkerd]. Tieto sú tu špecifikované ako parametre inštalácie.

   Pridajte inštaláciu `jaeger-injector` do súboru `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/jaeger-injector.helm-release.yaml` s obsahom

   ```yaml
   apiVersion: helm.toolkit.fluxcd.io/v2beta1
   kind: HelmRelease
   metadata:
     name: linkerd-jaeger-injector
     namespace: linkerd
   spec:
     interval: 1m
     dependsOn:  
     - name: linkerd-control-plane   @_important_@
     chart:
       spec:
         chart: linkerd-jaeger
         sourceRef:
           kind: HelmRepository
           name: linkerd
           namespace: linkerd
         interval: 1m
         reconcileStrategy: Revision
     values:
       # we already have Jaeger collector, installing only jaeger injector webhook
       # to ensure linkerd proxies are configured to send traces to existing collector
       collector:
         enabled: false   @_important_@
       jaeger:
         enabled: false   @_important_@
       webhook:
         collectorSvcAddr: "jaeger-collector.wac-hospital:14268"
         collectorSvcName: jaeger-collector.wac-hospital
   ```

   Touto konfiguráciou zabezpečíme aby [Linkerd] proxy boli nakonfigurované na odosielanie rozsahu výpočtu -  _span_ - do služby [Jaeger], ktorú sme nainštalovali v predchádzajúcej časti.

   >info:> V cvičení sme mohli postupovať aj spôsobom. kedy by sme do klastra pridali inštaláciu [Linkerd] a využívali poskytnuté črty ako [Gateway API], metriky, a distribuované trasovanie. Z didaktických dôvodov sme ale zvolili postupné pridávanie jednotlivých čŕt s vysvetlením ich prínosov k celkovému syystému a pochopeniu ich funkcionality ako samostatných celkov. V praxi je ale možné postupovať aj opačne a nasadiť primárne niektorý z nástrojov typu _Service Mesh_, ktorý poskytbe všetky tieto črty ako súčasť inštalácie.

   Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/namespace.yaml` s obsahom

   ```yaml
   ApiVersion: v1
   kind: Namespace
   metadata:
    name: linkerd
   ```

   a integrujte manifesty v súbore `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/kustomization.yaml` 

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization    

    namespace: linkerd    

    resources:
    - namespace.yaml
    - helm-repository.yaml
    - crds.helm-release.yaml
    - control-plane.helm-release.yaml
    - jaeger-injector.helm-release.yaml
   ```

2. Pred nasadením [linkerd] do klastra musíme vytvoriť samotné certifikáty pre objekt  `linkerd-trust-anchor`. Tento certikát [_certifikačnej autority_](https://en.wikipedia.org/wiki/Certificate_authority) bude slúžiť na overenie pravosti identít požiadaviek pri komunikácii medzi rôznymi klastrami. V produkčnom prostredí takyto certifikát _intermediary CA_ získate z oddelenia kybernetickej bezpečnosti Vašej organizácia, tu si vygenerujeme vlastný pár certifikátov pre náš vývojový server. Nainštalujte nástroj _step CLI_ podľa návodu na stránke [smallstep -  Install step](https://smallstep.com/docs/step-cli/installation/#windows). Napríklad, otvorte okno v priečinku mimo Vášho repozitára a vykonajte príkazy

   ```ps
   curl.exe -LO https://dl.smallstep.com/cli/docs-cli-install/latest/step_windows_amd64.zip
   Expand-Archive -LiteralPath .\step_windows_amd64.zip -DestinationPath .
   step_windows_amd64\bin\step.exe version
   $env:PATH += ";$pwd\step_windows_amd64\bin"
   ```

   >info:> Návod na inštaláciu nástroja _step CLI_ pre iné platformy nájdete na stránke [smallstep -  Install step](https://smallstep.com/docs/step-cli/installation/).

   V okne príkazového riadku prejdite do priečinku  `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/params` vygenerujte certifikát globálnej [_certifikačnej autority_](https://en.wikipedia.org/wiki/Certificate_authority), pomocou nasledujúceho príkazu.

   ```ps
   step certificate create root.linkerd.cluster.local linkerd-ca.crt linkerd-ca.key --profile root-ca --no-password --insecure
   ```

   Pokiaľ používate [_Správu prihlasovacích údajov pomocou SecretsOps](./050-secrets-ops.md), zakryptujte vytvorené certifikáty príkazmi

   ```ps
   sops --encrypt --in-place ./linkerd-ca.crt
   sops --encrypt --in-place ./linkerd-ca.key
   ```

   Pokiaľ _SecretOps_ nepoužívate, zabezpečte aby tieto súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/params/linkerd-issuer.key` nebol archivovaný do repozitára git - upravte súbor `.gitignore`.

   Upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/kustomization.yaml` a pridajte do neho

   ```yaml
   ...   
   secretGenerator:
     ...    
     - name: linkerd-trust-anchor    @_add_@
       type: kubernetes.io/tls    @_add_@
       options:    @_add_@
           disableNameSuffixHash: true    @_add_@
       files:    @_add_@
       - tls.crt=params/linkerd-ca.crt    @_add_@
       - tls.key=params/linkerd-ca.key    @_add_@
   ```

   Okrem tohto certifikátu [_certifikačnej autority_](https://en.wikipedia.org/wiki/Certificate_authority) je potrebné vytvoriť aj certifikát pre lokálnu [_certifikačnú autoritu_](https://en.wikipedia.org/wiki/Certificate_authority) pre službu [Linkerd], ktorá bude vydávať samotné certifikáty pre jednotlivé služby (_linkerd-proxy_) v rámci nášho klastra. V tomto prípade využijeme už nainštalovanú službu [cert-manager], ktorá nám zabezpečí vytvorenie certifikátu pre intermediary [_certifikačnú autoritu_](https://en.wikipedia.org/wiki/Certificate_authority) overeného certifikátom uloženom v objekte `linkerd-trust-anchor`. Výhodou použitia služby [cert-manager] je, že nám automaticky obnoví certifikát v prípade jeho expirácie a jeho platnosť môže byť krátko dobá, čím sa zvýši bezpečnosť systému.

   >info:> Objekt `linkerd-trust-anchor` by bolo možné tiež vytvoriť pomocou služby [cert-manager], podobne ako sme to urobili v kapitole [Bezpečné pripojenie k aplikácii protokolom HTTPS](./040-secure-connection.md), to by však nezodpovedalo skutočnosti, že tento certifikát má byť použitý na overenie identity medzi rôznymi klastrami

   Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/control-plane.issuer.yaml` s obsahom
  
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: Issuer
   metadata:
     name: linkerd-trust-anchor
     namespace: linkerd
   spec:
     ca:
       secretName: linkerd-trust-anchor   @_important_@
   ```

   a súbor `${WAC_ROOT}/ambulance-gitops/infrastructure/linkerd/control-plane.certificate.yaml` s obsahom

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: linkerd-identity-issuer 
   spec:
     secretName: linkerd-identity-issuer @_important_@
     duration: 48h
     renewBefore: 25h
     issuerRef:
       name: linkerd-trust-anchor  @_important_@
       kind: Issuer
     commonName: identity.linkerd.cluster.local @_important_@
     dnsNames:
     - identity.linkerd.cluster.local
     isCA: true @_important_@
     privateKey:
       algorithm: ECDSA
     usages:
     - cert sign
     - crl sign
     - server auth
     - client auth
   ```

3. Upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/prepare/kustomization.yaml` a pridajte do neho

   ```yaml
   ...
   resources:
   ...
   - ../../../infrastructure/linkerd   @_add_@

   patches: 
   ...
   ```

4. Uložte zmenené súbory a archivujte zmeny do vzdialeného repozitára

   ```ps
   git add .
   git commit -m "Add linkerd"
   git push
   ```

Počkajte kým sa zmeny prejavia v klastri a následne overte správnosť inštalácie  príkazmi

```ps
kubectl get helmreleases -n linkerd
kubectl get pods -n linkerd
```
