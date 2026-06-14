---
name: design
description: |
  System design skill with two modes. Use 'explore' when you don't
  know the right design and need options with tradeoffs before committing. Use
  'contract' when you know the design and need to formalize it into a handoff
  document for Claude Code. Triggers on: "I want to build X", "how should I
  structure this", "what's the best approach for", "help me design", "I need to
  add a feature", or any time a feature is described without defined inputs,
  outputs, or constraints. Always runs before /grill-with-docs for Small+ tasks.
---

# /design

> **Upstream skills required:** `/grill-with-docs`, `/tdd`, and `/to-issues`
> are from Matt Pocock's skills repo — not included here.
> Install once globally: `npx skills@latest add mattpocock/skills`
> See `.claude/INDEX.md → Required global skills` for details.

Two modes. Declare which at the start, or let the agent ask.

```
/design explore   ← don't know the right design, need options
/design contract  ← know the design, need to formalize it
```

For Tiny tasks: skip both. One behavior, the design is obvious.
For Small+: contract is mandatory. Explore is optional but recommended when uncertain.
For any task where agents will implement: run contract before handing off.

---

## Mode 1: /design explore

Run when you have a problem but not a design. Produces 2-3 options with
explicit tradeoffs. You pick one, then feed it into /design contract.

### Anti-rationalization

| Rationalization | Rebuttal |
|---|---|
| "There's only one reasonable approach" | Name it, then find two more. If they're worse, you now know why your choice is right. |
| "I already know what I want" | Then run /design contract. If you're here, you don't know yet. |
| "Exploration takes too long" | Implementing the wrong design takes longer. 15 minutes of options saves hours of rework. |

### The explore prompt

Paste this into a Claude Code session with your problem filled in:

```
Given this problem: [describe what needs to exist — the user need, not the implementation]
And this codebase context: [paste relevant CONTEXT.md section]
And these constraints: [paste relevant AGENTS.md architecture rules]

Propose 2-3 design options. For each:
- What layer owns this? (per the project's architecture — e.g. data, schemas, utils, components, routes)
- What is the public interface? (inputs, outputs, key types)
- What existing patterns in this codebase does this follow or break?
- What are the tradeoffs vs. the other options?
- What does this make harder in 6 months?

Do not implement anything.
Do not ask clarifying questions yet — state your assumptions explicitly.
Propose all options first, then recommend one with a one-sentence reason.
```

### What to do with the output

1. Read all options
2. Pick one — or ask for a hybrid with specific parts from each
3. Note which assumptions the agent made that need confirming
4. Feed the chosen option into /design contract

If the agent produces only one option: ask "give me two alternatives, even if you think they're worse."
One option is a recommendation disguised as exploration.

---

## Mode 2: /design contract

Formalizes a design into a handoff document. Run after explore (if used)
or directly when you already know the design. Output goes into
TASK-TEMPLATE.md and is the input to /grill-with-docs.

### Anti-rationalization

| Rationalization | Rebuttal |
|---|---|
| "The design is simple, a contract isn't needed" | Simple designs still have hidden assumptions. A contract takes 10 minutes. Wrong assumptions take hours to fix. |
| "I'll define the interface as I go" | The agent will define it for you. That's how you get designs you didn't want. |
| "I'll add the constraints later" | Constraints defined after implementation are just documentation. Define them before. |

### The four questions

Work through these in order. Don't skip to implementation.

**1. Business need**
- What user problem does this solve?
- What breaks for Monica if this doesn't exist?
- What is the minimum version that would actually be useful?

If the answer to the third question is smaller than what you're planning: cut to the minimum.

**2. Interface**
- What data or events trigger this? Where does that data come from?
- What shape is it? (TypeScript type, structure, optionality)
- What happens if input is missing, malformed, or unexpected?
- What does this produce or change?
- Who consumes the output? Sync or async? Loading and error states?

**3. Constraints**
- What must this never break or interfere with?
- What auth or security boundaries must it respect? (the project's access policies, tenant/owner scoping)
- Any performance requirements?
- What existing contracts elsewhere in the system must it stay compatible with?

**4. State ownership**
- Does this module own any state, or only transform data passed to it?
- If it owns state: what triggers a change? Who can read it?

### Simplicity check

After answering all four: *"What is the dumbest version of this that would still work?"*

Specifically look for:
- Parameters added for hypothetical future cases
- Things added because they seemed related, not because Monica needs them now
- Complexity justified by "it might need to"

If the user resists: *"What breaks for Monica if we leave that out?"* If nothing breaks, cut it.

### Handoff document format

Output of /design contract. Paste into TASK-TEMPLATE.md before running /feature.

```
# [Feature Name]
## What & Why
[One paragraph: the user problem this solves. Not implementation rationale —
user need. What breaks for Monica if this doesn't exist?]
## Context
[What already exists that this builds on. Name files explicitly so the agent
doesn't recreate them.]
## Done Looks Like
- [Specific, checkable output — what the user can see or do]
- [Tests that must pass]
## Interface Contract
Inputs:
- [name]: [TypeScript type] — [source, what happens if missing or malformed]
Outputs:
- [name]: [TypeScript type] — [consumer, sync or async, loading/error states]
Constraints:
- [What this must never break]
- [tenant/owner scoping must be preserved — never return another tenant's data]
State:
- [What state this owns, if any]
- [What triggers a change, who can read it]
## Out of Scope
- [Explicitly excluded thing and why]
## Relevant Files
- [path/to/file] — [why relevant]
```

### Critical sections — do not skip

**Interface Contract** — this is what separates a plan from a description.
If this section is vague, the handoff is not ready.

**Out of Scope** — naming what you decided not to build is as important as
what you did. It prevents agents from gold-plating and makes the contract
defensible in review.

**Done Looks Like** — must be checkable, not vague.
"Works correctly" is not done.
"Returns null from getEventById when eventId belongs to a different team" is done.

### The signal the contract isn't ready

If the agent has to guess anything during implementation, the contract has a
gap. Gaps found during /tdd should be surfaced immediately, not resolved
unilaterally. Surface them as open decisions in AGENTS.md.

---

## After the contract: decomposition

For Medium+ tasks, the contract feeds into decomposition:

1. **Find the tracer bullet** — which slice touches all layers (data layer → server action → component, per the project's architecture) and validates the architecture? Build this first.
2. **Map dependencies** — which slices must run before others?
3. **Label parallel vs. sequential** — parallel slices run in separate worktrees simultaneously. Sequential slices run in order.
4. **Verify each slice is independently shippable** — if a slice requires another to be meaningful to Monica, combine them.

Run /to-issues to generate the initial slice list, then apply this
decomposition logic to reorder and label before handing to agents.
