#!/usr/bin/env bash
# gc.sh removes a MERGED PR's worktree before deleting its branch, and never touches a worktree
# whose branch still has a live remote. Hermetic + offline: a throwaway repo with a local bare
# remote. (run-tests.sh clears inherited git env so the temp-repo ops stay isolated.)
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
GC="$ROOT/scripts/gc.sh"
[ -x "$GC" ] || { echo "test: $GC not found or not executable"; exit 1; }

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

TMP=$(mktemp -d)
(
  cd "$TMP" || exit 1
  git init -q; git config user.email t@example.com; git config user.name tester
  git commit -q --allow-empty --no-verify -m m0
  git init -q --bare "$TMP/remote.git"; git remote add origin "$TMP/remote.git"
  git push -q -u origin HEAD:refs/heads/main >/dev/null 2>&1 || git push -q -u origin master >/dev/null 2>&1

  # MERGED branch: feat/done — commit in a worktree, merge to the default branch, push+track, then
  # delete the remote branch (simulating PR merge + delete_branch_on_merge).
  DEF=$(git rev-parse --abbrev-ref HEAD)
  git worktree add -q .claude/worktrees/done -b feat/done >/dev/null 2>&1
  ( cd .claude/worktrees/done && git commit -q --allow-empty --no-verify -m work )
  git push -q -u origin feat/done >/dev/null 2>&1
  git merge -q --no-ff feat/done -m merge >/dev/null 2>&1   # feat/done now an ancestor → branch -d works
  git push -q origin --delete feat/done >/dev/null 2>&1     # remote gone → [gone] after prune

  # ACTIVE branch: feat/wip — worktree + live remote (must SURVIVE gc).
  git worktree add -q .claude/worktrees/wip -b feat/wip >/dev/null 2>&1
  ( cd .claude/worktrees/wip && git commit -q --allow-empty --no-verify -m wip )
  git push -q -u origin feat/wip >/dev/null 2>&1

  # UNMERGED branch: feat/orphan — remote deleted WITHOUT merging. A [gone] remote is NOT a merge,
  # so the worktree, branch, and untracked WIP must all SURVIVE (the --force-before-merge-check bug).
  git worktree add -q .claude/worktrees/orphan -b feat/orphan >/dev/null 2>&1
  ( cd .claude/worktrees/orphan && git commit -q --allow-empty --no-verify -m orphan && echo wip > WIP.txt )
  git push -q -u origin feat/orphan >/dev/null 2>&1
  git push -q origin --delete feat/orphan >/dev/null 2>&1   # remote gone, never merged into main
) >/dev/null 2>&1

# Run gc.sh in the temp repo.
( cd "$TMP" && bash "$GC" ) >/dev/null 2>&1

# Merged branch's worktree + branch are gone.
[ -d "$TMP/.claude/worktrees/done" ]; chk "$([ $? -ne 0 ] && echo 0 || echo 1)" "merged worktree .claude/worktrees/done should be removed"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/done >/dev/null 2>&1 ); chk "$([ $? -ne 0 ] && echo 0 || echo 1)" "merged branch feat/done should be deleted"

# Active branch's worktree + branch survive (live remote → never touched).
[ -d "$TMP/.claude/worktrees/wip" ]; chk "$?" "active worktree .claude/worktrees/wip must survive"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/wip >/dev/null 2>&1 ); chk "$?" "active branch feat/wip must survive"

# Unmerged-but-remote-gone branch + worktree + untracked WIP all survive (data-loss guard).
[ -d "$TMP/.claude/worktrees/orphan" ]; chk "$?" "unmerged worktree must survive (remote gone != merged)"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/orphan >/dev/null 2>&1 ); chk "$?" "unmerged branch must survive"
[ -f "$TMP/.claude/worktrees/orphan/WIP.txt" ]; chk "$?" "untracked WIP in the unmerged worktree must survive (no --force eat)"

rm -rf "$TMP"
echo ""
echo "gc: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
