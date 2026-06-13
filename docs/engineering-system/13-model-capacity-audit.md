# Model Capacity Audit — Where the System Constrains the Model

*Universal patterns — adapt to your project.*

The system was built to prevent bad AI outputs — and it does. But constraints designed for less capable models accumulate, and over time the system starts operating at a fraction of what the current model can actually do. This page is a living audit: where the system constrains the model unnecessarily, what to do about it, and the principles for building future skills that stay in front of model capability rather than behind it.

> **Review cadence:** Revisit when your model provider ships a major model update or when you add three or more new skills. The question is always: was this constraint a response to a model limitation, or is it load-bearing reasoning discipline?

---

## The core distinction

Not all constraints are the same. They fall into two categories:

**Reasoning discipline** — constraints that make *you* think better, or that force genuine tradeoffs the model would otherwise paper over. These stay, because they're about your judgment, not the model's capability.

**Capability proxies** — rules invented because the model couldn't do something reliably. When the model can now do it, the rule is overhead.

The failure mode is treating capability proxies as reasoning discipline. They look the same from the outside — both are rules in a skill file. But one compounds your judgment. The other just slows the loop.

---

## Where the system is constraining capacity today

### 1. Structural forcing instead of goal-stating

**Where:** design-exploration skills (a fixed number of options required), visual-design skills (a fixed number of layout options required), prototyping skills (a fixed number of variations required), compound questions (a fixed number required, numbered).

**What's happening:** The system mandates a specific structure — 3 options, 5 variations — rather than stating the goal (don't commit before exploring the design space). The structure was the enforcement mechanism when the model would produce one option and stop.

**Current reality:** A current high-capacity model understands "explore the design space before committing" as a goal. It will produce multiple options without being coerced if the goal is stated clearly and the anti-pattern (committing to the first plausible layout) is named.

**Better pattern:**

```
Goal: explore the design space before committing.
Anti-pattern: producing one option and treating it as the answer.
Mechanism: if you've only considered one layout/approach, you're not done.
```

This lets the model choose 2 options when 2 genuinely covers the space, and 5 when 5 are meaningfully different. The number was a proxy for thoroughness. State thoroughness directly.

**What to keep:** The *reason* for the rule — name it explicitly in the skill. The model should know *why* it's being asked to explore, not just *how many* options to produce.

---

### 2. Anti-rationalization tables as distrust codified

**Where:** prototyping skills, `/tdd`, handoff skills — all may carry anti-rationalization tables with rationalization/rebuttal pairs.

**What's happening:** The tables encode specific ways the model used to game the rules, and the rebuttals are the corrections. They're essentially training data for a less capable model baked into the skill file. The model reads its own distrust and has to argue against it.

**Current reality:** These tables are still valuable for *new patterns* — places where the failure mode is genuinely non-obvious. But for well-established flows, the model knows why deleting prototype code matters. Telling it twice in a table format is overhead that consumes context without adding signal.

**Better pattern:**

- Keep anti-rationalization tables for *new* skills where failure modes are unknown
- For mature skills: collapse the table into a single "the trap to avoid" line with a reason
- Audit quarterly: if a rationalization hasn't been observed in 90 days of runs, it's a ghost rule — remove it

**What to keep:** The pattern itself. Anti-rationalization tables are the right format for genuinely novel failure modes. The mistake is leaving them in place after the model has internalized the rule. See [12 · Anti-Rationalization Tables](./12-anti-rationalization.md).

---

### 3. Context monitoring as percentage tracking

**Where:** handoff skills — trigger at a fixed ~60% context-used threshold.

**What's happening:** The fixed threshold is a proxy for the real signal (coherence degradation). The model was expected to count tokens or estimate percentage.

**Current reality:** The model is better served by the actual signal: "initiate handoff when you notice you're losing track of decisions made earlier in this session, or when the task would take more than one clean-boundary step to complete." The model can assess its own coherence. A percentage is an approximation of something the model can observe directly.

**Better pattern:**

```
Monitor your own coherence throughout. When you notice:
- You're unsure of a decision made earlier this session
- The task has more remaining work than fits in a clean single push
- You're about to start something you can't finish without context degradation
→ initiate handoff at the next clean boundary. Don't wait to be asked.
```

This is the goal. The percentage was a heuristic for reaching it. The model should aim at the goal.

---

### 4. STOP AND SURFACE conditions that are too broad

