#!/bin/bash
set -euo pipefail

INPUT=$(cat)

# stop_hook_active is a JSON field on stdin, not an env var.
# If Claude re-entered after a stop, skip to avoid looping.
if printf '%s' "$INPUT" | jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
  exit 0
fi

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJ"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "(no commits)")
PR_URL=$(gh pr view --json url -q .url 2>/dev/null || echo "")
WORKTREES=$(git worktree list 2>/dev/null | tail -n +2 || echo "")
QUESTIONS=""
if [ -f ".claude/questions.md" ]; then
  # grep -c exits 1 on zero matches; the || 0 is required, not cosmetic.
  BLOCKING=$(grep -c "^\*\*Type:\*\* BLOCKING" .claude/questions.md 2>/dev/null || echo "0")
  if [ "$BLOCKING" -gt 0 ]; then
    QUESTIONS="$BLOCKING blocking question(s) in .claude/questions.md"
  fi
fi

printf '\n'
printf '## Handoff — %s\n' "$BRANCH"
printf '\n'

printf '### Done\n'
printf '%s\n' "$RECENT_COMMITS" | while IFS= read -r line; do
  printf '%s\n' "- $line"
done
printf '\n'

printf '### In-flight\n'
if [ -n "$QUESTIONS" ]; then
  printf '%s\n' "- $QUESTIONS"
fi
DIRTY=$(git status --short 2>/dev/null || true)
if [ -n "$DIRTY" ]; then
  printf '%s\n' "- Uncommitted changes on $BRANCH"
fi
if [ -z "$QUESTIONS" ] && [ -z "$DIRTY" ]; then
  printf '%s\n' "- (none)"
fi
printf '\n'

printf '### Continue from here\n'
printf '```bash\n'
printf 'cd %s\n' "$PROJ"
if [ -n "$PR_URL" ]; then
  printf '%s\n' "# PR: $PR_URL"
fi
if [ -n "$WORKTREES" ]; then
  printf '%s\n' "# Live worktrees:"
  printf '%s\n' "$WORKTREES" | while IFS= read -r line; do
    printf '%s\n' "#   $line"
  done
fi
printf 'git status\n'
printf '```\n'
printf '\n'
