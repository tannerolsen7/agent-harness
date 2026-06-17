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

## Writing a sentinel directly to bypass a gate

**Area:** Sentinel system (`.claude/.cr-ok`, `.claude/.design-confirmed`)

**Rule:** Never write a sentinel file directly (via Write-tool, `printf >`, or any means other than the designated script). Writing it directly produces a file that passes the gate's string comparison while certifying work that was never done.

**Why:** The sentinel is an honor-system certificate, not a cryptographic proof. Its only integrity property is that `scripts/cr-ok.sh` and `scripts/design-confirm.sh` refuse dirty trees and self-resolve `branch:sha` — bypasses strip both guarantees. A hand-written `.cr-ok` certifies a review that never ran; a hand-written `.design-confirmed` certifies a design session that never happened. Both silently propagate false assurance through every downstream gate.

**Symptoms:** Gate passes without the corresponding gate script having been invoked; audit log is absent or shows no matching entry for the branch:sha.

**When the gate fires unexpectedly:** Fix the condition (run the gate, commit the artifacts, resolve the stale sha) — do not write the sentinel to get past it.
