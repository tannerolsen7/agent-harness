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

## learning-loop-read-back-and-ratchet

**What:** Wire the harness to read its own task output after a run and keep its knowledge docs current, plus catch broken cross-links in those docs before they rot.

**When to use:** Any project where context docs (CONTEXT.md, AGENTS.md, patterns-registry.md, PITFALLS.md, memory.md) must stay true to the code, and where the same review finding keeps showing up across PRs.

**When NOT to use:** A throwaway project with no long-lived context docs. A one-shot script with no review pipeline. Do not reach for the ratchet on a finding seen once — it earns a rule only after it recurs (Occurrences ≥3) or is judged high-impact.

**The recipe:**
1. **`/cr` skill (`.claude/skills/cr/SKILL.md`)** — Step 3b reads `docs/RECURRING-FINDINGS.md`, gives each finding a stable signature, and counts occurrences across PRs. Step "Promotion candidates" promotes any finding at Occurrences ≥3 (or judgment-flagged) into a `PITFALLS.md` entry and moves it Active → Promoted. This is the finding→enforcement ratchet: a trap seen three times stops being a per-PR note and becomes a rule the gate checks every time.
2. **`@doc-updater` agent (`.claude/agents/doc-updater.md`)** — the read-back step. After a task, the agent reads its own diff back against the context docs and proposes corrections for any doc that now describes the old behavior. It writes proposals to a draft (`.claude/compound-draft-<slug>.md`) for human review at PR time — never a direct edit, because a wrong "fix" to canon is worse than stale canon.
3. **`docs/RECURRING-FINDINGS.md`** — the cross-PR ledger. Active findings carry a signature, occurrence count, last-seen date, and locations; promoted ones move to a Promoted section. This is the state the ratchet reads and writes.
4. **`scripts/check-integrity.sh` + CI (`scripts/ci-verify.sh`)** — the reference-integrity check. It scans markdown docs for broken relative cross-links (a `[text](./x.md)` whose file is gone) and fails the PR before a reader hits the dead link. It skips external links, pure anchors, template placeholders (`<…>`), fenced code blocks, and inline-code spans. Wired into `ci-verify.sh` so it runs server-side on the PR's exact commit.

**Golden exemplar:** `scripts/check-integrity.sh` + `tests/check-integrity.test.sh` (the check + its hermetic tests); `.claude/agents/doc-updater.md` (the read-back agent).
**Established by:** feat/learning-loop-integrity (V2-TRACEABILITY.md → Phase 2 — the learning loop row).
**Gotchas:**
- The integrity check skips links inside inline code spans (backtick-wrapped) on purpose. Docs that *describe* another file's link format (e.g. how an external memory index looks) would otherwise trip a false positive on a file that does not live in this repo.
- The check verifies only the file half of a `path#anchor` link, not the heading anchor. Verifying anchors needs a full markdown parse and produces false positives on cased or generated headings; the file-exists check is the high-value, low-noise part.
- The ratchet's count lives in `RECURRING-FINDINGS.md`, not in the agent. If that file is reset, the count resets — promotions are driven by the ledger, so keep it under version control.
- `@doc-updater` proposes; it never writes canon directly. The draft-then-human-review boundary is the whole point: an agent editing PITFALLS.md or CONTEXT.md unattended can entrench a wrong claim.

---

## preflight-structural-guard

**What:** Add a structural pre-flight check to both the review skill and the PR script so that a branch cannot be reviewed or a PR opened if a structural precondition fails.

**When to use:** When a check must fire before any review work begins AND again as a last-resort gate before the PR opens. The canonical example is merge-conflict detection: checking in the review skill blocks wasted review effort; checking again in `pr.sh` covers the window between review and PR open.

**When NOT to use:** Content/quality checks (logic correctness, test coverage) — those belong in the analytical review passes, not Pre-flight. Also not for checks that only matter at one stage — if the check is only meaningful at PR time, put it in `pr.sh` only.

**The recipe:**
1. **Review skill (`.claude/skills/cr/SKILL.md`)** — Add a `## Pre-flight — <name>` section before `## Step 0`. The section must: (a) run its check, (b) hard-block with a clear message if it fails, and (c) explicitly say "Do not run any passes. Do not write the sentinel." if it blocks. No sentinel is written when Pre-flight fails.
2. **PR script (`scripts/pr.sh`)** — Add the same check after the remote-branch precondition (around line 78, `git ls-remote`) but BEFORE the sentinel is consumed (around line 112, `mv "$SENTINEL" "$CONSUMED"`). On failure: exit non-zero, leave the sentinel intact. The ordering is the invariant: precondition first (proves the branch exists remotely), then this check (structural gate), then sentinel consumption (certifies the whole flow ran).
3. **Tests (`tests/pr-host-agnostic.test.sh`)** — Add TWO test cases for the new check: (a) the failure path (check fires, pr.sh exits non-zero, sentinel intact), and (b) the passing path (check is clean, pr.sh exits zero). A one-sided test that only covers the failure path will miss a regression that blocks all branches.
4. **`docs/TESTING.md`** — Add confirmed-behavior entries for both paths, under a section for the relevant script.

**Golden exemplar:** Pre-flight section in `.claude/skills/cr/SKILL.md` + merge-conflict block in `scripts/pr.sh` (lines 83–97) + two test cases in `tests/pr-host-agnostic.test.sh` (lines 93–159).

**Established by:** PR #68 (feat/merge-conflict-detection). See [solution doc](./solutions/2026-06-17-merge-conflict-preflight-guard.md).

**Gotchas:**
- The ordering in `pr.sh` is a hard invariant: precondition → this check → sentinel consumption. The sentinel must be the last thing consumed; any earlier check that fails must leave it intact so the user can fix and retry without re-running `/cr`.
- Always add a passing-path test alongside the failing-path test. If only the failure path is tested, a regression that blocks all branches will look green.
- The Pre-flight section in SKILL.md describes what an LLM agent should do. The shell code in `pr.sh` runs unconditionally. Keep them conceptually in sync but don't try to DRY them — they serve different contexts (LLM prompt vs. shell execution) and have different error-message requirements.

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
