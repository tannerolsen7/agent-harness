# V2 User Stories — How the Harness Is Actually Used, End to End

> **What this is.** Concrete, step-by-step journeys showing how a person (or a machine signal) gets work done
> through the V2 harness. Each story names: WHO/WHAT starts it · every step in order · where a HUMAN decides or
> approves · what gets produced · where it can fail · which harness parts do the work (skills / hooks / gates).
> The point is to make the design *legible as a sequence of events*, and — just as important — to surface what
> writing the sequences reveals we under-built (see "WHAT THESE FLOWS TEACH US" at the end).
>
> **How to read the harness vocabulary** (plain definitions, used throughout):
> - **Harness** — the whole bundle of skills, sub-agents, hooks, and gates an AI agent runs inside.
> - **Skill** — a named routine the agent runs (`/feature`, `/cr`, `/debug`). Slash-prefixed names are skills.
> - **Sub-agent** — a fresh AI worker spawned for one job (e.g. a reviewer), with its own clean context.
> - **Hook** — a small script the harness runs automatically at a fixed moment (before a tool runs, when a
>   session ends). The agent cannot talk a hook out of running — that's the point.
> - **Gate** — a checkpoint that must pass before work moves forward. Some gates are deterministic (a script
>   says yes/no); some are a human pressing approve.
> - **Worktree** — an isolated copy of the repo on its own branch, so two agent runs never step on each other.
> - **The verdict / `.cr-ok` sentinel** — the harness's record that review (`/cr`) ran and passed, written as
>   `branch:sha`. V1's flaw: it's a local file CI never sees. V2's fix (F6): CI re-checks it on the shipped
>   commit so it can't be faked.
> - **The built-in continuation loop** — Claude Code already has a primitive that runs an agent *until a
>   stopping condition is met* instead of stopping after every turn. V2 **uses this built-in** as the engine for
>   long runs; it does **not** build a new `/goal` skill to reinvent it. Where older drafts said "/goal," read it
>   as "the built-in continuation loop, driving one well-specified task until a separate grader says done."
>
> **Git-host-agnostic by design.** Nothing below assumes GitHub specifically. The trigger label, the
> canon-in-repo, the CI gate, and the plugin install all generalize across **your git host** (GitHub, GitLab,
> or another). Neutral words are used throughout: **pull/merge request (PR/MR)**, **CI pipeline**, **protected
> branch**, **issue/ticket**, **the host's label/automation system**.
>
> **Three ways in, on equal footing.** A person can start work from **(a)** a label on an issue/ticket in your
> git host, **(b)** a message in **Slack**, or **(c)** a command in **Linear**. None of these is "after" another.
> A bug report typed in Slack and a `fix-me` label on a ticket are two doors into the *same* routed pipeline.
> The only difference the design makes is a *safety* one (free-text channels carry an injection surface a label
> does not — see Story B and the floor notes), not a "first-class vs second-class" one.
>
> Citations point at `../../ambition/VISION.md` moves (L1, F6, …), the roster (`../roster.md`), and the
> git-host-usage design (`../github-usage.md`). Where a flow is currently underspecified, it says so plainly.

---

## The cast (who shows up in these stories)

- **Monica** — the floral designer the product serves. She never touches the harness; she's why "world-class"
  matters. She appears only as "the $30k client must not see a broken proposal."
- **The operator** — the one engineer running the fleet (this is the realistic V2 user: one person, many
  parallel agent runs across 5+ repos). The operator approves, course-corrects, and gets paged. The whole design
  exists to stop the operator from being the *dispatcher* for every piece of work.
- **A teammate / reporter** — anyone who notices a bug or wants a feature and says so in Slack, Linear, or a
  ticket. May not be technical.
- **The agent** — the AI doing the work inside a worktree. Interchangeable and cheap; the value is in the two
  *ends* around it (a good trigger, a trustworthy review), not the agent itself.
- **The fleet** — many agent runs at once. "Illegible without narration" (L7) is a fleet problem.

---

## STORY A — "I want a new feature" (spec-first, not code-first)

**The headline discipline:** a feature does NOT start with code. It starts by turning a rough request into a
**clear written spec** that a human approves *before any code is written*. This is what lets the output be
world-class instead of "technically works." (Moves: L1 trigger · `/design` + `/feature` · C6 the spec layer ·
F6 the verdict gate · L7 narration.)

### A.0 — Who/what starts it (three equal doors)

A teammate wants: *"Clients should be able to leave a comment on a specific line item in the proposal."* They can
kick this off any of three ways, all first-class:

- **Slack:** they type `/feature client can comment on a proposal line item` in the channel where product gets
  discussed.
- **Linear:** they create an issue and add it to the harness's intake (or type the summon command in a Linear
  comment).
