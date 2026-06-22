#!/bin/bash
# scripts/prune-branches.sh — remove stale branches, worktrees, and remote refs.
# Only removes things that are definitively done:
#   - branches whose remote was deleted (GitHub auto-deletes on PR merge)
#   - branches that were never pushed (no upstream ref ever set), but are merged into main
#   - worktree registrations whose directory no longer exists
#   - orphaned directories under .claude/worktrees/ that lost their git registration
#   - remote agent/* and claude/* branches whose tip is merged into origin/main
# WIP branches (remote still exists) and active worktrees are never touched.
# Runs automatically at session start (.claude/hooks/session-start.sh) and on demand;
# /queue also invokes it after a merge batch.
#
# Detection passes:
#   Pass A — orphaned directories: .claude/worktrees/ subdirs with no .git file.
#   Pass B — remote agent/workflow branches: origin/agent/* and origin/claude/* with
#             no local branch, no active worktree, and tip already in origin/main.
#   Pass 1 — [gone] branches: remote was deleted; detected via git branch -vv after fetch --prune.
#   Pass 2 — no-upstream branches: never pushed (or pushed without --set-upstream), so [gone]
#             never fires even after merging. Detected via git for-each-ref %(upstream) == "".
# The merge-verify gate protects Passes 1 and 2: a branch is only deleted if it is a
# confirmed merge. Pass B has its own ancestor check. Pass A checks the .git file.
set -e

echo "=== prune-branches: cleaning up stale branches and worktrees ==="

# Remove tracking refs for branches deleted on the remote.
# GitHub deletes the remote branch when a PR is merged (delete_branch_on_merge=true).
echo "Fetching and pruning remote refs..."
git fetch --prune

# Remove worktree registrations for directories that no longer exist.
echo "Pruning stale worktree entries..."
git worktree prune

