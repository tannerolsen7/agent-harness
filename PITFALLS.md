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
