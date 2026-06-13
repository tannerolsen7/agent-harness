#!/bin/sh
# Create a git worktree, provision its env files, and assert the gate machinery is
# live (worktree G1 — fail-closed). Usage: scripts/worktree-add.sh <path> <branch>
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

# Reject a branch name git would read as a flag (e.g. "-f", "--detach").
case "$BRANCH" in -*) echo "worktree-add: refusing unsafe branch name '$BRANCH'" >&2; exit 1 ;; esac

# Create the branch if it doesn't exist yet (so a NEW feat/<slug> works — this is how /queue
# starts each task), otherwise check out the existing branch into the worktree. Pin the new
# branch to an explicit commit-ish so it doesn't silently start from whatever HEAD the *calling*
# worktree happens to be on (run from the main worktree → branches off the current main HEAD).
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add "$WORKTREE_PATH" "$BRANCH"
else
  git worktree add -b "$BRANCH" "$WORKTREE_PATH" HEAD
fi

# --- env provisioning (adapter) ---
if [ "${UNATTENDED:-}" = "1" ] && [ -x "$REPO_ROOT/scripts/gen-local-env.sh" ]; then
  "$REPO_ROOT/scripts/gen-local-env.sh" "$WORKTREE_PATH" || {
    echo "UNATTENDED=1: local stack unavailable — removing uncredentialed worktree. Start your project's local stack first." >&2
    git worktree remove --force "$WORKTREE_PATH"
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

# --- G1: the gate machinery must be live in the new worktree, or refuse it ---
if [ -f "$WORKTREE_PATH/package.json" ] && [ -d "$WORKTREE_PATH/.husky" ]; then
  ( cd "$WORKTREE_PATH" && npm install ) || {
    echo "worktree-add: npm install failed — gates not provable; removing worktree (fail-closed)." >&2
    git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
    exit 1
  }
  "$REPO_ROOT/scripts/assert-husky-shim.sh" "$WORKTREE_PATH" || {
    echo "worktree-add: gate shim missing after install; removing worktree (fail-closed)." >&2
    git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
    exit 1
  }
  echo "Gates live in $WORKTREE_PATH."
fi
