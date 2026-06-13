# Pass 1 — Comprehend: "Commands vs. Skills — Authoring, Triggering & Where They Sit"

What the article SAYS, faithfully. Claims tagged (fact) = primary-sourced mechanic or
docs-verifiable; (opinion) = the author's judgment/recommendation. The article was authored
*specifically for this harness* (it names our Pillars, open-threads, line counts) — so I tag
its self-referential claims about us as (claim-about-us) for pass3 to verify against ground-truth.

---

## Thesis (as stated)

The "should this be a slash command or a skill?" framing is **partly obsolete**: in current
Claude Code, **custom commands have been merged into skills** — `.claude/commands/deploy.md` and
`.claude/skills/deploy/SKILL.md` both produce `/deploy` on the same machinery; a "command" is now
"the simplest form of a skill (a bare prompt, no auto-trigger)." (fact, primary-sourced per the
article's own verification note). The real questions that change harness behavior are two:
*who decides when this runs — you or the model?* and *how much of it sits in always-loaded context?*
(opinion — the reframing). The author claims both map onto our locked decisions: **Pillar 4**
(default-no, minimize auto-loaded context) and the file-structure research (AGENTS.md single root,
three-tier skill loading). (claim-about-us)

It asserts two of "your standing problems" are command-vs-skill mechanics applied wrong:
"agents don't spawn sub-agents unprompted" and "Bucket 1 is too large (799 lines always-loaded)."
(claim-about-us)

## The two real axes (after stripping the merge)

1. **Who triggers it.** A bare command/prompt is **explicit** (`/name`, full stop). A skill with a
   `description` is **model-invoked** — Claude reads the description and decides to load it when a
   task matches. (fact) The author frames this as "a control decision, not a packaging one… the
   Pillar 1 question (structural over advisory) applied to invocation." (opinion) "You do not want
   Claude *deciding* to deploy because the code looks ready." (opinion)

2. **How it loads.** A bare prompt **expands deterministically into context every time it runs.** A
   skill uses **progressive disclosure**: only `name`+`description` (~100 tokens) sit in the system
   prompt until a task matches; then the body loads; then bundled references/scripts load on demand.
   (fact, primary-sourced) "Pillar 4 made mechanical." (opinion)

## Verified mechanics (the article's middle section — almost all fact)

**Slash commands (lightweight end):**
- Markdown file under `.claude/commands/` (project) or `~/.claude/commands/` (personal). Filename =
  command name. Body = prompt. Optional frontmatter: `description`, `allowed-tools`, `model`,
  `argument-hint`. (fact)
- Invocation **explicit only** (`/name`). Args via `$ARGUMENTS`, `$1`, or named frontmatter args.
  `` !`cmd` `` inlines shell output at expansion; `@path` inlines file contents. (fact)
- Precedence on name collision: **enterprise > personal > project**; **if a skill and command share
  a name, the skill wins.** (fact)

**Agent Skills (full form):**
- A directory with required `SKILL.md` (YAML frontmatter — minimally `name`+`description` — then
  Markdown body), plus optional `scripts/` (**executed, not read into context**), `references/`
  (loaded on demand), `assets/`. (fact)
- **Three-tier loading:** name+description always (~100 tokens) → full body on description match →
  references/scripts on demand. (fact)
- **Description IS the trigger.** Claude decides to activate by reading the `description` *before the
  body loads*. Any "when to spawn a sub-agent" guidance in the **body is invisible at activation
  time and inert.** (fact — mechanic) "This is your documented root cause for why agents don't spawn
  sub-agents." (claim-about-us)
- **Invocation-control frontmatter:** `disable-model-invocation: true` → only you run it via `/name`
  (side-effectful workflows); `user-invocable: false` → only the model loads it (background
  knowledge); `context: fork` + `agent:` runs the skill as an isolated subagent; `paths:` restricts
  auto-trigger to matching files; `allowed-tools` pre-approves tools while active. (fact)
- Once invoked, the rendered body **stays in context for the session** — so keep bodies short
  (Anthropic suggests <~500 lines, detail pushed to references). (fact + recommendation)
- Agent Skills **GA'd Oct 16, 2025**; published as open standard (agentskills.io) **Dec 18, 2025**.
  Codex adopted the same `SKILL.md` standard; Codex's old slash-invoked "custom prompts" are
  deprecated in favor of skills. (fact — but article's own note flags cross-tool adoption as
  "secondary and hedged.")

**Plugins (distribution layer):**
- A plugin is the *installable unit*: a directory with `.claude-plugin/plugin.json` manifest bundling
  `skills/`, `commands/`, `agents/`, `hooks/`, `.mcp.json` into one versioned, namespaced,
  marketplace-installable package. **"skill = authoring format, plugin = distribution format."**
  Codex states it identically. (fact)

## The Decision Table (compressed)

- **Command (bare-prompt skill):** simple repeatable shortcut you always trigger yourself; action
  has side effects you must control (deploy/commit/PR) — *or equivalently a skill with
  `disable-model-invocation: true`*; no supporting scripts/refs; fine to expand the full prompt
  every use.
- **Skill:** multi-step procedure or domain expertise the agent should apply on its own;
  auto-triggering when a task matches a description; needs bundled scripts (determinism), reference
  docs, or progressive disclosure to keep context lean; "an AGENTS.md section has grown from a
  *fact* into a *procedure*."
- **Plugin:** distribute capability across repos/machines; bundle skills+commands+MCP+hooks; want
  versioning, namespace, one-command install; "answers your open-thread #4 (distribution mechanism)."

**One-line heuristic (opinion, load-bearing):** *"Do I want Claude to decide when to do this, or do
I?"* Decide → explicit command (or skill with model-invocation disabled). Agent should decide →
skill with a sharp description.

## Application to this system (the article's four self-claimed sharpenings — all claim-about-us)

1. **Move every spawn condition into the frontmatter `description`.** "Highest-leverage fix… you
   already identified it." Our Phase 1 sub-agent-spawning rule (Explore on >3-query exploration,
   security-reviewer after `/cr`, parallel spawns for independent tasks) "only fires if those
   conditions live in the description field." Body text is inert at trigger time. "Audit every skill
   that spawns: condition in description, not prose."
