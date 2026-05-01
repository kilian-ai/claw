#!/bin/sh
# Sync clawlite.sh from this repo into the LinuxOnTab repo so that
# GitHub Pages (linuxontab.com/local/clawlite.sh) serves the latest.
#
# Assumes the LinuxOnTab repo is checked out as a sibling of this repo
# at $LOT_DIR (default: ../LinuxOnTab relative to this script).

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOT_DIR="${LOT_DIR:-$CLAW_DIR/../LinuxOnTab}"

if [ ! -d "$LOT_DIR/.git" ]; then
  echo "error: LinuxOnTab repo not found at $LOT_DIR" >&2
  echo "       set LOT_DIR=/path/to/LinuxOnTab and re-run" >&2
  exit 1
fi

src="$CLAW_DIR/clawlite.sh"
dst="$LOT_DIR/local/clawlite.sh"

if [ ! -f "$src" ]; then
  echo "error: $src missing" >&2
  exit 1
fi

if cmp -s "$src" "$dst" 2>/dev/null; then
  echo "[sync] $dst already up to date"
  exit 0
fi

cp "$src" "$dst"
chmod +x "$dst"
echo "[sync] copied clawlite.sh -> $dst"

# Try to grab the most recent claw commit subject for a tidy message.
msg="$(cd "$CLAW_DIR" && git log -1 --pretty=%s 2>/dev/null || echo 'update')"
sha="$(cd "$CLAW_DIR" && git rev-parse --short HEAD 2>/dev/null || echo unknown)"

cd "$LOT_DIR"
git add local/clawlite.sh
if git diff --cached --quiet; then
  echo "[sync] no LinuxOnTab change to commit"
  exit 0
fi
git commit -m "sync clawlite.sh from kilian-ai/claw@$sha

$msg"
echo "[sync] committed in LinuxOnTab. Push with:"
echo "       (cd $LOT_DIR && git push)"

if [ "${PUSH:-0}" = 1 ]; then
  git push
  echo "[sync] pushed"
fi
