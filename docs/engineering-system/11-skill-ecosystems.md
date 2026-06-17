# Skill Ecosystems

*Universal patterns — adapt to your project.*

Upstream skills exist for the common failure modes of AI coding — install these, don't reinvent them. Don't edit them directly.

---

## Why these exist

Well-built upstream skill sets tend to fix four recurring failure modes:

1. **The agent didn't do what you want** — a grilling skill (`/grill-with-docs`)
2. **The agent is too verbose** — a shared-language document (CONTEXT.md)
3. **The code doesn't work** — test-first discipline (`/tdd`)
4. **You built a ball of mud** — an architecture-improvement skill (`/improve-codebase-architecture`)

"Software engineering fundamentals matter more than ever."

---

## Installation by tool

**Claude Code (this harness — skills are vendored locally):**

The upstream skills this harness uses are **vendored directly into the repo** under `.claude/skills/<name>/` as committed copies — *not* installed globally and *not* symlinked into a per-machine store. A fresh clone or git worktree must already contain the skills, with no separate global-install step. *(This harness: see `.claude/skills/VENDORED.md` for the pinned-SHA provenance and the vendored set.)*

To add or refresh one, pull upstream into the global store, copy just the folder you need into the repo, then commit:

```bash
npx skills@latest add <upstream/skills-repo>            # pulls upstream into the global store
cp -R <global-store>/<name> .claude/skills/<name>       # vendor only the one you need, then git add + commit
```

Vendor **only** the skills the project actually references — don't bulk-install all of them.

> **Why vendored, not global/symlinked:** the per-machine store + symlink pattern (used by some installers) breaks across git worktrees — the per-worktree store ends up empty and every symlink dangles, silently disabling the skills. Committed copies travel with the repo and survive clone, worktree, and CI. Before bumping a vendored skill, re-fetch at the new SHA and human-review the diff.

**Other tools (Cursor, Codex, Windsurf, Aider, etc.):**

The skills are plain markdown files in the repo. Drop the relevant ones into your tool's rules directory or paste them into your system prompt. The slash-command syntax (`/grill-with-docs`, `/tdd`) is Claude Code-specific — for other tools, reference the skill by name in your prompt or wire it as an automatic rule.

---

## How skills actually load — progressive disclosure

Understanding this changes how you write skills. There are three levels:

1. **YAML frontmatter** — always loaded into the model's system prompt, every session. This is how the model decides whether a skill is relevant. Keep it tight.
2. **SKILL.md body** — loaded when the model judges the skill relevant to the current task. This is the execution instructions.
3. **`references/` directory** — linked files the model navigates only when needed. Long-tail detail, API guides, error codes, examples.

The frontmatter is the trigger mechanism. The body is the workflow. References are the deep detail. Write accordingly: frontmatter must contain both *what it does* and *when to use it* or the skill will not fire. The body should stay under 5,000 words — move anything longer to `references/`.

**Debugging a skill that won't trigger:** ask the model directly: *"When would you use the [skill name] skill?"* It quotes the description back. Adjust based on what's missing or vague.

---

## Required conventions

These are not style preferences — getting them wrong silently breaks the skill.

- **`SKILL.md` must be exactly that** — case-sensitive. `skill.md`, `SKILL.MD`, `Skill.md` all fail.
- **Folder naming: kebab-case only** — `cr-security` works; `CR Security`, `cr_security`, `CrSecurity` all fail.
- **No `README.md` inside the skill folder** — documentation goes in `SKILL.md` or `references/`. A `README.md` at the repo level (for human visitors browsing the repo) is fine and recommended; inside the skill folder it breaks the structure.
- **`references/` for long-tail content** — pass-by-pass detail, anti-rationalization tables, API patterns, error codes. Link to them from SKILL.md; don't inline everything.
- **`allowed-tools` for review skills** — the YAML frontmatter supports an `allowed-tools` field that restricts which tools the skill can invoke. Review skills (`/cr`, `/cr-security`) should never write files or run migrations. Example: `allowed-tools: "WebFetch"`. This is a cheap safety layer on top of your process rules.

---

## Skill validation checklist

Run this when building a new skill or auditing an existing one.

**Triggering tests**

