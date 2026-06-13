# Pass 1 — Comprehend: "Stripe Minions — Unattended Coding Agents at Scale" (Kaliski, 2026)

Faithful restatement of what the article says. Claims tagged **(fact)** when the article presents
them as sourced/verified, **(opinion)** when they are the author's framing, synthesis, or judgment.
The article is itself a *curated research page* (sources, claims ledger, synthesis, application
section). Per instructions, its own curator analysis — the "Application to This System" and "What
Doesn't Transfer" sections — is recorded here as **the article's claims**, to be verified in pass 3,
not inherited as fact.

## Provenance and method (as the article states it)
- Primary sources: Stripe Dev Blog "Minions" Parts 1 & 2 (Feb 2026, direct fetch failed — permissions
  error — so sourced via ByteByteGo which quotes it); ChatPRD write-up of a Steve Kaliski live demo
  (Mar 24 2026, read directly). Kaliski is a Stripe engineer on the Minions team. **(fact, with a
  caveat the article itself flags: the canonical primary source was not directly accessible)**
- Secondary: ByteByteGo (Mar 16 2026), InfoQ (Mar 2026), Awesome Agents (Feb 26 2026).
- The article disciplines its own sourcing: it explicitly **drops** the unverifiable "3 million tests"
  figure (single-sourced) and tags non-engineer usage as "Directional," not detailed. **(fact)**
- It wrote hypotheses *before* research and scores them — 3 confirmed, 2 "surprised." **(opinion/method)**

## Core verified claims (the article's Claims Ledger, all tagged "Verified" unless noted)
- Stripe merges **1,300+ PRs/week, all agent-written, zero human-written code**. **(fact)**
- **All 1,300 are human-reviewed before merge. No autonomous-merge path exists.** **(fact)**
- Minions run **unattended** — no human watches during execution. **(fact)**
- **Devboxes spin up in ~10 seconds** from a pre-warmed pool; **<5s local lint**; deep test suite.
  Devboxes were **built for human engineers years before LLMs**; agents "plugged into" them. **(fact)**
- Orchestration is a **"blueprint": deterministic nodes + agentic loops**. Linters and branch-push are
  **hardcoded/deterministic**; "implement the feature" and "fix CI" are **agentic**. **(fact)**
- **Toolshed**: a centralized MCP server exposing **~500 internal tools**. Each Minion receives a
  **curated ~15-tool subset**, not all 500 (giving all 500 caused "token paralysis"). **(fact)**
- **Global rules are scoped by directory/file pattern**, picked up as the agent moves through the
  filesystem; same rule files human tools (Cursor) read — no agent-specific duplication. **(fact,
  tagged "Primary-adjacent")**
- **Max 2 CI retry rounds, then hand back to a human.** **(fact)**
- The agent runtime is **Goose (Block's open-source harness), forked and adapted** — *not* a
  custom-built agent (contrast: Ramp built "Inspect" from scratch). **(fact)**
- Triggered via **Slack emoji (most common), CLI, web, automated systems**. **(fact)**
- Codebase: **hundreds of millions of lines, mostly Ruby + Sorbet**. **(fact)**
- **"Activation energy"** is Kaliski's term for the friction Minions eliminate (idea → first line of
  code). **(fact)** Kaliski: "I can't remember the last time I started work in a text editor." **(fact, quote)**
- A separate **machine-payment demo**: an agent autonomously spent **$5.47** to plan a birthday party
  (browser sessions, venue research, physical mail, carbon offset). **(fact)**
- Non-engineers at Stripe reportedly ship code via Minions. **(fact, but tagged "Directional" only)**

## The synthesis theses (the author's interpretation of the facts — opinion)
1. **"The infrastructure predated the agents. That's the whole story."** The article's central claim:
   Minions work *almost not at all* because of the AI model and *almost entirely* because of human-DX
   infrastructure (devboxes, deep tests, fast CI) that pre-dated LLMs. Stated principle (Kaliski):
   **"what's good for human engineers is good for agents"** — same track, no human in the driver's
   seat. **(opinion, but attributed to Stripe as their own stated position)**
2. **Blueprints beat both pure workflows and pure agent loops.** Pure workflow = rigid, can't handle
   variation; pure agent loop = flexible but accumulates errors at scale. Each deterministic node is
   "one fewer thing that can go wrong," and at hundreds of runs/day that compounds into the
   reliability enabling 1,300 PRs/week. **(opinion)**
3. **Context curation is an engineering discipline.** The architectural move is centralizing all tools
   in Toolshed and curating *at task time* — controlling what is *surfaced* per run, not what exists.
   **(opinion)**
