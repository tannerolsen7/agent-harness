## Prune-branches TOCTOU race on worktree removal (`scripts/prune-branches.sh`)

The merge-verify gate already excludes branches that are checked out in a
worktree *at the moment `WT_PORCELAIN` is captured* (PITFALLS.md: "`git
merge-base --is-ancestor` cannot tell a fresh branch from a merged one").
That snapshot is captured once, early, and reused later — inside the delete
loop, and by every candidate branch ahead of a given one in that loop. Each
candidate can trigger a `gh pr list` network call, so by the time the loop
reaches a later candidate, real time has passed since the snapshot. A
worktree created by a concurrent session in that window is invisible to the
stale snapshot, so a branch that looks safe to delete can have its worktree
force-removed — destroying whatever uncommitted work that concurrent session
had in progress.

Confirmed independently: a project built on this harness (event-vendor)
hit this exact race in production and fixed it by re-checking worktree state
live, right before deletion, instead of trusting the snapshot from the top of
the script.

### Confirmed behaviors — zero-commit exclusion

- **A branch with zero commits ahead of `origin/main` is excluded from the
  candidate list before the merge-verify loop runs:** Given a candidate branch
  (from Pass 1 or Pass 2) whose tip has zero commits ahead of `origin/main`,
  when `prune-branches.sh` builds its candidate list, that branch is dropped
  from `CANDIDATES` before the merge-verify loop starts, and a "zero commits
  ahead" message is printed. This closes the false-positive at its source: a
  branch with no unique commits trivially passes `git merge-base
  --is-ancestor`, whether or not it is checked out in a worktree.

- **A genuinely merged branch with real commits is still cleaned up:** Given a
  candidate branch with one or more commits ahead of `origin/main`, all of
  which are already merged, the zero-commit exclusion does not apply to it,
  and the existing merge-verify gate still deletes it as before.

### Confirmed behaviors — live worktree check before deletion

- **The worktree lookup right before deletion re-reads live state, not the
  startup snapshot:** Given the delete loop is about to remove a worktree for
  a confirmed-merged branch, it runs `git worktree list --porcelain` again at
  that point instead of reusing the cached `$WT_PORCELAIN` variable captured
  at the top of the script. `$WT_PORCELAIN` is still used earlier (Pass B, the
  `NO_UPSTREAM` exclusion) as a fast up-front filter — only the deletion
  point itself needs the live re-check, since that is the point where
  destructive action actually happens.

- **Worktree removal no longer forces past a dirty working tree:** Given the
  worktree found for a confirmed-merged branch has uncommitted or untracked
  changes, `git worktree remove` (no `--force`) fails and the script prints a
  warning and leaves both the worktree and the branch in place, instead of
  silently discarding those changes. A clean, genuinely abandoned worktree is
  still removed and the branch still deleted, exactly as before.
