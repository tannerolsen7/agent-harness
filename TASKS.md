# TASKS.md

Task list for the agent-harness build. Each task is independent within its priority tier.
`/queue` runs the P1 items in parallel; humans merge everything.

Task status: `[ ]` not started · `[~]` in progress (open worktree) · `[x]` done (merged PR)

## Current State

_Verified against the code on 2026-07-13._

Phases 0–3 are done: the safety floor; the trust layer (un-forgeable CI gate, 4-lens reviewer, routing gate, and the risk classifier — `scripts/classify-risk.sh`, 59 passing tests); the before-coding design gate + learning loop; and the quality systems (token-lint, ux-reviewer/axe, perf-budget, mutation-testing, comment-lint, data-states — all merged). Phase 4 (fleet/platform) is mostly done — one-command install + sync (#72), the AI-activity dashboard (#76), the Claude Code plugin + marketplace (#114–#126), skill-frontmatter lint (#135), and the queue-stacking redesign (#105) all merged. Remaining Phase 4: full GitHub-canon migration, the complete CLAUDE.md→hooks audit, and multi-repo (fleet) rollout.

**Live open work:** [P0] unify the two execution paths — `/feature` (a prose pipeline) and `.claude/workflows/queue-execute.js` (the deterministic workflow run via `@task-runner`) build a feature two different ways and diverge: the queue path requires a pre-existing design instead of making one, skips `/simplify` and the manual checklist, and reviews with `@reviewer` instead of the full `/cr`. No design doc is written for the unify yet. [P1] the discovery → triage-inbox loop (nothing finds work but the human). [P2] remote-session commit/push gates, the CLAUDE.md→hooks audit, and agent-sandboxing.

**Unmerged WIP:** branch `feat/spec-layer` adds a per-feature behavioral-contract layer (`docs/specs/spec-layer.md`, `docs/templates/spec.md`) and further changes `/feature` — not yet merged.

All autonomy (bug→PR front doors, timers, risk-based auto-merge) stays deferred to Phase 5 by decision.

---

## P0 — Blocked / Needs Design First

- [x] AI activity dashboard — PR #76

- [ ] Unify the two execution paths: queue-execute.js as the one pipeline, /feature as its front-end
  Size: MEDIUM
  Slug: unify-execution-paths
  filesAffected: .claude/workflows/queue-execute.js, .claude/skills/feature/SKILL.md, .claude/skills/queue/SKILL.md, .claude/agents/task-runner.md
  Notes: The same feature lifecycle is implemented twice and the two copies already disagree.
  Path A is `/feature` (interactive prose in .claude/skills/feature/SKILL.md, re-interpreted by
  the model each run). Path B is `.claude/workflows/queue-execute.js` (deterministic Workflow:
  design gate → worktree setup → @task-runner per task → push + PR). Known divergences today:
  (1) the queue path hard-fails MEDIUM+ tasks without a `design:` ref (queue-execute.js
  `validateDesignGate`) while /feature runs the design phase itself; (2) the queue path never
  runs /simplify; (3) the queue path never runs the manual-checklist step. Every pipeline
  improvement currently has to be made twice, and the copies keep drifting. Proposed direction
  (to be validated by the design contract, not assumed): queue-execute.js becomes the single
  execution path; /feature becomes its interactive front-end — it gathers the human approvals
  (the approval packet, the /to-issues confirmation), then feeds the same deterministic pipeline
  the queue/webhook path uses. BLOCKED: run /design contract first and link the design doc here
  (`design: docs/features/unify-execution-paths.md`) before queuing. Done when: one pipeline
  implementation exists; /feature and /queue both drive it; the three divergences above are
  impossible by construction (one code path); both skills' SKILL.md docs describe the shared
  pipeline instead of restating it.

---

## P1 — Ready to Queue

- [ ] Discovery loop: scheduled scans deposit findings into a triage inbox
  Size: SMALL
  Slug: discovery-triage-inbox
  filesAffected: scripts/discovery-scan.sh, tests/discovery-scan.test.sh, docs/TRIAGE-INBOX.md, .claude/skills/scan-context/SKILL.md
  Notes: Nothing in the harness finds work except the human — rituals go overdue silently
  (scan-context reported CLAUDE.md 24 days past its 7-day review limit on 2026-07-11, with
  nothing prompting anyone to look). The missing piece is one bounded wire: a scheduled job
  that RUNS THE SCANS AND ACTS ON NOTHING. Build: (1) `scripts/discovery-scan.sh` — runs the
  existing read-only checks (`scripts/scan-context.sh`; a stale-branch audit via
  `scripts/prune-branches.sh` in a dry-run/report mode or `git for-each-ref` age listing;
  spec coverage: `docs/testing/` entries vs. tests; anything else already scripted and
  read-only) and appends findings with a date stamp to `docs/TRIAGE-INBOX.md`, deduplicating
  by finding text so re-runs don't spam. (2) The inbox doc has a header explaining the
  contract: the scanner only deposits; a human reviews the inbox; anything actionable flows
  through the normal gated pipeline (/feature, /debug, etc.) — the scanner must never edit
  other files, open PRs, or fix anything. (3) Scheduling: document (in the inbox header and
  the scan-context SKILL.md) how to wire it — a Claude Code routine/cron firing weekly that
  runs the script and surfaces new inbox entries; do not hand-roll a daemon. (4) Test:
  `tests/discovery-scan.test.sh` — a run on a fixture repo writes dated findings to the
  inbox, a second identical run adds nothing, and the script exits 0 with no other files
  modified. TDD required.
  Depends on: the /feature skill defect fixes (branch claude/skill-defects-efficiency-y56xdc) landing first.

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

- [ ] Remote session support in commit/push gates (human-only)
  Size: SMALL
  Slug: remote-session-gates
  filesAffected: .husky/pre-commit, .husky/pre-push, .claude/hooks/session-start.sh
  Notes: The commit/push hooks assume a local shared checkout and block managed remote
  sessions (fresh container, environment-designated branch). Three collisions, all observed
  live in a remote session on 2026-07-11: (1) the pre-commit and pre-push worktree gates
  require `.git` to be a FILE (dedicated worktree), but a remote container's clone has a
  `.git` DIRECTORY and no TTY, so every non-main commit/push is blocked even though the
  container IS the isolation; (2) the pre-push naming gate rejects environment-designated
  branch names like `claude/<slug>` (only feat|fix|refactor|chore|docs|test|perf|build|ci|
  style|revert pass), and the agent is forbidden from renaming the branch — and there is no
  agent-side bypass, since .claude/hooks/block-dangerous-git.sh (correctly) blocks
  `git push --no-verify`, so a remote session cannot push through local git at all; (3) the
  /dev/tty probe pattern is fragile in containers (see FLO-163 — the probe silently killed
  pushes).
  Proposed fix: the session-start hook detects a remote container (e.g. a marker the remote
  environment always provides) and exports/writes an explicit marker (e.g.
  `.claude/.remote-session`, gitignored); the worktree gates and the naming gate accept the
  marker path (worktree requirement waived, `claude/` prefix allowed) while every other gate
  (sync, merged-PR, .cr-ok sentinel) still applies. Fail closed: no marker → current
  behavior. While in .husky/pre-commit, also add the new `implementation-gate` script to the
  `_GATE_SCRIPTS` protected list (`scripts/implementation-gate.sh` is a gate now and should
  be operator-only like design-confirm.sh). Human-only: `.husky/*` and `.claude/hooks/*` are
  protected files agents cannot commit.

- [ ] Wire skill-frontmatter-lint.sh into .husky/pre-commit (human-only)
  Size: TINY
  Slug: wire-skill-frontmatter-lint
  filesAffected: .husky/pre-commit
  Notes: `scripts/skill-frontmatter-lint.sh` and `tests/skill-frontmatter-lint.test.sh` (feat/skill-frontmatter-lint) check `.claude/skills/*/SKILL.md` frontmatter (name/description present, name matches directory, description <=1024 chars, description contains "Use when"). The script is deliberately unwired — `.husky/pre-commit` is protected and only a human can edit it. Wire it the same way `shell-portability-lint.sh` is wired (grep staged files matching `^\.claude/skills/[^/]+/SKILL\.md$`, pass the list to the script). Use a NUL-delimited or `while read` loop rather than unquoted variable expansion, since unquoted expansion word-splits on spaces in filenames (see the existing `$STAGED_SHELL` pattern, which has the same latent issue). While in the file: extract the duplicated frontmatter-parsing awk one-liner (`awk '/^---$/{c++; next} c==1{print} c>=2{exit}'`, present both in the "Agent spawn lint" block and in the new script) into a shared helper so both call sites use one definition — see `docs/RECURRING-FINDINGS.md` → `duplicate-frontmatter-parser`. Done when: a malformed SKILL.md blocks a commit, a well-formed one doesn't, and both gates read frontmatter through the same shared code.

- [x] queue-execute: replace file-overlap stacking with explicit stacksOn field
  Size: SMALL
  Slug: queue-stacking-redesign
  filesAffected: .claude/workflows/queue-execute.js, .claude/skills/queue/SKILL.md
  Notes: Current stacking groups tasks by shared filesAffected paths and branches each task off the previous one's tip. This causes conflicts when tasks are squash-merged sequentially — squash creates new commit SHAs, so the stacked branch diverges from main. Fix: separate the two concerns. (1) Serialization (execution order) — tasks that share a file still run serially, not in parallel. (2) Branch base — every task branches from origin/main by default. Add an optional stacksOn: "<slug>" field to task objects; when present, the task branches from feat/<slug> instead of main. A task without stacksOn never gets stacked, even if it shares files with another task. Update queue/SKILL.md to document when to add stacksOn (only when task B calls or imports code written by task A) vs. when not to (two tasks that happen to edit different parts of the same file). Done when: tasks with shared files but no stacksOn branch from main and open PRs targeting main; tasks with stacksOn still branch from feat/<prevSlug>; tests cover both paths.

- [ ] Agent sandboxing approach — explore and decide who owns it
  Size: MEDIUM
  Slug: agent-sandboxing-approach
  Notes: The harness runs agents in git worktrees, which separates each task's filesystem writes. Hook guards prevent agents from touching specific files (husky/, settings.json, gate scripts). But a lot is still wide open — agents can run any shell command, read files outside the worktree, make network calls, and install packages. This task explores where the responsibility for tighter sandboxing belongs.

  Two candidate owners: (1) The harness — it controls how agents are spawned (queue-execute.js, worktree-add.sh, agent definitions). It could enforce a default-safe permission profile for all agents it runs, expose a `sandboxing:` field in task objects, or ship a standard allowedTools list in agent `.md` files. (2) The repo — each consuming project knows what agents need. Repos can configure `.claude/settings.json` with `allowedTools`, `permissions.deny`, and `permissionMode`. The harness can document the expected shape and let repos decide.

  The key question is whether the harness should pick a safe default that repos can loosen, or stay neutral and leave each repo to configure its own limits. Related questions to answer: Does Claude Code's `permissionMode: "default"` in agent definitions give us enough? Should worktree isolation extend to env vars (e.g., strip production credentials from agent subshells)? Should agents that run in CI have a stricter default than agents run locally?

  Done when: a short design doc (`docs/features/agent-sandboxing.md`) answers the ownership question with a clear rationale, documents what the harness will enforce vs. what it will leave to repos, and lists any follow-on implementation tasks.

- [ ] Audit CLAUDE.md rules and move to deterministic hooks
  Size: MEDIUM
  Slug: claudemd-to-hooks
  Notes: SERIALIZE — primary change touches CLAUDE.md (a shared, high-conflict file). Every rule in CLAUDE.md that can be enforced mechanically must become a hook or lint script, not a documented hope. This task audits every line of CLAUDE.md, creates hook scripts for the mechanically-enforceable rules, removes those lines from CLAUDE.md, and leaves only judgment-only guidance behind. Done when: each converted rule has a working hook script and test; CLAUDE.md is shorter by those rules; the harness enforces them on commit.

- [x] queue-execute: skip stacked PR when previous task was not pushed (@task-runner)
  Size: SMALL
  Slug: queue-stacked-pr-guard
  filesAffected: .claude/workflows/queue-execute.js
  Notes: /cr backlog from feat/queue-bs-clean. If task A in a stack lands commits but its /cr fails, A won't be pushed. Task B's PR would still open with --base feat/A, targeting a branch that never merges. GitHub only auto-retargets a stacked PR on merge — not on rejection. Fix: in the Push phase, track which task slugs were actually pushed (status: "pushed"). Before opening a stacked PR (--base feat/prevSlug), check that prevSlug is in the pushed set. If not, either open the PR targeting main with a warning comment, or skip with a clear message.

- [x] queue-execute: validate slug format before shell interpolation (@task-runner)
  Size: TINY
  Slug: queue-slug-validation
  filesAffected: .claude/workflows/queue-execute.js
  Notes: /cr backlog from feat/queue-bs-clean. Task slugs from user-supplied task objects are interpolated into shell commands inside createWorktreePrompt() — e.g. "bash scripts/worktree-add.sh .claude/worktrees/${task.slug} feat/${task.slug}". A slug like "my-task --force" would inject extra arguments. Fix: at the top of queue-execute.js, validate each task's slug against /^[a-z0-9-]+$/ before any work starts. If any slug is invalid, throw immediately with a clear message naming the offending slug.

- [x] worktree-add: verify ancestry after agent creates stacked worktree (@task-runner)
  Size: SMALL
  Slug: queue-ancestry-verify
  filesAffected: .claude/workflows/queue-execute.js, scripts/worktree-add.sh
  Notes: /cr backlog from feat/queue-bs-clean. The queue-execute workflow trusts that the agent ran the exact worktree-add.sh command with the right $3 base-ref. An agent that paraphrases or garbles the command could create a worktree on the wrong base, silently breaking git ancestry. Fix: after the worktree-create agent returns for a stacked task (baseRef !== null), run a direct bash check — `git -C .claude/worktrees/<slug> merge-base --is-ancestor feat/<prevSlug> HEAD` — not via an agent prompt. If the check fails, log an error and abort that stack group.
