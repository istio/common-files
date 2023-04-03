# Remote docker environment for ztunnel development.
#
# Build:
#   docker build -t ztunnel/remote-env:0.1 -f docker/remote-env/Dockerfile .
#
# Run:
#   docker run -d \
#       --privileged \
#       -p 127.0.0.1:2222:22 \
#       --name ztunnel-dev \
#       --mount type=bind,source="$PWD",target="/home/user/ztunnel" \
#       ztunnel/remote-env:0.1
#
# Clear credentials:
#   ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:2222"
#
# stop:
#   docker stop ztunnel-dev
#
# ssh credentials (test user):
#   ssh user@localhost -p2222 (enter `password` on the command-line)

FROM gcr.io/istio-testing/build-tools:master-42499d67179f80bbbeb71bc0f793d1b483cf8937

# - git (and git-lfs), for git operations (to e.g. push your work).
#   Also required for setting up your configured dotfiles in the workspace.
# - sudo, while not required, is recommended to be installed, since the
#   workspace user (`gitpod`) is non-root and won't be able to install
#   and use `sudo` to install any other tools in a live workspace.
RUN apt-get update && apt-get install -yq \
    net-tools \
    iproute2 \
    iptables \
    cmake \
    ninja-build \
    git \
    sudo \
    ssh \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Add the rust source code and set up the environment.
RUN rustup component add rust-src
ENV CARGO_HOME="/home/.cargo"
ENV RUSTUP_HOME="/home/.rustup"
ENV PATH=$CARGO_HOME/bin:$PATH

# Create the configuration file for sshd
RUN ( \
    echo 'LogLevel DEBUG2'; \
    echo 'PermitRootLogin yes'; \
    echo 'PasswordAuthentication yes'; \
    echo 'AllowTcpForwarding yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_remote_dev \
  && mkdir /run/sshd

RUN TMPDIR="$(mktemp -d)"
# Installing Krew
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR $TMPDIR
RUN OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
  KREW="krew-${OS}_${ARCH}" && \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
  tar zxvf "${KREW}.tar.gz" && \
  ./"${KREW}" install krew

ENV PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

RUN kubectl krew install ns

ENV BUILD_WITH_CONTAINER=0