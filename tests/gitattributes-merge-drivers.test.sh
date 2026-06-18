#!/usr/bin/env bash
# Verifies that .gitattributes merge strategies prevent conflict markers on five shared doc files:
#   - docs/TESTING.md             merge=union  (EOF-append conflicts auto-resolve)
#   - docs/RECURRING-FINDINGS.md  merge=union  (same)
#   - docs/patterns-registry.md   merge=union  (same)
#   - harness-progress.html       merge=ours   (current branch always wins)
#   - TASKS.md                    merge=tasks-higher-state (custom driver: [x]>[~]>[ ])

set -u
# Derive ROOT from the test file's location (tests/ is always one level below repo root).
# This lets the test be invoked from any cwd — the main worktree or a feature worktree —
# without depending on which worktree the shell is currently in.
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
GITATTRS="$ROOT/.gitattributes"
DRIVER="$ROOT/scripts/tasks-merge-driver.sh"

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

# Preconditions — both files must exist before any merge test can run.
[ -f "$GITATTRS" ]; chk "$?" ".gitattributes must exist"
[ -f "$DRIVER" ]; chk "$?" "scripts/tasks-merge-driver.sh must exist"
[ -x "$DRIVER" ]; chk "$?" "scripts/tasks-merge-driver.sh must be executable"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Clear any inherited git env vars that would confuse git init in a temp dir.
# (run-tests.sh clears these, but guard here for direct invocation too.)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE 2>/dev/null || true

# Create a temp repo with .gitattributes copied from the project and both drivers registered.
setup_repo() {
  local dir="$1"
  git init -q "$dir"
  git -C "$dir" config user.email t@example.com
  git -C "$dir" config user.name tester
  cp "$GITATTRS" "$dir/.gitattributes"
  # The 'ours' driver: always exits 0 without touching %A, keeping the current-branch version.
  git -C "$dir" config merge.ours.driver "true"
  # The tasks driver: higher-state-wins shell script.
  git -C "$dir" config merge.tasks-higher-state.name "higher-state-wins"
  git -C "$dir" config merge.tasks-higher-state.driver "\"$DRIVER\" %O %A %B"
}

# ── Behavior 1: merge=union for docs/TESTING.md ──────────────────────────────
echo "── merge=union: docs/TESTING.md resolves concurrent EOF appends ──"
REPO="$TMP/union-testing"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  mkdir -p docs
  printf '## Base\n\nexisting content\n' > docs/TESTING.md
  git add . && git commit -q --no-verify -m base

  git checkout -q -b branchA
  printf '## Base\n\nexisting content\n\n## Section A\n\nfrom branch A\n' > docs/TESTING.md
  git add docs/TESTING.md && git commit -q --no-verify -m "append section A"

  git checkout -q -b branchB "$(git rev-parse branchA^)"
  printf '## Base\n\nexisting content\n\n## Section B\n\nfrom branch B\n' > docs/TESTING.md
  git add docs/TESTING.md && git commit -q --no-verify -m "append section B"

  git merge -q branchA --no-edit --no-verify 2>/dev/null
) 2>/dev/null
MERGE_EXIT=$?
chk "$MERGE_EXIT" "merge=union TESTING.md: merge exits 0"
grep -q "Section A" "$REPO/docs/TESTING.md" && grep -q "Section B" "$REPO/docs/TESTING.md"
chk "$?" "merge=union TESTING.md: both appended sections present"
! grep -q "<<<<<<" "$REPO/docs/TESTING.md"
chk "$?" "merge=union TESTING.md: no conflict markers"

# ── Behavior 2: merge=union for docs/RECURRING-FINDINGS.md ───────────────────
echo "── merge=union: docs/RECURRING-FINDINGS.md resolves concurrent appends ──"
REPO="$TMP/union-findings"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  mkdir -p docs
  printf '## Active\n\n### finding-one\n**Occurrences:** 1\n' > docs/RECURRING-FINDINGS.md
  git add . && git commit -q --no-verify -m base

  git checkout -q -b branchA
  printf '## Active\n\n### finding-one\n**Occurrences:** 2\n\n### finding-new\n**Occurrences:** 1\n' \
    > docs/RECURRING-FINDINGS.md
  git add docs/RECURRING-FINDINGS.md && git commit -q --no-verify -m "A: bump count + add finding"

  git checkout -q -b branchB "$(git rev-parse branchA^)"
  printf '## Active\n\n### finding-one\n**Occurrences:** 3\n\n### finding-other\n**Occurrences:** 1\n' \
    > docs/RECURRING-FINDINGS.md
  git add docs/RECURRING-FINDINGS.md && git commit -q --no-verify -m "B: bump count + add finding"

  git merge -q branchA --no-edit --no-verify 2>/dev/null
) 2>/dev/null
MERGE_EXIT=$?
chk "$MERGE_EXIT" "merge=union RECURRING-FINDINGS.md: merge exits 0"
grep -q "finding-new" "$REPO/docs/RECURRING-FINDINGS.md" \
  && grep -q "finding-other" "$REPO/docs/RECURRING-FINDINGS.md"
