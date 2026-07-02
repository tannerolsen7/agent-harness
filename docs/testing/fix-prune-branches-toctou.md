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

Confirmed independently: a project built on this harness (event-vendor) hit
this exact race in production and fixed it two ways: (1) excluding any branch
with zero commits ahead of `origin/main` from the candidate list up front, and
(2) re-checking worktree state live, right before deletion, instead of
trusting the snapshot from the top of the script.

**Only fix (2) was ported here.** Fix (1) depends on the source repo
squash-merging every PR — under squash-merge, a merged branch's original
commits are never literally absorbed into `origin/main` (the squash creates a
brand-new commit), so "zero commits ahead of `origin/main`" reliably means
"never had any real work." This harness repo does not require squash-merge
(`allow_merge_commit` and `allow_rebase_merge` are both enabled on GitHub, and
`tests/prune-branches.test.sh` already exercises a real, non-squash merge as
a first-class scenario). Porting fix (1) as-is was tried and empirically
broke two existing regression cases (`feat/done`, `feat/local`) — once a
branch is genuinely merged via a real merge commit, its own commits become
ancestors of `origin/main` too, and "zero commits ahead of `origin/main`" can
no longer tell "never touched" apart from "already fully merged." The
exclusion was reverted rather than kept as a broken safety net.

A first version of this fix only re-checked worktree state live and dropped
`--force` from `git worktree remove` — closing the case where a concurrent
session leaves *uncommitted or untracked* changes in the worktree. Adversarial
review (two independent lenses, one with direct reproduction) found that
version still lost data in a narrower case: a concurrent session that
**commits** real work instead of just dirtying the tree. A worktree with a
fresh commit is clean, so `git worktree remove` (no `--force`) succeeds
anyway, and `git branch --delete --force` right after doesn't check ancestry
— it deletes the branch ref regardless, orphaning the new commit. The fix
below closes both cases: it re-verifies merge status immediately before *any*
destructive action for that branch (not just once at the top of the loop
iteration), and only then does the live worktree check and removal.

### Confirmed behaviors — re-verify before any destructive action

- **Merge status is re-checked immediately before touching the worktree or
  branch, not just once at the top of the loop iteration:** Given a candidate
  branch was confirmed merged when its iteration began, the delete loop runs
  `git merge-base --is-ancestor` on it again right before removing its
  worktree or deleting it. If the branch gained new commits in the meantime
  (a concurrent session committed real work), this second check fails, and
  the branch and its worktree are both left untouched — a warning is printed
  instead.

- **The worktree lookup re-reads live state, not the startup snapshot:**
  Given the delete loop is about to remove a worktree for a branch that just
  re-passed the merge check above, it runs `git worktree list --porcelain`
  again at that point instead of reusing a snapshot captured at the top of
  the script. That startup snapshot is still fine for the faster,
  non-destructive filters earlier (Pass B, the `NO_UPSTREAM` exclusion) —
  only the point that actually deletes something needs live state.

- **Worktree removal no longer forces past a dirty working tree:** Given the
  worktree found for a branch that's still confirmed merged has uncommitted
  or untracked changes, `git worktree remove` (no `--force`) fails and the
  script prints a warning and leaves both the worktree and the branch in
  place, instead of silently discarding those changes. A clean, genuinely
  abandoned worktree is still removed and the branch still deleted, exactly
  as before.
