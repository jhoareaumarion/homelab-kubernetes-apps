# Workspace & Secrets Management Guide

This workspace is configured with GPG-signed commits and `kubeseal` for secret management. Use this guide to manage your environment efficiently.

---

## 🔐 GPG Commit Signing

Because this workspace runs in a containerized environment (headless), the VS Code GUI cannot natively prompt for your GPG passphrase.

### The "Warm-up" Workflow
To enable "one-click" signing in the VS Code GUI, you must "warm up" the GPG agent in your terminal once per pod lifecycle (e.g., after the workspace restarts).

**Run this in your terminal:**
```bash
echo "test" | gpg --clearsign

```

* **What it does:** It prompts you for your passphrase, unlocks your key, and caches it in memory.
* **Result:** You can now click the **Commit** checkmark in VS Code without any errors, as your key is "unlocked" for the duration of the pod's life.

---

## 🛡️ Secret Management

We use `kubeseal` to encrypt secrets for GitOps compliance. Ensure you have the `kubeseal` CLI installed on your **local development machine**, not inside the workspace.

### Seal a Secret

To convert a standard Kubernetes secret into a SealedSecret:

```bash
kubeseal --cert /path/to/your/kubeseal-cert.pem -o yaml < input.secrets.yaml > sealed.secrets.yaml

```

* *Note: Replace `/path/to/your/kubeseal-cert.pem` with the location of your public key certificate.*

---

## 🛠️ Troubleshooting & Maintenance

### Reload GPG Agent

If GPG becomes unresponsive or you need to force a configuration reload:

```bash
gpg-connect-agent reloadagent /bye

```

### Verify Git Configuration

To ensure Git is correctly configured to sign your commits:

```bash
git config --get commit.gpgsign
git config --get user.signingkey

```

### Check DevPod Provider

If your external workspaces aren't launching via DevPod, verify the provider initialization:

```bash
devpod provider list

```

