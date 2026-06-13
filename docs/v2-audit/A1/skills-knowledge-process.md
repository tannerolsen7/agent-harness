# Pass A1 — Knowledge / Process / Domain Skills Inventory

FACT-ONLY ground-truth inventory. Records what exists and what each skill claims
to do. No evaluation or recommendation. All paths relative to
`/Users/tanner/Dev/event-vendor`.

Slice covered: `compound`, `notion-sync`, `prioritize-tasks`, `explain`,
`design`, `migrate`, `dep-update`, `supabase`, `supabase-postgres-best-practices`.

Directory facts (`ls`):
- `dep-update/` exists but is **EMPTY** — no `SKILL.md`, no files. (confirmed-absent content)
- `compound/` — `SKILL.md` only (5943 B)
- `notion-sync/` — `SKILL.md` only (11336 B)
- `prioritize-tasks/` — `SKILL.md` only (3462 B)
- `explain/` — `SKILL.md` only (3337 B)
- `design/` — `SKILL.md` only (7783 B)
- `migrate/` — `SKILL.md` only (16255 B)
- `supabase/` — `SKILL.md` + `references/skill-feedback.md` + `assets/feedback-issue-template.md`
- `supabase-postgres-best-practices/` — `SKILL.md` + `references/` (34 files, 33 rule docs + `_contributing.md`/`_sections.md`/`_template.md`)

---

## compound

### 1. Purpose / trigger
Frontmatter (`compound/SKILL.md:2-5`): "Capture a solved problem as a reusable
solution doc in `docs/solutions/`." Invoke with `/compound`. Trigger condition
(`:10-23`): after a feature merges when a non-obvious architectural decision was
made, a recurring problem class was solved, a new replicable pattern was
established, or compound questions surfaced something resolved. Explicitly NOT
for: obvious bug fixes, copy/config/dependency changes, or anything already in
PITFALLS.md.

### 2. Workflow (per step, cited)
- **Step 1 — Understand what was built** (`:26-33`): read merged PR diff
  (`git diff main~1..main`), `.claude/TASK-TEMPLATE.md` if filled, compound
  question answers in the task spec, any `docs/TESTING.md` entries added.
- **Step 2 — Spawn solution extractor (Sonnet)** (`:36-49`): spawn a sub-agent
  to produce a solution doc using `docs/solutions/TEMPLATE.md` as format; focus
  on underlying problem, approach, why it works, when/when-not to reuse.
- **Step 3 — Review the draft** (`:53-60`): present draft to user; ask about
  problem-statement accuracy, missing context, tags; apply corrections.
- **Step 4 — Write the file** (`:64-69`): write to
  `docs/solutions/YYYY-MM-DD-short-description.md`.
- **Step 5 — Check for PITFALLS.md promotion** (`:72-76`): if a new trap was
  revealed, **propose** adding it (Area, Rule, Why, Symptoms, Source); else say
  so explicitly. (Propose — does not state it writes.)
- **Step 6 — Check for memory.md update** (`:80-84`): if the session corrected a
  mistake that should be a permanent rule, **propose** the `.claude/memory.md`
  entry; else say so explicitly. (Propose only.)
- **Step 7 — Review permission log + suggest allowlist additions** (`:88-104`):
  read `/tmp/claude-perm-log-${HASH}.jsonl` (HASH = `md5` of `$CLAUDE_PROJECT_DIR`,
  first 8 chars), compare against `.claude/settings.json` `permissions.allow`,
  present uncovered patterns grouped "Safe to add" / "Review first". Does NOT
  write to settings.json directly — waits for confirmation.
- **Step 8 — Notion AI engineering system update** (`:108-124`): if the feature
  changed tooling/settings/hooks/pipeline-tiers/skills/sentinels/process, add a
  versioned subpage to the Notion Changelog (increment minor version), update
  the settings.json Notion subpage and other template pages; else say so.
- **Session retrospective** (`:128-135`): "86% audit" (what slowed the session
  that wasn't writing code) + learning capture (what was learned not in
  CONTEXT.md).
- **Step 9 — Quarterly memory review (~every 90 days, optional)** (`:139-163`):
  read `.claude/memory.md`, flag entries by `last_seen` >90 days, contradicting
  current patterns, or redundant-with-PITFALLS; produce a report. Explicitly
  "Do not modify memory.md. Surface candidates and wait for direction."

### 3. Produces / enforces
- **Writes:** `docs/solutions/YYYY-MM-DD-*.md` (the only file it actually writes,
  Step 4).
- **Proposes only (does not write):** PITFALLS.md entry, `.claude/memory.md`
  entry, `.claude/settings.json` allowlist additions, Notion changelog/template
  pages.
