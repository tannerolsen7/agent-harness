# Pass 1 — Comprehend: what the article says

**Source.** Notion research page "Augment Code — Context Engine, Contractor vs. Employee &
Probabilistic Enforcement (2026)" (id `36ce2971cd6281fab72cfaccd9732337`). It is a curator's
synthesis of Augment Code's vendor guides ("How to Build AGENTS.md", March 2026; "Harness
Engineering for AI Coding Agents", April 2026), a Codacy/AI-Giants podcast with Vinay Perneti
(VP Engineering), an Augment-vs-Continue comparison page, plus secondary Gartner/Medium pieces.

This pass records what the page *says*, faithfully. The page already contains its own
synthesis, claims ledger, and an "Application to This System" section; per instructions those
are treated as the curator's CLAIMS (tagged below), not inherited fact.

---

## A. The three headline ideas the page is built around

1. **Contractor vs. employee metaphor (the page's centerpiece).** (opinion — Perneti quote,
   curator elevates it) Perneti: "Contractors are just borrowing intelligence, but they're
   missing context. Augment provides context like an FTE." The curator calls this "the sharpest
   context-problem framing in this research" and "the cleanest articulation of why context files
   matter." (opinion) The structural implication the curator draws: the investment that matters
   is **context infrastructure**, not model intelligence — "contractors and FTEs can both be
   smart," only the FTE has deep context. (opinion) Every context file (`AGENTS.md`,
   `CONTEXT.md`, `PITFALLS.md`, `CLAUDE.md`) is reframed as "an investment in FTE-level agent
   behavior."

