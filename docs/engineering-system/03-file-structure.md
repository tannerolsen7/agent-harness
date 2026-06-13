# File Structure

*Universal patterns — the example tree is illustrative; each project defines its own layers.*

What to create and where it lives. Annotated so you know why each file exists.

> File locations shown use one common agent-tool layout. The patterns transfer across tools; the specific directory names do not. See the tool mapping table below for equivalents.

---

## Tool config directory mapping

Different agent tools store their configuration in different places. The roles are universal even when the paths differ.

| Role | Example layout | Equivalent in other tools |
|---|---|---|
| Agent config | `.<tool>/` | A tool-specific config directory |
| Skill / rule files | `.<tool>/skills/` | A rules directory or system-prompt store |
| Global config | `~/.<tool>/<config>.md` | A user-scoped global config file |
| Settings / permissions | `.<tool>/settings.json` | Workspace or tool-specific settings |

The project docs at the repo root (the process-rules doc, product-context doc, domain-model doc, and so on) are universal — every tool reads them.

---

## Full structure

The tree below is an illustrative example of where files can live. Treat it as a starting reference, not a mandate: the layers, directory names, and which docs you keep are all things each project defines for itself.

```
repo/
├── CLAUDE.md                    # Process rules, coding discipline, NEVER list
├── AGENTS.md                    # Product context, architecture, open decisions
├── CONTEXT.md                   # Domain model, business rules, vision, flywheel
├── PITFALLS.md                  # Codebase-specific traps (promoted from pipeline)
│
├── docs/
│   ├── TESTING.md               # Confirmed behaviors, test infra, known gaps
│   ├── ARCHITECTURE.md          # Layering model, tech debt, migration path
│   ├── RECURRING-FINDINGS.md    # Pipeline findings log (auto-updated by /cr)
│   ├── adr/                     # Architectural decision records
│   └── solutions/               # Solved problems worth reusing
│       ├── README.md
│       └── TEMPLATE.md
│
└── .<tool>/                     # Agent config directory (name is tool-specific)
    ├── SOUL.md                  # Engineering character — values, north star, non-negotiables
    ├── CLAUDE.md                # Session start: read SOUL.md + memory.md + TASKS.md + rituals.md
    ├── memory.md                # Corrected mistakes — read every session
    ├── rituals.md               # Weekly ritual tracking (last run dates)
    ├── INDEX.md                 # Annotated external resources
    ├── TASK-TEMPLATE.md         # Fill before every agent task
    ├── agent-contract.md        # Template for sub-agent briefs
    ├── AI-WORKFLOW.md           # Worktree lifecycle, git discipline
    ├── agentic-system-enabled   # Sentinel: present = agent orchestration authorized
    ├── settings.json            # Permissions allowlist, hooks
    ├── agents/                  # Project-scoped specialist agents
    │   ├── task-runner.md       # Orchestrator: coordinates specialists per task
    │   ├── explorer.md          # Codebase search specialist
    │   ├── spec-writer.md       # TESTING.md entry specialist
    │   ├── implementer.md       # TDD slice specialist
    │   ├── reviewer.md          # per-task review specialist
    │   ├── doc-updater.md       # /compound + solutions specialist
    │   └── security-reviewer.md # Access-control + auth specialist
    ├── hooks/
    │   ├── blast-door.sh        # PreToolUse: block dangerous commands
    │   ├── auto-loader.sh       # SessionStart: inject project context
    │   ├── auditor.sh           # PostToolUse: JSONL tool call log
    │   └── session-end.sh       # Stop: propose memory candidates
    └── skills/
        ├── feature/SKILL.md
        ├── cr/SKILL.md
        ├── cr-security/SKILL.md
        ├── compound/SKILL.md
        ├── queue/SKILL.md
        ├── setup/SKILL.md
        └── tdd/SKILL.md

~/.<tool>/                       # User-scoped config (travels across all projects)
├── <config>.md                  # Personal behavior config — applies across all projects
└── agents/                      # User-scoped agents (travel across all projects)
    └── explorer.md              # Generic codebase search (user-scoped copy)

Per worktree (when running /queue):
├── .<tool>/questions.md             # Blocked questions from this worktree's task
└── .<tool>/compound-draft-[slug].md # /compound draft before human review
```

---

## What to build first (by stage)

