#!/usr/bin/env bash
# Tests for scripts/sync-open-prs.sh — diagnoses CONFLICTING open PRs via a real local merge,
# reports real-conflict vs. resolvable, and NEVER pushes (see the script's own header comment
# for why: a self-issuing-sentinel + auto-push design was rejected after an adversarial review
# found it exploitable).
# gh is stubbed only for `pr list` — every git operation is real, run against a local bare
# "remote" repo (never the project's real origin). The whole point of this script is real
# merge-driver resolution, which a stubbed `gh pr update-branch` could never exercise.
# (run-tests.sh clears inherited git env so git ops stay isolated.)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/sync-open-prs.sh"
[ -x "$SCRIPT" ] || { echo "test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

FAKE_BIN=$(mktemp -d)
TMP=$(mktemp -d)
trap 'rm -rf "$FAKE_BIN" "$TMP"' EXIT

# Run the script from the worktree root with $FAKE_BIN as the only place gh could come from.
# For the no-CLI test: PATH contains only FAKE_BIN (no /usr/bin, /bin). This isolates gh on
# Linux CI too — ubuntu-latest has gh at /usr/bin/gh, so /usr/bin in PATH defeats the test.
# bash must be resolved now (outside the subshell) because name-lookup inside PATH="$FAKE_BIN"
# would fail — bash isn't in FAKE_BIN. The script's own error guards make this safe:
#   git rev-parse ... 2>/dev/null || pwd  →  ROOT = current dir (correct; we cd'd there)
#   sh detect-forge.sh 2>/dev/null || echo unknown  →  FORGE=unknown
# The unknown forge case tries command -v gh and glab, finds neither, and prints the skip msg.
_BASH=$(command -v bash)
run_no_cli() {
  ( cd "$ROOT" && PATH="$FAKE_BIN" "$_BASH" "$SCRIPT" ) 2>&1
}
run_with_stub() {
  local dir="${1:-$ROOT}"
  ( cd "$dir" && PATH="$FAKE_BIN:$PATH" bash "$SCRIPT" ) 2>&1
}

# ---- Behavior 1: missing forge CLI exits 0 with skip message ----
rm -f "$FAKE_BIN/gh" "$FAKE_BIN/glab"
OUT=$(run_no_cli); EC=$?
chk "$EC" "no-CLI: exit 0"
printf '%s' "$OUT" | grep -qF "forge CLI unavailable — skipping PR sync"
chk "$?" "no-CLI: skip message printed"

# ---- Behavior 2: no open PRs exits 0 with skip message ----
cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*) echo "[]" ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
OUT=$(run_with_stub); EC=$?
chk "$EC" "no-PRs: exit 0"
printf '%s' "$OUT" | grep -qF "no open PRs to sync"
chk "$?" "no-PRs: skip message printed"

# ---- Behavior 3: PR targeting a non-default base branch is skipped ----
rm -f "$FAKE_BIN/list-called-count"
cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*)
    echo '[{"number":99,"headRefName":"feat/child","baseRefName":"feat/parent","mergeable":"CONFLICTING","isDraft":false}]'
    ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
OUT=$(run_with_stub); EC=$?
chk "$EC" "non-default-base: exit 0"
printf '%s' "$OUT" | grep -qF "#99"
[ "$?" != 0 ]
chk "$?" "non-default-base: PR #99 never touched (no sync/skip/fail line)"

# ---- Behavior 4: draft PR is skipped ----
cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*)
    echo '[{"number":77,"headRefName":"feat/draft-work","baseRefName":"main","mergeable":"CONFLICTING","isDraft":true}]'
    ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
OUT=$(run_with_stub); EC=$?
chk "$EC" "draft-PR: exit 0"
printf '%s' "$OUT" | grep -qF "#77"
[ "$?" != 0 ]
chk "$?" "draft-PR: PR #77 never touched (no sync/skip/fail line)"

# ---- Behavior 4b: a branch name outside the expected charset is rejected, not passed to git ----
cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*)
    echo '[{"number":88,"headRefName":"-x/exploit","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false}]'
    ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
OUT=$(run_with_stub); EC=$?
chk "$EC" "bad-branch-name: exit 0"
printf '%s' "$OUT" | grep -qF "skipped #88 — branch name outside the expected charset, check it yourself"
chk "$?" "bad-branch-name: rejected before any git operation, PR number only in the message"

# ---- Behavior 5: .gitattributes covers every hot generated/tracking file ----
for entry in "PITFALLS\.md[[:space:]]+merge=union" \
             "harness-progress\.html[[:space:]]+merge=ours" \
             "harness-activity\.html[[:space:]]+merge=ours" \
             "BACKLOG\.md[[:space:]]+merge=union"; do
  grep -qE "$entry" "$ROOT/.gitattributes"
  chk "$?" ".gitattributes: $entry present"
done

