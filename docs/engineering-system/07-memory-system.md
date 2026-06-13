# Memory System

*Universal patterns — adapt to your project.*

Three documents with three distinct jobs. Easy to conflate — the distinction matters.

---

## The three documents

### memory.md — What went wrong in sessions

**Source:** You corrected an agent during a session.
**Content:** "We tried X, it broke, never do X" — as a direct constraint.
**Granularity:** Session-level. One rule per corrected mistake.
**Read by:** Every agent at session start, before any work begins.
**Grows:** When you correct an agent and add the rule before the session ends.

> The discipline: if you don't add the rule before the session ends, the mistake recurs.

---

### RECURRING-FINDINGS.md — What the pipeline keeps catching

**Source:** The pipeline flagged the same class of finding across multiple PRs.
**Content:** A log of findings with occurrence counts, file locations, and promotion status.
**Granularity:** PR-level. Tracks frequency across the codebase over time.
**Read by:** The pipeline synthesis step only — not implementing agents.
**Grows:** Automatically on every `/cr` run (Step 3b).

> The discipline: don't edit this file manually. Let the pipeline maintain it. Your job is to confirm or skip promotion candidates.

---

### PITFALLS.md — What implementing agents must know

**Source:** Promoted from RECURRING-FINDINGS.md (threshold or judgment) or added directly for known traps.
**Content:** Canonical statement of each trap — Area, Rule, Why, Symptoms, Source.
**Granularity:** Pattern-level. One entry per class of error, permanent until retired.
**Read by:** Implementing agents before writing code. Referenced by pipeline pass prompts.
**Grows:** Via human-confirmed promotion, or direct addition for known traps.

> The discipline: pipeline pass prompts reference PITFALLS.md by heading rather than restating inline. This prevents drift between the review system and the authoritative doc.

---

## How they relate

```
Session mistake (you correct the agent)
        ↓
  memory.md
  (read at session start — prevents repeat)

Pipeline catches a finding in a PR
        ↓
  RECURRING-FINDINGS.md
  (accumulates, counts occurrences)
        ↓ (threshold ≥3 or judgment — you confirm)
  PITFALLS.md
  (canonical, read by implementing agents)
        ↓
  Pipeline pass prompts reference PITFALLS.md
  (enforced at review — not just at write time)
```

A pattern can appear in all three:

- Starts as a session correction (memory.md)
- Keeps getting caught in review (RECURRING-FINDINGS.md)
- Gets codified so agents avoid it at write time (PITFALLS.md)

---

## RECURRING-FINDINGS.md format

```
## Entry schema

### [normalized-signature]
- First seen: YYYY-MM-DD (commit SHA short)
- Occurrences: N
- Last seen: YYYY-MM-DD (commit SHA short)
- Pass(es): P1, P3, etc.
- Description: one paragraph
- Example locations: file:line (cap at 5, drop oldest when full)
- Status: active | promoted-to-pitfalls | promoted-to-pass | retired
```

**Signature rules:** short, stable, lowercased, hyphen-separated. Examples: `unchecked-null-access`, `debug-log-in-non-test-file`. Same class of error → same signature.

---

## Promotion flow

**Auto-flag (threshold):** any active finding with Occurrences ≥3 not previously flagged.

**Judgment-flag:** any finding assessed as high-impact at lower count — security gap, systemic pattern, something pipeline passes don't yet cover. Agent must provide one-sentence reasoning.

**Promotion candidate format:**

```
1. [signature] — Occurrences: N.
   Reason: [threshold | judgment: <one sentence>].
   Suggested target: PITFALLS.md | /cr pass P# | docs/[other]
   Confirm? (y/n)
```

**On confirmation (y):** write new PITFALLS.md entry, move RECURRING-FINDINGS.md entry to Promoted/retired.

**On skip (n):** leave in Active findings. Will re-flag after one more occurrence past threshold.

