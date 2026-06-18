# Patterns registry

Reusable, **multi-file** recipes — the canonical way to do a recurring thing that spans
several files in this codebase (R4-D25). The companion to the **golden exemplars** in
AGENTS.md: golden exemplars name one canonical *file* per layer to imitate; this registry
captures *recipes* that touch several files at once — e.g. "add a custom field," "subscribe
to a live data source," "add a new public endpoint."

<!-- context-meta
owner: <name>
last-reviewed: YYYY-MM-DD
review-frequency: on-merge
drift-signals:
  - file references that no longer exist
  - a recipe contradicted by a newer pattern or a changed golden exemplar
  - two entries describing the same recipe (should be merged)
-->

Read the relevant entry (just the one you need — not the whole file) before writing code that
matches a recipe here. Replicating the established pattern is how the codebase stays
consistent; inventing a second way to do the same thing is a review finding.

> Project-agnostic structure; the entries themselves are this project's own patterns. Starts
> empty and grows as features establish reusable recipes.

---

## How entries get added

Entries are written and updated by `/compound` after a feature merges (R4-D25). When a feature
introduces or changes a multi-file recipe worth replicating, `/compound` adds or updates the
entry here and links it from the feature's [feature doc](./feature-doc-template.md) →
"Patterns established."

Add an entry directly (outside `/compound`) only when a known recipe is identified that isn't
yet captured — same format.

**Do not add** single-file conventions (those are golden exemplars in AGENTS.md), one-off
solutions to a non-recurring problem (those are [`docs/solutions/`](./solutions/)), or generic
engineering advice.

---

## Entries

## resumable-overnight-batch-skill

**What:** Wire a skill to delegate long-running parallel work to a resumable Workflow, keeping interactive setup in the skill and unattended execution in the Workflow.

**When to use:** Any skill that runs N independent tasks overnight — where "session dies mid-run" is a real failure mode you want to recover from without re-running completed work.

**When NOT to use:** Tasks that require human decisions between items (use the skill directly, with interactive checkpoints). Single-task operations (overkill; just call `agent()` directly). Tasks where partial completion is worse than full restart.

**The recipe:**
1. **Skill (`.claude/skills/<name>/SKILL.md`)** — Steps 1–N are interactive. The final interactive step builds structured task objects (JSON) and calls `Workflow({ scriptPath, args: [tasks] })`. Steps after the Workflow call process its return value.
2. **Workflow (`.claude/workflows/<name>.js`)** — Three phases in order:
   - **Setup** — `parallel()` (a barrier): create one worktree per task with the idempotent `scripts/worktree-add.sh`. Parallel because all worktrees must exist before Execute starts, and creation is independent.
   - **Execute** — `pipeline()`: run one specialist agent (`agentType:`) per task. Tasks advance independently — task B can be in @reviewer while task A is still in @implementer.
   - **Push** — sequential `for...of`: push and open PRs for tasks with a valid sentinel. Sequential because `scripts/pr.sh` reads and deletes `.cr-ok`; concurrent calls on the same worktree race.
3. **Worktree script (`scripts/worktree-add.sh`)** — Add an idempotency guard at the top using `[ -f "$PATH/.git" ]` (see [2026-06-17-worktree-git-file-detection.md](./solutions/2026-06-17-worktree-git-file-detection.md)). This makes Setup safe to re-run on resume.
4. **Smoke test (`tests/harness-smoke.test.sh`)** — Assert the Workflow script file exists: `[ -f ".claude/workflows/<name>.js" ] || note "..."`. The skill silently breaks if the file is deleted.

**Golden exemplar:** `.claude/workflows/queue-execute.js` + `.claude/skills/queue/SKILL.md`.

**Established by:** PR #34 (feat/queue-workflow-specwriter-gates).

