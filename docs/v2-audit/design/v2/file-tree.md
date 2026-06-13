# V2 File Structure & WHY (clarity-first, two budgets)

> **What this is.** The target file structure for the V2 harness — what is NEW, what is DELETED/CHANGED, and
> why — built on `ambition/VISION.md` (5 pillars, 33 moves, the 5-move minimal floor) under the rebuild
> charter (**world-class only; autonomy first-class; clarity beats minimalism; KEEP THE RIGOR**). Every line
> cites a VISION move + a ground-truth row (§N in `CANONICAL-HARNESS-AS-IS.md`) or a confirmed absence
> re-verified on disk this session. The conservative baseline is `phase3/RECONCILIATION.md §D/§E`; this raises
> ambition on top of its sound mechanics — it does **not** re-anchor on its minimalism.
>
> **Ground truth re-verified on disk (2026-06-11):** 26 skills, 23 agents, 5 Claude hooks, 7 scripts, 6 ADRs
> (5 + README), 34 solution docs, 2 specs (present), PITFALLS = 558 lines, memory.md = 166 lines, `.cr-ok` +
> `.cr-feature-ok` gitignored (`.gitignore:57-58`), existing Stop hook plays a SOUND only (`settings.json:191`).
> ABSENT (confirmed): `.claude/rules/`, `.claude-plugin/`, `block-dangerous-bash.sh`, `session-end*.sh`,
> `enforce-scope.sh`, `harness-manifest.json`, `golden-set/`. Platform facts: `capability-facts.md`.

---

## The two budgets (read this first — it governs the whole tree)

The charter retired *minimalism as a virtue* but kept *consolidation as a technique* (VISION ¶11). The honest
accounting — forced by `RECONCILIATION §A`, where two of three Phase-3 artifacts drifted into a file INCREASE
while reporting a favorable proxy — splits into **two budgets that move in opposite directions and are scored
separately:**

| Budget | What it is | V2 direction |
|---|---|---|
| **(1) Agent-READ forgeable prose** | Files the agent loads as prose: CLAUDE.md, memory.md, the PITFALLS monolith, AGENTS architecture rules — **and the new `.claude/rules/` shards, which load via `paths:` and are exactly as forgeable as the prose they were split from** (`RECONCILIATION §A` Phase-6 correction) | **DOWN, hard** |
| **(2) Out-of-band UNFORGEABLE enforcement** | Hooks, CI scripts, lint/dep-cruiser configs, the manifest, the plugin/marketplace — run *outside* the agent's context | **UP — and that is fine under the charter** |

**Budget (1) falls** not because bytes move into enforcement, but because the shards **load 1–2 per task on
their path instead of all 558 PITFALLS lines on every code task** — and the `/cr` 4-lens pass that today reads
~172 KB of PITFALLS (4 × ~43 KB) collapses to a fraction. **Copies-per-fact goes 3→1** (CLAUDE.md NEVER-section
+ memory.md + PITFALLS each restated a rule; now one home, generated). The always-load floor stays flat-to-down
(`00-safety.md` absorbs the deleted NEVER-section + memory.md safety text verbatim).

**Budget (2) grows ~+9–11 files, and the charter explicitly drops file-count-as-redflag.** Each item names a
§9 failure mode (the column is non-negotiable — see "Where every move lands"). **Do not apologize for budget-(2)
growth, and do not chase a flat `find | wc -l` total.** Clarity beats minimalism: a deterministic guard that
prevents the Replit-July-2025 prod-DB deletion earns its file. The total ends roughly flat (+1 to +2); the
distribution of *what* those files are is the entire point.

**The native mechanism — shard only where a clean glob exists.** `.claude/rules/` with `paths:` globs is
**native path-scoped lazy-loading** (`capability-facts.md:52-54`) — we do not invent it. **Rule: an area
becomes a shard iff it has a clean file-path glob** (`RECONCILIATION §B.3`). That yields **~5–6 shards**, not
the 8 an early draft proposed; path-less / operation-scoped constraints (worktree ops, destructive-op safety,
the external-tool rule) live in always-loaded `00-safety.md`, never in fake shards that don't auto-load.

