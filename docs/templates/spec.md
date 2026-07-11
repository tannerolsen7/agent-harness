---
feature: <slug>            # matches the branch slug (bash scripts/derive-slug.sh)
status: draft              # draft → building → complete (see docs/specs/README.md)
human-approved: false      # a human flips this to true after reading Outcome + Journey
last-verified: —           # date the Verification section last passed, set by /cr
---

# <Feature name>

<!-- TOP HALF — requirements. Written in business terms, before any design or code.
     A non-engineer should be able to write and verify everything above the line. -->

## Outcome

One short paragraph: who this is for, and what they can do after this ships that
they could not do before. No implementation words (no table names, no file paths).

## User journey

The steps as the user experiences them, numbered. Each step is something a person
does or sees — not something the system does internally.

1. …

## Edge cases

What happens at the boundaries the user can hit: empty states, bad input, no
permission, the thing already exists, the network fails. One line each.

- …

## Out of scope

What this feature deliberately does not do. Prevents scope creep during build and
false bug reports later.

- …

## DMMT audit (UI features only — delete this section otherwise)

Walk the journey as a first-time user. For each step: is it obvious what to do
next without thinking? Note every point of hesitation.

<!-- BOTTOM HALF — the behavioral contract. Filled in during the build, kept
     current forever. This is what a future cold-start agent reads before
     touching this feature, and updates before changing its behavior. -->

## Behavior

Numbered, testable statements of what the system does. Each one is a promise —
if a later change breaks one, that change must update this list first.

1. …

## Implementation pointers

Where this feature lives: entry points, key files, data shapes. Just pointers —
one line each — so a cold-start agent knows where to look. Update on every move.

- …

## Verification

Executable steps that prove the Behavior list still holds. Every item is a
command plus its expected result — prose like "check it works" is not allowed
and fails review. `/cr` runs these; `last-verified` records the last pass.

```bash
# 1. <what this proves>
<command>   # expect: <observable result>
```
