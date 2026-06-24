# Problem: `git branch -D` safe auto-delete after squash merge

**Problem class:** A branch deletion gate that distinguishes "squash-merged, safe to delete" from "real unmerged work, block deletion."

## When this bites you

You squash-merge a feature branch into main via GitHub. The CI is green and the PR is closed. Now you try to clean up with `git branch -d feat/my-feature`. Git refuses because the branch's individual commits are not in main's ancestry — the squash merge created a single new commit, not a replay of the originals. Agents were forced to ask a human to run `git branch -D` manually, or they silently skipped cleanup and left stale branches behind.

## Root cause

`git branch -d` checks commit ancestry: it only deletes if the branch tip is reachable from the current HEAD or a specified upstream. After a squash merge, the branch tip is never reachable — the squash commit is a new commit with a different hash. So `-d` always fails on squash-merged branches, even when all the work is safely on main.

## The fix

Use a two-dot diff to compare tree state instead of commit ancestry.

```sh
git diff --quiet "$default_branch" "$branch_name"
```

A two-dot `git diff A B` compares the file trees at the tips of both refs. After a squash merge, main's tree includes every change from the branch, so the diff is empty and `--quiet` exits 0. If any real unmerged work exists, the diff is non-empty and exits 1.

When the hook sees `-D` (or `--delete --force`), it runs this check. Exit 0 means safe to allow. Exit 1 means block and explain.

The default branch name comes from:
```sh
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```
Falls back to `main` if that ref is not set.

**Implementation:** `.claude/hooks/block-dangerous-git.sh`, `branch)` case.

## How to know it's working

After squash-merging a branch, the hook should allow `git branch -D feat/branch` to proceed. If you run the same command on a branch with commits not yet on main, the hook should block it and print an explanation.

Run the test suite:
```sh
cd /Users/tanner/Dev/agent-harness && bash tests/allow-merged-branch-delete.test.sh
```

## The regression gate

`tests/allow-merged-branch-delete.test.sh` uses two stub `git` binaries:

- One where `diff` exits 0 and `symbolic-ref` returns `refs/remotes/origin/main` — simulates a squash-merged branch. The hook must allow the delete.
- One where `diff` exits 1 — simulates unmerged work. The hook must block.

## The invariant (replicate this when...)

Any time you need to decide "is this branch's work captured in the default branch?" — use `git diff --quiet default branch`. Do not use commit ancestry checks (`git merge-base --is-ancestor`) because they fail after squash merges. Do not use three-dot diff (`git diff A...B`), which shows what's on B since the common ancestor and returns non-empty even after a squash merge.

## What doesn't work

- **`git branch -d`** — always refuses squash-merged branches; not fixable without upstream changes.
- **`git merge-base --is-ancestor branch main`** — checks commit reachability, not tree state. Returns false after a squash merge, giving a false "unsafe" result.
- **Three-dot diff (`git diff main...feat/branch`)** — shows commits that are on the branch but not reachable from main, which includes every commit even after squash-merge. Always non-empty, always blocks. Wrong tool for this check.
- **Checking `gh pr view --json state`** — relies on GitHub API availability and trusts PR state rather than actual code state. A PR can be "merged" in GitHub but still have local commits not pushed.

## Tags

git, squash-merge, branch-delete, hooks, block-dangerous-git, diff, tree-comparison
