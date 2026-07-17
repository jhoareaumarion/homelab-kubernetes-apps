# 1. Base Image: Use the official code-server
FROM codercom/code-server:4.129.0@sha256:49d5e176224523b0c924ee35b05c51e9a87f9c170f650ee0f7da05a4581a79ff

# Switch to root to perform installations
USER root

# Setup environment
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (Combined from both your Dockerfiles)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    xz-utils \
    sudo \
    apt-transport-https \
    gnupg \
    lsb-release \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 2. Install DevPod
RUN curl -L -s https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64 -o /usr/local/bin/devpod && \
    chmod +x /usr/local/bin/devpod

# 3. Setup Kubernetes & Kubeseal (from your second Dockerfile)
RUN mkdir -p -m 755 /etc/apt/keyrings/ && \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' > /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    \
    # Kubeseal install logic
    ARCH="amd64" && [ "$(uname -m)" = "aarch64" ] && ARCH="arm64"; \
    KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | jq -r '.tag_name' | cut -c 2-) && \
    curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${ARCH}.tar.gz" && \
    tar -xvzf "kubeseal-${KUBESEAL_VERSION}-linux-${ARCH}.tar.gz" kubeseal && \
    install -m 755 kubeseal /usr/local/bin/kubeseal && \
    rm kubeseal*

# 4. Setup Hubble
RUN HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt) && \
    curl -L --fail --remote-name-all "https://github.com/cilium/hubble/releases/download/${HUBBLE_VERSION}/hubble-linux-amd64.tar.gz" && \
    tar xzvfC "hubble-linux-amd64.tar.gz" /usr/local/bin && \
    rm "hubble-linux-amd64.tar.gz"

# 5. Final Permissions for 'coder' user
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy your entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch back to the 'coder' user
USER coder
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]