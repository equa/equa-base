# Five-tier image set on plain ubuntu:24.04. T1-T4 form a linear FROM-chain;
# T5 branches from T2. One buildx run produces all targets. Tier contents and
# the job-class mapping are recorded in equa-platform-docs change
# `ci-image-layers` (design.md + spike-findings.md).
#
#   t1-ci   → ghcr.io/equa/equa-base-ci    slim, NO az/oneAPI/Lisp   — checks jobs
#   t2-lite → ghcr.io/equa/equa-base-lite  + az                      — release jobs
#   t3-base → ghcr.io/equa/equa-base       + oneAPI/Lisp/Go          — compile jobs
#   t4-dev  → ghcr.io/equa/equa-base-dev   + dev conveniences        — local dev
#   t5-ifrt → ghcr.io/equa/equa-base-ifrt  FROM t2 + Fortran runtime — runtime-vendor jobs

# ── sbcl-builder: compile SBCL 2.6.5 from source ────────────────────────────
# Apt on noble is frozen at SBCL 2.2.9; the sbcl.org Linux binary omits
# :sb-core-compression, which the Linux lisp build leg's save-lisp-and-die
# :compression t requires. So build 2.6.5 from the public release tag with
# --fancy (includes sb-core-compression). Isolated in its own stage so the
# ~3-6 min compile and its build-only deps stay out of the shipping image and
# are reused via buildx cache on unrelated T3 edits. See equa-platform-docs
# change bump-linux-sbcl-2-6-5 (design D1/D2).
#
# SBCL_BUILDING_RELEASE_FROM=HEAD + NO_GIT_HASH_IN_VERSION=1 force the version
# string to a clean "2.6.5": a --depth 1 --branch clone has no origin/master, so
# SBCL's generate-version.sh cannot compute merge-base and would otherwise stamp
# the dev form "2.6.5.HEAD.N-<hash>", failing the exact-version smoke test.
FROM ubuntu:24.04 AS sbcl-builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        sbcl \
        build-essential \
        zlib1g-dev \
        libzstd-dev \
        git \
        ca-certificates \
    && git clone --depth 1 --branch sbcl-2.6.5 https://github.com/sbcl/sbcl /tmp/sbcl \
    && cd /tmp/sbcl \
    && SBCL_BUILDING_RELEASE_FROM=HEAD NO_GIT_HASH_IN_VERSION=1 sh make.sh --fancy \
    && sh install.sh --prefix=/opt/sbcl

# ── T1 equa-base-ci: slim non-compile CI toolchain ──────────────────────────
FROM ubuntu:24.04 AS t1-ci

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base packages: docs/lint/build helpers shared by every job class. az, SBCL,
# Go, and oneAPI are NOT here — they live in higher tiers. `sudo` is added here
# (plain ubuntu omits it; the devcontainers base used to provide it) for the
# vscode user the Lisp tier recreates.
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash-completion \
        build-essential \
        ca-certificates \
        clang-format \
        cmake \
        curl \
        ninja-build \
        git \
        gnupg \
        lsb-release \
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3-pip \
        ripgrep \
        shellcheck \
        sudo \
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

# Node 24 (baked into image; mirrors equa-platform-docs node:24 devcontainer feature)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Docs Node toolchain: markdownlint-cli2 and cspell via npm; lychee via binary release.
# These are shared, version-stable, not per-repo-pinned — baked. semantic-release is
# per-repo-pinned (each package-lock.json) and is NOT baked; jobs npm ci it.
RUN npm install -g markdownlint-cli2 cspell \
    && LYCHEE_VERSION="0.18.0" \
    && curl -sL "https://github.com/lycheeverse/lychee/releases/download/lychee-v${LYCHEE_VERSION}/lychee-x86_64-unknown-linux-gnu.tar.gz" \
      | tar xz -C /usr/local/bin/ lychee \
    && lychee --version

# System-wide uv install (accessible to CI runners running as root or any user)
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# T1 smoke test (tools present; az + heavy toolchain asserted absent)
COPY tests/toolchain/run-all-ci.sh /tmp/run-all-ci.sh

HEALTHCHECK NONE

# ── T2 equa-base-lite: T1 + az ──────────────────────────────────────────────
FROM t1-ci AS t2-lite

# az CLI + azure-devops extension (release jobs: ADO Artifacts login/publish)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az extension add --name azure-devops --yes \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# T2 smoke test (az present; compilers absent)
COPY tests/toolchain/run-all-lite.sh /tmp/run-all-lite.sh

HEALTHCHECK NONE

