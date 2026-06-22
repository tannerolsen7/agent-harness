## Design gate in `queue-execute.js`

A validation block runs at the top of the queue workflow script, before any
worktree is created. It checks every task in the batch and rejects MEDIUM,
LARGE, and FEATURE tasks that are missing a `design` field or have one that
points to a file that does not exist on disk. SMALL, BUG, CHORE, and tasks
with an unrecognized or absent size field pass through without a check.

### Confirmed behaviors

- **LARGE task missing design field is rejected before any worktree agent
  runs:** Given a task with `size: "LARGE"` and no `design` field, when
  queue-execute.js runs, it throws an error naming the task's slug before any
  `agent()` call for worktree creation or task execution. The error message
  tells the user to add a `design:` line to TASKS.md.

- **MEDIUM task missing design field is rejected the same way:** Given a task
  with `size: "MEDIUM"` and no `design` field, when queue-execute.js runs, it
  throws an error naming the task's slug before any `agent()` call for worktree
  creation or task execution. The error message tells the user to add a
  `design:` line to TASKS.md.

- **LARGE or MEDIUM task with a design field pointing to a non-existent file is
  rejected:** Given a task with `size: "LARGE"` and `design:
  "docs/features/missing.md"` where that file does not exist on disk, the
  workflow throws before any worktree is created. The error names the task's
  slug and the bad path.

- **SMALL task with no design field passes through:** Given a task with `size:
  "SMALL"` and no `design` field, the workflow proceeds normally to stacking and
  execution. No error is thrown.

- **Multiple failing tasks produce a single error listing all slugs:** Given two
  LARGE tasks that both have no `design` field, the workflow throws exactly once
  with a message that names both slugs. It does not stop at the first failure and
  throw separately for each task.

- **Null return from the file-existence agent call causes a fail-closed throw:**
  Given the `agent()` call that checks whether design files exist returns null
  (for example, due to a crash or timeout), the workflow throws an error rather
  than treating the result as a pass.

- **`size` value is trimmed and uppercased before comparison:** Given a task
  whose `size` field has leading or trailing whitespace (e.g. `" large "`), the
  workflow trims and uppercases the value before deciding whether to apply the
  gate. A whitespace-only `size` value does not silently pass as SMALL — it
  becomes an empty string after trimming, which is treated as an unrecognized
  size and passes through.

- **`design` value is trimmed before use:** Given a task whose `design` field
  has a trailing newline or surrounding whitespace (as can happen in TASKS.md),
  the workflow trims the value before checking file existence. This prevents a
  false "file not found" error caused by whitespace in the path.

- **File-existence check uses structured bash output lines:** The bash command
  run by the file-existence `agent()` call produces one line per checked task.
  Each line is either `OK: <slug>` when the file exists or `MISSING: <slug>:
  <path>` when it does not. The workflow parses these lines to build the list of
  failing tasks.

- **Throws before `computeStacks()` — no worktrees are created if the gate
  fires:** Given at least one task fails the design gate, the workflow throws
  before calling `computeStacks()`. No worktree directory is created for any
  task in the batch.

## SKILL.md documentation — design gate scope

Step 2 of SKILL.md describes when a design doc is required.

### Confirmed behaviors

- **Step 2 names MEDIUM as a gated size alongside LARGE and FEATURE:** The prose
  in Step 2's design gate section lists MEDIUM, LARGE, and FEATURE as the sizes
  that require a `design:` field. It does not omit MEDIUM, so users reading the
  skill understand which task sizes need a design doc before the queue will run.
