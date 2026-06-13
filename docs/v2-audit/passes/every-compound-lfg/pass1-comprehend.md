# Pass 1 — Comprehend: What the Article Says

**Article:** "Research · Every.to — Compound Engineering, /lfg & Plugin Architecture (2026)"
**Notion id:** 36ce2971cd628159acacf5b55d29702d · **Research date in article:** 2026-05-26
**Primary sources cited by the article:** EveryInc/compound-engineering-plugin (GitHub, MIT); "Compound Engineering: How Every Codes with Agents" (Kieran Klaassen, every.to); "The Folder Is the Agent" (Kieran Klaassen, every.to). The article also states all claims derive from an *existing Notion landscape research page* treated as a reliable secondary.

This pass is faithful, not interpretive. Claims tagged **(fact)** = verifiable about Every's published system / plugin; **(opinion)** = the article's judgment, recommendation, or framing. The article's own "Application to This System" section is reproduced here as *claims the article makes about our harness* — to be verified in pass 3, not inherited.

---

## 1. Core thesis the article asserts

- **Compound engineering is a named methodology, not a tool.** Structure: `brainstorm → plan → work → review → compound`, each step with a distinct job. The plugin makes it runnable as one command (`/lfg`). **(fact** that Every names/structures it this way**)**
- **The value lives in the non-obvious design decisions**, not the plugin packaging. **(opinion)**
- **`/lfg` is the "unattended overnight run"** — the full loop runs autonomously and surfaces a PR, no human intervention between steps. Framed as "the AFK north star expressed as a shipped product." **(fact** about what `/lfg` is; "north star" framing is **opinion)**

## 2. Hypotheses the author logged before researching (and their verdicts)

- Expected "just a plugin architecture" → **partially wrong**: it is a full named methodology with documented failure modes; "they eat their own cooking publicly." **(opinion/finding)**
- Expected "review = prompts" → **wrong**: three-tier conditional architecture with file-pattern routing, always-on reviewers, stack-specific personas. "This is engineering, not prompting." **(opinion)**
- Expected "one model" → **wrong**: multi-model routing by task type, encoded as routing rules in CLAUDE.md. **(fact** about Every**)**
- Surprised they **publicly documented failure modes**; the failure list is "the most transferable artifact in the research." **(opinion)**

## 3. The Claims Ledger (article marks all of these **Verified** against the plugin/articles) — **(fact)** unless noted

1. `/lfg` is a fully autonomous pipeline brainstorm → plan → work → review → compound, no human intervention between steps.
2. `/lfg` is the unattended overnight-run pattern.
3. Plugin contains **50+ agents and 38+ skills**.
4. **STRATEGY.md** is a pre-loop layer capturing product intent and architectural constraints.
5. **Brainstorm (divergent) and Plan (convergent) are intentionally separate**; conflating them causes premature commitment.
6. **Three-tier conditional review:** always-on, conditional (file-pattern triggered), stack-specific personas.
7. **Adversarial reviewer uses four techniques:** assumption violation, composition failures, cascade construction, abuse cases.
8. **Severity and routing are orthogonal:** a MUST-FIX can route to author, PM, or tech-debt backlog.
9. **Three modes of AI collaboration:** pair, delegate, orchestrate.
10. **Most teams operate only in mode 1 (pair);** leverage compounds in modes 2 and 3.
11. Kieran **routes by task type:** Claude Opus 4.6 primary; Gemini Pro and GPT-5 by cost/capability tradeoff.
12. **Opus lead + Sonnet sub-agents: ~90% better than single Opus on research tasks, but 15× more tokens** (citing Anthropic research).
13. **`/compound` must happen immediately after review;** delayed compounding loses nuance.
14. **Failure modes** (list): encoding disasters, context drift, agent stalls, non-determinism, compounding timing criticality, skill cache issue, cross-skill file-reference breaks.

