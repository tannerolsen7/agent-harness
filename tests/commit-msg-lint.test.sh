#!/usr/bin/env bash
# Tests for scripts/commit-msg-lint.sh.
#
# Each case writes a commit message to a temp file, runs the linter, and
# asserts the expected exit code.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/commit-msg-lint.sh"
[ -f "$SCRIPT" ] || { echo "commit-msg-lint.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0

ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

# Write message to a temp file and return the script's exit code.
run() {
  local tmp
  tmp=$(mktemp /tmp/commit-msg-lint-test-XXXXXX)
  printf '%s\n' "$1" > "$tmp"
  bash "$SCRIPT" "$tmp" >/dev/null 2>&1
  local rc=$?
  rm -f "$tmp"
  echo "$rc"
}

echo "── Valid types (must PASS) ──"
ok "$(run "feat: add login")"            0 "feat"
ok "$(run "fix: correct typo")"          0 "fix"
ok "$(run "chore: update deps")"         0 "chore"
ok "$(run "docs: update readme")"        0 "docs"
ok "$(run "refactor: extract helper")"   0 "refactor"
ok "$(run "test: add coverage")"         0 "test"
ok "$(run "perf: cache results")"        0 "perf"
ok "$(run "build: add docker")"          0 "build"
ok "$(run "ci: add lint step")"          0 "ci"
ok "$(run "style: fix whitespace")"      0 "style"
ok "$(run "revert: undo previous")"      0 "revert type"

echo "── Scope variants (must PASS) ──"
ok "$(run "fix(auth): correct token")"   0 "scope present"
ok "$(run "feat(ui-lib): add button")"   0 "scope with hyphen"
ok "$(run "feat(auth)!: drop legacy")"   0 "breaking change"
ok "$(run "fix!: drop old api")"         0 "breaking without scope"

echo "── Auto-generated commits (must PASS) ──"
ok "$(run "Merge branch 'main'")"                    0 "merge commit"
ok "$(run "squash! feat: something")"                0 "squash"
ok "$(run "fixup! fix: typo")"                       0 "fixup"
ok "$(run 'Revert "feat: add login"')"               0 "revert commit"

echo "── Unknown type (must FAIL) ──"
ok "$(run "wip: something")"             1 "unknown type"
ok "$(run "feat - something")"           1 "dash not colon"
ok "$(run "random commit message")"      1 "no type"

echo "── Case errors on type (must FAIL) ──"
ok "$(run "Fix: something")"             1 "capitalized type"
ok "$(run "FEAT: something")"            1 "all-caps type"

echo "── Missing or invalid description (must FAIL) ──"
ok "$(run "feat: ")"                     1 "empty description"
ok "$(run "fix: Fix something")"         1 "uppercase description start"
ok "$(run "feat: 123start")"             1 "description starts with digit"

echo "── Invalid scope characters (must FAIL) ──"
ok "$(run "feat(Auth): add login")"      1 "scope uppercase"
ok "$(run "feat(my_scope): add")"        1 "scope underscore"
ok "$(run "feat(my scope): add")"        1 "scope space"

echo "── 72-char subject hard block ──"
# "feat: " = 6 chars + 66 x's = 72 chars exactly → must pass
exact72="feat: $(printf 'x%.0s' {1..66})"
ok "$(run "$exact72")"                   0 "exactly 72 chars passes"

# "feat: " = 6 chars + 70 x's = 76 chars → must block
long="feat: $(printf 'x%.0s' {1..70})"
ok "$(run "$long")"                      1 "over 72 chars is blocked"

# Auto-generated commits are exempt even when very long
long_merge="Merge branch 'feat/$(printf 'x%.0s' {1..80})'"
ok "$(run "$long_merge")"               0 "auto-generated (Merge) over 72 chars is exempt"

echo ""
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
