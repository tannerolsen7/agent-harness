# Problem: git worktree list uses absolute paths, relative path grep always fails

**Problem class:** Silent grep mismatch — a path format difference causes an existence check to always return false, making an idempotency guard a no-op.

## When this bites you

You are writing a shell script that creates git worktrees. You want to skip creation if the worktree already exists. You write something like:

```sh
if [ -d "$WORKTREE_PATH" ] && git worktree list --porcelain | grep -qF "worktree $WORKTREE_PATH"; then
  echo "already exists, skipping"
fi
```

`$WORKTREE_PATH` is a relative path like `.claude/worktrees/my-task`. The check never matches. The script falls through to `git worktree add`, which exits with an error like "fatal: '.claude/worktrees/my-task' is already checked out."

## Root cause

`git worktree list --porcelain` outputs absolute paths. Example output:

```
worktree /full/path/to/repo/.claude/worktrees/my-task
HEAD abc1234...
branch refs/heads/my-task
```

Grepping for `worktree .claude/worktrees/my-task` never matches because the output contains `worktree /full/path/to/repo/.claude/worktrees/my-task`. The directory check (`-d "$WORKTREE_PATH"`) passes fine, so the bug is invisible until the second command fails.

## The fix

Check for the `.git` FILE that git writes inside every worktree directory:

```sh
if [ -d "$WORKTREE_PATH" ] && [ -f "$WORKTREE_PATH/.git" ]; then
  echo "already exists, skipping"
  exit 0
fi
```

The `.git` file is a plain text pointer that git writes when it creates a worktree. Its contents look like:

```
gitdir: /full/path/to/repo/.git/worktrees/my-task
```

This check is path-format-independent. It works with relative or absolute paths in `$WORKTREE_PATH` because it only looks at what is on disk, not what `git worktree list` prints.

## The invariant (replicate this when ...)

Any shell script that needs to detect "is this directory a live git worktree" should use `[ -f "$PATH/.git" ]`. Use this pattern in:

- Idempotency guards before `git worktree add`
- Cleanup scripts that need to distinguish worktree directories from plain directories
- Health checks that verify a worktree was set up correctly

## What doesn't work

**`git worktree list --porcelain | grep -qF "worktree $RELATIVE_PATH"`** — fails silently when `$RELATIVE_PATH` is relative. The directory exists, the worktree is registered with git, but the grep never matches because the output is always absolute.

**`git worktree list --porcelain | grep -qF "$WORKTREE_PATH"`** (even resolving to absolute) — fragile because it requires knowing `$PWD` at the time the worktree was created, which may differ from `$PWD` in the current shell.

**Just checking `[ -d "$WORKTREE_PATH" ]`** — a plain directory or a partially-failed setup also passes this check. The `.git` file confirms git actually registered the worktree.

## Tags

git-worktree, worktree detection, idempotent setup, .git file vs directory, relative path, grep mismatch, worktree-add.sh, shell script, resumable workflow
