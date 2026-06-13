# Principles

*Universal patterns — adapt to your project.*

The rules that govern everything else. These don't change with the stack.

---

## The compound engineering loop

```
Plan → Work → Review → Compound → Repeat
```

The first three steps are familiar. The fourth is where gains accumulate. Skip it and you've done traditional engineering with AI assistance.

**80% of thinking happens before and after code is written.** Plan and review are where the engineer's judgment lives.

---

## The stage ladder

| Stage | Description | Compound begins? |
| --- | --- | --- |
| 0 | Manual development | No |
| 1 | Chat-based assistance | No |
| 2 | Agentic with line-by-line review | No |
| **3** | **Plan-first, PR-only review** | **Yes ←** |
| 4 | Idea to PR, single machine | Yes |
| 5 | Parallel cloud execution | Yes |

Most developers plateau at Stage 2. Don't skip stages — each builds the mental models for the next.

---

## The 50/50 rule

50% building features. 50% improving the system.

Traditional teams do 90/10. The 10% is why codebases accumulate debt. An hour building a review agent saves 10 hours of review over a year.

**The ceiling:** 50/50 is a ceiling on system work, not a floor. Don't spend 80% improving the system — that's the Winchester Mystery House failure mode.

---

## The Winchester Mystery House

Don't get stuck building the tooling instead of the product. System work is an investment, not a destination.

**Signals you've crossed into the Mystery House:**

- Haven't shipped a feature in two weeks but built three new skills
- Refactoring the pipeline for a codebase with no tests
- Infrastructure is more sophisticated than the product it's serving

**The check:** when did you last ship something to a real user?

---

## Three questions before merging

1. **"What was the hardest decision you made here?"** — reveals where the tricky parts are
2. **"What alternatives did you reject, and why?"** — shows what options were considered
3. **"What are you least confident about?"** — gets the agent to admit where it might be wrong

Record answers in the task spec. If any answer reveals something surprising, address it before merging.

---

## Agent-native architecture

If a developer can see or do something, the agent should be allowed to too.

**Level 1 — Basic development (Stage 3 minimum):**

- [ ] File access and editing
- [ ] Run tests
- [ ] Git commits

**Level 2 — Full local (Stage 4):**

- [ ] Browser access (a browser-automation MCP or driver)
- [ ] View local logs
- [ ] Create pull requests

**Level 3 — Production visibility:**

- [ ] Production logs (read-only)
- [ ] Error tracking

**Level 4 — Full integration:**

- [ ] Issue tracker
- [ ] Deployment capabilities

---

## Destructive operation rules

**A real incident (2026):** An agent deleted a company's production database and all volume-level backups in seconds. It found an infrastructure-management token, assumed it was scoped, and called a delete operation. System prompts were present and ignored. The agent later enumerated every safety rule it had violated. Enforcement must live in process.

**Copy these verbatim into your project's primary agent rules file:**

```
- NEVER execute any destructive or irreversible operation without the user
  typing an explicit instruction to do exactly that operation on exactly that
  resource, in the same conversation turn.

- NEVER reuse an API key, token, or credential found in a file unrelated to
  the current task. Treat every credential as having root-level access.

- NEVER assume a credential is scoped to a specific environment, project, or
  operation. Most providers don't enforce least-privilege at the token level.

- NEVER treat "staging" as isolated from production without verifying the
  infrastructure boundary explicitly.

- Before any mutating external call: state (1) what resource this targets,
  (2) whether the operation is reversible, (3) the explicit user instruction
  authorizing it. If any of the three is uncertain, stop and ask.

- If you cannot answer "is this reversible?" with certainty, treat it as
  irreversible and stop.
```

See also → [12 · Anti-Rationalization Tables](./12-anti-rationalization.md) for the pre-written rebuttals that close the escape hatches on these rules.

---

## Manual work is always allowed

This system is opt-in at every step. You can write code by hand, commit manually, and push without involving any agent or skill. Nothing in this system gates a manual change, commit, or push.

The skills, pipelines, and workflow exist to improve the output of agentic work — not to block human work. If you're working manually, none of the agentic steps apply to you.

The one thing that doesn't change: code quality expectations. Good code is good code regardless of who wrote it.

---

## The discipline rule

Before any **AI-generated** code is committed, you must be able to answer:

1. What does this do, and why is it structured this way?
2. Where could this fail?
3. What would you change, and why?

If you cannot answer all three, do not commit. Stop and ask.

This is a supervision checkpoint, not a review checklist.

This rule applies only to AI-generated code. Manually written code has no required checkpoint.

---

## One-shot readiness checklist

The goal of the whole system. A feature is "one-shottable" when an agent can implement it correctly without back-and-forth, rework, or human correction mid-task.

Run this against any codebase. Score it honestly before adding more docs — docs don't help if the underlying codebase has competing patterns.

