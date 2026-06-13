# Pass 1 — Comprehend: "Ramp — Inspect Agent, Agent Architecture & Org-Wide AI Adoption" (2026)

**Source:** Notion research page `36ce2971cd628198b623d8d00bbfef4e`, frozen 2026-05-26. Aggregates: Ramp Builders blog "Why We Built Our Background Agent" (JS-gated, *not directly read* — derived from secondary summaries), Modal customer-story blog (vendor-reported), ZenML LLMOps case study (secondary), InfoQ Jan-23-2026 (independent), Geoff Charles CPO interview Mar-15-2026 (paywalled, preview only), Sengottuvelu "Fatal Flaw" talk (via Sequoia write-up).

This pass records what the page SAYS, faithfully. Tags: (fact) = verifiable/definitional or a reported observation; (opinion) = a normative or contestable judgment. **The page is itself a multi-pass research write-up** — it contains its own Pass 1–4, an Application section, a "What Doesn't Transfer" table, a Design Challenge, and Open Questions. Those embedded passes are the *curator's* interpretation; I record them here as claims the page makes, not as inherited analysis. Verification of those self-claims is the job of pass 2/3.

## Provenance and source-reliability (the page grades its own sources)

- The page front-loads a Source Reliability section — unusually disciplined. (fact, and notable)
- The primary engineering blog was JS-gated and **not directly read**; all blog-attributed claims are second-hand via ZenML/InfoQ/Modal. (fact — a stated limitation)
- The two headline figures ("half of merged PRs," "80% of Inspect written by Inspect") originate from **Modal's own customer-story post** — vendor-reported, and ZenML explicitly flags skepticism. (fact about sourcing)
- The **30% of PRs** figure (InfoQ) is "the most independently verified number on this page." (fact about sourcing)
- "Omnichat" (name of the unified interface) and "thousands of skills" are flagged **single-sourced / unconfirmed**. (fact — the page disowns them)

## Workflow 1: Inspect — the internal background coding agent

