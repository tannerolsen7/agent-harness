# Pass 3 — Apply: Stripe Minions vs. our harness (against CANONICAL-HARNESS-AS-IS.md)

Building on pass2: I apply the pass-2 tiering (§2.8: contract rules transfer fully, classification
disciplines transfer as method, infrastructure does not) and the pass-2 corrections (the headline
thesis is unverified §2.1; "fork-don't-build" is post-hoc §2.3; 2-retry protects the *review* gate
§2.4; activation-energy inverts at solo scale §2.5) to our actual harness. Every gap cites a
ground-truth row. No gap without a citation.

## (a) What we ALREADY do

- **Blueprint pattern (deterministic + agentic) — already built, not a gap.** Building on pass2 §2.2,
  the article's claim that this is "already implicit, needs naming" checks out. Our `/feature` pipeline
  *is* a blueprint: deterministic gates are the **pre-commit hook** (ESLint + `tsc --noEmit` + unit
  tests, exit-blocking) and the **pre-push hook**, both in `[canon §3e]` / `[disk §3e]`; the
  `.cr-ok` sentinel chain gates push `[canon §3e, §3f]`; CI `ci.yml`+`integration.yml` is the final
  deterministic node `[disk §3f]`. The agentic nodes are `/dev`, `/tdd` slices, `/cr` passes. So the
  D/A separation Stripe sells is **structurally present already**. What we lack is the *labeling*, not
  the *structure* — see (b).
- **Tool/rule curation per task — already done by a different mechanism.** Building on pass2 §2.7's
  correction that what transfers is the *principle* not Toolshed: we already surface skills
  **on invocation, not globally**, and scope rules by context. The runtime skill list mixes layers but
  skills load on `/invoke` `[canon §1, "skills loaded on invocation"]`; CLAUDE.md has scoped
  per-area rules (the table of "Changed → Update"). We have **no 500-tool token-paralysis problem** —
  our tool surface is small. The article's "transfers Fully" for Toolshed overstates; the principle is
  already satisfied. Not a gap.
- **Isolation per task — already done, and it's our genuine advance.** Building on pass2 §2.7: Stripe's
  devbox isolation maps to our **git worktrees** (`worktree-add.sh`) plus the **Tier-0 prod-key
  firewall** (`worktree-create.sh` WorktreeCreate hook, `gen-local-env.sh`, `test-local.sh`)
  `[disk §3e "worktree-create.sh"; §6 "prod-key firewall"]`. The ground-truth calls the firewall "a
  genuine disk advance over canon." Per the article's own "What Doesn't Transfer" table this row is
  "Partially — isolation yes, cloud parallelism no," which is accurate for us.
- **Human review as the hard gate — already our model.** Building on pass2 §2.4/§2.5: we have **no
  autonomous-merge path**. `/cr` (9-pass + adversarial) + `/cr-security` run before push, the `.cr-ok`
  sentinel is consumed by `scripts/pr.sh`, and the pre-push hook validates it `[canon/disk §3c, §3e,
  §3f]`. Review-as-gate is already load-bearing in our pipeline. The Stripe finding *confirms* our
  posture rather than exposing a gap.
- **A stop-and-surface discipline already exists.** The article's max-retry candidate lands on existing
  ground: our agent contract / skill bodies already have STOP-AND-SURFACE conditions (the article
  itself notes this), and CLAUDE.md hard-stops on unknown bug cause (`/debug` required) and destructive
  ops. The *calibration* (a numeric ceiling) is what's missing — see (b).

## (b) REAL gaps it exposes (each cites a ground-truth row or confirmed absence)

1. **No explicit numeric retry ceiling anywhere in the enforcement floor.** Building on pass2 §2.4
   (the 2-retry rule is the article's best-reasoned, free-to-adopt mechanism, and it exists to protect
   the review gate). Our deterministic floor `[canon/disk §3e]` is entirely *pre-commit/pre-push*
   correctness gates — there is **no hook or contract rule that counts agent fix-attempts and forces a
   human handoff after N**. This is a **confirmed absence**: no `enforce-scope.sh`, no retry-counter
   hook exists `[§3e, §5]`, and the auto-fix loop in `/cr` ("Opus auto-fix," `[canon §3c]`) has no
   stated attempt ceiling. Gap: add a max-retry stop condition to the agent contract / `@task-runner`.
   This is a **tier-1 contract rule (pass2 §2.8)** — words in a doc, near-zero cost. *Disciplined
   caveat:* verify whether existing STOP-AND-SURFACE wording already implies one-retry-then-stop before
   adding redundant text (the article's own open question, and our memory rule
   `feedback_hypothesis_before_speculative_build` says ship the simple version first).

