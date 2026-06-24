<!-- context-meta
owner: tanner
last-reviewed: 2026-06-17
review-frequency: weekly
drift-signals:
  - a rule here contradicts how the project actually works now
  - references a file, skill, or path that no longer exists
-->

# Communication voice

Use plain, clear language everywhere — inline docs, output explanations, comments, skill descriptions. The goal is not to impress. It is to help engineers make sound decisions without having to stop and look something up.

**The test:** Could someone read a sentence once and understand it well enough to explain it to a colleague? If not, rewrite it.

**Rules:**

- Write at roughly a 9th-grade reading level. Use technical terms only when they are the clearest option. Otherwise use the simpler word: "list" not "enumerate", "makes the result unpredictable" not "introduces non-determinism", "adds a security risk" not "expands the security surface".
- Do not drop internal codes or names without explaining them first. "F9", "Layer 2b", "ADR-0002" mean nothing cold. Explain what the thing is in plain words before (or instead of) using the label.
- One idea per sentence. If a sentence needs a second read, break it up.
- When explaining a design decision, state the plain reason before citing the spec, contract, or gate that enforces it.
- Skill and agent descriptions are written for agents first, humans second — but the same clarity standard applies.

# Work routing

These rules are mandatory — follow them before writing or moving any code.

**Refactor** (moving, splitting, extracting, or renaming code without changing behavior) → invoke `/refactor` first. Don't hand-edit a structural move.

**New or changed behavior** (a new feature, an update to how something works, a new function, or any step that changes what the system does) → invoke `/feature` first. `/feature` runs TDD for you — don't skip it and write the code directly.

# Mechanical enforcement

These rules are enforced by hooks or scripts — violations stop the action automatically.

| Rule | Where enforced |
|------|----------------|
| Commit messages must follow conventional commit format (`type(scope)?: description`) | `.husky/commit-msg` → `scripts/commit-msg-lint.sh` |
| Commit subject must be 72 characters or fewer | `scripts/commit-msg-lint.sh` via `.husky/commit-msg` |
| Branch names must follow `type/slug` format | `.husky/pre-push` naming gate |
| Feature branches must not be behind the default branch at push time | `.husky/pre-push` sync gate |
| Agent pushes must come from a dedicated worktree (`.git` file, not directory) | `.husky/pre-push` non-interactive path |
| Design must be confirmed before coding | `.claude/.design-confirmed` sentinel, checked by `/feature` |
| Sentinel files (`.cr-ok`, `.design-confirmed`) cannot be staged directly | `.husky/pre-commit` sentinel guard |
| Code review must pass before pushing | `.claude/.cr-ok` sentinel, checked by `.husky/pre-push` on agent pushes |
| Staged code must pass lint, comment-lint, and token-lint | `.husky/pre-commit` |
| Staged `.sh` files must not use `mktemp -p`, leading-dash `printf`, or `worktree list \| grep` | `scripts/shell-portability-lint.sh` via `.husky/pre-commit` |
| Staged `*.test.sh` files must include the git env unset line | `.husky/pre-commit` GIT_DIR guard |
| Agent definitions under `.claude/agents/` must have both `Task` and `permissionMode` or neither | `.husky/pre-commit` agent spawn lint |
| Agents cannot commit changes to `.husky/*` or `.claude/hooks/*` hook files | `.husky/pre-commit` safety-file guard |
| Agents cannot commit changes to `.claude/agents/*` agent definitions | `.husky/pre-commit` safety-file guard |
| Agents cannot commit changes to `.claude/settings.json` or `.claude/settings.local.json` | `.husky/pre-commit` safety-file guard |
| Agents cannot commit changes to gate scripts (`cr-ok.sh`, `design-confirm.sh`, `lint.sh`, and five others) | `.husky/pre-commit` safety-file guard |
| Agents cannot commit changes to `package.json` or `package-lock.json` | `.husky/pre-commit` safety-file guard |
| Agents cannot add or modify `.env*` files (deletions are allowed) | `.husky/pre-commit` safety-file guard |

These rules are guidance only — no hook can enforce them automatically:

- **Communication voice** (9th-grade reading level, plain language) — judgment call; no linter catches bad prose.
- **`/refactor` before structural moves** — no reliable way to detect a structural move from a diff alone. The branch `type/` prefix partially enforces the routing rule (the type must match the work), but detecting structural moves inside a diff is still a human judgment.

# Asking the user to act

Any time you cannot do something yourself and need the user to run a command, make a file edit, or take any other manual action, give three things in order:

1. **What** — one sentence describing what the action does.
2. **Why** — one sentence explaining why you cannot do it yourself (hook blocks it, deny rule, requires human auth, etc.).
3. **The action** — for a command: the full copy-pasteable `cd <absolute-path> && ...` command; for a file edit: the exact before/after text in a code block, or a self-contained command (e.g. `sed` with a heredoc) that makes the change without requiring the user to open an editor.

Never just describe the change and ask the user to "handle it." Give them everything they need to act in one place.
