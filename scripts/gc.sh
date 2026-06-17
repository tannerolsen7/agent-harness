#!/bin/bash
# scripts/gc.sh — clean up stale (merged) branches and orphaned worktrees.
# Only removes things that are definitively done:
#   - branches whose remote was deleted (GitHub auto-deletes on PR merge)
#   - branches that were never pushed (no upstream ref ever set), but are merged into main
#   - worktree registrations whose directory no longer exists
# WIP branches (remote still exists) and active worktrees are never touched.
# Runs automatically at session start (.claude/hooks/session-start.sh) and on demand;
# /queue also invokes it after a merge batch.
#
# Two detection passes feed one shared merge-verify loop:
#   Pass 1 — [gone] branches: remote was deleted; detected via git branch -vv after fetch --prune.
#   Pass 2 — no-upstream branches: never pushed (or pushed without --set-upstream), so [gone]
#             never fires even after merging. Detected via git for-each-ref %(upstream) == "".
# The merge-verify gate protects both: a branch is only deleted if it is a confirmed merge.
set -e

echo "=== gc: cleaning up stale branches and worktrees ==="

# Remove tracking refs for branches deleted on the remote.
# GitHub deletes the remote branch when a PR is merged (delete_branch_on_merge=true).
echo "Fetching and pruning remote refs..."
git fetch --prune

# Remove worktree registrations for directories that no longer exist.
echo "Pruning stale worktree entries..."
git worktree prune

# Pass 1: branches whose remote tracking ref is gone ([gone] after fetch --prune).
# git branch -vv marks the current branch "* " and a worktree-checked-out branch "+ ",
# so for those the name is $2, not $1. The [... : gone] match is anchored inside the
# tracking bracket so a commit subject containing the literal "gone]" can't false-trigger.
GONE=$(git branch -vv | awk '/\[[^]]*: gone\]/ && $1 != "*" { print ($1 == "+") ? $2 : $1 }' || true)

# Pass 2: local branches with no upstream tracking ref configured at all.
# These never get [gone] because git has no remote ref to mark absent.
# %(upstream) is empty when no upstream was ever set (git for-each-ref is safe to parse —
# no field-shift issues from the * and + decorators in git branch -vv).
CURRENT=$(git branch --show-current 2>/dev/null || true)
NO_UPSTREAM=$(git for-each-ref --format='%(refname:short) %(upstream)' refs/heads/ | \
  awk '$2 == "" { print $1 }' | grep -v "^${CURRENT}$" || true)

# Combine both passes. The merge-verify gate below protects both sets — a branch is only
# deleted if it is a confirmed merge (ancestor check or gh-confirmed merged PR).
CANDIDATES=$(printf '%s\n%s\n' "$GONE" "$NO_UPSTREAM" | sort -u | grep -v '^$' || true)

if [ -n "$CANDIDATES" ]; then
  echo "Cleaning up stale merged branches:"
  while IFS= read -r b; do
    # MERGE-VERIFY FIRST — before removing any worktree or branch. A [gone] remote is not a merge.
    # We can't use `git branch -d` as the probe (it refuses while the branch is checked out in a
    # worktree), so test merged-ness non-destructively: ancestor of where gc runs (normal merge),
    # or a gh-confirmed merged PR (squash-merge, which isn't an ancestor).
    MERGED=false
    if git merge-base --is-ancestor "$b" HEAD 2>/dev/null; then
      MERGED=true
    elif command -v gh >/dev/null 2>&1; then
      PR=$(gh pr list --head "$b" --state merged --json number -q '.[0].number' 2>/dev/null || true)
      [ -n "$PR" ] && MERGED=true
    fi
    if [ "$MERGED" != true ]; then
      echo "  skipped: $b (remote gone but NOT merged — your commits are safe; delete manually if sure: git branch -D $b)"
      continue
    fi

    # Merged → safe to clean. If it's checked out in one of our worktrees, remove that first
    # (git refuses to delete a checked-out branch). The awk reads the full path after "worktree "
    # so paths with spaces aren't truncated.
    WT=$(git worktree list --porcelain | awk -v br="refs/heads/$b" \
      '/^worktree /{ p=$0; sub(/^worktree /,"",p) } $0=="branch "br { print p }')
    if [ -n "$WT" ]; then
      case "$WT" in
        */.claude/worktrees/*)
          if git worktree remove --force "$WT" 2>/dev/null; then
            echo "  removed worktree: $WT (branch $b, merged)"
          else
            echo "  WARN: could not remove worktree $WT — remove it manually, then re-run gc" >&2
            continue   # leave the branch; deleting it would fail while still checked out
          fi ;;
        *)
          echo "  skipped worktree $WT (branch $b) — outside .claude/worktrees/, remove manually" >&2
          continue ;;
      esac
    fi
    # -D (force) is justified: merged-ness is already proven above. Print the SHA so it's recoverable.
    SHA=$(git rev-parse --short "$b" 2>/dev/null || echo "unknown")
    git branch --delete --force "$b" >/dev/null 2>&1 \
      && echo "  deleted: $b (merged; was at $SHA — recover: git branch $b $SHA)"
  done <<< "$CANDIDATES"
else
  echo "No stale branches found."
fi

echo "=== Done ==="
