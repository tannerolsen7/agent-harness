---
name: feature
description: |
  Guides the user through a complete feature development workflow,
  orchestrating discovery, planning, implementation, and review steps sized to
  feature complexity. Use when adding any new capability — net-new or incremental.
  Use when the user says "new feature", "build X", "implement X", "plan a feature",
  "add X", "wire up X to Y", "hook up X", "I want the app to do Y", "can you also
  add", "let's work on [task]", "let's tackle [task]", "get X working", or
  invokes /feature. Also use when /debug has produced a confirmed root cause and
  the user says "fix it", "fix the bug", or "make it work" — that is the Tiny path:
  root cause known, fix is code-only. Enter at Tiny: confirm behavior, record it
  in TESTING.md, implement, review. Skip the design contract and discovery phases.
---

# Feature Pipeline

> **Upstream skills:** `/grill-with-docs`, `/tdd`, and `/to-issues` are vendored in
> this harness (`.claude/skills/`). `/simplify` is a harness built-in — it ships with
> Claude Code itself. Every skill this pipeline calls must resolve before the pipeline
> starts. **A missing pipeline skill is a hard stop, not a skippable step:** report
> which skill failed to resolve and stop. Skipping a step because its tool "seems
> missing" is how decomposition and simplification silently disappear from the line.

## Tracer bullets (read before proceeding)

When building features, build a tiny, end-to-end slice of the feature first,
seek feedback, then expand out from there.

Tracer bullets come from The Pragmatic Programmer. When building systems, you
want to write code that gets you feedback as quickly as possible. Tracer bullets
are small slices of functionality that go through all layers of the system,
allowing you to test and validate your approach early. This helps identify
potential issues and ensures the overall architecture is sound before investing
significant time in development.

This is why /tdd enforces vertical slices and this skill enforces sizing.
AI's natural inclination is to build horizontal layers in isolation. You are
here to enforce the opposite.

## Anti-rationalization (read before proceeding)

| Rationalization | Rebuttal |
|---|---|
| "This is too small to need /grill-with-docs" | Tiny features still have hidden assumptions. /grill-with-docs takes 5 minutes. A wrong assumption takes hours to fix. Run it. |
| "The task is clear, sizing isn't needed" | Sizing exists because tasks are never as clear as they appear. Stating the estimate takes 2 minutes. |
| "I'll write the TESTING.md entry after" | There is no after. Spec before test. Test before code. This is the order. |
| "The plan is obvious, I don't need approval" | The plan phase exists because what seems obvious may be wrong in ways not yet considered. It rides the approval packet — it costs no extra round-trip. Get approval. |
| "Drafting the design before the human approves anything wastes work" | Agent drafting is cheap; human round-trips are the scarce resource. If the human rejects a draft at the packet, revising it costs minutes. Three separate waits cost more than one rejected draft. |
| "We're already mid-implementation, /to-issues would interrupt the flow" | The human asking "did you use /to-issues?" is the interrupt. Stop. Run /to-issues. A process question from the human is not rhetorical — it is a direct instruction. Momentum is not a reason to skip a step; it is how steps get skipped. (observed in practice) |

---

## Presenting decisions to the human

Every step below that asks the human to size, approve, or confirm something
must do three things. The goal is not to dumb the information down — it's to
make it as easy as possible to read, understand, and decide on:

1. **Full context first.** State what's being decided and why it matters, in
   one message. Don't make the human scroll back through the conversation to
   piece it together.
2. **Plain words — teachable, not dumbed down.** 8th/9th-grade English. If a
   technical term really is the clearest word, say the plain-English effect
   *before* using the term — see `CLAUDE.md` (repo root) → "Communication
   voice." The bar: could the human explain this back to a colleague and
   answer a follow-up question about it, confidently? If not, simplify the
   language further — never cut real information to get there. This applies
   to every decision point in this pipeline: the approval packet, the
   `/to-issues` list, and the final report.
3. **Leave the door open.** Close with something like "ask me to explain any
   part of this before you decide." A summary the human can't question is a
   rubber stamp, not a decision.

