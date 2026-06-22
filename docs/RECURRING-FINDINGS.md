# Recurring Findings

Tracks cross-PR patterns that surface in `/cr` passes. Auto-flagged at Occurrences ≥3 for promotion to PITFALLS.md.

Status key: **Active** — not yet promoted · **Promoted** — now in PITFALLS.md or a named /cr pass-prompt

## How findings flow (the ratchet)

This file is the memory of the learning loop. Findings enter and leave it on a fixed path:

- **In:** `/cr` Step 3b reads this file after every review. It gives each finding a stable
  signature, then either matches an Active entry (and bumps its count + last-seen) or appends a
  new one at Occurrences 1.
- **Out (promotion):** when a finding reaches Occurrences ≥3 — or `/cr` judges it high-impact at a
  lower count — it is promoted. The promoter writes the matching `PITFALLS.md` entry (or a named
  `/cr` pass-prompt) and moves the finding from **Active** to **Promoted** here. A trap seen three
  times stops being a per-PR note and becomes a rule the gate checks every time.
- **Read-back:** `@doc-updater` reads this file during `/compound` and proposes any pending
  promotion in its draft, so the human sees the ratchet fire at PR-review time.

Keep this file under version control — the occurrence counts ARE the ratchet's state. Reset the
file and you reset the loop's memory.

**Parallel-write note:** When two PRs run `/cr` at the same time, both write to this file. If the merge auto-resolves by picking one side, occurrence counts from the other are lost. Use `git merge=union` for this file (add `docs/RECURRING-FINDINGS.md merge=union` to `.gitattributes`) to keep increments from both sides. Until then, treat counts as a lower bound, not an exact record.

---

## Active

### missing-protected-branch-in-test
**Signature:** A regression gate for a hook that protects N branches only covers N-1 of them.
**Occurrences:** 3 — AUTO-PROMOTE
**Last seen:** 2026-06-22
**Locations:** tests/main-branch-guard.test.sh (develop branch missing); .husky/pre-push sync gate (0/4 exclusions tested initially); tests/agent-worktree-enforcement.test.sh (main tested, but not master/HEAD/"")
**Detail:** (1) The hook protects `main|master|develop` but the test had no `develop` stub or cases. (2) The pre-push sync gate skips main/master/HEAD/"" but had zero test coverage for any exclusion. (3) The worktree enforcement test covers `main` as exempt but not `master`, `HEAD`, or empty-string — the other three arms of the same `case` statement. Pattern: every new case-statement exclusion needs a companion test that would fail if that arm were removed. **→ Promoted to PITFALLS.md**

### sync-gate-head-vs-push-sha
**Signature:** A pre-push sync check compares `HEAD` against the upstream instead of `$PUSH_SHA` (the commit actually being pushed), silently passing stale branches in worktree scenarios.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** .husky/pre-push (sync gate, line 60 — initial implementation used HEAD)
**Detail:** `PUSH_SHA` is parsed from stdin at hook start specifically because "git can be in a detached state or a worktree where HEAD ≠ the branch being pushed." Using `HEAD` in the rev-list comparison defeats that. Fixed by replacing `HEAD` with `$PUSH_SHA`. Pattern: any behind-check in a pre-push hook must use the sha from stdin, not HEAD.

### fetch-no-timeout-in-hook
**Signature:** A `git fetch` in a git hook has no timeout, so a hung SSH connection or credential prompt hangs the hook (and the caller) indefinitely.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** .husky/pre-push (sync gate — initial implementation had no timeout)
**Detail:** Fixed by wrapping with `GIT_TERMINAL_PROMPT=0 timeout 15 git fetch ...`. `GIT_TERMINAL_PROMPT=0` prevents credential prompts from blocking a non-interactive hook. `timeout 15` caps the hang. Both are needed; without `GIT_TERMINAL_PROMPT=0`, a missing credential can still block even after the fetch timeout.

