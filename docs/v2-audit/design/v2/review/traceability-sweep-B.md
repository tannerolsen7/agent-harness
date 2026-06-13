# Traceability Sweep B — Research-to-Design Coverage Audit

**What this is.** A folded-in coverage audit: for each of the 18 assigned re-mine slugs, every
**ELEVATE** / **NEW** move is checked against the integrated V2 design (`ambition/VISION.md` +
`design/v2/{roster,file-tree,memory-model,github-usage,gaps-risks}.md`). Each move either **LANDED**
(name the move-ID), was **CUT / GATED** consciously (with a failure mode or flip-trigger in Honest
Cuts / STILL-GATED), or was **DROPPED** (raised by the re-mine, addressed nowhere). UPHELD-CUTs and
P0-carry-forwards from the re-mines are verified honored but not re-tabulated unless their kept-half
was dropped.

**Method note (charter rigor).** "Absent on disk" claims that gate a drop were re-verified by
`ls`/`grep` of `/Users/tanner/Dev/event-vendor/.claude/` **this session** (the audit artifacts rot —
this happened mid-effort). Confirmed on disk 2026-06-11: `.claude/hooks/` holds exactly 5 hooks
(`block-dangerous-git.sh`, `block-npm-install.sh`, `permission-logger.sh`, `session-start.sh`,
`worktree-create.sh`) — **`branch-registry-guard.sh`, `enforce-scope.sh`, `block-dangerous-bash.sh`
all ABSENT**; the `.githooks/pre-commit` main-branch block is wired out (dormant). So the dropped
guards below are genuine canon-only builds, not phantoms.

**Headline.** The design lands the overwhelming majority of the autonomy/floor/craft/compounding
spine cleanly. **13 ELEVATE/NEW moves are silently DROPPED** (raised by a re-mine, traceable to
nowhere in VISION or the v2 artifacts and not in any Honest-Cut / STILL-GATED list), plus **1
conscious GATE** (the retro/outcome store) and **2 partial landings**. The per-artifact WF4 checks did
**not** catch any of these research-to-design drops — their MUST-FIX items are internal-consistency
defects (`evaluate-solution` dropped from the roster, count reconciliation, a dead proxy-shard glob),
not lost research moves. That is exactly the gap this sweep exists to close. **Zero un-sourced design
additions were found** — every move-ID in VISION cites a ground-truth row + an elevating re-mine.

---

## Coverage table