# Pass A: orphaned worktree directories. After git worktree prune removes the git
# registration, the directory on disk can be left behind. A live worktree always has a
# .git file (a plain text pointer to the registration in .git/worktrees/). No .git file
# means the directory is abandoned — safe to remove.
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WT_BASE="$ROOT/.claude/worktrees"
if [ -d "$WT_BASE" ]; then
  for _wd in "$WT_BASE"/*/; do
    [ -d "$_wd" ] || continue
    _wd="${_wd%/}"
    if [ ! -f "$_wd/.git" ]; then
      if rm -rf "$_wd"; then
        echo "  removed orphaned directory: $_wd"
      else
        echo "  WARN: could not remove $_wd — remove it manually" >&2
      fi
    fi
  done
fi

# Collect active worktree branches once — reused by Pass B and the NO_UPSTREAM exclusion.
# Also capture the full porcelain output for the worktree-path lookup inside the merge loop,
# so the command runs once here instead of once per candidate branch.
# A freshly-created worktree branch (no commits yet) has its tip at the branch point, which
# makes `git merge-base --is-ancestor` return true — it looks "merged" but is live work.
# Excluding active worktree branches prevents false-positive deletions in both Pass B and Pass 2.
WT_PORCELAIN=$(git worktree list --porcelain 2>/dev/null || true)
ACTIVE_WT_BRANCHES=$(printf '%s\n' "$WT_PORCELAIN" | awk '/^branch /{sub(/^branch refs\/heads\//, ""); print}' || true)

# Pass B: remote agent/workflow branches. The workflow system pushes under agent/* and
# claude/* prefixes. Once the local branch and worktree are gone (cleaned by Passes 1/2),
# only the remote ref remains — GitHub does not auto-delete branches with no associated PR.
# Delete only when: (1) no local branch exists, (2) no active worktree has it checked out,
# and (3) the remote tip is an ancestor of origin/main (confirmed merged).
# If condition 3 fails, print a warning and skip — the human makes the call.
for _ref in $(git for-each-ref --format='%(refname:short)' \
    'refs/remotes/origin/agent/*' 'refs/remotes/origin/claude/*' 2>/dev/null); do
  _short="${_ref#origin/}"
  git rev-parse --verify "refs/heads/$_short" >/dev/null 2>&1 && continue
  printf '%s\n' "$ACTIVE_WT_BRANCHES" | grep -qxF "$_short" && continue
  if git merge-base --is-ancestor "$_ref" origin/main 2>/dev/null; then
    if git push origin --delete "$_short" >/dev/null 2>&1; then
      echo "  deleted remote: $_short (merged into origin/main)"
    else
      echo "  WARN: could not delete remote $_short — try manually: git push origin --delete $_short" >&2
    fi
  else
    echo "  skipped remote: $_short (not confirmed merged — delete manually if done: git push origin --delete $_short)" >&2
  fi
done

# Pass 1: branches whose remote tracking ref is gone ([gone] after fetch --prune).
# git branch -vv marks the current branch "* " and a worktree-checked-out branch "+ ",
# so for those the name is $2, not $1. The [... : gone] match is anchored inside the
# tracking bracket so a commit subject containing the literal "gone]" can't false-trigger.
GONE=$(git branch -vv | awk '/\[[^]]*: gone\]/ && $1 != "*" { print ($1 == "+") ? $2 : $1 }' || true)

# Pass 2: local branches with no upstream tracking ref configured at all.
# These never get [gone] because git has no remote ref to mark absent.
# %(upstream) is empty when no upstream was ever set (git for-each-ref is safe to parse —
# no field-shift issues from the * and + decorators in git branch -vv).
#
# Protected branches (main/master/develop) are excluded explicitly. In a local-only repo
# they have no upstream, but they ARE ancestors of any feature branch — without this guard,
# the merge-verify gate would delete them. Mirrors the same list in block-dangerous-git.sh.
CURRENT=$(git branch --show-current 2>/dev/null || true)
NO_UPSTREAM=$(git for-each-ref --format='%(refname:short) %(upstream)' refs/heads/ | \
  awk '$2 == "" { print $1 }' | \
  grep -vE "^(main|master|develop)$" | grep -vFx "${CURRENT}" || true)
# Remove active worktree branches from NO_UPSTREAM candidates in one pass.
# -F treats each pattern as a fixed string (not a regex) so branch names containing
# dots, brackets, or other metacharacters match exactly. -x anchors to the full line.
if [ -n "$ACTIVE_WT_BRANCHES" ]; then
  NO_UPSTREAM=$(printf '%s\n' "$NO_UPSTREAM" | \
    grep -vFxf <(printf '%s\n' "$ACTIVE_WT_BRANCHES") || true)
fi

# Combine both passes. The merge-verify gate below protects both sets — a branch is only
# deleted if it is a confirmed merge (ancestor check or gh-confirmed merged PR).
CANDIDATES=$(printf '%s\n%s\n' "$GONE" "$NO_UPSTREAM" | sort -u | grep -v '^$' || true)

# Check gh availability once — used in the merge-verify and Pass C blocks inside the loop.
GH_AVAILABLE=false
command -v gh >/dev/null 2>&1 && GH_AVAILABLE=true

if [ -n "$CANDIDATES" ]; then
  echo "Cleaning up stale merged branches:"
  while IFS= read -r b; do
    # MERGE-VERIFY FIRST — before removing any worktree or branch. A [gone] remote is not a merge.
    # We can't use `git branch -d` as the probe (it refuses while the branch is checked out in a
    # worktree), so test merged-ness non-destructively: ancestor of where the script runs (normal
    # merge), or a gh-confirmed merged PR (squash-merge, which isn't an ancestor).
    MERGED=false
    if git merge-base --is-ancestor "$b" HEAD 2>/dev/null; then
      MERGED=true
    elif [ "$GH_AVAILABLE" = true ]; then
      PR=$(gh pr list --head "$b" --state merged --json number -q '.[0].number' 2>/dev/null || true)
      [ -n "$PR" ] && MERGED=true
    fi

    # Pass C: closed (not merged) PR detection. When the merge-verify gate fails, check
    # whether the branch had a closed PR. If it did, print the branch name, PR number, and
    # the exact delete command — the human decides whether to act. This replaces the generic
    # skip message so the human knows the branch was deliberately closed, not just stale.
    if [ "$MERGED" != true ]; then
      CLOSED_PR=""
      if [ "$GH_AVAILABLE" = true ]; then
        CLOSED_PR=$(gh pr list --head "$b" --state closed --json number,title \
          -q '.[0] | "#\(.number) \(.title)"' 2>/dev/null || true)
      fi
      if [ -n "$CLOSED_PR" ]; then
        echo "  closed PR: $b had $CLOSED_PR (not merged — delete manually: git branch -D $b)"
      else
        echo "  skipped: $b (remote gone but NOT merged — your commits are safe; delete manually if sure: git branch -D $b)"
      fi
      continue
    fi

    # Merged → safe to clean. If it's checked out in one of our worktrees, remove that first
    # (git refuses to delete a checked-out branch). Parse the cached porcelain output so we
    # don't re-invoke git worktree list once per branch.
    WT=$(printf '%s\n' "$WT_PORCELAIN" | awk -v br="refs/heads/$b" \
      '/^worktree /{ p=$0; sub(/^worktree /,"",p) } $0=="branch "br { print p }')
    if [ -n "$WT" ]; then
      case "$WT" in
        */.claude/worktrees/*)
          if git worktree remove --force "$WT" 2>/dev/null; then
            echo "  removed worktree: $WT (branch $b, merged)"
          else
            echo "  WARN: could not remove worktree $WT — remove it manually, then re-run prune-branches" >&2
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
