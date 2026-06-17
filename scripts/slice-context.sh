#!/usr/bin/env bash
# Context slicer. Turns a source file into a compact outline so a specialist agent
# gets the signatures relevant to its task instead of the whole file.
#
# What it keeps: the lines that declare functions, classes, types, interfaces, and
# exports, plus structural headers (markdown headings, comment-style section banners)
# that show where each declaration lives. What it drops: function bodies and other
# detail an agent does not need to understand what the file offers.
#
# Why slice at all (BUILD-PLAN.md lines 82-83; ROUND-4 R4 token-efficiency audit,
# lines 556 and 661): comprehensive, already-inferable context degrades model output
# and raises cost. Feeding RELEVANT slices — not dump-everything — is the fix.
#
# Usage:
#   bash scripts/slice-context.sh <file>        # prints the slice to stdout
#   bash scripts/slice-context.sh --full <file> # prints the whole file (no slicing)
#
# Exit codes: 0 on success, non-zero if no path is given or the file is missing.
# The slicer fails loud — it never prints an empty or partial slice as a real result.
set -euo pipefail

FULL=0
FILE=""
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --) ;;
    *) FILE="$arg" ;;
  esac
done

if [ -z "$FILE" ]; then
  echo "slice-context: no file given. Usage: slice-context.sh [--full] <file>" >&2
  exit 2
fi

if [ ! -f "$FILE" ]; then
  echo "slice-context: file not found: $FILE" >&2
  exit 1
fi

# --full bypasses slicing: print the file unchanged. Used when an agent explicitly
# needs the body, or as the safe fallback for a file type we have no rules for.
if [ "$FULL" -eq 1 ]; then
  cat "$FILE"
  exit 0
fi

# Pick the slicing rules by file extension. Unknown types fall back to the whole
# file — a safe fallback never hides code from the agent.
case "$FILE" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs) KIND="js" ;;
  *.py)                              KIND="py" ;;
  *.sh|*.bash)                       KIND="sh" ;;
  *.md|*.mdx)                        KIND="md" ;;
  *)                                 KIND="full" ;;
esac

if [ "$KIND" = "full" ]; then
  cat "$FILE"
  exit 0
fi

# Each KIND prints only the declaration and header lines. Trailing structure (a lone
# closing brace) is dropped — the agent infers scope from the kept declaration lines.
awk -v kind="$KIND" '
  function trim(s) { gsub(/^[[:space:]]+/, "", s); return s }

  {
    t = trim($0)

    # Markdown headings anchor where declarations live.
    if (t ~ /^#+[[:space:]]/) { print; next }

    # Comment-style section banners (a comment line that is mostly punctuation,
    # e.g. "# ── Helpers ──" or "// ===== Public API =====").
    if (t ~ /^(#|\/\/)[[:space:]]*[-=*_]{2,}/) { print; next }

    if (kind == "md") { next }

    if (kind == "js") {
      if (t ~ /^export[[:space:]]/) { print; next }
      if (t ~ /^(async[[:space:]]+)?function[[:space:]]/) { print; next }
      if (t ~ /^(public|private|protected|static|abstract)?[[:space:]]*(class|interface|enum)[[:space:]]/) { print; next }
      if (t ~ /^type[[:space:]]+[A-Za-z_$]/) { print; next }
      # Arrow-function const/let assigned a => (a function value).
      if (t ~ /^(export[[:space:]]+)?(const|let)[[:space:]].*=>/) { print; next }
      next
    }

    if (kind == "py") {
      if (t ~ /^(async[[:space:]]+)?def[[:space:]]/) { print; next }
      if (t ~ /^class[[:space:]]/) { print; next }
      next
    }

    if (kind == "sh") {
      # POSIX/ksh function forms: "name()" or "function name".
      if (t ~ /^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)/) { print; next }
      if (t ~ /^function[[:space:]]+[A-Za-z_]/) { print; next }
      next
    }
  }
' "$FILE"
