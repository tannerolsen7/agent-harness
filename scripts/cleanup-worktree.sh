#!/usr/bin/env bash
# scripts/cleanup-worktree.sh — remove an agent worktree and branch after merge.
# Safe to call at any time: exits 0 without touching anything if branch is not yet merged.
# Usage: bash scripts/cleanup-worktree.sh [WORKTREE_PATH]
#   WORKTREE_PATH — optional; defaults to git rev-parse --show-toplevel from CWD.
# Note: squash-merge detection requires `gh` (GitHub CLI). Without it, squash-merged
# branches are treated as "not yet merged" and left for prune-branches.sh to handle.
set -e

# Resolve the target worktree path to an absolute path.
if [ -n "${1-}" ]; then
  case "$1" in
    /*) WORKTREE_PATH=$1 ;;
    *)
      # Normalize relative paths so ../traversals don't bypass the safety gate.
      if [ -d "$1" ]; then
        WORKTREE_PATH=$(cd "$1" && pwd)
      else
        WORKTREE_PATH=$(pwd)/$1
      fi
      ;;
  esac
else
  WORKTREE_PATH=$(git rev-parse --show-toplevel 2>/dev/null) || {
    printf 'error: cannot resolve worktree path from CWD — not inside a git repo\n' >&2
    exit 1
  }
fi

# Strip any trailing slash so git worktree remove matches its stored registration.
WORKTREE_PATH="${WORKTREE_PATH%/}"

# Safety gate: path must be under a .claude/worktrees/ directory.
# Prevents accidentally touching the main repo root or arbitrary paths.
case "$WORKTREE_PATH" in
  */.claude/worktrees/*)  ;;
  *)
    printf 'error: path is outside .claude/worktrees/ — refusing: %s\n' "$WORKTREE_PATH" >&2
    exit 1
    ;;
esac

# Safety gate: reject any path where .git is a directory.
# A linked worktree always has .git as a file (a pointer to the worktree registration).
if [ -d "$WORKTREE_PATH/.git" ]; then
  printf 'error: path has a .git directory — looks like a main repo root, refusing\n' >&2
  exit 1
fi

# If the directory is already gone, there is nothing to do.
[ -d "$WORKTREE_PATH" ] || exit 0

# Find the main repo root via the git common dir.
# We cannot use `git rev-parse --show-toplevel` here because inside a linked worktree
# it returns the worktree path, not the main repo root. `git-common-dir` returns the
# main .git directory's absolute path, whose parent is the main repo root.
# We also need the main repo root to run git worktree remove — git refuses to remove
# the current worktree when CWD is inside it.
COMMON_DIR=$(git -C "$WORKTREE_PATH" rev-parse --git-common-dir 2>/dev/null) || {
  printf 'error: cannot find git common dir for %s\n' "$WORKTREE_PATH" >&2
  exit 1
}
case "$COMMON_DIR" in
  /*) REPO_ROOT=$(dirname "$COMMON_DIR") ;;
  *)
    printf 'error: unexpected relative git-common-dir: %s\n' "$COMMON_DIR" >&2
    exit 1
    ;;
esac

# Derive the branch name from the worktree.
BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ]; then
  # Detached HEAD or unresolvable — cannot determine which branch to delete. Exit safely.
  exit 0
fi

BRANCH_TIP=$(git -C "$WORKTREE_PATH" rev-parse HEAD 2>/dev/null || true)
MAIN_TIP=$(git -C "$REPO_ROOT" rev-parse origin/main 2>/dev/null || true)

# Merge check: is the branch already merged into origin/main?
# Must compare against origin/main, NOT HEAD. Inside a linked worktree, HEAD points to
# the feature branch itself — comparing against it always returns true, which would
# silently delete every branch that calls this script.
#
# Guard: BRANCH_TIP != MAIN_TIP protects the false-positive case from PITFALLS.md —
# a freshly-provisioned branch with no unique commits has its tip at origin/main's tip
# (or an older commit in origin/main's history), so the ancestor check returns true
# even though the branch was never merged. If the tips are equal, the branch is fresh;
# fall through to the gh check for confirmation.
MERGED=false
if [ -n "$BRANCH_TIP" ] && [ -n "$MAIN_TIP" ] && [ "$BRANCH_TIP" != "$MAIN_TIP" ] \
   && git -C "$REPO_ROOT" merge-base --is-ancestor "$BRANCH_TIP" origin/main 2>/dev/null; then
  MERGED=true
fi
if [ "$MERGED" != true ] && command -v gh >/dev/null 2>&1; then
  PR=$(gh pr list --head "$BRANCH" --state merged --json number -q '.[0].number' 2>/dev/null || true)
  if [ -n "$PR" ]; then MERGED=true; fi
fi

if [ "$MERGED" != true ]; then
  printf 'branch %s not yet merged — nothing done\n' "$BRANCH"
  exit 0
fi

# Print recovery hint before deleting anything.
SHA=$(git -C "$WORKTREE_PATH" rev-parse --short HEAD 2>/dev/null || echo "unknown")
printf 'recover: git branch %s %s\n' "$BRANCH" "$SHA"

# Remove the worktree from the main repo context.
# Using REPO_ROOT as CWD avoids the "cannot remove current worktree" error.
if (cd "$REPO_ROOT" && git worktree remove --force "$WORKTREE_PATH" 2>/dev/null); then
  printf 'removed worktree: %s\n' "$WORKTREE_PATH"
fi

# Delete the local branch. Force-delete is safe: merge is already confirmed above.
if (cd "$REPO_ROOT" && git branch --delete --force "$BRANCH" >/dev/null 2>&1); then
  printf 'deleted branch %s (was at %s)\n' "$BRANCH" "$SHA"
fi

exit 0
