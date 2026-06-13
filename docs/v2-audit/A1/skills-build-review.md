# A1 — Build/Review Pipeline Skills Inventory (FACT-ONLY)

Pass A1 ground-truth inventory of the build/review pipeline skills under `/Users/tanner/Dev/event-vendor/.claude/skills/`. Records what exists and what each file claims. No evaluation, no recommendation.

Enforcement legend:
- **STRUCTURAL** — a hook, git mechanism, CI, or script that actually blocks.
- **ADVISORY** — a markdown instruction the model is asked to follow; nothing blocks if skipped.

Directory contents verified (`ls`):
- `cr/SKILL.md` (12832 b) — only file
- `cr-security/SKILL.md` (4248 b) — only file
- `tdd/SKILL.md` (5225 b) — only file
- `dev/SKILL.md` (5601 b) — only file
- `feature/SKILL.md` (9623 b) — only file
- `hotfix/SKILL.md` (12070 b) — only file
- `refactor/SKILL.md` (1440 b) + `refactor/extract-module.md` (4054 b)
- `queue/SKILL.md` (4668 b) — only file

---

## /cr — Full pre-merge review

**1. What it is / trigger.** `cr/SKILL.md:1-13`. "Full branch diff review across all commits on the branch, run once before merging to main." Triggers: "/cr", "run a code review", "review this branch", "pre-merge review", "is this ready to merge". Claims to fix must-fix items automatically and surface the rest.

**2. Workflow (step-by-step, cited).**

- **Anti-rationalization table** `cr:15-23` — three rebuttals, incl. "writing `.cr-ok` directly means no certificate." ADVISORY.
- **Step 0 — Docs-only check** `cr:25-38`. If every changed file in `git diff main..HEAD` is `.md`, under `.claude/`, or non-code config: run a single Haiku doc-review pass instead of the full review; check accuracy/broken refs/contradictions; return MUST FIX / Nice to Have; write the sentinel if no MUST FIX; evaluate `/compound`. **Skill-structure meta-check** `cr:36`: when diff includes `.claude/skills/**/*.md`, scan for mid-pipeline user-input waits and flag as MUST FIX structural bug. ADVISORY (model-run classification).
- **Step 1 — Gather context** `cr:42-49`. `git log --oneline main..HEAD`, `git diff main..HEAD`, read any plan file in `.claude/plans/`, note worktree path. ADVISORY.
- **Step 2 — Spawn 9 review agents IN PARALLEL** `cr:51-139`. Full diff + plan passed in each prompt. Each agent returns Must Fix / Nice to Have / Something to Think About.
  - Pass 1 Correctness & Spec (Sonnet) `cr:60-67`
  - Pass 2 Domain Safety (Sonnet) `cr:69-76`
  - Pass 3 TypeScript Discipline (Sonnet) `cr:77-84`
  - Pass 4 Layer Boundaries (Sonnet) `cr:86-92`
  - Pass 5 Readability & Naming (Sonnet) `cr:94-101`
  - Pass 6 Test Quality (Sonnet) `cr:103-109`
  - Pass 7 Doc Drift & Footprint (Haiku) `cr:111-119` — Part A mechanical (console.log, TODO/FIXME, commented code, unused imports, @ts-ignore, any, as-without-narrowing, it.only) + Part B doc drift.
  - Pass 8 Architectural Drift (Sonnet) `cr:121-129`
  - Pass 9 Devil's Advocate (Sonnet) `cr:131-139`
  - All ADVISORY (model-spawned sub-agents).
- **Pass 11 — Adversarial Review** `cr:143-151`. Spawns `@reviewer` in **implementation mode** with the full diff; @reviewer spawns four lens agents in parallel — assumption violation, composition failures, cascade construction, abuse cases — and consolidates. Findings fold into the three tiers; **High findings from any lens are Must Fix.** Tags: `[P11-assumption]`, `[P11-composition]`, `[P11-cascade]`, `[P11-abuse]`. References "Templates → agents/reviewer.md". ADVISORY.
  - **NOTE: there is no Pass 10.** Numbering jumps 9 → 11 (verified: `grep "Pass 10"` returns nothing; only Pass 11 present at `cr:143`).