- **Reads:** PR diff, `.claude/TASK-TEMPLATE.md`, `docs/TESTING.md`,
  `docs/solutions/TEMPLATE.md`, `/tmp/claude-perm-log-${HASH}.jsonl`,
  `.claude/settings.json`, `.claude/memory.md`.
- **Sub-agents:** Step 2 "solution extractor (Sonnet)" — described inline, not a
  named registered agent type.

### 4. Enforcement type per step
ALL ADVISORY. Every step is a markdown instruction. No hook, CI, or script
forces `/compound` to run or blocks on its output. Steps 5/6/7/8/9 explicitly
"propose"/"surface and wait" rather than write. Step 7's only script reference
is `block-dangerous-git.sh` (named as the basis for the "safe subset" tiering,
`:99`) — present at `.claude/hooks/block-dangerous-git.sh` (confirmed-present),
but `/compound` does not invoke it.

### 5. Cross-references
- `docs/solutions/TEMPLATE.md` (Step 2/4) — confirmed-present.
- `.claude/TASK-TEMPLATE.md` (Step 1) — confirmed-present.
- `docs/TESTING.md` (Step 1) — confirmed-present.
- PITFALLS.md (Step 5) — confirmed-present.
- `.claude/memory.md` (Step 6, 9) — confirmed-present.
- `.claude/settings.json` (Step 7) — confirmed-present; lists
  `Skill(compound)` / `Skill(compound:*)` in allow (`settings.json:132-133`).
- `block-dangerous-git.sh` (Step 7) — confirmed-present.
- Notion Changelog page (Step 8) — external; overlaps with notion-sync's
  changelog ID `35ae2971cd6281c69f55c4ff7bbb2b64`.
- `CONTEXT.md` (Session retrospective) — referenced; **NOT FOUND at repo root**
  (confirmed-absent; only `git diff` of it implied). Not verified to exist.
- Related agent `doc-updater` (per its own description, runs `/compound` after a
  task) — `.claude/agents/doc-updater.md` confirmed-present.

### 6. Overlaps (compound-specific, per audit instruction)
**Files `/compound` READS:** PR diff, TASK-TEMPLATE.md, TESTING.md, solutions
TEMPLATE.md, perm-log jsonl, settings.json, memory.md.
**Files `/compound` WRITES:** `docs/solutions/YYYY-MM-DD-*.md` ONLY.
**Files `/compound` PROPOSES (no write):** PITFALLS.md, memory.md, settings.json,
Notion pages.

**Does `/compound` count recurrences?** NO. `grep` of the SKILL for
"occurrence/increment/count/recur" returns only: `:14` ("A recurring problem
class was solved" — trigger prose), `:116` ("increment the minor version" —
Notion), `:161` ("[count] entries" — memory-review report template). There is
**no occurrence counter, no signature matching, no increment logic** in
`/compound`.

**Relationship to `docs/RECURRING-FINDINGS.md`:** NONE. `/compound` never reads,
writes, or mentions RECURRING-FINDINGS.md (grep confirmed: the only "recurring"
hit is the trigger sentence at `:14`). RECURRING-FINDINGS.md is confirmed-present
at `docs/RECURRING-FINDINGS.md`; its header (`RECURRING-FINDINGS.md:7-13`) states
"The pipeline synthesis step appends or increments entries automatically. Entries
are matched on the `signature` field." Cross-ref check: the ONLY skill that
references RECURRING-FINDINGS.md is `.claude/skills/cr/SKILL.md` (grep over
`.claude` + `docs`). So **occurrence/recurrence counting lives in `/cr` (the
pipeline), not in `/compound`.**

**Relationship to PITFALLS.md and memory.md:** `/compound` Step 5 proposes
PITFALLS promotions; Step 6 proposes memory.md additions; Step 9 proposes
memory.md pruning. Both files are also independently maintained by CLAUDE.md
standing rules and (PITFALLS) by `/cr`'s RECURRING-FINDINGS promotion path.
PITFALLS.md is thus a write/propose target of at least: `/compound` (propose),
`/cr` (promotion from RECURRING-FINDINGS), and CLAUDE.md "Keeping docs current"
rules. memory.md is a propose target of `/compound` (Steps 6, 9) and a write
target of CLAUDE.md session-end rules.

**Overlap with notion-sync:** Step 8 (Notion changelog/template update)
duplicates concern area of `/notion-sync`. notion-sync `:194-208` declares a
"Scope delimiter": notion-sync owns the *sync protocol*; `/compound` owns
*project-specific learnings discovered during a sync*. compound Step 8 still
writes upstream Notion changelog entries for tooling changes — both skills touch
Notion changelog ID `35ae2971cd6281c69f55c4ff7bbb2b64`.

