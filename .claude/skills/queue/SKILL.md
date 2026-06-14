---
name: queue
description: Run multiple independent backlog tasks in parallel worktrees, then push and open PRs for each.
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
- Scope does not overlap with any other candidate (different files, no shared migrations)
- Does not touch a shared, high-conflict file as its primary change:
  `migrations/`, `CLAUDE.md`, `AGENTS.md` — tasks that modify these
  must be serialized, not parallelized

Present the candidates as a numbered list with a one-line scope summary each.
Ask the user: "Which tasks should run in this batch? Enter numbers, or 'all'."

Wait for confirmation before proceeding.

---

## Step 2 — Preflight check

Before spawning any agents, verify:

- `scripts/worktree-add.sh` exists and is executable
- `scripts/pr.sh` exists and is executable
- `scripts/gc.sh` exists and is executable (Step 7 post-merge cleanup uses it)
- `gh` is installed (`command -v gh`)
- Any env/credential files this project's tests require exist in the repo root
  (e.g. `.env.local`) — skip this check for projects that need none

If any check fails, surface the missing prerequisite and stop. Do not proceed with
a partial setup — a worktree missing a required env file will fail integration tests.

---

## Step 3 — Spawn agents in parallel

For each confirmed task, in a single message (parallel tool calls):

1. Determine branch name: `feat/<task-slug>` (slugify the task title)
2. Create the task's worktree: `scripts/worktree-add.sh .claude/worktrees/<task-slug> feat/<task-slug>`
   (this runs the G1 setup — env symlinks, npm install, husky-shim assert).
3. Spawn the agent to run **in that worktree**. Do **not** pass `isolation: "worktree"` — the
   per-task worktree from step 2 IS this task's isolation (separate dir, branch, and index, so
   parallel agents don't conflict). Passing `isolation: "worktree"` would make the Agent tool
   create a *second*, separate worktree and leave the step-2 one orphaned (registered, unused,
   never cleaned). The agent's first action is to `cd` into its worktree.

Agent prompt template (fill in per task):

> You are implementing a single scoped task. Follow the agent contract in
> `.claude/agent-contract.md` exactly.
>
> **WORKTREE (do this first — and re-verify before every commit):** your worktree is
> `.claude/worktrees/<task-slug>`, on branch `feat/<task-slug>`. `cd` into it now. Because a shell
> CWD can reset between steps, **before each commit confirm you are still in it** —
> `git rev-parse --show-toplevel` must end in `/.claude/worktrees/<task-slug>`; if not, `cd` back
> (or run git with `-C .claude/worktrees/<task-slug>`). ALL edits, commits, and the `.cr-ok` sentinel
> happen there. A commit run from the repo root lands on the wrong branch — never work in the repo root.
>
> **SETUP:** if this project's tests need a root env file, symlink it in — the worktree does not
> inherit it, and integration tests fail without it. Example:
> `ln -sf "$(git rev-parse --show-toplevel)/.env.local" .env.local`
> Skip for projects that need no env file.
>
> **GOAL:** [one sentence — the done state]
> **SCOPE:** [exact files this task may touch]
> **DECISIONS ALREADY MADE:** [cite AGENTS.md → Resolved Decisions if relevant]
> **REFERENCES:** [CLAUDE.md sections, schemas, data functions]
> **TDD REQUIREMENT:** TDD required / TDD N/A (no new pure functions)
> **BRANCH:** feat/[task-slug]
> **STOP AND SURFACE:** [conditions per agent-contract.md]
>
> Return the standard agent-contract summary when done.

Note: Agents do NOT push — the orchestrator handles push and PR after reviewing all summaries.

---

## Step 4 — Collect results

Wait for all agents to return. For each:

- **Status: done, no NEEDS HUMAN** → ready to push
- **Status: done, NEEDS HUMAN items** → surface to user before pushing
- **Status: blocked / failed** → surface full summary; do not push

Present a table:

```
| Task | Branch | Status | NEEDS HUMAN | Tests |
|------|--------|--------|-------------|-------|
| ...  | ...    | done   | 0           | 14/14 |
| ...  | ...    | blocked| —           | —     |
```

Ask the user: "Push and open PRs for the 'done' tasks? [y/N]"

---

## Step 5 — Push and open PRs

For each task approved for push, sequentially (not in parallel — avoid concurrent pushes
on shared git state):

1. `cd` into the agent's worktree path
2. Verify the `.cr-ok` sentinel exists and matches HEAD: `cat .claude/.cr-ok` must equal `feat/<task-slug>:<HEAD sha>`
3. `git push -u origin feat/<task-slug>`
4. `scripts/pr.sh --title "<conventional commit title>" --body "<agent summary as PR body>"`
   `scripts/pr.sh` validates and consumes the `.cr-ok` sentinel before calling `gh pr create`.

If the sentinel is missing or stale, the task-runner did not complete its review pipeline — do not push. Surface the issue and stop for that task.

---

## Step 6 — Final summary

```
## Queue run complete

### Pushed + PR opened
- feat/<slug> → PR #<number>: <title>

### Needs human (not pushed)
- feat/<slug>: <NEEDS HUMAN item summary>

### Blocked / failed
- feat/<slug>: <reason>

### Skipped (overlapping scope — serialize these)
- <task name>: conflicts with <other task>
```

Update `TASKS.md`: mark completed tasks `[x]` and update the **Current State** block. Leave blocked/failed
tasks unchecked with a note appended to their **Notes** field.

---

## Step 7 — Worktree cleanup (after merge)

Task worktrees persist until their PRs **merge** — you may still need them for review fixes, so do
**not** remove a worktree while its PR is open. Once the PRs merge, run `scripts/gc.sh`: it removes
each merged branch's `.claude/worktrees/<slug>` worktree and then deletes the branch (the worktree
must go first — git refuses to delete a branch that is still checked out in a worktree). Run it after
a merge batch, or let the weekly `stale-branch-audit` ritual run it. WIP worktrees (live remote) are
never touched.