4. **Fork, don't build — when the moat is in the environment.** Stripe's moat is the context +
   environment (devboxes, Toolshed, blueprints), not the agent loop, so an off-the-shelf harness was
   correct. Ramp's moat required deep custom integration, so building was correct. **(opinion)**
5. **The 2-round CI limit = "knowing when to stop."** Empirical reasoning: LLMs show diminishing
   returns on retries; more attempts produce "creative but wrong fixes that are harder to review than
   the original problem." The ceiling surfaces to a human before tokens/compounding errors mount.
   **(opinion, framed as empirically grounded)**
6. **Activation energy, not execution, is the engineering problem.** The Slack-emoji trigger's value
   is that the agent fires *where the idea already lives* — zero context switch. **(opinion)**
7. **Human review is the hard gate, intentionally.** At 1,300/week Stripe has *not* automated review;
   everything else (2-round limit, isolation, curation, blueprints) exists to make output
   *reviewable*, not to replace review. Review capacity is "a constraint they've accepted," not one
   they've solved. **(opinion)**
8. **Machine payment = a different product thesis.** Software may be built for agent *consumers*, not
   human users — no UI/login/dashboard, just an API an agent pays for on demand. **(opinion, horizon)**

## Cross-page connections the article asserts
- **Confirms (Shopify + Ramp):** review capacity, not generation, is the binding constraint at scale —
  now corroborated across three companies. **(opinion/synthesis)**
- **Extends "infrastructure-before-agents":** Shopify proxy, Ramp Modal sandboxes, Stripe devboxes —
  all human infra agents inherit; sequence is always *infra first, agents as a consequence*. **(opinion)**
- **Contrasts Ramp on build-vs-adapt:** both succeeded; the decision criterion is *where the moat
  lives*. **(opinion)**
- **New thread:** machine payment / agent-as-economic-actor — not present in Shopify or Ramp. **(opinion)**

## The article's OWN application claims (to verify in pass 3 — NOT inherited as fact)
The page closes with an "Application to This System (extrapolation — not yet adopted)" block and a
"What Doesn't Transfer at Solo-Developer Scale" table. These are the curator's claims about *our*
harness; pass 3 must check each against the ground-truth map.
- **(claim)** Our compound agent has STOP AND SURFACE conditions; add an explicit **max-retry count**
  (allow one retry, hard-stop at two) to the agent contract.
- **(claim)** The **blueprint pattern is already implicitly present** in our skill pipeline
  (TESTING.md / `/cr-feature` / compound questions = deterministic; `/tdd` slices = agentic);
  candidate is to *name* the D/A structure when authoring skills, possibly in `11 · Skill Ecosystems`.
- **(claim)** Our **AFK north star embeds activation-energy thinking**, but the trigger to fire the
  agent is higher-friction than a Slack emoji; candidate is a *design lens* (does the trigger live
  where the idea lives?), not a mechanism. Long-horizon.
- **(claim)** Machine payment is **not applicable to event-vendor now**; watch item.
- **(claim, "What Doesn't Transfer" table):** devboxes transfer *partially* (isolation yes via git
  worktrees, cloud parallelism no); blueprint transfers *fully* (already implicit, needs naming);
  Toolshed/curation transfers *fully* (CLAUDE.md/AGENTS.md scoped sections + on-invocation skills);
  max-2-retry transfers *fully* (add to `@task-runner` STOP AND SURFACE); Goose fork transfers *as a
  decision criterion*; activation energy transfers *as a principle only* (task-description quality is
  the solo lever); machine payment *doesn't transfer yet*.

## The article's Design Challenge (a posed exercise, not a finding)
It challenges the reader to audit the `/feature` pipeline and classify each step as **D** (deterministic
hard gate), **A** (agentic freedom), or **G** (human gate), then identify steps currently treated as
optional/conditional that the blueprint principle says should be **D** — and warns that a classification
producing *no* reclassifications means you didn't engage the pattern. **(method/exercise)**

## Stated limitations the article admits about itself
- The canonical primary (Stripe Dev Blog) **was not directly fetched** — all "Stripe blog" claims route
  through ByteByteGo's quoting. **(fact — a sourcing dependency)**
- **Merge rate among the 1,300 is unknown** (Open Question #1): 1,300 = generation capacity, not output
  quality. The article does not have the denominator. **(fact — an admitted blind spot)**
- Task success distribution, review distribution, the *why* of the Goose choice, and non-engineer
  usage detail are all open questions it cannot answer. **(fact)**
