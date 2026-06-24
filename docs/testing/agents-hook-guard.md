## Pre-commit safety-file guard: `.claude/agents/**`

The pre-commit hook blocks any commit that touches files under `.claude/agents/`.
Agent definitions control what tools an agent can use and what permissions it runs with.
If an agent could modify its own definition, it could grant itself new tools or change its
permission mode — bypassing the safety floor the hook is meant to enforce.

### Confirmed behaviors

- **Commit touching `.claude/agents/` is blocked:** When a commit includes any file
  under `.claude/agents/`, the pre-commit hook exits 1 and prints a message saying
  agent definitions are protected and require a direct human commit.

- **Commit touching files outside `.claude/agents/` is not affected:** When a commit
  includes only files that are not under `.claude/agents/`, `.husky/`, or `.claude/hooks/`,
  the agent-definitions guard does not trigger.