- **Step 3 — Synthesize + RECURRING-FINDINGS** `cr:155-188`. Dedup; produce tiered report with per-item `[P#]` tags `cr:170-172`. **Step 3b** `cr:174-188`: read `docs/RECURRING-FINDINGS.md`, normalize signatures, match/append, increment Occurrences (cap file:line at 5); promotion candidates auto-flagged at Occurrences ≥3 or by judgment; collected but NOT surfaced here — deferred to Step 5. ADVISORY.
- **Step 4 — Fix Must Fix items (Opus)** `cr:192-209`. Spawn one Opus agent ("staff engineer; fix only what's listed; flag NEEDS HUMAN if >~15 lines / architectural decision / ambiguous"). **Hook-file escape hatch** `cr:201-205`: a Must Fix in `.claude/hooks/*.sh` is NOT routed to the Opus agent (blocked by `settings.json` deny on `Edit/Write(/.claude/hooks/**)`); routed to NEEDS HUMAN with paste-ready command; sentinel not written until human confirms. After fixes: run test suite, one retry. ADVISORY workflow; the underlying `Edit/Write(/.claude/hooks/**)` deny is STRUCTURAL (settings.json — outside A1 slice).
- **Step 5 — Surface the rest** `cr:213-228`. List Nice to Have + Something to Think About + promotion candidates with `Confirm? (y/n)`. On confirm: write PITFALLS.md entry, move to Promoted in RECURRING-FINDINGS.md. ADVISORY.
- **Step 6 — Manual test checklist** `cr:232-236`. ADVISORY (produces a checklist for the human to run before PR).
- **Step 7 — Write push sentinel** `cr:240-256`. After final report and no unresolved Must Fix: resolve `branch:sha`, write to absolute path `${REPO_ROOT}/.claude/.cr-ok` (relative form does not match harness allowlist for sub-agents). Content is exactly `branch:sha`, no trailing newline. Fallback to Write tool if printf-redirect denied. Then `scripts/pr.sh`, surface PR URL. The write itself is ADVISORY; the sentinel is **consumed/validated STRUCTURALLY** downstream by `.husky/pre-push` and `scripts/pr.sh`.
- **Step 8 — Evaluate /compound (required)** `cr:260-273`. Evaluate four conditions; invoke `/compound` if any true; else state "No compound-worthy findings…". ADVISORY.

**3. Produces / enforces.** Writes sentinel `.claude/.cr-ok` (content `branch:sha`) at `cr:249`. Updates `docs/RECURRING-FINDINGS.md` (Step 3b) and optionally `PITFALLS.md` (Step 5). Spawns: 9 analytical sub-agents (Step 2) + `@reviewer` (Pass 11, which spawns 4 lens agents) + 1 Opus fix agent (Step 4) + possibly `/compound`. No REJECT tier — routing is **MUST FIX (auto-fixed by Opus) / NEEDS HUMAN (escape hatch + >15-line/ambiguous) / SUGGESTION-equivalent (Nice to Have, Something to Think About)**.

**4. Enforcement summary.** Entire `/cr` body is ADVISORY at run time (model-driven). The only STRUCTURAL teeth are downstream: `.husky/pre-push` (agent path) requires `.claude/.cr-ok` == `branch:sha` or blocks the push (`pre-push:56-72`); `scripts/pr.sh` validates + consumes the sentinel at PR-create time (`pr.sh:8,17,28-45`). So `/cr`'s output (the sentinel) is structurally enforced even though `/cr`'s passes are not.

**5. Cross-references.** `@reviewer` agent (`.claude/agents/reviewer.md` — EXISTS) → 4 lens agents. `/compound` skill (EXISTS). `scripts/pr.sh` (EXISTS). `docs/RECURRING-FINDINGS.md`, `PITFALLS.md`, `AGENTS.md`, `PITFALLS.md`, `CONTEXT.md`, `docs/TESTING.md` (all EXIST). `settings.json` hook-deny (outside slice).

