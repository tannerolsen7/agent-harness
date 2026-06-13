---
name: cr
description: Runs a structured multi-agent code review across 9 analytical passes
  plus an adversarial review against the full branch diff. Use before merging any
  branch to main, when the user says "/cr", "run a code review", "review this
  branch", "pre-merge review", or "is this ready to merge". Catches correctness
  bugs, layer violations, doc drift, architectural inconsistency, and footprint
  issues across the entire branch. Fixes must-fix items automatically and surfaces
  the rest.
---

# /cr — Full pre-merge review
**cr = code review.** Full branch diff review across all commits on the branch, run once before merging to main.

## Anti-rationalization (read before proceeding)

| Rationalization | Rebuttal |
|---|---|
| "This is a small branch, /cr isn't needed" | Branch size doesn't determine what /cr catches. Architectural drift and doc contradictions don't scale with PR size. |
| "The deadline is today, I'll run /cr after" | There is no after merge. Run /cr before. If it finds something, you want to know now. |
| "The change is trivial / already reviewed — I'll write `.cr-ok` directly" | `.cr-ok` certifies that /cr ran at this exact HEAD. Writing it directly means no certificate, regardless of how small the change is. A commit not reviewed by /cr is unreviewed. Run /cr. |

---

## Step 0 — Docs-only check

If every changed file in `git diff main..HEAD` is `.md`, under `.claude/`, or non-code config:

Run a single Haiku doc-review pass instead of the full review:
- Check every doc change is accurate relative to the code it describes
- Check for broken references, outdated paths, contradictions with other docs
- Return findings in MUST FIX / Nice to Have format
- Write the sentinel if no MUST FIX items remain
- Evaluate `/compound` (same criteria as Step 8) — invoke if any condition is met; state "No compound-worthy findings" if none apply

**Skill-structure meta-check** — when the diff includes `.claude/skills/**/*.md`, additionally scan for user-input-wait instructions (`"Wait for user response"`, `"ask the user"`, `"(y/n)"`, `"confirm before proceeding"`, or equivalents). For each match, check position: is the wait at a natural checkpoint (end of a tier, before a destructive/irreversible action, before a sentinel write)? Or does it appear mid-pipeline, blocking later critical-path steps on a non-critical question? A user-input wait that blocks critical-path steps on a non-critical question is a MUST FIX structural bug. Example: `/cr` Step 3b promotion-candidates prompt appears before Step 4 (MUST FIX fixes) — a docs-curation question gates a correctness enforcement step.

If the diff is not docs-only: proceed to Step 1.

---

## Step 1 — Gather context

- Run `git log --oneline main..HEAD`
- Run `git diff main..HEAD` — capture the full output
- Check `.claude/plans/` for any plan file — read it if found
- Note the working directory / worktree path

---

## Step 2 — Spawn 9 review agents IN PARALLEL

Pass the full diff and plan content directly in each prompt.

Each agent returns findings sorted into three tiers:
- **Must Fix** — bugs, spec drift, broken backwards compat, unsafe failure modes
- **Nice to Have** — improvements that would meaningfully improve the code
- **Something to Think About** — architectural observations, future considerations

### Pass 1 — Correctness & Spec (Sonnet)
Does the code do what the plan says and handle domain constraints?

Review focus:
- Does the implementation match the plan/spec exactly?
- Logic bugs, off-by-one errors, incorrect conditions
- Codebase-specific footguns — read PITFALLS.md before reviewing
- Backwards compat: optional fields guarded with optional chaining?

### Pass 2 — Domain Safety (Sonnet)
Critical failure modes for this codebase. Read PITFALLS.md and AGENTS.md → domain rules first. If the diff
touches the database, auth, or payments, apply this project's database-safety rules (its backend-adapter
safety skill) — do not assume a specific backend.
- Every external/backend/data-store call: what happens on error? Error surfaced or swallowed?
- Mutations: is the ownership/authorization guard present (tenant/user/owner scoping)?
- State transitions: do the correct side effects fire (timestamps, audit events, triggers, notifications)?
- Numeric/money calculations: null/NaN/overflow handled? Integer-exact where money requires it?
- Public/unauthenticated entry points: within the documented security allowlist? No sensitive fields exposed?

