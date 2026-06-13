# A1 — Memory / Findings / Knowledge-Persistence Pipeline (FACT-ONLY Inventory)

Pass A1 of the v2 ground-truth audit. Records what exists and what each file claims to do. No evaluation, no recommendations. All citations are `file:line` against the state of `main` at audit time.

---

## Systems in scope

1. `.claude/memory.md` — project-specific corrected-mistake rules
2. `docs/RECURRING-FINDINGS.md` — pipeline-logged findings with promotion path
3. `PITFALLS.md` — codebase-specific silent-bug traps
4. `.claude/rituals.md` — recurring maintenance tasks with `last_run` gating
5. `docs/solutions/` (+ `README.md`) — solved-problem pattern docs
6. `docs/adr/` (+ `README.md`) — architectural decision records
7. `.claude/INDEX.md` — annotated index of external resources
8. Auto-memory: `/Users/tanner/.claude/projects/-Users-tanner-Dev-event-vendor/memory/MEMORY.md` — user-scoped point-in-time memory (separate from project `.claude/memory.md`)

---

## 1. `.claude/memory.md`

**1. What it is / stated purpose.** "Project-specific rules accumulated from corrected mistakes. Read this at the start of every session. When a mistake is corrected during a session, add a rule here before the session ends." (`.claude/memory.md:1-4`).

**2. Entry format / schema.** Declared block format (`.claude/memory.md:6-18`):
```
name: <short descriptive name>
type: feedback | convention | gotcha | architecture
last_seen: YYYY-MM-DD

<The rule, stated as a direct constraint.>

Why: <One sentence on why this matters for this project.>

How to apply: <Concrete instruction — what to do or check.>
```
Entries observed conform: e.g. `name: destructive-operation-hard-stop / type: gotcha / last_seen: 2026-05-08` (`.claude/memory.md:24-26`). NOTE: the schema field is `last_seen` (`:11`), but the `/compound` quarterly-review step refers to it as `last_seen` too (`compound/SKILL.md:143-147`) — consistent. The CLAUDE.md session-start instruction references rituals' `last_run`, a different field on a different file.

**3. How updated.** By a human / the agent at session end, manually. Source: the file's own header rule (`.claude/memory.md:3-4`) and CLAUDE.md: "When a mistake is corrected, add a rule to `.claude/memory.md` before the session ends." `/compound` Step 6 proposes a memory.md entry but does NOT write it — "propose the memory.md entry... If no, say so explicitly" (`compound/SKILL.md:81-84`). No hook or pipeline writes this file automatically.

**4. Promotion / lifecycle.** `/compound` Step 9 "Quarterly memory review (run every ~90 days)" reads memory.md, flags entries by `last_seen` age (>90 days = stale), contradiction with current patterns, or redundancy with PITFALLS.md, and produces a report. Explicitly: "Do not modify memory.md. Surface candidates and wait for direction." (`compound/SKILL.md:139-164`). So memory.md → PITFALLS.md is a possible promotion target but human-driven, no automation.

**5. Read triggers.** Session start. CLAUDE.md: "At the start of every session, read `.claude/memory.md`, `TASKS.md`, `.claude/rituals.md`, and `.claude/SOUL.md`." Also "MUST read `.claude/memory.md` at session start" (CLAUDE.md → Before writing code). The file restates this (`:3`).

**Content note.** 7 entries present (`.claude/memory.md`): `destructive-operation-hard-stop`, `token-scope-assumption`, `staging-is-not-isolated`, `pipeline-tier-by-task-scope`, `enforcement-boundary-layering`, `auto-fix-scoped-to-diff`, `claude-md-referenced-scripts-must-exist`, `check-branch-before-commit`, `honest-assessment-not-validation`, `build-what-is-needed-now`, `research-before-guessing`. (11 total.) Several are behavioral/agent-discipline rules (e.g. `honest-assessment-not-validation` `:132`, `build-what-is-needed-now` `:144`, `research-before-guessing` `:156`) that duplicate the "Agent behavior principles" section of CLAUDE.md verbatim.

---

## 2. `docs/RECURRING-FINDINGS.md`

**1. What it is / stated purpose.** "Findings logged from pipeline runs. Promotion path: a finding moves to PITFALLS.md or into a pipeline pass once it has recurred enough to warrant permanent codification." (`docs/RECURRING-FINDINGS.md:1-5`).

