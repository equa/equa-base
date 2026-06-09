# CLAUDE.md

This file is the single source of truth for AI agents and human
contributors working in `equa-base`.

## Repository purpose

`equa-base` owns the shared base Docker images and GitHub Actions composite
actions for the Equa platform. The image is a slim **four-tier FROM-chain** on
plain `ubuntu:24.04`; each tier extends the one below, so a CI job pulls the
smallest tier it needs:

| Tier | Image | For |
|------|-------|-----|
| T1 | `equa-base-ci` | checks jobs (lint, ruff, version dry-run) — no az/oneAPI/Lisp |
| T2 | `equa-base-lite` | release jobs (adds az CLI) |
| T3 | `equa-base` | compile / Lisp jobs (adds oneAPI, SBCL/Quicklisp/Parachute, Go, the `vscode` user) |
| T4 | `equa-base-dev` | the developer container (adds dev conveniences) |

Every Linux CI job and the developer container consume a tier published here.
See [`README.md`](README.md) for the full resource inventory.

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
- A successful release builds all four tier targets and pushes
  `equa-base-ci` / `equa-base-lite` / `equa-base` / `equa-base-dev` in lockstep
  (`beta`, `beta-<sha>`, and the semver tag).

## Key files

| File | Purpose |
|------|---------|
| `.devcontainer/Dockerfile` | Four-tier multi-stage image definition — source of truth for all toolchain versions |
| `tests/toolchain/run-all*.sh` | Per-tier smoke tests: `run-all-ci.sh` (T1), `run-all-lite.sh` (T2), `run-all.sh` (T3), `run-all-dev.sh` (T4), run on every CI push |
| `scripts/install_linux.sh` | Intel oneAPI offline installer (Linux) |
| `scripts/install_windows.bat` | Intel oneAPI offline installer (Windows) |
| `.github/actions/*/action.yml` | Shared composite actions |
| `renovate-presets/default.json` | Org-wide Renovate preset |
| `.github/workflows/release.yml` | CI: lint → build_image → release |

## Adding a new tool to the image

1. Edit `.devcontainer/Dockerfile` — add the install step to the **lowest tier
   that needs the tool** (checks tools → T1; az → T2; compiler/Lisp/Go → T3;
   dev-only conveniences → T4). Higher tiers inherit it via the FROM-chain.
2. Add a version/hello-world check to that tier's smoke test
   (`run-all-ci.sh` / `run-all-lite.sh` / `run-all.sh` / `run-all-dev.sh`).
3. Commit with `feat: add <tool> to base image`.
4. Push to `beta`; CI builds and smoke-tests the image automatically.

## Composite actions

Actions live under `.github/actions/<name>/action.yml`. When consuming from
another repo, reference them as:

```yaml
uses: equa/equa-base/.github/actions/<name>@beta
```