**Gotchas:**
- `resumeFromRunId` re-enters the Setup phase from the top — idempotent worktree creation is required, not optional.
- `pipeline()` in Execute, not `parallel()` — `parallel()` is a barrier (waits for all tasks) and kills the wall-clock benefit; `pipeline()` lets each task advance as fast as it can.
- Push must be sequential: `scripts/pr.sh` deletes `.cr-ok` on success; two pushes for the same task would race and one would fail validation.
- The Workflow has no pause-and-ask mechanism. Human approval of the task list must happen in the skill (Steps 1–2) before the Workflow is launched.
- **`isolation: 'worktree'` creates `agent/*` branches, not your `feat/*` branches.** If Execute uses `isolation: 'worktree'`, commits land on `agent/wf_<run-id>-<seq>` branches regardless of what the agent prompt says. Either drop isolation (pre-created worktrees are sufficient) or parse the actual branch name from the agent result and push that in Push. See [solution doc](./solutions/2026-06-17-workflow-isolation-worktree-branch-naming.md).

---

## learning-loop-read-back-and-ratchet

**What:** Wire the harness to read its own task output after a run and keep its knowledge docs current, plus catch broken cross-links in those docs before they rot.

**When to use:** Any project where context docs (CONTEXT.md, AGENTS.md, patterns-registry.md, PITFALLS.md, memory.md) must stay true to the code, and where the same review finding keeps showing up across PRs.

**When NOT to use:** A throwaway project with no long-lived context docs. A one-shot script with no review pipeline. Do not reach for the ratchet on a finding seen once — it earns a rule only after it recurs (Occurrences ≥3) or is judged high-impact.

**The recipe:**
1. **`/cr` skill (`.claude/skills/cr/SKILL.md`)** — Step 3b reads `docs/RECURRING-FINDINGS.md`, gives each finding a stable signature, and counts occurrences across PRs. Step "Promotion candidates" promotes any finding at Occurrences ≥3 (or judgment-flagged) into a `PITFALLS.md` entry and moves it Active → Promoted. This is the finding→enforcement ratchet: a trap seen three times stops being a per-PR note and becomes a rule the gate checks every time.
2. **`@doc-updater` agent (`.claude/agents/doc-updater.md`)** — the read-back step. After a task, the agent reads its own diff back against the context docs and proposes corrections for any doc that now describes the old behavior. It writes proposals to a draft (`.claude/compound-draft-<slug>.md`) for human review at PR time — never a direct edit, because a wrong "fix" to canon is worse than stale canon.
3. **`docs/RECURRING-FINDINGS.md`** — the cross-PR ledger. Active findings carry a signature, occurrence count, last-seen date, and locations; promoted ones move to a Promoted section. This is the state the ratchet reads and writes.
4. **`scripts/check-integrity.sh` + CI (`scripts/ci-verify.sh`)** — the reference-integrity check. It scans markdown docs for broken relative cross-links (a `[text](./x.md)` whose file is gone) and fails the PR before a reader hits the dead link. It skips external links, pure anchors, template placeholders (`<…>`), fenced code blocks, and inline-code spans. Wired into `ci-verify.sh` so it runs server-side on the PR's exact commit.

**Golden exemplar:** `scripts/check-integrity.sh` + `tests/check-integrity.test.sh` (the check + its hermetic tests); `.claude/agents/doc-updater.md` (the read-back agent).
**Established by:** feat/learning-loop-integrity (V2-TRACEABILITY.md → Phase 2 — the learning loop row).
**Gotchas:**
- The integrity check skips links inside inline code spans (backtick-wrapped) on purpose. Docs that *describe* another file's link format (e.g. how an external memory index looks) would otherwise trip a false positive on a file that does not live in this repo.
- The check verifies only the file half of a `path#anchor` link, not the heading anchor. Verifying anchors needs a full markdown parse and produces false positives on cased or generated headings; the file-exists check is the high-value, low-noise part.
- The ratchet's count lives in `RECURRING-FINDINGS.md`, not in the agent. If that file is reset, the count resets — promotions are driven by the ledger, so keep it under version control.
- `@doc-updater` proposes; it never writes canon directly. The draft-then-human-review boundary is the whole point: an agent editing PITFALLS.md or CONTEXT.md unattended can entrench a wrong claim.

---

## preflight-structural-guard

