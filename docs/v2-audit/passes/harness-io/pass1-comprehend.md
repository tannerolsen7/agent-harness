# Pass 1 — Comprehend: what the Harness.io article SAYS

Faithful restatement. Tags: (fact) = verifiable/attributed claim the article presents as established; (opinion) = the author's framing, judgment, or design position. The article is itself a curated research page (hypotheses, claims ledger, synthesis, application) — per instructions those internal passes are recorded here as **claims the article makes**, not inherited truth.

## 0. What the article is

A Notion research page (dated 2026-05-26) about **Harness.io the company** (a CI/CD / software-delivery platform vendor), explicitly distinguished from "harness engineering" the field (fact). Primary source: one blog post — Dewan Ahmed, "The Agent-Native Repo: Why AGENTS.MD is the New Standard," March 19 2026, Part 1 of a 5-part series (fact). Secondary: a Verdent.ai product review, April 2026 (fact). The page openly flags that it only accessed **Part 1 of 5** (fact, self-disclosed limitation).

## 1. Stated hypotheses and how the author scored them

- Author expected Harness's AI story to be "CI/CD product gaining AI features" → scored **confirmed**, but says the real insight is architectural: agents run **inside** pipeline stages, not alongside (opinion — author's own emphasis).
- Author expected the AGENTS.md blog series to be generic best-practice → scored **partially wrong**; the series has a specific thesis (below) (opinion).
- Author was **surprised** that Harness positions itself against "bespoke agent plumbing per team," selling the observation that ungoverned agent tooling fragments within a quarter (opinion / author reaction).

## 2. The central claims (the author's "Claims Ledger," reproduced as claims)

The article itself assigns confidence levels — recorded here verbatim as the article's own grading:

- **AGENTS.md is not static documentation; it is part of the execution surface.** Graded by the article "Verified (Harness position)" — i.e. it is a *stated position of Harness*, not an independent finding (opinion, attributed).
- **Module-level AGENTS.md should be owned by the module's engineers,** not a central platform team. Graded "Verified (Harness position)" (opinion, attributed).
- **When nobody owns agent tooling, every team builds its own version and consistency collapses within a quarter.** Graded "Primary-adjacent (experience claim)" (opinion / unfalsified experience claim).
- **50% of public AGENTS.md files are never modified after initial commit.** Graded "Primary-adjacent (Harness's own research)." The article's Source Reliability section explicitly down-rates this: it is a Harness claim, not an independent finding (fact about provenance; the statistic itself unverified).
- **Discovery-rate hierarchy:** root AGENTS.md = 100%, nested README = 80%, subdirectory = ~40%, orphan docs = <10%. Same status — Harness-sourced, not independently verified (the article says so explicitly) (unverified claim, honestly flagged).
- **Harness product taxonomy** (from Verdent.ai, graded "Verified"): *Code Agent* (IDE extension, Copilot/Cursor competitor); *AI DevOps Agent* (in-platform, generates pipeline YAML / IaC / troubleshooting); *Pipeline Agents* (AI workers inside pipeline stages with RBAC + audit logs — "the distinctive offering"); *MCP Server* (exposes Harness resources to external agents like Claude Code, Gemini CLI) (fact, secondary-sourced).
- **Clearest fit:** platform-engineering teams already standardized on Harness; "for a solo developer on Vercel + Supabase + GitHub, Harness is overkill" (opinion, secondary-verified).

## 3. The synthesis — the article's interpretation of what it means

