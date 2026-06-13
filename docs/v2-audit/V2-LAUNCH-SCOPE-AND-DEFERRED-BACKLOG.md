# V2 Launch Scope + Deferred Backlog (RECONCILED — Round 4)

> **What this is.** The Round-3 handoff asked: *"What are the other ~35 deferred items? Review them — this
> already found holes."* This is that review, reconciled against the corrected premises (it does NOT use the
> raw `simplification-pass.md` split, which was written against a stale 1-repo assumption).
>
> **Premises this is reconciled against:**
> - **Front door PUNTED** to post-launch (R4-D1) — no event auto-starts work.
> - **No clock** (R4-D2) — no timer auto-starts work either. V2 = *human starts every run, machine finishes
>   it safely.*
> - **~5 repos, not 1** (`project_harness_multi_repo_reality`) — distribution/convergence is a PRESENT problem.
> - **Isolation is conditional; locks are the always-on net** (`feedback_locks_always_on`) — a dev DB is a
>   per-repo *recommendation*, not a universal default. The deterministic locks apply everywhere.
>
> **How to read the verdicts on deferred items:**
> - **SOLID** — the defer reasoning holds; do not pull forward.
> - **RECONSIDER** — the defer trigger has effectively fired, or the item is cheap and its value is present;
>   a candidate to pull into the launch program.
> - **SUSPECT** — the defer reasoning is built on a premise Round 3 already corrected; pulling forward is
>   recommended.

---

## PART A — THE V2-LAUNCH BUILD-NOW SET (reconciled)

What actually ships in version 2. Grouped by purpose. Every one is human-started.

