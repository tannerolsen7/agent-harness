# Pass 1 — Comprehend: "Vercel — Agentic Infrastructure, Internal Agents & The Deployment Layer (2026)"

Faithful restatement of what the article says. Curator passes inside the article (its
own Synthesis / Application / What-Doesn't-Transfer sections) are reproduced here as the
article's CLAIMS, not adopted as fact. Tags: (fact) = verifiable external claim the
article sources; (opinion) = the curator's interpretation or recommendation.

## Sourcing the article declares
- Primary, directly read: Occhino "Agentic Infrastructure" (CPO, Vercel, Apr 9 2026); "Introducing the new v0" (Vercel blog, Feb 2026).
- Secondary: ZenML LLMOps DB summary of a Malta Ubie conference talk (the 3 internal-agent examples + metrics originate here, not the original transcript); InfoQ on skills.sh; Techstrong.ai on Zero.
- Self-flagged unconfirmed: Zero (pre-1.0, unstable per Vercel's own docs); the "94% AI-project failure rate" (sourcing unclear, "rhetorical framing, not an established statistic"). (fact — these are the article's own reliability caveats.)

## Verified claims (article's "Claims Ledger", marked Verified against primary)
- 30%+ of all Vercel deployments are now initiated by coding agents. (fact)
- Agent deployments up 1000% in 6 months. (fact)
- Claude Code = 75% of agent deployments; Lovable+v0 = 6%; Cursor = 1.5%. (fact)
- Agent-deployed projects are 20x more likely to call AI inference providers. (fact)
- Three-layer framework (below) attributed to Occhino. (fact, as attribution)
- Preview URLs + immutable deployments are "prerequisites for agent loops, not DX upgrades." (fact, as Occhino's framing / opinion of his)
- Fluid compute is designed for AI workload shape (latency, concurrency, idle waiting). (fact)
- Workflows/Queues give pause, resume, retry, maintain state, offload background work. (fact)
- Sandbox = isolated execution for untrusted code; AI Gateway = single endpoint for 100s of models w/ budgets, routing, retries, fallbacks; AI SDK 6 adds a reusable "agent" abstraction. (fact)

## Secondary-verified claims (conference-talk-sourced)
- Internal lead-processing agent: 15 min/lead of manual research → agent researches + drafts, human personalizes/sends; "hundreds of days" saved (article notes this is the speaker's claim, not an audited metric). (fact w/ caveat)
- Anti-abuse agent: moderation decisions 59% faster. (fact w/ caveat)
- Data-analyst agent: SQL from English prompts. (fact w/ caveat)
- Agent-selection method: ask each department "What do you hate most about your job?" (fact)
- Workflow decomposition: identify trigger → steps → output, then replace steps with an agent. (fact)
- skills.sh ("npm for AI agents"): 20,000 installs within hours; Open Agents = OSS reference impl for background coding agents; Zero = agent-oriented language, pre-1.0. (fact)
- New v0: non-engineers ship via branch-per-chat → PR against main → deploy on merge. (fact)

## The article's three-layer framework (its central structural claim)
- **Layer 1 — infra for agents to deploy TO.** Preview URL per commit, immutable deploys, instant rollback, CLI/API/MCP access. Reframed as the prerequisite for the autonomous loop code→deploy→verify→ship: "without a URL, the agent cannot verify." (opinion / Occhino's reframing)
- **Layer 2 — infra for building/running agents.** AI SDK, AI Gateway, Fluid compute, Workflows/Queues, Sandbox, Observability — solving long-lived execution, multi-step orchestration, model routing, cost control, sandboxing. (fact as a product list; opinion as "these are THE structural problems")
- **Layer 3 — infra that is itself agentic.** On a latency spike / provider failure, Vercel autonomously queries observability, reads logs, inspects source, does root-cause, reviews fixes in sandboxes — "currently with human approval in the loop." (fact w/ the human-in-loop caveat)

## The article's own synthesis claims (treat as claims, not inherited fact)
- "Vercel plays both sides": simultaneously the largest user of agent deploys and the infra provider, so its bets are derived from observing millions of agent deploys, not a roadmap. (opinion)
- "Preview URLs are a prerequisite, not a feature" composes with Ramp (Inspect screenshots/live preview) and Basis (verifier sub-agent runs diff-scoped tests) — all three solve "agents need a running system to verify against." For event-vendor this is "already solved; the gap is whether the compound agent uses it." (opinion)
- "Start with what people hate" is "the most transferable methodology in this research" — filters for repetitive, clearly bounded, model-reliable, business-valuable, human-judgment-preserving tasks. (opinion)
- Workflows/Queues are "the infrastructure-level answer" to long-running agent sessions staying open. (opinion)
- skills.sh + Open Agents + Zero = an ecosystem/discovery play above infrastructure; owning discovery + reference arch + language = owning more of the stack. (opinion)
- v0 = "Ramp L3 (non-engineers shipping prod) expressed as a product." (opinion)
- Cross-page: "infrastructure-before-agents" now spans 5 companies (Shopify, Ramp, Stripe, Basis, Vercel); Vercel is the layer beneath the others. (opinion)

## The article's application candidates for event-vendor (explicitly "not yet adopted")
1. Preview-URL verification step for UI tasks: agent opens the Vercel preview, confirms changed views render before marking done; "requires Chrome MCP." Open question it raises: does the compound agent have browser access today? (opinion / candidate)
2. Workflows/Queues for long-running sessions — flagged a "horizon item"; says TASK-TEMPLATE's `human-checkpoints-complete: true` gate is "the correct design" and Workflows would make the between-checkpoint wait non-blocking. (opinion / horizon)
3. Apply "what do you hate most?" quarterly — names TASKS.md maintenance, PITFALLS.md updates, changelog entries as candidates. (opinion / candidate)
4. skills.sh as a discovery layer — "before authoring a new skill, run `npx skills add` and inventory what's available"; open Q: are skills.sh packages compatible with the system's SKILL.md format? (opinion / candidate)

## The article's "what doesn't transfer at solo scale" claims
- Three-layer infra, preview URLs, Fluid compute: "fully, as a user — already on Vercel." Workflows/Queues, AI Gateway: future / worth evaluating. Org-scale internal agent program: methodology transfers, scale doesn't. Zero: doesn't transfer yet. (opinion)

## The article's open questions (unresolved, posed to Occhino)
Approval cadence for "agentic infrastructure"; lead-agent failure-rate distribution; skills.sh supply-chain/quality control; what Zero is actually for; incident rate of agent- vs human-initiated deploys; why agent-built software calls AI inference 20x more. (fact that these are open)

## One-line thesis (faithful)
Agentic engineering is gated by pre-existing deployment infrastructure — preview URLs, immutable deploys, programmatic access, long-running compute — and the highest-leverage agents are the boring, bounded, verifiable tasks people already hate doing.
