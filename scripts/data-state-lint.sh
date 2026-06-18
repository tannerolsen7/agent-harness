#!/usr/bin/env bash
# Check that every UI component handles all 6 data states a component can be in.
#
# The 6 states are:
#   1. empty      — no items at all (e.g. an empty list, a fresh account)
#   2. loading    — data is being fetched
#   3. error      — the fetch or operation failed
#   4. no-data    — data exists but nothing matches the current filter/search
#   5. some-data  — a normal number of items fits on screen
#   6. lots-of-data — so many items that pagination, scrolling, or truncation matters
#
# A component that only handles "some data" will show a blank screen or crash in
# the other 5 states. This lint rule catches that before it reaches users.
#
# Usage:
#   bash scripts/data-state-lint.sh [files...]   # check specific component files
#   bash scripts/data-state-lint.sh              # check all component files
#
# A file is treated as a component if it lives in a component directory
# (components/, pages/, views/, screens/, features/) or has a component-style
# name (PascalCase.tsx / PascalCase.jsx).
#
# Each state must have at least one recognizable handler in the file.
# Exits non-zero when any required state handler is missing.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# ---------------------------------------------------------------------------
# State detection patterns.
#
# Each state is identified by a set of keywords that a reasonable component
# would use to handle that state. We look for ANY of the keywords (OR logic).
# The patterns are intentionally broad — they match variable names, JSX
# conditionals, CSS class names, and aria attributes.
# ---------------------------------------------------------------------------

# State 1: empty — the data set has zero items.
# Signals: isEmpty, length === 0, count === 0, items.length == 0, "empty" state/class,
# EmptyState component, <Empty>, no-items.
PATTERN_EMPTY="(isEmpty|\.length[[:space:]]*[=!]==?[[:space:]]*0|count[[:space:]]*[=!]==?[[:space:]]*0|empty[_-]?state|EmptyState|<Empty[[:space:]/>]|no[_-]?items|\"empty\"|'empty'|data-testid[^\"']*empty|aria-label[^\"']*empty)"

# State 2: loading — an async operation is in progress.
# Signals: isLoading, loading state/class, Spinner/Skeleton component, isFetching,
# isPending, status === "loading".
PATTERN_LOADING="(isLoading|is_loading|loading[_-]?state|<Spinner|<Skeleton|<Loading|isFetching|is_fetching|isPending|is_pending|\"loading\"|'loading'|status[[:space:]]*[=!]==?[[:space:]]*(\"loading\"|'loading')|data-testid[^\"']*loading)"

# State 3: error — the operation failed.
# Signals: isError, hasError, error state/class, ErrorBoundary, onError, catch block
# with UI output, status === "error".
PATTERN_ERROR="(isError|is_error|hasError|has_error|error[_-]?state|ErrorBoundary|onError|\"error\"|'error'|status[[:space:]]*[=!]==?[[:space:]]*(\"error\"|'error')|catch[[:space:]]*\(|data-testid[^\"']*error|aria-label[^\"']*error)"

# State 4: no-data — data loaded successfully but nothing matches the current view.
# Signals: no results, noResults, nothing found, zero matches. Distinct from "empty"
# (which means the data set itself is empty, not filtered).
PATTERN_NO_DATA="(noResults|no_results|no[_-]?results|nothingFound|nothing[_-]?found|zeroResults|zero[_-]?results|\"no results\"|'no results'|\"no data\"|'no data'|\"nothing found\"|'nothing found'|noMatches|no[_-]?matches)"

# State 5: some-data — the normal happy path. Nearly every component has this.
# Signals: map(, forEach, items.map, results.map, data.map, .map(item =>, list render.
PATTERN_SOME_DATA="(\.(map|forEach)[[:space:]]*\(|\.map\(item|items\.map|results\.map|data\.map|list\.map|rows\.map)"

# State 6: lots-of-data — so many items that layout or performance matters.
# Signals: pagination, virtualiz(e/ation), infinite scroll, page size, truncate,
# maxItems, limit param, hasMore, loadMore.
PATTERN_LOTS_OF_DATA="(pagination|Pagination|virtualiz|virtualis|infiniteScroll|infinite[_-]?scroll|hasMore|has_more|loadMore|load_more|load[_-]?more|pageSize|page_size|itemsPerPage|items_per_page|maxItems|max_items|truncat|\"Load more\"|'Load more'|<Paginator)"

# ---------------------------------------------------------------------------
# Determine which files to check.
# ---------------------------------------------------------------------------
is_component_file() {
  local f="$1"
  local base
  base=$(basename "$f")
  local dir
  dir=$(dirname "$f")

  # Explicit component directories
  case "$dir" in
    */components/*|*/pages/*|*/views/*|*/screens/*|*/features/*) return 0 ;;
    *components*|*pages*|*views*|*screens*|*features*) return 0 ;;
  esac

  # PascalCase filename with a component extension
  case "$base" in
    [A-Z]*.tsx|[A-Z]*.jsx) return 0 ;;
  esac

  return 1
}

if [ $# -gt 0 ]; then
  files="$*"
else
  files=""
  while IFS= read -r f; do
    if is_component_file "$f"; then
      files="$files $f"
    fi
  done < <(find . -type f \( -name '*.tsx' -o -name '*.jsx' \) \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    -not -path '*/worktrees/*' \
    2>/dev/null | sort)
fi

# ---------------------------------------------------------------------------
# Check each file for all 6 states.
# ---------------------------------------------------------------------------
check_state() {
  local file="$1"
  local label="$2"
  local pattern="$3"
  # grep -Ei is POSIX-compatible (extended regex, case-insensitive).
  # Works on both GNU grep (Linux/CI) and BSD grep (macOS).
  grep -qEi "$pattern" "$file" 2>/dev/null
}

fail=0
count=0

for f in $files; do
  [ -f "$f" ] || continue
  count=$((count + 1))
  missing=""

  check_state "$f" "empty"         "$PATTERN_EMPTY"         || missing="$missing empty"
  check_state "$f" "loading"       "$PATTERN_LOADING"       || missing="$missing loading"
  check_state "$f" "error"         "$PATTERN_ERROR"         || missing="$missing error"
  check_state "$f" "no-data"       "$PATTERN_NO_DATA"       || missing="$missing no-data"
  check_state "$f" "some-data"     "$PATTERN_SOME_DATA"     || missing="$missing some-data"
  check_state "$f" "lots-of-data"  "$PATTERN_LOTS_OF_DATA"  || missing="$missing lots-of-data"

  if [ -n "$missing" ]; then
    echo "data-state-lint: $f is missing handlers for:$missing" >&2
    fail=1
  fi
done

if [ "$count" -eq 0 ]; then
  echo "data-state-lint: no component files found — nothing to check."
  exit 0
fi

if [ "$fail" = 0 ]; then
  echo "data-state-lint: OK ($count component(s) checked — all 6 states handled)"
fi
exit "$fail"
