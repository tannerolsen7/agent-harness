# Patterns registry

Reusable, **multi-file** recipes — the canonical way to do a recurring thing that spans
several files in this codebase (R4-D25). The companion to the **golden exemplars** in
AGENTS.md: golden exemplars name one canonical *file* per layer to imitate; this registry
captures *recipes* that touch several files at once — e.g. "add a custom field," "subscribe
to a live data source," "add a new public endpoint."

<!-- context-meta
owner: <name>
last-reviewed: YYYY-MM-DD
review-frequency: on-merge
drift-signals:
  - file references that no longer exist
  - a recipe contradicted by a newer pattern or a changed golden exemplar
  - two entries describing the same recipe (should be merged)
-->

Read the relevant entry (just the one you need — not the whole file) before writing code that
matches a recipe here. Replicating the established pattern is how the codebase stays
consistent; inventing a second way to do the same thing is a review finding.

> Project-agnostic structure; the entries themselves are this project's own patterns. Starts
> empty and grows as features establish reusable recipes.

---

## How entries get added

Entries are written and updated by `/compound` after a feature merges (R4-D25). When a feature
introduces or changes a multi-file recipe worth replicating, `/compound` adds or updates the
entry here and links it from the feature's [feature doc](./feature-doc-template.md) →
"Patterns established."

Add an entry directly (outside `/compound`) only when a known recipe is identified that isn't
yet captured — same format.

**Do not add** single-file conventions (those are golden exemplars in AGENTS.md), one-off
solutions to a non-recurring problem (those are [`docs/solutions/`](./solutions/)), or generic
engineering advice.

---

## Entries

## resumable-overnight-batch-skill

**What:** Wire a skill to delegate long-running parallel work to a resumable Workflow, keeping interactive setup in the skill and unattended execution in the Workflow.

**When to use:** Any skill that runs N independent tasks overnight — where "session dies mid-run" is a real failure mode you want to recover from without re-running completed work.

**When NOT to use:** Tasks that require human decisions between items (use the skill directly, with interactive checkpoints). Single-task operations (overkill; just call `agent()` directly). Tasks where partial completion is worse than full restart.

**The recipe:**
1. **Skill (`.claude/skills/<name>/SKILL.md`)** — Steps 1–N are interactive. The final interactive step builds structured task objects (JSON) and calls `Workflow({ scriptPath, args: [tasks] })`. Steps after the Workflow call process its return value.
2. **Workflow (`.claude/workflows/<name>.js`)** — Three phases in order:
   - **Setup** — `parallel()` (a barrier): create one worktree per task with the idempotent `scripts/worktree-add.sh`. Parallel because all worktrees must exist before Execute starts, and creation is independent.
   - **Execute** — `pipeline()`: run one specialist agent (`agentType:`) per task. Tasks advance independently — task B can be in @reviewer while task A is still in @implementer.
   - **Push** — sequential `for...of`: push and open PRs for tasks with a valid sentinel. Sequential because `scripts/pr.sh` reads and deletes `.cr-ok`; concurrent calls on the same worktree race.
3. **Worktree script (`scripts/worktree-add.sh`)** — Add an idempotency guard at the top using `[ -f "$PATH/.git" ]` (see [2026-06-17-worktree-git-file-detection.md](./solutions/2026-06-17-worktree-git-file-detection.md)). This makes Setup safe to re-run on resume.
4. **Smoke test (`tests/harness-smoke.test.sh`)** — Assert the Workflow script file exists: `[ -f ".claude/workflows/<name>.js" ] || note "..."`. The skill silently breaks if the file is deleted.

**Golden exemplar:** `.claude/workflows/queue-execute.js` + `.claude/skills/queue/SKILL.md`.

**Established by:** PR #34 (feat/queue-workflow-specwriter-gates).

**Gotchas:**
- `resumeFromRunId` re-enters the Setup phase from the top — idempotent worktree creation is required, not optional.
- `pipeline()` in Execute, not `parallel()` — `parallel()` is a barrier (waits for all tasks) and kills the wall-clock benefit; `pipeline()` lets each task advance as fast as it can.
- Push must be sequential: `scripts/pr.sh` deletes `.cr-ok` on success; two pushes for the same task would race and one would fail validation.
- The Workflow has no pause-and-ask mechanism. Human approval of the task list must happen in the skill (Steps 1–2) before the Workflow is launched.

---

## Entry format

Copy this skeleton for each new recipe.

```markdown
## <recipe-slug-as-heading>

**What:** the recurring multi-file task this recipe covers (e.g. "add a custom field to X").
**When to use:** the situation that calls for this recipe.
**When NOT to use:** the look-alike cases this recipe does not cover.

**The recipe:**
1. <file or layer> — <what to add or change, and why>
2. <file or layer> — <what to add or change, and why>
3. <…>

**Golden exemplar:** <the canonical file(s) to copy from — link AGENTS.md → Golden exemplars
or the specific file>.
**Established by:** <feature-doc link> (PR #N).
**Gotchas:** <the non-obvious step people get wrong; link PITFALLS.md if it has a matching trap>.
```

---

## How this differs from neighboring docs

| Doc | Holds | Granularity |
|---|---|---|
| **This registry** | reusable recipes that span **several files** | multi-file, repeatable |
| AGENTS.md → Golden exemplars | one canonical **file** per layer to imitate | single-file, per-layer |
| [`docs/solutions/`](./solutions/) | how a specific **non-obvious problem** was solved once | one problem, point-in-time |
| PITFALLS.md | traps that produce silent bugs | a rule, not a recipe |

The line vs. `docs/solutions/`: a solution doc is a **point-in-time narrative** of how one
hard problem was solved (with root cause, what didn't work, why this approach fit). A registry
entry is a **forward-looking, replicable recipe** — the steps to follow next time you do this
multi-file task. A solution may *graduate* into a registry entry once the same shape recurs;
until then it stays a solution. The two never hold the same content: solutions explain a past
fix, the registry prescribes a repeatable procedure.
