# Problem: skill frontmatter descriptions don't enforce routing

**Problem class:** Advisory vs. enforced agent behavior — a rule that looks authoritative
but is only a suggestion.

## When this bites you

You have skills with well-written frontmatter descriptions. For example:

```
/refactor → description: "Use when splitting a large file, extracting a function,
             renaming a symbol, or when user says 'refactor', 'extract this',
             'move this to its own module'..."
```

The model reads these and is supposed to invoke the skill. But it doesn't —
especially mid-session when a handoff or plan frames the next step as concrete
edit instructions. The model follows the frame ("remove the write at ~325, repoint
reads to groupDisplayFor") rather than recognizing the work-state ("this is a refactor
→ route through /refactor").

## Root cause

Skill frontmatter descriptions are a signal to the model — a "consider this skill
when the task matches" prompt. There is no mechanism that intercepts "you're about
to move code across files" and blocks until /refactor is active. Compare the
destructive-git hook, which hard-blocks on dangerous git commands: that's enforcement.
Skill routing is not.

The failure class is: model recognizes the task type, description matches, but
execution context (a detailed plan, a mid-session handoff, an instruction framed
as "continue") suppresses the recognition check.

## The fix

Put routing rules in CLAUDE.md as explicit instructions, not as skill descriptions:

```markdown
# Work routing

These rules are mandatory — follow them before writing or moving any code.

**Refactor** (moving, splitting, extracting, or renaming code without changing
behavior) → invoke `/refactor` first. Don't hand-edit a structural move.

**New or changed behavior** (a new feature, an update to how something works,
a new function, or any step that changes what the system does) → invoke `/feature`
first. `/feature` runs TDD for you — don't skip it and write the code directly.
```

The word "mandatory" and the explicit "before writing or moving any code" mirrors
how the project's destructive-git rules are written. It converts the advisory
signal into the same instruction-enforced routing that already works for bug
investigation flows.

## Why it works

CLAUDE.md is loaded as system context on every turn. An instruction written there
is active before the model reads any task framing, plan, or handoff message. The
skill description is evaluated after context — so a plan that says "do X" competes
with the description. An instruction in CLAUDE.md that says "before doing X, do Y"
is part of the same context as the plan.

## When to reuse this

Any time you find a model repeatedly skipping a skill it should be using:

1. Check whether the skill is being skipped mid-session (execution context suppresses)
   or never (description mismatched).
2. If mid-session: add a routing rule to CLAUDE.md.
3. If never: fix the frontmatter description — the model never recognized the task type.

Routing rules in CLAUDE.md are the floor, not the ceiling. The description still
matters for cold-start recognition and for other projects that read the skill list
without the CLAUDE.md context.

## What doesn't work

**Improving the frontmatter description.** If the description already matches the
task type and the model is skipping it mid-session, rewriting the description won't
help. The execution context (a plan, a handoff) outweighs a sharper signal from
the same source that wasn't enough to begin with.

**Putting the rule only in memory.** Memory is loaded as context, similar to
CLAUDE.md, but a routing rule in memory may not survive a fresh conversation on a
different branch or worktree. CLAUDE.md is the durable location.

## Where this applies in the codebase

- `CLAUDE.md` — `# Work routing` section (added 2026-06-17)
- `~/.claude/CLAUDE.md` — does NOT have this section; routing rules are project-specific
  because the skills they reference may not exist in other projects.

## Tags

skill routing, CLAUDE.md, advisory vs enforced, mandatory behavior, /refactor,
/feature, execution context suppression, model behavior, harness discipline