**The keep-verbatim safety floor stays in `00-safety.md` regardless of length** (`RECONCILIATION §B.4`,
`V1-TO-V2-CARRYFORWARD §A` diff-review). memory.md's destructive-op entries carry a richer
incident-narrative + apply-steps than CLAUDE.md's terser copy — that richer copy is absorbed **verbatim**
before memory.md is deleted. The 200-line CLAUDE.md "diet" is an **UPHELD-CUT** (VISION Honest Cuts): tier by
trigger-existence, never blind line-count.

---

## The target tree

Legend: **[NEW]** created in V2 · **[DEL]** deleted · **[CHG]** content/delivery changes · **[KEEP]** carried
as-is · `(§N)` ground-truth row · `(VISION Mx)` the move that creates/changes it.

```
event-vendor/                                  # the dogfood repo (canon is mirrored into agent-harness — see P3/P1)
│
├── CLAUDE.md                       [CHG] NEVER-section trimmed as ~64 rules relocate; tier by trigger, not line-count (RECONCILIATION §C; VISION C5)
├── AGENTS.md                       [KEEP] product context, MVP scope, Open/Rejected/Resolved decisions, golden-exemplars table, codebase map (V1-TO-V2-CARRYFORWARD §A)
├── PITFALLS.md                     [DEL]  558-line monolith → sharded into .claude/rules/ (path-globbable entries) + 00-safety.md (operation-scoped residuals) (§5; VISION C5/CMP4)
├── package.json                    [CHG] lint script gains `--max-warnings 0` so warn-severity rules actually block (RECONCILIATION §C.4); +dev-deps below (ASK-first)
│
├── .claude/
│   ├── settings.json               [CHG] Stop array gains the shared hook (coexists with the existing sound hook, settings.json:191); PreToolUse gains block-dangerous-bash (HUMAN-applied — no agent edits to guard files)
│   ├── settings.local.json         [KEEP] personal; autoMode policy lives here (NOT committed project settings — the classifier ignores those, capability-facts.md:42-46) (VISION P2)
│   ├── memory.md                   [DEL]  166 lines → safety text absorbed VERBATIM into 00-safety.md; 3 non-safety traps routed (see "Where every move lands"); deleted ONLY after absorb verified (RECONCILIATION §B.4/§D.1)
│   │
│   ├── rules/                      [NEW]  path-scoped lazy-load shards — native paths: mechanism (capability-facts.md:52-54; VISION C5/CMP4)
│   │   ├── 00-safety.md            [NEW]  ALWAYS-LOAD floor: CLAUDE NEVER-section + memory.md safety VERBATIM + destructive-op/worktree/external-tool (path-less) rules + always-load process section (RECONCILIATION §B.3/§B.4)
│   │   ├── migrations.md           [NEW]  paths: supabase/migrations/** — CREATE-REPLACE-grant-reset, no-CONCURRENTLY, trigger-owned-timestamps, number-collision (PITFALLS §migrations cluster)
│   │   ├── data-layer.md           [NEW]  paths: src/data/** — react-cache-for-shared-data, no-hand-written-interface, supabase-admin-for-public-writes, golden-exemplar pointer (V1-TO-V2-CARRYFORWARD §A)
│   │   ├── schemas.md              [NEW]  paths: src/schemas/** — schema-file-folder-collision, postgrest-timestamptz-offset, Zod-on-boundary, golden-exemplar pointer
│   │   ├── auth-routing.md         [NEW]  paths: app/**,src/proxy.ts,middleware* — public-paths-in-route-groups, rls-role-mission-creep, nextjs16-middleware-filename, redirect-pathname-only
│   │   ├── architecture.md         [NEW]  paths: src/components/**,renderer paths — components-are-I/O-only, design-tokens-first, golden-exemplar divergence (V1-TO-V2-CARRYFORWARD §A design system)
│   │   └── harness-hooks.md        [NEW]  paths: .claude/hooks/**,scripts/** — shell-guard-parse-not-substring, hook-args-scan, hash-consistency, bash-dangerous-heredoc, enforcement-boundary-layering (ex-memory trap)
│   │
│   ├── hooks/
│   │   ├── block-dangerous-git.sh  [KEEP] (§3e) — but fail-CLOSED on missing jq (today fails open) (VISION F1 doctrine)
│   │   ├── block-npm-install.sh    [KEEP] (§3e) — fail-closed correction same as above
│   │   ├── block-dangerous-bash.sh [NEW]  the absent 3rd guard: rm -rf outside worktree, DROP/TRUNCATE/DELETE-no-WHERE, prod deploy, supabase db push non-local, writes to .git/.claude — fail-closed (§3e/§5; VISION F1)
│   │   ├── permission-logger.sh    [CHG] promoted into the append-only agent-PR observability feed (trigger fired, PR link, risk tier, outcome) (§3f; VISION L7)
│   │   ├── session-start.sh        [KEEP] near-empty body; wiring is a build (V1-TO-V2-CARRYFORWARD §C)
│   │   ├── session-end.sh          [NEW]  HOOK-1 — the ONE shared Stop surface; payloads: C10 test+typecheck block-on-red, CMP5 capture-proposer, F7 retry counter, L7 narration; additive, exit-0-only, coexists with sound hook (§3e/§5; VISION HOOK-1)
│   │   └── worktree-create.sh      [KEEP] (§3e)
│   │
│   ├── skills/                     [CHG] 26 → 25 core + NEW autonomy/eval skills; each gains frontmatter contract (VISION P6/F9)
│   │   ├── (22 core kept)          [CHG] cr, cr-security, debug, design, dev, feature, hotfix, incident, migrate, perf, post-mortem, refactor, spike, tdd, queue, evaluate-solution, behavior-change, compound, explain, prioritize-tasks, review-strategy, setup-strategy — each gets disable-model-invocation tier + situational description (§3e 0/26; VISION F9)
│   │   ├── dep-update/             [DEL]  empty stub — the only §9-justified skill cut (RECONCILIATION §D)
│   │   ├── notion-sync/            [DEL]  Notion deprecated as canon; transferable mechanisms carried into /compound (§7; VISION P3)
│   │   ├── supabase/               [MOVE] → per-project Supabase add-on (out of the portable core) (V1-TO-V2-CARRYFORWARD §C)
│   │   ├── supabase-postgres-best-practices/ [MOVE] same; de-dup the double-listing (§1; VISION P5)
│   │   ├── goal/                   [NEW]  L2 — /goal continuation primitive; runs until a SEPARATE grader confirms; embeds verifier-rung doctrine; disable-model-invocation NOT set (user+orchestrator driven) (§3e absent; VISION L2)
│   │   ├── lfg/                    [NEW]  L5 — orchestrator brainstorm→plan→work→review→compound→opened-PR; ends at scripts/pr.sh; 1 orchestrator + 7 guards; disable-model-invocation:true (§3b absent; VISION L5)
│   │   ├── verify/                 [NEW]  C8 — render gate: a11y snapshot + console + pixel-diff vs baseline, fail-closed TENANT assertion; unattended leg runs in CI (chrome-devtools-mcp is headed-only) (§3c; VISION C8)
│   │   ├── scan-context/           [NEW]  CMP4 — bidirectional drift detection (staleness + doc-fiction) + decay; houses the L5 cross-skill reference-integrity check (§5/§6 absent; VISION CMP4)
│   │   ├── ratchet/                [NEW]  CMP2 — finding→enforcement ratchet (or a /compound sub-phase); ≥3-recurring → deterministic block (hook/lint/governance-lens criterion) (§3e/§4; VISION CMP2)
│   │   ├── cr-calibrate/           [NEW]  C4 — golden-set recall + false-positive rate per pass/lens; CI job; stale recall blocks /cr-as-trusted-gate (§6 phantom; VISION C4)
│   │   └── init/                   [NEW]  P2 — materializes per-repo files a plugin physically can't carry; prepares paste-ready settings/guard content for a HUMAN to apply; disable-model-invocation:true (capability-facts.md:42-46; VISION P2)
│   │
│   ├── agents/                     [CHG] 23 kept (each a distinct §9 failure mode, all wired) — model: re-audited on Opus 4.8 (VISION C13/CMP6/P10)
│   │   ├── reviewer.md             [CHG] C2 — adversarial pass gets isolated SOLUTION context but full project CANON; 3-4 round hunt→fix→retest; pre-reads CONTEXT/AGENTS/PITFALLS, passes into each lens (§3c/§3d; VISION C2)
│   │   ├── lens-*.md (4)           [CHG] lens-abuse/assumption/cascade/composition — model: → Opus 4.8; +governance-corpus lens criteria (C5); stay-in-lane rule verbatim (§3c; VISION C5/C13)
│   │   ├── security-reviewer.md    [KEEP] wired into /cr-security glob path
│   │   ├── incident-responder.md   [KEEP] L6 — 8-type routing brain + security isolation-short-circuit; doc-travel-as-orient-replacement carried VERBATIM (incident/SKILL.md:269-287; VISION L6)
│   │   ├── hotfix-guard.md         [KEEP] L6 — gates on exact [~] TASKS.md entry shapes /hotfix writes (VISION L6)
│   │   ├── spec-writer.md          [KEEP] C6 — writes docs/specs/<feature>.md (VISION C6)
│   │   ├── spike-*.md (6)          [KEEP] wired by spike-orchestrator; model: re-audited (RECONCILIATION §D; VISION C13)
│   │   └── (remaining 9)           [KEEP] doc-updater, explorer, implementer, investigator, refactor-extractor, solution-evaluator, task-runner, ux-reviewer + spike-orchestrator — all wired, all §9 (RECONCILIATION §D)
│   │
│   ├── rituals.md                  [CHG] 5 rituals KEEP; firing moves from session-start-check → cloud /schedule (L4); scan-context → CI drift detector; model-review → on-bump probe (CMP6) (rituals.md; VISION L4/CMP6)
│   ├── agent-contract.md           [KEEP] sub-agent spawning template (GOAL/SCOPE/DECISIONS/REFERENCES/TDD) — ships in plugin (V1-TO-V2-CARRYFORWARD §A)
│   ├── diff-review.md              [KEEP-VERBATIM] the HUMAN checkpoint after /cr clean; the manual-QA-coverage floor — NOT folded into AI review (V1-TO-V2-CARRYFORWARD §A)
│   ├── SOUL.md / AI-WORKFLOW.md    [KEEP] ship as plugin defaults a project may override (V1-TO-V2-CARRYFORWARD §C)
│   ├── INDEX.md / mcp.md           [KEEP] project-owned context (V1-TO-V2-CARRYFORWARD §C)
│   ├── harness-manifest.json       [NEW]  P6 — consumer of per-skill frontmatter (name, required-tools, owning-layer, portable, scope, disable-model-invocation); the SINGLE owner of "the task manifest" F3/F5/L1 reference (§1/§3b absent; VISION P6)
│   ├── .cr-ok                      [KEEP] (§3f) — survives as the READINESS signal; the CI gate (F6) is the enforceable boundary; .gitignore keeps it out of CI by design
│   ├── TASK-TEMPLATE.md            [ARCHIVE] 29 KB inert scratch — out of skim (RECONCILIATION §E)
│   ├── notes/, questions.md, grill-progress-*, walkthrough-*  [ARCHIVE] ~48 KB scratch (RECONCILIATION §E)
│   └── worktrees/                  [KEEP] 7 on disk; 7 STALE flagged NEEDS-HUMAN (each a full repo copy — biggest raw byte cut) (RECONCILIATION §E)
│
├── .claude-plugin/                 [NEW]  P1 — the distribution spine (built AFTER canon↔disk convergence — the publish gate) (§8/§0 absent; VISION P1)
│   ├── marketplace.json            [NEW]  descriptor: /plugin marketplace add <git-url>; version pinning + release channels + /plugin update (capability-facts.md:61-64; VISION P1)
│   └── plugin/
│       ├── plugin.json             [NEW]  manifest: name, version, bundled skills/agents/hooks/.mcp.json (capability-facts.md:57-60)
│       ├── hooks/hooks.json        [NEW]  ships the shared Stop hook + guards — REPLACES the hand-edited settings.json hook block at extraction (HOOK-1; capability-facts.md:57)
│       ├── skills/                 [NEW]  portable subset (scope: universal in manifest) — NOT supabase/* (project add-on) (VISION P5/P10)
│       ├── agents/                 [NEW]  23 roles serialized via manifest, tagged owning-layer + portable; gated on CMP4 fiction-scan + P5 dedup first (VISION P10)
│       ├── .mcp.json               [NEW]  MCP servers the harness ships (capability-facts.md:57)
│       └── UPSTREAM-DEPENDENCY-POLICY.md [NEW] P7 — vendor-and-freeze / track-with-cadence / cut per skill; provenance + pinned SHAs (§1/§8; VISION P5/P7)
│           # NOTE: a plugin CANNOT carry permissions/full-settings — those stay project/user/managed; /init places them (capability-facts.md:57-60; VISION P2)
│
├── scripts/                        [CHG] 7 → 10
│   ├── pr.sh                       [CHG] (§3f) — posts the F6 verdict ARTIFACT (MUST-FIX-resolved/NEEDS-HUMAN/REJECT/RECURRING delta) to the PR; consumes .cr-ok (VISION F6)
│   ├── gc.sh / worktree-add.sh / test-local.sh / gen-local-env.sh / seed.ts  [KEEP]
│   ├── gen-rules.sh                [NEW]  CMP4-adjacent — deterministically shards path-globbable PITFALLS entries into .claude/rules/; operation-scoped residuals named & routed by hand (RECONCILIATION §B.3/§D.2)
│   ├── migration-lint.sh           [NEW]  CI — absorbs 8 safety-critical migration rules (REVOKE-after-CREATE-REPLACE, no-CONCURRENTLY, rollback-path) (RECONCILIATION §C; VISION CMP2)
│   └── repo-structure.sh           [NEW]  CI — absorbs commitlint (no new dep) + file/export conventions + page-route-level rules (RECONCILIATION §C)
│
├── .github/workflows/
│   ├── ci.yml                      [CHG] (§6) — gains the F6 STOP-AUTHORITY job: parse .cr-ok branch:sha, FAIL unless sentinel-SHA == head-SHA AND required checks green; made required via branch protection (the KEYSTONE) (§3f:229-231; VISION F6)
│   ├── integration.yml             [KEEP]
│   ├── cr-security-classifier.yml  [NEW]  glob classifier — auth/middleware/RLS paths force /cr-security (RECONCILIATION §C; VISION C5)
│   ├── cr-calibrate.yml            [NEW]  C4 — runs golden-set, emits recall + FP-rate; stale recall blocks trusted-gate promotion (VISION C4)
│   ├── verify.yml                  [NEW]  C8 — headless render gate against a preview deploy; fail-closed tenant assertion; attaches evidence bundle (VISION C8)
│   └── scan-context.yml            [NEW]  CMP4/P9 — drift + reference-integrity on every merge; knowledge-artifact frontmatter validation (VISION CMP4/P9)
│
└── docs/
    ├── adr/                        [CHG] 6 (5+README); +0007 migration-credential (F4: agent verifies local, human applies prod) +0008 verdict-artifact surface (F6/Fork-F1) (VISION F4/F6)
    ├── specs/                      [KEEP→GROW] change-quote-request.md, proposal-status-state-machine.md PRESENT; /feature writes one per feature (C6 — CLAUDE.md named it, it now grows) (§3a; VISION C6)
    ├── solutions/                  [KEEP] 34 docs — the solved-pattern corpus (§4)
    ├── design/                     [KEEP] tokens/components/briefs/handoff — UI rule becomes path-scoped on src/components/** (architecture.md shard); +data-testid/aria mandate (C9) (V1-TO-V2-CARRYFORWARD §A; VISION C9)
    ├── RECURRING-FINDINGS.md       [CHG] read-path closed: loaded into implementer task-start context + decay (CMP1); ratchets to blocks (CMP2) (§4/§9; VISION CMP1/CMP2)
    ├── ARCHITECTURE.md / TESTING.md [KEEP] TESTING.md is /tdd's behavior-ledger oracle (C12) (VISION C12)
    └── research/v2-audit/
        └── golden-set/             [NEW]  C4 — adversarially-seeded labeled diffs (missing fallback, as-without-narrowing, cross-tenant RLS hole, open-redirect) + clean diffs; the calibration corpus (§6; VISION C4)
```

