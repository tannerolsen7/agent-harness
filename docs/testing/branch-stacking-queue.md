## Branch stacking in the /queue workflow

When a /queue batch includes tasks whose `filesAffected` fields share at least
one file path, those tasks are automatically stacked. Each branch is cut from
the previous branch's post-implementation tip so the branches merge to main
without conflicts. Tasks with no file overlap run in parallel as before.

### Confirmed behaviors

- **No file overlap → unchanged parallel behavior:** Given a /queue batch where
  no two tasks share any path in their `filesAffected` field, when the workflow
  runs, all worktrees are created from HEAD in parallel and all task-runners
  execute concurrently. Behavior is identical to the pre-stacking workflow.

- **Overlap detected → stacking plan logged before work starts:** Given a /queue
  batch where 2 or more tasks share at least one file path in their
  `filesAffected` fields, when the workflow reaches the Setup phase, it logs
  the stacking plan (which tasks are stacked and in what order) before creating
  any worktree. Tasks whose `filesAffected` value is `"N/A"`, `""`, or
  whitespace-only are treated as declaring no files and are never placed in a
  stack.

- **Stacked tasks run serially with correct git ancestry:** Given tasks A and B
  in the same stack group (sharing at least one file), when the workflow runs,
  it creates A's worktree, implements A, then creates B's worktree using
  `feat/A`'s branch tip as the base, then implements B. After the run, `git log
  feat/B` includes the commits from `feat/A` in its ancestry. Tasks in different
  stack groups (no shared files between groups) run concurrently with each other
  at the same time as the serial stack execution.

- **`worktree-add.sh` accepts an optional third argument as the base ref:** Given
  a call to `worktree-add.sh <path> <branch> <base-ref>`, when `$3` is provided,
  the script creates the new branch from `<base-ref>` instead of HEAD (i.e. runs
  `git worktree add -b "$BRANCH" "$PATH" "$BASE_REF"`). When `$3` is absent,
  the script behaves identically to today. The idempotency guard — which skips
  creation when the worktree directory already exists — still runs before `$3`
  is ever used. The TASKS.md in-progress marking still runs after worktree
  creation regardless of whether `$3` was supplied.

- **Stacked PRs target the previous branch, not the default branch:** Given task
  B is the second (or later) task in a stack, when the Push phase runs for B,
  the PR is opened with `--base feat/<prevSlug>` so the PR diff shows only B's
  own changes. The first task in each stack group, and all independent tasks,
  open their PRs targeting the repository's default branch as before.

- **Stacked-worktree ancestry is verified by the workflow, not trusted from the
  agent:** Given task B is stacked on task A, the workflow asks a sub-agent to
  run `worktree-add.sh` with `feat/A` as the base ref. An agent might paraphrase
  or garble that command and create B's worktree on the wrong base. After the
  worktree-create agent returns for a stacked task (one with a non-null base
  ref), the workflow runs its own direct check that `feat/<prevSlug>` is an
  ancestor of the new worktree's HEAD — it does not trust the agent's report.
  The check is exposed as the pure function `verifyAncestry(worktreePath,
  prevSlug, isAncestorFn)`: it returns `{ ok: true }` when `isAncestorFn`
  reports the base is an ancestor, and `{ ok: false, error }` (with a message
  naming `feat/<prevSlug>` and the worktree path) when it is not. The first task
  in a stack group has a null base ref and is never checked. When the check
  fails, the workflow logs the error and aborts the rest of that stack group;
  other stack groups and independent tasks are unaffected.
