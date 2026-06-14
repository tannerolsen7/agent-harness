# ADR 0001 — Backlog mechanism (anti-"build-forever")

**Status:** Proposed (awaiting acceptance)
**Date:** 2026-06-13
**Deciders:** Tanner (human merges); drafted by the harness build agent
**Supersedes:** the interim `BACKLOG.md` anti-build-forever rule

---

## Context

The harness lets an **agent** (not only a human) file backlog items — `/cr`'s triage classifies each
non-MUST-FIX finding as fix-now / **backlog** / drop, and other reviews do the same. An agent-fed
backlog has a specific failure mode: filing is nearly free, so the list grows faster than it drains
and rots into a dumping ground. The interim `BACKLOG.md` guards this with a hand-written rule (every
item carries a severity + status; HIGH/MEDIUM must be *promoted to the active plan, not parked*; the
list is reviewed whenever `/cr` backlogs something; unjustifiable items are dropped).

We need a durable mechanism that (a) **bounds the list** so it can't build forever, (b) works for an
**agent reader/writer**, and (c) works **across ~5 repos** that each adopt the harness (project-agnostic).

### What the research says (see "Evidence" below for citations)

1. **Decay must key on *relevance + priority*, not raw inactivity.** Inactivity-based auto-close
   (`actions/stale`) is the standard tool, but it kills a real-but-unworked item as readily as a dead
   one. It is only safe paired with an **exempt label** (deliberately-parked work survives) and a
   **severity tier that forces high-priority items *out* of the backlog** into active work.
2. **One-shot purges ("backlog bankruptcy") don't bound a backlog — continuous drain + an inflow gate do.**
   The cheapest durable control for an *agent* backlog is the **gate at creation** (the `/cr` **drop**
   disposition), because AI makes filing trivially cheap (cf. the open-source "AI slop" wave).
3. **Storage is a real trade, not a wash.** Markdown-in-git (the emerging agent-native default —
   Backlog.md, todo-md) wins on no-auth, offline, review-as-diff, but has **weak query and no
   cross-repo aggregation**. GitHub Issues + a cross-repo Project + `actions/stale` is the only
   *native* path giving both self-aging and a 5-repo roll-up — at the cost of per-repo auth.

---

## Decision

Adopt a **two-tier mechanism: the project's issue tracker is the backlog of record; a repo-local
`BACKLOG.md` is the project-agnostic fallback.** The anti-build-forever guarantee comes from three
parts that hold in *both* tiers: an **inflow gate**, **severity→placement**, and **priority-keyed decay**.

### 1. Backlog of record = the project's issue tracker (GitHub Issues by default)

- The harness is on GitHub, so the default target is **GitHub Issues**. `/cr`'s "backlogged"
  disposition files `gh issue create` with a `sev:*` label (GitLab `glab issue create` / Linear are
  per-project adapters). This gives query, labels, and native cross-repo roll-up via a **Project**.
- **Fallback:** a repo with no issue tracker (or where the agent has no token) uses `BACKLOG.md` with
  the same severity + status discipline. `BACKLOG.md` is the *floor*, never silently skipped.
- **5-repo aggregation:** a single cross-repo GitHub **Project** with an auto-add filter rolls every
  repo's `sev:high`/`sev:medium` issues into one board — the native answer to fleet visibility.

### 2. Inflow gate (the most important control)

- Before filing, the agent **searches existing items** (`gh issue list --search "<signature>"` or grep
  of `BACKLOG.md`) and **updates** a match instead of creating a duplicate. Dedup is the agent-specific
  hazard — agents re-discover the same finding every run.
- Every item MUST carry **severity** (`high`/`medium`/`low`) + a one-line **why-it-matters**. An item
  that can't justify itself is **dropped at creation**, not filed. This is `/cr` Step 5's existing
  drop disposition — the gate already exists; this ADR makes it the backlog's front door.

### 3. Severity → placement (high/medium can't just sit)

- **HIGH / MEDIUM → promoted to the active plan**, not parked (the existing `BACKLOG.md` rule, kept).
  In Issues this is a saved query (`is:open label:sev:high`) reviewed every time `/cr` backlogs
  something; these are expected to leave the backlog by being *done*, not by aging out.
- **LOW → may sit, but ages out.** Low-severity items are the only ones eligible for inactivity decay.

### 4. Priority-keyed decay (`actions/stale`, tuned)

A scheduled `actions/stale` workflow (free; no paid plan needed), configured so decay can't eat real work:

- `days-before-stale: 60`, `days-before-close: 14`, `remove-stale-when-updated: true`.
- **`exempt-issue-labels: "keep,sev:high,sev:medium"`** — only LOW, un-pinned items can auto-close.
  A `keep` label is the explicit "deliberately parked, don't reap" escape hatch.