### hook-refspec-norm-ref-bypasses
**Signature:** A push refspec that resolves to a protected ref through an unrecognized form bypasses `norm_ref()`.
**Occurrences:** 1
**Last seen:** 2026-06-15
**Locations:** .claude/hooks/block-dangerous-git.sh (norm_ref doesn't resolve HEAD; explicit-arg branch check only)
**Detail:** `git push origin HEAD` on main exits 0 (allowed). `norm_ref("HEAD")` returns `"HEAD"` (not in protected list); two non-flag args means `_non_flag=2` skips the bare-push `_non_flag<=1` fallback. Guard file — NEEDS HUMAN to fix.

### test-mk-no-gitdir-guard
**Signature:** A test helper that calls `git init` in a temp dir does not unset inherited `GIT_DIR` env vars, risking real-repo corruption when run from a worktree.
**Occurrences:** 2
**Last seen:** 2026-06-18
**Locations:** tests/check-integrity.test.sh (mk() function, lines 18–30); tests/install.test.sh (line 695 — correctly handled)
**Detail:** Matches the documented PITFALL "Running tests from inside a worktree corrupts the real repo." The fix is to unset GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/GIT_PREFIX/GIT_COMMON_DIR/GIT_OBJECT_DIRECTORY/GIT_NAMESPACE at the top of the test file. Fixed in both locations. At Occurrences ≥3 this should be promoted to a named /cr check.

### stale-comment-wrong-output-protocol
**Signature:** A comment describes the behavior or output of a command/function, but the actual behavior differs, misleading anyone who reads or extends it.
**Occurrences:** 3 — AUTO-PROMOTE
**Last seen:** 2026-06-22
**Locations:** scripts/check-integrity.sh (lines 34–37); .claude/skills/cr/SKILL.md (Pre-flight step 1); tests/activity.test.sh (header — "Run after applying the hook diff" written when hook was manual; the hook is now committed alongside the test)
**Detail:** (1) awk comment described wrong output columns. (2) `git remote show origin` parenthetical claimed no network call. (3) Test file header told readers to manually apply a hook diff that is committed as part of the same PR. Pattern: comments written at a point in time get stale when the code or process changes around them. **→ Promoted to PITFALLS.md (see below)**
**Post-promotion sightings:** 2026-06-22 — `queue-execute.js`: section header "Stacking helpers," `parseFiles` comment "task is never stacked," `verifyAncestry` parameter `prevSlug` and block comment "feat/<prevSlug>" — all stale after renaming stacking to serialization. `docs/testing/queue-stacking-redesign.md`: claimed `validateStacksOn` throws "before `computeStacks()` runs" — it runs after. Fixed in PR feat/queue-stacking-redesign.

### validate-trim-use-site-mismatch
**Signature:** A validator normalizes input (e.g., trims whitespace) before checking it, but downstream code reads the raw field — so padded input passes validation and then causes a different failure at the use site.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** `.claude/workflows/queue-execute.js` — `validateStacksOn` trims `task.stacksOn` via `(task.stacksOn || '').trim()`, but the Execute and Push phases used `task.stacksOn || null` (raw), so `"  task-a  "` passes validation as `"task-a"` but reaches `worktree-add.sh` with spaces in the branch name.
**Detail:** Fix: normalize at the point of use (`(task.stacksOn || '').trim() || null`), not just at the validation call site. The rule of thumb: if a validator trims or coerces, also trim/coerce at every downstream use of the same field. One normalize-once location (at parse time, before any code sees the value) is cleaner than normalizing at both validate and use.

### doc-shard-not-deleted-on-redesign
**Signature:** A testing-shard file describes how a feature works, then the feature is redesigned, but the old shard is not deleted — leaving the assembled doc with two contradictory descriptions of the same behavior.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** `docs/testing/branch-stacking-queue.md` — described automatic file-overlap branch stacking; still present when the redesign replaced it with explicit `stacksOn`. After merging, `docs/TESTING.md` would have assembled both the old and new behavior descriptions for the same workflow, directly contradicting each other.
**Detail:** Fix: when redesigning a feature whose confirmed behaviors live in a doc shard, add the old shard to the PR's git rm list. Search `docs/testing/` for any file that names the feature being replaced before closing the PR.


### sed-i-macos-only-linux-noop
**Signature:** `sed -i ''` (BSD form) silently no-ops on Linux — GNU sed treats the empty string as a backup suffix, creates `file.bak`, and leaves the original unchanged. Exits 0.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** scripts/update-progress.sh (initial version, all three sed calls)
**Detail:** Fix: write substitutions to a temp file and mv atomically. Reference: project memory reference-ci-linux-vs-macos-parity.md.

### new-detection-path-missing-branch-exclusions
**Signature:** A new code path that collects branch candidates doesn't apply the same exclusion rules as the existing path for the same script.
**Occurrences:** 2
**Last seen:** 2026-06-17
**Locations:** scripts/prune-branches.sh (Pass 2 NO_UPSTREAM; active-worktree exclusion)
**Detail:** Two instances of the same class. (1) The Pass 2 no-upstream detection did not exclude main/master/develop — fixed by adding `grep -vE "^(main|master|develop)$"`. (2) It also did not exclude branches checked out in active worktrees — a freshly-created worktree branch (no commits yet) has its tip at the branch point, so `git merge-base --is-ancestor` returns true and it looks merged. Fixed by collecting `ACTIVE_WT_BRANCHES` from `git worktree list --porcelain` and filtering them from the NO_UPSTREAM candidate list with `grep -vFxf`. Both fixes use `-F` (fixed-string) and `-x` (full-line) to avoid regex metacharacter issues in branch names. Pattern: every new candidate-collection pass in prune-branches.sh must explicitly enumerate and apply all exclusions from the existing pass.

### no-signal-trap-in-mutation-runner
**Signature:** A script that temporarily replaces a file (mutant swap) has no signal trap, leaving the original file in a mutated state if the script is interrupted mid-run.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** scripts/mutation-test.sh (run_against_mutation function)
**Detail:** After cp mutant→orig and before cp backup→orig, a SIGINT leaves the original file as the mutant. A `trap` restoring from backup on INT/TERM/EXIT would prevent this. Not a correctness bug during normal operation, but a recovery hazard. Nice-to-have fix.

### case-short-circuit-silences-later-ban
**Signature:** A `case` statement that checks allow-conditions and ban-conditions in the same block silently skips the ban when an allow-condition matches first.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** scripts/token-lint.sh (border-left ban, lines 245–254 in original; fixed in this PR)
**Detail:** Ban 3 checked `border-left: 1px solid` (allowed), `border-left: 2px solid` (warn), then `border-left:*px solid` (error) as a single `case` statement. A file with both `1px solid` and `4px solid` matched the 1px arm and exited the case — the 4px ban was never evaluated. Fix: strip all allowed thicknesses from a copy of the content, then check the copy for banned patterns. The allow-list and ban-check run on different inputs and cannot short-circuit each other.

### advertised-feature-is-dead-code
**Signature:** Code is described as reading or using an external file, but the variable populated from that file is never referenced in any check.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** scripts/token-lint.sh (known_tokens variable, original lines 54–78)
**Detail:** The script header said "reads the active design token names from docs/design/DESIGN.md" and built a `known_tokens` variable. The variable was never used — checks used `var(--` structural detection, not the token name list. Fixed by removing the loop and updating the header comment to describe what the linter actually does.

### section-count-mismatch-in-agent-spec
**Signature:** An agent spec says "N required sections" in its body but the actual numbered list has a different count, causing the agent to silently skip injecting the extra sections.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** .claude/agents/design-synthesizer.md (lines 29 and 108 say "6"; list has 7 entries)
**Detail:** Body and output-format header both say 6 required sections; the numbered list ends at 7. The commit message correctly states 7. An agent reading the text would stop injecting stubs after section 6. Fix: update both occurrences of "6" to "7" — requires human edit (guard-file path).

### dangling-skill-reference-in-agent-frontmatter
**Signature:** An agent's description frontmatter mentions a slash command or skill that does not exist in the repo.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** .claude/agents/design-synthesizer.md (line 9 — "via /design-init")
**Detail:** No /design-init skill, command, or script exists. Any agent or human reading the spec will try to find it and fail. Either add the skill or remove the reference — requires human edit (guard-file path).

### driver-missing-install-registration
**Signature:** A custom git merge driver is declared in `.gitattributes` but no setup script registers it in `.git/config`, so the driver silently falls back to 3-way merge on any fresh clone or CI environment.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** `.gitattributes` (merge=ours + merge=tasks-higher-state without corresponding npm prepare step)
**Detail:** `.gitattributes` declared two drivers requiring `.git/config` registration (`merge.ours.driver`, `merge.tasks-higher-state.driver`). A fresh clone gets the attributes but not the config, so both file types silently conflict instead of auto-resolving. Fixed by adding `scripts/register-merge-drivers.sh` and wiring it into the `prepare` npm script.

### hardcoded-count-drifts-when-set-grows
**Signature:** A doc says "N items" where N is a hardcoded count of a concrete list (files, rules, cases). When the list grows, the count is wrong until someone notices and fixes it — no automated check catches it.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** docs/testing/gitattributes-merge-drivers.md (line 3 — "Four shared doc files"); docs/patterns-registry.md (line 202 — "four file rules"); docs/solutions/2026-06-18-gitattributes-merge-drivers-for-shared-docs.md (line 131 — "four file rules")
**Detail:** docs/patterns-registry.md was added as a fifth union-merge target in .gitattributes, but three doc files still said "four." Fix: avoid hardcoding counts in prose when the list they count is in the same doc — either reference the list directly ("the files listed below") or keep the count adjacent to the list so it's obviously stale.

### documented-edge-case-not-guarded
**Signature:** A guard condition documents a fallback for an edge case (e.g. "falls back to X if Y") but the code only checks the most obvious form — a related but distinct form of Y slips through.
**Occurrences:** 2
**Last seen:** 2026-06-20
**Locations:** scripts/pr.sh (line 85 — `[ -z "$MERGE_CHECK_BASE" ]` caught empty string but not `"(unknown)"` from git); scripts/worktree-add.sh (BRANCH has a leading-dash guard but BASE_REF, added in the same commit, has no equivalent guard)
**Detail:** (1) `git remote show origin` outputs `(unknown)` when unset. Guard checked only empty string. Fixed by adding `|| [ "$X" = "(unknown)" ]`. (2) `worktree-add.sh` added BASE_REF without the same `case "$BASE_REF" in -*) ... esac` guard already present for BRANCH. A caller passing `--detach` or `-f` as `$3` would cause git to interpret it as a flag. Fixed by adding the guard immediately after the BRANCH check.

### doc-drift-generated-file-references
**Signature:** Multiple skill or agent files still reference a file as the write target after it becomes a generated artifact; agents follow stale instructions and write to the wrong path.
**Occurrences:** 2
**Last seen:** 2026-06-18
**Locations:** .claude/skills/feature/SKILL.md (multiple lines — "writes to docs/TESTING.md"); .claude/agents/task-runner.md (line 79); .claude/agents/spike-slice.md (line 81, 113); .claude/agents/spike-orchestrator.md (line 188); .claude/skills/tdd/SKILL.md (Step 1 and Step 6); .claude/skills/debug/SKILL.md (Step 3 and done-criteria); .claude/skills/cr/SKILL.md (Pass 6 line 189)
**Detail:** When docs/TESTING.md became a generated file, seven instruction files still pointed to it as the direct write target. Agents following those instructions write to the generated file and corrupt it on the next assembly run. Fix: update all instruction files when a write target changes role. Search for `docs/TESTING.md` across all .md files in .claude/ after any similar promotion of a file to generated status.

### hook-diff-filter-missing-deletion
**Signature:** A pre-commit hook using `--diff-filter=ACM` misses deleted files, so side effects that depend on "did a tracked file change" fire only for adds/modifies and silently skip deletes.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** .husky/pre-commit (shard-detection block)
**Detail:** The shard-detection block used ACM. Deleting a shard file didn't trigger reassembly, leaving the deleted content in the generated docs/TESTING.md. Fix: add D to the filter: `--diff-filter=ACDM`.

### hook-grep-glob-pattern-mismatch
**Signature:** A hook's detection pattern and the script it triggers use different path scopes — the hook fires on paths the script won't process.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** .husky/pre-commit (shard detection: grep "^docs/testing/" vs assemble-testing.sh glob *.md top-level only)
**Detail:** The hook's grep matched any path under docs/testing/ including subdirectories. The assembly glob only picks up top-level .md files. Staging docs/testing/subdir/foo.md triggered assembly, but the file was silently excluded from output. Fix: restrict the hook grep to the same scope as the glob: `grep -E "^docs/testing/[^/]+\.md$"`.

### duplicate-line-from-sed-edit
**Signature:** A sed-based text edit leaves a duplicate instruction line when the replacement doesn't first remove the old line.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** .claude/agents/spec-writer.md (line 18 — stale "Derive the shard filename from the current branch name by running:")
**Detail:** A sed substitution added the corrected instruction but didn't delete the old one, leaving both. An agent reading the file sees two conflicting "Derive the shard filename" sentences. Fix: ensure sed edits replace rather than append when the old line is no longer correct.

### truncate-before-write-leaves-partial-output
**Signature:** A script uses `{ ... } > "$OUTPUT"` to write a generated file; a failure inside the braces causes `set -e` to exit mid-write, leaving the output file empty or partial.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** scripts/assemble-testing.sh (pre-fix — `{ ... } > "$OUTPUT"` truncated docs/TESTING.md before the loop body ran)
**Detail:** The shell truncates the output file at the `>` redirect before the compound block runs. Any failure inside (`cat` on a bad file, `git` error) exits via `set -e` mid-write. Fix: write to a temp file and `mv` atomically: `{ ... } > "$OUTPUT.tmp" && mv "$OUTPUT.tmp" "$OUTPUT"`.

### bsd-gnu-sed-quantifier-mismatch
**Signature:** A `sed` expression uses `\+` (one-or-more), which GNU sed accepts as an extension but BSD sed (macOS) does not, causing silent wrong output on one platform.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** scripts/derive-slug.sh (pre-fix — `s|-\+|-|g` failed to collapse repeated hyphens on macOS)
**Detail:** `\+` is a GNU extension. BSD sed interprets it as a literal backslash followed by a plus sign — the substitution matches nothing and repeated hyphens pass through uncollapsed. The POSIX alternative `--*` (hyphen followed by zero-or-more hyphens) works on both. Fix: replace `s|-\+|-|g` with `s|--*|-|g`.

### three-state-conflict-missing-user-only-branch
**Signature:** A three-way sha comparison (local vs. manifest vs. upstream) omits the "user edited, upstream unchanged" branch, causing a false-positive conflict when the user modifies a file that upstream has not touched.
**Occurrences:** 1
**Last seen:** 2026-06-18
**Locations:** scripts/sync-harness.sh (conflict `else` branch, fixed in this PR)
**Detail:** The `else` clause fired when `local_sha != old_sha AND local_sha != upstream_sha`, but did not verify `old_sha != upstream_sha`. A user-only edit hit this branch and blocked sync with "CONFLICT." Fix: add `elif [ "$old_sha" = "$upstream_sha" ]` before the conflict branch to handle the user-edit-only case as a non-error.

### one-sided-test-no-happy-path
**Signature:** A test covers only the rejection / failure path of a new guard; without a passing-path test, a regression that blocks all inputs looks green.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** tests/pr-host-agnostic.test.sh (conflict test added without a clean-branch test for the same guard)
**Detail:** The conflict-detection test verified that a conflicting branch is rejected. No test verified that a clean branch passes. A bug making `grep -c` always return non-zero would block every PR, but all tests would still pass. Fixed by adding a separate test for the clean-branch path.

### null-guard-misses-empty-string
**Signature:** A null guard (`!value`) accepts an empty string as truthy, letting a no-output agent response pass a gate that should reject it.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** `.claude/workflows/queue-execute.js` (design-gate file-existence check — `if (!check)` allowed `check = ""` to proceed, silently passing all MISSING tests when the agent produced no output)
**Detail:** `!check` is false when `check` is `""`, so the guard only catches `null`/`undefined`. A model that runs the commands but produces no output would pass the check and find zero MISSING lines, falsely confirming all files exist. Fix: `!check || !check.trim()`. Pattern: wherever an agent's text output gates a decision, guard against both null and the empty-string case — they are equally invalid responses.

### gate-size-not-mirrored-across-companion-docs
**Signature:** When a gate's size list grows (e.g. adding MEDIUM alongside LARGE), not all companion docs that name the sizes are updated — leaving inconsistent behavior descriptions across files.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** `.claude/agents/task-runner.md` step 1.5 (still said "Size: LARGE / FEATURE" after MEDIUM was added to the workflow gate and SKILL.md Step 2); `.claude/skills/queue/SKILL.md` Step 2 prose (said "A MEDIUM or LARGE task" while omitting FEATURE that appears in the same section's heading)
**Detail:** Three places all documented the gate's size list. When the list changed, one (SKILL.md heading and workflow code) was updated correctly but two others drifted. Pattern: before merging a gate-size change, grep all .md files under .claude/ for the previous size list and update every occurrence.

