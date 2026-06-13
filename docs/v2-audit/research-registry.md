# Phase 1 — Research Article Registry

Exact enumeration of the Notion **Research** corpus (`notion.so/367e2971cd6281df8c99d02af2a2f011`),
fetched 2026-06-11. Purpose: provable, complete coverage for Phase 2. Every child page is registered
with a **type** and a **disposition** so coverage is auditable and proportionate (the governing rule:
nothing skipped silently; depth where it bears on the V2 decision).

**Disposition legend:**
- **3-PASS** — primary source; gets Pass 1 (comprehend) / Pass 2 (penetrate) / Pass 3 (apply vs
  CANONICAL-HARNESS-AS-IS), each separately persisted, each checked by a separate agent.
- **SYNTHESIS** — a 2nd-order page that already aggregates other articles in this corpus. Read once
  to cross-check our own synthesis; 3-passing it would double-count primary sources.
- **DEDUP** — near-duplicate of another entry (same topic/company). 3-pass the richer twin; scan this
  one only for deltas.
- **EXCLUDE** — workspace/infra page (queue, tracker, database), not a research article.

Counts: **45 article pages + 5 infra pages.** Proposed: ~34 3-PASS · ~6 SYNTHESIS · ~4 DEDUP · 5 EXCLUDE.

---

## A. Primary articles — company case studies & practitioners

