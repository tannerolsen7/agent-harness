# Spec: Audit CLAUDE.md rules → move to deterministic hooks

<!-- spec-meta
slug: claudemd-to-hooks
human-approved: true
status: complete
-->

## User goal

Every rule in CLAUDE.md that can be enforced mechanically should stop a violation at
commit or push time — not rely on an agent reading the docs and making a good decision.
When a violation happens, the error message tells the user exactly what is wrong and
what to do to fix it.

## User journey

1. Agent finishes a commit message with a 73-character subject → commit-msg hook blocks
   with a clear message and the character count.
2. Agent tries to push a branch named `my-feature` → pre-push hook blocks and says to
   rename it to `feat/my-feature`.
3. Agent writes `.claude/.cr-ok` directly via a Write tool call, then tries to commit →
   pre-commit hook blocks and says to use `scripts/cr-ok.sh`.
4. Agent writes a shell script using `mktemp -p /tmp` → pre-commit lint flags it and
   says to use `mktemp "/tmp/file.XXXXXX"` instead (BSD `mktemp` does not support `-p`).
5. Agent writes `printf '- [x] item'` in a shell script → pre-commit lint flags it and
   says to add `--` before the format string.
6. Agent writes `git worktree list --porcelain | grep "worktree $path"` in a shell
   script → pre-commit lint warns that `[ -f "$path/.git" ]` is the correct check.
7. Agent tries to push a `feat/` branch while the same enforcement is already in place →
   the push goes through with no friction.

## What this feature does NOT do

- Does not enforce communication voice (9th-grade reading level) — no linter can
  catch bad prose reliably.
- Does not enforce `/refactor`-before-structural-moves as a full semantic check — only
  the shell portability lint rules apply to shell scripts; structural refactoring in
  TypeScript/JavaScript remains guidance-only.
- Does not touch the global `~/.claude/CLAUDE.md` — only the project-level file.
- Does not change the behavior of existing enforcement (commit-msg format, sync gate,
  design-confirmed, CR sentinel, lint/comment-lint/token-lint).

## Behaviors (7)

1. **Branch naming blocked on push** — A push from a branch whose name does not follow
   `type/slug` (where type is one of feat/fix/refactor/chore/docs/test/perf/build/ci/
   style/revert) is blocked. main, master, HEAD, and empty-name are exempt.

2. **72-char commit subject → hard block** — A commit subject exceeding 72 characters
   is now a hard error (exit 1), not a warning. Auto-generated commits (Merge, squash!,
   fixup!, Revert) remain exempt.

3. **Sentinel direct write blocked** — Staging `.claude/.cr-ok` or
   `.claude/.design-confirmed` directly (not via the designated scripts) is blocked in
   pre-commit with a message pointing to the correct script.

4. **`mktemp -p` portability lint** — Staging a `.sh` file containing `mktemp -p`
   triggers a pre-commit error explaining the BSD/macOS incompatibility and the correct
   form.

5. **`printf` leading-dash lint** — Staging a `.sh` file containing `printf '- ` or
   `printf "- ` (a format string that starts with a dash, without `--`) triggers a
   pre-commit error explaining the bash 3.2 issue.

6. **Worktree detection pattern lint** — Staging a `.sh` file that uses
   `git worktree list --porcelain` piped to `grep` for existence detection triggers a
   pre-commit warning pointing to `[ -f "$path/.git" ]` as the correct pattern.

7. **CLAUDE.md enforcement table updated** — The "guidance only" section loses the two
   rules that now have hooks. The "mechanical enforcement" table gains the new rules.
   PITFALLS.md gains entries for the three new shell-portability rules (mktemp, printf
   leading-dash, worktree detection) if they don't already have them.

## Edge cases

- **Branch exemptions**: main, master, HEAD, and "" must pass branch-name enforcement
  unconditionally. Deleting a branch (all-zeros SHA) must pass.
- **Commit exemptions**: Merge commits, squash!, fixup!, Revert commits are already
  exempt from subject-length checking in commit-msg-lint.sh — this must stay true.
- **Sentinel path**: `.claude/.cr-ok` and `.claude/.design-confirmed` are listed in
  `.gitignore`. The block only fires if someone forces them into the index (e.g.
  `git add -f`). The message must mention this.
- **`mktemp` false positives**: A comment that mentions `mktemp -p` should not trigger
  the lint. Check that the match excludes comment lines.
- **`printf` false positives**: `printf -- '- ` (already correct) must NOT trigger the
  lint. The lint only fires when the `--` is absent.
- **`printf` scope**: Only `.sh` files are linted for this rule. TypeScript/JS files
  that use `printf` in strings are not affected.
- **Worktree detection scope**: Only `.sh` files are checked. The pattern must only
  flag `grep`-for-path usage, not all uses of `git worktree list --porcelain`.

## DMMT (Don't Make Me Think) audit

Each new error message must:
- Name the violated rule in one sentence.
- Give the exact fix (command to run, or form to use instead).
- Never require the user to look up another file to understand what to do.

Example for mktemp:
```
pre-commit: mktemp -p is not supported on BSD/macOS.
  Use: mktemp "/tmp/file.XXXXXX"  (not: mktemp -p /tmp)
  File: scripts/foo.sh:42
```

Example for branch naming:
```
Push blocked: branch 'my-feature' does not follow type/slug naming.
  Rename it: git branch -m my-feature feat/my-feature
  Valid prefixes: feat/ fix/ refactor/ chore/ docs/ test/ perf/ build/ ci/ style/ revert/
```