chk "$?" "merge=union RECURRING-FINDINGS.md: both new findings present"
! grep -q "<<<<<<" "$REPO/docs/RECURRING-FINDINGS.md"
chk "$?" "merge=union RECURRING-FINDINGS.md: no conflict markers"
# Both sides edited the same **Occurrences:** field — union keeps both lines (no markers).
# Two count lines for the same finding is expected: counts are a human-read lower bound,
# not an exact value. Do NOT replicate this pattern for fields that drive automated logic.
grep -q "Occurrences.*2" "$REPO/docs/RECURRING-FINDINGS.md" \
  && grep -q "Occurrences.*3" "$REPO/docs/RECURRING-FINDINGS.md"
chk "$?" "merge=union RECURRING-FINDINGS.md: both occurrence counts present"

# ── Behavior 3: merge=ours for harness-progress.html ─────────────────────────
echo "── merge=ours: harness-progress.html keeps current-branch version ──"
REPO="$TMP/ours-progress"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  printf 'base content\n' > harness-progress.html
  git add . && git commit -q --no-verify -m base

  # Feature branch auto-updates the file (simulates session-start hook).
  git checkout -q -b feature
  printf 'stale branch version\n' > harness-progress.html
  git add harness-progress.html && git commit -q --no-verify -m "branch: auto-update"

  # Main also updated the file independently.
  git checkout -q -
  printf 'main version\n' > harness-progress.html
  git add harness-progress.html && git commit -q --no-verify -m "main: own update"

  # Main merges feature — merge=ours keeps main's version.
  git merge -q feature --no-edit --no-verify 2>/dev/null
) 2>/dev/null
MERGE_EXIT=$?
chk "$MERGE_EXIT" "merge=ours harness-progress.html: merge exits 0"
grep -q "main version" "$REPO/harness-progress.html"
chk "$?" "merge=ours harness-progress.html: main-branch version preserved"
! grep -q "stale branch" "$REPO/harness-progress.html"
chk "$?" "merge=ours harness-progress.html: branch version discarded"

# ── Behavior 4a: TASKS.md driver — [x] beats [~] ────────────────────────────
echo "── tasks driver: [x] beats [~] ──"
REPO="$TMP/tasks-x-over-tilde"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  printf -- '- [ ] do the thing\n  Slug: do-the-thing\n' > TASKS.md
  git add . && git commit -q --no-verify -m base

  git checkout -q -b branchA
  printf -- '- [~] do the thing\n  Slug: do-the-thing\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "A: in-progress"

  git checkout -q -b branchB "$(git rev-parse branchA^)"
  printf -- '- [x] do the thing\n  Slug: do-the-thing\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "B: done"

  git merge -q branchA --no-edit --no-verify
) >/dev/null 2>&1
MERGE_EXIT=$?
chk "$MERGE_EXIT" "tasks driver [x]>[~]: merge exits 0"
grep -qF -- '- [x] do the thing' "$REPO/TASKS.md"
chk "$?" "tasks driver [x]>[~]: [x] wins"
! grep -q "<<<<<<" "$REPO/TASKS.md"
chk "$?" "tasks driver [x]>[~]: no conflict markers"

# ── Behavior 4b: TASKS.md driver — [~] beats [ ] ────────────────────────────
echo "── tasks driver: [~] beats [ ] ──"
REPO="$TMP/tasks-tilde-over-open"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  # Both branches diverge from [x] so that each can change the line (required for a conflict).
  printf -- '- [x] task alpha\n  Slug: task-alpha\n' > TASKS.md
  git add . && git commit -q --no-verify -m base

  git checkout -q -b branchA
  printf -- '- [~] task alpha\n  Slug: task-alpha\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "A: downgrade to in-progress"

  git checkout -q -b branchB "$(git rev-parse branchA^)"
  printf -- '- [ ] task alpha\n  Slug: task-alpha\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "B: reset to open"

  git merge -q branchA --no-edit --no-verify
) >/dev/null 2>&1
MERGE_EXIT=$?
chk "$MERGE_EXIT" "tasks driver [~]>[ ]: merge exits 0"
grep -qF -- '- [~] task alpha' "$REPO/TASKS.md"
chk "$?" "tasks driver [~]>[ ]: [~] wins"
! grep -q "<<<<<<" "$REPO/TASKS.md"
chk "$?" "tasks driver [~]>[ ]: no conflict markers"

