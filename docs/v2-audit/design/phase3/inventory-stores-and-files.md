# Phase 3 — Store & File Census (ground-truthed on disk 2026-06-11)

**What this is.** Two inventories, both verified by opening actual files (not inherited from rotted audit
artifacts). Part A is the memory-store census (the MOVE 3 substrate — `[map §4]`). Part B is the full
file/dir census of `.claude/`, repo-root `*.md`, and `docs/`, with a KEEP / MERGE / DELETE / MOVE
disposition per item, each citing the §9 deletion criterion ("name a failure mode the constraint prevents,
or it's overhead") or a map row.

**Governing rule honored.** Every disposition cites a current-state component (`[map §N]`, a disk path, or
a re-verified absence). Nothing here proposes building something that already exists (anti-phantom is
MASTER-FINDINGS §E). Re-verification was done on disk this session where any claim was load-bearing.

**Headline numbers.** **6 memory stores** (3 with a freshness rule, 0 with a single coherent
writer/reader/freshness contract encoded in tooling). **23 delete-candidate items** in the file census
(20 hard DELETE-CANDIDATE + 3 MERGE/MOVE that empty a path). Stale worktrees are the single largest
clutter mass.

---

# PART A — MEMORY STORES (as-BUILT, ground-truthed)

The canon's model names 5 stores; disk runs 6 (auto-memory is the canon-invisible 6th, `[map §4]`,
`[map §6]`). For each: **writer** (who/what, manual vs automated) · **reader** (who/what + WHEN) ·
**freshness rule** · **pathologies**. Quotes are from the actual file headers read this session.

## Store 1 — `.claude/memory.md` (166 lines, 10 KB)

