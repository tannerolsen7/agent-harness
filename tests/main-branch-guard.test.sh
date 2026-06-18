#!/usr/bin/env bash
# Regression gate: no commits and no pushes (explicit or bare) directly on
# main/master/develop. Covers four protections in block-dangerous-git.sh:
#   (a) git commit on a protected branch → exit 2 (BLOCK)
#   (b) git push / git push origin (no explicit refspec) on protected branch → exit 2
#   (c) a commit aimed at a worktree via `git -C <dir>` is judged by the
#       worktree's branch, not the directory the hook runs in
#   (d) `cd <worktree> && git commit` is judged by the cd target's branch
#       (_tracked_cd), not the ambient branch
#
# Uses a stub git binary so the hook's internal "git rev-parse --abbrev-ref HEAD"
# call returns a controlled branch name without touching the real repo state.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "main-branch-guard.test: not in a git repo"; exit 1; }
HOOK="$ROOT/.claude/hooks/block-dangerous-git.sh"
[ -f "$HOOK" ] || { echo "main-branch-guard.test: $HOOK not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "main-branch-guard.test: jq required"; exit 1; }

pass=0; fail=0

# Build a stub git that reports a given branch for rev-parse --abbrev-ref HEAD
# and exits 1 (safely) for anything else — the hook calls nothing else in
# the commit/bare-push paths.
make_stub() {
  local dir="$1" branch="$2"
  mkdir -p "$dir"
  printf '#!/bin/sh\n[ "$1" = "rev-parse" ] && [ "$2" = "--abbrev-ref" ] && [ "$3" = "HEAD" ] && { echo "%s"; exit 0; }\necho "stub: unsupported git call: $*" >&2; exit 1\n' \
    "$branch" > "$dir/git"
  chmod +x "$dir/git"
}

# A stub whose AMBIENT branch (a bare `git rev-parse`) is main, but a
# `git -C <dir> rev-parse` reports the branch encoded in the dir name:
# a path containing "on-main" → main, anything else → a feature branch.
# This lets us prove the protected-branch check follows the -C target,
# not the directory the hook happens to run in.
make_stub_dispatch() {
  local dir="$1"
  mkdir -p "$dir"
  cat > "$dir/git" <<'STUB'
#!/bin/sh
if [ "$1" = "-C" ]; then
  target="$2"; shift 2
  if [ "$1" = "rev-parse" ] && [ "$2" = "--abbrev-ref" ] && [ "$3" = "HEAD" ]; then
    case "$target" in
      *on-main*) echo "main" ;;
      *) echo "feat/wt-task" ;;
    esac
    exit 0
  fi
elif [ "$1" = "rev-parse" ] && [ "$2" = "--abbrev-ref" ] && [ "$3" = "HEAD" ]; then
  echo "main"; exit 0
fi
echo "stub: unsupported git call: $*" >&2; exit 1
STUB
  chmod +x "$dir/git"
}

STUB_MAIN=$(mktemp -d); make_stub "$STUB_MAIN" "main"
STUB_MASTER=$(mktemp -d); make_stub "$STUB_MASTER" "master"
STUB_DEVELOP=$(mktemp -d); make_stub "$STUB_DEVELOP" "develop"
STUB_FEAT=$(mktemp -d); make_stub "$STUB_FEAT" "feat/my-feature"
STUB_WT=$(mktemp -d); make_stub_dispatch "$STUB_WT"
trap 'rm -rf "$STUB_MAIN" "$STUB_MASTER" "$STUB_DEVELOP" "$STUB_FEAT" "$STUB_WT"' EXIT

run() { # run <expect> <label> <cmd> <stub-dir>
  local expect="$1" label="$2" cmd="$3" stub="${4:-}"
  local json rc
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

echo "── commit guard ──"
run 2 "git commit on main → BLOCK"           "git commit -m 'msg'"       "$STUB_MAIN"
run 2 "git commit -a on main → BLOCK"        "git commit -am 'msg'"      "$STUB_MAIN"
run 2 "git commit --amend on main → BLOCK"   "git commit --amend"        "$STUB_MAIN"
run 2 "git commit on master → BLOCK"         "git commit -m 'msg'"       "$STUB_MASTER"
run 2 "git commit on develop → BLOCK"        "git commit -m 'msg'"       "$STUB_DEVELOP"
run 0 "git commit on feature branch → ALLOW" "git commit -m 'msg'"       "$STUB_FEAT"

echo "── worktree commit guard (honors git -C <dir>) ──"
# Root repo is on main (ambient), but the commit targets a worktree via -C.
# Before the fix the hook stripped -C and judged the commit by the ambient
# branch (main) → wrongly blocked. After the fix it reads the -C target's branch.
run 0 "git -C <feature worktree> commit while root on main → ALLOW" \
      "git -C /repo/.claude/worktrees/on-feat commit -m 'msg'"  "$STUB_WT"
run 2 "git -C <worktree on main> commit → still BLOCK" \
      "git -C /repo/.claude/worktrees/on-main commit -m 'msg'"  "$STUB_WT"

echo "── cd-then-git worktree commit guard (honors _tracked_cd) ──"
# `cd <worktree> && git commit` — no explicit -C, but the preceding cd sets
# _tracked_cd so the hook resolves the branch from the cd target, not ambient.
run 0 "cd <feature worktree> && git commit while root on main → ALLOW" \
      "cd /repo/.claude/worktrees/on-feat && git commit -m 'msg'"  "$STUB_WT"
run 2 "cd <worktree on main> && git commit → BLOCK" \
      "cd /repo/.claude/worktrees/on-main && git commit -m 'msg'"  "$STUB_WT"

echo "── bare push guard ──"
run 2 "git push (no args) on main → BLOCK"         "git push"            "$STUB_MAIN"
run 2 "git push origin on main → BLOCK"            "git push origin"     "$STUB_MAIN"
run 2 "git push -u origin on main → BLOCK"         "git push -u origin"  "$STUB_MAIN"
run 2 "git push on develop → BLOCK"                "git push"            "$STUB_DEVELOP"
run 2 "git push origin HEAD on main → BLOCK"       "git push origin HEAD" "$STUB_MAIN"
run 0 "git push (no args) on feature branch → ALLOW"    "git push"       "$STUB_FEAT"
run 0 "git push origin on feature branch → ALLOW"       "git push origin" "$STUB_FEAT"

echo "── existing protections unchanged ──"
run 2 "git push origin main (explicit) → still blocked"  "git push origin main"  ""
run 2 "git push --force → still blocked"                 "git push --force"      ""
run 2 "git push -f → still blocked"                      "git push -f"           ""
run 0 "git push origin feat/x → still allowed"           "git push origin feat/x" ""

echo ""
echo "main-branch-guard: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