### test-inline-copy-undocumented-drift-risk
**Signature:** A test file contains an inline copy of a function from a source file that cannot be required, but the comment claims static analysis catches drift — when the static checks only verify substring presence, not logic parity.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** `tests/queue-design-gate.test.sh` (lines 14-26 — inline copy of `validateDesignGate`; comment said "static analysis catches it" but greps only checked that `GATED_SIZES` and `!check` strings appear somewhere in the source)
**Detail:** An inline copy produces behavior tests that are totally disconnected from the actual implementation. Divergence is undetectable if the static grep only checks for substring presence. The correct comment is: "these behavioral tests exercise this copy, not the live function — any change to the function in the source must be manually mirrored here." Requires human discipline to maintain, not automation.
### relative-path-implicit-cwd-in-js
**Signature:** A JS function that shells out to `git -C <path>` uses a relative path resolved against the process CWD rather than an anchored repo root, silently targeting the wrong directory if CWD drifts.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** `.claude/workflows/queue-execute.js` — `isAncestorViaGit` initially built `worktreePath` as `.claude/worktrees/${task.slug}` with no REPO_ROOT anchor.
**Detail:** `execFileSync` resolves relative paths from `process.cwd()`. Workflow scripts typically run from the repo root, but there is no guarantee. If CWD is elsewhere, `git -C <relative>` targets the wrong path, `merge-base --is-ancestor` exits non-zero (ref not found), and the guard returns `false` — aborting the stack group with a misleading "ancestry broken" error when the real issue is a path resolution failure. Fix: resolve `REPO_ROOT = execFileSync('git', ['rev-parse', '--show-toplevel'], {encoding: 'utf8'}).trim()` once at module scope and build the path as `${REPO_ROOT}/.claude/worktrees/${task.slug}`.

