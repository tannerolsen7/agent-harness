# The Dual Learning Loop — how one repo gets smarter, and how the whole fleet does

> **What this is.** A teachable, draw-it-on-a-napkin walk-through of the TWO loops that make the harness
> compound, and how they feed each other:
> - **Loop A — the per-repo loop:** how *one* project's agents stop repeating a mistake. A mistake is caught →
>   proposed as a lesson (a human says yes) → sits in an inbox → recurs three times → promotes to a rule that
>   loads on the next run → if it can be a hard check, a "ratchet" turns it into a deterministic block → you
>   measure that first-pass-approval rose.
> - **Loop B — the global loop:** how a lesson learned in *one* repo improves the *shared* harness so *every*
>   repo gets it. A lesson tagged "universal" → opens a human-reviewed pull/merge request against the shared
>   plugin → review → merge → `/plugin update` pulls it down to every repo on the fleet.
>
> Then: how the two loops feed each other, what is built now vs gated, and a plain "it gets smarter while you
> sleep" narrative.
>
> **Plain-language word list (used below, defined once):**
> - **harness** — the bundle of helpers an AI coding agent uses: its rules, its review step, its checklists.
> - **agent** — the AI doing the coding work in one repo.
> - **repo** — one project's codebase (event-vendor, a logistics service, etc.).
> - **fleet** — all the repos that run the harness.
> - **rule** — a short "never do X here" the agent reads before it writes code.
> - **deterministic block** — a dumb, non-AI check (a script, a lint rule, a CI step) that *refuses* the bad
>   thing. It does not have an opinion; it just says no. "Deterministic" = same input → same answer, every time.
> - **CI pipeline** — the automated checks your git host runs on every change (tests, type-check, lint). Works
>   the same on GitHub, GitLab, or any host.
> - **pull/merge request (PR/MR)** — the proposed-change-for-review unit. GitHub calls it a PR; GitLab calls it
>   an MR. Same thing. We write **PR/MR**.
> - **plugin** — the installable, version-pinned package that carries the shared harness (rules, skills, review
>   step) to every repo. Update it with `/plugin update`.
> - **first-pass-approval** — did the work pass review on the *first* try, with no rework? The headline "are we
>   getting better?" number.
>
> **Grounding.** Every claim cites a VISION.md move (CMP1–6 in Pillar 4; P8/P9 in Pillar 5) or a design artifact
> (`design/v2/github-usage.md`, `design/v2/memory-model.md`, `design/phase45/compounding-loop.md`,
> `design/v2/CORRECTIONS-LEDGER.md`, `design/v2/ROUND-2-FEEDBACK-AND-CORRECTIONS.md`). New gaps are flagged
> **GAP**.
>
> **Three corrections folded in (per Tanner, 2026-06-11 — `ROUND-2-FEEDBACK §Tanner's 9 notes`):**
> 1. **Slack and Linear are first-class kickoff doors**, equal to a repo label — a person can start a feature or
>    report a bug from chat or a ticket and have it routed and run.
> 2. **Git-host-agnostic.** GitHub OR GitLab (or others). Neutral words throughout: "your git host", "PR/MR",
>    "CI pipeline", "protected branch", "issue/ticket".
> 3. **No new `/goal` skill.** Claude Code already ships a continuation loop (`/goal <condition>`, native since
>    v2.1.139). Where this doc references run-until-done, it means **the built-in continuation loop** — not a new
>    skill to build.

---

## 0. The one-paragraph thesis (teach-test)

The harness today only writes lessons down; it never reads them back. `/cr` (the review step) already *counts*
how often the same problem recurs and appends it to a findings file — but that file is **"never read by
implementers"** (VISION CMP1; `memory-model.md §0`). So the agent makes the same class of mistake every single
run, because nothing it was corrected on last time is in front of it this time. A learning loop has two ends —
**write the lesson** and **read it back** — and the harness only built the write end. **Loop A** closes that
circle inside one repo: catch → propose → inbox → promote → read-back → (if possible) turn into a dumb block
that makes the mistake *impossible* → measure that it worked. **Loop B** does the same thing one level up: a
lesson that is true for *every* repo gets pushed up into the shared plugin, a human reviews and merges it, and
`/plugin update` pulls it down to the whole fleet. The two loops are the same shape at two scales, and they feed
each other: a block that proves itself useful in one repo becomes a candidate to ship to all of them; a rule
that arrives from the shared plugin starts its own "did this actually help here?" clock in each repo that
receives it. **The teach-test version:** *one repo learns by catch → inbox → promote → block → measure; the
fleet learns by tagging a lesson "universal" → human-reviewed PR/MR → merge → pull; and each loop is the other
loop's input.*

---