**What:** Add a structural pre-flight check to both the review skill and the PR script so that a branch cannot be reviewed or a PR opened if a structural precondition fails.

**When to use:** When a check must fire before any review work begins AND again as a last-resort gate before the PR opens. The canonical example is merge-conflict detection: checking in the review skill blocks wasted review effort; checking again in `pr.sh` covers the window between review and PR open.

**When NOT to use:** Content/quality checks (logic correctness, test coverage) — those belong in the analytical review passes, not Pre-flight. Also not for checks that only matter at one stage — if the check is only meaningful at PR time, put it in `pr.sh` only.

**The recipe:**
1. **Review skill (`.claude/skills/cr/SKILL.md`)** — Add a `## Pre-flight — <name>` section before `## Step 0`. The section must: (a) run its check, (b) hard-block with a clear message if it fails, and (c) explicitly say "Do not run any passes. Do not write the sentinel." if it blocks. No sentinel is written when Pre-flight fails.
2. **PR script (`scripts/pr.sh`)** — Add the same check after the remote-branch precondition (around line 78, `git ls-remote`) but BEFORE the sentinel is consumed (around line 112, `mv "$SENTINEL" "$CONSUMED"`). On failure: exit non-zero, leave the sentinel intact. The ordering is the invariant: precondition first (proves the branch exists remotely), then this check (structural gate), then sentinel consumption (certifies the whole flow ran).
3. **Tests (`tests/pr-host-agnostic.test.sh`)** — Add TWO test cases for the new check: (a) the failure path (check fires, pr.sh exits non-zero, sentinel intact), and (b) the passing path (check is clean, pr.sh exits zero). A one-sided test that only covers the failure path will miss a regression that blocks all branches.
4. **`docs/TESTING.md`** — Add confirmed-behavior entries for both paths, under a section for the relevant script.

**Golden exemplar:** Pre-flight section in `.claude/skills/cr/SKILL.md` + merge-conflict block in `scripts/pr.sh` (lines 83–97) + two test cases in `tests/pr-host-agnostic.test.sh` (lines 93–159).

**Established by:** PR #68 (feat/merge-conflict-detection). See [solution doc](./solutions/2026-06-17-merge-conflict-preflight-guard.md).

**Gotchas:**
- The ordering in `pr.sh` is a hard invariant: precondition → this check → sentinel consumption. The sentinel must be the last thing consumed; any earlier check that fails must leave it intact so the user can fix and retry without re-running `/cr`.
- Always add a passing-path test alongside the failing-path test. If only the failure path is tested, a regression that blocks all branches will look green.
- The Pre-flight section in SKILL.md describes what an LLM agent should do. The shell code in `pr.sh` runs unconditionally. Keep them conceptually in sync but don't try to DRY them — they serve different contexts (LLM prompt vs. shell execution) and have different error-message requirements.

---

## add-linting-git-hook

**What:** Add a new git hook that validates something about the repo state (commit message format, file contents, sync status) by delegating to a dedicated bash script, tested hermetically.

**When to use:** You need to enforce a rule at commit or push time. The rule is checkable mechanically (a regex, a file-presence test, a count). The check should fail-closed (block the action on violation) and be runnable standalone for debugging.

**When NOT to use:** Checks that require network access without a clear fail-open strategy — see the sync gate pitfall below. Checks that need to read the working tree at staging time but the staged content differs from disk (use pre-commit index-aware commands instead). Don't add a hook if a CI check in GitHub Actions is sufficient — hooks add latency to every developer action.