# ==== Real-git fixture: bare "remote" + a local clone with merge drivers registered ====
REMOTE="$TMP/remote.git"
git init -q --bare "$REMOTE"
git -C "$REMOTE" symbolic-ref HEAD refs/heads/main

LOCAL="$TMP/local"
git clone -q "$REMOTE" "$LOCAL" >/dev/null 2>&1
(
  cd "$LOCAL" || exit 1
  git config user.email t@example.com; git config user.name tester
  git config merge.ours.driver true
  printf 'harness-progress.html merge=ours\n' > .gitattributes
  printf 'v1\n' > harness-progress.html
  printf 'real\n' > real.txt
  git add -A && git commit -q -m init
  git push -q origin HEAD:main
  git remote set-head origin main
) >/dev/null 2>&1

# Clone $REMOTE into $TMP/<dir>, create <branch>, write <content> into <file> (overwrite unless
# <mode> is "append"), commit, push. Collapses the covered/checkedout/uncovered fixture setup
# below into one call each — they differ only in dir/branch/file/content/message/mode.
# Mode matters for the uncovered case: appending (not overwriting) real.txt is what makes both
# sides' changes land on the same line and produce a genuine, unresolvable conflict.
make_pr_branch() {
  local dir="$1" branch="$2" file="$3" content="$4" msg="$5" mode="${6:-write}"
  git clone -q "$REMOTE" "$TMP/$dir" >/dev/null 2>&1
  (
    cd "$TMP/$dir" || exit 1
    git config user.email t@example.com; git config user.name tester
    git checkout -q -b "$branch"
    if [ "$mode" = append ]; then
      printf '%s\n' "$content" >> "$file"
    else
      printf '%s\n' "$content" > "$file"
    fi
    git commit -aq -m "$msg"
    git push -q origin "$branch"
  ) >/dev/null 2>&1
}

# feat/covered: diverges from main on harness-progress.html only (driver-covered).
make_pr_branch covered-clone feat/covered harness-progress.html "branch version" "feat: branch touches dashboard"

# feat/checkedout: same shape as feat/covered, used for the live-worktree skip test.
make_pr_branch checkedout-clone feat/checkedout harness-progress.html "branch version 2" "feat: branch touches dashboard too"

# main moves: bumps harness-progress.html (conflicts with both branches above, driver-covered).
(
  cd "$LOCAL" || exit 1
  git checkout -q -b bump1 origin/main
  printf 'main version\n' > harness-progress.html
  git commit -aq -m "chore: main also touches dashboard"
  git push -q origin bump1:main
  git fetch -q origin main
) >/dev/null 2>&1

# feat/uncovered: diverges from (post-bump1) main on real.txt — no merge strategy declared.
# Appending (not overwriting) is what makes this collide with main's own append below.
make_pr_branch uncovered-clone feat/uncovered real.txt "branch edit" "feat: branch edits real.txt" append

# main moves again: also edits real.txt — genuine conflict, no driver to resolve it.
(
  cd "$LOCAL" || exit 1
  git checkout -q -b bump2 origin/main
  printf 'main edit\n' >> real.txt
  git commit -aq -m "chore: main edits real.txt too"
  git push -q origin bump2:main
) >/dev/null 2>&1

# feat/cleanuncovered: touches a DIFFERENT line of notes.txt than main does below, so the plain
# git merge succeeds with no conflict markers — the only thing that should flag this one is the
# coverage check, not the merge step. This closes the gap /cr's review found: without this
# fixture, a stubbed-out coverage check would still pass every existing test.
(
  cd "$LOCAL" || exit 1
  git checkout -q -b bump2b origin/main
  printf 'one\ntwo\nthree\n' > notes.txt
  git add notes.txt && git commit -q -m "chore: add notes.txt"
  git push -q origin bump2b:main
  git fetch -q origin main
) >/dev/null 2>&1
git clone -q "$REMOTE" "$TMP/cleanuncovered-clone" >/dev/null 2>&1
(
  cd "$TMP/cleanuncovered-clone" || exit 1
  git config user.email t@example.com; git config user.name tester
  git checkout -q -b feat/cleanuncovered
  printf 'ONE\ntwo\nthree\n' > notes.txt
  git commit -aq -m "feat: branch edits notes.txt line 1"
  git push -q origin feat/cleanuncovered
) >/dev/null 2>&1
(
  cd "$LOCAL" || exit 1
  git checkout -q -b bump3 origin/main
  printf 'one\ntwo\nTHREE\n' > notes.txt
  git commit -aq -m "chore: main edits notes.txt line 3"
  git push -q origin bump3:main
) >/dev/null 2>&1

# feat/fork: same shape as feat/covered, but flagged cross-repository — must never be touched.
make_pr_branch fork-clone feat/fork harness-progress.html "fork version" "feat: fork touches dashboard"

