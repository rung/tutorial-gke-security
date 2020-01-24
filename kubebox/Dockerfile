FROM ubuntu:18.04

RUN apt -y update && apt -y full-upgrade && \
    apt -y install ca-certificates && \
    apt -y install --no-install-recommends emacs vim less curl wget tmux zsh && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /bin/kubectl

# Add unprivileged user
RUN useradd appuser -d /home/appuser
WORKDIR /home/appuser

USER appuser
