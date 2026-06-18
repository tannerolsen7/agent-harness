# TASKS.md

Task list for the agent-harness build. Each task is independent within its priority tier.
`/queue` runs the P1 items in parallel; humans merge everything.

Task status: `[ ]` not started · `[~]` in progress (open worktree) · `[x]` done (merged PR)

## Current State

Phase 3 (Quality Systems) is done. Phase 4 is in progress — install, install hardening, AI activity dashboard, and pre-push fix all merged. Remaining: CLAUDE.md→hooks audit (P2) and fleet rollout.

---

## P0 — Blocked / Needs Design First

- [x] AI activity dashboard — PR #76

---

## P1 — Ready to Queue

- [x] One-command install for new projects
  Size: LARGE
  Slug: one-command-install
  design: docs/features/one-command-install.md
  Notes: Self-contained installer for any repo. Delivers: `scripts/install.sh` (copies harness files, writes manifest), `scripts/sync-harness.sh` (drift detection and update), `scripts/install-harness-hooks.sh` (husky/npm wiring, separate from install.sh), `/init` skill (interactive CLAUDE.md setup), and `docs/templates/` (CLAUDE.md + PITFALLS.md + AGENTS.md + CONTEXT.md starters with setup checklist at top). Three file categories: copy (harness always updates), create-once (template on first install, never touched again), never-installed (project knowledge — solutions, memory, TESTING.md). settings.json split: env block removed, project context moves to CLAUDE.md. See design doc for manifest format, drift algorithm, and full interface contract. Merged: PR #72.

- [x] Design system synthesizer
  Size: MEDIUM
  Slug: design-synthesizer
  Notes: Build the @design-synthesizer agent and the docs/design/ directory structure. The agent accepts 1–N source design systems — refero DESIGN.md files, described systems ("something like Linear"), or the user's own — and always produces exactly one output: docs/design/DESIGN.md. For a single source it normalizes and writes directly. For multiple sources it compares them across 12 axes (font, color strategy, spacing, elevation, motion, etc.), identifies conflicts vs. agreements, asks the user to resolve only the conflicts (all in one batch), then synthesizes a single coherent system. Sources are stored in docs/design/sources/. Output DESIGN.md must include 6 required sections (colors, typography, spacing, components, shapes, philosophy) plus an Agent Prompt Guide at the end. Done when: N=1 passthrough writes a normalized DESIGN.md without asking questions; N>1 conflict-detect → batch-interview → synthesize path produces a valid DESIGN.md with a synthesis log; tests verify both paths; docs/design/ structure is created on first run.
  Depends on: nothing (prerequisite for ui-token-lint)

- [x] UI token lint and design-system enforcement
  Size: MEDIUM
  Slug: ui-token-lint
  Notes: Lint every UI change for hardcoded colors and spacing — no raw hex, no px values outside a token reference. Reads the active design system from docs/design/DESIGN.md (written by @design-synthesizer). If DESIGN.md is missing, the linter exits with a clear message telling the user to run @design-synthesizer first. Also bakes in impeccable's 13 absolute bans as static checks (gradient-text class, glassmorphism patterns, side-stripe borders, hero-metric template, identical card grids, eyebrow-on-every-section, etc.) — detected via grep/class-name patterns. Gate `/cr` on design-system compliance. Outputs: `scripts/token-lint.sh` (linter + absolute-ban checks), a pre-commit hook entry, and a `/cr` check step. Done when: token-lint exits non-zero on a hardcoded hex value and zero on a token-only file; exits non-zero on each of the 13 absolute bans; exits with a clear error when docs/design/DESIGN.md is missing; tests cover all three paths.
  Depends on: design-synthesizer
  Merged: PR #67

- [x] UX reviewer with accessibility gate
  Size: MEDIUM
  Slug: ux-a11y-gate
  Notes: Extend the existing `ux-reviewer` agent to run axe accessibility checks as a third review pass. Regressions (a11y that was passing before this change broke it) are MUST FIX. New friction (a11y issues introduced alongside new UI) is flagged but not blocking. Never emit a fake human metric — axe results only. Done when: `ux-reviewer.md` has a Pass 3 axe section; regressions and new-friction are classified separately in the FRICTION REPORT; the agent description is updated.
  Merged: PR #48

- [x] Performance budget with measured warnings
  Size: MEDIUM
  Slug: perf-budget
  Notes: Define Core Web Vitals targets per project in a config file. Measure and log them on each build. CI warns (non-blocking) when a budget is breached. Never silently pass a breached budget. Outputs: `scripts/perf-budget.sh` (measure + compare), `docs/perf-budget.md` (default targets and how to override per project), a `ci-verify.sh` integration that runs the budget check and prints a warning on breach. Done when: a sample run logs LCP/CLS/FID targets vs. measured, warns on breach, exits 0 (warning only), and tests verify both pass and warn paths.

- [x] Mutation testing — verify tests by breaking the code
  Size: MEDIUM
  Slug: mutation-testing
  Notes: Automatically delete and corrupt implementation code to verify that tests actually fail when they should. This catches tests that always pass regardless of the implementation (vacuous tests). Outputs: `scripts/mutation-test.sh` that picks implementation files, applies simple mutations (delete a function body, negate a condition, swap a return value), runs the test suite, and reports which mutations survived (= untested code). The script uses a loop-until-dry pattern: each round randomly selects mutation targets, runs the suite, and records survivors. The loop stops after 2 consecutive rounds with no new survivors — this guarantees coverage saturation rather than a single random sample that may miss under-tested paths. Done when: the script runs against the harness's own shell tests, reports survivors, halts after 2 dry rounds, and a test in `tests/mutation.test.sh` verifies the mutation-detection path using a planted always-pass test.

- [x] Comments-earned lint and 6 data states required
  Size: MEDIUM
  Slug: comment-lint-and-data-states
  Notes: Two independent lint rules delivered together. (1) Comment lint: block comments that describe *what* the code does — only *why* comments are allowed. The code already says what; a comment restating it is noise. (2) Data state lint: every UI component must handle all 6 states: empty, loading, error, no data, some data, and lots of data. Missing states are flagged. Outputs: `scripts/comment-lint.sh` (regex-based what-comment detector), `scripts/data-state-lint.sh` (checks component files for all 6 state handlers), pre-commit hook entries for both, and tests covering each linter. Done when: comment-lint exits non-zero on a "what" comment and zero on a "why" comment; data-state-lint exits non-zero on a component missing any of the 6 states.

---

## P2 — Serialize After P1

- [ ] Audit CLAUDE.md rules and move to deterministic hooks
  Size: MEDIUM
  Slug: claudemd-to-hooks
  Notes: SERIALIZE — primary change touches CLAUDE.md (a shared, high-conflict file). Every rule in CLAUDE.md that can be enforced mechanically must become a hook or lint script, not a documented hope. This task audits every line of CLAUDE.md, creates hook scripts for the mechanically-enforceable rules, removes those lines from CLAUDE.md, and leaves only judgment-only guidance behind. Done when: each converted rule has a working hook script and test; CLAUDE.md is shorter by those rules; the harness enforces them on commit.
