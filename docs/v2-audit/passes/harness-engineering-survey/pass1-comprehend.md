# Pass 1 — Comprehend: "Harness Engineering & Agent-Ready Repos (Deep Survey)"

**Source:** Notion page `367e2971cd6281da8a88f04ab4f0d29a` (child of Research → AI-Native Engineering System).
**Status banner (verbatim):** "SNAPSHOT — canonical: false | status: frozen as of 2026-05-21." The page itself
warns its gap analysis "must not be used to make implementation decisions" and points at a separate delta
page (`369e…`). Session date 2026-05-21; "Complete — interview phase pending."

This pass reports what the article *says*, faithfully. The article embeds its own gap analysis and priority
map — per instructions, those are treated as the author's **claims**, not inherited fact. Tags: (fact) =
externally checkable assertion the article attributes to a source; (opinion) = the author's judgment, framing,
or self-assessment of "our system."

---

## Part 1 — The intellectual landscape (the origin narrative)

The article's spine is that between Feb–May 2026 "harness engineering" became a named discipline. Its claimed
timeline:

- (fact, attributed) **Feb 5 — Mitchell Hashimoto** coins "harness engineering": *"Anytime you find an agent
  makes a mistake, you take the time to engineer a solution such that the agent never makes that mistake
  again."* Ghostty's AGENTS.md offered as the canonical example — every line maps to a past agent failure.
- (fact, attributed) **Feb 9 — Stripe Minions Part 1:** 1,000+ PRs/week by unattended agents; the lesson is
  *"it almost has nothing to do with the AI model… everything to do with infrastructure Stripe built for human
  engineers years before LLMs existed."*
- (fact, attributed) **Feb 11 — Ryan Lopopolo (OpenAI):** a team shipped a production product with zero
  hand-written lines; 1M lines generated, 1,500 PRs merged, 3 engineers at 3.5 PRs/day.
- (fact, attributed) **Feb 12 — ETH Zurich (Gloaguen et al.):** across 60,000+ repos / 138-instance benchmark,
  LLM-*generated* context files **reduce** task success in 5/8 settings (avg −3%) and **raise** inference cost
  20–23%. Human-written files help only +4%, and only when minimal and precise. (This is the paper the article
  repeatedly leans on; arXiv:2602.11988.)
- (fact, attributed) **Feb 2026 — Hashimoto distills "Agent = Model + Harness."** LangChain cited: harness-only
  changes moved a coding agent 52.8% → 66.5% on Terminal Bench 2.0 (+13.7pp); max reasoning budget scored
  *worse* (53.9%) from timeouts.
- (fact, attributed) **Apr 2026 — Birgitta Böckeler (Thoughtworks):** the **guides-and-sensors** taxonomy from
  cybernetics. *Guides* = feedforward (system prompts, AGENTS.md, context pipelines). *Sensors* = feedback
  (evals, validation loops, output parsers, drift detectors).
- (opinion) The governing slogan the article adopts: **"The model is a commodity. The harness is the moat."**

## Part 2 — The five primary sources

1. **Agentic Platform Engineering (Saul Fernandez, DEV.to).** (fact) A **three-repo architecture**:
   `agent-library` (tool-agnostic brain: cumulative per-directory AGENTS.md "layers," explicitly-invoked
   "skills," always-on "rules," a `library.yaml` manifest), `agent-setup` (a `setup.sh` that reads
   `library.yaml` and deploys via symlinks), `resource-catalog` (Backstage-format inventory/map). (fact)
   Layers load cumulatively by path; Terraform rules don't load inside React. (fact) Disaster recovery: 3 git
   clones + `setup.sh` = full rebuild in <5 min. (opinion) "We have no equivalent of this separation."
2. **ECC — Everything Claude Code (affaan-m).** (fact, attributed) "178k ⭐," v2.0.0-rc.1, 30 agents, 135
   skills, 60 commands, multi-tool (Claude Code, Codex, Cursor, OpenCode, Gemini, Zed, Copilot). Notable
   sub-claims: SOUL.md; **Instincts** (patterns auto-generated from git history, applied continuously);
   plugin-style **Memory** reinjected into the agent loop; PreToolUse/PostToolUse/Stop/SubagentStop hooks;
   **AgentShield** (a security scanner for the harness itself: 1,282 tests, 98% coverage, 102 rules);
   `agent.yaml` manifest + per-tool adapter folders; a "Hermes" self-improving loop. (opinion) "ECC is what
   our system would look like if we made it… a north star." (opinion) Gap claimed: "We have no AgentShield
   equivalent… no hooks layer."
3. **Nimbalyst (Karl Wirth, MIT).** (fact) A local desktop visual workspace for Claude Code + Codex. (opinion,
   attributed) **Five pillars:** Context; Context graph (sessions/tasks/commits/files/decisions as linked
   nodes); Restraint (path-scoped rules + MCP permission controls); Empowerment (tools that touch live state —
   read logs, query DB, screenshot UI, run E2E in a loop); Visual interface. (opinion, attributed, quoted) *"A
   harness is context plus restraint plus empowerment. Strip those three out and what's left is a chat box
   pointed at a fast autocomplete engine."* (opinion) The "linking problem": features touch ~7 tools and the
   connections live in human heads; the missing layer is a context graph.
