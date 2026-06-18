# Problem: `git stash` During a Rebase Conflict Corrupts `--continue` State

**Problem class:** You are mid-rebase with conflict markers to resolve. Working-tree changes unrelated to the conflict are blocking `git rebase --continue`. You run `git stash`, resolve the conflict files, pop the stash — and now `git rebase --continue` loops forever with "You must edit all merge conflicts and then mark them as resolved using git add", even though `git ls-files -u` shows nothing.

## When this bites you

You're rebasing a branch with ten commits onto current main. Git stops at commit 3: conflicts in two files. You also have unrelated working-tree edits (a hook file you modified mid-session). You stash those changes to get a clean state. You resolve the two conflict files and `git add` them. You pop the stash. You run `git rebase --continue`. Git refuses, claiming conflicts remain. `git ls-files -u` shows nothing. `git status` shows only working-tree modifications (` M`), no unmerged paths. You run `git add` on those too. Still refuses. The session ends with `git rebase --abort` and a merge instead.

## Root cause

When git enters a rebase conflict state, it records which files have conflicts in the index via unmerged entries (stage 1, 2, and 3 for ancestor, ours, and theirs). `git stash` snapshots and clears the index. When `git stash pop` applies the stash back, it writes file contents to the working tree but does not reconstruct the precise index state rebase was tracking. Git's internal conflict ledger is now out of sync with the actual file state. `git rebase --continue` reads that ledger and sees unresolved entries that no longer correspond to any file.

## The fix

**Never stash during a rebase conflict.** If you have unstaged working-tree changes that are blocking `--continue`:

- **If they're unrelated to the conflict:** Stage them anyway (`git add <file>`), then run `--continue`. After the rebase finishes, undo the add if you don't want them in any commit: `git restore --staged <file>`.
- **If you already stashed and are now stuck:** Abort and use `git merge` instead.

```bash
git rebase --abort          # restores pre-rebase state
git merge origin/main       # creates a merge commit instead; conflicts resolve normally
# resolve conflicts, git add, git commit
```

A merge commit is always safe here. It does not rewrite history and does not have this stash interaction problem.

## Why merge is a safe fallback

This codebase already uses merge commits to sync feature branches with main (e.g. `merge: sync with main (resolve TASKS.md conflict)`). The pre-push hook and PR script care about the sentinel file, not whether the sync was a rebase or a merge. A merge commit is the simpler, safer choice when the rebase state is uncertain.

## What doesn't work

**Touching and re-adding the conflict files after stash pop:** Git's internal ledger still says those paths are unmerged. Touching the file does not update the ledger; only a fresh conflict resolution does.

**Running `git commit --amend` then `--continue`:** This creates a new commit on the partially-applied state rather than finishing the rebase.

**Waiting for git to settle:** The state is genuinely stuck. Abort is the only reliable exit.

## Tags

git, rebase, stash, conflict-resolution, state-corruption, abort-and-merge
