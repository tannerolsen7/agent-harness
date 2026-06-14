#!/usr/bin/env bash
# install-locks.sh must place the managed-settings policy WORLD-READABLE (mode 644) — Claude Code
# reads it on startup and EXITS if it can't, which a mode-600 install silently caused. Hermetic:
# override DEST to a temp path + skip sudo (INSTALL_LOCKS_SUDO=) so no real install / no privilege.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/install-locks.sh"
[ -x "$SCRIPT" ] || { echo "test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
ck() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }
mode_of() { stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1" 2>/dev/null || echo "?"; }

TMP=$(mktemp -d)
DEST="$TMP/managed/managed-settings.json"

echo "── place: file is mode 644 + readable + valid JSON ──"
INSTALL_LOCKS_DEST="$DEST" INSTALL_LOCKS_SUDO= bash "$SCRIPT" >/dev/null 2>&1
[ -f "$DEST" ]; ck "$?" "managed-settings placed at the override dest"
[ "$(mode_of "$DEST")" = "644" ] && ck 0 "mode is 644 (world-readable, root-writable only)" \
  || { echo "  MISS: mode is $(mode_of "$DEST"), not 644 — Claude Code needs world-read"; fail=$((fail+1)); }
[ "$(mode_of "$(dirname "$DEST")")" = "755" ] && ck 0 "dir mode is 755 (world-traversable)" \
  || { echo "  MISS: dir mode is $(mode_of "$(dirname "$DEST")"), not 755 — file unreachable"; fail=$((fail+1)); }
[ -r "$DEST" ]; ck "$?" "placed file is readable by the current user"
if command -v jq >/dev/null 2>&1; then
  jq -e . "$DEST" >/dev/null 2>&1; ck "$?" "placed file is valid JSON"
  jq -e 'has("_comment")|not' "$DEST" >/dev/null 2>&1; ck "$?" "_comment key stripped"
fi

echo "── --check: passes when readable ──"
INSTALL_LOCKS_DEST="$DEST" INSTALL_LOCKS_SUDO= bash "$SCRIPT" --check >/dev/null 2>&1
ck "$?" "--check exits 0 when the policy is present + readable"

echo "── --check: FAILS loudly when present-but-unreadable (the mode-600 bug) ──"
chmod 000 "$DEST" 2>/dev/null
if [ -r "$DEST" ]; then
  echo "  (skipped: running as root — chmod 000 is still readable)"; pass=$((pass+1))
else
  INSTALL_LOCKS_DEST="$DEST" INSTALL_LOCKS_SUDO= bash "$SCRIPT" --check >/dev/null 2>&1; rc=$?
  [ "$rc" -ne 0 ] && ck 0 "--check exits non-zero on an unreadable policy file" \
    || { echo "  MISS: --check should fail on an unreadable policy (the exact startup-break)"; fail=$((fail+1)); }
fi
chmod 644 "$DEST" 2>/dev/null
rm -rf "$TMP"

echo ""
echo "install-locks: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
