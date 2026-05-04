#!/bin/sh
# deploy-site.sh — build and deploy getclaw.site
#
# GitHub Pages (default):
#   ./scripts/deploy-site.sh
#
# VPS via rsync:
#   DEPLOY_HOST=user@1.2.3.4 ./scripts/deploy-site.sh
#   DEPLOY_HOST=user@1.2.3.4 DEPLOY_PATH=/var/www/html ./scripts/deploy-site.sh
#
# Environment:
#   DEPLOY_HOST   — if set, use rsync instead of GitHub Pages
#   DEPLOY_PATH   — remote path for rsync (default: /var/www/getclaw.site)
#   CLAW_URL      — source URL for the claw script (default: local clawlite.sh)
#   GIT_REMOTE    — git remote to push gh-pages to (default: origin)

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="$REPO_DIR/site"

DEPLOY_HOST="${DEPLOY_HOST:-}"
DEPLOY_PATH="${DEPLOY_PATH:-/var/www/getclaw.site}"
GIT_REMOTE="${GIT_REMOTE:-origin}"

# ── 1. Bundle clawlite.sh as site/claw ──────────────────────────────────────
echo "[deploy] bundling clawlite.sh → site/claw"
cp "$REPO_DIR/clawlite.sh" "$SITE_DIR/claw"

# ── 2. Choose deployment method ──────────────────────────────────────────────
if [ -n "$DEPLOY_HOST" ]; then

  # ── RSYNC TO VPS ──────────────────────────────────────────────────────────
  echo "[deploy] method: rsync"
  echo "[deploy] target: $DEPLOY_HOST:$DEPLOY_PATH"

  if ! command -v rsync >/dev/null 2>&1; then
    echo "error: rsync not found" >&2
    exit 1
  fi

  rsync -avz --delete \
    --exclude='.git' \
    --exclude='CNAME' \
    "$SITE_DIR/" "$DEPLOY_HOST:$DEPLOY_PATH/"

  echo ""
  echo "[deploy] done — site synced to $DEPLOY_HOST:$DEPLOY_PATH"
  echo "[deploy] make sure nginx/caddy is configured to serve $DEPLOY_PATH"

else

  # ── GITHUB PAGES ─────────────────────────────────────────────────────────
  echo "[deploy] method: GitHub Pages (gh-pages branch)"

  if ! command -v git >/dev/null 2>&1; then
    echo "error: git not found" >&2
    exit 1
  fi

  cd "$REPO_DIR"

  # Stage the bundled claw file so subtree push includes it.
  git add site/claw 2>/dev/null || true
  if ! git diff --cached --quiet 2>/dev/null; then
    git commit -m "chore: sync site/claw from clawlite.sh"
  fi

  echo "[deploy] pushing site/ subtree to $GIT_REMOTE gh-pages …"
  # Force-push via split so we're never blocked by non-fast-forward on gh-pages.
  local_ref="$(git subtree split --prefix site HEAD)"
  git push "$GIT_REMOTE" "${local_ref}:gh-pages" --force

  echo ""
  echo "[deploy] done."
  echo "[deploy] GitHub Pages will serve: https://getclaw.site"
  echo ""
  echo "If this is your first deploy:"
  echo "  1. Go to: https://github.com/kilian-ai/claw/settings/pages"
  echo "  2. Source → Deploy from a branch → Branch: gh-pages / root"
  echo "  3. Custom domain → getclaw.site  (then Save)"
  echo "  4. Tick 'Enforce HTTPS' once the cert is provisioned (~5 min)"

fi
