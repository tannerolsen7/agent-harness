# V2 Traceability Matrix — every decision → build status

**Purpose:** guarantee the build delivers *exactly* the V2 we planned, with nothing dropped or drifted. Every
locked decision from `docs/v2-audit/ROUND-4-DECISIONS-AND-HANDOFF.md` is listed here with its phase, status, and
artifact. **The planning is DONE — this is the execution checklist.** Update the Status column as the build
lands each item; verify against this per phase. Source of truth for *what V2 is* = `ROUND-4-DECISIONS-AND-HANDOFF.md`
(the detail) + `BUILD-PLAN.md` (the phase order). Notion is the V1 base/meta-docs only — NOT the V2 spec.

Status key: ✅ done · 🔄 in progress · ⬜ todo · ➡️ deferred (Phase 5 / post-launch by decision)

---

## Cross-cutting principles (must hold in every task — verify in `/cr`)
| Principle | Decision | Status |
|---|---|---|
| Project-agnostic (no project's specifics baked in; adapters/roles) | R4-D10, project-agnostic correction | 🔄 host-agnostic pr.sh ✓; roster genericization pending |
| Locks are the sole safety net | R4-D8 | ✅ Phase 0 |
| Deterministic > advisory (mechanical rules → hooks/lint, not CLAUDE.md) | R4-D33 | ⬜ Phase 4 audit |
| One capable pass; spawn only for independence/parallelism/scale | R4-D21 | ⬜ Phase 1 (spawn doctrine) |
| Comments earned (why, never what) | R4-D26 | ⬜ Phase 3 lint |
| Human starts + merges everything | R4-D7, R4-D1 | ✅ (no auto-merge; PR-based) |
| Frictionless handoff (checklist + commands every handback) | R4-D24 | ⬜ Phase 2 |
| Honest claims (un-fakeable = the test re-run only; never fake human metrics) | R4-D16, R4-D7#4 | 🔄 F6 ✓; UX no-fake pending |
| Plain-language standard for founder-facing docs | R4-D5 | ✅ (standard) |

## Step 0 — Foundation: migrate the FULL canon (base to transform — NOT "V2" itself)
| Item | Decision | Status |
|---|---|---|
| Migrate ALL universal skills (genericized) | R4-D30, roster | ✅ 21/21 universal present — PR-B added cr-security, incident, hotfix, post-mortem, migrate, behavior-change, perf, spike, prioritize-tasks, review-strategy, setup-strategy, design, evaluate-solution (Supabase/RLS/teamId/src-data → DB-safety adapter + tenant/owner/data-access-layer). Asserted in harness-smoke.test.sh. (dep-update cut + notion-sync→github-sync in PR-D; explain stays user-only.) |
| Migrate ALL 23 agents (genericized) | roster | ✅ 23/23 — PR-A added incident-responder, security-reviewer, refactor-extractor, solution-evaluator, doc-updater, ux-reviewer (genericized: legacy tool names → modern; RLS/tenant/src-data → adapter language; backend-specific checks → DB-safety adapter). Asserted in harness-smoke.test.sh. |
| Vendor borrowed skills (grill-with-docs ✓, simplify, to-issues) | R4-D17 | 🔄 grill-with-docs ✓; simplify/to-issues pending |
| Adopt zoom-out / write-a-skill / prototype / triage / to-prd | R4-D17 | ⬜ |
| Drop dep-update (empty); notion-sync → github-sync | roster, R4-D30 | ⬜ |
| Keep evaluate-solution | R4-D13 | ✅ migrated (PR-B) |
| Migrate Notion canon docs (four layers, principles, templates, meta-system) → docs/ | R4-D10 (P3) | ⬜ |
| supabase/* NOT in universal harness (per-project adapter) | project-agnostic | ✅ (correctly excluded) |

## Phase 0 — Safety floor (DONE)
| Item | Decision | Status |
|---|---|---|
| block-dangerous-bash.sh (fail-closed, full scope) | R4-D8, security CRITICAL-2 | ✅ |
| credential firewall / block-credential-read.sh | R4-D8, security CRITICAL-1 | ✅ |
| egress control (block-egress.sh) | security CRITICAL-3 | ✅ |
| fail-closed existing hooks | security HIGH-1 | ✅ (hooks-fail-closed.test.sh) |
| managed-settings.json (OS-level) + installer | R4-D7#5, security HIGH-2 | ✅ (template + install-locks.sh) |
| disable-model-invocation on side-effect skills | R4-D8 (F9) | ⬜ verify |
| worktree G1 (npm-install + assert husky shim) | worktree review G1 | ✅ (assert-husky-shim.sh) |
| worktree G2 (standardize `.claude/worktrees/<slug>`) | worktree review G2 | ⬜ verify |

## Phase 1 — Trust (IN PROGRESS)
| Item | Decision | Status |
|---|---|---|
| Bug-catch test (real-defect, build-first, auto-grow) | R4-D32#1, R4-D27 | ✅ starter (8 cases + score.sh) — verify real-defect seeding + auto-grow |
| F6 un-forgeable CI verdict gate (host-agnostic) | R4-D7#4 | ✅ |
| Routing-assertion gate | R4-D32#3 | ✅ |
| C5 governance/canon pass in /cr | R4-D14b, C5 | ✅ |
| Host-agnostic pr.sh (gh/glab) | R4-D7, project-agnostic | ✅ |
| 4-lens adversarial reviewer + lenses | C2 | 🔄 lens agents present; verify wired |
| Collapse 9 analytical passes → 1 + lint, GATED on bug-catch test | R4-D20, R4-D32 | ⬜ (the 9→1 question — yes, gated; keep splits where recall drops) |
| Model tiers by ROLE + re-audit on model-id change | R4-D31, R4-D32#4 | ⬜ |
| Skill-routing reliability: sharp descriptions (oblique/regression/screenshot) + classify-AND-route + no empty stubs | R4-D31 | 🔄 /debug triggers broadened + work-state table routes to /debug + classify-AND-route rule (debug-process PR); no-empty-stub lint ✅ (PR-C). Debug process verified sound: /debug → @investigator → /feature/hotfix; /incident → @incident-responder → /debug. Broaden other skills' triggers as field misses surface. |
| Bounded-loop + REJECT | F7 | ⬜ |
| Classifier guard (over-classify when unsure; in bug-catch) | R4-D32#5 | ⬜ |

## Phase 2 — The loop (TODO)
| Item | Decision | Status |
|---|---|---|
| One adaptive build command + /goal | R4-D7#3 | ⬜ |
| Strict before-coding gate: data shape → UX → UI mockup | R4-D4 | ⬜ |
| Design phase: 1 designer (schema+API+front-end) + grill; framework-adapted | R4-D14/14a/14b | ⬜ |
| Feature-doc-as-hub + patterns/golden-exemplars registry | R4-D9, R4-D25 | ⬜ |
| Incident subsystem carry-forward; security response human-driven (isolate+log) | R4-D11, L6 | ⬜ |
| Learning loop (read-path + ratchet) + reference-integrity check | CMP1/CMP2/CMP4 | ⬜ |
| Selective context (slice, not dump); retrieval-recall measure | R4-D20#4, R4-D32#6 | ⬜ |
| Narration + shared Stop-hook | L7, HOOK-1 | ⬜ |

## Phase 3 — Quality systems (TODO)
| Item | Decision | Status |
|---|---|---|
| Design-system bootstrap-if-missing | R4-D22 | ⬜ |
| UI: design-system-only + token-lint + impeccable detector + gated design-review + /compound feedback | R4-D15, R4-D23, R4-D30 | ⬜ |
| UX: tiered reviewer + axe gate + feature-doc targets; never fake human metrics | R4-D16 | ⬜ |
| Red-team pass (scoped to security-sensitive diffs) | R4-D12 | ⬜ |
| Perf: Core-Web-Vitals budget, measured+logged+warn | R4-D19 | ⬜ |
| Data-state matrix (no/some/lots/bad/loading; no page shift); loading per-project | R4-D18 | ⬜ |
| Clean-code / comments-earned (lint) | R4-D26 | ⬜ |
| Tests verified by delete-the-code + break-the-code (mutation) | R4-D27 | ⬜ |
| a11y lint (data-testid/aria) | R4-D3 | ⬜ |

## Phase 4 — Fleet / platform (TODO)
| Item | Decision | Status |
|---|---|---|
| GitHub canon (single source of truth) | R4-D10 (P3) | 🔄 (repo exists; full migration pending) |
| Pin + vendor borrowed skills; per-skill frontmatter | R4-D17, P6 | ⬜ |
| Self-contained add-on + thin /init + sync-harness.sh | R4-D10 | ⬜ |
| Deep AI-activity dashboard (per task: commit, trigger, model, skills/agents) | R4-D29, R4-D6 | ⬜ |
| CLAUDE.md→hooks ratchet audit | R4-D33 | ⬜ |
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