### Pass 3 — TypeScript Discipline (Sonnet)
- No implicit `any`
- No non-null assertions without type narrowing
- No `as` casts without narrowing
- Types derived from Zod schemas via z.infer<> — no duplicate hand-written interfaces
- Props as named interfaces, not inline object types
- Discriminated union `switch` statements: `never` type guard on default?
- No loose comparisons where strict equality is required

### Pass 4 — Layer Boundaries (Sonnet)
Read AGENTS.md → Architecture before reviewing. The project's own architecture doc defines the layer names
and the one-way import rule — review against those, not a hardcoded stack.
- No backend / data-store calls outside the project's data-access layer
- No business logic in components, pages, layouts
- UI / server entry points call the data-access layer directly (no bypass)
- Shared data fetched once / cached per the project's data-fetching convention
- Store/state exports are readonly where applicable

### Pass 5 — Readability & Naming (Sonnet)
Write for a tired engineer five years from now.

- Would every changed file be understood without reading the PR description?
- Naming consistency across layers
- Magic numbers or strings should be named constants
- Comments explain WHY — never WHAT
- Is any function doing more than one thing?

### Pass 6 — Test Quality (Sonnet)
- New behavior → test exists
- Transcription test check: if you deleted the implementation and left only the types, would any new test fail? If not, it's a transcription.
- Tests assert behavior, not implementation
- Edge cases covered
- No database mocks
- New behaviors in docs/TESTING.md?

### Pass 7 — Doc Drift & Footprint (Haiku)
**Part A — Mechanical (MUST FIX):** console.log outside tests, TODO/FIXME/HACK, commented-out code, unused imports, @ts-ignore, any type, as without narrowing, it.only.

**Part B — Doc drift (MUST FIX if contradiction):**
- Does the diff change a module's responsibility? Does AGENTS.md reflect it?
- Does the diff add/remove a data path? Does AGENTS.md reflect it?
- Does the diff add/change domain vocabulary? Does CONTEXT.md reflect it?
- New confirmed behaviors in docs/TESTING.md?
- Does any sentence in CLAUDE.md, AGENTS.md, or CONTEXT.md now contradict the code?

### Pass 8 — Architectural Drift (Sonnet)
Before reviewing the diff, search the codebase for existing patterns relevant to what changed. Then evaluate:
- Does this introduce a second way to do something the codebase already does one way?
- Different approach to state, data fetching, or error handling than what exists?
- Naming inconsistent with existing conventions?
- Dependency that duplicates something already in the codebase?
- Five years from now: will a new engineer find two ways and not know which to follow?

Flag silent new standards as MUST FIX. Inconsistencies as SUGGESTION.

### Pass 9 — Devil's Advocate (Sonnet)
Stress-test the reasoning. For each meaningful choice:
- Why this approach and not the simpler/more obvious one?
- What does this decision make harder in the future?
- Is this abstraction earning its complexity?
- If you had to revert this in six months, how painful?
- Is the scope right, or doing more/less than it should?

Mark unjustified decisions as MUST FIX. Over-engineering as SUGGESTION.

---

### Pass 10 — Adversarial Review (@reviewer, four parallel lens agents)

Spawn `@reviewer` in implementation mode with the full diff. @reviewer spawns four specialist lens agents in parallel — assumption violation, composition failures, cascade construction, and abuse cases — and consolidates their findings.

This pass runs after all analytical passes but before synthesis. Its findings fold into the Must Fix / Nice to Have / Something to Think About tiers alongside the other passes. High findings from any lens are Must Fix.

Full agent: **Templates → agents/reviewer.md**

Tag findings with [P10-assumption], [P10-composition], [P10-cascade], or [P10-abuse].

---

## Step 3 — Synthesize + update RECURRING-FINDINGS.md

Collect all findings from all passes. Deduplicate overlapping findings.

Produce tiered report:

```
## Must Fix
- [P#] [label] Description
## Nice to Have
- [P#] [label] Description
## Something to Think About
- [P#] [label] Description
```

Tag each item: [P1] correctness · [P2] domain safety · [P3] TS discipline ·
[P4] layers · [P5] readability · [P6] test quality · [P7] doc drift/footprint ·
[P8] architectural drift · [P9] devil's advocate · [P10] adversarial review