4. **AgentLint (0xmariowu + ecosystem).** (fact) "ESLint for your harness," scoring across Findability,
   Instructions, Workability, Safety, Continuity (+ opt-in deep checks). (fact, attributed) Evidence base:
   analysis of **265 versions** of Anthropic's Claude Code system prompt; 6 academic papers; claimed Claude
   Code hard limits — **40K char CLAUDE.md cap, 256KB file-read limit.** Ecosystem variants: `agents-lint`
   (giacomo, staleness CLI), `agentlint` MCP variant, `eslint-plugin-agentlint` (agent-accessible UIs).
   (opinion) HANDOFF.md is "particularly relevant."
5. **Stripe Minions architecture.** (fact, attributed) Four layers: **isolated devboxes** (pre-warmed,
   10-second spin-up, QA-isolated by default, no prod data/network); **hybrid orchestration "blueprints"**
   (deterministic nodes + agentic loops, alternating); **curated context "Toolshed"** (global rules used
   judiciously, subdir-scoped, a central MCP hosting ~500 tools with a small default set);
   **fast feedback + hard limits** (<5s cached local lint; **max 2 CI retry rounds then back to human**).
   (opinion, attributed) "Start with your developer environment… If those are solid, agents will benefit."

## Part 3 — 25 additional sources (recurring threads, condensed)

The table's load-bearing recurring claims (fact, attributed unless noted):
- **AGENTS.md is a briefing/interface contract, not documentation** (Kaplan; Augment; Harness.io); "only write
  what the agent cannot infer from the codebase" (ASDLC.io); module-level AGENTS.md owned by module engineers.
- **ETH finding restated:** LLM-generated files cost 2.45–3.92 extra steps/task (Augment).
- (fact, attributed) Anthropic internal benchmark via Augment: human-curated CLAUDE.md cuts wrong-pattern
  rewrites **40–60%** — but only human-curated.
- (fact, attributed) harness setup alone can swing benchmarks **5+ pp** (ai-boost trends report).
- (fact, attributed) Claude Code exposes **21+ lifecycle hook events** (claudelog); IMPORTANT keyword used only
  4× internally; >40K chars silently truncated (AgentLint analysis).
- (fact, attributed) VILA-Lab: ML-classifier approval automation grows auto-approve ~20% → 40%+, "84%
  reduction in permission prompts via sandbox."
- (fact, attributed) Carlini/Anthropic C-compiler: 16 parallel Opus 4.6 agents, 2,000 sessions, 100K-line C
  compiler — *"Most of my effort went into designing the environment around Claude."*
- (fact, attributed) Spotify Honk: 1,500+ AI PRs since mid-2024; key = verification loops.
- (opinion, the article's own) RoboRhythms 8-check: "We pass ~3/8."

## Part 4 — The article's own gap analysis (CLAIMS to verify, not fact)

The author self-grades "our system." Reproduced as the author's claims:
- (opinion) **BETTER than the field:** spec-first as a gate; compound-questions-before-merge hard gate;
  3 pre-grill discipline questions ("no public equivalent"); SOUL.md "deeper than ECC's"; changelog discipline;
  AFK-eligible gate; `docs/research/` with expiry signals; spec.md for Medium+ features; human walkthrough
  ritual before /cr.
- (opinion) **EQUAL (concept, missing impl):** cumulative layer loading (we have "single flat CLAUDE.md");
  skill manifest (we have "Notion pages," no `library.yaml`); session continuity (questions.md is task-scoped,
  not a persistent HANDOFF.md); context graph (flat files, no links); tool-agnostic brain (skills tied to
  Claude Code); hard retry limits ("no equivalent"); memory persistence (memory.md "manually updated").
- (opinion, the priority claims) **GAPS — missing entirely:** (1) **No hooks layer (CRITICAL)** — "we have zero
  hooks," "every safety rule depends on the agent reading it"; (2) no three-repo / cross-project skill sharing;
  (3) **no AgentShield / harness security audit** — "never been audited"; (4) **no sensors layer**; (5) no
  isolated execution environment (AFK blocker); (6) no `library.yaml` manifest; (7) no context-rot detection;
  (8) **CLAUDE.md likely too long** (>40K, too many IMPORTANT markers, includes auto-discoverable overview);
  (9) no specialist-agent routing protocol.

## Part 5 — Priority action map (the author's plan)

Tier 1 (immediate): write 3–5 hooks; run AgentLint; strip CLAUDE.md to <10K chars; `agents-lint` in CI.
Tier 2: `ai-library` repo; `ai-setup` symlink deploy; `skills-index.yaml`; persistent HANDOFF.md.
Tier 3: define 3–5 sensor signals; worktree-scoped PreToolUse write guard; context graph; AgentShield audit.

## Part 6 — The headline finding the article elevates

(fact, the author's chosen "most important counterintuitive result") **The ETH Zurich result:** comprehensive,
auto-generated, or already-discoverable context *harms* performance; the sweet spot is "minimal, human-written,
surgical intervention." (opinion) This "validates harness engineering over prompt engineering — you engineer the
*environment* so fewer instructions are needed." (opinion) The governing formula: **Agent = Model + Harness; the
harness is the moat; harness improvements compound across every future model.**

---

### What the article assumes about "our system" (recorded, not yet judged)

The gap analysis is written against a mental model of "our harness" that asserts, as of 2026-05-21: zero hooks,
no worktree write-scoping, no security audit, CLAUDE.md possibly >40K chars, skills tied to one tool, manual
memory, `/cr-feature` as the live reviewer, an `agentic-system-enabled` sentinel, "8 specialist agent
templates." Pass 3 tests each of these against the ground-truth map; several are already stale.
