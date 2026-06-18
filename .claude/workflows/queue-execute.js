export const meta = {
  name: 'queue-execute',
  description: 'Run a /queue task batch: create worktrees, execute task-runner pipeline per task, push and open PRs for tasks that pass /cr. Tasks whose filesAffected fields share a file are automatically stacked — each branch cut from the previous one so they merge without conflicts.',
  phases: [
    { title: 'Setup', detail: 'Plan stacking, create worktrees for independent tasks' },
    { title: 'Execute', detail: 'Run task-runner per task; stacked groups run serially, others in parallel' },
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
if (!tasks || tasks.length === 0) {
  return { summary: { total: 0, done: 0, blocked: 0, prsOpened: 0, prsFailed: 0 }, taskResults: [], prResults: [] }
}

// ── Stacking helpers ─────────────────────────────────────────────────────────
// Parse a filesAffected string into a Set of trimmed, non-empty paths.
// "N/A", "", or whitespace-only returns an empty Set (task is never stacked).
function parseFiles(filesAffected) {
  const s = (filesAffected || '').trim()
  if (!s || s.toUpperCase() === 'N/A') return new Set()
  return new Set(s.split(',').map(f => f.trim()).filter(Boolean))
}

// Group tasks into connected components by shared file paths, then split into
// multi-task stacks (groups with 2+ tasks) and single independent tasks.
// Order within each component follows input array order.
function computeStacks(taskList) {
  const parent = taskList.map((_, i) => i)
  function find(i) {
    if (parent[i] !== i) parent[i] = find(parent[i])
    return parent[i]
  }
  function union(a, b) { parent[find(a)] = find(b) }

  const fileSets = taskList.map(t => parseFiles(t.filesAffected))

  for (let i = 0; i < taskList.length; i++) {
    if (fileSets[i].size === 0) continue
    for (let j = i + 1; j < taskList.length; j++) {
      if (fileSets[j].size === 0) continue
      for (const f of fileSets[i]) {
        if (fileSets[j].has(f)) { union(i, j); break }
      }
    }
  }

  const groups = new Map()
  for (let i = 0; i < taskList.length; i++) {
    const root = find(i)
    if (!groups.has(root)) groups.set(root, [])
    groups.get(root).push(taskList[i])
  }

  const stacks = []
  const independent = []
  for (const group of groups.values()) {
    if (group.length >= 2) stacks.push(group)
    else independent.push(group[0])
  }
  return { stacks, independent }
}

// Build a map from slug -> previous slug for non-first stack members.
// Used in the Push phase to set --base on stacked PRs.
function buildPrevSlugMap(stacks) {
  const map = {}
  for (const group of stacks) {
    for (let i = 1; i < group.length; i++) {
      map[group[i].slug] = group[i - 1].slug
    }
  }
  return map
}

const TASK_RESULT_SCHEMA = {
  type: 'object',
  required: ['taskSlug', 'status', 'branch'],
  properties: {
    taskSlug:         { type: 'string', pattern: '^[a-z0-9][a-z0-9-]*$' },
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

// ── Compute stacking plan ────────────────────────────────────────────────────
const { stacks, independent } = computeStacks(tasks)
const prevSlugMap = buildPrevSlugMap(stacks)

// ── Phase 1: Setup + Execute ─────────────────────────────────────────────────
// Independent tasks: create their worktree then run task-runner immediately.
// Stacked groups: serial loop — create worktree A, implement A, create worktree B
// (based on feat/A's tip), implement B, etc. A failure mid-stack aborts the group.
// All groups (independent and stacked) run concurrently via parallel().
phase('Setup')
if (stacks.length > 0) {
  const planLines = stacks.map(g =>
    `  stack: ${g.map(t => t.slug).join(' -> ')}`
  ).join('\n')
  log(`Stacking plan (${stacks.length} group(s) run serially within each group):\n${planLines}`)
}

phase('Execute')
log(`Running ${tasks.length} tasks (${independent.length} independent, ${stacks.reduce((n, g) => n + g.length, 0)} in ${stacks.length} stack group(s))`)

function createWorktreePrompt(task, baseRef) {
  const baseNote = baseRef
    ? `Base the new branch on feat/${baseRef} (not HEAD): pass it as the third argument.`
    : 'No base-ref needed — branch off HEAD as normal.'
  return `Create a git worktree for task "${task.slug}". ${baseNote}
From the repo root, run:
bash scripts/worktree-add.sh .claude/worktrees/${task.slug} feat/${task.slug}${baseRef ? ` feat/${baseRef}` : ''}

The script is idempotent — if the worktree already exists it exits 0 immediately.
Report "created" or "already exists" on success, or the exact error on failure.`
}

function executeTaskPrompt(task) {
  return `You are implementing a single scoped task. Follow .claude/agent-contract.md exactly.

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
STOP AND SURFACE: per .claude/agent-contract.md`
}

// Treat every task as a group: independent tasks become single-element groups.
// This unifies the execution path — the same serial loop handles both cases.
const allGroups = [...independent.map(t => [t]), ...stacks]

const allResults = await parallel(
  allGroups.map(group => async () => {
    const results = []
    for (let i = 0; i < group.length; i++) {
      const task = group[i]
      const baseRef = i === 0 ? null : group[i - 1].slug

      await agent(createWorktreePrompt(task, baseRef), { label: `worktree:${task.slug}`, phase: 'Setup' })

      const result = await agent(executeTaskPrompt(task), {
        agentType: 'task-runner',
        label: `task:${task.slug}`,
        schema: TASK_RESULT_SCHEMA,
        phase: 'Execute',
      })

      if (!result || result.status !== 'done') {
        const reason = result ? result.status : 'agent returned null'
        const remaining = group.slice(i + 1).map(t => t.slug)
        if (remaining.length > 0) {
          log(`Stack group aborted at "${task.slug}" (status: ${reason}). Skipping: ${remaining.join(', ')}`)
        }
        if (result) results.push(result)
        break
      }
      results.push(result)
    }
    return results
  })
)

const taskResults = allResults.filter(Boolean).flat()

// ── Phase 3: Push ────────────────────────────────────────────────────────────
// Open PRs for tasks that completed successfully. Sequential — scripts/pr.sh
// reads and deletes .cr-ok; concurrent calls on the same worktree would race.
// Stacked tasks (non-first in their group) target feat/<prevSlug> as PR base
// so the diff shows only that task's own changes.
phase('Push')
const doneResults = taskResults.filter(r => r && r.status === 'done')
log(`${doneResults.length} of ${tasks.length} tasks done — pushing and opening PRs`)

const taskBySlug = new Map(tasks.map(t => [t.slug, t]))
const prResults = []
for (const result of doneResults) {
  const task = taskBySlug.get(result.taskSlug) ?? { title: result.taskSlug }
  const prevSlug = prevSlugMap[result.taskSlug]
  const baseArg = prevSlug ? ` \\\n     --base feat/${prevSlug}` : ''

  const pr = await agent(
    `Push branch and open a GitHub PR for task "${result.taskSlug}".

Steps (run in order):
1. cd .claude/worktrees/${result.taskSlug}
2. Confirm .claude/.cr-ok exists and contains "feat/${result.taskSlug}:<sha>".
   If missing or wrong, report status: "skipped" with failureReason explaining why.
3. git push -u origin feat/${result.taskSlug}
4. bash scripts/pr.sh \\
     --title "feat(${result.taskSlug}): ${task.title}" \\
     --body "$(cat .claude/compound-draft-${result.taskSlug}.md 2>/dev/null || echo 'Automated /queue task — see task-runner summary.')"${baseArg}

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