# ── Behavior 4c: TASKS.md driver — [x] beats [ ] (rank extremes) ────────────
echo "── tasks driver: [x] beats [ ] ──"
REPO="$TMP/tasks-x-over-open"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  printf -- '- [~] anchor\n  Slug: anchor\n' > TASKS.md
  git add . && git commit -q --no-verify -m base

  git checkout -q -b branchA
  printf -- '- [ ] anchor\n  Slug: anchor\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "A: reset to open"

  git checkout -q -b branchB "$(git rev-parse branchA^)"
  printf -- '- [x] anchor\n  Slug: anchor\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "B: done"

  git merge -q branchA --no-edit --no-verify
) >/dev/null 2>&1
MERGE_EXIT=$?
chk "$MERGE_EXIT" "tasks driver [x]>[ ]: merge exits 0"
grep -qF -- '- [x] anchor' "$REPO/TASKS.md"
chk "$?" "tasks driver [x]>[ ]: [x] wins"
! grep -q "<<<<<<" "$REPO/TASKS.md"
chk "$?" "tasks driver [x]>[ ]: no conflict markers"

# ── Behavior 4d: TASKS.md driver — unresolvable conflict leaves markers ───────
echo "── tasks driver: unresolvable conflict leaves markers ──"
REPO="$TMP/tasks-unresolvable"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  printf -- '- [ ] do the thing\n  Slug: do-the-thing\n  Notes: original\n' > TASKS.md
  git add . && git commit -q --no-verify -m base

  git checkout -q -b branchA
  printf -- '- [~] do the thing\n  Slug: do-the-thing\n  Notes: from A\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "A: in-progress + note"

  git checkout -q -b branchB "$(git rev-parse branchA^)"
  printf -- '- [x] do the thing\n  Slug: do-the-thing\n  Notes: from B\n' > TASKS.md
  git add TASKS.md && git commit -q --no-verify -m "B: done + note"

  git merge -q branchA --no-edit --no-verify
) >/dev/null 2>&1
MERGE_EXIT=$?
[ "$MERGE_EXIT" -ne 0 ]
chk "$?" "tasks driver unresolvable: merge exits non-zero"
grep -q "<<<<<<" "$REPO/TASKS.md"
chk "$?" "tasks driver unresolvable: conflict markers present"

# ── Behavior 5: merge=union for docs/patterns-registry.md ───────────────────
echo "── merge=union: docs/patterns-registry.md resolves concurrent EOF appends ──"
REPO="$TMP/union-patterns"
setup_repo "$REPO"
(
  cd "$REPO" || exit 1
  mkdir -p docs
  printf '## Existing pattern\n\nbase content\n' > docs/patterns-registry.md
  git add . && git commit -q --no-verify -m base

  git checkout -q -b branchA
  printf '## Existing pattern\n\nbase content\n\n## Pattern A\n\nrecipe from branch A\n' > docs/patterns-registry.md
  git add docs/patterns-registry.md && git commit -q --no-verify -m "append pattern A"

  git checkout -q -b branchB "$(git rev-parse branchA^)"
  printf '## Existing pattern\n\nbase content\n\n## Pattern B\n\nrecipe from branch B\n' > docs/patterns-registry.md
  git add docs/patterns-registry.md && git commit -q --no-verify -m "append pattern B"

  git merge -q branchA --no-edit --no-verify 2>/dev/null
) 2>/dev/null
MERGE_EXIT=$?
chk "$MERGE_EXIT" "merge=union patterns-registry.md: merge exits 0"
grep -q "Pattern A" "$REPO/docs/patterns-registry.md" && grep -q "Pattern B" "$REPO/docs/patterns-registry.md"
chk "$?" "merge=union patterns-registry.md: both appended sections present"
! grep -q "<<<<<<" "$REPO/docs/patterns-registry.md"
chk "$?" "merge=union patterns-registry.md: no conflict markers"

echo ""
echo "gitattributes-merge-drivers: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