**Where:** Sub-agent contracts — "Domain area not covered by CONTEXT.md is touched."

**What's happening:** This condition, taken literally, means any undocumented code path stops the agent. That's not the intent. The intent is: don't make consequential decisions about domain behavior without validation.

**Current reality:** A capable agent can distinguish between "this function isn't in CONTEXT.md but it's obvious what it does" and "I'm about to make a business-logic call in undocumented territory." Treating these the same produces agents that surface trivial questions instead of making obvious decisions.

**Better pattern:**

```
STOP AND SURFACE when:
- A business-logic or data-model decision would need to be made without documented guidance
- The behavior of an undocumented domain concept is genuinely ambiguous
Do NOT stop for:
- Code paths that are locally obvious from their naming and tests
- Utility functions where the behavior is observable in tests
```

Name the distinction. The model will apply it correctly.

---

### 5. Skill descriptions that over-specify trigger conditions

**Where:** Every custom skill's YAML frontmatter description.

**What's happening:** Descriptions were tuned to fire on exact phrases. This prevents false positives but creates false negatives — the model doesn't fire a skill it should fire because the user phrased the request differently.

**Current reality:** The model's routing is substantially better than when the ~60-word target and narrow trigger phrases were established. Descriptions can now express intent and context rather than pattern-matching keywords.

**Better pattern:** Descriptions that answer two questions:

1. What outcome does this skill produce?
2. What situation signals it's needed — in terms of the *problem*, not the *phrasing*?

The trigger should be the situation, not the words. The model is good at situation-to-skill matching when the situation is described clearly.

---

### 6. The sentinel gate

**Where:** `/compound` automation, parallel agent dispatch, doc-updater activation — all gated behind a sentinel file (e.g. `.claude/agentic-system-enabled`).

**What's happening:** The sentinel gates agentic features to prevent them from activating on projects that aren't ready. It was a training wheel.

**Current reality:** This is a judgment call, not a capability issue. The question isn't "can the model handle agentic orchestration" — it can. The question is "is this project's context layer ready to support it?" That's still a valid gate, but the criterion should be the one-shot readiness checklist score, not the mere presence of a sentinel file.

**Recommendation:** Keep the sentinel, but document it as a readiness signal, not a capability unlock. When the one-shot score is 4+/5, enable the sentinel. When it's below 3/5, the sentinel won't save you anyway — the context layer isn't ready.

---

### 7. The compound questions as a required-output block

**Where:** feature-review skills — the compound questions are a gated required output.

**What's happening:** The requirement ensures the questions get answered. That's the right enforcement. But the structure — numbered questions with hard gate language — treats the model like it needs to be forced to reflect.

**What to keep:** The gate. "The review is not complete until all questions are answered" is load-bearing.

**What to change:** The framing. The questions exist because they surface non-obvious risk and process insight. Tell the model *why* each question exists, not just that it must answer them. A model that understands why it's being asked "what are you least confident about?" will give a more useful answer than one that's filling in a required field.

---

## What to never remove

Some constraints look like capability proxies but are actually reasoning discipline. These stay:

**The Phase 1 pre-grill (the human questions answered before the agent grills)**

This isn't about the model's capability. It's about your thinking. The point is that you form a prior before the model shapes your view. Remove this and you've rebuilt the failure mode it exists to prevent.

**The manual QA coverage blocker in `/grill-with-docs`**

An agent cannot close the loop on behavior it can't verify automatically. This is a structural fact, not a model limitation.

**The deletion rule for prototypes**

Prototype code surviving is not a model capability issue. It's an incentive structure issue. The rule is load-bearing because the correct behavior (delete it) runs against the momentum of the session.

**Destructive operation rules**

These are not capability constraints. They're safety constraints. Real-world incidents demonstrate the failure mode. The rules stay verbatim. See [10 · Principles](./10-principles.md).

**The tracer bullet first principle in `/tdd`**

This is a response to how AI generates code (complete solutions all at once), not a response to model quality. The model still has a tendency to outrun its headlights even when it's capable of doing each step correctly. The discipline is load-bearing.

---

## Principles for future skills

### 1. State the goal, not the mechanism

The mechanism was invented to reach the goal under model limitations. State the goal. Let the model choose the mechanism. If the model chooses a mechanism that doesn't work, name that anti-pattern specifically.