**The recipe:**
1. **Hook file (`.husky/<hook-name>`)** — Thin POSIX sh file, 3–5 lines. First line: `# shellcheck shell=sh`. Set `set -e`. Delegate immediately: `bash scripts/<name>-lint.sh "$@"`. Never put logic here — logic belongs in the script.
2. **Lint script (`scripts/<name>-lint.sh`)** — Full bash (`#!/usr/bin/env bash`, `set -euo pipefail`). Reads input, validates, writes actionable errors to stderr, exits 1 on violation. Exit 0 on skip (auto-generated commits, etc).
3. **Test file (`tests/<name>.test.sh`)** — Hermetic: `unset GIT_DIR GIT_WORK_TREE ...` at top. Uses `mktemp` for fixtures; cleans up with `trap`. Tests every case from the spec shard. Structure: `run()` helper invokes the script; `ok()` checks exit code.
4. **Spec shard (`docs/testing/<feature-slug>.md`)** — List confirmed behaviors before writing the test. Each behavior is "Given X, exits N and [writes/does not write] to stderr." The shard is assembled into `docs/TESTING.md` by the pre-commit hook.
5. **install.sh (`scripts/install.sh` `COPY_FILES`)** — Add `.husky/<hook-name>` to the `COPY_FILES` string so `install.sh` propagates the new hook to target repos.

**Golden exemplar:** `.husky/commit-msg` + `scripts/commit-msg-lint.sh` + `tests/commit-msg-lint.test.sh` + `docs/testing/enforce-claude-md-hooks.md`.

**Established by:** feat/enforce-claude-md-hooks. See [solution doc](./solutions/2026-06-18-pre-push-sha-timing-and-rebase.md).

**Gotchas:**
- Husky v10 runs hooks with `sh .husky/<hook>` — no shebang, no `+x` needed on the hook file. The `# shellcheck shell=sh` directive at line 1 tells shellcheck which shell to target (without it, shellcheck raises SC2148 "specify a shell with a shebang").
- The hook file must be POSIX sh. The script it delegates to can be bash. Do not use `${#var}`, `pipefail`, or `[[` in the hook file itself.
- `PUSH_INPUT=$(cat)` must be the very first thing in `pre-push` hooks — stdin is single-read. Any `case` or `if` block that reads stdin after the first consumer will get nothing. Drain it all into a variable first, then pass it to sub-logic.
- For pre-push hooks: use `$PUSH_SHA` (parsed from stdin), not `HEAD`, in any `git rev-list` comparison. `HEAD` is the wrong commit in worktrees. See [solution doc](./solutions/2026-06-18-pre-push-sha-timing-and-rebase.md).
- Auto-rebase inside a pre-push hook silently sends the wrong commits — git locks the push SHA before calling the hook. Block-and-instruct instead: exit 1 with the rebase command to run, then let the user push again.

---

## managed-file-distribution

**What:** Install a set of harness files into an arbitrary repo, record each file's sha and ownership policy in a manifest, and run three-way conflict detection on subsequent updates so project-owned customizations are never clobbered.

**When to use:** A toolset (skills, scripts, hooks, config) lives in one repo and needs to land — and stay current — in many target repos. Some files the toolset owns forever; others are starter templates the project will edit. You need a safe update path without git submodules, without a package manager, and without requiring the target project to change its toolchain.

**When NOT to use:** The toolset is a versioned library with a semver contract (use a package manager). The files are binary or generated (sha comparison produces spurious conflicts). The consuming repos are few and a git submodule or monorepo is practical. Automatic updates without human review are required (this pattern always asks a human to run `sync-harness.sh`).

**The recipe:**
1. **Installer (`scripts/install.sh`)** — Classify every file into one of two categories: `"copy"` (harness-owned, always updated on sync) or `"create-once"` (written from `docs/templates/` the first time only, then project-owned). Never touch category-3 (project-only) files — they simply don't appear in the manifest. Copy category-1 files, create category-2 from templates, then write `.claude/.harness-manifest.json` LAST. Writing the manifest last makes any interrupted install safe to re-run: no manifest = re-install everything. Use `mktemp` + `mv` for the write, not a direct redirect — atomic write prevents a half-written manifest from wedging sync on a mid-run kill. Guard against `HARNESS_SRC == TARGET_DIR` (would `cp` a file onto itself) and verify a sha tool exists before doing anything.
2. **Manifest (`.claude/.harness-manifest.json`)** — Records `source`, `installed_at`, `synced_at`, and per-file `{ sha, policy }` entries. The sha is the anchor value for three-way comparison. The `source` field must be present; sync reads it to locate the harness; a missing field must be a hard error, not a fallback.
3. **Sync (`scripts/sync-harness.sh`)** — For each `"copy"` file, compute `local_sha`, `old_sha` (manifest), `upstream_sha` (source). Apply the five-case decision table:
   - `local == old AND local == upstream` → nothing to do
   - `local == old AND local != upstream` → update from upstream
   - `local != old AND local == upstream` → user edited to match; record local sha
   - `local != old AND old == upstream` → user-only edit; leave it alone, record local sha
   - `local != old AND old != upstream AND local != upstream` → CONFLICT, exit non-zero, leave file untouched, do NOT rewrite the manifest
   For `"create-once"` files: if the file exists, skip; if it's gone, restore from the template. Use the same `mktemp` + `mv` pattern for the manifest rewrite; withhold the rewrite if any conflict exists.
