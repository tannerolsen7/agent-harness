#!/usr/bin/env bash
# Worktree G1: assert-husky-shim.sh refuses a worktree whose committed hooks have no
# regenerated wrapper (gates would silently not run). Uses fabricated dir layouts —
# fast and offline (no real `git worktree add` / `npm install`).
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ASSERT="$ROOT/scripts/assert-husky-shim.sh"
[ -f "$ASSERT" ] || { echo "worktree-gates.test: $ASSERT not found"; exit 1; }

pass=0; fail=0
check() { # check <expect 0|1> <dir> <label>
  sh "$ASSERT" "$2" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$1" ]; then pass=$((pass+1)); else echo "  MISS ($3): want exit $1, got $rc"; fail=$((fail+1)); fi
}

TMP=$(mktemp -d)

# 1. husky project, committed pre-push, NO wrapper → fail-closed (exit 1)
d="$TMP/missing"; mkdir -p "$d/.husky/_"; echo '{}' > "$d/package.json"; echo '#!/bin/sh' > "$d/.husky/pre-push"
check 1 "$d" "committed hook without wrapper"

# 2. husky project, committed pre-push WITH wrapper → ok (exit 0)
d="$TMP/ok"; mkdir -p "$d/.husky/_"; echo '{}' > "$d/package.json"
echo '#!/bin/sh' > "$d/.husky/pre-push"; echo '#!/bin/sh' > "$d/.husky/_/pre-push"
check 0 "$d" "committed hook with wrapper"

# 3. no package.json → skip (exit 0)
d="$TMP/nonpm"; mkdir -p "$d/.husky"; echo '#!/bin/sh' > "$d/.husky/pre-push"
check 0 "$d" "no package.json"

# 4. npm project, no .husky → skip (exit 0)
d="$TMP/nohusky"; mkdir -p "$d"; echo '{}' > "$d/package.json"
check 0 "$d" "no .husky dir"

# 5. multiple committed hooks, one wrapper missing → fail-closed (exit 1)
d="$TMP/partial"; mkdir -p "$d/.husky/_"; echo '{}' > "$d/package.json"
echo '#!/bin/sh' > "$d/.husky/pre-commit"; echo '#!/bin/sh' > "$d/.husky/_/pre-commit"
echo '#!/bin/sh' > "$d/.husky/pre-push"   # no wrapper for pre-push
check 1 "$d" "one of several wrappers missing"

rm -rf "$TMP"

# Structural guard: both worktree creators must call the assert + fail-closed.
for f in scripts/worktree-add.sh .claude/hooks/worktree-create.sh; do
  if grep -q 'assert-husky-shim.sh' "$ROOT/$f"; then pass=$((pass+1)); else echo "  MISS: $f does not call assert-husky-shim.sh"; fail=$((fail+1)); fi
done

echo ""
echo "worktree-gates: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
