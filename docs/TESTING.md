# TESTING — confirmed behaviors

Confirmed behaviors for the harness's own tooling. Each entry is a behavior a test
checks, not an invented requirement. Per-project work adds its own entries.

---

## Token linter (`scripts/token-lint.sh`)

Enforces design-system token usage in UI files. Catches hardcoded colors and
spacing, and flags six absolute design bans that are never acceptable regardless
of token use. Activated the moment `docs/design/DESIGN.md` exists in the repo.

### Confirmed behaviors

- **Token-only file passes:** A CSS file that uses only `var(--...)` references
  for colors and spacing exits 0 with no violations.
- **Hardcoded 6-digit hex exits non-zero:** A file containing a bare `#RRGGBB`
  value (not inside a `var()` call) causes the linter to exit 1 and name the
  violation in the output.
- **Hardcoded 3-digit hex exits non-zero:** A file containing a bare `#RGB` value
  (not inside a `var()` call) causes the linter to exit 1 and name the violation.
- **Raw color function exits non-zero:** A file using `rgb()`, `rgba()`, or
  `hsl()` directly causes the linter to exit 1 and mention the function name.
- **Ban — gradient text:** A file with `background-clip: text` (the CSS gradient-text
  pattern) causes the linter to exit 1 and mention "gradient" in the output.
- **Ban — glassmorphism:** A file with `backdrop-filter: blur` causes the linter
  to exit 1 and mention "glassmorphism" in the output.
- **Ban — side-stripe border (3px+):** A file with `border-left: 4px solid` causes
  the linter to exit 1 and mention "side-stripe" in the output.
- **Side-stripe 1px (divider) is allowed:** A file with `border-left: 1px solid`
  exits 0 — 1px is a functional divider, not a decorative stripe.
- **Ban — hero-metric template:** A file containing the class name `hero-metric`
  causes the linter to exit 1 and mention "hero-metric" in the output.
- **Warning — identical card grid:** A file containing the class name `card-grid`
  emits a warning and exits 0 (warning, not a hard error — human review required).
- **Warning — eyebrow label:** A file containing an `eyebrow` class emits a warning
  and exits 0 (one eyebrow per page may be acceptable; human review required).
- **Missing DESIGN.md skips without blocking:** When `docs/design/DESIGN.md` does
  not exist, the linter exits 0 and prints a message naming the missing file and
  telling the user to run `@design-synthesizer` to create it.

---

## Progress auto-updater (`scripts/update-progress.sh`)

The script updates the mechanical fields in `harness-progress.html` —
the date, PR count, and progress bar — and writes a visible "last
auto-updated" line so you can tell at a glance that it ran and what changed.

### Confirmed behaviors

- **Last-updated line shows time and what changed:** Given `harness-progress.html`
  has an `auto-update-status` element, when `update-progress.sh` runs, it replaces
  that element's text with "Last auto-updated: [date] at [time] · [old]→[new] PRs"
  when the PR count changed, or "Last auto-updated: [date] at [time] · [N] PRs (no change)"
  when the count was already current.

---

## Pre-push hook (`.husky/pre-push`) — branch from push ref-list

The pre-push hook validates a `.cr-ok` sentinel before any non-interactive push is
allowed. The sentinel records `branch:sha` — the branch and commit that `/cr` ran on.
The hook must read the branch being pushed from git's stdin ref-list, not from `HEAD`,
so that pushing a branch from a worktree not checked out on that branch still checks
the right sentinel.

### Confirmed behaviors

- **Branch name comes from push ref-list, not HEAD:** When git calls the hook with
  `refs/heads/feat/x` in stdin and `HEAD` points to a different branch, the hook
  validates the sentinel for `feat/x`, not for the HEAD branch. A sentinel written
  for `feat/x:SHA_feat_x` allows the push; a sentinel written for a different branch
  blocks it.

---

## PR opener (`scripts/pr.sh`) — merge conflict check

`pr.sh` verifies the branch merges cleanly into the remote base branch before
consuming the `/cr` sentinel. This is a safety net: `/cr` runs the same check
as its first step, and `pr.sh` re-runs it as a last guard in case the branch
received a commit after `/cr` ran.

### Confirmed behaviors

- **Conflict detection aborts before sentinel consumption:** Given a branch
  where the same file has conflicting changes in HEAD versus `origin/<base>`,
  when `pr.sh` runs non-interactively with a valid `.cr-ok` sentinel, it exits
  non-zero and leaves the sentinel intact — the sentinel is still there once
  the conflicts are resolved and the user retries.

