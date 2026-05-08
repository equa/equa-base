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
cd /home/iakovn/repos/equa-base
git checkout beta
# … make changes …
git commit -m "feat: description"
git push origin beta
```

See [`AGENTS.md`](AGENTS.md) for full contributor conventions.