**6. UNATTENDED / autoMode branching.** `grep "UNATTENDED|autoMode|auto-mode"` over `cr/SKILL.md` and `cr-security/SKILL.md` returns **nothing**. Neither skill body contains any UNATTENDED flag branching. (UNATTENDED worktree mode exists at the repo/settings level per commit `130f4a2`, but is NOT referenced inside these two skills.)

**Claim-vs-reality for /cr.**
- "9 review agents" — body defines Passes 1–9 (9 passes). ✅ matches.
- "plus adversarial review" — Pass 11 / `@reviewer`. ✅ `@reviewer` agent file exists.
- Four lens agents (`@lens-assumption`, `@lens-composition`, `@lens-cascade`, `@lens-abuse`) — **all four agent files EXIST** in `.claude/agents/`. ✅
- "Templates → agents/reviewer.md" `cr:149` — the path label "Templates →" is a naming convention; the actual file is `.claude/agents/reviewer.md` (EXISTS). Note the indirection label vs. real path.
- Pass numbering gap (9 → 11, no Pass 10) — factual gap in the document.

---

## /cr-security — Security review

**1. What it is / trigger.** `cr-security:1-20`. Opt-in 3-pass security review. Run manually before committing changes to: auth/middleware/route guards, public unauthenticated handlers (`/p/[token]`, `/no-team`, `/auth/callback`), RLS policies/data boundaries, cross-team isolation, share tokens / `get_proposal_by_share_token` RPC, server actions, new Postgres functions. **Every finding is MUST FIX — no SUGGESTION tier** (`cr-security:34`).

**2. Workflow.**
- Step 1 Gather context `cr-security:24-29` — `git diff HEAD` or `main..HEAD`, read AGENTS.md routing + RLS strategy. ADVISORY.
- Step 2 Spawn 3 review agents IN PARALLEL `cr-security:32-68`:
  - Pass 1 Security & Auth (Sonnet) `cr-security:36-45`
  - Pass 2 Data Boundary Integrity (Sonnet) `cr-security:47-54`
  - Pass 3 Supabase Security Checklist (Sonnet) `cr-security:56-68` — **invokes the `/supabase` skill** and runs its checklist.
  - ADVISORY.
- Step 3 Auto-fix (Opus) `cr-security:72-78` — compile all MUST FIX, spawn one Opus agent, minimum changes, flag NEEDS HUMAN if architectural/ambiguous. After fixes: `npx vitest run`, **no retry**. ADVISORY.
- Step 4 Surface NEEDS HUMAN `cr-security:82-84`. ADVISORY.

**3. Produces / enforces.** Does NOT write a sentinel. No `.cr-ok` or `.cr-security-ok` mentioned. Spawns 3 sub-agents + 1 Opus fix agent. Invokes `/supabase` skill.

**4. Enforcement.** Entirely ADVISORY. No hook validates that `/cr-security` ran. (`.husky/pre-push` checks only `.cr-ok`, not any security sentinel.)

**5. Cross-references.** `/supabase` skill (symlink `.claude/skills/supabase` → `../../.agents/skills/supabase`, EXISTS). `AGENTS.md`. CLAUDE.md REVOKE rule.

**6. Overlap note (recorded, not judged).** Pass 2 of `/cr-security` ("Supabase client called outside `src/data/`") overlaps `/cr` Pass 4 (Layer Boundaries: "No Supabase calls outside src/data/"). Both run a layer-boundary check. Flagged at `cr-security:49` vs `cr:88`.

---

## /tdd — Vertical-slice red-green-refactor

**1. What it is / trigger.** `tdd:1-8`. Implements one confirmed behavior via red-green-refactor. Requires a confirmed behavior in `docs/TESTING.md` first. "One behavior = one test = one implementation = one commit." Triggers: "/tdd", "implement this", "write the code for", "build this slice", "make this test pass".