```
[ ] Boundaries clear
    Layer rules are documented AND followed in existing code.
    Not just in the agent rules file — in the actual files agents will read.
    Fail: stores call the database directly. Components contain business logic.
    Test: point to the layer rules doc AND confirm existing files follow them.
    Scripts/CLI repos: "boundaries" = mutation ownership. Which scripts are
    authorized entry points for writes to each data store? Document in the
    agent rules file → Layer responsibilities table (e.g. "setup script owns
    timing/setup/state — no other script writes there"). Fail: an orchestrator
    script writes to the data store directly. Test: point to the layer table
    AND confirm existing scripts follow it.

[ ] Patterns generalized
    Golden exemplars designated per layer.
    Agents know which file to replicate, not which to average across.
    Fail: 3 different patterns for the same thing exist in the codebase.
    Test: is there one canonical file per layer that new files should look like?

[ ] Context sufficient
    CONTEXT.md explains the domain without needing the code.
    A fresh agent can read it and understand entities, data flow, business rules.
    Fail: CONTEXT.md lists what exists but not why it's shaped that way.
    Test: could an agent answer domain questions from CONTEXT.md alone?

[ ] Skills exist
    /feature, /tdd, /cr wired and running on real tasks.
    Not just created — actually used and tuned.
    Fail: skills exist but aren't invoked, or invoked but skipped in practice.
    Test: run /cr on the last PR. Did it catch anything real?

[ ] Tech debt not in the way
    No Priority 1 competing patterns in actively-modified files.
    Fail: stores use two different patterns for data access.
    Test: look at your tech debt table. Any Priority 1 items in active files?
```

**Score:**

- 5/5 — ready to one-shot features
- 3–4/5 — one-shot rate is low in areas touching the gaps; fix the gaps
- <3/5 — adding more docs won't help; fix competing patterns first

**The counterintuitive rule:** you cannot document your way past competing patterns. If the codebase has both a correct pattern (in the agent rules file) and a violating pattern (in existing code), agents average across both. The fix is consolidation — eliminating the second way to do something until only one way exists. The strongest version of this discipline restructures the codebase around a single canonical pattern before adding any AI tooling.

---

## The context moat

The question to ask about every agentic setup you maintain:

**What's the opinionated context layer — and is it deliberate or accidental?**

**Generic:** the agent reviews the diff with no knowledge of the codebase's rules.

**Opinionated:** the agent is grounded in this codebase's decisions, standards, and prior failures.

**The test:** could a fresh agent generate code that fits the existing codebase's style without you correcting it? If yes, you have the moat. If no, the docs are decorative.

---

## AI- and human-friendly code

The best code for AI agents is also the best code for a tired engineer debugging at 2 AM. The properties are identical.

**File size is a hard constraint.** A file over 300 lines forces an agent to either load the whole thing to change 10 lines, read a chunk and miss context, or hallucinate what's in the parts it didn't read. Research consistently shows model correctness degrades when context fills — the degradation under heavy context fill is well-documented in agentic workflows. Keep files under 300 lines. If you're adding to a file already over 250, surface it as a split candidate before proceeding.

**One concept per file, not one class.** Vertical slicing (feature-scoped files) outperforms horizontal slicing (type-scoped files) for agents. An agent loading a single feature directory gets everything it needs without cross-directory jumps. An agent loading a type-scoped directory (all components, all types) still has to hunt for the logic, the types, and the tests.

**Explicit over clever.** Magic, convention-over-configuration, and inference all require the agent to have loaded the conventions. Explicit code the agent can read is always safer than inferred behavior it has to reconstruct. If you have to know a convention to understand a file, the file is not explicit enough.

**Return early, minimal nesting.** Deep nesting forces more intermediate state into the agent's reasoning while it parses the file. Return early reduces the mental model required — same reason it helps human readers.

**Naming as documentation.** Agents don't load adjacent files unless forced to. `processData` forces a file read. `computeLineItemTotal` doesn't. Name every function, variable, and type as if the reader has no surrounding context — because under heavy context fill, they often don't.

**Tests as ground truth.** The agent reads tests to understand intent. Tests that test the implementation (transcription tests) give false signal. Tests that test observable behavior give ground truth the agent can reason against — which is also the only kind of test worth having.

**Enforcement in `/cr`:** The correctness pass should flag any file over 300 lines touched in the PR. If it grew during this feature, surface it. If it was already large and you added to it, surface it as a split candidate. This is not optional review commentary — it's a first-pass item.

**Enforcement in the agent rules file:** Every project should have an explicit rule: *"No file in this codebase should exceed 300 lines. If you find yourself needing to add to a file already at 250+, surface it before proceeding."*

**Enforcement in `/improve-codebase-architecture`:** File size is a first-order candidate, same as shallow modules and coupling. Any file over 300 lines is automatically a friction candidate in the weekly scan.

---

## Deferred patterns (Stage 4+)

Patterns worth knowing but not worth implementing yet:

**Lazy-loaded guides** — Instead of one global config file, break it into topic guides that load only when relevant: "before working on dashboards, read guides/dashboards.md." Preserves context budget when the global config gets long. Worth revisiting when the global rules file feels like it's loading irrelevant context every session.

**Progressive disclosure / skill router** — A meta-skill that reads the task type and activates only the relevant skill, instead of loading all skills at session start. Prevents loading security-review context for a docs-only task. Worth revisiting at Stage 4+ when running many parallel agents who need to self-select workflows. The pipeline routing table in the agent rules file already handles lightweight routing for most cases.

**Compound automation** — A doc-updater agent runs `/compound` automatically after each task completes, on projects where the system is enabled. Produces a draft file for human review at PR time. The compound step then happens on every task by default rather than being manually invoked. See the workflow skills documentation for the full mechanic.

**Native async automations** — Some agent platforms now offer native async automations: higher-order prompts that run on a schedule or trigger so you wake up to PRs that are ready to merge. This is the native version of the async agent workflow your `/feature` skill plus agent contracts approximate manually. Worth experimenting with on a low-risk task before applying to production repos.

**CI auto-fix** — Some platforms file automatic fixes against failing PRs so the PR owner never sees a red X. The pipeline enforcement layer your pre-commit hooks and `/cr` pipeline approximate manually. Near-term evaluation item: enable on one low-risk project first, test whether it catches what `/cr` catches. Don't remove your custom pipeline until tested.

**Session-review memory** — Some platforms can review prior sessions automatically and create persistent memory files without a hook. This is the official version of the session-end hook described in the settings and permissions documentation.

**Tool portability** — The principles in this system are tool-agnostic; the mechanics are often tied to a specific tool. Skills are slash commands that don't exist across every agent tool. The gap to close: each skill needs a raw prompt section that can be pasted into any chat interface, the agent rules file should be the primary rules file (most major agent tools read it natively), and a `docs/prompts/` directory of tool-agnostic skill files makes the loop portable. The honest boundary: single-agent flow works in any tool that reads the agent rules file; full orchestration (parallel worktrees, sub-agents, handoffs) is currently specific to whichever tool supports it. Worth formalizing when the team expands or the primary tool changes.

---

## Eight principles — periodic pressure-test

Run this audit when doing a system review or before a major restructure. For each principle, the question is whether the system actively enforces it or just aspires to it.

| Principle | System mechanism | Gap |
| --- | --- | --- |
| 1. Everything comes back to impact | Winchester Mystery House check; 50/50 ceiling | No mechanism ties a shipped feature back to whether it mattered. Impact is assumed, not measured. |
| 2. Automate the repeatable | Memory, skills, feature loop; `/compound` captures patterns | Adaptation is still slower than it could be — a memory curator agent would help |
| 3. Raise the floor on quality | `/cr`, `/tdd`, pre-commit hooks | Strong. The pipeline is explicitly a floor, not just a ceiling. |
| 4. Go 10x deeper in your lane | Skills scoped to specific workflows | Worth auditing whether any skills are too broad to fire reliably |
| 5. Build in the open | Shared, reusable harness | Gate is several real installs passing the validation criteria |
| 6. Own the output | Discipline rule; compound questions before merge | Strong. The pre-grill and compound questions are explicit ownership checkpoints. |
| 7. Be trusted with data | Destructive-op protocol; `/cr-security`; data-access boundary enforcement | Strong. The credential rules and security review are structural, not advisory. |
| 8. Adapt as a team | PITFALLS.md, memory.md, RECURRING-FINDINGS.md | Adaptation happens but relies on manual promotion. A memory curator agent would close this. |

**The two persistent gaps:** impact measurement (Principle 1) and adaptation speed (Principle 8). Both are addressable with instrumentation and a memory curator agent, in that order.

**When to run this audit:** before any major system restructure, when the deferred-ideas list is being pruned, or when the last feature felt harder than it should have.

---

## What this system is not

It is not a silver bullet. Agents still make mistakes. The system catches more of them, more consistently, and ensures mistakes don't repeat. That is the actual goal.

It is not tool-specific. The patterns apply to any agent that reads project files. Tool-specific mechanics are noted where they differ.

It is not a one-time setup. The system is alive. It grows with the codebase. A system that hasn't been updated in three months is a system that has stopped compounding.

---

## Beliefs to let go

| Old belief | New reality |
| --- | --- |
| The code must be written by hand | The requirement is good code, not your keystrokes |
| Every line must be manually reviewed | If you don't trust the output, fix the system that produces it |
| Solutions must originate from the engineer | The engineer's job is to add taste — which solution fits this codebase |
| Code is the primary artifact | A system that produces code is more valuable than any individual piece |
| Writing code is the core job function | The job is shipping value. Planning, reviewing, and teaching the system all count |
| First attempts should be good | First attempts have a ~95% garbage rate. This is the process, not a failure |
| More typing equals more learning | Understanding matters more than muscle memory |
