#!/usr/bin/env bash
# Run the harness's own tests. Tests are shell scripts under tests/ named *.test.sh;
# each exits non-zero on failure. With no tests present this passes cleanly — the
# harness ships behavior tests per build phase (e.g. the bug-catch test, the
# block-dangerous-bash test matrix), not all at once.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# Hermetic git env for the tests. When `npm test` runs inside a git hook (the pre-push gate runs it),
# git exports GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE / etc. Tests that spin up throwaway repos
# (mktemp + git init) would inherit those and operate on THIS repo instead of their temp one —
# passing under a direct `npm test` but failing inside the push hook. Clear them so every test
# discovers git from its own CWD. (ROOT is already resolved above using the ambient env.)
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE

tests=""
while IFS= read -r t; do tests="$tests $t"; done < <(find tests -type f -name '*.test.sh' 2>/dev/null | sort)

if [ -z "${tests// /}" ]; then
  echo "test: no tests yet (tests/*.test.sh) — passing."
  exit 0
fi

fail=0
for t in $tests; do
  [ -f "$t" ] || continue
  echo "── $t"
  if bash "$t"; then
    echo "  ok"
  else
    echo "  FAIL: $t" >&2
    fail=1
  fi
done
exit "$fail"
