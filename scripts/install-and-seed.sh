#!/bin/sh
# install-and-seed.sh
#
# Download clawlite.sh and explicitly seed config/data directories.
#
# Usage:
#   TARGET_HOME=/Users/kilian sh ./scripts/install-and-seed.sh
#
# Optional env:
#   CLAW_URL=https://linuxontab.com/local/clawlite.sh
#   CLAW_BIN=/usr/local/bin/claw
#   TARGET_HOME=$HOME
#   XDG_CONFIG_HOME=/path/to/.config
#   XDG_DATA_HOME=/path/to/.local/share

set -eu

CLAW_URL="${CLAW_URL:-https://linuxontab.com/local/clawlite.sh}"
CLAW_BIN="${CLAW_BIN:-/usr/local/bin/claw}"
TARGET_HOME="${TARGET_HOME:-$HOME}"
CFG_HOME="${XDG_CONFIG_HOME:-$TARGET_HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$TARGET_HOME/.local/share}"

mkdir -p "$(dirname "$CLAW_BIN")" "$CFG_HOME" "$DATA_HOME"

if command -v wget >/dev/null 2>&1; then
  wget -qO "$CLAW_BIN" "$CLAW_URL"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$CLAW_URL" -o "$CLAW_BIN"
else
  echo "error: neither wget nor curl is available" >&2
  exit 1
fi
chmod +x "$CLAW_BIN"

# This call seeds config, instructions, prompts, and data dirs.
XDG_CONFIG_HOME="$CFG_HOME" XDG_DATA_HOME="$DATA_HOME" "$CLAW_BIN" --where >/dev/null

# Ensure all expected data subdirs exist even before first chat turn.
mkdir -p "$DATA_HOME/clawlite/sessions" "$DATA_HOME/clawlite/journals"

echo "[claw] installed: $CLAW_BIN"
echo "[claw] config root: $CFG_HOME/clawlite"
echo "[claw] data root:   $DATA_HOME/clawlite"

# Show key seeded files.
for p in \
  "$CFG_HOME/clawlite/config" \
  "$CFG_HOME/clawlite/instructions/00-default.md" \
  "$CFG_HOME/clawlite/prompts/tool-system.txt" \
  "$CFG_HOME/clawlite/prompts/memory-user-compact.txt" \
  "$CFG_HOME/clawlite/prompts/memory-assistant-compact.txt" \
  "$CFG_HOME/clawlite/prompts/mentor-review.txt" \
  "$CFG_HOME/clawlite/prompts/mentor-revision.txt" \
  "$DATA_HOME/clawlite/sessions" \
  "$DATA_HOME/clawlite/journals"
  do
  if [ -e "$p" ]; then
    echo "[ok] $p"
  else
    echo "[missing] $p"
  fi
done
