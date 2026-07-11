# Paperless-ngx & Proton Mail Bridge Integration

This directory contains the Kubernetes manifests managed by ArgoCD for the `paperless-ngx` deployment and its local `proton-bridge` dependency. 

Because Proton Mail uses zero-knowledge encryption, the bridge container requires a one-time manual interactive login sequence immediately following the initial ArgoCD sync. Without these steps, Paperless will fail to authenticate or fetch emails.

---

## 🛠️ Required Post-Deployment Manual Actions

Follow these steps directly after ArgoCD syncs the manifests to the cluster.

### Step 1: Access the Interactive Bridge CLI
Run the following command to log directly into the running Proton Bridge container:
```bash
kubectl exec -it deployment/proton-bridge -n paperless-ngx -- bridge-cli