# Anti-Rationalization Tables

*Universal patterns — adapt to your project.*

LLMs are excellent at rationalizing why *this particular* task doesn't need the spec, test, or review. Anti-rationalization tables are pre-written rebuttals to lies the agent hasn't yet told.

Add these to your skill files. Each skill gets the rationalizations most likely to be used to skip *that specific* skill.

> The most distinctive and stealable idea in this layer: pre-written rebuttals attached to the step most likely to be skipped. Tables updated with real rationalizations observed in production.

---

## Real rationalizations observed in production

These are not hypothetical. Both occurred on a real project before the system was set up there.

**Incident 1 — Credential search rationalization:**

Agent needed credentials for a browser-automation screenshot. Couldn't find username/password. Started searching for the root-level service credential — full access to all data — to generate a login link instead. Rationalization: "I need to complete the task. I'll find another way to authenticate."

**Incident 2 — review skip rationalization:**

After implementing a feature, agent skipped `@reviewer` entirely. When caught, confirmed it had deliberately skipped it. Also wrote to memory.md autonomously without human review. Rationalization: "Tests pass and the build is clean. The review step isn't necessary here."

Both happened because the system wasn't set up on that project. The rules existed elsewhere. They didn't exist where the work was happening.

---

## For `/feature` — Phase 0 (scope and clarity check)

Add this table to Phase 0 of the `/feature` skill:

| Rationalization | Rebuttal |
| --- | --- |
| "This is too small to need /grill-with-docs" | Tiny features still have hidden assumptions. /grill-with-docs takes 5 minutes. Fixing a wrong assumption takes hours. Run it. |
| "The task is clear, Phase 0 scope check isn't needed" | Phase 0 exists because tasks are never as clear as they appear. If you're certain, confirming takes 2 minutes. |
| "I'll write the TESTING.md entry after" | There is no after. The spec is written before the test. The test is written before the code. This is the order. |
| "This is a refactor, not a feature, so /feature doesn't apply" | If it changes behavior or touches more than one file, /feature applies. |
| "The plan is obvious, I don't need approval before writing code" | The plan phase exists because what seems obvious to you may be wrong in ways you haven't considered. Get approval. |
| "We're already mid-implementation, /to-issues would interrupt the flow" | The human asking "did you use /to-issues?" is the interrupt. Stop. Run /to-issues. A process question from the human is not rhetorical — it is a direct instruction. Momentum is not a reason to skip a step; it is how steps get skipped. Observed in production. |

---

## For `/tdd` — Before writing any test

Add this table to Step 0 or Step 1 of the `/tdd` skill:

| Rationalization | Rebuttal |
| --- | --- |
| "I'll write the test after the implementation" | There is no after. A test written after implementation is a transcription, not a spec. Write the failing test first. |
| "This function is too simple to need a test" | Simple functions break in simple ways. One edge case, one null, one wrong type. Write the test. |
| "I'll just verify it works by running the app" | Manual verification is not a test. It doesn't run on the next PR. Write the test. |
| "The behavior is obvious from the type signature" | Types describe shape. Tests describe behavior. They are not the same thing. |
| "I can't write the test first because I don't know the interface yet" | Then you're not ready to implement. Stop and design the interface first. |
| "Tests pass, so it's correct" | Passing tests are evidence, not proof. They prove the behaviors you tested. Did you test the right behaviors? |

---

## For `@reviewer` — Before declaring done

Add this table to the synthesis step of the `@reviewer` skill:

| Rationalization | Rebuttal |
| --- | --- |
| "@reviewer is overkill for this small change" | @reviewer is 4 passes. It takes minutes. It catches layer violations and footprint issues that tests don't. Run it. |
| "I reviewed it myself, @reviewer isn't necessary" | Self-review misses what familiarity hides. The passes are designed to catch what you can't see. Run it. |
| "Tests pass, the feature is done" | @reviewer catches things tests can't: layer violations, naming drift, unused imports, doc drift. Tests green is not done. |
| "I'll run @reviewer before the full /cr" | @reviewer runs after each task. /cr runs before merge. They are not the same gate. Run @reviewer now. |
| "The build is clean and tests pass, the review step isn't necessary here" | This is the exact rationalization observed in production. The agent skipped the review, the developer caught it before commit. Tests passing is not the same as @reviewer passing. Run it. |
| "The compound questions are optional if the review is otherwise clean" | They are not optional. They are the last required output of @reviewer. An empty answer block means the review is incomplete. A clean review against a wrong assumption is a clean review of the wrong thing. Fill all four before proceeding to /cr. |