### Step 3b — Recurring findings update

After producing the tiered report, read `docs/RECURRING-FINDINGS.md`.

For each finding in the report:
- Generate a normalized signature: short, stable, lowercased, hyphen-separated
- Match against Active findings or append new entry with Occurrences: 1
- Update Last seen, increment Occurrences, append file:line (cap at 5)

Identify promotion candidates:
- Auto-flag: any active finding with Occurrences ≥3
- Judgment-flag: any finding assessed as high-impact at lower count

Collect promotion candidates but do NOT surface them here. Proceed to Step 4.
Present candidates at Step 5 alongside Nice-to-Have and Something to Think About items.

---

## Step 4 — Fix Must Fix items (Opus)

If there are Must Fix items, spawn one Opus agent:

> You are a staff engineer. Fix only what's listed. Do not refactor beyond
> the finding. For each fix, note what changed and which finding it resolves.
> Flag as NEEDS HUMAN if the fix requires >~15 lines of new code, an
> architectural decision, or the intended behavior is ambiguous.

**Hook-file escape hatch:** if a Must Fix lives in a `.claude/hooks/*.sh` file, do
NOT route it to the Opus fix agent — the `settings.json` deny on `Edit/Write(/.claude/hooks/**)`
blocks that agent too. Route it to NEEDS HUMAN and surface a paste-ready command; the
human is the only one allowed to change a hook. Do not write the sentinel (Step 7) until
the human confirms the hook fix is applied.

After fixes: run the test suite. One retry on failure. Surface failures after that.

If no Must Fix items, skip and say so.

---

## Step 5 — Surface the rest

List Nice to Have and Something to Think About. If promotion candidates were
identified in Step 3b, surface them here:

```
## Promotion candidates
1. [signature] — Occurrences: N. Reason: [threshold | judgment: <reason>].
   Suggested target: PITFALLS.md | /cr pass P# prompt
   Confirm? (y/n)
```

On confirmation: write PITFALLS.md entry, move to Promoted/retired in RECURRING-FINDINGS.md.
On skip: leave in Active. Will re-flag after one more occurrence.

Do not implement Nice-to-Haves without explicit confirmation.

---

## Step 6 — Manual test checklist

Specific checklist from the actual diff. Sections: backwards compat, the affected user/feature flows, failure modes, regression risks.

Conclude: "Run through this checklist before opening a PR. Anything that fails is a regression."

---

## Step 7 — Write push sentinel

After the final report is presented and there are no unresolved Must Fix items, write the sentinel. Resolve `branch:sha` first, then write to the absolute sentinel path (the relative form `.claude/.cr-ok` does not match the harness's path-based allowlist for sub-agents):

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
SHA=$(git rev-parse HEAD)
REPO_ROOT=$(git rev-parse --show-toplevel) || { echo "error: not in a git repo — sentinel not written" >&2; exit 1; }
SENTINEL="${REPO_ROOT}/.claude/.cr-ok"
printf "%s:%s" "$BRANCH" "$SHA" > "$SENTINEL"
```

If the printf-redirect form is denied (some sub-agent contexts reject shell redirects to nested paths even with the absolute form), fall back to the Write tool with the resolved absolute `$SENTINEL` path — the content is exactly `branch:sha` (no trailing newline).

**The sentinel encodes `branch:sha`. Any commit after this point invalidates it — re-run `/cr` before opening a PR.**

After pushing and opening the PR via `scripts/pr.sh`, surface the URL to the user: `gh pr view --json url -q .url`

---

## Step 8 — Evaluate /compound (required)

After the sentinel is written, evaluate these conditions:

- A non-obvious architectural or process decision was made
- A recurring problem class was solved (future problems of this type should reference this solution)
- A new pattern was established that agents should replicate
- The compound questions surfaced something surprising that got resolved

If **any** condition is true: invoke `/compound` before declaring done. Do not wait to be asked.

If none apply: state explicitly "No compound-worthy findings — no new pattern, no recurring problem solved, no non-obvious decision."

**This evaluation is not optional.** The step always runs; only the outcome varies.
