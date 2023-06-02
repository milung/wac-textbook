## Úprava nasadenia WebApi applikácie v kubernetes klastri

Keďže je databáza prístupná len pod menom a heslom, musíme tieto oznámiť aj kontaineru, v ktorom v rámci klastra beží náš webapi komponent. Naprogramovali sme `mongodb_service` vo webapi tak, aby získaval adresu mongo databázy, ako aj prihlasovacie meno a heslo z premenných prostredia.

Tieto premenné nakonfigurujeme rovnako ako v prípade mongo express kontainera. Upravte súbor  `.../webcloud-gitops/apps/<pfx>-ambulance-webapi/deployment.yaml` nasledovne:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <pfx>-ambulance-webapi
spec:
  replicas: 2
  selector:
      matchLabels:
        pod: <pfx>-ambulance-webapi-label
  template:
      metadata:
        labels:
          pod: <pfx>-ambulance-webapi-label
      spec:
        containers:
        - name: <pfx>-ambulance-webapi-container
          image: <userid>/ambulance-webapi:latest
          imagePullPolicy: Always
          ports:
          - name: webapi-port
            containerPort: 8080
          resources:
            requests:
              memory: "32Mi"
              cpu: "0.1"
            limits:
              memory: "128Mi"
              cpu: "0.3"
          env:
          - name: MONGODB_URI
            valueFrom:
              configMapKeyRef:
                name: mongodb-configmap
                key: mongodb_uri
          - name: MONGODB_USERNAME
            valueFrom:
              secretKeyRef:
                name: mongodb-secret
                key: mongo-root-username
          - name: MONGODB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mongodb-secret
                key: mongo-root-password
```

Archivujte zmeny do vzdialeného repozitára a po chvíli skontrolujte, či boli pody `webapi` reštartované:

```ps
kubectl get pods -n wac-hospital
```

Vyskúšajte aj funkcionalitu webapi, opäť použijeme presmerovanie portov:

```ps
kubectl port-forward service/<pfx>-ambulance-webapi -n wac-hospital 8111:80
```

a v prehliadači otvorte stránku [http://localhost:8111/api](http://localhost:8111/api), na ktorej uvidíte správu "Hello World!".

> Poznámka: V prípade, že premenné nie sú nastavené správne, sa chyba prejaví až pri prvej požiadavke na databázu.
