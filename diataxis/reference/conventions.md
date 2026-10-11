# Conventions

_Glossary and conventions glossary_

This page is the glossary of terms, conventions, and patterns used across this repository. It is the "glossary" quadrant of Diataxis for this repo: a reference you consult to understand the vocabulary and standard patterns when reading or writing manifests.

## Repository layout

```
homelab-kubernetes-apps/
├── apps/
│   ├── <app-name>/            # one directory per application
│   │   ├── deployment.yaml    # Kubernetes Deployment(s)
│   │   ├── service.yaml       # Kubernetes Service(s)
│   │   ├── namespace.yaml     # Namespace for the app
│   │   ├── route.yaml         # ExposedRoute (public)
│   │   ├── private-route.yaml # ExposedRoute (private)
│   │   ├── cm.yaml            # ConfigMap(s)
│   │   ├── secrets.secrets.yaml   # Plaintext Secret (gitignored)
│   │   ├── secrets.sealed.yaml    # SealedSecret (committed)
│   │   ├── certificate.yaml   # cert-manager Certificate
│   │   └── pvc.yaml          # PersistentVolumeClaim
│   └── <other-app>/
├── apps/cluster-gateway/      # Ingress/Egress gateways (shared infra)
│   ├── ingress-gateway/       # Public ingress (20-virtual-mgmt, 50-service)
│   └── external-dns/          # ExternalDNS + Route53
├── apps/infrastructure/       # CNI, argocd, nfs, etc.
├── app-of-apps.yaml           # Root ArgoCD Application
└── shared-authentication.yaml # ArgoCD Application (recurse: true)
```

## Application manifest conventions

Every application is delivered as an **ArgoCD `Application`** manifest. The conventions are:

| Convention | Example |
| --- | --- |
| ArgoCD API version | `argoproj.io/v1alpha1` |
| Kind | `Application` |
| App name | `metadata.name: <app-name>` |
| ArgoCD install namespace | `metadata.namespace: argocd` |
| Source repo | `https://github.com/jhoareaumarion/homelab-kubernetes-apps` |
| Source path | `apps/<app-name>` |
| `recurse: true` | so all subdirectories are deployed |
| Destination namespace | `spec.destination.namespace: <app-name>` |
| ArgoCD auto-sync | `prune: true`, `selfHeal: true` |
| `CreateNamespace: true` | the destination namespace is created by ArgoCD |

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>
  namespace: argocd
  labels:
    hoareau-marion.eu/category: <category>
spec:
  project: homelab
  source:
    repoURL: https://github.com/jhoareaumarion/homelab-kubernetes-apps
    targetRevision: HEAD
    path: apps/<app-name>
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: <app-name>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Category labels

Each application namespace is tagged with a `hoareau-marion.eu/category:` label used for grouping. Examples observed:

- `security` — keycloak, shared-authentication
- `auth` — namespaces that may receive `gateway-access: auth` (keycloak, actual-budget, etc.)

## Networking conventions

- **Ingress gateway**: `cluster-gateway/ingress-gateway/ingress-gateway.yaml` is the single public entry point.
- **Sections**: Routes are attached to a `sectionName` on the ingress gateway:
  - `web-https` — general public web apps
  - `auth-https` — auth provider (Keycloak)
  - `auth-private-https` — private admin UI (Keycloak admin)
- **Route kind**: `gateway.networking.k8s.io/v1` `HTTPRoute`.
- **Hostnames**: `<app>.hoareau-marion.eu` (public), `<app>.private.hoareau-marion.eu` (private admin).
- **TLS**: `cert-manager` `Certificate` resources with a `letsencrypt` `ClusterIssuer`; certs are stored in the `cluster-gateway` namespace.
- **Cross-namespace traffic**: a `ReferenceGrant` in the source namespace authorizes routing to a target Service (required by Gateway API security).

## Secrets conventions

1. Authors write a **plaintext** `Secret` (e.g. `secrets.secrets.yaml`) with `stringData`.
2. It is **sealed** into a `SealedSecret` (`secrets.sealed.yaml`) using `sealos`.
3. Only the **SealedSecret** is committed to git; the plaintext secret is **gitignored**.
4. The deployment references the secret via `secretRef`.

```bash
# Seal a plaintext secret into a SealedSecret
sealos seal apps/<app>/secrets.secrets.yaml -o apps/<app>/secrets.sealed.yaml
```

## Database conventions (when an app needs a DB)

Apps that need a database (e.g. keycloak) keep a nested `db/` directory containing:

- `deployment.yaml` — the Postgres Deployment (`app: postgres`)
- `service.yaml` — the Postgres Service (port `5432`)
- `pvc.yaml` — the data PVC (typically `storageClassName: nfs-client`, `ReadWriteMany`)
- `cm.yaml` — DB credentials (`POSTGRES_DB`, `POSTGRES_USER`)

The main app Deployment pulls the DB password from the shared secret via `secretKeyRef`.

## Node selection

Containers that must run on a specific VLAN use:

```yaml
spec:
  nodeSelector:
    affected_vlan: "50"
```

## Resources

Apps define `resources.requests` and `resources.limits` for memory and cpu (e.g. keycloak requests `512Mi` memory / `250m` cpu, limits `1Gi` / `1000m`).
