# CANONICAL-HARNESS-AS-IS — Multi-Project Ground-Truth Map

**What this is.** The Phase 0 deliverable: a single map of the AI engineering harness as it
*actually exists across all three layers* — Notion canon, project disk (event-vendor), and the
global machine layer (`~/.claude`, `~/.agents`, other repos). It merges:

- `HARNESS-AS-IS.md` (the 7-way fact-only audit of event-vendor's `.claude/` — **project disk**)
- `A2-canonical/cluster-A…E.md` (5 fact-only inventories of the **Notion canon**)
- direct inspection of the **global machine layer** (recorded in §2 below — not previously audited)

It is a **map, not a plan.** Every row is a verifiable fact or a verifiable absence. The governing
rule for all later phases: *no proposal survives without a citation to a row in this map* — the exact
component it changes, or a confirmed absence. Cite as `[canon §X]`, `[disk §Y]`, or `[absent]`.

Detail lives in the source files; this document is the **reconciliation layer**. It does not restate
the per-component detail already in `HARNESS-AS-IS.md` or the cluster files — it maps them against
each other and surfaces the divergences that V2 must resolve.

> **Correction log (post independent check, `A2-canonical/CHECK-canonical-map.md`).** The first draft
> inherited four stale absence-claims from `HARNESS-AS-IS.md` and they were ground-truthed false:
> `CONTEXT.md` **exists** (15 KB, created in PR #92, after the audit ran), `docs/ARCHITECTURE.md`
> **exists** (2 KB), `.githooks/pre-commit` **exists but is dormant** (`core.hooksPath=.husky/_`), and
> the third repo is `recyclops/logistics-service` (nested), not a top-level dir. **Process finding: the
> project audit artifact itself rots** — `HARNESS-AS-IS.md` predates files the repo has since created.
> Any "ABSENT" claim sourced to it must be re-verified before being cited as a confirmed absence. The
> rows below are corrected; the remaining `HARNESS-AS-IS §7` phantoms (`learned-patterns.md`,
> `review-log.md`, `triage-inbox.md`, `agentic-system-enabled`, `skills-lock.json`) were re-checked and
> are genuinely absent.

---

## 0. The headline (read this first)

Three layers, and they do not agree:

1. **Notion canon (the design target).** A tool-agnostic "AI-Native Engineering System,"
   currently **v1.1 (2026-06-07)**, built from two codebases (Vue/Firestore + Next/Supabase). On
   *enforcement breadth and doctrine* it is ahead of disk (it declares structural mechanisms — a third
   bash guard, scope/branch-registry guards, a session-end memory hook, a pre-push sync gate — that
   disk lacks). But **disk is ahead on other axes**: a real Tier-0 prod-key firewall + worktree
   provisioning + permission logger the canon never specifies, and several knowledge docs now built
   (`CONTEXT.md`, `ARCHITECTURE.md`, `RECURRING-FINDINGS.md`, `TASKS.md`). So it is not "canon ahead,
   disk behind" — it is **bidirectional drift**. The canon is also **internally inconsistent** (two
   feature loops, two reviewer names, Pages 12↔13 contradict on anti-rationalization tables and the
   60% handoff trigger); where pages conflict the **later-dated page wins** and is noted.

2. **Project disk (the real harness).** event-vendor's `.claude/` — ~26 skills, 23 agents, 5 Claude
   hooks, 3 git hooks, 6 scripts, 2 CI workflows, a 5-store memory layer. Roughly **v0.97–v1.0**:
   behind canon by ~4 versions. This is the *only* place the rich harness actually runs. Fully mapped
   in `HARNESS-AS-IS.md`.

3. **Global machine layer (nearly empty).** `~/.claude` has **no** global `CLAUDE.md`, **no** global
   agents, hooks, commands, or memory — just a minimal `settings.json`, one Notion plugin, and 15
   skills *symlinked* to `~/.agents/skills/` (generic Matt-Pocock/Supabase/Vercel skills). Other
   repos carry **no harness**: `recyclops/.claude` is a one-line allowlist; `recyclops-logistics-service/.claude`
   is empty.

**The central structural fact of V2:** the harness the canon describes as "global / multi-project"
is, on disk, a **single-project artifact** (event-vendor) plus **generic third-party skills** plus
**Notion documentation**. There is no installable, shared, version-controlled harness. The "multi-project
canonical harness" is, today, aspirational. *Every binding principle for V2 — global, GitHub-hosted,
bidirectional self-update, compounding — is a response to this gap.*

And the canon already tells us where to cut: **Page 13 (Model Capacity Audit)** declares the system
"operates at 60% of what the current model can do," distinguishes **reasoning discipline (keep)** from
**capability proxies (remove)**, gives a 14-row keep/replace table, and states its judgments were made
against **Sonnet 4.6** and are due for re-audit on a model update. We are on **Opus 4.8**. That re-audit
is part of this effort. (Reproduced in §9.)

---

## 1. Layer map — where each kind of thing lives

| Layer | Location | Contents | Status |
|---|---|---|---|
| **Notion canon** | `notion.so/358e…` (AI-Native Engineering System) | 15 numbered Reference pages, Templates, Setup Prompts, Quick-Start, Changelog (→v1.1), Incidents, a 24-item "To Think About" backlog, and the Research corpus | The documented design; ahead of disk; internally inconsistent |
| **Project disk** | `~/Dev/event-vendor/.claude/` + repo root + `docs/` | The running harness (skills/agents/hooks/scripts/CI/memory). Mapped in `HARNESS-AS-IS.md` | Real, drifted, ~v0.97–1.0 |
| **Global skills** | `~/.agents/skills/` (15) ← symlinked from `~/.claude/skills/` | caveman, diagnose, find-skills, grill-me, grill-with-docs, improve-codebase-architecture, setup-matt-pocock-skills, supabase-postgres-best-practices, tdd, to-issues, to-prd, triage, vercel-react-best-practices, write-a-skill, zoom-out | Generic third-party; installed via `mattpocock/skills` (`.skill-lock.json`, v3) |
| **Global config** | `~/.claude/settings.json`, `~/.claude.json` | Minimal: permissions for one sibling repo, `notion` MCP (http), `effortLevel:xhigh`, the notion-workspace plugin. **No global CLAUDE.md.** | Near-empty vs canon's prescribed `~/.claude/CLAUDE.md` |
| **Plugin** | `~/.claude/plugins/…/notion-plugin-marketplace` | 11 Notion commands (create-page/task/db-row, find, search, tasks build/plan/setup/explain-diff) + `notion` MCP | Third-party (makenotion) |
| **Other repos** | `recyclops/.claude`, `recyclops-logistics-service/.claude` | one-line allowlist / empty | **No harness present** |

**Key cross-layer couplings & frictions (facts):**

- **The `CONTEXT.md` coupling.** The 15 global Matt-Pocock skills (`grill-with-docs`,
  `improve-codebase-architecture`, `diagnose`, etc.) are *written to expect* `CONTEXT.md`, `docs/adr/`,
  `docs/agents/`, and an issue tracker. event-vendor adopted these skills' vocabulary *and eventually
  created the file* — `CONTEXT.md` now exists (15 KB, PR #92). The artifact V1-planning treated as a
  phantom is real; the live coupling is that **project structure is being pulled toward an upstream
  ecosystem's expected layout** (`docs/agents/`, issue-tracker assumptions) that the project has only
  partially adopted. [global skills frontmatter; disk `CONTEXT.md`]
- **`/tdd` and `/supabase-postgres-best-practices` exist in both layers.** `supabase-postgres-best-practices`
  is a *symlink* (project → global, shared). **`/tdd` is a project-local fork** (5.2 KB, edited 2026-06-07)
  that has diverged from the global Matt-Pocock `tdd` — two copies, no sync. [disk: `.claude/skills/tdd/SKILL.md`]
- **The runtime skill list mixes all layers.** When the agent sees `/cr`, `/queue`, `/dev` (project),
  `/tdd`, `/triage`, `/to-issues` (global), and `Notion:*` (plugin) in one list, it cannot tell which
  layer owns each, nor which will travel to another project. None of the project skills travel.

---

## 2. Global machine layer — full inventory (newly audited)

This layer was not covered by the prior project audit. Facts:

```
~/.claude/
  settings.json        # permissions(allow: 3 Read globs for event-vendor-item-form; additionalDirectories: 2),
                       # enabledPlugins(notion-workspace-plugin), extraKnownMarketplaces(notion),
                       # effortLevel: xhigh, theme, notif flags, switchModelsOnFlag. NO hooks. NO agents.
  skills/              # 15 SYMLINKS → ~/.agents/skills/*   (no project-specific skills globally)
  plugins/             # notion-plugin-marketplace (11 commands + notion MCP); official marketplace cached
  projects/            # per-project transcript/history dirs (event-vendor, recyclops×2, worktrees, /private/tmp)
  (NO CLAUDE.md, NO agents/, NO hooks/, NO commands/, NO memory/, NO rituals/)
~/.claude.json         # global config: mcpServers={notion(http)}; projects tracked = {event-vendor,
                       # recyclops/logistics-service}; onboarding/feature caches. No global behavior rules.
~/.agents/
  .skill-lock.json     # v3 lockfile; source mattpocock/skills (+ supabase, vercel, anthropic)
  skills/              # the 15 real skill dirs the symlinks point to
~/Dev/recyclops/.claude/settings.json            # {permissions.allow:[mcp__claude_ai_Notion__notion-fetch]}
~/Dev/recyclops/logistics-service/.claude/       # empty (a tracked project per ~/.claude.json; no harness)
```

**Canon vs global-disk:** Canon Page 09 prescribes a global `~/.claude/CLAUDE.md` (personal behavior
config: directness, push-back, teaching style, the 3-question pre-commit checkpoint) + `~/.claude/statusline.sh`.
**Neither exists on disk.** Canon does *not* prescribe global agents/skills/hooks — so the 15 symlinked
skills are a disk addition the canon doesn't specify, and the absence of global agents is *canon-consistent*.
Net: the global layer is missing the one file canon says it must have (`~/.claude/CLAUDE.md`), and the
harness's own SOUL/values/process live entirely inside event-vendor. [`cluster-D §4`]

---

## 3. Component reconciliation — canon vs disk

Legend: ✅ present · ❌ absent · ⚠️ present-but-drifted · `n/a` not applicable to that layer.
"Canon" = documented in Notion. "Proj" = event-vendor disk. "Glob" = global machine layer.

### 3a. Governance / context docs

| Component | Canon | Proj | Glob | Divergence |
|---|---|---|---|---|
| `CLAUDE.md` (repo root) | ✅ | ✅ | n/a | Aligned in purpose |
| `~/.claude/CLAUDE.md` (global behavior) | ✅ §09 | n/a | ❌ | **Canon-mandated, absent globally** — values live only in project SOUL |
| `AGENTS.md` | ✅ | ✅ | n/a | event-vendor's has the "None open" contradiction [`HARNESS-AS-IS §7`] |
| `CONTEXT.md` | ✅ ("the *why*", hardest doc) | ✅ (15 KB, PR #92) | n/a | Built *after* the project audit — upstream-ecosystem coupling (§1) |
| `.claude/SOUL.md` | ✅ (1-page values) | ✅ | n/a | Aligned |
| `.claude/agent-contract.md` | ✅ | ✅ | n/a | Aligned |
| `.claude/INDEX.md` | ✅ (external resources) | ✅ | n/a | Aligned |
| `.claude/AI-WORKFLOW.md` | ✅ | ✅ | n/a | Aligned |
| `docs/ARCHITECTURE.md` | ✅ §03 (tech-debt ledger) | ✅ (2 KB) | n/a | Present (audit had it stale-absent) |
| `docs/TESTING.md` | ✅ | ✅ | n/a | Aligned |
| `STRATEGY.md` | ⚠️ (templates only) | ✅ | n/a | Disk has it; canon documents only the template |

### 3b. Skills (registry)

The canon documents **~46 skills** across pipeline/workflow/ecosystem pages; disk has **26** project
skill dirs (one empty). The split:

- **On disk AND in canon, aligned:** `cr`, `cr-security`, `feature`, `design`, `compound`, `tdd`,
  `incident`, `evaluate-solution`, `debug`, `hotfix`, `migrate`, `behavior-change`, `perf`, `queue`,
  `refactor`, `spike`, `post-mortem`, `review-strategy`, `setup-strategy`, `prioritize-tasks`,
  `notion-sync`, `supabase`, `supabase-postgres-best-practices`.
- **On disk, NOT documented in canon pages 05/06/11/Templates:** **`dev`, `explain`** — entirely absent
  from the canon's skill pages. [`cluster-C Notable`]
- **`dep-update`:** canon documents it *in full* (2 modes, 5 phases, audit-depth table); **disk is an
  empty stub** (no SKILL.md). Canon is richer than disk. [`cluster-C`; `HARNESS-AS-IS §7`]
- **Documented in canon, ABSENT on disk (project):** `/scan-context` (full template), `/handoff`
  (detailed), `/setup` (9-step bootstrap), `/simplify` (in feature loop), `/prototype-interface`,
  `/prototype-ui`, `/visual-design`, `/vibe-check`, `/ideate`. [`cluster-C`]
- **`/cr-feature`:** **RETIRED v0.85** in canon (folded into `/cr`), yet still referenced in canon's
  own Page-11 action items and Page-14 worktree section — a canon self-contradiction. Disk correctly
  has no `/cr-feature`. [`cluster-C §6`, `cluster-D §7`]
- **Global (Matt-Pocock) skills, real on disk at `~/.agents/skills/`, documented as "upstream":**
  `grill-with-docs`, `grill-me`, `to-issues`, `to-prd`, `improve-codebase-architecture`, `diagnose`,
  `zoom-out`, `triage`, `caveman`, `write-a-skill`, `find-skills`, `setup-matt-pocock-skills`,
  `vercel-react-best-practices`. (`/prototype` documented upstream but not in the global store.)

### 3c. `/cr` and `/cr-security` pass structure (canon vs disk vs runtime description)

| Source | `/cr` | `/cr-security` |
|---|---|---|
| **Canon §05** | 9 passes P1–P9, *Devil's Advocate folded in as P9* (4 attack vectors); Step 3b recurring-findings; Opus auto-fix. **No P0, no P10** in its table — yet its own auto-fix prose cites "P0–P10" (internal bug). | **2 passes** (Security & Auth; Data Boundary Integrity), Sonnet, all MUST FIX |
| **Disk** (`HARNESS-AS-IS §4`) | "9 parallel passes (1–9) + Pass 11 `@reviewer` (4 lenses). **No Pass 10.** No REJECT tier, no UNATTENDED branching." | 3 passes (per `HARNESS-AS-IS`) |
| **Runtime skill registry** (this session's live skill list) | "9 analytical passes **plus** an adversarial review" (implies 10) | "3-pass" (`cr-security` registration) |

→ Three sources, three pass-count framings. The canon's "P9 = adversarial" and disk's "Pass 11 =
adversarial, no Pass 10" are reconcilable in spirit but differ in numbering; the runtime description's
"9 plus adversarial" disagrees with the canon's "9 including adversarial." **`/cr-security` pass count
differs (canon 2 vs disk 3).** [`cluster-C §3`; `HARNESS-AS-IS §7`]

### 3d. Agents

Canon documents a **7–10 specialist roster** (reviewer, explorer, spec-writer, implementer,
doc-updater, security-reviewer, ux-reviewer, task-runner, investigator, + 6 spike agents). Disk has
**23 agents** including all 4 lenses (assumption/composition/cascade/abuse), hotfix-guard,
refactor-extractor, solution-evaluator, incident-responder, and the 6 spike agents. Canon's File-Structure
tree (§03) shows a **narrower, older 7-agent roster** than both its own prose and the disk. Canon's
Templates page has agent-count inconsistencies ("8 specialist agents" header over a 9-row table; "Ten"
v0.19 templates over an 8-role build order). Disk roster ⊇ canon tree roster. [`cluster-A`, `cluster-C §2`]

### 3e. Hooks (the enforcement gap)

| Hook | Canon | Proj disk | STRUCTURAL? | Divergence |
|---|---|---|---|---|
| `block-dangerous-git.sh` | ✅ | ✅ | yes (exit 2; jq fail-**open**) | Aligned; both fail-open on missing jq |
| `block-npm-install.sh` | ✅ | ✅ | yes (exit 2; jq fail-open) | Aligned |
| `block-dangerous-bash.sh` | ✅ (deploys, `rm -rf`, writes to `.git`/`.husky`/`.claude`) | ❌ | yes | **Canon's 3rd guard — ABSENT on disk.** Disk has no safety-floor bash guard |
| `enforce-scope.sh` | ✅ (blocks staging files outside TASK-TEMPLATE `## ALLOWED FILES`) | ❌ | yes | **Canon structural, absent on disk** |
| `branch-registry-guard.sh` | ✅ (blocks commit when another session owns the branch) | ❌ | yes | **Canon structural, absent on disk** |
| `session-end.sh` (Stop → memory candidates) | ✅ | ❌ | observational | **Canon's memory-capture hook — absent**; disk's memory is fully manual |
| `permission-logger.sh` | ❌ | ✅ | observational | **Disk-only**, canon declares no logging hook |
| `session-start.sh` (SessionStart) | ✅ | ✅ | mixed | Aligned in event; disk also does remote npm install |
| `worktree-create.sh` (WorktreeCreate) | ❌ | ✅ | structural in UNATTENDED | **Disk-only** (prod-key firewall); a genuine disk advance over canon |
| pre-commit | ✅ `.githooks/pre-commit` (w/ main-branch agent hard-block) | ⚠️ BOTH exist; `.githooks/` is **dormant** (`core.hooksPath=.husky/_`), live `.husky/pre-commit` is a 67-byte shim | yes | **Enforcement gap, not a location difference.** The live husky pre-commit lacks canon's main-branch agent block; the canon-matching `.githooks/pre-commit` is wired out |
| pre-push | ✅ + **sync-gate** | ✅ (no sync gate) | yes | Canon adds an auto-rebase sync gate disk lacks (and canon's own §14↔template disagree) |
| post-checkout | ✅ | ✅ | observational | Aligned |

**Net enforcement picture:** Canon declares a *broader* structural floor (3 bash guards + scope guard +
branch-registry guard + `.cr-ok` chain + pre-push sync gate). Disk implements a *narrower* one (2 bash
guards + `.cr-ok` chain + pre-push without sync gate) plus two disk-only mechanisms canon lacks (prod-key
firewall, permission logger). **Both agree the system is overwhelmingly advisory** — neither has a
deterministic backstop for the bulk of skill bodies, CLAUDE.md rules, or the autoMode lists.
[`cluster-D §1,§3`; `HARNESS-AS-IS §3`]

### 3f. Scripts / CI

Disk: `pr.sh`, `worktree-add.sh`, `gc.sh`, `gen-local-env.sh`, `test-local.sh`, `seed.ts`; CI
`ci.yml` + `integration.yml`. Canon's only script template is `pr.sh`; canon documents `.github/workflows/ci.yml`
+ `.husky/*`. **Disk carries the canon's `.githooks/pre-commit` but has wired it out** (`core.hooksPath=.husky/_`),
running a 67-byte husky shim that lacks the canon's main-branch agent hard-block (§3e). The Node 8.5(c)
gap (CI never verifies `.cr-ok`) is a disk fact [`HARNESS-AS-IS §8`]; canon's `.cr-ok` chain has the same
hole (gitignored, never reaches CI). [`cluster-D §2h`]

---

## 4. The memory model — declared vs built (the Phase 3 crux)

**Canon's declared model** (`cluster-B`): the "Three documents" core — `memory.md` (session
corrections, read every session start), `RECURRING-FINDINGS.md` (pipeline-only, auto-counted by `/cr`
Step 3b, never read by implementers), `PITFALLS.md` (canonical traps, promoted ≥3 or by judgment,
read before writing code) — *plus* `docs/solutions/` (reusable positive patterns), `docs/adr/` (locked
decisions), and the context docs (SOUL/CONTEXT/AGENTS/CLAUDE). Promotion: session→memory.md; pipeline→
RECURRING-FINDINGS→(human-confirmed)→PITFALLS; quarterly `/compound` Step 7 stale-review of memory.md
(90-day `last_seen`).

**What's built on disk** (`HARNESS-AS-IS §4`): the same five stores **plus the harness's own
auto-memory** (`MEMORY.md` + 51 siblings, user-scoped, written by the Claude Code subsystem, not any
skill). The auto-memory layer is **not in the canon at all** — it's a sixth store the canon's model
doesn't account for.

**The triple-duplication the canon both sanctions and forbids:** canon says "A pattern can appear in
all three" (memory.md + RECURRING-FINDINGS + PITFALLS) *and* "Do not duplicate what's already in
PITFALLS.md" / "Redundant → remove." The reconciliation ("same knowledge at different lifecycle
stages") exists only in prose, encoded in no tooling. On disk this manifests as the same corrected-mistake
facts living in `.claude/memory.md` + `PITFALLS.md` + auto-memory `feedback_*` files simultaneously,
with `/compound` itself flagging memory entries as "already covered by PITFALLS (redundant)."
[`cluster-B Notable`; `HARNESS-AS-IS §6`]

**Canon's own admitted ambiguities** (so V2 doesn't inherit them): PITFALLS.md and memory.md are
assigned to *both* Layer 1 (Context) and Layer 3 (Memory) depending on the page; read-time is specified
for only ~5 of ~14 knowledge files; freshness rules exist for only 3 stores (memory 90-day, PITFALLS
changelog-driven, RECURRING-FINDINGS cap-at-5). [`cluster-B Notable`]

→ **For Phase 3:** the target is ONE coherent model that (a) accounts for the auto-memory store the
canon ignores, (b) encodes the lifecycle-stage reconciliation in tooling rather than prose, (c) gives
every store one writer/one reader/one freshness rule, (d) collapses the triple-duplication.

---

## 5. Canon-only registry — declared, NOT on disk (candidate build-or-reject)

Each is a citable absence. V2 must decide, per item: build it, or reject it with reason.

| Item | Canon cite | Nature |
|---|---|---|
| `~/.claude/CLAUDE.md` (global behavior config) | §09 | Personal behavior rules; the global layer's missing keystone |
| `block-dangerous-bash.sh` | §08, cluster-D §1 | 3rd structural guard (deploys, `rm -rf`, boundary writes) |
| `enforce-scope.sh` | §08/§14 | Structural: blocks staging files outside ALLOWED FILES |
| `branch-registry-guard.sh` + `active-branches.json` | §14 | Structural: one-session-per-branch collision guard |
| `session-end.sh` (Stop hook) | §08, cluster-B | Auto-proposes memory candidates — disk memory is fully manual |
| Git Status Preamble | §14 | Model-emitted state block (advisory even in canon) |
| pre-push auto-rebase sync gate | §14 | Structural drift guard (canon's §14 and template disagree) |
| `/scan-context`, `/handoff`, `/setup`, `/simplify`, `/prototype-*`, `/vibe-check` | §06/§11 | Documented skills with no disk dir (`/ideate` is backlog-only, To-Think-About #6) |
| main-branch agent hard-block in pre-commit | §08 | Canon's `.githooks/pre-commit` blocks agent commits on `main`; disk's live husky shim lacks it (§3e) |

## 6. Disk-only registry — built, NOT in canon (candidate document-or-delete)

| Item | Disk cite | Nature |
|---|---|---|
| `/dev`, `/explain` skills | `HARNESS-AS-IS §2` | Real skills the canon's skill pages never mention |
| `permission-logger.sh` | §3e | Observational hook canon doesn't declare |
| `worktree-create.sh` + prod-key firewall (`gen-local-env.sh`, `test-local.sh`) | `HARNESS-AS-IS §3` | A genuine disk *advance* (Tier-0 credential isolation) canon lacks |
| Auto-memory (`MEMORY.md` + 51 siblings) | `HARNESS-AS-IS §4` | A whole 6th memory store outside canon's model |
| `dep-update/` empty dir | `HARNESS-AS-IS §7` | Stub; canon documents the skill fully but disk never built it |
| `/cr-security` 3rd pass | §3c | Disk has 3 passes; canon documents 2 |
| Phantom refs (`learned-patterns.md`, `review-log.md`, `triage-inbox.md`, `/prototype-interface`, `/scan-context`, `@benchmark-runner`, `skills-lock.json`, `agentic-system-enabled`) | `HARNESS-AS-IS §7` | Referenced on disk, never built on disk *or* in canon |

## 7. Canon internal contradictions (do not cite a contradictory target)

1. **Two feature loops** — §02 includes `/simplify` + `/cr-security`; Quick-Start omits both and inserts
   `/cr-feature`. [`cluster-A §6`]
2. **Two reviewer names** — `@reviewer`/`/cr` (00/02) vs `/cr-feature` (Quick-Start), the latter retired v0.85.
3. **Pages 12 ↔ 13 contradict** — §12 mandates anti-rationalization tables on mature skills; §13 (later)
   calls them "distrust codified / ghost rules → collapse + quarterly audit." **§13 wins** (later-dated).
4. **60% handoff trigger** — §12 treats it as load-bearing; §13 says replace with coherence self-assessment.
   **§13 wins.** [`cluster-E Notable`]
5. **`/cr` numbering** — table is P1–P9 but auto-fix prose cites "P0–P10." [`cluster-C §3`]
6. **Agent counts** — "8 specialist agents" over 9 rows; "Ten" templates over 8 roles. [`cluster-C §2`]
7. **pre-push sync gate** — §14 says add it; the pre-push template omits it. [`cluster-D §1c`]
8. **Upstream-skill install method** — 00 says vendor as committed copies (not symlinks); Quick-Start says
   install globally. Disk does *both* (symlinks for some, a fork for `/tdd`). [`cluster-A §6`]
9. **v0.16 ownership table** — §03 carries an un-applied "add these rows manually" block (self-declared
   mid-migration). [`cluster-A §6`, `cluster-B §6`]

## 8. Cross-project reality

- **event-vendor** — the entire rich harness. Single-project.
- **recyclops** — `.claude/settings.json` = one allowlist line (`notion-fetch`). No harness.
- **recyclops/logistics-service** — empty `.claude/` (a tracked project per `~/.claude.json`). No harness.
- **Global** — 15 generic third-party skills + Notion plugin. No project-specific harness, no global CLAUDE.md.

→ The harness has **never been installed anywhere but event-vendor.** "Multi-project" is a goal, not a
state. The canon's own backlog confirms it: "GitHub Publishing — *in progress (agent-harness migration);
next gate: 3 real installs*" and "apply engineering system to Recyclops" are both unmet. [`canon To-Think-About #20,#22`]

## 9. The Model Capacity Audit (Page 13) — canon's pre-authorized cuts

Reproduced because it pre-authorizes much of V2's deletion and sets the boundary on how far "empower the
model, remove the scaffold" may go. Canon's own keep/replace judgments (made against **Sonnet 4.6**;
**re-audit due on model update → now Opus 4.8**):

**Replace (capability proxies — scaffolds the current model no longer needs):**
- Structural option-count forcing (`/design explore` 2–3, `/visual-design` 3, `/prototype-ui` 3–5,
  4 compound questions) → "state thoroughness directly / goal + anti-pattern."
- Anti-rationalization tables on mature skills → "ghost rules if unobserved 90 days; collapse + quarterly audit."
- `/handoff` 60% context tracking → "replace with coherence self-assessment."
- STOP-AND-SURFACE breadth ("domain not in CONTEXT.md") → "narrow to consequential decisions."
- Phrase-keyed skill descriptions → "trigger should be the situation, not the words."
- The `.cr-ok` sentinel as a capability gate → "document as a readiness signal, not a capability unlock."

**Keep verbatim (reasoning discipline / safety — never remove):**
- Destructive-operation rules (PocketOS); `/grill-with-docs` Phase 1 three human questions; the manual-QA
  coverage blocker; the prototype-deletion rule; tracer-bullet-first in `/tdd`. "Treating a safety
  constraint like a quality constraint is the PocketOS incident."

**Golden rule (canon):** "If you can't name a failure mode that the constraint prevents, the constraint
is overhead." [`cluster-E §2`]

---

## How later phases cite this map

- A Phase-2 article insight is **actionable** only if it maps to a §3–§9 row (a real gap) — not to a
  canon ideal that's already built, nor to a disk mechanism that already covers it.
- A Phase-3/4/5 proposal **must** name its row: a canon-only item to build (§5), a disk-only item to
  document-or-delete (§6), a duplication to collapse (§4, `HARNESS-AS-IS §6`), or a §9 proxy to remove.
- The anti-duplication gate (Phase 6) checks every surviving item against this map. The V1-planning
  failures (`learned-patterns.md`, bugfix-test rule, `/simplify` wiring) would each be killed here:
  `learned-patterns.md` is §6 phantom; the bugfix-test rule duplicates `/tdd` (§3b); `/simplify` is a
  canon-only absence (§5), not a disk mechanism to wire.
