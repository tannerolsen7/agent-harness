# HARNESS-AS-IS — Authoritative Ground-Truth Map

Consolidated from the seven Pass A1 fact-only inventories (governance, build/review skills,
quality/analysis skills, knowledge/process skills, enforcement, scripts/CI, memory/findings).
This is a map, not a plan. Every entry is a verifiable fact or a verifiable absence. No
recommendations, no prioritization, no "should."

Enforcement legend used throughout:
- **STRUCTURAL** — a git hook, CI job, git mechanism, or script deterministically blocks/executes.
- **ADVISORY** — a markdown instruction the model is asked to follow; nothing blocks if skipped.

---

## 1. What the harness is

This is a single-developer AI-agent engineering harness layered onto a Next.js 16 / Supabase
proposal app (event-vendor / Fern's Flowers). It is a body of markdown governance documents
(CLAUDE.md, AGENTS.md, SOUL.md, agent-contract, INDEX, AI-WORKFLOW), a library of ~30 slash-command
"skills" that orchestrate build/review/debug/migrate/research workflows by spawning sub-agents, a
set of named sub-agents (reviewer + four adversarial lenses, explorer, investigator, incident/spike/
solution orchestrators, doc-updater, task-runner), a thin layer of deterministic enforcement (five
Claude PreToolUse/SessionStart hooks, three git hooks via Husky, six shell scripts, two CI
workflows), and a multi-file knowledge-persistence corpus (memory.md, PITFALLS.md,
RECURRING-FINDINGS.md, docs/solutions, docs/adr, rituals.md, plus the harness's own auto-memory).
The vast majority of the system is advisory markdown the model is trusted to honor; the only
deterministic spine is a single chain — `/cr` writes a `branch:sha` sentinel (`.claude/.cr-ok`),
the pre-push hook validates it, and `scripts/pr.sh` consumes it at PR-creation time — backed by
pre-commit (lint/tsc/unit) and the Bash guard hooks (dangerous-git, npm-install).

---

## 2. Component inventory

| Component | Type | One-line purpose | Status |
|---|---|---|---|
| CLAUDE.md | Governance doc | Process rules + coding discipline + session bootstrap | active |
| AGENTS.md | Governance doc | Product context, architecture, scope, open/resolved/rejected decisions | active |
| .claude/SOUL.md | Governance doc | Engineering character / judgment-call fallback | active |
| .claude/agent-contract.md | Governance doc | Sub-agent prompt template (self-contained brief) | active |
| .claude/INDEX.md | Governance doc | Annotated index of EXTERNAL resources | active |
| .claude/AI-WORKFLOW.md | Governance doc | Worktree + work-state + commit playbook | active |
| STRATEGY.md | Governance doc | Product strategy (read by setup/review/prioritize-strategy) | active |
| CONTEXT.md | Governance doc | Domain knowledge (referenced by many skills) | **phantom-referenced (ABSENT at repo root)** |
| /cr | Skill | 9-pass + adversarial pre-merge review; writes sentinel | active |
| /cr-security | Skill | 3-pass opt-in security review (no sentinel) | active |
| /tdd | Skill | One-behavior red-green-refactor slice | active |
| /dev | Skill | Phase 0–5 TDD+pipeline loop for one task | active |
| /feature | Skill | Size-tiered feature orchestration | active |
| /hotfix | Skill | Production-broken triage + fix | active |
| /refactor | Skill | Safe extract-module refactor (+ plan file) | active |
| /queue | Skill | Multi-agent parallel-worktree backlog runner | active |
| /debug | Skill | Symptom → root cause → failing test → task spec | active |
| /incident | Skill | 8-type incident classifier + router | active |
| /post-mortem | Skill | Post-hotfix analysis → PITFALLS/memory candidates | active |
| /perf | Skill | Baseline-gated performance optimization | active |
| /spike | Skill | Research → decision + TDD slice (orchestrator) | active |
| /evaluate-solution | Skill | Build-vs-buy 7-question analysis | active |
| /review-strategy | Skill | 3-lens adversarial review of STRATEGY.md | active |
| /setup-strategy | Skill | Interview → write STRATEGY.md + CLAUDE.md edit | active |
| /behavior-change | Skill | Intentional behavior change (test inversion) | active |
| /compound | Skill | Capture solved problem → docs/solutions; propose PITFALLS/memory/Notion | active |
| /notion-sync | Skill | Sync canonical Notion templates → disk | active |
| /prioritize-tasks | Skill | Weekly TASKS.md reorder vs STRATEGY.md | active |
| /explain | Skill | Teaching brief on the current diff (no review) | active |
| /design | Skill | explore/contract system-design handoff | active |
| /migrate | Skill | State-mutation migration loop (pre-flight/rollback) | active |
| /supabase | Skill | Vendor Supabase reference + security checklist | active |
| /supabase-postgres-best-practices | Skill | 33-rule Postgres reference library | active |
| dep-update | Skill dir | (intended dependency-update skill) | **empty (no SKILL.md)** |
| grill-with-docs | Skill | Pre-build design grilling (Matt Pocock) | active globally; **ABSENT in `.claude/skills/`** |
| to-issues | Skill | Decompose into GitHub issues (Matt Pocock) | active globally; **ABSENT in `.claude/skills/`** |
| simplify | Skill | Quality cleanup of diff (Matt Pocock) | global/built-in resolves name; **ABSENT in `.claude/skills/` AND `~/.claude/skills/`** |
| @reviewer | Sub-agent | Adversarial orchestrator → 4 lens agents | active |
| @lens-assumption/-composition/-cascade/-abuse | Sub-agents | Single-failure-class adversarial lenses | active (all 4 present) |
| @incident-responder | Sub-agent | Incident triage (sonnet) | active |
| @solution-evaluator | Sub-agent | Build-vs-buy researcher (sonnet) | active |
| @spike-orchestrator (+ researcher/synthesis/adversarial-verifier/user-verifier/slice) | Sub-agents | Spike pipeline | active (all present) |
| @investigator | Sub-agent | Cross-layer bug investigation (debug) | active |
| @explorer | Sub-agent | Callsite/hot-path discovery | active |
| @doc-updater | Sub-agent | Post-task doc draft (gated by agentic-system-enabled) | active (gate flag absent) |
| @hotfix-guard | Sub-agent | Hotfix 3-gate check | active |
| @refactor-extractor | Sub-agent | Per-module extraction (4+ module splits) | active |
| @task-runner | Sub-agent | Per-task /queue orchestrator; writes sentinel | active |
| strategy-lens-pm/-cto/-challenger | Sub-agents | Strategy review lenses (in skill dir) | active |
| @benchmark-runner | Sub-agent | (perf future) | **phantom-referenced (ABSENT)** |
| block-dangerous-git.sh | Claude hook (PreToolUse Bash) | Block destructive git ops | active (STRUCTURAL, jq fail-open) |
| block-npm-install.sh | Claude hook (PreToolUse Bash) | Block dependency-adding npm | active (STRUCTURAL, jq fail-open) |
| permission-logger.sh | Claude hook (PreToolUse, no matcher) | Log all tool calls to /tmp JSONL | active (observational) |
| session-start.sh | Claude hook (SessionStart) | Truncate perm-log; remote npm install | active |
| worktree-create.sh | Claude hook (WorktreeCreate) | Provision worktree + env (jq fail-closed) | active (STRUCTURAL in UNATTENDED) |
| .husky/pre-commit | Git hook | lint + tsc + test:unit per commit | active (STRUCTURAL) |
| .husky/pre-push | Git hook | env/merged-PR/sentinel gate + test + build | active (STRUCTURAL) |
| .husky/post-checkout | Git hook | npm install in fresh worktree | active |
| scripts/pr.sh | Script | Validate + consume `.cr-ok`, open PR | active (STRUCTURAL) |
| scripts/worktree-add.sh | Script | Create worktree + provision creds | active |
| scripts/gc.sh | Script | Clean merged branches/orphan worktrees | active |
| scripts/gen-local-env.sh | Script | Write local-stack .env.local (prod-key firewall) | active (STRUCTURAL) |
| scripts/test-local.sh | Script | Run vitest against 127.0.0.1 stack only | active (STRUCTURAL guard) |
| scripts/seed.ts | Script | Seed test user + demo wedding | active |
| .github/workflows/ci.yml | CI workflow | tsc + eslint + test:unit on PR/push-main | active (STRUCTURAL on merge) |
| .github/workflows/integration.yml | CI workflow | DB integration tests, manual dispatch only | active (manual only) |
| .github/dependabot.yml | CI config | (dependency updates) | **ABSENT** |
| .claude/memory.md | Knowledge file | Project corrected-mistake rules | active |
| docs/RECURRING-FINDINGS.md | Knowledge file | Occurrence-counted pipeline findings | active |
| PITFALLS.md | Knowledge file | Codebase silent-bug traps | active |
| .claude/rituals.md | Knowledge file | Recurring-maintenance last_run gating | active (several rituals stale at audit) |
| docs/solutions/ (+README, TEMPLATE) | Knowledge corpus | Solved-problem patterns (31 dated docs) | active (README index has drift) |
| docs/adr/ (+README) | Knowledge corpus | Architectural decision records (5 ADRs) | active |
| Auto-memory MEMORY.md (+51 siblings) | Knowledge store | Harness point-in-time user-scoped memory | active (self-declared 5 days stale) |
| .claude/skills-lock.json | Config | (skill lockfile referenced by CLAUDE.md) | **phantom-referenced (ABSENT)** |
| .claude/agentic-system-enabled | Gating flag | Gates auto-/compound + doc-updater writes | **phantom-referenced (ABSENT)** |
| .claude/learned-patterns.md | Knowledge file | (referenced) | **phantom-referenced (ABSENT)** |
| .claude/review-log.md | Knowledge file | (referenced) | **phantom-referenced (ABSENT)** |
| .claude/triage-inbox.md | Knowledge file | (referenced) | **phantom-referenced (ABSENT)** |

---

## 3. Enforcement model — structural vs advisory

This is the most important section. The harness presents itself as a disciplined pipeline, but only
the items in the STRUCTURAL list deterministically block. Everything else is honored by the model.

### STRUCTURAL (actually blocks)

| Mechanism | File:line | What it blocks / does |
|---|---|---|
| **pre-commit** | `.husky/pre-commit:1-6` | `set -e`; aborts the commit if `npm run lint`, `npx tsc --noEmit`, or `npm run test:unit` fails. `test:unit` = `vitest run --exclude 'src/data/**'` — integration/DB tests NOT run at commit. No `next build`. |
| **pre-push — deletion skip** | `.husky/pre-push:7-18` | All-deletion pushes (local-sha all-zeros) exit 0 — branch deletions bypass every gate. |
| **pre-push — .env.local gate** | `.husky/pre-push:22-25` | Blocks the push if `.env.local` is absent (integration tests need creds). |
| **pre-push — merged-PR guard** | `.husky/pre-push:28-35` | If `gh` present and not detached HEAD, blocks pushing to a branch whose PR is already merged. |
| **pre-push — sentinel gate (agent path)** | `.husky/pre-push:47-72` | Non-interactive: detached HEAD → block; `.claude/.cr-ok` must exist, be non-empty, and equal `${BRANCH}:${SHA}` exactly, else block as missing/empty/stale. Validates, does NOT consume. |
| **pre-push — TTY path** | `.husky/pre-push:37-46` | Interactive: prompts "Have you run /cr?"; non-`y` aborts. Does NOT check the sentinel. |
| **pre-push — test + build** | `.husky/pre-push:75-76` | After the gate: `npm run test` (full suite, hits the DB `.env.local` points at) and `npm run build`; failure aborts the push. |
| **scripts/pr.sh — sentinel consume** | `scripts/pr.sh:27-45` | Non-interactive: aborts if sentinel missing; atomically `mv`s it, validates `branch:sha`, restores+aborts on mismatch, else `rm`s it. **Sole consumer.** Then `gh pr create` (only after remote-branch existence check). |
| **block-dangerous-git.sh** | `.claude/hooks/block-dangerous-git.sh:61-97` | PreToolUse(Bash) exit 2 on: `reset --hard`, `clean`, `rebase`, `stash clear`, `branch -*D*`, `push --force*`/`-*f*`, refspec push to `main\|master\|develop`, `worktree remove` outside `.claude/worktrees/*`. |
| **block-npm-install.sh** | `.claude/hooks/block-npm-install.sh:21-37` | PreToolUse(Bash) exit 2 when an `npm` install/add-family token is followed by a package positional. Allows `npm ci`, bare `npm install`, flag-only. |
| **worktree-create.sh prod-key firewall** | `.claude/hooks/worktree-create.sh:27-32` | UNATTENDED=1: runs `gen-local-env.sh`; on failure removes the worktree and exit 1 (no prod env symlinked). jq missing → fail-CLOSED (exit 1). |
| **gen-local-env.sh prod firewall** | `scripts/gen-local-env.sh:32-40` | `set -euo pipefail`; refuses (exit 1, writes nothing) to write `.env.local` unless the resolved Supabase URL matches `http://127.0.0.1:*`. No prod fallback. |
| **test-local.sh local guard** | `scripts/test-local.sh:55-58` | Refuses to run vitest unless the URL is `http://127.0.0.1:*`. |
| **worktree-add.sh UNATTENDED** | `scripts/worktree-add.sh:15-20` | UNATTENDED=1: removes the uncredentialed worktree and exits 1 if local creds unavailable. (Default mode is best-effort: warns, does not fail.) |
| **CI ci.yml** | `.github/workflows/ci.yml:3-26` | On PR + push-to-main: `tsc --noEmit`, `eslint .`, `test:unit`. Merge-blocking depends on GitHub branch protection (not verifiable from repo files). Does NOT run integration, `next build`, or any `.cr-ok` check. |
| **settings.json guard-file deny** | `.claude/settings.json:34-47` | `Edit/Write` deny on `.claude/hooks/**`, `settings.json`, `settings.local.json`, `.claude/agents/**`, `.env*`, `supabase/config.toml`. (Path-anchoring caveat — see §8.) |

### ADVISORY (model-honored only)

Summarized by category — these are the bulk of the harness and nothing blocks if skipped:

- **All CLAUDE.md coding/architecture/TypeScript/migration/safe-change/destructive-op rules.** The
  ~17-item NEVER list, layer rules (Supabase only in `src/data/`, components I/O-only, RBAC in TS
  not RLS), `no any`/`no @ts-ignore`/`no as`-without-narrowing, REVOKE-EXECUTE and no-CONCURRENTLY
  migration rules, redirect-URL pathname rule. `tsc --noEmit` structurally catches *type errors* but
  not the stylistic/architectural bans. CLAUDE.md:360 states outright "System prompts are advisory."
- **All AGENTS.md governance constraints.** Design-system gate, MVP scope, open/resolved/rejected
  decisions, golden-exemplar reads.
- **All SOUL.md values** (by the doc's own framing — the judgment-call fallback where no hook applies).
- **All agent-contract.md fields, anti-patterns, and MUST-FIX retry policy.** Nothing validates that
  a spawned sub-agent actually received or honored the template.
- **Every numbered step inside all ~30 skill bodies.** All `/cr` passes (1–9 + 11), `/cr-security`'s
  3 passes, every red-green loop, every human-confirm gate, the `/feature` `/to-issues` STOP gate and
  human-approved-spec gate, `@hotfix-guard`'s "will not pass" (a model-spawned agent, not a hook),
  `/spike`/`/migrate`/`/perf`/`/behavior-change` phase gates and sign-offs.
- **The `autoMode` lists in settings.json** (`settings.json:6-32`): `environment`/`allow`/`soft_deny`/
  `hard_deny` are natural-language directives consumed by the autonomous-mode classifier, NOT
  deterministic regex gates. `hard_deny` force-push overlaps the deterministic git-hook arm; the rest
  (no DROP/TRUNCATE/DELETE-without-WHERE against prod) has no shell-level backstop.
- **All ritual cadence and session-start reading rules.** Surfacing stale rituals is the nearest
  thing to enforcement and lives in CLAUDE.md, not in any hook.
- **All knowledge-persistence writes that are "propose only"** — `/compound` proposing PITFALLS/
  memory/settings/Notion; `/post-mortem` candidates; memory.md session-end additions.

### The single most important structural mechanism

The **`.cr-ok` sentinel chain** is the one deterministic mechanism that ties the entire advisory
review pipeline to a hard gate: `/cr` writes `branch:sha` → `.husky/pre-push` validates it → `scripts/
pr.sh` consumes it. Its one known hole is the **Node 8.5(c) gap**: CI never verifies the sentinel
(`grep -c "cr-ok"` = 0 in both ci.yml and integration.yml, and the file is gitignored so it never
reaches the CI runner), so any path bypassing the local hook — `git push --no-verify`, an
environment without `.husky` installed, or a PR opened with `gh pr create` directly instead of
`scripts/pr.sh` — produces zero CI-level `/cr` enforcement.

---

## 4. Control flows

### Build → review → push → merge

1. **Scope / spec.** A skill (`/dev` Phase 0, `/feature` Step 0, or `/tdd` Step 1) reads CLAUDE.md +
   AGENTS.md, confirms the behavior in `docs/TESTING.md`, stops on open decisions / ambiguity / new
   npm packages. (ADVISORY.)
2. **Red-green implement.** `/tdd` (or `/dev` Phases 1–2 via test-writer + implementation-writer
   sub-agents): write failing test → `npx vitest run` confirm red → minimum code → green → commit
   test+impl atomically. (ADVISORY ordering.)
3. **pre-commit fires per commit** (STRUCTURAL): lint + `tsc --noEmit` + `test:unit`. Integration
   tests under `src/data/**` are excluded here.
4. **Pre-merge review `/cr`** (ADVISORY body): Step 0 docs-only fast path → Step 2 nine parallel
   analytical agents (Passes 1–9) → Pass 11 `@reviewer` (spawns 4 lens agents; High findings = Must
   Fix; **there is no Pass 10**) → Step 3/3b synthesize + RECURRING-FINDINGS signature counting →
   Step 4 Opus fix agent for Must Fix (hook-file Must Fix routed to NEEDS HUMAN, not auto-fixed) →
   Step 5 surface the rest + promotion candidates → Step 7 **write `${REPO_ROOT}/.claude/.cr-ok` =
   `branch:sha`** → Step 8 evaluate `/compound`. Other skills (`/dev` Ph3, `/feature` all tiers,
   `/hotfix` Ph5, `/refactor` done, `/notion-sync` Step 11) invoke `/cr` to produce the sentinel;
   none write a sentinel themselves. `/cr-security` writes NO sentinel.
5. **pre-push fires on push** (STRUCTURAL): deletion-skip → `.env.local` gate → merged-PR guard →
   agent path validates `.cr-ok == branch:sha` (or TTY prompt) → `npm run test` (full, hits DB) +
   `npm run build`.
6. **PR open via `scripts/pr.sh`** (STRUCTURAL): atomically consumes the sentinel (validate `branch:
   sha`, then `rm`), checks remote branch exists, calls `gh pr create`. `/queue` Step 5 additionally
   `cat`s the sentinel and compares to `feat/<slug>:<HEAD sha>` before pushing each worktree.
7. **CI on PR/push-main** (STRUCTURAL on merge, subject to branch protection): re-runs tsc + eslint +
   test:unit independently. Does NOT check the sentinel, run integration, or run `next build`.

### Findings → promotion

1. During `/cr` Step 3b (`cr/SKILL.md:174-188`), each review finding is normalized to a signature,
   matched against Active entries in `docs/RECURRING-FINDINGS.md`, and appended (Occurrences: 1) or
   incremented (update Last seen, +1, append file:line capped at 5). **This counting lives ONLY in
   `/cr`** — `/compound` does NO occurrence counting and never touches RECURRING-FINDINGS.md.
2. Auto-flag threshold: any active finding at **Occurrences ≥3** (or judgment-flagged high-impact at
   lower count). Candidates are collected in Step 3b but surfaced at Step 5.
3. **Human-confirmed promotion** at Step 5: `Confirm? (y/n)`. On confirm → write the `PITFALLS.md`
   entry (or codify into a `/cr` pass prompt) and move the RECURRING-FINDINGS entry to
   `promoted-to-pitfalls`/`promoted-to-pass`/`retired`. On skip → leave Active; re-flag after one more
   occurrence.
4. Observed real promotion: `agents-md-migration-index-lags-final-commit` reached Occurrences 4,
   promoted 2026-06-03 to `PITFALLS.md § agents-md-migration-index-must-stay-current`.
   RECURRING-FINDINGS is the **only** occurrence-counted, signature-matched, auto-incrementing store;
   every other knowledge file is terminal or human-maintained.

### Knowledge persistence

Five distinct layers, each with its own writer/reader/trigger:

- **`.claude/memory.md`** (project corrected-mistake rules). WRITE: manual at session end when a
  mistake is corrected; `/compound` Step 6 *proposes* but does not write. READ: session start
  (CLAUDE.md mandatory). 11 entries; several behavioral ones duplicate CLAUDE.md "Agent behavior
  principles" verbatim.
- **`PITFALLS.md`** (codebase silent-bug traps). WRITE: promotion from RECURRING-FINDINGS (`/cr`
  Step 5, human-confirmed) OR direct add (`/compound` Step 5 propose-then-write, or human). READ:
  before writing/editing in an affected area (area-gated, not session-start). ~30 entries; itself a
  terminal destination — entries do not promote further.
- **`docs/solutions/`** (reusable solved-problem patterns). WRITE: `/compound` after a feature merges
  (Sonnet extractor → user review → write `YYYY-MM-DD-*.md`). READ: skim README before designing.
  31 dated docs; README excludes "anything already fully captured in PITFALLS.md."
- **`docs/adr/`** (hard-to-reverse architectural decisions). WRITE: manual/human only — no skill or
  hook writes ADRs. READ: skim README before designing. 5 ADRs, all Accepted.
- **Auto-memory `MEMORY.md`** (harness point-in-time store, user-scoped, outside the repo). WRITE:
  the Claude Code memory subsystem — NOT any repo skill or hook. READ: injected at session start by
  the harness. HIGH content overlap with memory.md / PITFALLS.md / docs/solutions (individual facts
  appear in three layers; PITFALLS `Source:` points back to auto-memory files).

Supporting cadence file: **`.claude/rituals.md`** — manual `last_run` reset, read at session start,
7-day staleness surfaced by CLAUDE.md. `.claude/INDEX.md` indexes only EXTERNAL resources and does
NOT index the internal knowledge corpus (there is no single internal index).

---

## 5. The 5 Pillars → real mechanisms

| Pillar | Mechanism that implements it today | STRUCTURAL or ADVISORY |
|---|---|---|
| **Structural over advisory** | The `.cr-ok` sentinel chain (`/cr` → pre-push → pr.sh), pre-commit, the two Bash guard hooks, the prod-key firewalls. These are the only places the principle is actually realized. | STRUCTURAL for the named mechanisms — but the pillar is contradicted in aggregate: the overwhelming majority of harness rules (all skill bodies, all CLAUDE.md/AGENTS.md/SOUL.md rules, autoMode) are advisory. The pillar is asserted system-wide but structurally backed only at a handful of git/script boundaries. |
| **Reversibility gates autonomy** | `/migrate` irreversibility tiers (clean-revert/compensate/window/permanent) with human sign-off for permanent; `/hotfix` mitigation-vs-full-fix modes; CLAUDE.md destructive-op rule requiring same-turn explicit naming; `block-dangerous-git.sh` for git-side irreversibles. | MIXED. `block-dangerous-git.sh` is STRUCTURAL (blocks reset --hard, clean, rebase, force-push, etc.). The `/migrate` tier sign-offs, `/hotfix` mode gates, and the CLAUDE.md destructive-op discipline are ADVISORY (no hook enforces "irreversible → stop" outside the git verbs the hook happens to cover). `autoMode.hard_deny` (DROP/TRUNCATE/DELETE-without-WHERE) is ADVISORY with no shell backstop. |
| **Verify the system not the model / cross-authority** | `/cr` spawns independent review agents; Pass 11 `@reviewer` runs 4 isolated lenses; `/review-strategy` runs 3 isolated strategy lenses; `/cr-security` runs 3 isolated passes; the sentinel makes one authority (`/cr`) gate another (the push hook). | MIXED. The cross-authority *handoff* (the sentinel) is STRUCTURAL. The multi-agent verification itself is ADVISORY — the agents are model-spawned, isolation is an instruction, and nothing verifies the agents ran or that findings were honored (the sentinel checks only a `branch:sha` string, not that `/cr` actually executed). |
| **Default-no + canon discipline** | settings.json `permissions.deny` on guard files; `permissions.allow` as an explicit allowlist; npm-install requiring an ask (hook-backed); `/notion-sync` treating Notion templates as canon and diffing every file; guard-file edits routed to NEEDS HUMAN across `/cr`, `/notion-sync`. | MIXED. The guard-file Edit/Write deny and the npm-install block are STRUCTURAL (subject to the path-anchoring caveat in §8 and jq fail-open). The "canon discipline" (Notion-as-source-of-truth, ask-before-X, don't-resolve-open-decisions-unilaterally) is ADVISORY. The allowlist is permissive in practice (`Bash(git *)`, `Bash(npm install*)`, `Edit/Write(/Users/tanner/Dev/event-vendor/**)`). |
| **Code is a liability** | SOUL.md north star (simple/deep modules); CLAUDE.md "build what's needed now", rule-of-three before abstraction, no speculative code; `/cr` Pass 7 footprint check (console.log/TODO/dead code/unused imports); the `/simplify` step in `/feature`; `/refactor` naming gate rejecting utils/helpers/common. | ADVISORY in full. `/cr` Pass 7 is a model-run review pass, not a hook. The `/simplify` step depends on a skill that is absent from the project skill dir (resolves to a global/built-in). No structural mechanism enforces footprint or simplicity. The pillar is asserted but not structurally backed. |

---

## 6. Redundancy registry

| What overlaps | Where (2+ locations) | Nature of overlap |
|---|---|---|
| Layer-boundary check (Supabase outside `src/data/`) | `/cr` Pass 4 (`cr:88`) + `/cr-security` Pass 2 (`cr-security:49`) | Same check run by two review skills. |
| `@reviewer` invocation | `/cr` Pass 11 (4-lens), `/hotfix` Ph4 (2-lens blast-radius), `/hotfix` Ph5 re-invokes `/cr` | Three invocation sites; a single hotfix triggers `@reviewer` twice. (Note: the 2-lens blast-radius mode `/hotfix` describes is not a mode `reviewer.md` actually defines — see §7.) |
| Red-green-implement loop | `/tdd` (Steps 3–4), `/dev` (Phases 1–2), `/feature` (per-tier) | Loop defined in three skills; `/dev` and `/feature` both delegate to `/tdd` yet also restate it in prose. |
| Doc-update step | `/cr` Pass 7 (doc drift), `/dev` Phase 4 (doc-updater agent), `/feature` done-criteria, plus the `@doc-updater` agent | Four places concern doc sync after a change. |
| Destructive-op / token rules | CLAUDE.md destructive-op section (358–372) + NEVER list (514–530) + SOUL.md "stop and surface" + agent-contract anti-patterns + block-dangerous-git.sh | Same prohibition restated across 4 docs plus one hook. |
| TypeScript / no-any / no-DB-mock / no-what-comments | CLAUDE.md (TypeScript, Code style, Testing) + agent-contract anti-patterns (129–133) + memory.md behavioral entries | Same rules in 2–3 docs. |
| Worktree naming + lifecycle / post-merge cleanup | CLAUDE.md (8–9, 380–399) + AI-WORKFLOW (17–69) + INDEX.md (14) + scripts/gc.sh | Triple-doc overlap on worktree discipline. |
| Work-state classification | CLAUDE.md line 7 + AI-WORKFLOW "Choosing the right work state" | Duplicate. |
| "Surface open decisions, never resolve unilaterally" | AGENTS.md + CLAUDE.md NEVER + SOUL.md + agent-contract STOP-AND-SURFACE | Four-way. |
| RBAC / role-enforcement location | AGENTS.md (Resolved 405/387, Rejected 426) + CLAUDE.md Architecture | 3× within AGENTS.md + once in CLAUDE.md. |
| Pipeline ("/cr before push") | CLAUDE.md shipping pipeline + SOUL.md "pipeline not optional" + AI-WORKFLOW skills table + agent-contract PIPELINE | Four-way. |
| debug ↔ incident | both reproduce-first + STOP on auth/RLS; incident routes into debug | Boundary stated incident:9-10. |
| incident ↔ evaluate-solution | third-party/capability-gap types route to eval | Routing overlap. |
| spike ↔ evaluate-solution | spike routes third-party feasibility to eval; **both write `docs/research/[topic].md`** | Routing + shared output target (collision-prone). |
| debug ↔ post-mortem | post-mortem writes PITFALLS/memory that debug Step 0 reads | Not cross-referenced. |
| behavior-change ↔ perf | both characterization-tests-first + compound-Q gate; opposite "two hats" halves | Adjacent halves of the same doctrine. |
| review-strategy ↔ build-side reviewer/lens-* | same parallel-isolated-lens fan-out architecture (strategy vs code) | Architectural duplication. |
| Memory-layer triple duplication | `.claude/memory.md` (gotcha entries) + `PITFALLS.md` + auto-memory `feedback_*` files | Same corrected-mistake facts in three stores; PITFALLS `Source:` points back to auto-memory; `/compound` Step 9 explicitly flags memory entries "already covered by PITFALLS.md (redundant)". |
| docs/solutions ↔ docs/adr | architectural-pattern solution vs ADR (e.g. rls-isolation solution vs ADR-0003) | Same decision, two stores. |
| Two Supabase skills | `/supabase` (vendor checklist) + `/supabase-postgres-best-practices` (33-rule library) | Both cover RLS/security; both appear as local skill dir AND runtime skill list (latter also a separate top-level registration). |
| TASKS.md writers | `/prioritize-tasks` (STRATEGY-driven reorder) + `/notion-sync` (Notion-template diff) | Two writers with different source-of-truth assumptions. |
| /compound Step 8 ↔ /notion-sync | both touch Notion changelog ID `35ae...` | Scope delimiter declared in notion-sync:204-208. |
| Three npm-install call sites | `session-start.sh:14` (remote) + `post-checkout:8` (fresh worktree) + allowed `Bash(npm install*)` | Three independent paths run `npm install` for a new worktree; none use `--ignore-scripts`. |
| 127.0.0.1 URL guard | `gen-local-env.sh:34-37` + `test-local.sh:55` | Same guard implemented twice. |
| supabase-status env remap/quote-strip | `gen-local-env.sh:24-26` + `test-local.sh:40-49` | Same logic, two differing implementations. |
| Redundant allow entries | `scripts/pr.sh*`/`worktree-add.sh*`/`gc.sh*` (settings.json 54-56) subsumed by `Bash(bash scripts/*.sh*)` (57) | Individually listed AND covered by the broader pattern. |
| Force-push-to-main guard | `autoMode.hard_deny` (advisory) + `block-dangerous-git.sh` push arm (deterministic) | Guarded twice, one advisory one structural. |

---

## 7. Phantom & claim-vs-reality registry

| Referenced thing | Referenced where | Reality |
|---|---|---|
| `/simplify` (project skill) | feature:13,52,53,70,88,115; AI-WORKFLOW skills table | **ABSENT** in `.claude/skills/` AND `~/.claude/skills/`; the name resolves to a global/built-in `simplify` skill, not a project skill. |
| `/grill-with-docs` | feature:11,52-54; design:16-18; AI-WORKFLOW | Not in `.claude/skills/`; EXISTS in `~/.claude/skills/` (global). |
| `/to-issues` | feature:11,53-54,110-111; design; AI-WORKFLOW | Not in `.claude/skills/`; EXISTS in `~/.claude/skills/` (global). |
| `/prototype-interface` | spike:25,113,189,220 | **ABSENT** — no skill dir. Named repeatedly as the Open/Blocked next step. |
| `/scan-context` | review-strategy frontmatter:8; prioritize-tasks; rituals.md (a ritual) | **ABSENT** — no skill, not in runtime skills list. (A `scan-context` ritual entry exists in rituals.md.) |
| `@benchmark-runner` | perf:174-176,374-380 | **ABSENT** — self-labeled future. |
| `dep-update` skill | skill dir present | **EMPTY** — directory exists, no SKILL.md, not in runtime list. |
| `.claude/agentic-system-enabled` | SOUL.md:72 (auto-/compound gate); doc-updater desc; post-mortem "sentinel projects" | **ABSENT** — so by SOUL.md's own condition, auto-/compound is NOT enabled and doc-updater auto-write does not fire here. |
| `.claude/skills-lock.json` | CLAUDE.md:227 ("Keeping docs current") | **ABSENT**. |
| `.claude/learned-patterns.md` | (referenced) | **ABSENT** on disk. |
| `.claude/review-log.md` | (referenced) | **ABSENT** on disk. |
| `.claude/triage-inbox.md` | (referenced) | **ABSENT** on disk. |
| `CONTEXT.md` (repo root) | compound, design, agent-contract, incident, setup-strategy, AI-WORKFLOW, SOUL | **ABSENT at repo root** — referenced as required reading by multiple skills. |
| `TASK-TEMPLATE.md` (bare, repo root) | debug:110, spike:198, incident:280 | Referenced by bare name; actually lives at `.claude/TASK-TEMPLATE.md` (PRESENT there). Path-vs-claim mismatch. |
| `docs/solutions/2026-05-18-notion-changelog-sync-process.md` | notion-sync:199,249 | **ABSENT** — cited twice as the canonical solution doc. |
| `2026-05-27-hook-single-responsibility-skill-boundary.md` | exists on disk | **NOT in `docs/solutions/README.md` index table** — index drift. |
| `docs/solutions/README.md` YAML-tag threshold | README:33 ("when dir exceeds ~10 entries") | 31 dated docs present — threshold passed, frontmatter-tag action state unverified. |
| AGENTS.md "Open decisions … None open." | AGENTS.md:361 | **INTERNAL INCONSISTENCY** — "None open" banner immediately followed by two substantive open decisions (event_type enum 363–368; payer model 370–375). |
| `/cr` Pass 10 | cr SKILL numbering | **ABSENT** — numbering jumps 9 → 11; no Pass 10. |
| `/cr` REJECT tier | cr routing | **ABSENT** — routing is Must Fix (auto-fixed) / NEEDS HUMAN / Nice-to-Have+Something-to-Think-About; no REJECT tier. |
| `/cr` UNATTENDED / autoMode branching | cr + cr-security bodies | **ABSENT** — neither skill body branches on UNATTENDED/autoMode (the mode exists at repo/settings level per commit 130f4a2, not in these skills). |
| `@reviewer` 2-lens blast-radius mode | hotfix:202-216 | **MISMATCH** — reviewer.md defines only Design + Implementation (4-lens) modes; no 2-lens blast-radius mode. |
| `incident-db-query-enabled` settings flag | incident:150-153 | **INERT** — incident:319-322 self-documents that the flag cannot be added (Claude Code schema rejects unrecognized top-level keys); auto-query path is structurally unreachable. |
| `[hotfix-postmortem]` TASKS.md entry | post-mortem:6-8,23; hotfix Ph3 | Token **ABSENT** in current TASKS.md — the triggering entry is not present. |
| `Templates` directory ("Templates → agents/…") | spike:218; cr:149; hotfix; reviewer label | **ABSENT** as a directory — actual files are under `.claude/agents/`. Naming-convention label, not a real path. |
| `AI-WORKFLOW.md` (bare, repo root) | block-dangerous-git.sh:86-87 comment | The file lives at `.claude/AI-WORKFLOW.md`; the hook comment's bare reference does not resolve at repo root (informational only; logic doesn't read it). |
| `.cr-feature-ok` | settings.local.json allow (27,37); docs/solutions history | **ABSENT** on disk; no live (non-doc) code references it — the second review gate was collapsed (per 2026-05-27 solution doc). |
| Auto-memory "ADR 0005 still unwritten" | MEMORY.md:6 | **STALE / CONTRADICTED** — `0005-activity-log-as-system-spine.md` exists and is indexed Accepted; auto-memory is self-declared 5 days old. |
| `.claude/.cr-ok` referenced by CI | ci.yml / integration.yml | **ABSENT** — grep count 0 in both; sentinel is gitignored, never reaches CI. |
| pre-push "integration tests" claim | CLAUDE.md:178 step 4 | Partial — hook runs `npm run test` (full suite, which does include integration) + `npm run build`; the doc's wording is approximately correct but `npm run test:unit` (CI) excludes integration. |

---

## 8. Known structural gaps (factual)

Plain verifiable facts — not recommendations.

- **CI does not verify `.cr-ok`.** Both ci.yml and integration.yml have zero references to it; the
  file is gitignored and never reaches the CI runner. (`grep -c "cr-ok"` = 0 in both.) The Node
  8.5(c) gap.
- **`git push --no-verify` / missing-`.husky` / direct `gh pr create` bypass the entire sentinel
  chain** with no CI backstop; CI independently re-runs only tsc + eslint + test:unit.
- **No `--ignore-scripts` anywhere.** The string is absent from all five hooks. Three `npm install`
  call sites (`session-start.sh:14`, `post-checkout:8`, allowed `Bash(npm install*)`) run lifecycle
  scripts.
- **No `dependabot.yml`** (`.github/dependabot.yml` ABSENT); `.github/` holds only the two workflows.
- **Bare `git push` on `main` is not caught by the dangerous-git hook.** The push arm inspects the
  refspec dst; a bare push (relying on `push.default`) has no non-flag arg, so `norm_ref` never runs
  (`block-dangerous-git.sh:81-84`). Only force variants are blocked.
- **jq fail-open in the two Bash guards.** `block-dangerous-git.sh:13` and `block-npm-install.sh:6`
  exit 0 (guard DISABLED) when jq is missing, warning on stderr only. (worktree-create.sh fails
  CLOSED; permission-logger.sh and session-start.sh have no jq guard at all.)
- **Guard-file deny path-anchoring possibly inert.** settings.json deny entries use leading-slash
  form (`Edit/Write(/.claude/hooks/**)`) while absolute allow entries use full
  `/Users/tanner/Dev/event-vendor/**` paths. If `/.claude/**` resolves literally against filesystem
  root rather than repo-relative, the deny would not match files under the project's `.claude/**` and
  would be inert. Identified from the path strings; not resolvable by reading alone.
- **`git checkout` is ungated.** Broadly allowed (`settings.local.json:23` `Bash(git checkout *)`)
  with no `checkout` case in the dangerous-git hook — working-tree-discarding checkouts pass.
- **Other destructive git verbs uncovered** by block-dangerous-git.sh: `update-ref -d`, `reflog
  expire`, `gc --prune`, `filter-branch`, `branch -M`, `checkout -- .` / `restore`, `tag -d`, `push
  --delete`, `push --mirror`.
- **`npx <pkg>` / `npm exec` not matched** by block-npm-install.sh — only literal `npm` with an
  install-family subcommand.
- **Protected-branch list is literal** `main|master|develop` (block-dangerous-git.sh:83); any other
  protected branch name is not caught.
- **Integration/DB tests only run on manual dispatch** (`integration.yml` is `workflow_dispatch`
  only) and at pre-push; never automatically on PR/push. pre-commit and ci.yml both exclude
  `src/data/**`.
- **`ci.yml` does not run `next build`** — only pre-push does.
- **Default (attended) worktree mode symlinks the prod-pointing `.env.local`.** The prod-key firewall
  (`gen-local-env.sh`) applies only in `UNATTENDED=1`; the default path (`worktree-add.sh:21-23`,
  `worktree-create.sh:33-40`) symlinks prod creds.
- **`autoMode.hard_deny`** (DROP/TRUNCATE/DELETE-without-WHERE against prod) has no deterministic
  shell backstop — it is natural-language for the classifier only.
- **`.husky/pre-push` agent gate trusts the sentinel string**, not that `/cr` ran — any process
  writing the correct `branch:sha` to `.claude/.cr-ok` satisfies it (policy-enforced, not
  hook-enforced).
- **All-deletion pushes bypass pre-push entirely** (`.husky/pre-push:7-18`).
- **`scripts/README.md` documents 3 of 6 scripts** (omits `gen-local-env.sh`, `test-local.sh`,
  `seed.ts`).
- **rituals.md gating definition diverges from CLAUDE.md** — file says "more than the specified
  frequency ago"; CLAUDE.md hardcodes "more than 7 days ago." Two gate definitions for one file.
- **No single index of the internal knowledge corpus** — INDEX.md indexes only external resources;
  the closest internal indexes are the per-file README tables in docs/solutions and docs/adr.

---

## Executive summary — the harness's true current state

**Genuinely strong (structurally enforced):**
- The `.cr-ok` sentinel chain (`/cr` writes `branch:sha` → pre-push validates → `scripts/pr.sh`
  atomically consumes) is the one real spine tying the advisory review pipeline to a hard gate.
- pre-commit (lint + tsc + test:unit) and pre-push (env + merged-PR + sentinel + full test + build)
  deterministically block at the git boundary.
- The two prod-key firewalls (`gen-local-env.sh`, `test-local.sh`) fail-closed unless the Supabase
  URL is `127.0.0.1`, and `worktree-create.sh` fails-closed on missing jq — real Tier-0 credential
  isolation in UNATTENDED mode.
- `block-dangerous-git.sh` deterministically blocks the common irreversible git verbs (reset --hard,
  clean, rebase, force-push, force-delete, out-of-tree worktree removal).

**Advisory-only (the bulk of the system):**
- Every step inside all ~30 skill bodies, including all `/cr` passes, every human-confirm gate, and
  `@hotfix-guard`'s "will not pass" — these are model-spawned, not hook-blocked.
- All CLAUDE.md/AGENTS.md/SOUL.md/agent-contract rules (layering, TypeScript bans, migration rules,
  destructive-op discipline, scope/decision discipline). CLAUDE.md:360 states this outright.
- The settings.json `autoMode` lists (environment/allow/soft_deny/hard_deny) are natural-language for
  the classifier, not regex gates.

**Biggest redundancies:**
- The memory layer is triple-duplicated: `.claude/memory.md` (gotcha entries) ↔ `PITFALLS.md` ↔
  auto-memory `feedback_*` files; `/compound` itself flags memory entries as "already covered by
  PITFALLS (redundant)."
- `@reviewer` is invoked by three skills; the red-green loop, doc-update step, and destructive-op
  rules each live in 3–4 places; two Supabase skills overlap on RLS/security.
- `docs/research/[topic].md` is a shared write target for both `/spike` and `/evaluate-solution`
  (collision-prone); TASKS.md has two writers with conflicting source-of-truth assumptions.

**Biggest phantom/stale problems:**
- `CONTEXT.md` is referenced as required reading by 6+ skills but is ABSENT at repo root.
- `.claude/agentic-system-enabled` is ABSENT — so by SOUL.md's own condition auto-/compound and
  doc-updater auto-write do not fire here, yet multiple docs assume they do.
- Five+ referenced skills/files are phantom: `/prototype-interface`, `/scan-context`,
  `@benchmark-runner`, `skills-lock.json`, `learned-patterns.md`/`review-log.md`/`triage-inbox.md`;
  `dep-update/` is an empty dir.
- `/cr` has no Pass 10, no REJECT tier, and no UNATTENDED branching despite the surrounding framing;
  the `@reviewer` 2-lens blast-radius mode `/hotfix` describes does not exist in reviewer.md.
- AGENTS.md says "Open decisions: None open" directly above two open decisions; auto-memory still
  claims "ADR 0005 unwritten" though it is written and Accepted.

**Real structural gaps:**
- CI never verifies the sentinel (Node 8.5(c) gap); `--no-verify`/direct-`gh pr create` bypass the
  whole chain with no CI backstop.
- No `--ignore-scripts` on any of three npm-install paths; no dependabot.
- Bare `git push` on main and all `git checkout` working-tree discards are ungated; the dangerous-git
  hook fails OPEN on missing jq and omits many destructive verbs.
- The guard-file Edit/Write deny may be path-anchoring-inert (leading-slash vs absolute-path form).
- Integration/DB tests run only at pre-push and on manual CI dispatch — never automatically on PR.
- Default (attended) worktrees still symlink prod creds; the firewall is UNATTENDED-only.