**2. Entry format / schema.** Declared schema (`:13-23`):
```
### [normalized-signature]
- **First seen:** YYYY-MM-DD (commit SHA short)
- **Occurrences:** N
- **Last seen:** YYYY-MM-DD (commit SHA short)
- **Pass(es):** P1, P2, etc.
- **Description:** one paragraph
- **Example locations:** file:line (cap at 5, drop oldest when full)
- **Status:** active | promoted-to-pitfalls | promoted-to-pass | retired
```
Entries match: e.g. `### agents-md-migration-index-lags-final-commit` with `Occurrences: 4`, `Status: promoted-to-pitfalls (2026-06-03...)` (`:35-42`).

**3. How updated.** By the `/cr` pipeline automatically. The file states: "The pipeline synthesis step appends or increments entries automatically. Entries are matched on the `signature` field. The pipeline flags promotion candidates; the human confirms before promotion." (`:9-11`). Mechanism is `/cr` Step 3b (`cr/SKILL.md:174-188`): "read `docs/RECURRING-FINDINGS.md`. For each finding... Generate a normalized signature... Match against Active findings or append new entry with Occurrences: 1. Update Last seen, increment Occurrences, append file:line (cap at 5)."

**4. Promotion / lifecycle — FULL PATH.**
- Threshold for auto-flag: "any active finding with Occurrences ≥3" (`cr/SKILL.md:184`). Plus a judgment-flag: "any finding assessed as high-impact at lower count" (`:185`).
- Candidates collected in Step 3b but NOT surfaced there; surfaced at Step 5 (`cr/SKILL.md:187-188`, `:213-226`).
- Human confirms: Step 5 prints `Confirm? (y/n)` (`cr/SKILL.md:220-223`). "On confirmation: write PITFALLS.md entry, move to Promoted/retired in RECURRING-FINDINGS.md. On skip: leave in Active. Will re-flag after one more occurrence." (`:225-226`).
- Target of promotion: `PITFALLS.md | /cr pass P# prompt` (`:221`). So two promotion destinations: PITFALLS.md, or codification into a `/cr` pass prompt.
- Observed real promotion: `agents-md-migration-index-lags-final-commit` reached Occurrences 4, promoted 2026-06-03 to `PITFALLS.md § agents-md-migration-index-must-stay-current` (`RECURRING-FINDINGS.md:42`, `:228`, `:497-503`; landing entry at `PITFALLS.md:491-503`).
- Status terminal states: `promoted-to-pitfalls`, `promoted-to-pass`, `retired`. Retired examples logged in "Promoted / retired findings" section (`:224-229`).

**5. Read triggers.** Read by `/cr` Step 3b on every code review run (`cr/SKILL.md:176`). Not listed in the session-start read set in CLAUDE.md. No "read before editing area X" trigger.

**Content note.** ~21 active findings; majority tagged `P7` (doc drift, AGENTS.md staleness). Several findings are flagged `retired`/`promoted` inline AND restated in the trailer section (`:224-229`), i.e. status is tracked in two places per entry.

---

## 3. `PITFALLS.md`

**1. What it is / stated purpose.** "Codebase-specific traps that produce silent bugs. Read this before writing or modifying code in any affected area." (`PITFALLS.md:1-4`).

**2. Entry format / schema.** Not a fenced schema block; each entry is a `## <slug>` heading with bolded fields. Observed consistent shape: `**Area:**`, `**Rule:**`, `**Why:**`, `**Symptoms:**`, sometimes `**Fix:**`, `**Source:**`, `**See also:**` (e.g. `PITFALLS.md:16-26`, `:475-487`). `/compound` Step 5 names the canonical fields: "the standard format (Area, Rule, Why, Symptoms, Source)" (`compound/SKILL.md:75`).

**3. How updated.** Two declared write paths (`PITFALLS.md:6-9`): "Entries are added either: Promoted from docs/RECURRING-FINDINGS.md once recurrent enough, or Added directly when a known trap is identified outside the review loop." The promotion path is executed by `/cr` Step 5 on human confirmation (`cr/SKILL.md:225`). The direct path is via `/compound` Step 5 ("propose adding it with the standard format" — proposed, then written; `compound/SKILL.md:73-76`) or ad-hoc human edit.

**4. Promotion / lifecycle.** PITFALLS.md is itself a promotion *destination*, not a source — entries do not promote further. No retirement/archival mechanism is documented in the file. (RECURRING-FINDINGS entries that promote here change their own status to `promoted-to-pitfalls`; the PITFALLS entry persists.)