- **Execution surface, not documentation.** The article's restatement of Harness's thesis: when an agent runs it reads AGENTS.md and *changes behavior*; a stale AGENTS.md doesn't mean stale docs, it means **the agent's behavior is wrong** (opinion / reframe). Practical consequence asserted: an execution surface must be owned by people who know what the code does → module engineers, not a docs/platform team (opinion).
- The article cross-links an **ETH Zurich finding** (human-written AGENTS.md: +4%; LLM-generated: −3% and +20–23% cost) and argues it is "consistent with" the execution-surface framing — auto-generation fails because the generator lacks execution knowledge (claim + the author's interpretive bridge; the ETH numbers are presented as fact, the causal link as opinion).
- **Agent-in-pipeline vs agent-alongside.** Most tools run *alongside* CI (agent writes, CI validates, human reviews); Harness runs agents *inside* stages so their actions inherit pipeline secrets, RBAC, audit logs, and rollback semantics (fact about the product architecture). Significance asserted: "if AI actions are inside the pipeline, they are governed; if outside, they produce outputs the pipeline then validates" — relevant for regulated/compliance environments (opinion / applicability judgment).
- **Consistency collapse pattern.** Ungoverned agent tooling → inconsistent behavior, quality floors, security policies, and exponential maintenance overhead as agent count grows (opinion / named failure mode). The article ties this to the **Ramp** write-up (hundreds of specialist agents → unsustainable → pivot to one unified agent + skills) and calls it "independent confirmation" (opinion — the author's cross-page bridge).

## 4. Cross-page connections the article draws

- **Basis + Harness:** Basis calls context files "canonical artifacts / ground truth"; Harness calls them "execution surfaces." The article asserts these are "two names for the same underlying principle: these files are not documentation. They determine what happens" (opinion / synthesis).
- **Linear + Stripe + Zapier:** all said humans retain accountability for AI work; Harness gives a *structural* answer — in-pipeline agent actions inherit the human audit trail; "RBAC as accountability infrastructure" (opinion / bridge).

## 5. The article's own "Application to This System" (extrapolation — explicitly labeled "not yet adopted")

Recorded as the article's **proposals**, not as facts about our harness:

- Treat **every line** of AGENTS.md / CLAUDE.md as execution surface: "if a line doesn't change agent behavior, remove it." Frame it as Basis's default-no at the line level + "Harness's audit standard." Proposed mechanism: apply this as the audit criterion **when running /scan-context**; flag non-execution lines for removal. The article asserts this "is already implied by the AgentLint check ('only write what agents can't discover themselves')" (proposal — and note it presumes `/scan-context` and an "AgentLint check" exist in our system).
- **Feature-area-scoped AGENTS.md** for event-vendor (vendor management, event creation, payment flows): each feature area should carry its own AGENTS.md / CLAUDE.md section maintained alongside the feature. Proposed mechanism: add one line to the **/compound** output template — after each AFK session, update the relevant feature-area section. The article ends with an **open question it cannot answer**: "does event-vendor currently have feature-area-scoped AGENTS.md files, or is everything in one root file?" (proposal + self-flagged unknown).

## 6. "What doesn't transfer at solo scale" (the article's own discount table)

The article explicitly concedes most of Harness is org-scale and does not transfer to a solo developer; only the **principles** transfer (opinion, and a useful honesty signal):
- Pipeline-native agents → "agent runs in GitHub Actions (simpler; no RBAC at agent level)"; principle of in-pipeline verification transfers, product does not.
- RBAC/audit for agent actions → "Claude Code permission model + PreToolUse hooks" is named as the solo equivalent (claim about our stack).
- Centralized governance → ".claude/ as the governance layer; compound agent contract as policy" (claim about our stack).
- MCP Server → "Supabase MCP + Vercel MCP are the equivalents" (claim about our stack).
- Consistency-collapse prevention → "Notion as skill source of truth; SKILL.md files as the enforcement" (claim about our stack).

## 7. The Design Challenge and Open Questions (article's framing)

- **Design Challenge:** audit CLAUDE.md + AGENTS.md, classify every entry as *execution surface* or *documentation*; move documentation to CONTEXT.md; then report "what % is actually execution surface vs documentation" and a "new target line count." The article stresses this is "not an aggressive trimming exercise … it's a precision exercise" (proposal / method).
- **Open questions the author would ask Dewan Ahmed:** (1) what did "consistency collapse within a quarter" actually look like; (2) what's in Parts 2–5 (unread); (3) how do pipeline Agents detect failure when an agent produces "plausible-looking output with a subtle bug"; (4) is the 50% statistic from public-repo analysis or customer data — provenance affects its weight (self-disclosed gaps).

## Bottom line of Pass 1

The article advances **one transferable idea** — *context files are execution surface, so every line must change agent behavior or be moved out* — wrapped around a **vendor product story** (Harness pipeline-native, RBAC-governed agents) the article itself says does not transfer at solo scale. Its strongest empirical hooks (50% never-modified, discovery-rate hierarchy) are flagged by the article as Harness-sourced and unverified. Its "Application" section makes two concrete proposals (line-level execution-surface audit; feature-scoped AGENTS.md) and presumes harness components (`/scan-context`, "AgentLint") whose existence in our system it does not verify.
