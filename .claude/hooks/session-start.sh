#!/bin/bash
set -euo pipefail

# Truncate the permission log so each session starts clean
HASH=$(echo "${CLAUDE_PROJECT_DIR:-/}" | md5 | cut -c1-8)
> "/tmp/claude-perm-log-${HASH}.jsonl" 2>/dev/null || true

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

npm install
