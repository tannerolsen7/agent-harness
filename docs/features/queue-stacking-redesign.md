# queue-stacking-redesign

## What & Why

The `/queue` workflow uses shared file paths to decide when to stack branches — task B branches from task A's feature branch because they both touch the same file. This conflates two separate ideas: execution order (should these tasks run one at a time?) and git ancestry (should task B's branch sit on top of task A's?). Three tasks that each add an independent function to the same file should run one at a time (safe) but each branch from `main` (independent PRs, clean diffs). Without this change, the queue forces them into a stack, which breaks when any of the tasks gets squash-merged.

## Context

- `.claude/workflows/queue-execute.js` — the workflow. `computeStacks()` builds connected components by file overlap. The loop that creates worktrees uses group position (`group[i-1].slug`) to set the base ref for each stacked task. `buildPrevSlugMap()` maps stacked slugs to their predecessor for PR base resolution.
- `.claude/skills/queue/SKILL.md` — documents stacking behavior to humans; Step 1 currently says "the workflow detects the overlap and stacks them automatically."

## Done Looks Like

- A batch of three tasks that share `filesAffected` files but have no `stacksOn` field all branch from `origin/main` and open PRs targeting `main`.
- A task with `stacksOn: "task-a"` branches from `feat/task-a` and its PR targets `feat/task-a`.
- A batch containing a task whose `stacksOn` names a slug not in the batch fails in preflight before any worktree is created, with a clear error naming the bad slug.
- `queue/SKILL.md` documents `stacksOn` in the task JSON example and field notes. It explains when to add it (task B calls or imports code written by task A) vs. leave it out (two tasks edit different parts of the same file). It also explains what to do when two tasks have a code dependency but share no files: add a shared filename (e.g. the file being created) to both tasks' `filesAffected` so the workflow puts them in the same group, then add `stacksOn`.
- Tests cover: no-stacksOn (branches from main), stacksOn-valid (branches from feat/<slug>), stacksOn-missing-slug (preflight error), stacksOn-cross-group (preflight error with filesAffected guidance).

## Interface Contract

Inputs:
- `task.stacksOn?: string` — optional slug of the task this task's branch should sit on top of. Absent or empty string means "branch from origin/main." Validated in preflight: if present, it must name another slug in the current batch.

Outputs:
- Worktree base ref — `feat/<stacksOn>` when `stacksOn` is set and that task is in the batch; `origin/main` otherwise. This is passed to `worktree-add.sh` as the third argument.
- PR base — `feat/<stacksOn>` when `stacksOn` is set and that task was pushed; `main` (with a retarget warning) when the stacked-on task was not pushed.

Constraints:
- Serialization (execution order) is unchanged — tasks that share files still run serially, regardless of `stacksOn`. `computeStacks()` is not replaced; it still drives the parallel/serial grouping.
- `stacksOn` can only reference a task in the same file-overlap group (a task the workflow would already run serially with this one). Cross-group `stacksOn` fails preflight: "task-b stacksOn task-a, but they share no files — add a shared filename to both tasks' filesAffected to put them in the same group." This keeps the execution model simple (flat parallel-over-groups).
- If `stacksOn` names a slug not in the current batch, the entire batch fails in preflight. No worktrees are created.
- Cycle detection: if A stacksOn B and B stacksOn A, fail in preflight.
- The ancestry guard (`verifyAncestry`) still runs for tasks with `stacksOn`, using `task.stacksOn` instead of group position. Tasks without `stacksOn` skip the guard (nothing to verify).

State:
- No new persistent state. `stacksOn` is runtime-only, lives in the JSON passed to the workflow.

## Out of Scope

- Changing how `/queue` identifies candidate tasks from `TASKS.md` — that step is unaffected.
- Auto-detecting code dependencies between tasks (imports, calls) — `stacksOn` is always explicit.
- Changing the serialization logic — tasks that share files still run one at a time.

## Relevant Files

- `.claude/workflows/queue-execute.js` — primary change: `computeStacks`, `buildPrevSlugMap`, `createWorktreePrompt`, and the preflight validation block all change.
- `.claude/skills/queue/SKILL.md` — Step 1 paragraph and the task JSON example both change.
- `tests/queue-execute.test.js` — new tests for the three `stacksOn` cases.
