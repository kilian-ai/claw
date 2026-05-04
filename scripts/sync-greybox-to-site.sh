#!/bin/sh
# Sync greybox.html into a website repo as index.html (for kilian-ai.com).
#
# Default target assumes a sibling repo named ../kilian-ai.com.
#
# Usage:
#   SITE_DIR=/path/to/site-repo ./scripts/sync-greybox-to-site.sh
#
# Optional env:
#   SITE_DIR   target git repo (default: ../kilian-ai.com)
#   DEST_PATH  destination path inside SITE_DIR (default: index.html)
#   CNAME      optional domain to write/update in SITE_DIR/CNAME (example: kilian-ai.com)
#   PUSH=1     push after commit

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="${SITE_DIR:-$CLAW_DIR/../kilian-ai.com}"
DEST_PATH="${DEST_PATH:-index.html}"
CNAME_VAL="${CNAME:-}"

if [ ! -d "$SITE_DIR/.git" ]; then
  echo "error: target site repo not found at $SITE_DIR" >&2
  echo "       set SITE_DIR=/path/to/site-repo and re-run" >&2
  exit 1
fi

src="$CLAW_DIR/greybox.html"
dst="$SITE_DIR/$DEST_PATH"

if [ ! -f "$src" ]; then
  echo "error: source page missing at $src" >&2
  exit 1
fi

mkdir -p "$(dirname "$dst")"
cp "$src" "$dst"
echo "[sync] copied $src -> $dst"

if [ -n "$CNAME_VAL" ]; then
  printf '%s\n' "$CNAME_VAL" > "$SITE_DIR/CNAME"
  echo "[sync] wrote CNAME=$CNAME_VAL"
fi

msg="$(cd "$CLAW_DIR" && git log -1 --pretty=%s 2>/dev/null || echo 'update greybox page')"
sha="$(cd "$CLAW_DIR" && git rev-parse --short HEAD 2>/dev/null || echo unknown)"

cd "$SITE_DIR"
git add "$DEST_PATH"
if [ -n "$CNAME_VAL" ]; then
  git add CNAME
fi

if git diff --cached --quiet; then
  echo "[sync] no change to commit in target repo"
  exit 0
fi

git commit -m "sync greybox page from kilian-ai/claw@$sha

$msg"
echo "[sync] committed in target repo"

echo "[sync] push with: (cd $SITE_DIR && git push)"
if [ "${PUSH:-0}" = 1 ]; then
  git push
  echo "[sync] pushed"
fi