### slice-index-off-by-one-in-skip-log
**Signature:** A failure-path log message includes the failing task in the "Skipping" list because `slice(i)` was used instead of `slice(i + 1)`, making it appear the task ran and was skipped when it was never attempted.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** `.claude/workflows/queue-execute.js` — ancestry check failure branch initially used `group.slice(i)` for the downstream list.
**Detail:** When the ancestry check fails for task `i`, the log should list which *downstream* tasks are being cancelled. Using `slice(i)` includes the failing task itself, which confuses a reader: the task appears in the "Skipping" list even though it never got to run a task-runner. The correct pattern (used in the analogous task-runner failure branch in the same loop) is `slice(i + 1)` for downstream tasks, with the failing task named separately in the primary error message.
### platform-field-name-mismatch
**Signature:** A script written for one forge platform (GitHub/GitLab) uses the other platform's API field names, so every record silently passes the filter and no action is taken.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** scripts/sync-open-prs.sh (glab path read `.number`, `.headRefName`, `.isDraft`, `.mergeable` — GitHub field names; glab returns `iid`, `source_branch`, `draft`, `merge_status`)
**Detail:** `glab mr list --output json` returns different keys than GitHub's `gh pr list --json`. Every jq read returned `null`; the CONFLICTING filter always skipped MRs. Feature ran to completion with exit 0 and no output, appearing to work while never rebasing anything. Fixed by adding an explicit "not yet supported" early-exit for the glab path. Pattern: any script that dispatches on forge type must verify the JSON field names match the actual CLI output for *each* forge — they differ significantly between `gh` and `glab`.

