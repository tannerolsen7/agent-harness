#!/usr/bin/env bash
# OPTIONAL, one-time-per-MACHINE hardening: place the OS-level managed settings —
# the unbypassable floor (P0-4 / HIGH-2). One command instead of manual JSON editing.
#
# The harness is fully functional and safe for NORMAL use without this: the in-repo
# .claude/settings.json denies + the five PreToolUse hooks do the enforcement. This
# adds the belt-and-suspenders layer that survives a checkout-old-commit, a chmod -x
# on a hook, or an attempt to edit settings.json.
#
# It is a HUMAN-run step by design: the point is a lock the agent cannot place or
# reach. You authorize it with your admin password; the agent never gains privilege
# (and can't run this — it can't answer the sudo prompt).
#
# Usage:
#   bash scripts/install-locks.sh           # place it (prompts for sudo)
#   bash scripts/install-locks.sh --check    # show status only, place nothing
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TEMPLATE="$ROOT/docs/security/managed-settings.template.json"

case "$(uname -s)" in
  Darwin) DEST_DEFAULT="/Library/Application Support/ClaudeCode/managed-settings.json" ;;
  Linux)  DEST_DEFAULT="/etc/claude-code/managed-settings.json" ;;
  *) echo "install-locks: unknown OS '$(uname -s)' — see docs/security/locks.md for the path." >&2; exit 1 ;;
esac
# DEST + SUDO are overridable for tests (a user-writable temp dest, no sudo). Default = the real path.
DEST="${INSTALL_LOCKS_DEST:-$DEST_DEFAULT}"
SUDO="${INSTALL_LOCKS_SUDO-sudo}"

# Print a file's permission bits portably. GNU stat (`-c`) FIRST, then BSD/macOS (`-f`): on Linux
# `stat -f` means --file-system and "succeeds" with the wrong output, so a BSD-first order silently
# returns filesystem text on CI instead of the mode. (That broke install-locks.test.sh on CI.)
_mode() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null || echo "?"; }

if [ "${1:-}" = "--check" ]; then
  if [ ! -f "$DEST" ]; then
    echo "managed-settings NOT placed (optional hardening). To add it: bash scripts/install-locks.sh"
  elif [ ! -r "$DEST" ]; then
    # Present but unreadable: Claude Code reads this policy on startup and EXITS if it can't —
    # the exact failure a mode-600 install causes. Fail the check loudly, with the fix.
    echo "managed-settings PRESENT but NOT READABLE (mode $(_mode "$DEST")) at $DEST" >&2
    echo "  → Claude Code will fail to start (cannot read the managed policy)." >&2
    echo "  → Fix: sudo chmod 644 \"$DEST\"   (keeps root ownership; readable, not user-writable)" >&2
    exit 1
  else
    echo "managed-settings PRESENT + readable (mode $(_mode "$DEST")): $DEST"
  fi
  exit 0
fi

[ -f "$TEMPLATE" ] || { echo "install-locks: template missing: $TEMPLATE" >&2; exit 1; }

# Strip the _comment key (some versions reject unknown keys) before placing.
TMP=$(mktemp)
trap 'rm -f "${TMP:-}"' EXIT   # never leak the temp policy, even if a chmod/cp fails under set -e
if command -v jq >/dev/null 2>&1; then jq 'del(._comment)' "$TEMPLATE" > "$TMP"; else grep -v '"_comment"' "$TEMPLATE" > "$TMP"; fi

echo "Placing the OS-level managed settings (the unbypassable floor)."
echo "  from: $TEMPLATE"
echo "  to:   $DEST"
echo "You'll be asked for your admin password — that is you authorizing a lock the agent cannot place itself."
$SUDO mkdir -p "$(dirname "$DEST")"
$SUDO chmod 755 "$(dirname "$DEST")"   # the dir must be world-traversable so the file can be reached
$SUDO cp "$TMP" "$DEST"
# CRITICAL: Claude Code READS this managed policy on startup and EXITS if it can't. `cp` carries the
# mktemp 600 mode, leaving the file root-only-readable — which silently breaks Claude Code startup.
# Force 644: root-owned + root-writable (tamper-resistant) but WORLD-READABLE so Claude Code can read it.
$SUDO chmod 644 "$DEST"
rm -f "$TMP"
# Hard-fail if the policy still isn't readable — don't claim success on a state that breaks startup.
if [ ! -r "$DEST" ]; then
  echo "install-locks: ERROR — $DEST is not readable after install (mode $(_mode "$DEST"))." >&2
  echo "  Claude Code will fail to start. Fix: sudo chmod 644 \"$DEST\"" >&2
  exit 1
fi
echo "Done. Verify with: bash scripts/install-locks.sh --check"
