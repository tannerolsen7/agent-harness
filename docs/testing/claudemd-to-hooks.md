## Branch naming gate (`.husky/pre-push`)

A check added to `.husky/pre-push` blocks pushes from branches whose names do
not follow the `type/slug` pattern. It runs right after the all-deletions guard
and before the sync gate, so no network fetch has happened yet.

### Confirmed behaviors

- **Valid `type/slug` branch passes:** Given a branch whose name matches
  `<type>/<slug>` where `<type>` is one of {feat, fix, refactor, chore, docs,
  test, perf, build, ci, style, revert} and `<slug>` is a non-empty string,
  the check exits 0 and the push continues to the sync gate.

- **Invalid branch name is blocked:** Given a branch whose name does not match
  the `type/slug` pattern (e.g. `my-branch`, `feature-login`, `FEAT/thing`),
  the check exits 1 and blocks the push. The error message includes the correct
  rename command and a list of valid type prefixes.

- **`feat/` with no slug is blocked:** Given a branch named exactly `feat/`
  (or any valid type followed by `/` with nothing after the slash), the check
  exits 1 with a message containing "missing a slug after the slash."

- **`revert/` prefix is valid:** Given a branch named `revert/<slug>`, the
  check exits 0 and the push continues.

- **main and master are exempt:** Given `BRANCH` is `main` or `master`, the
  naming check is skipped and the push continues.

- **HEAD and empty-string branches are exempt:** Given `BRANCH` is the literal
  string `HEAD` or is empty, the naming check is skipped and the push continues.

- **Deletion pushes are exempt:** Given all refs in the push have an all-zeros
  new SHA (a delete push), the existing `$_ALL_DELETIONS` guard fires before
  the naming check and the naming check never runs.

- **Check runs before the sync gate:** Given a branch that fails the naming
  check, the gate exits 1 before performing any `git fetch`, so no network
  call is made.

## Commit subject length hard block (`scripts/commit-msg-lint.sh`)

The 72-character subject-length check is upgraded from a warning to a hard
block. A commit whose subject exceeds 72 characters now causes the script to
exit 1 instead of exiting 0.

### Confirmed behaviors

- **Subject over 72 chars exits 1:** Given a valid conventional commit whose
  first line is longer than 72 characters, the script exits 1 and the commit
  is blocked. The error message shows the actual character count.

- **Auto-generated commits remain exempt:** Given a first line that starts with
  `Merge `, `squash! `, `fixup! `, or `Revert ` (the existing case-statement
  patterns), the script exits 0 regardless of length. The exemption list is
  unchanged from the previous behavior.

- **Subject at exactly 72 chars passes:** Given a valid conventional commit
  whose first line is exactly 72 characters long, the script exits 0.

## Sentinel direct-write guard (`.husky/pre-commit`)

A check added to `.husky/pre-commit` detects when `.claude/.cr-ok` or
`.claude/.design-confirmed` has been staged directly and blocks the commit.

### Confirmed behaviors

- **Staging `.claude/.cr-ok` directly is blocked:** Given `git add -f
  .claude/.cr-ok` has been run and the file appears in `git diff --cached
  --name-only --diff-filter=ACM`, the pre-commit hook exits 1 and blocks the
  commit.

- **Staging `.claude/.design-confirmed` directly is blocked:** Given `git add
  -f .claude/.design-confirmed` has been run and the file appears in the cached
  diff, the pre-commit hook exits 1 and blocks the commit.

- **Error message names both files and their correct scripts:** The error output
  names both `.claude/.cr-ok` and `.claude/.design-confirmed` and tells the
  user to use `scripts/cr-ok.sh` and `scripts/design-confirm.sh` respectively.
  It also notes that these files are gitignored and can only be staged with
  `git add -f`.

- **Normal staged files are not affected:** Given only ordinary source files are
  staged (no sentinel files), the sentinel check exits 0 and pre-commit
  continues to the next check.

## Shell portability linter (`scripts/shell-portability-lint.sh`)

