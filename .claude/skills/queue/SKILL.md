---
name: queue
description: Run multiple independent backlog tasks in parallel worktrees, then push and open PRs for each. Use when the user wants to work on several tasks at once, drain the backlog, or says "run tasks X through Y", "work on all of these", "do these in parallel", "knock out the backlog", "can we queue these up", "batch these tasks", "run the queue-execute workflow", or invokes /queue.
disable-model-invocation: true
---

# /queue — Multi-agent backlog runner

Orchestrates parallel agent work against independent tasks in `TASKS.md`.
Each task gets its own worktree, runs the full feature loop, and surfaces a push-ready
summary. Use this when you want to drain several independent tasks without sequential
hand-offs.

---

## Step 1 — Identify candidate tasks

Read `TASKS.md`. Extract tasks from the **P1** (and **P0** if any) sections that meet all of:

- Status is not blocked by another in-progress task
- Does not touch a shared, high-conflict file as its primary change:
  `CLAUDE.md`, `AGENTS.md` — tasks that modify these must be serialized, not parallelized

Tasks whose `filesAffected` fields share a file path are allowed in the same batch.
When two tasks share a file, the workflow runs them one at a time so they do not
edit the same file at the same time. Each task still branches from `origin/main` by default —
sharing a file does not automatically stack one branch on top of another.

To opt into branch stacking, add `stacksOn: "<slug>"` to a task. That task will branch
from `feat/<slug>` instead of `main`, and its PR will target `feat/<slug>` so the diff
shows only that task's own changes. Add `stacksOn` when task B calls or imports code that
task A writes. Omit it when two tasks happen to edit different parts of the same file but
do not depend on each other's code.

If two tasks have a code dependency but list no shared file, you cannot add `stacksOn` —
the workflow will reject it. Fix: add the shared output file (e.g. the file task A creates
and task B imports) to both tasks' `filesAffected`. That puts them in the same serial group,
and then `stacksOn` will be accepted.

Present the candidates as a numbered list with a one-line scope summary each.
Ask the user: "Which tasks should run in this batch? Enter numbers, or 'all'."

Wait for confirmation before proceeding.

---

## Step 2 — Preflight check

### Design gate (MEDIUM / LARGE / FEATURE tasks)

For each confirmed task, read its TASKS.md entry and check its size/type field:

- **MEDIUM**, **LARGE**, or **FEATURE** tasks (entries with `Size: MEDIUM`, `Size: LARGE`,
  `Size: FEATURE`, `Type: MEDIUM`, `Type: LARGE`, or `Type: FEATURE`) must have a `design:`
  reference in the entry. Example:
  ```
  - [ ] Redesign user dashboard
    Size: LARGE
    design: docs/design/dashboard.md
  ```
  A MEDIUM, LARGE, or FEATURE task without a `design:` line is rejected — stop and tell the user to run
  `/design contract` and add the `design:` reference before queuing it. Rationale: `@spec-writer`
  cannot write a good spec for a large task without a human-validated design; the run wastes
  overnight compute and blocks in the questions.md protocol.

  The workflow enforces this gate automatically — it will throw before creating any worktrees
  if a gated task is missing a `design:` field or if the file at that path does not exist.

- **SMALL**, **BUG**, and **CHORE** tasks skip this check — their scope is narrow enough that
  `@spec-writer` can work from the task description alone.

- If a task has no size/type field, treat it as SMALL and proceed (no `design:` required).

### Tool and environment check

- `scripts/worktree-add.sh` exists and is executable
- `scripts/pr.sh` exists and is executable
- `scripts/prune-branches.sh` exists and is executable (Step 5 post-merge cleanup uses it)
- `gh` is installed (`command -v gh`)
- Any env/credential files this project's tests require exist in the repo root
  (e.g. `.env.local`) — skip this check for projects that need none

If any check fails, surface the missing prerequisite and stop. Do not proceed with
a partial setup — a worktree missing a required env file will fail integration tests.

---

## Step 3 — Run the Workflow

This step launches the `queue-execute` Workflow, which handles worktree setup, task execution,
and PR opening without requiring you to be present. The Workflow is resumable: if the session
drops or the API times out, relaunch with `resumeFromRunId` and completed tasks return cached
results — no re-running from scratch.

