# Paperless-ngx & Proton Mail Bridge Integration

This directory houses the Kubernetes manifests managed by ArgoCD for `paperless-ngx` and its `protonmail-bridge` secure mail dependency. 

Because Proton Mail uses zero-knowledge encryption, the bridge cannot automatically authenticate on a fresh deployment. A one-time interactive login loop must be executed manually.

---

## 🛠️ Post-Deployment Initialization Workflow

Follow these steps immediately after ArgoCD completes its initial sync of the manifests.

### Step 1: Execute into the Running Pod
Get the exact name of your deployed bridge pod and open an interactive bash shell:
```bash
kubectl get pods -n paperless-ngx
kubectl exec -it <protonmail-bridge-pod-name> -n paperless-ngx -- /bin/bash
```

### Step 2: Trigger the Internal Init Sequence
Run the container's native onboarding script to provision local GPG keys and initialize the secure `pass` credential store:
```bash
bash /protonmail/entrypoint.sh init
```

### Step 3: Authenticate inside the Bridge CLI
Once the ASCII art banner loads and you see the interactive bridge prompt (`>>>`), run the following commands sequentially:

1. **Log In:**
   ```text
   login
   ```
   *Provide your master Proton Mail username and password. Enter your 2FA token code immediately after if prompted.*

2. **Split Mailbox Mode:**
   ```text
   change mode imap
   ```
   *This changes the runtime to raw IMAP protocol bindings required by Paperless-ngx.*

3. **Get Your Unique Bridge Credentials:**
   ```text
   info
   ```
   *Locate the generated 12-character random **Password** string in the output printout. Copy this password—you will use it to link Paperless.*

4. **Exit the CLI Shell:**
   ```text
   exit
   ```
   *(Note: The bridge will begin syncing folders. Do **not** wait for this to complete. The process is safely written to persistent storage).*

5. **Exit the Pod:**
   Type `exit` once more to return to your local terminal session.

### Step 4: Cycle the Pod to Production Mode (Crucial)
The container is currently locked in configuration mode. To force it to launch its background mail-serving engines and open port `143`, **delete the pod** to trigger a fresh Kubernetes replica cycle:
```bash
kubectl delete pod <protonmail-bridge-pod-name> -n paperless-ngx
```

---

## 📬 Step 5: Link the Account in Paperless-ngx
Log into your Paperless-ngx web UI, navigate to **Settings ➔ Mail Accounts ➔ Add Account**, and connect using these internal parameters:

| Configuration Field | Value to Enter |
| :--- | :--- |
| **IMAP Server** | `protonmail-bridge-service` *(or `protonmail-bridge-service.paperless-ngx.svc.cluster.local`)* |
| **IMAP Port** | `143` |
| **Username** | `your-proton-email@proton.me` |
| **Password** | *The 12-character App Password generated in Step 3.3* |
| **SSL/TLS** | `None` *(Safe as traffic is contained entirely within the private cluster network)* |

---

## ⚠️ Troubleshooting & Cluster Maintenance

### Resetting a Corrupted/Dirty PVC Volume State
If you run into an image update mismatch or encounter an NFS lock error (`Device or resource busy`), run this sequence from your local terminal to forcefully drop handles and wipe the configuration slate clean:

```bash
# 1. Force kill the locked pod
kubectl delete pod <pod-name> -n paperless-ngx --force --grace-period=0

# 2. Wait 10 seconds for the replacement pod to spawn, exec in, and wipe directories
kubectl exec -it <new-pod-name> -n paperless-ngx -- /bin/bash
rm -rf /root/.config/Proton /root/.gnupg /root/.password-store

# 3. Re-run initialization
bash /protonmail/entrypoint.sh init
```