- [ ] Fires on the obvious invocation (explicit slash command or obvious phrasing)
- [ ] Fires on paraphrased requests (different wording, same intent)
- [ ] Does NOT fire on unrelated queries
- [ ] Debug: ask the model *"When would you use [skill name]?"* — adjust description if the quoted-back answer is thin or wrong

**Functional tests**

- [ ] Produces correct output on a standard case
- [ ] Handles the hard case (iterate on one challenging task before expanding)
- [ ] Error handling works
- [ ] Output format matches what downstream steps expect (e.g. the compound-questions block is present and filled)

**Sync check (custom skills)**

- [ ] SKILL.md body matches the current canonical docs — especially after the docs are updated
- [ ] Anti-rationalization tables reflect current rules
- [ ] `references/` contains anything over 5,000 words that was previously inline

---

## The critical rule

**Never edit upstream skill files directly.** They get blown away the next time you update or reinstall.

All customization goes through your project docs — CONTEXT.md, AGENTS.md, PITFALLS.md. The skills read these documents. The documents are the customization layer; the skills are the mechanism.

---

## Engineering skills

### `/grill-with-docs`

**Trigger:** before any Small, Medium, or Large feature.

Grilling session that challenges your plan against the existing domain model. Interviews you one question at a time, surfaces hidden assumptions, sharpens terminology, updates CONTEXT.md and creates ADRs inline.

Creates ADRs only when all three conditions are met: hard to reverse, surprising without context, result of a real tradeoff.

### `/tdd`

**Trigger:** whenever implementing a confirmed behavior.

Test-driven development with red-green-refactor loop. Vertical slices — one behavior, one test, one implementation, one commit. Never batches.

Extend in your own skills directory — don't edit the upstream version.

### `/to-issues`

**Trigger:** Medium and Large features, before planning.

Breaks a plan into independently-shippable issues on your tracker. Each issue: one acceptance criterion, few files, one agent session, one test that proves it's done. Requires the tracker's CLI.

### `/to-prd`

**Trigger:** when you want to capture the current conversation as a structured spec.

Turns conversation into a PRD and submits it as an issue. No interview — synthesizes what's already discussed.

### `/improve-codebase-architecture`

**Trigger:** periodically — every few days, not on every feature.

Finds deepening opportunities in the codebase, informed by CONTEXT.md and `docs/adr/`.

### `/diagnose`

**Trigger:** hard bugs and performance regressions.

Disciplined diagnosis loop: reproduce → minimise → hypothesise → instrument → fix → regression-test.

### `/zoom-out`

**Trigger:** navigating unfamiliar sections.

Tells the agent to explain code in the context of the whole system.

### `/prototype`

**Trigger:** when you don't know what to build yet.

Builds a throwaway prototype to flush out a design — either a runnable terminal app or several UI variations. Delete the prototype when done — it's for learning, not shipping.

### `/triage`

**Trigger:** a backlog of issues to prioritize.

Triages issues through a state machine of triage roles.

---

## Productivity skills

### `/grill-me`

Non-code version of `/grill-with-docs`. Relentless interview about a plan or design until every branch of the decision tree is resolved.

### `/caveman`

Ultra-compressed communication mode. Cuts token usage ~75%. Use when context budget is running low.

### `/write-a-skill`

**Trigger:** when a workflow repeats weekly.

Creates new skills with proper structure.

**The skill-building pattern:**

1. **Pick one hard task first** — not an easy one. Easy tasks give false confidence; hard tasks reveal where instructions are actually ambiguous.
2. Do the task once interactively
3. Ask the agent to turn it into a skill
4. Run the skill on the same hard task
5. Correct the output in the same session (feedback logs in the transcript)
6. Ask the agent to update the skill based on corrections
7. Repeat until it converges, then expand to more test cases

Refine via the transcript, not by editing the file directly.

---

## Misc skills

### `/git-guardrails`

Sets up hooks to block dangerous git commands before they execute. Complement to destructive-operation rules. *(This harness: equivalent guards ship in `.claude/hooks/` — see [14 · Git Discipline](./14-git-discipline.md).)*

### `/setup-pre-commit`

Sets up pre-commit hooks with staged-file linting, formatting, type checking, and tests.

---

## Skill sources at a glance