**2. Workflow.** Canon TDD loop (Specify → Encode → Fulfill) `tdd:12-21`. Anti-rationalization table `tdd:24-32`. Step 0 no-transcription rule `tdd:36-39`. Step 1 confirm behavior in `docs/TESTING.md`, stop+ask if absent `tdd:43-49`. Step 2 design the interface `tdd:53-64`. Step 3 decompose into vertical slices `tdd:68-81`. Step 4 the loop — pick slice, comment expected behavior, write failing test, `npx vitest run <file>` confirm red, minimum code green, re-run, refactor-only-if-needed, commit test+impl atomically, next slice `tdd:84-99`. Step 5 codebase test patterns (no DB mock; seed via `supabaseAdmin`; auth-error spy exception) `tdd:103-109`. Step 6 update `docs/TESTING.md` `tdd:113-118`.

**3. Produces / enforces.** Atomic commits (test + impl). Updates `docs/TESTING.md`. No sentinel. No sub-agents.

**4. Enforcement.** ADVISORY throughout. `npx vitest run` is run by the model, not gated within the skill (pre-commit hook independently runs `test:unit` — STRUCTURAL but external, `pre-commit:5`).

**5. Cross-references.** `docs/TESTING.md`, `PITFALLS.md`, `docs/solutions/`. Two top-level `tdd` skills exist: project `.claude/skills/tdd/` AND a global `tdd` skill (both listed in available skills). Recorded as a potential name collision.

---

## /dev — Full TDD + pipeline loop for one task

**1. What it is / trigger.** `dev:1-6`. Orchestrates Phase 0 (scope) → Phase 5 (commit) for a single task. Trigger: `/dev <task description>`.

**2. Workflow.**
- Phase 0 Scope & clarity `dev:20-31` — read CLAUDE.md + AGENTS.md, list pure functions, stop on open decision / ambiguity / new npm package. ADVISORY.
- Phase 1 Test Writer Agent `dev:34-55` — spawn sub-agent to write ONLY failing tests; then `npx vitest run` confirm they fail. ADVISORY.
- Phase 2 Implementation Writer Agent `dev:57-81` — spawn sub-agent for minimum impl; `npx vitest run` until green (re-spawn on failure). ADVISORY.
- Phase 3 Multi-stage review `dev:83-94` — **invokes `/cr`** on `git diff HEAD`; then `npx vitest run` once more. ADVISORY (delegates to /cr).
- Phase 4 Doc Updater Agent `dev:96-116` — spawn sub-agent to update CLAUDE.md / AGENTS.md / docs/design. ADVISORY.
- Phase 5 tsc + commit `dev:118-129` — `npx tsc --noEmit` zero errors, conventional commit. ADVISORY.
- Final report format `dev:132-148`.

**3. Produces / enforces.** Commits. Delegates sentinel-writing to `/cr` (Phase 3). Spawns: test-writer, implementation-writer (1+), `/cr` (and its agents), doc-updater. No own sentinel.

**4. Enforcement.** ADVISORY orchestration; structural teeth come only from invoked `/cr` (→ sentinel) and external pre-commit/pre-push hooks.

**5. Cross-references.** `/cr` (EXISTS). CLAUDE.md, AGENTS.md, `docs/design/tokens.md`, `docs/design/components.md`.

**6. Overlap (recorded).** `/dev` Phase 1+2 (spawn test-writer then implementation-writer) overlaps `/tdd`'s red-green loop and `/feature`'s implement step — three skills each define a "write failing test → implement → green" flow. `/dev` Phase 4 doc-updater overlaps `/cr` Pass 7 (doc drift) and the `doc-updater` agent. `/dev` Phase 3 wholly re-invokes `/cr`.

---

## /feature — Feature pipeline (size-tiered)

**1. What it is / trigger.** `feature:1-8`. Size-driven orchestration (Tiny/Small/Medium/Large). Triggers: "new feature", "build X", "implement X", "plan a feature", `/feature`.

