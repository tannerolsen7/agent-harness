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
**Occurrences:** 1
**Last seen:** 2026-06-15
**Locations:** tests/main-branch-guard.test.sh (develop branch missing)
**Detail:** The hook protects `main|master|develop` but the test had no `develop` stub or cases. Dropping `develop` from the hook case pattern would ship green. Fixed by adding STUB_DEVELOP + 2 cases.

### hook-refspec-norm-ref-bypasses
**Signature:** A push refspec that resolves to a protected ref through an unrecognized form bypasses `norm_ref()`.
**Occurrences:** 1
**Last seen:** 2026-06-15
**Locations:** .claude/hooks/block-dangerous-git.sh (norm_ref doesn't resolve HEAD; explicit-arg branch check only)
**Detail:** `git push origin HEAD` on main exits 0 (allowed). `norm_ref("HEAD")` returns `"HEAD"` (not in protected list); two non-flag args means `_non_flag=2` skips the bare-push `_non_flag<=1` fallback. Guard file — NEEDS HUMAN to fix.

### test-mk-no-gitdir-guard
**Signature:** A test helper that calls `git init` in a temp dir does not unset inherited `GIT_DIR` env vars, risking real-repo corruption when run from a worktree.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** tests/check-integrity.test.sh (mk() function, lines 18–30)
**Detail:** Matches the documented PITFALL "Running tests from inside a worktree corrupts the real repo." The fix is to unset GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/GIT_PREFIX/GIT_COMMON_DIR/GIT_OBJECT_DIRECTORY/GIT_NAMESPACE at the top of the test file. Fixed in this PR.

### stale-comment-wrong-output-protocol
**Signature:** A comment describes the behavior or output of a command/function, but the actual behavior differs, misleading anyone who reads or extends it.
**Occurrences:** 2
**Last seen:** 2026-06-17
**Locations:** scripts/check-integrity.sh (lines 34–37, comment above run_one()); .claude/skills/cr/SKILL.md (Pre-flight step 1 — parenthetical said "no network call" but the command makes one)
**Detail:** (1) Comment said awk emits `BROKEN<TAB>source<TAB>target`; it actually emits `CHECK<TAB>src<TAB>tgt<TAB>path`. (2) `git remote show origin` parenthetical claimed "reads local config, no network call" — only true with the `-n` flag, which this command does NOT use. Fixed in both PRs.

### internal-code-no-explanation
**Signature:** An internal label (CMP*, R4-D*, Fx) is used in prose or code without being explained, leaving cold readers confused.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** scripts/check-integrity.sh (header), .claude/agents/doc-updater.md (section headings), docs/patterns-registry.md (Established by line)
**Detail:** "CMP4", "CMP1", "CMP2" appear without explanation. CLAUDE.md rule: do not drop internal codes without explaining them first. Partially fixed in this PR (CMP labels removed from doc-updater.md headings; CMP4 explained in check-integrity.sh header).

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
**Locations:** scripts/gc.sh (Pass 2 NO_UPSTREAM, lines 35–41; active-worktree exclusion, lines 51–62)
**Detail:** Two instances of the same class. (1) The Pass 2 no-upstream detection did not exclude main/master/develop — fixed by adding `grep -vE "^(main|master|develop)$"`. (2) It also did not exclude branches checked out in active worktrees — a freshly-created worktree branch (no commits yet) has its tip at the branch point, so `git merge-base --is-ancestor` returns true and it looks merged. Fixed by collecting `ACTIVE_WT_BRANCHES` from `git worktree list --porcelain` and filtering them from the NO_UPSTREAM candidate list with `grep -vFxf`. Both fixes use `-F` (fixed-string) and `-x` (full-line) to avoid regex metacharacter issues in branch names. Pattern: every new candidate-collection pass in gc.sh must explicitly enumerate and apply all exclusions from the existing pass.

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

### documented-edge-case-not-guarded
**Signature:** A guard condition documents a fallback for an edge case (e.g. "falls back to X if Y") but the code only checks the most obvious form — a related but distinct form of Y slips through.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** scripts/pr.sh (line 85 — `[ -z "$MERGE_CHECK_BASE" ]` caught empty string but not `"(unknown)"` from git); .claude/skills/cr/SKILL.md (same guard)
**Detail:** `git remote show origin` outputs the literal string `(unknown)` when the remote HEAD symref is unset. TESTING.md documented "falls back to main if the remote HEAD cannot be determined" — but `(unknown)` is non-empty, so the guard didn't fire. Fixed by adding `|| [ "$X" = "(unknown)" ]`.

### one-sided-test-no-happy-path
**Signature:** A test covers only the rejection / failure path of a new guard; without a passing-path test, a regression that blocks all inputs looks green.
**Occurrences:** 1
**Last seen:** 2026-06-17
**Locations:** tests/pr-host-agnostic.test.sh (conflict test added without a clean-branch test for the same guard)
**Detail:** The conflict-detection test verified that a conflicting branch is rejected. No test verified that a clean branch passes. A bug making `grep -c` always return non-zero would block every PR, but all tests would still pass. Fixed by adding a separate test for the clean-branch path.

---

## Promoted

*(none yet)*