**The box (safety — the always-on locks are the SOLE net; assume NO practice DB anywhere — R4-D8):**
- **F0** — isolation-by-construction is **NOT assumed for any project** (R4-D8: "treat every project as if it
  can't spin up a throwaway DB"). A disposable per-job DB is an optional human-added bonus where a project
  supports it (event-vendor/Supabase), never relied on for safety. The locks below carry 100% of the load.
- **F1** — `block-dangerous-bash.sh`, fail-closed, full scope (deploys, destructive SQL, `rm -rf`, force-push,
  writes to `.git`/`.husky`/`.claude`). *Must be very thorough* (R3 correction #3).
- **F2** — credential firewall as a standalone always-on lock (UN-folded from F0 — see Part B).
- **F9** — `disable-model-invocation` on every irreversible side-effect skill.

**The finish line (trust — the half that makes output shippable without a human reading every line):**
- **F6** — the un-forgeable + visible CI verdict gate. `.cr-ok` → CI required-check on the shipped SHA. *The
  keystone.*
- **C2 + C5** — the 4-lens adversarial reviewer (isolated solution context, shared project canon) + the
  governance lens (ADRs / Rejected Patterns / PITFALLS as criteria).
- **C4-lite** — one golden-set, one aggregate recall number that gates trust. (No per-lens granularity yet.)
- **F7** — the bounded-loop contract: retry ceiling + a real REJECT/NEEDS-HUMAN terminal state.

**The loop (now human-started):**
- **L2** — `/goal`, the continuation primitive (needs the Phase-0 force-continue capability probe first).
- **L5** — `/lfg`, the orchestrator (resolve Fork F8: `/dev` vs `/feature` as the single driver, first).
- **L6** — the incident → hotfix → migrate → post-mortem subsystem, carried forward verbatim.
- **L7** — the narration + observability log, anchored on GitHub (no new connector surface).
- **HOOK-1** — the single shared Stop/PostToolUse hook surface (C10, CMP5, L7 are payloads on it).
- **C10** — test + typecheck block-on-red at task completion (the cheap regression-trust half).
- **C12** — the TDD `docs/TESTING.md` ledger discipline, carried forward.
- **C13** — the one-time `model:`-field re-audit of every reasoning sub-agent on Opus 4.8.

**The learning (compounding):**
- **CMP1** — close the read-path: recurring findings load into the implementer's task-start context.
- **CMP2** — the finding→enforcement ratchet: a ≥3-recurring finding becomes a deterministic block.
- **CMP4-refcheck** — the reference-integrity check (canon cites 5 phantom artifacts today — a live bug).
  *Manual command for V2; the scheduled scanner is post-clock.*

**The fleet source-of-truth (PULLED FORWARD — 5 repos, see Part B):**
- **P3 (content half)** — migrate canon from Notion into GitHub Markdown; convergence becomes a `git diff`.
- **P6 (frontmatter half)** — the per-skill frontmatter contract (`owning-layer`, `portable`, `scope`,
  `disable-model-invocation`). Cheap; F9 needs it anyway.

**New, Tanner-requested (Round 3):**
- **Item 4 — the metrics dashboard.** Elevate CMP3's day-0-measurable fields (review-cycle-count, REJECT
  rate, finding-recurrence, PR-size trend) into a dashboard a human opens to answer *"is the harness helping,
  and where?"* (Manual/on-demand surface — no cloud report, per no-clock.)
- **Item 5 — answer the data-shape/design questions before coding.** A spec step that forces the hard design
  questions (schema / data shape, edge cases, open decisions) to be raised and **human-confirmed** before any
  code. The build-now slice of C6.

---

## PART B — THE STRUCTURAL FINDING (why "deferred" needs re-reading)

The `simplification-pass.md` that produced the "~8 build / ~35 defer" split states plainly: *"the harness has
been installed exactly once (event-vendor)... building marketplace channels... before a 2nd install is solving
a distribution problem that doesn't exist yet"* (line 43). **Round 3 corrected this: the harness runs in ~5
repos.** Two of the pass's biggest calls rest on the dead premise:

1. **The PLATFORM pillar was deferred behind a "2nd repo exists" trigger that has already fired (5×).**
   Convergence, a single source of truth, and supply-chain provenance across 15 vendored skills are *present*
   problems. The source-of-truth + convergence + provenance + manifest-frontmatter work is **build-now**; only
   the *plugin packaging* legitimately waits — and it waits on convergence finishing, not on a 2nd repo.

2. **F2 was folded into F0, assuming every job gets a disposable DB.** Round 3 corrected: isolation is
   conditional (not every repo has a dev DB), so **the locks are the always-on net.** F2 stays a standalone
   lock. (Same correction makes F3/F5's blast-radius-removal logic non-universal — but the front-door punt
   defers them anyway, for a different reason: no free-text trigger exists to guard.)

The lesson the handoff named: *deferring already hid the 5-repos and practice-copy holes.* These are those
holes surfacing.

---

## PART C — THE DEFERRED BACKLOG (each: what · why deferred · trigger to pull forward · verdict)

### Pillar 1 — THE LOOP

- **L1 — the trigger front door (label / Slack-Linear / CI self-heal).**
  *What:* an event auto-starts a run. *Why deferred:* Tanner's explicit punt (R4-D1). *Trigger:* V2 launches.
  *Verdict:* **SOLID.**
- **L4 — the cloud clock / scheduled self-triggering.**
  *What:* a timer auto-starts runs laptop-closed. *Why deferred:* Tanner's no-clock call (R4-D2). *Trigger:*
  V2 launches. *Verdict:* **SOLID.**
- **LOOP-7 / A6 — risk-based auto-approval.**
  *What:* a non-LLM classifier auto-approves LOW-risk PRs into the CI floor (never auto-*merge*). *Why
  deferred:* "no auto-approval yet" (R3 lock) + needs C4 recall to clear a floor. *Trigger:* C4 recall ≥ stated
  floor AND Fork F2 resolved. *Verdict:* **SOLID.**
- **P4 — MCP-as-substrate (summonable from outside).**
  *What:* external systems can summon the harness. *Why deferred:* it's the distribution half of L1; nothing
  summons it without the front door. *Trigger:* L1 ships. *Verdict:* **SOLID.**

### Pillar 2 — THE FLOOR

- **F3 — egress allowlist + operation-level gate.**
  *What:* network allowlist; deny `gh api` mutations / `WebFetch` / `apply_migration` unless a manifest grants
  them. *Why deferred:* its P0 status was tied to a free-text trigger (now punted) and to local-unattended being
  primary (Fork F4, unresolved). *Trigger:* a free-text trigger ships OR local-unattended becomes a first-class
  surface. *Verdict:* **SOLID for launch** — but note the conditional-isolation correction means it's *more*
  load-bearing than the simplification pass claimed once any trigger returns.
- **F5 — MCP lethal-trifecta gate.**
  *What:* refuse when one agent holds private-data + untrusted-content + egress at once. *Why deferred:* the
  untrusted-content leg only arrives with a free-text trigger. *Trigger:* Slack/CI free-text trigger ships.
  *Verdict:* **SOLID for launch.** *(The cheap MCP pin-and-diff lockfile — a separate supply-chain control — is
  a candidate to build now; see P5.)*
- **F8 — fleet stop-the-line circuit breaker.**
  *What:* halt the fleet when the same failure signature repeats N times. *Why deferred:* bounds the *fleet*;
  no fleet-volume autonomy yet (everything human-started). *Trigger:* running many repos at volume unattended.
  *Verdict:* **SOLID.**

### Pillar 3 — THE CRAFT

- **C4 (per-lens / per-pass granularity).**
  *What:* recall + false-positive rate broken down per pass and per lens. *Why deferred:* the launch decision
  needs only one aggregate recall number; per-lens is a tuning luxury. *Trigger:* you're actively tuning
  individual lenses. *Verdict:* **SOLID.**
- **C6 (the full per-feature spec layer with executable Verification).**
  *What:* every feature gets a `docs/specs/<feature>.md` with runnable verification steps + an independent
  review pass on the spec. *Why deferred:* the *before-coding-questions* slice is pulled forward as Item 5; the
  full executable-Verification-per-feature machinery is broader. *Trigger:* Item 5 in use exposes the need for
  the full spec doc. *Verdict:* **RECONSIDER** — scope exactly how much of C6 Item 5 covers vs. defers.
- **C8 — the `/verify` render gate (headless CI, pixel-diff baseline, fail-closed tenant assertion).**
  *What:* prove a UI fix actually renders, as the *right* tenant. *Why deferred:* you only trust an automated
  screenshot under autonomy; V2 UI fixes are human-verified. *Trigger:* the first autonomous UI-fix run.
  *Verdict:* **SOLID.**
- **C9 — agent-legible markup mandate (`data-testid` / aria, lint-enforced).**
  *What:* the markup that makes the app navigable by an agent (= accessible to humans). *Why deferred:* its
  payoff (browser verification) defers with C8. *Trigger:* C8, or any browser-verification work. *Verdict:*
  **RECONSIDER** — the lint rule is nearly free at commit time and improves human a11y today regardless.
- **C11 — property-based invariants on money math (`fast-check`).**
  *What:* human-authored invariants (`total = sum(line items)`, tax never on service fees, no negative totals,
  integer-cents exact) the loop cannot weaken. *Why deferred:* gated on the `fast-check` install decision (Fork
  F6). *Trigger:* approve the dependency. *Verdict:* **SUSPECT** — a wrong total on a $30k proposal is the
  product's core disaster and is independent of autonomy. The only blocker is one install decision. The
  simplification pass itself lists this under "do NOT cut." **Recommend deciding the install now.**

### Pillar 4 — THE COMPOUNDING ENGINE

- **CMP3 (volume-dependent fields).**
  *What:* first-pass-approval-rate, post-merge-defect attribution. *Why deferred:* needs real merged-PR volume
  to mean anything. *Trigger:* ≥N merged agent PRs. *Verdict:* **SOLID** — the day-0 fields ship now in the
  dashboard (Item 4).
- **CMP4 (the full drift engine — staleness + decay + fiction classification).**
  *What:* bidirectional context-drift detection with `last_seen` decay. *Why deferred:* the cheap
  reference-integrity half ships now; the decay engine solves fleet-scale rot before it's real, and its
  *scheduled* execution needs the clock. *Trigger:* rule-churn creates real rot AND the clock returns.
  *Verdict:* **SOLID** (double-deferred by no-clock).
- **CMP5 — session-end capture (observed failure → proposed rule, human-confirmed).**
  *What:* propose memory/PITFALLS candidates from corrections seen in a session. *Why deferred:* `/cr` 3b
  already auto-writes findings; this is the upgrade, degrade-safe. *Trigger:* the manual capture cost becomes
  painful. *Verdict:* **SOLID.**
- **CMP6 — the model-capacity prune-PR loop with behavioral probes.**
  *What:* a probe suite that asserts the model still has each capability a de-scaffolding cut assumed; runs on
  every model bump. *Why deferred:* the recurring loop is scheduled (no clock); the *one-time* C13 re-audit
  ships now. *Trigger:* you start cutting scaffolding AND the clock returns. *Verdict:* **SOLID** — but note
  the de-scaffolding thesis quietly depends on this safety interlock; don't cut scaffolding aggressively in V2
  without it.

### Pillar 5 — THE PLATFORM (the pillar the 1-repo premise wrongly buried)

- **P1 — plugin + marketplace.**
  *What:* the installable, version-pinned unit. *Why deferred:* "no 2nd repo." *Trigger:* **already fired (5
  repos)** — but legitimately waits on canon↔disk convergence (the publish gate, = P3). *Verdict:*
  **RECONSIDER** — pull into the V2 program, sequenced *after* P3 convergence, not behind a dead trigger.
- **P2 — the thin `/init` template for project-owned files.**
  *What:* materializes per-repo files a plugin physically can't carry (permissions, settings, CLAUDE/AGENTS
  skeletons). *Why deferred:* co-built with P1. *Trigger:* P1. *Verdict:* **RECONSIDER** (rides P1).
