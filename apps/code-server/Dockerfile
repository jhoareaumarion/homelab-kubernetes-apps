FROM codercom/code-server:4.128.0@sha256:bd4a3a022ff016954bf9ae6ea0bce6c7eef96a69da4d2fe34552638f32d4820c
USER root
RUN curl -L -s https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64 -o /usr/local/bin/devpod && \
    chmod +x /usr/local/bin/devpod
USER coder