### 7. Claim-vs-reality
- `docs/solutions/TEMPLATE.md` — CONFIRMED-PRESENT.
- `.claude/TASK-TEMPLATE.md` — CONFIRMED-PRESENT.
- `docs/TESTING.md` — CONFIRMED-PRESENT.
- `PITFALLS.md`, `.claude/memory.md`, `.claude/settings.json` — CONFIRMED-PRESENT.
- `/tmp/claude-perm-log-${HASH}.jsonl` — runtime artifact, not verified.
- `CONTEXT.md` — referenced in Session retrospective; NOT FOUND at repo root
  (CONFIRMED-ABSENT at root).
- Sonnet "solution extractor" sub-agent (Step 2) — inline-described, no
  registered agent type by that name.

---

## notion-sync

### 1. Purpose / trigger
Frontmatter (`notion-sync/SKILL.md:2-3`): sync project with the AI-native
engineering system in Notion. Triggers: "/notion-sync", "sync with Notion",
"apply Notion updates". Fetches changelog since LAST-SYNC.md, fetches all
canonical template pages, diffs against disk, applies every gap. Core principle
(`:14-20`): canonical Notion template pages are source of truth; changelog
entries are summaries only; diff every file. Includes an Anti-rationalization
table (`:21-30`).

### 2. Workflow (per step, cited)
- **Step 1 — Load Notion MCP schema** (`:33-38`): run
  `ToolSearch select:mcp__claude_ai_Notion__notion-fetch`; never WebFetch Notion
  URLs (PITFALLS § notion-pages-require-mcp).
- **Step 2 — Read LAST-SYNC.md** (`:41-44`): capture last sync date; if absent,
  apply all versions.
- **Step 3 — Create a dedicated branch** (`:47-57`): "Non-negotiable";
  `git checkout main && git pull && git checkout -b chore/notion-sync-vX.Y-vX.Z`.
- **Step 4 — Fetch the changelog** (`:60-83`): changelog ID
  `35ae2971cd6281c69f55c4ff7bbb2b64`; list versions after last-sync date
  oldest-first; if none, "Already up to date", update LAST-SYNC, stop. Includes
  "Canonical-page-lag protocol".
- **Step 5 — Fetch ALL canonical template pages in parallel** (`:86-126`):
  Templates index ID `359e2971cd62819e9142c30b99fecb6c`; fetch index first, then
  every template (table of ~21 page IDs spanning skills, agents, TASK-TEMPLATE,
  TASKS, CLAUDE.md, AGENTS.md, agent-contract.md, SOUL.md, docs templates).
- **Step 6 — Comprehensive diff: template vs disk** (`:129-157`): read each disk
  file, compare to template, classify gaps (universal addition / structural /
  new file), build gap list, apply together. **Guard-file exception** (`:146`):
  gaps in `settings.json`, `settings.local.json`, `.claude/hooks/**` are NOT
  applied — staged to `/tmp/sync-guard-fix/`, verified, surfaced as paste-ready
  NEEDS HUMAN; recorded `human-pending`. Preserve project-specific content.
- **Step 7 — Create new files and directories** (`:160-165`): create missing
  files from template; `.gitkeep` for empty dirs.
- **Step 8 — Update LAST-SYNC.md** (`:167-190`): only after diff clean; build a
  coverage table (every page from Step 5 with status: `in-sync`/`gaps-applied`/
  `created`/`lag-detected`/`not-fetched`/`human-pending`).
- **Step 9 — Run /compound** (`:193-208`): if the sync established a non-obvious
  process; scope delimiter vs `/compound` defined here.
- **Step 10 — Commit** (`:212-220`): `chore(system): apply AI-native system
  updates vX.Y–vX.Z`; run `npx tsc --noEmit` (zero errors) before committing.
- **Step 11 — Push and open PR** (`:224-230`): run `/cr` (writes `.cr-ok`),
  `git push`, `scripts/pr.sh --title ...`.
- **Done criteria** (`:234-239`) + Reference table (`:243-251`).

### 3. Produces / enforces
- **Writes/updates:** `LAST-SYNC.md` (coverage table), any canonical doc/skill
  files that diverge from Notion templates, new files for missing templates,
  `.gitkeep`. Commits on a dedicated `chore/notion-sync-*` branch, opens a PR.
- **Does NOT write:** guard files (settings.json, settings.local.json,
  `.claude/hooks/**`) — staged as NEEDS HUMAN.
- **Reads:** LAST-SYNC.md, Notion changelog + ~21 template pages, all
  corresponding disk files.
- **Gates relied on:** pre-commit hook (tsc/lint/tests), `/cr` writing `.cr-ok`,
  `scripts/pr.sh` consuming `.cr-ok`, pre-push hook.

### 4. Enforcement type per step
- Steps 1-9 ADVISORY (markdown instructions; "Non-negotiable" branch rule at
  Step 3 is advisory text, not script-enforced).
