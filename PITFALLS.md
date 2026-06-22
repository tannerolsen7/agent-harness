<!-- context-meta
owner: tanner
last-reviewed: 2026-06-18
review-frequency: on-merge
drift-signals:
  - an entry was fixed by a newer solution and no longer applies
  - a pitfall is no longer reachable in the current code
-->

# PITFALLS

Known traps in this codebase. Each entry is a real incident, not a speculation.
Check this file before any `/cr` pass. If you see a pattern here in a diff, flag it MUST FIX.

---

## Stale comments: written for a state that has since changed

**Area:** Any shell script, test file, or skill doc with inline comments or header explanations

**Rule:** Comments that describe prerequisites ("run X first"), expected output format, or current behavior must be updated whenever the code they describe changes. A stale comment is not cosmetic — it actively misleads the next reader into doing the wrong thing.

**Why:** This pattern appeared three times in three PRs before being promoted: an awk comment describing the wrong column names, a skill doc claiming a command makes no network call when it does, and a test header telling readers to manually apply a diff that was already committed in the same PR. In each case the comment was accurate when written and wrong when read.

**Symptoms:** A reader follows a comment's instructions and gets an unexpected result, then goes back to the code to find the comment was describing an older state.

**The check:** Before committing, read every comment in files you changed and ask: does this comment describe the current behavior? Instructions to "run X first" or "apply Y before using" are especially likely to go stale when the dependency is eliminated by the same commit.

---

## Internal labels without explanation: "Layer 2a", "CMP4", "F6", "R4-D2"

**Area:** Any shell script, skill doc, or inline comment that references the harness's own design framework

**Rule:** Every internal label — from any naming system, including the ADR layer model (Layer 2a, Layer 2b), the harness internal codes (F6, CMP4, R4-D*), or any project-specific abbreviation — must be explained in the same sentence or paragraph that uses it. "Do not drop internal codes without explaining them first" is a direct rule in CLAUDE.md. Cite the reference doc as a follow-on, not as a substitute for the inline explanation.

**Why:** This pattern appeared three times before being promoted: (1) CMP1/CMP2/CMP4 labels in ci-verify.sh and agent specs. (2) "Layer 2a" in scripts/deploy-drift-check.sh header — the label means "the manifest-presence layer of the deploy-drift gate" but was dropped without explanation. (3) "F6" in ci-verify.sh header — the label means "the host-agnostic CI floor script." In each case, a cold reader (someone opening the file for the first time) saw only the label and had to trace back through the ADR or design doc to understand it.

**Symptoms:** A reader opens a script, sees "Layer 2a" or "CMP4" in the header, and does not know what it means without reading the linked ADR — which may be long, proposed, or not yet accepted.

**The fix:** Replace the label with a plain-English description first, then add the label parenthetically if useful:

```bash
# Checks that every required deploy step in deploy-targets.yml has a drift_check
# command declared. This is the manifest-presence layer of the deploy-drift gate
# (called "Layer 2a" in docs/adr/0002-deploy-drift-gate.md).
```

**Check:** Before committing, search every changed file for `Layer [0-9]`, `CMP[0-9]`, `R4-D`, `F[0-9]` and verify the surrounding sentence explains what the label means in plain English.

---

## Exempt branch arms in hook tests: every case arm needs its own test

**Area:** Hook test files (`.husky/pre-push`, `.husky/pre-commit`) that protect a fixed set of branch names or values via a `case` statement

**Rule:** Every arm of a hook's `case` statement needs its own test case. If a hook exempts `main|master|HEAD|""`, write four tests — one for each exempt value. A test that only covers `main` gives no protection against a regression that removes the `master` arm.

**Why:** This pattern appeared in three separate PRs: (1) a main-branch guard that listed `develop` as exempt but had no `develop` test, (2) the pre-push sync gate that exempted `main|master|HEAD|""` but had no test for any of the four, (3) the worktree enforcement test that tested only `main`. In each case, the missing test looked fine because the code was correct at the time — but it left no signal to catch a future regression.