- **P5 — skill-provenance trust governance.**
  *What:* pin each of the 15 vendored skills to a reviewed SHA; human-review-diff before any upstream update.
  *Why deferred:* framed as distribution. *Trigger:* **already fired** — 15 third-party skills steering judgment
  across ~5 repos is a present supply-chain surface. *Verdict:* **SUSPECT** — pinning + the MCP pin-and-diff
  lockfile is cheap and the risk is live now.
- **P6 (the manifest *consumer*).**
  *What:* the program that reads the frontmatter to drive distribution/`/init`/self-filtering. *Why deferred:*
  needed by the plugin, not the floor. *Trigger:* P1. *Verdict:* **RECONSIDER** (frontmatter ships now; consumer
  rides P1).
- **P7 — per-skill upstream-dependency disposition policy.**
  *What:* a one-page policy + a per-skill `vendor-freeze / track-with-cadence / cut` column. *Why deferred:*
  folds into the P6 manifest. *Trigger:* P6. *Verdict:* **RECONSIDER** — cheap, and the 5-repo + live-fork
  reality makes it present.
- **P8 — push-back-up promotion gate.**
  *What:* an improvement in one repo opens a human-gated PR against the shared plugin. *Why deferred:* needs the
  plugin to exist; automation gated on a 2nd repo installing it. *Trigger:* P1 ships (manual path); 2nd plugin
  install (automation). *Verdict:* **SOLID** (rides P1).
