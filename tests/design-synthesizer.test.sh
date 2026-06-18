#!/usr/bin/env bash
# design-synthesizer tests.
#
# Tests two behaviors:
#   1. N=1 passthrough: the validate script accepts a DESIGN.md that has all 6 sections.
#   2. Section requirement: the validate script rejects a DESIGN.md missing any required section.
#
# The design-synthesizer agent itself is interactive (it may ask questions for N>1 sources
# and calls an LLM). These tests cover the validate script that the agent and token-lint use
# as a pre-flight check, which is the mechanically testable part.
#
# GIT_DIR guard: running from inside a worktree would inherit GIT_DIR and cause any git commands
# in subshells to operate on the real repo. Unset them here.
# See PITFALLS.md — "Running tests from inside a worktree corrupts the real repo."
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
VALIDATE="$ROOT/scripts/design-system-validate.sh"
[ -f "$VALIDATE" ] || { echo "test: $VALIDATE not found"; exit 1; }

pass=0; fail=0
ok()  { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got '$1', want '$2'"; fail=$((fail+1)); fi; }
hasout() { if printf '%s' "$1" | grep -qi "$2"; then pass=$((pass+1)); else echo "  MISS ($3): output missing '$2'"; fail=$((fail+1)); fi; }

# Write a DESIGN.md with all 6 required sections to a temp file; print the path.
full_design() {
  f=$(mktemp)
  cat > "$f" <<'EOF'
# DESIGN.md

## Colors

- color-primary: #000000
- color-surface: #ffffff
- color-border: #e5e5e5
- color-error: #ef4444
- color-text-primary: #111111
- color-text-secondary: #6b7280

Neutral scale: 50 100 200 300 400 500 600 700 800 900.

## Typography

Primary font: Inter Variable. Code font: JetBrains Mono.

Type scale:
- display: 48px / 1.1 / 700 / -0.02em
- heading: 32px / 1.2 / 600 / -0.01em
- subheading: 24px / 1.3 / 600 / 0
- body: 16px / 1.6 / 400 / 0
- caption: 12px / 1.5 / 400 / 0.01em

## Spacing

Base unit: 4px.

Scale: space-1=4px space-2=8px space-3=12px space-4=16px space-6=24px space-8=32px space-12=48px.

Section gap: 80px. Component padding: card 24px, button 12px 20px, input 10px 14px.

## Components

Button (primary): background color-primary, color white, padding 12px 20px, radius 6px.
Button (secondary): border 1px color-border, color color-text-primary, same padding.
Button (ghost): no border, no background.
Input: border 1px color-border, radius 6px, padding 10px 14px.
Card: background color-surface, border 1px color-border, radius 8px, padding 24px.
Badge: background neutral-100, radius pill, padding 2px 8px.

## Shapes & elevation

Border radius: sharp 2px, default 6px, large 12px, pill 9999px.

Shadows: none (flat), sm (0 1px 2px rgba(0,0,0,0.05)), md (0 4px 6px rgba(0,0,0,0.07)).

## Philosophy & constraints

1. Design serves the product — no decoration for its own sake.
2. Never use gradients.
3. Never use more than one accent color.
4. All interactive states must be visually distinct.
5. Spacing follows the 4px grid — no arbitrary values.

Register: Product. This system values clarity and restraint.

## Agent Prompt Guide

Color: color-primary=#000000 color-surface=#ffffff color-border=#e5e5e5
Typography: body=16px/400 heading=32px/600 display=48px/700
Spacing: space-4=16px space-8=32px space-12=48px section-gap=80px
Personality: minimal, restrained, high-contrast. Prefer flat over decorated. Every element earns its place.
EOF
  echo "$f"
}

# Return the content of a DESIGN.md that is missing one section.
# $1 = the section keyword to omit (e.g. "Colors")
design_missing() {
  keyword="$1"
  f=$(mktemp)
  full=$(full_design)
  # Drop the section block (heading line and lines until the next ## heading).
  awk -v kw="$keyword" '
    /^## / && tolower($0) ~ tolower(kw) { skip=1; next }
    /^## / { skip=0 }
    !skip
  ' "$full" > "$f"
  rm -f "$full"
  echo "$f"
}

# ── 1. N=1 passthrough: full DESIGN.md with all 6 sections passes validate ──
echo "── N=1 passthrough: validate accepts a complete DESIGN.md ──"
F=$(full_design)
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
ok "$rc" 0 "full DESIGN.md exits 0"
hasout "$out" "OK" "reports OK"
rm -f "$F"

# ── 2. Missing Colors ──
echo "── missing Colors section: exits non-zero ──"
F=$(design_missing "Colors")
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: missing Colors should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Colors" "names the missing section"
rm -f "$F"

# ── 3. Missing Typography ──
echo "── missing Typography section: exits non-zero ──"
F=$(design_missing "Typography")
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: missing Typography should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Typography" "names the missing section"
rm -f "$F"

# ── 4. Missing Spacing ──
echo "── missing Spacing section: exits non-zero ──"
F=$(design_missing "Spacing")
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: missing Spacing should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Spacing" "names the missing section"
rm -f "$F"

# ── 5. Missing Components ──
echo "── missing Components section: exits non-zero ──"
F=$(design_missing "Components")
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: missing Components should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Components" "names the missing section"
rm -f "$F"

# ── 6. Missing Shapes & elevation ──
echo "── missing Shapes & elevation section: exits non-zero ──"
F=$(design_missing "Shapes")
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: missing Shapes should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Shapes" "names the missing section"
rm -f "$F"

# ── 7. Missing Philosophy & constraints ──
echo "── missing Philosophy & constraints section: exits non-zero ──"
F=$(design_missing "Philosophy")
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: missing Philosophy should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Philosophy" "names the missing section"
rm -f "$F"

# ── 8. Multiple missing sections: reports each one ──
echo "── multiple missing sections: reports each missing section name ──"
F=$(mktemp)
printf '# DESIGN.md\n\n## Colors\nsome colors\n' > "$F"
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: partial file should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Typography" "names missing Typography"
hasout "$out" "Spacing" "names missing Spacing"
hasout "$out" "Components" "names missing Components"
rm -f "$F"

# ── 9. File not found: exits non-zero with a helpful message ──
echo "── missing file: exits non-zero with error message ──"
out=$(bash "$VALIDATE" "/tmp/does-not-exist-$(date +%s).md" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: missing file should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "not found" "reports file not found"

# ── 10. No argument: exits non-zero with usage message ──
echo "── no argument: exits non-zero with usage message ──"
out=$(bash "$VALIDATE" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: no argument should exit non-zero"; fail=$((fail+1)); fi
hasout "$out" "Usage" "shows usage"

# ── 11. Agent Prompt Guide absent: warns but does not fail ──
echo "── Agent Prompt Guide missing: warns but still exits 0 if 6 sections present ──"
F=$(full_design)
# Remove the Agent Prompt Guide block.
tmp=$(mktemp)
awk '/^## Agent Prompt Guide/{skip=1;next} /^## /{skip=0} !skip' "$F" > "$tmp"
mv "$tmp" "$F"
out=$(bash "$VALIDATE" "$F" 2>&1); rc=$?
ok "$rc" 0 "missing Agent Prompt Guide is a warning, not a failure"
hasout "$out" "warning" "prints a warning about the missing guide"
rm -f "$F"

echo ""
echo "design-synthesizer: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