**Symptoms:** A test suite passes after a code change that accidentally removes one of the exempt arms, because the only test for that branch type was never written.

**The check:** After adding a `case` statement that exempts N values, count the exempt tests. If `N tests < N arms`, add the missing ones.

**Source:** Promoted from RECURRING-FINDINGS.md at Occurrences 3 (2026-06-22).

---

## Agent orchestrators — Task tool and permissionMode are both required for spawning

**Area:** Agent system (`.claude/agents/*.md` frontmatter)

**Rule:** Any orchestrator agent must have `Task` in `tools:` AND `permissionMode: default` or `auto`. Both conditions are independently required. Either missing alone breaks spawning completely.

**Why:** Without `Task`, the agent has no spawn mechanism. With `permissionMode: plan`, all action invocations including spawning are blocked regardless of what's in `tools:`. The failure is silent — the agent falls back to running all sub-agents in one context, producing structurally correct output with no error or warning. You cannot detect the collapse from the output quality alone.

**Symptoms:** Orchestrator returns a consolidated report but no distinct agent tool calls appear in the conversation trace. Findings from "parallel" lenses look like one analysis dressed as multiple. The design's isolation guarantee never occurs.

**Source:** `docs/solutions/2026-06-15-orchestrator-task-tool-spawn-wiring.md`
**Regression gate:** `tests/agent-spawn-tools.test.sh` (bidirectional: spawners must have Task; Task holders must have a spawn instruction)

---

## Running tests from inside a worktree corrupts the real repo

**Area:** Test runner (`scripts/run-tests.sh`, any test that calls `git init` in a subshell)

**Rule:** Never invoke `run-tests.sh` (or `npm test`) directly from inside a git worktree directory. Always prepend a full git env clear: `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE && bash scripts/run-tests.sh`.

**Why:** `run-tests.sh` unsets inherited git env vars — that protects against the push-hook contamination case (where git exports `GIT_DIR` before calling hooks). It does NOT protect against git's filesystem autodiscovery. When tests run from inside a worktree, git walking up the directory tree from temp-dir subshells finds the worktree's `.git` file before settling on the temp dir's `.git`. The result: `git commit` inside a temp-dir subshell commits to the real repo, and `git checkout -b feat/x` switches the real worktree's branch — silently, with exit 0.

**Symptoms:** Tests pass; afterward the worktree branch has changed (e.g. to `feat/x`) and spurious `"init"` commits appear in `git log`.

**Recovery:** `git reset --soft origin/<branch>` to repoint HEAD to the remote tip; all local changes are preserved in the index.

**Deeper fix:** Pin `GIT_DIR` and `GIT_WORK_TREE` in every `mk()`-style helper that `git init`s a temp dir. See `docs/solutions/2026-06-17-worktree-gitdir-test-corruption.md`.

---

## Detecting a live git worktree: use the .git FILE, not `git worktree list`

**Area:** Shell scripts that create or check git worktrees (`scripts/worktree-add.sh`, any idempotency guard)

**Rule:** To check whether a directory is a live git worktree, test for the `.git` FILE: `[ -f "$PATH/.git" ]`. Do not parse `git worktree list --porcelain` for the path.

**Why:** `git worktree list --porcelain` outputs absolute paths. Shell scripts commonly receive relative paths. `grep -qF "worktree $RELATIVE_PATH"` never matches `worktree /full/absolute/path/...`. The directory check (`-d`) passes fine, so the guard appears to run — but it always falls through. The script then calls `git worktree add` on an existing worktree and exits with an error.

A git worktree always has a `.git` FILE (a one-line pointer: `gitdir: /path/to/.git/worktrees/<name>`). A regular repo has a `.git` DIRECTORY. A plain directory has neither. The file check is path-format-independent and doesn't require any git commands.

**Symptoms:** Resuming a Workflow that re-runs worktree setup fails with "already checked out" errors, even though an idempotency guard is present.

**Fix:**
```sh
if [ -d "$WORKTREE_PATH" ] && [ -f "$WORKTREE_PATH/.git" ]; then
  echo "Worktree already exists — skipping creation."
  exit 0
fi
```

