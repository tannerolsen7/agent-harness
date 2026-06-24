#!/usr/bin/env bash
# cleanup-worktree.sh removes an agent worktree and branch when the branch is merged.
# Tests are hermetic + offline: each uses a throwaway repo with a local bare remote.
# (run-tests.sh clears inherited git env so the temp-repo ops stay isolated.)
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/cleanup-worktree.sh"
[ -x "$SCRIPT" ] || { echo "test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

# Set up a fresh repo with a bare remote and a commit on main.
make_repo() {
  local tmp
  tmp=$(mktemp -d)
  (
    cd "$tmp"
    git init -q
    git config user.email t@example.com
    git config user.name tester
    git commit -q --allow-empty --no-verify -m m0
    git init -q --bare "$tmp/remote.git"
    git remote add origin "$tmp/remote.git"
    git push -q -u origin HEAD:refs/heads/main >/dev/null 2>&1 || \
      git push -q -u origin master >/dev/null 2>&1
  ) >/dev/null 2>&1
  echo "$tmp"
}

# ── merged branch: worktree removed and branch deleted ──────────────────────
TMP=$(make_repo)
(
  cd "$TMP"
  git worktree add -q .claude/worktrees/my-task -b feat/my-task >/dev/null 2>&1
  ( cd .claude/worktrees/my-task && git commit -q --allow-empty --no-verify -m work )
  git merge -q --no-ff feat/my-task -m "merge" >/dev/null 2>&1
  git push -q origin HEAD:refs/heads/main >/dev/null 2>&1   # update origin/main
) >/dev/null 2>&1

OUT=$(cd "$TMP/.claude/worktrees/my-task" && bash "$SCRIPT" 2>&1)
! [ -d "$TMP/.claude/worktrees/my-task" ]; chk "$?" "merged: worktree directory removed"
! ( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/my-task >/dev/null 2>&1 ); chk "$?" "merged: branch deleted"
printf '%s\n' "$OUT" | grep -q "recover:"; chk "$?" "merged: recovery hint printed before deletion"
printf '%s\n' "$OUT" | grep -q "removed worktree:"; chk "$?" "merged: 'removed worktree' message printed"
printf '%s\n' "$OUT" | grep -q "deleted branch"; chk "$?" "merged: 'deleted branch' message printed"
rm -rf "$TMP"

# ── not-merged branch: exits 0, worktree and branch survive ─────────────────
TMP=$(make_repo)
(
  cd "$TMP"
  git worktree add -q .claude/worktrees/unmerged-task -b feat/unmerged-task >/dev/null 2>&1
  ( cd .claude/worktrees/unmerged-task && git commit -q --allow-empty --no-verify -m wip )
) >/dev/null 2>&1

OUT=$(cd "$TMP/.claude/worktrees/unmerged-task" && bash "$SCRIPT" 2>&1); EC=$?
[ "$EC" = 0 ]; chk "$?" "not merged: exit 0"
[ -d "$TMP/.claude/worktrees/unmerged-task" ]; chk "$?" "not merged: worktree survives"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/unmerged-task >/dev/null 2>&1 ); chk "$?" "not merged: branch survives"
printf '%s\n' "$OUT" | grep -q "not yet merged"; chk "$?" "not merged: 'not yet merged' message printed"
rm -rf "$TMP"

# ── path outside .claude/worktrees/ → exit 1 ────────────────────────────────
TMP=$(make_repo)
mkdir -p "$TMP/some/other/path"

bash "$SCRIPT" "$TMP/some/other/path" >/dev/null 2>&1; EC=$?
[ "$EC" = 1 ]; chk "$?" "bad path: exit 1 for path outside .claude/worktrees/"
rm -rf "$TMP"

# ── main repo root passed as path → exit 1 ──────────────────────────────────
TMP=$(make_repo)

bash "$SCRIPT" "$TMP" >/dev/null 2>&1; EC=$?
[ "$EC" = 1 ]; chk "$?" "main repo root: exit 1 (.git is a directory)"
rm -rf "$TMP"

# ── explicit path argument (not called from CWD inside the worktree) ─────────
TMP=$(make_repo)
(
  cd "$TMP"
  git worktree add -q .claude/worktrees/explicit-task -b feat/explicit-task >/dev/null 2>&1
  ( cd .claude/worktrees/explicit-task && git commit -q --allow-empty --no-verify -m work )
  git merge -q --no-ff feat/explicit-task -m "merge" >/dev/null 2>&1
  git push -q origin HEAD:refs/heads/main >/dev/null 2>&1
) >/dev/null 2>&1