4. **Templates (`docs/templates/`)** — Create-once starters that install.sh copies to the target root on first install. Template paths are hardcoded in install.sh's `CREATE_ONCE` variable as `dest:source` pairs. If the dest exists, skip. If it's gone, sync restores it from the template.
5. **Tests (`tests/install.test.sh`)** — Each test creates throwaway `mktemp -d` git repos (never the real harness tree). Unset `GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/GIT_PREFIX/GIT_COMMON_DIR/GIT_OBJECT_DIRECTORY/GIT_NAMESPACE` at the top — inherited env contaminates `git init` in temp dirs. Cover: conflict path, user-only-edit path, create-once skip, re-create-on-delete, and both hooks-script paths.
6. **Hooks script (`scripts/install-harness-hooks.sh`)** — Separate from install.sh. Runs `npm install` and edits `package.json`. Users run this explicitly. Never call it from install.sh — keeping the installer side-effect-free lets CI re-run it safely.

**Golden exemplar:** `scripts/install.sh` + `scripts/sync-harness.sh` + `tests/install.test.sh`.

**Established by:** PR #72 (feat/one-command-install). See [solution doc](./solutions/2026-06-18-harness-file-install-and-sync.md).

**Gotchas:**
- The fourth decision-table case is the easy-to-miss one: `local != old AND old == upstream` means the user edited the file but upstream didn't change — it is NOT a conflict. Missing this case causes a false-positive conflict on any user customization and blocks sync. See [solution doc](./solutions/2026-06-18-harness-file-install-and-sync.md) for the full decision table.
- `mktemp -p DIR` is not portable — BSD `mktemp` (macOS) does not support `-p`. Use `mktemp "$DIR/.file.XXXXXX"` instead.
- The manifest must be written LAST by install.sh, and withheld entirely by sync when conflicts exist. Both invariants make re-run safe; breaking either causes partial installs that are hard to debug.
- Name the env var used to skip npm in tests with a private prefix (e.g. `_HARNESS_SKIP_NPM`) rather than a plain name. An ambient `SKIP_NPM=1` in a shell session silently bypasses npm install in a real install.
- Add `docs/solutions` to `COPY_DIRS` if the harness ships solution docs, OR remove references to `docs/solutions/` from the CLAUDE.md template. A template referencing a path the installer doesn't create produces a broken session start on every installed repo.

---

## cross-hook-session-state

**What:** Pass state from a `SessionStart` hook to a `SessionStop` hook (or any two hook invocations in the same session) using a temp file keyed on `session_id`.

**When to use:** When a `SessionStart` hook captures something — a timestamp, the model name, a snapshot — that a later hook in the same session needs to read back. The canonical use is session duration: start time is captured at start, stop time is read at stop, and the delta is written to the activity log.

**When NOT to use:** Sharing state across sessions (different `session_id` values). Sharing large payloads (prefer a project-level state file). Use a `PreToolUse`→`PostToolUse` pair for per-tool state; the `session_id` temp file is for session-level lifecycle only.

