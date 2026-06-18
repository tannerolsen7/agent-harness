#!/usr/bin/env bash
# Tests for scripts/data-state-lint.sh — every UI component must handle all 6 data states.
#
# Each case writes a small TSX file to a temp directory and runs the linter
# against it using --files. A component missing states must produce exit 1.
# A component that handles all states must produce exit 0.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LINT="$ROOT/scripts/data-state-lint.sh"

[ -f "$LINT" ] || { echo "data-state-lint.test: $LINT not found"; exit 1; }

pass=0; fail=0
ok() { pass=$((pass+1)); }
no() { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

# Write a temp TSX file with the given content, run linter, return exit code.
check() {
  local content="$1"
  local tmp
  tmp=$(mktemp "/tmp/ds_test_XXXXXX.tsx")
  printf '%s\n' "$content" > "$tmp"
  bash "$LINT" --files "$tmp" >/dev/null 2>&1
  local rc=$?
  rm -f "$tmp"
  return "$rc"
}

# ── Non-component files: should be skipped (exit 0) ──────────────────────────
# A TSX file with no JSX is not a UI component and should not be checked.

check 'export const helper = (x: number) => x + 1'
[ $? -eq 0 ] && ok || no "Non-component TSX (no JSX) should be skipped"

# ── Complete component: handles all 5 detectable states (exit 0) ─────────────

FULL_COMPONENT=$(cat <<'EOF'
import React from 'react'

export function UserList({ data, isLoading, error }: Props) {
  if (isLoading) return <Spinner />
  if (error) return <div>Error loading users</div>
  if (!data) return <div>No data available</div>
  if (data.length === 0) return <div>No users found</div>
  return (
    <div className="overflow-scroll">
      {data.slice(0, limit).map(u => <User key={u.id} user={u} />)}
      <Pagination page={page} perPage={perPage} />
    </div>
  )
}
EOF
)
check "$FULL_COMPONENT"
[ $? -eq 0 ] && ok || no "Full component handling all 6 states should pass"

# ── Happy-path only component: missing loading, error, empty, lots-of-data (exit 1) ──

HAPPY_ONLY=$(cat <<'EOF'
import React from 'react'

export function UserList({ data }: Props) {
  return (
    <ul>
      {data.map(u => <li key={u.id}>{u.name}</li>)}
    </ul>
  )
}
EOF
)
check "$HAPPY_ONLY"
[ $? -eq 1 ] && ok || no "Happy-path-only component should be flagged"

# ── Missing loading only: still has enough other signals (4/5 >= threshold 3) (exit 0) ──
# loading is missing but 4 other signals are present — this passes at threshold 3.

NO_LOADING=$(cat <<'EOF'
import React from 'react'

export function UserList({ data, error }: Props) {
  if (error) return <div>Error</div>
  if (!data) return <div>No data</div>
  if (data.length === 0) return <div>Empty</div>
  return (
    <div className="overflow-scroll">
      {data.slice(0, limit).map(u => <User key={u.id} />)}
      <Pagination />
    </div>
  )
}
EOF
)
check "$NO_LOADING"
[ $? -eq 0 ] && ok || no "Component missing only loading (4/5 signals) should pass at threshold 3"

# ── Threshold flag: same component fails at --threshold 5 ────────────────────
# When threshold is raised to 5, all 5 signals must be present.

tmp_no_loading=$(mktemp "/tmp/ds_test_XXXXXX.tsx")
printf '%s\n' "$NO_LOADING" > "$tmp_no_loading"
bash "$LINT" --files "$tmp_no_loading" --threshold 5 >/dev/null 2>&1
rc=$?
rm -f "$tmp_no_loading"
[ "$rc" -eq 1 ] && ok || no "Component with 4/5 signals should fail at --threshold 5"

# ── Storybook story file: should be skipped (exit 0) ─────────────────────────

STORY=$(mktemp "/tmp/ds_test_XXXXXX.stories.tsx")
printf '%s\n' "$HAPPY_ONLY" > "$STORY"
bash "$LINT" --files "$STORY" >/dev/null 2>&1
rc=$?
rm -f "$STORY"
[ "$rc" -eq 0 ] && ok || no "*.stories.tsx file should be skipped"

# ── Test file: should be skipped (exit 0) ────────────────────────────────────

TEST_FILE=$(mktemp "/tmp/ds_test_XXXXXX.test.tsx")
printf '%s\n' "$HAPPY_ONLY" > "$TEST_FILE"
bash "$LINT" --files "$TEST_FILE" >/dev/null 2>&1
rc=$?
rm -f "$TEST_FILE"
[ "$rc" -eq 0 ] && ok || no "*.test.tsx file should be skipped"

# ── Component with Skeleton instead of isLoading: still counts (exit 0) ──────

SKELETON_COMPONENT=$(cat <<'EOF'
import React from 'react'

export function UserList({ data, isFetching, error }: Props) {
  if (isFetching) return <Skeleton count={3} />
  if (isError) return <ErrorBoundary />
  if (data === null) return <div>Nothing here</div>
  if (data.length === 0) return <div>No results</div>
  return (
    <div className="virtualize">
      {data.map(u => <User key={u.id} />)}
    </div>
  )
}
EOF
)
check "$SKELETON_COMPONENT"
[ $? -eq 0 ] && ok || no "Component using Skeleton/isFetching/virtualize should pass"

# ── Plain JS file (not TSX): non-JSX file should be skipped ─────────────────

NON_UI=$(mktemp "/tmp/ds_test_XXXXXX.js")
printf '%s\n' "$HAPPY_ONLY" > "$NON_UI"
# No JSX tags present → should be skipped even though it is .js
printf '%s\n' 'module.exports = { helper: (x) => x + 1 }' > "$NON_UI"
bash "$LINT" --files "$NON_UI" >/dev/null 2>&1
rc=$?
rm -f "$NON_UI"
[ "$rc" -eq 0 ] && ok || no "Non-JSX JS file should be skipped"

# ── Component missing lots-of-data and loading (3/5 signals, just at threshold) ──

PARTIAL=$(cat <<'EOF'
import React from 'react'

export function UserList({ data, error }: Props) {
  if (error) return <div>Error</div>
  if (!data) return <div>No data</div>
  if (data.length === 0) return <div>Empty</div>
  return (
    <ul>
      {data.map(u => <User key={u.id} />)}
    </ul>
  )
}
EOF
)
check "$PARTIAL"
[ $? -eq 0 ] && ok || no "Component with exactly 3/5 signals should pass at default threshold"

# ── Component with only 2 signals: below threshold (exit 1) ──────────────────

SPARSE=$(cat <<'EOF'
import React from 'react'

export function UserList({ data, isLoading }: Props) {
  if (isLoading) return <Spinner />
  return (
    <ul>
      {data.map(u => <User key={u.id} />)}
    </ul>
  )
}
EOF
)
check "$SPARSE"
[ $? -eq 1 ] && ok || no "Component with only 2/5 signals should be flagged"

echo ""
echo "data-state-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
