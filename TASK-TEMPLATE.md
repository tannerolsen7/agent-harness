# Audit CLAUDE.md rules → deterministic hooks

## What & Why

Rules marked "guidance only" in CLAUDE.md are invisible to the tools agents and
humans use every day. An agent can write `mktemp -p /tmp` (fails on macOS), push a
branch named `my-fix` (bypasses the routing system), write a 74-char commit subject
(hard to read in git log), or stage `.claude/.cr-ok` directly (certifies a review
that never ran) — and nothing stops them. This feature converts five of those rules
into hook-level checks that fire with clear, actionable error messages.

## Context

Existing hook infrastructure (do not recreate):
- `.husky/pre-commit` — calls lint.sh, token-lint.sh, comment-lint.sh,
  data-state-lint.sh. All new pre-commit checks follow this call pattern.
- `.husky/pre-push` — reads stdin, extracts $BRANCH and $PUSH_SHA, runs sync gate
  and CR sentinel check. New branch-name check inserts after the sync gate.
- `scripts/commit-msg-lint.sh` — already checks format; 72-char is an advisory
  `printf` warning on line 26-28. Upgrade: change exit 0 to exit 1 there.
- `scripts/comment-lint.sh` — reference for "scan staged .sh files for a pattern."
  Same --diff mode and file-collection pattern apply here.
- `docs/solutions/2026-06-16-stub-git-for-hook-branch-testing.md` — how to stub git
  for branch-conditional hook tests.

## Done Looks Like

- `git commit -m "$(python3 -c "print('feat: ' + 'x'*70)")"` → exit 1, message shows
  char count
- `git push` from a branch named `my-feature` → blocked, message says to rename it
- `git push` from `feat/my-feature` → passes
- `git push` from `main` → passes (exempt)
- `git add -f .claude/.cr-ok && git commit` → pre-commit blocks, points to
  `scripts/cr-ok.sh`
- `bash scripts/shell-portability-lint.sh file.sh` where file.sh has `mktemp -p /tmp`
  → exit 1, shows file:line, explains BSD incompatibility, gives correct form
- `bash scripts/shell-portability-lint.sh file.sh` where file.sh has
  `printf '- item'` (no `--`) → exit 1, shows file:line, gives correct form
- `bash scripts/shell-portability-lint.sh file.sh` where file.sh has
  `printf -- '- item'` (with `--`) → exit 0
- `bash scripts/shell-portability-lint.sh file.sh` where file.sh uses
  `git worktree list --porcelain | grep` for path existence → prints advisory warning,
  exits 0 (non-blocking)
- `npm test` → all new test files pass

## Interface Contract

### scripts/shell-portability-lint.sh (new)

Inputs:
- No args: scan all .sh files in the repo (excluding node_modules, .git, worktrees)
- `--diff`: scan only files staged in the current commit (used from pre-commit)
- File paths as positional args: scan those specific files

Outputs:
- stdout: summary line ("shell-portability-lint: OK (N files)")
- stderr: violations — format: `shell-portability-lint: FILE:LINE — RULE. Fix: EXACT_COMMAND`
- Exit 0 = clean, exit 1 = violations found
- All three checks (mktemp, printf, worktree) → exit 1; all are blocking

### .husky/pre-push (branch naming addition)

Inputs:
- $BRANCH — already extracted from stdin by existing hook logic
- Exempt set: main, master, HEAD, ""  
- Deletion refs (all-zeros SHA) — already handled by existing `$_ALL_DELETIONS` guard

