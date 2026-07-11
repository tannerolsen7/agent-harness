---
feature: spec-layer
status: draft
human-approved: false
last-verified: —
---

# Spec layer — per-feature behavioral contracts

## Outcome

For the harness owner (and eventually any non-engineer directing agent work):
you can state what a feature must do in plain terms, approve it once, and every
future agent — including one with no memory of the original build — can find
that contract, build against it, and prove the feature still honors it. Today
that knowledge lives only in developer-level task files and the heads of past
sessions.

## User journey

1. You (or `/feature`) start a Small-or-larger task; a spec file appears in
   `docs/specs/` with the Outcome and User journey written in plain terms.
2. You read the top half and set `human-approved: true` — that is your whole
   requirements gate. You never write a task contract yourself.
3. The build runs. When the PR is ready, the spec's bottom half describes what
   was actually built, and review has run the spec's Verification commands.
4. Months later, a change touches the feature. The agent reads the spec first,
   updates the Behavior list, and review re-runs Verification — behavior never
   drifts silently.

## Edge cases

- Task has no spec yet and is Tiny → no spec required; TESTING.md shard only.
- A change alters behavior but skips the spec update → `/cr` Pass 1 flags it.
- Verification section is prose, not commands → review fails the item.
- A shipped feature's spec is left at `draft`/`building` → `/cr` Pass 7 flags it.
- Spec exists but the feature was deleted → delete the spec in the same PR.

## Out of scope

- Re-typing the `.cr-ok` push sentinel into a verification-based gate (VISION
  C7 clause) — designed in lockstep, shipped separately.
- Automatic spec ingest from Linear/Notion (Feedback layer, Phase 5).
- Back-filling specs for every existing harness feature (incremental: any task
  that touches an unspecced feature writes that feature's spec as it goes).

## Behavior

1. `docs/templates/spec.md` exists and contains the seven required sections
   (Outcome, User journey, Edge cases, Out of scope, Behavior, Implementation
   pointers, Verification) plus `status` / `human-approved` frontmatter.
2. `docs/specs/README.md` defines the doc class: two halves, three lifecycle
   states, and the five rules (spec-first, cold-start, executable verification,
   no self-certification, human approves the top half).
3. `/feature` Small tier creates or updates `docs/specs/<slug>.md` from the
   template during the design step, and closes it out (bottom half + status)
   before review.
4. `/feature` Medium/Large tiers reference the real template path
   (`docs/templates/spec.md`) instead of a template that does not exist.
5. `/feature` carries the cold-start rule: read and update an existing spec
   before changing that feature's behavior.
6. `/cr` Pass 1 verifies the diff against the spec's Behavior list and runs the
   spec's Verification commands; failures are Must Fix.

## Implementation pointers

- `docs/templates/spec.md` — the template.
- `docs/specs/README.md` — doc-class rules and lifecycle.
- `.claude/skills/feature/SKILL.md` — Small step 3 (create), new close-out step
  before Review; Medium step 3 and Large step 2 (template path); cold-start
  rule in the shared rules near the top.
- `.claude/skills/cr/SKILL.md` — Pass 1 (verify against spec + run
  Verification), Pass 7 already checks spec `status`.

## Verification

```bash
# 1. Template exists with all seven sections
for s in "## Outcome" "## User journey" "## Edge cases" "## Out of scope" "## Behavior" "## Implementation pointers" "## Verification"; do grep -q "^$s" docs/templates/spec.md || echo "MISSING: $s"; done   # expect: no output

# 2. README defines the lifecycle states
grep -c "draft\|building\|complete" docs/specs/README.md   # expect: >= 3

# 3. /feature no longer references a phantom template
grep -q "docs/templates/spec.md" .claude/skills/feature/SKILL.md && ! grep -q "Medium+ spec template" .claude/skills/feature/SKILL.md; echo $?   # expect: 0

# 4. /feature Small tier has a spec step and a close-out step
grep -q "docs/specs/" .claude/skills/feature/SKILL.md && grep -qi "spec close-out" .claude/skills/feature/SKILL.md; echo $?   # expect: 0

# 5. /cr Pass 1 runs the spec's Verification section
grep -qi "Verification section" .claude/skills/cr/SKILL.md; echo $?   # expect: 0
```
