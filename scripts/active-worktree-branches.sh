#!/bin/bash
# scripts/active-worktree-branches.sh — print one branch name per line for every branch
# currently checked out in a live worktree of this repo.
# Shared by scripts/prune-branches.sh and scripts/sync-open-prs.sh so the porcelain-parsing
# awk expression lives in exactly one place instead of being copy-pasted at each call site.
git worktree list --porcelain 2>/dev/null | awk '/^branch /{sub(/^branch refs\/heads\//, ""); print}'