### file-path-guard-missing-type-check
**Signature:** A script checks `[ -f "$PATH" ] || exit 0` for an optional config file. When the path is set to a directory, `-f` returns false and the script silently passes — treating a misconfigured path as "not present."
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** scripts/deploy-drift-check.sh (pre-fix — `[ -f "$MANIFEST" ] || exit 0` without checking whether the path exists-but-is-a-directory)
**Detail:** `-f` is false for both "does not exist" and "exists but is a directory." An env var like `HARNESS_DEPLOY_TARGETS` pointing to a directory causes silent pass — the gate looks active but checks nothing. Fix: add `[ -e "$PATH" ] && [ ! -f "$PATH" ]` check before the absent-path early-exit, and print an error to stderr. Pattern: any optional-file guard that distinguishes "not opted in" from "opted in" needs a separate check for "path exists but is wrong type."
### lint-regex-false-positive-on-separator
**Signature:** A lint regex uses `.*` which crosses shell command separators (`;`, `&&`, `|`), producing false positives when the flagged pattern appears in a later command on the same line.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** scripts/shell-portability-lint.sh:29 (mktemp -p check — `\bmktemp\b[[:space:]].*-p\b` matched `mktemp -d; mkdir -p` in tests/pr-host-agnostic.test.sh lines 69, 99, 130, 164)
**Detail:** `.*` in POSIX ERE matches everything including text after `;`. `mktemp -d; mkdir -p "$dir"` triggered the mktemp check because `-p` appeared later on the same line in an unrelated `mkdir -p` call. Fix: replace `.*` with `[^;|&]*` to stop at command separators. This also avoids false positives from `mktemp -d && mkdir -p` and piped commands.

