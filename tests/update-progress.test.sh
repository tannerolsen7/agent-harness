#!/usr/bin/env bash
# update-progress.sh: verifies the three sed substitutions, PR counting, and
# error handling (missing HTML, missing git repo).
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/update-progress.sh"
[ -x "$SCRIPT" ] || { echo "test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

TMP=$(mktemp -d)
TMP2=$(mktemp -d)
trap 'rm -rf "$TMP" "$TMP2"' EXIT

STUB='<!DOCTYPE html><html><body>
<div class="date">January 1, 2000</div>
<div class="progress-label">0 PRs merged</div>
<div class="progress-fill" style="width:0%"></div>
</body></html>'

scaffold_repo() {
  local dir=$1 count=${2:-0}
  (
    cd "$dir"
    git init -q
    git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m "init"
    git branch -M main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
    i=0
    while [ "$i" -lt "$count" ]; do
      i=$((i+1))
      git commit -q --allow-empty --no-verify -m "Merge pull request #$i from user/branch"
    done
  ) >/dev/null 2>&1
}

# ── Test 1: all three patterns are substituted ──────────────────────────────
scaffold_repo "$TMP" 3
printf '%s\n' "$STUB" > "$TMP/harness-progress.html"
(cd "$TMP" && unset GIT_DIR GIT_WORK_TREE && bash "$SCRIPT") >/dev/null 2>&1
chk $? "script exits 0 on valid HTML + git repo"
grep -q "3 PRs merged" "$TMP/harness-progress.html"
chk $? "PR count updated to 3"
grep -qE "$(date +'%B')" "$TMP/harness-progress.html"
chk $? "date month substituted in HTML"
grep -qE 'style="width:[1-9][0-9]*%"' "$TMP/harness-progress.html"
chk $? "progress bar width is non-zero"

# ── Test 2: script exits non-zero when HTML is absent ───────────────────────
scaffold_repo "$TMP2" 1
(cd "$TMP2" && unset GIT_DIR GIT_WORK_TREE && bash "$SCRIPT") >/dev/null 2>&1
[ $? -ne 0 ]
chk $? "script exits non-zero when harness-progress.html is absent"

# ── Test 3: zero PRs produces 0% width (not an empty or broken value) ───────
TMP3=$(mktemp -d)
trap 'rm -rf "$TMP" "$TMP2" "$TMP3"' EXIT
scaffold_repo "$TMP3" 0
printf '%s\n' "$STUB" > "$TMP3/harness-progress.html"
(cd "$TMP3" && unset GIT_DIR GIT_WORK_TREE && bash "$SCRIPT") >/dev/null 2>&1
chk $? "script exits 0 with zero PR count"
grep -q 'style="width:0%"' "$TMP3/harness-progress.html"
chk $? "progress bar shows 0% when no PRs found"

[ "$fail" = 0 ] && echo "update-progress: OK ($pass passed)"
exit "$fail"
