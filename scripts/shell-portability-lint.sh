#!/usr/bin/env bash
# portability-lint: skip-file — this script contains the patterns as grep targets and error messages.
# Checks .sh files for three patterns that fail on BSD/macOS or bash 3.2.
# Usage: bash scripts/shell-portability-lint.sh <file1.sh> [file2.sh ...]
# Exit 0 = no violations. Exit 1 = violations found, details on stderr.
set -euo pipefail

found=0

for f in "$@"; do
  [ -f "$f" ] || continue
  # Skip files with a file-level disable pragma in the first 5 lines.
  if head -5 "$f" 2>/dev/null | grep -qF '# portability-lint: skip-file'; then
    continue
  fi
  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    # Skip comment lines (first non-whitespace char is #).
    # Skip lines with an inline skip pragma — these contain the patterns as
    # analysis targets or test data, not as actual shell code.
    if printf '%s' "$line" | grep -qE '^\s*#'; then
      continue
    fi
    if printf '%s' "$line" | grep -qF '# portability-lint: skip'; then
      continue
    fi
    # mktemp -p is not supported on BSD/macOS.
    if printf '%s' "$line" | grep -qE '\bmktemp\b[[:space:]].*-p\b'; then
      printf "%s:%d: mktemp -p is not supported on BSD/macOS.\n" "$f" "$lineno" >&2
      printf "  Use: mktemp \"DIR/file.XXXXXX\" instead of mktemp -p DIR\n" >&2
      found=1
    fi
    # printf with a leading-dash format string fails silently in bash 3.2.
    # Match: printf '- or printf "- without printf -- on the same line.
    if printf '%s' "$line" | grep -qE "printf[[:space:]]+['\"][-]" && \
       ! printf '%s' "$line" | grep -qE "printf[[:space:]]*--"; then
      printf "%s:%d: printf with leading dash — add -- before the format string.\n" "$f" "$lineno" >&2
      printf "  Use: printf -- '- ...' to prevent bash 3.2 treating '-' as an option flag.\n" >&2
      found=1
    fi
    # git worktree list --porcelain outputs absolute paths; grep on relative
    # paths always misses. Use [ -f "\$path/.git" ] to check worktree existence.
    if printf '%s' "$line" | grep -qE 'git worktree list --porcelain.*\|.*grep'; then
      printf "%s:%d: use [ -f \"\$path/.git\" ] to check worktree existence.\n" "$f" "$lineno" >&2
      printf "  git worktree list --porcelain outputs absolute paths; grep on relative paths misses them.\n" >&2
      found=1
    fi
  done < "$f"
done

exit $found