**2. Workflow.** Tracer-bullets framing `feature:17-32`. Anti-rationalization `feature:34-42`. Step 0 size the feature `feature:46-61` — sizing table `feature:49-54`; contract-per-sub-agent required from `.claude/agent-contract.md` `feature:56-58`; tell user estimate, ask if wrong. Tiers:
- **Tiny (1)** `feature:64-74`: Confirm → TESTING.md → `/tdd` → `/simplify` → `/cr` (+`/cr-security` if auth/RLS/db) → tsc → commit → report.
- **Small (2–5)** `feature:78-97`: Orient → Research check → `/design contract` (+`/design explore`) → `/grill-with-docs` → solutions check → spec to TESTING.md → plan+approval → `/tdd` → `/simplify` → `/cr`(+`/cr-security`) → tsc → commit → compound questions → `/compound` → report.
- **Medium (6–15)** `feature:102-121`: adds `docs/specs/[slug].md` (human-approved gate) + `/to-issues` decompose with hard STOP gate `feature:111` → parallel sub-agents → plan → `/tdd` per issue → `/simplify` → `/cr` → … → `/compound`.
- **Large (16+)** `feature:125-133`: spec (human-approved) → `/grill-with-docs` → TESTING.md → `/to-issues` → run `/feature` on each issue.
Final report `feature:137-148`. Done criteria `feature:152-164`.

**3. Produces / enforces.** Delegates everything; no own sentinel (relies on `/cr`). Writes `docs/TESTING.md`, optionally `docs/specs/[slug].md`, GitHub issues via `/to-issues`. Spawns sub-agents per contract (`.claude/agent-contract.md`, EXISTS; `TASK-TEMPLATE.md`, EXISTS).

**4. Enforcement.** ADVISORY. The `/to-issues` STOP gates (`feature:111`) and human-approved spec gate (`feature:105`) are ADVISORY (model-honored, not hook-blocked).

**5. Cross-references.** Header `feature:11-15` declares upstream deps `/grill-with-docs`, `/tdd`, `/to-issues`, **`/simplify`** as "from Matt Pocock's skills repo — not included here; install via `npx skills@latest add mattpocock/skills`." Also `/design`, `/cr`, `/cr-security`, `/compound`. `.claude/INDEX.md` (EXISTS), `.claude/agent-contract.md` (EXISTS), `TASK-TEMPLATE.md` (EXISTS), `CONTEXT.md`.

**Claim-vs-reality for /feature.**
- **`/simplify` does NOT exist at `.claude/skills/simplify/`** (verified: `ls` → "No such file or directory"). It is also **not** in `~/.claude/skills/`. The skill IS listed as an available skill named `simplify` (a built-in/global "Review the changed code for reuse, simplification…" skill per the system skill list) — so the *name* resolves to a different, globally-provided skill, not a project skill. `/feature` invokes `/simplify` at every tier (`feature:52,53,70,88,115`). The skill header correctly flags it as external/not-included (`feature:13`).
- **`/grill-with-docs` and `/to-issues`** also do NOT exist under `.claude/skills/` but DO exist in `~/.claude/skills/` (verified: both present in global skills). So they resolve globally.
- `/design` exists at `.claude/skills/design/` (EXISTS).
- `.claude/agent-contract.md`, `TASK-TEMPLATE.md`, `.claude/INDEX.md` all EXIST.

---

## /hotfix — Production-broken triage + fix

**1. What it is / trigger.** `hotfix:1-9`. Two-mode hotfix (mitigation-only / full-fix). Triggers: "production is down", "users can't", "critical bug", "hotfix", P0/P1. Requires `/debug` root cause first. Entry should be via `/incident` (`hotfix:53-71`).

**2. Workflow.** Loop diagram `hotfix:75-99`. Entry conditions (must be classified `our-code-narrow`/`our-code-structural` by `/incident`, or `/debug` confirmed root cause; active impact) `hotfix:61-71`.
- Phase 1 Triage gate (agent proposes, human confirms; mode decision) `hotfix:103-126`. ADVISORY (human confirm step).
- Phase 2 Mitigation-options (2–3 options, human picks) `hotfix:128-154`. ADVISORY.
- Phase 3 TASKS.md entries before code — full-fix = 1 `[hotfix-postmortem]` entry; mitigation-only = `[hotfix-correction]` + `[hotfix-postmortem]` (`hotfix:158-192`). Note `hotfix:192`: "**@hotfix-guard will not pass without the required entries present.**"
- Phase 4 Blast-radius analysis `hotfix:196-234` — spawn **`@reviewer`** with Impact lens + Cascade lens → blast-radius report; verdict Stop/Proceed-with-risks/Safe.
- Phase 5 The hotfix loop `hotfix:237-266` — branch, failing test (confirm red), minimum fix, `npx tsc --noEmit`, `/cr`, `@hotfix-guard`, merge.
- Phase 6 `@hotfix-guard` `hotfix:270-280` — 3 gates: required TASKS.md entries exist, failing test exists, scope not exceeded. References "Templates → agents/hotfix-guard.md".
- Final report `hotfix:284-300`; after-merge handling `hotfix:304-320`.

