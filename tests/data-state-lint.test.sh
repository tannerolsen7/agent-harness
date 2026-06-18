#!/usr/bin/env bash
# Tests for scripts/data-state-lint.sh.
#
# Each case creates a temporary .tsx file that handles some or all of the
# 6 required data states, runs the linter against it, and asserts the exit code.
#
# GIT_DIR guard: unset inherited git env so any subshells are fully isolated.
# See PITFALLS.md — "Running tests from inside a worktree corrupts the real repo."
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_OBJECT GIT_NAMESPACE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/data-state-lint.sh"
[ -f "$SCRIPT" ] || { echo "data-state-lint.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0
TMPFILE=""

ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

hasout() {
  if printf '%s' "$1" | grep -qi "$2"; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): output missing '$2'"
    fail=$((fail+1))
  fi
}

# Write component content to a temp file and run the linter.
# Sets OUT (combined stdout+stderr) and RC (exit code).
OUT=""
RC=0
run_tsx() {
  local content="$1"
  TMPFILE=$(mktemp /tmp/data-state-lint-test-XXXXXX.tsx)
  printf '%s\n' "$content" > "$TMPFILE"
  OUT=$(bash "$SCRIPT" "$TMPFILE" 2>&1) && RC=0 || RC=$?
  rm -f "$TMPFILE"
}

# ---------------------------------------------------------------------------
# A fully-compliant component — handles all 6 states.
# ---------------------------------------------------------------------------
FULL_COMPONENT='
import React from "react";

export function UserList({ isLoading, isError, isEmpty, noResults, items }) {
  if (isLoading) return <Spinner />;
  if (isError) return <div className="error-state">Something went wrong.</div>;
  if (isEmpty) return <EmptyState message="No users yet." />;
  if (noResults) return <div>No results found.</div>;
  return (
    <div>
      {items.map(item => <div key={item.id}>{item.name}</div>)}
      <Pagination hasMore={hasMore} loadMore={loadMore} />
    </div>
  );
}
'

echo "── complete component (all 6 states) — must PASS ──"
run_tsx "$FULL_COMPONENT"
ok "$RC" 0 "complete component exits 0"

# ---------------------------------------------------------------------------
# Components missing each state one at a time.
# ---------------------------------------------------------------------------
echo "── missing empty state — must FAIL ──"
MISSING_EMPTY='
export function List({ isLoading, isError, noResults, items }) {
  if (isLoading) return <Spinner />;
  if (isError) return <div className="error-state">Failed</div>;
  if (noResults) return <div>No results found.</div>;
  return (
    <div>
      {items.map(item => <div key={item.id}>{item.name}</div>)}
      <Pagination hasMore={hasMore} loadMore={loadMore} />
    </div>
  );
}
'
run_tsx "$MISSING_EMPTY"
ok "$RC" 1 "missing empty: exits non-zero"
hasout "$OUT" "empty" "missing empty: names the state"

echo "── missing loading state — must FAIL ──"
MISSING_LOADING='
export function List({ isError, isEmpty, noResults, items }) {
  if (isError) return <div className="error-state">Failed</div>;
  if (isEmpty) return <EmptyState />;
  if (noResults) return <div>No results found.</div>;
  return (
    <div>
      {items.map(item => <div key={item.id}>{item.name}</div>)}
      <Pagination hasMore={hasMore} loadMore={loadMore} />
    </div>
  );
}
'
run_tsx "$MISSING_LOADING"
ok "$RC" 1 "missing loading: exits non-zero"
hasout "$OUT" "loading" "missing loading: names the state"