**Stage 3 minimum (plan-first, PR-only review):**

1. `CLAUDE.md` — scope, NEVER rules, destructive-operation rules
2. `AGENTS.md` — architecture, open decisions
3. `CONTEXT.md` — domain model (run `/grill-with-docs` to build this)
4. `docs/TESTING.md` — confirmed behaviors before writing any code
5. `settings.json` — permissions allowlist and hooks
6. the `@reviewer` agent — per-task review

**Add for Stage 4 (idea to PR):**

1. `PITFALLS.md` — starts empty, populated as patterns emerge
2. `memory.md` — starts empty, populated as mistakes are corrected
3. `/cr` skill (full pre-merge)
4. `/cr-security` skill (if auth/data access is involved)
5. `docs/RECURRING-FINDINGS.md` — wired into /cr synthesis step
6. `agent-contract.md` — once you're spawning sub-agents
7. `INDEX.md` — once external resources need to be findable

**Add when features are shipping regularly:**

1. `docs/solutions/` + `/compound` skill
2. `docs/adr/` — created by /grill-with-docs when needed

**Add when enabling agentic orchestration (/queue, parallel worktrees):**

1. `SOUL.md` — engineering character (from template)
2. `TASKS.md` — agent task queue (replaces a plain todo list; see the full TASKS.md spec)
3. `agentic-system-enabled` — sentinel file (empty, presence enables orchestration)
4. `agents/` — project-scoped specialist agents (from templates)
5. `hooks/` — auto-loader, auditor, session-end hooks
6. `/queue` skill + `/setup` skill

> **The sentinel scope:** the `agentic-system-enabled` sentinel gates agent orchestration features only — /queue, @task-runner, @doc-updater auto-compound, the auto-loader hook. It does NOT affect human developer workflows. Pre-commit hooks, pre-push hooks, manual git operations, and direct commits/merges all continue normally for any developer on the project, regardless of the sentinel.

---

## File ownership rules

Every shared file should have exactly one clear owner and a defined moment it gets updated. Ambiguous ownership is how docs drift.

| File | Who updates it | When |
|---|---|---|
| `CLAUDE.md` | Human or Doc Updater agent | New process rule or coding constraint |
| `AGENTS.md` | Human or Doc Updater agent | Scope, architecture, or decisions change |
| `CONTEXT.md` | `/grill-with-docs` • human | During grilling sessions |
| `PITFALLS.md` | Human (confirms promotion) | When /cr flags recurring finding for promotion |
| `docs/TESTING.md` | `/tdd` agent | Before writing any test |
| `docs/RECURRING-FINDINGS.md` | `/cr` synthesis step (automatic) | After every pipeline run |
| `docs/adr/` | `/grill-with-docs` proposes, human confirms | When all three ADR conditions are met |
| `docs/solutions/` | `/compound` proposes, human reviews | After features with non-obvious patterns |
| `memory.md` | Human + agent (prompted) | When a mistake is corrected in session |
| `settings.json` | Human only | When permissions need adjustment |
| `SOUL.md` | Human (reviews /compound proposals) | When a new cross-project engineering principle emerges |
| `TASKS.md` | Human + /queue (updates status markers) | When backlog changes; when tasks are claimed or completed |
| `questions.md` | @task-runner (writes), human (answers) | When a parallel task hits a BLOCKING decision |

---

## Naming conventions

Pick conventions that fit your stack and apply them consistently — the value is in the consistency, not the specific scheme. Some common patterns:

- Component / view files: a consistent cased convention for your UI layer (e.g. `PascalCase`)
- Utility, data, and schema files: a consistent cased convention (e.g. `camelCase`)
- Skill files: `SKILL.md` in a folder named after the skill
- ADR files: `NNNN-short-title.md` (zero-padded number)
- Solution files: `YYYY-MM-DD-short-description.md`
- Worktrees: `repo-name_branch-slug` (so one Edit allowlist pattern can cover all worktrees)

---

## Golden exemplars

One of the highest-leverage, lowest-effort things you can do for one-shot rate. Agents don't write new code from scratch — they replicate what they see. If the codebase has both well-written and poorly-written files, agents average across all of them including the bad ones.

A golden exemplar is the single best-written file per layer. Designating it costs nothing — pick from what already exists and add one section to AGENTS.md.

**Example AGENTS.md entry:**

