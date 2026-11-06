# burnsy-github-template

GitHub **template repository** for new apps on the local platform fleet.

Derived from [sample-go](https://github.com/ironmanburns/sample-go) settings and the
sample-app contract: Conventional Commits → Harness semver tag on `main` →
**tag-only** stable deploy (`v*`), plus PR preview/teardown.

## Quick start (new repo)

1. Use this template (or clone) into a new empty repository.
2. Bootstrap placeholders (also promotes `README.app.md` → app `README.md`):

```bash
./scripts/bootstrap.sh --name my-service --owner Ironmanburns
```

3. Add your language runtime (Dockerfile + app that serves `/healthz` and `/version`).
4. Push a feature branch and open a PR — never push straight to `main`.

See [SETUP.md](./SETUP.md) for the full checklist (Harness, Helm, secrets, URLs).
Mark this repository as a GitHub **Template repository** so “Use this template” works.

## What this ships

| Path | Purpose |
|------|---------|
| [STANDARD.md](./STANDARD.md) | Runtime + delivery contract |
| [AGENTS.md](./AGENTS.md) | Hard rules for coding agents |
| [SETUP.md](./SETUP.md) | Create-a-repo checklist |
| `.github/PULL_REQUEST_TEMPLATE.md` | Conventional Commit PR checklist |
| `.cursor/skills/` | Agent skills (commits, PR flow, contract) |
| `harness/` | Release / deploy-tag / PR preview / teardown pipelines |
| `charts/__APP_NAME__/` | Helm chart (probes on `/healthz`) |
| `scripts/harness-semver-release.sh` | Conventional-commit → `v*` tag |
| `scripts/mint-github-app-token.sh` | Short-lived GitHub App token for tagging |
| `scripts/bootstrap.sh` | Substitute `__APP_*__` placeholders |
| `Dockerfile` | Stub — replace with your multi-stage, non-root image |

## Placeholders (before bootstrap)

| Token | Example |
|-------|---------|
| `__APP_NAME__` | `my-service` (kebab-case; image + chart name) |
| `__APP_ID__` | `my_service` (Harness identifiers) |
| `__GITHUB_OWNER__` | `Ironmanburns` |
| `__GITHUB_REPO__` | `Ironmanburns/my-service` |
| `__INGRESS_HOST__` | `my-service.burnsy.me` |
| `__NODE_PORT__` | `30110` |
| `__HARNESS_PROJECT__` | `sample_apps` (default) |
| `__HARNESS_ORG__` | `default` |

## Delivery model (do not weaken)

```text
PR → merge to main → Harness Release → annotated vX.Y.Z tag
                                      → (optional) GitHub Release
tag v* → Harness Deploy (build/push/scan + Helm) → stable
PR open → preview; PR close → teardown
```

Merging to `main` alone does **not** deploy to stable.