| slug | move (ELEVATE/NEW) | LANDED-as / CUT / DROPPED |
|---|---|---|
| **goal-loop-primitive** | `/goal` continuation primitive (ELEVATE) | LANDED — **L2** |
| | verifier-rung taxonomy doctrine (NEW) | LANDED — **L2 clause** (DEMOTED-TO-CLAUSE, was L3) |
| | CI-verify `.cr-ok` unforgeable gate (ELEVATE) | LANDED — **F6** |
| | REJECT/UNATTENDED fallback path (ELEVATE) | LANDED — **F7** |
| **harness-engineering-survey** | Hashimoto ratchet as enforced machinery (ELEVATE) | LANDED — **CMP2** |
| | sensors / measurement layer (ELEVATE) | LANDED — **CMP3** (effectiveness-metrics ledger) |
| | portable harness = distributable artifact (ELEVATE) | LANDED — **P1/P6/P10** |
| | bounded-retry stopping condition (ELEVATE) | LANDED — **F7** |
| | self-improving instinct loop / derive-from-history (ELEVATE) | LANDED — **CMP1 + CMP2** (read-path + ratchet) |
| | subtraction as a first-class tier (ELEVATE) | LANDED — **CMP6** (§9 prune-PR loop) |
| **harness-io** | execution-surface audit → dedicated `/scan-context` skill on a cloud schedule (ELEVATE) | LANDED — **CMP4 + P9** |
| | feature-scoped AGENTS.md split (UPHELD-CUT) | CUT — honored (staleness-surface failure mode named in re-mine; VISION never adds it) |
| | audit-trail-as-accountability sliver (ELEVATE) | LANDED — **L7** (agent-PR observability log) |
| **leland-eight-principles** | outcome-keyed retro gate / IMPACT-LOG store (ELEVATE — "reward channel for the autonomy program") | **CUT (GATED)** — STILL-GATED "outcome/impact tracking (≥N autonomous PRs/week)". See §Conscious cuts. |
| | reusability-as-specialization-axis / portable-skill-by-default (ELEVATE) | LANDED — **P10 + P1** (portable roles via manifest) |
| | "name the failure mode or it's overhead" enforcement-test lens (UPHELD-CUT) | CUT — honored (folded into §9 re-audit; standalone build rejected) |
| **linear-context-execution** | converge scattered task surfaces into ONE canonical typed task object, with agent-read field gating (ELEVATE) | **DROPPED** |
| | accountability-binding doc — classify gates never-deletable vs capability-proxy (ELEVATE) | **DROPPED** |
| | skill-promotion rung — observed repeated workflow → named skill (ELEVATE) | **DROPPED** |
| | Design Challenge — spec-quality→outcome correlation probe (NEW) | **DROPPED** |
| **loop-engineering** | cloud heartbeat / scheduled discovery (ELEVATE) | LANDED — **L4** |
| | temporal-gap rule as an *enforced* invariant (CI/lint fails a ritual with no clock) (ELEVATE) | **DROPPED** (the audit-doctrine column landed implicitly via L4; the *enforced* "no committed ritual without a clock" check did not) |
| | discover/act seam → gated action agent (ELEVATE) | LANDED — **L4** (gated action agent, review-cheap output) |
| | `/goal` graded-continuation primitive (NEW+ELEVATE) | LANDED — **L2** |
| **mcp-servers** | consumed-tool trifecta leg-union gate (ELEVATE) | LANDED — **F5** |
| | tool/MCP-description pin-and-diff lockfile + `/cr` poisoning pass (ELEVATE) | LANDED — **F5** (pin-and-diff lockfile) |
| | dev-agent-only internal MCP server (NEW — "evaluate and de-defer") | **DROPPED** (P4 is the inverse — harness-as-*server-summonable*; the shared dev-fleet tool layer over `src/data/` is unaddressed) |
| | SDK / MCP-package supply-chain trust gate (ELEVATE) | LANDED — **`/dep-update` (roster Table B) + F3 op-level** |
| **notion-spec-driven** | per-feature behavioral contract `docs/specs/` with executable Verification (ELEVATE) | LANDED — **C6** |
| | executable verification surface gates autonomy (not `.cr-ok`) (ELEVATE) | LANDED — **C6 + C8 + F6** (C7 config) |
| | CI-as-throughput latency lever (UPHELD-CUT) | CUT — honored (flip-trigger: `/queue` ≥3 parallel worktrees; STILL-GATED CI-latency) |
| | Hot-Potato scheduled cross-source fan-out pre-read / situational brief (NEW) | **DROPPED** |
| **osmani-agent-skills** | learned-constraint store + grep enforcer + writer (ELEVATE) | LANDED — **CMP1 + CMP2** (read-path + ratchet; `learned-patterns.md` *file* correctly stays dead, mechanism kept) |
| | subtractive enforcement — `/simplify` as a guarded deletion skill (Chesterton's Fence) (ELEVATE) | **DROPPED** (`/simplify` survives only as a referenced `/feature` pipeline step; no subtractive-enforcement / deletion-guard move) |
| | stop-the-line defect-class circuit breaker (ELEVATE) | LANDED — **F8** |
| | CI-verified review gate (close honor-system hole) (ELEVATE/NEW) | LANDED — **F6** |
| | adopt/borrow/reject import-vetting screen as an enforced gate on skill imports (ELEVATE) | **DROPPED** (P5 provenance + P7 disposition are adjacent but neither is the *import-admission screen* on new skills) |
| **packmind** | bidirectional drift detector (stale AND fiction) (ELEVATE) | LANDED — **CMP4** |
| | observed-failure→rule capture trigger (`session-end.sh`) (ELEVATE) | LANDED — **CMP5 + HOOK-1** |
| | decay/expiry rule that runs (ELEVATE) | LANDED — **CMP4** (decay pass, `last_seen`) |
| | process-vs-knowledge taxonomy + "does the model already infer this?" authoring gate (NEW, small) | **DROPPED** |
| **playwright-mcp-debug** | artifact-producing render gate reaching CI (ELEVATE) | LANDED — **C8** |
| | debug≠verify — project-owned `/verify` (ELEVATE) | LANDED — **C8** (`/verify` skill) |
| | agent-legible == accessible markup, lint-enforced (ELEVATE) | LANDED — **C9** |
| | headless unattended browser path (ELEVATE) | LANDED — **C8** (CI leg vs preview deploy) |
| | fail-closed tenant assertion before trusting a snapshot (NEW) | LANDED — **C8** ("fail-closed tenant assertion") |
| **ramp-inspect-agent** | machine-enforced self-verification loop / evidence bundle (ELEVATE) | LANDED — **C10 + HOOK-1** |
| | real-browser visual artifact guardrail for UI diffs (ELEVATE) | LANDED — **C8/C10** |
| | multi-surface front door / Slack-Linear summon (ELEVATE) | LANDED — **L1 + P4** |
| | evaluable pass/fail output contract on every skill gate (ELEVATE — cross-cutting) | **DROPPED** (only `/cr` tiers + the C10 bundle exist; no cross-cutting per-skill pass/fail contract) |
| | model-capacity re-audit (ELEVATE half of "skill not agent") | LANDED — **C13 + CMP6** |
| **recursive-self-improvement** | unforgeable terminal stop authority (ELEVATE) | LANDED — **F6** (the keystone) |
| | continuous reviewer-recall calibration / golden set (ELEVATE) | LANDED — **C4** (`/cr-calibrate`) |
| | property-based testing on money math (ELEVATE) | LANDED — **C11** (GATED Fork F6) |
| | adversarial seeding of the golden set (ELEVATE-as-requirement) | LANDED — **C4** ("adversarially-seeded labeled diffs") |
| **shopify-ai-first** | session-end review artifact / structured handoff carried into PR (ELEVATE) | LANDED — **L7 + HOOK-1** (narration + observability; PR-carry via `pr.sh`) |
| | comprehension-debt detection — chronic-debt ledger / handoff field (ELEVATE) | **DROPPED** |
| | cross-repo cost/usage telemetry plane (PARTIAL-ELEVATE) | **DROPPED** (named only as gaps-risks #2 "never priced"; no build move) |
| | adversarial-generation (exploit-construction/fuzz) pass in `/cr-security` (ELEVATE) | **DROPPED** |
| | review-capacity as a named AFK constraint + review-queue-depth instrumentation (ELEVATE) | **DROPPED** (the *bottleneck* is named at LOOP-7; the *named pillar + queue-depth sensor* is not built) |
| **stripe-minions-kaliski** | Slack/automated-system trigger front-door (ELEVATE) | LANDED — **L1** (incl. CI-self-heal automated trigger) |
| | numeric retry ceiling + human handoff (ELEVATE) | LANDED — **F7** |
| | blueprint D/A/G discipline — **build the absent D-gates** (ELEVATE) | **SPLIT**: `block-dangerous-bash.sh`→**F1** ✓, `enforce-scope.sh`→**LANDED** (roster/file-tree) ✓, **`branch-registry-guard.sh`→DROPPED**, **main-branch agent hard-block re-wire→DROPPED** |
| | Toolshed 500-tool registry (UPHELD-CUT) | CUT — honored (token-paralysis absent at our scale; per-task tool-allow manifest kept via P6/F3) |
| **vercel-agentic-infra** | deterministic render-gate (ELEVATE) | LANDED — **C8** |
| | two-question kill-filter / autonomous-vs-human admission routing (ELEVATE) | **PARTIAL** — L1 routes feature/incident + blast-radius classifier + LOOP-7 tiers cover the risk-routing; the *verifiable-correct-output admission test that routes unstatable tasks to a human queue* is not built |
| | non-blocking checkpoints / pause-resume execution primitive (ELEVATE) | **DROPPED** (acknowledged only as gaps-risks #7 "recovery semantics under-specified"; no checkpoint-serialize/fire-and-resume move) |
| | skill-provenance / trust governance (ELEVATE) | LANDED — **P5** |
| **when-is-llm-call-worth-it** | evals-in-CI golden-PR regression for `/cr` (ELEVATE) | LANDED — **C4** (`/cr-calibrate`) |
| | behavioral-probe backstop on the Model Capacity Audit (ELEVATE) | LANDED — **CMP6** |
| | deterministic validation gates *between* probabilistic passes + measure-the-chain (ELEVATE, partial) | **DROPPED** (CMP3 measures cycle-count/first-pass-approval; no between-pass deterministic gate or per-pass chain-reliability measurement) |
| | fallback/abstention contract per reasoning pass + `/queue` liveness check (ELEVATE) | **DROPPED** (F7 bounds the *retry loop*; the per-pass abstention/confidence contract + dead-agent liveness/heartbeat is unaddressed) |
| | reversibility gate as primary autonomous-action gate (UPHELD-CUT + extension) | CUT — honored (doctrine built; the named unbuilt sliver = "what is same-turn consent when summoner is a webhook" lives in L1 design, not restated) |
| **zapier-skillmd** | enforcement-tier doctrine + advisory→tier-1 promotion campaign (ELEVATE) | LANDED — **F9 + the floor (F1/F5/F8)** |
| | build `block-dangerous-bash.sh` + `enforce-scope.sh` (ELEVATE) | LANDED — **F1 + enforce-scope (roster/file-tree)** |
| | SKILL.md frontmatter contract + real skill router (ELEVATE) | LANDED — **P6** |
| | accountability-as-residual-owner human gate in bug→PR (UPHELD-CUT contract sentence; gate kept) | CUT — honored (sentence cut as duplication; gate covered by LOOP-7/F6 human path) |

---

## The DROPPED list (raised by a re-mine, addressed nowhere in VISION or the v2 artifacts)

Ranked roughly by leverage. Each names the source slug, the move, and the failure mode the *re-mine*
attached to it (so the design owner can decide build-or-consciously-cut — right now it is neither).

1. **`branch-registry-guard.sh` + `active-branches.json`** — *stripe-minions-kaliski* (D-gate list),
   echoed by *zapier-skillmd* (enforce-scope sibling) and a canon-only §5 build. **Verified ABSENT on
   disk this session.** The design built `block-dangerous-bash.sh` (F1) and `enforce-scope.sh` but
   dropped the third structural guard of the same cluster. *Failure mode:* two unattended sessions own
   the same branch and stomp each other's commits — the exact multi-agent collision CLAUDE.md's
   worktree discipline exists to prevent, now unenforced at fleet scale. **Highest-priority drop** —
   it is a P0-floor-class deterministic guard that the floor pillar is supposed to be complete on.

2. **Main-branch agent hard-block re-wire** — *stripe-minions-kaliski* (D-gate list) + *osmani-agent-skills*
   (Move 4) + canon §5. The dormant `.githooks/pre-commit` carries a main-branch agent commit block;
   the live husky shim lacks it (`core.hooksPath=.husky/_`). Zero mentions in the v2 design.
   *Failure mode:* an unattended agent commits directly to `main`, bypassing the whole worktree+PR
   spine. Same floor-completeness gap as #1.

3. **Comprehension-debt ledger** — *shopify-ai-first* (Move 2, "the article's most useful gap-exposure
   for us"). *Failure mode (passes §9 golden rule):* an agent-written subsystem breaks and no human can
   diagnose it because nobody tracked which subsystems were touched-but-not-reasoned-about. The re-mine
   scoped a disciplined, lightweight version (one field in the session-end handoff feeding a chronic-debt
   list). HOOK-1/L7 build the handoff surface it would ride on, but the comprehension field/store is absent.

4. **Canonical typed task object** — *linear-context-execution* (Move 1). Converge the scattered task
   surfaces (TASKS.md line, TASK-TEMPLATE, AGENTS.md open-decision, ad-hoc prompt) into ONE typed object
   every entry point (L1, `/dev`, `/feature`, `/queue`) instantiates, with explicit agent-read field
   gating. *Failure mode:* parallel agents across 5+ repos each spin up from a different partial task
   surface — the fragmentation Linear's product erased. TASK-TEMPLATE survives as *a* handoff format in
   the roster, but the *convergence-to-one-typed-object* move is not a design item.

5. **Skill-promotion rung** — *linear-context-execution* (Move 3). A lifecycle rung that promotes a
   repeated multi-step *workflow* into a named skill (with the §9 retirement rule), distinct from the
   fact-promotion ladder (memory→RECURRING-FINDINGS→PITFALLS). *Failure mode:* recurring workflows get
   crammed into the fact-stores (a driver of the triple-duplication) and a genuinely reusable process is
   re-derived every session instead of codified. The compounding pillar (CMP1-6) promotes *findings/blocks*
   but has no workflow→skill rung.

6. **Accountability-binding classification doc** — *linear-context-execution* (Move 2). A canonical
   statement classifying every human/STOP gate as *accountability-binding* (never deletable: merge,
   destructive-op denylist, review checkpoint) vs *capability-proxy* (deletable as models improve).
   *Failure mode:* the §9/CMP6 deletion engine runs against Opus 4.8 with no principled stop-line and
   over-prunes a safety gate as if it were a capability proxy — the PocketOS class. This is a *precondition*
   for CMP6, which the design ships without.

7. **Cross-repo cost/usage telemetry plane** — *shopify-ai-first* (Move 3, partial-elevate). *Failure
   mode:* unattended fleets across 5+ repos on cloud `/schedule` hit a runaway-loop solvency problem with
   no per-repo/per-agent token+cost accounting (the re-mine cites an individual's five-figure weekly spend).
   gaps-risks.md #2 *names* the un-priced economics as a gap but the design has no telemetry build move; the
   provider-swap proxy half is correctly judged already-covered.

8. **Adversarial-generation (exploit-construction/fuzz) pass in `/cr-security`** — *shopify-ai-first*
   (Move 4). *Failure mode:* a named-pattern security pass passes code with a novel exploit no signature
   anticipated — the weakest link when PRs may auto-approve. The `lens-abuse`/security-reviewer roster
   rows keep the existing pattern-matching abuse lens, but no *exploit-construction* step is added.

9. **Review-capacity as a named AFK constraint + review-queue-depth instrumentation** —
   *shopify-ai-first* (Move 5). *Failure mode:* N agents generate PRs faster than one human reviews, so the
   queue grows unbounded or review goes shallow and quality degrades. LOOP-7 names the *bottleneck* and is
   the auto-approval response, but the design never adopts "review throughput is the AFK ceiling" as a
   scored principle, nor builds a queue-depth/staleness sensor.

10. **Hot-Potato scheduled cross-source fan-out pre-read** — *notion-spec-driven* (Move 4, NEW). A
    cloud-`/schedule` agent that fans out parallel sub-agents over GitHub PRs / Linear-Notion tasks / CI
    status / prior handoffs and reduces them into a committed situational-awareness brief. *Failure mode:*
    a single agent serially crawls N sources, blows its context, and loses the plot on embarrassingly-parallel
    work. L4 (heartbeat) is the scheduler substrate it would ride, but the fan-out *situational-brief* payload
    is not a design item (the roster's "fan-out" refs are the `/cr` lenses and `/design explore`, not this).

11. **Subtractive-enforcement deletion skill (`/simplify` w/ Chesterton's Fence)** — *osmani-agent-skills*
    (Move 2, "the page's strongest gap"). *Failure mode:* an additive-only harness accretes dead code, dead
    skills, and stale canon forever across 5+ repos; nothing drives guarded *removal*. `/simplify` appears
    only as a referenced step inside `/feature`'s pipeline — the subtractive *enforcement* mechanism (state
    why the code exists + what proves it dead before deletion) is absent. (Partly adjacent to CMP6's
    *capacity* prune, but that prunes scaffolding the model outgrew, not product dead-code.)

12. **Adopt/borrow/reject import-vetting screen** — *osmani-agent-skills* (Move 5, "the single highest-value
    synthesis artifact"). An enforced gate every plugin/marketplace skill import passes through
    (`structural_gain − (context_tax + drift_surface + maintenance_cost)` → adopt/borrow/reject). *Failure
    mode:* a marketplace world where every repo accretes a different pile of advisory skills, 23×-ing drift
    surface for zero capability. P5 (provenance/pinning) and P7 (upstream disposition) govern *trust and
    upstream cadence* of skills you already have — neither is the *admission screen on new imports*.

13. **Non-blocking checkpoints / pause-resume execution primitive** — *vercel-agentic-infra* (Move 3),
    overlapping *when-is-llm* fallback concerns. A checkpoint-serialize + fire-and-resume primitive so an
    agent yields at a CI-pending / approval / deploy-in-flight gate and is re-invoked on the event. *Failure
    mode:* a long autonomous loop dies when the session ends and restarts from scratch, or freezes at a
    human-checkpoint with the whole task stalled. gaps-risks.md #7 acknowledges "recovery semantics after a
    partial unattended run are under-specified" — but as an open gap, not a designed move.

**Secondary drops (smaller / self-trigger-gated in the re-mine, still un-homed):**

14. **Dev-agent-only internal MCP server** — *mcp-servers* (Move 3, NEW, "evaluate and de-defer"). A shared
    tool layer over `src/data:`/harness ops for the agent fleet's own consumption. *Failure mode the re-mine
    names against over-building:* premature until a 2nd cross-repo consumer needs it — so a conscious "watch,
    trigger = 2nd consumer" note would satisfy it. P4 is the *inverse* (harness summonable as a server), not
    this; currently neither built nor explicitly deferred.

15. **Evaluable pass/fail output contract on every skill gate** — *ramp-inspect-agent* (Move 4, cross-cutting).
    *Failure mode:* skills that "run and produce prose" with no machine-checkable verdict mean a scheduled
    review agent / fleet operator can't triage by pass/fail. Only `/cr` tiers + the C10 bundle emit verdicts.

16. **Process-vs-knowledge skill-authoring gate** — *packmind* (Move 4, NEW small). Classify each new skill
    process-vs-knowledge; for knowledge-skills require a "does the model already infer this?" check.
    *Failure mode:* a knowledge-skill narrating judgment the model already has is a ghost rule that drifts and
    dilutes. P6 frontmatter is the natural home; the authoring gate is not specified.

17. **Deterministic validation gates *between* probabilistic passes + chain-reliability measurement** —
    *when-is-llm-call-worth-it* (Move 3, partial). *Failure mode:* a 9-pass / 23-agent chain silently lowers
    end-to-end reliability (0.9ⁿ) while reporting success, with no deterministic checkpoint between steps.
    CMP3 measures *outcomes* (cycle-count, first-pass-approval) but not per-pass agreement or between-pass gates.

18. **Fallback/abstention contract per reasoning pass + `/queue` liveness check** — *when-is-llm-call-worth-it*
    (Move 4). *Failure mode:* a pass returns garbage / an agent silently dies and the pipeline proceeds as if
    it succeeded (the generalized "background agents fail silently" hazard). F7 bounds the *retry loop* and
    REJECT state; the *per-pass abstention/confidence field + dead-agent liveness signal* is not built.

19. **Temporal-gap rule as an *enforced* invariant** — *loop-engineering* (Move 2, elevated from audit-hygiene
    to enforcement). A CI/lint check that fails when a ritual is declared in `rituals.md` with no scheduled
    trigger. *Failure mode:* the harness silently regresses into documented-but-inert "scheduled" rituals (the
    map's "overwhelmingly advisory" verdict). L4 builds the scheduler; the *enforced* "no committed ritual
    without a clock" check is not present.

---

## Conscious cuts / gates (traceable, NOT silent — listed for completeness)

- **Outcome-keyed retro / IMPACT-LOG store** — *leland-eight-principles* (single-biggest move, ELEVATE-now).
  The re-mine argued hard for in-scope-now ("the reward channel for the entire autonomy program"). VISION
  **consciously GATES** it: STILL-GATED "outcome/impact tracking (≥N autonomous PRs/week)" (VISION line 726),
  and CMP3 explicitly carves day-0-measurable fields IN while keeping first-pass-approval/post-merge-defect/
  outcome P1-volume-gated. *This is a real charter tension the design owner should ratify:* the re-mine says
  the store works with a placeholder definition on day 0 and is infrastructure not a product metric; VISION
  treats outcome tracking as volume-gated. It is *traceable and conscious* (not a drop) — but it is the one
  place a strong ELEVATE was overruled into a GATE, and worth a confirm rather than silent acceptance.

## Partial landings (the move is present but its distinctive half is thin)

- **Kill-filter / autonomous-vs-human admission routing** — *vercel-agentic-infra* (Move 2). L1's
  "name which downstream path each trigger takes" + blast-radius classifier + LOOP-7 LOW/MEDIUM/HIGH cover
  *risk* routing. The re-mine's distinctive ask — an explicit *verifiable-correct-output* admission test that
  routes a task whose "done" can't be stated to a human queue *before* autonomous execution — is not built out.

---

## Un-sourced design additions (design items that trace to NO re-mine/ground-truth row)

**None found.** Every move-ID in VISION carries a `*Citation:*` to a CANONICAL-HARNESS-AS-IS §N row or a
confirmed absence, plus an elevating re-mine. The roster's NEW skills/hooks were each verified absent on disk
(no phantom rebuilds — the roster-check confirms this and it re-verifies clean here). HOOK-1, L6, and L7 are
the three moves whose provenance is *internal* (a proportionality-check framing restore, a coherence-check
carry-forward alert, and Tanner's mid-run design input respectively) rather than a single corpus source — all
three are explicitly attributed in VISION, so they are sourced, just not to the 18 slugs in this sweep's scope.

---

## Status

Sweep complete over all 18 assigned slugs. **19 silent DROPPED items** (13 primary + 6 secondary),
**1 conscious GATE worth ratifying** (the retro store), **1 partial landing**, **0 un-sourced additions**.
The WF4 per-artifact checks did not surface any of these — they audited internal consistency, not
research→design coverage. Drops #1–#2 (branch-registry guard, main-branch hard-block) are the most urgent:
they are P0-floor-class deterministic guards, verified absent on disk this session, that leave the FLOOR
pillar incomplete despite the design claiming the floor is the safety substrate the whole autonomy program
rides on.