**The recipe:**
1. **`SessionStart` hook (`.claude/hooks/session-start.sh`)** — Read stdin into a variable immediately. Stdin can only be consumed once, so this must be the first thing the hook does. Extract `session_id` and any data to carry forward. Write a temp file at `/tmp/claude-activity-${SESSION_ID}` with the data as a single line. Wrap the write in `2>/dev/null || true` so a write failure never blocks the session.
2. **`SessionStop` hook (`.claude/hooks/session-stop.sh`)** — Add a subagent guard near the top: `AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // ""'); [ -n "$AGENT_TYPE" ] && exit 0`. This skips subagent stops — they share the parent's session but should not write their own lifecycle records. Read the temp file by matching `session_id`. Handle the missing-file case explicitly: use `null` (not `0`) for numeric fields that cannot be computed without the start data.
3. **Protect the stop hook from failures** — Wrap writes inside a subshell with `(set -euo pipefail; ...) 2>&1 | sed 's/^/prefix: /' >&2 || true`. The `|| true` after the subshell ensures any failure inside is swallowed. The `sed` prefix makes error messages identifiable.
4. **Tests (`tests/activity.test.sh`)** — Write a temp file manually before calling the stop hook in the test. Assert: file written, model field matches, skills deduplicated, duration positive. In a second test, omit the temp file and assert `duration_s: null`.

**Golden exemplar:** `.claude/hooks/session-start.sh` (writes temp file) + `.claude/hooks/session-stop.sh` (reads it, writes record) + `tests/activity.test.sh` (end-to-end verification).

**Established by:** feat/activity-dashboard. See [solution doc](./solutions/2026-06-18-cross-hook-state-via-temp-file.md).

**Gotchas:**
- Stdin in a `SessionStart` hook can only be consumed once. Always `_INPUT=$(cat)` as the very first line, before any `jq` calls. A `jq` call on a named input (`.session_id`) will silently get empty results if stdin was already consumed.
- The temp file may be absent at stop time (session crashed before start hook ran, or `/tmp` was cleared). Never assume it exists. The missing-file path must produce a valid, spec-conformant record with `null` for unmeasurable fields.
- The `agent_type` guard must appear BEFORE any output the hook produces — including handoff summaries. Subagent stops should produce nothing: no record, no handoff output.
- Session activity files go to `.claude/activity/{branch-slug}.jsonl`. Commit the `.gitkeep` to ensure the directory is tracked; the JSONL files accumulate and can be committed on a schedule.

---

## per-file-merge-driver

**What:** Add a per-file merge strategy to a shared doc file so that concurrent edits from multiple feature branches auto-resolve without human intervention.

**When to use:** A file is touched by many branches at once, merge conflicts on it are always the same mechanical operation (keep both sides, or pick the higher value), and no merge should ever produce conflict markers in CI. Classic targets: append-only doc files, task-state files, and auto-regenerated files that should always keep the main-branch version.

**When NOT to use:** Files where concurrent edits can be genuinely incompatible in ways that need human judgment — e.g. overlapping config changes, schema migrations. Do not use `merge=union` on any file whose fields drive automated logic: union keeps duplicate lines when two branches update the same field, so the field becomes ambiguous.

**The recipe:**
1. **`.gitattributes`** — add one line per file: `<glob> merge=<strategy>`. Three built-in strategies: `union` (keep all lines from both sides), `ours` (always keep current-branch version), or a custom name for a shell-script driver. Add a comment block explaining each choice.
2. **`scripts/<driver-name>.sh`** (custom drivers only) — POSIX sh script that receives `$1=%O` (ancestor), `$2=%A` (output), `$3=%B` (other). Try `git merge-file "$CURRENT" "$ANCESTOR" "$OTHER"` first; if it exits 0, done. Otherwise awk over the conflict markers, resolve what the domain allows, leave the rest as markers, and set `bad=1`. Exit `$bad`. Guard the temp file: `TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT`. Only move `$TMP` onto `$CURRENT` when awk exits 0 or 1 — any other code means awk failed and `$CURRENT` must not be overwritten.
3. **`scripts/register-merge-drivers.sh`** — register every non-`union` strategy in `.git/config`. One `git config merge.<name>.driver "..."` line per driver. `merge=ours` requires `merge.ours.driver "true"`. Include a `git config merge.<name>.name "..."` line for human-readable `git log --merges` output.
4. **`package.json`** `prepare` script — append `&& bash scripts/register-merge-drivers.sh` so `npm install` and `npm ci` both register the drivers on fresh clones and in CI. Without this step, `.gitattributes` is cloned but the registrations are not — git silently falls back to 3-way merge and produces conflict markers.
5. **`tests/<driver-name>.test.sh`** — one test per behavior. Each test: `git init` a temp dir, copy `.gitattributes`, register both drivers with `git -C "$dir" config`, make three commits (base + two conflicting branches), run `git merge`, assert the result. Use `printf -- '- [x] ...\n'` (with `--`) in bash test scripts when the format string starts with `- `. Cover: each rank comparison, and the unresolvable-conflict path (verify both exit non-zero and markers present).

