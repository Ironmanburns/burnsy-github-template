# Setup — new app from this template

Follow these steps after creating a repository from **burnsy-github-template**.

## 1. Bootstrap

```bash
./scripts/bootstrap.sh \
  --name my-service \
  --owner Ironmanburns \
  --host my-service.burnsy.me \
  --node-port 30110
```

This replaces template tokens (app name, GitHub owner/repo, ingress host,
NodePort, Harness org/project) and renames `charts/__APP_NAME__` to
`charts/<name>`. See the placeholder table in README.md.

Optional flags:

- `--project sample_apps` — Harness projectIdentifier
- `--org default` — Harness orgIdentifier
- `--dry-run` — print substitutions without writing

## 2. Implement the app contract

Your service **must**:

- Listen on `PORT` (default `8080`)
- Expose `GET /healthz` → JSON with healthy status (e.g. `{"status":"ok"}`)
- Expose `GET /version` → `{"version":"...","service":"<app-name>"}`
- Prefer `SERVICE_NAME` and `APP_VERSION` env vars (Helm sets these)

Replace `Dockerfile` with a **multi-stage, non-root** image for your language
(Go, Python, Java, Node, …). Keep `EXPOSE 8080` and a non-root `USER`.

Add a minimal smoke test that hits `/healthz` and `/version` in CI or locally.

## 3. Wire GitHub

- Mark the source repo as a **template** only on `burnsy-github-template` itself;
  app repos are normal repos created *from* the template.
- Protect `main`: require PR, required checks, no direct push.
- Grant the **release GitHub App** contents write (tags + optional releases) on the new repo.
- Prefer squash-merge; the **PR title** is the Conventional Commit release signal.

## 4. Wire Harness

Register four pipelines from `harness/` (or sync via Terraform / platform IaC):

| File | Trigger |
|------|---------|
| `pipeline-release-main.yaml` | Push to branch `main` |
| `pipeline-deploy-tag.yaml` | Tag push matching `v*` |
| `pipeline-pr-preview.yaml` | PR open/sync |
| `pipeline-pr-teardown.yaml` | PR close / merge |

Also create or reuse:

- Harness **Service** identifier matching `__APP_ID__` (chart path `charts/<app>`)
- Environment / infra already used by the sample fleet (`local_kind`, `kind_infra_samples`, …)
- Secrets: `github_release_app_id`, `github_release_app_private_key`
- Connectors: `github_sample_apps`, `local_kind_k8s`, `dockerhub_public`
- Zot image repo named `__APP_NAME__`

**Do not** add a push-to-main trigger on the deploy-tag pipeline.

## 5. Helm / DNS

- Confirm `charts/<app>/values.yaml` image repository, ingress host, and NodePort.
- Point DNS / tunnel for `__INGRESS_HOST__` when exposing outside kind.

## 6. First release

1. Open a PR titled `feat: initial <app> from template` (or similar).
2. Merge to `main` → Release pipeline cuts `v0.1.0` (or next semver).
3. Deploy pipeline runs on that tag only.
4. Verify stable `/healthz` and `/version`.

## Reference implementation

Language-specific example that already follows this contract:
[sample-go](https://github.com/ironmanburns/sample-go).
