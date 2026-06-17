# Feature doc template

*Fill-in skeleton — copy per feature; placeholders marked with `<…>`. Do not edit this template in place.*

The feature doc is the **single source of truth for one feature** (R4-D9). It is the hub
that links the feature's spec, the decisions behind it, the tests that prove it still works,
and the reusable patterns it established. Tests and test reports derive from it, agents read
it for context before touching the feature, and downstream consumers (e.g. marketing) pull
from it. One feature = one feature doc.

This is a hub, not a copy. Each section **links to** the canonical artifact (the ADR, the
TESTING.md entries, the patterns-registry entry) rather than restating it — the feature doc
points at the source of truth, it does not duplicate it. If a section would copy more than a
sentence or two from another doc, link instead.

**Where it lives:** `docs/features/<feature-slug>.md` (one file per feature, kebab-case slug).

**How it's created:** grown out of the before-coding gate — the spec exists before the code
(see [04 · Context Docs](./engineering-system/04-context-docs.md) and CLAUDE.md → Before
writing code). The doc starts at design time and is kept current through implementation and
review; it is not written after the fact.

**Related canon:**
- Patterns established here are captured into the [patterns registry](./patterns-registry.md)
  by `/compound` after the feature merges (R4-D25).
- Non-obvious *solutions* go to [`docs/solutions/`](./solutions/) — see "Feature doc vs.
  solution doc" at the bottom for the boundary.

---

Copy everything below this line into `docs/features/<feature-slug>.md` and fill it in.

---

# Feature: <feature name>

<!-- feature-meta
slug: <feature-slug>
status: design | in-progress | shipped
owner: <name>
merged-pr: <#N or "—">
last-reviewed: YYYY-MM-DD
-->

## What this feature is

<One paragraph in plain language: what it does, who uses it, what it enables or replaces.
A new agent should be able to read this and know what the feature is for without reading code.>

## Why it exists

<The problem this solves and why now. The motivating need, not the implementation.>

---

## Spec

What "done" looks like, stated as observable behavior — not implementation.

- **Inputs:** <what goes in>
- **Outputs:** <what comes out>
- **Must NOT do:** <explicit non-goals and out-of-scope boundaries>
- **Done looks like:** <the acceptance condition, observable from outside the system>

> If this feature has a richer spec elsewhere (a PRD, a `/design` contract), link it here and
> keep only the summary above. The feature doc is the hub — it points at the fuller spec, it
> does not replace it.

---

## Key decisions

The decisions that shaped this feature, and why. Link the canonical record; do not restate it.

| Decision | Resolution | Where recorded |
|---|---|---|
| <the question that had to be answered> | <what was chosen> | <ADR link, AGENTS.md → Resolved decisions, or this doc if minor> |

> Hard-to-reverse, surprising, real-tradeoff decisions get an ADR in
> [`docs/adr/`](./adr/) — link it above rather than re-explaining it here.

---

## How it works

<A short tour of the moving parts — the entry points, the layers it touches, the key files.
Enough that an agent can orient before reading code. Link the golden-exemplar file for any
layer this feature follows (AGENTS.md → Golden exemplars). Keep this current as the feature
evolves — a stale "how it works" is worse than none.>

| Part | File(s) | Role |
|---|---|---|
| <entry point> | `<path>` | <what it does> |
| <core logic> | `<path>` | <what it does> |
| <data access> | `<path>` | <what it does> |

---

## Tests — how we know it still works

The confirmed behaviors that prove this feature works, and where their tests live. This
section is the source the test layer derives from (R4-D9): behaviors are confirmed here and
in `docs/TESTING.md` before any code is written.

| Behavior | Test file | TESTING.md entry |
|---|---|---|
| <observable behavior> | `<test path>` | <link or anchor> |

**How to verify manually:** <the steps a human runs to confirm the feature works end-to-end,
if automated tests don't fully cover the user-facing flow.>

---

## Patterns established

Reusable, multi-file patterns this feature introduced that future work should replicate
(R4-D25). Each one links to its entry in the [patterns registry](./patterns-registry.md) —
the registry holds the canonical recipe; this section is just the index for this feature.

| Pattern | Registry entry |
|---|---|
| <short name of the recipe — e.g. "add a custom field"> | [patterns-registry.md#<slug>](./patterns-registry.md#<slug>) |

> If the feature established no new cross-file pattern, write "None — followed existing
> patterns." Do not invent one to fill the table.

---

## Pitfalls and gotchas

<Traps specific to this feature that aren't obvious from the code. If a trap is general enough
to bite any feature in this area, promote it to PITFALLS.md and link it here instead of
restating it.>

- <trap — what goes wrong and how to avoid it, or a link to the PITFALLS.md entry>

---

## Status and follow-ups

- **Current state:** <design | in progress | shipped — and where it stands if mid-flight>
- **Known limitations:** <what it does not yet handle, and the upgrade path>
- **Follow-up work:** <backlog items or next steps, with links if tracked>
