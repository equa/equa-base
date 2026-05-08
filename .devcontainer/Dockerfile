FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base packages: adds SBCL, Go, Python 3.12 dev, and docs tools over equa-superlu base
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash-completion \
        build-essential \
        ca-certificates \
        clang-format \
        cmake \
        curl \
        git \
        gnupg \
        golang-go \
        lsb-release \
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3-pip \
        ripgrep \
        sbcl \
        shellcheck \
        wget \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# az CLI + azure-devops extension
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az extension add --name azure-devops --yes \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Intel oneAPI APT repository + minimal C/Fortran components only (no MKL)
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
      | gpg --dearmor \
      | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
      > /etc/apt/sources.list.d/oneAPI.list \
    && apt-get update -o Dir::Etc::sourcelist="sources.list.d/oneAPI.list" \
         -o APT::Get::List-Cleanup="0" \
    && apt-get install -y --no-install-recommends \
        intel-oneapi-dpcpp-cpp-compiler \
        intel-oneapi-compiler-fortran \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node 24 (baked into image; mirrors equa-platform-docs node:24 devcontainer feature)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Docs Node toolchain: markdownlint-cli2 and cspell via npm; lychee via binary release
# lychee is a Rust binary (no npm package) - install from GitHub releases
RUN npm install -g markdownlint-cli2 cspell \
    && LYCHEE_VERSION="0.18.0" \
    && curl -sL "https://github.com/lycheeverse/lychee/releases/download/lychee-v${LYCHEE_VERSION}/lychee-x86_64-unknown-linux-gnu.tar.gz" \
      | tar xz -C /usr/local/bin/ lychee \
    && lychee --version

# System-wide uv install (accessible to CI runners running as root or any user)
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# Copy toolchain smoke-test (build context = repo root)
COPY tests/toolchain/run-all.sh /tmp/run-all.sh

HEALTHCHECK NONE
