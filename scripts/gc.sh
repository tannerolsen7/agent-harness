#!/bin/bash
# scripts/gc.sh — clean up stale (merged) branches and orphaned worktrees.
# Only removes things that are definitively done:
#   - branches whose remote was deleted (GitHub auto-deletes on PR merge)
#   - worktree registrations whose directory no longer exists
# WIP branches (remote still exists) and active worktrees are never touched.
# Run weekly via .claude/rituals.md → stale-branch-audit.
set -e

echo "=== gc: cleaning up stale branches and worktrees ==="

# Remove tracking refs for branches deleted on the remote.
# GitHub deletes the remote branch when a PR is merged (delete_branch_on_merge=true).
echo "Fetching and pruning remote refs..."
git fetch --prune

# Remove worktree registrations for directories that no longer exist.
echo "Pruning stale worktree entries..."
git worktree prune

# Delete local branches whose remote tracking branch is gone ([gone] in git branch -vv).
# A branch only shows [gone] after its remote was deleted — WIP branches with live
# remotes are never matched here.
GONE=$(git branch -vv | awk '/: gone\]/{print $1}' | grep -v '^\*$' || true)
if [ -n "$GONE" ]; then
  echo "Cleaning up local branches with deleted remotes:"
  while IFS= read -r b; do
    if git branch -d "$b" 2>/dev/null; then
      echo "  deleted: $b"
    elif command -v gh &>/dev/null; then
      # -d refused (squash-merged branches have different SHAs). Verify via GitHub
      # that the PR is actually merged before force-deleting.
      # Assumes branch names are not reused after a squash-merge — safe for this repo's naming conventions.
      MERGED=$(gh pr list --head "$b" --state merged --json number -q '.[0].number' 2>/dev/null || true)
      if [ -n "$MERGED" ]; then
        # [gone] means the remote-tracking ref was pruned (squash-merge), not a proven
        # ancestor merge — so -D is required. Print the SHA first so the force-delete is
        # recoverable via: git branch <name> <sha>.
        SHA=$(git rev-parse --short "$b" 2>/dev/null || echo "unknown")
        git branch --delete --force "$b"
        echo "  deleted: $b (squash-merged, PR #$MERGED confirmed; was at $SHA — recover: git branch $b $SHA)"
      else
        echo "  skipped: $b (no merged PR found — delete manually if safe: git branch -D $b)"
      fi
    else
      echo "  skipped: $b (gh unavailable, cannot confirm merged — delete manually: git branch -D $b)"
    fi
  done <<< "$GONE"
else
  echo "No stale branches found."
fi

echo "=== Done ==="
