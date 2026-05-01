#!/bin/sh
# guest-bootstrap.sh
#
# Run this inside a fresh LinuxOnTab guest (Alpine v86) to:
#   1. Install git + a credential helper
#   2. Set git identity
#   3. Clone github.com/kilian-ai/claw to ~/claw
#   4. Symlink /usr/local/bin/claw -> ~/claw/clawlite.sh
#
# Usage (interactive — prompts for name/email/PAT):
#   wget -qO- https://raw.githubusercontent.com/kilian-ai/claw/main/scripts/guest-bootstrap.sh | sh
#
# Or non-interactively:
#   GIT_NAME="Your Name" GIT_EMAIL="you@x.com" GH_USER=youruser GH_TOKEN=ghp_... \
#     sh ./guest-bootstrap.sh

set -eu

if ! command -v apk >/dev/null 2>&1; then
  echo "error: apk not found (this script targets Alpine)" >&2
  exit 1
fi

apk add --no-cache git curl jq >/dev/null

GIT_NAME="${GIT_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"
GH_USER="${GH_USER:-}"
GH_TOKEN="${GH_TOKEN:-}"

if [ -z "$GIT_NAME" ];  then printf 'git user.name:  '  ; read -r GIT_NAME ;  fi
if [ -z "$GIT_EMAIL" ]; then printf 'git user.email: '  ; read -r GIT_EMAIL ; fi

git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper 'store --file=/root/.git-credentials'
git config --global init.defaultBranch main

# Pre-seed credential store so first push is non-interactive.
if [ -n "$GH_USER" ] && [ -n "$GH_TOKEN" ]; then
  printf 'https://%s:%s@github.com\n' "$GH_USER" "$GH_TOKEN" \
    > /root/.git-credentials
  chmod 600 /root/.git-credentials
  echo "[bootstrap] credential store seeded"
fi

mkdir -p "$HOME"
cd "$HOME"
if [ -d claw/.git ]; then
  echo "[bootstrap] ~/claw already exists, pulling latest"
  (cd claw && git pull --ff-only)
else
  git clone https://github.com/kilian-ai/claw "$HOME/claw"
fi

ln -sf "$HOME/claw/clawlite.sh" /usr/local/bin/claw
chmod +x "$HOME/claw/clawlite.sh"

echo
echo "[bootstrap] done. claw -> $HOME/claw/clawlite.sh"
echo "  edit:    \$EDITOR ~/claw/clawlite.sh"
echo "  commit:  cd ~/claw && git add -A && git commit -m '...' && git push"
echo "  run:     claw 'hello'"