2. **Apply `disable-model-invocation: true` to every side-effectful skill.** Framed as Pillar 1
   (structural over advisory) + Pillar 2 (reversibility gates autonomy) in frontmatter. Names
   `/queue` (opens PRs), `/change` (gates migrations), any deploy/commit skill. "The frontmatter flag
   is the structural enforcement; a NEVER in the body is the advisory hope Pillar 1 rejects."
3. **The Phase 1 file audit IS a three-tier loading audit.** "Bucket 1 too large" = CLAUDE.md 325 +
   AGENTS.md 474 = **799 always-loaded lines** doing work that belongs in tier 2/3. Skills cost ~100
   tokens until triggered; standalone always-loaded files cost full length every session for every
   agent. Folding PITFALLS.md / RECURRING-FINDINGS.md into on-demand references (the "KILLED-list
   decision") is the same move. Target: **~200-line AGENTS.md root**, everything else tiered.
4. **Plugins answer open-thread #4** ("distribution: submodule / template-copy / package"). Verified
   answer: **plugin-as-package** — versioned, namespaced, `/plugin`-installable, bundles
   skills+agents+hooks+`.mcp.json`. "Template-copy drifts; a plugin updates."

**One caution (fact):** Routines/cloud automations only see **project-level** `.claude/skills/`
committed to the repo — not personal `~/.claude/skills/`. Since canon is now Git-canonical (Node 14),
"this is aligned." "Don't author a harness-critical skill personal-only and expect a scheduled run to
find it."

## The Standing Rule (the article's prescriptive close — opinion)

In this repo: side-effect workflow = skill with `disable-model-invocation: true` (explicit only);
expertise the agent should self-apply = skill with a sharp, trigger-word-front-loaded `description`;
a spawn condition lives in the description, never the body; anything shared across repos is a plugin,
not a copied folder. The always-loaded root stays near 200 lines — "if content can live in tier 2/3,
it must."

## Sourcing (as the article states it)

Anthropic Engineering "Equipping agents… with Agent Skills" (Oct 16 / Dec 18 2025); Claude Code docs
(skills; slash commands; GitHub Actions; command frontmatter ref); agentskills.io; OpenAI Codex
Skills + deprecated Custom Prompts docs; Matt Pocock skills repo; Aaron Ott "MCP vs Skills vs
Plugins"; Simon Willison on the open standard. **Self-declared verification flags:** "commands merged
into skills" + progressive-disclosure token figures are **primary-sourced**; Routines preview dates
and cross-tool adoption counts are **secondary and hedged.**

## Pass-1 flags for later passes (no interpretation, just markers)

- The article embeds **no curator passes of its own** — it is a single argued piece, so there are no
  inherited "analyses" to demote to claims. The four "Application" items and the Standing Rule are
  the author's own recommendations, to be tested in pass3, not facts to inherit.
- Heavy reliance on **claim-about-us** statements (Pillars, "799 lines," open-thread #4, "/change"
  skill, "KILLED-list decision," Node 14 Git-canonical, Phase 1 spawning rule). These reference a
  **planning/canon layer** (Pillars, Nodes, open-threads) that is *not* the ground-truth map.
  Pass3 must check each against `CANONICAL-HARNESS-AS-IS.md` — several may reference decisions or
  files that do not exist on disk.
- Mechanics (the middle section) are the durable, transferable content; the "Application" section is
  where staleness risk concentrates.