- Ramp is a finance-automation platform, 50,000+ customers; "one of the most documented AI-native engineering organizations publicly available." (fact / opinion-superlative)
- **The problem Inspect solves:** existing coding agents generate code but "couldn't verify it. They wrote code, then stopped. Inspect closes the loop." (opinion — this is the page's central thesis, stated as fact)
- **Infrastructure:** each session runs in its own sandboxed VM on Modal; the VM carries a full local-equivalent stack (Vite, Postgres, Temporal). Images are pre-built every 30 min per repo (cloned, deps installed, build done). Modal filesystem snapshots freeze/restore state. (fact — reported architecture)
- **Design principle (explicit):** "startup time should be bounded only by the model provider's time-to-first-token, not by infrastructure overhead." (fact — a stated principle; its *importance* is opinion)
- **Integrations:** Sentry, Datadog, LaunchDarkly, Braintrust, GitHub, Slack, Buildkite. The claim: Inspect "operates with the same signals and data sources human engineers use… not generating code in isolation." (fact list; opinion on significance)
- **Verification loop (the core innovation, per the page):** backend → runs automated tests + queries feature flags; frontend → visual verification, screenshots, live preview URLs. "The agent doesn't just write code, it runs its own verification against the same production observability stack the team uses." (opinion — the page's load-bearing claim)
- **Multi-model:** all frontier models; none pinned; infra/integration layer separated from model selection; MCP supported. (fact)
- **Organizational skills:** custom tools/skills encode "how we ship at Ramp" — org-knowledge capture, not a generic agent. (fact + opinion-framing)
- **Results:** ~30% of all merged PRs (frontend+backend) within months, **without a usage mandate**. CPO: AI writes 50% of Ramp's code (Mar 2026), predicted 80% soon. (fact-as-reported; the 50/80 are CPO statements)

## Workflow 2: client interfaces — "meet engineers where they are"

- Deliberate choice **not** to require one interaction pattern. Surfaces: Slack, Chrome extension (highlight a UI element), web UI, GitHub PR comments, web VS Code, **voice**. (fact)
- All changes sync to the session regardless of entry surface; every session is **multiplayer by default** (shareable, collaborative). (fact — reported)

## Workflow 3: the agent-architecture pivot (early 2026)

- **Old approach:** hundreds of specialized, isolated agents per financial workflow task (expense policy, accounting classification, invoice processing). (fact-as-reported)
- **New approach:** a single unified agent with "thousands of skills," consolidated through one conversational interface ("Omnichat" — single-sourced, page disowns the name). (fact-as-reported, with disowned detail)
- **Rationale:** maintaining hundreds of agents "as models improved became unsustainable"; one agent can "reason across skills and compose them situationally." (opinion — the page's reading)
- **Ramp's stated framework:** modern AI-native software must handle all five components of a process — **events, prompt instructions, guardrails (policies), context, tools/APIs**. "Traditional software handled only the last two." (fact — a quoted framework; the claim is opinion)

## Workflow 4: org adoption — the L0–L3 framework (Geoff Charles)

- **L0** use existing AI tools for personal productivity · **L1** automate specific repetitive tasks in your own workflow · **L2** build tools for your team (prompt pipelines, agents) · **L3** ship production code/product changes autonomously. (fact — a quoted framework)
- Claim: non-engineers at Ramp are reaching L3. "The goal was not AI-assisted engineers — it was AI-capable everyone." (opinion / reported)

## Workflow 5: the Claude Code PM skill

- Three phases: **(1) problem framing** — Claude challenges the PM with 7 questions (job-to-be-done, why now, what it unlocks); pushes back if answers are weak. **(2) parallel research** — launches 6–10 parallel agents (competitors, Gong calls, Zendesk, codebase), each writes a markdown file; Claude synthesizes. **(3) spec output** — a clean spec grounded in intent + research. (fact — reported behavior)
- Framed as the spec-first pattern (as at Notion) but with research parallelized via subagents. (opinion — the page's framing)

## The page's own Pass 2 ("What It Deeply Means") — recorded as claims

- **The closed verification loop is the entire engineering bet.** Code generation is commodity; verification is the contribution. With verification, the human's role shifts from "catching regressions" to "reviewing intent and design." 30% organic adoption is "a direct consequence" of trust. (opinion — strong)
- **Session velocity is a first-class infrastructure concern.** Latency affects *frequency of use*, not just speed; slow agents get batched/avoided. Maps to Notion's CI-speed argument (Ryan Nystrom). (opinion)
- **Specialization is technical debt.** Hundreds of agents = per-agent context/prompting/failure-modes/maintenance; "the right unit is the skill, not the agent." (opinion — load-bearing)
- **Skills are org knowledge, not just prompts.** "A prompt is a shortcut. A skill is a standard." The PM skill "raises the floor and makes the floor visible." (opinion)
- **L0–L3 as a forcing function**, not just a framework — makes adoption observable, creates a credible career signal. (opinion)

## The page's own Pass 3 ("Cross-Cutting Patterns") — recorded as claims

- **Build-vs-buy resolved by integration depth** — internal tools reach proprietary systems vendors can't; "a replicable decision criterion." (opinion)
- **Organic adoption as a quality signal** — mandate → surface compliance; voluntary → trust that compounds. (opinion)
- **Multi-interface accessibility** lowers the cost of reaching for the agent; matters for AFK workflows. (opinion)
- **Org AI architecture has a different shape** — "flatter in the middle, more capable at the edges." (opinion)
- **Tension: build requires org commitment** — "the lesson is not 'build your own Inspect'"; it's identify which integrations off-the-shelf can't reach and whether those gaps are load-bearing. (opinion — the page's honest hedge)
- **Tension: 50% AI-written ≠ 50% AI-reviewed** — review burden doesn't scale with generation unless verification is also automated; teams accrue "review debt." (opinion)

## The page's own Pass 4 ("second-pass research") — net-new facts it surfaced

- The in-sandbox agent runtime is **OpenCode** (open-source), *not* a Ramp-built loop; Inspect layers multi-model + integrations on top. (fact — corrects the page's own Pass 1)
- Each Modal Sandbox = full stack (Postgres, Redis, Temporal, RabbitMQ) + VS Code server + web terminal + **VNC/Chromium for visual verification** (before/after screenshots, navigates the real app). (fact)
- **Control-plane / data-plane split** (the "key architectural decision Pass 1 missed"): session state in **Cloudflare Durable Objects** (one SQLite DB per session), disposable sandboxes on Modal. Modal Functions = 30-min snapshot cron; Dicts = session locks + image metadata (enables multiplayer); Queues = route prompts from any client to the right session. This is why a days-built prototype scaled to hundreds of concurrent sessions without a rewrite. (fact — reported architecture)
- **Snapshot mechanism:** snapshots stored as diffs from base (only modified files persist); new session starts ≤30 min stale; sync to HEAD near-instant; "within a few seconds." (fact)
- **Figures moved:** Modal deep-dive (Feb 2026) ≈ half of merged PRs started by Inspect; **>80% of Inspect itself now written by Inspect** — "the tool builds itself." Page re-flags both as Modal-sourced / vendor-biased; 30% remains the conservative number. (fact-as-reported, explicitly caveated)
- **Build-vs-buy, sharpened (Ramp's words):** "Owning the tooling lets you build something significantly more powerful… After all, it only has to work on your code." The asymmetry (vendor builds for every codebase; you build for one) is the advantage. (opinion — quoted)
- **"Computer-use yourself" (the page calls this the most transferable idea, missed in Pass 1).** Sengottuvelu's "Fatal Flaw": bolting an agent on the *backend* forces an endless march to feature parity, one tool-interface per endpoint — a perpetual catch-up, and an org-structure problem. Ramp's fix: connect the model to the **frontend** — spin up a browser with the user's credentials, navigate Ramp's own UI; the user sees only the result. Gains feature-completeness day one, reuses the frontend team's work, inherits auth/permissions. "Before letting external agents computer-use your product, learn to computer-use it yourself." (opinion — strong, quoted)
- **Authorship:** Zach Bruggeman, Jason Quense, Rahul Sengottuvelu. Sengottuvelu (Head of Applied AI) was co-founder/CTO of Cohere (CX automation), acquired by Ramp May 2023; the scaffolding philosophy predates Inspect. (fact)
- **What this changes:** Inspect, the customer assistant, and the architecture pivot are "three applications of one principle" — don't build bespoke scaffolding; give a general agent the *real* environment (real frontend, real dev stack, real tools) and let it operate like a human. (opinion — the page's synthesized thesis)

## The page's own Application section (candidates it proposes for *this* system) — recorded as claims

The page explicitly marks these "extrapolation — not yet adopted." Recorded so pass 3 can audit them against ground truth:

1. **Verification gate inside the compound-agent loop** — `pnpm test` green + `pnpm typecheck` clean + screenshot/preview for any UI slice before marking a task done. Calls it "the most actionable item." Open: `/compound` vs `@task-runner` contract vs PostToolUse hook. (candidate)
2. **Skills as standards, not just process** — produce evaluable output (pass/fail an explicit bar) at gates; `/grill-with-docs` 3-question gate is the closest analogue. (candidate)
3. **Give the agent the real interface, not bespoke scaffolding** (new, Pass-4-surfaced) — before building a skill/tool-wrapper, ask whether the agent could be given the real thing; maybe a sharpening of an existing `10 · Principles` agent-native rule rather than a new principle. (candidate)
4. **Skill-not-agent / unified orchestrator** — treat the skill as the durable unit, the agent as orchestrator; new capabilities default to skills; the system's 8 specialist templates *could* become skill definitions. Page judges this **horizon** ("8 is small"). (candidate)
5. **Session velocity** — explicitly **no new action** at solo scale; revisit only if the system runs hosted/background agents. (candidate, self-deferred)

## The "What Doesn't Transfer at Solo-Developer Scale" table — the page's own honesty

The page tabulates each pattern → Ramp mechanism → solo equivalent → transfers? Verdicts: verification loop "principle fully, mechanism simplified"; skills-as-standards "partially"; computer-use-yourself "partially (Chrome MCP is the analogue)"; skill-not-agent "horizon"; session velocity "doesn't transfer yet"; L0–L3 "principle only." (fact — the page pre-discounts most of its own mechanisms for solo scale.)
