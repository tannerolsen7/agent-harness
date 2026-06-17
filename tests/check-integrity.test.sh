#!/usr/bin/env bash
# check-integrity.sh scans markdown docs for broken cross-links: a relative link to a
# .md file (or a file under solutions/, scripts/, .claude/) that does not exist on disk.
# It catches context-doc rot before it reaches a reader. All cases are hermetic: each
# builds a throwaway repo with its own docs tree so the check runs against fixtures, not
# this repo. The script resolves the repo root with `git rev-parse`, so a temp repo works.
#
# GIT_DIR guard: running this test from inside a worktree would inherit GIT_DIR and cause
# git commands inside mk() subshells to operate on the real repo instead of the temp dir.
# Unset all git env vars at the top of the script so the temp repos are fully isolated.
# See PITFALLS.md — "Running tests from inside a worktree corrupts the real repo."
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/check-integrity.sh"
[ -f "$SCRIPT" ] || { echo "test: $SCRIPT not found"; exit 1; }

pass=0; fail=0
ok()  { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got '$1', want '$2'"; fail=$((fail+1)); fi; }
hasout() { if printf '%s' "$1" | grep -qi "$2"; then pass=$((pass+1)); else echo "  MISS ($3): output missing '$2'"; fail=$((fail+1)); fi; }
clean() { d="$1"; [ -n "$d" ] && [ -d "$d" ] && find "$d" -mindepth 0 -delete 2>/dev/null; }

# Build a fresh repo with a copy of check-integrity.sh and an empty docs/ tree; print its dir.
mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com; git config user.name tester
    mkdir -p scripts docs
    cp "$SCRIPT" scripts/check-integrity.sh
    chmod +x scripts/check-integrity.sh
    git add -A && git commit -q -m init  # no hooks in temp fixture repos
  ) >/dev/null 2>&1
  echo "$d"
}
echo "── all links resolve: exit 0 ──"
D=$(mk)
( cd "$D" && printf 'See [b](./b.md).\n' > docs/a.md && printf 'hi\n' > docs/b.md )
out=$(cd "$D" && bash scripts/check-integrity.sh 2>&1); rc=$?
ok "$rc" 0 "clean tree exit 0"
hasout "$out" "OK" "reports OK"
clean "$D"

echo "── broken relative link: exit non-zero, names the file and the dead target ──"
D=$(mk)
( cd "$D" && printf 'See [gone](./missing.md).\n' > docs/a.md )
out=$(cd "$D" && bash scripts/check-integrity.sh 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: broken link should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "missing.md" "names the dead target"
hasout "$out" "docs/a.md" "names the source file"
clean "$D"

echo "── link with anchor resolves to the file part: ./b.md#sec is OK if b.md exists ──"
D=$(mk)
( cd "$D" && printf 'See [b](./b.md#section).\n' > docs/a.md && printf 'hi\n' > docs/b.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
ok "$rc" 0 "anchor link to existing file is OK"
clean "$D"

echo "── template placeholder link (contains <>) is skipped, not flagged ──"
D=$(mk)
( cd "$D" && printf 'Row: [registry](./registry.md#<slug>).\n' > docs/a.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
ok "$rc" 0 "placeholder link with <> is skipped"
clean "$D"

echo "── links inside fenced code blocks are skipped ──"
D=$(mk)
( cd "$D" && printf '%s\n' '```' '[skel](./does-not-exist.md)' '```' > docs/a.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
ok "$rc" 0 "fenced-code link is not checked"
clean "$D"

echo "── link inside an inline code span (backticks) is skipped ──"
D=$(mk)
( cd "$D" && printf 'Format example: `- [x](./gone.md) — note`.\n' > docs/a.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
ok "$rc" 0 "inline-code link is not checked"
clean "$D"

echo "── a live link on the same line as an inline-code link is still checked ──"
D=$(mk)
( cd "$D" && printf 'See [real](./missing.md), e.g. `[ex](./also.md)`.\n' > docs/a.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: live link outside code span should still fail"; fail=$((fail+1)); fi
clean "$D"

echo "── external links (http/https/mailto) are skipped ──"
D=$(mk)
( cd "$D" && printf 'See [x](https://example.com/y.md) and [m](mailto:a@b.com).\n' > docs/a.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
ok "$rc" 0 "external links skipped"
clean "$D"

echo "── ../ link from a nested doc resolves against the doc's own dir ──"
D=$(mk)
( cd "$D" && mkdir -p docs/sub && printf 'up [b](../b.md).\n' > docs/sub/a.md && printf 'hi\n' > docs/b.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
ok "$rc" 0 "../ link resolves from the doc's own directory"
clean "$D"

echo "── broken ../ link from nested doc is caught ──"
D=$(mk)
( cd "$D" && mkdir -p docs/sub && printf 'up [b](../nope.md).\n' > docs/sub/a.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: broken ../ link should fail"; fail=$((fail+1)); fi
clean "$D"

echo "── pure-anchor link (#heading, same file) is skipped ──"
D=$(mk)
( cd "$D" && printf 'jump [top](#heading).\n' > docs/a.md )
rc=$(cd "$D" && bash scripts/check-integrity.sh >/dev/null 2>&1; echo $?)
ok "$rc" 0 "pure-anchor link skipped"
clean "$D"

echo ""
echo "check-integrity: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