## Loop A — the PER-REPO loop (how one project's agents get better)

### A.0 The loop in one picture (draw this)

```
        ┌──────────────────────── THE PER-REPO LEARNING LOOP ────────────────────────┐
        │                                                                             │
        │   1. CATCH          2. PROPOSE        3. INBOX         4. PROMOTE            │
        │   a mistake    ──►  a lesson      ──► it sits and  ──► after 3 hits +        │
        │   is found          (human says yes) counts up         a human "yes"        │
        │      ▲                                                      │                │
        │      │                                                      ▼                │
        │   7. MEASURE  ◄──  6. RATCHET   ◄──────────────────  5. READ-BACK            │
        │   first-pass-      (if it can be a    the rule now loads    on the           │
        │   approval rose    dumb block, make    on the NEXT run      next run         │
        │                    it impossible)                                           │
        │                                                                             │
        └─────────────────────────────────────────────────────────────────────────────┘
```

Seven steps. Steps 1–5 take a mistake from "the agent just did it" to "the agent reads the lesson before it can
do it again." Step 6 is the upgrade: when the lesson can be enforced by a dumb check, you stop *reminding* the
agent and start *refusing* the mistake. Step 7 is the proof it worked.

The design names each edge (`memory-model.md §0`: "run → write-back → airlock → promote → read-path → ratchet →
measure → drift"). Below, each step in plain language, with the concrete example carried all the way through.

### A.1 The running example (we will carry it to "impossible")

**The mistake:** the agent keeps writing a database query that forgets to scope by tenant. In this app every
table is shared across many vendors, and a query *must* filter to the current vendor's `team_id`. If it doesn't,
Vendor A could see Vendor B's data — a real security hole. The agent, run after run, writes
`select * from proposals` instead of `select * from proposals where team_id = $current`. (This is exactly the
kind of cross-tenant defect the design treats as a worked case — `compound/golden-set` source list,
`compound-loop.md §3.2`: "a cross-tenant RLS hole".)

We will take this one mistake from its first appearance all the way to "it is now impossible for the agent to
ship it."

### A.2 Step 1 — CATCH (a mistake is found)

Two things can catch it, and both already exist in the harness:

- **The review step (`/cr`)** reads the diff and flags it: "this query is not tenant-scoped — MUST-FIX." `/cr`
  is the one component on disk that already *counts* recurring problems (VISION CMP1; `cr/SKILL.md:174`, the
  Step 3b auto-writer).
- **The end-of-session capture** notices the human corrected the agent mid-session ("you forgot the tenant
  filter again"). That's the CMP5 session-end payload — a hook that watches for a correction and proposes a
  lesson from it (VISION CMP5; `memory-model.md §S3 writers`).

Either way, the raw signal is: *"tenant-scope was missed here, again."*

> **Honest note (built vs not):** the *review-time* catch is built (`/cr` Step 3b). The *session-end* catch
> (CMP5) is **designed, not built** — and it rides on an unverified capability: can a Stop hook even *see* that a
> mistake was corrected this turn? (`compound-loop.md §1`, the load-bearing risk; `VISION.md` Phase-0 probe:
> "force-continue semantics"). The fallback if it can't: the review-time catch alone still feeds the loop. So the
> loop works today even with only one of the two catch points.

### A.3 Step 2 — PROPOSE (turn the catch into a candidate lesson — human-confirmed)

The catch becomes a *proposed lesson*, not yet a rule. Phrased like a rule: *"In `src/data/`, every query MUST
filter by `team_id`."* A **human confirms** it is real before it counts (VISION CMP5: "human confirms —
deliberately NOT a deterministic mistake-detector"; `memory-model.md §S3`: "no `/note` skill"). This human gate
is on purpose: an AI guessing "this is a lesson" with no confirmation would fill the rulebook with noise, and a
noisy rulebook trains everyone to ignore it.

This is the cheapest, most important gate in the whole loop: **one human "yes."**

### A.4 Step 3 — INBOX (it sits in the airlock and counts up)

The proposed lesson lands in an **inbox** — the design calls it the **airlock** (`memory-model.md §The three
load-bearing ideas #2`). Concretely it's the findings ledger (`docs/RECURRING-FINDINGS.md`), where each finding
carries a **signature** (a normalized fingerprint of the problem) and an **occurrence count**.

Why an inbox and not a rule right away? Because **one observation is not yet a pattern.** The airlock is "the one
place a finding sits at occurrences=1 without polluting the always-loaded rule set" (`memory-model.md §2`). If
every single catch became an always-on rule, the agent's reading list would bloat with one-offs and flukes, and
the real rules would drown.

So the first time the agent misses tenant-scope, the inbox records:
`signature: missing-team_id-filter-in-src/data | occurrences: 1 | status: active`.

### A.5 Step 4 — PROMOTE (3 hits + a human "yes" → it becomes a rule)

The lesson sits in the inbox and the count climbs each time the same signature recurs:

- 1st miss → `occurrences: 1`
- 2nd miss → `occurrences: 2`
- 3rd miss → `occurrences: 3` → **promotion threshold reached.**

At **≥3 occurrences plus a human/`/compound` confirm**, the finding **promotes** out of the inbox into a real
rule (VISION CMP1; `cr/SKILL.md:179-225`, the existing ≥3 threshold; `memory-model.md §2`: "Promotion to S1
requires ≥3 occurrences + a human/`/compound` confirm").

The promoted rule lands in `.claude/rules/` as a path-scoped rule — e.g. a `src-data.md` shard that **only loads
when the agent touches `src/data/`** (`memory-model.md §S1`: "area shards auto-load via native `paths:` globs").
That path-scoping matters: the agent doesn't carry every rule on every task; it carries the rules that apply to
the files it's about to edit.

There's also a clock on the inbox so good lessons don't get stuck: a finding sitting `active` at ≥3 for more than
14 days is flagged "overdue promotion," and a finding with no new hits in 30 days auto-retires as noise
(`memory-model.md §S3 freshness`). The inbox can't silently swallow a real lesson, and it can't keep a fluke
forever.

> **Why 3?** It's the "duplication is cheaper than the wrong abstraction" instinct applied to lessons: one or two
> hits could be a fluke or a one-off; three is a *pattern* worth making everyone read. The number is the existing
> harness threshold, carried forward — not invented here.

### A.6 Step 5 — READ-BACK (the rule loads on the NEXT run — this is the half the harness was missing)

This is the step the harness never had. Now that the lesson is a rule:

- **Promoted rules** (≥3) load automatically. When the next run touches `src/data/`, the platform's path-scoping
  loads the `src-data.md` shard, and "every query MUST filter by `team_id`" is **in front of the agent before it
  writes the query** (VISION CMP1; `memory-model.md §S1 reader`: "delivered by the platform's native `paths:`
  glob lazy-load").
- **Not-yet-promoted findings** (1–2 hits, still in the inbox) are *also* read back, just more softly: at
  task-start the skill globs the inbox against the files the task will touch and surfaces matches with their
  count — *"you are about to edit `src/data/proposals.ts`; a tenant-scope finding recurred here twice"*
  (VISION CMP1; `compound-loop.md §2`, the S3 task-start glob). So the agent sees the warning at the exact
  moment it's about to repeat the mistake — even before the lesson is a full rule.

**This is the closed read-path** — the thing VISION CMP1 exists to build, because today the findings file is
"never read by implementers" (`memory-model.md §0`). A real-world proof point the research leans on: Bitloops
drove the same class of violation down 87–100% over eight weeks **purely by feeding caught violations back as
generation context** — the write side already existed; closing the read side was the whole gain (VISION CMP1).

After Step 5, the agent is *much* less likely to miss tenant-scope — but "less likely" is not "impossible." A
rule is a reminder. A tired or distracted run can still skip a reminder. That's what Step 6 fixes.

### A.7 Step 6 — RATCHET (turn the rule into a dumb block → make the mistake impossible)

The **ratchet** is the move from *advisory* ("the agent reads a rule that says don't") to *deterministic* ("a
dumb check refuses it"). It's named after a ratchet wrench: it only turns one way — once a mistake is blocked, it
stays blocked.

The doctrine (Hashimoto, quoted in VISION CMP2): *"anytime you find an agent makes a mistake, engineer a solution
such that the agent never makes that mistake again."* Today's harness is "overwhelmingly advisory" — lots of
rules, few hard blocks. The ratchet fixes that.

When a finding promotes, a **ratchet pass classifies it**: *can this be a deterministic block?* (VISION CMP2;
the ratchet's home is the `/compound` sub-phase — `CORRECTIONS-LEDGER §K4`.) Three possible enforcement homes:

1. **A lint rule / pre-commit hook** — refuses the bad code before it's even committed.
2. **A CI pipeline check** — fails the build on your git host if the bad pattern appears (works on GitHub,
   GitLab, anywhere).
3. **A new criterion in the governance review lens** — `/cr` now flags it as MUST-FIX by an explicit, named rule
   (VISION C5/CMP2 compose).

For our tenant-scope example, here's the ratchet turning, rung by rung:

- **Rung 0 (advisory):** the `src-data.md` rule says "filter by `team_id`." The agent reads it. Usually obeys.
- **Rung 1 (lint):** a custom lint rule scans every query in `src/data/` and **errors** if a query against a
  tenant table has no `team_id` filter. Now a careless run *fails to commit*.
- **Rung 2 (CI):** the same check runs in the CI pipeline as a required check on a protected branch. Even if
  someone bypassed the local lint, **the PR/MR cannot merge** with an unscoped query.
- **Rung 3 (the strongest, app-level):** the database itself enforces tenant isolation (row-level security), so
  even a query the agent *wrote* wrong returns no cross-tenant rows. (In this repo that backstop already exists —
  `private.team_ids()` RLS; the app-layer rule is the *first* line, RLS is the *last*.)

By the time the ratchet has turned to Rung 2, **it is no longer possible for the agent to ship a tenant-scope
miss** — a dumb check, below the model's reach, refuses it every time, identically. The lesson went from "the
agent keeps forgetting" → "the agent reads a reminder" → "the agent literally cannot merge it." That arc — first
mistake to impossible — is the whole point of the per-repo loop.

> **Honest note:** not every lesson *can* become a dumb block. "Write clearer variable names" has no
> deterministic check. The ratchet's rule (VISION CMP2): turn it into a block *if you can*; "note only when a
> block is genuinely impossible." The win is that the *mechanical* lessons (tenant-scope, layer boundaries,
> destructive ops, money-math) ratchet into blocks, and the rulebook stays small because the enforced ones leave
> the advisory list.

### A.8 Step 7 — MEASURE (first-pass-approval rises — proof, not vibes)

How do you know the loop is *working* and not just accumulating rules? You measure. The headline sensor is
**first-pass-approval-rate**: of the agent's PR/MRs, what fraction passed review on the first try with no rework?
(VISION CMP3; `memory-model.md §0`: "the loop's own health is measured.")

The logic:
- If tenant-scope was failing review every third PR/MR, and after the loop closes it stops failing, **first-pass-
  approval climbs.** That climb is the loop compounding.
- If first-pass-approval is *flat* after you added a rule, the rule loaded but didn't land — a **read-path
  failure** to investigate (`compound-loop.md §4`).
- A second sensor watches the blocks themselves: a layer-boundary CI check that fires less and less over time
  means the constraint is actually preventing the mistake; a check that *never* fires after a long history may be
  guarding a mistake that can't happen anymore — a candidate to retire (`compound-loop.md §4`, the L2
  failure-rate-over-time signal).

**Honest, important caveat (built vs gated).** The day-0-measurable fields — review-cycle-count, per-finding
recurrence, PR/MR-size trend — can be tracked **now**. But true **first-pass-approval-rate** needs real merged-PR
volume to be meaningful, so VISION re-tiers it as **P1, gated on a volume flip-trigger** (VISION CMP3: "P0 for
day-0-measurable fields; P1(volume) for first-pass-approval"). On a solo repo with a handful of PRs, the rate is
noise. So: recurrence-count proves the loop *now*; first-pass-approval becomes the headline number *once there's
enough volume to trust it*. Saying otherwise would be measuring on vibes — the exact thing this step exists to
prevent.

### A.9 The per-repo loop, end to end, in the example

| Step | What happens to "the agent forgets tenant-scope" | Built now? |
|---|---|---|
| 1. Catch | `/cr` flags the unscoped query as MUST-FIX (or session-end notices the correction) | Review-catch built; session-catch designed (CMP5) |
| 2. Propose | "In `src/data/`, every query MUST filter by `team_id`" — **a human says yes** | Designed (human gate is the rule) |
| 3. Inbox | Lands in `RECURRING-FINDINGS.md`, `occurrences: 1`, signature-matched | Ledger built; airlock discipline designed |
| 4. Promote | Hits 3 → promotes to a `src-data.md` path-scoped rule | ≥3 threshold built (`/cr` 3b); shard target designed |
| 5. Read-back | Rule loads when the agent touches `src/data/`; sub-threshold findings surfaced too | **The missing half — CMP1, designed** |
| 6. Ratchet | Classify → lint rule → CI required check → impossible to merge unscoped | **Designed — CMP2, the `/compound` sub-phase** |
| 7. Measure | Recurrence drops now; first-pass-approval rises once volume allows | Day-0 fields now; FPA gated on volume |

The honest read of this table: the harness already had the *write* and the *count*. V2's per-repo work is
**read-back (CMP1) + ratchet (CMP2) + measurement (CMP3)** — the three steps that turn a write-only logbook into
a loop that actually makes mistakes impossible (`memory-model.md §0`).

---

## Loop B — the GLOBAL loop (a lesson in one repo improves the shared harness for all)

### B.0 The problem Loop B solves

Loop A makes *one repo* smarter. But the moment you run a fleet across 5+ repos, a different rot sets in: an
improvement made in one repo **never reaches the others.** Each repo independently re-learns the same lesson, and
the fleet **drifts apart** — every repo accreting local fixes the others never see (VISION P8;
`github-usage.md §5a`: "the 5 repos drift *apart*").

The tenant-scope lesson is the perfect example. It is **not** specific to this repo — *every* multi-tenant repo
has it. It would be absurd for the logistics-service repo to re-discover tenant-scope from scratch through its own
three-strikes loop. Loop B is the path that carries the lesson up to the shared harness and back down to everyone.

### B.1 The loop in one picture (draw this)

```
   a repo's /compound promotes a learned lesson (Loop A, step 4)
            │
            ▼
   ┌─ the promotion gate reads ONE field:  scope: project | universal ─┐
   │                                                                     │
   ├─ scope: project  → STAYS LOCAL  (this repo's .claude/rules/)        │
   │                                                                     │
   └─ scope: universal → opens a HUMAN-REVIEWED PR/MR                     │
                          against the SHARED plugin repo (agent-harness) │
                                  │                                       │
                                  ▼   a human reviews + merges            │
                          /plugin update  pulls it DOWN to               │
                          EVERY repo on the fleet (any git host)         │
                                  │                                       │
                                  ▼                                       │
                          the rule arrives in each repo and starts        │
                          its OWN per-repo "did this help here?" clock     │
   └─────────────────────────────────────────────────────────────────────┘
```

### B.2 The gate — one field decides project vs universal

The whole global loop hinges on **one field on the promotion gate: `scope: project | universal`** (VISION P8;
`github-usage.md §5a`; the field lives on the P6 `harness-manifest.json`). When Loop A promotes a lesson, the
gate asks: *is this true for this repo only, or for every repo?*

- **`scope: project`** — e.g. "this repo's proposals page must show the deposit line first." Stays local. Lands
  in this repo's `.claude/rules/` and goes no further. (`github-usage.md §5a`: "stays local.")
- **`scope: universal`** — e.g. "every query in a multi-tenant data layer must filter by tenant." This is true
  everywhere. It earns a trip up to the shared harness.

**Who decides?** A human, at promotion time. The field is set during `/compound`, and a `universal` tag triggers
a **human-reviewed PR/MR** — the automation does **not** auto-push to the shared harness (VISION P8: "a
`universal` change opens a human-gated PR"). This is deliberate: a bad universal rule poisons *every* repo at
once, so the gate up to the fleet is a human, every time.

### B.3 The path up — a human-reviewed PR/MR against the shared plugin

A `universal` lesson opens a PR/MR against the **shared harness plugin repo** (named `agent-harness` in the
design). This is an ordinary code review, on your git host:

1. The PR/MR adds the rule (and, where it ratcheted into a block, the lint/CI check) to the plugin's portable
   rule set.
2. A **human reviews it** — is this really universal? Is the block correct? Does it conflict with an existing
   rule? (`github-usage.md §5a`: "merged by a human.")
3. On merge, the plugin's version bumps (e.g. `agent-harness@1.2.0`).

**Git-host-agnostic by construction.** The plugin install path takes *any* git URL —
`claude plugin marketplace add <git-url>` works on GitHub, GitLab, Gitea, or a self-hosted host; only Anthropic's
*public curated* marketplaces are GitHub-pinned (`ROUND-2-FEEDBACK §/goal-facts`: "Plugins/marketplaces are
GIT-HOST-AGNOSTIC … private marketplaces self-host on GitLab/Gitea/any"). So a fleet on GitLab pushes its
universal lessons up exactly the same way a GitHub fleet does. The "open a PR/MR against the shared plugin" step
is the same on every host.

### B.4 The path down — `/plugin update` carries it to every repo

The merged universal rule reaches the fleet through the **native pull path**: `/plugin update` (VISION P1;
`github-usage.md §2`). Each repo runs:

```
/plugin update agent-harness@1.2.0
```

This pulls the new version — a **validated, pinned version, not a live symlink** (a symlink would resolve to
whatever's at HEAD and re-create the drift it's meant to prevent — `github-usage.md §2`, the symlink-live
upheld-cut). The tenant-scope rule (and its lint/CI block) now lives in every repo that updated.

**Push-up and pull-down are two halves of one ring** (`github-usage.md §5a`: "push-back-up and the pull path are
the same loop's two halves"). The lesson left one repo, passed a human, and arrived at all of them.

### B.5 What a receiving repo actually gets

When a repo runs `/plugin update`, the plugin can carry the *portable* parts of the lesson:

- The **rule text** (the `.claude/rules/` shard for the data layer).
- The **deterministic block** if the lesson ratcheted into one (the lint rule / CI check) — the "earned blocks
  travel via plugin" path (VISION CMP2: "earned blocks travel via plugin").
- The **review-lens criterion** if it became a governance-lens check.

What the plugin **cannot** carry: per-repo files like `permissions`/`settings.json` (a plugin's settings file is
limited to a tiny set of keys — the "27-byte proof", `github-usage.md §2`). Those per-repo files come from the
thin `/init` template (VISION P2), not the rule-carrying plugin. So a universal *rule* travels cleanly; anything
that must be placed in a guarded per-repo file is a separate, human-applied step. Honest seam, not a wrinkle to
hide.

### B.6 Built now vs gated — the honest line on Loop B

This is where the design is deliberately restrained, and it matters:

- **BUILT NOW (P1):** the **`scope:` field + the human-reviewed PR/MR path.** One field, one human-gated PR/MR,
  no automation (VISION P8: "P1 for the human-gated PR path").
- **GATED:** the **automation** of push-back-up. It waits on a single flip-trigger — **a 2nd repo installs the
  plugin** (VISION P8; `github-usage.md §5a`: "there's nothing to push *to* until a second project exists").

Why gated? Because **the harness has only ever been installed in one repo (event-vendor)** (`github-usage.md §0`,
§8). Building automatic cross-repo push-back-up *before a second repo exists* is building a bridge to nowhere —
the exact "hypothesis before speculative build" discipline the project follows (`memory:
feedback_hypothesis_before_speculative_build`). Until repo #2 lands: one field, a human-reviewed PR/MR, done. The
moment repo #2 installs, the automation has somewhere to push, and it earns its build. **This is a deliberate
hold, not a gap.**

---

## How the two loops feed each other

The two loops are not parallel tracks — they're a figure-eight. Each one's output is the other's input.

### C.1 Per-repo → global: a proven local block becomes a universal one

The handoff *up* is the `scope: universal` tag (Loop A step 4 → Loop B). But the deeper connection is
**evidence**: a block that has *proven itself useful in one repo* is the strongest candidate to ship to all of
them.

Walk it with tenant-scope:
1. **Loop A** in event-vendor catches it, inboxes it, promotes it, ratchets it into a CI block, and **measures**
   that it stopped recurring (Loop A step 7).
2. That measurement is the argument: *"this block caught real defects here; it should protect every multi-tenant
   repo."*
3. A human tags the rule `scope: universal` and opens the PR/MR up to the shared plugin (Loop B).
4. The fleet pulls it down. Every repo now has tenant-scope enforced **without re-learning it through its own
   three-strikes loop.**

The local loop *earns* the universal promotion; the global loop *distributes* it. A block doesn't go universal on
a guess — it goes universal because Loop A's measurement showed it works (VISION CMP2 composes with "the
distribution pillar — earned blocks travel via plugin").

### C.2 Global → per-repo: an arriving rule starts a local clock

The handoff *down* is `/plugin update` (Loop B → Loop A). But the arriving rule isn't the *end* of a story — it's
the *start* of a new per-repo loop in the receiving repo.

Walk it in logistics-service (a repo that just installed the plugin):
1. `/plugin update` brings in the tenant-scope rule and its CI block.
2. In logistics-service, that rule now **loads on the next run** (Loop A step 5) and **measures itself** (Loop A
   step 7) — *did this rule actually help in this repo?*
3. If logistics-service has a quirk the universal rule doesn't cover (say, a read-only reporting schema that's
   intentionally cross-tenant), Loop A in *that* repo catches the friction, and a *new* local lesson is born — a
   `scope: project` carve-out — which may itself eventually flow back up as a refinement.

So a universal rule arriving in a repo doesn't end learning there; it **seeds** a fresh per-repo loop. The fleet
gets smarter *and* each repo keeps adapting the shared lesson to its own reality. The figure-eight never stops:

```
   PER-REPO LOOP (repo X)  ──[scope:universal + measured]──►  GLOBAL LOOP (shared plugin)
        ▲                                                              │
        │                                                              │
        └──[/plugin update arrives, starts a new local clock]──────────┘
```

---

## The cross-repo drift loop (the third, quieter loop on a schedule)

There's a third loop worth naming, because it protects the *other* two from rotting: **scan-context on a
schedule** (VISION P9 / CMP4).

The problem it prevents: **context rot at fleet scale.** A human reads a slightly-stale doc and shrugs; an agent
re-onboards from that doc **thousands of times** and reasons wrongly with full confidence (`github-usage.md
§5b`). And the harness has a *live, dated proof* this happens — the audit that produced these very design files
**rotted mid-run and shipped four false claims** (`github-usage.md §5b`; `CORRECTIONS-LEDGER §C-i`).

`scan-context` is a scheduled cloud routine that scans the fleet's knowledge files for two kinds of drift:
- **Stale** — a doc fell behind the code (a rule references a path/command/skill that no longer exists).
- **Fiction** — the more dangerous one: a doc asserts a rule the code *never actually followed*. (The harness's
  own canon cites *five phantom artifacts* — files referenced but absent — `github-usage.md §5b`, §6.)

It runs in three legs, in dependency order (VISION P9; `github-usage.md §5b`):
1. **A CI check on every merge (P0 — detection):** validates every knowledge file — frontmatter present, owner
   set, prose instructional not descriptive, **no broken cross-references** (the reference-integrity check that
   catches phantom refs).
2. **A scheduled scanner (P0 — detection):** a cloud routine that opens **issues/tickets** for
   stale/fiction/contradiction/duplication/decay, *across the fleet*.
3. **The repair worker (P1 — GATED):** opens scoped, review-gated, human-merged fix PR/MRs — with safety baked
   in: a declared `owner` and a `supersedes:` precedence schema (so the loop can't eat its own tail), and the
   worker is **denied write access to guard files, settings, and the destructive-op floor**
   (`github-usage.md §5b`).

**Built vs gated, honestly:** **detection (legs 1+2) is P0 and ungated**; the **repair worker (leg 3) is P1 and
gated on a fork** (does it get a deterministic auto-delete lane for *provably-absent* fiction refs, while gating
staleness fixes to human review? — `github-usage.md §5b`, Fork F7). Detection ships; the part that *changes
files on its own* waits on a human decision about how aggressive it's allowed to be. That line — "self-correcting"
vs "self-modifying" — is exactly where the design stops and asks.

Why this is the *third* loop and not part of A or B: Loops A and B make the harness *learn new things*;
scan-context makes sure the things it already wrote down **stay true.** A learning loop that compounds fiction is
worse than no loop. Scan-context is the loop that keeps the other two honest.

---

## "The harness gets smarter while you sleep" — the plain-language narrative

Picture a Tuesday night. Your laptop is closed.

1. A bug gets reported. Maybe someone types `/fix` in **Slack**, or files it in **Linear**, or labels an
   issue/ticket in your git host. **All three are first-class doors** — any of them summons an agent (VISION L1;
   the correction that Slack/Linear are equal to a repo label). A scheduled cloud routine (a `/schedule` routine,
   triggered by a webhook or a host event) wakes an agent in a fresh worktree — **laptop-closed** (VISION L4).
2. The agent reads its rules *before* it writes — including the tenant-scope rule that Loop A promoted three
   weeks ago (Loop A step 5). It does **not** repeat that mistake, because the read-path is closed.
3. It writes the fix, the review step (`/cr`) checks it, and — because tenant-scope long ago **ratcheted into a
   CI block** — even if the agent had slipped, the PR/MR simply could not merge unscoped (Loop A step 6). The
   built-in continuation loop runs it until a *separate* check says done (not a new skill — the native `/goal`
   primitive), and a PR/MR opens.
4. While it works, a **narration stream** tells you what it's doing — just-finished / running-now / next /
   waiting-on — so when you wake up you can see the whole run, not just the ending (VISION L7).
5. That same night, in another repo on the fleet, an agent hits a *new* recurring mistake. Loop A catches it,
   inboxes it, and — if it crosses three and a human later tags it `universal` — it'll ride Loop B up to the
   shared plugin and down to everyone (Loop B).
6. And on its own schedule, scan-context sweeps the fleet's docs for drift and opens tickets where the canon has
   started to lie (P9).

In the morning, you review a small stack of PR/MRs that were *written, checked, and gated* while you slept —
**and** the harness that produced them is measurably better than it was last week, because every mistake it made
fed back as a rule, the mechanical ones became blocks, and the universal ones traveled to the whole fleet. That's
the dual learning loop: **the work compounds, and the thing doing the work compounds too.**

---

## What is built now vs gated — the honest ledger

| Piece | Loop | Status | Cite |
|---|---|---|---|
| `/cr` counts recurring findings (the write side) | A | **Built** | `cr/SKILL.md:174` |
| ≥3-occurrence promotion threshold | A | **Built** | `cr/SKILL.md:179-225` |
| Findings ledger / inbox (airlock) | A | **Built** (ledger exists; airlock discipline designed) | `memory-model.md §S3` |
| Read-back into task-start context (CMP1) | A | **Designed, not built** — the missing half | VISION CMP1 |
| Session-end capture of corrections (CMP5) | A | **Designed; rides an unverified Stop-hook capability** | `compound-loop.md §1` |
| The ratchet — finding → deterministic block (CMP2) | A | **Designed** — `/compound` sub-phase | VISION CMP2; `CORRECTIONS-LEDGER §K4` |
| Recurrence-count / cycle-count metrics | A | **Buildable now (day-0 fields)** | VISION CMP3 |
| First-pass-approval-rate (headline metric) | A | **GATED on PR-volume flip-trigger** | VISION CMP3 |
| `scope: project\|universal` field + human-reviewed PR/MR up | B | **Built now (P1)** | VISION P8 |
| Automatic push-back-up | B | **GATED on a 2nd repo installing the plugin** | VISION P8 |
| `/plugin update` pull path (any git host) | B | **Designed** — after canon↔disk convergence (the publish gate) | VISION P1; `github-usage.md §2` |
| scan-context detection (CI check + scheduled scanner) | drift | **P0 — designed, ungated** | VISION P9 |
| scan-context repair worker | drift | **P1 — GATED on Fork F7** | `github-usage.md §5b` |

The honest one-line summary: **the write half is built; V2 builds the read half, the ratchet, and the
measurement (Loop A), plus the one-field human-gated promotion up to the shared plugin (Loop B) — and it
deliberately holds back the cross-repo *automation* until a second repo proves there's anywhere to push to.**

---

## New gaps / design-additions this deep-dive surfaced

- **GAP-DLL-1 — The `scope` decision has no decision aid.** Loop B hinges on a human correctly tagging a lesson
  `project` vs `universal`, but nothing helps them decide. A mis-tag is costly in both directions: tag-too-narrow
  and every repo re-learns it (the rot P8 exists to kill); tag-too-broad and a repo-specific quirk poisons the
  whole fleet. **Design-addition:** a lightweight heuristic at the promotion gate — *does this rule reference any
  repo-specific path, product name, or schema? If yes, default to `project` and require an explicit override to
  go `universal`.* Cheap, deterministic, and it makes the safer default the easy one. (Not in VISION; surfaced
  here.)

- **GAP-DLL-2 — A universal rule can collide with a local carve-out, and nothing reconciles them.** Loop B pushes
  a universal rule down; Loop A in a receiving repo may have a legitimate `scope: project` exception (the
  read-only cross-tenant reporting schema in §C.2). When the universal rule arrives, the two can contradict, and
  the design doesn't say which wins or how the conflict surfaces. **Design-addition:** the receiving repo's
  `/plugin update` should run the reference-integrity / conflict check (P9 leg 1) against incoming plugin rules
  vs local `.claude/rules/`, and surface a contradiction as a NEEDS-HUMAN item rather than silently letting one
  shadow the other. (Touches P9 + P8; neither states the merge-conflict case.)

- **GAP-DLL-3 — "Earned blocks travel" has no portability test.** VISION CMP2 says a ratcheted block travels via
  the plugin, but a lint rule or CI check written against one repo's structure (e.g. assuming `src/data/`) may not
  apply cleanly in a repo with a different layout. A block that's silently a no-op in the receiving repo is worse
  than no block — it *looks* enforced. **Design-addition:** before a universal block merges into the shared
  plugin, it needs a portability check — does it depend on a path/convention not guaranteed by the `/init`
  template? If yes, the block stays `project` or the convention gets promoted into `/init` first. (Not in VISION;
  surfaced here. Related to GAP-DLL-1.)

- **GAP-DLL-4 — Per-repo measurement on a low-volume repo can't tell "loop works" from "small sample."** Loop A
  step 7's honest caveat (FPA needs volume) becomes sharper across a fleet: a brand-new repo with five PR/MRs
  can't measure first-pass-approval at all, so it has *no* local signal for whether an arriving universal rule
  helped it. **Design-addition (or at least a named acceptance):** until a repo clears a volume floor, it borrows
  the *fleet-aggregate* effectiveness signal for inherited universal rules rather than computing its own — and the
  design should state plainly that low-volume repos run the loop on *recurrence-count* (day-0) only, deferring FPA
  to the fleet view. (Sharpens VISION CMP3's volume gate; the cross-repo aggregation is not designed.)

- **GAP-DLL-5 (cross-host honesty, from the corrections) — the non-GitHub trigger leg is not a native action.**
  Loop B's pull path and canon-in-repo are genuinely host-agnostic, but the *trigger front door* on a non-GitHub
  host is **webhook→routine or the Agent SDK, not a native action** (`ROUND-2-FEEDBACK §/goal-facts`: "GitLab CI
  / generic CI has NO native Claude action"). This doesn't break the dual loop — the loop is driven by promotion
  and `/plugin update`, not by the trigger — but any teachable write-up must say plainly that *kicking off* work
  on GitLab uses a generic webhook→routine, while GitHub has a native event trigger. Stating it is the honesty;
  hiding it would be the exact phantom-claim failure the audit exists to catch.
