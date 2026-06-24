#!/usr/bin/env bash
# Tests for the git branch -D merge-check in block-dangerous-git.sh.
# Uses stub git binaries so no real repo state is touched.
# Stubs control two calls the hook makes:
#   git symbolic-ref refs/remotes/origin/HEAD  → returns default branch name
#   git diff --quiet <default> <branch>        → exit 0 (merged) or 1 (unmerged)
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "allow-merged-branch-delete.test: not in a git repo"; exit 1; }
HOOK="$ROOT/.claude/hooks/block-dangerous-git.sh"
# In a worktree, ROOT/.git is a file and .claude/hooks/ is a stale checkout.
# Resolve the main tree's path so tests run against the live hook.
if [ -f "$ROOT/.git" ]; then
  _gitdir=$(sed 's/gitdir: //' "$ROOT/.git")
  _main="${_gitdir%/.git/worktrees/*}"
  [ -f "$_main/.claude/hooks/block-dangerous-git.sh" ] && HOOK="$_main/.claude/hooks/block-dangerous-git.sh"
fi
[ -f "$HOOK" ] || { echo "allow-merged-branch-delete.test: $HOOK not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "allow-merged-branch-delete.test: jq required"; exit 1; }

pass=0; fail=0

# Stub that reports a fully merged branch (git diff exits 0 = no differences).
STUB_MERGED=$(mktemp -d)
cat > "$STUB_MERGED/git" <<'STUB'
#!/bin/sh
case "$1" in
  symbolic-ref) echo "refs/remotes/origin/main"; exit 0 ;;
  diff) exit 0 ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$STUB_MERGED/git"

# Stub that reports an unmerged branch (git diff exits 1 = differences exist).
STUB_UNMERGED=$(mktemp -d)
cat > "$STUB_UNMERGED/git" <<'STUB'
#!/bin/sh
case "$1" in
  symbolic-ref) echo "refs/remotes/origin/main"; exit 0 ;;
  diff) exit 1 ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$STUB_UNMERGED/git"

trap 'rm -rf "$STUB_MERGED" "$STUB_UNMERGED"' EXIT

run() { # run <expect-exit> <label> <cmd> [stub-dir]
  local expect="$1" label="$2" cmd="$3" stub="${4:-}" rc json
  json=$(jq -nc --arg c "$cmd" '{tool_input:{command:$c}}')
  if [ -n "$stub" ]; then
    printf '%s' "$json" | PATH="$stub:$PATH" bash "$HOOK" >/dev/null 2>&1; rc=$?
  else
    printf '%s' "$json" | bash "$HOOK" >/dev/null 2>&1; rc=$?
  fi
  if [ "$rc" -eq "$expect" ]; then
    pass=$((pass+1))
  else
    echo "  FAIL [$label]: want exit $expect, got $rc"
    fail=$((fail+1))
  fi
}

echo "── -D on merged branch (must ALLOW) ──"
run 0 "git branch -D feat/merged → ALLOW"                  "git branch -D feat/merged"                  "$STUB_MERGED"
run 0 "git branch -Dd feat/merged → ALLOW"                 "git branch -Dd feat/merged"                 "$STUB_MERGED"

echo "── -D on unmerged branch (must BLOCK) ──"
run 2 "git branch -D feat/unmerged → BLOCK"                "git branch -D feat/unmerged"                "$STUB_UNMERGED"
run 2 "git branch -dD feat/unmerged → BLOCK"               "git branch -dD feat/unmerged"               "$STUB_UNMERGED"
run 2 "git branch --delete --force feat/unmerged → BLOCK"  "git branch --delete --force feat/unmerged"  "$STUB_UNMERGED"
run 2 "git branch --force --delete feat/unmerged → BLOCK"  "git branch --force --delete feat/unmerged"  "$STUB_UNMERGED"

echo "── -D with no branch name (must BLOCK) ──"
run 2 "git branch -D (no name) → BLOCK"                    "git branch -D"                              ""

echo "── -D with multiple branch names (must BLOCK) ──"
run 2 "git branch -D feat/a feat/b → BLOCK"                "git branch -D feat/a feat/b"                ""

echo "── safe delete -d unchanged (must ALLOW) ──"
run 0 "git branch -d feat/x → ALLOW"                       "git branch -d feat/x"                       ""
run 0 "git branch --delete feat/x → ALLOW"                 "git branch --delete feat/x"                 ""
run 0 "git branch --force feat/x → ALLOW"                  "git branch --force feat/x"                  ""

echo ""
echo "allow-merged-branch-delete: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
