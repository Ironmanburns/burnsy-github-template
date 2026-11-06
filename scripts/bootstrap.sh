#!/usr/bin/env bash
# Substitute template placeholders for a new app repository.
#
# Usage:
#   ./scripts/bootstrap.sh --name my-service --owner Ironmanburns
#   ./scripts/bootstrap.sh --name my-service --owner Ironmanburns --host my-service.burnsy.me --node-port 30110
#   ./scripts/bootstrap.sh --name my-service --owner Ironmanburns --dry-run
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME=""
GITHUB_OWNER=""
INGRESS_HOST=""
NODE_PORT=""
HARNESS_PROJECT="sample_apps"
HARNESS_ORG="default"
DRY_RUN=false

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  echo "Options:"
  echo "  --name NAME          App name (kebab-case) [required]"
  echo "  --owner OWNER        GitHub owner/org login [required]"
  echo "  --host HOST          Ingress host (default: NAME.burnsy.me)"
  echo "  --node-port PORT     Service NodePort (default: 30100)"
  echo "  --project ID         Harness projectIdentifier (default: sample_apps)"
  echo "  --org ID             Harness orgIdentifier (default: default)"
  echo "  --dry-run            Print plan only"
  echo "  -h, --help           Show help"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) APP_NAME="${2:-}"; shift 2 ;;
    --owner) GITHUB_OWNER="${2:-}"; shift 2 ;;
    --host) INGRESS_HOST="${2:-}"; shift 2 ;;
    --node-port) NODE_PORT="${2:-}"; shift 2 ;;
    --project) HARNESS_PROJECT="${2:-}"; shift 2 ;;
    --org) HARNESS_ORG="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$APP_NAME" || -z "$GITHUB_OWNER" ]]; then
  echo "--name and --owner are required" >&2
  usage >&2
  exit 1
fi

if [[ ! "$APP_NAME" =~ ^[a-z0-9]+([.-][a-z0-9]+)*$ ]]; then
  echo "APP_NAME must be lowercase kebab/dot style: got '$APP_NAME'" >&2
  exit 1
fi

APP_ID="$(echo "$APP_NAME" | tr '.-' '_')"
GITHUB_REPO="${GITHUB_OWNER}/${APP_NAME}"
INGRESS_HOST="${INGRESS_HOST:-${APP_NAME}.burnsy.me}"
NODE_PORT="${NODE_PORT:-30100}"

if [[ ! "$NODE_PORT" =~ ^[0-9]+$ ]] || (( NODE_PORT < 30000 || NODE_PORT > 32767 )); then
  echo "NODE_PORT must be an integer in 30000–32767" >&2
  exit 1
fi

echo "Bootstrap plan:"
echo "  __APP_NAME__        → $APP_NAME"
echo "  __APP_ID__          → $APP_ID"
echo "  __GITHUB_OWNER__    → $GITHUB_OWNER"
echo "  __GITHUB_REPO__     → $GITHUB_REPO"
echo "  __INGRESS_HOST__    → $INGRESS_HOST"
echo "  __NODE_PORT__       → $NODE_PORT"
echo "  __HARNESS_PROJECT__ → $HARNESS_PROJECT"
echo "  __HARNESS_ORG__     → $HARNESS_ORG"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY_RUN: no files written"
  exit 0
fi

# Substitute placeholders everywhere except:
#   - .git/
#   - this bootstrap script (must keep token names for future runs on copies)
#   - README.md (template landing page; swapped for README.app.md at the end)
mapfile -t FILES < <(
  find . \
    -path './.git' -prune -o \
    -type f \
    ! -name '*.png' ! -name '*.jpg' ! -name '*.jpeg' ! -name '*.gif' ! -name '*.webp' \
    ! -name '*.ico' ! -name '*.pdf' ! -name '*.zip' \
    ! -path './scripts/bootstrap.sh' \
    ! -path './README.md' \
    -print \
    | sed 's|^\./||' \
    | sort
)

replace_in_file() {
  local file="$1"
  # Skip binary-ish files quickly
  if grep -Iq . "$file" 2>/dev/null; then
    :
  else
    return 0
  fi
  if ! grep -qE '__APP_NAME__|__APP_ID__|__GITHUB_OWNER__|__GITHUB_REPO__|__INGRESS_HOST__|__NODE_PORT__|__HARNESS_PROJECT__|__HARNESS_ORG__' "$file"; then
    return 0
  fi
  local tmp
  tmp="$(mktemp)"
  sed \
    -e "s|__APP_NAME__|${APP_NAME}|g" \
    -e "s|__APP_ID__|${APP_ID}|g" \
    -e "s|__GITHUB_OWNER__|${GITHUB_OWNER}|g" \
    -e "s|__GITHUB_REPO__|${GITHUB_REPO}|g" \
    -e "s|__INGRESS_HOST__|${INGRESS_HOST}|g" \
    -e "s|__NODE_PORT__|${NODE_PORT}|g" \
    -e "s|__HARNESS_PROJECT__|${HARNESS_PROJECT}|g" \
    -e "s|__HARNESS_ORG__|${HARNESS_ORG}|g" \
    "$file" >"$tmp"
  mv "$tmp" "$file"
  echo "  updated $file"
}

for f in "${FILES[@]}"; do
  replace_in_file "$f"
done

CHART_SRC="charts/__APP_NAME__"
CHART_DST="charts/${APP_NAME}"
if [[ -d "$CHART_SRC" ]]; then
  if [[ -e "$CHART_DST" && "$CHART_SRC" != "$CHART_DST" ]]; then
    echo "Refusing to overwrite existing $CHART_DST" >&2
    exit 1
  fi
  mv "$CHART_SRC" "$CHART_DST"
  echo "  renamed $CHART_SRC → $CHART_DST"
fi

if [[ -f README.app.md ]]; then
  mv README.app.md README.md
  echo "  promoted README.app.md → README.md"
fi

# Leave a marker so agents know bootstrap already ran.
cat > .template-bootstrapped <<EOF
app_name=${APP_NAME}
app_id=${APP_ID}
github_repo=${GITHUB_REPO}
bootstrapped_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
echo "  wrote .template-bootstrapped"

echo "Done. Next: implement Dockerfile + /healthz + /version, then follow SETUP.md."
