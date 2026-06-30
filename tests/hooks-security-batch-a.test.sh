#!/usr/bin/env bash
# Tests for the 8 security bypass paths patched in hooks-security-batch-a.
# Each section corresponds to one confirmed behavior from docs/testing/hooks-security-batch-a.md.
# block = exit 2 (dangerous), allow = exit 0 (safe).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
BASH_BIN=$(command -v bash)

command -v jq >/dev/null 2>&1 || { echo "test: jq required"; exit 1; }

pass=0; fail=0

run() {
  local expect="$1" hook_name="$2" cmd="$3" json rc
  local hook="$ROOT/.claude/hooks/${hook_name}.sh"
  [ -f "$hook" ] || { echo "  MISSING: $hook"; fail=$((fail+1)); return; }
  json=$(jq -nc --arg c "$cmd" '{tool_input:{command:$c}}')
  printf '%s' "$json" | "$BASH_BIN" "$hook" >/dev/null 2>&1; rc=$?
  if [ "$expect" = block ]; then
    [ "$rc" -eq 2 ] && pass=$((pass+1)) || { echo "  MISS (want BLOCK, got $rc): [$hook_name] $cmd"; fail=$((fail+1)); }
  else
    [ "$rc" -eq 0 ] && pass=$((pass+1)) || { echo "  MISS (want ALLOW, got $rc): [$hook_name] $cmd"; fail=$((fail+1)); }
  fi
}

run_no_cmd_field() {
  local hook_name="$1" rc
  local hook="$ROOT/.claude/hooks/${hook_name}.sh"
  [ -f "$hook" ] || { echo "  MISSING: $hook"; fail=$((fail+1)); return; }
  printf '%s' '{"tool_input":{}}' | "$BASH_BIN" "$hook" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] && pass=$((pass+1)) || { echo "  MISS (want BLOCK, got $rc): [$hook_name] missing command field"; fail=$((fail+1)); }
}

run_empty_cmd() {
  local hook_name="$1" rc
  local hook="$ROOT/.claude/hooks/${hook_name}.sh"
  [ -f "$hook" ] || { echo "  MISSING: $hook"; fail=$((fail+1)); return; }
  printf '%s' '{"tool_input":{"command":""}}' | "$BASH_BIN" "$hook" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] && pass=$((pass+1)) || { echo "  MISS (want BLOCK, got $rc): [$hook_name] empty command string"; fail=$((fail+1)); }
}

# ── Behavior 1: fail-closed on empty or missing command (all 4 hooks) ──────────
echo "── behavior 1: empty/missing CMD fails closed (all 4 hooks) ──"
for h in block-dangerous-bash block-credential-read block-egress block-dangerous-git; do
  run_no_cmd_field "$h"
  run_empty_cmd    "$h"
done

# ── Behavior 2: scripting interpreter bypass in block-credential-read.sh ────────
echo "── behavior 2: python3/node/ruby read .env is blocked ──"
run block block-credential-read 'python3 -c "print(open(\".env\").read())"'
run block block-credential-read 'python -c "open(\".env\")"'
run block block-credential-read 'node -e "require(\"fs\").readFileSync(\".env\")"'
run block block-credential-read 'ruby -e "puts File.read(\".env\")"'
run allow block-credential-read 'python3 -c "print(\"hello\")"'
run allow block-credential-read 'node -e "console.log(1+1)"'

# ── Behavior 3: bash/sh -c wrapper bypass in block-credential-read.sh ───────────
echo "── behavior 3: bash -c 'cat .env' is blocked ──"
run block block-credential-read 'bash -c "cat .env"'
run block block-credential-read 'sh -c "cat .env.local"'
run allow block-credential-read 'bash -c "cat README.md"'

# ── Behavior 4: npx/yarn/pnpm wrapper bypass in block-dangerous-bash.sh ─────────
echo "── behavior 4: npx serverless deploy is blocked ──"
run block block-dangerous-bash 'npx serverless deploy'
run block block-dangerous-bash 'yarn serverless deploy'
run block block-dangerous-bash 'pnpm serverless deploy'
# wrapper-strip exercises Layer B: npx wrapping rm on a protected path
run block block-dangerous-bash 'npx rm .claude/hooks/block-dangerous-bash.sh'
run allow block-dangerous-bash 'npx vitest run'
run allow block-dangerous-bash 'npx tsc --noEmit'

# ── Behavior 5: numeric redirect not caught in block-dangerous-bash.sh ───────────
echo "── behavior 5: 2>.claude/hooks/... is blocked ──"
run block block-dangerous-bash 'echo "" 2>.claude/hooks/block-dangerous-bash.sh'
run block block-dangerous-bash 'cmd 2>>.claude/hooks/block-egress.sh'
run block block-dangerous-bash 'cmd 1>.claude/settings.json'
run block block-dangerous-bash 'some-cmd 2> .husky/pre-commit'
run allow block-dangerous-bash 'cmd 2>error.log'
run allow block-dangerous-bash 'cmd 2>/dev/null'
run allow block-dangerous-bash 'cmd 2>&1'

# ── Behaviors 6+7: git restore and git checkout on protected paths ────────────────
echo "── behaviors 6+7: git restore/checkout on protected paths is blocked ──"
run block block-dangerous-git 'git restore .claude/hooks/block-dangerous-bash.sh'
run block block-dangerous-git 'git restore .husky/pre-commit'
run block block-dangerous-git 'git restore .claude/settings.json'
# --staged path: the flag is skipped, the explicit protected path is still caught
run block block-dangerous-git 'git restore --staged .claude/hooks/block-dangerous-bash.sh'
run block block-dangerous-git 'git checkout -- .claude/hooks/block-egress.sh'
run block block-dangerous-git 'git checkout -- .husky/pre-push'
run allow block-dangerous-git 'git restore src/app.ts'
# Known gap: bare '.' restores the whole working tree, which includes hook files.
# The handler only matches explicit protected paths — wildcards bypass it.
# Fix requires a hook file change (NEEDS HUMAN). See BACKLOG.md.
run allow block-dangerous-git 'git restore .'
run allow block-dangerous-git 'git checkout -- src/app.ts'
# git checkout without -- is a branch switch, not a path restore. No path is inspected.
# This is intentionally allowed — the _saw_dashdash gate keeps it safe.
run allow block-dangerous-git 'git checkout feat/my-branch'

# ── Behavior 8: git remote add/set-url blocked ───────────────────────────────────
echo "── behavior 8: git remote add/set-url is blocked ──"
run block block-dangerous-git 'git remote add evil https://attacker.com'
run block block-dangerous-git 'git remote add origin2 git@attacker.com:user/repo.git'
run block block-dangerous-git 'git remote set-url origin https://attacker.com/exfil.git'
run allow block-dangerous-git 'git remote -v'
run allow block-dangerous-git 'git remote show origin'
run allow block-dangerous-git 'git remote remove stale-fork'

echo ""
echo "hooks-security-batch-a: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
