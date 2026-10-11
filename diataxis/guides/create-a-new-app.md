# Create a new app

_The "tutorial" of the how-to_

This tutorial walks you through adding a new application to the repository, following the exact pattern used by the existing apps. We use **actual-budget** as the reference implementation throughout.

> **Prerequisites**
> - Access to the cluster and the ArgoCD `argocd` namespace.
> - `kubectl` configured to talk to the cluster.
> - `sealos` installed for sealing secrets.
> - A chosen app name, public hostname, and (if needed) a database.

## Step 1 — Create the app directory

Create `apps/<app-name>/` and add the core manifests. We'll use `actual-budget` as the template:

```bash
mkdir -p apps/your-app
```

## Step 2 — Create the namespace

`apps/your-app/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: your-app
```

## Step 3 — Create the Deployment

`apps/your-app/deployment.yaml`. Base it on actual-budget:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-app
  namespace: your-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: your-app
  template:
    metadata:
      labels:
        app: your-app
    spec:
      nodeSelector:
        affected_vlan: "50"
      containers:
      - name: your-app
        image: <registry>/<image>:<tag>
        ports:
        - name: http
          containerPort: <port>
        volumeMounts:
        - name: data
          mountPath: /app/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: your-app-data
```

Replace `<registry>/<image>:<tag>` with your app's image, `<port>` with the container's HTTP port, and the mount path with where your app expects its data.

## Step 4 — Create the Service

`apps/your-app/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: your-app
  namespace: your-app
spec:
  selector:
    app: your-app
  ports:
  - name: http
    protocol: TCP
    port: <port>
    targetPort: <port>
```

## Step 5 — Create the PVC

`apps/your-app/pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: your-app-data
  namespace: your-app
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client
```

## Step 6 — Create the ConfigMap

`apps/your-app/cm.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-map
  namespace: your-app
data:
  # <key>: <value>
```

## Step 7 — Create the route

`apps/your-app/route.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: route
  namespace: your-app
spec:
  parentRefs:
  - name: ingress-gateway
    namespace: cluster-gateway
    sectionName: web-https
  hostnames:
  - "<app-name>.hoareau-marion.eu"
  rules:
  - backendRefs:
    - name: your-app
      port: <port>
```

Choose a section name that matches the ingress gateway's sections (`web-https` for public apps, `auth-https`/`auth-private-https` for auth apps).

## Step 8 — Create the TLS certificate

`apps/your-app/certificate.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: <app-name>-hoareau-marion-eu-tls
  namespace: cluster-gateway
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  secretName: <app-name>-hoareau-marion-eu-tls
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
  - "<app-name>.hoareau-marion.eu"
```

## Step 9 — Handle secrets

1. Create the plaintext secret `apps/your-app/secrets.secrets.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secrets
  namespace: your-app
type: Opaque
stringData:
  # <key>: "<value>"
```

2. Seal it into `apps/your-app/secrets.sealed.yaml`:

```bash
sealos seal apps/your-app/secrets.secrets.yaml -o apps/your-app/secrets.sealed.yaml
```

3. Make sure `secrets.secrets.yaml` is listed in the repo `.gitignore` (it already is) so only the sealed version is committed.

## Step 10 — Create the ArgoCD Application

`apps/your-app.yaml` at the repo root:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: your-app
  namespace: argocd
  labels:
    hoareau-marion.eu/category: <category>
spec:
  project: homelab
  source:
    repoURL: https://github.com/jhoareaumarion/homelab-kubernetes-apps
    targetRevision: HEAD
    path: apps/your-app
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: your-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

## Step 11 — Deploy and verify

```bash
kubectl apply -f apps/your-app/
kubectl -n your-app get pods,services,ingresses
```

ArgoCD will detect the new Application and deploy it. ExternalDNS will create the public DNS record for the route.

## Adding a database

If your app needs a database (see how keycloak does it), create an `apps/your-app/db/` directory with:

- `deployment.yaml` — the Postgres Deployment (`app: postgres`)
- `service.yaml` — the Postgres Service (port `5432`)
- `pvc.yaml` — the data PVC
- `cm.yaml` — DB credentials (`POSTGRES_DB`, `POSTGRES_USER`)

Then have your main Deployment pull the DB password from the shared secret via `secretKeyRef`.

## Reference implementation

- **Full example**: `apps/actual-budget/` — a simple app with storage, a route, and a certificate.
- **App with a database**: `apps/keycloak/` — includes the nested `db/` directory.
- **App with authentication**: `apps/shared-authentication/` — oauth2-proxy + Keycloak integration.

See [reference/actual-budget.md](../reference/actual-budget.md) for the exact manifests and [reference/conventions.md](../reference/conventions.md) for the conventions behind them.
