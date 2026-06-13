# The Four Layers

*Universal architecture — adapt to your project.*

Every AI-native engineering system has four compounding layers. Skip any one and you have AI assistance. Build all four and you have a system that gets better every PR.

---

## Layer 1 — Context

**The principle:** Context is the moat. Agents without opinionated context produce generic code. Agents with it produce code that fits this codebase, this domain, these constraints.

**What "opinionated" means:** Generic is "check for type errors." Opinionated is "check that writes go through the project's data-access layer — direct mutation bypasses a domain invariant" (e.g., a helper that enforces a stickiness or ownership rule). The codebase-specific rules are the moat. Generic rules are table stakes.

**The documents:**

`CONTEXT.md` — the *why*. Vision, domain model, business rules, how you ship.

`AGENTS.md` — the *what*. Module responsibilities, layer rules, routing table, open decisions, resolved decisions, rejected patterns, golden exemplars.

`PITFALLS.md` — codebase-specific traps. Not generic advice — only things specific to *this* codebase that an agent gets wrong on first attempt.

`docs/adr/` — architectural decision records.

`docs/solutions/` — solved problems worth reusing. Run `/compound` to generate after a feature ships.

`docs/TESTING.md` — confirmed behaviors (the spec), what's tested, known gaps, mock infrastructure.

`.claude/memory.md` — corrected mistakes. Read at session start. Only rules earned by real mistakes.

`.claude/INDEX.md` — annotated index of external resources.

**Build and maintain the context layer:** → [04 · Context Docs](./04-context-docs.md)

---

## Layer 2 — Pipelines

**The principle:** Pipelines enforce taste automatically. If review depends on humans remembering to check things, it doesn't scale.

**Tier by scope:**

| Tier | When | Auto-fix |
| --- | --- | --- |
| Pre-commit hook | Every commit | No — lint, type-check, run changed tests |
| `@reviewer` | End of each feature task | No — surfaces only |
| `/cr-security` | Any auth, tenant/owner-scoping, or data-boundary change | Yes — high-capacity model |
| `/cr` (full) | Pre-merge against full branch diff | Yes — high-capacity model |

**The recurring-findings loop:** After synthesis, the pipeline writes to `docs/RECURRING-FINDINGS.md`. At threshold (≥3) or by judgment, findings are promoted to `PITFALLS.md`. The pipeline gets sharper every PR without manual curation.

**The compound step:** After a feature merges, run `/compound`. Traditional development stops at review. The compound step is where gains accumulate.

**Build the pipeline:** → 05 · Pipeline Skills

---

## Layer 3 — Memory

Three distinct documents. Easy to conflate — don't.

| Document | Source | Read by | Grows |
| --- | --- | --- | --- |
| `memory.md` | Human corrects agent in session | Every agent at session start | When mistakes are corrected |
| `RECURRING-FINDINGS.md` | Pipeline catches a finding repeatedly | Pipeline synthesis step only | Automatically on every pipeline run |
| `PITFALLS.md` | Promoted from findings, or added directly | Implementing agents before writing code | Via human-confirmed promotion |

A pattern can appear in all three: starts as a session correction → keeps getting caught in review → gets codified so agents avoid it at write time.

**Build the memory system:** → [07 · Memory System](./07-memory-system.md)

---

## Layer 4 — Workflow

**The principle:** Clear inputs produce predictable outputs.

**The task spec:** Fill before every agent task. Fields: TASK, SUCCESS CRITERIA, SCOPE (in/out), CONSTRAINTS, OPEN QUESTIONS, REFERENCES, SIZE ESTIMATE, COMPOUND QUESTIONS, BRANCH.

**The feature loop:**

```
Size → /design [explore →] contract (Small+)
     → /grill-with-docs → TESTING.md spec
     → tracer bullet first → /tdd (slice by slice)
     → /simplify → @reviewer → /cr-security (if triggered)
     → compound questions → type-check → commit → /cr (pre-merge) → /compound → merge
```

Full loop with all steps: 06 · Workflow Skills

**The sub-agent contract:** Every spawned agent gets a filled contract: GOAL, SCOPE (hard boundary), DECISIONS ALREADY MADE, REFERENCES, TDD REQUIREMENT, PIPELINE REQUIREMENT, BRANCH, STOP AND SURFACE conditions, SUMMARY FORMAT.

**The retry policy for MUST FIX items:**

- Stage 1: re-prompt original agent (one retry)
- Stage 2: fresh agent, no parent context, diff + MUST FIX list (one attempt)
- Stage 3: surface to user

Bypass immediately if: open decision touched, architectural redesign required, bug in pre-existing code, NEVER rule would be violated.

**Build the workflow layer:** → 06 · Workflow Skills