**Source:** `scripts/worktree-add.sh`; `docs/solutions/2026-06-17-worktree-git-file-detection.md`.
**Regression gate:** `scripts/shell-portability-lint.sh` — flags `git worktree list --porcelain | grep` in any staged `.sh` file.

---

## Writing a sentinel directly to bypass a gate

**Area:** Sentinel system (`.claude/.cr-ok`, `.claude/.design-confirmed`)

**Rule:** Never write a sentinel file directly (via Write-tool, `printf >`, or any means other than the designated script). Writing it directly produces a file that passes the gate's string comparison while certifying work that was never done.

**Why:** The sentinel is an honor-system certificate, not a cryptographic proof. Its only integrity property is that `scripts/cr-ok.sh` and `scripts/design-confirm.sh` refuse dirty trees and self-resolve `branch:sha` — bypasses strip both guarantees. A hand-written `.cr-ok` certifies a review that never ran; a hand-written `.design-confirmed` certifies a design session that never happened. Both silently propagate false assurance through every downstream gate.

**Symptoms:** Gate passes without the corresponding gate script having been invoked; audit log is absent or shows no matching entry for the branch:sha.

**When the gate fires unexpectedly:** Fix the condition (run the gate, commit the artifacts, resolve the stale sha) — do not write the sentinel to get past it.

---

## integrity-check-skips-inline-code-and-fences

**Area:** Reference-integrity script (`scripts/check-integrity.sh`), any link checker added to this repo

**Rule:** When extending or replacing the integrity check, preserve the skips for inline code spans (backtick-wrapped text), fenced code blocks, external links, pure anchors, and template placeholders (`<...>`). All five skips must stay in place.

**Why:** A link that appears inside a backtick span or a fenced block is a documentation example — it shows how another file formats something. It is not a live cross-link in this repo. Without the skip, the checker flags it as broken and fails CI on a doc that is correct. The external-link, pure-anchor, and placeholder skips exist for the same reason: they prevent noise from patterns that are never meant to resolve to a local file.

**Symptoms:** CI fails with a "broken link" error pointing at a path outside the repo — for example, a path inside the user's `~/.claude` auto-memory index. The file the link points to does not exist in this repo, but the link is only a formatted example inside a code span or fence.

Check whether the flagged link is inside backticks or a fenced block in the source file. If it is, the checker is missing the skip. Add the skip to `scripts/check-integrity.sh` — blank inline code spans before extracting links, and skip lines that fall inside a fenced block.

**Source:** `scripts/check-integrity.sh`
**Regression gate:** `tests/check-integrity.test.sh` (cases: "links inside fenced code blocks are skipped", "link inside an inline code span is skipped")

---

## `git merge-base --is-ancestor` cannot tell a fresh branch from a merged one

**Area:** Shell scripts that use ancestor checks to decide whether a branch is safe to delete (`scripts/prune-branches.sh`)

**Rule:** Never use `git merge-base --is-ancestor "$branch" HEAD` alone as proof that a branch was merged. A freshly-created branch with zero commits has its tip at the branch point — that commit IS reachable from HEAD, so the check returns true. Guard with an explicit exclusion for branches that are actively checked out in a worktree before running the deletion loop.

**Why:** "Reachable" and "was merged" are not the same thing. A branch with zero unique commits is always an ancestor of anything descended from its branch point. When `/queue` provisions a worktree but the task runner hasn't committed yet, the branch looks merged — and a prune-branches.sh pass that runs concurrently (e.g. from a session-start hook in a parallel subagent) deletes it.

**Symptoms:** Four parallel `/queue` worktrees are destroyed mid-run; task agents report "worktree was deleted by an external process"; `git worktree list` shows the branches are gone before any work was committed.

