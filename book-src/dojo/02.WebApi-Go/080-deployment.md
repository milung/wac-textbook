# Nasadenie webapi na lokálny klaster

---

```ps
devcontainer templates apply -t registry-1.docker.io/milung/wac-api-080
```

---

Ďalším krokom je nasadenie pripravených manifestov do lokálneho klastra. Tentokrát využijeme manifesty ktoré sme pripravili v predchádzajúcom cvičení.

>info:> Pamätajte, že [konfigurácia aplikácie má byť oddelená od zdrojového kódu aplikácie](https://12factor.net/build-release-run). Manifesty v repozitári `ambulance-webapi` sú preto len odporučeným predpisom, nie súčasťou konfigurácie Vášho systému. V typických prípadoch tento predpis môže byť vhodný, pri iných prípadoch je potrebné ho upraviť. Tento príklad slúži i len ako ukážka možností konfigurácie jednotlivých komponentov s využitím distribuovaných repozítarov.

1. Otvorte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-webapi/kustomization.yaml` a vložte do neho nasledujúci obsah - upravte názov repozitára podľa toho, ako ste ho nazvali:

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization

   resources:
   - 'https://github.com/<your-account>/ambulance-webapi//deployments/kustomize/install' # ?ref=v1.0.1
   ```

   >info:> Dva po sebe idúce znaky `//` oddeľujú URL repozitára od cesty k repozitáru. Pokiaľ by ste chceli získať konkrétnu verziu - git tag allebo commit - pridajte za na koniec URL  `?ref=<tag>`.

2. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/install/patches/ambulance-webapi.service.yaml` s nasledujúcim obsahom:

   ```yaml
   kind: Service
   apiVersion: v1
   metadata:
   name: pfx-ambulance-webapi
   spec:  
   ports:
   - name: http
     protocol: TCP

     type: NodePort
     nodePort: 30081
   ```

   Tento súbor upraví definíciu služby tak, aby bola dostupná z lokálnej siete na porte `30081`.

3. Otvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/install/kustomization.yaml` a vložte do neho nasledujúci obsah:

   ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    ...

    resources:
    - ../../../apps/<pfx>-ambulance-ufe
    - ../../../apps/<pfx>-ambulance-webapi @_add_@

    components: 
    - ../../../components/version-developers
    - https://github.com/<your-account>/ambulance-webapi//deployments/kustomize/components/mongodb @_add_@

    patches: @_add_@
    - path: patches/ambulance-webapi.service.yaml @_add_@
   ```

   Pretože v našom lokálnom klastri máme len jednu službu využívajúcu [MongoDB], aplikuje priamo manifesty uvedené v repozítary `ambulance-gitops`. Pri spoločnom klastri, alebo v prípade viacerých služieb využívajúcich [MongoDB] budeme postupovať odlišne, a manifesty v repozitári  `ambulance-webapi` nám poslúžia len ako príklad konfigurácie.

4. Otvorte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-ufe/webcomponent.yaml` a upravte atribút `api-base`:

   ```yaml
   ...
   spec:   
     ...
     navigation:
       - element: pfx-ambulance-wl-app    
       ...
         attributes:
           - name: api-base
             value: http://localhost:30081/api @_add_@
           ...
   ```

   Týmto sme nášmu mikro frontendu povedali, že má komunikovať s webapi na porte `30081`.

5. V tomto kroku pripravíme manifesty pre sledovanie zmien v registry kontainerov. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/gitops/ambulance-webapi.image-repository.yaml`:

   ```yaml
   apiVersion: image.toolkit.fluxcd.io/v1beta2
   kind: ImageRepository
   metadata:
     name: ambulance-webapi
     namespace: wac-hospital
   spec:
     image: <github-id>/ambulance-wl-webapi
     interval: 1m0s
   ```

   Ďalej vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/gitops/ambulance-webapi.image-policy.yaml`:

   ```yaml
   apiVersion: image.toolkit.fluxcd.io/v1beta1
   kind: ImagePolicy
   metadata:
     name: ambulance-webapi
     namespace: wac-hospital
   spec:
     imageRepositoryRef:
       name: ambulance-webapi # referuje ImageRepository z predchádzajúceho kroku 
     filterTags:
       pattern: "main.*" # vyberie všetky verzie, ktoré začínajú na main- (napr. main-20240315.1200)
     policy:
       alphabetical:
         order: asc
   ```

   Upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/gitops/kustomization.yaml`:

   ```yaml
   ...
   resources:
   ..
   - ambulance-ufe.image-repository.yaml
   - ambulance-ufe.image-policy.yaml
   - ambulance-webapi.image-repository.yaml @_add_@
   - ambulance-webapi.image-policy.yaml @_add_@
   ...
   ```

   a nakoniec upravte súbor `${WAC_ROOT}/ambulance-gitops/components/version-developers/kustomization.yaml`:

   ```yaml
   images:
   - name: <docker-id>/ambulance-wl-webapi @_add_@
     newName: <docker-id>/ambulance-wl-webapi # {"$imagepolicy":  "wac-hospital:ambulance-webapi:name"} @_add_@
     newTag: main # {"$imagepolicy": "wac-hospital:ambulance-webapi:tag"} @_add_@
  
   ...
   ```

6. Ďalej upravte atribúty web componentu aby sa pokúsil pripojiť k nasadenému webapi. Otvorte súbor `${WAC_ROOT}/ambulance-gitops/apps/<pfx>-ambulance-ufe/webcomponent.yaml` a upravte ho:

    ```yaml
    ...
    spec:   
      ...
      navigation:
        - element: pfx-ambulance-wl-app    
        ...
          attributes:  @_add_@
            - name: api-base  @_add_@
              value: http://localhost:30081/api @_add_@
            - name: ambulance-id 
              value: bobulova 
            ...
    ```
  
    Týmto sme nášmu mikro frontendu povedali, že má komunikovať s webapi na porte `30081`.

7. Otvorte okno príkazového riadku v adresári ``${WAC_ROOT}/ambulance-gitops` a overte správnosť konfigurácie príkazom:

   ```ps
   kustomize build clusters/localhost/install
   ```

   Výstupom by mali byť manifesty pre nasadenie aplikácie bez chybovej správy.

8. Uložte zmeny do git repozitára a odovzdajte ich do vzdialeného repozitára.

   ```ps
   git add .
   git commit -m 'added webapi to localhost cluster'
   git push
   ```

   Overte, že sú Vaše zmeny aplikované v klastri príkazom:

   ```ps
    kubectl get pods  -n wac
    ```

9. V prehliadači otvorte stránku [http://localhost:30331](http://localhost:30331), na ktorej uvidíte aplikačnú obálku s integrovanou mikro aplikáciou. Mikro aplikácia sa pokúsi načítať dáta z webapi, ktoré však zatiaľ neexistujú. Vytvorte ich pomocou zobrazeného rozhrania. Skuste reštartovať Váš klaster a overte, že dáta sú stále dostupné.

<hr/>

Týmto krokom máme front-end aj webapi nasadené v lokálnom klastri. Nevýhodou tohto nasadenia je, že tieto služby sú dostupné na rôznych portoch, čo z pohľadu prehliadača je považované za rôzne inštancie servera. Navyše by tento prístup bol problematický pri nasadení na verejne URL, pretože väčšina sietí implicitne blokuje HTTP prístup na porty mimo portov 80 a 443. V ďalšej časti si vysvetlíme ako tento problém vyriešiť a zostaviť z jednotlivých mikroslužieb takzvaný [Service Mesh], ktorý vo výsledku bude tvoriť jeden konzistentný celok aj z pohľadu používateľa.
