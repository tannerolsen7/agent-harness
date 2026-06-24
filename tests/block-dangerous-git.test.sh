#!/usr/bin/env bash
# Tests for the --no-verify and core.hooksPath blocks in block-dangerous-git.sh.
# Feeds {"tool_input":{"command":"..."}} to the hook and asserts exit code:
#   block = exit 2 (dangerous), allow = exit 0 (safe).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE

set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.claude/hooks/block-dangerous-git.sh"
BASH_BIN=$(command -v bash)

command -v jq >/dev/null 2>&1 || { echo "block-dangerous-git.test: jq required"; exit 1; }
[ -f "$HOOK" ] || { echo "block-dangerous-git.test: $HOOK not found"; exit 1; }

pass=0; fail=0

run() {
  local expect="$1" cmd="$2" json rc
  json=$(jq -nc --arg c "$cmd" '{tool_input:{command:$c}}')
  printf '%s' "$json" | "$BASH_BIN" "$HOOK" >/dev/null 2>&1
  rc=$?
  if [ "$expect" = block ]; then
    if [ "$rc" -eq 2 ]; then pass=$((pass+1)); else echo "  MISS (want BLOCK, got $rc): $cmd"; fail=$((fail+1)); fi
  else
    if [ "$rc" -eq 0 ]; then pass=$((pass+1)); else echo "  MISS (want ALLOW, got $rc): $cmd"; fail=$((fail+1)); fi
  fi
}

echo "── --no-verify commit (must BLOCK) ──"
run block 'git commit --no-verify -m "bypass"'
run block 'git commit -n -m "bypass"'
run block 'git commit -nm "bypass"'

echo "── --no-verify push (must BLOCK) ──"
run block 'git push --no-verify'
run block 'git push origin feat/x --no-verify'

echo "── core.hooksPath redirect (must BLOCK) ──"
run block 'git -c core.hooksPath=/dev/null commit -m "bypass"'
run block 'git -c core.hooksPath=/tmp/fake push origin main'

echo "── safe operations (must ALLOW) ──"
run allow 'git commit -m "normal commit"'
run allow 'git commit -am "stage all and commit"'
run allow 'git push origin feat/my-feature'
run allow 'git push -u origin feat/my-feature'
run allow 'git -c user.email=x@y.com commit -m "set email"'

echo ""
echo "block-dangerous-git: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
