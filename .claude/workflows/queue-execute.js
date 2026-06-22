import { execFileSync } from 'node:child_process'

// Resolve the repo root once so relative worktree paths work regardless of CWD.
const REPO_ROOT = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim()

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

// ── Slug validation ──────────────────────────────────────────────────────────
// Every task slug is interpolated into shell commands — for example
// "bash scripts/worktree-add.sh .claude/worktrees/<slug> feat/<slug>" plus the
// branch names and PR titles built later. A slug like "my-task --force" or
// "x; rm -rf ." would inject extra shell arguments or whole commands. Only
// lowercase letters, digits, and hyphens are safe. Check every slug up front
// and throw before any worktree is created, so a bad slug never reaches a shell.
const SLUG_RE = /^[a-z0-9-]+$/
function validateSlugs(taskList) {
  const bad = []
  taskList.forEach((t, i) => {
    const slug = t && t.slug
    if (typeof slug !== 'string' || !SLUG_RE.test(slug)) {
      const shown = typeof slug === 'string' ? `"${slug}"` : String(slug)
      bad.push(`task[${i}]: ${shown}`)
    }
  })
  if (bad.length > 0) {
    throw new Error(
      'Invalid task slug(s) — each slug must match /^[a-z0-9-]+$/ ' +
      `(lowercase letters, digits, hyphens only): ${bad.join(', ')}`
    )
  }
}
validateSlugs(tasks)

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

// Decide what base branch a PR should target, given the slug of the task it is
// stacked on (prevSlug) and the set of slugs whose branches were actually pushed.
//
// A stacked PR (task B on top of task A) should target feat/A so its diff shows
// only B's own changes. But that only works if feat/A was pushed. If task A
// landed commits and then failed /cr, it is never pushed and feat/A does not
// exist on the remote. GitHub only auto-retargets a stacked PR to main when its
// base branch merges — not when the base is rejected or was never pushed. So a
// PR left pointing at an unpushed feat/A would have a broken base forever.
//
// Returns:
//   base       — the branch to pass as --base, or null to use the repo default (main)
//   retargeted — true when we dropped a stacked base because its branch was not pushed
//   prevSlug   — the previous slug we wanted to stack on (for the warning message)
//
// An independent task (prevSlug == null) gets base: null and retargeted: false.
// A stacked task whose previous slug was pushed gets base: "feat/<prevSlug>".
// A stacked task whose previous slug was NOT pushed falls back to base: null and
// retargeted: true, so the caller can target main and post a warning comment.
function resolvePrBase(prevSlug, pushedSlugs) {
  if (!prevSlug) return { base: null, retargeted: false, prevSlug: null }
  if (pushedSlugs.has(prevSlug)) {
    return { base: `feat/${prevSlug}`, retargeted: false, prevSlug }
  }
  return { base: null, retargeted: true, prevSlug }
}

// ── Stacked-worktree ancestry guard ──────────────────────────────────────────
// A stacked task is built by asking a sub-agent to run worktree-add.sh with
// feat/<prevSlug> as the base ref. The agent could paraphrase or garble that
// command and create the worktree on the wrong base, which silently breaks the
// stack's git ancestry. Because the agent's report is not trustworthy, the
// workflow itself confirms feat/<prevSlug> is an ancestor of the new worktree's
// HEAD after the agent returns.
//
// verifyAncestry is pure so it can be unit-tested without a real repo. It takes
// isAncestorFn(worktreePath, ref) -> boolean and returns:
//   { ok: true }                       when the base ref is an ancestor
//   { ok: false, error: <message> }    when it is not (message names the branch
//                                       and worktree path so a human can see it)
function verifyAncestry(worktreePath, prevSlug, isAncestorFn) {
  const baseRef = `feat/${prevSlug}`
  if (isAncestorFn(worktreePath, baseRef)) return { ok: true }
  return {
    ok: false,
    error: `Stacked-worktree ancestry check failed: ${baseRef} is not an ancestor of HEAD in ${worktreePath}. The worktree-create agent likely ran the wrong base-ref. Aborting this stack group.`,
  }
}