### confirmed-spec-without-implementation
**Signature:** A testing shard entry lists a confirmed behavior that has no corresponding implementation in the hook or script.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** docs/testing/claudemd-to-hooks.md (lines 198–201 — "human push from main worktree warns but does not block" with no matching code in .husky/pre-push)
**Detail:** The worktree check lives entirely inside the non-interactive `else` branch. A human push via TTY does not trigger the worktree check at all — no warning fires. The confirmed behavior was written against an earlier design that was not implemented. Fix: update the spec entry to describe actual behavior. Pattern: testing shard entries must be cross-checked against the live code before merging — a confirmed behavior with no implementation and no test is a spec that can't fail.

### hook-error-message-misleading-recovery
**Signature:** A hook's error message gives a command to run that is blocked by the same hook, creating a recovery loop with no exit.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** .husky/pre-commit (settings.json guard — error message says "git add .claude/settings.json && git commit" but `git commit` goes through the same hook and is blocked by the same guard)
**Detail:** The settings.json guard fires during `git commit` and tells the user "Apply the change directly: git add .claude/settings.json && git commit." Running that command will hit the same guard and fail again. The correct recovery instruction is `git commit --no-verify` since the hook itself is the barrier. Pattern: any error message in a guard hook must verify that the suggested recovery command does not itself pass through the same guard.

