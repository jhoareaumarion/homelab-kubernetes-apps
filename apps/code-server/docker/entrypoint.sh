#!/bin/bash
set -e

# 1. Configure Git
# Configure Git if secrets are provided
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
fi
git config --global commit.gpgsign true
git config --global gpg.program gpg
git config --global pull.rebase false

# 2. Configure DevPod Provider (Idempotent check)
if ! devpod provider list | grep -q "kubernetes"; then
    devpod provider add kubernetes
    devpod provider set-options kubernetes \
        --option KUBERNETES_NAMESPACE=devpod-workspaces \
        --option STORAGE_CLASS=nfs-client \
        --option ARCHITECTURE=amd64
fi

# 3. GPG Environment
export GPG_TTY=$(tty)

# 4. Start code-server
exec "$@"