**The fix:**
```sh
ACTIVE_WT_BRANCHES=$(git worktree list --porcelain \
  | awk '/^branch /{sub(/^branch refs\/heads\//, ""); print}' || true)
if [ -n "$ACTIVE_WT_BRANCHES" ]; then
  CANDIDATES=$(printf '%s\n' "$CANDIDATES" \
    | grep -vFxf <(printf '%s\n' "$ACTIVE_WT_BRANCHES") || true)
fi
```
Use `-Fx` (fixed-string, full-line) — branch names with dots or brackets in them are misread as regex patterns without it.

**Source:** PR #50; `docs/solutions/2026-06-17-merge-base-cannot-detect-empty-branch.md`
**Regression gate:** `tests/prune-branches.test.sh` case "fresh branch feat/queue-task must survive (no commits, active worktree)"

---

## Two parsers over the same structure must agree on scope

**Area:** Shell scripts that scan a structured block (`scripts/scan-context.sh`)

**Rule:** When two pieces of code scan the same thing for related decisions, they must use the same notion of what counts. Share the scoping rule, or mirror it exactly so the two cannot drift. Test the adversarial layout where the two scopes would diverge — the simple layout passes even when they disagree.

**Why:** `scan-context.sh` had two functions reading the same `context-meta` block. `has_real_meta` decided whether a file is governed and skipped blocks inside ``` code fences (a fenced block is a documentation example, not real metadata — the same lesson as the link-checker entry above). But `meta_field`, which read the dates, used a plain `sed` that grabbed the first block, fenced or not. A file that shows a fenced example block above its real block was judged governed by one function and read from the wrong (example) block by the other. The result is a false OVERDUE, or — worse — a false OK that hides a genuinely stale file.

**Symptoms:** A scan result that does not match the file's real metadata: a file whose real `last-reviewed` is recent is reported overdue, or a stale file is reported fresh. Every simple-layout test (one block, no fence) passes; only the example-above-real layout exposes the disagreement.

**Source:** Caught by `/cr` on PR #42, not by the first test pass. Fix: make `meta_field` fence-aware (awk) so it reads the same block `has_real_meta` counts.
**Regression gate:** `tests/scan-context.test.sh` case H ("fenced example above real block → reads the REAL block").

---

## Design contracts committed to task branches disappear in the next session

**Area:** Cross-session design workflow

**Rule:** Always commit a design contract (`docs/features/<slug>.md`) on the same branch where `TASKS.md` references it under `design:`. If you write the contract on a separate branch (e.g. a task-specific feature branch), the next session opening on a different branch won't find the file — Read tools, Edit tools, and Bash `ls` will all report it missing.

**Why:** Each branch has its own working tree. A file committed only on `feat/foo` does not exist when the shell is on `feat/bar`. This burned a full session: the design contract was committed on `feat/progress-in-progress-view`, the next session opened on `feat/merge-conflict-detection`, and every tool call that tried to find `docs/features/one-command-install.md` failed. Half the session went to diagnosing why the file existed in some contexts (git show, git log) but not others (Read, Bash ls with absolute path, Edit).

**Symptoms:** `File does not exist` from the Read tool on a path that `git log --all` confirms was committed; Edit tool failing with "file does not exist" before the Write tool works; `ls` returning empty for a directory that `git show <branch>:<path>` returns content for.

**The fix:** Either (a) commit the design artifact directly on the working branch that holds the `TASKS.md` entry, or (b) merge the design branch to the working branch before adding the `design:` reference to `TASKS.md`. The `design:` field is only useful if the file is reachable on the branch where the task will be queued.

**Source:** Session 2026-06-17 (design contract for one-command-install, feat/progress-in-progress-view vs feat/merge-conflict-detection).
**Regression gate:** The `design:` field in `TASKS.md` is checked by `/queue` preflight — if the file doesn't exist on the current branch, the task is rejected before any agent work begins.

---

## Feature work in the main worktree races against background processes

**Area:** Git operations during feature development

**Rule:** Never do feature work directly in the main worktree (`/Users/tanner/Dev/agent-harness`). Always create a dedicated worktree at `.claude/worktrees/<slug>` first — either via `scripts/worktree-add.sh` or by running `git worktree add .claude/worktrees/<slug> feat/<slug>` directly — and do all commits, pushes, and sentinel writes from there.

**Why:** The harness runs several worktrees concurrently — workflow agents (`wf_*`), active feature worktrees, and session-start hooks — all of which can call `git checkout` on the main worktree. When two processes touch `HEAD` at the same time, git logs `cannot lock ref 'HEAD': is at X but expected Y` and the commit fails. The branch pointer is left unchanged, so the commit object exists in the object store but is not attached to any branch. The same race causes commits to land on whichever branch was last checked out, which is often wrong.

**Symptoms:** `cannot lock ref 'HEAD': is at X but expected Y` during a commit; commits that appear to succeed but don't show up in `git log`; code from one branch appearing in a diff on a different branch; sentinel-mismatch errors on push (`expected branch:sha, got branch:other-sha`) after what looked like a clean commit sequence.

**The fix:** Check `git worktree list` before starting work. If no worktree exists for your branch, create one. Then `cd` into it and stay there for the duration of the session.

```sh
git worktree add .claude/worktrees/<slug> feat/<slug>
cd .claude/worktrees/<slug>
# all git operations from here
```

**Source:** Session 2026-06-17 (feat/progress-in-progress-view); root cause identified after repeated ref-lock failures and sentinel mismatches caused by concurrent `wf_*` workflow agents.
**Regression gate:** Human-process rule — no automated check yet.

---

## Workflow `isolation: 'worktree'` commits to `agent/*` branches, not your `feat/*` branches

**Area:** Queue workflows (`.claude/workflows/*.js`)

**Rule:** Never pass `isolation: 'worktree'` to an agent call and expect its commits to land on a pre-created `feat/*` branch. `isolation: 'worktree'` always creates a new `agent/wf_<run-id>-<seq>` branch. The branch name in the agent prompt is prompt text — git never sees it.

**Why:** `isolation: 'worktree'` is a concurrency safety mechanism. It creates an isolated sandbox so parallel agents don't step on each other's files. That sandbox is a fresh worktree on a fresh branch, named by the workflow runtime. Any pre-created `feat/*` branches remain untouched.

**Symptoms:** Setup phase creates `feat/perf-budget`. Execute phase returns `Branch: agent/wf_...-7`. Push phase pushes `feat/perf-budget`, finds it at the same SHA as main, and `gh pr create` fails with "no commits between head branch and base branch."

**The fix:** Choose one approach and stick to it:
- **No isolation:** Drop `isolation: 'worktree'`. Pass the pre-created worktree path in the agent prompt. The agent commits to the branch that worktree is already on.
- **With isolation:** Accept `agent/*` branches. Parse the actual branch from the agent's return value and push that in the Push phase. Delete the pre-created `feat/*` branches — they will be empty.

**Source:** `docs/solutions/2026-06-17-workflow-isolation-worktree-branch-naming.md`
**Regression gate:** Human-process rule — no automated check yet.

---

## `git stash` during a rebase conflict corrupts `--continue` state

**Area:** Git operations (rebase + stash interaction)

**Rule:** Never run `git stash` while in a rebase conflict state. Once stashed and popped, `git rebase --continue` will refuse with "You must edit all merge conflicts" even when `git ls-files -u` is empty and all conflict files look resolved.

**Why:** `git stash` snapshots the index and clears it. When `git stash pop` restores files, it writes to the working tree but does not reconstruct the exact index entries rebase was tracking (stage 1/2/3 unmerged markers). The rebase ledger is now out of sync — it still records unresolved paths that no longer exist as unmerged entries.

**Symptoms:** `git rebase --continue` loops with "You must edit all merge conflicts and then mark them as resolved using git add." `git ls-files -u` returns nothing. `git add` on every modified file makes no difference. The error persists.

**The fix:** `git rebase --abort` and use `git merge origin/main` instead. Merge commits are safe here — the sentinel and pre-push hook do not distinguish merge commits from regular commits.

**Source:** `docs/solutions/2026-06-17-stash-during-rebase-corrupts-continue.md`
**Regression gate:** Human-process rule — no automated check yet.

---

## Shell scripts — `mktemp -p DIR` is GNU-only; breaks silently on macOS

**Area:** Shell scripts (`scripts/install.sh`, `scripts/sync-harness.sh`, any script that writes temp files)

**Rule:** Never use `mktemp -p DIR`. Use `mktemp "DIR/file.XXXXXX"` instead — this form is portable across GNU (Linux) and BSD (macOS).

**Why:** GNU `mktemp` accepts `-p DIRECTORY [TEMPLATE]` (two separate args). BSD `mktemp` does not support `-p` at all — it only accepts a positional template with the `XXXXXX` suffix. On macOS, `mktemp -p DIR` either fails with `unknown option -- p` or writes the temp file to the wrong location, and `set -euo pipefail` aborts the script mid-run. The breakage is on the primary dev platform (macOS), so it hits the first person to run the script locally.

**Symptoms:** Script aborts with `mktemp: unknown option -- p` on macOS. Manifest is not written because `mktemp` failed before the write.

**The fix:** Replace `mktemp -p "$DIR"` with `mktemp "$DIR/.file.XXXXXX"`.

**Source:** PR #72 (feat/one-command-install), adversarial review pass finding [P10-assumption].
**Regression gate:** `scripts/shell-portability-lint.sh` — runs on every staged `.sh` file via `.husky/pre-commit`.

---

## File sync — omitting the "user-only edit" branch causes false-positive conflicts

**Area:** Shell scripts that do three-way file comparison (`scripts/sync-harness.sh`)

**Rule:** A three-way sha comparison (local vs. manifest/baseline vs. upstream) needs five cases, not four. The easy-to-miss case is: `local != old AND old == upstream`. This means the user edited the file but upstream did not change — it is NOT a conflict. Treat it as a user customization and leave the file alone.

**Why:** Without the `old == upstream` case, the `else` branch fires for any local edit regardless of whether upstream actually changed. Every user customization to a harness-owned file permanently blocks sync with a false conflict. The user has no escape except hand-editing the manifest.

**Symptoms:** Running sync after editing any harness-owned file reports CONFLICT even though the source file hasn't changed. The conflict message names the file correctly, but there is no conflicting upstream change.

**The fix:** Add `elif [ "$old_sha" = "$upstream_sha" ]; then` before the conflict `else` branch. See `scripts/sync-harness.sh` for the canonical implementation.

**Source:** PR #72 (feat/one-command-install); `docs/RECURRING-FINDINGS.md` entry `three-state-conflict-missing-user-only-branch`.
**Regression gate:** `tests/install.test.sh` — "sync: conflict" test covers the real conflict path; a separate user-only-edit case should be added (currently tested implicitly by the re-run test).

---

## bash 3.2 printf: leading dash in format string treated as option flag

**Area:** Shell scripts / test fixtures (any bash script that writes task-list items via `printf`)

**Rule:** Always use `printf -- '- [x] ...\n'` (with the `--` end-of-options marker) when the format string starts with a dash-space (`- `). Never write `printf '- [x] ...'` — it fails silently in bash 3.2, writing 0 bytes.

**Why:** bash's built-in `printf` in bash 3.2 (the macOS default) treats a format string starting with `-` as an option flag: it sees `- ` and tries to parse it as an unknown option, exits non-zero, and writes nothing. The `--` tells printf that options are done and the next argument is the format string. zsh (used by Claude Code's Bash tool) handles `printf '- ...'` correctly, so the bug is invisible in interactive testing but breaks test scripts that run under bash.

**Symptoms:** A test fixture or setup step that calls `printf '- [x] do the thing\n' > file.md` silently creates an empty file. The test that follows fails with "file contains unexpected content" or "file has 0 lines" — not with a printf error — because the subshell's stderr is redirected to `/dev/null`. Adding `set -x` inside the subshell reveals `printf: - : invalid option` at the printf call.

**The fix:** Change `printf '- [status] ...'` to `printf -- '- [status] ...'`. The `--` is harmless on all other shells and bash versions.

**Source:** feat/gitattributes-merge-drivers — root cause of 2/18 tests failing; discovered by reading the subshell trace via `exec 2>/tmp/dbg-subshell.log` inside the test's `( ... )` block.
**Regression gate:** `scripts/shell-portability-lint.sh` — runs on every staged `.sh` file via `.husky/pre-commit`.

---

## pre-push hooks: git locks the push SHA before calling the hook

**Area:** `.husky/pre-push` (or any git pre-push hook)

**Rule:** Never auto-rebase inside a `pre-push` hook. Never use `HEAD` to reference the commit being pushed — use the SHA parsed from stdin (`PUSH_SHA`).

**Why:** Git resolves the push ref SHAs *before* calling the hook. If you rebase inside the hook, the local branch tip moves, but git pushes the SHA it locked before the hook ran. The push reports success and the user's new commits stay local. There is no error — the failure is completely silent. The same applies to any `git rev-list` comparison using `HEAD`: in a worktree, `HEAD` is the worktree's checked-out branch, which may differ from the branch being pushed.

**Symptoms (auto-rebase):** User runs `git push`. Hook rebases. Push reports success. Remote does not have the new commits. `git log --oneline origin/<branch>` shows the pre-rebase state.

**Symptoms (HEAD in rev-list):** Sync gate reports "0 commits behind" when the branch is actually stale, because it compared `HEAD` (the worktree's checked-out branch — possibly `main`) against `origin/main`, not the pushed branch.

**The fix:**
- Parse `PUSH_INPUT=$(cat)` and extract `PUSH_SHA` at the top of the hook, before any other logic.
- Use `$PUSH_SHA..origin/$MAIN` in all `git rev-list` comparisons.
- Block-and-instruct instead of auto-rebase: exit 1 with the rebase command to run, then let the user push again cleanly outside the hook.
- Add `GIT_TERMINAL_PROMPT=0 timeout 15` before any `git fetch` in a hook to prevent credential-prompt hangs in non-interactive contexts.

**Source:** feat/enforce-claude-md-hooks — sync gate initially used `HEAD` in `git rev-list`; CI review agent caught the auto-rebase design flaw before it was wired; /cr fixed the `HEAD` vs `$PUSH_SHA` bug after initial implementation.
**Regression gate:** `tests/pre-push-sync-gate.test.sh` — the "behind by N" test passes `PUSH_SHA` explicitly; replacing it with `HEAD` would produce a false pass when branch ≠ checked-out HEAD.

---

## gitattributes merge drivers: registration is lost on fresh clone

**Area:** `.gitattributes` + git merge drivers

**Rule:** Any time you add `merge=ours` or `merge=<custom-name>` to `.gitattributes`, immediately wire the corresponding `git config merge.<name>.driver "..."` calls into `npm prepare` (or the equivalent project setup step). Never depend on a comment or README to prompt manual registration.

**Why:** `.gitattributes` is committed and clones with the repo. The driver registration — the `merge.<name>.driver` entry in `.git/config` — is local-only; git never commits or clones it. A fresh clone gets the attributes but not the config. git silently falls back to 3-way merge for the affected files, producing conflict markers despite the `.gitattributes` declaration. The developer on the original machine never sees this; CI and new team members do.

**Symptoms:** Driver works in the original dev environment. After `git clone` on a new machine or in CI, the files produce conflict markers exactly as if `.gitattributes` weren't there. Running `git config --list | grep merge` reveals the registrations are missing.

**The fix:** Create `scripts/register-merge-drivers.sh` with the `git config` calls. Add `&& bash scripts/register-merge-drivers.sh` to the `prepare` script in `package.json` so every `npm install` and `npm ci` registers the drivers automatically.

**Source:** feat/gitattributes-merge-drivers — identified in /cr Pass Pgov/P8 and added to `docs/RECURRING-FINDINGS.md` entry `driver-missing-install-registration`.
**Regression gate:** Human review — confirm `scripts/register-merge-drivers.sh` exists and `package.json` `prepare` includes it whenever a new merge driver is added to `.gitattributes`.
