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

# Install the official Dev Container CLI to /usr/local/bin (accessible globally)
RUN curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh | \
    sh -- --prefix /usr/local

USER coder