echo "── missing error state — must FAIL ──"
MISSING_ERROR='
export function List({ isLoading, isEmpty, noResults, items }) {
  if (isLoading) return <Spinner />;
  if (isEmpty) return <EmptyState />;
  if (noResults) return <div>No results found.</div>;
  return (
    <div>
      {items.map(item => <div key={item.id}>{item.name}</div>)}
      <Pagination hasMore={hasMore} loadMore={loadMore} />
    </div>
  );
}
'
run_tsx "$MISSING_ERROR"
ok "$RC" 1 "missing error: exits non-zero"
hasout "$OUT" "error" "missing error: names the state"

echo "── missing no-data state — must FAIL ──"
MISSING_NO_DATA='
export function List({ isLoading, isError, isEmpty, items }) {
  if (isLoading) return <Spinner />;
  if (isError) return <div className="error-state">Failed</div>;
  if (isEmpty) return <EmptyState />;
  return (
    <div>
      {items.map(item => <div key={item.id}>{item.name}</div>)}
      <Pagination hasMore={hasMore} loadMore={loadMore} />
    </div>
  );
}
'
run_tsx "$MISSING_NO_DATA"
ok "$RC" 1 "missing no-data: exits non-zero"
hasout "$OUT" "no-data" "missing no-data: names the state"

echo "── missing some-data state — must FAIL ──"
MISSING_SOME_DATA='
export function List({ isLoading, isError, isEmpty, noResults }) {
  if (isLoading) return <Spinner />;
  if (isError) return <div className="error-state">Failed</div>;
  if (isEmpty) return <EmptyState />;
  if (noResults) return <div>No results found.</div>;
  return <Pagination hasMore={hasMore} loadMore={loadMore} />;
}
'
run_tsx "$MISSING_SOME_DATA"
ok "$RC" 1 "missing some-data: exits non-zero"
hasout "$OUT" "some-data" "missing some-data: names the state"

echo "── missing lots-of-data state — must FAIL ──"
MISSING_LOTS='
export function List({ isLoading, isError, isEmpty, noResults, items }) {
  if (isLoading) return <Spinner />;
  if (isError) return <div className="error-state">Failed</div>;
  if (isEmpty) return <EmptyState />;
  if (noResults) return <div>No results found.</div>;
  return <div>{items.map(item => <div key={item.id}>{item.name}</div>)}</div>;
}
'
run_tsx "$MISSING_LOTS"
ok "$RC" 1 "missing lots-of-data: exits non-zero"
hasout "$OUT" "lots-of-data" "missing lots-of-data: names the state"

# ---------------------------------------------------------------------------
# A component missing ALL 6 states (bare skeleton).
# ---------------------------------------------------------------------------
echo "── bare skeleton (no state handling) — must FAIL and name all 6 missing states ──"
BARE='
export function BareList({ items }) {
  return <div>{items}</div>;
}
'
run_tsx "$BARE"
ok "$RC" 1 "bare skeleton: exits non-zero"
hasout "$OUT" "empty"        "bare: names empty"
hasout "$OUT" "loading"      "bare: names loading"
hasout "$OUT" "error"        "bare: names error"
hasout "$OUT" "no-data"      "bare: names no-data"
hasout "$OUT" "some-data"    "bare: names some-data"
hasout "$OUT" "lots-of-data" "bare: names lots-of-data"

# ---------------------------------------------------------------------------
# Explicit file passed as an arg is checked regardless of path/naming.
# ---------------------------------------------------------------------------
echo "── explicit file (non-component path) is still checked when passed as arg ──"
EXPLICIT_FULL='
export function MyWidget({ isLoading, isError, isEmpty, noResults, items }) {
  if (isLoading) return <Spinner />;
  if (isError) return <div className="error-state">Oops</div>;
  if (isEmpty) return <EmptyState />;
  if (noResults) return <div>No results found.</div>;
  return (
    <div>
      {items.map(i => <span key={i.id}>{i.name}</span>)}
      <Pagination hasMore={more} loadMore={fn} />
    </div>
  );
}
'
run_tsx "$EXPLICIT_FULL"
ok "$RC" 0 "explicit full component passes"

echo ""
echo "data-state-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
