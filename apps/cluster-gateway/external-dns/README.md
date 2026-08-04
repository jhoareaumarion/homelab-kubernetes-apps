# External-DNS OPNsense Integration (ArgoCD Application)

This repository/manifest defines an ArgoCD application that deploys **External-DNS** integrated with a custom **OPNsense Webhook Provider**. Its primary job is to bridge your Kubernetes cluster with your local OPNsense firewall to **automatically create, update, and delete DNS records (Host Overrides)** whenever you expose services via Kubernetes Gateway API `HTTPRoute` resources.

---

## 🏗️ Architecture & How It Works

1. **Source Monitoring:** 
   - External-DNS monitors the cluster for **`gateway-httproute`** objects (defined in namespaces like `planka`, etc.) pointing to your ingress gateway.
2. **Domain Filtering:** 
   - It restricts automated changes exclusively to the **`hoareau-marion.eu`** domain filter.
3. **The Webhook Sidecar Pattern:**
   - Because standard External-DNS does not have a built-in provider for OPNsense, this Helm deployment runs an official container alongside a specialized webhook sidecar image (`ghcr.io/crutonjohn/external-dns-opnsense-webhook:main`).
   - External-DNS sends internal requests to the sidecar plugin via localhost (`port 8888`).
   - The sidecar translates these requests into API calls to your OPNsense firewall to manage Unbound DNS Host Overrides.

---

## ⚙️ Key Manifest Configuration Breakdown

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-dns
  namespace: argocd
spec:
  project: homelab
  source:
    repoURL: https://kubernetes-sigs.github.io/external-dns/
    chart: external-dns
    targetRevision: 1.14.3
    helm:
      values: |
        fullnameOverride: external-dns
        logLevel: info
        
        # Uses the webhook provider to connect to OPNsense
        provider:
          name: webhook
          webhook:
            image:
              repository: ghcr.io/crutonjohn/external-dns-opnsense-webhook
              tag: main
            env:
              - name: OPNSENSE_HOST
                value: "https://opnsense.home.hoareau-marion.eu"
              - name: OPNSENSE_API_KEY
                valueFrom:
                  secretKeyRef:
                    name: external-dns-opnsense-secret
                    key: api_key
              - name: OPNSENSE_API_SECRET
                valueFrom:
                  secretKeyRef:
                    name: external-dns-opnsense-secret
                    key: api_secret
            # Health check probes bound to the secondary metrics/health server on port 8080
            livenessProbe:
              httpGet:
                path: /healthz
                port: 8080
            readinessProbe:
              httpGet:
                path: /healthz
                port: 8080
                
        sources:
          - gateway-httproute
          
        domainFilters:
          - hoareau-marion.eu
          
        registry: "noop"
  destination:
    server: https://kubernetes.default.svc
    namespace: cluster-gateway
  syncPolicy:
    automated:
      prune: true
      self_heal: true
    syncOptions:
      - CreateNamespace=true
```

---

## 🔒 Prerequisites & Dependencies

For this application to function correctly, ensure the following are present in your cluster:

1. **Kubernetes Secret (`external-dns-opnsense-secret`):**
   - Must exist in the `cluster-gateway` namespace containing valid OPNsense API credentials:
     - `api_key`
     - `api_secret`
2. **OPNsense API Access:**
   - The API user must have permissions to manage Unbound DNS / Host Overrides.

---

## 💡 Quick Troubleshooting Reference

- **`connection refused` on health checks:** 
  - Ensure probes point to **port 8080** (the sidecar's health server interface), *not* port 8888 (which is bound internally to localhost for core webhook communication).
- **Check sync status:** 
  - External-DNS queries the cluster and updates OPNsense by default every **1 minute**.