UNCOVERED_TIP_BEFORE=$(git -C "$REMOTE" rev-parse feat/uncovered)
CHECKEDOUT_TIP_BEFORE=$(git -C "$REMOTE" rev-parse feat/checkedout)
CLEANUNCOVERED_TIP_BEFORE=$(git -C "$REMOTE" rev-parse feat/cleanuncovered)
COVERED_TIP_BEFORE=$(git -C "$REMOTE" rev-parse feat/covered)
FORK_TIP_BEFORE=$(git -C "$REMOTE" rev-parse feat/fork)

# Check out feat/checkedout in a live worktree inside $LOCAL, so the sync script must skip it.
git -C "$LOCAL" fetch -q origin feat/checkedout
git -C "$LOCAL" worktree add --quiet -B feat/checkedout "$TMP/live-wt" origin/feat/checkedout >/dev/null 2>&1

cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*)
    echo '[{"number":201,"headRefName":"feat/covered","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false,"isCrossRepository":false},{"number":202,"headRefName":"feat/uncovered","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false,"isCrossRepository":false},{"number":203,"headRefName":"feat/checkedout","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false,"isCrossRepository":false},{"number":204,"headRefName":"feat/cleanuncovered","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false,"isCrossRepository":false},{"number":205,"headRefName":"feat/fork","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false,"isCrossRepository":true}]'
    ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"

OUT=$(run_with_stub "$LOCAL"); EC=$?
chk "$EC" "real-git: script always exits 0"

# ---- Behavior 6: a merge fully covered by registered drivers is reported resolvable, NOT pushed ----
printf '%s' "$OUT" | grep -qF "resolvable #201 (feat/covered) — not a real conflict, push it yourself:"
chk "$?" "covered: resolvable line printed with the push-it-yourself command"
COVERED_TIP_AFTER=$(git -C "$REMOTE" rev-parse feat/covered)
[ "$COVERED_TIP_AFTER" = "$COVERED_TIP_BEFORE" ]
chk "$?" "covered: remote branch NOT pushed to (diagnose-only, never auto-publishes)"

# ---- Behavior 7: a genuine content conflict is reported, not force-resolved ----
printf '%s' "$OUT" | grep -qF "failed #202 (feat/uncovered) — real conflict, resolve manually:"
chk "$?" "uncovered: real-conflict message printed"
UNCOVERED_TIP_AFTER=$(git -C "$REMOTE" rev-parse feat/uncovered)
[ "$UNCOVERED_TIP_AFTER" = "$UNCOVERED_TIP_BEFORE" ]
chk "$?" "uncovered: remote branch left untouched"

# ---- Behavior 8: a branch checked out in a live worktree is skipped, never touched ----
printf '%s' "$OUT" | grep -qF "skipped #203 (feat/checkedout) — checked out in another worktree, check it yourself"
chk "$?" "checked-out: skip message printed"
CHECKEDOUT_TIP_AFTER=$(git -C "$REMOTE" rev-parse feat/checkedout)
[ "$CHECKEDOUT_TIP_AFTER" = "$CHECKEDOUT_TIP_BEFORE" ]
chk "$?" "checked-out: remote branch left untouched"

# ---- Behavior 9: a merge that succeeds cleanly but touches an uncovered file is still flagged ----
# This is the case a stubbed-out coverage check would silently let through — the git merge alone
# has no conflict markers here, so only the coverage check catches it.
printf '%s' "$OUT" | grep -qF "failed #204 (feat/cleanuncovered) — merge touched files outside the registered merge strategies, needs a real /cr pass"
chk "$?" "clean-uncovered: coverage check catches a cleanly-merged-but-uncovered file"
CLEANUNCOVERED_TIP_AFTER=$(git -C "$REMOTE" rev-parse feat/cleanuncovered)
[ "$CLEANUNCOVERED_TIP_AFTER" = "$CLEANUNCOVERED_TIP_BEFORE" ]
chk "$?" "clean-uncovered: remote branch left untouched"

# ---- Behavior 10: a cross-repository (fork) PR is never touched, regardless of coverage ----
printf '%s' "$OUT" | grep -qF "#205"
[ "$?" != 0 ]
chk "$?" "fork-PR: PR #205 never touched (no diagnose/skip/fail line)"
FORK_TIP_AFTER=$(git -C "$REMOTE" rev-parse feat/fork)
[ "$FORK_TIP_AFTER" = "$FORK_TIP_BEFORE" ]
chk "$?" "fork-PR: remote branch left untouched"

# ---- Behavior 11: no scratch worktrees are left registered afterward ----
WT_COUNT=$(git -C "$LOCAL" worktree list | wc -l | tr -d ' ')
# 2 expected: $LOCAL itself + the feat/checkedout worktree this test set up on purpose.
[ "$WT_COUNT" = "2" ]
chk "$?" "cleanup: no leftover scratch worktrees registered in \$LOCAL"

echo ""
echo "sync-open-prs: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