- **Git host:** they open an issue/ticket and add the `feature` label (the host's automation fires on the label).

All three land at the same front door (**L1**, wired through **P4 "MCP-as-substrate"** — the entry point that
lets an outside event summon the agent into a worktree). The git-host label is the *lowest-risk* door (a label is
a controlled token, not free text); the Slack/Linear doors carry attacker-controllable free text, so they pass
through one extra safety gate (**F5**, the injection/trifecta gate) before routing. **That is the only
difference** — not which is "primary."

### A.1 — Triage: is this even a feature?

The front-door **classifier** reads the request and decides the downstream path:
- *Net-new behavior* → the **feature** loop (this story).
- *Something is broken* → the **incident/hotfix** subsystem (Story B / L6).
- *Deliberate change to existing-and-previously-correct behavior* → the **`/behavior-change`** skill (its
  test-inversion classifier protects callers who relied on the old behavior).

**HUMAN POINT #1 (implicit / fast):** if the request is ambiguous or smells like an open product decision, the
classifier does **not** guess — it surfaces a question to the operator and waits. (CLAUDE.md rule: never resolve
an open decision unilaterally.)

### A.2 — Spec FIRST: the request becomes a written contract

This is the heart of "not code-first." The agent runs **`/design`** in its `explore` mode and/or **`/feature`**,
which for any Medium+ feature is required to **write the spec before spawning any implementer**:

1. **`/design explore`** produces 2–3 options *with tradeoffs* (e.g. comment stored per-line-item vs per-section;
   realtime vs poll; who can see comments). It does NOT pick silently.
2. The chosen design is formalized into the **TASK-TEMPLATE handoff** — the cross-skill contract every downstream
   skill consumes (inputs, outputs, what it must NOT do, what "done" looks like).
3. **C6 — the per-feature behavioral contract** is written to `docs/specs/client-line-item-comments.md`, with
   three sections: **Behavior** (what it must do, in plain language), **Implementation pointers** (where it
   lives), and **Verification** (executable steps that prove it still works). *This file is the durable answer to
   "what is THIS feature supposed to do?" — the thing that stops a cold-start agent six months later from
   silently breaking it.*

**HUMAN POINT #2 (the load-bearing approval):** the operator **reads and approves the spec** before any code.
This is a hard gate for Medium+ features (`human-approved` on the spec file). C6 also calls for an **independent
review pass on the spec itself** — because spec-first has no built-in adversary, a separate reviewer checks the
spec isn't quietly wrong or incomplete.

**Produced so far:** an options doc, a TASK-TEMPLATE contract, and an approved `docs/specs/<feature>.md`. No code
yet — on purpose.

### A.3 — Build, against the spec, test-first

With the spec approved, **`/feature`** sizes the work (Tiny/Small/Medium/Large) and runs the size-appropriate
pipeline of *other* skills. For a Medium feature that's roughly: `/design` (done) → tests-first via **`/tdd`** →
implement → **`/simplify`** → **`/cr`** → docs → opened PR/MR.

- **`/tdd`** writes failing tests derived from the spec's Verification section and `docs/TESTING.md` — never
  from reading the implementation (the no-transcription rule keeps the test an *oracle*, not a *mirror*).
- The **`@implementer`** sub-agent does one TDD slice per turn (one behavior → one test → one commit), reading
  the **golden exemplars** in AGENTS.md before writing each layer so the code matches house style.
- Independent issues can be built by **parallel** sub-agents in their own worktrees (the fleet primitive).

**HUMAN POINT #3 (only if triggered):** the agent **stops and surfaces** if it hits an open decision, an
ambiguity, or wants to install a new package (the "never install without asking" rule). Otherwise it keeps going.

### A.4 — Review (`/cr`), adversarially and against project canon

**`/cr`** runs: 9 analytical passes + an **adversarial 4-lens pass** where `@reviewer` fans out four isolated
sub-agents (assumption / composition / cascade / abuse), each attacking exactly one failure class, each given the
project canon (CLAUDE.md, AGENTS.md, PITFALLS, ADRs) but NOT the coder's reasoning (**C2** independence). A
**governance lens (C5)** checks the diff against locked ADRs, Rejected Patterns, and golden exemplars.

- MUST-FIX items are auto-fixed and re-reviewed.
- A finding that needs a *product/design* call (not a code fix) is routed as **needs-design-decision** →
  surfaced to the operator, not silently resolved.
- `/cr` writes its full **verdict** to a structured artifact and the `.cr-ok` readiness sentinel (`branch:sha`).

### A.5 — Open the PR/MR; the unforgeable gate

`scripts/pr.sh` consumes the readiness sentinel and opens the **pull/merge request** on your git host, posting the
verdict artifact onto it. Then the **F6 CI gate** (the keystone) runs in your **CI pipeline**: it **fails unless
the sentinel's SHA equals the head SHA AND all required checks (typecheck, lint, tests) are green**, and it's made
**required via protected-branch rules**. This is what stops a loop from "grading its own homework" — CI, a
*different authority*, re-checks the verdict on the exact shipped commit.

**HUMAN POINT #4 (merge):** a human reviews the opened PR/MR and merges. The agent is **never the last gate**
(even under auto-approval, LOOP-7 only auto-*approves* LOW-risk PRs into the CI floor; merge authority stays
human-or-deterministic-CI, never model judgment).

**Throughout (L7):** a **narration stream** tells the operator what's happening after each milestone
("spec written, waiting on your approval" → "tests written, implementing" → "`/cr` found 2 MUST-FIX, fixing" →
"PR opened: <link>"). The operator can watch and course-correct without being asked to drive.

### A.6 — Where Story A can fail

- **Spec skipped or thin.** If `/feature` doesn't enforce the spec-first gate for the right size class, you're
  back to code-first and quality drops. (Gap: see "Spec-first is only as strong as its trigger," below.)
- **Open decision guessed.** The classifier or implementer invents an answer instead of surfacing it → wrong
  product behavior shipped confidently. The stop-and-surface rules exist to prevent this; they're advisory until
  a human drives, so under full autonomy this leans on the bounded-loop REJECT path (F7).
- **Review blind spot.** If the reviewer shares the coder's blind spot, a confidently-wrong design passes. C2
  (independence) + C4 (calibration — measure `/cr`'s actual catch rate) are the defenses.
- **Spec drift later.** Someone changes the feature without updating `docs/specs/<feature>.md`. Nothing
  deterministic re-checks the spec's Verification on every change yet — that's the C6/C8 verify gate's job, and
  it's P1/P2, not day-0.

---

## STORY B — "I found a bug" (review at PR time, OR earlier if a human decision is needed)

**The headline discipline:** a bug is investigated to a *confirmed root cause*, a **failing test is written that
proves the bug**, then it's fixed — and review happens at PR/MR time **unless a human decision is needed earlier**,
in which case the flow **surfaces it immediately** instead of pushing forward. (Moves: L1 trigger · L6
incident/hotfix subsystem · `/debug` → `/feature` or `/hotfix` · F7 bounded-loop/REJECT · F6 gate.)

### B.0 — Who/what starts it (four doors, all equal)

- **Slack:** a teammate types `/fix proposals show the wrong subtotal when a discount is applied`.
- **Linear:** a bug issue is filed and summoned into the harness.
- **Git host:** an issue gets the `fix-me` label.
- **CI failure self-heal:** a required check goes red on a branch and *that event itself* summons an agent (with
  transient-vs-permanent triage first — a flaky network blip is retried, not "fixed").

All four enter at **L1**. The label and CI-failure doors carry the least free text; the Slack/Linear doors ingest
attacker-controllable text and so pass the **F5** injection gate first.

### B.1 — Classify: bug vs incident

A `fix-me` label or a CI-red is **often an incident**, not a plain feature-style fix. The classifier routes:
- *Production is broken / urgent* → **`/incident`** (the classify-first front door for "something is wrong").
- *A defect, not urgent* → **`/debug`** investigation.
- *Security signal detected* → **isolation-only short-circuit** — the incident-responder proposes *isolation
  only* and **stops**. It NEVER auto-fixes a security issue. (This is a non-negotiable safety boundary.)

`/incident` runs 6 evidence checks (including a PITFALLS.md short-circuit — "have we seen this before?"), assigns
an 8-type classification, and writes a **triage doc** (`.claude/incident-[slug].md`) that *travels to the
receiving skill and replaces its orient step* — i.e. `/hotfix` or `/debug` picks up where `/incident` left off
instead of re-investigating. This is the **L6 routed state machine** (incident → hotfix → migrate → post-mortem),
carried forward verbatim.

### B.2 — Investigate to a confirmed root cause (no fix yet)

**`/debug`** spawns **`@investigator`**, which:
1. Reproduces the bug (bounded by a retry cap — **F7**, so it can't spin forever).
2. Confirms the root cause as a specific `file:line` — not a guess.
3. **Writes a failing test that proves the bug** — and *hands that red test off*, deliberately **without writing
   the fix**. (The investigate→test→hand-off split is the spine of bug→reviewed-PR: the fix and the test are
   produced by different steps, so the test can't be quietly shaped to pass whatever the fix happens to do.)

**EARLY-SURFACE PATH (HUMAN POINT, the key part of this story):** `@investigator` has **7 BLOCKING STOP
conditions**. If the root cause touches **auth, RLS (row-level security / tenant isolation), a database
migration, payments/money math, or the bug is ambiguous** — it **STOPS AND SURFACES to the operator right then**,
*before* writing any fix and *before* any PR exists. This is the explicit "review earlier if a human decision is
needed" path: review does not wait for PR time when the decision is risky. The operator makes the call (or
provides the known fix in a "pre-grill" note), and only then does the flow continue.

### B.3 — Fix it (the right subsystem)

- **Non-urgent defect:** the filled TASK-TEMPLATE goes to **`/feature` (Tiny)**, which implements the fix
  test-first (the red test must go green), then `/cr`, then PR/MR.
- **Production incident:** **`/hotfix`** runs, with a **mandatory triage-gate** that picks ONE mode *before any
  code* — **mitigation-only** (stop the bleeding) vs **full-fix** — plus a blast-radius analysis (`@reviewer`'s
  Impact + Cascade lenses). It writes precise `[~]` TASKS.md entries whose exact shape **`@hotfix-guard`** later
  checks.

### B.4 — Review at PR/MR time

For the normal (non-early-surface) path, review lands at PR time:
- **`/hotfix`** is gated by **`@hotfix-guard`** — a *binary* merge-gate that mechanically verifies: the required
  TASKS.md entries for the chosen mode exist, a *new* failing test was added, and the diff stayed in declared
  scope. PASS/FAIL, no judgment. Its determinism is its value.
- **`/cr`** runs the adversarial review (as in Story A). If the diff touches auth/RLS/payments, the
  **cr-security path classifier** (a deterministic glob, no model judgment) auto-routes it to **`/cr-security`**
  (MUST-FIX-only, no "suggestion" tier).
- `scripts/pr.sh` opens the PR/MR; the **F6 CI gate** re-verifies the verdict on the shipped SHA on a protected
  branch.

**HUMAN POINT (merge):** a human merges (or, post-incident, the post-merge `/post-mortem` step runs to find the
*structural condition* that allowed the bug and propose a PITFALLS + memory entry — closing the loop so the
bug-class can't recur).

### B.5 — Where Story B can fail

- **Wrong triage.** A real incident classified as a routine bug (or vice-versa) routes into the wrong subsystem
  and loses urgency or over-escalates. The classifier quality is the risk; L6's evidence checks reduce it.
- **Security auto-fix.** If the isolation-only short-circuit doesn't fire, an agent could "fix" a security bug
  and ship the patch (and the exploit details) through a normal PR. The short-circuit is a hard boundary; it must
  be wired into *every* trigger door, not just one.
- **Spin / wrong-problem fix.** Under autonomy an agent can produce a polished all-green PR that solves the
  *wrong* problem. **F7's REJECT** deterministically catches this (diff solves a different problem than the spec;
  auth/schema/payment change with zero/negative test delta; diff over ~800 lines) and re-queues or escalates.
- **CI-self-heal injection.** A red CI log can carry injected text; that door waits on F5 + the egress allowlist
  (F3) before it's safe to run unattended.

---

## STORY C — A production incident ("prod is down")

**Who starts it:** an error monitor fires, or a teammate posts *"the proposal page is 500-ing for everyone"* in
Slack, or a `fix-me`/`incident` label lands. (Moves: L1 incident-class trigger → L6 · `/incident` → `/hotfix` ·
F1/F2 floor · L7 narration · F6 gate.)

1. **Trigger → `/incident`.** The front-door classifier sees incident-class and routes to **`/incident`** (NOT
   `/feature`). The triage doc is written and *travels* to `/hotfix`.
2. **Reproduce + classify.** `/incident` reproduces, runs its 6 evidence checks, hits the PITFALLS.md
   short-circuit ("seen this? here's the known mitigation"), assigns the 8-type class + confidence.
   - **If it's a security signal:** isolation-only short-circuit — propose isolation, **stop**, page the operator.
     No auto-fix. End of autonomous path.
3. **`/hotfix` triage-gate (HUMAN POINT, fast).** Pick **mitigation-only** vs **full-fix** before any code.
   Under autonomy, mitigation-only (e.g. revert the bad deploy, feature-flag off) is the safer default and may be
   pre-approved; full-fix on a risky surface pages the operator.
4. **Floor does its quiet work.** **F1** (`block-dangerous-bash.sh`, fail-closed) makes sure the agent can't run
   a prod-deploy or a destructive DB command as part of "fixing" things; **F2** (credential pre-flight) refuses
   the run if the readable env holds a prod service-role key in a context that shouldn't have it. These are
   *deterministic* — they don't ask the model's permission.
5. **Failing-test-first, then the fix**, in `/hotfix`'s chosen mode, gated by `@hotfix-guard`.
6. **PR/MR + F6 gate + human merge.** Same un-fakeable finish as every other flow.
7. **`/post-mortem`** (after merge): find the structural condition that *allowed* the incident, propose a
   PITFALLS entry + a memory entry (human-reviewed before write). This is what makes the next occurrence
   impossible, not just fixed.

**L7 narration is load-bearing here:** during a live incident the operator must see "reproduced → classified as
DB-connection-exhaustion → mitigating by rolling back deploy abc123 → testing → PR opened" *as it happens*, not a
summary at the end.

**Where it can fail:** a too-aggressive "full-fix" under autonomy on a prod surface (mitigation-only should be the
unattended default); a destructive command the floor doesn't cover (F1 must be full-scope and fail-closed); the
human-paging surface (Fork F9) being undefined means the page might go nowhere (see gaps).

---

## STORY D — A planned refactor ("split this 600-line file safely")

**Who starts it:** the operator (this is deliberate, planned work — not a trigger-fired bug). Often run inside a
`/queue` batch. (Moves: `/refactor` + the plan-file · `/tdd` characterization tests · F7 · F6.)

1. **Operator invokes `/refactor`** on a target (e.g. split `pricing.ts` into modules). `/refactor` is a
   side-effect-aware skill but commits-only (no deploy), so it isn't `disable-model-invocation`-gated.
2. **Tests before movement (HARD RULE).** Every symbol that moves must have a **characterization test** first —
   a test that calls it from outside and asserts on output. If one doesn't exist, **`/tdd` runs first** to write
   it. No test → no move. (CLAUDE.md refactor rule, non-negotiable.)
3. **The plan-file.** `@refactor-extractor` writes `.claude/refactor-plan.md` as its **source of truth** ("not
   your context window") — so an interrupted or context-reset run (very real for a long cloud run) is
   **resumable**. Each module extraction is one invocation: pure move, zero logic change.
4. **The naming gate.** The no-conjunction naming gate **rejects** `utils` / `helpers` / `misc` / `and`-joined
   names — a deterministic check that stops a refactor from creating junk-drawer modules.
5. **Two hats, enforced.** Structure and behavior never change in the same commit. If the agent is tempted to
   "fix a bug while I'm here," the logic-regression REVERT rule kicks it back. Different hat = different commit.
6. **Verify + review.** Full test suite + `tsc` after each extraction (a green bar is the gate to the next
   module); then `/cr`; then PR/MR + F6.

**HUMAN POINT:** approving the PR/MR. The refactor is low-product-risk (behavior is locked), so it's a natural
LOW-tier auto-approve candidate *once* the auto-approval classifier (LOOP-7) is live and `/cr` recall is
calibrated (C4).

**Where it can fail:** a "pure move" that silently changes behavior (the characterization tests + REVERT rule are
the defense); a circular-import introduced by the split (a `@refactor-extractor` judgment call — why its model
matters); a context reset losing progress (the plan-file is the resumability primitive that prevents this).

---

## STORY E — A dependency bump ("a library has a new version")

**Who/what starts it:** a **scheduled cloud run** (L4 heartbeat) notices a new release, OR the operator asks.
(Moves: L4 cloud `/schedule` · the rebuilt `/dep-update` slot · F7 · F6 · the "never install without asking"
rule.)

1. **Scheduled discovery (laptop-closed).** A cloud `/schedule` routine reads dependency changelogs and surfaces
   bumps. *Note:* the old `dep-update` skill was an **empty stub** (cut); this is a **NEW build**, an autonomy
   target, not a carry-forward.
2. **Safe-bump classification.** A patch/minor with a clean changelog and green tests is **safe-bump** class.
3. **The hard human gate on majors.** A **major version** (breaking changes) **summons a human** — and the
   project's standing rule is **"NEVER install/bump a dependency without asking first,"** with the required facts
   surfaced (name, purpose, weekly downloads, last publish, ships-its-own-types). This rule is *already a norm*;
   the flow just enforces it.
4. **Build + verify.** For a safe-bump: apply, run the full suite + `tsc`, then `/cr`, then **one scoped,
   pre-validated PR/MR** — *never* a pile of raw bumps (respects the "+98% PRs, zero DORA gain" constraint: one
   reviewable PR per change, not noise).
5. **F6 gate + human merge.**

**Where it can fail:** a "safe" minor that's actually breaking (the full-suite-must-be-green gate is the catch);
a supply-chain attack via an injected/compromised package (this is exactly what the **egress allowlist F3** and
the "never install without asking" gate defend — an unattended `npm install` is the Cline-Feb-2026 vector);
classifying a major as minor (the human gate on majors is the backstop).

---

## STORY F — A scheduled "find work" run (the cloud heartbeat)

**Who/what starts it:** **nobody** — that's the entire point. A cloud `/schedule` routine fires on a clock,
laptop-closed. (Moves: L4 heartbeat · CMP4 `/scan-context` · the discovery→gated-action pattern · L7.)

1. **The clock fires.** A recurring cloud agent wakes up (this is the fix for "every weekly ritual ran twice and
   then died" — V1 had no scheduler).
2. **Discovery scans** run: ritual scans (is STRATEGY.md stale?), runtime-error surfacing, and the **≥3-recurring
   findings** check. **`/scan-context` (CMP4)** runs its two drift checks against the repo's own canon:
   **staleness** (does every path/command/skill the docs claim still exist?) and the more dangerous
   **doc-fiction** (does every *named artifact* the docs reference actually exist on disk? — the harness's own
   canon once cited five phantom files).
3. **Gated action, not a dump.** Discovery feeds a **gated action agent** that produces **one scoped,
   pre-validated PR/MR per finding** — *not* 30 raw triage items a human reads on an unscheduled morning. (The
   R1 constraint: producing many PRs with zero throughput gain is a failure, not a feature.)
4. **Each produced PR/MR** then runs the normal `/cr` → F6 → human-merge path.

**HUMAN POINT:** every produced PR is human-merged (and ritual recommendations like a STRATEGY.md reorder are
**surfaced for one-click confirm**, never auto-written).

**Where it can fail:** the schedule silently stops firing (needs the cloud `/schedule` substrate actually wired —
confirmed-absent today); a noisy flood of low-value PRs (the "one scoped PR per finding" + the gated-action
pattern are the throttle); the repair-worker half of `/scan-context` overstepping (its *detection* is P0 and
ungated, but *fixing* drift is gated on Fork F7 — auto-delete only provably-absent fiction refs; gate staleness
demotions to a human).

---

## STORY G — "This is too risky — ask a human" (the deliberate STOP)

This isn't a separate trigger; it's the **stop path that can fire inside any of the stories above**, and it's
worth telling on its own because *a harness that can't stop itself is not safe to run unattended.*

**Where a stop can fire and what happens:**

1. **A deterministic floor block (F1).** The agent tries a destructive command (prod deploy, `rm -rf` outside the
   worktree, `DROP`/`TRUNCATE`/`DELETE`-without-`WHERE`, a non-local `supabase db push`). The **fail-closed**
   hook blocks it *before it runs*. The agent cannot argue with the hook.
2. **A credential refusal (F2).** The credential pre-flight sees a prod URL / service-role key readable in an
   unattended context and **refuses the whole run**. Fail-closed.
3. **An investigator/spike STOP condition.** Root cause touches auth / RLS / migration / billing, or the question
   is ambiguous → **STOP AND SURFACE** to the operator before any fix (Story B's early-surface path).
4. **A bounded-loop REJECT (F7).** The agent has retried up to the ceiling (default 2–3), or tripped a REJECT
   trigger (scope explosion, diff > ~800 lines, CI failing with no auto-fix path, a risky change with zero/negative
   test delta, or the diff solves a *different* problem than the spec). It writes a **REJECT/NEEDS-HUMAN
   artifact** and re-queues; two REJECT→re-spec→REJECT cycles **escalate to the human-paging surface**.
5. **A fleet circuit breaker (F8).** Across many runs, the *same* normalized failure signature repeats N times.
   **Stop-the-line:** stop opening new PRs in that class, write a marker, page a human. ("The fleet doesn't fail
   once, it fails twenty times" — this stops 20 broken PRs across 5 repos stacking on one bad assumption.)
6. **A migration / side-effect skill (F9).** Skills that do irreversible things (deploy, apply-migration, open-PR,
   `/init`, `/queue`) carry `disable-model-invocation` — the model **can't** auto-fire them; only a pinned
   orchestrator step or an explicit human invocation can. For migrations specifically (**F4**): the agent
   verifies against a throwaway *local* stack; a **human applies to prod**.

**What's produced by a stop:** a clear artifact saying *why* it stopped, *what it had done so far*, and *what it
needs from the human* — plus a page to the operator. **L7's observability log** records every stop (trigger fired,
risk tier, escalated-vs-handled, outcome), so stops are legible, not silent.

**HUMAN POINT:** the human decides — approve, redirect, or kill. Then the flow resumes (or doesn't).

**Where it can fail:** the human-paging surface (Fork F9) is **undecided** — a stop that pages "nowhere" is a
silent failure (see gaps); a guard that fails *open* (V1's two existing guards fail open on a missing `jq`) is
"probabilistic enforcement in a costume" — V2's new guards must fail closed.

---

## STORY H — A teammate just wants to understand a change (the lightweight path)

Worth including because not every interaction is a build. (Moves: `/explain` · L7.)

1. The operator (or a learning teammate) asks: *"what did that proposal-comments PR actually do?"*
2. **`/explain`** produces a teaching brief about the diff: what was built, the React/Next concepts in play, the
   decisions made, what would break, and one staff-engineer-level question. It is **explicitly not a review** — no
   verdict, no gate.
3. Optionally, this brief is appended to every autonomous PR as a "what this teaches" section, so the operator can
   skim *why* a fleet-produced change looks the way it does.

**No human gate, no failure surface beyond "the brief is wrong"** — which is why `/explain` is cleanly separate
from `/cr` (a teaching brief and a quality gate must never be confused).

---

## WHAT THESE FLOWS TEACH US (the gaps writing the stories surfaced)

Writing the journeys end-to-end exposed places the design is thinner than the pillar prose suggests. These are
honest gaps and design additions, not restatements.

### G1 — Slack/Linear are first-class doors, but the *router behind them* is underspecified.
The vision (L1) and the git-host design name three trigger doors and say the classifier "routes to the right
subsystem." But the actual **classifier** — the thing that reads a free-text Slack message and decides
feature vs incident vs behavior-change vs "ask a human" — is described only as a step, never as a built artifact
with inputs, a decision table, and a confidence threshold. **For a label** the routing token is explicit; **for
free text** there is no specified classifier contract. *Design addition needed:* a small, named **front-door
classifier** (its inputs: the message text + source channel; its output: one of {feature, incident,
behavior-change, needs-human}; its escalation rule: low confidence → ask). This is on the critical path for
Slack/Linear being genuinely first-class, not just "a door that exists."

### G2 — Spec-first (Story A) is only as strong as its *trigger*, and that trigger is soft.
C6 says `/feature` "writes the spec first" for Medium+ work. But *what forces a Slack-summoned feature into
`/feature` at the right size class* is unspecified. A bug-to-PR trigger could plausibly route a feature-shaped
request straight to coding and skip the spec. **The spec-first discipline has no deterministic gate** — it's a
convention inside `/feature`, not a hook that *blocks* an implementer from spawning before an approved
`docs/specs/<feature>.md` exists. *Design addition:* a PreToolUse-style check (or a `/feature`-internal hard gate)
that **refuses implementer spawn for Medium+ work until an approved spec file exists**. Otherwise "world-class,
not code-first" is aspirational.

### G3 — The human-paging surface (Fork F9) is undecided, and *every stop path depends on it*.
Stories B, C, F, and G all end at "page the operator" / "surface to a human." But **where** that page goes
(Slack? Linear? the git host? a PR comment?) is an open fork. Until it's chosen, the entire stop/escalation
substrate pages *into the void*. This is the single most cross-cutting gap: it's not one feature's problem, it's
the shared exit door for F7 (REJECT), F8 (circuit breaker), B's early-surface, and L7's narration. **It should be
resolved before any unattended trigger ships**, because an autonomous run you can't be paged by is not safe.

### G4 — "Review earlier if a human decision is needed" exists in `/debug` but not uniformly.
Story B's early-surface path is real and well-specified *for the investigator* (7 BLOCKING STOP conditions). But
the equivalent "stop before the PR, this needs a human now" path is **not uniformly present** in the
feature flow, the refactor flow, or the dep-bump flow — there, risky decisions mostly surface as `/cr`
**needs-design-decision** findings *at review time*, which is later than ideal. *Design implication:* the
auth/RLS/migration/billing STOP-AND-SURFACE conditions should be a **shared, early tripwire** across all build
flows, not just `@investigator`'s. (`@reviewer` already has STOP-AND-SURFACE on auth/RLS High findings, but that's
at review time; the cheaper place is *before* the work.)

### G5 — The continuation engine is the built-in loop, and its stopping condition is assumed-not-verified.
These stories lean on long unattended runs (Stories C, E, F, and the auto-approve path) continuing **until a
separate grader says done**. V2 correctly **uses Claude Code's built-in continuation loop** rather than building a
new `/goal` skill. But the design rests on an *unverified capability*: that a Stop hook's `decision:block`
actually **force-continues** the model (VISION marks this "verify empirically"). **If it doesn't hold**, the
fallback is external re-invocation via the L1 front door / cloud `/schedule` — which changes the shape of every
long-run story (re-summon instead of in-process continue). *Action:* the Phase-0 capability probe must run before
any of these continuation-dependent flows are trusted. This is named in the vision but it's worth flagging that
**five of these eight stories silently assume the probe passes.**

### G6 — "Done" for a long run needs a *grader contract*, and only the deterministic half is specified.
Every flow ends at F6 (CI re-checks the verdict on the shipped SHA). That's the *deterministic* finish line —
typecheck/lint/tests green + sentinel SHA matches. But the **judgment half** (did `/cr` actually catch the
defects?) is only as trustworthy as its measured recall, and **C4 calibration is P1, not day-0**. So in the
earliest version of these flows, a long unattended run's "done" rests on a quality gate whose miss-rate is
*unknown*. The stories quietly assume `/cr` is good; the honest statement is: **until C4 ships, treat any
unattended self-merge as ungated on judgment** — keep merges human until recall clears a floor (which is exactly
what LOOP-7's observe-only mode encodes, but the flows should state it loudly).

### G7 — The security isolation-only short-circuit must be wired into *every* door, and that wiring isn't drawn.
Story B/C rely on a security signal triggering isolation-only (never auto-fix). That short-circuit lives in
`@incident-responder`. But a security-relevant bug could enter through the **Slack `/fix` door** or the **dep-bump
flow** (a CVE in a dependency) and route somewhere *other* than `/incident`. *Design addition:* the
security-signal detector must sit **on the front-door classifier itself** (G1's artifact), not only inside the
incident responder — so no door can route a security issue into a normal auto-fixing pipeline.

### G8 — Parallel `/queue` runs and the stories interact, but conflict-handling across flows isn't shown.
Stories D and E commonly run inside a `/queue` batch (many worktrees at once). The roster says `/queue` serializes
migration / CLAUDE.md / AGENTS.md tasks. But the stories don't show **what happens when two flows touch the same
file** (e.g. a refactor in Story D and a dep-bump in Story E both edit `pricing.ts`). The worktree isolation
prevents corruption, but the *merge-order* and *rebase-conflict* resolution across parallel agent PRs is
unspecified. *Design implication:* the sequential-push rule exists, but a **cross-flow conflict policy** (who
rebases, who re-runs `/cr` after a rebase invalidates the sentinel SHA) is missing — and F6's "sentinel SHA must
equal head SHA" means **any rebase invalidates the verdict and forces a `/cr` re-run**, which the flows don't
currently account for.

### G9 — The "found work → one scoped PR" promise (Story F) has no specified *dedup* against in-flight work.
The heartbeat produces one PR per finding. But if the same finding was surfaced last night and a PR is already
open (or was merged), nothing in the flow is specified to **dedup against in-flight or recently-closed work**.
`/spike` has a 30-day staleness/dedup gate; the discovery heartbeat needs an equivalent, or the fleet re-opens the
same PR nightly. *Design addition:* a finding-dedup check (against open PRs + a recent-findings ledger) before the
gated action agent opens anything.

### G10 — Every story ends "human merges," but the *capacity* math is the original bottleneck.
The whole point of the loop is to stop the operator being the dispatcher — yet every flow still ends at "a human
merges." With a fleet across 5+ repos, **merge-review becomes the new bottleneck.** LOOP-7 (risk-based
auto-approval) is the designed answer, but it's GATED (Fork F2) and ships observe-only. *Honest implication:*
until LOOP-7 goes live, V2 moves the bottleneck from "human starts every run" to "human merges every PR" — a real
improvement, but not the full ceiling-lift the charter promises. The stories should be honest that **the
last-mile human merge is the remaining ceiling** until auto-approval clears calibration.

---

## Appendix — quick map of stories → moves → human points

| Story | Starts from | Primary moves | Human approval point(s) | Produces |
|---|---|---|---|---|
| A — new feature | Slack / Linear / label | L1 · `/design` · `/feature` · C6 spec · C2/C5 `/cr` · F6 | **Spec approval (before code)**; merge | Approved spec + opened PR/MR |
| B — found a bug | Slack / Linear / label / CI-red | L1 · L6 · `/debug`→`/feature`/`/hotfix` · F7 · F6 | **Early-surface on auth/RLS/migration/billing**; merge | Failing test + fix + PR/MR |
| C — prod incident | monitor / Slack / label | L1→L6 · `/incident`→`/hotfix` · F1/F2 · F6 | Mitigation-vs-full-fix; merge; post-mortem write | Mitigation/fix PR + post-mortem |
| D — refactor | operator (often `/queue`) | `/refactor` plan-file · `/tdd` · F6 | Merge (LOW-tier auto-approve candidate) | Behavior-locked module split PR |
| E — dep bump | cloud `/schedule` / operator | L4 · `/dep-update` · F3 · F6 | **Majors require human**; merge | One scoped bump PR |
| F — find-work | cloud clock (nobody) | L4 · `/scan-context` CMP4 · gated-action | One-click confirm rituals; merge | One scoped PR per finding |
| G — too risky, stop | any flow | F1/F2/F4/F7/F8/F9 | The human decides (approve/redirect/kill) | A REJECT/NEEDS-HUMAN artifact + page |
| H — explain a change | operator / teammate | `/explain` | none (not a gate) | A teaching brief |