**Choosing how to ask.** For a small set of discrete choices — size, approve
vs. reject, pick one of a few options — use `AskUserQuestion`; it renders as
clickable options and already has a built-in escape hatch (the human can
always answer "Other" with free text instead of picking a preset). One
`AskUserQuestion` call holds up to four separate questions — this is what
makes the approval packet below a single round-trip instead of three. For
anything the human needs to actually read before deciding — a spec, an
interface, a full report — present it as prose or a document *first*, then
follow with the structured ask; a structured question can't hold that much
content.

See `/design contract`'s own "Presenting decisions to the human" section for
the same rule applied to the Design Questions sheet.

---

## Step 0 — Size the feature first

Estimate scope before doing anything else:

| Size | Behaviors | Pipeline |
|---|---|---|
| Tiny | 1 | Confirm → TESTING.md → /tdd → Ship sequence |
| Small | 2–5 | /design contract → /grill-with-docs → behavior spec → interface plan → approval packet → /tdd → Ship sequence |
| Medium | 6–15 | product spec → /design [explore →] contract → /grill-with-docs → behavior spec → approval packet → /to-issues → /tdd → Ship sequence |
| Large | 16+ | product spec → /grill-with-docs → behavior spec → /to-issues → /feature on each issue |

Before proceeding to any size tier, fill a contract for each sub-agent
this feature will spawn. Use .claude/agent-contract.md as the template.
A contract must exist before a sub-agent is invoked — never spawn without one.

**State your estimate, then keep moving — do not stop and wait for a separate
size confirmation.** Say what the size actually changes for the human, not just
the label — e.g. "this is Small, so I'll draft the design and check everything
with you in one review before I touch any code." The size gets its human yes
inside the approval packet (Small+) or the behavior confirmation (Tiny). If the
human corrects the size there, re-route to the right tier before implementing —
the drafting work is cheap to redo; a wrong-sized pipeline is not.

---

## Step 0.5 — Create a dedicated worktree

Before writing any spec, test, or code, create an isolated git worktree for this
feature. Working in the main worktree risks branch conflicts with concurrent workflow
agents and background hooks that may switch the main worktree's branch mid-session.

Determine the slug for this task from its name — lower-case, hyphens instead of
spaces, e.g. `rate-limiter` for a feature called "Add Rate Limiter". If you are
already on `feat/<slug>`, `bash scripts/derive-slug.sh` reads it from the branch.
Otherwise, set it directly from the task name.

```sh
SLUG=<slug>   # e.g. "rate-limiter" — not "main" or the name of another branch
bash scripts/worktree-add.sh .claude/worktrees/"$SLUG" feat/"$SLUG"
```

Then `cd .claude/worktrees/"$SLUG"` and do all subsequent work from there — every
commit, file edit, and gate check must happen inside the worktree, not in the main
worktree.

The script is idempotent: if the worktree already exists (e.g. on resume), it exits 0
and skips creation.

**Remote sessions.** When the environment supplies a designated branch (a managed
remote session — fresh container, freshly cloned repo, one branch to develop and
push), the container itself is the isolation: no concurrent agent or background
hook can switch branches under you. Skip this step, stay on the designated
branch, and never rename it. Worktree isolation protects a *shared local
checkout*; an ephemeral single-branch container has nothing to protect. Every
other gate in this pipeline — design confirmation, `/cr`, lint, tests — still
applies unchanged. (The commit/push hooks currently assume a local checkout and
can block remote sessions; the hook-side fix is tracked in TASKS.md under
"Remote session support in commit/push gates".)

---

## The approval packet — one pre-code decision point (Small+)

The pipeline's human gates are correct; separate blocking waits for each one are
the waste. A Small feature does not need three round-trips (size, design
sign-off, plan approval) minutes apart — it needs one well-prepared decision
point. So: **draft everything first, then ask once.**

Draft without blocking: the design contract, the grill findings folded back in,
the behavior spec, and the interface plan (Small). Then present the whole packet
and ask for approval in **one `AskUserQuestion` call**, with these as separate
questions inside it:

1. **Size** — "I sized this as Small (2–5 behaviors); is that right?" Fold this
   into the design sign-off question if the four question slots run out.
2. **Schema** (only if the feature touches the database) — the exact proposed
   migration SQL and Zod boundary schema. The schema always gets **its own
   question**: a "looks fine, keep going" on the whole packet is not schema
   approval. It is the least-reversible decision in the system.
3. **Design sign-off** — the Design Questions sheet, post-grill, plus the mockup
   look if the feature has a screen.
4. **Interface plan** — what goes in, what comes back, what happens when
   something goes wrong.

Present the documents as prose *before* the structured ask (a question box can't
hold a design sheet), per "Presenting decisions to the human" above. The open
questions the robot must not answer (section 3 of the design sheet) ride along
in the same message.

**On approval:** commit the design artifacts (sheet, contract, migration,
mockup, spec), then write the sentinel:

```bash
bash scripts/design-confirm.sh
```

**On rejection or size correction:** revise the drafts or re-route to the right
tier, then present a fresh packet. Never proceed on a partial yes.

Medium keeps exactly one more gate after this: the `/to-issues` decomposition
list (presented together with the interface plan), because decomposition
genuinely depends on the first approval. Nothing else in the pipeline blocks on
the human.

This batches `/design contract`'s per-item asks (schema, mockup, sheet) into one
round-trip. The ordering rule is unchanged — everything is still approved before
any code is written — only the number of waits shrinks.

---

## Implementation gate — design-confirmed sentinel (R4-D4)

**Before any feature code is written, the Implement step checks the
`design-confirmed` sentinel and refuses to start if it is absent or stale.** This
is the hard stop that makes the before-coding gate real: the approval packet
writes `.claude/.design-confirmed` via `scripts/design-confirm.sh`; this gate
reads it. Same pattern as the `/cr` push sentinel — no sentinel, coding stops.

**Applies to Small+.** Tiny features are exempt (one obvious behavior, no new data
shape, no new screen — they skip `/design contract`). If a "Tiny" task turns out to
touch the database or add a UI screen, it is not Tiny: escalate it to Small and run
the design gate before coding.

At the top of the **Implement** step (Small and Medium tiers), run the gate
before the first line of code:

```bash
bash scripts/implementation-gate.sh
```

The script checks that the sentinel exists, names the current branch, and that
its sha is an ancestor of HEAD — tolerating intermediate pre-coding commits
(spec, plan, grill docs) without requiring a re-confirmation. On failure it
prints the exact remediation. The gate lives in a script, not inline bash in
this file, because copy-pasted enforcement logic can be mistyped — and a
transcription slip fails open silently. (Tests: `tests/implementation-gate.test.sh`.)

This check runs **once**, at the very top of the Implement step, before the
first `/tdd` call. It is not re-evaluated between issues. The `.design-confirmed`
sentinel is **not consumed** (unlike `.cr-ok`, which pr.sh deletes after reading) —
it persists until overwritten by the next `design-confirm.sh` run.

If the gate fires, **stop and surface the script's remediation output** — do not
write code, and do not write the sentinel yourself to get past the gate (writing
`.claude/.design-confirmed` directly to unblock coding is the same violation as
hand-writing `.cr-ok`; a design not confirmed through the gate is unconfirmed).
The fix is to run `bash scripts/design-confirm.sh` only after the human has
approved the packet.

---

## Tiny (1 behavior)

1. **Confirm** the expected behavior with the user, stating the Tiny size in the
   same message — this is Tiny's single decision point.
   - **If this touches the database or adds a UI screen, it is not Tiny** — escalate to Small and run the design gate. Tiny is exempt from the design-confirmed sentinel only because it has no new data shape and no new screen.
2. **Record** it in `docs/testing/<slug>.md` under confirmed behaviors before writing any code (run `bash scripts/derive-slug.sh` to get the slug from the current branch). Then commit the spec file before `/tdd` starts — stop if the file is missing:
   ```bash
   bash scripts/spec-commit.sh
   ```
