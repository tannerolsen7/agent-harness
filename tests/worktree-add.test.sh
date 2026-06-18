#!/usr/bin/env bash
# worktree-add.sh: verifies that feat/<slug> worktrees mark the matching TASKS.md
# task as in-progress ([~]) and that edge cases (no slug, no TASKS.md) are safe.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/worktree-add.sh"
[ -x "$SCRIPT" ] || { echo "test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

# Scaffold a git repo with a TASKS.md containing two tasks.
# Usage: scaffold_tasks_repo <dir>
scaffold_tasks_repo() {
  local dir=$1
  (
    cd "$dir"
    git init -q
    git config user.email t@example.com
    git config user.name tester
    git commit -q --allow-empty --no-verify -m "init"
    git branch -M main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
  ) >/dev/null 2>&1
  cat > "$dir/TASKS.md" << 'TASKSEOF'
# TASKS.md

## P1 — Ready to Queue

- [ ] Alpha task
  Size: SMALL
  Slug: alpha-task
  Notes: First task.

- [ ] Beta task
  Size: SMALL
  Slug: beta-task
  Notes: Second task.
TASKSEOF
}

# ── Test 1: feat/<slug> worktree marks matching task as [~] ─────────────────
TMP1=$(mktemp -d)
TMP1_WT=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP1_WT"' EXIT
scaffold_tasks_repo "$TMP1"
(cd "$TMP1" && unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE && bash "$SCRIPT" "$TMP1_WT" "feat/alpha-task") >/dev/null 2>&1
chk $? "script exits 0 when creating feat/alpha-task worktree"
grep -q '^- \[~\] Alpha task' "$TMP1/TASKS.md"
chk $? "alpha-task task is marked [~] in TASKS.md"
grep -q '^- \[ \] Beta task' "$TMP1/TASKS.md"
chk $? "beta-task is not changed (only the matching task is updated)"

# ── Test 2: non-feat branch leaves TASKS.md unchanged ───────────────────────
TMP2=$(mktemp -d)
TMP2_WT=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP1_WT" "$TMP2" "$TMP2_WT"' EXIT
scaffold_tasks_repo "$TMP2"
(cd "$TMP2" && unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE && bash "$SCRIPT" "$TMP2_WT" "chore/something") >/dev/null 2>&1
chk $? "script exits 0 for non-feat branch"
grep -q '^- \[ \] Alpha task' "$TMP2/TASKS.md"
chk $? "TASKS.md is unchanged for non-feat branch"
grep -q '^- \[ \] Beta task' "$TMP2/TASKS.md"
chk $? "TASKS.md beta-task also unchanged for non-feat branch"

# ── Test 3: missing TASKS.md is not an error ────────────────────────────────
TMP3=$(mktemp -d)
TMP3_WT=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP1_WT" "$TMP2" "$TMP2_WT" "$TMP3" "$TMP3_WT"' EXIT
(
  cd "$TMP3"
  git init -q
  git config user.email t@example.com; git config user.name tester
  git commit -q --allow-empty --no-verify -m "init"
  git branch -M main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
) >/dev/null 2>&1
(cd "$TMP3" && unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE && bash "$SCRIPT" "$TMP3_WT" "feat/no-tasks-file") >/dev/null 2>&1
chk $? "script exits 0 when TASKS.md is absent"
[ ! -f "$TMP3/TASKS.md" ]
chk $? "no TASKS.md is created when it did not exist"

# ── Test 4: idempotent re-run — task already [~] stays [~] ─────────────────
TMP4=$(mktemp -d)
TMP4_WT=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP1_WT" "$TMP2" "$TMP2_WT" "$TMP3" "$TMP3_WT" "$TMP4" "$TMP4_WT"' EXIT
(
  cd "$TMP4"
  git init -q
  git config user.email t@example.com
  git config user.name tester
  git commit -q --allow-empty --no-verify -m "init"
  git branch -M main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
) >/dev/null 2>&1
cat > "$TMP4/TASKS.md" << 'TASKSEOF'
# TASKS.md

## P1 — Ready to Queue

- [~] Alpha task
  Size: SMALL
  Slug: alpha-task
  Notes: First task.
TASKSEOF
(cd "$TMP4" && unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE && bash "$SCRIPT" "$TMP4_WT" "feat/alpha-task") >/dev/null 2>&1
chk $? "script exits 0 for already-in-progress task"
grep -q '^- \[~\] Alpha task' "$TMP4/TASKS.md"
chk $? "task already [~] stays [~] after re-run"

# ── Test 5: task already [x] (done) stays [x] ───────────────────────────────
TMP5=$(mktemp -d)
TMP5_WT=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP1_WT" "$TMP2" "$TMP2_WT" "$TMP3" "$TMP3_WT" "$TMP4" "$TMP4_WT" "$TMP5" "$TMP5_WT"' EXIT
(
  cd "$TMP5"
  git init -q
  git config user.email t@example.com
  git config user.name tester
  git commit -q --allow-empty --no-verify -m "init"
  git branch -M main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
) >/dev/null 2>&1
cat > "$TMP5/TASKS.md" << 'TASKSEOF'
# TASKS.md

## P1 — Ready to Queue

- [x] Alpha task
  Size: SMALL
  Slug: alpha-task
  Notes: First task.
TASKSEOF
(cd "$TMP5" && unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE && bash "$SCRIPT" "$TMP5_WT" "feat/alpha-task") >/dev/null 2>&1
chk $? "script exits 0 for already-done task"
grep -q '^- \[x\] Alpha task' "$TMP5/TASKS.md"
chk $? "task already [x] is not changed to [~]"

# ── Test 6: optional $3 base-ref — new branch starts from that ref ───────────
TMP6=$(mktemp -d)
TMP6_BASE_WT=$(mktemp -d)
TMP6_CHILD_WT=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP1_WT" "$TMP2" "$TMP2_WT" "$TMP3" "$TMP3_WT" "$TMP4" "$TMP4_WT" "$TMP5" "$TMP5_WT" "$TMP6" "$TMP6_BASE_WT" "$TMP6_CHILD_WT"' EXIT
(
  cd "$TMP6"
  git init -q
  git config user.email t@example.com
  git config user.name tester
  git commit -q --allow-empty --no-verify -m "init"
  git branch -M main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
  # Create a base branch with a unique commit so we can verify ancestry
  git checkout -q -b feat/base-task
  git commit -q --allow-empty --no-verify -m "base-task work"
  git checkout -q main
) >/dev/null 2>&1
# Create a child worktree based on feat/base-task (not main/HEAD)
(cd "$TMP6" && unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE && bash "$SCRIPT" "$TMP6_CHILD_WT" "feat/child-task" "feat/base-task") >/dev/null 2>&1
chk $? "script exits 0 when a base-ref is provided"
# The child branch should include the base-task commit in its ancestry
(cd "$TMP6" && git log feat/child-task --oneline 2>/dev/null | grep -q "base-task work")
chk $? "feat/child-task ancestry includes the base-ref commit"

[ "$fail" = 0 ] && echo "worktree-add: OK ($pass passed)"
exit "$fail"