bash "$SCRIPT" "$TMP/.claude/worktrees/explicit-task" >/dev/null 2>&1
! [ -d "$TMP/.claude/worktrees/explicit-task" ]; chk "$?" "explicit path: worktree removed"
! ( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/explicit-task >/dev/null 2>&1 ); chk "$?" "explicit path: branch deleted"
rm -rf "$TMP"

# ── worktree directory already removed → exit 0 silently ────────────────────
TMP=$(make_repo)
(
  cd "$TMP"
  git worktree add -q .claude/worktrees/gone-task -b feat/gone-task >/dev/null 2>&1
  ( cd .claude/worktrees/gone-task && git commit -q --allow-empty --no-verify -m work )
  git merge -q --no-ff feat/gone-task -m "merge" >/dev/null 2>&1
  git push -q origin HEAD:refs/heads/main >/dev/null 2>&1
  git worktree remove --force .claude/worktrees/gone-task >/dev/null 2>&1
  git branch -D feat/gone-task >/dev/null 2>&1
) >/dev/null 2>&1

bash "$SCRIPT" "$TMP/.claude/worktrees/gone-task" >/dev/null 2>&1; EC=$?
[ "$EC" = 0 ]; chk "$?" "already removed: exit 0 when worktree directory is gone"
rm -rf "$TMP"

# ── called twice: second call is a no-op ────────────────────────────────────
TMP=$(make_repo)
(
  cd "$TMP"
  git worktree add -q .claude/worktrees/twice-task -b feat/twice-task >/dev/null 2>&1
  ( cd .claude/worktrees/twice-task && git commit -q --allow-empty --no-verify -m work )
  git merge -q --no-ff feat/twice-task -m "merge" >/dev/null 2>&1
  git push -q origin HEAD:refs/heads/main >/dev/null 2>&1
) >/dev/null 2>&1

bash "$SCRIPT" "$TMP/.claude/worktrees/twice-task" >/dev/null 2>&1
bash "$SCRIPT" "$TMP/.claude/worktrees/twice-task" >/dev/null 2>&1; EC=$?
[ "$EC" = 0 ]; chk "$?" "idempotent: second call exits 0"
rm -rf "$TMP"

# ── detached HEAD → exit 0 gracefully, branch untouched ─────────────────────
TMP=$(make_repo)
(
  cd "$TMP"
  git worktree add -q .claude/worktrees/detached-task -b feat/detached-task >/dev/null 2>&1
  ( cd .claude/worktrees/detached-task && git commit -q --allow-empty --no-verify -m work )
  SHA=$(cd .claude/worktrees/detached-task && git rev-parse HEAD)
  ( cd .claude/worktrees/detached-task && git checkout -q --detach "$SHA" >/dev/null 2>&1 )
) >/dev/null 2>&1

bash "$SCRIPT" "$TMP/.claude/worktrees/detached-task" >/dev/null 2>&1; EC=$?
[ "$EC" = 0 ]; chk "$?" "detached HEAD: exits 0 gracefully"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/detached-task >/dev/null 2>&1 ); chk "$?" "detached HEAD: branch survives (cannot derive name)"
rm -rf "$TMP"

# ── merge check uses origin/main, NOT HEAD ───────────────────────────────────
# Branch is NOT merged into origin/main. But from inside the worktree, HEAD points
# to the feature branch — if the script compared against HEAD instead of origin/main,
# it would always return "merged" (the feature tip is always an ancestor of itself).
TMP=$(make_repo)
(
  cd "$TMP"
  git worktree add -q .claude/worktrees/head-guard -b feat/head-guard >/dev/null 2>&1
  ( cd .claude/worktrees/head-guard && git commit -q --allow-empty --no-verify -m wip )
  # Deliberately do NOT merge into main or push to origin/main.
) >/dev/null 2>&1

cd "$TMP/.claude/worktrees/head-guard" && bash "$SCRIPT" >/dev/null 2>&1; EC=$?
[ "$EC" = 0 ]; chk "$?" "origin/main guard: exit 0 (not merged)"
[ -d "$TMP/.claude/worktrees/head-guard" ]; chk "$?" "origin/main guard: unmerged worktree survives"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/head-guard >/dev/null 2>&1 ); chk "$?" "origin/main guard: unmerged branch survives"
rm -rf "$TMP"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
