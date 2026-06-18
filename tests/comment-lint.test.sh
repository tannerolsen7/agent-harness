#!/usr/bin/env bash
# Tests for scripts/comment-lint.sh.
#
# Each case creates a temporary file with a specific comment, runs the linter
# against that one file, and asserts the expected exit code.
#
# GIT_DIR guard: running from inside a worktree would pollute git env vars and
# cause subshells to operate on the real repo. Unset them so each temp file
# is fully isolated. See PITFALLS.md — "Running tests from inside a worktree
# corrupts the real repo."
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/comment-lint.sh"
[ -f "$SCRIPT" ] || { echo "comment-lint.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0

ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

# Create a temp shell script with the given comment line and run the linter.
# Prints the exit code.
run_sh() {
  local comment="$1"
  local tmp
  tmp=$(mktemp /tmp/comment-lint-test-XXXXXX.sh)
  printf '#!/usr/bin/env bash\n%s\nls\n' "$comment" > "$tmp"
  bash "$SCRIPT" "$tmp" >/dev/null 2>&1
  local rc=$?
  rm -f "$tmp"
  echo "$rc"
}

# Same but for a .js file.
run_js() {
  local comment="$1"
  local tmp
  tmp=$(mktemp /tmp/comment-lint-test-XXXXXX.js)
  printf '%s\nconsole.log("hi");\n' "$comment" > "$tmp"
  bash "$SCRIPT" "$tmp" >/dev/null 2>&1
  local rc=$?
  rm -f "$tmp"
  echo "$rc"
}

# ---------------------------------------------------------------------------
# WHAT comments — must exit non-zero (1 = violations found)
# ---------------------------------------------------------------------------
echo "── WHAT comments (must FAIL) ──"

rc=$(run_sh "# loop through files")
ok "$rc" 1 "sh: loop through files"

rc=$(run_sh "# check if user exists")
ok "$rc" 1 "sh: check if user exists"

rc=$(run_sh "# increment counter")
ok "$rc" 1 "sh: increment counter"

rc=$(run_sh "# set the variable")
ok "$rc" 1 "sh: set the variable"

rc=$(run_sh "# filter the list")
ok "$rc" 1 "sh: filter the list"

rc=$(run_sh "# parse the response")
ok "$rc" 1 "sh: parse the response"

rc=$(run_sh "# return the result")
ok "$rc" 1 "sh: return the result"

rc=$(run_sh "# load the config")
ok "$rc" 1 "sh: load the config"

rc=$(run_sh "# validate the input")
ok "$rc" 1 "sh: validate the input"

rc=$(run_sh "# call the API")
ok "$rc" 1 "sh: call the API"

rc=$(run_js "// loop through items")
ok "$rc" 1 "js: loop through items"

rc=$(run_js "// check if authenticated")
ok "$rc" 1 "js: check if authenticated"

rc=$(run_js "// update the state")
ok "$rc" 1 "js: update the state"

rc=$(run_js "// fetch the data")
ok "$rc" 1 "js: fetch the data"

rc=$(run_js "// map the results")
ok "$rc" 1 "js: map the results"

# ---------------------------------------------------------------------------
# WHY comments — must exit 0 (no violations)
# ---------------------------------------------------------------------------
echo "── WHY comments (must PASS) ──"

rc=$(run_sh "# git merge-base returns true for empty branches (see PR #50)")
ok "$rc" 0 "sh: merge-base PR reference"

rc=$(run_sh "# workaround for bash 3.2 on macOS — array syntax differs")
ok "$rc" 0 "sh: bash 3.2 workaround"

rc=$(run_sh "# husky v10 removed the shebang line — this keeps shellcheck quiet")
ok "$rc" 0 "sh: husky v10 note"

rc=$(run_sh "# avoid double-quoting here because the glob must expand")
ok "$rc" 0 "sh: avoid reason"

rc=$(run_sh "# see https://github.com/owner/repo/issues/42 for context")
ok "$rc" 0 "sh: URL reference"

rc=$(run_sh "# note: CI runs on Linux so stat -c is required instead of stat -f")
ok "$rc" 0 "sh: note with CI context"

rc=$(run_sh "# guard against concurrent gc.sh deleting an active worktree branch")
ok "$rc" 0 "sh: guard reason"

rc=$(run_sh "# POSIX sh does not support arrays — use space-separated string instead")
ok "$rc" 0 "sh: POSIX constraint"

rc=$(run_sh "# TODO: replace with streaming once the API supports it")
ok "$rc" 0 "sh: TODO"

rc=$(run_js "// React batches state updates in event handlers — only one re-render fires")
ok "$rc" 0 "js: React batching note"

rc=$(run_js "// see https://example.com/docs for the rate-limit policy")
ok "$rc" 0 "js: URL reference"

rc=$(run_js "// prevent the modal from closing when the user clicks the overlay")
ok "$rc" 0 "js: prevent reason"

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------
echo "── edge cases ──"

# An empty file should pass.
tmp=$(mktemp /tmp/comment-lint-test-XXXXXX.sh)
printf '#!/usr/bin/env bash\nls\n' > "$tmp"
rc=$(bash "$SCRIPT" "$tmp" >/dev/null 2>&1; echo $?)
ok "$rc" 0 "sh: file with no comments passes"
rm -f "$tmp"

# A non-code file (e.g. .md) passed explicitly is skipped without error.
tmp=$(mktemp /tmp/comment-lint-test-XXXXXX.md)
printf '# loop through files\n' > "$tmp"
rc=$(bash "$SCRIPT" "$tmp" >/dev/null 2>&1; echo $?)
ok "$rc" 0 "md: non-code file is skipped"
rm -f "$tmp"

echo ""
echo "comment-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