- Step 6 Guard-file exception is STRUCTURALLY backed: settings.json/hooks are
  agent-uneditable by the project-relative `deny` in settings (the skill relies
  on that deny, not on its own enforcement).
- Step 10 `npx tsc --noEmit` ADVISORY here but STRUCTURALLY enforced by the
  pre-commit hook on actual commit.
- Step 11 `/cr` + `.cr-ok` + `scripts/pr.sh` is STRUCTURAL: `scripts/pr.sh`
  (confirmed-present) validates/consumes the `.cr-ok` sentinel and the pre-push
  hook blocks a stale/missing sentinel.

### 5. Cross-references
- `LAST-SYNC.md` — confirmed-present.
- PITFALLS.md § notion-pages-require-mcp — PITFALLS confirmed-present (specific
  section not verified here).
- `scripts/pr.sh` — confirmed-present.
- `/cr`, `/compound` skills — both confirmed-present.
- `docs/solutions/2026-05-18-notion-changelog-sync-process.md` (referenced at
  `:199` and `:249`) — **CONFIRMED-ABSENT** (file does not exist).
- Notion IDs: changelog `35ae2971cd6281c69f55c4ff7bbb2b64`, templates index
  `359e2971cd62819e9142c30b99fecb6c` (external, not verifiable from disk).

### 6. Overlaps
- Notion changelog write/update overlaps `/compound` Step 8 (both touch the same
  changelog ID). The skill defines an explicit scope delimiter (`:204-208`).
- Step 9 hard cross-call into `/compound`.
- Coverage of CLAUDE.md / AGENTS.md / SOUL.md / TASKS.md as sync targets means
  notion-sync can rewrite docs that other skills (prioritize-tasks → TASKS.md;
  compound → memory/PITFALLS) also maintain.

### 7. Claim-vs-reality
- `LAST-SYNC.md`, `scripts/pr.sh`, `/cr`, `/compound` — CONFIRMED-PRESENT.
- `docs/solutions/2026-05-18-notion-changelog-sync-process.md` — CONFIRMED-ABSENT
  (referenced as the canonical solution doc twice; missing on disk).
- `mcp__claude_ai_Notion__notion-fetch` — present as a deferred MCP tool name in
  this environment (Notion MCP tools listed); not loaded by default.

---

## prioritize-tasks

### 1. Purpose / trigger
Frontmatter (`prioritize-tasks/SKILL.md:1-9`): weekly ritual. Reads `TASKS.md`
and `STRATEGY.md`, produces a recommended priority reordering aligned with north
star and product stage, flags stale tasks and unreviewed backlog, waits for human
confirmation before writing. Run weekly alongside `/scan-context` and
`/improve-codebase-architecture`. Tracked in `rituals.md`.

### 2. Workflow (per step)
- **Prerequisites** (`:11-17`): TASKS.md must exist; read STRATEGY.md and TASKS.md
  in full; if TASKS.md absent, stop and surface.
- **Step 1 — Read and parse** (`:21-34`): extract from STRATEGY.md (stage, north
  star, constraints, out-of-scope) and TASKS.md (active tasks+status, `[backlog]`,
  BLOCKED, last-modified dates).
- **Step 2 — Evaluate** (`:38-53`): alignment check (north star, constraints,
  out-of-scope), staleness check (>30 days = flag; BLOCKED = surface blocker),
  backlog check (alignment; High-severity >30 days flagged).
- **Step 3 — Produce recommendation** (`:57-81`): output a reordering with flags
  (STALE / BLOCKED / STRATEGY MISALIGNMENT), backlog promote/prune candidates.
  Wait for confirmation; do not rewrite TASKS.md until confirmed.
- **Step 4 — Apply confirmed changes** (`:85-99`): reorder TASKS.md, promote/prune
  backlog, add `## Last prioritized: YYYY-MM-DD` line, update `rituals.md`
  (`last_run`, `frequency: weekly`, notes).
- **Hard rules** (`:103-108`): never reorder/prune without confirmation; if
  STRATEGY.md absent, still run on severity alone and recommend `/setup-strategy`.

### 3. Produces / enforces
- **Writes (after confirmation):** `TASKS.md` (reordered, promoted/pruned,
  `Last prioritized` line), `.claude/rituals.md` (`prioritize-tasks` block).
- **Reads:** `TASKS.md`, `STRATEGY.md`.

### 4. Enforcement type
ALL ADVISORY. Ritual cadence is tracked in `rituals.md`; CLAUDE.md session-start
rule surfaces rituals whose `last_run` is >7 days old (that surfacing is the
nearest thing to enforcement, and it lives in CLAUDE.md, not this skill). No
hook/CI blocks on it.

### 5. Cross-references
- `TASKS.md` (confirmed-present), `STRATEGY.md` (confirmed-present),
  `.claude/rituals.md` (confirmed-present).
