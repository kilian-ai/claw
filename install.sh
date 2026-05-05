#!/bin/sh
# install.sh — install claw into /usr/local/bin and exec it.
#
# Usage:
#   wget -qO- https://getclaw.site/install.sh | sh
#
# Or via LinuxOnTab's ?postboot= URL parameter (which auto-expands an
# http(s) URL to a wget-to-tempfile + sh, preserving the controlling
# TTY so the claw REPL stays interactive):
#
#   https://linuxontab.com/shell/?postboot=https://getclaw.site/install.sh

set -e
wget -qO /usr/local/bin/claw https://getclaw.site/claw
chmod +x /usr/local/bin/claw
echo "[claw-install] /usr/local/bin/claw installed ($(wc -c < /usr/local/bin/claw) bytes)"

# Install rlwrap for arrow keys / history in the REPL (best-effort).
if ! command -v rlwrap >/dev/null 2>&1; then
  if command -v apk >/dev/null 2>&1; then
    apk add --no-cache rlwrap >/dev/null 2>&1 && echo "[claw-install] rlwrap installed" || true
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get install -y -q rlwrap >/dev/null 2>&1 && echo "[claw-install] rlwrap installed" || true
  fi
fi

# Reset terminal modes (icrnl/echo/etc) and re-attach to the controlling
# TTY before launching claw. Without </dev/tty, claw inherits whatever
# stdin our wrapper script was invoked with — which after `wget | sh` or
# `sh /tmp/postboot.sh` may not satisfy isatty(0), causing node's readline
# to fall back to cooked mode and render Enter as a literal ^M.
stty sane 2>/dev/null || true
export TERM="${TERM:-linux}"
exec claw </dev/tty >/dev/tty 2>&1