**5. Read triggers.** "Read this before writing or modifying code in any affected area." (`:4`). CLAUDE.md → Before writing code: "MUST read `PITFALLS.md` before writing in any affected area." Not a session-start read; it is area-gated.

**Content note.** ~30 entries. Areas span Supabase/migrations, hooks/`settings.json`, routing, git/worktree, schema layering. Some entries cite `docs/solutions/*` as Source (e.g. `:122`, `:222`, `:346`), some cite auto-memory files (e.g. `:54` cites `feedback_postgrest_timestamptz.md`; `:150` cites `project_schema_cascade_gotchas.md`; `:164` cites `project_table_grants.md`), some cite CLAUDE.md, some cite Notion changelog versions (`:26`, `:40`).

---

## 4. `.claude/rituals.md`

**1. What it is / stated purpose.** "Read at session start alongside memory.md. If any ritual's last_run is more than the specified frequency ago, surface it before any other work begins." (`.claude/rituals.md:1-4`).

**2. Entry format / schema.** Per-ritual block (observed, `:8-16`):
```
## <ritual-name>
last_run: YYYY-MM-DD
frequency: weekly | 14d | on-release
notes: <free text>
```

**3. How updated.** Manually, by the agent/human after running a ritual. The `notes` for `model-review` says "Update this file after any model changes." (`:25`). No hook writes it.

**4. Promotion / lifecycle.** None. Rituals do not promote; `last_run` is reset when the ritual runs.

**5. Read triggers.** Session start. CLAUDE.md: "read `.claude/memory.md`, `TASKS.md`, `.claude/rituals.md`, and `.claude/SOUL.md`. If any ritual's `last_run` is more than 7 days ago, surface it..." Note: the file says "more than the specified frequency ago" (`:2-3`) while CLAUDE.md hardcodes "more than 7 days ago" — two different gating rules for the same file.

**Content note.** 5 rituals: `improve-codebase-architecture` (weekly), `scan-context` (weekly), `model-review` (on-release), `prioritize-tasks` (weekly), `stale-branch-audit` (14d). All `last_run` values are 2026-05-27 or 2026-05-28; audit date context is 2026-06-10, so several are >7 days stale at audit time (fact, not judgment).

---

## 5. `docs/solutions/` + `README.md`

**1. What it is / stated purpose.** "Solved problems worth remembering. Each file captures a reusable pattern, architectural insight, or approach that worked — and why." (`docs/solutions/README.md:1-4`).

**2. Entry format / schema.** Per-solution file named `YYYY-MM-DD-short-description.md` (`README.md:28-30`). Format taken from `docs/solutions/TEMPLATE.md` (present in dir). README declares search keys: `tags:`, `area:`, `problem:` (`README.md:18-26`). "Add YAML frontmatter tags when this directory exceeds ~10 entries." (`:33`) — note the dir currently has 31 solution files (excluding README/TEMPLATE), exceeding that threshold. The central record is a markdown index table `| File | Problem solved |` (`:37-68`).

**3. How updated.** By `/compound` after a feature merges. README: "Run /compound after the feature is merged." (`:11`). `/compound` Steps 2-4 spawn a Sonnet extractor, review the draft with the user, then write `docs/solutions/YYYY-MM-DD-short-description.md` (`compound/SKILL.md:36-69`). The index table is maintained manually/by the same flow.

**4. Promotion / lifecycle.** Solutions are referenced by PITFALLS.md `Source:`/`See also:` fields (many entries) but do not themselves promote. README defines exclusions: do not add for obvious bug fixes, copy/config tweaks, or "Anything already fully captured in PITFALLS.md" (`:12-16`) — an explicit deduplication boundary against PITFALLS.

**5. Read triggers.** "MUST skim `docs/solutions/README.md` — know what patterns are already solved before designing anything" (CLAUDE.md → Before writing code). Search via grep recipes (`README.md:18-26`). Not a session-start read.

