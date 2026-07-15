FROM codercom/code-server:4.128.0@sha256:bd4a3a022ff016954bf9ae6ea0bce6c7eef96a69da4d2fe34552638f32d4820c

USER root

# Install system dependencies needed for DevContainer CLI operations
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install DevPod
RUN curl -L -s https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64 -o /usr/local/bin/devpod && \
    chmod +x /usr/local/bin/devpod

# Download the Dev Container CLI install script, run it, and clean up the script
RUN curl -fsSL -o /tmp/install-devcontainer.sh https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh && \
    sh /tmp/install-devcontainer.sh --prefix /usr/local && \
    rm /tmp/install-devcontainer.sh

USER coder