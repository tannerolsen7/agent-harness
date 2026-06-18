#!/usr/bin/env bash
# Every UI component must handle all 6 data states.
#
# The rule: a component that renders live data will eventually be shown to a
# user while that data is empty, loading, errored, absent, sparse, or large.
# If the component only handles the "happy path" (some data), the other states
# produce broken, blank, or crashed UI. This lint rule catches components that
# are missing one or more required states before they ship.
#
# The 6 required states:
#   1. empty       — the data source exists but has zero records
#   2. loading     — data is being fetched (show a spinner, skeleton, etc.)
#   3. error       — the fetch failed (show an error message)
#   4. no-data     — the data source returned null/undefined (not the same as empty)
#   5. some-data   — the normal case: a small set of records
#   6. lots-of-data — a large set of records (pagination, truncation, scroll)
#
# How detection works:
#   A file is considered a UI component if it contains JSX (the pattern "return ("
#   followed by JSX, or the pattern "<Component" or "React.createElement"). The
#   script then looks for keyword signals for each state. A state is "handled" if
#   at least one matching keyword appears anywhere in the file.
#
# Signal keywords per state:
#   empty:         "empty", "isEmpty", "length === 0", ".length == 0", "count === 0"
#   loading:       "loading", "isLoading", "isFetching", "skeleton", "spinner", "Spinner", "Skeleton"
#   error:         "error", "isError", "hasError", "catch", "onError", "ErrorBoundary"
#   no-data:       "null", "undefined", "!data", "data == null", "data === null", "noData", "no-data"
#   some-data:     always assumed present — if the file renders anything it handles some data
#   lots-of-data:  "paginate", "pagination", "Pagination", "page", "perPage", "limit",
#                  "truncate", "overflow", "scroll", "virtualize", "virtual", "infinite"
#
# A file that has fewer than 3 of the 5 detectable signals (empty, loading, error,
# no-data, lots-of-data) is flagged. The threshold is 3 because:
#   - some-data is always assumed
#   - small purely-presentational components (e.g. a Button) are not data components
#   - 3/5 signals prevents false positives on simple components while still
#     catching components that skip important states
#
# Exemptions: test files, story files (*.stories.*), generated files,
# and non-component files (no JSX detected).
#
# Usage:
#   bash scripts/data-state-lint.sh           # checks staged files only
#   bash scripts/data-state-lint.sh --all     # checks all tracked files
#   bash scripts/data-state-lint.sh --files "a.tsx b.tsx"
#   bash scripts/data-state-lint.sh --threshold 4  # require 4/5 signals (stricter)

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

MODE="staged"
EXPLICIT_FILES=""
THRESHOLD=3

while [ $# -gt 0 ]; do
  case "$1" in
    --all)       MODE="all" ;;
    --files)     shift; EXPLICIT_FILES="$1" ;;
    --threshold) shift; THRESHOLD="$1" ;;
    *)           echo "data-state-lint: unknown arg '$1'" >&2; exit 1 ;;
  esac
  shift
done

# ── Collect files to check ────────────────────────────────────────────────────

files=""

if [ -n "$EXPLICIT_FILES" ]; then
  files="$EXPLICIT_FILES"
elif [ "$MODE" = "staged" ]; then
  while IFS= read -r f; do
    [ -f "$ROOT/$f" ] && files="$files $ROOT/$f"
  done < <(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)
else
  while IFS= read -r f; do
    [ -f "$ROOT/$f" ] && files="$files $ROOT/$f"
  done < <(git ls-files 2>/dev/null)
fi

# ── File type filter ──────────────────────────────────────────────────────────
# Only check files that can contain JSX/TSX UI components.

is_ui_candidate() {
  local f="$1"
  case "$f" in
    *.stories.*|*.story.*)  return 1 ;;  # skip Storybook stories
    *.test.*|*.spec.*)       return 1 ;;  # skip test files
    *__tests__*)              return 1 ;;
    *.generated.*|*.gen.*)   return 1 ;;
    *node_modules*)           return 1 ;;
    */worktrees/*)            return 1 ;;
    *.tsx|*.jsx)              return 0 ;;  # JSX/TSX: always candidates
    *.ts|*.js|*.mjs)          return 0 ;;  # could have React.createElement
    *)                        return 1 ;;
  esac
}

# ── JSX detection ─────────────────────────────────────────────────────────────
# A file is a UI component if it contains JSX. We detect JSX by looking for:
#   - return ( followed by < (the common React return pattern)
#   - React.createElement (the older API)
#   - A JSX tag on its own line, either a capital-letter component or an HTML element
#
# We match both <Component and <div/<ul/<span etc. so that components that only
# use plain HTML elements (no custom components) are still detected.

is_ui_component() {
  local f="$1"
  grep -qE '(return\s*\(?\s*<|React\.createElement|<[A-Za-z][A-Za-z0-9]*[\s/>])' "$f" 2>/dev/null
}

# ── Signal detection ──────────────────────────────────────────────────────────
# Each function prints "1" if the signal is present, "0" otherwise.

has_signal() {
  local f="$1" pattern="$2"
  grep -qE "$pattern" "$f" 2>/dev/null && printf '1' || printf '0'
}

check_empty()        { has_signal "$1" '(empty|isEmpty|\.length\s*===?\s*0|count\s*===?\s*0|noItems|no.items)'; }
check_loading()      { has_signal "$1" '(loading|isLoading|isFetching|[Ss]keleton|[Ss]pinner)'; }
check_error()        { has_signal "$1" '(error|isError|hasError|\bcatch\b|onError|ErrorBoundary)'; }
check_no_data()      { has_signal "$1" '(!data\b|data\s*===?\s*null|data\s*===?\s*undefined|noData|no.data|notFound)'; }
check_lots_of_data() { has_signal "$1" '(paginat|Paginat|perPage|per_page|\blimit\b|truncate|overflow.*scroll|scroll|virtuali[sz]|[Ii]nfinite[Ss]croll)'; }

fail=0
count=0
violations=0

for f in $files; do
  [ -f "$f" ] || continue
  is_ui_candidate "$f" || continue
  is_ui_component "$f" || continue
  count=$((count + 1))

  e=$(check_empty "$f")
  l=$(check_loading "$f")
  r=$(check_error "$f")
  n=$(check_no_data "$f")
  d=$(check_lots_of_data "$f")

  score=$((e + l + r + n + d))

  if [ "$score" -lt "$THRESHOLD" ]; then
    rel="${f#"$ROOT/"}"
    missing=""
    [ "$e" = "0" ] && missing="${missing} empty"
    [ "$l" = "0" ] && missing="${missing} loading"
    [ "$r" = "0" ] && missing="${missing} error"
    [ "$n" = "0" ] && missing="${missing} no-data"
    [ "$d" = "0" ] && missing="${missing} lots-of-data"
    printf 'data-state-lint: %s: missing states [%s] (%d/%d signals found)\n' \
      "$rel" "$missing" "$score" 5 >&2
    violations=$((violations + 1))
    fail=1
  fi
done

if [ "$fail" = 0 ]; then
  echo "data-state-lint: OK ($count UI components checked, 0 violations)"
else
  printf '\ndata-state-lint: %d component(s) missing required data states\n' "$violations" >&2
  printf 'Every UI component must handle: empty, loading, error, no-data, some-data, lots-of-data\n' >&2
  printf 'See docs/TESTING.md for examples of each state.\n' >&2
fi

exit "$fail"
