#!/bin/bash
set -euo pipefail

# Truncate the permission log so each session starts clean
HASH=$(echo "${CLAUDE_PROJECT_DIR:-/}" | md5 | cut -c1-8)
> "/tmp/claude-perm-log-${HASH}.jsonl" 2>/dev/null || true

# Auto-clean merged worktrees + branches at session start (best-effort).
# Must sit BEFORE the remote-only early-exit below, or it never runs locally —
# which is where worktrees actually accumulate. gc.sh is safe: it only removes
# [gone], merge-verified branches and prints a recovery SHA for each.
( cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" && bash scripts/gc.sh ) || true

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

npm install
