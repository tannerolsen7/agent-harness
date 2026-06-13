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
  Darwin) DEST="/Library/Application Support/ClaudeCode/managed-settings.json" ;;
  Linux)  DEST="/etc/claude-code/managed-settings.json" ;;
  *) echo "install-locks: unknown OS '$(uname -s)' — see docs/security/locks.md for the path." >&2; exit 1 ;;
esac

if [ "${1:-}" = "--check" ]; then
  if [ -f "$DEST" ]; then echo "managed-settings PRESENT: $DEST"; else echo "managed-settings NOT placed (optional hardening). To add it: bash scripts/install-locks.sh"; fi
  exit 0
fi

[ -f "$TEMPLATE" ] || { echo "install-locks: template missing: $TEMPLATE" >&2; exit 1; }

# Strip the _comment key (some versions reject unknown keys) before placing.
TMP=$(mktemp)
if command -v jq >/dev/null 2>&1; then jq 'del(._comment)' "$TEMPLATE" > "$TMP"; else grep -v '"_comment"' "$TEMPLATE" > "$TMP"; fi

echo "Placing the OS-level managed settings (the unbypassable floor)."
echo "  from: $TEMPLATE"
echo "  to:   $DEST"
echo "You'll be asked for your admin password — that is you authorizing a lock the agent cannot place itself."
sudo mkdir -p "$(dirname "$DEST")"
sudo cp "$TMP" "$DEST"
rm -f "$TMP"
echo "Done. Verify with: bash scripts/install-locks.sh --check"
