---
name: review-strategy
description: |
  Orchestrates three adversarial reviewers against STRATEGY.md — PM lens,
  CTO lens, and Challenger lens — running in parallel as isolated sub-agents.
  Isolation is required: a PM lens that has already read the CTO critique
  softens its own findings. Run after /setup-strategy, when strategy shifts,
  or when /scan-context flags STRATEGY.md as stale.
---

## Prerequisites

- `STRATEGY.md` exists at repo root
- If not: stop — "STRATEGY.md not found. Run `/setup-strategy` first."

---

## Step 1 — Read context files (orchestrator only)

Read these before spawning lens agents. Pass content directly — do not ask agents to re-read.

- `STRATEGY.md`
- `CLAUDE.md`
- `AGENTS.md`
- `CONTEXT.md`

---

## Step 2 — Spawn three lens agents IN PARALLEL

Single message, three agent tool calls. Each lens receives only the file contents — no prior lens output. Contamination between lenses degrades findings.

Spawn these three simultaneously:
- `@strategy-lens-pm` — PM lens
- `@strategy-lens-cto` — CTO lens
- `@strategy-lens-challenger` — Challenger lens

Pass to each agent:
- Content of `STRATEGY.md`, `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`

---

## Step 3 — Consolidated summary

Collect all three lens reports. Produce:

```
## Strategy Review — Summary

**MUST REVISIT total:** [N] items across [N] sections
**Most flagged section:** [section name] — flagged by [reviewer names]
**Clean sections:** [list]

**Recommended action:**
[Revise now — MUST REVISIT items make STRATEGY.md unsafe for agents to act on]
[OR: Note and monitor — CONSIDER items only, strategy is actionable as-is]

**If revising:** focus on [most flagged section] first.
Run `/setup-strategy` in update mode, or edit directly and update `last-reviewed`.
```

---

## Hard rules

- All three lenses spawn every time — no skipping based on apparent quality
- MUST REVISIT means the strategy is unclear or contradicted enough that an agent acting on it would make wrong decisions
- CONSIDER means worth thinking about but not a blocker — don't inflate to MUST REVISIT
- Do not rewrite `STRATEGY.md` — surface findings only. The human decides what to change.