```
## Golden exemplars

Before writing a new file in any layer, read the canonical example first.

| Layer | Canonical file | Why |
|---|---|---|
| <layer A> | <path/to/best/file> | Clean structure, correct patterns, readonly exports |
| <layer B> | <path/to/best/file> | Correct interface, typed boundaries, error handling |
| <layer C> | <path/to/best/file> | Pure functions, no side effects, well-tested edge cases |
| <layer D> | <path/to/best/file> | Correct lifecycle, no business logic in the wrong place |
| <layer E> | <path/to/best/file> | Humble I/O, handles all data states |
```

The layers above are placeholders. Use whatever layers your project actually has — the project defines its own layers. Update the exemplar when a better example emerges. It's a pointer, not a monument.

**The compound effect:** every feature that follows the golden exemplar raises the average quality of the codebase, which raises the quality of the next agent's starting point.

---

## Tech debt as a one-shot blocker

The counterintuitive insight: adding more context docs doesn't help if the codebase has competing patterns.

When a codebase has both a correct pattern (documented in AGENTS.md) and a violating pattern (in existing code), agents see two ways to do something and average across them. The result is code that partially follows the rule and partially follows the violation — often worse than either consistently.

**The consolidation principle:** consolidation, boundary definition, generalizing tech. Not adding new things — removing the second way to do something until there's only one way.

**How to identify blockers:** look at your tech debt table in docs/ARCHITECTURE.md. Any Priority 1 item involving a layer violation or competing pattern is a one-shot blocker. Context docs and skills help everywhere else; they don't help here.

**The fix is consolidation, not documentation.** You cannot document your way past a codebase where one layer reaches around its intended boundary in some places and goes through the correct path in others. The agent follows whichever pattern appears more often in the files it reads.

**The worktree experiment:** before committing to a full debt resolution, fork a worktree and attempt the fix. Run the test suite. If it passes, you've validated the approach at low cost. Implement-to-learn applied to debt.

---

## Codebase architecture for agents (deep modules)

The context layer (CONTEXT.md, AGENTS.md, PITFALLS.md) tells agents what to do. Codebase architecture determines whether agents can navigate the code at all. Both matter. Neither replaces the other.

One good frame for thinking about AI-friendly codebase design comes from the deep modules concept, drawn from "A Philosophy of Software Design" and applied to AI by Matt Pocock at aihero.dev. The article is worth reading: https://www.aihero.dev/how-to-make-codebases-ai-agents-love

The core observation: AI is not a super-powered developer. It's a new starter with no memory. Every time you spawn an agent, it steps into your codebase with no context. Your codebase structure, more than your prompts or context docs, determines what it produces. If it's hard to navigate, you pay in three ways: the agent doesn't know if its changes worked (poor feedback loops), can't figure out where things belong (hard to navigate), and you end up patching manually what the agent gets wrong (cognitive burnout on your end).

The deep modules approach: rather than many small files that all import from each other with no clear groupings, organize code into larger chunks with simple, explicit interfaces. The file system itself tells the agent what each module does. It can go deeper when it needs to, but the interface is usually enough. This creates natural seams where agents can work without needing to hold the entire codebase in context.

Shallow modules — a web of interrelated files with no clear boundaries — give agents no signal about where things belong. They generate code that fits locally but conflicts globally.

This is one approach, not a requirement. The principle is clear interfaces and navigable structure. How you get there depends on your stack, your constraints, and your existing codebase. What matters is that the file system matches the mental map you have of the project.

Two indicators to check in your own codebase:

- Which modules already have a clean public interface hiding implementation? Those are your deep modules. Name them in AGENTS.md as examples.
- Which areas have circular imports or reach into each other's internals? Those are your shallow modules — and likely your Priority 1 tech debt. The deep modules frame is another way of naming why those areas lower one-shot rate.

---

## Related canon

- [Overview](./README.md)
- [The Four Layers](./02-four-layers.md)
- [Context Docs](./04-context-docs.md)
- [Memory System](./07-memory-system.md)
- [Principles](./10-principles.md)
- [Skill Ecosystems](./11-skill-ecosystems.md)
- [Anti-Rationalization](./12-anti-rationalization.md)
- [Model Capacity Audit](./13-model-capacity-audit.md)
- [Git Discipline](./14-git-discipline.md)
- [Templates](./templates.md)
