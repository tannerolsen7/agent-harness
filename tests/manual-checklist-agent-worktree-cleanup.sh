#!/usr/bin/env bash
# Manual checklist for scripts/cleanup-worktree.sh
# Run from inside .claude/worktrees/agent-worktree-cleanup/
# All checks should PASS before merging.

set -u
pass=0; fail=0
chk() { if "$@" 2>/dev/null; then echo "  PASS: $*"; pass=$((pass+1)); else echo "  FAIL: $*"; fail=$((fail+1)); fi; }

echo "=== Manual checklist: scripts/cleanup-worktree.sh ==="

# 1. Unit tests pass
echo ""
echo "-- Unit tests --"
chk bash tests/cleanup-worktree.test.sh

# 2. Script is executable
echo ""
echo "-- Permissions --"
chk [ -x scripts/cleanup-worktree.sh ]

# 3. Shell portability lint passes
echo ""
echo "-- Portability lint --"
REPO_ROOT=$(git rev-parse --show-toplevel)
chk bash "$REPO_ROOT/scripts/shell-portability-lint.sh" scripts/cleanup-worktree.sh tests/cleanup-worktree.test.sh

# 4. Spec file exists and is non-empty
echo ""
echo "-- Spec file --"
chk [ -s docs/testing/agent-worktree-cleanup.md ]

# 5. task-runner.md step 5 uses || true
echo ""
echo "-- task-runner.md || true --"
chk grep -q "cleanup-worktree.sh || true" .claude/agents/task-runner.md

echo ""
printf "%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" = 0 ]
