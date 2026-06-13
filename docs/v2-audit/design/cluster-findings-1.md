# Cluster Findings 1 — Org-scale / case studies / distribution

**Cluster:** Org-scale / case studies / distribution
**Articles (9):** shopify-ai-first, ramp-inspect-agent, stripe-minions-kaliski,
agentic-platform-eng-saul, vercel-agentic-infra, linear-context-execution, ashby,
notion-spec-driven, 37signals-dhh
**Source pass:** each article's `pass3-apply.md` (built on `pass2-penetrate.md`), mapped against
`CANONICAL-HARNESS-AS-IS.md` (cited as `[GT §X]`).

**Governing rule applied:** every realGap cites a ground-truth section or a confirmed absence.
Any "gap" that ground-truth shows is already built was moved to `alreadyDo`. The dedup collapses
the same gap raised by multiple articles into one entry listing all sources. Prefer few, well-cited
gaps. Most pass-3s concluded "synthesize, don't re-research" — `freshResearchWarranted` is held to
the genuine, bounded capability checks only.

---

## 1. Real gaps (deduplicated across the cluster)

### G1. The Stop/PostToolUse hook layer does not exist — the missing home for verification, memory-capture, render-gating, and pace-discipline
**Citation:** `session-end.sh (Stop → memory candidates)` is **canon-declared, ABSENT on disk**;
"disk's memory is fully manual" `[GT §3e, §5]`. No PostToolUse/Stop interceptor exists anywhere in
the hook inventory `[GT §3e]`.
**Sources:** shopify (b1/b3 — session-end review artifact), ramp (b — machine-enforced
self-verification needs a Stop/PostToolUse hook), vercel (b5 — memory-capture is the absent
`session-end.sh`), 37signals (b2 — pace/commitment stopping signal would live here), linear (b1
intersects — promotion-ladder automation).
**The dedup insight:** five articles independently reach for the *same one missing mechanism* for
four different payloads (a session-end review/handoff artifact, a verification assertion, a
memory-candidate proposer, an explicit stopping signal). V2 should build **one** Stop/PostToolUse
hook surface and treat these as payloads on it — not four features. Scope it to its highest-leverage
job first (machine-enforced verification, see G2); memory-capture and review-handoff are additional
emitters on the same hook.

