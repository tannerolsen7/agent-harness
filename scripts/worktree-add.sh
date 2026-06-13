#!/bin/sh
# Create a git worktree and provision its env files.
# Usage: scripts/worktree-add.sh <path> <branch>
#
# UNATTENDED=1 + a per-project local-env adapter (scripts/gen-local-env.sh):
#   write local/ephemeral backend credentials, fail-closed (no prod fallback).
#   Without the adapter there are no local creds to write — fall through to symlink.
# Default: symlink the repo-root env files into the worktree (human session).
#
# Project-agnostic: a project that needs no env files simply has none to symlink.
set -e

WORKTREE_PATH="${1:?Usage: scripts/worktree-add.sh <path> <branch>}"
BRANCH="${2:?Usage: scripts/worktree-add.sh <path> <branch>}"
REPO_ROOT=$(git rev-parse --show-toplevel)

git worktree add "$WORKTREE_PATH" "$BRANCH"

if [ "${UNATTENDED:-}" = "1" ] && [ -x "$REPO_ROOT/scripts/gen-local-env.sh" ]; then
  "$REPO_ROOT/scripts/gen-local-env.sh" "$WORKTREE_PATH" || {
    echo "UNATTENDED=1: local stack unavailable — removing uncredentialed worktree. Start your project's local stack first." >&2
    git worktree remove "$WORKTREE_PATH"
    exit 1
  }
else
  linked=0
  for envname in .env.local .env.test .env; do
    if [ -f "$REPO_ROOT/$envname" ] && [ ! -e "$WORKTREE_PATH/$envname" ]; then
      ln -sf "$REPO_ROOT/$envname" "$WORKTREE_PATH/$envname"
      echo "Symlinked $envname into $WORKTREE_PATH"
      linked=1
    fi
  done
  [ "$linked" = 0 ] && echo "No env files at repo root to symlink (fine if this project needs none)."
fi
