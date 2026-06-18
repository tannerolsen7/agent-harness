## Setup checklist (remove this section when done)
- [ ] `bash scripts/install-harness-hooks.sh`  — wire git hooks and npm
- [ ] `bash scripts/install-locks.sh`          — optional OS-level locks (requires sudo)
- [ ] Open Claude Code and run `/init`         — fill in this file and create starter docs

---

# Project overview

<!-- One paragraph: what this project is and who it is for. -->
TODO: describe this project.

# Tech stack

<!-- List each major choice with a one-line "why". -->
- Language: TODO
- Framework: TODO
- Package manager: TODO (npm / pnpm / yarn / bun)
- Source control host: TODO (GitHub / GitLab)
- Deployment target: TODO

# Commands

- Dev: TODO
- Test: `npm test`
- Build: TODO
- Lint: TODO

# Before writing code

- Read `.claude/memory/` notes at session start.
- Skim `docs/solutions/` — know what patterns are already solved (create this dir when you capture your first solution).
- Read `PITFALLS.md` before writing in any affected area.
- Confirm the task fits the current scope.
- Surface open decisions rather than inventing answers.
- Ask before installing any package.
- Ask one clarifying question if anything is ambiguous.

# Communication voice

Use plain, clear language everywhere. Write at roughly a 9th-grade reading level.
One idea per sentence. Explain internal names before using them.

# Work routing

- Refactor (moving, splitting, renaming code without changing behavior) -> run `/refactor` first.
- New or changed behavior -> run `/feature` first. It runs TDD for you.

# Architecture rules

<!-- Where business logic lives, layer boundaries, what must not import what. -->
TODO

# Testing rules

<!-- How tests are organized, what must be tested, what must never be mocked. -->
TODO

# Commit format

Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.

# NEVER

<!-- Hard rules, one per line. -->
- TODO: add project-specific hard rules.