3. **Implement** — invoke `/tdd` for the single slice (contract required)
4. Run the **[Ship sequence](#ship-sequence-all-tiers)**.

---

## Small (2–5 behaviors)

1. **Orient** — read .claude/memory.md, skim docs/solutions/README.md, check AGENTS.md open decisions. Report: any open decisions touching this task? Any relevant solutions already documented?
2. **Research check** — search `docs/research/` for files relevant to this feature's external dependencies. If a relevant file exists, read it before the design contract. If a gap exists and the feature touches an external API or new framework pattern, create a research file in `docs/research/[topic].md` before proceeding.
3. **Design contract** — invoke `/design contract`. If uncertain about the design, run `/design explore` first. Contract output goes into TASK-TEMPLATE.md before proceeding. The contract's human asks (schema, mockup, sheet sign-off) are **deferred to the approval packet** — draft everything now, ask once later.
4. **Grill** — invoke `/grill-with-docs` (contract required). Confirm scope, surface hidden assumptions, challenge design against `CONTEXT.md`. Doc updates get written here.
5. **Solutions check** — search `docs/solutions/` for relevant patterns before designing the interface.
6. **Behavior spec** — invoke `@spec-writer`. Include the design contract text and a summary of grill
   findings directly in the `@spec-writer` prompt — it cannot read the parent conversation.
   `@spec-writer` writes confirmed behavior entries to `docs/testing/<slug>.md` before touching code.
   Do not write TESTING.md entries inline — `@spec-writer` owns the format and the "never invent
   behaviors" rule. Wait for its summary (entries written + open questions) before proceeding.
   Then commit the spec file — stop if the file is missing:
   ```bash
   bash scripts/spec-commit.sh
   ```
7. **Interface plan** — read relevant source files and existing tests. Design the public interface: what goes in, what comes back, what happens when something goes wrong. Draft it — the human approves it in the packet, not here.
8. **Approval packet** — present size + schema (if any) + design sign-off + interface plan in one `AskUserQuestion`, per [The approval packet](#the-approval-packet--one-pre-code-decision-point-small). On approval: commit the artifacts, run `bash scripts/design-confirm.sh`.
9. **Implement** — run `bash scripts/implementation-gate.sh` first; refuse to code if it fails. Then invoke `/tdd` (contract required). Tracer bullet slice first.
10. Run the **[Ship sequence](#ship-sequence-all-tiers)**.

---

## Medium (6–15 behaviors)

1. **Orient** — read .claude/memory.md, skim docs/solutions/README.md, check AGENTS.md open decisions
2. **Research check** — search `docs/research/` for files relevant to external dependencies. Create a research file if a gap exists before designing anything.
3. **Product spec** — create `docs/specs/[task-slug].md` from the Medium+ spec template. Fill the user goal, user journey, edge cases, and DMMT audit section. Set `human-approved: false`. Approval happens in the packet — draft now, ask once later.
4. **Design** — invoke `/design explore` (if uncertain about the approach), then `/design contract`. Contract output goes into TASK-TEMPLATE.md. The contract's human asks are deferred to the packet.
5. **Grill** — invoke `/grill-with-docs` (contract required)
6. **Solutions check** — search `docs/solutions/` before designing anything
7. **Behavior spec** — invoke `@spec-writer`. Include the design contract text and a summary of grill
   findings directly in the `@spec-writer` prompt — it cannot read the parent conversation.
   `@spec-writer` writes confirmed behavior entries to `docs/testing/<slug>.md`. Do not write entries
   inline. Wait for its summary before proceeding.
   Then commit the spec file — stop if the file is missing:
   ```bash
   bash scripts/spec-commit.sh
   ```
8. **Approval packet** — present size + product spec + schema (if any) + design sign-off in one `AskUserQuestion`, per [The approval packet](#the-approval-packet--one-pre-code-decision-point-small). On approval: set `human-approved: true` in the product spec, commit the artifacts, run `bash scripts/design-confirm.sh`.
9. **Decompose** — invoke `/to-issues`. Apply decomposition checklist: tracer bullet first, label parallel vs. sequential, verify each slice independently shippable. Read CONTEXT.md, AGENTS.md, and existing tests, and draft the interface plan for the issue set (what goes in, what comes back, what happens when something goes wrong).
   **STOP. Do not proceed to Implement until the user has confirmed the issue list and the interface plan — present both together in one ask.** This is Medium's second and final gate; decomposition depends on the packet approval, which is why it cannot ride the packet itself. Present each issue as what it delivers for the user, not just a technical label, and invite questions before asking for confirmation. If the user asks "did you use /to-issues?" mid-implementation, that question is the instruction — stop, run /to-issues, get confirmation, then resume.
   After confirmation: identify which issues are independent. Spawn sub-agents for independent issues simultaneously — do not work sequentially through the list if issues have no shared dependency. State the parallel groupings explicitly before spawning.
10. **Implement** — run `bash scripts/implementation-gate.sh` first; refuse to code if it fails. Then invoke `/tdd` for each issue in order. Tracer bullet slice first. (contract required)
11. Run the **[Ship sequence](#ship-sequence-all-tiers)**.

---

## Large (16+ behaviors)

1. **Research check** — search `docs/research/` for relevant external dependencies. Create research files for any gaps before proceeding.
2. **Product spec** — create `docs/specs/[task-slug].md`. Must be human-approved before decomposition begins — state the size estimate, the user goal, and the journey in plain terms in the same ask, and invite questions before approval.
3. **Grill** — invoke `/grill-with-docs`
4. **Behavior spec** — invoke `@spec-writer`. Include the design contract text and a summary of grill
   findings directly in the `@spec-writer` prompt — it cannot read the parent conversation.
   `@spec-writer` writes confirmed behavior entries to `docs/testing/<slug>.md`. Do not write entries
   inline. Wait for its summary before decomposition.
5. **Decompose** — invoke `/to-issues`. Each issue maps to Small or Medium. The product spec's user journey is the reference for tracing issues back to user intent. Same gate as Medium's Decompose step: present each issue as what it delivers for the user, invite questions, and get explicit confirmation of the list before proceeding.
   After confirmation, fire the design gate once, here at top level: commit the artifacts (product spec, grill docs, behavior spec, issue list), run `bash scripts/design-confirm.sh`, then `bash scripts/implementation-gate.sh` — it must pass before any sub-`/feature` starts.
6. **Execute** — run `/feature` on each issue in dependency order. Sub-`/feature` calls do **not** run their own per-issue Implementation gate — `.design-confirmed` is gitignored and does not propagate into sub-worktrees. The gate fired once, at the end of the Decompose step above, and covers all issues. An issue that adds a data shape or screen the top-level spec never covered is new scope: stop and re-run the gate, don't code through it.

---

## Ship sequence (all tiers)

Every tier ends here — one copy of the shipping steps, so an update lands once
instead of once per tier. Run these in order after the last `/tdd` slice:

1. **Simplify** — invoke `/simplify` on all changed files. Then commit before `/cr`:
   ```bash
   SLUG=$(bash scripts/derive-slug.sh)
   git add -u
   git commit -m "style($SLUG): simplify" || echo "nothing to commit — skipping"
   ```
2. **Review** — invoke `/cr`. If the change touched auth/permissions/data boundary, also invoke `/cr-security`.
3. **Type check** — `npx tsc --noEmit` must exit zero
4. **Commit** — conventional commit format
5. **Compound questions** — ask the agent:
   - What was the hardest decision you made here?
   - What alternatives did you reject, and why?
   - What are you least confident about?
6. **Compound** — if a non-obvious pattern was introduced, invoke `/compound`
7. **Checklist** — only if the diff has runtime surface the automated suite doesn't exercise. See the [Manual checklist rule](#manual-checklist-rule) below for the condition and the procedure.
8. **Report** — deliver the [final report](#final-report-format).

---

## Manual checklist rule

A manual checklist exists to catch what the automated suite cannot see. It is
**conditional, not automatic**:

**Write one only when the diff has runtime surface the automated suite doesn't
exercise** — UI a human must eyeball, calls to external services, visual or
subjective checks, side effects on files or processes that no test asserts. A
pure utility function that is already fully unit-tested needs no checklist and
no agent spawn; the report says so instead:
`Checklist: not needed — automated suite covers the diff`.

When the condition is met, spawn a **fresh agent** — not the one that wrote the
code — to produce the manual verification output. The implementing agent must
not write the checklist itself; it hands off context and waits.

**What to pass the fresh agent:**
- The git diff for the branch (`git diff main...HEAD`)
- The confirmed behavior entries from `docs/testing/<slug>.md`
- The path to any existing `tests/manual-checklist.sh` (so it can see the established style)

**What the fresh agent produces:**
- `tests/manual-checklist.sh` — a runnable shell script that checks every behavior it can check automatically. Each item should be one `ok`/`no` assertion (follow the style in any existing checklist). Only include checks that genuinely require running the code or inspecting file state; do not pad with trivial checks.
- A short bulleted list (in its reply, not in the script) for anything it cannot automate — visual confirmation, subjective UX, external service calls, etc.

**Do not commit the script.** It is a one-time verification artifact for the human to run after the feature lands, not a permanent test. If the project already has a permanent test suite entry for the behavior, the checklist item should still exist as a quick sanity check, but the source of truth is the test suite.

---

## Final report format

Fill every slot in plain terms — a fellow engineer should be able to read this
once and know what shipped and what still needs a decision from them. End
with an open invitation to ask about anything above.

```
## /feature complete
Built: <one sentence>
Size: <Tiny | Small | Medium | Large>
Behaviors: <N confirmed behaviors added to docs/testing/<slug>.md>
Tests: <N tests written, what they cover>
Review: <code review ran; N issues found and already fixed>
Commit: <hash and short message>
Security tier: <ran | not required>
Checklist: <tests/manual-checklist.sh (run to verify); manual-only steps: <list>> OR <not needed — automated suite covers the diff>
Needs human: <list or "None">

Ask me to explain anything above in more detail.
```

---

## Done criteria

- (Small+) Design was confirmed before coding — the approval packet was approved, `.claude/.design-confirmed` was written via `scripts/design-confirm.sh`, and `scripts/implementation-gate.sh` passed
- All confirmed behaviors in `docs/testing/<slug>.md` (assembled into `docs/TESTING.md` automatically)
- All slices committed (test + implementation in same commit)
- All /to-issues issues closed — via `closes #N` in commit body (auto-closed on merge) or manually if the issue was partially addressed
- `/simplify` has run
- `/cr` clean (and `/cr-security` if security-sensitive code touched)
- CI passed — `scripts/pr.sh` polls checks after PR creation and exits non-zero on failure. If `/debug` commits a fix, re-run `/cr` to get a fresh sentinel, push, and re-run `scripts/pr.sh`.
- `npx tsc --noEmit` exits zero
- Checklist handled per the [Manual checklist rule](#manual-checklist-rule): written by a fresh agent (not the implementation agent) and not committed — or explicitly reported as not needed
- Final report delivered
- If non-obvious pattern introduced: `/compound` has run
- If feature changed a documented pattern: affected solution doc updated
- PITFALLS.md checked: if feature revealed new footgun, entry proposed
- Spec sync: if any spec assumption changed during build, TESTING.md and CONTEXT.md updated to reflect what was actually learned

---

## Worktree cleanup (after merge)

If this feature ran in a dedicated worktree (`.claude/worktrees/<slug>`), leave it in place while the
PR is open — review fixes may need it. After the PR **merges**, `scripts/prune-branches.sh` removes the worktree
and deletes the branch (it removes the worktree before the branch, since git won't delete a branch
that is still checked out). Run `prune-branches.sh` after merging, or rely on the session-start hook
(`.claude/hooks/session-start.sh`), which runs it each session. Never remove the worktree before the PR merges.
