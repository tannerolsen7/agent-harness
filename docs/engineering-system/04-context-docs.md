# Context Docs

*Universal patterns — adapt to your project.*

Templates and guidance for the core context layer. These are the documents agents read before writing any code.

> CLAUDE.md, AGENTS.md, CONTEXT.md, and PITFALLS.md live at the repo root and are read by any AI coding tool. The memory.md file lives in the tool config directory (`.claude/` for Claude Code, `.cursor/` for Cursor, or your tool's equivalent).

---

## SOUL.md

The engineering character of the system. Not process rules (those live in CLAUDE.md). Not architecture (AGENTS.md). Not domain knowledge (CONTEXT.md). SOUL.md is what doesn't change under pressure, across projects, across machines.

**What belongs in SOUL.md:**

- The north star definition of world-class code
- Engineering values the agent holds regardless of task pressure
- The non-negotiables — things the agent never compromises on
- The update mechanic (how this file itself gets improved)

**What does NOT belong in SOUL.md:**

- Process rules — those go in CLAUDE.md
- Architecture decisions — AGENTS.md
- Domain knowledge — CONTEXT.md
- Project-specific mistakes — memory.md
- Codebase traps — PITFALLS.md

SOUL.md is one page. If it's growing past a page, content is in the wrong file.

**Location:** `.claude/SOUL.md` (or your tool's config directory) — committed to the project repo, travels with it. Same content across all projects (populated by `/setup` from the canonical template). When you update the template, `/setup` propagates it to new projects.

**Relationship to global CLAUDE.md:** Global CLAUDE.md carries personal behavior preferences (how direct to be, when to push back, teaching style). SOUL.md carries engineering values (what the agent stands for, what it never compromises). Both travel everywhere; they answer different questions.

**Update mechanic:** SOUL.md is reviewed during `/compound`. If a new principle emerged from the session's work that should apply across all future work everywhere, the agent proposes an addition here. Human confirms. Nothing is written automatically. The proposal goes in the `/compound` draft file alongside `solutions/` and memory.md candidates.

**Template:** See Templates → SOUL.md ([./templates.md](./templates.md))

---

## CLAUDE.md

Process rules and coding discipline. Read at session start by any tool alongside global config.

**Sections to include:**

- Project overview (one paragraph)
- Tech stack (with one-line why per choice)
- Commands (dev, test, build, lint)
- Before writing code (must-dos before any implementation):
	- Read memory.md at session start (location: your tool's config directory, e.g. `.claude/memory.md` or `.cursor/memory.md`)
	- Skim `docs/solutions/README.md` — know what patterns are already solved
	- Read PITFALLS.md before writing in any affected area
	- Confirm task fits current scope
	- Surface open decisions rather than inventing answers
	- Ask before installing any package
	- Ask one clarifying question if ambiguous
- Development workflow (tiered pipeline table)
- Keeping docs current (table of what changes → what to update)
- Language and type rules (e.g. for typed languages: never suppress the type checker, never use escape hatches like `any`)
- Architecture rules (layer boundaries, where business logic lives)
- File and export conventions
- Code style (comment philosophy)
- Testing rules
- Safe-change rules (files that need explanation before modification)
- Destructive-operation rules (copy verbatim from [10 · Principles](./10-principles.md))
- Commit format
- Before finishing checklist
- NEVER list (hard rules, one per line)

---

## AGENTS.md

Product context, architecture, scope, and open decisions.

**Sections to include:**

- What this project is (one paragraph)
- Stack table
- Data flow (ASCII diagram)
- Routing table
- What exists in the codebase (organized by layer)
- **Golden exemplars** — one canonical file per layer that agents replicate. See [03 · File Structure](./03-file-structure.md) for the format and why this is the highest-leverage low-effort addition.
- Required reading before writing code (PITFALLS.md, memory.md, INDEX.md, `docs/solutions/README.md`)
- Scope (in scope / out of scope)
- Open decisions (unresolved — tasks touching these must stop and ask)
- Resolved decisions table
- Rejected patterns table
- Known limitations table

---

## CONTEXT.md

The *why* behind the project. The document a new agent reads to understand the domain without asking questions. This is the hardest document to write and the most valuable.

**What belongs here:**

- **Vision** — what does "done" look like at scale?
- **The flywheel** — how does each piece of infrastructure enable the next?
- **How we ship** — the unit of work, spec-first rule, what "small enough" looks like
- **Domain model** — entities and relationships in domain language, not implementation language
- **Live data flow** — how data moves through the system (ASCII diagram)
- **State machines** — any non-obvious state with frozen/invalid/live semantics
- **Business rules** — constraints invisible from reading the code; violating them produces production bugs

**What does NOT belong here:** implementation details, things that belong in ADRs, things obvious from reading the code.

**Building it:** Run `/grill-with-docs` before starting any feature. Don't write CONTEXT.md from scratch — let it grow through grilling sessions.

---

## PITFALLS.md

Codebase-specific traps that produce silent bugs.

**Format for each entry:**

```
## [slug-as-heading]

**Area:** which files or layers this applies to
**Rule:** the constraint, stated directly
**Why:** one paragraph on what goes wrong if violated
**Symptoms:** what the failure looks like at runtime
**Source:** where this rule came from (CONTEXT.md § X, pipeline Pass Y)
```

**How entries get added:**

1. Pipeline catches a finding 3+ times → promoted from `RECURRING-FINDINGS.md` (human confirms)
2. Known trap identified outside the pipeline → added directly

**Critical rule:** The canonical statement of a codebase-specific rule lives in PITFALLS.md. Pipeline pass prompts reference it by section heading rather than restating inline. This prevents drift.

---

## memory.md

Corrected mistakes. Read at session start.

Location by tool:

- Claude Code: `.claude/memory.md`
- Cursor: `.cursor/memory.md` or equivalent rules file
- Other tools: wherever your tool reads session-start instructions

**Format for each entry:**

```
name: short-descriptive-name
type: feedback | convention | gotcha | architecture
last_seen: YYYY-MM-DD

The rule, stated as a direct constraint.

Why: One sentence on why this matters for this project.

How to apply: Concrete instruction — what to do or check.
```

The `last_seen` field enables the quarterly stale review in `/compound` Step 10. Update it when the rule fires. See [07 · Memory System](./07-memory-system.md) for the full lifecycle and the session-end hook that proposes new entries automatically.

**Rules for adding entries:**

- Only add rules earned by real mistakes — not aspirational
- Add the entry before the session ends or it's lost
- Do not duplicate what's already in PITFALLS.md

**Seed entries to add on day one:**

- Destructive operation protocol (require explicit confirmation before any irreversible operation)
- Credential scope assumption (treat every token as root-level until proven otherwise)
- Staging isolation assumption (verify before assuming staging is separate from production)
- Pipeline tier selection (which tier for which work)