- **P9 — the cross-repo context-maintenance loop.**
  *What:* (1) a CI check validating every knowledge artifact on every merge; (2) a scheduled scanner; (3) a
  repair worker. *Why deferred:* (2)/(3) need the clock + Fork F7. *Trigger:* clock returns (scanner);
  Fork F7 (repair worker). *Verdict:* **RECONSIDER for half (1)** — the per-repo CI knowledge-artifact check
  needs no clock and catches the live phantom-ref bug across all 5 repos.
- **P10 — the 23-agent / 26-skill roster as portable roles.**
  *What:* ship the roster inside the plugin, serialized through the manifest. *Why deferred:* gated on a
  phantom-prune + dedup pass and the plugin. *Trigger:* P1 + prune/dedup done. *Verdict:* **SOLID** (rides P1).

---

## PART D — RECOMMENDED PULL-FORWARDS (the suspect/reconsider set)

> **DECIDED 2026-06-12 (R4-D3):** #1 (fleet-sync slice) and #3 (C9 a11y lint) PULLED FORWARD to build-now.
> #2 (C11 money-math) STAYS PARKED — pricing schema is mid-redesign (`recipe-planner` blocked); new trigger =
> "pricing schema finalized," not "approve `fast-check`."

The defer verdicts I'd challenge, highest-leverage first:

1. **The fleet source-of-truth + convergence + provenance slice** (P3 content + P6 frontmatter + P5 pinning +
   P7 policy + P9-CI-check). *Why now:* the "2nd repo" trigger fired 5×; canon drift, no single source of
   truth, and 15 unpinned vendored skills are present risks across the fleet. *Cost:* mostly docs + pinning +
   one CI check — not the plugin machinery (that follows convergence). **The biggest correction.**
2. **C11 — money-math property-based invariants.** *Why now:* core product disaster, independent of autonomy,
   one `fast-check` install-decision away. **Recommend making the install call now.**
3. **C9 — the `data-testid`/aria lint rule.** *Why now:* nearly free at commit time, improves human a11y today,
   and pre-positions browser verification. Low stakes, low cost — easy yes.

Everything else marked SOLID stays deferred with its trigger intact.