**Directory contents (33 files total):** 31 dated solution docs + `README.md` + `TEMPLATE.md`. Dated docs run 2026-05-08 through 2026-06-04. Full list:
2026-05-08-atomic-proposal-item-writes-rpc, -public-rpc-security-allowlist, -trigger-based-status-timestamps; 2026-05-12-rls-isolation-only-role-enforcement, -vendor-skill-integration; 2026-05-13-enforcement-boundary-layering, -vendor-skill-caveat-durability; 2026-05-18-dual-path-git-hook-tty-detection, -pipeline-sentinel-post-pipeline-commits, -solution-doc-drift-after-implementation-upgrade, -testing-react-cache-with-vitest-spy; 2026-05-20-post-checkout-worktree-npm-install; 2026-05-22-skill-file-vs-standing-rule; 2026-05-26-broad-allowlist-blocking-hook, -item-form-jsx-const-fields; 2026-05-27-agent-behavior-rules-in-system-files, -background-agent-permission-wall, -behavioral-standing-rules-vs-session-router, -collapsing-redundant-review-gate, -hook-single-responsibility-skill-boundary, -migration-number-collision-after-rebase, -notion-sync-audit-receipt, -pre-push-deletion-skip, -pre-push-merged-pr-guard, -public-write-rpc-security-definer, -service-role-membership-guard-null-uid; 2026-05-28-migrate-interface-to-zod-schema; 2026-06-03-dual-layer-formula-enforcement; 2026-06-04-client-array-rpc-scope-gap, -per-step-try-catch-multi-step-actions, -resolve-first-ordering-partial-success, -zod-validation-client-id-arrays-server-actions.
NOTE: `2026-05-27-hook-single-responsibility-skill-boundary.md` exists on disk but is NOT listed in the README index table (`README.md:37-68`) — index drift, fact.

---

## 6. `docs/adr/` + `README.md`

**1. What it is / stated purpose.** "ADRs are written when a decision is: hard to reverse, surprising without context, and the result of a real tradeoff. If any of the three is missing, skip the ADR." (`docs/adr/README.md:3`).

**2. Entry format / schema.** Fenced format block (`README.md:7-24`): `# NNNN — Short title / Date / Status: Accepted | Superseded by NNNN | Deprecated / ## Context / ## Decision / ## Alternatives considered / ## Consequences`. File naming `NNNN-short-title.md` (`:26`). Index table `| # | Title | Status |` (`:30-36`).

**3. How updated.** Manually / human-authored when a qualifying decision is made. No skill or hook writes ADRs automatically (no `/compound` step targets `docs/adr/`; grep found no pipeline writer). The decision criteria gate is in the README header.

**4. Promotion / lifecycle.** Status lifecycle via the `Status` field: `Accepted → Superseded by NNNN | Deprecated`. No occurrence-counting; lifecycle is editorial.

**5. Read triggers.** "MUST skim `docs/adr/README.md` — know what architectural decisions are locked before designing anything" (CLAUDE.md → Before writing code). Not session-start.

**Directory contents (6 files):** `0001-proposal-state-machine-predicate.md`, `0002-item-revisions-via-trigger.md`, `0003-role-checks-in-typescript-not-rls.md`, `0004-monolith-no-service-boundaries.md`, `0005-activity-log-as-system-spine.md`, `README.md`. All 5 ADRs indexed as `Accepted` (`README.md:32-36`). NOTE: auto-memory `MEMORY.md:6` and the memory index claim "ADR 0005 still unwritten" — but `0005-activity-log-as-system-spine.md` is present on disk and indexed as Accepted. Auto-memory is stale on this point (its own banner says it is 5 days old).

---

## 7. `.claude/INDEX.md`

**1. What it is / stated purpose.** "Annotated index of external resources for this project. When you need context that isn't in the repo, check here before asking." (`.claude/INDEX.md:1-3`).

**2. Entry format / schema.** Free-form sections: "This repo", "External docs" (each: link + "Read when:" annotation), "MCP tools" (when/how to use), "Required global skills", "What does NOT belong here." No structured schema.

**3. How updated.** Manually. No automated writer.

**4. Promotion / lifecycle.** None.

**5. Read triggers / role re: the memory pipeline.** INDEX.md indexes EXTERNAL resources (Next.js, Supabase, Zod, Vitest, Tailwind docs; Chrome/Supabase/Notion MCP; Matt Pocock global skills). It does NOT index memory.md, PITFALLS.md, RECURRING-FINDINGS.md, solutions, or ADRs. So the knowledge-persistence files are NOT cross-indexed by INDEX.md — there is no single index of the internal knowledge corpus. (The closest to an internal index are the per-file index tables inside `docs/solutions/README.md` and `docs/adr/README.md`.)

---

## 8. Auto-memory — `/Users/tanner/.claude/projects/.../memory/MEMORY.md`

