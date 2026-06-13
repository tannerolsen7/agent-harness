# Pass 1 — Comprehend: "Linear — Context-to-Execution, Issue Tracking's End & Agent-Native Product Development" (2026)

**Source:** Notion research page `36ce2971cd6281769940f893374aabf3`, frozen 2026-05-26. Primary sources: Karri Saarinen (Linear CEO), "Issue tracking is dead" (2026-03-24); Rhea Purohit, "How we use Linear Agent at Linear" (2026-04-10); Linear changelog (Mar–May 2026); Ramp/Coinbase/Cursor customer stories.

This pass records what the page SAYS, faithfully. Each major claim tagged (fact) or (opinion). "(fact)" = verifiable/definitional or a reported metric; "(opinion)" = a normative or contestable judgment. The page is itself a curator write-up that already contains its own Hypotheses, Synthesis, Application, and "What Doesn't Transfer" sections — those are the *curator's* interpretation, recorded here as claims the page makes, NOT inherited as fact.

## The headline thesis

- **"Issue tracking is dead."** Saarinen's March 2026 post is framed as a thesis about the structure of software development, not a feature launch. (opinion — the page's own framing)
- Argument: issue tracking was built for a *handoff model* — PM scopes work, engineers pick it up later, the system manages the gap (prioritization, negotiation, routing). That made sense when engineering time was scarce and coordination expensive. (opinion, presented as historical fact)
- Agents change both variables. When agents absorb procedural work, planning and implementation *compress*; the gap issue tracking existed to manage *shrinks*. (opinion)
- What replaces it is "not better issue tracking" but a different system: one that captures context (feedback, intent, decisions, code) and routes it to the right actor (human or agent) through to execution. (opinion)
- Saarinen's reframe: **Linear is "the shared product system that turns context into execution"** — "not a tracker, a substrate." (opinion — strategic positioning)

## The structured-data insight (the page's claimed deepest contribution)

- "Agents are not mind readers. They become useful through context." (opinion)
- Ramp's internal coding agent can take a Linear issue to completion *because the issue is structured* — description, labels, linked customer feedback, related code, history. That structure is what the agent reasons from. (opinion / mechanism claim)
- An unstructured Slack message or freeform doc would produce a "different — worse — starting point." (opinion)
- Stated as the page's deepest insight: **structured issue data is not project-management overhead; it is the context layer that makes agent reasoning precise.** (opinion — strong)
- Generalized implication: "the quality of your task specifications directly determines the quality of your agent output." Page concedes this is "not a new insight" — confirmed by Notion's spec-driven dev, Stripe's Slack-to-issue, Ramp's L3 — but says Linear *quantifies* it: 60%+ of merged PRs. (opinion, leaning on a metric)

## Verified metrics (Claims Ledger — all tagged "Verified" by the curator)

- Coding agents installed in 75%+ of Linear enterprise workspaces. (fact — reported, primary: Saarinen)
- Volume of agent-completed work grew 5x in 3 months. (fact — reported)
- Agents authored ~25% of new issues. (fact — reported)
- Ramp's internal agent writes 60%+ of merged PRs using Linear as the structured context layer. (fact — reported, primary-adjacent / customer story)
- Linear Agent creates issues from Intercom without leaving the inbox. (fact — reported)
- Triage Intelligence flags duplicates, suggests labels, links Sentry/Datadog context. (fact — reported)
- Code Intelligence answers "why was this built this way?" and "who to talk to?" — launched 2026-05-13. (fact — reported)
- MCP support launched 2026-04-23; Linear Agent can pull external context from any MCP-connected tool. (fact — reported)
- Codex used for PR review at Linear; human makes final approval. (fact — reported)
- When an issue is marked Done, related Intercom feature requests reopen automatically. (fact — reported)
- "An agent cannot be held accountable" — humans retain accountability (Linear developer docs). (fact — reported as documented policy; the *normative weight* placed on it is opinion)

## The five-stage workflow ("how Linear eats its own cooking")

The page calls this "the most complete end-to-end loop in this research." (opinion)

1. **Intercom → Linear:** Linear Agent creates a scoped issue directly from the Intercom inbox, picking up back-and-forth + attachments; "the CX manager rarely adds anything." (fact — reported)
2. **Linear → Triage:** Triage Intelligence routes to the right team, flags duplicates, suggests labels, links Sentry/Datadog. (fact — reported)
3. **Triage → Engineering:** a PM uses Linear Agent to synthesize themes across overlapping requests, reorganize issues, draft implementation specs. (fact — reported)
4. **Engineering → Code:** engineer delegates to a coding agent within Linear; **the issue stays assigned to the human (accountability preserved)**; Code Intelligence provides codebase context; Codex reviews the PR; human makes final approval. (fact — reported)
5. **Merge → Customer:** when the issue is Done, related Intercom requests reopen automatically; CX follows up with every customer whose request shipped. (fact — reported)

