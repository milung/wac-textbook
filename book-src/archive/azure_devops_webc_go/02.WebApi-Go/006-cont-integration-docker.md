## Automatická priebežná integrácia (_Continuous Integration, CI_)

V tejto kapitole využijeme [Azure Pipelines] na automatizáciu integrácie našej webovej služby. V kontexte našej webovej služby bude automatická integrácia zahŕňať:

* Nainštalovanie správnej verzie jazyka Go,
* zostavenie (_build_) aplikácie,
* spustenie testov,
* zostavenie docker image,
* publikovanie docker image na službu [Docker Hub].

Všimnite si, že priebežná integrácia v sebe nezahŕňa nasadenie (deployment) webovej služby.

### Servisné pripojenie

Pri implementácie webového kontajnera sme vytvorili servisné pripojenie na náš Docker Hub účet nazvaný `Docker Hub Registry` (pozri kapitolu [Polo-automatické nasadenie (automatická aktualizácia docker obrazu z dockerhub)](../01.Web-Components/dojo/005-docker-azure-update-from-dockerhub.md).

### CI pipeline

Nakonfigurujeme CI pipeline s použitím Azure Pipelines. Prihláste sa do svojho účtu v [Microsoft Azure DevOps Services][azure-devops] a prejdite do projektu _WebCloud-<vaše priezvisko>_. V ľavom paneli kliknite na _Pipelines -> Pipelines_ a následne na _New Pipeline_.

>info:> Podobne ako v prípade Web komponentu v prvej časti, aj tu použijeme YAML. (Pozn. Pre tých, čo majú radšej pôvodný spôsob, je stále možnosť použiť klasický editor: Dole kliknite na _Use the classic editor_).

Zvoľte možnosť _Azure Repos Git YAML_, ako repozitár zvoľte _ambulance-webapi_ a v ďalšom kroku ako šablónu (_template_) zvoľte _Starter pipeline_. Bude vygenerovaný jednoduchý yaml template.

Rovnako ako v prípade prvej pipeliny pre SPA aj tu bude pipeline obsahovať iba jeden _stage_ a jeden _job_, čiže by sme ich mohli definície vynechať a rovno písať _steps_. Ale teraz si ukážeme ako vyzerá pipeline aj s nimi.

Najprv premenujte pipeline na `ambulance-webapi-CI.yaml`.

1. Vymažte celý obsah pipeliny a vypíšte jej začiatok, zatiaľ bez stepov:

    ```yaml
    trigger:
    - main

    stages:
    - stage: BuildAndPublish
      displayName: Build and Publish docker image
      jobs:  
      - job: BuildAndPublish
        displayName: Build and Publish docker image
        pool:
          vmImage: 'ubuntu-20.04'
        steps:
    ```

   CI trigger je nastavený na hlavnú vetvu `main`. Definujeme si jednu _stage_ s jedným _jobom_. _Agent pool_ pre build job sme nastavili na `ubuntu-20.04`. Podobne ako v prípade prvej pipeline možeme použiť aj build agentov s windows systémom `windows-2019`, ktoré sú ale pomalšie.

2. Kliknite na _Show asisstant_ vpravo hore. Vyroluje sa nám zoznam preddefinovaných taskov, ktoré nám uľahčia tvorbu pipeliny.

3. V editore pipeline yaml umiestnite kurzor na nový riadok, za riadkom `steps`. V task assistante vyhľadajte úlohu typu `Go tool installer`, v poli _Version_ napíšte vašu aktuálnu verziu Go (v čase písania skrípt `1.19.4`).  Pridajte task do yaml a pomenujte ho `Use Go version 1.19.4`.

    ```yaml
     - task: GoTool@0
       displayName: Use Go version 1.19.4
       inputs:
         version: '1.19.4'
    ```

4. Vložte ďalšiu úlohu typu _Go_, v poli _Command_ zvoľte voľbu `build`, v časti _Advanced_ do poľa _Working Directory_ vložte `$(System.DefaultWorkingDirectory)`. Pridajte task do yaml a pomenujte ho `Build Go project`.

    ```yaml
     - task: Go@0
       displayName: Build Go project
       inputs:
         command: 'build'
         workingDirectory: '$(System.DefaultWorkingDirectory)'
    ```
 
    >info:> Poznámka:Všimnite si, že nepotrebujeme explicitný krok na stiahnutie a nainštalovanie závislostí. Príkaz `go build` si nainštaluje chýbajúce závislosti sám, ak mu chýbajú.

5. Po builde môžeme spustiť testy. Vložte ďalšiu úlohu typu _Go_, v poli _Command_ zvoľte možnosť `test`, v poli _Arguments_ zadajte `./...`, v časti _Advanced_ do poľa _Working Directory_ vložte `$(System.DefaultWorkingDirectory)`. Pridajte task do yaml a pomenujte ho `Run the tests`.

    ```yaml
     - task: Go@0
       displayName: Run the tests
       inputs:
         command: 'test'
         arguments: './...'
         workingDirectory: '$(System.DefaultWorkingDirectory)'
    ```

6. Doteraz sme si overili, že je aplikácia buildovateľná a že sú testy zelené. Ak áno, môžeme vytvoriť docker image a nahrať ho na Docker Hub. Vložte úlohu typu _Docker_. Vyplňte ju nasledovne:
   * _Container Registry_ : **Docker Hub Registry**
   * _Container repository_ : **<VASE_DOCKERHUB_ID>/ambulance-webapi**
   * _Command_ : **build**
   * _Docker File_ : **Dockerfile**
   * _Tags_ :  
          **1.0.0-$(Build.BuildId)**  
          **latest**  
          **dev-latest**
  
   Pridajte úlohu do yaml a nazvite ju `Docker build`.

    ```yaml
     - task: Docker@2
       displayName: Docker build
       inputs:
         containerRegistry: 'Docker Hub Registry'
         repository: '<VASE_DOCKERHUB_ID>/ambulance-webapi'
         command: 'build'
         Dockerfile: 'Dockerfile'
         tags: |
           1.0.0-$(Build.BuildId)
           latest
           dev-latest
    ```

7. Pridajte poslednú úlohu typu _Docker_. Vyplňte ju nasledovne:
   * _Container Registry_ : `Docker Hub Registry`
   * _Container repository_ : `<VASE_DOCKERHUB_ID>/ambulance-webapi`
   * _Command_ : `push`
   * _Tags_ :  
          `1.0.0-$(Build.BuildId)`  
          `latest`  
          `dev-latest`
  
   Pridajte úlohu do yaml a nazvite ju `Docker push`.

    ```yaml
     - task: Docker@2
       displayName: Docker push
       inputs:
         containerRegistry: 'Docker Hub Registry'
         repository: '<VASE_DOCKERHUB_ID>/ambulance-webapi'
         command: 'push'
         tags: |
           1.0.0-$(Build.BuildId)
           latest
           dev-latest
    ```

   Kompletné yaml je uvedené nižšie.

8. Stlačte tlačidlo _Save & run_ a overte, že táto zostava prebehne úspešne.

>build_circle:> Ak pri builde dostanete error _No hosted parallelism has been purchased
> or granted. To request a free parallelism grant, please fill out the
> following form https://aka.ms/azpipelines-parallelism-request_, znamená to, že
> musíte Microsoft požiadať o pridelenie grantu na využívanie voľných build
> agentov. Vyplňte a pošlite formulár na danej stránke. Viac detailov tu:
> https://devblogs.microsoft.com/devops/change-in-azure-pipelines-grant-for-private-projects/

Máme hotovú CI pipeline pre webapi projekt, pri každej novej verzii repozitára (_commit_) sa zostava spustí a mailom nás bude informovať o úspechu či neúspechu buildu.

>info:> Zostavu, a teda aj yaml súbor, sme vytvorili na main vetve v repozitári na devops stránke. Nezabudnite si zmeny synchronizovať do lokálneho repozitára na počítač.

### Kompletné yaml pre webapi CI pipeline

```yaml
trigger:
- main

stages:
- stage: BuildAndPublish
  displayName: Build and Publish docker image
  jobs:  
  - job: BuildAndPublish
    displayName: Build and Publish docker image
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: GoTool@0
      displayName: Use Go version 1.17.5
      inputs:
        version: '1.17.5'
    - task: Go@0
      displayName: Build Go project
      inputs:
        command: 'build'
        workingDirectory: '$(System.DefaultWorkingDirectory)'
    - task: Go@0
      displayName: Run the tests
      inputs:
        command: 'test'
        arguments: './...'
        workingDirectory: '$(System.DefaultWorkingDirectory)'
    - task: Docker@2
      displayName: Docker build
      inputs:
        containerRegistry: 'Docker Hub Registry'
        repository: '<VASE_DOCKERHUB_ID>/ambulance-webapi'
        command: 'build'
        Dockerfile: 'Dockerfile'
        tags: |
          1.0.0-$(Build.BuildId)
          latest
          dev-latest
    - task: Docker@2
      displayName: Docker push
      inputs:
        containerRegistry: 'Docker Hub Registry'
        repository: '<VASE_DOCKERHUB_ID>/ambulance-webapi'
        command: 'push'
        tags: |
          1.0.0-$(Build.BuildId)
          latest
          dev-latest
```