A new script that checks staged `.sh` files for three patterns that fail on
BSD/macOS or older bash. Called from `.husky/pre-commit` on staged `.sh` files.

### Confirmed behaviors — `mktemp -p` lint

- **`mktemp -p` in code exits 1:** Given a staged `.sh` file that contains
  `mktemp -p` on a non-comment line, the script exits 1.

- **Comment lines are skipped:** Given a line whose first non-whitespace
  character is `#`, the script does not flag `mktemp -p` on that line even if
  the pattern appears in the text.

- **Error shows file and line number:** The error output includes the file path
  and line number where the violation was found.

- **Error explains the incompatibility and gives correct form:** The error
  message explains that `mktemp -p` is not supported on BSD/macOS and shows
  the correct alternative: `mktemp "DIR/file.XXXXXX"`.

### Confirmed behaviors — `printf` leading-dash lint

- **`printf '- ...'` exits 1:** Given a staged `.sh` file containing a line
  with `printf` followed by a single-quoted string starting with `-` (e.g.
  `printf '- item'`) and the line does not contain `printf --`, the script
  exits 1.

- **`printf "- ..."` exits 1:** Given a staged `.sh` file containing a line
  with `printf` followed by a double-quoted string starting with `-` and the
  line does not contain `printf --`, the script exits 1.

- **`printf '-%s'` and `printf '-n'` are flagged:** Pattern `printf ['"]-`
  without `printf --` on the same line is the match condition; both single and
  double quotes are covered.

- **`printf -- '- item'` passes:** Given a line that contains `printf --`
  before the format string, the check exits 0 for that line.

- **Comment lines are skipped:** Given a line whose first non-whitespace
  character is `#`, the printf check does not flag it.

- **Error shows file and line number:** The error output includes the file path
  and line number of the violation.

- **Error explains the issue and gives correct form:** The error message explains
  the bash 3.2 incompatibility and shows the fix: use `printf -- '...'` with
  the `--` separator.

### Confirmed behaviors — worktree detection pattern lint

- **`git worktree list --porcelain | grep` exits 1:** Given a staged `.sh` file
  containing a line that pipes `git worktree list --porcelain` to `grep` for
  path existence detection, the script exits 1.

- **`git worktree list --porcelain` without piping to grep is not flagged:**
  Given a line that uses `git worktree list --porcelain` but does not pipe the
  output to `grep`, the script exits 0 for that line.

- **Comment lines are skipped:** Given a line whose first non-whitespace
  character is `#`, the worktree detection check does not flag it.

- **Error points to the correct alternative:** The error message tells the user
  to use `[ -f "$path/.git" ]` to check whether a worktree path exists.

## CLAUDE.md and PITFALLS.md documentation updates

### Confirmed behaviors

- **CLAUDE.md enforcement table gains new rows:** The "Mechanical enforcement"
  table in `CLAUDE.md` is updated to include rows for: branch naming
  enforcement, the 72-character subject hard block, sentinel direct-write
  blocking, and the shell portability lint. Each row names the rule and the
  hook or script that enforces it.

- **CLAUDE.md guidance-only section updated for branch naming:** The entry for
  `/refactor` before structural moves in the guidance-only section is updated to
  note that branch naming now partially enforces the routing rule (the branch
  type prefix must match the work type), while detection of structural moves in
  diffs remains guidance-only.

- **PITFALLS.md `mktemp` entry regression gate updated:** The existing
  `mktemp -p` pitfall entry has its "Regression gate" field changed from
  "Human review" to a reference to `scripts/shell-portability-lint.sh`.

- **PITFALLS.md `printf` entry regression gate updated:** The existing `printf`
  leading-dash pitfall entry has its "Regression gate" field changed from
  "Human review" to a reference to `scripts/shell-portability-lint.sh`.

- **PITFALLS.md worktree detection entry regression gate updated:** The existing
  worktree detection pitfall entry has its "Regression gate" field changed from
  "Human review" to a reference to `scripts/shell-portability-lint.sh`.
