# Pass A1 — Governance Documents Inventory

FACT-ONLY ground-truth map of the harness governance layer. Records what exists and what each
document claims. No evaluation, no recommendations.

Slice files (read in full):
- `CLAUDE.md`
- `AGENTS.md`
- `.claude/SOUL.md`
- `.claude/agent-contract.md`
- `.claude/INDEX.md`
- `.claude/AI-WORKFLOW.md`

Enforcement legend used throughout:
- **STRUCTURAL** — a hook, CI job, git mechanism, or script actually blocks/executes.
- **ADVISORY** — a markdown instruction the model is asked to follow; nothing enforces it.

---

## Verified harness inventory (cross-reference ground truth)

Checked once here; cited by document sections below.

Confirmed PRESENT:
- Docs: `CONTEXT.md`, `PITFALLS.md`, `TASKS.md`, `docs/TESTING.md`, `.claude/memory.md`,
  `.claude/rituals.md`, `.claude/TASK-TEMPLATE.md`, `docs/solutions/README.md`,
  `docs/adr/README.md`, `docs/planning/02-schema.md`, `03-security.md`, `04-implementation.md`,
  `05-renderer-scope.md`, `docs/design/tokens.md`, `docs/design/components.md`, `.claude/mcp.md`.
- Routing/config: `proxy.ts` (root), `.mcp.json`.
- Scripts: `scripts/gc.sh`, `scripts/worktree-add.sh`, `scripts/pr.sh`, `scripts/test-local.sh`.
- Claude hooks (`.claude/hooks/`): `block-dangerous-git.sh`, `block-npm-install.sh`,
  `permission-logger.sh`, `session-start.sh`, `worktree-create.sh`.
- Settings: `.claude/settings.json`, `.claude/settings.local.json`.
- Git hooks (`.husky/`, `core.hooksPath=.husky/_`): `pre-commit`, `pre-push`, `post-checkout`.
- CI: `.github/workflows/ci.yml`, `.github/workflows/integration.yml`.
- Skills present locally: `feature`, `design`, `tdd`, `cr`, `cr-security`, `compound`, `queue`,
  `incident`, `hotfix`, `migrate`, `behavior-change`, `perf`.

Confirmed ABSENT:
- `.claude/agentic-system-enabled` — ABSENT. (Gating flag referenced by SOUL.md /compound auto-run
  language and by the doc-updater agent description.)
- `middleware.ts` — ABSENT (routing uses `proxy.ts`; consistent with CLAUDE.md naming `proxy.ts`).
- `.claude/skills-lock.json` — ABSENT (referenced in CLAUDE.md "Keeping docs current" table).
- Local skill dirs `grill-with-docs`, `to-issues`, `simplify` — ABSENT locally. INDEX.md itself
  declares these as required GLOBAL installs (not in-repo), so absence is documented, not a gap.