- `/scan-context`, `/setup-strategy`, `/improve-codebase-architecture` (named) —
  `setup-strategy` and `improve-codebase-architecture` appear in the available
  skills list; `/scan-context` not confirmed present.

### 6. Overlaps
- Writes `TASKS.md`, which `/notion-sync` also syncs from a canonical Notion
  TASKS template (ID `364e2971cd6281739ec7cb62b26bed45`). Two writers of TASKS.md
  with different source-of-truth assumptions (Notion vs STRATEGY-driven reorder).

### 7. Claim-vs-reality
- TASKS.md, STRATEGY.md, rituals.md — CONFIRMED-PRESENT.
- `/setup-strategy`, `/improve-codebase-architecture` — present in skills list.
- `/scan-context` — NOT confirmed in skills list (CONFIRMED-ABSENT from the
  available-skills enumeration).

---

## explain

### 1. Purpose / trigger
Frontmatter (`explain/SKILL.md:1-5`): learning brief explaining the current diff
to a developer building their React mental model. Covers what was built, React
concepts, decisions/tradeoffs, what would break, and one staff-engineer question.
Body (`:9-14`): "Do not review for quality — that is `/cr`'s job. Do not suggest
fixes. Explain."

### 2. Workflow
- **Step 0 — Gather the diff** (`:18-22`): `git diff HEAD`; if clean, `git diff
  HEAD~1`; if no meaningful diff, say so and stop.
- **Step 1 — Produce the learning brief** (`:26-69`): spawn an Agent sub-agent
  **model: sonnet** with a framing prompt producing five sections (What was
  built / React concepts in play / Key decisions and tradeoffs / What would break
  and why / One question to test understanding).
- **Final output** (`:73-76`): present the brief directly under the five headings.

### 3. Produces / enforces
- **Writes:** nothing to disk — output is a brief presented to the user.
- **Sub-agents:** one Sonnet Agent sub-agent (inline-described, not a named
  registered agent type).

### 4. Enforcement type
ALL ADVISORY. Pure read + present. No files, gates, or scripts.

### 5. Cross-references
- `/cr` (named as the quality-review counterpart). No file dependencies beyond
  the git working tree.

### 6. Overlaps
- Reads the diff like `/cr` and `/compound` Step 2 but explicitly disclaims
  review/fix scope (teaching-only). Minimal overlap by design.

### 7. Claim-vs-reality
- `/cr` — CONFIRMED-PRESENT. No other file claims to verify.

---

## design

### 1. Purpose / trigger
Frontmatter (`design/SKILL.md:1-10`): two-mode system design skill. `explore`
when the right design is unknown (options + tradeoffs); `contract` when the
design is known (formalize into a Claude Code handoff doc). Triggers on "I want
to build X", "how should I structure this", etc. "Always runs before
/grill-with-docs for Small+ tasks."

### 2. Workflow
- **Upstream-skills banner** (`:16-18`): `/grill-with-docs`, `/tdd`, `/to-issues`
  are from Matt Pocock's repo, "not included here"; install via
  `npx skills@latest add mattpocock/skills`; see `.claude/INDEX.md → Required
  global skills`.
- **Mode declaration** (`:20-29`): `/design explore` vs `/design contract`. Tiny
  tasks skip both; Small+ contract mandatory; explore optional.
- **Mode 1: explore** (`:32-75`): anti-rationalization table; an "explore prompt"
  to paste (problem + CONTEXT.md section + AGENTS.md rules → 2-3 options with
  layer ownership, interface, patterns followed/broken, tradeoffs, 6-month cost);
  what to do with output.
- **Mode 2: contract** (`:78-181`): anti-rationalization table; four questions
  (business need, interface, constraints, state ownership); simplicity check;
  handoff document format (template block `:135-161`) written into
  TASK-TEMPLATE.md; critical sections (Interface Contract, Out of Scope, Done
  Looks Like); the "contract isn't ready" signal → surface gaps as open decisions
  in AGENTS.md.
- **After the contract: decomposition** (`:184-195`): tracer bullet, map
  dependencies, label parallel/sequential, verify slices independently shippable;
  run `/to-issues` then reorder.

### 3. Produces / enforces
- **Writes:** nothing directly. Output (handoff doc) is pasted into
  `.claude/TASK-TEMPLATE.md` by the user; gaps surfaced into AGENTS.md as open
  decisions. Explore output is a set of options presented, not written.

### 4. Enforcement type
ALL ADVISORY. Prompt-template skill; no scripts/gates. Cadence relationship
("Always runs before /grill-with-docs for Small+") is advisory text.

### 5. Cross-references
- `.claude/TASK-TEMPLATE.md` (confirmed-present), AGENTS.md (assumed present),
  CONTEXT.md (referenced; CONFIRMED-ABSENT at root).
