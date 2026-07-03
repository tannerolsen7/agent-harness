#!/usr/bin/env bash
# Tests scripts/skill-frontmatter-lint.sh against docs/testing/skill-frontmatter-lint.md.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/skill-frontmatter-lint.sh"
[ -f "$SCRIPT" ] || { echo "skill-frontmatter-lint.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0
ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

# A single helper (not a run/run_err pair) so every call site has the same
# shape: `run ... >/dev/null 2>&1; ok "$?" ...` for exit-code checks, or
# `err=$(run ...; true)` for message checks — the `; true` stops a non-zero
# exit from tripping `set -u`/pipefail in the caller.
run() {
  local dir="$1" content="$2"
  local tmp
  tmp=$(mktemp -d /tmp/skill-frontmatter-lint-test-XXXXXX)
  mkdir -p "$tmp/$dir"
  printf '%s' "$content" > "$tmp/$dir/SKILL.md"
  bash "$SCRIPT" "$tmp/$dir/SKILL.md" 2>&1
  local rc=$?
  rm -rf "$tmp"
  return $rc
}

GOOD='---
name: foo-bar
description: Does a thing. Use when doing the thing.
---

# Foo Bar
'

echo "── frontmatter block presence ──"
run foo-bar "$GOOD" >/dev/null 2>&1; ok "$?" 0 "well-formed frontmatter passes"
run foo-bar '# No frontmatter here' >/dev/null 2>&1; ok "$?" 1 "missing frontmatter block exits 1"
err=$(run foo-bar '# No frontmatter here'; true)
if printf '%s' "$err" | grep -q "no frontmatter block"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (no-frontmatter message): expected 'no frontmatter block'. got: $err"
fi

echo "── name/description field presence ──"
NO_NAME='---
description: Does a thing. Use when doing the thing.
---
'
NO_DESC='---
name: foo-bar
---
'
EMPTY_NAME='---
name:
description: Does a thing. Use when doing the thing.
---
'
EMPTY_DESC='---
name: foo-bar
description:
---
'
run foo-bar "$NO_NAME" >/dev/null 2>&1; ok "$?" 1 "missing name: exits 1"
run foo-bar "$NO_DESC" >/dev/null 2>&1; ok "$?" 1 "missing description: exits 1"
run foo-bar "$EMPTY_NAME" >/dev/null 2>&1; ok "$?" 1 "empty name: exits 1"
run foo-bar "$EMPTY_DESC" >/dev/null 2>&1; ok "$?" 1 "empty description: exits 1"
err=$(run foo-bar "$NO_NAME"; true)
if printf '%s' "$err" | grep -qi "name"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (missing-name message): expected to mention 'name'. got: $err"
fi
err=$(run foo-bar "$NO_DESC"; true)
if printf '%s' "$err" | grep -qi "description"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (missing-description message): expected to mention 'description'. got: $err"
fi

echo "── name matches parent directory ──"
MISMATCHED='---
name: something-else
description: Does a thing. Use when doing the thing.
---
'
run foo-bar "$GOOD" >/dev/null 2>&1; ok "$?" 0 "name matching directory passes"
run foo-bar "$MISMATCHED" >/dev/null 2>&1; ok "$?" 1 "name not matching directory exits 1"
err=$(run foo-bar "$MISMATCHED"; true)
if printf '%s' "$err" | grep -q "something-else" && printf '%s' "$err" | grep -q "foo-bar"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (name-mismatch message): expected both the frontmatter name and directory name. got: $err"
fi

echo "── description length ──"
# "Use when " is 9 chars; pad to exactly 1024 / 1025 total description chars.
PAD_1015=$(printf 'a%.0s' $(seq 1 1015))
PAD_1016=$(printf 'a%.0s' $(seq 1 1016))
AT_LIMIT="---
name: foo-bar
description: Use when ${PAD_1015}
---
"
OVER_LIMIT="---
name: foo-bar
description: Use when ${PAD_1016}
---
"
run foo-bar "$AT_LIMIT" >/dev/null 2>&1; ok "$?" 0 "description at 1024 chars passes"
run foo-bar "$OVER_LIMIT" >/dev/null 2>&1; ok "$?" 1 "description over 1024 chars exits 1"
err=$(run foo-bar "$OVER_LIMIT"; true)
if printf '%s' "$err" | grep -q "1024"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (description-length message): expected to mention the 1024 limit. got: $err"
fi

echo "── trigger phrase ──"
NO_TRIGGER='---
name: foo-bar
description: Does a thing without saying when.
---
'
run foo-bar "$GOOD" >/dev/null 2>&1; ok "$?" 0 "description with 'Use when' passes"
run foo-bar "$NO_TRIGGER" >/dev/null 2>&1; ok "$?" 1 "description missing 'Use when' exits 1"
err=$(run foo-bar "$NO_TRIGGER"; true)
if printf '%s' "$err" | grep -qi "use when"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (trigger-phrase message): expected to mention 'Use when'. got: $err"
fi

echo "── aggregation and reporting ──"
LONG_DESC=$(printf 'a%.0s' $(seq 1 1030))
MULTI_VIOLATION="---
description: ${LONG_DESC}
---
"
err=$(run foo-bar "$MULTI_VIOLATION"; true)
if printf '%s' "$err" | grep -qi "name" && printf '%s' "$err" | grep -q "1024"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (multi-violation): expected both a name violation and a length violation. got: $err"
fi

tmp1=$(mktemp -d /tmp/skill-frontmatter-lint-test-XXXXXX)
mkdir -p "$tmp1/foo-bar" "$tmp1/baz"
printf '%s' "$GOOD" > "$tmp1/foo-bar/SKILL.md"
printf '%s' "$NO_TRIGGER" > "$tmp1/baz/SKILL.md"
multi_err=$(bash "$SCRIPT" "$tmp1/foo-bar/SKILL.md" "$tmp1/baz/SKILL.md" 2>&1; true)
if printf '%s' "$multi_err" | grep -q "baz" && ! printf '%s' "$multi_err" | grep -q "foo-bar/SKILL.md:"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (multi-file): expected only baz flagged, foo-bar clean. got: $multi_err"
fi
rm -rf "$tmp1"

bash "$SCRIPT" /nonexistent/path/SKILL.md >/dev/null 2>&1; ok "$?" 0 "missing file argument is skipped, not a violation"

echo "── quoted empty values (/cr fix: quote-stripping) ──"
QUOTED_EMPTY_NAME='---
name: ""
description: Does a thing. Use when doing the thing.
---
'
QUOTED_EMPTY_DESC='---
name: foo-bar
description: ""
---
'
run foo-bar "$QUOTED_EMPTY_NAME" >/dev/null 2>&1; ok "$?" 1 "quoted empty name: exits 1"
err=$(run foo-bar "$QUOTED_EMPTY_NAME"; true)
if printf '%s' "$err" | grep -q "name: field is empty"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (quoted-empty-name message): expected 'name: field is empty'. got: $err"
fi
run foo-bar "$QUOTED_EMPTY_DESC" >/dev/null 2>&1; ok "$?" 1 "quoted empty description: exits 1"
err=$(run foo-bar "$QUOTED_EMPTY_DESC"; true)
if printf '%s' "$err" | grep -q "description: field is empty"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (quoted-empty-description message): expected 'description: field is empty'. got: $err"
fi

echo "── quoted non-empty name still matches directory ──"
QUOTED_NAME='---
name: "foo-bar"
description: Does a thing. Use when doing the thing.
---
'
run foo-bar "$QUOTED_NAME" >/dev/null 2>&1; ok "$?" 0 "quoted name matching directory passes"

echo "── bare filename with no parent directory ──"
tmp2=$(mktemp -d /tmp/skill-frontmatter-lint-test-XXXXXX)
printf '%s' "$GOOD" > "$tmp2/SKILL.md"
( cd "$tmp2" && bash "$SCRIPT" SKILL.md >/dev/null 2>&1 ); ok "$?" 0 "bare filename with no dirname does not false-positive on directory match"
rm -rf "$tmp2"

echo "── directory passed as argument ──"
tmp3=$(mktemp -d /tmp/skill-frontmatter-lint-test-XXXXXX)
mkdir -p "$tmp3/foo-bar"
printf '%s' "$GOOD" > "$tmp3/foo-bar/SKILL.md"
dir_err=$(bash "$SCRIPT" "$tmp3/foo-bar" 2>&1; true)
if printf '%s' "$dir_err" | grep -q "not a regular file"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (directory-as-arg): expected 'not a regular file'. got: $dir_err"
fi
rm -rf "$tmp3"

echo "── CRLF line endings ──"
tmp4=$(mktemp -d /tmp/skill-frontmatter-lint-test-XXXXXX)
mkdir -p "$tmp4/foo-bar"
printf -- '---\r\nname: foo-bar\r\ndescription: Does a thing. Use when doing the thing.\r\n---\r\n' > "$tmp4/foo-bar/SKILL.md"
crlf_rc=0
bash "$SCRIPT" "$tmp4/foo-bar/SKILL.md" >/dev/null 2>&1 || crlf_rc=$?
ok "$crlf_rc" 0 "CRLF frontmatter is parsed like LF"
rm -rf "$tmp4"

echo "── clean run across multiple files exits 0 with no output ──"
tmp5=$(mktemp -d /tmp/skill-frontmatter-lint-test-XXXXXX)
mkdir -p "$tmp5/foo-bar" "$tmp5/baz"
printf '%s' "$GOOD" > "$tmp5/foo-bar/SKILL.md"
printf -- '---\nname: baz\ndescription: Does a thing. Use when doing the thing.\n---\n' > "$tmp5/baz/SKILL.md"
clean_out=$(bash "$SCRIPT" "$tmp5/foo-bar/SKILL.md" "$tmp5/baz/SKILL.md" 2>&1; true)
clean_rc=0
bash "$SCRIPT" "$tmp5/foo-bar/SKILL.md" "$tmp5/baz/SKILL.md" >/dev/null 2>&1 || clean_rc=$?
ok "$clean_rc" 0 "clean run across multiple files exits 0"
if [ -z "$clean_out" ]; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (clean multi-file output): expected no output. got: $clean_out"
fi
rm -rf "$tmp5"

echo ""
echo "skill-frontmatter-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
