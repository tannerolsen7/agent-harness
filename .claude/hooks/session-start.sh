#!/bin/bash
set -euo pipefail

# Read hook stdin first — it can only be consumed once.
_INPUT=$(cat)

# Write the session temp file. session-stop.sh reads it back to compute duration
# and capture the model name for the activity record.
_SESSION_ID=$(printf '%s' "$_INPUT" | jq -r '.session_id // ""')
_MODEL=$(printf '%s' "$_INPUT" | jq -r '.model // "unknown"')
if [ -n "$_SESSION_ID" ]; then
  printf '%s %s\n' "$(date +%s)" "$_MODEL" \
    > "/tmp/claude-activity-${_SESSION_ID}" 2>/dev/null || true
fi
unset _INPUT _SESSION_ID _MODEL

# Truncate the permission log so each session starts clean
HASH=$(echo "${CLAUDE_PROJECT_DIR:-/}" | md5 | cut -c1-8)
> "/tmp/claude-perm-log-${HASH}.jsonl" 2>/dev/null || true

# Auto-clean merged worktrees + branches at session start (best-effort).
# Gated behind .claude/.gc-enabled so installed repos don't auto-delete branches
# without the team opting in. The harness repo has this file; installed targets don't
# (install.sh does not copy it). A team can create it themselves to enable cleanup.
_GC_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if [ -f "$_GC_DIR/.claude/.gc-enabled" ]; then
  ( cd "$_GC_DIR" && bash scripts/prune-branches.sh ) || true
fi
unset _GC_DIR


# Report how far the current branch is behind main so the gap is visible
# before any feature work starts, not at PR time.
_REPO="${CLAUDE_PROJECT_DIR:-$(pwd)}"
_BRANCH=$(git -C "$_REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [ -n "$_BRANCH" ] && [ "$_BRANCH" != "HEAD" ]; then
  _BEHIND=$(git -C "$_REPO" rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
  _AHEAD=$(git -C "$_REPO" rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
  if [ "$_BEHIND" -gt 0 ]; then
    echo "=== Branch '$_BRANCH' is $_BEHIND commit(s) behind main (you are $_AHEAD ahead) ==="
    echo "Sync with main before starting new work."
  fi
fi
unset _REPO _BRANCH _BEHIND _AHEAD


if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

npm install
