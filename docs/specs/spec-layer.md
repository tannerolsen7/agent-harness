---
feature: spec-layer
status: draft
human-approved: false
last-verified: 2026-07-11
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
4. Months later, a change touches the feature. The agent finds the feature's
   spec (named for the feature, not the branch), updates the Behavior list,
   and review re-runs Verification — behavior never drifts silently.

## Edge cases

- Task has no spec and is Tiny → no new spec required; but if the touched
  feature already has one, the cold-start rule still applies (read + update).
- A change alters behavior but skips the spec update → `/cr` Pass 1 flags it.
- A spec-only diff (docs-only) → `/cr` Step 0 still runs that spec's
  Verification section; the shortcut does not skip it.
- Verification section is prose, not commands → review fails the item.
- A Verification command needs a running app → written as a `manual:` line,
  routed to the manual checklist, never auto-run.
- A shipped feature's spec is left at `draft`/`building` → `/cr` Pass 7 flags it.
- Spec exists but the feature was deleted → delete the spec in the same PR.
- Two tasks touch the same feature → both update the one spec; a second spec
  file for the same feature is a bug.

## Out of scope

- Re-typing the `.cr-ok` push sentinel into a verification-based gate (VISION
  C7 clause) — designed in lockstep, shipped separately.
- Wiring the `/queue` → `@task-runner` fleet path — agent definitions are
  human-edit-only; recorded as a Known gap in `docs/specs/README.md` with the
  needed edit surfaced to the human.
- Mechanical enforcement of `human-approved` (a sentinel like
  `.design-confirmed`) — hook files are human-edit-only; today the field is
  honor-system process, stated as such in the README.
- Automatic spec ingest from Linear/Notion (Feedback layer, Phase 5).
- Cross-repo features and branch-rename tracking — one spec per feature per
  repo; a renamed feature means renaming its spec file in the same PR.
- Back-filling specs for every existing harness feature (incremental: any task
  that touches an unspecced feature writes that feature's spec as it goes).

## Behavior

1. `docs/templates/spec.md` exists with the seven core sections (Outcome, User
   journey, Edge cases, Out of scope, Behavior, Implementation pointers,
   Verification) plus an optional DMMT audit section for UI features, and
   `status` / `human-approved` / `last-verified` frontmatter keyed to a stable
   feature name — not a branch slug.
2. `docs/specs/README.md` defines the doc class: feature-named files, two
   halves, three lifecycle states (`building` set at human approval and on any
   later behavior change; `complete` set at close-out in the same PR), five
   rules, and the Known gap on the `/queue` path.
3. `/feature` distinguishes the behavioral contract (`docs/specs/`) from the
   testing shard (`docs/testing/`, handled by `spec-commit.sh`), creates or
   updates the contract at design time (Small+), and closes it out with an
   explicit `git add docs/specs/` commit before review.
4. `/feature` carries the cold-start rule at every tier including Tiny: read
   and update an existing spec before changing that feature's behavior.
5. `/cr` Pass 1 verifies the diff against the spec's Behavior list, reads each
   Verification command before running it, refuses side-effecting or networked
   commands, routes `manual:` lines to the manual checklist, and treats
   failures and prose items as Must Fix.
6. `/cr` Step 0 (docs-only path) still runs Verification for any touched spec,
   so spec-only edits cannot drift unverified.

## Implementation pointers

- `docs/templates/spec.md` — the template.
- `docs/specs/README.md` — doc-class rules, lifecycle, Known gap.
- `.claude/skills/feature/SKILL.md` — "Spec layer" section before the Tiny
  tier; Tiny step 1 cold-start check; Small steps 3/7/10; Medium steps 3/12;
  Large step 2.
- `.claude/skills/cr/SKILL.md` — Step 0 spec-verification check; Pass 1 spec
  rules; Step 5 `last-verified` update.

## Verification

```bash
# 1. Template has the seven core sections
for s in "## Outcome" "## User journey" "## Edge cases" "## Out of scope" "## Behavior" "## Implementation pointers" "## Verification"; do grep -q "^$s" docs/templates/spec.md || echo "MISSING: $s"; done   # expect: no output

# 2. Template keys identity to a feature name, not the branch slug
grep -q "NOT the branch slug" docs/templates/spec.md; echo $?   # expect: 0

# 3. All three /feature tiers point at the real template
test "$(grep -c 'docs/templates/spec.md' .claude/skills/feature/SKILL.md)" -ge 3; echo $?   # expect: 0

# 4. /feature has the spec-layer rules, Tiny cold-start, and close-out
grep -q "## Spec layer" .claude/skills/feature/SKILL.md && grep -qi "spec close-out" .claude/skills/feature/SKILL.md && grep -qi "Tiny is not exempt from the cold-start rule" .claude/skills/feature/SKILL.md; echo $?   # expect: 0

# 5. /cr Pass 1 runs Verification with the safety rules
grep -qi "refuse to run" .claude/skills/cr/SKILL.md && grep -qi "Verification section" .claude/skills/cr/SKILL.md; echo $?   # expect: 0

# 6. /cr docs-only path does not skip spec verification
grep -qi "Spec-verification check" .claude/skills/cr/SKILL.md; echo $?   # expect: 0

# 7. README states the /queue known gap and the honest human-approved limit
grep -qi "Known gap" docs/specs/README.md && grep -qi "process, not a lock" docs/specs/README.md; echo $?   # expect: 0
```
