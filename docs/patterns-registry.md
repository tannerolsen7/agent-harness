# Patterns registry

Reusable, **multi-file** recipes — the canonical way to do a recurring thing that spans
several files in this codebase (R4-D25). The companion to the **golden exemplars** in
AGENTS.md: golden exemplars name one canonical *file* per layer to imitate; this registry
captures *recipes* that touch several files at once — e.g. "add a custom field," "subscribe
to a live data source," "add a new public endpoint."

<!-- context-meta
owner: <name>
last-reviewed: YYYY-MM-DD
review-frequency: on-merge
drift-signals:
  - file references that no longer exist
  - a recipe contradicted by a newer pattern or a changed golden exemplar
  - two entries describing the same recipe (should be merged)
-->

Read the relevant entry (just the one you need — not the whole file) before writing code that
matches a recipe here. Replicating the established pattern is how the codebase stays
consistent; inventing a second way to do the same thing is a review finding.

> Project-agnostic structure; the entries themselves are this project's own patterns. Starts
> empty and grows as features establish reusable recipes.

---

## How entries get added

Entries are written and updated by `/compound` after a feature merges (R4-D25). When a feature
introduces or changes a multi-file recipe worth replicating, `/compound` adds or updates the
entry here and links it from the feature's [feature doc](./feature-doc-template.md) →
"Patterns established."

Add an entry directly (outside `/compound`) only when a known recipe is identified that isn't
yet captured — same format.

**Do not add** single-file conventions (those are golden exemplars in AGENTS.md), one-off
solutions to a non-recurring problem (those are [`docs/solutions/`](./solutions/)), or generic
engineering advice.

---

## Entries

(none yet)

---

## Entry format

Copy this skeleton for each new recipe.

```markdown
## <recipe-slug-as-heading>

**What:** the recurring multi-file task this recipe covers (e.g. "add a custom field to X").
**When to use:** the situation that calls for this recipe.
**When NOT to use:** the look-alike cases this recipe does not cover.

**The recipe:**
1. <file or layer> — <what to add or change, and why>
2. <file or layer> — <what to add or change, and why>
3. <…>

**Golden exemplar:** <the canonical file(s) to copy from — link AGENTS.md → Golden exemplars
or the specific file>.
**Established by:** <feature-doc link> (PR #N).
**Gotchas:** <the non-obvious step people get wrong; link PITFALLS.md if it has a matching trap>.
```

---

## How this differs from neighboring docs

| Doc | Holds | Granularity |
|---|---|---|
| **This registry** | reusable recipes that span **several files** | multi-file, repeatable |
| AGENTS.md → Golden exemplars | one canonical **file** per layer to imitate | single-file, per-layer |
| [`docs/solutions/`](./solutions/) | how a specific **non-obvious problem** was solved once | one problem, point-in-time |
| PITFALLS.md | traps that produce silent bugs | a rule, not a recipe |

The line vs. `docs/solutions/`: a solution doc is a **point-in-time narrative** of how one
hard problem was solved (with root cause, what didn't work, why this approach fit). A registry
entry is a **forward-looking, replicable recipe** — the steps to follow next time you do this
multi-file task. A solution may *graduate* into a registry entry once the same shape recurs;
until then it stays a solution. The two never hold the same content: solutions explain a past
fix, the registry prescribes a repeatable procedure.