- `.claude/INDEX.md` (confirmed-present).
- Upstream skills `/grill-with-docs`, `/to-issues` — **CONFIRMED-ABSENT** as
  local `.claude/skills/` dirs (neither directory exists). `/tdd` —
  CONFIRMED-PRESENT (`.claude/skills/tdd/SKILL.md`). NOTE: `grill-with-docs` and
  `to-issues` DO appear in the runtime available-skills list (globally installed),
  consistent with the "install globally" banner — present at runtime, absent on
  disk in `.claude/skills/`.
- `/feature` (named as where the handoff feeds) — CONFIRMED-PRESENT.

### 6. Overlaps
- Writes into the same `.claude/TASK-TEMPLATE.md` that `/compound` reads (Step 1)
  and that `/notion-sync` syncs from Notion (ID `359e2971cd6281b68becec61207f98c0`).
- Decomposition logic overlaps `/to-issues` (which it explicitly delegates to).

### 7. Claim-vs-reality
- `.claude/TASK-TEMPLATE.md`, `.claude/INDEX.md`, `/tdd`, `/feature` —
  CONFIRMED-PRESENT.
- `/grill-with-docs`, `/to-issues` local skill dirs — CONFIRMED-ABSENT on disk;
  present in runtime skills list (global install).
- `CONTEXT.md` — CONFIRMED-ABSENT at repo root.

---

## migrate

### 1. Purpose / trigger
Frontmatter (`migrate/SKILL.md:1-11`): moving stored state from one form to
another (schema/data/infra/service migrations). Use when the primary artifact is
a mutation to DB/filesystem/external state, when `/incident` routes a data-problem
here, or when a feature needs a non-revertible schema/data change. Not for pure
code changes touching migration files (those → `/feature`). Requires a confirmed
migration plan before any execution.

### 2. Workflow
- **Framing** (`:14-52`): migration ≠ deploy; mandatory pre-flight; owns
  state-mutation PRs only; "What this is not"; anti-rationalization table.
- **Migration types** (`:56-73`): schema/data/infrastructure/service/combined
  table with irreversibility risk; combined = most dangerous → decompose.
- **Irreversibility tiers** (`:77-89`): clean-revert / compensate / window /
  permanent; permanent needs human sign-off before Phase 3; window needs duration
  documented.
- **The loop** (`:93-118`): Entry gate → Phase 0 sequencing → Phase 1 pre-flight
  → Phase 2 rollback → Phase 3 dry-run → Phase 4 execution → Phase 5 verification.
- **Entry gate** (`:122-150`): classification block (what's moving, type, tier,
  expand/contract, rows affected).
- **Phase 0 — Sequencing plan** (`:153-181`): expand/contract pattern; names
  PR1 Expand (/feature), PR2 Migrate (this skill, branch `migrate/[slug]`), PR3
  Contract (/feature).
- **Phase 1 — Pre-flight checklist** (`:185-256`): Check A Backup, Check B Lock
  safety (schema only; ACCESS EXCLUSIVE DDL list), Check C Batch strategy (data;
  >10k rows), Check D Dry-run strategy (per-type table). HIGH lock risk with no
  safe strategy → write BLOCKING to `questions.md`, do not proceed.
- **Phase 2 — Rollback plan** (`:260-290`): operationally concrete commands;
  permanent tier requires explicit human sign-off line before Phase 3.
- **Phase 3 — Dry-run** (`:294-315`): agent runs; human confirms "Proceed" — hard
  gate, no auto-proceed.
- **Phase 4 — Execution** (`:319-349`): `git checkout -b migrate/[slug]`, backup
  immediately, run (batched if needed), monitor; mid-stream failure → stop, record
  cursor, write BLOCKING to `questions.md`.
- **Phase 5 — Post-migration verification** (`:352-379`): row count, spot-check,
  constraint validation, smoke test; human signs off.
- **Final report format** (`:384-401`).
- **Agents/feeds footer** (`:405-412`): spawns `@explorer` (optional, callsite
  discovery); feeds `/feature` and `/compound`; output lives in
  `.claude/migrate-[slug].md`.

### 3. Produces / enforces
- **Writes/creates:** `.claude/migrate-[slug].md` (pre-flight artifacts),
  `questions.md` (BLOCKING entries on lock-risk/mid-stream failure), a
  `migrate/[slug]` branch.
- **Reads:** the schema/data being migrated; nothing else file-specific.
- **Sub-agents:** `@explorer` (optional) — registered agent type
  (`Explore`/explorer exists in the agent roster).

### 4. Enforcement type
Mostly ADVISORY (markdown gates: classification, tiers, pre-flight checks, human
sign-offs, "hard gate" at Phase 3 are all instruction-level, human-confirmed, not
script-blocked). The downstream commit/push touches the real STRUCTURAL gates
(pre-commit, `/cr` `.cr-ok`, pre-push) but those are not part of this skill. No
script in the skill itself enforces backup/dry-run.

