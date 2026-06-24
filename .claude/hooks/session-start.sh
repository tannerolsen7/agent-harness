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
unset _INPUT _MODEL

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
  # Rebase conflicting open PRs. Gated here so only repos that opted into
  # automated maintenance (by creating .gc-enabled) trigger the sync.
  ( cd "$_GC_DIR" && bash scripts/sync-open-prs.sh ) || true
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
  unset _BEHIND _AHEAD
fi

# Prevents one-off edits from landing directly on main when /feature is skipped.
if [ -n "$_SESSION_ID" ] \
   && [ ! -f "$_REPO/.git" ] \
   && { [ "${_BRANCH:-}" = "main" ] || [ "${_BRANCH:-}" = "master" ]; }; then
  _SESSION_BRANCH="session/${_SESSION_ID}"
  _SESSION_WT="$_REPO/.claude/worktrees/${_SESSION_ID}"
  mkdir -p "$_REPO/.claude/worktrees" 2>/dev/null || true
  if [ ! -f "$_SESSION_WT/.git" ]; then
    if git -C "$_REPO" worktree add -b "$_SESSION_BRANCH" "$_SESSION_WT" HEAD 2>/dev/null; then
      printf '%s\n' "$_SESSION_WT" > "/tmp/claude-session-wt-${_SESSION_ID}" || true
      echo "=== Session worktree: $_SESSION_WT ==="
      echo "Work in this directory — changes stay on branch '$_SESSION_BRANCH' until you merge."
    fi
  fi
  unset _SESSION_BRANCH _SESSION_WT
fi
unset _REPO _BRANCH _SESSION_ID


if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

npm install