### G2. The enforcement floor is overwhelmingly advisory — no deterministic backstop converts "required in prose" into a gate at task-completion
**Citation:** "Both agree the system is overwhelmingly advisory… neither has a deterministic backstop
for the bulk of skill bodies, CLAUDE.md rules, or the autoMode lists" `[GT §3e Net enforcement
picture]`. Pre-commit/pre-push gates fire at commit/push, never at the moment a subtask is reported
done `[GT §3e]`.
**Sources:** ramp (b — machine-enforced self-verification gate, its headline; scope to
*regression-trust only*, keep the human semantic checkpoint), stripe (b2 — label every pipeline step
D/A/G and convert should-be-D-but-advisory steps into real gates), agentic-platform (corroborates the
advisory finding), notion-spec (b — our gate validates a `.cr-ok` *sentinel*, not *behavior*; the
sentinel certifies "review ran," not "feature behaves as specified"), vercel (b1 — every gate is
code-shape, never live consequence).
**The dedup insight:** this is the cluster's center of gravity. The concrete action is a
classification + conversion exercise: label each pipeline step Deterministic / Agentic / Guardrail,
attach a one-line failure mode to each should-be-D step (G5), and move the should-be-D-but-advisory
ones onto the Stop/PostToolUse surface (G1). **Constraint carried from sources:** the verification
gate buys *regression-trust, not correctness-trust* (ramp); it must NOT write `.cr-ok` or become a
capability unlock (notion-spec + `[GT §9]`); the human semantic checkpoint stays.

### G3. No numeric retry ceiling with a defined human-handoff anywhere in the floor
**Citation:** the deterministic floor is entirely pre-commit/pre-push correctness gates; the `/cr`
auto-fix loop is "Opus auto-fix" with **no stated attempt ceiling and no REJECT/handoff tier**
`[GT §3c: "No REJECT tier, no UNATTENDED branching"; §3e, §5]`. Confirmed absence of any
retry-counter hook or contract rule.
**Sources:** stripe (b1 — the 2-retry rule, its best-reasoned free-to-adopt mechanism; exists to
protect the review gate), agentic-platform (b2 — "single most valuable, model-independent
contribution," highest-value gap).
**The dedup insight:** the cheap version is a tier-1 contract rule (words in `@task-runner` /
agent-contract); the enforced version is a counter on the Stop/PostToolUse surface (G1). **Caveat
from sources:** verify existing STOP-AND-SURFACE wording doesn't already imply one-retry-then-stop
before adding redundant text (stripe's own open question + memory
`feedback_hypothesis_before_speculative_build`). The *number* is the one model-dependent question
worth a bounded check (see freshResearchWarranted F1).

### G4. No visual / rendered-output verification gate — Chrome MCP capability exists but nothing wires it in, and a render failure leaves no signal
**Citation:** the hook inventory `[GT §3e]` and CI `[GT §3f]` contain nothing that verifies rendered
output — every gate is tsc/lint/vitest/build (code-shape). Chrome MCP exists in the tool surface but
**no hook, skill rule, or agent contract requires a visual artifact for a UI change** `[GT §3e, §3a]`.
The canon keeps "the manual-QA coverage blocker" on its never-remove list `[GT §9]` so the *principle*
is sanctioned but the *enforcement* is unbuilt.
**Sources:** vercel (b1/b2 — render-gate absent; the global config lists only the `notion` MCP, so the
browser MCP is also undeclared in canon/disk inventory `[GT §2]`), ramp (b — real-interface visual
verification built but un-systematized; the cheap, solo-transferable half), ashby (b1 — refined: the
public `/p/[token]` page HAS an `error.tsx` boundary that *renders* a fallback but **nothing records
the failure** — the precise gap is no failure-logging, not "nothing watching").
**The dedup insight:** two distinct sub-gaps that the articles converge on as one verification axis —
(a) a *pre-merge* "agent confirms the changed view renders" screenshot gate (the cheap, solo-doable
half), and (b) a *runtime* failure-logging signal behind the error boundary (ashby's category gap).
(a) belongs on the Stop/PostToolUse surface; (b) is a small Supabase error-log table + optional
feature-flag column (ashby explicitly: no observability vendor, build-what's-needed-now).

### G5. No failure-mode test applied to existing constraints — the §9 Model Capacity Audit is pre-authorized but uncompleted, and is now due against Opus 4.8
**Citation:** `[GT §9]` reproduces Page-13's golden rule ("If you can't name a failure mode that the
constraint prevents, the constraint is overhead") and its keep/replace table; the judgments were made
against **Sonnet 4.6** and "re-audit due on model update → now Opus 4.8" `[GT §9, §0 headline]`. The
re-audit is an open, pre-authorized cut with no completed pass.
**Sources:** stripe (b3 — independently re-derives the golden rule; adopt "name-the-failure-mode" as
the demotion criterion for the re-audit), agentic-platform (c — flags the article's "better = more
elaborate" bias and points at `[GT §9]` as the opposite, correct direction), 37signals (a/b — already
distinguishes keep-vs-remove friction by failure mode via `[GT §9]`).
**The dedup insight:** this is not a net-new feature — it is the trigger + criterion for running the
already-owed §9 re-audit on Opus 4.8. Every step labeled D in G2 must carry a one-line failure mode or
be demoted. This gap is the *method* that disciplines G1–G4 so V2 doesn't add scaffold the current
model no longer needs.

### G6. No machine-readable skill manifest / registry — skill inventory is prose-only and actively drifting
**Citation:** skills inventoried only in prose (canon ~46 vs disk 26, reconciled by hand) with active
drift: `/dev` and `/explain` exist on disk but in **no** canon page; `dep-update` documented but an
empty stub; `/cr-feature` retired in canon yet still referenced `[GT §3b, §6]`. `skills-lock.json` is
a **confirmed phantom** (referenced, never built) `[GT §6]`.
**Sources:** agentic-platform (b3 — a manifest would mechanically catch exactly this drift; genuinely
unbuilt, not merely undocumented).
**The dedup insight:** single-source but cleanly cited against a confirmed phantom and documented
drift. Low-cost, high-clarity: a `library.yaml`-style manifest is the mechanical fix for the
canon-vs-disk reconciliation the map currently does by hand.

### G7. No cross-project / installable harness — the cluster's case studies all assume an org-scale install the harness does not have
**Citation:** the map's headline: the harness "has **never been installed anywhere but
event-vendor**; 'multi-project' is a goal, not a state"; recyclops/logistics-service carry no harness;
there is **no global `~/.claude/CLAUDE.md`** `[GT §0, §2, §8; canon To-Think-About #20/#22]`.
**Sources:** agentic-platform (b4 — the "three-repo brain" / `agent-library` + `agent-setup`
separation is one concrete answer to this exact V2-central gap). Ramp (a) and stripe (d) corroborate
the framing (we are the off-the-shelf buyer; our real direction is "global, GitHub-hosted,
bidirectional self-update — an *installability* question").
**The dedup insight:** this is the V2-central structural fact, surfaced most directly by
agentic-platform. **Carried constraint:** adopt the **versioned-copy-with-lock** variant, NOT the
symlink-live variant the article prefers, or we recreate the canon's own unresolved install-method
contradiction `[GT §7.8]`; scoping ≠ repo-separation (the in-repo scoping value is capturable without
repo surgery, agentic-platform c).

### G8. No per-feature behavioral-contract layer with a Verification section
**Citation:** the governance/context inventory `[GT §3a]` lists project-level docs
(CLAUDE/CONTEXT/AGENTS/SOUL/ARCHITECTURE/TESTING/STRATEGY) and the memory model `[GT §4]` lists
memory.md/RECURRING-FINDINGS/PITFALLS/docs/solutions/docs/adr — **none is a per-feature spec answering
"what this feature IS and how to verify it still does that."** ADRs capture decisions, solutions
capture patterns, PITFALLS capture traps; the feature-lifetime behavioral contract is a confirmed
structural absence.
**Sources:** notion-spec (b — its single most transferable, tool-agnostic idea), linear (b1 — the
"skill rung" / promotion ladder dead-ends at PITFALLS, the adjacent missing layer above per-task
memory).
**The dedup insight:** two articles name a missing layer above the existing doc/memory stores —
notion-spec wants a per-feature *behavioral contract*; linear wants a *skill rung* that promotes a
repeated multi-step workflow into a named skill. Related but distinct: one is a per-feature artifact,
the other is a promotion mechanism. **Carried constraints:** (a) sequence the verification harness
*after* the spec layer (notion-spec); (b) the spec layer must ship with an independent review pass
from day one — do NOT copy Notion's implementer-self-verification (notion-spec c); (c) any skill rung
must ship a *retirement rule* or it imports the ghost-rule liability `[GT §9]` (linear c).

### G9. No PII-handling rule for real client data
**Citation:** grep of CLAUDE.md finds no `PII` / `synthetic` / `fixture` rule. `[GT §3a/§3e]` document
credential/Tier-0 guards (prod-key firewall, `worktree-create.sh`) but **no rule governs real client
PII** (names, emails, event details) entering test fixtures or agent context. A genuine §6-style disk
gap, not a canon item.
**Sources:** ashby (b2 — the one axis where we are ahead on credentials but the symmetric data-class is
uncovered).
**The dedup insight:** single-source, cheap to close (a CLAUDE.md rule + a fixture grep). Included
because it is a clean confirmed absence in a real-client product ($30k proposals) and complements the
existing credential firewall.

### G10. Governance gaps the cluster names but that are doc/coherence work, not new features
Grouped because each is single-source, cleanly cited, and small:
- **Accountability rationale unnamed** — the destructive-op/merge gate is enforced but no file states
  *why* it is permanent (distinct from deletable capability gates); `[GT §9]` is about to prune
  STOP-AND-SURFACE breadth without that distinction written down. Source: linear (b2). Citation:
  `[GT §9 "STOP-AND-SURFACE breadth → narrow"; absent: no accountability-rationale doc in §3a]`.
- **Blast-radius tier unnamed** — the mechanisms exist but "blast radius" appears once, incidentally,
  in `AI-WORKFLOW.md`; not a classification an agent must declare before choosing autonomy. Source:
  ashby (b3). Citation: `[GT §3b + disk AI-WORKFLOW.md]`.
- **No workflow-level "rejected approaches" log** — AGENTS.md "Rejected Patterns" is a code/architecture
  table; there is no record of *failed agent/workflow experiments*. Should *extend* the existing
  section, not fork it. Source: ashby (b4). Citation: `[GT §6 / AGENTS.md]`.
- **Task surface is fragmented** — TASKS.md / TASK-TEMPLATE / AGENTS.md open-decisions / per-session
  description are several partial task objects, not one canonical typed object (AGENTS.md "None open"
  contradiction). Source: linear (b4). Citation: `[GT §3a AGENTS.md contradiction; §5]`. Defer to the
  AGENTS.md cleanup already on the map.

---

## 2. Already do (anti-phantom — do not re-propose)

1. **Parallel-agent execution + per-task isolation** — worktrees (`worktree-add.sh`/`worktree-create.sh`)
   + `/queue` batches + the **Tier-0 prod-key firewall** (`gen-local-env.sh`, `test-local.sh`), called
   "a genuine disk advance over canon" `[GT §3e, §6]`. (shopify a2, stripe a3, agentic-platform a7,
   notion-spec a). Note: this is *credential* isolation, not *environment* (no devbox/disposable
   compute) — that narrower gap is real (agentic-platform b5) but the parallel+isolation capability is
   built.
2. **Human review as the hard gate / no autonomous-merge path** — `/cr` (9-pass + adversarial) +
   `/cr-security`, `.cr-ok` sentinel consumed by `pr.sh`, pre-push validates it `[GT §3c, §3e, §3f]`.
   (shopify a4, ramp a, stripe a4, agentic-platform a, linear a, notion-spec a).
3. **Adversarial / abuse-case review exists** — `@reviewer` 4 lenses (assumption/composition/cascade/
   abuse), `/cr` final adversarial pass, `/cr-security` `[GT §3c, §3d]`. (shopify a3, notion-spec a).
   *Caveat:* it attacks *code*, not a *spec*; and it is named-pattern checking, not
   generative-adversarial exploit construction (shopify b4, partial gap — narrow, not empty).
4. **The comprehension-debt / discipline rule + Q3/Q4 kill-filter** — the 3-question pre-commit
   checkpoint and `/grill-with-docs` Phase-1 three-human-questions, marked **keep verbatim** `[GT §9]`;
   "define inputs/outputs/what-it-must-NOT-do/done-looks-like" in CLAUDE.md. (shopify a1, vercel a1/a2,
   linear a). Ours is *stronger* than the article norms.
5. **Destructive-op / accountability gate (PocketOS rules)** — kept verbatim, never-remove `[GT §9]`.
   (vercel a2, linear a, notion-spec c). This IS the article's "human owns the irreversible act."
6. **Skills-as-version-controlled-files, invoked explicitly (never auto-loaded)** — ~26 project skill
   dirs `[GT §3b]`; the "skill not agent" direction is already our default. (ramp a, agentic-platform
   a, 37signals a, vercel a). The "hundreds→one" pivot is a direction we're already closer to than
   Ramp's *old* state.
7. **Upstream skill packs already installed** — 15 Matt-Pocock/Supabase/Vercel skills symlinked at
   `~/.agents/skills/` via `mattpocock/skills` `[GT §1, §2]`. (vercel a — skills.sh "install best-practice
   packs" is already done in spirit). *Caveat:* this is an ungoverned trust boundary (vercel b4) — see
   freshResearchWarranted.
8. **Context/"Brain" docs exist** — CLAUDE/AGENTS/CONTEXT/SOUL/ARCHITECTURE/INDEX/AI-WORKFLOW all present
   `[GT §3a]`. (agentic-platform a, linear a, notion-spec a). The *content* exists; cumulative
   directory-scoped *loading* does not (agentic-platform b1 — a real but token/clarity-only gap, partly
   pre-authorized to shrink by `[GT §9]`).
9. **Defense-in-depth deterministic verification (at commit/push)** — pre-commit (ESLint+tsc+vitest),
   pre-push (integration + `next build` + `.cr-ok`), CI `ci.yml`+`integration.yml` `[GT §3e, §3f]`.
   (ashby a, stripe a, notion-spec a). Denser than the case-study stacks. The gap is *timing*
   (task-completion vs commit/push) and *axis* (code-shape vs render/behavior), not absence.
10. **Tool-surface permission gating** — `permissions.allow` / `additionalDirectories`, the bash/git/npm
    guard hooks, the UNATTENDED firewall `[GT §2, §3e, §6]`. (37signals a, stripe a). *Ahead* of the
    article frames on the permission axis.
11. **Selective-friction doctrine + the §9 golden rule** — "if you can't name a failure mode the
    constraint prevents, it's overhead" + explicit Keep list `[GT §9]`. (37signals a, shopify, stripe
    b3). We already distinguish keep-vs-remove friction by failure mode.
12. **Promotion ladder exists in prose** — session→memory.md; pipeline→RECURRING-FINDINGS→PITFALLS;
    docs/solutions; `/compound` Step 7 stale-review `[GT §4]`. (linear a). The gap is the missing *skill
    rung* (G8), not the ladder.
13. **Typed task object with scope enforcement (canon-declared)** — TASK-TEMPLATE `## ALLOWED FILES` +
    `enforce-scope.sh` `[GT §5, §3e]`. (linear a). *Caveat:* `enforce-scope.sh` is canon-declared but
    **absent on disk** — so the template exists in spec; the structural guard does not (feeds G2).
14. **Blueprint pattern (deterministic + agentic), structurally present** — `/feature` pipeline =
    deterministic hooks + agentic `/dev`/`/tdd`/`/cr` nodes `[GT §3e, §3f, §3c]`. (stripe a1). We lack
    the *labeling* (G2/G5), not the structure.

---

## 3. Reject as literal (article advice that is wrong for us if taken at face value)

1. **"Demo velocity" as an AFK metric** (shopify) — *Why wrong:* the metric resists Goodharting only
   because an audience depends on the output. Solo, there is no audience; it prevents no failure mode,
   so by `[GT §9]`'s golden rule it is pure overhead. Reject as instrumentation; at most a framing note.
2. **Import the 80%-self-written / 1,300-PRs-week / 60%-of-PRs / "hundreds of days saved" figures as
   evidence** (ramp, stripe, linear, vercel) — *Why wrong:* each is vendor-self-report or a numerator
   without a denominator (PRs opened ≠ merged-clean; 80% is Modal-vendor-sourced, ZenML-disowned; 60%
   ignores abandonment/rework). They fail our fact-vs-opinion bar. Import the *mechanism*, never the
   *rate*.
3. **"Computer-use yourself" / drive the finished frontend as a user** (ramp) — *Why wrong:* assumes a
   finished frontend; ours is the thing under construction. Anti-applicable pre-MVP, and for a
   finance-style irreversible-mutation surface the safe envelope is narrow and unstated. The *narrow*
   transferable half (screenshot a UI slice) survives as G4.
4. **"Collapse the 23 agents into skills" / "hundreds→one" pivot** (ramp, "skill not agent") — *Why
   wrong:* the overhead argument is a *threshold* claim (real at hundreds) sold as universal; at our
   ~8–23 roster specialists are clarity, and `[GT §9]` keeps reasoning-discipline. The real gap is
   taxonomy reconciliation (one canonical agent count, `[GT §3d, §7.6]`), not an architecture pivot.
5. **Drive activation energy toward a low-friction (Slack-emoji) trigger** (stripe) — *Why wrong:* with
   one human review gate, cheaper activation just loads the single scarce reviewer `[GT §0, §8]`. The
   actionable inverse is review-load management, not trigger-friction reduction.
6. **Symlink-live "install everywhere" for a shared harness** (agentic-platform, plus Quick-Start) —
   *Why wrong:* symlinks resolve to HEAD, not a validated SHA, contradicting reproducible DR and
   recreating the canon's own install-method contradiction `[GT §7.8]`. Use versioned-copy-with-lock.
7. **Wire `/post-mortem` and `/incident` to *auto-append* durable rules to memory.md** (ashby) — *Why
   wrong:* `/post-mortem/SKILL.md` already writes memory.md/PITFALLS candidates **only on human
   approval**; auto-appending removes a deliberate human gate and runs against `[GT §9]` keep-verbatim.
   The real (small) gap is only that the loop isn't *triggered as a final step*, not that it should go
   unattended.
8. **Build CLI-first for any recurring admin op** (37signals) — *Why wrong:* prices a CLI at zero; a CLI
   is a second tested/versioned/documented interface, and our "no shared abstraction until the third
   occurrence" rule cuts against reflexive CLI-building. The article also ignores MCP entirely, which is
   often the better, per-call-permissioned fit `[GT §2]`.
9. **Adopt spec-first with the implementer authoring its own Verification section** (notion-spec) — *Why
   wrong:* the oracle's author is the implementer — a test-design violation. If we build the spec layer
   (G8) it must ship an independent review pass from day one; do not copy Notion's self-verification.
10. **Treat `.cr-ok` as a capability gate / correctness signal** (notion-spec exposes; also a §9 cut) —
    *Why wrong:* `.cr-ok` certifies "review ran," not "feature behaves." `[GT §9]` already pre-authorizes
    re-typing it as a *readiness signal, not a capability unlock*. Do not build new gates that write or
    depend on it as proof of correctness.

---

## 4. Cross-themes (patterns recurring across the cluster)

- **CT-A. The advisory-floor problem is the cluster's spine.** Ramp, stripe, agentic-platform,
  notion-spec, vercel all land on the same `[GT §3e]` finding from different angles: the harness states
  rules in prose that nothing enforces at task-completion. Every high-value gap (G1–G5) is a facet of
  converting advisory → deterministic at the right point in the loop.
- **CT-B. One missing mechanism serves many payloads.** The absent Stop/PostToolUse hook `[GT §3e, §5]`
  is reached for independently by 5 articles for verification, memory-capture, render-gating, and
  pace-discipline. V2 builds the *surface* once.
- **CT-C. Verification must buy the right kind of trust.** Regression-trust ≠ correctness-trust (ramp);
  sentinel ≠ behavior (notion-spec); tests-pass ≠ feature-correct (ramp OQ#1, ashby). Any gate must
  keep the human semantic checkpoint and must not masquerade as a correctness unlock.
- **CT-D. The cluster independently re-derives our own §9 golden rule.** Stripe, 37signals, and the
  Model Capacity Audit converge on "name a failure mode or it's overhead." This makes the owed Opus-4.8
  §9 re-audit (G5) the disciplining method for everything else, and a guard against the articles' shared
  "better = more elaborate" bias (agentic-platform c).
- **CT-E. "Better = more scaffold" is the recurring article bias; our map points the opposite way.**
  Several case studies celebrate elaborateness; `[GT §9]` pre-authorizes cuts. Treat every "add a
  layer" recommendation as a candidate scaffold to test against the failure-mode rule before building.
- **CT-F. Org-scale mechanisms invert or evaporate at solo scale.** Demo velocity, activation-energy
  reduction, fleet-CI-as-throughput, cross-team triage — each is load-bearing on org context (an
  audience, many reviewers, a running fleet) we don't have. The transferable residue is consistently
  *smaller* than each article's candidate list, and usually resolves to a framing note or "already
  covered." The single binding solo constraint the cluster surfaces is **one human's review
  throughput** `[GT §0, §8]`.
- **CT-G. The case studies all assume the org-scale install we don't have.** The biggest structural fact
  (G7 — never installed beyond event-vendor) is the precondition the distribution/case-study framing
  silently assumes; V2's installability work is the response.

---

## 5. Fresh research warranted (strict — most pass-3s said synthesize, not re-research)

Only items the corpus + ground-truth genuinely cannot answer, each bounded to a "how does this
capability work" check (not deep research), and each gated on a build decision:

1. **Retry-value decay on Opus-class models (the "max-N" number).** The only *empirical, model-dependent*
   question in the cluster: before encoding a fixed retry ceiling (G3) into `/cr` auto-fix / debug /
   refactor loops, a short verification pass on current evidence for diminishing returns on retries —
   Stripe's "2" was tuned on their stack, not ours, and the number is model-specific. Raised by
   agentic-platform (d, "the only place re-research beats synthesis") and stripe (b1). Bounded; gated on
   G3 being greenlit.
2. **What a Claude Code Stop / PostToolUse hook can actually intercept and block at task-completion.**
   Make-or-break for G1/G2: can a hook (a) see "subtask marked done," (b) run `pnpm test`/`typecheck`,
   (c) block on red, (d) require a screenshot artifact for a UI diff — *without* writing `.cr-ok`?
   Check the harness hook/`claude-api` docs, NOT the case-study corpus. Raised by ramp (d1). Bounded;
   gated on G1/G2.
3. **Chrome MCP screenshot capture in an unattended/worktree run.** For the cheap half of G4: confirm
   Chrome MCP works headless in an UNATTENDED worktree `[GT §3e]` and that browser-tool calls are in
   `permissions.allow` for background agents (memory: background agents fail silently on
   un-allowlisted calls). Raised by ramp (d2), vercel (d). Bounded; gated on G4(a).
4. **Skill-package provenance / pinning policy (one-pass).** For the ungoverned-skill-trust boundary we
   already straddle (alreadyDo #7; vercel b4): a single-pass scan of how agent-skill package managers
   (skills.sh, Anthropic's plugin marketplace we already use) handle signing/pinning, to set an internal
   pin-with-review policy. Raised by vercel (d). Bounded; gated on touching the skill-install path.

**Explicitly NOT warranted (synthesize/decide instead):** the three-repo architecture / symlink-vs-copy
(map already settles it via §0/§2/§8 + §7.8); devbox isolation as a concept (confirmed gap, an
implementation spike not research); session-bound-execution / Vercel Workflows (horizon architecture
decision); spec-layer design (Phase-3/5 decision against §3a/§4); the linear Design Challenge (an
*internal* probe — audit five `/compound` sessions, not external research); fork-vs-build for the agent
runtime (a build-plan decision, not a research gap); machine-payment / agent-as-economic-actor
(horizon watch-item, no map row).
