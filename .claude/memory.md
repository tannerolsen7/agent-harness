# Memory

Read every session. Short, durable corrections and working agreements that every agent must honor.

## Working agreements

### Notion vs. conversation — where things live (2026-07-13)
- **Notion is the store, not the conversation.** Deep research — sources, full findings, the actionable-upgrade tables — goes into the Notion Research library so agents and humans can refer back to it later. Write research there, in the `Research · <topic> (2026)` convention, as a child of the Research page.
- **The conversation is where we decide.** We talk through findings and pick actions in chat, not in Notion. Pull the actionable parts out of Notion into the conversation when it is time to discuss them.
- **Research must lead to a decision.** Every research page ends by driving to an action. "Do nothing" is a valid outcome, but it must be an explicit decision the human makes — not research that just gets filed and forgotten.

### Quality bar — Hobday's "absence of problems" (2026-07-13)
The owner's stated quality target: "this is the code quality we're going for."
- **Quality = the absence of problems.** You raise it by getting better at *finding* problems (adversarial lenses, fuzzing, evals, CI) — not by asserting quality.
- **Measure it two ways, keep both:** an objective measure (e.g. bugs reported / CI) AND expert judgment. "Test with many people and have many experts look." Our four adversarial `/cr` lenses + server-side CI are exactly this split — don't drop either side.
- **Six signals of software quality:** reliability, speed, clarity, efficacy, efficiency, beauty. For the harness's *own* code (a CLI/agent tool), the ones that matter are reliability, clarity, efficiency, speed — not beauty. Beauty applies to product UIs and the dashboards.
- **The 20 interface QoL rules are for product UIs** (applied via `@ux-reviewer`), never for the harness's scripts/hooks.
- **Cap it at the north star:** build the minimum that solves the problem — then make *that* scope genuinely free of problems. Don't chase perfection past its diminishing returns.
- Full framework: G6 Notion page ("Tools, Craft & Working Principles"), §5b.