- Claimed distinction: no other company in this research closes the loop "from customer feedback to shipped feature to customer confirmation with agents involved at every stage except human judgment gates." Called "the AFK north star expressed as a product development workflow." (opinion)

## The accountability principle

- Stated explicitly: an agent cannot be held accountable; delegated issues stay assigned to the human. (fact — reported policy)
- The page's reading: this is "not a limitation — it is a design principle." Accountability requires the ability to understand, explain, and own a decision; agents currently cannot. Linear enforces it structurally. (opinion)
- Cross-page claim: maps to Stripe/Ramp/Shopify ("humans review all agent output before merge"); Linear "names *why*: because accountability requires a human." (opinion)

## Skills as compounding organizational knowledge

- Linear Skills (launched March 2026): teams codify repeatable workflows as reusable slash commands, auto-triggered when relevant. (fact — reported)
- Mechanism story: a PM who finds that "synthesize themes across a feature catchall" produces useful output can save it as a skill; next time the pattern appears the skill is available to the whole team — "the floor rises." (opinion / mechanism claim)
- Page equates this to "the Ramp PM skill pattern applied at the product level rather than the Claude Code level" — different mechanism (native product UI vs repo skill file), identical principle: "repeatable processes encode organizational knowledge; once codified, anyone can use them." (opinion)

## The page's own Application section (curator self-application — recorded as candidates, NOT inherited)

Explicitly labelled "extrapolation — not yet adopted. Candidates only."

- **TASKS.md for agent-readability:** TASKS.md is "the system's equivalent of a Linear issue"; audit entries for Linear-issue properties (scoped description, explicit constraints, linked context). Concedes TASK-TEMPLATE.md "already does much of this." Open question raised: what % of compound sessions begin from a well-formed TASK-TEMPLATE vs ad-hoc. (opinion / candidate)
- **Skills as a compound-learning layer:** `/compound` does per-task capture; the candidate is one level up — when a pattern repeats across `/compound` outputs it should become a named skill, not just a memory entry. Proposed distinction: memory corrects behavior, principles set constraints, skills encode repeatable multi-step workflows producing evaluable output. (opinion / candidate)
- **Accountability principle named in the agent contract:** the system already enforces it structurally but doesn't *name* it; candidate is to add it as the stated rationale for STOP-AND-SURFACE, so the human gate is understood as permanent, not a temporary limitation to remove. (opinion / candidate)

## The page's own "What Doesn't Transfer at Solo-Developer Scale" table (recorded as claims)

- Full Intercom→Linear→GitHub loop → TASKS.md → compound agent → PR: "Principle fully — mechanism simplified."
- Triage Intelligence → /incident classification: "Principle only."
- Skills (team-level) → .claude/ skill files: "Fully."
- Code Intelligence → agent reading CONTEXT.md / PITFALLS.md / docs/solutions/: "Principle fully — mechanism different."
- Multi-role workflow (CX/PM/Eng) → single human, agents compress handoffs: "Partially — handoff elimination transfers, role specialization doesn't."
- Customer-loop close → manual follow-up or Supabase trigger: "Principle only at current scale."
- Accountability principle → already enforced via STOP-AND-SURFACE + walkthrough checklist: "Fully — naming it is the remaining step."

## Provenance / reliability the page itself flags

- "Code Diffs" and "Linear Coding Agent" announced "coming soon" in March 2026, not shipped as of research date — page says "treat as roadmap, not current." (fact — self-flagged)
- Ramp customer story labelled "marketing-adjacent (Linear describing their own customer's results)." (fact — self-flagged caveat)
- The 60% figure's source is a customer story, not Linear's own engineering post — "primary-adjacent." (fact — self-flagged)

## The Design Challenge the page poses (recorded, not executed)

Audit the last five compound agent sessions; classify each starting spec as **S** (structured), **P** (partial), **A** (ad-hoc); then correlate spec quality to outcome (merged cleanly / rework / abandoned), identify the most consequential missing field, and write the single rule that would most improve average spec quality. Framed as "the test of whether 'structured context enables better agent output' is actually true in your specific workflow, or just true in principle."
