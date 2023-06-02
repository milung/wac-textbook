# Obnova lokálneho klastra v novom prostredí

V niektorých prípadoch sa môže stať, že potrebujete nanovo nasadiť Vašu lokálnu konfiguráciu. Napríklad pri reinštalácii počítača, zlyhanie subsystému Docker Desktop, alebo pri neopraviteľných zmenách v lokálnom klastri. V takom prípade môžete využit konfigurácie v priečinku `.../webcloud-gitops/flux-system`.

1. Vytvorte súbor `.../webcloud-gitops/flux-system/kustomization.yaml` s nasledujúcim obsahom:

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
    ```

2. Vytvorte súbor `.../webcloud-gitops/flux-system/.secrets/kustomization.yaml` s nasledujúcim obsahom:

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: flux-system
    
    secretGenerator:
     - name: ambulance-gitops-repo
       type: Opaque
       literals:
         - username=<váš webcloud-gitops account name>
         - password=<váš Personal Access Token pre  webcloud-gitops repozitár>
       options:
         disableNameSuffixHash: true
    ```

    >info:> Tento súbor zodpovedá súboru, ktorý vytvorí flux pri použití príkazu na vytvorenie git zdroja (použitý v kapitole Flux).

    >info:> Pridajte adresár `.secrets` do súboru `.gitignore` aby ste zabránili zdieľaniu Vášich PAT

3. Následne môžete kedykoľvek obnoviť Váš lokálny klaster pomocou príkazu v priečinku `.../webcloud-gitops`

    ```sh
    kubectl apply -k ./flux-system
    ```

    >info:> Samotné nasadenie zvyšku konfigurácie vykoná flux systém
   
    >build_circle:> Ak počas nasadenia vidíte error hovoriaci o neexistujucom namespace chvílu počkajte a znova použite príkaz apply.

    >build_circle:> V prípade že po obnovení je niečo v stave pending alebo padá reštartujte docker.

4. Archivujte zmeny a synchronizujte so vzdialeným repozitárom.
