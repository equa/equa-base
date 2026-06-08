# CLAUDE.md

This file is the single source of truth for AI agents and human
contributors working in `equa-base`.

## Repository purpose

`equa-base` owns the shared base Docker image and GitHub Actions composite
actions for the Equa platform. Every Linux CI job and the shared developer
container consumes the image published here. See [`README.md`](README.md)
for the full resource inventory.

## Branching policy

All work happens on the `beta` branch only. `main` is not updated during
the current rollout phase.

## Commit conventions

All commits follow [Conventional Commits](https://www.conventionalcommits.org/).
The format is enforced by `commitlint`.

Content changes that should appear in the CHANGELOG and trigger a release must
use `feat:`, `fix:`, or `docs:`. Pure maintenance commits (`chore:`, `ci:`,
`style:`) do not trigger a release.

### Agent-specific rules

- The very first commit of a session (initial plan / scaffolding) **must** use
  `chore:` or `docs:` — never a bare prose subject like `"Initial plan"`.

## Workflow

- Trunk-based development. `beta` is the pre-release channel.
- Releases are produced by `semantic-release` on each push to `beta`.
- A successful release triggers `docker build` + `docker push` to
  `ghcr.io/equa/equa-base:beta`.

## Key files

| File | Purpose |
|------|---------|
| `.devcontainer/Dockerfile` | Image definition — source of truth for all toolchain versions |
| `tests/toolchain/run-all.sh` | Smoke tests run inside the built image on every CI push |
| `scripts/install_linux.sh` | Intel oneAPI offline installer (Linux) |
| `scripts/install_windows.bat` | Intel oneAPI offline installer (Windows) |
| `.github/actions/*/action.yml` | Shared composite actions |
| `renovate-presets/default.json` | Org-wide Renovate preset |
| `.github/workflows/release.yml` | CI: lint → build_image → release |

## Adding a new tool to the image

1. Edit `.devcontainer/Dockerfile` — add the install step.
2. Add a version check and hello-world test in `tests/toolchain/run-all.sh`.
3. Commit with `feat: add <tool> to base image`.
4. Push to `beta`; CI builds and smoke-tests the image automatically.

## Composite actions

Actions live under `.github/actions/<name>/action.yml`. When consuming from
another repo, reference them as:

```yaml
uses: equa/equa-base/.github/actions/<name>@beta
```