**Relationship to `.claude/memory.md`: TWO SEPARATE SYSTEMS.**

- **Location:** user-scoped, outside the repo: `/Users/tanner/.claude/projects/-Users-tanner-Dev-event-vendor/memory/MEMORY.md`. The project `.claude/memory.md` is repo-checked-in. Different files, different roots, no symlink.
- **Mechanism:** `MEMORY.md` is the Claude Code "auto-memory" feature — a point-in-time memory index. Its loaded banner states: "This memory is 5 days old. Memories are point-in-time observations, not live state — claims about code behavior or file:line citations may be outdated. Verify against current code before asserting as fact." It is NOT governed by any repo skill or hook; it is the harness's own memory store.
- **Format:** `MEMORY.md` is an index of one-line bullets, each linking to a sibling `.md` file in the same `memory/` dir (51 sibling files: `feedback_*.md`, `project_*.md`, `reference_*.md`, plus `MEMORY.md`). E.g. `- [PostGREST timestamptz format](feedback_postgrest_timestamptz.md) — Use z.iso.datetime({ offset: true })...` (`MEMORY.md:10`).
- **How updated:** by the Claude Code memory subsystem (the harness writes/refreshes it), not by `/compound`, `/cr`, or any repo hook. The project files in scope here never reference writing to it.
- **Read trigger:** injected into context at session start by the harness (it appears in the system reminder), independent of the CLAUDE.md session-start read list.
- **Overlap with project files:** HIGH content overlap. PITFALLS.md cites auto-memory files as `Source:` (`PITFALLS.md:54`, `:150`, `:164`). The same facts appear in three places: e.g. PostgREST timestamptz lives in auto-memory (`feedback_postgrest_timestamptz.md`), in PITFALLS.md (`:44-54` § `postgrest-timestamptz-offset-format`), and is referenced from MEMORY.md index (`MEMORY.md:10`). Background-agent-bash-permissions lives in auto-memory (`feedback_background_agent_bash_permissions.md`, `MEMORY.md:4`), in PITFALLS-adjacent CLAUDE.md rules, and in `docs/solutions/2026-05-27-background-agent-permission-wall.md`.

---

## 6. THE CENTRAL QUESTION — Overlap Map (FACT-ONLY)

| File | Distinct role (as stated) | What triggers a WRITE | What triggers a READ | Overlaps with |
|------|---------------------------|------------------------|----------------------|----------------|
| `.claude/memory.md` | Project-specific rules from corrected mistakes; "direct constraint" + Why + How-to-apply | Manual at session end when a mistake is corrected; `/compound` Step 6 *proposes* but does not write | Session start (CLAUDE.md mandatory read) | PITFALLS.md (gotcha-type entries overlap traps); CLAUDE.md (behavioral entries duplicate "Agent behavior principles" verbatim); auto-memory `feedback_*` files (same corrected-mistake content) |
| `docs/RECURRING-FINDINGS.md` | Occurrence-counted log of pipeline findings; staging area with promotion path | `/cr` Step 3b automatic: append/increment by signature | `/cr` Step 3b each review run | PITFALLS.md (its promotion target); `/cr` pass prompts (alt promotion target). Distinct in being the only occurrence-counted/transient store |
| `PITFALLS.md` | Codebase traps that cause silent bugs; area-gated | Promotion from RECURRING-FINDINGS (`/cr` Step 5, human-confirmed) OR direct add (`/compound` Step 5 or human) | Before writing/editing in an affected area (CLAUDE.md mandatory) | RECURRING-FINDINGS (upstream source); memory.md (gotcha rules); docs/solutions (cited as Source); auto-memory (cited as Source) |
| `docs/solutions/` | Reusable solved-problem patterns + why | `/compound` after a feature merges (Sonnet extractor → review → write) | "Skim README before designing" (CLAUDE.md); grep by tag/area/problem | PITFALLS.md (README excludes "anything already fully captured in PITFALLS.md"); ADRs (some solutions encode architectural decisions); auto-memory (some same patterns) |
| `docs/adr/` | Hard-to-reverse architectural decisions w/ tradeoffs | Manual/human when a qualifying decision is made; no automated writer | "Skim README before designing" (CLAUDE.md) | docs/solutions (architectural-pattern solutions blur into ADR territory); AGENTS.md "Resolved/Rejected Decisions" |
| `.claude/rituals.md` | Recurring maintenance tasks gated by last_run | Manual after running a ritual | Session start (CLAUDE.md mandatory; 7-day gate) | None on content; structurally parallels memory.md (both session-start, both `last_*` dated, both manual) |
| `.claude/INDEX.md` | Annotated index of EXTERNAL resources only | Manual | "Check here before asking" for external context | Does NOT index the internal knowledge corpus; no overlap with the persistence files (gap, not overlap) |
| Auto-memory `MEMORY.md` (+ siblings) | Harness point-in-time memory: project context + corrected-mistake notes + references | Claude Code memory subsystem (harness), not any repo skill/hook | Injected at session start by harness | HIGH: PITFALLS.md cites it as Source; memory.md duplicates corrected-mistake content; docs/solutions duplicates some patterns. Three-way duplication of individual facts is common |