| Source | Skills | How to get |
| --- | --- | --- |
| Upstream engineering set | `/grill-with-docs`, `/tdd`, `/to-issues`, `/to-prd`, `/improve-codebase-architecture`, `/diagnose`, `/zoom-out`, `/prototype`, `/triage`, `/grill-me`, `/caveman`, `/write-a-skill`, `/git-guardrails`, `/setup-pre-commit` | This harness: **vendored** into the repo's `.claude/skills/<name>/` (committed, not global/symlinked) — see `.claude/skills/VENDORED.md`. Refresh: pull upstream into the global store, then `cp -R <global-store>/<name> .claude/skills/`. Others: copy the markdown files from the repo. |
| Custom (yours) | `/feature`, `/cr`, `/cr-security`, `/compound`, `/tdd` (extended), `/scan-context`, `/setup-strategy`, `/review-strategy`, `/prioritize-tasks` | Claude Code: build in `.claude/skills/`. Cursor: `.cursor/rules/`. Others: equivalent rules directory or system prompt. |
| Database / platform vendor set | Vendor-specific guidance + best-practices skills | Install via the vendor's installer where one exists; otherwise copy the markdown files. See the vendor-skill integration notes below. |

---

## The shared language pattern

The most underrated thing a good skill system does: it forces you to build a shared language.

**Before:** "There's a problem when a child item inside a section of a parent is made 'real' (i.e. given a spot in the file system)"

**After:** "There's a problem with the materialization cascade"

This concision compounds. Once a term is in CONTEXT.md, every future session can use it. Code naming stays consistent. New contributors pick up vocabulary faster.

Run `/grill-with-docs` not just to resolve decisions but to build vocabulary.

---

## Compound-engineering plugins

Large all-in-one plugins bundle dozens of agents, commands, and skills. If you've already built the custom pipeline described in this guide, such a plugin is largely redundant and may conflict. Don't install one unless you're starting from scratch and want their conventions rather than your own.

---

## Skill ecosystem evaluation framework

New skill repos appear constantly. The temptation is to install everything and let them sort themselves out. That's how you end up with hundreds of conflicting skills and sessions that spend a large fraction of their context on tool descriptions.

The framework: evaluate before installing. For any repo you find:

1. Does it do something your current skills don't? If not, skip it.
2. Can you steal the pattern without installing the repo? Usually yes.
3. If installing, use the minimal path. Copy specific files, not the full installer.
4. Never stack install methods. One install path per repo.

---

## Ecosystems worth knowing

### Upstream engineering skill sets

What they're best at: engineering discipline — grilling, test-first development, issue decomposition, prototyping, diagnosis. The shared language pattern is the highest-value contribution.

Install: yes, when lean and non-conflicting.

Steal vs install: install the skills. Steal the shared language philosophy.

---

### Reference blogs and write-ups (not packages)

Some of the best material is published as articles, not installable repos — for example the anti-rationalization table pattern, "process over prose" framing, and a short list of engineering non-negotiables.

Install: don't. Treat these as a reference, not a package.

Steal vs install: steal the anti-rationalization table pattern and add it to your own skill files. See [12 · Anti-Rationalization Tables](./12-anti-rationalization.md).

A short list of non-negotiables worth adding to any AGENTS.md:

- Surface assumptions before building
- Stop and ask when requirements conflict
- Push back when warranted
- Prefer the boring, obvious solution
- Touch only what you're asked to touch

---

### Large community mega-repos

Some community repos ship dozens of agents, hundreds of skills, legacy command shims, and cross-harness support for many tools.

What these tend to have that leaner sets don't:

- **Instinct-based continuous learning** with confidence scoring — more sophisticated than a flat memory.md for capturing recurring patterns. Worth understanding even if you don't install it wholesale.
- **A security scanner for your agent configuration** — runs many rules against your context files, settings, hooks, and tool configs.
- **Sub-agent delegation agents** — code-reviewer, security-reviewer, architect, doc-updater as separate specialized agents rather than review passes.
- **Language-agnostic always-follow rules** — git workflow, testing, performance, security.

Install: selectively. Do not run the full installer. Do not stack a plugin install on top of a manual install.

Recommended selective install (adapt paths for your tool): clone the repo, copy only the language-agnostic common rules into your global rules directory, and copy 2–3 specific sub-agents you actually want.