---

## Where every move lands (the completeness index — provably complete against the roster)

Every VISION move maps to the file(s) it creates/changes. Moves demoted to clauses (L3→L2, C1→F6, C3→F7,
C7→F6+C6, C13-recurring→CMP6) are listed at their host. `(§N)` / confirmed-absence cited per move.

| Move | Lands in | Named failure mode prevented |
|---|---|---|
| **L1** trigger trifecta | `.github/workflows/` GitHub-label Action (ships first, no free-text); `lfg/` + `init/` route into worktree shell; wires L6 incident triggers (§3e absent) | engineer stays per-repo dispatcher — the ceiling autonomy exists to lift |
| **L2** `/goal` | `.claude/skills/goal/` (embeds verifier-rung doctrine, L3-clause) (§3e absent) | babysitting a session; agent rationalizing its own success |
| **L4** cloud heartbeat | `.claude/rituals.md` (firing → cloud `/schedule`); `scan-context.yml` (§3e absent) | silent death of every "weekly" ritual |
| **L5** `/lfg` | `.claude/skills/lfg/` (1 orchestrator + 7 guards); ends at `scripts/pr.sh`; reference-integrity check → `scan-context/` (§3b absent) | the AFK-is-a-someday-feature trap — loop never closes |
| **L6** incident subsystem | `agents/incident-responder.md` + `agents/hotfix-guard.md` + `skills/{incident,hotfix,migrate,post-mortem}` (doc-travel VERBATIM) (grounding skills-B/agents-A) | flattening prod-incident path into `/feature` loses the routed state machine |
| **L7** narration + observability | `hooks/session-end.sh` (narration payload) + `hooks/permission-logger.sh` (promoted to PR log) (§3e/§3f absent) | autonomous run reports only at end — operator blind mid-run |
| **LOOP-7/A6** auto-approval | classifier in `.github/workflows/` (observe-only first); consumes F6 (§3c) | human-review-capacity bottleneck no parallel agents lift |
| **F1** block-dangerous-bash | `hooks/block-dangerous-bash.sh` (fail-closed) (§3e/§5 absent) | Replit-July-2025 prod-DB deletion; PocketOS-2026 |
| **F2** credential firewall | `init/` + a pre-flight in `hooks/session-end.sh`/start; per-`/queue` isolated env (§3e/§6 "partially") | stale `.env.local` → prod silently re-arms the 24/25 failure |
| **F3** egress allowlist | `harness-manifest.json` (op-level grants) + hook reading it (GATED Fork-F4) (§3e absent) | Cline-Feb-2026 supply-chain on unattended `npm install` |
| **F4** migration-credential | `docs/adr/0007-*.md` (decision); `block-dangerous-bash.sh` enforces (`db push` non-local) (absent) | highest-severity credential returns through the one legit hole |
| **F5** MCP trifecta gate | `harness-manifest.json` capability-tags + session/pre-tool guard hook (P0 for Slack/CI path only) (§3e absent) | scheduled agent reads PII + poisoned page → exfiltrate |
| **F6** verdict gate (KEYSTONE) | `.github/workflows/ci.yml` STOP-AUTHORITY job + `scripts/pr.sh` verdict artifact; `.cr-ok` = readiness only (absorbs C1) (§3f:229-231) | a loop merging because reviewers share the generator's blind spots |
| **F7** bounded-loop | cross-cutting contract in `goal/`,`lfg/`,`cr`,`debug`,`refactor` + counter on `hooks/session-end.sh` (absorbs C3) (§3c) | unattended agent spins forever, or 5 polished PRs solving the wrong problem |
| **F8** circuit breaker | stop-the-line marker in `/queue`,`/loop`,`/schedule` path; pairs with `ratchet/` (CMP2) (§3c/§3f) | fleet stacks 20 PRs on one broken assumption across 5 repos |
| **F9** disable-model-invocation | frontmatter on every side-effect skill (`lfg`,`queue`,`init`,deploy,migrate-apply); manifest tier (§3e 0/26) | autonomous loop invokes deploy/open-PR on model judgment |
| **HOOK-1** shared Stop surface | `hooks/session-end.sh` (one hook; C10/CMP5/F7/L7 are payloads); plugin `hooks.json` at extraction (§3e/§5 absent) | four overlapping Stop hooks fighting over the guard file |
| **C2** adversarial independence | `agents/reviewer.md` (isolated solution / shared canon; 3-4 rounds) (§3c/§3d) | reviewer inherits coder's rationalizations; OR canon-blind re-litigation |
| **C4** calibration | `skills/cr-calibrate/` + `.github/workflows/cr-calibrate.yml` + `golden-set/` (§6 phantom) | shipping autonomy on a gate with unknown miss-rate |
| **C5** governance lens | `agents/lens-*.md` criteria input = `docs/adr/`+Rejected+PITFALLS+golden-exemplars; `cr-security-classifier.yml` (§5/§4 absent) | reviewer lets a PR violate a locked ADR / rejected RLS-role rule |
| **C6** behavioral spec | `docs/specs/<feature>.md` + `agents/spec-writer.md`; `/feature` writes spec-first (absorbs C7 as F6+C6 config) (§3a/§4 absent) | behavioral drift — 5th cold-start edit silently breaks behavior |
| **C8** /verify render gate | `skills/verify/` + `.github/workflows/verify.yml` (headless leg) (§3c/§3f) | overnight UI-broken merge; wrong-tenant snapshot renders "fine" |
| **C9** agent-legible markup | `docs/design/` mandate + `architecture.md` shard + `jsx-a11y` ESLint (absent — zero `data-testid`) | every browser-verify run produces noisy guess-laden snapshots |
| **C10** evidence bundle | `hooks/session-end.sh` payload: `npm run test` + `tsc --noEmit` block-on-red; render = verify-if-present (CI-hard via C8) (§3e/§5 absent; capability-facts.md:18-20) | "done" + PR opened, regression ships, nothing re-ran the suite |
| **C11** money-math PBT | `fast-check` invariants on pricing module (GATED Fork-F6) (absent) | $30k-client wrong total; loop weakening its own oracle |
| **C12** TDD ledger | `docs/TESTING.md` (spec-derived oracle, VERBATIM) (grounding skills-C) | loop writes transcription tests — a mirror, not an oracle |
| **C13** model re-audit | `model:` fields across `agents/` set to Opus 4.8 (one-time; recurring half → CMP6) (§9) | the catch-the-error agents run on the cheapest model |
| **CMP1** read-path | `docs/RECURRING-FINDINGS.md` loaded into implementer task-start + decay (§4/§9) | agent repeats the same mistake-class every run |
| **CMP2** ratchet | `skills/ratchet/` (or `/compound` sub-phase) → hook/lint/lens criterion (§3e/§4) | re-finding the same bug forever instead of making it impossible |
| **CMP3** metrics ledger | in-repo/GitHub-canon ledger per agent-PR; cloud `/schedule` report (day-0 fields P0) (§4 absent) | "deployed then evaluated anecdotally" — self-improving on vibes |
| **CMP4** scan-context | `skills/scan-context/` + `scan-context.yml` (staleness + doc-fiction + decay; houses L5 ref-integrity) (§5/§6/§4 absent) | shipping a harness whose own canon is partly fiction |
| **CMP5** session-end capture | `hooks/session-end.sh` payload (proposes memory/PITFALLS candidate; human confirms) (§5 absent) | failures outpace hand-transcription; playbook ossifies |
| **CMP6** prune-PR + probes | `rituals.md` `/schedule` routine keyed to model version (subsumes C13-recurring) (§9) | outgrown scaffold accumulates; OR a model silently loses an assumed capability |
| **P1** plugin + marketplace | `.claude-plugin/marketplace.json` + `plugin/` (after convergence) (§8/§0 absent) | template-copy drift — every repo a hand-copied divergent folder |
| **P2** thin `/init` | `skills/init/` (materializes settings/guard content for a HUMAN to apply) (§3a/§8; capability-facts.md:42-46) | fresh install runs bare-default permissions + bare auto-mode |
| **P3** Notion→GitHub canon | DELETE `skills/notion-sync/`; canon mirrored to `agent-harness` git; `/compound` Step 8 re-pointed (§0/§7) | a distributed harness whose source-of-truth a cloud agent can't read |
| **P4** MCP-as-substrate | externally-summonable endpoints (`RemoteTrigger`-style) routing into the shell; F9 actuator (`ai-automation-ecosystem.md` absent) | the autonomy ceiling — harness can never be summoned |
| **P5** provenance governance | `.claude-plugin/plugin/UPSTREAM-DEPENDENCY-POLICY.md` + manifest disposition column; pin SHAs; dedup (§1) | malicious/low-quality upstream skill corrupts behavior across every repo |
| **P6** manifest contract | `.claude/harness-manifest.json` + per-skill frontmatter (single task-manifest owner) (§1/§3b absent) | an installer/agent that can't reason about its own skills |
| **P7** upstream disposition | `UPSTREAM-DEPENDENCY-POLICY.md` + manifest column (folds into P6 workstream) (§1/§8) | silent drift toward an upstream layout strands the fleet |
| **P8** push-back-up | `scope: project\|universal` field on the manifest promotion gate (human-gated PR) (§8 absent) | 5 repos drift apart; a fix in one never reaches the others |
| **P9** cross-repo context loop | `scan-context.yml` CI check + cloud `/schedule` scanner + repair-worker (GATED Fork-F7) (§5/§3f/§0/§7 absent) | undetected context rot, faster at fleet scale |
| **P10** roster as portable roles | `agents/` + `skills/` serialized via manifest into `plugin/` (after prune+dedup) (§11/§9) | distribution ships skills but loses the wired sub-agent fleets |