| # | ID (short) | Title | Type | Disposition |
|---|---|---|---|---|
| 1 | 367e…cda3 | Agentic Platform Engineering (Saul Fernandez / Stripe Minions) | case study | 3-PASS |
| 8 | 36ce…298f | Shopify AI-First Engineering (Farhan Thawar / Bessemer) | case study | 3-PASS |
| 9 | 36ce…ef4e | Ramp — Inspect Agent, Agent Architecture & Org-Wide AI Adoption | case study | 3-PASS |
| 10 | 36ce…99b9 | Stripe Minions — Unattended Coding Agents at Scale (Steve Kaliski) | case study | 3-PASS (pair w/ #1; distinct author) |
| 7 | 369e…d016 | Spec-Driven Development & Agent Workflows at Notion (Ryan Nystrom) | case study | 3-PASS |
| 13 | 36ce…aabf3 | Linear — Context-to-Execution, Issue Tracking's End | case study | 3-PASS |
| 14 | 36ce…90b8 | Vercel — Agentic Infrastructure, Internal Agents, Deployment Layer | case study | 3-PASS |
| 15 | 36ce…702d | Every.to — Compound Engineering, /lfg & Plugin Architecture | case study | 3-PASS (compound source) |
| 16 | 36ce…f6b0 | Zapier — SKILL.md Architecture, AI Fluency, Org-Wide Transformation | case study | 3-PASS (skill source) |
| 17 | 36ce…1494 | 37signals — Agent-Accessibility Architecture (DHH) | case study | 3-PASS |
| 19 | 36ce…422a | Harness.io — Agent-Native Repos, Execution Surface, Pipeline Gov. | case study | 3-PASS |
| 20 | 36ce…2337 | Augment Code — Context Engine, Contractor vs. Employee | case study | 3-PASS |
| 21 | 36ce…48a0 | Packmind — Engineering Playbook, Context Drift | case study | 3-PASS |
| 22 | 36ce…e280 | CodeRabbit — AI-First Code Review, the Review Bottleneck | case study | 3-PASS (review source) |
| 36 | 376e…b59f | Ashby — AI-Native Engineering Process & Practices | case study | 3-PASS |
| 12 | 36ce…4cddb | Basis — Canon/Not-Canon, Context Maintenance, Agent-Native Org | case study | 3-PASS (canon/not-canon = core to memory model) |

## B. Topic deep-dives — directly load-bearing for V2

| # | ID (short) | Title | Type | Disposition |
|---|---|---|---|---|
| 23 | 36ee…1e20 | 12-Factor Agents (Dex Horthy / HumanLayer) | doctrine | 3-PASS (high priority) |
| 39 | 37be…44d2 | Loop Engineering — You Built the Harness, Not the Loop | doctrine | 3-PASS (high priority) |
| 37 | 37be…4e75 | /goal — The Loop Primitive vs. the Harness Pipeline | doctrine | 3-PASS (high priority) |
| 38 | 37be…cd8c | Commands vs. Skills — Authoring, Triggering, Where They Sit | composition | 3-PASS (high priority) |
| 44 | 37be…f2e | Recursive Self-Improvement — Verification Is the Scarce Capability | doctrine | 3-PASS (high priority; compounding) |
| 2 | 367e…d29a | Harness Engineering & Agent-Ready Repos (Deep Survey) | survey | 3-PASS (structure source) |
| 3 | 367e…35bf | Basis Monorepo Ergonomics for Agents (Deep Analysis) | deep-dive | 3-PASS |
| 4 | 367e…f5ac | Basis Monorepo Ergonomics for Agents (Full Analysis) | deep-dive | DEDUP of #3 (3-pass richer; delta-scan other) |
| 32 | 376e…12c5 | Code Review in the Agent Era — Latent Space & 15+ Co Survey | survey | 3-PASS (review source) |
| 35 | 376e…34f2 | Code Review in the Agent Era — Cross-Company Research | survey | DEDUP of #32 (delta-scan) |
| 33 | 376e…e059 | Bug-to-PR Automation — Automated Bug Triage | topic | 3-PASS |
| 31 | 376e…03a2 | When Is an LLM Call Worth It? — Decision Framework | doctrine | 3-PASS |
| 40 | 37be…4a71 | MCP Servers — What They Are, When It's Worth Building | topic | 3-PASS |
| 30 | 376e…9920 | Playwright MCP for Debugging — Browser Automation | topic | 3-PASS |
| 41 | 37be…83dc | Engineering Rigour for a 1–3 Person Team — Process Over Model | doctrine | 3-PASS (team-of-one fit) |
| 42 | 37be…4513 | AI-Pilling a Team — Readiness Framework, Filtered for Team of One | doctrine | 3-PASS (team-of-one fit) |
| 18 | 36ce…8c61 | Leland (Jake Lingwall) — Eight Principles for AI Builders | doctrine | 3-PASS (already in canon §10) |
| 45 | 37be…8452 | Addy Osmani's agent-skills — Study the Formats, Don't Install | doctrine | 3-PASS (anti-rationalization source) |

## C. Sandboxing / safety / unattended-execution cluster

| # | ID (short) | Title | Type | Disposition |
|---|---|---|---|---|
| 26 | 375e…4658 | Claude Code Dev Containers — Sandboxed Agent Execution | safety | 3-PASS |
| 27 | 375e…3060 | How Anthropic Contains Claude — Capability Boundaries, Egress | safety | 3-PASS (high priority; enforcement) |
| 28 | 375e…fe7b | Claude Code Auto-Mode Configuration — Reliable Long-Running Agents | safety | 3-PASS (autoMode is live on disk) |
| 29 | 375e…bc13 | Agent Sandboxing in 2026 — 10 Companies Blast-Radius Controls | survey | 3-PASS (high priority; enforcement) |
| 34 | 376e…826e | AI Automation Ecosystem Beyond the Giants — n8n/Make/Pipedream | landscape | 3-PASS (lower priority; adjacent) |

## D. Synthesis / derived pages (read once, cross-check — do NOT 3-pass as primary)

| # | ID (short) | Title | Why SYNTHESIS |
|---|---|---|---|
| 5 | 367e…01a3 | AI-Native Engineering — Every, Zapier, Basis & the Full Landscape | aggregates #8/#15/#16/#3 etc. |
| 6 | 369e…f54b | Research Delta — Current System State vs. Snapshot Analyses (05-22) | delta of system vs prior research |
| 11 | 36ce…2f13 | Research Synthesis — Cross-Company Patterns (Living) | living synthesis of the case studies |
| 24 | 36fe…f249 | Matt Pocock corpus synthesis (aihero.dev) | synthesis of an external corpus |
| 25 | 36fe…951b | Michael Madsen corpus synthesis (agenticsmith.ai) | synthesis of an external corpus |
| 43 | 37be…7b06 | DEW #158 — "Mostly Tangential, Two Real Residues" | self-described tangential; harvest the 2 residues only |

## E. Workspace / infra — EXCLUDE (not articles)

| ID (short) | Title | Reason |
|---|---|---|
| 374e…4658 | AI Engineering Queue | work queue |
| 19f8…6644 | Research Notes (database) | notes DB |
| 374e…d783 | Morning Brief | daily tracker |
| 374e…2828 | Learning Tracker | tracker |
| 374e…781c | Pending Actions | action list |

---

## Coverage accounting

- **3-PASS:** entries in A (16) + B (16, minus the 2 DEDUP = 16 listed, 14 three-passed +2 dedup) + C (5)
  = **~34 primary 3-pass articles.**
- **DEDUP (delta-scan only):** #4 Basis Full, #35 Code Review Cross-Company. (Plus #1/#10 kept as a pair
  since authors differ.)
- **SYNTHESIS (read-once cross-check):** #5, #6, #11, #24, #25, #43 = 6.
- **EXCLUDE:** 5 infra pages.

Total registered: 45 articles + 5 infra = **50 pages, all dispositioned.** No page is silently dropped.

## Fresh-research hooks (corpus gaps to fill in Phase 2, per "research is not bounded by the corpus")

Anticipated gaps the corpus likely won't answer, to be filled with fresh web/primary research and
persisted alongside the passes:
- Current Claude Code mechanics on **plugins/marketplaces as a harness distribution channel** (Phase 4).
- **Opus 4.8 capability delta vs Sonnet 4.6** — the basis for re-running canon Page 13's capacity audit.
- The actual **`skills`/plugin install + update** surface (for the bidirectional self-update design).
