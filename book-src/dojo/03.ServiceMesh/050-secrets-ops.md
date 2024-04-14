# Správa prihlasovacích údajov pomocou SecretsOps

---

>info:>
Šablóna pre predvytvorený kontajner ([Detaily tu](../99.Problems-Resolutions/01.development-containers.md)):
`registry-1.docker.io/milung/wac-mesh-050`

---

Pred tým, než pristúpime k autentifikácii používateľov, si pripravíme spôsob, ako bezpečne nasadiť citlivé informácie do nášho kubernetes klastra. V našom prípade sa zatiaľ jedná o prihlasovacie údaje do databázy a o _Personal Access Token_ k repozitáru. S tým, ako budú pribúdať citlivé údaje, je ich správa na lokálnom disku bez archivácie čoraz menej efektívna. Riešením je pre nás použitie metódy [_Secrets Ops_][sops]. Ich princíp spočíva v použití asymetrických kľúčov na šifrovanie citlivých informácií pomocou verejného kľúča a schopnosť ich rozšifrovania len pri použití súkromného kľúča. Súkromný kľúč je ručne uložený na príslušný klaster. Verejný kľúč a zašifrované údaje potom môžme bezpečne uložiť a archivovať v našom repozitári. Zároveň využijeme zabudovanú vlastnosť [Flux CD](https://fluxcd.io/flux/guides/mozilla-sops/), ktorá umožňuje, aby Flux automaticky dešifroval tieto údaje pri ich nasadení do klastra.

1. K využitiu tejto techniky potrebujete mať nainštalované nástroje [sops] zo stránky [https://github.com/getsops/sops/releases](https://github.com/getsops/sops/releases). V tomto cvičení budeme ako šifrovací nástroj používať [AGE], ktorý si môžete nainštalovať zo stránky [https://github.com/FiloSottile/age/releases/tag/v1.1.1](https://github.com/FiloSottile/age/releases). Oba nástroje sa dajú nainštalovať aj pomocou správcu balíčku [Chocolatey]. Nástroj [AGE] možno nainštalovať príkazom `apt-get` na systémoch linux.

   >info:> Nástroj [sops] podporuje aj iné spôsoby šifrovania a ukladania kľúčov, napríklad pomocou [GPG](https://www.gnupg.org/) alebo [Azure KeyVault](https://learn.microsoft.com/en-us/azure/key-vault/general/) a podobne. V závislosti od cieľových požiadavok môžete použiť iný nástroj na šifrovanie, postup bude vo všetkých prípadoch obdobný, až na konfiguráciu sops parametrov.

2. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/params/repository-pat.env` s obsahom zodpovedajúcim Vášmu _Personal Access Token_ k repozitáru. Tieto údaje by ste mali mať v súbore `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/repository-pat.yaml`. Obsah súboru `repository-pat.env` by mal vyzerať nasledovne:

   ```env
   username=<github-id>
   password=<your-pat> @_important_@
   ```

   >info:>  _Personal Access Token_ podľa [návodu](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) alebo podľa postupu v kapitole [Kontinuálne nasadenie pomocou nástroja Flux](../01.Web-Components/081-flux.md).

   Zmažte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/repository-pat.yaml` a upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/kustomization.yaml` tak, aby obsahoval:

   ```yaml
   ...
   resources: @_remove_@
     - repository-pat.yaml  @_remove_@
   
   secretGenerator:        @_add_@
     - name: repository-pat        @_add_@
       type: Opaque        @_add_@
       envs:       @_add_@
         - params/repository-pat.env       @_add_@
       options:        @_add_@
           disableNameSuffixHash: true     @_add_@
   ```

3. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/params/mongodb-auth.env` s obsahom:

   ```env
   username=admin
   password=<silne-heslo> @_important_@
   ```

   >warning:> Pri zmene hesla je možné, že budete musieť v klastri vymazať pôvodný _Persistent Volume Claim_ - Mongo DB si inicializačné heslo totiž ukladá na disk a pri následnom štarte ignoruje heslo nastavené v premennej prostredia. Pre ukážku odporúčame použiť pôvodné heslo.

   Upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/kustomization.yaml` a pridajte:

   ```yaml
   ...
   secretGenerator:
     - name: repository-pat
       ...
     - name: mongodb-auth    @_add_@
       type: Opaque    @_add_@
       envs:    @_add_@
         - params/mongodb-auth.env    @_add_@
       options:    @_add_@
        disableNameSuffixHash: true    @_add_@
   ```

   Teraz ešte musíme zmazať pôvodný objekt `mongodb-auth`, ktorý je pridaný do konfigurácie spolu s mongodb. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/install/patches/mongodb-auth.secret.yaml` s obsahom:

   ```yaml
   $patch: delete  @_important_@
   apiVersion: v1
   kind: Secret
   metadata:
     name: mongodb-auth
   ```

   a upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/install/kustomization.yaml`:

   ```yaml
   ...
   patches:
     - path: patches/ambulance-webapi.service.yaml
     - path: patches/mongodb-auth.secret.yaml   @_add_@
   ```

4. Vygenerujte si nový pár šifrovacích kľúčov pomocou príkazu:

   ```ps
   age-keygen
   ```

   Výstup príkazu bude vyzerať asi takto:

   ```ps
   # created: 2024-01-01T00:00:00Z
   # public key: age_verejny_hexa_kluc
   AGE-SECRET-KEY-sukromny_hexa_kluc
   ```

   Skopírujte a uchovajte na bezpečnom mieste súkromný kľúč - budete ho potrebovať aj v prípadoch, keď budete chcieť opätovne nasadiť Váš klaster. Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/params/.sops.yaml` s obsahom:

   ```yaml
   creation_rules:
   - age: age_verejny_hexa_kluc 
   ```

   Tento súbor slúži na šifrovanie kľúčov uložených v tomto adresári.

   >warning:> Každý klaster môže mať asociovaný jeden alebo viac šifrovacích kľúčov, tieto kľúče ale z bezpečnostných dôvodov nesmú byť zdieľané medzi rôznymi klastrami. Azda jedinú výnimku tvorí prípad, kedy zdieľate privátny kľúč medzi vývojármi produktu tak, aby si mohli všetci vývojári nasadiť vlastný lokálny klaster, v ktorom sa predpokladá len prítomnosť testovacích údajov.
   >
   > Z rovnakého dôvodu vytvárame všetky objekty typu _Secret_ nezávisle pre každý klaster a ich aktuálne hodnoty by sa mali odlišovať t.j jedinečné heslo, meno používateľa alebo klientský identifikátor.

   Aplikujte súkromný kľúč do klastra pomocou príkazu:

   ```ps
   $agekey="AGE-SECRET-KEY-sukromny_hexa_kluc" @_important_@
   kubectl create secret generic sops-age --namespace wac-hospital --from-literal=age.agekey="$agekey"
   ```

   >warning:> Tento krok budete musieť odteraz vykonať vždy pred prvým nasadením Flux CD.

   Vytvorte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/gitops/secrets.kustomization.yaml` s obsahom:

   ```yaml
   apiVersion: kustomize.toolkit.fluxcd.io/v1
   kind: Kustomization
   metadata:
     name: secrets
     namespace: wac-hospital
   spec:
     wait: true
     interval: 42s
     path: clusters/localhost/secrets
     prune: true
     sourceRef:
       kind: GitRepository
       name: gitops-repo
    ```

   a upravte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/gitops/kustomization.yaml`:

```yaml
  ...
  resources:
  - prepare.kustomization.yaml
  - cd.kustomization.yaml
  - install.kustomization.yaml
  - secrets.kustomization.yaml   @_add_@
  ...

  patches:    @_add_@
  - target:    @_add_@
      group: kustomize.toolkit.fluxcd.io    @_add_@
      version: v1    @_add_@
      kind: Kustomization    @_add_@
    patch: |-    @_add_@
      - op: add @_add_@
        path: /spec/decryption @_add_@
        value: @_add_@
          provider: sops @_add_@
          secretRef: @_add_@
            name: sops-age @_add_@
```

   Táto úprava pridá do všetkých objektov typu [_Kustomization_](https://fluxcd.io/flux/components/kustomize/kustomizations/) konfiguráciu pre dešifrovanie súborov pomocou nástroja [sops] s použitím nami vytvoreného objektu [_Secret_](https://kubernetes.io/docs/concepts/configuration/secret/) `sops-age`. Navyše sme pridali automatizáciu pre nasadenie citlivých údajov do klastra, čo sme doteraz museli vykonávať manuálne.

5. Zašifrujte súbory s citlivými údajmi. Otvorte okno príkazového riadku v adresári `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/params` a vykonajte príkazy:

   ```ps
   sops --encrypt --in-place repository-pat.env
   sops --encrypt --in-place mongodb-auth.env
   ```

   Pokiaľ teraz otvoríte súbory `repository-pat.env` a `mongodb-auth.env`, uvidíte, že ich obsah je zašifrovaný. Pridané premenné umožňujú identifikovať, ktorým kľúčom a verziou nástroja [sops] boli zašifrované.

6. Zmažte súbor `${WAC_ROOT}/ambulance-gitops/clusters/localhost/secrets/.gitignore`. Archivujte zmeny a odovzdajte ich do vzdialeného repozitára. V priečinku `${WAC_ROOT}/ambulance-gitops` vykonajte príkazy:

   ```ps
   git add .
   git commit -m "SecretsOps"
   git push
   ```

7. Overte, či sú naše objekty typu [Kustomization](https://fluxcd.io/flux/components/kustomize/kustomizations/) správne nasadené:

   ```ps
   kubectl get kustomization -n wac-hospital
   ```

Odteraz možeme vykonať zmenu v súboroch s citlivými údajmi a po ich zašifrovaní a odovzdaní do repozitára budú automaticky nasadené do klastra. V prípade opätovného nasadenia nám postačuje nasadiť len súkromný kľúč, ktorý sme si uložili na bezpečné miesto. Pri prvom nasadení na prázdny klaster musíme nasadiť aj nezašifrovaný objekt `repository-pat`, aby bol FluxCD schopný stiahnuť zdrojový kód z repozitára. Všetky ostatné citlivé údaje už ale môžeme udržiavať v šifrovanej podobe priamo v repozitári, medzi nimi aj `repository-pat` a teoreticky aj _Secret_ `sops-age`, tu to však nedoporučujeme z dôvodu, že môže obsahovať rôzne kategórie kľúčov.

>warning:> Pri tímovej práci sa môže stať, že niektorý člen tímu nechtiac archivuje aj nezašifrované heslá. V takom prípade je nutné vykonať zmenu prihlasovacích údajov. Tiež odporúčame v repozitári implementovať vhodný [_pre-commit hook_](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), ktorý zabráni odovzdaniu nezašifrovaných súborov do repozitára.

## Automatizácia nasadenia do klastra pre vývojárov

Pre informáciu tu uvádzam skript, ktorý môžete použiť pre automatizovanie nasadenia do prázdneho klastra pre vývojárov. Tento skript predpokladá, že členovia tímu zdieľajú privátny kľuč pre nasadenia do lokálneho klastra. Skript automatizuje nasadenie zdroja `sops-age` a `repository-pat`, následné nasadenie Flux CD a nasadenie objektov _kustomization_ pri vytvorení alebo obnove lokálneho klastra. Script môžete uložiť napríklad do súboru `${WAC_ROOT}/ambulance-gitops/scripts/developer-deploy.ps1`:

```ps
param (
    $cluster ,
    $namespace,
    $installFlux = $true
)

if ( -not $cluster ) {
    $cluster = "localhost"
}

if ( -not $namespace ) {
    $namespace = "wac-hospital"
}

$ProjectRoot = "${PSScriptRoot}/.."
echo "ScriptRoot is $PSScriptRoot"
echo "ProjectRoot is $ProjectRoot"

$clusterRoot = "$ProjectRoot/clusters/$cluster"


$ErrorActionPreference = "Stop"

$context = kubectl config current-context

if ((Get-Host).version.major -lt 7 ){
    Write-Host -Foreground red "PowerShell Version must be minimum of 7, please install latest version of PowerShell. Current Version is $((Get-Host).version)"
    exit -10
}
$pwsv=$((Get-Host).version)
try {if(Get-Command sops){$sopsVersion=$(sops -v)}} 
Catch {
    Write-Host -Foreground red "sops CLI must be installed, use 'choco install sops' to install it before continuing."
    exit -11
}

# check if $cluster folder exists
if (-not (Test-Path -Path "$clusterRoot" -PathType Container)) {
    Write-Host -Foreground red "Cluster folder $cluster does not exist"
    exit -12
}

$banner = @"
THIS IS A FAST DEPLOYMENT SCRIPT FOR DEVELOPERS!
---

The script shall be running **only on fresh local cluster** **!
After initialization, it **uses gitops** controlled by installed flux cd controller.
To do some local fine tuning get familiar with flux, kustomize, and kubernetes

Verify that your context is coresponding to your local development cluster:

* Your kubectl *context* is **$context**.
* You are installing *cluster* **$cluster**.
* *PowerShell* version is **$pwsv**.
* *Mozilaa SOPS* version is **$sopsVersion**.
* You got *private SOPS key* for development setup.
"@
    
$banner = ($banner | ConvertFrom-MarkDown -AsVt100EncodedString) 
Show-Markdown -InputObject $banner
Write-Host "$banner"
$correct = Read-Host "Are you sure to continue? (y/n)"

if ($correct -ne 'y')
{
    Write-Host -Foreground red "Exiting script due to the user selection"
    exit -1
}

function read-password($prompt="Password", $defaultPassword="")
{
    $p = "${prompt} [${defaultPassword}]"
    $password = Read-Host -MaskInput -Prompt $p
    if (-not $password) { $password = $defaultPassword}
    return $password
}

$agekey = read-password "Enter master key of SOPS AGE (for developers)" 

# create a namespace
Write-Host -Foreground blue "Creating namespace $namespace"
kubectl create namespace $namespace
Write-Host -Foreground green "Created namespace $namespace"

# generate AGE key pair and create a secret for it
Write-Host -Foreground blue "Creating sops-age private secret in the namespace ${namespace}"

kubectl delete secret sops-age --namespace "${namespace}"
kubectl create secret generic sops-age --namespace "${namespace}" --from-literal=age.agekey="$agekey"

Write-Host -Foreground green "Created sops-age private secret in the namespace ${namespace}"

# unencrypt gitops-repo secrets to push it into cluster
Write-Host -Foreground blue "Creating gitops-repo secret in the namespace ${namespace}"

$patSecret = "$clusterRoot/secrets/params/repository-pat.env"
if (-not (Test-Path -Path $patSecret)) {
    $patSecret = "$clusterRoot/../localhost/secrets/params/gitops-repo.env"
    if (-not (Test-Path -Path $patSecret)) {
        Write-Host -Foreground red "gitops-repo secret not found in $clusterRoot/secrets/params/gitops-repo.env or $clusterRoot/../localhost/secrets/params/gitops-repo.env"
        exit -13
    }
}

$oldKey=$env:SOPS_AGE_KEY
$env:SOPS_AGE_KEY=$agekey
$envs=sops --decrypt $patSecret

# check for error exit code
if ($LASTEXITCODE -ne 0) {
    Write-Host -Foreground red "Failed to decrypt gitops-repo secret"
    exit -14
}

# read environments from env
$envs | Foreach-Object {
    $env = $_.split("=")
    $envName = $env[0]
    $envValue = $env[1]
    if ($envName -eq "username") {
        $username = $envValue
    }
    if ($envName -eq "password") {
        $password = $envValue
    }    
}
$env:SOPS_AGE_KEY="$oldKey"
$agekey=""
kubectl delete secret repository-pat --namespace $namespace
kubectl create secret generic  repository-pat `
  --namespace $namespace `
  --from-literal username=$username `
  --from-literal password=$password `

$username=""
$password=""
Write-Host -Foreground green "Created gitops-repo secret in the namespace ${namespace}"

if($installFlux)
{
    Write-Host -Foreground blue "Deploying the Flux CD controller"
    # first ensure crds exists when applying the repos
    kubectl apply -k $ProjectRoot/infrastructure/fluxcd --wait

    if ($LASTEXITCODE -ne 0) {
        Write-Host -Foreground red "Failed to deploy fluxcd"
        exit -15
    }

    Write-Host -Foreground blue "Flux CD controller deployed"
}

Write-Host -Foreground blue "Deploying the cluster manifests"
kubectl apply -k $clusterRoot --wait
Write-Host -Foreground green "Bootstrapping process is done, check the status of the GitRepository and Kustomization resource in namespace ${namespace} for reconcilation updates"

```