**3. Produces / enforces.** Writes TASKS.md entries, `.claude/hotfix-scope-[slug].md` (`hotfix:320`). Branch `hotfix/[slug]` or `hotfix/[slug]-mit`. Spawns `@hotfix-guard`, `@reviewer` (blast-radius). Invokes `/cr`. Feeds `/post-mortem`.

**4. Enforcement.** ADVISORY. `@hotfix-guard` is a model-spawned sub-agent (not a git hook) — "will not pass" (`hotfix:192`) is advisory gating, not structural. `/cr` (Phase 5) → sentinel (structural downstream). `npx tsc --noEmit` model-run.

**5. Cross-references.** `@reviewer` (`.claude/agents/reviewer.md`, EXISTS), `@hotfix-guard` (`.claude/agents/hotfix-guard.md`, EXISTS). Skills: `/incident`, `/debug`, `/cr`, `/migrate`, `/post-mortem`, `/feature` (all present as skills). TASKS.md.

**6. Overlap (recorded).** `/hotfix` Phase 4 blast-radius spawns `@reviewer` (Impact + Cascade lenses); `/cr` Pass 11 also spawns `@reviewer` (4 lenses incl. cascade). Both invoke the same `@reviewer` agent but in different lens configurations. Phase 5 also invokes `/cr` itself → double `@reviewer` invocation within one hotfix.

**Claim-vs-reality for /hotfix.** `@reviewer` and `@hotfix-guard` agent files both EXIST. `reviewer.md` declares only **Design mode** and **Implementation mode** (`reviewer.md:5-7,17-19`) — it does NOT declare a "blast-radius / Impact+Cascade lens" mode that `/hotfix` Phase 4 describes (`hotfix:202-216`). The two-lens blast-radius framing in `/hotfix` does not map onto the four-lens implementation/design modes the reviewer agent actually defines. Recorded as a claim-vs-reality mismatch.

---

## /refactor — Safe incremental refactor (extract-module)

**1. What it is / trigger.** `refactor/SKILL.md:1-6`. One mode: extract-module. Triggers: "refactor", "extract this", "split this file", "this file is too big", "move this to its own module". For renaming/extracting a function: apply two-hat + test-first from CLAUDE.md, no skill invocation needed.

**2. Workflow.** SKILL.md: two rules (tests-before-movement, two-hats) `refactor/SKILL.md:8-17`; Step 0 baseline — vitest/tsc/lint/build all green `refactor/SKILL.md:18-27`; defer to `extract-module.md` `refactor/SKILL.md:29-32`.
`extract-module.md`: write `.claude/refactor-plan.md` first (memory file) `extract-module.md:5-34`; **naming gate** — single-sentence responsibility, no "and"/"or", reject `utils/helpers/common/shared/misc/base` `extract-module.md:36-40`; cover symbols with characterization tests else stop and run `/tdd` `extract-module.md:42-51`; extract loop per module (create file, move symbols, re-export from source, run verifications, verify clean, commit, mark plan) `extract-module.md:54-94`; update callers + remove transitional re-exports `extract-module.md:96-106`; done checklist incl. **"Run `/cr`"** `extract-module.md:108-119`; for 4+ modules use `refactor-extractor` sub-agent, one per module, run sequentially `extract-module.md:121-127`.

**3. Produces / enforces.** Writes `.claude/refactor-plan.md`. Per-module commits. Spawns `refactor-extractor` sub-agent for 4+ modules. Invokes `/tdd` (if uncovered) and `/cr` (done step).

