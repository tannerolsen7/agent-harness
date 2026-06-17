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

At design time, `@designer` fills the **Design** section below in one pass — the data shape,
the API contract, and the front-end shape — grounded in the project's locked patterns. Then
`@design-griller` attacks that design with a clean context to find the expensive-to-undo
decision and the missed case before the human signs off. Only after sign-off does
`scripts/design-confirm.sh` write the sentinel that lets coding start (R4-D14, R4-D4).

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

## Design

`@designer` fills this in one pass, before any code. `@design-griller` then attacks it.
Three areas, each a separate decision the human signs off on. Skip an area only when it
genuinely does not apply — and say so ("no schema change", "no screen"), do not delete the
heading.

### Data shape

The least-reversible decision — get it right first.

- **Tables / columns / types / relations:** <existing and new; name existing ones so nothing
  gets recreated. Or "no schema change.">
- **Migration:** <the real `CREATE TABLE` / `ALTER` for anything new — not a sketch.>
- **Zod boundary schema:** <the schema for each input/output that crosses a trust boundary;
  at least as strict as the column it guards.>
- **Tenant / owner scoping:** <the column and the rule that stops this returning another
  tenant's or owner's data.>

### API contract

The shape of what crosses each boundary.

- **Inputs:** <name · type · source · what happens when missing/malformed/unexpected.>
- **Outputs:** <name · type · consumer · sync or async · loading and error states.>
- **Entry point:** <the server action / route / data function this lives behind, per the
  project's architecture; link the golden exemplar for that layer.>
- **Access policy:** <the auth/access boundary this respects, as a rule.>

### Front-end shape

<Only if the feature has a screen — otherwise "no screen." Same rigor as the backend
(R4-D14a). Cover: the layered one-way imports; pure logic split from framework glue; the
component triad (humble I/O components + orchestration + state source); the framework fill-in
the project's stack uses (reactive unit, slots, shared state, DI); and the full data-state
matrix — no data, some, lots/overflow, bad data, loading — with no layout shift (R4-D18). The
look reuses `docs/design/` tokens and components, never a new style.>

### Open questions the robot must NOT answer

<Every product, business, or UX call left for the human. If this list is empty, look harder —
a design with zero open questions usually means the designer quietly answered some.>

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
