
- download and install cli : https://github.com/linkerd/linkerd2/releases/tag/stable-2.11.1 (or other latest stable tag)
- create alias "linkerd", verify with linkerd version

- run linkerd check -d - see output, resolve issues or apply recommendation durring installation
- create folder ...infrastructure/linkerd
- execute linkerd install - > .\infrastructure\linkerd\linkerd.yaml
- execute linkerd viz install - > .\infrastructure\linkerd\viz.yaml
- execute linkerd jaeger install - > .\infrastructure\linkerd\jaeger.yaml

- check the file - be aware of secrets - you may want to use some of techniques for secret management or override them manually at the cluster - we will use them but consider generated secrets as unsafe for production if you store them at git (eventually you can extract them from the file to aspecial folder that is ignored and distribute by other means)

- create kustomization.yaml
- create clusters/localhost-infra/kustomization (not shared namespaces) and create viz web patch
- kubectl apply  -k .\clusters\localhost-infra\

- wait for all pods in running state `kubectl get pods --namespace linkerd -w`
- `linkerd check`
- linker viz dashboard


- setup nginx ingress

- enable tracing in nginx: https://linkerd.io/2.11/tasks/distributed-tracing/#ingress


2. Auth with https://oauth2-proxy.github.io/oauth2-proxy/
