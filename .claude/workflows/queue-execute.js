export const meta = {
  name: 'queue-execute',
  description: 'Run a /queue task batch: create worktrees, execute task-runner pipeline per task, push and open PRs for tasks that pass /cr.',
  phases: [
    { title: 'Setup', detail: 'Create a worktree for each task (idempotent — safe to resume)' },
    { title: 'Execute', detail: 'Run the task-runner specialist pipeline per task in parallel' },
    { title: 'Push', detail: 'Push branches and open PRs for tasks whose .cr-ok sentinel is present' },
  ],
}

// args is an array of task objects. Each task must have:
//   slug        — hyphenated identifier, e.g. "add-rate-limiter"
//   title       — human-readable title for the PR
//   description — one sentence: what "done" looks like
//   filesAffected — string listing files the task may touch
//   decisions   — resolved decisions relevant to this task (or "N/A")
//   references  — CLAUDE.md / CONTEXT.md / AGENTS.md sections to read (or "N/A")
//   tdd         — "TDD required" or "TDD N/A (no new behaviors)"
const tasks = args

const TASK_RESULT_SCHEMA = {
  type: 'object',
  required: ['taskSlug', 'status', 'branch'],
  properties: {
    taskSlug:         { type: 'string' },
    status:           { type: 'string', enum: ['done', 'blocked', 'failed'] },
    branch:           { type: 'string' },
    commitSHAs:       { type: 'array', items: { type: 'string' } },
    needsHuman:       { type: 'array', items: { type: 'string' } },
    testsAdded:       { type: 'number' },
    testsGreen:       { type: 'number' },
    mustFixCount:     { type: 'number' },
    compoundDraftPath:{ type: 'string' },
    blockingReason:   { type: 'string' },
    assumptions:      { type: 'array', items: { type: 'string' } },
  },
}

const PR_RESULT_SCHEMA = {
  type: 'object',
  required: ['taskSlug', 'status'],
  properties: {
    taskSlug:      { type: 'string' },
    status:        { type: 'string', enum: ['pushed', 'failed', 'skipped'] },
    prUrl:         { type: 'string' },
    prTitle:       { type: 'string' },
    failureReason: { type: 'string' },
  },
}

// ── Phase 1: Setup ──────────────────────────────────────────────────────────
// Create each task's worktree before the pipeline fan-out. This separation
// means a resumed run (resumeFromRunId) won't try to re-create worktrees that
// the Execute phase already used — worktree-add.sh is idempotent, so re-running
// it is safe, but avoiding it is cleaner.
phase('Setup')
log(`Creating ${tasks.length} worktrees`)
await parallel(tasks.map(t => () =>
  agent(
    `Create a git worktree for task "${t.slug}". From the repo root, run:
bash scripts/worktree-add.sh .claude/worktrees/${t.slug} feat/${t.slug}

The script is idempotent — if the worktree already exists it exits 0 immediately.
Report "created" or "already exists" on success, or the exact error on failure.`,
    { label: `worktree:${t.slug}`, phase: 'Setup' }
  )
))

// ── Phase 2: Execute ─────────────────────────────────────────────────────────
// pipeline() lets each task advance independently — task B reaches reviewer
// while task A is still in implementer. resumeFromRunId caches completed
// agent() calls by (prompt, opts), so a session that dies at task 5 of 10
// restarts from task 6, not task 1.
phase('Execute')
log(`Running ${tasks.length} task-runner agents`)
const taskResults = await pipeline(
  tasks,
  (task) => agent(
    `You are implementing a single scoped task. Follow .claude/agent-contract.md exactly.

WORKTREE (do this first — re-verify before every commit):
  Path:   .claude/worktrees/${task.slug}
  Branch: feat/${task.slug}
  cd into it now. Before each commit confirm git rev-parse --show-toplevel
  ends in /.claude/worktrees/${task.slug}. If not, cd back.

GOAL: ${task.description}
SCOPE: ${task.filesAffected || 'N/A'}
DECISIONS ALREADY MADE: ${task.decisions || 'N/A'}
REFERENCES: ${task.references || 'N/A'}
TDD REQUIREMENT: ${task.tdd || 'TDD required'}
BRANCH: feat/${task.slug}
STOP AND SURFACE: per .claude/agent-contract.md`,
    {
      agentType: 'task-runner',
      label: `task:${task.slug}`,
      schema: TASK_RESULT_SCHEMA,
      phase: 'Execute',
    }
  )
)

// ── Phase 3: Push ────────────────────────────────────────────────────────────
// Open PRs for tasks that completed successfully. Sequential — scripts/pr.sh
// reads and deletes .cr-ok; concurrent calls on the same worktree would race.
// The .cr-ok sentinel (written by task-runner on completion) is the gate:
// scripts/pr.sh validates and consumes it before calling gh pr create.
phase('Push')
const doneResults = taskResults.filter(r => r && r.status === 'done')
log(`${doneResults.length} of ${tasks.length} tasks done — pushing and opening PRs`)

const prResults = []
for (const result of doneResults) {
  const task = tasks.find(t => t.slug === result.taskSlug) || { title: result.taskSlug }
  const pr = await agent(
    `Push branch and open a GitHub PR for task "${result.taskSlug}".

Steps (run in order):
1. cd .claude/worktrees/${result.taskSlug}
2. Confirm .claude/.cr-ok exists and contains "feat/${result.taskSlug}:<sha>".
   If missing or wrong, report status: "skipped" with failureReason explaining why.
3. git push -u origin feat/${result.taskSlug}
4. bash scripts/pr.sh \\
     --title "feat(${result.taskSlug}): ${task.title}" \\
     --body "$(cat .claude/compound-draft-${result.taskSlug}.md 2>/dev/null || echo 'Automated /queue task — see task-runner summary.')"

Report the PR URL and title on success, or the failure reason.`,
    { label: `pr:${result.taskSlug}`, schema: PR_RESULT_SCHEMA, phase: 'Push' }
  )
  if (pr) prResults.push(pr)
}

// ── Return structured summary for /queue's final report ──────────────────────
const pushed  = prResults.filter(r => r.status === 'pushed')
const blocked = taskResults.filter(r => r && r.status !== 'done')
const failedPRs = prResults.filter(r => r.status === 'failed')

return {
  summary: {
    total:      tasks.length,
    done:       doneResults.length,
    blocked:    blocked.length,
    prsOpened:  pushed.length,
    prsFailed:  failedPRs.length,
  },
  taskResults: taskResults.filter(Boolean),
  prResults,
}