# ── T3 equa-base: T2 + vscode user + oneAPI/Lisp/Go ─────────────────────────
FROM t2-lite AS t3-base

# Plain ubuntu:24.04 ships a stock UID-1000 `ubuntu` user; remove it and
# recreate `vscode` (UID/GID 1000, /home/vscode, /bin/bash, passwordless sudo)
# byte-for-byte as the devcontainers base did — the per-user Quicklisp/Parachute
# layout and CI's `runuser -l vscode` drop depend on it. Confirmed by the
# ci-image-layers Phase 0 spike.
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m --shell /bin/bash vscode \
    && echo 'vscode ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# SBCL + Go: build toolchains used only by compile/Lisp jobs. SBCL is the
# source-built 2.6.5 from the sbcl-builder stage (not apt, which is 2.2.9);
# only its runtime libs are apt-installed here. Must precede the Quicklisp
# bootstrap so those fasls compile under 2.6.5 (design D5).
COPY --from=sbcl-builder /opt/sbcl/ /usr/local/
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        golang-go \
        libzstd1 \
        zlib1g \
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

# Lisp toolchain: bootstrap Quicklisp into /home/vscode and pre-fetch Parachute,
# all as the vscode user (UID 1000) so the per-user ~/quicklisp + ~/.sbclrc layout
# that downstream tooling assumes is owned by vscode. The dist is pinned to a known
# version (2026-01-01) via install-dist so a rebuild of this image tag is reproducible;
# pre-quickloading Parachute makes the library resident and loadable offline at runtime.
USER vscode
RUN export HOME=/home/vscode \
    && curl -fsSL -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp \
    && sbcl --non-interactive \
         --load /tmp/quicklisp.lisp \
         --eval '(quicklisp-quickstart:install :path "/home/vscode/quicklisp")' \
         --eval '(ql-dist:install-dist "http://beta.quicklisp.org/dist/quicklisp/2026-01-01/distinfo.txt" :replace t :prompt nil)' \
         --eval '(ql-util:without-prompting (ql:add-to-init-file))' \
    && sbcl --non-interactive --eval '(ql:quickload :parachute)' \
    && rm -f /tmp/quicklisp.lisp
USER root

# Full toolchain smoke-test (build context = repo root)
COPY tests/toolchain/run-all.sh /tmp/run-all.sh

HEALTHCHECK NONE

# ── T4 equa-base-dev: T3 + developer conveniences (local dev only) ──────────
FROM t3-base AS t4-dev

# Conveniences the devcontainers base used to provide; CI tiers never pay for
# these. Extend as the dev workflow needs.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        less \
        locales \
        man-db \
        nano \
        procps \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Dev smoke test (developer conveniences present)
COPY tests/toolchain/run-all-dev.sh /tmp/run-all-dev.sh

HEALTHCHECK NONE

# ── T5 equa-base-ifrt: T2 + Intel Fortran runtime (no compiler, Lisp, or Go) ──
# Extends T2 (inherits az). Carries the Intel Fortran shared-library runtime
# (libifcoremt, libifcore, libifport, libimf, libsvml, libintlc) only — no
# ifx/icx compiler, no SBCL, no Go, no vscode user.
# The versioned intel-oneapi-openmp-<ver> package is a transitive dep that
# ships ~502 MB of LLVM tools, sanitizer runtimes, SPIR-V bitcode, and OpenMP
# offload with no DT_NEEDED relationship to the Fortran runtime libs; its files
# are removed in the same layer to keep /opt/intel under ~510 MB. The package
# name is resolved by pattern (not a hardcoded minor version) so an upstream
# oneAPI bump — e.g. 2026.0 to 2026.1 — does not break the purge. The
# [0-9] class excludes intel-oneapi-openmp-common-<ver> (small config).
FROM t2-lite AS t5-ifrt

RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
      | gpg --dearmor \
      | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
      > /etc/apt/sources.list.d/oneAPI.list \
    && apt-get update -o Dir::Etc::sourcelist="sources.list.d/oneAPI.list" \
         -o APT::Get::List-Cleanup="0" \
    && apt-get install -y --no-install-recommends \
        intel-oneapi-compiler-fortran-runtime \
    && for pkg in $(dpkg-query -W -f='${Package}\n' 'intel-oneapi-openmp-[0-9]*' 2>/dev/null); do \
           dpkg -L "$pkg" | while IFS= read -r f; do [ -f "$f" ] && rm -f "$f"; done; \
       done \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# T5 smoke test
COPY tests/toolchain/run-all-ifrt.sh /tmp/run-all-ifrt.sh

HEALTHCHECK NONE
