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
| Feature branches must not be ahead of `origin/main` at push time | `.husky/pre-push` sync gate |
| Design must be confirmed before coding | `.claude/.design-confirmed` sentinel, checked by `/feature` |
| Code review must pass before pushing | `.claude/.cr-ok` sentinel, checked by `.husky/pre-push` |
| Staged code must pass lint, comment-lint, and token-lint | `.husky/pre-commit` |

These rules are guidance only — no hook can enforce them automatically:

- **Communication voice** (9th-grade reading level, plain language) — judgment call; no linter catches bad prose.
- **`/refactor` before structural moves** — no reliable way to detect a structural move from a diff alone.
