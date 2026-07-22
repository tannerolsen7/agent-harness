# V2 Traceability Matrix — every decision → build status

**Purpose:** guarantee the build delivers *exactly* the V2 we planned, with nothing dropped or drifted. Every
locked decision from `docs/v2-audit/ROUND-4-DECISIONS-AND-HANDOFF.md` is listed here with its phase, status, and
artifact. **The planning is DONE — this is the execution checklist.** Update the Status column as the build
lands each item; verify against this per phase. Source of truth for *what V2 is* = `ROUND-4-DECISIONS-AND-HANDOFF.md`
(the detail) + `BUILD-PLAN.md` (the phase order). Notion is the V1 base/meta-docs only — NOT the V2 spec.

Status key: ✅ done · 🔄 in progress · ⬜ todo · ➡️ deferred (Phase 5 / post-launch by decision)

> **Code-verified update (2026-07-13).** A full read of the repo confirms the build has advanced past what several cells below showed. Corrected in this pass: **Phase 3 is DONE** (every quality script/agent exists and was merged); Phase 2's designer+grill, feature-doc hub, and incident subsystem are **built**; Phase 4's vendor/frontmatter, install/sync/plugin, and the activity dashboard are **built**. The agent roster is now **26** (not 23). Still genuinely open: the P0 unify-execution-paths work, GitHub-canon completion, the full CLAUDE.md→hooks audit, multi-repo rollout, and all Phase-5 autonomy (deferred by decision).

---

