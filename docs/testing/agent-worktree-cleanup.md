## Agent worktree cleanup (`scripts/cleanup-worktree.sh`)

`cleanup-worktree.sh` removes an agent's worktree directory and its branch
immediately after a PR merges — without waiting for the next session start.
The script is safe to call at any time: if the branch is not yet merged, it
exits without touching anything.

### Confirmed behaviors — path resolution and safety gate

- **No-arg call resolves path from CWD:** Given the script is called with no
  arguments from inside a worktree, it runs `git rev-parse --show-toplevel` to
  find the worktree root and uses that as the target path.

- **Explicit path argument overrides CWD resolution:** Given a path is passed
  as the first positional argument, the script uses that path directly instead
  of running `git rev-parse --show-toplevel`.

- **Path outside `.claude/worktrees/` exits 1 immediately:** Given the
  resolved absolute path does not start with `$REPO_ROOT/.claude/worktrees/`,
  the script exits 1 before touching any worktree or branch.

- **Main repo root exits 1 immediately:** Given the resolved path is the main
  repo root (identified by `.git` being a directory rather than a file), the
  script exits 1 before touching anything.

### Confirmed behaviors — merge check

- **Merged branch is cleaned up:** Given the branch's tip commit is an ancestor
  of `origin/main` (checked via `merge-base --is-ancestor`), when the script
  runs, it removes the worktree and deletes the branch.

- **Merge check uses `origin/main`, not `HEAD`:** The script compares the
  branch tip against `origin/main`. It does NOT compare against `HEAD`, because
  `HEAD` inside the worktree points to the feature branch — comparing against it
  would always return true and delete every branch.

- **Branch not merged exits 0 with message:** Given the branch tip is NOT an
  ancestor of `origin/main` and `gh` is not available or reports no merged PR,
  the script prints "branch X not yet merged — nothing done" and exits 0 without
  removing the worktree or branch.

- **Squash-merge detected via `gh` when available:** Given the branch was merged
  via a squash-merge (so the tip commit is not a direct ancestor of `origin/main`)
  and `gh` is available, the script checks `gh pr list --state merged` to confirm
  the merge. When `gh` confirms the PR is merged, cleanup proceeds.

- **`gh` absent with squash-merge treated as not merged:** Given the branch was
  squash-merged and `gh` is not available, `merge-base --is-ancestor` returns
  false and there is no fallback check. The script treats the branch as not
  merged, prints the "not yet merged" message, and exits 0.

### Confirmed behaviors — cleanup order and output

- **Worktree is removed before the branch is deleted:** The script calls the
  worktree removal command before calling the branch deletion command. This
  order is required because git refuses to delete a branch that is checked out
  in a live worktree.

- **Recovery hint printed before branch deletion:** Before deleting the branch,
  the script prints a one-line recovery hint in the form
  `recover: git branch <name> <sha>` so the branch tip SHA is visible in the
  log if a rollback is ever needed.

- **Stdout messages are one line per action:** Each action (worktree removed,
  branch deleted) produces exactly one line of output, e.g.
  "removed worktree: ..." and "deleted branch ...".

- **Script exits 0 on success:** After the worktree and branch are removed, the
  script exits 0.

### Confirmed behaviors — idempotency and edge cases

- **Worktree directory already gone exits 0:** Given the worktree directory was
  already removed before the script runs (e.g., removed by a prior run or
  manually), the script exits 0 silently. Any orphaned branch will be caught by
  `prune-branches.sh` at the next session start.

- **Branch already deleted exits 0:** Given the worktree is removed and then the
  branch delete finds no branch to delete, the script suppresses the error and
  exits 0. Both are cleaned up, which is the desired end state.

- **Called twice is a no-op on the second call:** Given the script runs
  successfully once, a second call finds no worktree directory and no branch.
  The script exits 0.

- **Detached HEAD exits 0 gracefully:** Given `git rev-parse --abbrev-ref HEAD`
  run inside the worktree returns the literal string "HEAD" (indicating detached
  HEAD state), the script exits 0 without attempting to delete a branch named
  "HEAD".

### Confirmed behaviors — task-runner integration

- **Step 6 runs cleanup after TASKS.md is updated:** In `.claude/agents/task-runner.md`,
  after the existing step that marks the task `[x]` in `TASKS.md` and before
  returning the summary, step 6 runs `bash scripts/cleanup-worktree.sh` with no
  argument (called from inside the worktree).

- **Cleanup step never blocks the return summary:** The exit code of
  `cleanup-worktree.sh` is always treated as 0 by the task-runner. A failed or
  skipped cleanup does not prevent the task-runner from returning its summary.

- **Cleanup at task completion is speculative:** The PR is usually not yet merged
  when the task-runner finishes. If the branch is not merged, the script exits 0
  with the "not yet merged" message and the worktree and branch are left for
  `prune-branches.sh` to handle at the next session start.