Skip: the bulk of the skills (most overlap with what you've built), the hooks (may conflict with your settings), and the multi-agent orchestration commands (complex, opinionated).

Steal vs install: steal the continuous-learning and config-scanner concepts. Install common rules and 2–3 specific agents selectively.

---

### Vendor / platform skill sets

What these are best at: implementation-specific security checklists, query best practices, CLI workflow, and platform gotchas — all specific to one vendor's product. They cover platform-specific traps that generic security passes miss (auth-claim staleness, row-level-security edge cases, privileged-role exposure, views bypassing access control, and so on).

Install: yes, where the vendor ships an installer. Some installers place canonical files in a per-machine store and create symlinks in your tool's skill directory — keep both directories; the symlinks make skills invocable from the harness.

Trigger rule to add to your process docs → Before writing code: if the task touches the vendor's surface (DB, auth, access policies, migrations, storage, platform functions, client SDK), invoke the vendor skill before writing code. Add the same trigger to `/cr-security` and any migration review checklist.

Steal vs install: install it. The security checklist is the value — it systematically catches platform-specific auth and tenancy vulnerabilities that generic passes miss.

Two extension layers — choose based on whether the content survives an upgrade:

1. **Process-doc trigger rules + context** — workflow gates, project-specific decision rules, invocation conditions. Write here by default. Never overwritten by the installer.
2. **Inline project caveats** — when an upstream reference example directly contradicts a project rule (e.g. shows a privilege-granting pattern without the matching revoke, or uses a non-transactional migration form), add a blockquote immediately after the offending example:

   > **Project caveat:** [rule from your process docs and why]

   Colocating the caveat with the example is the only reliable way to ensure the model reads it in the same context window as the pattern it overrides. **These blockquotes are overwritten on upgrade** — re-apply them after any installer run. Never restructure vendor files; only add caveat blockquotes.

Record the full pattern and the caveats currently applied in a `docs/solutions/` entry.

---

### Official skill-creation tools

Some platforms ship an official skill-creation tool that generates a new SKILL.md *and* runs an evaluation loop automatically after generation — a set of queries that should trigger the skill and a set that should not. It reports which fire correctly and which need description work.

**Prefer the eval-equipped tool over a plain `/write-a-skill` for new skills.** The eval loop is the differentiator: it catches description failures before the skill goes into production.

**Install:** via the platform's installer, or copy from its repo.

**Watch out for:** auto-generated descriptions trend verbose. Trim by hand after generation to stay under the ~60-word target.

**Use when:** writing any new skill. Install this first if you're about to write more than one skill.

---

### `/setup` skill

An interactive bootstrap skill that gets a project running with the full system in one command. Run on a new project or a new machine.

**What it does:**

1. Checks the environment (tracker CLI, `jq`, runtime version, existing config structure)
2. Creates all required files from templates: CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md, memory.md, SOUL.md, the task template, settings file (see [Templates](./templates.md))
3. Installs hooks: the load-gate, auto-loader, auditor, and session-end hooks
4. Installs project-scoped agents: task-runner, explorer, spec-writer, implementer, reviewer, doc-updater, security-reviewer
5. Creates the task tracker file from template
6. Asks: "Enable agentic orchestration (`/queue`, parallel agents)?" — if yes, creates the sentinel file
7. Installs skills: `/queue`, `/compound`, `/cr`, `/cr-security`, `/tdd`, `/feature`, `/design`
8. **Repository platform setup phase:**
   - Creates the CI workflow file from template. Prompts for the test command and type-checker command.
   - Creates the pull/merge request template from template.
   - Asks: "Add a code-owners file? (Recommended for teams or high-risk directories like migrations — optional for solo)" — if yes, creates the file with a placeholder owner and prompts for high-risk paths to add (migrations, CI config, auth code).
   - Prints a branch protection checklist: "Complete this in your repo host settings before the first PR: require a PR before merging, require the CI status check, require an up-to-date branch, no bypass."
9. Runs the existing-codebase review prompt if inheriting an existing project

Every decision is explicit. The sentinel only gates agent orchestration — human git workflows are unaffected.

**Install:** build in `.claude/skills/setup/SKILL.md`.

---

## Skill description engineering

The skill description is the entire routing decision at the frontmatter level. Five rules for descriptions that fire:

1. Third person
2. Cover what AND when
3. Specific trigger phrases
4. Don't restate the name
5. Don't write skills for trivial tasks

The multi-query eval is the only way to know if a description works. Use an eval-equipped skill-creation tool for new skills — it has the eval built in.

---

## Upgrade process

This field moves fast. New repos appear weekly. The right posture:

- Watch for patterns worth stealing, not repos worth installing
- When you find something genuinely new, add it to your reading list
- When you steal a pattern, add it to the relevant canon page with a source link
- When a new version of an installed repo ships, review the changelog before upgrading — don't auto-upgrade
- Installer-based upgrades usually prompt before overwriting. Review what changed.
- Mega-repos: check the changelog before pulling. They ship frequently and have breaking changes between versions.

The goal is not to have the most skills. It's to have the right ones, maintained, that you actually use.

---

## Context ownership convention — `context-meta`

A governed context file carries a `context-meta` block. This is what makes `/scan-context` work — it reads the block's `last-reviewed` date against the file's `review-frequency` and flags files that are overdue.

**Two scopes, on purpose:**

- **Freshness** (the OVERDUE check) applies to **any** file that carries a block. A skill becomes governed by *opting in* — adding a block. This keeps the maintenance surface small: you are not forced to put a block on every skill.
- **Required-core** files must always carry a block, and `/scan-context` reports them as MISSING if they don't: CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md, SOUL.md, memory.md.

```markdown
<!-- context-meta
owner: <name>
last-reviewed: YYYY-MM-DD
review-frequency: on-merge | weekly | monthly
drift-signals:
  - file references that no longer exist
  - patterns contradicted by newer solutions entries
-->
```

Review frequency tiers:

- `on-merge` — PITFALLS.md, memory.md — reviewed on every PR (by `/cr`), so `/scan-context` does not time-check them
- `weekly` — CLAUDE.md, AGENTS.md, CONTEXT.md — overdue past 7 days
- `monthly` — SOUL.md, and any skill that opted in — overdue past 30 days

Put the block at the very top of the file (for a file with YAML frontmatter, just below the closing `---`). Update `last-reviewed` only when you have actually reviewed the file and confirmed it is current — a false date is worse than an overdue one.

### Firing the freshness check on a schedule

`/scan-context` is a freshness ritual: it should run on a cadence, not only when someone remembers. In a project that adopts this harness, wire it during onboarding as a `/schedule` cloud routine — for example, weekly: "run `bash scripts/scan-context.sh`; if it exits non-zero, open an issue listing the overdue and missing files." The script's exit code (`0` = fresh, `1` = findings) is the signal the routine keys on.

The project's `.claude/rituals.md` is the local record of which rituals exist and when each last ran — the human-readable cadence log that sits next to the `/schedule` routines. (This harness repo itself runs `/scan-context` on demand instead, because its memory lives outside the repo, where a cloud routine cannot read it.)

See [07 · Memory System](./07-memory-system.md) for how memory.md fits the wider lifecycle.

---

## Custom skill maintenance — keeping skills in sync with the canon

These are the kinds of gaps that open up between the canonical docs and the actual skill files in a project. Work through them in priority order whenever you audit.

**Priority 1 — Sync custom skills with the canon**

- Review skills: ensure the compound-questions block is a required output section with explicit gate language, including the process-improvement question.
- `/grill-with-docs`: ensure the two-phase structure exists — Phase 1 (your answers before the agent grills) and Phase 2 (agent grill with the manual-QA-coverage check).
- Task spec template: ensure it carries a pre-grill section with human-answered questions and a full compound-questions list.
- `/design contract`: ensure the deep-module check follows the simplicity check.
- Any visual-design skill: replace ASCII wireframes with a multi-option prose approach.

**Priority 2 — Structure: move long content to `references/`**

- `/cr` and feature-review skills: move pass-by-pass detail and anti-rationalization tables to `references/`. Keep the skeleton and links in SKILL.md.

**Priority 3 — Add `allowed-tools` to review skills**

- `/cr`, feature-review, and `/cr-security`: add an `allowed-tools` constraint to the YAML frontmatter. Review skills should not write files or run bash commands.

**Priority 4 — Description audit**

- Run the debug technique on each custom skill: ask the model *"When would you use [skill name]?"* and verify the quoted-back answer is accurate and complete. Fix any that are thin or wrong.