Enforcement-mechanism ground truth (used by every doc's enforcement column):
- **pre-commit** (`.husky/pre-commit`): runs `npm run lint`, `npx tsc --noEmit`, `npm run test:unit`,
  `set -e`. STRUCTURAL, blocking per commit.
- **pre-push** (`.husky/pre-push`): `set -e`; all-deletions short-circuit; requires `.env.local`;
  blocks if branch's PR already merged (via `gh pr list`); interactive path = TTY `/cr` prompt;
  non-interactive (agent) path = detached-HEAD guard + `.claude/.cr-ok` sentinel check
  (`BRANCH:SHA`, blocks if missing/empty/stale); then `npm run test` + `npm run build`. STRUCTURAL.
  Note: sentinel is validated, NOT consumed by pre-push; comment says `scripts/pr.sh` is sole consumer.
- **CI** (`ci.yml`): on PR + push to main, runs `npx tsc --noEmit`, `npx eslint .`,
  `npm run test:unit`. STRUCTURAL, blocking on merge.
- **settings.json hooks**: `SessionStart` → `session-start.sh`; `PreToolUse` → `block-dangerous-git.sh`
  + `block-npm-install.sh` (and `permission-logger.sh`, `worktree-create.sh`); `Stop` → sound only.
  STRUCTURAL for the dangerous-git / npm-install guards.

---

## CLAUDE.md

### 1. What it is / stated purpose
"Process rules and coding discipline for this repo." (CLAUDE.md:3). Defers product context,
architecture, scope, open decisions to AGENTS.md (CLAUDE.md:4). The session-bootstrap and
discipline rulebook.

### 2. Concrete rules / mechanisms (with enforcement classification)

**Session-start rituals (CLAUDE.md:5–9)**
- Read `.claude/memory.md`, `TASKS.md`, `.claude/rituals.md`, `.claude/SOUL.md` at session start;
  surface any ritual whose `last_run` > 7 days (line 5). ADVISORY. All four target files PRESENT.
- Run `git fetch --prune --quiet && git branch -vv | grep ': gone]'`; if branches listed, run
  `scripts/gc.sh` before other work (line 6). ADVISORY instruction; `scripts/gc.sh` PRESENT.
- When a mistake is corrected, add a rule to `.claude/memory.md` before session end (line 5). ADVISORY.
- Classify work state on first message; name it if not explicit (line 7). ADVISORY. (Restated in
  AI-WORKFLOW.md "Choosing the right work state" — OVERLAP.)
- Worktree-before-commit rule: if cwd is repo root with uncommitted/unfinished prior work, create a
  worktree via `scripts/worktree-add.sh` before proceeding; sessions must not share a branch
  (lines 8–9). ADVISORY in this doc. Partial STRUCTURAL backstop: `worktree-create.sh` is wired as a
  hook in settings.json; `scripts/worktree-add.sh` PRESENT.

**Project overview / stack (CLAUDE.md:13–37)**
- Tech stack list; "Do NOT introduce: Redux, React Query (deferred), class components, CSS modules"
  (line 37). ADVISORY.

**Commands (CLAUDE.md:43–46)** — `npm run dev/test/build/lint`. Reference only.

**The discipline rule (CLAUDE.md:50–63)** — three questions answerable before committing AI code;
"If you cannot answer all three, do not commit." ADVISORY (self-attestation).

**Before writing code (CLAUDE.md:67–84)** — a MUST list:
- Read `.claude/memory.md`, skim `docs/solutions/README.md`, `docs/adr/README.md`, read `PITFALLS.md`
  (lines 69–72). ADVISORY. All targets PRESENT.
- If task touches Supabase → invoke `/supabase` skill before writing code (line 73). ADVISORY trigger.
- `/notion-sync`, `/debug` invocation triggers (lines 74–76). ADVISORY.
- Define props/inputs/returns/forbidden/done before starting (line 77). ADVISORY.
- Confirm MVP scope, surface open decisions, ask before installing npm packages (with required
  metadata), ask on ambiguity (lines 78–82). ADVISORY. (npm-install has a STRUCTURAL backstop —
  see `block-npm-install.sh` below.)

**Agent behavior principles (CLAUDE.md:88–110)** — Honest assessment; build what's needed now;
research before guessing; 3-pass research for deep unknowns. ALL ADVISORY. (OVERLAP with SOUL.md
values "Honesty over momentum," "Simplicity over completeness," and CLAUDE.md "Research before
guessing" ≈ memory-driven research methodology.)

**Development workflow (CLAUDE.md:114–205)**
- Pure-function TDD: test must fail first (`npx vitest run`), minimum impl, all green; "NEVER write
  implementation before tests exist for a new pure function"; `/dev` runs the loop (lines 118–127).
  ADVISORY (no hook enforces test-first ordering); pre-commit runs `test:unit` but cannot prove
  test-first. (OVERLAP with AI-WORKFLOW "Commit discipline" + `/tdd` skill.)
- Refactoring two rules: tests-before-movement, two-hats (lines 131–139). ADVISORY.
- Shipping a change pipeline (lines 143–186):
  - Step 2 pre-commit hook (ESLint, `tsc --noEmit`, unit tests) — STRUCTURAL, matches `.husky/pre-commit`.
  - Step 3 `/cr` before pushing; writes `.cr-ok` sentinel (lines 161–172). `/cr` invocation ADVISORY;
    the sentinel it writes is STRUCTURALLY checked by pre-push (agent path).
  - Step 4 pre-push hook: interactive prompt vs. agent sentinel `branch:sha`; all tests + `next build`
    (lines 176–181). STRUCTURAL, matches `.husky/pre-push`.
  - Step 5 `scripts/pr.sh` validates+consumes `.cr-ok` then calls `gh pr create` (lines 183–185).
    STRUCTURAL (script PRESENT; pre-push comments confirm pr.sh is the sentinel consumer).
  - Step 6 CI blocks merge (line 188). STRUCTURAL, matches `ci.yml` (note: ci.yml runs `test:unit`,
    not full integration; integration is a separate `integration.yml` workflow — see claim-vs-reality).
  - "NEVER push or open a PR without running /cr" (line 190). ADVISORY; backed by sentinel STRUCTURAL.
  - Background-agent Bash permission rule: every required pattern must be in `permissions.allow` in
    `.claude/settings.json` before spawning (lines 192–205). ADVISORY (settings.json PRESENT).

**Keeping docs current (CLAUDE.md:209–229)** — table mapping change-type → doc to update in the same
commit. References `.claude/skills-lock.json` (line 227) — ABSENT (claim-vs-reality). All ADVISORY.

**TypeScript rules (CLAUDE.md:233–245)** — no `any`, no `@ts-ignore`/`@ts-expect-error`, no `as`
without narrowing, Zod at boundaries, `z.infer<>` derivation, named-interface props. ADVISORY in doc;
`tsc --noEmit` (pre-commit + CI) STRUCTURALLY catches type errors but NOT the `any`/`as`/comment
stylistic bans unless an ESLint rule does. (OVERLAP with agent-contract.md anti-patterns and the
NEVER list.)

**Architecture rules (CLAUDE.md:249–280)** — components I/O-only; business logic in pure functions;
Supabase queries only in `src/data/`; never call Supabase client from component/page/layout; server
components/actions call `src/data/` directly; split two-purpose functions; rule-of-three before
abstraction; status transitions via Postgres triggers; `proxy.ts PUBLIC_PATHS` pages at root route
level; every route group + layout level needs colocated `error.tsx`; `cache()` for dual-callsite data
fns; relative-path import rule for `app/(app)/*/actions.ts`; RBAC enforced only at `src/data/` TS
layer, never RLS. ALL ADVISORY (no structural enforcement of layering). `proxy.ts` PRESENT.

**File and export conventions (CLAUDE.md:284–302)** — export defaults vs named; file naming
(PascalCase/camelCase); `@/` alias from `src/`; schema file-vs-folder collision ban. ADVISORY.

**Code style (CLAUDE.md:306–313)** — no what-comments, one-line why-comments only, no multi-line
comment blocks/docstrings, `cn()` for conditional Tailwind, no manual class concatenation. ADVISORY.
(OVERLAP: "no comments describing what code does" restated in agent-contract.md:131.)

**Testing (CLAUDE.md:317–331)** — Vitest, colocated tests; unit tests for pure fns; integration tests
against real Supabase; NEVER mock the DB; auth-method spying allowed for error-routing; no snapshot
tests; `.env.local` → prod warning; `npm run test:local` via `scripts/test-local.sh`. ADVISORY;
`scripts/test-local.sh` PRESENT. (OVERLAP with AGENTS.md "Testing and CI" section + memory entries.)

**Migrations (CLAUDE.md:335–342)** — REVOKE EXECUTE after every CREATE OR REPLACE FUNCTION; no
`CONCURRENTLY` inside migration; rollback path for destructive ops; invoke `/supabase` before any
migration. ALL ADVISORY.

**Safe-change rules (CLAUDE.md:346–356)** — never modify `next.config.ts`/`tsconfig.json` without
explaining first; never silently delete a file; `images.remotePatterns` requirement; redirect-URL
uses only `resolved.pathname`. ADVISORY.

**Destructive-operation rules — "PocketOS incident, 2026-04-25" (CLAUDE.md:358–372)** — explicit
header "System prompts are advisory — they can be violated. Enforcement must live here." (line 360).
Rules: no destructive/irreversible op (DELETE/DROP/TRUNCATE/`rm`/`git reset --hard`/`git push --force`/
curl mutations/mutating RPC) without same-turn explicit instruction naming exact resource; no
credential reuse from unrelated files; never assume tokens are scoped; never treat staging as isolated;
state target+reversibility before mutating external API calls; treat unknown-reversibility as
irreversible and stop. ADVISORY by the doc's own admission, BUT partial STRUCTURAL backstop:
`block-dangerous-git.sh` (PreToolUse hook) blocks dangerous git ops. (OVERLAP with the NEVER list
lines 521–528 and SOUL.md "Stop and surface, never route around" + agent-contract.md anti-pattern.)

**Commit and PR workflow (CLAUDE.md:376–413)** — only commit this conversation's changes; move to
worktree if main has prior changes; `git worktree remove` when done; post-merge local+tracking ref
cleanup (`git branch -d` + `git remote prune origin` / `scripts/gc.sh`); background-agent allow-list
rule (restated); conventional commits with required body; squash merge; no unrelated changes.
ADVISORY. (OVERLAP with AI-WORKFLOW worktree lifecycle table + commit discipline.)

**Before finishing (CLAUDE.md:507–510)** — `tsc --noEmit` zero errors; no unused imports/dead
code/placeholder comments; no silently resolved open decisions. ADVISORY; `tsc` STRUCTURALLY checked.

**NEVER list (CLAUDE.md:514–530)** — 17 negative rules consolidating the above (any/ts-ignore/as,
no dep install, no business logic in component, no Supabase from component, no DB mock, no scope
expansion, no unilateral decision resolution, no dead code, no dual type/schema, destructive-op +
token rules, worktree removal, background-agent allow-list). ADVISORY restatement.

### 3. Cross-references
AGENTS.md (lines 4, 78–79); `.claude/memory.md`, `TASKS.md`, `.claude/rituals.md`, `.claude/SOUL.md`
(line 5); `scripts/gc.sh` (line 6), `scripts/worktree-add.sh` (line 8), `scripts/pr.sh` (line 183),
`scripts/test-local.sh` (line 329); `PITFALLS.md` (lines 6, 72); `docs/solutions/README.md`,
`docs/adr/README.md` (lines 70–71); skills `/supabase` `/notion-sync` `/debug` `/dev` `/cr`
`/cr-security` `/refactor` `/tdd` `/migrate`; hooks pre-commit + pre-push (lines 155, 176); CI
`.github/workflows/ci.yml` (line 188); `proxy.ts` (lines 273, 357); `.claude/settings.json`
(lines 195, 412); `.claude/skills-lock.json` (line 227 — ABSENT); `docs/specs/`, `docs/design/`,
`.claude/mcp.md` (doc-current table).

### 4. Overlaps observed
- Work-state classification (line 7) ↔ AI-WORKFLOW "Choosing the right work state" table.
- Worktree lifecycle / post-merge cleanup (lines 8–9, 380–399) ↔ AI-WORKFLOW lifecycle table (39–58).
- Destructive-op + token rules (358–372) ↔ NEVER list (521–528) ↔ SOUL.md "Stop and surface" ↔
  agent-contract.md anti-pattern (133) + bypass-retry (155–157).
- TypeScript/no-`any`/no-DB-mock/no-what-comments ↔ agent-contract.md anti-patterns (129–132).
- TDD requirement ↔ AI-WORKFLOW commit discipline + `/tdd` skill.
- Testing rules ↔ AGENTS.md "Testing and CI."
- Pipeline (/cr before push) ↔ SOUL.md "The pipeline is not optional" ↔ AI-WORKFLOW skills table ↔
  agent-contract.md PIPELINE REQUIREMENT.

### 5. Claim-vs-reality flags
- `.claude/skills-lock.json` (line 227) — ABSENT.
- Step 4 claims pre-push runs "All tests (unit + integration, hits real database)" (line 178). The
  pre-push hook runs `npm run test` (not explicitly `test:integration`) then `npm run build`;
  whether `npm run test` includes integration depends on package.json script wiring (not verified in
  this slice). FLAG: partial — `next build`/`npm run build` confirmed in hook; "integration" claim
  unverified against the `test` script definition.
- Step 6 / CI claim "runs tsc, lint, and vitest" (line 188) — CONFIRMED for `ci.yml` but it runs
  `npm run test:unit` specifically; a separate `.github/workflows/integration.yml` exists (PRESENT)
  and is not mentioned in CLAUDE.md's CI description.
- All referenced scripts, hooks, and the four session-start files: CONFIRMED PRESENT.

---

## AGENTS.md

### 1. What it is / stated purpose
"Product context, architecture, scope, and open decisions for event-vendor." (AGENTS.md:3). Defers
process rules to CLAUDE.md (line 4). It is primarily a product/architecture reference, but it carries
binding decision records that act as governance constraints.

### 2. Concrete rules / mechanisms (governance-relevant; product detail summarized)
- **Design-system gate (8–17):** "All UI work must reference the design files before writing any
  component or style"; conform to `docs/design/tokens.md` + `components.md`; "Deviate only if
  explicitly instructed." ADVISORY. Both design files PRESENT.
- **Project identity / target state (21–37):** multi-vendor SaaS; single-vendor assumptions must be
  flagged and generalized before a second vendor. ADVISORY constraint.
- **Proposal structure / typography / stack / data flow / routing (40–117):** reference tables.
  Routing table cites `proxy.ts PUBLIC_PATHS` semantics indirectly; `/p/[token]` via
  `get_proposal_by_share_token` RPC. ADVISORY/reference.
- **"What exists in the codebase" (119–295):** exhaustive file-by-file inventory of layouts, shell,
  proposal components, routes, `src/data/`, `src/lib/`, schemas, types, testing/CI, utils, constants,
  migrations 0001–0070. Reference inventory (not rules). Notable governance line: "vitest.setup.ts
  Mocks @/lib/supabaseServer to return a service_role client — bypasses RLS" (244) — documents the
  DB-mock exception relative to CLAUDE.md "NEVER mock the database."
- **Golden exemplars (299–312):** "Before writing a new file in any layer, read the canonical example
  first." Table of canonical files per layer. ADVISORY.
- **Images (316–334):** `next/image` for all images; add Supabase domain to `next.config.ts`
  remotePatterns; restates the "never modify next.config.ts without explaining" safe-change rule
  (334). ADVISORY. (OVERLAP with CLAUDE.md safe-change rules.)
- **MVP scope (338–352):** in-scope / out-of-scope lists. Binding scope constraint referenced by
  CLAUDE.md "confirm task fits MVP scope." ADVISORY.
- **Open decisions (356–375):** "A ticket that depends on one of these cannot run until it is
  resolved here first. Do not invent answers — surface them and ask." Currently "_None open._" (361)
  but two narrative open items follow (event_type enum expansion 363–368; Payer ≠ booker 370–375).
  CLAIM-vs-INTERNAL inconsistency flagged below. ADVISORY governance gate. (OVERLAP with
  agent-contract STOP-AND-SURFACE + SOUL "Honesty over momentum.")
- **Resolved decisions (379–415):** large table of locked decisions (approval model, role model,
  change-request flow, tax/labor defaults, snapshot consistency, editor UX, etc.). Binding "do not
  re-litigate" records. ADVISORY.
- **Rejected Patterns (419–426):** "Role checks in RLS policies" rejected. ADVISORY. (OVERLAP with
  CLAUDE.md Architecture "RBAC at src/data/ only, never RLS" + Resolved "Role enforcement location.")
- **Known limitations of v1 data layer (430–439):** catalog fuzzy search, tests don't exercise RLS,
  updateProposal writes no revision row — each with upgrade path. Reference.
- **Proposal renderer layout (443–463):** long-scroll mobile-first decision; section order. ADVISORY.
- **How we work (467–474):** double-check assumptions; hold scope; name drift; accuracy over comfort;
  ask clarifying questions; surface open decisions never resolve unilaterally. ADVISORY. (OVERLAP with
  SOUL.md values + agent-contract anti-patterns + CLAUDE.md NEVER "no unilateral decision.")

### 3. Cross-references
`docs/design/tokens.md`, `docs/design/components.md` (12–17, 57, 123); CLAUDE.md (4, 334);
`docs/planning/02-schema.md` (283, 402), `03-security.md` (404, 438), `04-implementation.md` (102),
`05-renderer-scope.md` (383); migrations `supabase/migrations/` 0001–0070; `next.config.ts` (320–334);
external data dump path `/Users/tanner/Documents/Claude/Projects/...` (364, referenced — outside repo).

### 4. Overlaps observed
- RBAC/role enforcement location appears 3× within AGENTS.md (Resolved 405, 387; Rejected 426) and
  in CLAUDE.md Architecture — OVERLAP across and within docs.
- "Surface open decisions, never resolve unilaterally" ↔ CLAUDE.md NEVER ↔ SOUL.md ↔ agent-contract.
- Testing/CI inventory (239–251) ↔ CLAUDE.md Testing section.
- next.config.ts safe-change (334) ↔ CLAUDE.md safe-change rules.

### 5. Claim-vs-reality flags
- "Open decisions … _None open._" (361) immediately followed by two substantive open decisions
  (event_type enum 363–368; payer model 370–375). INTERNAL INCONSISTENCY flag (the "None open"
  banner contradicts the two entries below it).
- Referenced `docs/planning/*.md` (02/03/04/05) — all CONFIRMED PRESENT.
- Migrations described 0001–0070 — file count not enumerated in this slice (out of A1 scope); the
  prose claims squashed stubs `_squashed_into_0030.sql` for 0021/0026 (285) — not verified here.
- External data-dump path (364) is outside the repo — unverifiable from repo.

---

## .claude/SOUL.md

### 1. What it is / stated purpose
"The engineering character of this system." (SOUL.md:5). Explicitly NOT process rules (CLAUDE.md),
NOT architecture (AGENTS.md), NOT domain knowledge (CONTEXT.md) (lines 6–7). "Read this before
starting any work. When a judgment call arises that no hook can make, the answer lives here." (9–10).
States it is "the only file that applies everywhere, always" (82).

### 2. Concrete rules / mechanisms
All values/principles — ADVISORY by definition (the doc frames itself as the judgment-call fallback
where no hook applies):
- **North star (14–23):** "World-class code is simple to extend, maintain, debug at 2 AM"; deep
  modules; cleverness is a liability. ADVISORY.
- **What this agent values (27–49):** Simplicity over completeness; Deep modules; Honesty over
  momentum (stop and surface); Diligence over urgency; Auto-improvement as default (memory.md entry on
  failure, compound captures patterns, fix skill descriptions). ADVISORY.
- **Never compromises on (53–75):** Stop and surface never route around; Touch only what you're asked
  (flag don't fix); Push back when warranted; Prefer boring/obvious; "The pipeline is not optional —
  /cr runs before every push. On projects with the agentic system enabled, /compound runs
  automatically. Memory capture is a manual step at session close." (71–74). The /cr-before-push
  clause has a STRUCTURAL backstop (pre-push sentinel + scripts/pr.sh); the rest ADVISORY.
- **What gets updated (79–85):** SOUL.md reviewed during /compound; new cross-project principles
  belong here; updates go through the same human-review gate as memory.md — "The agent proposes in
  the compound-draft file. The human confirms. Nothing is written automatically." ADVISORY process.

### 3. Cross-references
CLAUDE.md, AGENTS.md, CONTEXT.md (6–7); `memory.md` (45, 73, 84); `/cr` (71); `/compound` (72, 80);
"agentic system enabled" gate (72) → `.claude/agentic-system-enabled` flag.

### 4. Overlaps observed
- "Stop and surface, never route around" (54) ↔ CLAUDE.md destructive-op rules + NEVER ↔
  agent-contract STOP AND SURFACE.
- "Touch only what you're asked" (59) ↔ AGENTS.md "hold scope" ↔ CLAUDE.md NEVER "no scope
  expansion" ↔ agent-contract SCOPE.
- "Simplicity over completeness" / "build what's needed now" ↔ CLAUDE.md "Build what's needed now"
  (98) — near-verbatim duplicate principle.
- "The pipeline is not optional / /cr before every push" ↔ CLAUDE.md shipping pipeline ↔ AI-WORKFLOW
  skills table.
- Auto-improvement (memory.md on failure, /compound) ↔ CLAUDE.md "Keeping docs current" + session-start
  memory rules.

### 5. Claim-vs-reality flags
- "On projects with the agentic system enabled, /compound runs automatically" (72). The gating flag
  `.claude/agentic-system-enabled` is ABSENT in this repo. So by SOUL.md's own condition, automatic
  /compound is NOT enabled here. The same flag gates the `doc-updater` agent ("Only runs on projects
  with .claude/agentic-system-enabled"). CONFIRMED-ABSENT.
- `/cr` and `/compound` skills — PRESENT.

---

## .claude/agent-contract.md

### 1. What it is / stated purpose
"Template for every sub-agent prompt spawned from this repo." Self-contained brief so a sub-agent
needs no parent history (agent-contract.md:1–5). Instructs maintainers to iterate it when a sub-agent
run goes wrong (7–9).

### 2. Concrete rules / mechanisms
This is a PROMPT TEMPLATE — entirely ADVISORY (it governs how a human/parent composes a sub-agent
brief; nothing structurally validates that a spawned agent received these fields):
- **Required fields (13–119):** every field filled or `N/A` (13–16). Fields: GOAL (18–21); SCOPE —
  exact files with absolute paths, anything outside is out of scope, STOP AND SURFACE rather than
  touch (23–26); DECISIONS ALREADY MADE — cite where resolved, must not re-litigate (28–32);
  REFERENCES — cite by file:line, lists required reading incl. CONTEXT.md, AGENTS.md, CLAUDE.md,
  PITFALLS.md, design docs, Zod schemas, `docs/TESTING.md`, `docs/solutions/` (34–45); TDD REQUIREMENT
  — "TDD required" vs "TDD N/A"; confirmed behavior in TESTING.md before code (47–51); PIPELINE
  REQUIREMENT — `/cr` all tasks, `/cr-security` if auth/RLS/db boundary; agent runs pipeline in own
  context and reports MUST FIX (53–60); BRANCH — worktree branch `<working-branch>/<short-task-slug>`,
  conventional commits, does not push (62–66); PARALLEL CANDIDATES — list parallelizable parts, don't
  default to sequential (68–72); STOP AND SURFACE — 8 trigger conditions incl. open decision touched,
  domain not in CONTEXT.md, migration needed, test fails after one retry, missing dependency, scope
  wrong, CLAUDE.md NEVER would be violated, destructive op required (74–84); SUMMARY FORMAT — exact
  required structure (Result/Files/Decisions/Tests/Pipeline/Surfaced/Notes) (86–119).
- **Anti-patterns the agent must avoid (123–133):** resolving open decision unilaterally; editing
  outside SCOPE without surfacing; reporting done with MUST FIX remaining; skipping the pipeline tier;
  `any`/`@ts-ignore`/`as` without narrowing; mocking the DB; what-comments; bundling unrelated changes;
  destructive op without same-turn instruction. ADVISORY.
- **MUST FIX retry policy (137–157):** 3 stages (re-prompt original once → fresh no-context agent once
  → surface to user). Bypass retry / surface immediately when MUST FIX touches open decision, requires
  migration/schema, requires architectural redesign, violates CLAUDE.md NEVER, points to pre-existing
  bug, or involves destructive op (149–157). ADVISORY orchestration protocol.

### 3. Cross-references
CONTEXT.md (39); AGENTS.md → Responsibilities/Layer rules/Resolved/Open Decisions (31, 41, 77, 80, 84,
125, 152); CLAUDE.md → NEVER (82, 130, 155); PITFALLS.md (42); `docs/design/tokens.md`,
`components.md` (43); `docs/TESTING.md` (44, 51); `docs/solutions/` (45); `/cr`, `/cr-security` (56–58).

### 4. Overlaps observed
- Anti-patterns (129–133) restate CLAUDE.md TypeScript rules + NEVER + Code style (no what-comments) +
  Testing (no DB mock) — heavy OVERLAP.
- STOP AND SURFACE triggers (74–84) ↔ SOUL.md "Stop and surface" ↔ AGENTS.md "surface open decisions"
  ↔ CLAUDE.md NEVER.
- PIPELINE REQUIREMENT (53–60) ↔ CLAUDE.md shipping pipeline ↔ SOUL.md "pipeline not optional" ↔
  AI-WORKFLOW skills table.
- BRANCH/commit discipline (62–66) ↔ AI-WORKFLOW commit discipline ↔ CLAUDE.md commit workflow.

### 5. Claim-vs-reality flags
- All referenced required-reading files (CONTEXT.md, AGENTS.md, CLAUDE.md, PITFALLS.md, design docs,
  docs/TESTING.md, docs/solutions/) — CONFIRMED PRESENT.
- `/cr`, `/cr-security` skills — PRESENT.
- The contract is not itself wired to any hook/CI — there is no structural check that a spawned
  sub-agent actually conformed to this template (consistent with its stated nature). No false claim.

---

## .claude/INDEX.md

### 1. What it is / stated purpose
"Annotated index of external resources for this project." Check here before asking when context isn't
in the repo; read annotations rather than opening every link (INDEX.md:1–8).

### 2. Concrete rules / mechanisms (all ADVISORY — it is a resource directory)
- **This repo (12–16):** path + worktree naming `event-vendor_<branch-slug>`. (OVERLAP with AI-WORKFLOW
  naming convention — NOTE: AI-WORKFLOW uses `event-vendor_branch-slug`; CLAUDE.md session rule line 8
  references repo root `event-vendor/`.)
- **External docs (20–49):** Next.js App Router, Supabase JS client, Supabase SSR, Zod v4, Vitest,
  Tailwind v4 — each with "Read when" guidance and "prefer existing patterns first." ADVISORY.
- **MCP tools (52–84):** Chrome DevTools MCP (configured in `.mcp.json`, "local project MCP") with
  when/how-to-use; Supabase MCP (claude.ai connector); Notion MCP (claude.ai connector). References
  `docs/planning/03-security.md` SQL probes and `docs/TESTING.md`. ADVISORY.
- **Required global skills (88–98):** "These skills are referenced in `.claude/skills/` but are NOT
  included in this repo." Lists `/grill-with-docs`, `/tdd`, `/to-issues`, `/simplify` from Matt
  Pocock's repo (github.com/mattpocock/skills); "Install globally, not per-project. Without these the
  /feature workflow will reference commands that don't exist." ADVISORY install instruction.
- **What does NOT belong here (102–105):** no credentials/keys, nothing requiring auth — ask the user.

### 3. Cross-references
`src/lib/supabaseServer.ts` (30); `src/data/` (30); `src/schemas/` (39); `docs/design/tokens.md`
(48); `docs/TESTING.md` (44, 66); `.mcp.json` (55); `docs/planning/03-security.md` (74); external
GitHub (github.com/mattpocock/skills, 92); `/feature` (98); skills `/grill-with-docs` `/tdd`
`/to-issues` `/simplify` (95).

### 4. Overlaps observed
- Worktree naming convention (14) ↔ AI-WORKFLOW.md naming convention (24–33) — DUPLICATE.
- External-doc "read when" guidance partially restates CLAUDE.md/AGENTS.md "prefer existing patterns"
  posture.

### 5. Claim-vs-reality flags
- `.mcp.json` — CONFIRMED PRESENT (Chrome DevTools MCP config claim).
- Required global skills `/grill-with-docs`, `/to-issues`, `/simplify` — CONFIRMED ABSENT from local
  `.claude/skills/` (matches INDEX's own statement that they are global, not in-repo). `/tdd` — present
  locally (INDEX lists it among the four "not included," but a local `tdd` skill dir exists — MINOR
  INCONSISTENCY: `/tdd` is both claimed not-in-repo AND present locally).
- `docs/planning/03-security.md`, `docs/TESTING.md` — CONFIRMED PRESENT.

---

## .claude/AI-WORKFLOW.md

### 1. What it is / stated purpose
"How to work with AI coding agents on this project." (AI-WORKFLOW.md:3). Operational playbook for
worktrees, work-state classification, task setup, skills, commit discipline.

### 2. Concrete rules / mechanisms (all ADVISORY unless noted)
- **Prerequisites (8–13):** `gh` CLI required for `scripts/pr.sh`; `.env.local` must exist in repo
  root (worktrees symlink it). ADVISORY in doc; `.env.local` presence is STRUCTURALLY enforced by the
  pre-push hook (blocks push without it). `scripts/pr.sh` PRESENT.
- **Worktrees (17–69):** use git worktrees not multiple checkouts; naming `event-vendor_branch-slug`
  "required for the Edit allowlist in settings.json"; 7-step lifecycle table (create via
  `scripts/worktree-add.sh`; open PR via `scripts/pr.sh`; remove via `git worktree remove`; delete
  branch via `git branch -d`; prune via `git remote prune origin`); `delete_branch_on_merge=true`
  removes only remote ref; `scripts/gc.sh` does steps 5–7 in bulk; bare `git worktree add` skips the
  `.env.local` symlink and breaks integration tests; rules: one window per worktree, never
  `git checkout` in shared dir, remove after merge, worktree-before-code on resumed sessions.
  ADVISORY; scripts PRESENT; `worktree-create.sh` hook gives partial STRUCTURAL support.
- **Choosing the right work state (73–95):** signal → work-state → entry-point table (Incident/Hotfix/
  Feature/Parallel/Migration/Behavior change/Performance/Dependency/Ambiguous/Resumption/Exploratory),
  with re-classify-at-each-transition rule. ADVISORY.
- **Starting a task (99–107):** copy `.claude/TASK-TEMPLATE.md`, fill every field, hand to agent.
  ADVISORY; `TASK-TEMPLATE.md` PRESENT.
- **Skills (111–133):** skill → when table (`/feature` `/design` `/grill-with-docs` `/tdd`
  `/cr-security` `/cr` `/compound` `/to-issues` `/simplify` `/queue` `/incident` `/hotfix` `/migrate`
  `/behavior-change` `/perf`). ADVISORY.
- **Agent context files (137–149):** table mapping CLAUDE.md / AGENTS.md / CONTEXT.md / memory.md /
  PITFALLS.md / docs/TESTING.md / docs/solutions/ / docs/planning/ / INDEX.md to what each covers.
  ADVISORY directory.
- **Commit discipline (153–163):** unit of work = one behavior; one behavior = one spec = one commit;
  test+impl same commit; conventional commits; body required (why not what); each commit leaves tests
  green; "A commit that can't be reviewed in under a minute is too large." ADVISORY.

### 3. Cross-references
`scripts/pr.sh` (11, 43), `scripts/worktree-add.sh` (41, 54), `scripts/gc.sh` (52); `.env.local`
(12, 54); `settings.json` (35 ref via "Edit allowlist"); `PITFALLS.md → post-merge-local-branch-
persists` (51) and `→ worktree-env-local-not-inherited` (56); `.claude/TASK-TEMPLATE.md` (103); all
skills in table; CLAUDE.md, AGENTS.md, CONTEXT.md, `.claude/memory.md`, PITFALLS.md, docs/TESTING.md,
docs/solutions/, docs/planning/, `.claude/INDEX.md` (140–149).

### 4. Overlaps observed
- Worktree naming + lifecycle (17–69) ↔ INDEX.md (14) ↔ CLAUDE.md commit-and-PR workflow (380–399) +
  session-start gc rule (6). Triple OVERLAP on worktree/cleanup discipline.
- Commit discipline (153–163) ↔ CLAUDE.md commit workflow (404–413) + TDD (118–127).
- Skills table (111–133) ↔ CLAUDE.md before-writing-code triggers + SOUL pipeline + agent-contract
  PIPELINE.
- Agent context files table (137–149) ↔ partially restates CLAUDE.md session-start reading list and
  agent-contract REFERENCES.
- Work-state classification (73–95) ↔ CLAUDE.md line 7 ("classify the work state").

### 5. Claim-vs-reality flags
- `scripts/pr.sh`, `scripts/worktree-add.sh`, `scripts/gc.sh`, `.claude/TASK-TEMPLATE.md` — CONFIRMED
  PRESENT.
- PITFALLS anchors `post-merge-local-branch-persists` (51) and `worktree-env-local-not-inherited` (56)
  — referenced; `PITFALLS.md` PRESENT (specific anchors not verified in this slice).
- Skills `/grill-with-docs`, `/to-issues`, `/simplify` referenced in the skills table — ABSENT locally
  (INDEX.md documents them as required global installs; AI-WORKFLOW does not repeat that caveat, so a
  reader of AI-WORKFLOW alone would not know these are not in-repo). FLAG: referenced-but-not-local,
  caveat lives only in INDEX.md.
- `.env.local` prerequisite (12) — STRUCTURALLY backed by pre-push hook (confirmed in hook body).