**Build the task list.** For each confirmed task, construct a JSON object:

```json
{
  "slug": "add-rate-limiter",
  "title": "Add rate limiter to the public API",
  "description": "Rate-limiting middleware is wired to all public routes, tests green, behavior in TESTING.md.",
  "filesAffected": "src/middleware/rate-limit.ts, src/routes/api.ts, tests/rate-limit.test.ts",
  "decisions": "N/A",
  "references": "AGENTS.md → Middleware layer; CLAUDE.md → API conventions",
  "tdd": "TDD required",
  "size": "SMALL",
  "design": "",
  "stacksOn": ""
}
```

Field notes:
- `slug`: lowercase, spaces → hyphens, strip special chars. Becomes `feat/<slug>` branch name
  per `.claude/agent-contract.md` → BRANCH convention.
- `description`: one sentence stating the done state — not "implement X" but "X is wired to Y, tests green."
- `decisions`: resolved decisions from AGENTS.md → Resolved Decisions, or "N/A"
- `tdd`: "TDD required" unless the task has no new behaviors ("TDD N/A (no new behaviors)")
- `size`: copy the `Size:` value from the TASKS.md entry exactly (e.g. "LARGE", "MEDIUM", "SMALL"). Omit or set to `""` if the entry has no Size field.
- `design`: copy the `design:` path from the TASKS.md entry (e.g. `"docs/features/my-task.md"`). Omit or set to `""` if the entry has no `design:` line. The workflow will reject MEDIUM/LARGE/FEATURE tasks where this field is missing or points to a file that doesn't exist.
- `stacksOn`: the slug of another task in this batch whose branch this task should sit on top of. Leave empty (`""`) for most tasks — they will branch from `origin/main`. Set it only when this task calls or imports code that the other task writes. Both tasks must list at least one shared file in `filesAffected`; if they share no files the workflow will reject the value and explain how to fix it.

**Launch the Workflow** with the task array as `args`:

```
Workflow({ scriptPath: ".claude/workflows/queue-execute.js", args: [<task objects>] })
```

The Workflow runs three phases automatically:
1. **Setup** — creates a `feat/<slug>` worktree per task (idempotent: safe on resume)
2. **Execute** — runs `@task-runner` per task via `pipeline()` (resumable)
3. **Push** — pushes branches and opens PRs for tasks with a valid `.cr-ok` sentinel

Push is automatic for any task where task-runner wrote `.cr-ok` — the sentinel means `/cr`
ran clean. Tasks that are blocked or failed are excluded automatically.

**Resuming a failed run:** if the Workflow stops mid-run, relaunch with the run ID it reported:
```
Workflow({ scriptPath: ".claude/workflows/queue-execute.js", resumeFromRunId: "wf_<id>" })
```
Completed task-runner calls return instantly from cache; only the remaining tasks re-execute.

---

## Step 4 — Report results

After the Workflow completes, it returns a structured summary. Present it as a table:

```
## Queue run complete

| Task | Branch | Status | Tests | PR |
|------|--------|--------|-------|----|
| add-rate-limiter | feat/add-rate-limiter | done | 8/8 | #42 |
| fix-null-check   | feat/fix-null-check   | blocked | — | — |
```

Surface any `needsHuman` items from task results and any blocked/failed tasks with their
reason, so the user can act on them.

Update `TASKS.md`: mark completed tasks `[x]` and update the **Current State** block. Leave blocked/failed
tasks unchecked with a note appended to their **Notes** field.

---

## Step 5 — Worktree cleanup (after merge)

Task worktrees persist until their PRs **merge** — you may still need them for review fixes, so do
**not** remove a worktree while its PR is open. Once the PRs merge, run `scripts/prune-branches.sh`: it removes
each merged branch's `.claude/worktrees/<slug>` worktree and then deletes the branch (the worktree
must go first — git refuses to delete a branch that is still checked out in a worktree). Run it after
a merge batch, or rely on the session-start hook (`.claude/hooks/session-start.sh`), which runs it
automatically each session. WIP worktrees (live remote) are
never touched.
