# Problem: Adding a Machine-Measured Pass to a Judgment-Based Review Pipeline

**Problem class:** A review agent that uses human judgment (confusion scores, persona walkthroughs) gains a machine-measured pass (axe, Lighthouse, ESLint). The two kinds of data have different properties — one is a count from a tool, the other is an opinion — and mixing them naively produces two bugs: faked scores and no distinction between regressions and pre-existing issues.

## When this bites you

You add axe-core output to a UX review agent. The report now includes a line like "92% accessible" or "accessibility score: 8.3/10." These numbers look authoritative but are made up — axe does not produce them. Or: the agent flags 14 violations without saying which ones this PR introduced, so the author does not know which are theirs to fix and which were already there.

## Root cause

Two structural problems:

**Problem 1 — Faked aggregation.** Machine tools return raw counts and rule IDs. Agents trained to be helpful tend to convert those into scores, grades, or percentages to make the output feel complete. A number like "92% accessible" sounds precise but is fabricated. It has no meaning and trains readers to ignore it.

**Problem 2 — No diff boundary on violations.** A reviewer that reports all violations equally treats a violation introduced by this PR the same as one that's been there for two years. That conflation puts the PR author on the hook for fixing things they didn't break, so they learn to ignore violation lists.

## Solution

Three rules, applied in `ux-reviewer.md` Pass 3:

**Rule 1 — Run the machine pass last.** Judgment passes (DMMT audit, persona walkthroughs) catch things axe cannot: a focus trap, a confusing tab order, mislabeled but technically present aria-labels. axe catches things judgment misses: color contrast ratios, role mismatches, missing landmarks. Run judgment first, machine last. Keep them separate.

**Rule 2 — Classify every violation as regression or net-new.** A violation is a regression if it is on an element or state the diff touched and would not have appeared before the diff. Everything else is net-new (pre-existing). Regressions are MUST FIX — they are the author's responsibility. Net-new violations are flagged but not blocking.

For a brand-new surface with no prior version, treat `critical` and `serious` as MUST FIX, `moderate` and `minor` as flagged only.

**Rule 3 — Report only what the tool returned.** The only acceptable metric is the raw axe output: rule ID, impact level, node count. A summary line like `axe: 3 violations (1 critical, 2 serious)` is a real count. A line like `accessibility score: 92%` is a faked metric and is banned. If the tool could not run, mark the pass `NOT RUN — <plain reason>` and move on. Never guess a result.

## The correct output shape

```
### Pass 3 — axe accessibility scan
axe: 3 violations (1 critical, 2 serious)

**Regressions (MUST FIX)**
- color-contrast (serious) — 2 nodes — button.primary-cta in new checkout flow
**Flagged (not blocking)**
- label (critical) — 1 node — legacy input#email (pre-existing, outside this diff)
```

## When to reuse this pattern

Any time you add a machine-measured pass to an agent that already has judgment-based passes. The same three rules apply regardless of what the tool measures: Lighthouse scores, ESLint counts, mutation survivors, bundle size deltas. All are raw counts, not scores. All need a regression/net-new split to be actionable.

## When NOT to reuse

If the machine pass is the only review mechanism (no judgment passes), the regression/net-new split still applies, but the "run last" rule is irrelevant. Apply Rules 2 and 3; skip Rule 1.

## Files changed

- `.claude/agents/ux-reviewer.md` — Pass 3 section, FRICTION REPORT format, agent description

**Tags:** agent-design, review-pipeline, axe, machine-measured, regression-classification, no-faked-metrics
