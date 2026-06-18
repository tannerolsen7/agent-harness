#!/usr/bin/env bash
# Tests for scripts/comment-lint.sh — blocks WHAT comments, allows WHY comments.
#
# Each case creates a small file in a throwaway temp directory and runs the
# linter against it using --files. A WHAT comment must produce exit code 1.
# A WHY comment (or any file with only clean comments) must produce exit code 0.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LINT="$ROOT/scripts/comment-lint.sh"

[ -f "$LINT" ] || { echo "comment-lint.test: $LINT not found"; exit 1; }

pass=0; fail=0
ok() { pass=$((pass+1)); }
no() { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

# Write a temp file with the given content, run the linter, return exit code.
check() {
  local ext="$1" content="$2"
  local tmp
  tmp=$(mktemp "/tmp/cl_test_XXXXXX.$ext")
  printf '%s\n' "$content" > "$tmp"
  bash "$LINT" --files "$tmp" >/dev/null 2>&1
  local rc=$?
  rm -f "$tmp"
  return "$rc"
}

# ── WHAT comments: must be flagged (exit 1) ───────────────────────────────────

check ts  '// Get the user from the database'
[ $? -eq 1 ] && ok || no "TS: '// Get the user' should be flagged"

check ts  '// Set the value to zero'
[ $? -eq 1 ] && ok || no "TS: '// Set the value' should be flagged"

check ts  '// Return the filtered list'
[ $? -eq 1 ] && ok || no "TS: '// Return the filtered list' should be flagged"

check ts  '// Check if user is admin'
[ $? -eq 1 ] && ok || no "TS: '// Check if user is admin' should be flagged"

check ts  '// This function loops over the records'
[ $? -eq 1 ] && ok || no "TS: 'This function loops over' should be flagged"

check ts  '// This method builds the response'
[ $? -eq 1 ] && ok || no "TS: 'This method builds' should be flagged"

check ts  '// Loop over the items'
[ $? -eq 1 ] && ok || no "TS: '// Loop over the items' should be flagged"

check ts  '// Call the API endpoint'
[ $? -eq 1 ] && ok || no "TS: '// Call the API endpoint' should be flagged"

check ts  '// Fetch the user profile'
[ $? -eq 1 ] && ok || no "TS: '// Fetch the user profile' should be flagged"

check ts  '// Parse the response JSON'
[ $? -eq 1 ] && ok || no "TS: '// Parse the response JSON' should be flagged"

check sh  '# Get the config file'
[ $? -eq 1 ] && ok || no "SH: '# Get the config file' should be flagged"

check sh  '# Set the output path'
[ $? -eq 1 ] && ok || no "SH: '# Set the output path' should be flagged"

check py  '# Load the dataset'
[ $? -eq 1 ] && ok || no "PY: '# Load the dataset' should be flagged"

check go  '// Build the request payload'
[ $? -eq 1 ] && ok || no "GO: '// Build the request payload' should be flagged"

check ts  '  // Initialize the store'
[ $? -eq 1 ] && ok || no "TS: indented '// Initialize the store' should be flagged"

# ── WHY comments: must pass (exit 0) ─────────────────────────────────────────

check ts  '// We skip the cache here because the token may have rotated'
[ $? -eq 0 ] && ok || no "WHY: 'because' exemption should pass"

check ts  '// Fetch early so that the data is warm before the modal opens'
[ $? -eq 0 ] && ok || no "WHY: 'so that' exemption should pass"

check ts  '// NOTE: this is a workaround for the Safari date-parsing bug'
[ $? -eq 0 ] && ok || no "WHY: 'NOTE:' exemption should pass"

check ts  '// TODO: replace with the new API once it is stable'
[ $? -eq 0 ] && ok || no "WHY: 'TODO:' exemption should pass"

check ts  '// HACK: avoid the race condition until the lock is released'
[ $? -eq 0 ] && ok || no "WHY: 'HACK:' exemption should pass"

check ts  '// FIXME: prevent the double-submit when the button is clicked fast'
[ $? -eq 0 ] && ok || no "WHY: 'FIXME:' exemption should pass"

check ts  '// Guard against null — the API can return null for deleted accounts'
[ $? -eq 0 ] && ok || no "WHY: 'guard' reasoning should pass"

check ts  '// Legacy compat: the old API returns a string, the new one returns a number'
[ $? -eq 0 ] && ok || no "WHY: 'legacy compat' should pass"

# ── File type exemptions: skipped file types must always pass ────────────────

check md  '# Get the user'   # markdown is not checked
[ $? -eq 0 ] && ok || no "Exemption: .md files should be skipped"

# ── Clean files with no comments: must pass ───────────────────────────────────

check ts  'const x = 1 + 2;'
[ $? -eq 0 ] && ok || no "Clean TS file with no comments should pass"

check sh  'set -e; echo hello'
[ $? -eq 0 ] && ok || no "Clean shell file with no comments should pass"

# ── Multiple lines: flag only the bad ones ────────────────────────────────────

MULTI=$(printf '%s\n' \
  '// We load the user early so that auth checks are fast' \
  '// Get the email address' \
  'const x = 1')
check ts "$MULTI"
[ $? -eq 1 ] && ok || no "Mixed file: WHAT comment in multi-line file should be flagged"

# Exit code is 0 only when all good
CLEAN=$(printf '%s\n' \
  '// We use a queue here because the downstream API rate-limits at 10 req/s' \
  'const x = 1')
check ts "$CLEAN"
[ $? -eq 0 ] && ok || no "Mixed file: only WHY comments should pass"

echo ""
echo "comment-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