### 2. Name the failure mode, not just the rule

Rules without reasons are brittle. A rule that says "produce 3 options" breaks as soon as the situation is slightly different. A rule that says "don't commit to a design before exploring the space — the failure mode is producing one option and treating it as the answer" survives context changes.

### 3. Anti-rationalization tables for new skills only

When you build a new skill, you don't know the failure modes yet. Run the skill on hard tasks, observe where it games the rules, add those to the anti-rationalization table. For mature skills, collapse tables to single lines and remove entries that haven't been observed in 90 days.

### 4. Let the model assess itself

Context degradation, coherence, design-space coverage — the model can assess these directly. Proxy metrics (a fixed percentage, 3 options, 5 variations) were stand-ins for model self-assessment that wasn't reliable. It's more reliable now. Replace proxies with goals.

### 5. Distinguish safety constraints from quality constraints

Safety constraints (destructive operations, credential handling) stay unconditional. Quality constraints (exploration depth, reflection thoroughness) can be expressed as goals with named anti-patterns. Never conflate these — treating a quality constraint like a safety constraint makes the system brittle; treating a safety constraint like a quality constraint is how production incidents happen.

### 6. Write skill descriptions for situation recognition, not keyword matching

Descriptions that fire on phrases will miss equivalent situations phrased differently. Descriptions that characterize the *situation* will fire on any phrasing of the same situation. The model is good at this now.

### 7. Audit constraints when the model updates

Model updates change what's possible. What was a capability proxy six months ago may now be overhead. Schedule a constraint audit after every major model release. For each constraint, ask: "Is this load-bearing reasoning discipline, or is it a response to a model limitation that no longer exists?"

> **Dated capability note (e.g., as of 2026-06-13):** the current generation of high-capacity models (for example, the Claude Opus 4.x line) reliably handles design-space exploration, self-assessed context coherence, and situation-based skill routing without the numeric proxies that earlier models needed. Re-confirm this against whatever model you are actually running — model identity is the one specific worth naming in a capability audit, and only with a date attached so the claim ages honestly.

---

## The audit process

Run this against any skill file or process-doc rule:

```
[ ] State what this constraint prevents
[ ] Is the prevention about human judgment, or model capability?
[ ] If model capability: does the current model still exhibit this failure mode reliably?
[ ] If no: can the constraint be replaced with a stated goal + named anti-pattern?
[ ] Is there an anti-rationalization table? Is each entry still observed in practice?
[ ] Is the trigger condition for this skill based on situation or keyword?
[ ] Does the skill tell the model *why* it's doing each step?
```

Golden rule: **if you can't name a failure mode that the constraint prevents, the constraint is overhead.**

---

## Constraint status table — current custom skills

| Skill/Rule | Constraint | Type | Action |
| --- | --- | --- | --- |
| Design-exploration skill | Fixed number of options required | Capability proxy | Replace with goal + anti-pattern |
| Visual-design skill | Fixed number of layout options required | Capability proxy | Replace with goal + anti-pattern |
| Prototyping skill | Fixed number of variations required | Capability proxy | Replace with goal + anti-pattern |
| `/grill-with-docs` Phase 1 | Human questions before agent | Reasoning discipline | Keep |
| `/grill-with-docs` Phase 2 | Manual QA coverage blocker | Structural fact | Keep |
| Handoff skill | Fixed ~60% context trigger | Capability proxy | Replace with coherence goal |
| Sub-agent contracts | STOP AND SURFACE: domain not in CONTEXT.md | Too broad | Narrow to consequential decisions |
| Feature-review skill | Compound questions gate | Keep gate, reframe why | Reframe |
| Anti-rationalization tables (mature skills) | Rationalization/rebuttal pairs | Ghost rules risk | Audit quarterly |
| Skill descriptions | Narrow trigger phrases | Capability proxy | Rewrite for situation recognition |
| Sentinel gate | Agentic-system enabled flag | Readiness signal | Keep, document as readiness not capability |
| Prototype deletion rule | Delete all prototype code | Incentive structure | Keep |
| Tracer bullet first | Build end-to-end slice before expanding | Structural response to AI codegen pattern | Keep |
| Destructive operation rules | All destructive-op rules in your process doc | Safety constraint | Keep verbatim |

---

> This page is a living document. When you observe a constraint failing or succeeding in an unexpected way, add it here. When the model updates, run the audit process against this table.