**Golden exemplar:**
- `.gitattributes` — five file rules
- `scripts/tasks-merge-driver.sh` — the higher-state-wins custom driver
- `scripts/register-merge-drivers.sh` — the registration script
- `tests/gitattributes-merge-drivers.test.sh` — 27-case regression suite

**Established by:** feat/gitattributes-merge-drivers (PR #78). See [solution doc](./solutions/2026-06-18-gitattributes-merge-drivers-for-shared-docs.md).

**Gotchas:**
- `merge=union` keeps ALL distinct lines from both sides. When two branches update the same counter field (e.g. `**Occurrences:** 2` vs. `**Occurrences:** 3`), union keeps BOTH lines — the file is not broken, but it now has two conflicting values for the same field. This is acceptable as a lower-bound approximation only if the field is human-read. If automated logic reads the field, use a custom driver instead.
- Driver registration lives in `.git/config`, which is never committed or cloned. Always wire registration into `npm prepare`. A comment in `.gitattributes` saying "run these commands after cloning" is always missed.
- In the awk script, anchor field reads to a fixed position: `substr(s, 3, 3)` reads the bracket at position 3. Do NOT use `index(s, "[x]")` — that matches `[x]` anywhere in the line, so a task whose description mentions `[x]` gets misranked.
- In bash 3.2 (macOS default shell), `printf '- [x] ...'` fails: the builtin treats the leading `- ` as an option flag. Always use `printf -- '- [x] ...'` in test scripts. zsh (used by the Bash tool interactively) handles this correctly, so the bug is invisible until the test suite runs under bash. See PITFALLS.md § "bash 3.2 printf: leading dash in format string treated as option flag".

---

## Entry format

Copy this skeleton for each new recipe.

```markdown
## <recipe-slug-as-heading>

**What:** the recurring multi-file task this recipe covers (e.g. "add a custom field to X").
**When to use:** the situation that calls for this recipe.
**When NOT to use:** the look-alike cases this recipe does not cover.

**The recipe:**
1. <file or layer> — <what to add or change, and why>
2. <file or layer> — <what to add or change, and why>
3. <…>

**Golden exemplar:** <the canonical file(s) to copy from — link AGENTS.md → Golden exemplars
or the specific file>.
**Established by:** <feature-doc link> (PR #N).
**Gotchas:** <the non-obvious step people get wrong; link PITFALLS.md if it has a matching trap>.
```

---

## How this differs from neighboring docs

| Doc | Holds | Granularity |
|---|---|---|
| **This registry** | reusable recipes that span **several files** | multi-file, repeatable |
| AGENTS.md → Golden exemplars | one canonical **file** per layer to imitate | single-file, per-layer |
| [`docs/solutions/`](./solutions/) | how a specific **non-obvious problem** was solved once | one problem, point-in-time |
| PITFALLS.md | traps that produce silent bugs | a rule, not a recipe |

The line vs. `docs/solutions/`: a solution doc is a **point-in-time narrative** of how one
hard problem was solved (with root cause, what didn't work, why this approach fit). A registry
entry is a **forward-looking, replicable recipe** — the steps to follow next time you do this
multi-file task. A solution may *graduate* into a registry entry once the same shape recurs;
until then it stays a solution. The two never hold the same content: solutions explain a past
fix, the registry prescribes a repeatable procedure.
