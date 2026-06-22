# queue-execute: Design gate enforcement

## What & Why

When someone queues a MEDIUM, LARGE, or FEATURE task without a design doc,
the spec-writer agent makes wrong assumptions and blocks overnight in the
questions.md protocol. Rejecting the task immediately — before any worktree
is created — stops the wasted run and tells the user exactly what to fix.

## Done Looks Like

- A LARGE task with no `design` field throws before any worktree agent runs;
  the error names the slug and tells the user to add a `design:` line
- A MEDIUM task without a `design` field is rejected the same way
- A LARGE or MEDIUM task with a `design` field pointing to a file that doesn't
  exist is rejected; the error names the slug and the bad path
- A SMALL task with no `design` field proceeds normally
- Multiple failing tasks produce a single error listing all of them
- Tests cover all five cases above

## Interface Contract

**Inputs:**
- `size?: string` — from the task object; trimmed + uppercased before comparing;
  unknown values treat as SMALL (pass-through)
- `design?: string` — file path from the TASKS.md `design:` line;
  must be non-empty for gated sizes; trimmed before use

**Outputs:**
- Throws before the stacking step if validation fails.
- If the file-existence `agent()` returns null, throws (fail-closed).
- File-existence check uses structured bash output: each line is
  `"OK: <slug>"` or `"MISSING: <slug>: <path>"` — no freeform text.

**Constraints:**
- Must run before `computeStacks()` — no worktrees created if gate fires.
- Must list all failing tasks at once, not just the first.
- SKILL.md Step 2 and the workflow's `GATED_SIZES` set must stay in sync
  (both must name MEDIUM, LARGE, FEATURE).

**State:** None.

## Out of Scope

- Empty design files (0 bytes on disk) — presence check only for now
- Enum validation on `size` — unknown values pass through as SMALL

## Relevant Files

- `.claude/workflows/queue-execute.js` — where the gate code lands
- `.claude/skills/queue/SKILL.md` — Step 2 and Step 3 need updating
- `docs/testing/queue-design-gate.md` — confirmed behaviors