- `operations-per-run: 30` to stay under API rate limits.
- A closed-as-stale item is recoverable (it's an issue, not a delete) and its signature stays
  searchable, so the agent won't silently re-file it without seeing the prior closure.

The ready-to-adopt workflow YAML is in the appendix. It is **proposed**, not installed — `.github/`
changes are placed by the human.

---

## Consequences

**Positive**
- The backlog is bounded by construction: inflow gate (drop), forced promotion (high/medium), and
  decay (low) — three independent pressures, not one fragile rule.
- Native query + cross-repo roll-up for the GitHub tier; zero custom tooling beyond one stale workflow.
- The fallback keeps the harness project-agnostic (no GitHub → `BACKLOG.md` with identical discipline).

**Negative / costs**
- GitHub Issues needs a token/`gh` auth per repo for the agent; the fallback exists precisely for when
  that's absent.
- `actions/stale` is inactivity-based; the exempt-label tuning is what makes it safe — if a future
  edit drops the exempt labels, real items could be reaped. (Encode the exempt list as load-bearing.)
- Two tiers means the `/cr` "backlogged" step needs an adapter (`gh` / `glab` / file) — small, but real.

**Migration path (post-acceptance, separate PRs)**
1. Add the `sev:high|medium|low` + `keep` labels to the repo (or document them for adopters).
2. Land the `actions/stale` workflow (human-placed under `.github/workflows/`).
3. **Already live:** `/cr` Step 5's "Backlogged" disposition routes to `gh issue create` /
   `glab issue create` when the repo has a remote, else `BACKLOG.md`. Remaining refinement: have it
   apply the `sev:*` label on creation and search existing items for a duplicate before filing (the
   dedup gate). No new routing needed — only the label + dedup-search additions.
4. Migrate the current `BACKLOG.md` items to issues with `sev:*` labels; keep `BACKLOG.md` as the fallback doc.

---

## Alternatives considered

- **Markdown-in-git only (Backlog.md / todo-md style).** Best for no-auth + review-as-diff, but no
  cross-repo aggregation and weak query — fails the 5-repo visibility requirement. Kept as the *fallback*,
  not the primary.
- **Linear.** Best dedicated UI + cross-repo workspace, but most external, an extra API key/integration,
  and lock-in. Available as a per-project adapter, not the default.
- **Backlog bankruptcy (periodic full purge).** One-time relief that regrows; loses quiet-but-real items.
  Rejected as the *mechanism* (it doesn't fix inflow), though `keep`-less LOW decay is a gentler form of it.
- **Pure `actions/stale` with default settings.** Rejected — un-exempted inactivity decay reaps real items.

---

## Evidence (researched 2026-06-13)

- `actions/stale` knobs, defaults, exemptions, throttling — https://github.com/actions/stale ;
  GitHub's documented example (stale 30d, close 14d, 30/run) —
  https://docs.github.com/actions/managing-issues-and-pull-requests/closing-inactive-issues
- Cross-repo Projects auto-add + auto-archive —
  https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project
- Backlog bankruptcy is one-shot relief — https://www.mountaingoatsoftware.com/blog/product-backlog-bankruptcy
- Appetite / fixed-time-variable-scope / circuit-breaker — https://basecamp.com/shapeup/1.2-chapter-03
- Agent-native markdown backlog tools — https://github.com/MrLesk/Backlog.md , https://github.com/todo-md/todo-md
- Severity→SLA / priority placement — https://rootly.com/incident-response/support-levels ,
  https://ardura.consulting/blog/bug-triage-process-priority-matrix/
- "Filing is cheap, review is costly" (AI-slop inflow asymmetry) — https://daniel.haxx.se/blog/2025/07/14/death-by-a-thousand-slops/ ,
  https://leaddev.com/software-quality/open-source-has-a-big-ai-slop-problem

*Caveats:* the "10–20% capacity for debt" band is a commonly-cited range, not a single authoritative
figure (Atlassian source didn't render). Agent-dedup mechanics are inferred from the slop literature —
no single prescriptive source found.

---

## Appendix — proposed `actions/stale` workflow (not installed; human-placed)

```yaml
# .github/workflows/stale-backlog.yml — priority-keyed backlog decay.
# Only LOW, un-pinned items can auto-close; high/medium and `keep` are exempt.
name: stale-backlog
on:
  schedule: [{ cron: "30 1 * * 1" }]   # weekly, Monday 01:30 UTC
  workflow_dispatch: {}
permissions:
  issues: write
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          days-before-stale: 60
          days-before-close: 14
          remove-stale-when-updated: true
          stale-issue-label: "stale"
          exempt-issue-labels: "keep,sev:high,sev:medium"
          stale-issue-message: >
            This low-severity backlog item has been inactive for 60 days. It will close in 14 days
            unless updated. Add the `keep` label to park it deliberately, or raise its severity to
            promote it to the active plan.
          operations-per-run: 30
          only-issue-labels: "sev:low"   # decay is scoped to LOW; high/medium leave by being done
```
