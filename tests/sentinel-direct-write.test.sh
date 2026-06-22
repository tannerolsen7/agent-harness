#!/usr/bin/env bash
# Tests the sentinel direct-write guard in .husky/pre-commit.
# The guard blocks commits where .claude/.cr-ok or .claude/.design-confirmed
# was staged directly (git add -f), because those files should only be
# written by scripts/cr-ok.sh and scripts/design-confirm.sh.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-commit"
[ -f "$HOOK" ] || { echo "sentinel-direct-write.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

# Create a minimal git repo and run the hook from it.
# The hook calls "bash scripts/lint.sh" etc., which won't exist here.
# The sentinel guard runs BEFORE those calls, so an early exit 1 is testable.
mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com
    git config user.name tester
    git commit -q --allow-empty --no-verify -m init
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

# Run the hook and capture its exit code.
# We deliberately allow failure in the subshell by appending "; echo $?" not "|| echo".
run_hook() {
  bash "$HOOK" >/dev/null 2>&1
  echo $?
}

echo "── staging .cr-ok directly is blocked ──"
D=$(mk)
mkdir -p "$D/.claude"
printf 'feat/x:abc123' > "$D/.claude/.cr-ok"
rc=$(cd "$D" && git add -f .claude/.cr-ok && run_hook)
ok "$rc" 1 "staging .cr-ok is blocked"
rm -rf "$D"

echo "── staging .design-confirmed directly is blocked ──"
D=$(mk)
mkdir -p "$D/.claude"
printf 'feat/x:abc123' > "$D/.claude/.design-confirmed"
rc=$(cd "$D" && git add -f .claude/.design-confirmed && run_hook)
ok "$rc" 1 "staging .design-confirmed is blocked"
rm -rf "$D"

echo "── error message names both files and their scripts ──"
D=$(mk)
mkdir -p "$D/.claude"
printf 'feat/x:abc123' > "$D/.claude/.cr-ok"
err=$(cd "$D" && git add -f .claude/.cr-ok && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "cr-ok" && \
   printf '%s' "$err" | grep -q "design-confirmed"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (error message): did not name both sentinel files"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── normal staged files are not affected ──"
D=$(mk)
# Stage a normal file; the hook will fail on scripts/lint.sh not found,
# but that's after the sentinel check. We verify it's NOT the sentinel check
# that failed by checking the error message.
printf 'hello\n' > "$D/normal.txt"
err=$(cd "$D" && git add normal.txt && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "sentinel" || \
   printf '%s' "$err" | grep -q "cr-ok" || \
   printf '%s' "$err" | grep -q "design-confirmed"; then
  fail=$((fail+1))
  echo "  MISS (normal files): sentinel guard fired on non-sentinel staged file"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo ""
echo "sentinel-direct-write: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
