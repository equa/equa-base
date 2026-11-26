# equa-base

Public base Docker image and shared GitHub Actions composite actions for the Equa platform.

## What this repo provides

| Resource | Path | Consumers |
|----------|------|-----------|
| Base images (6-tier) | `ghcr.io/equa/equa-base-ci` / `-lite` / `equa-base` / `-dev` / `equa-base-ifrt` / `equa-base-web` | checks / release / compile / devcontainer / runtime-vendor / web checks jobs respectively |
| oneAPI install action | `.github/actions/oneapi-install/` | `equa-superlu` CI; future C/Fortran module repos |
| Setup-uv action | `.github/actions/setup-uv/` | All repos needing uv |
| Setup-node action | `.github/actions/setup-node/` | All repos needing Node 24 |
| Semantic-release action | `.github/actions/semantic-release/` | All repos using semantic-release |
| Renovate preset | `renovate-presets/default.json` | All Equa repos via `github>equa/equa-base//renovate-presets/default` |
| oneAPI offline installer scripts | `scripts/install_linux.sh`, `scripts/install_windows.bat` | `oneapi-install` composite action |

## Image contents

Slim tiers on plain `ubuntu:24.04`; T1-T4 form a FROM-chain, T5 extends T2
and T6 extends T1, so a CI job pulls the smallest tier it needs:

| Tier | Image | Adds over the tier below | For |
|------|-------|--------------------------|-----|
| T1 | `equa-base-ci` | Python 3.12 + Node 24 + uv + cmake + clang-format + shellcheck + gh + openssh-client + markdownlint-cli2 + cspell + lychee | checks jobs |
| T2 | `equa-base-lite` | az CLI + `azure-devops` extension | release jobs |
| T3 | `equa-base` | Intel oneAPI dpcpp/ifort + SBCL/Quicklisp/Parachute + Go, and the `vscode` user | compile / Lisp jobs |
| T4 | `equa-base-dev` | developer conveniences (`less`, `nano`, `procps`, `unzip`, `locales`, `man-db`, `rsync`), full Chromium with its libraries (Playwright, `PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright`) | local devcontainer |
| T5 | `equa-base-ifrt` | Intel Fortran runtime (libifcoremt/libifport/libimf); no compiler, Lisp, or Go; inherits az from T2 | runtime-vendor jobs (auditwheel etc.) |
| T6 | `equa-base-web` | Playwright's headless Chromium shell with its libraries (`PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright`) on T1 | checks jobs of web repos (equa.ci `test_ui`) |

Per-repo Node tools (`semantic-release`, `commitlint`) are pinned by each repo's
`package-lock.json` and installed via `npm ci`, not baked. The shared docs/lint
tools (`markdownlint-cli2`, `cspell`, `lychee`) are baked into T1.

T4 and T6 share one `PLAYWRIGHT_VERSION` (Dockerfile `ARG`); Renovate raises
it with npm `@playwright/test`, and a beta release ships the new browser.

### Lisp toolchain

T3 and T4 ship a per-user Common Lisp development toolchain owned by the
`vscode` user (UID 1000 — recreated in T3 on the slim base):

| Component | Detail |
|-----------|--------|
| SBCL | 2.6.5 built from source (public `github.com/sbcl/sbcl` tag, `--fancy` so core compression is available), installed under `/usr/local`, on `PATH` for every user |
| Quicklisp | Bootstrapped into `/home/vscode/quicklisp`, dist pinned to `2026-01-01` |
| `~/.sbclrc` | Holds the `(load "~/quicklisp/setup.lisp")` init form (written by `ql:add-to-init-file`) |
| Parachute | Test framework, pre-fetched into the resident dist (`parachute-20260101-git`) |

Because Quicklisp and Parachute follow the conventional per-user layout, a
shell running as `vscode` can `(ql:quickload :parachute)` and run a Parachute
suite with **no network access and no manual setup** — the dist is resident in
the image. The dist version and the Parachute release are pinned so a rebuild
of a given image tag resolves the same libraries.

Consumers that run the image as a different user (e.g. CI running the container
as `root`) will not find `~/quicklisp/setup.lisp` on their `HOME`; pin the
container and CI to the `vscode` user to use the resident toolchain.

See the platform docs Base Image page (`equa-platform-docs/docs/ci/image.md`,
"Lisp toolchain" section) for the full reference.

## Usage

### In a CI workflow

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container: ghcr.io/equa/equa-base:beta
    steps:
      - uses: actions/checkout@v4
      - run: uv sync
      - run: uv run doit build
```

### Consuming a composite action

```yaml
- uses: equa/equa-base/.github/actions/oneapi-install@beta
  with:
    os: linux
```

### Extending the Renovate preset

```json
{
  "extends": ["github>equa/equa-base//renovate-presets/default"]
}
```

## Development

All work happens on the `beta` branch. `main` is not used during the current rollout phase.

Commits follow [Conventional Commits](https://www.conventionalcommits.org/). Releases are produced by `semantic-release` on each push to `beta`.

```bash
cd /path/to/equa-base
git checkout beta
# … make changes …
git commit -m "feat: description"
git push origin beta
```

See [`CLAUDE.md`](CLAUDE.md) for full contributor conventions.