---

## For `/cr` — Before merging

Add this table to Step 0 of the `/cr` skill:

| Rationalization | Rebuttal |
| --- | --- |
| "I ran @reviewer, /cr is redundant" | @reviewer is per-task. /cr runs against the full branch diff and catches drift across tasks. They catch different things. |
| "This is a small branch, /cr isn't needed" | Branch size doesn't determine what /cr catches. Architectural drift, readability decay, and doc contradictions don't scale with PR size. |
| "The deadline is today, I'll run /cr after" | There is no after merge. Run /cr before. If it finds something, you want to know now. |
| "The branch has been reviewed in @reviewer already" | @reviewer reviews task by task. /cr reviews the cumulative effect. They are not interchangeable. |

---

## For `agent-contract.md` — Before spawning a sub-agent

Add this to the agent-contract template preamble:

| Rationalization | Rebuttal |
| --- | --- |
| "The task is simple, a contract isn't needed" | Simple tasks drift. The contract's SCOPE field is the hard boundary. Without it, the agent decides scope. |
| "I'll fill the contract out after the agent starts" | The contract is the input, not the output. Fill it before spawning. |
| "The agent knows what to do from the conversation" | The agent has no conversation history. It has what you put in the contract. Fill every field. |
| "STOP AND SURFACE conditions don't apply here" | They always apply. The conditions exist because agents guess when they should stop. Guessing is how scope expands. |

---

## For destructive operations and credentials

Add this table to your primary agent rules file or memory.md seed entries. These are not skill-specific — they apply in every session.

| Rationalization | Rebuttal |
| --- | --- |
| "I need to complete the task. I'll find another way to authenticate." | Stop. Ask the human for credentials explicitly. Never search the codebase for credentials to complete a blocked task. The task is not worth a security incident. |
| "This credential is probably scoped to just what I need" | Treat every credential as root-level access. This is not a guideline — it's a hard rule. In a real 2026 incident an agent deleted a production database in seconds by assuming a token was scoped. |
| "I found a root-level service credential in the environment file. I'll use it just for this" | NEVER. A root-level service credential has full access to all data. If you cannot complete the task without it and the user hasn't explicitly provided it for this purpose, stop and ask. |
| "I'll generate a login link using the service credential to take a screenshot" | This is exactly what happened in a real production incident. The agent couldn't find credentials, found the root-level service credential, and was about to use it to authenticate for a screenshot. Stop. Ask. |

See also → [10 · Principles](./10-principles.md) for the destructive operation rules these rebuttals enforce.

---

## For memory.md writes

Add this to any skill or session that involves updating system files.

| Rationalization | Rebuttal |
| --- | --- |
| "I'll add this to memory.md since it's a useful rule" | memory.md is only written by the session-end hook proposing candidates and the human approving them. Never write to memory.md autonomously. |
| "The rule is obvious enough that I don't need human review" | The review exists because agents are not reliable judges of what belongs in memory.md. Propose it. The human decides. |
| "I'll update memory.md now while I remember" | Use the session-end hook. It runs at session end and proposes everything at once for a single review decision. Mid-session writes bypass the human review step. |

---

## For `/handoff` — Context monitoring

Add this table to the session start rule in your agent rules file and to the `/handoff` skill:

| Rationalization | Rebuttal |
| --- | --- |
| "I can finish this slice before handing off" | The 60% threshold exists because finishing at 85% produces degraded work. Stop at the next clean boundary, not when you're done. |
| "The task is almost done, handoff would interrupt the flow" | Momentum is how quality slips unnoticed. Interrupt the flow. |
| "The human didn't ask me to monitor context" | Monitoring context is not optional. Degraded output without warning is a system failure. |
| "I'll just compact the context instead" | Compaction is not a substitute. It loses decision history the next task depends on. Use it between unrelated tasks, not mid-feature. |
| "The handoff contract takes time to write" | A degraded agent writing a handoff takes longer and produces a worse contract than a healthy agent doing it at 60%. Do it early. |

---

## For `/prototype-interface` — Before or after /design explore

Add this table to the `/prototype-interface` skill:

| Rationalization | Rebuttal |
| --- | --- |
| "The text options from /design explore are clear enough" | If they're clear enough to choose from, don't run /prototype-interface. If you're running it, they weren't clear enough. The trigger condition is the test. |
| "I'll keep the prototype as a starting point" | The prototype is a question, not an answer. Delete it. Start clean from the contract. |
| "The prototype revealed the right design — I'll just build on it" | A prototype built for exploration cuts corners that production code cannot. Delete it and build correctly from /tdd. |
| "We're behind, I'll skip the report and just tell the human which one worked" | The report is why you ran this. The human's taste applies to the tradeoffs, not your summary. Produce the report. |
| "I only need one prototype, the answer is obvious" | If the answer is obvious, you shouldn't have triggered /prototype-interface. Build all viable options. The human picks. |

---

## For `/prototype-ui` — Before the Plan step

Add this table to the `/prototype-ui` skill:

| Rationalization | Rebuttal |
| --- | --- |
| "The design is obvious, I'll just implement it" | If it's obvious, generate one variation and confirm. One variation takes 5 minutes. Wrong UI takes a sprint to undo. |
| "I'll ask the human what they want before generating" | Generate first, ask after. The human can't evaluate options they haven't seen. Show the space, then get feedback. |
| "All 3 variations look similar" | Then you haven't explored the space. Regenerate with explicit constraint: each variation must make a different primary UX assumption. |
| "I'll keep one of the prototypes as the starting point" | Delete all non-chosen variations. The chosen direction goes through Plan and /tdd. Prototype code is not implementation code. |
| "There's no DESIGN-CRITERIA.md, I can't run the UX pass" | Use the standard viewports. DESIGN-CRITERIA.md enriches the pass but isn't required to run it. |
| "The variations I generated cover the space" | Have you varied layout structure, not just styling? Interaction model, not just colors? State display approach, not just component placement? If not, you haven't covered the space. |

---

## For `/cr` — additional pass rationalizations

Add these to the existing `/cr` anti-rationalization table:

| Rationalization | Rebuttal |
| --- | --- |
| "Spec integrity is overkill — I know the spec didn't change" | Agents rewrite specs to match their implementation and are not reliable judges of whether they did so. This is the check you can't do yourself. Run it. |
| "The UX pass doesn't apply, there are no UI changes" | Check the diff first. If any component or style file changed, the UX pass runs. Don't decide from memory. |
| "The devil's advocate pass found nothing, I'll skip the attack vectors" | The attack vectors are the pass. "Nothing found" is a valid result for each. "Skipped" is not. |
| "The UX pass needs a browser-automation MCP, which isn't set up" | The UX pass is blocked without it. Surface this as NEEDS HUMAN, not as a reason to skip the pass. |

---

## The meta-principle

> **Process over prose.** A workflow with checkpoints beats a 2,000-word essay every time. If your skill file reads like reference documentation, it won't be followed under pressure. If it reads like a runbook with checkpoints and exit criteria, it will.

Anti-rationalization tables are what make a workflow a runbook rather than a suggestion. They close the escape hatches.

**How to add them to your skill files:**

1. Read the skill
2. Ask: what is the most likely reason an agent skips this skill or exits early?
3. Write the rationalization and the one-sentence rebuttal
4. Add the table to the step most likely to be skipped
5. Keep rebuttals short and direct — a paragraph is too long to be a rebuttal
