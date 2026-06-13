# Engineering System — Start Here

*Universal patterns — adapt to your project; specifics here are illustrative. This is the index for `docs/engineering-system/`.*

One page. Print it. Hand it to a new team member.

## Upstream skills are vendored (self-contained)

Some feature-loop steps come from upstream skill sets (e.g. Matt Pocock's). The harness is
**self-contained** (R4-D10): rather than relying on a global install, it **vendors** those skills
into `.claude/skills/` pinned to a reviewed SHA — so a project never silently loses a step.
`/grill-with-docs`, `/to-issues`, and the adopted `/prototype`, `/zoom-out`, `/triage`, `/to-prd`,
`/write-a-skill` are vendored (provenance: `.claude/skills/VENDORED.md`); `/tdd` is local; `/simplify`
is a Claude Code built-in. Nothing to install globally.

> Adapting these patterns to a *non-harness* project? Either vendor the upstream skills the same way
> (recommended — pin to a SHA), or install them globally (`npx skills@latest add mattpocock/skills`).
> The principle that travels: don't let a project silently lose a step.

Full reference: [11 · Skill Ecosystems](./11-skill-ecosystems.md)

---

## The four layers

Every AI-native engineering system has four compounding layers. Skip any one and you have AI assistance. Build all four and you have a system that gets better every PR.

Full reference: [02 · The Four Layers](./02-four-layers.md)

| Layer | What it is | Key files |
| --- | --- | --- |
| Context | Everything agents need to know before writing code | CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md |
| Pipelines | Automated review that enforces quality at every merge | @reviewer, /cr-security, /cr |
| Memory | Accumulated corrections and patterns that don't repeat | memory.md, RECURRING-FINDINGS.md, PITFALLS.md |
| Workflow | The discipline that makes all three compound | /design, /feature, /tdd, /compound |

---

## The feature loop

```
/design contract   define inputs, outputs, constraints
        ↓
/grill-with-docs   challenge the design against domain model
        ↓
TESTING.md spec    write confirmed behaviors before any code
        ↓
tracer bullet      one end-to-end slice that validates the architecture
        ↓
/tdd               slice by slice: red → green → commit
        ↓
/cr-feature        4-pass review: correctness, layers, tests, footprint
        ↓
compound Qs        what was hardest? what alternatives? least confident?
        ↓
/cr (pre-merge)    9-pass review against full branch diff
        ↓
/compound          capture what worked for the next agent
```

Full loop with all steps: 06 · Workflow Skills

---

## The five one-shot conditions

A feature is one-shottable when all five are true. Full scored checklist: [10 · Principles](./10-principles.md)

1. **Boundaries clear** — layer rules documented AND followed in existing code
2. **Patterns generalized** — golden exemplars designated per layer in AGENTS.md
3. **Context sufficient** — CONTEXT.md explains the domain without needing the code
4. **Skills exist** — /feature, /tdd, /cr-feature wired and running
5. **Tech debt not in the way** — no Priority 1 competing patterns in active files

Score below 3/5: fix competing patterns before adding more docs.

---

## The three setup prompts

Full prompts: Setup Prompts

| Situation | Prompt |
| --- | --- |
| New project | Prompt 1 — Project context intake |
| Existing project | Prompt 2 — Existing codebase review |
| After setup | Prompt 3 — Post-write validation |

---

## Where to start

**Reading:** 01 · Reading List — three articles, ~38 min total, before anything else

**New project:** 00 · Start Here — decision tree and numbered setup sequence

**Existing project:** run Prompt 2, then fix in priority order

**Full reference:** AI-Native Engineering System