> The article itself flags **one unconfirmed stat**: feature time-to-ship (>1 week → 1–3 days) is from a Quick-Reference stats page, not attributed to a specific source article. **(article's own caveat)**

## 4. Synthesis points the article draws (its own analysis)

- **STRATEGY.md is the missing middle layer.** Most systems have only high-level product context (too vague for agents) and low-level code context (CLAUDE.md/AGENTS.md). STRATEGY.md sits between: product intent + architectural constraints, too specific for a README, too high-level for implementation rules. Agents read it **before any planning**. **(fact** Every has it + **opinion** it's the named solution to the solo/small-team gap**)**
- **Brainstorm-before-plan is a structural rule, not style.** Conflation → agents commit before exploring; plans technically correct but miss better alternatives. Premature commitment is "a failure mode at the planning level, not just implementation." **(opinion** built on Every's structure**)**
- **Three-tier review is an engineering system, not a prompt.** Routing is deterministic (file patterns); always-on tier is guaranteed; adversarial reviewer runs on every PR. Framed as "post-training red-teaming applied to code review." **(opinion** framing over **fact** structure**)**
- **Severity/routing orthogonality is "the cleanest design insight" and "most transferable" to `/cr-feature` output.** Conflating the two produces *false blocking* (medium findings needing product decisions block merges; high-severity tech-debt never gets triaged). **(opinion)**
- **Failure modes documented publicly = rare candor**; "not theoretical — a 6-person team hit them in production." **(opinion** + **fact** about the source**)**

## 5. Cross-page connections the article asserts

- **Confirms the "blueprint" pattern (Stripe):** `/lfg`'s five steps are deterministic nodes; the agent has agentic freedom only inside "work" and "review"; the *sequence is fixed*. Article says the blueprint pattern appears independently in Stripe (formally named) and Every (unnamed but structurally identical). **(opinion/cross-reference)**
- **Extends a three-mode taxonomy:** pair/delegate/orchestrate maps to "the system's AFK architecture" — pair (interactive), delegate (AFK single task), orchestrate (AFK parallel worktrees). **(opinion** about mapping**)**
- **Failure modes are "the adversarial layer this research has been missing";** context drift, skill cache, cross-skill file breaks are "directly applicable to this system." **(opinion)**

## 6. The article's own "Application to This System" (extrapolation — **NOT yet adopted**, per the article's heading) — treat as CLAIMS to verify in pass 3

- **C-A: Add STRATEGY.md** to `.claude/` for event-vendor. Claims the system "currently has CLAUDE.md (engineering rules), CONTEXT.md (domain knowledge), and TASKS.md (current task state)." Would contain product direction, architectural bets in flight, non-self-evident constraints; read by the compound agent **before TASKS.md** every session. Open question it raises: *does CONTEXT.md already serve this?*
- **C-B: Severity/routing orthogonality in `/cr-feature` output.** Claims "the system's `/cr-feature` produces findings but doesn't distinguish routing from severity." Candidate: add a routing field (author / design-decision / tech-debt) alongside severity. Open question: *friction or reduction?*
- **C-C: Four adversarial techniques as a `/cr-security` upgrade.** Claims "the system's `/cr-security` is currently pattern-based." Candidate: add the four lenses as required passes / a required reasoning sequence. Open question: *additions to `/cr-security` or a new `/adversarial-review` skill?*

> Note for later passes: claims C-A ("currently has…"), C-B ("`/cr-feature`… doesn't distinguish"), and C-C ("`/cr-security` is pattern-based") are **assertions about our harness as of 2026-05-26**. Several name a `/cr-feature` skill. Ground truth must adjudicate these — do not inherit.

## 7. "What Doesn't Transfer at Solo-Developer Scale" (article's own transfer table)

- `/lfg` autonomous overnight run → **transfers fully** (the AFK compound agent session).
- STRATEGY.md → **transfers fully** (add to `.claude/`).
- 13+ reviewer system → **principle transfers; 5–7 scoped reviewers is "the right number solo."** **(opinion)**
- Adversarial reviewer → **transfers fully** (add to `/cr-security` as explicit passes).
- Severity vs routing → **transfers fully** (routing field on `/cr-feature`).
- Three modes (pair/delegate/orchestrate) → **"already in the system; naming is the remaining step."** **(opinion/claim)**
- Multi-model routing → **transfers fully** (model routing rules in CLAUDE.md).
- 50+ agent / 38+ skill plugin → **skills are the transferable unit; build selectively.** **(opinion)**
- Compounding timing criticality → **"already in the system: `/compound` is the final step before merge."** **(claim)**

## 8. Design Challenge the article sets

Redesign `/cr-feature` output so each finding carries **both** Severity (MUST-FIX / SHOULD-FIX / CONSIDER) **and** Routing (author / design-decision / tech-debt). Then produce: an example MUST-FIX/design-decision finding; an example SHOULD-FIX/tech-debt finding that would currently block a merge unnecessarily; and the new output schema as a concrete addition to the skill template. The article frames this as "the test of whether you understand orthogonality or just summarized it."

## 9. Open questions the author would ask Kieran (article's stated unknowns)

1. How often does `/lfg` *actually* run unattended vs. need mid-session intervention? (Failure modes suggest it isn't always reliable overnight.) Success rate? Which task categories succeed/fail?
2. How is the **skill cache issue** handled — does every `/lfg` run start a fresh session? What happens to session state between brainstorm and plan?
3. How does **STRATEGY.md stay current** — who updates it, when, what's the trigger? Drift → stale planning intent.
4. What do the **90% improvement / 15× token** numbers mean for economics? Consistent across task types or only complex ones?
5. What was the **fix for encoding disasters** — character normalization in the pipeline, or deeper in the harness?

---

**One-line of pass 1:** Every shipped compound engineering as a methodology (`brainstorm → plan → work → review → compound`) runnable as one autonomous command (`/lfg`), backed by a STRATEGY.md middle context layer, a deterministic three-tier review with a four-technique adversarial reviewer, severity/routing orthogonality, multi-model routing, and — uniquely — a publicly documented list of production failure modes.
