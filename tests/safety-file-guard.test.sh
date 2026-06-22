#!/usr/bin/env bash
# Tests the safety-file guard in .husky/pre-commit.
# The guard blocks agent commits of safety-critical files: hook scripts,
# permission settings, gate scripts, package wiring, and credential files.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-commit"
[ -f "$HOOK" ] || { echo "safety-file-guard.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

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

run_hook() {
  bash "$HOOK" >/dev/null 2>&1
  echo $?
}

# ── .husky/* — modifications, new files, and deletions are all blocked ──

echo "── staging a .husky/* modification is blocked ──"
D=$(mk)
mkdir -p "$D/.husky"
printf 'echo hook\n' > "$D/.husky/pre-commit"
(cd "$D" && git add .husky/pre-commit) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (husky modification): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging a new .husky/* file is blocked ──"
D=$(mk)
mkdir -p "$D/.husky"
printf 'echo new-hook\n' > "$D/.husky/post-merge"
(cd "$D" && git add .husky/post-merge) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (husky new file): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── deleting a .husky/* file is blocked ──"
D=$(mk)
mkdir -p "$D/.husky"
printf 'echo hook\n' > "$D/.husky/some-hook"
(cd "$D" && git add .husky/some-hook && git commit -q --no-verify -m 'add hook') >/dev/null 2>&1
(cd "$D" && git rm -q .husky/some-hook) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (husky deletion): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging a normal file does not trigger the hook-files guard ──"
D=$(mk)
printf 'hello\n' > "$D/normal.txt"
(cd "$D" && git add normal.txt) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  fail=$((fail+1))
  echo "  MISS (normal file): hook-files guard fired on normal staged file"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo ""
echo "safety-file-guard (slice 1): $pass passed, $fail failed"
[ "$fail" -eq 0 ]
