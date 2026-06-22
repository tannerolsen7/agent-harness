## Branch and worktree pruning (`scripts/prune-branches.sh`)

`prune-branches.sh` (renamed from `gc.sh`) cleans up leftover branches and
worktree directories. Three new passes extend the existing merge-verify loop.

**Pass A** removes orphaned worktree directories — directories under
`.claude/worktrees/` that git no longer tracks. After `git worktree prune`
removes the registration, a directory can be left behind. A live worktree
directory always contains a `.git` file; absence of that file marks the
directory as abandoned.

**Pass B** removes orphaned remote agent and workflow branches — remote
branches under `origin/agent/*` or `origin/claude/*` that have already been
merged into `origin/main` and have no local branch or active worktree keeping
them alive.

**Pass C** (flag-only) identifies local branches that have a closed (not yet
merged) pull request and prints the exact delete command instead of the
generic skip message, so a human can act on it deliberately.

### Confirmed behaviors — Pass A (orphaned worktree directories)

- **orphaned-dir-removed:** Given a subdirectory exists under
  `.claude/worktrees/` and that directory does NOT contain a `.git` file, when
  the script runs Pass A, the directory is removed with `rm -rf` and a log
  message is printed naming the directory.

- **live-worktree-dir-kept:** Given a subdirectory exists under
  `.claude/worktrees/` and that directory DOES contain a `.git` file, when the
  script runs Pass A, the directory is left untouched.

- **worktrees-dir-absent-is-safe:** Given `.claude/worktrees/` does not exist,
  when the script runs Pass A, no error is produced and the script continues.

### Confirmed behaviors — Pass B (orphaned remote agent/workflow branches)

- **merged-ancestor-remote-deleted:** Given a remote branch under
  `origin/agent/*` or `origin/claude/*` has no matching local branch, is not
  checked out in any active worktree, and its tip is an ancestor of
  `origin/main`, when the script runs Pass B, the remote branch is deleted.

- **local-branch-present-skipped:** Given a remote branch under
  `origin/agent/*` or `origin/claude/*` and a local branch of the same name
  exists, when the script runs Pass B, the remote branch is NOT deleted.

- **active-worktree-checkout-skipped:** Given a remote branch under
  `origin/agent/*` or `origin/claude/*` and an active worktree has that branch
  checked out, when the script runs Pass B, the remote branch is NOT deleted.

- **non-ancestor-remote-warned:** Given a remote branch under `origin/agent/*`
  or `origin/claude/*` has no matching local branch, is not checked out in any
  active worktree, and its tip is NOT an ancestor of `origin/main`, when the
  script runs Pass B, a warning is printed and the remote branch is NOT deleted.

### Confirmed behaviors — Pass C (closed PR flag)

- **closed-pr-prints-command:** Given a local branch has a closed (not merged)
  pull request (detected via `gh pr list --head <branch> --state closed`), when
  the existing merge-verify loop determines the branch was not merged, the
  script prints the branch name, the PR number, and the exact `git branch -D
  <branch>` command. The branch is NOT deleted by the script.

- **no-closed-pr-falls-through:** Given a local branch has neither a merged
  commit nor a closed pull request, when the existing merge-verify loop
  processes that branch, the script falls through to the existing generic skip
  message unchanged.
