# Cluster Findings 2 — "Compound / loop / verification doctrine"

**Aggregator output.** Consolidates the pass-3 "apply vs our harness" analyses for 9 articles into one
deduplicated, citation-anchored gap list. Governing rule honored: **every realGap cites a
`CANONICAL-HARNESS-AS-IS.md` section (`[map §N]`) or a confirmed absence.** Any "gap" that is actually
already built is demoted to `alreadyDo`.

Articles in cluster: `12-factor-agents`, `loop-engineering`, `goal-loop-primitive`,
`recursive-self-improvement`, `every-compound-lfg`, `when-is-llm-call-worth-it`, `leland-eight-principles`,
`engineering-rigour-small-team`, `ai-pilling-team-of-one`.

---

## 1. Real gaps (deduplicated across the cluster)

### G1 — The terminal stop authority is forgeable: `.cr-ok` → CI is not wired (Node 8.5c)
**The most-cited gap in the cluster — four articles converge on it.** `/cr`'s MUST-FIX tiers are
model-computed `[map §3c]`; the `.cr-ok` sentinel is consumed only by the local pre-push hook and **CI
never verifies it** — "gitignored, never reaches CI" `[map §3f, Node 8.5c]`. So a loop's stop condition
(`MUST-FIX=0` → write `.cr-ok` → push) can be satisfied by *model self-agreement* with no independent
oracle re-check that CI is green on the sentinel'd SHA. recursive-self-improvement names this *authority
laundering*; goal-loop calls it the false "unforgeable gate" premise. Fix: stop authority must be
**MUST-FIX=0 AND CI-required-checks-green on the sentinel SHA**, enforced in CI/branch-protection where it
cannot be forged — not in the skill body. (Qualifier from recursive-self-improvement: this makes the gate
*coverage-bounded less forgeable*, not *un*forgeable.)
- **Sources:** goal-loop-primitive (b2 — its single most important finding), recursive-self-improvement
  (R-1), ai-pilling-team-of-one (b2), when-is-llm-call-worth-it (c — "oversells CI-green as oracle").
- **Citation:** `[map §3f Node 8.5(c)]`, `[map §3c]`.