**4. Enforcement.** ADVISORY. The verification suite (vitest/tsc/lint/build) is model-run within the loop; structural teeth only at external pre-commit/pre-push + invoked `/cr` sentinel.

**5. Cross-references.** `/tdd`, `/cr`. `refactor-extractor` agent (`.claude/agents/refactor-extractor.md`, EXISTS). `.claude/refactor-plan.md` (plan file). CLAUDE.md → Refactoring.

---

## /queue — Multi-agent backlog runner

**1. What it is / trigger.** `queue:1-12`. Runs multiple independent `TASKS.md` tasks in parallel worktrees, then pushes + opens PRs. Trigger: `/queue`.

**2. Workflow.**
- Step 1 Identify candidates `queue:16-30` — P1 (P0 if any) tasks, non-blocked, non-overlapping scope; serialize tasks touching `supabase/migrations/`, `CLAUDE.md`, `AGENTS.md`. Present numbered list; **wait for user confirmation**. ADVISORY.
- Step 2 Preflight `queue:32-43` — verify `scripts/worktree-add.sh`, `scripts/pr.sh`, `gh`, `.env.local`. ADVISORY (model checks; stops if missing).
- Step 3 Spawn agents in parallel `queue:45-75` — branch `feat/<slug>`; `scripts/worktree-add.sh`; spawn `Agent` with `isolation: "worktree"` (note: Agent tool makes its own worktree, not the step-2 one); agent prompt template incl. mandatory `ln -sf .env.local` setup. Agents do NOT push. ADVISORY.
- Step 4 Collect results `queue:77-96` — status table; ask "Push and open PRs? [y/N]". ADVISORY.
- Step 5 Push + open PRs `queue:99-111` — sequentially: cd worktree, **verify `.cr-ok` == `feat/<slug>:<HEAD sha>`** (`queue:105`), `git push`, `scripts/pr.sh` (validates+consumes sentinel). If sentinel missing/stale → don't push.
- Step 6 Final summary + update TASKS.md `queue:114-133`.

**3. Produces / enforces.** Creates worktrees, branches, PRs. Verifies `.cr-ok` sentinel before push. Updates TASKS.md. Spawns one `Agent` per task (each runs its own feature loop; references `.claude/agent-contract.md`).

**4. Enforcement.** Step 5 sentinel verification is ADVISORY in the skill (a `cat .claude/.cr-ok` comparison the model runs), but it is backstopped STRUCTURALLY by `.husky/pre-push` (sentinel match) and `scripts/pr.sh` (consume). Scripts `worktree-add.sh`, `pr.sh`, `gc.sh`, `test-local.sh` all EXIST.

**5. Cross-references.** `scripts/worktree-add.sh`, `scripts/pr.sh` (EXIST). `.claude/agent-contract.md` (EXISTS). `TASKS.md`. `task-runner` agent (`.claude/agents/task-runner.md`, EXISTS — referenced in pre-push memory/CLAUDE.md as the per-task orchestrator; `queue/SKILL.md` itself spawns generic `Agent`, not `@task-runner` by name).

---

## Cross-skill overlaps (recorded, not judged)

1. **Review duplication:** `/cr` Pass 4 (layer boundaries) ⊇ `/cr-security` Pass 2 (Supabase outside `src/data/`). `cr:88` vs `cr-security:49`.
2. **`@reviewer` invoked by three skills:** `/cr` Pass 11 (4-lens, implementation mode), `/hotfix` Phase 4 (2-lens blast-radius), and `/hotfix` Phase 5 re-invokes `/cr` (→ `@reviewer` again). `cr:143`, `hotfix:201`, `hotfix:249`.
3. **Red-green-implement loop defined in three places:** `/tdd` (Steps 3-4), `/dev` (Phases 1-2), `/feature` (per-tier "Implement → /tdd"). `/dev` and `/feature` both delegate to `/tdd` but also restate the loop in prose.
4. **Doc-update step in three places:** `/cr` Pass 7 (doc drift), `/dev` Phase 4 (doc-updater agent), `/feature` done-criteria (doc sync). Plus the `doc-updater` agent.
5. **Sentinel `.claude/.cr-ok`:** written only by `/cr` (Step 7); verified by `/queue` Step 5, `.husky/pre-push`, `scripts/pr.sh`. `/cr-security`, `/tdd`, `/dev`, `/feature`, `/hotfix`, `/refactor` write NO sentinel — they rely on invoking `/cr` to produce it.
6. **`/cr` is the universal review hub:** invoked by `/dev` (Phase 3), `/feature` (all tiers), `/hotfix` (Phase 5), `/refactor` (done step). It is the single chokepoint that produces the structurally-enforced push sentinel.