- **Clean branch passes conflict check:** Given a branch where both HEAD and
  the base branch have advanced independently with no overlapping file changes,
  when `pr.sh` runs non-interactively with a valid `.cr-ok` sentinel, it exits
  zero and the PR proceeds normally.

- **Base branch detected dynamically:** The merge check reads the base branch
  from `git remote show origin`, falling back to `main` if the remote HEAD
  cannot be determined (including when the remote reports `(unknown)`).

---

## Install system (`scripts/install.sh`, `scripts/sync-harness.sh`, `scripts/install-harness-hooks.sh`)

`install.sh` copies harness files into a target git repo and writes a manifest. `sync-harness.sh`
reads the manifest and updates harness-owned ("copy") files while leaving project-owned
("create-once") files alone. `install-harness-hooks.sh` wires husky into the target's package.json.

### Confirmed behaviors

- **Install creates files and manifest:** Given a valid git repo as the target, `install.sh` copies
  category-1 files, creates category-2 files from templates, and writes `.claude/.harness-manifest.json`.
  Exits 0.

- **Non-git target is rejected:** Given a directory that is not a git repository, `install.sh` exits
  non-zero with a clear message asking the user to run `git init` first.

- **Re-run preserves create-once files:** Given `install.sh` has already run and `CLAUDE.md` exists
  in the target, running `install.sh` again does not overwrite `CLAUDE.md` — it reports "skipped (exists)".

- **Sync updates a copy file:** Given a copy file in the target that matches the manifest sha (unmodified),
  and the same file has changed in the harness source, `sync-harness.sh` overwrites the target file
  and exits 0.

- **Sync skips a create-once file:** Given `CLAUDE.md` exists in the target (unmodified or edited),
  and the template in the harness source has changed, `sync-harness.sh` does not overwrite `CLAUDE.md`.

- **Sync exits non-zero on conflict:** Given a copy file that the user edited locally AND has also
  changed in the harness source (three-way divergence: local != manifest sha != upstream), `sync-harness.sh`
  exits non-zero and prints the file path. The local file is left untouched.

- **Sync leaves a user-only edit alone:** Given a copy file that the user edited but the harness
  source has not changed (local != manifest sha, but manifest sha == upstream sha), `sync-harness.sh`
  exits 0 and does not overwrite the file.

- **Sync re-creates a deleted copy file:** Given a copy file that was deleted from the target,
  `sync-harness.sh` re-creates it from the harness source.

- **Sync re-creates a deleted create-once file:** Given a create-once file (e.g. `CLAUDE.md`) that
  was deleted from the target, `sync-harness.sh` re-creates it from the template.

- **Missing manifest blocks sync:** Given no `.claude/.harness-manifest.json` in the target,
  `sync-harness.sh` exits non-zero with a message telling the user to run `install.sh` first.

- **Hook paths in settings.json exist in the harness tree:** Every hook script path referenced
  in `.claude/settings.json` via `$CLAUDE_PROJECT_DIR/...` exists as a real file.

- **settings.json has no autoMode.environment block:** `autoMode.environment` has been removed;
  project-specific context belongs in `CLAUDE.md`, not in `settings.json`.

- **install-harness-hooks creates package.json when none exists:** Given a target with no
  `package.json`, running `install-harness-hooks.sh` creates one with `prepare` and `test` scripts.

- **install-harness-hooks protects an existing prepare script:** Given a `package.json` that
  already has a `prepare` script, `install-harness-hooks.sh` exits non-zero and prints the
  manual steps rather than overwriting the existing prepare.

---

## Performance budget (`scripts/perf-budget.sh`)

Measures Core Web Vitals (LCP, CLS, INP) against per-project targets. Exits 1 when any metric
exceeds its budget so `ci-verify.sh` can catch the breach with `||`; exits 0 when all metrics
pass. Never blocks the build — advisory only.

### Confirmed behaviors

- **Pass path:** When all three metrics are within budget, exits 0, prints a `pass` line for each metric, and prints the `OK` summary. No `WARN` lines appear in the output.
- **Warn path:** When a metric exceeds its budget, exits 1, prints a `WARN` line naming the metric and showing the measured value vs the budget, and prints the `WARNING` summary.
- **Config override:** A `perf-budget.config.sh` file at the project root overrides the default budgets. A metric that passes the default but fails the tighter config triggers a `WARN` line.
- **Curl fallback:** When `lighthouse` is not available, the script measures LCP via `curl` response time and sets CLS and INP to 0 (they cannot be measured without a browser). CLS and INP always pass in curl mode.

---

## Worktree setup (`scripts/worktree-add.sh`)

