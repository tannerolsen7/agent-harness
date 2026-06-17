# Orchestration Patterns — Skill, Agent, Workflow

*Universal patterns — adapt to your project.*

When a task requires multiple AI invocations, three orchestration tools exist in this harness.
Choosing the wrong one costs either token budget (over-engineering simple work) or reliability
(under-engineering work that needs recovery). This doc is the decision guide.

---

## The three tools

### Skill invocation

A skill is markdown instructions the model reads and executes step by step. The model is the
orchestrator — it decides how to execute each step and can exercise judgment at every point.

**Use when:**
- The human is present and may need to make decisions mid-flow
- The workflow pauses for approval (design sign-off, UX review, STOP AND SURFACE questions)
- The pipeline is 3–7 linear steps that compose naturally as skills
- Steps are qualitatively different in character (design → implementation → review)

**Examples:** `/feature`, `/hotfix`, `/debug`, `/migrate`, `/grill-with-docs`, `/design`

**Not for:** batch work the model executes while you're away, or anything that processes a list
of items in parallel.

---

### Agent tool (single subagent spawn)

A single specialist delegated one bounded task. The caller waits for one result and moves on.

**Use when:**
- One specialist is right for one scoped task (explorer for discovery, implementer for one TDD slice)
- The task is independent and the result is a single artifact (findings, a commit, a summary)
- No need to fan out over a list or process structured results in bulk
- The caller doesn't need recovery if this one call fails

**Examples:** spawning `@explorer` to map all callsites, `@implementer` for one confirmed behavior,
`@reviewer` to consolidate lens findings

**Not for:** processing a list of N items (use `pipeline()` in a Workflow instead of N Agent calls).

---

### Workflow script

A JavaScript script with deterministic control flow. `agent()`, `pipeline()`, `parallel()` calls
are explicit code — the orchestration layer is not model-driven. Individual `agent()` calls still
run a model, but the structure around them is a program, not prose.

**Use when:**
- Processing a list of 5+ items in parallel (files, tasks, findings, research questions)
- The run might be interrupted and must resume — `resumeFromRunId` restarts from the last
  completed `agent()` call, not from scratch
- Typed, structured results are needed from each agent (`schema:` option returns validated objects)
- Control flow depends on results: early-exit if nothing found, loop-until-dry, phase gating
- The run is overnight or background — human is not present to restart it

**Examples:** overnight task batch, `/spike` pipeline when expected to run long, `/cr` sweep over
a large diff, multi-pass research fan-out

**Not for:** interactive workflows where the human approves steps (Workflow has no pause-and-ask).

---

## Decision rules

```
Is the human present and making decisions mid-flow?
  → Skill

Am I delegating one bounded task to one specialist?
  → Agent tool

Am I processing a list of items, running overnight, or need recovery on failure?
  → Workflow script
```

More specific triggers for Workflow:

| Trigger | Why Workflow |
|---|---|
| "Run this overnight / while I'm away" | Must recover from API failure without manual restart |
| "Process all N items in this list" | `pipeline()` over N is cleaner and resumable vs N Agent calls |
| "I need structured typed results from each" | `schema:` option validates output; no parsing |
| "This might run for 30+ minutes" | Long runs are more likely to hit API timeouts |
| "Continue where we left off if this fails" | `resumeFromRunId` is the only recovery mechanism |

---

## Use cases in this harness

Where Workflow adds the most value, ordered by impact:

| Operation | Current approach | Workflow gain | When to switch |
|---|---|---|---|
| `/queue` Step 3+ (task batch) | Workflow (`queue-execute.js`) — pipeline() of task-runner agents with resumeFromRunId | Completed tasks return cached results on session restart; three phases: Setup (idempotent worktrees), Execute (pipeline), Push (sequential PR open) | Done — Workflow is the current implementation |
| `/spike` pipeline | spike-orchestrator (Opus agent) orchestrates sub-agents | Resumable multi-pass research; `resumeFromRunId` if session dies mid-pass | When the spike is expected to run 30+ min or involves 3+ research passes |
| `/cr` on a large diff | reviewer agent spawns 4 lens agents | Per-file structured findings; loop-until-dry over changed files; early-exit if 0 findings | When the diff exceeds ~30 files |
| `/deep-research` fan-out | Skill-driven web fan-out | Parallel fetches with structured citations; resume if interrupted; loop-until-N-sources | When research needs 10+ sources or multiple adversarial verification passes |

Operations that stay as Skills (human-present, interactive):

| Operation | Why it stays a Skill |
|---|---|
| `/feature` | Human approves design before code; interactive gates are the point |
| `/hotfix` | Time-critical, human present and deciding |
| `/debug` | Investigation requires human judgment at branch points |
| `/migrate` | Phase-gated by human sign-off; permanent-tier requires explicit approval |

---

## Anti-patterns

**Agent fan-out loop from a skill** — calling Agent N times in sequence or parallel from a skill
has no recovery. If the session dies at step 8 of 15, restart from 0. Use `pipeline()` in a
Workflow instead when N ≥ 5 or the run is overnight.

**Workflow for interactive tasks** — Workflow scripts have no pause-and-ask mechanism. If the
next step requires human input, you cannot pause a Workflow mid-run and resume after the response.
Use a Skill with an explicit STOP condition instead.

**Skill for overnight batches** — Skills that fan out agents have no `resumeFromRunId`. An API
dropout at 2am means the whole run is lost. If the human won't be present to restart, the work
belongs in a Workflow.

**Workflow for a single agent call** — `new Workflow(agent("do X"))` is overhead. A single
bounded task is an Agent tool call, not a Workflow.

**Overusing `parallel()` when `pipeline()` is correct** — `parallel()` is a barrier: every item
waits for the slowest one before the next stage starts. `pipeline()` lets each item advance
independently. Default to `pipeline()`; use `parallel()` only when stage N genuinely needs all
stage N-1 results together (deduplication, cross-item comparison, early-exit on total count).

---

## Workflow structure patterns

The patterns most useful in this harness:

**Batch over a list with recovery**
```js
const results = await pipeline(
  taskList,
  (task) => agent(`Implement: ${task.title}`, {
    subagent_type: 'task-runner',
    label: task.slug,
    schema: TASK_RESULT_SCHEMA,
  })
)
```
If the session dies at item 8, relaunch with `resumeFromRunId` — items 1–7 return cached results.

**Multi-pass with early-exit**
```js
const findings = await agent('Find issues', { schema: FINDINGS_SCHEMA })
if (!findings.items.length) {
  log('No findings — skipping verification')
  return { findings: [] }
}
const verified = await parallel(findings.items.map(f => () =>
  agent(`Verify: ${f.title}`, { schema: VERDICT_SCHEMA })
))
```

**Loop-until-dry (discovery)**
```js
const seen = new Set()
let dry = 0
while (dry < 2) {
  const found = await agent('Find more cases', { schema: CASES_SCHEMA })
  const fresh = found.cases.filter(c => !seen.has(c.id))
  if (!fresh.length) { dry++; continue }
  dry = 0
  fresh.forEach(c => seen.add(c.id))
}
```

---

## Related docs

- [11 · Skill Ecosystems](./11-skill-ecosystems.md) — which skills exist and how they compose
- [13 · Model Capacity Audit](./13-model-capacity-audit.md) — which model tier for which role
- [`docs/model-tier-audit.md`](../model-tier-audit.md) — per-agent model assignments
