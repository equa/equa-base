# equa-base

Public base Docker image and shared GitHub Actions composite actions for the Equa platform.

## What this repo provides

| Resource | Path | Consumers |
|----------|------|-----------|
| Base image | `ghcr.io/equa/equa-base:beta` | `equa-ci` devcontainer; all module CI jobs via `container:` |
| oneAPI install action | `.github/actions/oneapi-install/` | `equa-superlu` CI; future C/Fortran module repos |
| Setup-uv action | `.github/actions/setup-uv/` | All repos needing uv |
| Setup-node action | `.github/actions/setup-node/` | All repos needing Node 24 |
| Publish-wiki action | `.github/actions/publish-wiki/` | Module repos publishing a subdirectory of the Azure DevOps wiki |
| Semantic-release action | `.github/actions/semantic-release/` | All repos using semantic-release |
| Renovate preset | `renovate-presets/default.json` | All Equa repos via `github>equa/equa-base//renovate-presets/default` |
| oneAPI offline installer scripts | `scripts/install_linux.sh`, `scripts/install_windows.bat` | `oneapi-install` composite action |

## Image contents

Ubuntu 24.04 + Python 3.12 + Node 24 + uv + Intel oneAPI dpcpp/ifort (APT) + SBCL + Go + az CLI + gh CLI + cmake + clang-format + shellcheck + markdownlint-cli2 + cspell + lychee.

### Lisp toolchain

The image ships a per-user Common Lisp development toolchain owned by the
`vscode` user (UID 1000):

| Component | Detail |
|-----------|--------|
| SBCL | `sbcl` apt package, on `PATH` for every user |
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
