## Commit-message linter (`scripts/commit-msg-lint.sh`, `.husky/commit-msg`)

`commit-msg-lint.sh` reads the commit message file passed as `$1` and checks
the first line against the conventional commit format. `.husky/commit-msg` is
the hook that calls it.

### Confirmed behaviors

- **Valid conventional commit exits 0:** Given a commit message whose first line
  matches `type(scope)?!?: description` (e.g. `feat(auth): add login`), the
  script exits 0 and produces no output.

- **Unknown type exits 1:** Given a first line whose type is not in the allowed
  set {feat, fix, chore, docs, refactor, test, perf, build, ci, style, revert},
  the script exits 1 and writes an explanation to stderr.

- **Missing description exits 1:** Given a first line that ends at the colon
  with nothing after it (e.g. `fix: `), the script exits 1 and writes an
  explanation to stderr.

- **Description starting with uppercase letter exits 1:** Given a first line
  where the description begins with an uppercase character (e.g. `fix: Fix bug`),
  the script exits 1 and writes an explanation to stderr.

- **Scope with uppercase letters exits 1:** Given a scope that contains an
  uppercase letter (e.g. `feat(Auth): add login`), the script exits 1 and
  writes an explanation to stderr.

- **Scope with characters outside `[a-z0-9-]` exits 1:** Given a scope
  containing an underscore, space, or other character not matching
  `[a-z0-9-]` (e.g. `feat(my_scope): add login`), the script exits 1 and
  writes an explanation to stderr.

- **Breaking-change marker `!` is accepted:** Given a first line with `!`
  between the scope (or type) and the colon (e.g. `feat(auth)!: drop old api`),
  the script exits 0.

- **Merge commit is skipped:** Given a first line that starts with `Merge `,
  the script exits 0 without validating the rest of the message.

- **squash! commit is skipped:** Given a first line that starts with `squash! `,
  the script exits 0 without validating the rest of the message.

- **fixup! commit is skipped:** Given a first line that starts with `fixup! `,
  the script exits 0 without validating the rest of the message.

- **Revert commit is skipped:** Given a first line that starts with `Revert `
  (capital R, space), the script exits 0 without validating the rest of the
  message. This matches the format git generates automatically for `git revert`.

- **First line over 72 chars emits a warning but exits 0:** Given a valid
  conventional commit whose first line exceeds 72 characters, the script writes
  a warning to stderr and exits 0. The commit is not blocked.

- **Body and footer are not validated:** Given a commit message with a valid
  first line followed by any body or footer content, the script exits 0
  regardless of that content.

- **Hook calls script with message file path:** `.husky/commit-msg` invokes
  `bash scripts/commit-msg-lint.sh "$1"`, where `$1` is the path git passes to
  the hook.

## Pre-push sync gate (`.husky/pre-push`)

A sync gate block is inserted into `.husky/pre-push` after the merged-PR check
and before the TTY detection / sentinel check. It fetches `origin/<default-branch>`
and blocks the push if the current branch is behind, telling the user to rebase
manually before pushing.

### Confirmed behaviors

- **Up-to-date branch: push continues:** Given the current branch has 0 commits
  behind `origin/<default-branch>`, the gate does nothing and the push continues.

- **Branch behind by N commits is blocked:** Given the current branch is behind
  `origin/<default-branch>` by one or more commits, the gate exits 1 and prints
  a message telling the user to run `git rebase origin/<default-branch>` before
  pushing.

- **Push to main or master is not checked:** Given `BRANCH` is `main` or
  `master`, the gate skips the sync check entirely and continues.

- **Push when BRANCH is HEAD or empty is not checked:** Given `BRANCH` is the
  literal string `HEAD` or is empty, the gate skips the sync check and continues.

- **Fetch failure skips the check:** Given `git fetch origin <default-branch>
  --quiet` exits non-zero (e.g. no network), the gate skips the sync check and
  continues. The push is not blocked by a network error.

- **DEFAULT_BRANCH is read from origin/HEAD:** The gate derives the default
  branch name via `git symbolic-ref refs/remotes/origin/HEAD | sed 's|.*/||'`
  and falls back to `main` when that command returns empty or fails.

## CLAUDE.md enforcement map

A new section in `CLAUDE.md` documents which rules are enforced by hooks and
which remain agent-only guidance.

### Confirmed behaviors

- **Section heading is "# Mechanical enforcement":** The new section appears at
  the bottom of `CLAUDE.md` and uses exactly that heading.

- **Section lists mechanically gated rules:** The section names the rules that
  hooks now enforce: commit format, pre-push sync, design-confirmed gate,
  `.cr-ok` gate, and lint / comment-lint / token-lint.

- **Section lists agent-only rules:** The section names the rules that remain
  guidance without a hook gate: communication voice rules, and work routing via
  `/refactor` (no sentinel exists for refactor).

- **Section is informational only:** The section contains no hook logic and does
  not itself gate any action. It exists to tell engineers what is automatic and
  what is not.

## Install script (`scripts/install.sh`) — commit-msg additions

### Confirmed behaviors

- **install.sh includes `.husky/commit-msg` in the copy-files list:** After the
  feature is applied, the `COPY_FILES` list in `install.sh` contains an entry
  for `.husky/commit-msg` so the hook is copied into the target repo.

- **install.sh runs `git remote set-head origin --auto` after npm install:**
  After running `npm install` (to set up husky), `install.sh` executes
  `git remote set-head origin --auto` so that `refs/remotes/origin/HEAD` is
  populated and the `DEFAULT_BRANCH` detection in the pre-push gate works on
  first install.
