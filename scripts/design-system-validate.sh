#!/usr/bin/env bash
# Validate that a DESIGN.md has all 6 required sections.
# Used by token-lint as a pre-flight check before any UI code is generated.
#
# Usage: bash scripts/design-system-validate.sh <path-to-DESIGN.md>
#
# The 6 required sections are (in any order):
#   1. Colors
#   2. Typography
#   3. Spacing
#   4. Components
#   5. Shapes & elevation
#   6. Philosophy & constraints
#
# The Agent Prompt Guide (section 7) is also required in the output produced by
# design-synthesizer, but this validator focuses on the 6 content sections that
# describe the design system itself. A missing Agent Prompt Guide is a warning,
# not an error, because normalization adds it automatically.
#
# Exit codes:
#   0 — all 6 sections present
#   1 — one or more sections missing (error message on stderr names each one)
set -euo pipefail

usage() {
  echo "Usage: bash $0 <path-to-DESIGN.md>" >&2
  exit 1
}

[ "${1:-}" = "" ] && usage
FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "design-system-validate: file not found: $FILE" >&2
  exit 1
fi

# Each entry is a pattern that matches the section heading. The pattern is
# case-insensitive and checks for a markdown heading (## or ###) followed by
# the section name. This is loose enough to match headings like "## Colors"
# or "### 1. Colors" without needing exact formatting.
SECTIONS=(
  "Colors"
  "Typography"
  "Spacing"
  "Components"
  "Shapes"
  "Philosophy"
)

# Human-readable names for error messages (parallel array, same order as SECTIONS).
SECTION_NAMES=(
  "Colors"
  "Typography"
  "Spacing"
  "Components"
  "Shapes & elevation"
  "Philosophy & constraints"
)

missing=0

for i in "${!SECTIONS[@]}"; do
  pattern="${SECTIONS[$i]}"
  name="${SECTION_NAMES[$i]}"
  # Match a markdown heading line that contains the section keyword.
  # grep -i for case-insensitivity; -E for the pattern.
  if ! grep -qiE "^#{1,6}[[:space:]].*${pattern}" "$FILE"; then
    echo "design-system-validate: missing required section: ${name}" >&2
    missing=$((missing + 1))
  fi
done

# Warn (but do not fail) if the Agent Prompt Guide is absent.
if ! grep -qiE "^#{1,6}[[:space:]].*Agent Prompt Guide" "$FILE"; then
  echo "design-system-validate: warning: Agent Prompt Guide section is missing (design-synthesizer will add it on next run)" >&2
fi

if [ "$missing" -ne 0 ]; then
  echo "design-system-validate: FAIL — $missing required section(s) missing from $FILE" >&2
  exit 1
fi

echo "design-system-validate: OK — all 6 required sections present in $FILE"