### 5. Cross-references
- `/feature` (expand/contract PRs), `/incident` (routes here), `/hotfix`,
  `/compound`, `@explorer` — `/feature`, `/incident`, `/hotfix`, `/compound`
  all CONFIRMED-PRESENT in skills list; explorer agent CONFIRMED-PRESENT.
- `questions.md` — the /queue/task-runner blocking-protocol file (not a committed
  root file; runtime artifact).

### 6. Overlaps
- Schema-change concern overlaps `/supabase` (which owns the SQL/migration
  mechanics + security checklist). migrate owns sequencing/rollback/verification;
  supabase owns the migration SQL generation. CLAUDE.md independently requires
  `/supabase` before any migration.
- Feeds `/compound` like notion-sync does.

### 7. Claim-vs-reality
- `.claude/migrate-*.md` — none currently on disk (no migrations run via skill
  yet; expected, output-only).
- `@explorer`, `/feature`, `/incident`, `/hotfix`, `/compound` — CONFIRMED-PRESENT.

---

## dep-update

### 1-7. Status
**EMPTY DIRECTORY.** `.claude/skills/dep-update/` contains no files (no SKILL.md).
There is no skill content to inventory. CONFIRMED-ABSENT. (Not listed in the
runtime available-skills enumeration either.) No trigger, workflow, outputs,
enforcement, or cross-references exist.

---

## supabase

### 1. Purpose / trigger
Frontmatter (`supabase/SKILL.md:1-7`, author: supabase, version 0.1.2): use for
ANY Supabase task. Triggers: Database/Auth/Edge Functions/Realtime/Storage/
Vectors/Cron/Queues; supabase-js + @supabase/ssr in Next/React/etc.; auth/session
/JWT/RLS issues; CLI or MCP; schema changes, migrations, security audits, Postgres
extensions. (CLAUDE.md additionally mandates invoking `/supabase` before any
Supabase or migration work.)

### 2. Workflow / content (this is a reference skill, not a phased pipeline)
- **Core Principles** (`:11-52`): (1) verify against changelog/current docs —
  fetch `https://supabase.com/changelog.md`, scan `breaking-change` tags;
  (2) verify your work with a test query; (3) recover from errors, don't loop
  (stop after 2-3 attempts); (4) exposing tables to Data API; (5) RLS in exposed
  schemas; (6) **Security checklist** (`:33-52`): auth/session (no user_metadata
  in authz, deleting user ≠ token invalidation, JWT freshness), API-key exposure
  (never expose service_role; `NEXT_PUBLIC_`), RLS/views (views bypass RLS →
  `security_invoker = true`; UPDATE needs SELECT policy; no SECURITY DEFINER in
  exposed schema), storage (upsert needs INSERT+SELECT+UPDATE).
- **Supabase CLI** (`:54-70`): discover via `--help`; known gotchas (`supabase db
  query` needs v2.79.0+; `db advisors` needs v2.81.3+; always create migrations
  via `supabase migration new`).
- **Supabase MCP Server** (`:72-86`): setup + troubleshooting (curl reachability,
  `.mcp.json`, OAuth).
- **Supabase Documentation** (`:88-94`): MCP `search_docs` → fetch `.md` pages →
  web search.
- **Making and Committing Schema Changes** (`:96-108`): use `execute_sql`/`db
  query` to iterate (NOT `apply_migration` locally); when ready: run advisors →
  review Security Checklist → `supabase db pull <name> --local --yes` → verify
  with `migration list --local`.
- **Reference Guides** (`:109-112`): `references/skill-feedback.md` (MUST read
  when skill gave wrong guidance).

### 3. Produces / enforces
- **Writes:** nothing directly; guides the operator to generate migration files
  via the CLI and to create a GitHub Issue (via skill-feedback flow) on
  `supabase/agent-skills`.
- **Reference files:** `references/skill-feedback.md` (confirmed-present),
  `assets/feedback-issue-template.md` (confirmed-present).

### 4. Enforcement type
ALL ADVISORY (a knowledge/checklist skill). The project's migration RULES that
ARE structural (REVOKE EXECUTE, no CONCURRENTLY) live in CLAUDE.md/Migrations and
are enforced by review/pre-commit, not by this skill.

### 5. Cross-references
- `references/skill-feedback.md` → `assets/feedback-issue-template.md` (both
  present). External: supabase.com docs/changelog, `supabase/agent-skills` GitHub.
- Complemented by project rules in CLAUDE.md (Migrations) and the
  `supabase-postgres-best-practices` skill.

### 6. Overlaps
- Security checklist (RLS, views, SECURITY DEFINER, storage grants) overlaps the
  project's CLAUDE.md migration rules and AGENTS.md "RBAC in src/data only, RLS =
  tenant isolation" decisions.