---

## Claim-vs-reality summary (all flags)

| Claim / reference | Location | Reality |
|---|---|---|
| `/simplify` skill | `feature:13,52,53,70,88,115` | **NOT in `.claude/skills/`, NOT in `~/.claude/skills/`.** A global/built-in skill named `simplify` is listed in the harness skill list. Project path absent. |
| `/grill-with-docs` | `feature:11,52-54,83` | Not in `.claude/skills/`; EXISTS in `~/.claude/skills/grill-with-docs`. |
| `/to-issues` | `feature:11,53-54,110-111` | Not in `.claude/skills/`; EXISTS in `~/.claude/skills/to-issues`. |
| `/cr` "9 review agents plus adversarial" | `cr:51,143` | 9 analytical passes (1–9) + Pass 11 adversarial. ✅ |
| `/cr` Pass numbering | `cr:60-151` | **No Pass 10** — jumps 9 → 11. Factual gap in doc. |
| 4 lens agents (`@lens-*`) | `cr:145,151`; `reviewer.md:43-46` | All four files EXIST: `lens-assumption`, `lens-composition`, `lens-cascade`, `lens-abuse`. ✅ |
| `@reviewer` agent | `cr:149`, `hotfix:201` | EXISTS (`.claude/agents/reviewer.md`). ✅ |
| `@reviewer` blast-radius (2-lens) mode | `hotfix:202-216` | `reviewer.md` defines only Design + Implementation (4-lens) modes — **no 2-lens blast-radius mode**. Mismatch. |
| `@hotfix-guard` agent | `hotfix:272,280` | EXISTS (`.claude/agents/hotfix-guard.md`). ✅ |
| `refactor-extractor` agent | `extract-module.md:121` | EXISTS (`.claude/agents/refactor-extractor.md`). ✅ |
| `/cr` UNATTENDED/autoMode branching | (searched) | **None present** in `cr` or `cr-security` SKILL.md. |
| `.cr-ok` sentinel | `cr:248`; `queue:105`; pre-push; pr.sh | Path `.claude/.cr-ok`. Written by `/cr`; structurally validated by `.husky/pre-push:56-72` and consumed by `scripts/pr.sh:31-45`. ✅ |
| `.claude/agent-contract.md`, `TASK-TEMPLATE.md`, `.claude/INDEX.md` | `feature:14,56`; `queue:58` | All EXIST. ✅ |
| scripts `pr.sh`, `worktree-add.sh`, `gc.sh`, `test-local.sh` | queue, cr | All EXIST. ✅ |
| `task-runner` agent (referenced for /queue) | env/CLAUDE.md | EXISTS, but `/queue` SKILL.md spawns generic `Agent`, not `@task-runner` by name. |

## Structural vs advisory — bottom line

- **STRUCTURAL (actually block):** `.husky/pre-commit` (lint + tsc + test:unit, `pre-commit:3-5`); `.husky/pre-push` (.env.local present, merged-PR block, `.cr-ok` branch:sha match on agent path, then `npm run test` + `npm run build`, `pre-push:22-76`); `scripts/pr.sh` (sentinel validate+consume). `settings.json` deny on `Edit/Write(/.claude/hooks/**)` (referenced by `cr:201-205`, outside A1 slice).
- **ADVISORY (model-honored only):** every numbered step inside all eight skill bodies, including all `/cr` passes, the `@hotfix-guard` "will not pass" gate, the `/feature` `/to-issues` STOP gate and human-approved spec gate, and every sub-agent spawn. The skills produce one structurally-enforced artifact: the `.claude/.cr-ok` sentinel, written only by `/cr`.
