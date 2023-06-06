# Cvičenie 3: Docker a Kubernetes

## <a name="ciel"></a>Cieľ cvičenia

Aplikácie vytvorené počas predchádzajúcich cvičení sú dostupné vo verejnom dátovom centre. Ich nasadenie 
je automatizované a tak máme zabezpečený kontinuálny vývoj. Jedinou nevýhodou je, že momentálne je ich 
kontinuálne nasadenie zabezpečené len pre jedného konkrétneho poskytovateľa, konkrétne Microsoft Azure. 
Nasadenie k alternatívnym poskytovateľom by síce nebolo komplikované, v tomto cvičení si ale ukážeme ako 
nasadiť našu aplikáciu čo najjednoduchším spôsobom do ľubovoľného kubernetes klastra. 

## <a name="priprava"></a>Príprava na cvičenie

* Oba projekty `ambulance-spa` a `ambulance-api` sú funkčné a zaintegrované. 
* Nainštalovaný Docker a kubernetes. Pre účely cvičenia postačí inštalácia [Docker for Desktop](https://www.docker.com/products/docker-desktop) so zapnutým systémom Kubernetes
* Vytvorený účet na stránke [Docker Hub](https://hub.docker.com/)