Logic: after the $_ALL_DELETIONS guard and the merged-PR check, BEFORE the sync gate (fail fast — don't do a network fetch for a branch that will be blocked anyway), add:
```sh
case "$BRANCH" in
  main|master|HEAD|"") ;;
  feat/*|fix/*|refactor/*|chore/*|docs/*|test/*|perf/*|build/*|ci/*|style/*|revert/*)
    # valid slug must follow the slash — "feat/" alone is invalid
    _slug="${BRANCH#*/}"
    if [ -z "$_slug" ]; then
      echo "Push blocked: '$BRANCH' is missing a slug after the slash." >&2
      exit 1
    fi
    ;;
  *)
    echo "Push blocked: branch '$BRANCH' does not follow type/slug naming." >&2
    echo "  Rename: git branch -m $BRANCH feat/$BRANCH" >&2
    echo "  Valid prefixes: feat/ fix/ refactor/ chore/ docs/ test/ perf/ build/ ci/ style/ revert/" >&2
    exit 1
    ;;
esac
```

### .husky/pre-commit (sentinel check addition)

Inputs:
- `git diff --cached --name-only` output

Logic: check before the other lint calls; fast-fail if sentinel is staged:
```sh
STAGED_SENTINELS=$(git diff --cached --name-only --diff-filter=ACM | \
  grep -E '\.claude/\.(cr-ok|design-confirmed)$' || true)
if [ -n "$STAGED_SENTINELS" ]; then
  echo "pre-commit: do not stage sentinel files directly." >&2
  echo "  .cr-ok     → use scripts/cr-ok.sh" >&2
  echo "  .design-confirmed → use scripts/design-confirm.sh" >&2
  echo "  These files are gitignored; if you added them with -f, remove them from staging." >&2
  exit 1
fi
```

### scripts/commit-msg-lint.sh (modification)

Line ~26-28 — change the 72-char advisory to a hard block:
```sh
# Current (advisory):
if [ "${#first}" -gt 72 ]; then
  printf "commit-msg: warning: subject is %d chars (recommended max: 72)\n" "${#first}" >&2
fi

# New (hard block):
if [ "${#first}" -gt 72 ]; then
  printf "commit-msg: subject is %d chars (max: 72). Shorten before committing.\n" "${#first}" >&2
  exit 1
fi
```

Constraints:
- Hooks are POSIX sh (`.husky/pre-commit`, `.husky/pre-push`) — no bashisms, no arrays
- `scripts/shell-portability-lint.sh` is bash (shebang `/usr/bin/env bash`)
- All three shell portability checks skip comment lines (`#` prefix after optional whitespace);
  no per-line suppression mechanism
- printf lint: flag any line matching `printf ['"]-` (quote followed by dash) when that
  line does NOT also contain `printf --`; this covers printf '- ', printf "- ",
  printf '-%s', printf '-n' — all dangerous forms in bash 3.2
- printf lint: only `.sh` files — not .ts, .js, .md
- worktree lint: flag `git worktree list --porcelain | grep` existence checks; exit 1 (blocking)
- Tests: unset GIT_DIR and all git env vars at top of each test file (existing pattern)
- Branch check must not fire for deletion pushes — already handled by $\_ALL\_DELETIONS

State:
- None. All checks are stateless reads of file content and git index.

## Open Questions (must NOT be answered by the implementing agent)

1. Should `revert/slug` branches ever be created by the harness (e.g. by a `/revert`
   skill)? If not, should `revert/` be removed from the valid prefix list? Surfaced
   only — the current spec includes it because it matches the commit type list.

2. Should the worktree detection check eventually be promoted to a hard block (exit 1)?
   It is advisory now because the pattern works but is fragile. If a future incident
   proves it breaks silently, promote it.

## Out of Scope

- Communication voice / prose linting — subjective; no reliable linter exists
- Structural move detection in TypeScript/JS — too many false positives
- Agent YAML frontmatter (Task tool / permissionMode) validation
- Design contract cross-branch reference lint
- File sync three-way comparison logic check
- Parser scope agreement check

## Relevant Files

- `.husky/pre-commit` — add sentinel check + shell-portability-lint call
- `.husky/pre-push` — add branch naming check (after sync gate, before npm test)
- `scripts/commit-msg-lint.sh:26-28` — 72-char advisory → hard block
- `scripts/shell-portability-lint.sh` (NEW)
- `CLAUDE.md` — enforcement table: add new rows for each new check; guidance-only:
  update the `/refactor before structural moves` entry to note that branch naming
  now partially enforces the routing rule (refactor/ branch required for pushed
  refactors) while structural move detection in diffs remains guidance-only
- `PITFALLS.md` — all three entries (mktemp, printf, worktree) already exist;
  update only their `Regression gate` lines to point to `scripts/shell-portability-lint.sh`
  instead of "Human review" / the single test file they currently cite
- `tests/shell-portability-lint.test.sh` (NEW)
- `tests/pre-push-branch-naming.test.sh` (NEW)
- `tests/commit-msg-lint.test.sh` (MODIFY — add 72-char hard-block cases)

## Design Questions Sheet

### 1. Data shape

No database or schema changes. No new persistent state. The only "data" involved is:
- File content of staged `.sh` files (read-only)
- Git index state (`git diff --cached --name-only`)
- Commit message text (passed as a file path to commit-msg hook)
- Branch name (parsed from pre-push stdin)

No Zod schemas. No migrations. No tenant/owner scoping concerns.

### 2. Edge cases

**mktemp check:**
- Must skip lines where the leading non-whitespace is `#` (comment lines)
- Must NOT flag `mktemp "/tmp/prefix.XXXXXX"` — only `mktemp -p <dir>` is flagged
- Must NOT flag a comment that *mentions* `mktemp -p` as an example

**printf check:**
- `printf -- '- item'` must pass (-- present = correct form)
- `printf '- item'` must fail (no --)
- `printf "-item"` where the dash is not followed by space does NOT need to be flagged
  (only the leading `-[space]` form is a known bash 3.2 problem)
- Must NOT flag non-sh files

**Worktree detection check (hard block, exit 1):**
- Flag `git worktree list --porcelain` piped directly to `grep` with a path variable
- `git worktree list --porcelain` used for enumeration (not grep-for-existence) must pass
- Comment lines that mention the pattern must not be flagged

**Branch naming:**
- `main`, `master`, `HEAD`, `""` exempt
- All-zeros SHA (deletion) already exempt via `$_ALL_DELETIONS`
- `feat/` (trailing slash, no slug) → block: "missing a slug after the slash"
- `feat/my/nested` → passes (slug may contain slashes; type is just the first component)

**Sentinel check:**
- `.gitignore` already lists these files. A `git add -f` can still stage them.
- The check fires only on ACM diff-filter (added, copied, modified) — not deletions

**72-char:**
- Auto-generated commits (`Merge ...`, `squash! ...`, `fixup! ...`, `Revert ...`) remain exempt
- The exemption is in the existing `case` statement at line 14-16 of commit-msg-lint.sh

### 3. Open questions the robot must NOT answer

See "Open Questions" section above.
