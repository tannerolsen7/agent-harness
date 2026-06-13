# Pass 1 — Comprehend: "Loop Engineering — You Built the Harness, Not the Loop"

**Source.** Notion page `37be2971cd6281a59b38ccc5dea344d2`, built on Addy Osmani's "Loop
Engineering" + "Agent Harness Engineering" essays plus Claude Code (`/goal`, scheduled-tasks) and
Codex (Automations, Worktrees, Subagents) docs. The page is itself a *corrected* curation: a self-
reported "Correction" section says the first draft wrongly told the reader their harness "already is a
loop." Per task instructions, the page's own passes/judgments are treated here as **claims to verify**,
not facts to inherit; I tag them accordingly.

This pass states what the page *says*, faithfully, without applying it to our harness.

---

## The central claim

**Claim 1 (definitional, opinion presented as fact).** A harness and a loop are different floors.
A pipeline you invoke by hand — *even a sophisticated multi-agent one* — is a **harness**. A system
that "finds its own work on a schedule and prompts the agents *for* you" is a **loop**. (opinion —
it's a definitional stance attributed to Osmani, not an empirical finding)

**Claim 2 (quote, fact-of-attribution).** Osmani is quoted: *"loop engineering sits one floor above
the harness… but it runs on a timer, it spawns little helpers, and it feeds itself."* (fact that the
quote is attributed; the framing is opinion)

**Claim 3 (the load-bearing reduction, opinion).** Osmani lists five pieces — automations, worktrees,
skills, plugins/connectors, sub-agents — plus a sixth, external memory. **Only one of the six converts
a harness into a loop: the automations — the heartbeat.** Quoted: *"Automations are what make a loop an
actual loop and not just one run you did once."* Worktrees, skills, connectors, and sub-agents "all
live inside any good harness already. None of them make it a loop." Spawning sub-agents is
*orchestration* — a harness capability, not a loop capability. (opinion/definitional)

**Claim 4 (memory as spine, opinion + quote).** The second easily-missed piece is the memory file as
*spine, not optional plumbing*: *"the model forgets everything between runs so the memory has to be on
disk and not in the context. The agent forgets, the repo doesn't."* Without durable external state, a
"loop" is just a repeated cold start, not a compounding one. (opinion, with quoted support)

---

## The self-critique (the page's own audit of "our" system)

**Claim 5 (assessment of our system, opinion).** "Everything in your system is **human-initiated**":
you queue tasks, run `/change`, approve `/compound` curation, do the morning review — which the plan
itself concedes is *"not a named calendar ritual"* (Node 5.2). **There is no step that surfaces work
you didn't already know about.** (opinion — a judgment about our harness; must be verified against the
ground-truth map)

**Claim 6 (the orphaned-rituals finding, factual claim about our plan).** The "partial heartbeat" the
first draft credited "does not exist." At least **five committed mechanisms** are described as "weekly"
or "scheduled" rituals **with no scheduler named anywhere in the plan**:
1. `check-resolvable` (Node 2.1)
2. mutation testing (Node 6.3)
3. the weekly doc-drift review
4. permission-logger aggregation (Ashby item 4)
5. the "a finding class appears 3+ times → mandatory AGENTS.md update" rule.
(factual claim about the plan's contents — verifiable against our docs)

**Claim 7 (consequence, opinion).** "In a solo system with no cron, a 'weekly ritual' runs twice and
then never again." Those five "aren't a loop; they're not even running." This is "a direct **Pillar 1**
violation — *a control with no enforcing hook is a hope* — hiding inside the part of the plan that
looks most complete." (opinion built on Claim 6; Pillar 1 is cited as our own doctrine)

---

## The in-session primitives

**Claim 8 (definitional, fact-about-docs).** Two Claude Code primitives are distinguished:
- **`/loop`** = cadence re-run; the next turn starts when a clock elapses. "Your *ritual* layer — if it
  had a scheduler."
- **`/goal`** = run until a verifiable stopping condition, graded by a *separate* model. Single-task
  continuation, not a discovery loop. Its grader is "transcript-only and must bottom out on your CI
  sentinel."
**Neither is the loop. The loop is the automation that fires them for you.** (mostly factual about what
the primitives are; the "neither is the loop" line is opinion)

---

## The prescriptive core

**Claim 9 (should-we-build-it, opinion grounded in cited evidence).** The real question is whether to
build the loop layer at all. "Your own Svpino R1 is the shape of the answer": overnight autonomy
*relocated the review bottleneck* — **+98% PRs, +154% PR size, +9% bug density, *zero* DORA gain.**
Therefore the answer is **not** "build the self-acting loop." It is: **automate the discovery half,
keep the action half human-gated.** That is the "bounded, R1-respecting version of loop engineering."
(opinion/recommendation; the R1 metrics are presented as fact)

**Claim 10 (the concrete proposal — Node 17, opinion).** The first step from harness to loop is a
*single scheduled job* (the page asserts "the scheduling capability exists in this environment") that:
- runs the five currently-orphaned scans,
- reads the `/p/[token]` runtime-error table (Ashby item 1, "once built"),
- greps `review-log.md` for finding classes recurring 3+ times,
- and **deposits everything into a `triage-inbox.md` that the morning review consumes.**
Discovery is automated; **action stays human-gated** — the agent surfaces candidate work, never acts on
it; anything worth doing still flows through `/change` / `/queue` and their blast-radius caps (Pillar
2). "The smallest thing that is genuinely a loop, respects R1, and converts five Pillar-1-violating
hopes into one enforced mechanism. It should be a new node in the build plan." (opinion/recommendation)

---

## The standing rule (the page's takeaway)

**Claim 11 (rule, opinion).** "A control described as a 'scheduled ritual' with no scheduler is a hope,
not a control — either it is wired to a heartbeat or it does not exist (Pillar 1). And never call a
hand-invoked pipeline a loop: the loop is the thing that does the prompting you used to do." (opinion —
a proposed standing rule)

---

## What the page assumes the reader already has (named, not argued)

- A "Pillar 1 / Pillar 2" doctrine (blast-radius caps; "a control with no enforcing hook is a hope").
- A build plan with numbered Nodes (2.1, 5.2, 6.3), "Ashby items," an "Svpino R1" experiment, a
  `/change`, `/queue`, `/compound` pipeline, a `review-log.md`, a `/p/[token]` runtime-error table.
- A morning-review habit that is *not* a named calendar ritual.
- A scheduling capability in the environment (asserted, not demonstrated).

## One-line thesis (faithful)

You built a serious *harness* but not a *loop*; the only thing that makes a harness a loop is a
scheduled, self-triggering discovery step backed by on-disk memory — and the disciplined first version
of it automates **discovery only**, leaving **action human-gated**, which also rescues five "scheduled"
rituals that currently have no scheduler and therefore do not run.