- **Writer:** MANUAL, human-or-agent at session end. Header quote: *"When a mistake is corrected during a
  session, add a rule here before the session ends."* No hook writes it — `session-end.sh` is ABSENT
  (deliberately removed in #70; its output was discarded). So the documented write trigger has **no
  enforcement and no automation** behind it. `[map §3e session-end ABSENT]`, `[map §5]`.
- **Reader:** Loaded by INSTRUCTION at session start. Header quote: *"Read this at the start of every
  session."* CLAUDE.md session-start ritual repeats it. There is no hook that injects it — it depends on
  the model honoring a prose instruction. The disk `session-start.sh` exists but does a remote npm install,
  not a memory read `[map §3e]`.
- **Freshness rule:** Per-entry `last_seen: YYYY-MM-DD`; canon prescribes a 90-day staleness review in
  `/compound` Step 7 (`[map §4]`). Of 11 substantive entries read, last_seen spans 2026-05-08 → 2026-05-22
  — i.e. **no entry has been touched in ~3 weeks**, and several are already past or near the 90-day window
  with no decay actually applied (the rule is documented, the sweep is manual and unrun).
- **Content shape:** 11 rules. The top 3 are the PocketOS destructive-op trio (`destructive-operation-
  hard-stop`, `token-scope-assumption`, `staging-is-not-isolated`) — these are KEEP-VERBATIM safety floor.
  The rest are process/behavior rules (`honest-assessment-not-validation`, `build-what-is-needed-now`,
  `research-before-guessing`) that **also live verbatim in CLAUDE.md → Agent behavior principles**.
- **Pathologies:**
  1. **Behavior-rule duplication with CLAUDE.md.** `honest-assessment-not-validation`, `build-what-is-
     needed-now`, `research-before-guessing` are near-verbatim copies of CLAUDE.md's standing principles.
     The auto-memory feedback_* files (Store 6) carry the *same* facts a third time. This is the
     triple-duplication the canon "both sanctions and forbids" `[map §4]`.
  2. **No automated writer** — the entire "compounding write-back" half is a prose instruction. MOVE 1's
     session-end emitter is the missing writer.
  3. **Dual-layer assignment** — memory.md is assigned to BOTH Layer 1 (Context) and Layer 3 (Memory)
     depending on canon page `[map §4]`. Unresolved.
  4. **Decay documented, not executed** — last_seen exists; the 90-day sweep is a manual `/compound` step
     that has visibly not run (dates are stale).

## Store 2 — `docs/RECURRING-FINDINGS.md` (16 KB)

- **Writer:** AUTOMATED-ish — appended/incremented by `/cr` Step 3b. Header quote: *"The pipeline
  synthesis step appends or increments entries automatically. Entries are matched on the `signature`
  field."* This is the **one store with a real automated writer on disk**.
- **Reader:** `/cr` itself (to increment counts + flag promotion candidates) and `PITFALLS.md` (promotion
  source). **Verified this session:** the ONLY non-worktree files that reference it are
  `.claude/skills/cr/SKILL.md` and `PITFALLS.md`. (The 21 worktree hits are stale copies of those same two
  files.) **No implementer, no task-start context, no other skill reads it.** Header quote confirms the
  intent: *"a finding moves to PITFALLS.md … once it has recurred enough."*
- **Freshness rule:** Occurrence cap-at-5 on `Example locations` ("cap at 5, drop oldest when full"); status
  field (`active | promoted-to-pitfalls | promoted-to-pass | retired`). No time-decay.
- **Pathologies:**
  1. **The half-open loop** `[map §4]`, `[MASTER-FINDINGS §B MOVE 6]`. It is written by the pipeline and
     read only by the pipeline. A finding logged here is invisible at the moment an implementer is about to
     repeat it. The read-path into task-start context does not exist — this is the structural core of
     MOVE 6.
  2. **Promotion is manual + lossy.** "Human confirms before promotion." In practice entries sit `active`
     for weeks (e.g. `multi-line-comment-in-test`, occurrences 1, still active 3 weeks on). Promotion is a
     judgment gate with no clock.
  3. **Overlaps PITFALLS by design** — a promoted finding lives in both until someone retires the source.

## Store 3 — `PITFALLS.md` (558 lines, 43 KB, repo root)

- **Writer:** MANUAL — promoted from RECURRING-FINDINGS (≥3 occurrences or judgment) OR added directly.
  Header quote: *"Entries are added either: Promoted from docs/RECURRING-FINDINGS.md once recurrent enough,
  or Added directly when a known trap is identified outside the review loop."*
- **Reader:** By INSTRUCTION, area-scoped. CLAUDE.md: *"MUST read `PITFALLS.md` before writing in any
  affected area."* Header quote: *"Read this before writing or modifying code in any affected area."* This
  is the most-honored knowledge read on disk, but it is **43 KB read wholesale** — there is no path-scoping,
  so the model must load all 558 lines to find the 1 trap relevant to its file (the native `.claude/rules/`
  + `paths:` glob mechanism that would fix this is ABSENT — MOVE 3 net-new).
- **Freshness rule:** Changelog-driven (`[map §4]`); no per-entry decay.
- **Pathologies:**
  1. **Triple-duplication** — the same corrected-mistake facts live here AND in memory.md AND in
     auto-memory feedback_* (e.g. the permission-path-is-project-relative trap, the TTY-detection rule,
     the enforcement-boundary-layering rule all appear in ≥2 of the 3 stores). `/compound` itself flags
     memory entries as "already covered by PITFALLS (redundant)" `[map §4]`.
  2. **Dual-layer assignment** — like memory.md, assigned to BOTH Layer 1 and Layer 3 `[map §4]`.
  3. **Monolithic read** — 43 KB with no glob-gating; every code task pays the full token cost.

## Store 4 — `docs/solutions/` (33 dated files + README + TEMPLATE)

- **Writer:** MANUAL — `/compound` after a merged feature. README quote: *"After any feature that introduced
  a non-obvious pattern … Run /compound after the feature is merged."*
- **Reader:** MANUAL grep, by the human/agent who remembers to look. README ships the read-path as shell
  snippets: *"grep -r 'tags:.*[your-tag]' docs/solutions/"*. **No skill auto-loads it at task start.**
  Verified: only `notion-sync`, `compound`, `feature`, `tdd`, `debug` SKILL.md reference `docs/solutions`
  at all — and those reference it as a *write* target or cross-link, not a task-start read.
- **Freshness rule:** NONE (positive patterns are assumed durable). README has a latent scaling rule:
  *"Add YAML frontmatter tags when this directory exceeds ~10 entries"* — it is now at 33 entries and the
  tag-on-frontmatter migration has **not** happened, so the documented grep-by-tag read-path partially
  fails (tags are inconsistent).
- **Pathologies:**
  1. **No read-path into work** — same half-open shape as RECURRING-FINDINGS, milder (positive patterns
     are less time-sensitive). A solution doc is found only if the worker greps for it.
  2. **Index drift** — README's manual index table must be hand-maintained per file; at 33 entries this is
     a doc-drift surface (a phantom-reference vector — our live failure class, `[map §0]`).
  3. **Unmet self-rule** (the >10-entry frontmatter migration) — a documented constraint with no
     enforcement; §9 says an unenforced constraint is overhead until relocated or deleted.

## Store 5 — `docs/adr/` (5 ADRs + README)

- **Writer:** MANUAL — written when a decision is "hard to reverse, surprising without context, and the
  result of a real tradeoff" (README quote: *"If any of the three is missing, skip the ADR."*).
- **Reader:** By INSTRUCTION at design time. CLAUDE.md: *"MUST skim `docs/adr/README.md` — know what
  architectural decisions are locked before designing anything."* This is honored at design start only.
- **Freshness rule:** Status field (`Accepted | Superseded by NNNN | Deprecated`) — supersession, not decay.
  This is the **cleanest store**: one writer, a real read trigger, a coherent lifecycle.
- **Pathologies:** Minimal. The only gap is that the corpus of locked decisions is **not wired into `/cr`
  as review criteria** (MOVE 6's read-path point) — an ADR can be silently violated by a diff and `/cr`
  won't catch it because it doesn't load the ADRs as constraints. Otherwise this store is the model the
  other five should converge toward.

## Store 6 — Auto-memory (`MEMORY.md` index + 51 siblings) — the canon-invisible 6th store

Path: `/Users/tanner/.claude/projects/-Users-tanner-Dev-event-vendor/memory/`. Verified composition this
session: **52 files** = `MEMORY.md` (index) + **32 `feedback_*`** + **15 `project_*`** + **3 `reference_*`**
+ **1 `user_*`**.

- **Writer:** AUTOMATED, by the **Claude Code memory SUBSYSTEM** — not any skill, not any hook, not in the
  canon `[map §4]`, `[map §6]`. This is the only store with a fully automated writer that runs without the
  harness asking. The harness does not control it and cannot see its write cadence.
- **Reader:** AUTOMATED at session start — first **200 lines / 25 KB** of `MEMORY.md` auto-loaded
  (capability-facts.md). Beyond that requires an explicit read. The index read this session carries a
  staleness banner: *"This memory is 5 days old. Memories are point-in-time observations … Verify against
  current code before asserting as fact."*
- **Freshness rule:** The subsystem stamps age and warns (the 5-day banner) but does **not decay or evict**.
  Entries like `project_test_gaps_nh7.md` ("All 3 gaps closed; PRs #32/33/34 open, pending merge") are
  factually stale (those PRs long since resolved) yet still loaded.
- **Pathologies:**
  1. **Not modeled in canon at all** `[map §4, §6]` — the V2 memory model must account for a store it
     does not own and cannot write to.
  2. **Triple-duplication, third copy.** The 32 `feedback_*` files are the same corrected-mistake class as
     memory.md + PITFALLS. Examples confirmed in the index: `feedback_tty_detection`, `feedback_sentinel_*`,
     `feedback_no_env_credential_reuse`, `feedback_background_agent_bash_permissions` — each has a twin in
     memory.md and/or PITFALLS.
  3. **No eviction → monotonic growth** collides with §9 decay doctrine. 52 files and climbing, auto-loaded
     up to the 25 KB cap, with stale entries inside the cap displacing fresher signal.
  4. **Authority confusion** — because it auto-loads first, its (sometimes stale) facts arrive *before*
     the manually-curated memory.md/PITFALLS. The freshest-looking store is the least curated.

## Cross-store synthesis (the MOVE 3 problem stated precisely)

| Store | Writer | Reader (WHEN) | Freshness | Worst pathology |
|---|---|---|---|---|
| 1 memory.md | manual (session end) | instruction (session start) | 90-day last_seen, unrun | dup w/ CLAUDE.md + Store 6; no auto-writer; dual-layer |
| 2 RECURRING-FINDINGS | **auto (`/cr` 3b)** | `/cr` only | cap-at-5 | **half-open: never read by implementers** |
| 3 PITFALLS | manual (promotion/direct) | instruction (area-scoped) | changelog | triple-dup; 43 KB monolithic read; dual-layer |
| 4 solutions | manual (`/compound`) | manual grep | none (unmet tag rule) | no task-start read-path; index drift |
| 5 adr | manual (judgment) | instruction (design start) | supersession | **cleanest** — only gap: not wired into `/cr` |
| 6 auto-memory | **auto (CC subsystem)** | **auto (session start, 25 KB)** | age-stamp, **no decay** | canon-invisible; no eviction; stale-first authority |

**Three facts MOVE 3 must resolve:**
1. **Two automated writers exist (Stores 2, 6), zero automated writers feed the curated stores (1, 3, 4).**
   The compounding write-back is structurally absent where it matters and present where it isn't governed.
2. **Two automated readers exist (Store 6 session-start, Store 2 by `/cr`); the curated knowledge
   (1, 3, 4, 5) is read only by instruction or manual grep.** The read-path into work is the MOVE 6 gap.
3. **Freshness exists for 3 of 6 (1, 2, 6) and decay is actually executed for none.** The dual-layer
   assignment (PITFALLS + memory.md in both L1 and L3) is the labeling ambiguity to collapse.

The canon's reconciliation ("same knowledge at different lifecycle stages") **exists only in prose,
encoded in no tooling** `[map §4]`. ADR (Store 5) is the existence proof that one-writer / one-read-trigger
/ one-lifecycle is achievable in this repo — it is the convergence target, not a new invention.

---

# PART B — FILE CENSUS

Disposition legend: **KEEP** · **MERGE-INTO-<target>** · **DELETE-CANDIDATE** · **MOVE-TO-<target>**.
Each row cites the §9 criterion (name the failure mode prevented, else overhead) or a map row.
"DELETE-CANDIDATE" = recommend deletion pending human confirm (CLAUDE.md forbids silent deletion);
it is a flag, not an action. Delete-candidate tally is at the end.

## B1 — `.claude/` top level

| Item | Size | Disposition | Reason (§9 failure-mode or map cite) |
|---|---|---|---|
| `.cr-ok.consumed` | 58 B | **DELETE-CANDIDATE** | Spent sentinel receipt (`chore/notion-sync:9d69e45…`). Prevents no failure mode; it is the *consumed* artifact of a past run. Overhead. Add `.cr-ok*` to `.gitignore` so it never recurs. |
| `notes/` (empty dir) | 0 | **DELETE-CANDIDATE** | Empty directory, no writer/reader on disk. Pure overhead `[§9]`. |
| `TASK-TEMPLATE.md` | 29 KB | **MERGE-INTO-`docs/specs/` or DELETE-CANDIDATE** | 29 KB task template. Its enforcement counterpart `enforce-scope.sh` (which reads `## ALLOWED FILES` from it) is ABSENT `[map §3e, §5]` — so the template's structural payload is inert today. Failure mode it *would* prevent (scope creep) is real but currently unenforced. Decision: keep ONLY if MOVE 2 builds `enforce-scope.sh`; otherwise it is a 29 KB advisory doc duplicating CLAUDE.md's "Before writing code" gate. Flag for the MOVE-2 fork. |
| `grill-progress-change-quote-request.md` | 14 KB | **DELETE-CANDIDATE** | Per-task progress checkpoint, header marked *"FINAL — pre-implementation pipeline complete; user takes #86 manually next."* It is a spent work-artifact for one closed task. Belongs in the worktree/PR that produced it, not the harness root. Overhead `[§9]`. |
| `walkthrough-item-form-refactor.md` | 2.2 KB | **DELETE-CANDIDATE** | Generated QA walkthrough for one past refactor. Spent artifact; regenerable. Overhead `[§9]`. |
| `walkthrough-item-form-type-boundary.md` | 1.3 KB | **DELETE-CANDIDATE** | Same class — spent generated walkthrough. Overhead `[§9]`. |
| `walkthrough-public-write-rpc-pattern.md` | 513 B | **DELETE-CANDIDATE** | Header: *"docs-only branch — no new confirmed behaviors."* Empty-of-signal walkthrough. Overhead `[§9]`. |
| `diff-review.md` | 3 KB | **KEEP** (or MERGE-INTO `/cr` keep-verbatim) | "What only a human can catch before merging to main" — this is the **manual-QA coverage blocker / human semantic checkpoint**, KEEP-VERBATIM floor `[map §9]`, `[MASTER-FINDINGS MOVE 1 constraint]`. Names a real failure mode (regression-trust ≠ correctness-trust). Keep; consider folding into `/cr`'s human-checkpoint section so it travels. |
| `questions.md` | 1 KB | **DELETE-CANDIDATE** | Single stale NON-BLOCKING assumption about migration `0062` and a worktree with no psql. Spent per-task scratch. Overhead `[§9]`. |
| `mcp.md` | 7 KB | **KEEP** | Canonical MCP registry + allowlist + "Playwright explicitly rejected" decision `[MASTER-FINDINGS §E]`. Prevents the failure mode of re-litigating rejected MCP servers. Keep. |
| `memory.md` | 10 KB | **KEEP** (MOVE-3 subject) | Store 1. Safety-floor content is KEEP-VERBATIM `[map §9]`; the behavior-rule duplication is a MOVE 3 collapse, not a delete. |
| `rituals.md` | 2 KB | **KEEP** | Ritual layer exists; gap is the missing clock not the layer `[MASTER-FINDINGS §E]`. Keep. |
| `settings.json` | 7 KB | **KEEP** | Guard file. No agent edits `[memory: no_agent_edits_guard_files]`. autoMode *placement* is a MOVE 2 issue (block ignored at runtime, capability-facts.md), not a delete. |
| `settings.local.json` | 4 KB | **KEEP** | Guard file (gitignored personal settings). Correct home for autoMode per MOVE 2. Keep. |
| `SOUL.md` | 3.5 KB | **KEEP** | Values doc `[map §3a]`. Keep. |
| `agent-contract.md` | 5.5 KB | **KEEP** | Sub-agent contract `[map §3a]`. Keep. |
| `INDEX.md` | 3.5 KB | **KEEP** | External-resources index `[map §3a]`. Keep (verify no phantom refs — drift vector). |
| `AI-WORKFLOW.md` | 7 KB | **KEEP** | Workflow doc `[map §3a]`. Keep; candidate to merge with CLAUDE.md workflow section in MOVE 3 if duplicative. |
| `hooks/` (5 hooks) | dir | **KEEP** | All 5 live hooks named in `[map §3e]`. Keep; MOVE 1/2 ADD to this dir (one Stop surface + `block-dangerous-bash.sh`), do not subtract. |
| `agents/` (23) | dir | **KEEP** | Roster `[map §3d]`; collapse-to-skills is rejected `[MASTER-FINDINGS §F]`. MOVE 4 may prune individuals but the dir stays. |
| `skills/` (26 dirs) | dir | **KEEP** | Skill registry `[map §3b]`. One member is a delete-candidate (see B2). |
| `worktrees/` (7 dirs) | dir | **see B5** | Stale worktrees are the largest clutter mass — handled in B5. |

## B2 — `.claude/skills/` notable members (the 26 dirs are KEEP except)

| Skill | Disposition | Reason |
|---|---|---|
| `dep-update/` | **DELETE-CANDIDATE** | Verified EMPTY (no SKILL.md). Canon documents it fully; disk never built it `[map §3b, §6]`. An empty skill dir is a phantom-trigger surface (the model may try to invoke a skill with no body). Either build it or delete the stub. Overhead until built `[§9]`. |
| `dev/`, `explain/` | **KEEP** (document) | Real on disk (5.6 KB / 3.3 KB SKILL.md, verified), absent from canon `[map §3b, §6]`. Disposition is *document-in-canon during MOVE 5 convergence*, not delete. |
| `supabase-postgres-best-practices/` | **KEEP** | Symlink to global; shared `[map §1]`. Keep. |
| `tdd/` | **KEEP** (note fork) | Project-local fork diverged from global Matt-Pocock `[map §1]`; upstream-dependency policy is a MOVE 4/5 item `[MASTER-FINDINGS §D]`. Tracer-bullet-first is KEEP-VERBATIM `[map §9]`. |
| other 22 | **KEEP** | All aligned canon↔disk `[map §3b]`. |

## B3 — Repo-root `*.md`

| File | Size | Disposition | Reason |
|---|---|---|---|
| `CLAUDE.md` | 21 KB / 326 L | **KEEP** (MOVE-3/4 trim subject) | Process rules + NEVER list. Over the <200-line target (capability-facts.md) but tier by *trigger-existence not line-count* `[map §9]`. Safety NEVERs are KEEP-VERBATIM; phrase-keyed/unobserved rules are MOVE 4 cut candidates. The behavior-principles block duplicates memory.md (MOVE 3 collapse). |
| `AGENTS.md` | 49 KB / 475 L | **KEEP** (MOVE-3 split candidate) | Largest knowledge doc; product+architecture context `[map §3a]`. Carries the "None open" Open-Decisions contradiction `[map §3a, HARNESS-AS-IS §7]` — a doc-fiction (live failure class). Candidate for `.claude/rules/` path-scoped splitting in MOVE 3. Not a delete. |
| `PITFALLS.md` | 43 KB / 558 L | **KEEP** (MOVE-3 subject) | Store 3. Path-scope via native `.claude/rules/` is the MOVE 3 fix; content stays. |
| `CONTEXT.md` | 15 KB | **KEEP** | PR #92, the "why" doc `[map §3a, §E]`. Upstream-skill coupling is real `[map §1]`. Keep. |
| `TASKS.md` | 16 KB | **KEEP** | Active task ledger `[map §3a]`. Keep. |
| `STRATEGY.md` | 1.4 KB | **KEEP** | Disk has it; canon documents only the template `[map §3a]`. Small; keep. |
| `LAST-SYNC.md` | 3.9 KB | **KEEP** | Notion-sync audit receipt `[docs/solutions 2026-05-27-notion-sync-audit-receipt]`. Prevents silent sync omissions. Keep. |
| `README.md` | 1.4 KB | **KEEP** | Repo readme (oldest file, Mar 20). Keep; verify it isn't stale (drift check). |

## B4 — `docs/` (excluding the v2-audit research tree, which is this effort's own scratch)

| Item | Disposition | Reason |
|---|---|---|
| `docs/RECURRING-FINDINGS.md` | **KEEP** (MOVE-6 subject) | Store 2; the half-open loop is wired shut by MOVE 6, not deleted. |
| `docs/solutions/` (33+README+TEMPLATE) | **KEEP** (MOVE-3/6 subject) | Store 4; needs the unmet tag migration + a read-path. Not a delete. |
| `docs/adr/` (5+README) | **KEEP** | Store 5; the convergence-target model. Wire into `/cr` (MOVE 6). |
| `docs/ARCHITECTURE.md` | 2 KB | **KEEP** | Tech-debt ledger `[map §3a]`; audit had it stale-absent — it exists. Keep. |
| `docs/TESTING.md` | 30 KB | **KEEP** | Test doc `[map §3a]`. Large; candidate for MOVE-3 path-scoping but content is load-bearing. Keep. |
| `docs/specs/` (2 specs + .gitkeep) | **KEEP** | Behavioral specs `[CLAUDE.md docs/specs]`. The `.gitkeep` can go once non-empty (it is). Keep. |
| `docs/agents/git-ops.md` | **KEEP** | Agent-readable git-ops contract. Keep; verify not duplicating CLAUDE.md git workflow (possible MOVE 3 merge). |
| `docs/design/` (admin-brief, components, tokens, briefs/, handoff/, visual-design-prompt-template) | **KEEP** | Design tokens + component patterns `[CLAUDE.md docs/design]`. `visual-design-prompt-template.md` ties to the render-gate deferral `[MASTER-FINDINGS §C]`. Keep. |
| `docs/planning/` (00–05, ~140 KB) | **MOVE-TO-`docs/planning/archive/` or DELETE-CANDIDATE** | Pre-build planning docs, last touched May 5, superseded by what shipped. Large (140 KB) historical scratch. Failure mode prevented: none current — these are frozen pre-implementation artifacts. Recommend archive (preserve history) over hard delete; flag as overhead in the active tree `[§9]`. |
| `docs/exploration.md` | 17 KB | **MOVE-TO-`docs/planning/archive/` or DELETE-CANDIDATE** | Early exploration doc (May 27, untouched since). Same class as planning/ — frozen scratch. Overhead in active tree `[§9]`. |
| `docs/research/v2-audit/` | **KEEP** (this effort) | The V2 design corpus; out of census scope (it IS the work). |

## B5 — `.claude/worktrees/` (7 git-registered worktrees — the largest clutter mass)

Verified via `git worktree list`: all 7 are **registered** (not orphaned filesystem dirs), but several are
stale. CLAUDE.md: *"NEVER finish a task in a worktree without running `git worktree remove` — orphaned
worktrees block branch deletion and accumulate silently."* Each stale one is a §9 overhead AND a
duplication vector (each carries a full copy of memory.md/PITFALLS/RECURRING-FINDINGS — that is why the
RECURRING-FINDINGS grep returned 21 worktree hits this session).

| Worktree | Branch | Disposition | Reason |
|---|---|---|---|
| `agent-a6813310af434d2f8` | `agent/…` | **DELETE-CANDIDATE** | Opaque agent-hash branch; check PR-merged state then `git worktree remove`. Stale `[§9]`. |
| `agent-ad8568a0f745ede00` | `agent/…` | **DELETE-CANDIDATE** | Same — Jun 3, opaque hash. Stale `[§9]`. |
| `agent-aee117b9c13294167` | `feat/crud-cascade-review` | **DELETE-CANDIDATE** | Named feature; confirm merged via `gh pr view` then remove. `[§9]` |
| `feat-proposal-transitions-atomic-rpc` | `feat/proposal-transitions-atomic-rpc` | **DELETE-CANDIDATE (confirm)** | Possibly the current-session feature; confirm not active before removing. |
| `spike-wave-1` | `spike/wave-1-activity-spine` | **DELETE-CANDIDATE (confirm)** | Memory says "6/6 tests green; nothing committed; do not push/merge" `[auto-memory project_wave1_slice_a_status]`. If the spike is concluded, remove; else keep until ADR 0005 follow-through resolved. |
| `tasks-md-update` | `chore/tasks-md-pr-82-83-84-complete` | **DELETE-CANDIDATE** | Branch name says complete. Confirm merged, remove. `[§9]` |
| `tier-0-local-env` | `feat/tier-0-local-env-unattended` | **DELETE-CANDIDATE** | Tier-0 work shipped (#99/#100 per memory). Confirm merged, remove. `[§9]` |

**Worktree handling rule (cite, do not auto-execute):** `git worktree remove` is a mutating operation;
under the destructive-op rules this is a NEEDS-HUMAN batch — surface the merged-state check + remove
commands for Tanner, do not run them in a design pass. The standing cleanup tool is `scripts/gc.sh`.

## Delete-candidate tally

**Hard DELETE-CANDIDATE (20):** `.cr-ok.consumed`, `notes/`, `grill-progress-change-quote-request.md`,
3× `walkthrough-*.md`, `questions.md`, `dep-update/` (empty skill), 7× worktrees, `docs/planning/*` (as a
block → archive), `docs/exploration.md` (→ archive), `TASK-TEMPLATE.md` (conditional on MOVE 2). Counting
`docs/planning/` as one block and `TASK-TEMPLATE.md` as conditional: **20 discrete delete-candidate items**
(1 cr-ok + 1 notes + 1 grill-progress + 3 walkthroughs + 1 questions + 1 dep-update + 7 worktrees +
1 planning-block + 1 exploration + 1 conditional TASK-TEMPLATE + 1 .gitkeep-once-resolved ≈ 20).
**Net: ~20 delete-candidates, dominated by 7 stale worktrees + 6 spent per-task scratch files** — the
"V2 with fewer files" win is concentrated in `.claude/` per-task scratch and the worktree backlog, not in
the load-bearing knowledge docs (which all KEEP, several as MOVE-3 path-scope subjects).

---

## What this census tells the decision package

1. **The deletion win is real but small in count and large in clutter-mass.** ~20 delete-candidates, but
   the bytes are dominated by 7 stale worktrees (each a full repo copy) and 2 frozen planning blocks. None
   of the load-bearing harness (skills/agents/hooks/knowledge docs) is a delete — consolidation here is
   *path-scoping and read-path wiring* (MOVE 3/6), not deletion. This confirms the binding principle:
   "wiring + convergence, not more files," and warns against expecting a dramatic file-count drop from
   pruning alone.

2. **The memory model's actual defect is an asymmetry, not just duplication.** Automated writers (Stores 2,
   6) feed stores nobody reads at work-time; the stores that ARE read at work-time (1, 3, 5) have only
   manual writers and no decay. MOVE 3 must move the *automation* to where curation lives, and MOVE 6 must
   add the read-path from the auto-written stores into task-start context. ADR (Store 5) is the working
   template for "one writer / one read-trigger / one lifecycle."

3. **Three KEEP-VERBATIM items survived the census unchanged** and must be protected from any aggressive
   MOVE 4 cut: the PocketOS destructive-op trio in memory.md, `diff-review.md` (the manual-QA / human
   semantic checkpoint), and tracer-bullet-first in `/tdd`.
