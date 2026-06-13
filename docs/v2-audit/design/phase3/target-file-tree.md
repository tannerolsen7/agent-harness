# V2 Target File Tree — the consolidation map (Phase 3 synthesis)

**What this is.** The single CURRENT→TARGET file tree for the harness, covering `.claude/`, repo-root
knowledge docs, and `docs/` (excluding the `v2-audit/` research tree, which is this effort's own scratch).
Every line carries a DELETE / MERGE-INTO / MOVE-TO / KEEP / NEW annotation with a one-line reason citing a
map row, a §9 failure-mode, an `[inv …]` census row, the enforcement-sort table, or a disk path
re-verified on disk this session (2026-06-11).

**Governing rule honored.** Nothing here builds something that already exists (anti-phantom: MASTER-
FINDINGS §E). The only NET-NEW files are the `.claude/rules/*.md` shards (§5 — the sanctioned path-scoped
tiering, ABSENT today) plus the small build set the enforcement-sort already named (3 hooks + arch-test rig
+ CI scripts — those are *mechanisms*, counted at the end, not knowledge files). Every absence I rely on
was re-verified on disk: `.claude/rules/` ABSENT; `block-dangerous-bash.sh` / `enforce-scope.sh` /
`session-end.sh` ABSENT; `dep-update/` empty (no `SKILL.md`); `lens-*` agents ARE wired (corrected below).

**The honest headline, stated up front.** This tree deletes/relocates **~22 discrete items** and *adds*
**~9 net-new files** (8 `.claude/rules/` shards + 1 `.cr-fix` artifact). The raw knowledge-file count drops
modestly. **The big count win is not in the harness knowledge docs — it is in clutter and worktrees**
(7 stale worktrees, each a full repo copy; 6 spent per-task scratch files). The *load-bearing* win is not a
file-count drop at all: it is **one corrected-mistake fact existing in ONE canonical place instead of three**
(`.claude/memory.md` + `PITFALLS.md` + auto-memory), and **the 43 KB PITFALLS monolith — today loaded 4×
in parallel by `/cr`'s lens agents (verified: `reviewer.md` passes `PITFALLS.md` to each of 4 lens agents)
— becoming a ~2 KB path-scoped load.** I say this plainly because the binding principle demands honesty:
if you score V2 purely by `find | wc -l`, the knowledge-doc win is small. The win is the *collapse of
duplication and the path-scoping of reads*, which the count alone does not capture. Full reconciliation in
the final COUNT section.

---

## 0. Reading guide — the five disposition verbs

- **KEEP** — survives; for skills/agents a one-line §9 failure-mode justification is given (the survivor test).
- **NEW** — net-new file; only the `.claude/rules/*.md` shards qualify (sanctioned per FRESH GROUND TRUTH +
  memory-model §7). Mechanisms (hooks/CI scripts) are listed in §9, not counted as knowledge files.
- **MERGE-INTO-`<x>`** — content folds into `<x>`; the source file is then DELETE-CANDIDATE.
- **MOVE-TO-`<x>`** — relocated, not deleted (archive or correct home).
- **DELETE-CANDIDATE** — recommend deletion pending human confirm. CLAUDE.md forbids silent deletion, so
  every delete here is a *flag*, not an executed action. Mutating ops (worktree removal) are NEEDS-HUMAN.

"Owned store" labels (S1/S2/S3) refer to the memory-model's 3 harness-owned stores + 1 ridden cache.

---

## 1. `.claude/` top level — CURRENT → TARGET

CURRENT (17 top-level files + 5 dirs, verified `ls .claude/`):

```
.claude/
  .cr-ok.consumed        58 B     spent sentinel receipt
  AI-WORKFLOW.md         7 KB
  INDEX.md               3.5 KB
  SOUL.md                3.5 KB
  TASK-TEMPLATE.md       29 KB
  agent-contract.md      5.5 KB
  diff-review.md         3 KB
  grill-progress-change-quote-request.md  14 KB
  mcp.md                 7 KB
  memory.md              10 KB / 166 L
  questions.md           1 KB
  rituals.md             2 KB
  settings.json          7 KB
  settings.local.json    4 KB
  walkthrough-item-form-refactor.md        2.2 KB
  walkthrough-item-form-type-boundary.md   1.3 KB
  walkthrough-public-write-rpc-pattern.md  513 B
  agents/   skills/   hooks/   notes/(empty)   worktrees/(7)
```

TARGET disposition:

| Item | Disposition | Reason (cite) |
|---|---|---|
| `.cr-ok.consumed` | **DELETE-CANDIDATE** + gitignore `.cr-ok*` | Spent sentinel receipt; prevents no failure mode `[inv B1]`. Enforcement-sort relocates the stop authority to **CI/branch-protection** (`MUST-FIX=0 AND CI-green on sentinel SHA`, resolution (b)), so the on-disk `.cr-ok` ceases to be the trust anchor — the consumed receipt is pure residue. |
| `.cr-ok` (live, gitignored) | **KEEP as local convenience, DEMOTE authority** | Still written locally by `/cr`, but it is no longer the *gate* — branch-protection is (enforcement-sort (b)). Add `.cr-ok*` to `.gitignore` (already is per sort) so neither it nor `.consumed` is ever tracked. |
| `notes/` (empty dir) | **DELETE-CANDIDATE** | Empty; no writer/reader on disk `[inv B1, §9]`. |
| `TASK-TEMPLATE.md` (29 KB) | **DELETE-CANDIDATE** | Its enforcement counterpart `enforce-scope.sh` (which would read `## ALLOWED FILES`) is **ABSENT** `[map §3e/§5; re-verified]`, so the structural payload is inert. The scope discipline it advises is covered by CLAUDE.md "Before writing code" + the enforcement-sort's `/cr-security` glob classifier (resolution (c)). A 29 KB inert advisory doc is overhead `[§9]`. **If** MOVE-2 ever builds `enforce-scope.sh`, a ~2 KB machine-readable scope spec is reborn then — not this 29 KB doc. |
| `grill-progress-change-quote-request.md` (14 KB) | **DELETE-CANDIDATE** | Spent per-task checkpoint, header "FINAL — user takes #86 manually" `[inv B1]`. Belongs to the PR that produced it, not the harness root. |
| `walkthrough-item-form-refactor.md` (2.2 KB) | **DELETE-CANDIDATE** | Spent generated QA walkthrough; regenerable `[inv B1, §9]`. |
| `walkthrough-item-form-type-boundary.md` (1.3 KB) | **DELETE-CANDIDATE** | Same class `[inv B1]`. |
| `walkthrough-public-write-rpc-pattern.md` (513 B) | **DELETE-CANDIDATE** | Header "docs-only branch — no new confirmed behaviors"; empty of signal `[inv B1]`. |
| `questions.md` (1 KB) | **DELETE-CANDIDATE** | Single stale NON-BLOCKING per-task scratch about migration 0062 `[inv B1]`. |
| `diff-review.md` (3 KB) | **KEEP** (fold into `/cr`) | KEEP-VERBATIM floor — the manual-QA / human-semantic checkpoint ("what only a human can catch"). §9 failure prevented: regression-trust ≠ correctness-trust `[map §9; inv B1]`. Fold its checklist into `/cr`'s human-checkpoint section so it *travels with the gate* instead of sitting as a loose file. |
| `mcp.md` (7 KB) | **KEEP** | Canonical MCP registry + "Playwright rejected" decision `[MASTER-FINDINGS §E]`. Failure prevented: re-litigating a rejected MCP server. |
| `memory.md` (10 KB) | **MERGE → DELETE-CANDIDATE** | Store S1 source. Safety trio → already verbatim in CLAUDE.md floor (`tier: safety`, verified `[inv S1; map §9]`); behavior rules → verbatim CLAUDE.md dups, deleted; codebase traps → `.claude/rules/<area>.md`; capture role → auto-memory (free). The *file* dies; no fact is lost `[memory-model §i row 1]`. |
| `rituals.md` (2 KB) | **KEEP** + add 2 clocked entries | The heartbeat layer already exists `[MASTER-FINDINGS §E]`; gap is the missing clock, not the layer. Add `/compound` (weekly) and `scan-context` (per-push via CI) so the conveyor actually fires `[memory-model §3]`. |
| `settings.json` (7 KB) | **KEEP** (guard file, human-only) | No agent edits `[memory: no_agent_edits_guard_files]`. autoMode block is a *placement* fix (move to `settings.local.json`/`managed-settings.json` — enforcement-sort (e)), human handoff, not a delete. |
| `settings.local.json` (4 KB) | **KEEP** (guard file) | Correct home for autoMode per enforcement-sort (e). |
| `SOUL.md` (3.5 KB) | **KEEP** | Values doc `[map §3a]`. |
| `agent-contract.md` (5.5 KB) | **KEEP** | Sub-agent contract `[map §3a]`. Plugin-shipped (§8). |
| `INDEX.md` (3.5 KB) | **KEEP** (drift-check) | External-resources index `[map §3a]`. Every ref must resolve under the new drift CI (§9, FICTION class) — it is a phantom-ref vector. |
| `AI-WORKFLOW.md` (7 KB) | **KEEP** (MERGE candidate) | Workflow doc `[map §3a]`. Candidate to merge into CLAUDE.md's workflow section if duplicative — flag, not a forced cut; verify overlap before merging. |
| `agents/` (23) | **KEEP dir** (prune 0, see §3) | Roster `[map §3d]`; collapse-to-skills rejected `[MASTER-FINDINGS §F]`. All 23 survive §9 (§3 below). |
| `skills/` (26 dirs) | **KEEP dir, 1 cut** | Registry `[map §3b]`. Cut `dep-update/` (empty). The other 25 survive (§3). |
| `hooks/` (5) | **KEEP + ADD** | All 5 live `[map §3e]`. MOVE-1/2 *add* `session-end-capture.sh` + `block-dangerous-bash.sh`; subtract none. |
| `worktrees/` (7) | **DELETE-CANDIDATE (NEEDS-HUMAN batch)** | §B5 — the largest clutter mass; each is a full repo copy carrying stale memory.md/PITFALLS/RECURRING-FINDINGS copies (the reason the RECURRING-FINDINGS grep returned 21 worktree hits). Removal is a mutating op → surface merged-state check + `git worktree remove` for Tanner; do not auto-run `[inv B5; destructive-op rules]`. |
| `notes/` | (already above) | |
| **`rules/` (NEW dir, 8 shards)** | **NEW** | The sanctioned net-new build — path-scoped constraint delivery. ABSENT today (re-verified). Full design §5. |

TARGET `.claude/` top level (after):

```
.claude/
  AI-WORKFLOW.md         (KEEP; merge-candidate into CLAUDE.md)
  INDEX.md               (KEEP, drift-checked)
  SOUL.md                (KEEP)
  agent-contract.md      (KEEP, plugin-shipped)
  diff-review.md         (KEEP — folded into /cr human-checkpoint)
  mcp.md                 (KEEP)
  rituals.md             (KEEP + 2 clocked entries)
  settings.json          (KEEP, guard)
  settings.local.json    (KEEP, guard; autoMode lands here)
  rules/                 (NEW — 8 path-scoped shards, §5)
  agents/  (23, all KEEP)
  skills/  (25 — dep-update cut)
  hooks/   (5 KEEP + 2 NEW: session-end-capture.sh, block-dangerous-bash.sh)
  [GONE: .cr-ok.consumed, memory.md, TASK-TEMPLATE.md, grill-progress-*.md,
         3× walkthrough-*.md, questions.md, notes/, worktrees/*(stale)]
```

`.claude/` top-level **files: 17 → 9** (−8). New `rules/` dir adds 8 shard files (counted as NEW). Two new
hooks. The top-level *clutter* (scratch + spent sentinel) is fully cleared.

---

## 2. Repo-root knowledge docs — CURRENT → TARGET

CURRENT (8 files): `AGENTS.md` 49 KB · `CLAUDE.md` 21 KB · `CONTEXT.md` 15 KB · `LAST-SYNC.md` 3.9 KB ·
`PITFALLS.md` 43 KB · `README.md` 1.4 KB · `STRATEGY.md` 1.4 KB · `TASKS.md` 16 KB.

| File | Disposition | Reason (cite) |
|---|---|---|
| `CLAUDE.md` (21 KB) | **KEEP, TRIM** | Process rules + NEVER list. Over the <200-line target but tier by *trigger-existence not line-count* `[map §9; _EMERGING §3]`. Safety NEVERs KEEP-VERBATIM. Two concrete cuts the enforcement-sort licenses: **delete the terminal NEVER-list *section*** once its members relocate to L1/L2 (its emphasis becomes mechanical — sort DELETE list), and **delete the behavior-principles block's duplicate** of memory.md (collapses with memory.md's death). Net: CLAUDE.md shrinks, stays the always-loaded floor (incl. the absorbed `tier: safety` PocketOS trio + the "auto-memory loses on conflict" line, memory-model §5). |
| `AGENTS.md` (49 KB) | **KEEP, SPLIT-candidate** | Largest knowledge doc; product+architecture context `[map §3a]`. Two real defects to fix in place: (1) the "Open Decisions: None open" contradiction is a **doc-fiction** the new drift CI must catch (§9) `[HARNESS-AS-IS §7]`; (2) the architecture *constraints* inside it (component-I/O-only, data-layer rules) are better delivered path-scoped via `.claude/rules/architecture.md` than as a 49 KB always-skim. Recommend: keep AGENTS.md as the product/scope narrative; *project* its hard architecture rules into `.claude/rules/` (same pattern as PITFALLS). Not a delete. |
| `PITFALLS.md` (43 KB / 558 L) | **SPLIT → DELETE-CANDIDATE** | Store S1 source. Split by its existing `**Area:**` field (**36 entries carry it, verified this session**) into the 8 `.claude/rules/*.md` shards (§5). **The monolith dies.** §9 failure prevented: the 43 KB wholesale read with the one relevant trap buried in 558 lines — *and today it is worse than the canon knew*: `/cr`'s `reviewer.md` passes the full `PITFALLS.md` to **each of 4 lens agents in parallel** (verified), so a single `/cr` pays ~172 KB of PITFALLS tokens to surface a handful of relevant traps. Path-scoping makes the relevant trap unavoidable on its path and absent (free) everywhere else `[inv S3 pathology 3; memory-model §7]`. |
| `CONTEXT.md` (15 KB) | **KEEP** | The "why" doc (PR #92) `[map §3a, §E]`. Upstream-skill coupling is real; passed to lens agents by `reviewer.md`. Keep. |
| `TASKS.md` (16 KB) | **KEEP** | Active task ledger `[map §3a]`. |
| `STRATEGY.md` (1.4 KB) | **KEEP** | Small; disk has it `[map §3a]`. |
| `LAST-SYNC.md` (3.9 KB) | **KEEP** | Notion-sync receipt; prevents silent sync omissions `[docs/solutions notion-sync-audit-receipt]`. |
| `README.md` (1.4 KB) | **KEEP** (drift-check) | Repo readme; oldest file (Mar 20) — verify not stale under drift CI `[inv B3]`. |

Repo-root **files: 8 → 7** (−1, PITFALLS dies into the shards). The bytes win is large (43 KB monolith →
~16 KB across 8 path-scoped shards that load 1–2 at a time), even though the *count* barely moves — this is
the clearest case where count understates the win.

---

## 3. The 26 skills and 23 agents — §9 survivor test applied to EVERY one

§9 rule: *"If you can't name a failure mode the constraint prevents, it's overhead."* For each survivor, one
line names the failure mode that justifies its existence. Cuts/merges are explicit.

### Skills (26 dirs → 25; one cut, three canon-documentation actions, no other cuts)

| Skill | Verdict | Failure-mode justification (survivors) / cut reason |
|---|---|---|
| `dep-update/` | **DELETE-CANDIDATE** | **Empty stub — no `SKILL.md` (verified).** Canon documents it; disk never built it `[map §3b/§6]`. An empty skill dir is a phantom-trigger surface (model may invoke a body-less skill). Overhead until built `[§9]`. Cut now; rebuild if/when dependency-update automation is actually scoped. |
| `cr/` | **KEEP** | Without the 9-pass review gate, MUST-FIX defects merge to main; it is the stop-authority producer `[enforcement-sort (b)]`. |
| `cr-security/` | **KEEP** | A security-relevant diff (auth/RLS/middleware) merges unreviewed `[R67; enforcement-sort (c)]`. |
| `compound/` | **KEEP** | The promotion conveyor + solutions writer; without it, learning never graduates from S3→S1 `[memory-model §3]`. |
| `tdd/` | **KEEP** (note upstream fork) | New pure fn ships untested; tracer-bullet-first is KEEP-VERBATIM `[map §9; R38]`. Upstream-divergence policy is a MOVE-4/5 item, not a cut. |
| `dev/` | **KEEP** (document in canon) | Real body (5.6 KB, verified), absent from canon `[map §3b/§6]`. Runs the TDD+review loop; failure prevented: ad-hoc impl skipping the test-first gate. Action is *document*, not delete. |
| `explain/` | **KEEP** (document in canon) | Real body (3.3 KB, verified), absent from canon. Teachable-explanation discipline `[memory: teachable_explanations]`; failure prevented: jargon-stacked explanations Tanner can't re-teach. Document, don't delete. |
| `feature/` | **KEEP** | Multi-commit feature ownership + the full push loop; failure: half-shipped features `[memory: pipeline_feature_ownership]`. |
| `refactor/` | **KEEP** | The plan-file + naming-gate system for safe multi-file extraction; failure: unsafe symbol moves without characterization tests `[map §9; R39]`. |
| `spike/` | **KEEP** | Owns the 6 spike-* agents; failure: deep-unknown work done without the 3-pass research + adversarial verification `[map §3d]`. |
| `debug/` | **KEEP** | Unknown-cause bug fixed by guessing; CLAUDE.md mandates it `[R56]`. |
| `migrate/` | **KEEP** | A migration ships an RLS/grant/CONCURRENTLY gotcha `[migration rules R92/R93/R125]`. |
| `supabase/` | **KEEP** (global symlink) | Supabase security checklist; symlink to `supabase/agent-skills` per `skills-lock.json` (verified) `[map §1]`. |
| `supabase-postgres-best-practices/` | **KEEP** (global symlink) | Same upstream; `skills-lock.json` tracks the hash. |
| `notion-sync/` | **KEEP** | Canonical AI-engineering record drifts from Notion `[memory: compound_evaluation_scope]`. |
| `queue/` | **KEEP** | Batch/parallel agent runs; the user's actual cadence `[memory: estimation_harness_first]`. |
| `hotfix/` | **KEEP** | Emergency path that *skips* the full pipeline safely; failure: a prod hotfix forced through the slow gate or through *no* gate `[map §3b]`. |
| `incident/` | **KEEP** | Live-incident response runbook; failure: ad-hoc incident handling. Pairs with `incident-responder` agent. |
| `post-mortem/` | **KEEP** | Incident learning never codified; failure: repeat incident. |
| `behavior-change/` | **KEEP** | Changing agent behavior without routing through settings/hooks; failure: a "from now on" request that memory can't fulfill silently dropped `[update-config skill semantics]`. |
| `evaluate-solution/` | **KEEP** | Owns `solution-evaluator` agent; failure: shipping a solution without the adversarial eval pass. |
| `perf/` | **KEEP** | Performance regressions land unmeasured; failure: LCP/round-trip regressions `[R18, R101]`. |
| `prioritize-tasks/` | **KEEP** | Task ledger churns without a priority pass; mild but nameable (TASKS.md staleness). **DEMOTE-candidate** if it duplicates `/queue` triage — flag, verify overlap before cutting. |
| `review-strategy/` | **KEEP** | STRATEGY.md drifts from reality; failure: strategy doc rot. **MERGE-candidate** with `setup-strategy` (below). |
| `setup-strategy/` | **KEEP** | Bootstraps STRATEGY.md; failure: greenfield work with no strategy frame. **MERGE-candidate**: `setup-strategy` + `review-strategy` are the same lifecycle (create vs refresh) — consider one `/strategy` skill with a mode arg. Flag, not a forced cut. |

**Skills net: 26 → 25 hard (dep-update cut).** Two soft merge-candidates flagged (`review-strategy`+
`setup-strategy`; `prioritize-tasks` vs `/queue`) — surfaced as open decisions, not executed, because each
names a *distinct* failure mode today and the merge needs a body-diff to confirm no capability is lost.
Two skills (`dev`, `explain`) need **canon documentation** (MOVE-5 convergence), not deletion.

### Agents (23 — all survive §9; the prompt's "lane-depth could be reused" hypothesis tested and rejected)

The prompt flagged lens-depth/spike agents as possible reuse-cuts. **I tested this on disk and it is wrong
— do not cut them.** Verification:

- `lens-abuse`, `lens-assumption`, `lens-cascade`, `lens-composition` — grep showed these are referenced by
  **`reviewer.md`**, which "Spawns four specialist lens agents in parallel" as `/cr` Pass 11 AND
  `/grill-with-docs` design review (verified `reviewer.md` body). They are wired, load-bearing, and each
  attacks one failure class. Cutting them guts the adversarial review. **KEEP all 4.**
- `spike-*` (6) — referenced by `spike/SKILL.md` (verified). The orchestrator dispatches researcher /
  slice / synthesis / adversarial-verifier / user-verifier. They are the spike pipeline. **KEEP all 6.**

| Agent | Verdict | Failure-mode justification |
|---|---|---|
| `reviewer` | **KEEP** | Orchestrates the 4-lens adversarial review; without it `/cr` Pass 11 + design grill have no parallel-lens engine. |
| `lens-abuse` | **KEEP** | One adversarial failure class (abuse/misuse) goes unchecked in review. Spawned by `reviewer` (verified). |
| `lens-assumption` | **KEEP** | Unstated assumptions ship unexamined. |
| `lens-cascade` | **KEEP** | Cascade/blast-radius failures missed. |
| `lens-composition` | **KEEP** | Composition/integration failures missed. |
| `implementer` | **KEEP** | Without a dedicated implement agent, planning and coding blur; the `/dev` loop needs it. |
| `reviewer` (above) | | |
| `investigator` | **KEEP** | Root-cause investigation collapses into guess-fixing `[R56]`. |
| `explorer` | **KEEP** | Codebase mapping done ad-hoc; orientation rot. |
| `doc-updater` | **KEEP** | Docs drift from code (the live failure class — phantom refs) `[R65]`. |
| `refactor-extractor` | **KEEP** | Multi-file extraction without the plan-file/naming gate → unsafe moves `[R39]`. |
| `security-reviewer` | **KEEP** | Security-relevant diffs merge unreviewed; pairs with `/cr-security` `[R67]`. |
| `solution-evaluator` | **KEEP** | Solutions ship without adversarial evaluation. |
| `spec-writer` | **KEEP** | Behavioral specs (`docs/specs/`) go unwritten; module contracts stay implicit. |
| `task-runner` | **KEEP** | `/queue` batch execution has no worker. |
| `ux-reviewer` | **KEEP** | UI ships off-design-system `[R96/R97]`. |
| `hotfix-guard` | **KEEP** | A hotfix bypasses *all* safety, not just the slow gate; the guard scopes the bypass. |
| `incident-responder` | **KEEP** | Live incident handled without the runbook. |
| `spike-orchestrator` | **KEEP** | Spike pipeline has no coordinator; dispatches the other 5 spike agents (verified). |
| `spike-researcher` | **KEEP** | Spike done without the 3-pass research. |
| `spike-slice` | **KEEP** | No tracer-bullet slice; spike has no runnable proof. |
| `spike-synthesis` | **KEEP** | Spike findings never synthesized into a decision. |
| `spike-adversarial-verifier` | **KEEP** | Spike conclusion accepted without adversarial check (the audit-rot failure class) `[_EMERGING]`. |
| `spike-user-verifier` | **KEEP** | Spike output unverified against the human's actual need. |

**Agents net: 23 → 23.** Zero cuts. This is the honest answer: the roster passes §9 cleanly because each
agent names a distinct failure mode and each is wired to a skill. Collapsing agents-into-skills is already
rejected `[MASTER-FINDINGS §F]`. The reuse-cut hypothesis was a phantom — corrected by disk grep.

---

## 4. `docs/` (excluding `v2-audit/`) — CURRENT → TARGET

CURRENT: 93 files under `docs/` (excl research). Breakdown verified: `solutions/` 34 · `adr/` 6 ·
`specs/` 3 · `design/` (incl `briefs/`, `handoff/**`) ~35 · `planning/` 6 · `agents/` 1 · plus
`ARCHITECTURE.md`, `RECURRING-FINDINGS.md`, `TESTING.md`, `exploration.md`.

| Item | Disposition | Reason (cite) |
|---|---|---|
| `docs/RECURRING-FINDINGS.md` (16 KB) | **KEEP + WIRE** (Store S3) | The airlock/inbox. Half-open loop wired shut by MOVE-6 (add task-start reader) + MOVE-1 (Stop-hook second writer) + promotion clock + decay CI `[memory-model §2 S3, §6, §9]`. Not a delete — the schema and the one real auto-writer (`/cr` 3b) are kept. |
| `docs/solutions/` (33 + README + TEMPLATE = 34) | **KEEP + WIRE** (Store S2) | Reusable patterns. Run the unmet ">10 entries → frontmatter tags" migration (now at 33, never run), add `/dev`+`/feature` task-start reader, add `status:`/`superseded-by:`, CI frontmatter assertion `[memory-model §2 S2; inv S4]`. Not a delete. |
| `docs/adr/` (5 ADRs + README) | **KEEP as long-form source, PROJECT into S1** | Cleanest store `[inv S5]`. ADRs become `.claude/rules/architecture.md` entries (`kind: decision`, decay-exempt, supersession-tracked) delivered by `paths:`; `docs/adr/` is *retained* as the Context/Decision/Alternatives/Consequences authoring home + wired into `/cr` as criteria (its one gap). One projection, generated + drift-checked, not a hand-duplicate `[memory-model §1 Open-Decision-1, §4]`. **Genuine fork** — see open decisions. |
| `docs/specs/` (2 specs + .gitkeep) | **KEEP** | Behavioral module contracts; `.gitkeep` removable now that non-empty `[inv B4]`. |
| `docs/agents/git-ops.md` | **KEEP** (merge-check) | Agent-readable git-ops contract; verify not duplicating CLAUDE.md git workflow (possible MOVE-3 merge) `[inv B4]`. |
| `docs/design/` (admin-brief, components, tokens, `briefs/`, `handoff/**`, visual-design-prompt-template) | **KEEP** | Design tokens + component patterns `[CLAUDE.md docs/design]`. `handoff/**` is bulky (~20 files incl screenshots) but is the design source-of-record; `visual-design-prompt-template.md` ties to the render-gate deferral `[MASTER-FINDINGS §C]`. KEEP; flag `handoff/` for archival review once the referenced screens ship (not in this pass). |
| `docs/ARCHITECTURE.md` (2 KB) | **KEEP** | Tech-debt ledger `[map §3a]`. |
| `docs/TESTING.md` (30 KB) | **KEEP** (path-scope candidate) | Test doc, passed to lens agents by `reviewer.md` (verified). Large; a MOVE-3 path-scoping candidate but content is load-bearing. KEEP. |
| `docs/planning/` (00–05, 6 files) | **MOVE-TO `docs/planning/archive/`** | Pre-build planning, last touched May 5, superseded by what shipped `[inv B4]`. Archive (preserve history) over hard delete; removes from the active-tree skim surface. |
| `docs/exploration.md` (17 KB) | **MOVE-TO `docs/planning/archive/`** | Frozen early exploration (May 27, untouched) `[inv B4]`. Same class as planning/. |

`docs/` (excl research) **files: 93 → ~93 in count** (planning/exploration *move* to an archive subdir,
they don't delete; one `.gitkeep` removable). The count barely moves because `docs/design/handoff/**` (the
bulk) is legitimately KEEP. **The honest read: `docs/` is not where the file-count win lives** — it is where
the *wiring* win lives (S2/S3 read-paths, ADR projection). The only count reduction is the `.gitkeep` and
the conceptual demotion of 7 files (planning+exploration) out of the active skim surface into `archive/`.

---

## 5. The NEW `.claude/rules/` shards — the only sanctioned net-new files

`.claude/rules/` is **ABSENT** (re-verified: `ls .claude/rules` → No such file). This is a **net-new build
of a NATIVE mechanism**, not a custom loader (`capability-facts.md`: "`.claude/rules/` with `paths` globs =
native path-scoped lazy-loading"). The shards are **generated projections** of the canonical constraint
corpus (ex-PITFALLS split by its `**Area:**` field — 36 entries carry it — plus ex-memory traps and the 5
ADRs as `kind: decision`). They are the delivery surface for Store S1 and the L3-tiered enforcement rules.

| Shard | `paths:` glob | What it gates (entries) | Ties to |
|---|---|---|---|
| `00-safety.md` | **(none — always loads)** | PocketOS destructive-op trio + the relocated-but-judgment NEVERs; KEEP-VERBATIM, never decays | enforcement-sort L3-1 (R77–R82, R111/R112/R114); memory-model §7 "tier by trigger-existence" |
| `migrations.md` | `supabase/migrations/**` | REVOKE-after-CREATE-FUNCTION, no-CONCURRENTLY, RLS-tenant-only, grants-inherit, DEFINER token RPCs, null-uid precondition, prefix-collision, anon-only grant, empty-array guard | enforcement-sort L1-CI migration-lint rules (R92/R93/R103/R109/R125/R127/R129/R132) — the rules CI *enforces*; the shard is the *teaching* copy at the agent's pre-write moment |
| `data-layer.md` | `src/data/**`, `app/**/actions.ts` | `cache()`-wrap, no-Supabase-from-component, public-write-RPC security, write-input Zod, no `supabaseAdmin` for public writes, no hand-written interface for external data | enforcement-sort L2 (R5/R9/R10/R11/R123/R126); these load when the dep-cruiser would also catch them — belt + suspenders at the right altitude |
| `schemas.md` | `src/schemas/**` | schema-file-folder collision, timestamptz-offset (`z.iso.datetime({offset:true})`), discriminated-payload location | enforcement-sort R27 (L1-CI), R110 (L2), R26 (L3) |
| `auth-routing.md` | `proxy.ts`, `app/**/middleware.ts`, `app/(auth)/**` | PUBLIC_PATHS-at-root, redirect-pathname-only, error.tsx-per-group | enforcement-sort R16/R17 (L1-CI), R76 (L2) |
| `harness-hooks.md` | `.claude/hooks/**`, `scripts/**`, `.claude/settings*.json` | permission-path-relative, hook-must-parse-not-grep, identical `${CLAUDE_PROJECT_DIR}` default, heredoc-commit pattern, bg-agent perm-allowlist precheck | enforcement-sort L3-1 guard-file rules (R111/R112/R114) + R71/R113; these are human-only-edit but agents *read* them when touching hook/script code |
| `git-worktree.md` | (advisory — worktree/branch ops; glob optional) | worktree-remove-when-done, post-merge-branch-persist, rebase-migration-renumber, pre-push sentinel semantics | enforcement-sort R44/R84/R85/R122; the operational sequencing rules |
| `architecture.md` | `src/**` | the 5 ADRs as `kind: decision` entries (decay-exempt, `superseded-by:` tracked) + component-I/O-only, business-logic-outside-components, rule-of-three | memory-model §1/§4 (ADR projection); enforcement-sort R7/R8/R12/R13 (L3 judgment, tiered) |

**Why exactly these 8 (not more, not fewer):** the split key is the **existing `**Area:**` field** (36
entries, verified) — so the shard boundaries are *mechanical*, not invented. `00-safety.md` does **not**
shard and has no `paths:` because safety applies everywhere and loads always regardless of length
(`_EMERGING §3`; KEEP-VERBATIM FLOOR). Generation is `scripts/gen-rules.sh` in CI (Open Decision 4, lean
script — "boring & deterministic is a feature"); the drift CI (§9) asserts shard ↔ canonical-source
consistency so the projection never drifts.

**8 NEW files. This is the entire sanctioned net-new knowledge-file addition.**

---

## 6. The `.claude/` clutter — explicit per-item resolution (requirement 4)

Every clutter item the prompt named, resolved:

| Clutter item | Resolution | One-line reason |
|---|---|---|
| `TASK-TEMPLATE.md` (29 KB) | **DELETE-CANDIDATE** | `enforce-scope.sh` (its reader) ABSENT → payload inert; scope discipline covered elsewhere `[§9]` |
| `grill-progress-change-quote-request.md` (14 KB) | **DELETE-CANDIDATE** | Spent per-task checkpoint, header marked FINAL `[inv B1]` |
| `walkthrough-item-form-refactor.md` (2.2 KB) | **DELETE-CANDIDATE** | Spent generated walkthrough; regenerable `[§9]` |
| `walkthrough-item-form-type-boundary.md` (1.3 KB) | **DELETE-CANDIDATE** | Same class `[§9]` |
| `walkthrough-public-write-rpc-pattern.md` (513 B) | **DELETE-CANDIDATE** | "docs-only — no new behaviors"; empty of signal `[§9]` |
| `diff-review.md` (3 KB) | **KEEP** (fold into `/cr`) | KEEP-VERBATIM human-QA checkpoint `[map §9]` |
| `questions.md` (1 KB) | **DELETE-CANDIDATE** | Stale per-task scratch `[inv B1]` |
| `notes/` (empty dir) | **DELETE-CANDIDATE** | Empty; no reader/writer `[§9]` |
| `.cr-ok` / `.cr-ok.consumed` | **DELETE `.consumed`; KEEP `.cr-ok` local but DEMOTE** | Stop authority relocated to **CI/branch-protection** (enforcement-sort (b)); on-disk sentinel is no longer the gate. gitignore `.cr-ok*`. |
| `worktrees/` (7 stale) | **DELETE-CANDIDATE (NEEDS-HUMAN)** | Largest clutter mass; each a full repo copy carrying stale store copies. Mutating op → surface `gh pr view`-then-`git worktree remove` batch for Tanner; do not auto-run `[inv B5; destructive-op rules]` |

Worktree batch (surface, do not execute — confirm each PR-merged first via `gh pr view`):
`agent-a6813310af434d2f8`, `agent-ad8568a0f745ede00`, `agent-aee117b9c13294167 (feat/crud-cascade-review)`,
`tasks-md-update (chore/...complete)`, `tier-0-local-env (#99/#100 shipped per memory)` →
likely-removable; `feat-proposal-transitions-atomic-rpc` and `spike-wave-1` → **confirm not active first**
(spike has "6/6 green, do not push/merge" per auto-memory).

---

## 7. PLUGIN-vs-PROJECT-OWNED split (requirement 6 — mark, don't fully design; Phase 4 owns distribution)

The harness is meant to be global/multi-project but lives only in event-vendor today. The split that makes
that possible: **portable mechanism → plugin/marketplace; project-specific knowledge → stays in the repo.**

| File / dir | Owner | Why |
|---|---|---|
| `.claude/skills/**` (25, minus the 2 supabase global symlinks) | **PLUGIN** | Skills are portable procedures; ship in the marketplace plugin. The 2 supabase skills already come from an upstream marketplace (`skills-lock.json`) — keep that source. |
| `.claude/agents/**` (23) | **PLUGIN** | Agent definitions are portable roles, project-agnostic. |
| `.claude/hooks/**` (5 + 2 new) | **PLUGIN** (with project config) | Hook *scripts* are portable; the *allowlists/paths* they read are project config. Ship the scripts; the project supplies `settings.json` patterns. |
| `.claude/rules/**` (8 NEW shards) | **SPLIT** | `00-safety.md` (PocketOS floor) is **PLUGIN** (universal). The area shards (`migrations.md`, `data-layer.md`, …) are **PROJECT-OWNED** — their traps and `paths:` globs are this codebase's (Next/Supabase) shape. A new project gets the safety floor free and authors its own area shards. |
| `.claude/SOUL.md`, `agent-contract.md`, `rituals.md`, `AI-WORKFLOW.md`, `INDEX.md`, `diff-review.md` | **PLUGIN** (templates) | Portable agent-discipline docs; ship as plugin defaults, project may override. |
| `.claude/mcp.md` | **PROJECT-OWNED** | The allowlist + "Playwright rejected" decision is this project's. |
| `.claude/settings.json` / `settings.local.json` / `managed-settings.json` | **PROJECT-OWNED** (guard files) | Permissions, env, autoMode are per-project + per-machine; never plugin-shipped; human-only edit. |
| `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `TASKS.md`, `STRATEGY.md`, `LAST-SYNC.md`, `README.md` | **PROJECT-OWNED** | Product/scope/process narrative — irreducibly this project's. |
| `docs/**` (solutions, adr, specs, design, RECURRING-FINDINGS, TESTING, ARCHITECTURE) | **PROJECT-OWNED** | Captured knowledge about *this* codebase. The README/TEMPLATE *shapes* could ship as plugin scaffolds; the *content* stays. |
| `scripts/**` (gc, pr, worktree-add, test-local, gen-local-env, seed, + new gen-rules, scan-context, migration-lint) | **SPLIT** | Generic workflow scripts (gc, pr, worktree-add, gen-rules, scan-context) → **PLUGIN**; project-specific (seed, test-local env-wiring, migration-lint ruleset) → **PROJECT-OWNED**. |

Mark only — Phase 4 designs the actual marketplace packaging, the override/merge precedence, and the
distribution sequence (`canon-locked-decisions.md` already locks that sequence).

---

## 8. CURRENT → TARGET tree (consolidated view)

```
                                  CURRENT                         TARGET
.claude/  (top-level files)       17                       →     9            (−8 clutter/merge)
  rules/                          ABSENT                   →     8 shards      (+8 NEW, sanctioned)
  skills/                         26 dirs (1 empty)        →     25            (−1 dep-update)
  agents/                         23                       →     23            (0 — all pass §9)
  hooks/                          5                        →     7            (+2: capture, dangerous-bash)
  worktrees/                      7 (stale)                →     0–2          (NEEDS-HUMAN removal)
  notes/                          1 empty dir              →     gone

repo-root *.md                    8                        →     7            (−1: PITFALLS → shards)

docs/ (excl research)             93                       →     93           (planning+exploration MOVE
                                                                               to archive/; .gitkeep gone)
  RECURRING-FINDINGS.md           KEEP+WIRE (S3)
  solutions/ (34)                 KEEP+WIRE (S2)
  adr/ (6)                        KEEP source + PROJECT into S1
  planning/ (6) + exploration.md  MOVE → planning/archive/

scripts/                          8                        →     11           (+3: gen-rules, scan-context,
                                                                               migration-lint — mechanisms)
```

---

## 9. The mechanism delta (NOT knowledge files — counted separately, honestly)

The enforcement-sort names **7 build items** that absorb ~64 of 118 rules. These are *mechanisms*, not
knowledge files — I count them apart so the knowledge-file math stays clean:

- **NEW hooks (+2):** `block-dangerous-bash.sh` (PreToolUse exit-2; absorbs R77 + bash-half of
  R72/R73/R81 + guard-file/egress), `session-end-capture.sh` (Stop/SubagentStop; the MOVE-1 writer landing
  in S3 — fixes #70's "output went nowhere").
- **NEW CI scripts (+3):** `scan-context.sh` (the drift/decay detector — replaces the phantom
  `/scan-context` ritual; STALE+FICTION+DECAY in one CI pass), `migration-lint` (8 safety-critical migration
  rules in one script), `repo-structure` (file-pairing + layout checks). Plus `gen-rules.sh` (regenerates
  the §5 shards).
- **NEW dev-dependency (ASK FIRST):** `dependency-cruiser` for the L2 arch-test layer (R5/R9/R10/R11/etc.).
- **Placement fix (no new file):** autoMode → `settings.local.json`/`managed-settings.json` (human handoff).
- **Branch-protection (repo setting, no file):** the relocated `.cr-ok` stop authority.

**Net mechanism delta: +2 hooks, +4 CI/gen scripts, +1 dev-dep, +1 dir of generated shards.** Every one
absorbs multiple advisory rules — this is the "fewer files, more wiring" shape. The hooks/scripts are
mechanisms that *delete prose* (the enforcement-sort moves ~64 rules from advisory L3 to deterministic
L1/L2/CI), which is the real consolidation even though it adds executable files.

---

## 10. FILE COUNT — before vs after, and the honest reconciliation

**Knowledge files (the census scope — `.claude/` non-mechanism + repo-root *.md + `docs/` non-research):**

| Zone | BEFORE | AFTER | Δ |
|---|---|---|---|
| `.claude/` top-level files | 17 | 9 | **−8** |
| `.claude/rules/` shards | 0 | 8 | **+8** (NEW, sanctioned) |
| `.claude/skills/` (dirs w/ body) | 23 (26 dirs, 3 = symlink/empty) | 22 + 2 symlink = 24 dirs | **−1** (dep-update) |
| `.claude/agents/` | 23 | 23 | 0 |
| repo-root *.md | 8 | 7 | **−1** (PITFALLS) |
| `docs/` (excl research) | 93 | 93 | 0 (planning/exploration *moved* to archive/, not deleted; −1 `.gitkeep`) |

**Knowledge-file net: roughly −10 (clutter + memory.md + PITFALLS + dep-update + .gitkeep) and +8 (shards)
= net ≈ −2 to −3 knowledge files.** Adding the **2 new hooks + 4 new CI/gen scripts** as mechanisms, the
*total tracked file* count is approximately **flat to slightly up** (−10 knowledge, +8 shards, +6
mechanism scripts).

**Does this tree reduce file count? Knowledge files: yes, slightly (≈−2 to −3). Total tracked files
including new mechanisms: roughly flat.** I will not pretend otherwise. Here is why it is still the right
tree — three load-bearing wins the count does not show:

1. **Duplication collapse (the real prize).** Today the same corrected-mistake fact lives in **three
   files** — `.claude/memory.md` + `PITFALLS.md` + an auto-memory `feedback_*` file — sanctioned-and-
   forbidden by the canon simultaneously `[inv S1/S3/S6]`. After: it lives in **exactly one canonical
   place** (`.claude/rules/<area>.md`), with the auto-memory copy explicitly demoted to an untrusted cache
   and the duplication collapse enforced by *there being only one place to write a constraint* (the S3→S1
   promotion gate), not by a prose note. Count-of-files doesn't move much; count-of-*copies-of-each-fact*
   drops from 3 to 1. **That is the metric that matters and the count metric hides it.**

2. **Token-cost collapse on every code task.** `PITFALLS.md` is 43 KB read wholesale today — and worse,
   `/cr`'s `reviewer.md` passes it to **4 lens agents in parallel** (verified this session), ~172 KB per
   review. After: a ~2 KB path-scoped `.claude/rules/<area>.md` load via native `paths:` globs. One file
   became eight, but each task loads 1–2 of them instead of all 558 lines. **Eight smaller files that load
   selectively beat one monolith that loads always** — this is the case where "fewer files" is the *wrong*
   target and "less loaded context" is the right one.

3. **Every store gains a tool-driven exit.** Today decay is documented for 3 of 6 stores and *executed for
   none* `[inv cross-store synthesis]`. After: the drift CI (one deterministic pass) gives S1/S2/S3 a clock
   (180d/365d/30d) and the phantom-ref detector catches the live failure class (the audit itself rotted).
   No store grows monotonically. **A file that can shrink itself is worth more than a file that can't, at
   the same count.**

**The biggest raw cuts, in order of bytes:** (1) 7 stale worktrees (each a full repo copy — by far the
largest mass, NEEDS-HUMAN removal); (2) `TASK-TEMPLATE.md` (29 KB inert) + `grill-progress` (14 KB) + 3
walkthroughs + `questions.md` (≈48 KB of spent `.claude/` scratch); (3) `PITFALLS.md` 43 KB monolith → 8
path-scoped shards (~16 KB total, loaded 1–2 at a time); (4) `.claude/memory.md` 10 KB (merged away, zero
fact loss); (5) `docs/planning/` + `exploration.md` (≈157 KB) archived out of the active skim surface.

**Net mechanism delta:** +2 hooks, +4 CI/gen scripts, +1 dev-dep, +1 generated `rules/` dir, −1 empty
skill, −1 empty dir, ~−11 spent/merged knowledge files, 7 worktrees → human-gated removal. **The harness
ends with FEWER knowledge files and FEWER copies-of-each-fact, MORE deterministic enforcement, and one
canonical home per constraint** — which is the consolidation the binding principle asks for, even though a
naive `find | wc -l` understates it because the 8 sanctioned shards and 6 new mechanism scripts partly
offset the deletions on paper.

---

## 11. Genuine open decisions (forks left for Tanner)

1. **ADR: project-into-S1 with retained `docs/adr/` long-form, OR delete `docs/adr/` and flatten to S1
   entries, OR keep it as a distinct 4th owned store?** Recommendation: project into S1 as `kind: decision`
   AND retain `docs/adr/` as the authoring home (the §4 model). This is the single biggest fork and is
   inherited from memory-model Open Decision 1.
2. **Soft skill merges:** fold `setup-strategy` + `review-strategy` into one `/strategy` skill (mode arg)?
   And does `prioritize-tasks` duplicate `/queue` triage enough to merge? Each names a distinct failure mode
   today — recommend a body-diff before cutting, not a blind merge.
3. **`docs/design/handoff/**` (≈20 files incl screenshots):** KEEP as design source-of-record now;
   archive after the referenced screens ship? Flagged, not resolved — it's the second-largest `docs/` mass.
4. **Worktree removal batch:** which of the 7 are safe to remove? `feat-proposal-transitions-atomic-rpc`
   and `spike-wave-1` need active-state confirmation before removal (NEEDS-HUMAN, mutating op).
5. **Shard generation:** `scripts/gen-rules.sh` in CI (recommended, deterministic) vs a `/compound` step?
   Inherited from memory-model Open Decision 4; lean script.
```
