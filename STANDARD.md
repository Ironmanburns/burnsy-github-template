# App contract

Platform contract for apps created from **burnsy-github-template**.
Reference implementation: `sample-go`. Master copy may also live under
`platform/sample-apps/STANDARD.md` in **local-platform-demo**.

## Runtime

- `PORT` default `8080`
- `GET /healthz` — liveness/readiness probe target
- `GET /version` → `{"version","service":"<app-name>"}`
- Prefer env `SERVICE_NAME` and `APP_VERSION` (Helm injects both)
- Non-root container (distroless / nonroot USER, or equivalent)

## Delivery

- Harness **release** on push to `main` → annotated `v*` tag (`scripts/harness-semver-release.sh`)
- Harness **stable deploy** on tag `v*` only (`harness/pipeline-deploy-tag.yaml`)
- PR preview + teardown pipelines
- No release-please; no stable deploy from bare `main`
- No secrets or credentials in the repository tree

## Agent / PR hygiene

- Feature branches + PRs only; never push to `main`
- PR title is a [Conventional Commit](https://www.conventionalcommits.org/) subject
  (`feat:` / `fix:` / `perf:` / `feat!:` …) — squash-merge titles drive semver