**Carry-forwards verified present** (not new builds): `agents/incident-responder.md` + `hotfix-guard.md`
(L6), `docs/specs/` 2 files (C6), `docs/TESTING.md` (C12), `agent-contract.md`, `diff-review.md`
(KEEP-VERBATIM human checkpoint), `AGENTS.md` golden-exemplars table + codebase map, `docs/design/`,
`rituals.md` — all `V1-TO-V2-CARRYFORWARD §A`.

---

## Honest budget summary (carry these numbers, not a flat total)

- **Budget (1) — agent-READ prose: large win.** PITFALLS monolith (558 lines) deleted → ~5–6 shards loading
  1–2 per task; memory.md (166 lines) merged then deleted; CLAUDE.md NEVER-section trimmed; ~64 rules out of
  prose. **Copies-per-fact 3→1.** Per-`/cr` PITFALLS cost ~172 KB → a fraction.
- **Budget (2) — deterministic enforcement: ~+9–11, every item §9-justified and that is fine.** +2 hooks
  (`block-dangerous-bash`, `session-end`), +5 CI jobs (stop-authority on `ci.yml`, cr-security-classifier,
  cr-calibrate, verify, scan-context), +3 scripts (`gen-rules`, `migration-lint`, `repo-structure`), +1
  manifest, +5–6 rule shards, +the `.claude-plugin/` tree, +`golden-set/`. ASK-first deps: `dependency-cruiser`
  (L2), `fast-check` (Fork-F6), `jsx-a11y` (C9).
