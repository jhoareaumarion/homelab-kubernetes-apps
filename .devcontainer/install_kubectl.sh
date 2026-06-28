#!/bin/bash
set -euo pipefail

# # Yarn repo make issues, to fix later maybe?
rm -f /etc/apt/sources.list.d/yarn.list* 2>/dev/null || true

# Update packages and install dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release jq curl git

mkdir -p -m 755 /etc/apt/keyrings/

# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

# Update again and install kubectl
apt-get update
apt-get install -y kubectl

# Récupération sécurisée
RESPONSE=$(curl -L -s https://api.github.com/repos/bitnami/sealed-secrets/tags)

# Extraction de la version
KUBESEAL_VERSION=$(echo "$RESPONSE" | jq -r '.[0].name' 2>/dev/null | cut -c 2-)

# Validation
if [ -z "$KUBESEAL_VERSION" ] || [ "$KUBESEAL_VERSION" = "null" ]; then
    echo "Erreur : impossible d'extraire la version du JSON."
    echo "Réponse reçue : $RESPONSE"
    exit 1
fi

echo "Version détectée : $KUBESEAL_VERSION"

curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}