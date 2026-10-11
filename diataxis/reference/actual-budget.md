# Actual Budget

**Location:** `apps/actual-budget`

**Category:** personal

**Description:** Actual Budget is a self-hosted personal finance application for tracking budgets, expenses, and accounts. It is deployed as a simple single-container app (no database) that authenticates via OIDC through Keycloak.

## Files in `apps/actual-budget/`

| File | Kind | Purpose |
| --- | --- | --- |
| `deployment.yaml` | Deployment | Runs the `actual-budget` container (port `5006`) |
| `service.yaml` | Service | ClusterIP Service exposing port `5006` |
| `namespace.yaml` | Namespace | Creates the `actual-budget` namespace |
| `route.yaml` | HTTPRoute | Public route on `budget-https` section, host `budget.hoareau-marion.eu` |
| `pvc.yaml` | PersistentVolumeClaim | `actual-budget-pvc` for the app data at `/data` |
| `cm.yaml` | ConfigMap | App configuration |
| `secrets.secrets.yaml` | Secret | Plaintext secrets (gitignored) |
| `secrets.sealed.yaml` | SealedSecret | Encrypted secret (committed) |
| `certificate.yaml` | Certificate | TLS cert for `budget.hoareau-marion.eu` |

## Manifest reference

### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: actual-budget
  namespace: actual-budget
spec:
  replicas: 1
  selector:
    matchLabels:
      app: actual-budget
  template:
    metadata:
      labels:
        app: actual-budget
    spec:
      nodeSelector:
        affected_vlan: "50"
      containers:
      - name: actual-budget
        image: docker.io/actualbudget/actual-server:26.9.0
        ports:
        - name: http
          containerPort: 5006
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: actual-budget-pvc
```

- **Image:** `docker.io/actualbudget/actual-server:26.9.0` (pinned digest).
- **Port:** `5006`.
- **Storage:** mounts `actual-budget-pvc` at `/data`.
- **Scheduling:** pinned to `affected_vlan: "50"` nodes.
- **Config/secrets:** injected via `envFrom` with `configMapRef: cm` and `secretRef: secrets`.

### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: actual-budget
  namespace: actual-budget
spec:
  selector:
    app: actual-budget
  ports:
  - name: http
    protocol: TCP
    port: 5006
    targetPort: 5006
```

### route.yaml

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: route
  namespace: actual-budget
spec:
  parentRefs:
  - name: ingress-gateway
    namespace: cluster-gateway
    sectionName: budget-https
  hostnames:
  - "budget.hoareau-marion.eu"
  rules:
  - backendRefs:
    - name: actual-budget
      port: 5006
```

- Exposed publicly at `https://budget.hoareau-marion.eu`.
- Attached to the `budget-https` section of the ingress gateway.

### pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: actual-budget-pvc
  namespace: actual-budget
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client
```

### cm.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm
  namespace: actual-budget
data:
  # <key>: <value>
```

### secrets.secrets.yaml (plaintext, gitignored)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secrets
  namespace: actual-budget
type: Opaque
stringData:
  # <key>: "<value>"
```

### secrets.sealed.yaml (committed)

```yaml
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: secrets
  namespace: actual-budget
spec:
  encryptedData:
    # <key>: <encrypted-value>
  template:
    metadata:
      name: secrets
      namespace: actual-budget
    type: Opaque
```

### certificate.yaml

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: budget-hoareau-marion-eu-tls
  namespace: cluster-gateway
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  secretName: budget-hoareau-marion-eu-tls
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
  - budget.hoareau-marion.eu
```

## How to customize

- **Change the app name:** update `metadata.name` and the `app:` label in all manifests, plus the PVC, Service, Deployment, and route.
- **Change the hostname:** update `route.yaml` hostnames and `certificate.yaml` `dnsNames`.
- **Change resources:** edit `resources.requests`/`limits` in `deployment.yaml`.
- **Change storage size:** edit `resources.requests.storage` in `pvc.yaml`.
- **Add OIDC auth:** see [Configure Authentication](../guides/configure-authentication.md).