- **Knowledge files net ≈ −2 to −3; total tracked files ≈ flat (+1 to +2).** The charter dropped
  file-count-as-redflag; what changed is the *kind* of file — forgeable prose down, unforgeable enforcement up.
- **Biggest raw byte cuts (out of skim, not the budget axis):** 7 stale worktrees (NEEDS-HUMAN, each a full
  repo copy) > `.claude/` scratch (~48 KB) > PITFALLS 43 KB sharded > memory.md 10 KB merged.

---

## Open forks this tree surfaces (do not resolve unilaterally)

The tree's exact shape depends on these VISION forks — each named so a downstream builder doesn't bake in an
answer:

- **Fork F1** (verdict-artifact surface: PR comment vs body vs committed `review/` file vs Checks API) → fixes
  whether F6's artifact is a `docs/`/`review/` file or pure CI. **Drawn here as: `scripts/pr.sh` posts + `ci.yml`
  enforces** (placeholder pending ratification).
- **Fork F4** (egress depth / local-unattended first-class?) → decides if `F3` egress hook + op-level manifest
  grants are P0 or P1. **Drawn here as GATED.**
- **Fork F5** (`managed-settings.json` now vs committed-settings + social rule) → decides whether `/init`
  materializes a managed file or only local. **Drawn here as: `/init` prepares content, human applies.**
- **Fork F8** (`/dev` vs `/feature` as `/lfg`'s canonical single-task driver) → resolve BEFORE building `lfg/`
  so the orchestrator doesn't bake in a duplication.
- **Fork F10** (convergence scope as publish gate: resolve all 9 §7 contradictions first, or publish from a
  declared-precedence snapshot) → gates when `.claude-plugin/` can exist.
- **RECONCILIATION D1** (ADR disposition: project into rules as `kind: decision` + keep `docs/adr/` long-form —
  recommended). **Drawn here as: both** (`docs/adr/` kept + decisions referenced in shards).
- **RECONCILIATION D8** (ratify the two-budget reframe — accept ~flat total as the price of determinism).
  **This whole tree assumes D8 = accepted.**
```