### G2 — No scheduler / heartbeat: rituals have no clock
The ritual layer (`.claude/rituals.md`) fires **only at session start**, via a CLAUDE.md line asking the
*model* to check `last_run` against `frequency` — it runs only when a human starts a session and only if
the model remembers. There is no cron, no scheduled-tasks config, no always-on trigger on disk. This is
the *temporal* edge a static file-inventory audit structurally cannot surface. The canon's own
`session-end.sh` is absent `[map §3e, §5]` and the map's verdict is "overwhelmingly advisory… no
deterministic backstop" `[map §3e]` — loop-engineering sharpens that to: our rituals lack not just a hook
but a **clock**. NOTE: the deferred-tool surface in this very environment exposes `CronCreate`/`CronList`
+ a `/schedule`/`/loop` skill, so the substrate exists; the open item is a 15-min durability spike (does
it fire when the dev's machine is asleep, or does it need an always-on host / CI schedule?).
- **Sources:** loop-engineering (Gap 1 — its bullseye; also re-bundles permission-logger aggregation,
  phantom triage inputs, unwired morning-review around the heartbeat theme).
- **Citation:** `[map §3e Net enforcement picture]`, `[map §5 session-end.sh]`.

### G3 — No eval / golden-set / recall measurement for `/cr` and the harness's probabilistic output
The harness is now itself probabilistic (multi-pass `/cr`, 4 adversarial lenses, `/queue` batches) but CI
runs tsc/lint/vitest only `[map §3f]` — it never evaluates whether `/cr` still *catches what it used to
catch* after a model swap. **Confirmed absence:** no `/cr` recall / defect-detection measurement anywhere
in the corpus or ground-truth files; no eval-in-CI store (`evaluate-solution` is a solution-quality skill,
not an LLM-regression eval). The build item is *continuous recall measurement of the reviewer* (a golden
set calibrating a moving target: passes × merge-rule × model × diff-distribution), not a one-time score —
and it is **triage calibration, never a path to letting `/cr` self-certify**. Seed the golden set with
adversarial/known-defective diffs, not just friendly historical ones, or it inherits warm-signal bias.
This is the direct regression backstop the §9 Model Capacity re-audit (Sonnet 4.6 → Opus 4.8) currently
lacks — §9 schedules a *manual* one-time human pass, names no automated probe.
- **Sources:** recursive-self-improvement (R-2, R-4, R-5 freshness-of-calibration), when-is-llm-call-worth-it
  (b1 sharpest contribution, b2 the §9 re-audit has no regression backstop).
- **Citation:** confirmed absence in `[map §3f]` (CI), `[map §3b]` (skills), `[map §9]` (re-audit is manual).

### G4 — State / memory is not unified: triple-duplication the canon "both sanctions and forbids"
The same corrected-mistake fact lives simultaneously in `.claude/memory.md` + `PITFALLS.md` + auto-memory
`feedback_*` files, with `/compound` itself flagging memory entries as "already covered by PITFALLS
(redundant)." The reconciliation ("same knowledge at different lifecycle stages") exists "only in prose,
encoded in no tooling" `[map §4]`. The auto-memory store (`MEMORY.md` + 51 siblings) is "a sixth store the
canon's model doesn't account for" `[map §4, §6]` — a literal second state system outside the canonical
one. This is 12-factor's F5 ("two/three state systems you spend your life keeping in sync") and the
strongest factor-to-row mapping that article makes. The Phase-3 target (already stated in `[map §4]`): one
model that accounts for auto-memory, encodes the lifecycle reconciliation in tooling not prose, gives every
store one writer / one reader / one freshness rule, and collapses the duplication.
- **Sources:** 12-factor-agents (F5), loop-engineering (re-curation load from duplication), leland-eight-
  principles (P8 adaptation-speed gap, which resolves to absent `session-end.sh`).
- **Citation:** `[map §4]`, `[map §6 Auto-memory]`.

### G5 — Context has no machine-enforced doc-authority / freshness level ("the Doctrine layer")
Our context bag mixes authority levels with no tooling to separate them: the audit artifact itself rots
(`HARNESS-AS-IS.md` carries stale absence-claims) `[map §0 Correction log]`; `AGENTS.md` has a "None open"
contradiction `[map §3a]`; PITFALLS/memory are assigned to *both* Layer 1 and Layer 3 depending on the page;
**read-time is specified for only ~5 of ~14 knowledge files and freshness rules exist for only 3 stores**
`[map §4 admitted ambiguities]`. 12-factor's F3 ("context ordering/authority *is* the product") and
engineering-rigour's "fourth G = Doctrine" (the Guides/Gates/Guards frame has no slot for judgment-shaping
doctrine, confirming from the outside this is our least-governed layer) both land here. The advisory/doctrine
layer (skill bodies, CLAUDE.md rules) is the part with no deterministic owner — `[map §4]` already names
this the Phase-3 crux.
- **Sources:** 12-factor-agents (F3), engineering-rigour-small-team (b4 + the "Doctrine" fourth-G framing),
  leland-eight-principles (P8/composition lens).
- **Citation:** `[map §4]`, `[map §0 Correction log]`, `[map §3a]`.

### G6 — No global `~/.claude/CLAUDE.md` and no installable shared harness (multi-project is aspirational)
The harness has **never been installed anywhere but event-vendor** `[map §8]`; the global layer has no
global CLAUDE.md, no global agents/hooks/commands `[map §2]`; `~/.claude/CLAUDE.md` is "the global layer's
missing keystone," canon-mandated and absent `[map §3a, §5]`. The canon backlog's "GitHub Publishing — next
gate: 3 real installs" and "apply engineering system to Recyclops" are both unmet `[map §8]`. ai-pilling
independently re-derives "one centralized rules system" as the readiness keystone — which is exactly this
absent file. 12-factor's F11 (trigger-from-anywhere) is correctly re-scoped as *downstream* of this: there
is no installable shared harness to trigger, so multi-surface triggers are blocked on the install gap, not a
standalone plumbing task. leland's P5 (build-in-the-open) maps to the same central structural fact and is
*under*-rated by the article ("wait 30 days") — the map makes it a present-tense V2 driver.
- **Sources:** ai-pilling-team-of-one (b1 — its most useful contribution), leland-eight-principles (P5),
  12-factor-agents (F11 — re-scoped as downstream of the install gap).
