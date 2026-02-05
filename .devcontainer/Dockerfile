FROM mcr.microsoft.com/devcontainers/python:1-3.12-bullseye
#3.12-bullseye

LABEL org.opencontainers.image.source="https://github.com/jhoareaumarion/devcontainers"
LABEL org.opencontainers.image.description="Kubernetes/Kubeseal/Hubble for VS Code"
LABEL org.opencontainers.image.licenses="MPL 2.0"

WORKDIR /workspace

# Copy the installation script
COPY install_kubectl.sh /tmp/install_kubectl.sh

# Run the script
RUN /tmp/install_kubectl.sh && \
    rm /tmp/install_kubectl.sh

CMD ["/bin/bash"]
