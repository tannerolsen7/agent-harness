## Safety-file guard in `.husky/pre-commit`

A new block runs at the top of `.husky/pre-commit`, before all existing
checks. It inspects the staged file list and exits 1 if any of the staged
files belong to a safety-critical category. The guard uses two staged-file
variables:

- `STAGED` — files from `git diff --cached --name-only --diff-filter=ACMRDT`
  (includes additions, copies, modifications, renames, deletions, and type
  changes).
- `STAGED_ENV` — files from `git diff --cached --name-only --diff-filter=ACMR`
  (same minus deletions, used only for the `.env` check so that deleting a
  `.env` file is allowed).

### Confirmed behaviors — `.husky/*` files

- **Staging a modification to a husky hook is blocked:** Given `.husky/pre-commit`
  is staged as a modification, the guard exits 1 and writes a message to stderr
  before any other check runs.

- **Staging a new file under `.husky/` is blocked:** Given a new file
  `.husky/my-new-hook` is staged, the guard exits 1 and writes a message to
  stderr.

- **Staging a deletion of a `.husky/*` file is blocked:** Given `.husky/pre-push`
  is staged as a deletion, the guard exits 1. Deletions are included because
  `STAGED` uses `--diff-filter=ACMRDT` which covers `D`.

### Confirmed behaviors — `.claude/hooks/*` files

- **Staging a change to a file under `.claude/hooks/` is blocked:** Given
  `.claude/hooks/block-dangerous-bash.sh` is staged (as any change type
  covered by `ACMRDT`), the guard exits 1 and writes a message to stderr.

### Confirmed behaviors — `.claude/settings.json` and `.claude/settings.local.json`

- **Staging `.claude/settings.json` is blocked:** Given `.claude/settings.json`
  is staged, the guard matches the regex `^\.claude/settings(\.local)?\.json$`
  and exits 1.

- **Staging `.claude/settings.local.json` is blocked:** Given
  `.claude/settings.local.json` is staged, the guard matches the same regex
  and exits 1.

- **Staging a new `.claude/agents/my-agent.md` is NOT blocked:** Given a new
  agent definition file `.claude/agents/my-agent.md` is staged, the settings
  regex does not match it and the guard does not exit 1 for this reason.

### Confirmed behaviors — gate scripts under `scripts/`

- **Staging `scripts/lint.sh` is blocked:** Given `scripts/lint.sh` is staged,
  the guard matches it against the list of protected gate scripts and exits 1.

- **Staging `scripts/cr-ok.sh` is blocked:** Given `scripts/cr-ok.sh` is staged,
  the guard exits 1. The full protected list is: `cr-ok.sh`,
  `design-confirm.sh`, `commit-msg-lint.sh`, `shell-portability-lint.sh`,
  `lint.sh`, `token-lint.sh`, `comment-lint.sh`, `data-state-lint.sh` —
  matched via a `scripts/<name>` prefix check.

### Confirmed behaviors — `package.json` and `package-lock.json`

- **Staging `package.json` is blocked:** Given `package.json` is staged, the
  guard matches the regex `^package(-lock)?\.json$` and exits 1.

- **Staging `package-lock.json` is also blocked:** Given `package-lock.json`
  is staged, the same regex matches and the guard exits 1.

### Confirmed behaviors — `.env` files

- **Staging a new `.env` file is blocked:** Given `.env` is staged as an
  addition, the guard matches it against the regex `(^|/)\.env($|\.)` using
  `STAGED_ENV` and exits 1.

- **Staging a modification to `.env` is blocked:** Given `.env` is staged as a
  modification, the guard matches it against the same regex and exits 1.

- **Deleting a `.env` file is NOT blocked:** Given `.env` is staged only as a
  deletion, it does not appear in `STAGED_ENV` (which uses `--diff-filter=ACMR`,
  excluding `D`). The guard does not exit 1 for a deletion.

- **Staging `.envrc` is NOT blocked:** Given `.envrc` is staged, the regex
  `(^|/)\.env($|\.)` does not match because `.envrc` has characters after
  `.env` that are not a dot or end-of-string. The guard passes through.

### Confirmed behaviors — normal source files

- **Staging a normal source file is allowed:** Given only `src/foo.ts` is
  staged, none of the guard patterns match it. The guard does not exit 1 and
  execution continues to the existing checks in the hook.