## Cross-cutting principles (must hold in every task — verify in `/cr`)
| Principle | Decision | Status |
|---|---|---|
| Project-agnostic (no project's specifics baked in; adapters/roles) | R4-D10, project-agnostic correction | 🔄 host-agnostic pr.sh ✓; roster genericization pending |
| Locks are the sole safety net | R4-D8 | ✅ Phase 0 |
| Deterministic > advisory (mechanical rules → hooks/lint, not CLAUDE.md) | R4-D33 | ⬜ Phase 4 audit |
| One capable pass; spawn only for independence/parallelism/scale | R4-D21 | ✅ `.claude/SOUL.md` — spawn doctrine (independence/parallelism/scale) + two-layer model (deterministic BATTERY vs ad-hoc judgment) + governance (trust + log) |
| Comments earned (why, never what) | R4-D26 | ⬜ Phase 3 lint |
| Human starts + merges everything | R4-D7, R4-D1 | ✅ (no auto-merge; PR-based) |
| Frictionless handoff (checklist + commands every handback) | R4-D24 | ✅ `/handoff` skill (`.claude/skills/handoff/`) — emits done / in-progress / needs-human / exact-continue-commands / links; honest-state + exact-commands rules. (Optional future: a Stop-hook that auto-emits it — guard file, deferred.) |
| Honest claims (un-fakeable = the test re-run only; never fake human metrics) | R4-D16, R4-D7#4 | 🔄 F6 ✓; UX no-fake pending |
| Plain-language standard for founder-facing docs | R4-D5 | ✅ (standard) |

## Step 0 — Foundation: migrate the FULL canon (base to transform — NOT "V2" itself)
| Item | Decision | Status |
|---|---|---|
| Migrate ALL universal skills (genericized) | R4-D30, roster | ✅ 21/21 universal present — PR-B added cr-security, incident, hotfix, post-mortem, migrate, behavior-change, perf, spike, prioritize-tasks, review-strategy, setup-strategy, design, evaluate-solution (Supabase/RLS/teamId/src-data → DB-safety adapter + tenant/owner/data-access-layer). Asserted in harness-smoke.test.sh. (dep-update cut + notion-sync→github-sync in PR-D; explain stays user-only.) |
| Migrate ALL 23 agents (genericized) | roster | ✅ 23/23 — PR-A added incident-responder, security-reviewer, refactor-extractor, solution-evaluator, doc-updater, ux-reviewer (genericized: legacy tool names → modern; RLS/tenant/src-data → adapter language; backend-specific checks → DB-safety adapter). Asserted in harness-smoke.test.sh. **(2026-07-13: 26 agent files now present — `designer`, `design-griller`, `design-synthesizer` added by the design-phase work.)** |
| Vendor borrowed skills (grill-with-docs ✓, simplify, to-issues) | R4-D17 | ✅ grill-with-docs ✓; to-issues vendored (PR-C, mattpocock@694fa30, MIT); simplify is a Claude Code built-in (not vendored — see VENDORED.md) |
| Adopt zoom-out / write-a-skill / prototype / triage / to-prd | R4-D17 | ✅ all 5 vendored (PR-C, mattpocock@694fa30, MIT). Provenance: .claude/skills/VENDORED.md. No-empty-description asserted in harness-smoke. |
| Drop dep-update (empty); notion-sync → github-sync | roster, R4-D30 | ✅ (PR-D) dep-update cut (never migrated); notion-sync NOT in V2 (obsolete under the Notion→GitHub move — canon lives in the repo, no sync-to-Notion). No `github-sync` skill: GitHub-canon *maintenance* = the Phase-2 reference-integrity check (CMP4), not a skill. Both kept out by a forbidden-skill guard in harness-smoke. |
| Keep evaluate-solution | R4-D13 | ✅ migrated (PR-B) |
| Migrate Notion canon docs (four layers, principles, templates, meta-system) → docs/ | R4-D10 (P3) | ✅ (PR-E) core canon migrated → `docs/engineering-system/` (README + 02 four-layers, 03 file-structure, 04 context-docs, 07 memory-system, 10 principles, 11 skill-ecosystems, 12 anti-rationalization, 13 model-capacity-audit, 14 git-discipline, templates) — genericized (stack/project specifics → universal patterns), Notion syntax stripped, cross-links relative. Skipped (per scope): research surveys (in docs/v2-audit/passes/), "to think about" futures (V2 decisions are in ROUND-4), V2 plan (superseded), redundant 05/06/08 + personal 09. Asserted in harness-smoke. |
| supabase/* NOT in universal harness (per-project adapter) | project-agnostic | ✅ (correctly excluded) |

## Phase 0 — Safety floor (DONE)
| Item | Decision | Status |
|---|---|---|
| block-dangerous-bash.sh (fail-closed, full scope) | R4-D8, security CRITICAL-2 | ✅ |
| credential firewall / block-credential-read.sh | R4-D8, security CRITICAL-1 | ✅ |
| egress control (block-egress.sh) | security CRITICAL-3 | ✅ |
| fail-closed existing hooks | security HIGH-1 | ✅ (hooks-fail-closed.test.sh) |
| managed-settings.json (OS-level) + installer | R4-D7#5, security HIGH-2 | ✅ (template + install-locks.sh) |
| disable-model-invocation on side-effect skills | R4-D8 (F9) | ✅ set on to-issues, to-prd, migrate, queue; zoom-out already had it; smoke guard added — platform trust only, no behavioral suppression test |
| worktree G1 (npm-install + assert husky shim) | worktree review G1 | ✅ (assert-husky-shim.sh) |
| worktree G2 (standardize `.claude/worktrees/<slug>`) | worktree review G2 | ✅ `.claude/hooks/worktree-create.sh` enforces `.claude/worktrees/$NAME` (line 20); calls `git worktree add` directly — does not delegate to `scripts/worktree-add.sh`; prune-branches.sh operates on `.claude/worktrees/` |

## Phase 1 — Trust (IN PROGRESS)
| Item | Decision | Status |
|---|---|---|
| Bug-catch test (real-defect, build-first, auto-grow) | R4-D32#1, R4-D27 | ✅ starter (8 cases + score.sh) — verify real-defect seeding + auto-grow |
| F6 un-forgeable CI verdict gate (host-agnostic) | R4-D7#4 | ✅ |
| Routing-assertion gate | R4-D32#3 | ✅ |
| C5 governance/canon pass in /cr | R4-D14b, C5 | ✅ |
| Host-agnostic pr.sh (gh/glab) | R4-D7, project-agnostic | ✅ |
| 4-lens adversarial reviewer + lenses | C2 | ✅ wired: reviewer.md tools: Task,Read,Glob + permissionMode: default; regression test agents/spawn-wiring |
| Collapse 9 analytical passes → 1 + lint, GATED on bug-catch test | R4-D20, R4-D32 | ➡️ Deferred — instrument not ready. Corpus needs ≥80 real escaped defects + rotating holdout + per-pass attribution before the gate is meaningful. Tracked in BACKLOG.md. |
| Model tiers by ROLE + re-audit on model-id change | R4-D31, R4-D32#4 | ✅ audit done (`docs/model-tier-audit.md`); all guard-file model changes applied by human: reviewer → opus, security-reviewer → opus, doc-updater → haiku; implementer never-touch rule added (regression gate + `.claude/agents/**`). |
| Skill-routing reliability: sharp descriptions (oblique/regression/screenshot) + classify-AND-route + no empty stubs | R4-D31 | 🔄 /debug triggers broadened + work-state table routes to /debug + classify-AND-route rule (debug-process PR); no-empty-stub lint ✅ (PR-C). Debug process verified sound: /debug → @investigator → /feature/hotfix; /incident → @incident-responder → /debug. Broaden other skills' triggers as field misses surface. |
| Bounded-loop + REJECT | F7 | ✅ `/cr` Step 3c: REJECT terminal state (wrong approach → paste-ready `gh pr close` + redirect, no sentinel, halt). Step 4: explicit 2-attempt ceiling; after attempt 2 → NEEDS HUMAN block with exact test command. |
| Classifier guard (over-classify when unsure; in bug-catch) | R4-D32#5 | ✅ classifier built (`scripts/classify-risk.sh`): deterministic path+content HIGH/MEDIUM/LOW; over-classify-when-unsure rule encoded; `bug-catch/run-classifier.sh` feeds TSV to `score.sh --traps`; 59 classifier tests pass; all 5 trap cases caught (100% trap recall, lower bound 56.6%); `path:` field added to cases 009–013 so the gate measures the classifier tier directly, not reviewer prose. |

## Phase 2 — The loop (TODO)
| Item | Decision | Status |
|---|---|---|
| One adaptive build command + /goal | R4-D7#3 | 🔄 **Decision: no dedicated front-door/router skill.** `/feature` IS the one adaptive front door — its Step 0 sizes Tiny/Small/Medium/Large and drives `/tdd` as the under-the-hood engine (R4-D7#3's "engine inside; no user choice"). A bare goal reaches it via native skill-dispatch on a sharp `description`, not a wrapper skill. A `/goal`→`/tdd`/`/feature` router was built (PR #22, merged) then removed — redundant: it duplicated `/feature` Step 0's sizing criteria, and `/tdd` is the engine, never a front-door peer (no front-door case routes to `/tdd`). Residual: keep `/feature`'s `description` sharp enough that bare goals route there reliably. **`/goal` continuation primitive (L2, run-until-graded) = decide later** — Anthropic ships a built-in `/goal` (v2.1.139) that natively provides it (separate checker model), which also resolves the T1-2 force-continue uncertainty. |
| Strict before-coding gate: data shape → UX → UI mockup | R4-D4 | ✅ `scripts/design-confirm.sh` writes the `design-confirmed` sentinel (`branch:sha`, dirty-tree refusal, audit log — mirrors `cr-ok.sh`); `tests/design-confirm.test.sh` (13 assertions). `/design contract` gains the before-coding gate: 3-section Design Questions sheet (data shape + Zod / edge cases / open questions robot can't answer) → adversarial grill → DB sub-step (migration SQL + Zod, schema approved alone first) → UI sub-step (rough mockup from `docs/design/`, look approved before build, PR screenshot) → sentinel. `/feature` Implementation gate reads `.claude/.design-confirmed` and refuses to code if absent/stale (Small+; Tiny exempt unless it touches DB/UI). |
| Design phase: 1 designer (schema+API+front-end) + grill; framework-adapted | R4-D14/14a/14b | ✅ `@designer` (179 lines: schema+API+front-end) + `@design-griller` (152) + `@design-synthesizer`; spawned by `/design contract` |
| Feature-doc-as-hub + patterns/golden-exemplars registry | R4-D9, R4-D25 | ✅ `docs/feature-doc-template.md` + `docs/patterns-registry.md` present |
| Incident subsystem carry-forward; security response human-driven (isolate+log) | R4-D11, L6 | ✅ `/incident` (424) + `@incident-responder` (217) + `/hotfix` + `/post-mortem` present |
| Learning loop (read-path + ratchet) + reference-integrity check | CMP1/CMP2/CMP4 | ✅ feat/learning-loop-integrity — read-back step in `@doc-updater` (CMP1), finding→enforcement ratchet in `/cr` Step 3b (CMP2), `scripts/check-integrity.sh` + `tests/check-integrity.test.sh` + CI wire-up (CMP4). CMP3 was not defined in the original plan; the gap is intentional. |
| Selective context (slice, not dump); retrieval-recall measure | R4-D20#4, R4-D32#6 | 🔄 slice built (`scripts/slice-context.sh`, used by `@task-runner`); retrieval-recall measure not built |
| Narration + shared Stop-hook | L7, HOOK-1 | 🔄 `.claude/hooks/session-stop.sh` (141) emits a handoff block (branch/commits/PR/worktrees/blocking-Qs); narration-into-context not built |

## Phase 3 — Quality systems (DONE — verified in code 2026-07-13)
| Item | Decision | Status |
|---|---|---|
| Design-system bootstrap-if-missing | R4-D22 | ✅ `docs/design/DESIGN.md` + `@design-synthesizer` + `scripts/design-system-validate.sh` |
| UI: design-system-only + token-lint + impeccable detector + gated design-review + /compound feedback | R4-D15, R4-D23, R4-D30 | ✅ `scripts/token-lint.sh` (318 lines, impeccable bans) + `@ux-reviewer` AI-tell scan; wired into `/cr` |
| UX: tiered reviewer + axe gate + feature-doc targets; never fake human metrics | R4-D16 | ✅ `.claude/agents/ux-reviewer.md` (458 lines — DMMT + personas + axe) (#48) |
| Red-team pass (scoped to security-sensitive diffs) | R4-D12 | ✅ `/cr-security` + `@security-reviewer` (scope-gated) |
| Perf: Core-Web-Vitals budget, measured+logged+warn | R4-D19 | ✅ `scripts/perf-budget.sh` + `docs/perf-budget.md` |
| Data-state matrix (no/some/lots/bad/loading; no page shift); loading per-project | R4-D18 | ✅ `scripts/data-state-lint.sh` |
| Clean-code / comments-earned (lint) | R4-D26 | ✅ `scripts/comment-lint.sh` |
| Tests verified by delete-the-code + break-the-code (mutation) | R4-D27 | ✅ `scripts/mutation-test.sh` (358 lines; loop-until-dry) |
| a11y lint (data-testid/aria) | R4-D3 | ✅ axe pass in `@ux-reviewer` Pass 3 |

## Phase 4 — Fleet / platform (IN PROGRESS — verified 2026-07-13)
| Item | Decision | Status |
|---|---|---|
| GitHub canon (single source of truth) | R4-D10 (P3) | 🔄 (repo exists; full migration pending) |
| Pin + vendor borrowed skills; per-skill frontmatter | R4-D17, P6 | ✅ `.claude/skills/VENDORED.md` (pinned SHA) + `scripts/skill-frontmatter-lint.sh` (#135) |
| Self-contained add-on + thin /init + sync-harness.sh | R4-D10 | ✅ `scripts/install.sh` + `sync-harness.sh` (195) + `/harness-setup` (was /init, #129) + plugin (#114–126) |
| Deep AI-activity dashboard (per task: commit, trigger, model, skills/agents) | R4-D29, R4-D6 | 🔄 dashboard built (`activity-report.sh` + `update-progress.sh` + HTML, #76); deep per-task fields (trigger/model/agents) partial |
| CLAUDE.md→hooks ratchet audit | R4-D33 | 🔄 partial — many rules enforced (#106); full audit still a P2 task (claudemd-to-hooks) |
| 5-repo sync | R4-D3 | ⬜ |

## Phase 5 — Post-launch (DEFERRED by decision, with triggers)
| Item | Decision | Status |
|---|---|---|
| Front door: GitHub-label / Slack-Linear summon / CI self-heal | R4-D1, L1 | ➡️ after launch |
| The clock (timer-based runs) | R4-D2, L4 | ➡️ after launch |
| Risk-based auto-approval (auto-merge LOW once catch-rate clears) | LOOP-7 | ➡️ catch-rate floor |
| Real-time access-control UI | R4-D34 | ➡️ |
| Fleet circuit breaker · plugin marketplace · push-back-up | F8, P1/P2/P8 | ➡️ |

---

**How to use this:** the build works top-to-bottom (Step 0 → Phase 0 → … ). After each item lands, flip its
Status and link the artifact. Before declaring a phase done, every row in that phase is ✅ or explicitly ➡️.
This file is how we *prove* V2 was built as planned — not re-planned.