**Changelog-to-PITFALLS review:** After applying any changelog entry — especially one that fixes a previous workaround or retires a previous approach — check PITFALLS.md for entries whose workarounds have been superseded. Stale entries should be either (a) removed if the workaround no longer applies, or (b) updated to reference the correct fix. This prevents context rot where agents apply retired workarounds because PITFALLS.md still recommends them.

---

## docs/solutions/ format

```
---
date: YYYY-MM-DD
tags: [tag1, tag2, tag3]
area: the layer or module this applies to
problem: one sentence
---

# [Short title]

## Problem
What was the actual problem? Not the feature — the underlying challenge.

## What we tried first (if relevant)
What didn't work and why.

## Solution
What worked. Specific — file paths, function names, patterns used.

## Why it works
The reasoning. What property of the codebase makes this right.

## When to reuse this
Concrete trigger: "Use this pattern when X."

## When NOT to reuse this
Edge cases where this approach breaks down.

## Related
- PITFALLS.md § (if applicable)
- docs/adr/ (if applicable)
- Source files: (key files)
```

**File naming:** `YYYY-MM-DD-short-description.md`

**Add YAML frontmatter tags** when directory grows past ~10 entries.

### Pre-seeded entries

Seed docs/solutions/ with entries covering the patterns agents most commonly need to get right in your codebase. Good candidates:

- How to add a new entity or data type end-to-end (from schema through the data layer to the UI)
- How to pick the right layer for a subscription or side effect
- How to branch on entity-type variants (e.g. one kind of account vs. another)
- How to set up a service or module test without triggering real infrastructure side effects
- How shared state handles multiple entity types
- How a frozen or computed value propagates through the system

Each entry should include: what the problem was, the correct solution with specific file paths and code, why it works, and when not to use it.

6 entries is a good starting point. Run `/compound` after the first few features to grow it organically from there.

### Active maintenance

docs/solutions/ is not a static reference. Two `/feature` done-criteria gates keep it current:

1. If a feature changed a documented pattern → update the affected solution doc in place
2. If a feature revealed a new footgun → check PITFALLS.md and propose an entry if missing

For the stale review process and the session-end hook that proposes new entries automatically, see the Memory evolution section below.

---

## Memory evolution

Two upgrade paths beyond the baseline. Neither requires external dependencies.

**Automatic candidate surfacing:** A Stop hook proposes memory.md candidates at session end so you don't depend on remembering. Script and settings wiring are in 08 · Settings & Permissions.

Note: Anthropic's **Dreaming** feature (announced Code with Claude 2026, currently in research preview) is the official version of this pattern — it runs overnight, reviews prior sessions automatically, and creates persistent memory files without a hook. When Dreaming becomes generally available, evaluate replacing the session-end hook with it.

**Stale entry review:** The `last_seen` field on each entry makes staleness visible. Every ~90 days, run Step 7 of `/compound` to flag entries not seen in 90+ days, entries that contradict current patterns, and entries redundant with PITFALLS.md. The review surfaces candidates; nothing is modified automatically.

**The lifecycle:**

```
Session mistake (agent corrected)
        ↓
  Stop hook proposes candidate
        ↓
  You review — add to memory.md with last_seen date
        ↓
  Agent reads at session start — update last_seen when it fires
        ↓
  Quarterly /compound review
        ↓
  Stale → remove or promote to PITFALLS.md
  Healthy → keep, reset last_seen
  Redundant → remove (PITFALLS.md already covers it)
```

---

## docs/adr/ format

Write an ADR when all three conditions are met:

1. Hard to reverse
2. Surprising without context
3. Result of a real tradeoff

If any of the three is missing, skip the ADR.

```
# NNNN — [Short title]

Date: YYYY-MM-DD
Status: Accepted | Superseded by NNNN | Deprecated

## Context
What situation prompted this decision?

## Decision
What was decided?

## Alternatives considered
What else was on the table, and why was it rejected?

## Consequences
What does this make easier? What does it make harder?
```

**File naming:** `NNNN-short-title.md` (e.g. `0001-use-single-write-path-for-state.md`)