// Real ancestry check: runs git in the new worktree. Returns true only when the
// command exits 0 (ref is an ancestor). Any non-zero exit or error (missing ref,
// bad worktree) is treated as "not an ancestor" so the guard fails closed rather
// than letting a broken stack proceed. Arguments go to execFileSync as a list,
// not a shell string — git is run directly, so a path or ref can never be read
// as a shell metacharacter even if a caller forgets to validate it.
function isAncestorViaGit(worktreePath, ref) {
  try {
    execFileSync('git', ['-C', worktreePath, 'merge-base', '--is-ancestor', ref, 'HEAD'], {
      stdio: 'ignore',
    })
    return true
  } catch {
    return false
  }
}

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

      // For a stacked task, confirm the new worktree really sits on top of the
      // previous branch before we let an implementer build on it. The agent's
      // report is not trusted — we run the git check ourselves. A broken base
      // here would silently produce merge conflicts later, so we abort the rest
      // of this stack group instead of continuing.
      if (baseRef !== null) {
        const worktreePath = `${REPO_ROOT}/.claude/worktrees/${task.slug}`
        const check = verifyAncestry(worktreePath, baseRef, isAncestorViaGit)
        if (!check.ok) {
          const downstream = group.slice(i + 1).map(t => t.slug)
          const skipNote = downstream.length ? ` Skipping downstream: ${downstream.join(', ')}` : ''
          log(`${check.error}${skipNote}`)
          break
        }
      }

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

// ── Phase 2: Push ────────────────────────────────────────────────────────────
// Open PRs for tasks that completed successfully. Sequential — scripts/pr.sh
// reads and deletes .cr-ok; concurrent calls on the same worktree would race.
// Stacked tasks (non-first in their group) target feat/<prevSlug> as PR base
// so the diff shows only that task's own changes.
phase('Push')
const doneResults = taskResults.filter(r => r && r.status === 'done')
log(`${doneResults.length} of ${tasks.length} tasks done — pushing and opening PRs`)

const taskBySlug = new Map(tasks.map(t => [t.slug, t]))
const prResults = []
// Track which slugs were actually pushed (PR opened). A stacked PR may only
// target feat/<prevSlug> if that previous task is in this set — see
// resolvePrBase for why an unpushed base would break the stacked PR forever.
const pushedSlugs = new Set()
for (const result of doneResults) {
  const task = taskBySlug.get(result.taskSlug) ?? { title: result.taskSlug }
  const prevSlug = prevSlugMap[result.taskSlug]
  const { base, retargeted } = resolvePrBase(prevSlug, pushedSlugs)
  const baseArg = base ? ` \\\n     --base ${base}` : ''

  // When a stacked task loses its intended base (the previous task was not
  // pushed), warn on the PR after it is created so a human knows the diff shows
  // this task plus the un-landed base, and the base needs sorting before merge.
  const retargetStep = retargeted
    ? `5. The base task "${prevSlug}" was not pushed, so this PR targets the default branch (main) instead of feat/${prevSlug}. After the PR is created, post a warning comment on it:
   gh pr comment <pr-url> --body "Note: this task was stacked on \`feat/${prevSlug}\`, but that base was never pushed (its /cr likely failed). This PR now targets the default branch, so its diff includes the changes from \`${prevSlug}\` as well. Review and re-base once \`${prevSlug}\` lands."`
    : ''

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
${retargetStep}
Report the PR URL and title on success, or the failure reason.`,
    { label: `pr:${result.taskSlug}`, schema: PR_RESULT_SCHEMA, phase: 'Push' }
  )
  if (pr) {
    prResults.push(pr)
    if (pr.status === 'pushed') pushedSlugs.add(result.taskSlug)
  }
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