2. **The blueprint D/A/G classification is unlabeled — and our floor is mostly advisory.** Building on
   pass2 §2.2 (a D is legitimate only when justified by a failure mode). The ground-truth's blunt
   finding: **"Both agree the system is overwhelmingly advisory — neither has a deterministic backstop
   for the bulk of skill bodies, CLAUDE.md rules, or the autoMode lists"** `[§3e Net enforcement
   picture]`. The article's Design Challenge is therefore *directly* actionable against a real gap:
   several steps our pipeline *treats as required in prose but enforces nowhere*. Concrete
   ground-truthed instances of "should-be-D, is-actually-advisory":
   - `block-dangerous-bash.sh` — **canon's 3rd structural guard, ABSENT on disk** `[§3e, §5]`. A
     should-be-D safety node that does not exist.
   - `enforce-scope.sh` — **canon structural, absent on disk** `[§3e, §5]`. Scope-exceeded is a
     should-be-D gate; it is prose-only today.
   - `branch-registry-guard.sh` — **canon structural, absent on disk** `[§3e, §5]`. One-session-per-
     branch is a should-be-D gate; advisory only.
   - **main-branch agent hard-block** lives in the *dormant* `.githooks/pre-commit`; the live husky
     shim lacks it `[§3e, §3f, §5]` — a should-be-D gate that is **wired out**.
   The gap the article exposes is not "add a blueprint" (we have one) but **"label every pipeline step
   D/A/G and convert the should-be-D-but-advisory ones into real gates."** This is a **tier-2
   classification discipline (pass2 §2.8)** with a real backstop deficit behind it.

3. **No failure-mode test on existing constraints — which the article's own golden rule demands.**
   Building on pass2 §2.2 and the ground-truth's reproduction of Page-13's golden rule: **"If you can't
   name a failure mode that the constraint prevents, the constraint is overhead"** `[§9]`. The article
   independently arrives at the same principle (a D is only justified by a failure mode). This is not a
   new gap so much as **external corroboration that the §9 Model Capacity Audit is the right cut** — and
   it sharpens it: every step we *do* label D in gap #2 must carry a one-line failure mode, or be
   demoted. The §9 re-audit (made against Sonnet 4.6, **due on the Opus 4.8 update** `[§9, §0 headline]`)
   should adopt the article's "name-the-failure-mode" test as its demotion criterion. Citation:
   §9 is an open, pre-authorized cut with no completed re-audit.

4. **Activation-energy / low-friction trigger inverts at solo scale — a gap to *resist*, not build.**
   Building on pass2 §2.5 (cheaper activation just loads the one scarce reviewer). The ground-truth
   confirms our single-reviewer reality: the harness is a **single-project, single-human** artifact
   `[§0 headline; §8 "never been installed anywhere but event-vendor"]`. The article's "activation
   energy as a design lens" candidate is therefore a **lower priority than it presents**: with one
   human review gate, driving activation toward a Slack-emoji trigger increases queue pressure on the
   exact bottleneck we can't scale. Cited gap is the *inverse* of the article's: our constraint is
   review throughput for one person `[§0; §8]`, so the actionable item is **review-load management**,
   not trigger-friction reduction. (No new infra; a sequencing/priority finding.)

## (c) Weaknesses in the article's OWN reasoning

- **Headline thesis is unverified and motivated (pass2 §2.1).** "Infrastructure is the whole story" is
  Stripe's self-description, routed through a secondary because the **primary blog was never fetched**
  (the article admits the permissions error). No counterfactual (weak model, same infra) was run.
  Necessary ≠ sufficient. We should import the *infra-first sequencing* as a heuristic, not as proof.
- **"Fork, don't build" is post-hoc (pass2 §2.3).** The article's own Open Question #4 concedes it does
  not know why Stripe chose Goose. The decision criterion is reverse-engineered and, as stated,
  unfalsifiable (any outcome "confirms" where the moat was). Use the *moat question*, discard the
  pseudo-criterion.
- **Leans on an unanchored metric (pass2 §2.6).** "1,300 PRs/week" is PRs *opened*, not merged-clean
  (Open Q #1). The article flags this then leans on the number throughout. Evidence the pipeline runs,
  not that output is good. We should not import throughput framing.
- **"Transfers Fully" is over-stated for infra rows (pass2 §2.7).** Toolshed/curation is marked "Fully"
  when only the *principle* transfers, not the centralized-MCP *mechanism*. The article conflates
  principle-transfer with mechanism-transfer in multiple rows.
- **Misses its own strongest connection (pass2 §2.4).** It separately states "2-retry = knowing when to
  stop" and "review is the gate" but never connects them — that the retry ceiling exists *to protect
  reviewability*. The mechanism is under-theorized in its own text.

## (d) Does it warrant fresh external research? — Mostly NO; synthesize.

Disciplined answer per the "prefer synthesize over re-research" rule:
- **No external research needed for the actionable items.** Gaps #1–#4 are tier-1/tier-2 (pass2 §2.8):
  a contract rule (retry ceiling), a classification exercise (D/A/G labeling against §3e/§9), and a
  priority finding (review-load). All resolve *inside* our own ground-truth map plus this article. The
  retry-ceiling number (2) and the failure-mode test are already fully specified by the source.
- **One narrow, optional re-research trigger — and only if a specific decision opens it.** If V2 ever
  considers **fork-vs-build for the agent runtime itself** (we currently *are* the Claude Code harness,
  not a forked Goose), the article's criterion is too weak (pass2 §2.3) to decide on. That is a
  **build-plan decision, not a research gap** — and the ground-truth already frames our real direction
  as "global, GitHub-hosted, bidirectional self-update" `[§0 headline; §8]`, which is an *installability*
  question, not a runtime-fork question. So even here: synthesize from existing canon first; only
  research if a concrete fork proposal is tabled.
- **Quarantine, don't research, the horizon item.** Machine-payment / agent-as-economic-actor `[article
  §future]` maps to nothing in the ground-truth map (no row) and the article itself says it doesn't
  transfer at event-vendor scope. Per pass2 §2.8 tier-3, it is horizon — file as watch-item, do **not**
  spend research budget. Citation for the non-gap: **confirmed absence of any related row in
  CANONICAL-HARNESS-AS-IS.md §1–§9.**

**Net:** this article is high-signal for *one* thing — it independently re-derives our own §9 golden
rule ("name a failure mode or it's overhead") and gives us a concrete, free mechanism (the numeric
retry ceiling) plus a labeling exercise (D/A/G) that lands precisely on the ground-truth's biggest
admitted weakness: **the floor is overwhelmingly advisory `[§3e]`**. Everything else is either already
built (worktrees, review-gate, on-invocation skills) or scale-dependent infra that should be
quarantined as horizon, not imported as a gap.
