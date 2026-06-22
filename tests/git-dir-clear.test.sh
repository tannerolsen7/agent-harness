#!/usr/bin/env bash
# Tests the GIT_DIR clearing check in .husky/pre-commit.
# Every staged *.test.sh file must contain the line that clears git
# environment variables. Without it, tests that create temp git repos
# inherit the real repo's environment and can corrupt the working tree.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-commit"
[ -f "$HOOK" ] || { echo "git-dir-clear.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got exit $1, want $2"; fail=$((fail+1)); fi; }

UNSET_LINE='unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE'

mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m init
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

run_hook() {
  bash "$HOOK" >/dev/null 2>&1
  echo $?
}

echo "── staged *.test.sh missing the unset line exits 1 ──"
D=$(mk)
printf '#!/usr/bin/env bash\necho hi\n' > "$D/foo.test.sh"
rc=$(cd "$D" && git add foo.test.sh && run_hook)
ok "$rc" 1 "missing unset line blocked"
rm -rf "$D"

echo "── staged *.test.sh with the unset line passes ──"
D=$(mk)
printf '#!/usr/bin/env bash\n%s\necho hi\n' "$UNSET_LINE" > "$D/foo.test.sh"
err=$(cd "$D" && git add foo.test.sh && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "GIT_DIR\|unset line\|git env"; then
  fail=$((fail+1))
  echo "  MISS (unset line present): GIT_DIR check fired when it should not"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo "── error explains why the line is needed ──"
D=$(mk)
printf '#!/usr/bin/env bash\necho hi\n' > "$D/foo.test.sh"
err=$(cd "$D" && git add foo.test.sh && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "GIT_DIR\|unset\|git env"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (error explains): stderr='$err'"
fi
rm -rf "$D"

echo "── non-test .sh files are not checked ──"
D=$(mk)
printf '#!/usr/bin/env bash\necho hi\n' > "$D/helper.sh"
err=$(cd "$D" && git add helper.sh && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "GIT_DIR\|unset line\|git env"; then
  fail=$((fail+1))
  echo "  MISS (non-test excluded): GIT_DIR check fired on .sh (not .test.sh)"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo "── .md files are not checked ──"
D=$(mk)
printf '# Some doc\n' > "$D/notes.md"
err=$(cd "$D" && git add notes.md && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "GIT_DIR\|unset line\|git env"; then
  fail=$((fail+1))
  echo "  MISS (.md excluded): GIT_DIR check fired on .md file"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo ""
echo "git-dir-clear: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
