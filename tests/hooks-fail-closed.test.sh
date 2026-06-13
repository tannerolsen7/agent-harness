#!/usr/bin/env bash
# HIGH-1 guarantee: every PreToolUse(Bash) guard FAILS CLOSED when jq is missing —
# an un-inspectable command must block (exit 2), never silently pass (exit 0).
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
BASH_BIN=$(command -v bash)
HOOKS="block-dangerous-git block-npm-install block-dangerous-bash"

command -v jq >/dev/null 2>&1 || { echo "hooks-fail-closed.test: jq required to build the input"; exit 1; }

# PATH with the coreutils the hooks use (cat, tr) but WITHOUT jq.
MASK=$(mktemp -d)
for b in cat tr; do p=$(command -v "$b"); [ -n "$p" ] && ln -sf "$p" "$MASK/$b"; done
json=$(jq -nc '{tool_input:{command:"git push origin main"}}')

pass=0; fail=0
for h in $HOOKS; do
  hook="$ROOT/.claude/hooks/$h.sh"
  [ -f "$hook" ] || { echo "  MISSING: $hook"; fail=$((fail+1)); continue; }
  printf '%s' "$json" | PATH="$MASK" "$BASH_BIN" "$hook" >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 2 ]; then
    pass=$((pass+1)); echo "  ok: $h blocks when jq absent"
  else
    echo "  MISS: $h returned $rc (want 2 = block) when jq absent"; fail=$((fail+1))
  fi
done
rm -rf "$MASK"

echo ""
echo "hooks-fail-closed: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
