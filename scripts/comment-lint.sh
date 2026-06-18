#!/usr/bin/env bash
# Block comments that describe WHAT the code does. Only WHY comments are allowed.
#
# The rule: a comment that restates the code in plain English adds no value. It
# will drift from the code over time and mislead readers. A comment that explains
# WHY a decision was made — the tradeoff, the constraint, the context — helps
# readers who encounter the code months later.
#
# This script scans staged files (or all files when run with --all) and flags
# comment lines that match known WHAT patterns. It exits non-zero when violations
# are found, blocking the commit.
#
# What patterns are caught:
#   - "// Get the ..." / "// Set the ..." / "// Return ..."  (verb-first noun phrases)
#   - "// This function ..." / "// This method ..."
#   - "// Loop over ..." / "// Iterate over ..."
#   - "// Check if ..." / "// Check that ..."
#   - "// Call ..." (just describes the function call below)
#   - "# Get ", "# Set ", "# Return " etc. in shell/python files
#
# Exemptions: test files (*.test.*, *.spec.*), generated files, and lines that
# also contain "because", "so that", "in order to", "workaround", "NOTE:",
# "FIXME:", "TODO:", "HACK:" — those carry reasoning, not just description.
#
# Usage:
#   bash scripts/comment-lint.sh           # checks staged files only (pre-commit mode)
#   bash scripts/comment-lint.sh --all     # checks all tracked files
#   bash scripts/comment-lint.sh --files "a.ts b.ts"  # checks a specific list

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

MODE="staged"
EXPLICIT_FILES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --all)   MODE="all" ;;
    --files) shift; EXPLICIT_FILES="$1" ;;
    *)       echo "comment-lint: unknown arg '$1'" >&2; exit 1 ;;
  esac
  shift
done

# ── Collect files to check ────────────────────────────────────────────────────

files=""

if [ -n "$EXPLICIT_FILES" ]; then
  files="$EXPLICIT_FILES"
elif [ "$MODE" = "staged" ]; then
  # Only look at files that are actually staged for this commit.
  while IFS= read -r f; do
    [ -f "$ROOT/$f" ] && files="$files $ROOT/$f"
  done < <(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)
else
  # --all: every tracked file the repo knows about.
  while IFS= read -r f; do
    [ -f "$ROOT/$f" ] && files="$files $ROOT/$f"
  done < <(git ls-files 2>/dev/null)
fi

# ── Which file types carry inline comments we understand ─────────────────────
# We only check files where we can reliably identify comment syntax.
# Unrecognized file types are skipped — a false negative is safer than
# flagging code we cannot parse.

is_checkable() {
  local f="$1"
  case "$f" in
    *.test.*|*.spec.*)    return 1 ;;  # skip test files
    *__tests__*)           return 1 ;;
    *.generated.*|*.gen.*) return 1 ;;
    *node_modules*)        return 1 ;;
    */.husky/_/*)          return 1 ;;
    */worktrees/*)         return 1 ;;
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) return 0 ;;
    *.sh|*.bash|*.zsh)    return 0 ;;
    *.py)                  return 0 ;;
    *.go)                  return 0 ;;
    *.java|*.kt|*.swift|*.cs) return 0 ;;
    *.rb)                  return 0 ;;
    *)                     return 1 ;;
  esac
}

# ── Pattern matching ──────────────────────────────────────────────────────────
# A WHAT comment: starts with a comment marker, then describes what code does
# using a verb-first or "this function/method" phrase.
#
# WHY markers take priority: if the line contains reasoning language (because,
# so that, in order to, etc.) we leave it alone even if a WHAT verb also matches.

WHAT_PATTERNS='^\s*(//|#)\s*(Get |Set |Return |Loop over |Iterate over |Iterate through |Check if |Check that |Call |Create |Delete |Remove |Update |Add |Build |Parse |Convert |Format |Send |Fetch |Load |Save |Store |Find |Filter |Sort |Map |Wrap |Unwrap |Open |Close |Read |Write |Handle |Process |Render |Init |Initialize |Reset |Clear |Enable |Disable |Toggle |Compute |Calculate |Count |Emit |Fire |Trigger |Validate |Log |Print )'

THIS_PATTERNS='^\s*(//|#)\s*[Tt]his (function|method|class|component|hook|helper|util|module|script|file|block|loop|section|line|step|part|chunk) '

WHY_MARKERS='because|so that|in order to|workaround|NOTE:|FIXME:|TODO:|HACK:|reason:|rationale:|this is why|otherwise|avoid|prevent|ensure|guarantee|guard|fallback|legacy|compat'

fail=0
count=0
violations=0

for f in $files; do
  [ -f "$f" ] || continue
  is_checkable "$f" || continue
  count=$((count + 1))

  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    # Skip lines that do not start with a comment marker.
    printf '%s\n' "$line" | grep -qE '^\s*(//|#)' || continue

    # Skip lines that carry WHY reasoning markers.
    printf '%s\n' "$line" | grep -qiE "$WHY_MARKERS" && continue

    # Flag WHAT patterns.
    if printf '%s\n' "$line" | grep -qE "$WHAT_PATTERNS" ||
       printf '%s\n' "$line" | grep -qE "$THIS_PATTERNS"; then
      rel="${f#"$ROOT/"}"
      printf 'comment-lint: %s:%d: WHAT comment — describe WHY not WHAT\n' "$rel" "$lineno" >&2
      printf '  > %s\n' "$line" >&2
      violations=$((violations + 1))
      fail=1
    fi
  done < "$f"
done

if [ "$fail" = 0 ]; then
  echo "comment-lint: OK ($count files checked, 0 violations)"
else
  printf '\ncomment-lint: %d violation(s) across %d file(s) checked\n' "$violations" "$count" >&2
  printf 'Replace WHAT comments with WHY comments:\n' >&2
  printf '  BAD:  // Get the user from the database\n' >&2
  printf '  GOOD: // Fetch fresh data — the cache is bypassed on first login\n' >&2
fi

exit "$fail"
