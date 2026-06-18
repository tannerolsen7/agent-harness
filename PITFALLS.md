<!-- context-meta
owner: tanner
last-reviewed: 2026-06-17
review-frequency: on-merge
drift-signals:
  - an entry was fixed by a newer solution and no longer applies
  - a pitfall is no longer reachable in the current code
-->

# PITFALLS

Known traps in this codebase. Each entry is a real incident, not a speculation.
Check this file before any `/cr` pass. If you see a pattern here in a diff, flag it MUST FIX.

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

**Area:** Shell scripts that use ancestor checks to decide whether a branch is safe to delete (`scripts/gc.sh`)

**Rule:** Never use `git merge-base --is-ancestor "$branch" HEAD` alone as proof that a branch was merged. A freshly-created branch with zero commits has its tip at the branch point — that commit IS reachable from HEAD, so the check returns true. Guard with an explicit exclusion for branches that are actively checked out in a worktree before running the deletion loop.

**Why:** "Reachable" and "was merged" are not the same thing. A branch with zero unique commits is always an ancestor of anything descended from its branch point. When `/queue` provisions a worktree but the task runner hasn't committed yet, the branch looks merged — and a gc.sh pass that runs concurrently (e.g. from a session-start hook in a parallel subagent) deletes it.

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
**Regression gate:** `tests/gc.test.sh` case "fresh branch feat/queue-task must survive (no commits, active worktree)"

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
