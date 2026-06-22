# Spec: Safety-file guard — block agent commits of protected files

<!-- spec-meta
slug: safety-file-guard
human-approved: true
status: implemented
-->

## User goal

An agent must not be able to commit changes to files that control how agents behave —
hooks, permission settings, gate scripts, and credential files. If an agent edits one
of these files and tries to commit it, the pre-commit hook blocks the commit with a
clear message telling the human what to do instead.

## User journey

1. Agent edits `.husky/pre-commit` and tries to commit → hook blocks immediately with
   a message explaining that hook files enforce the safety floor and require a direct
   human commit.
2. Agent edits `.claude/settings.json` (e.g., to add a permission) and tries to commit
   → hook blocks with a message explaining that this file controls agent permissions and
   must be committed by the human directly.
3. Agent edits `scripts/cr-ok.sh` (a script called from the CR gate) and tries to commit
   → hook blocks, explaining that gate scripts can only be modified by the operator.
4. Agent edits `package.json` and tries to commit → hook blocks, explaining that
   `package.json` wires the husky hooks and only the operator can modify it.
5. Agent creates a new `.env.local` file and tries to commit → hook blocks, explaining
   that `.env` files contain secrets and must not be committed.
6. Agent deletes `.env.local` → hook **allows** the commit (removing a secret is safe).
7. Agent creates a new `.claude/agents/my-agent.md` → hook **allows** it (agents are
   created during feature work; the existing frontmatter check handles them separately).
8. Agent commits a normal source file → hook allows it, no false positive.

## Behaviors

BLOCKED:
1. Staging a `.husky/*` file (new, modified, deleted, renamed, or type-changed) is blocked.
2. Staging a `.claude/hooks/*` file (new, modified, or deleted) is blocked.
3. Staging `.claude/settings.json` (any change) is blocked.
4. Staging `.claude/settings.local.json` (any change) is blocked.
5. Staging a safety script (`cr-ok.sh`, `design-confirm.sh`, `commit-msg-lint.sh`,
   `shell-portability-lint.sh`, `lint.sh`, `token-lint.sh`, `comment-lint.sh`,
   `data-state-lint.sh`) is blocked.
6. Staging `package.json` or `package-lock.json` is blocked.
7. Staging a `.env` file addition or modification is blocked (`.env`, `.env.local`,
   `.env.production`, etc. — but NOT `.envrc`).

PASS-THROUGH (must not false-positive):
8.  A normal source file commits without triggering the guard.
9.  Deleting a `.env` file does NOT trigger the guard.
10. Staging a new `.claude/agents/*.md` file does NOT trigger the guard.

## Edge cases

- Deletion of hook files is also blocked (ACMRDT filter). An agent removing a hook is
  the same violation as adding one — the safety floor must stay intact.
- `.envrc` (a direnv config file) must NOT be caught by the `.env` regex. The regex
  must be `(^|/)\.env($|\.)` — requiring the name to end after `.env` or continue with a dot.
- The guard runs before all other pre-commit checks so that blocked commits fail for the
  right reason (not a lint mismatch or missing script).

## DMMT audit (does this make me think?)

- Error messages must name the file and give the exact manual command to use instead.
  An agent or human should not have to figure out "what do I do now?" — the message tells them.
- The `.env` pass-through for deletions is a subtle distinction. The messages for blocked
  `.env` additions must not say "never touch .env files" — they should say "additions and
  modifications are blocked" so a human knows a deletion is safe.