### hook-guard-op-coverage-gap
**Signature:** A hook guard that fires on multiple git operations (Add, Modify, Delete) has tests for only one operation type, leaving Modify and Delete regressions undetected.
**Occurrences:** 1
**Last seen:** 2026-06-22
**Locations:** tests/safety-file-guard.test.sh (.claude/hooks/* guard — only Add tested; .husky/* guard correctly has all three)
**Detail:** The `.husky/*` guard has three test cases (new, modify, delete), covering all arms of the ACMRDT filter. The `.claude/hooks/*` guard in the same file has only one test (new file). A regression that removes the Modify or Delete arm from the guard would go undetected. Pattern: for every category a hook protects, test each operation type (Add, Modify, Delete) that the diff-filter covers — not just Add.

---

## Promoted

### internal-code-no-explanation
**Promoted:** 2026-06-22 (Occurrences: 3)
**Entry:** PITFALLS.md → "Internal labels without explanation: 'Layer 2a', 'CMP4', 'F6', 'R4-D2'"
### missing-protected-branch-in-test
**Promoted:** 2026-06-22 (Occurrences: 3)
**Entry:** PITFALLS.md → "Exempt branch arms in hook tests: every case arm needs its own test"

### stale-comment-wrong-output-protocol
**Promoted:** 2026-06-18 (Occurrences: 3)
**Entry:** PITFALLS.md → "Stale comments: describing code state that has since changed"
**Post-promotion sighting:** 2026-06-20 — `scripts/worktree-add.sh` line 3 header comment said `Usage: ... <path> <branch>` after adding an optional `[base-ref]` parameter. The `:?` usage strings on lines 13–14 were updated but the header was not. Fixed in this pass.
**Post-promotion sighting:** 2026-06-22 — `scripts/ci-verify.sh` deploy-drift step comment said "Exits 0 when the manifest is absent (opt-in only)" — omitted the second exit-0 case (all entries pass). Fixed in this pass.
