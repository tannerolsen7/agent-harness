#!/usr/bin/env bash
# feature skill must instruct agents to create a dedicated worktree before starting work.
# Without this, /feature runs in the main worktree and creates branches with no worktree.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SKILL="$ROOT/.claude/skills/feature/SKILL.md"

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

[ -f "$SKILL" ] || { echo "feature SKILL.md not found"; exit 1; }

# Extract content that appears before the first implementation tier heading.
# "## Tiny" is the first tier — setup instructions must appear before it.
before_tiny=$(awk '/^## Tiny/{exit} {print}' "$SKILL")

# 1. The setup steps must reference worktree-add.sh so agents know to create a worktree.
echo "$before_tiny" | grep -q "worktree-add.sh"
chk $? "feature skill must instruct agents to run worktree-add.sh before implementation tiers"

# 2. The worktree creation instruction must precede the implementation tiers, not only appear
#    in the cleanup-after-merge section (where it is already present but conditional).
total_refs=$(grep -c "worktree-add.sh" "$SKILL" || true)
cleanup_refs=$(awk '/^## Worktree cleanup/,0 {print}' "$SKILL" | grep -c "worktree-add.sh" || true)
setup_refs=$((total_refs - cleanup_refs))
[ "$setup_refs" -ge 1 ]
chk $? "worktree-add.sh must appear in setup steps, not only in the cleanup-after-merge section"

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" = 0 ]