`worktree-add.sh` creates a git worktree for a given branch. When the branch
name follows the `feat/<slug>` pattern and `TASKS.md` exists at the repo root,
the script also marks the matching task as in-progress in `TASKS.md`.

### Confirmed behaviors

- **In-progress marker written on worktree create:** Given `TASKS.md` contains
  `- [ ] Some task` followed (within the same task block) by `  Slug: <slug>`,
  when `worktree-add.sh <path> feat/<slug>` runs, `TASKS.md` is updated so the
  task header reads `- [~] Some task`. Other tasks in the file are not changed.

- **Non-feat branches leave TASKS.md unchanged:** Given a branch name that does
  not start with `feat/`, when `worktree-add.sh` runs, `TASKS.md` is not
  modified and the script exits 0.

- **Missing TASKS.md is not an error:** Given `TASKS.md` does not exist at the
  repo root, when `worktree-add.sh` runs, the script exits 0 and no TASKS.md
  update attempt is made.

---

## Context slicer (`scripts/slice-context.sh`)

The slicer turns a source file into a compact outline: the lines that declare
functions, classes, types, and exports, plus the structural headers that tell an
agent where each declaration sits. It drops function bodies and other detail the
agent does not need to understand what a file offers. The task-runner uses it when
it assembles REFERENCES context for a specialist, so a specialist gets the
signatures relevant to its task instead of the full file.

### Confirmed behaviors

- **Signature extraction (the gated path):** Given a file path argument, the
  slicer prints declaration lines and drops body lines. For a JavaScript or
  TypeScript file it keeps lines that declare a `function`, an arrow-function
  `const` assigned a `=>`, a `class`, an `interface`, a `type`, or an `export`,
  and it drops the statements inside a function body.
- **Output is smaller than input:** For any file with at least one multi-line
  function body, the sliced output has fewer lines than the original file.
- **Header anchoring:** Markdown heading lines (`#`, `##`, …) and shell/Python
  comment-style section banners are kept, so the agent can see where in the file
  each kept line lives.
- **Missing file fails loud:** Given a path that does not exist, the slicer prints
  an error to stderr and exits non-zero. It never prints a partial or empty slice
  as if it were a real result.
- **No path given fails loud:** With no file-path argument the slicer prints a
  usage message to stderr and exits non-zero.
- **Unknown file type falls back safely:** For a file type the slicer has no rules
  for, it prints the whole file rather than silently dropping content. A safe
  fallback never hides code from the agent.

## AI activity dashboard

Records one entry per top-level session stop and shows the full history in a
browsable HTML page committed to the repo.

### Confirmed behaviors

- **Session start writes temp file:** When `session-start.sh` runs and hook stdin
  JSON contains a `session_id` and `model`, it writes
  `/tmp/claude-activity-{session_id}` with a single line of the form
  `{start_unix_ts} {model}` — a Unix timestamp and the model string,
  space-separated.

- **Subagent stop writes no record:** When `session-stop.sh` runs and hook stdin
  JSON contains a non-empty `agent_type`, the hook exits without writing anything
  to `.claude/activity/`. Only top-level session stops produce records.

- **Top-level stop writes a valid JSONL record:** When `session-stop.sh` runs with
  no `agent_type` in hook stdin, it appends one valid JSON object to
  `.claude/activity/{branch-slug}.jsonl`. The object contains `ts` (ISO-8601 UTC),
  `branch`, `sha`, `model`, `skills` (array), and `duration_s` (integer or null).

- **Missing temp file yields null duration:** When the session temp file
  `/tmp/claude-activity-{session_id}` does not exist at stop time, the written
  record has `duration_s` set to `null` — not `0` and not omitted — and `model`
  set to `"unknown"`.

- **Skills are extracted and deduplicated:** The written record's `skills` array
  holds only the names of Skill calls found in the session permission log,
  deduplicated, with no duplicates. When the log is empty or absent, `skills`
  is `[]`.

- **activity-report.sh writes harness-activity.html:** Running
  `scripts/activity-report.sh` reads all `.claude/activity/*.jsonl` files and
  writes `harness-activity.html` with a summary bar (total sessions, top-3 skills,
  average duration excluding nulls) and a sessions table ordered newest-first
  (columns: Date, Branch, SHA, Model, Skills, Duration).

- **Bad JSONL line is skipped, not fatal:** A malformed line in any
  `.claude/activity/*.jsonl` file does not stop the report from completing. Valid
  records before and after the bad line still appear in the output.

- **update-progress.sh calls activity-report.sh:** Running
  `scripts/update-progress.sh` also regenerates `harness-activity.html` so the
  dashboard stays fresh at every session start.