- Overlaps `supabase-postgres-best-practices` on RLS/security (that skill's
  category 3 `security-`).
- This is the upstream vendor skill; appears BOTH as a local `.claude/skills/`
  skill and in the runtime skills list (also `supabase-postgres-best-practices`
  appears twice — local skill + runtime list + a separate top-level Skill entry).

### 7. Claim-vs-reality
- `references/skill-feedback.md`, `assets/feedback-issue-template.md` —
  CONFIRMED-PRESENT.

---

## supabase-postgres-best-practices

### 1. Purpose / trigger
Frontmatter (`supabase-postgres-best-practices/SKILL.md:1-11`, author: Supabase,
version 1.1.1, dated Jan 2026): Postgres performance optimization + best
practices. Use when writing/reviewing/optimizing queries, schema, or DB config.

### 2. Workflow / content (reference index)
- **When to Apply** (`:18-26`): SQL/schema authoring, indexing, perf review,
  pooling/scaling, Postgres features, RLS.
- **Rule Categories by Priority** (`:28-38`): 8 categories with prefixes —
  `query-` (CRITICAL), `conn-` (CRITICAL), `security-` (CRITICAL), `schema-`
  (HIGH), `lock-` (MED-HIGH), `data-` (MED), `monitor-` (LOW-MED), `advanced-`
  (LOW).
- **How to Use** (`:40-57`): read individual rule files under `references/`;
  each has explanation, incorrect/correct SQL, EXPLAIN/metrics, context,
  Supabase notes.
- **References** (`:59-64`): external Postgres/Supabase doc URLs.

### 3. Produces / enforces
- **Writes:** nothing. Pure reference library: `references/` holds 33 rule docs
  (confirmed-present, names match the category prefixes) + `_contributing.md`,
  `_sections.md`, `_template.md`.

### 4. Enforcement type
ALL ADVISORY. Reference-only knowledge skill; no scripts/gates.

### 5. Cross-references
- Self-contained `references/` directory; external Postgres/Supabase URLs.
- Complements `/supabase` (security/RLS overlap).

### 6. Overlaps
- `security-rls-basics.md`, `security-rls-performance.md`, `security-privileges.md`
  overlap the `/supabase` Security Checklist and project RLS rules.
- Lock guidance (`lock-*.md`) overlaps `/migrate` Phase 1 Check B (lock safety)
  and CLAUDE.md "no CONCURRENTLY in migrations".
- Appears redundantly: local `.claude/skills/` dir AND the runtime available-skills
  list AND a separate top-level Skill registration with the same name.

### 7. Claim-vs-reality
- `references/` 33 rule files + 3 underscore files — CONFIRMED-PRESENT (all named
  files in the SKILL's category scheme exist).

---

## Cross-skill overlap map (facts only)

| Canonical file | Skills that WRITE it | Skills that PROPOSE/read-only | Other owners |
|---|---|---|---|
| `docs/solutions/*.md` | compound (Step 4) | notion-sync (Step 9 invokes compound) | doc-updater agent |
| `PITFALLS.md` | — | compound (Step 5 proposes) | /cr (RECURRING promotion), CLAUDE.md rules |
| `.claude/memory.md` | — | compound (Steps 6, 9 propose) | CLAUDE.md session-end rule |
| `docs/RECURRING-FINDINGS.md` | /cr (pipeline) | — | NOT compound |
| `.claude/settings.json` | — | compound (Step 7 proposes) | human-only (guard deny) |
| `TASKS.md` | prioritize-tasks (Step 4), notion-sync (Step 6 diff) | — | — |
| `.claude/TASK-TEMPLATE.md` | design (handoff paste), notion-sync (diff) | compound (Step 1 reads) | — |
| `.claude/rituals.md` | prioritize-tasks (Step 4) | — | CLAUDE.md ritual surfacing |
| Notion Changelog (35ae...) | compound (Step 8), notion-sync (Steps 4,8) | — | upstream maintainer |

Key recurrence-counting fact (re-stated): occurrence/signature counting lives
ONLY in `docs/RECURRING-FINDINGS.md`, fed by `/cr` (`cr/SKILL.md` is the only
skill referencing it). `/compound` does NO counting and never touches that file.

## Confirmed-absent items (claim-vs-reality summary)
- `.claude/skills/dep-update/SKILL.md` — empty directory.
- `docs/solutions/2026-05-18-notion-changelog-sync-process.md` — referenced
  twice by notion-sync; missing.
- `CONTEXT.md` (repo root) — referenced by compound + design; missing.
- `.claude/skills/grill-with-docs/`, `.claude/skills/to-issues/` — referenced by
  design as upstream installs; absent on disk (present in runtime global skills).
- `/scan-context` — referenced by prioritize-tasks; not in skills list.