2. **Context Engine vs. search-based context.** (fact — about Augment's product) Augment's
   Context Engine indexes entire repositories ("400,000+ files in real time", tagged Verified in
   the ledger) and maintains real-time sync, enabling architectural/dependency analysis. The
   claimed failure mode of search/RAG tools: implicit dependency chains ("one service triggers a
   queue that triggers an event that affects a module in a different part of the system") are
   real but not locatable by search. (opinion — the framing of why competitors fail)
   - **The 200k-token threshold.** (fact-as-reported, secondary) For codebases under ~200k
     tokens, loading **full context outperforms RAG with chunking** — "Howdy found 67% retrieval
     failure reduction with full-context loading under the threshold." Above the threshold,
     structured indexing becomes necessary. Augment targets the above-threshold case.

3. **Rules are probabilistic; the outer harness must be deterministic.** (fact — stated as
   Augment's architectural principle, ledger-tagged "Verified (key architectural principle)")
   "LLM compliance with instructions is probabilistic, not deterministic." Rules files change
   the *probability* the agent follows a convention; they do not guarantee it. The correct
   architecture combines probabilistic rules files with **deterministic outer-harness
   constraints — linters, CI gates, pre-commit hooks** — that make violations structurally
   impossible. The curator's gloss: this "resolves the question of whether CLAUDE.md can replace
   CI enforcement. It cannot." (opinion, but tightly derived)

---

## B. Augment Rules — three load-trigger types (fact, ledger-Verified)

A taxonomy keyed on *when a rule loads*:
- **always_apply** — loaded into every prompt automatically. Curator maps to root `CLAUDE.md`.
- **agent_requested** — loaded when the agent judges them relevant. Curator maps to skills
  loaded on invocation.
- **manual** — loaded only when explicitly invoked. Curator maps to opt-in skills / explicit
  prompts.

Design principle stated alongside (fact, ledger-Verified): **the Context Engine handles what
can be inferred from the codebase; rules files are reserved for what cannot be inferred**
(naming conventions, logging standards, architectural boundaries). The curator ties this to a
"Harness execution-surface principle: rules files = behavior-changing content only, not
documentation."

---

## C. Automation bias is cultural, not technical (opinion — Perneti, ledger-Verified as his position)

Perneti: "The person pushing the PR owns the code, period." Automation bias (over-trusting AI
output, reducing scrutiny) is addressed at Augment by **cultural framing, not technical
constraint** — the engineer who merges an AI PR owns it as if they wrote it. Curator links this
to the Zapier "Accountability" pillar and Linear's agent-accountability principle.

---

## D. The AGENTS.md / structured-context claims (the page's most-cited figures)

From the claims ledger, with the curator's own confidence tags preserved:
- **AGENTS.md = "living interface contract between humans and agents."** (opinion — Augment
  position; ledger "Verified (Augment position)")
- **LLM-generated AGENTS.md causes agents to take 2.45–3.92 extra steps per task.** (fact —
  ledger "Verified (cites primary research)", attributed to ETH Zurich via Augment)
- **Decision tables outperform prose by +25% on agent benchmark scoring.** (opinion-grade fact —
  ledger "Primary-adjacent (Augment-sourced figure)"; curator repeatedly flags it as
  Augment-sourced, no independent confirmation)
- **Human-curated AGENTS.md can reduce wrong-pattern rewrites by 40–60%.** (fact-as-reported —
  ledger "Primary-adjacent", Augment citing Anthropic internal benchmarks)
- **60–80% code-review acceptance rate** for Augment's AI suggestions vs human reviews. (opinion
  — Augment's own claim, flagged skeptical)
- **Onboarding cut 4–5 months → 6 weeks**, new engineers ship complex cross-codebase PRs in
  first month. (opinion — customer claim via Perneti, "not independently verified")
- **Roadmap thrown out Jan 25, 2026; now planning in quarters.** (fact — Perneti direct)

The curator is explicit and disciplined about provenance: "Treat figures as Augment's
synthesis, not independent studies."

---

## E. The curator's own "Application to This System" (CLAIMS — to verify in pass 3, not facts)

The page extrapolates two candidate actions for "this system" (the canon, written before this
audit existed — its picture of "the system" is the Notion canon, **not** verified against
event-vendor disk):

1. **Audit CLAUDE.md for prose→table conversion.** Convert highest-stakes behavioral rules
   (boundary conditions, "what to do if X", "when to STOP AND SURFACE") from prose to 2-column
   `Condition | Action` tables — "not all content, just the conditional logic." Open question
   the curator leaves: which sections would benefit most.

2. **Add the hooks layer before expanding unattended operation.** "STOP AND SURFACE conditions
   are rules-file entries, not hooks." Before any complex AFK/unattended session, encode
   critical safety conditions as hooks. Specific candidate — **write 3 hooks**: (1) PreToolUse
   block on sensitive files, (2) Stop hook that checks test output before completion, (3)
   SessionStart hook that injects current `TASKS.md` state. The curator asserts this is "Gap 1
   from the existing Harness research page, now confirmed by Augment."

---

## F. "What doesn't transfer at solo-developer scale" (curator's own honesty table)

- Context Engine 400k-file indexing → **principle transfers, mechanism differs**; solo
  equivalent is `CLAUDE.md`/`CONTEXT.md`/`AGENTS.md` as the context layer.
- Three-tier rules → curator claims **"Fully — already in the system"** (CLAUDE.md=always /
  skills=invocation / prompts=manual). (CLAIM to check in pass 3.)
- Architectural dependency analysis → principle yes; mechanism is **manual** `CONTEXT.md`
  documentation of cross-module dependencies.
- Managed enterprise compliance (SOC 2, ISO 42001) → **does not transfer**.
- Automation bias as cultural norm → principle transfers as personal discipline ("I own every
  merged line").
- Onboarding acceleration → **does not transfer** (solo developer).

---

## G. The Design Challenge (the page's self-test)

"Identify the three compound-agent rules in CLAUDE.md most critical to enforce and least
reliably followed today. For each, write the hook that makes violation structurally impossible."
Each: (1) state the rule, (2) name the failure mode, (3) write a concrete Claude Code hook
(lifecycle event, what it checks, what it does on failure). The curator's gate: "If you can't
name three rules that have *actually been violated*, you don't have enough signal yet — run a
session first and observe." (opinion — a methodological discipline)

---

## H. Open questions the curator would ask Perneti (recorded, not resolved)

1. How does the Context Engine *represent* implicit dependencies internally (graph? embedding?)
   and how does that surface to the agent?
2. When does always_apply vs agent_requested vs manual matter most — is the probabilism in the
   *load decision* or in the *agent following the rule once loaded*?
3. How is the +25% decision-table figure actually measured (benchmark, context length, task
   types)?
4. What does "throw out the roadmap, plan in quarters" look like operationally when model
   capabilities shift monthly?

---

## One-line thesis (faithful)

Agent context files raise the *probability* of correct behavior but never guarantee it — so the
real architecture is **FTE-level context (probabilistic) wrapped in a deterministic outer
harness of hooks/CI/linters**, with accountability handled culturally, not mechanically.