- **Citation:** `[map §8]`, `[map §2]`, `[map §3a / §5 ~/.claude/CLAUDE.md]`.

### G7 — `/cr` output conflates "how bad" with "who acts" — no orthogonal routing field
`/cr`'s tiers (MUST FIX / NEEDS HUMAN / SUGGESTION) `[map §3c]` mix a severity scale with a routing concept
smuggled into NEEDS HUMAN, but there is no clean routing dimension (author / design-decision / tech-debt).
**Disciplined scope (per CLAUDE.md "build what's needed now"):** not a full 3×3 grid — the actual fix is a
two-value routing flag that splits NEEDS HUMAN into *needs-design-decision* (don't hard-block) vs.
*must-fix-now*. NOTE the premise correction: the article (every-compound) aimed this at `/cr-feature`, which
is **retired v0.85, correctly absent on disk** `[map §3b, §7.2]`; the real target is `/cr`.
- **Sources:** every-compound-lfg (b1 — its strongest applicable insight).
- **Citation:** `[map §3c]` (no REJECT tier, no routing dimension) + confirmed absence of a routing field in
  `/cr` resolution.

### G8 — Failure modes have no deterministic guard: cross-skill reference breaks + skill-cache staleness
The enforcement floor is "overwhelmingly advisory… no deterministic backstop" `[map §3e]`, and two of
every-compound's seven failure modes map onto confirmed disk absences: (i) **cross-skill reference breaks** —
we *already suffer* this, with `/cr-feature` still referenced in canon's own Page-11/14 and a pile of phantom
refs (`learned-patterns.md`, `review-log.md`, `triage-inbox.md`, `/prototype-interface`, `/scan-context`)
`[map §6]`, and no reference-integrity check; (ii) **skill-cache staleness** — no session-restart /
cache-invalidation rule exists in our hooks `[map §3e]`. Both are deterministic, detectable conditions —
prime candidates for the enforcement-floor / guard work `[map §5]`. (The other five failure modes are
operational watch-items for UNATTENDED mode, not mapped absences today.)
- **Sources:** every-compound-lfg (b2). Reinforced by loop-engineering (phantom inputs `review-log.md`/
  `triage-inbox.md` block any triage loop) and engineering-rigour (`learned-patterns.md` is a phantom home).
- **Citation:** `[map §6 phantom-refs]`, confirmed absence in `[map §3e]` hook table.

### G9 — Bug-fix TDD is not enforced outside pure functions, and has no executable home
CLAUDE.md scopes failing-test-first to pure functions in `src/data`/`src/schemas`/`src/utils` only. A bug
fix to a component, a server action (`app/(app)/*/actions.ts`), or the `/p/[token]` renderer has **no
reproducing-test requirement**, and the enforcement layer is advisory with "no deterministic backstop for
the bulk of skill bodies, CLAUDE.md rules" `[map §3e]`. Two-layered gap: (i) no bug-class executable
constraint; (ii) **no executable-constraint store to put it in** — the article (engineering-rigour)
prescribes `learned-patterns.md`, which is a confirmed phantom `[map §6, §0 correction log]`. Any V2 home
must be real — a `/cr` pass addition or a new hook — not the phantom file.
- **Sources:** engineering-rigour-small-team (b1/b2).
- **Citation:** `[map §3e Net enforcement picture]` + `[map §6 phantom-refs]`.

### G10 — No path/glob classifier forcing `/cr-security` on high-blast-radius diffs
We enforce `/cr-security` on "auth, middleware, or RLS" via *prose in CLAUDE.md* — there is **no hook that
detects a diff touching those paths and forces the security pass.** The structural guard slot for this is
the absent `enforce-scope.sh` / `branch-registry-guard.sh` `[map §3e, §5]`. Without a classifier, the
"irreversible tier" decays into "scrutinize whatever felt scary" (the burnout mode it set out to prevent).
- **Sources:** engineering-rigour-small-team (b3).
- **Citation:** `[map §5]` (canon-only structural guards, not built), `[map §3e]`.

### G11 — Review-bandwidth ≥ generation-bandwidth is an unmodeled V2 invariant
Our *generation* side is rich (`/queue`, 23 agents, worktrees) but the *review* side is `/cr` (advisory,
rationalizable — memory `feedback_sentinel_bypass`) with the CI hole that never verifies the sentinel
`[map §3f]`. No row in the map establishes review throughput as a first-class, deterministically-enforced
constraint. The article (ai-pilling) supplies the design rule: raising agent output without raising review
throughput is net-negative. NOTE: the supporting "Svpino R1 / DORA" evidence is cited as **our own internal
finding**, so the owed action is locating/citing that internal artifact, not a web search.
- **Sources:** ai-pilling-team-of-one (b2). Related to G1 (the review sentinel itself is unverified) and to
  the §9 reviewer-degradation concern in G3.
- **Citation:** confirmed absence (no map row makes review throughput a first-class enforced constraint);
  `[map §3e]`, `[map §3f]`.

### G12 — Property-based testing is absent, and money-math is the textbook case
Grep for `property-based|fast-check|PBT` across the v2-audit corpus + ground-truth files returns nothing.
Testing discipline `[map §3f; CLAUDE.md → Testing]` is example-based Vitest + real-DB integration only.
**Confirmed absence.** The product is pricing/proposal math (integer-cents, tax-on-goods-only, line-item
totals) — exactly the human-authored-invariant case. PBT encodes a *human-specified, model-immutable*
correctness spec, identified as the real scarce resource. (This is one of the two genuinely-fresh-research
items — see §5.)
- **Sources:** recursive-self-improvement (R-3).
- **Citation:** confirmed absence in `[map §3f]` and CLAUDE.md → Testing.

### G13 — F9 errors-into-context + a deterministic circuit-breaker convention is absent
No error-handling-strategy hook, skill rule, or PITFALLS entry handles tool-error compaction `[map §3e
lists every hook; none handle it]`; the memory model captures *human-corrected mistakes*, not *runtime tool
failures fed back to the agent* `[map §4]`. **Better-scoped than the raw article (12-factor F9):** the
convention we lack is "errors→context **+** a deterministic max-retry / circuit-breaker in a hook" — because
F8 says the give-up decision is control flow, and our control flow lives in hooks `[map §3e]`. A naive
errors-as-context without a breaker invites unbounded retry loops. (See §5: what a Claude Code hook can
actually intercept on a failed tool call is the one genuine harness-capability question.)
- **Sources:** 12-factor-agents (F9, reconciled against F8).
- **Citation:** confirmed absence in `[map §3e]` hook inventory; `[map §4]`.

### G14 — One-agent-one-job scope discipline (F10) is uncodified; roster grew lane-depth not reuse
We have the *roster* (23 agents `[map §3d]`) but the canon's agent taxonomy is itself inconsistent ("8
specialist agents" over 9 rows; "Ten" templates over 8 roles `[map §3d, §7.6]`) and there is **no
scope-limiting design rule** in SOUL/AGENTS/CLAUDE `[map §3a]`. leland's P4 reframes this as a *reusability*
axis: growth has been lane-depth (more specialist agents — the direction Ramp moved *away* from) rather than
reuse (no project skill travels `[map §1, §8]`). This is reasoning-discipline (keep under §9), not a
capability proxy. Reframes V2's roster question: fewer specialist agents, more portable skills.
- **Sources:** 12-factor-agents (F10), leland-eight-principles (P4).
- **Citation:** `[map §3d]`, `[map §1 "None of the project skills travel"]`, `[map §8]`.

### G15 — No impact / outcome-tracking mechanism (P1)
The map inventories every context/governance doc `[map §3a]`, memory store `[map §4]`, skill `[map §3b]`,
hook `[map §3e]`, and the Model Capacity Audit `[map §9]` — **none is outcome-keyed**; no store records "did
this matter," no skill scores a shipped unit against an outcome. Confirmed absence. **Scope it as a per-unit
retro gate, not a two-sentence definition in TASKS.md** (that version is theater). The cheap version is
trivially addable (`TASKS.md` exists `[map §0]`); the load-bearing version is not. Outcome-proxy choice at
pre-revenue/solo scale is a product decision for Tanner; default to defer behind the §9 re-audit.
- **Sources:** leland-eight-principles (P1).
- **Citation:** confirmed absence — `[map §4]` has a row for every memory store, none outcome-keyed.

---

## 2. Already do (do NOT re-propose — the anti-phantom list)

- **Own prompts + control flow / decision-execution split** (F1/F2/F4/F8). Skills are version-controlled
  prompt templates; deterministic enforcement is in hooks (`block-dangerous-git.sh`, `block-npm-install.sh`
  = `exit 2` PreToolUse guards), `.husky/pre-commit` + pre-push, `pr.sh`/`gc.sh`/`worktree-add.sh`. The model
  proposes, the hook disposes. `[map §3e, §3f]`
- **The maker/checker split** — `/cr` runs 9 passes + an adversarial/`@reviewer` pass with all 4 lenses
  (assumption/composition/cascade/abuse), MUST-FIX auto-fixed by Opus. `[map §3c, §3d]` The four "Every
  adversarial techniques" = our four lenses (convergent design, NOT a gap).
- **Hard test oracle / CI exists** — `ci.yml` (tsc/lint/vitest) + `integration.yml` (real DB); pre-push runs
  all tests + `next build`; NEVER-mock-the-DB enforced. `[map §3f]`
- **`/loop` already exists** — runtime skill registers `loop` (interval poller). The article's `/loop`
  characterization matches 1:1; do NOT build `/loop`. `[runtime skill list]`
- **`/compound` exists** as a near-merge capture step. `[map §3b]`
- **Sub-agent orchestration / 23-agent roster** including review lenses, 6 spike agents, task-runner. `[map §3d]`
- **Worktrees + Tier-0 prod-key firewall** (`worktree-create.sh`, `gen-local-env.sh`, `test-local.sh`) — a
  genuine disk *advance* over canon; UNATTENDED mode + credential isolation built. `[map §3e, §6]`
- **External memory spine is over-satisfied** — six-store memory layer (`memory.md`,
  `RECURRING-FINDINGS.md`, `PITFALLS.md`, `docs/solutions/`, `docs/adr/`, + auto-memory). The gap is
  *duplication/lifecycle* (G4), not existence. `[map §4]`
- **Discover/act seam already biases to human-gated action** — `/change`, `/queue`, `/compound` curation
  are human-initiated. The article's "gate action" prescription is already our posture.
- **Ritual layer exists** — `.claude/rituals.md` (5 rituals with `last_run`/`frequency`). The gap is the
  missing clock (G2), not the layer.
- **STRATEGY.md already exists** (repo root, 1.4 KB) — Every advised building a file we shipped. `[map §3a]`
- **CONTEXT.md already exists** (15 KB, PR #92). `[map §3a]`
- **Build-the-boring-version-first / reversibility gate** — standing CLAUDE.md rule; destructive-operation
  (PocketOS) rules require explicit same-turn naming of the exact resource; the product makes **zero LLM
  calls** today (already the deterministic version). `[map §9 keep-verbatim]`
- **Risk-tiered review codified as policy** — `/cr-security` mandated when a commit "touched auth,
  middleware, or RLS"; the §9 golden rule predates the article's "name the failure mode" standing rule.
  (The *classifier* to enforce the path-based trigger is still absent — that's G10.)
- **Failing-test-first for pure functions** is already mandatory (`/tdd`). Only the bug-fix extension is open (G9).
- **Structured output as a typed boundary** — Zod schemas mandated for everything crossing a boundary;
  subagents return validated structured output (this task included).
- **Gates / Guides / Guards (engineering-rigour's three Gs)** — all three present at project scope.

---

## 3. Reject as literal (article advice that is WRONG for us taken at face value)

| Advice | Why wrong for us |
|---|---|
| **"Add STRATEGY.md to `.claude/`"** (Every) | Already shipped at repo root `[map §3a]`. The real concern is the *reverse*: overlapping middle layers (CONTEXT.md vs STRATEGY.md) with no writer/freshness rule — a §4 drift concern, not an adoption. |
| **"Add the bug-fix-test rule to `learned-patterns.md`"** (engineering-rigour) | `learned-patterns.md` is a confirmed phantom `[map §6, §0]`. The rule needs a *real* home (a `/cr` pass or a hook). The article was written against canon vocabulary, not disk reality. |
| **"Validate / confirm we have compound engineering via `learned-patterns.md`"** (ai-pilling) | Same phantom `[map §6]`. The real mechanism is `/compound` (§3b); the *executable-constraints file* does not exist. Drop the validation. |
| **"Model choice is a rounding error / context-engineering compounds"** (12-factor) | Directly contradicts `[map §9]`: a model upgrade (Sonnet 4.6 → Opus 4.8) *retires* context-engineering scaffolds. Under fast capability gains, context-engineering investment can depreciate into overhead. |
| **"Run `/scan-context` weekly" to fix adaptation speed** (leland) | `/scan-context` is documented in canon but has **no disk dir** `[map §3b, §5]` — it can't run. The actionable mapping is building `session-end.sh` `[map §5]`, not scheduling a scanner that doesn't exist. |
| **"Skip Operational/Pillar-3 readiness — team of one"** (ai-pilling) | Category error: the agent fleet *is* the team; coordination is a present problem. Following the skip-list would defer building structural guards the map already flags absent (`branch-registry-guard.sh`, `enforce-scope.sh`, `session-end.sh`) `[map §3e, §5]`. |
| **Cost/latency/margin gates (10%-of-revenue, 50–65% margin, $300K crossover)** (when-is-llm-worth) | Calibrated to per-end-user product transactions; do NOT transfer to a harness (no per-call revenue). Applying them to the harness audit is a category error. Also: the cited constants will rot `[map §0 "the artifact itself rots"]`. |
| **Adopt `/goal` now with a written "Standing Rule" stop condition** (goal-loop) | Unenforceable on disk: `enforce-scope.sh` and `block-dangerous-bash.sh` are absent `[map §3e, §5]`, `.cr-ok` never reaches CI (G1), and `/cr` has "no REJECT tier, no UNATTENDED branching" `[map §3c]`. `/goal` is *blocked* until those structural prerequisites are built. |
| **Import the borrowed recall statistics (16.6% adopted / "1-in-5" / 18–20% ceiling)** as our number (recursive-self-improvement, when-is-llm-worth) | They measure *suggestion adoption in a specific study*, not our `/cr` defect recall. Valid inheritance is only "measure locally" (G3). Do not treat them as our number. |
| **"Frameworks are evil — own everything"** (12-factor, read literally) | Condemns the very vendor harness (Claude Code) we operate inside. The article never draws the must-own vs safe-to-borrow line; taken literally it's self-defeating for us. |
| **A full severity × routing 3×3 grid** (every-compound) | Over-engineering against "build what's needed now." The disciplined version is a two-value routing flag (G7). |

---

## 4. Cross-cutting themes (patterns recurring across multiple articles)

1. **"Advisory ≠ enforced" is the spine of the whole cluster.** Every article's real gap reduces to a
   control that is *written* but has no deterministic backstop: the stop sentinel (G1), the heartbeat (G2),
   doc-authority (G5), the security-pass trigger (G10), bug-fix TDD (G9). The map's verdict — "overwhelmingly
   advisory… no deterministic backstop" `[map §3e]` — is the single fact every pass-3 cites.
2. **The reviewer/oracle is the load-bearing-yet-least-tested component.** G1 (forgeable stop), G3 (unmeasured
   recall), G11 (review-bandwidth invariant) all say the same thing from different angles: we have invested in
   *generation* and assumed *verification* is sound. Multiple passes note the human/automated reviewer is the
   bottleneck and the least-inspected part.
3. **Articles validate against phantoms / stale canon — the map exists to catch exactly this.** Three articles
   confirmed our maturity against files that don't exist (`learned-patterns.md` ×2, retired `/cr-feature`,
   `/scan-context`). Re-grounding against `[map §6]`/`[map §0]` is itself a recurring corrective move.
4. **"Synthesize, don't re-research" — near-unanimous.** 8 of 9 pass-3s conclude the work is internal
   mapping/decision, not discovery; the articles' value is *vocabulary that names map rows*, not new external
   facts. (Only two narrow, bounded exceptions survive — see §5.)
5. **The model-upgrade lens (§9) reframes or absorbs several gaps.** Multi-model routing, impact-tracking,
   compounding-reliability, and the eval backstop all get folded into the pending Sonnet 4.6 → Opus 4.8
   Model Capacity re-audit rather than adopted as the articles state them.
6. **State unification / single-writer-single-reader is a structural theme**, not just a memory concern: F5
   (memory triple-duplication), the overlapping STRATEGY.md/CONTEXT.md layers, and "freshness rules for only
   3 of 14 stores" `[map §4]` are one problem — the canon has no tooling-encoded lifecycle for any store.
7. **`/goal` and multi-surface triggers are *downstream* of structural prerequisites**, not adoptable now: both
   goal-loop and 12-factor (F11) conclude their headline primitive is blocked on prior gaps (CI-verified
   `.cr-ok`, the install gap), not buildable as a standalone task.

---

## 5. Fresh research warranted (strict — most pass-3s said synthesize)

Only two genuinely bounded capability checks survive the discipline; everything else is internal
mapping/decision against the ground-truth map.

1. **What a Claude Code hook can actually intercept on a failed tool call** (for G13's errors-into-context +
   circuit-breaker). This is a *Claude Code capability* question, not a 12-factor question — a focused check
   of the PreToolUse/PostToolUse hook surface (load `claude-api` / harness hook docs), not a literature review.
2. **`fast-check` + Vitest 4 integration for integer-cents money math** (for G12). A *targeted dependency
   vetting* per CLAUDE.md "Before writing code" (name, weekly downloads, last publish, ships-its-own-types) +
   confirming clean Vitest 4 / TS 5 integration and the minimal invariant set — not a deep research pass.

**Deferred / not-now (explicitly bounded, do not spawn a fan-out):**
- Scheduler durability spike for G2 — does `CronCreate` fire when the dev's machine is asleep / does it need
  an always-on host? A 15-min internal capability spike, not external research.
- `/goal` Stop-hook contract confirmation (goal-loop) — a single doc fetch against `code.claude.com/docs`,
  *only on a build decision*; `/goal` is blocked behind G1 + the REJECT-path build until then.
- Behavioral-probe / golden-PR-regression patterns for LLM *code-review* agents (G3) — one narrow question
  ("how do teams detect a code-review agent got worse after a model swap?"), warranted only *before* building
  the eval harness, only if not synthesizable from what we have.
- Outcome-proxy patterns at pre-revenue/solo scale (G15) — default defer; product decision for Tanner, behind
  the §9 re-audit.
- Locating/citing the internal **Svpino R1 / DORA** finding for G11 — an internal-records reconciliation, not
  a web search.
