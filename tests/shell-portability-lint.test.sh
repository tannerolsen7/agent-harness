#!/usr/bin/env bash
# portability-lint: skip-file — this file contains the bad patterns as test data, not as real code.
# Tests scripts/shell-portability-lint.sh for three portability patterns
# that fail on BSD/macOS or bash 3.2: mktemp -p, printf with leading dash,
# and git worktree list --porcelain piped to grep.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/shell-portability-lint.sh"
[ -f "$SCRIPT" ] || { echo "shell-portability-lint.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0
ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

# Write a temp file with given content and run the linter on it.
run() {
  local tmp
  tmp=$(mktemp /tmp/portability-lint-test-XXXXXX.sh)
  printf '%s\n' "$1" > "$tmp"
  bash "$SCRIPT" "$tmp" >/dev/null 2>&1
  local rc=$?
  rm -f "$tmp"
  echo "$rc"
}

# Write a file and capture both exit code and stderr.
run_err() {
  local tmp
  tmp=$(mktemp /tmp/portability-lint-test-XXXXXX.sh)
  printf '%s\n' "$1" > "$tmp"
  bash "$SCRIPT" "$tmp" 2>&1
  local rc=$?
  rm -f "$tmp"
  return $rc
}

echo "── mktemp -p lint ──"
ok "$(run 'mktemp -p /tmp')"                                           1 "mktemp -p exits 1"
ok "$(run 'mktemp /tmp/file.XXXXXX')"                                  0 "mktemp without -p exits 0"
ok "$(run '# mktemp -p is documented here')"                           0 "mktemp -p in comment skipped"
err=$(run_err 'mktemp -p /tmp'; true)
if printf '%s' "$err" | grep -q "mktemp -p" && printf '%s' "$err" | grep -q ":1:"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (mktemp error message): missing file/line or explanation. got: $err"
fi

echo "── printf leading-dash lint ──"
ok "$(run "printf '- item'")"                                          1 "printf single-quote dash exits 1"
ok "$(run 'printf "- item"')"                                          1 "printf double-quote dash exits 1"
ok "$(run "printf '-%s' foo")"                                         1 "printf '-%s' exits 1"
ok "$(run "printf -- '- item'")"                                       0 "printf -- passes"
ok "$(run "# printf '- item' is bad")"                                 0 "printf dash in comment skipped"
err=$(run_err "printf '- item'"; true)
if printf '%s' "$err" | grep -q ":1:"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (printf error message): missing line number. got: $err"
fi

echo "── worktree detection lint ──"
ok "$(run 'git worktree list --porcelain | grep path')"                1 "worktree list piped to grep exits 1"
ok "$(run 'git worktree list --porcelain')"                            0 "worktree list without grep exits 0"
ok "$(run '# git worktree list --porcelain | grep is bad')"            0 "worktree grep in comment skipped"
err=$(run_err 'git worktree list --porcelain | grep path'; true)
if printf '%s' "$err" | grep -q '\.git'; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (worktree error): error should mention .git alternative. got: $err"
fi

echo "── clean file exits 0 ──"
ok "$(run 'mktemp /tmp/x.XXXXXX'$'\n''printf -- "hello"')"            0 "clean file passes"

echo "── multiple violations all reported ──"
multi=$(printf '%s\n' "mktemp -p /tmp" "printf '- foo'")
tmp=$(mktemp /tmp/portability-lint-test-XXXXXX.sh)
printf '%s\n' "$multi" > "$tmp"
err=$(bash "$SCRIPT" "$tmp" 2>&1; true)
rm -f "$tmp"
if printf '%s' "$err" | grep -q ":1:" && printf '%s' "$err" | grep -q ":2:"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (multiple violations): expected line 1 and line 2 reported. got: $err"
fi

echo ""
echo "shell-portability-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
