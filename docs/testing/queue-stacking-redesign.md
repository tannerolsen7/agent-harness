## Explicit `stacksOn` field in the /queue workflow

Replaces automatic file-overlap branch stacking with an opt-in `stacksOn`
field on task objects. Tasks that share `filesAffected` files still run
serially within their overlap group, but each branches from `origin/main`
by default. Adding `stacksOn: "<slug>"` to a task makes that task branch
from `feat/<slug>` instead.

### Confirmed behaviors — preflight validation

- **`stacksOn` naming an unknown slug fails the whole batch before any
  worktree is created:** Given a batch where task B has `stacksOn: "task-x"`
  and no task in the batch has slug `"task-x"`, when queue-execute.js runs,
  it throws before any `agent()` call for worktree creation. The error message
  names the unrecognized slug `"task-x"` so the user knows exactly what to fix.

- **`stacksOn` referencing a task in a different file-overlap group fails the
  batch:** Given task A touches `src/a.ts` and task B touches `src/b.ts` (no
  shared file), if B has `stacksOn: "task-a"`, the workflow throws before any
  worktree is created. The error message explains that A and B share no files
  and tells the user how to fix it: add a shared filename to both tasks'
  `filesAffected` to put them in the same serial group.

- **A `stacksOn` cycle fails the batch:** Given task A has `stacksOn: "task-b"`
  and task B has `stacksOn: "task-a"`, when the workflow runs, it throws before
  any worktree is created. The error message identifies the cycle.

- **All three preflight failures throw before `computeStacks()` runs:** Given
  any of the three invalid `stacksOn` cases above, the workflow throws before
  `computeStacks()` is called. No worktree directory is created for any task in
  the batch.

- **Multiple `stacksOn` errors in one batch produce a single throw listing all
  problems:** Given two tasks that each have an invalid `stacksOn` value, the
  workflow throws once with a message that covers both failures rather than
  stopping at the first one.

### Confirmed behaviors — default branching (no `stacksOn`)

- **Tasks with no `stacksOn` field branch from `origin/main` by default:** Given
  two tasks that share a file in `filesAffected` but neither has a `stacksOn`
  field, when the workflow creates their worktrees, each is branched from
  `origin/main` (not from the other task's branch tip). Both tasks still run
  serially within the overlap group.

- **Tasks with `stacksOn: ""` (empty string) also branch from `origin/main`:**
  Given a task object where `stacksOn` is present but set to an empty string,
  the workflow treats it the same as an absent field and branches from
  `origin/main`.

### Confirmed behaviors — `stacksOn` in effect

- **A task with `stacksOn: "<slug>"` branches from `feat/<slug>`:** Given task B
  has `stacksOn: "task-a"` and task A is in the same file-overlap group, when
  the workflow creates B's worktree, it passes `feat/task-a` as the base ref
  to `worktree-add.sh`. After creation, `git log feat/task-b` includes commits
  from `feat/task-a` in its ancestry.

- **`verifyAncestry` still runs for tasks with `stacksOn`:** Given task B has
  `stacksOn: "task-a"` and the worktree-create agent returns, the workflow runs
  its own direct git ancestry check (`git merge-base --is-ancestor feat/task-a
  HEAD` in B's worktree) before letting the implementer agent start. If the
  check fails, the workflow logs the error and aborts the rest of the stack group.

- **Tasks without `stacksOn` skip the ancestry check:** Given task B has no
  `stacksOn` field (or an empty one) and therefore branches from `origin/main`,
  the workflow does not call `verifyAncestry` for that task. Only tasks whose
  base ref is a sibling branch (not main) need the check.

- **Stacked PR targets `feat/<stacksOn-slug>` as its base:** Given task B has
  `stacksOn: "task-a"` and task A was successfully pushed, when the Push phase
  runs for B, it opens the PR with `--base feat/task-a` so the PR diff shows
  only B's own changes.

- **Stacked PR falls back to default branch when the `stacksOn` task was not
  pushed:** Given task B has `stacksOn: "task-a"` and task A was not pushed
  (its /cr failed or it was blocked), when the Push phase runs for B, the PR
  targets the repository default branch instead of `feat/task-a`. The workflow
  posts a warning comment on the PR explaining that the base was never pushed
  and the diff includes both tasks' changes.

### Confirmed behaviors — SKILL.md documentation

- **Step 1 describes `stacksOn` as opt-in, not automatic:** The prose in Step 1
  no longer describes automatic stacking from file overlap alone. It tells the
  user to add `stacksOn` when task B calls or imports code written by task A,
  and to omit it when two tasks happen to edit different parts of the same file.

- **Step 3 task JSON example includes a `stacksOn` field:** The example task
  object in Step 3 includes a `stacksOn` field (set to `""` for an independent
  task) so users see the field name and know it exists.

- **Step 3 field notes explain the `filesAffected` workaround for cross-group
  stacking:** The notes explain that if two tasks have a code dependency but
  share no files, the user should add a shared filename to both tasks'
  `filesAffected` and then add `stacksOn`. This is the only way to stack across
  tasks that would otherwise be in separate serial groups.