### Where purposes blur (factual observations only)

- **memory.md `type: gotcha` vs PITFALLS.md.** Both hold "trap that causes a silent failure" content. `destructive-operation-hard-stop` (memory.md `:24`) and `enforcement-boundary-layering` (`:84`) are gotcha/architecture rules indistinguishable in kind from PITFALLS entries. `/compound` Step 9 explicitly flags memory entries "already covered by PITFALLS.md (redundant)" (`compound/SKILL.md:148`, `:158-159`), confirming the overlap is acknowledged in-system.
- **memory.md behavioral entries vs CLAUDE.md.** `honest-assessment-not-validation` (`:132`), `build-what-is-needed-now` (`:144`), `research-before-guessing` (`:156`) reproduce the CLAUDE.md "Agent behavior principles" section near-verbatim. Same content in two repo files.
- **Auto-memory vs PITFALLS.md vs docs/solutions.** Individual facts (PostgREST timestamptz, background-agent bash permissions, table grants, cascade gotchas) appear in all three layers, with PITFALLS.md `Source:` pointing back to the auto-memory file.
- **docs/solutions vs docs/adr.** Architectural-decision solutions (e.g. `2026-05-12-rls-isolation-only-role-enforcement.md`) overlap conceptually with ADR `0003-role-checks-in-typescript-not-rls.md` — same decision, two stores. PITFALLS `rls-role-mission-creep` (`:212-222`) cites the solution doc, while the ADR holds the decision record.
- **RECURRING-FINDINGS → PITFALLS is the only formal promotion pipeline.** Every other file is either a terminal store or human-maintained. RECURRING-FINDINGS is the sole occurrence-counted, signature-matched, auto-incrementing store.
- **Status tracked in two places within RECURRING-FINDINGS.** Each promoted/retired entry carries an inline `Status:` AND a duplicate line in the trailer "Promoted / retired findings" section (`:224-229`).

---

## 7. Claim-vs-Reality Flags (present/absent verification)

| Referenced file/mechanism | Result |
|---------------------------|--------|
| `.claude/learned-patterns.md` | **ABSENT** — does not exist on disk |
| `.claude/review-log.md` | **ABSENT** — does not exist on disk |
| `.claude/triage-inbox.md` | **ABSENT** — does not exist on disk |
| `.claude/INDEX.md` | PRESENT |
| `docs/solutions/TEMPLATE.md` (referenced `compound/SKILL.md:39`) | PRESENT |
| `docs/RECURRING-FINDINGS.md` promotion → `PITFALLS.md § agents-md-migration-index-must-stay-current` | PRESENT and consistent (`RECURRING-FINDINGS.md:42,228,503` ↔ `PITFALLS.md:491-503`) |
| Auto-memory `MEMORY.md` | PRESENT (50 lines + 50 sibling `.md` files) |

**Additional claim-vs-reality notes:**
- Auto-memory `MEMORY.md:6` claims "ADR 0005 still unwritten" — **CONTRADICTED**: `docs/adr/0005-activity-log-as-system-spine.md` exists and is indexed `Accepted`. Auto-memory is stale (self-declared 5 days old).
- `docs/solutions/2026-05-27-hook-single-responsibility-skill-boundary.md` exists on disk but is **NOT** in the `README.md` index table — index drift.
- `docs/solutions/README.md:33` says add YAML frontmatter tags "when this directory exceeds ~10 entries"; directory has 31 dated docs — threshold passed, condition's action-state not verified here.
- rituals.md gating rule ("more than the specified frequency ago", `:2-3`) differs from CLAUDE.md's hardcoded "more than 7 days ago" — two gate definitions for the same file.
