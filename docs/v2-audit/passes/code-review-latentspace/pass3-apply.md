# Pass 3 — Apply

Building on pass2: I apply the distilled theses (pass2 Net §1–§5) and the per-section critiques to OUR harness, checked against `CANONICAL-HARNESS-AS-IS.md`. Every gap cites a ground-truth section or a confirmed absence. Where the article asserts something about our harness, I verify it against the map rather than inheriting it.

---

## (a) What we ALREADY do (cite ground-truth rows)

1. **Adversarial review pass already exists.** The article claims `/cr` "already performs a version of" L5 (pass1 §1) — true. Ground-truth §3c records `/cr` as **9 passes with the adversarial/Devil's-Advocate pass** (canon folds it as P9; disk runs it as "Pass 11 `@reviewer`, 4 lenses"); the four lens agents (assumption/composition/cascade/abuse) exist on disk [ground-truth §3d: "all 4 lenses"]. So "add adversarial verification" is **already built** — only its *independence* is in question (see gaps).

2. **Deterministic guardrails (L2) partially exist as hooks + CI.** The article's L2 "parse-and-fail invariants in CI" (pass1 §1) maps to our two bash guards (`block-dangerous-git.sh`, `block-npm-install.sh`) + pre-commit (ESLint, `tsc --noEmit`, vitest) + two CI workflows (`ci.yml`, `integration.yml`) [ground-truth §3e, §3f]. We have real deterministic floors; the article's framing that this is novel doesn't apply to us.

3. **Permission architecture / blast-radius escalation (L4) partially exists.** The article's L4 "auth/schema/payment auto-escalate" (pass1 §1) — our CLAUDE.md already mandates `/cr-security` "alongside" any commit touching auth, middleware, or RLS, and our worktree prod-key firewall (`worktree-create.sh`, Tier-0 credential isolation) is a real blast-radius control [ground-truth §3e, §6]. RBAC is enforced at the `src/data/` layer per CLAUDE.md. We have a partial, manually-triggered L4.

4. **Spec-before-code discipline (L3) partially exists.** The article's L3 / `/feature`-gate (pass1 §1, §6) — our CLAUDE.md "Before writing code" already requires defining inputs/outputs/what-it-must-NOT-do/done-definition, and `/feature` + `/queue` + `/spike` exist as disk skills [ground-truth §3b, aligned list]. We already have the *discipline*; what we lack is the *machine-checkable* form (see gaps).

5. **A compounding-capture trigger already exists.** The article wants `/compound` to capture review findings (pass1 §3, §8). `/compound` exists on disk [ground-truth §3b aligned list] and the memory model already has `RECURRING-FINDINGS.md` "pipeline-only, auto-counted by `/cr` Step 3b" [ground-truth §4]. The recurrence-counting mechanism the article describes as missing is **partly built already** — `/cr` Step 3b counts recurring findings.

6. **A reusable-pattern store already exists (multiple).** The article recommends building `.claude/learned-patterns.md` (pass1 §3, action item 4). We already have `docs/solutions/` (reusable positive patterns), `PITFALLS.md` (canonical traps), `.claude/memory.md`, and the 6th auto-memory store [ground-truth §4]. The capability the article says to build largely exists under different names.

## (b) REAL gaps it exposes — each cites a ground-truth section or confirmed absence

1. **No REJECT / approach-level-failure tier in `/cr`.** The article's central actionable claim (pass1 §4, §9 item 1). Ground-truth §3c confirms the absence directly: disk `/cr` has **"No REJECT tier, no UNATTENDED branching."** CLAUDE.md's pipeline resolution lists only MUST FIX / NEEDS HUMAN / SUGGESTION. This is a **confirmed real gap** — the system can polish a wrong-approach PR but cannot say "close and re-spec." Weight (pass2 §C): the *concept* is well-motivated; the article's specific trigger thresholds are unevidenced design opinion, so build the tier, treat the thresholds as defaults to tune.

2. **Adversarial pass shares context with the coding session.** Article action item 5 (pass1 §8). Verified against the map: ground-truth §3c describes the adversarial pass as part of the same `/cr` invocation over "the full branch diff" — there is no separate-context provisioning recorded; the 4 lenses run inside `/cr`. The independence the Gemini CLI result depends on (pass2 §C, §D — the one *strongly-evidenced* lever, 43%→91%) is **not** structurally guaranteed. Real gap. Per pass2 §D, the fix is **shared project canon, isolated solution context** (a fresh sub-agent with clean task framing but access to CLAUDE.md/Rejected Patterns), not a different model.

3. **No machine-checkable acceptance criteria from `/feature`.** Article §6, §8 (Stage 2→3 lever). Ground-truth shows `/feature`, `/queue` exist [§3b] but records no automated success-condition artifact; the spec discipline in CLAUDE.md is human-readable prose. The "success condition (automated check)" section the article wants (pass1 §6) is a **confirmed absence** — no map row describes a committed, machine-verified acceptance-criteria file feeding the pipeline.

4. **No diff-size or file-scope gate in `/queue`.** Article action items 2, 3 (pass1 §6, §9). Ground-truth §3e notes `enforce-scope.sh` (blocks staging files outside an ALLOWED FILES list) is **canon-structural but ABSENT on disk** — and it's listed in §5 (canon-only build candidates). So the file-scope half is a *citable canon-only absence*; the diff-size-cap and CI-pass-before-PR halves are **not present in either layer** (no map row anywhere for a line-count gate or a CI-precondition on PR open) → confirmed absence. Note §3f: "the Node 8.5(c) gap (CI never verifies `.cr-ok`)" — we don't even gate PR-open on the existing sentinel reaching CI, let alone on CI passing.

5. **No measurement layer at all (first-pass approval rate, cycle count, per-task-type tracking).** Article §3, action item 7. The map's entire memory/metrics model [ground-truth §4] is about *knowledge* stores, not *effectiveness* metrics — there is no row, in canon or disk, for first-pass-approval-rate, review-cycle-count, or post-merge-defect tracking. **Confirmed absence of an effectiveness-measurement layer.** This is the gap that blocks the compounding the article (and Bitloops, pass2 §C) says is the real lever — you cannot compound what you don't measure.

6. **The compounding store the article names (`learned-patterns.md`) is a known phantom — but the *function* is genuinely partial.** Ground-truth §6 lists `learned-patterns.md` as a **phantom reference** ("referenced on disk, never built on disk *or* in canon"), and the "How later phases cite this map" closing section explicitly names `learned-patterns.md` as a V1-planning failure to be killed by the anti-duplication gate (it duplicates `docs/solutions/` + `RECURRING-FINDINGS.md`, §4). **So the article's action item 4 is partly a trap**: do NOT build a new `learned-patterns.md` (would duplicate §4 stores), but the underlying gap — *review findings are not systematically fed back into task-start context* — is real, since `RECURRING-FINDINGS.md` is explicitly "never read by implementers" [ground-truth §4]. The gap is a **read-path** gap, not a missing-file gap.

7. **No `/cr-security` ↔ blast-radius wiring to a deterministic escalation.** Article L4 (pass1 §1). Ground-truth §3c shows `/cr-security` exists (2 vs 3 passes drift) but §3e shows the relevant *structural* guards are absent: `block-dangerous-bash.sh` (3rd guard) and `branch-registry-guard.sh` are **canon-structural, ABSENT on disk** [§3e, §5]. L4's "automatic escalation" is, on our harness, advisory (a CLAUDE.md instruction to run `/cr-security`), not enforced — consistent with the map's headline that the system is "overwhelmingly advisory" [§3e Net].

## (c) Weaknesses in the article's OWN reasoning (from pass2)

1. **Confidence inversely correlated with evidence** (pass2 §C): the most foregrounded action items (REJECT thresholds, "5 PRs <400 lines") are the least evidenced — the article *admits* "no broad industry consensus exists on a specific number" then issues a specific number (pass1 §5). Adopt the *structure* (a cap exists), reject the *magic numbers* as our own to set.

2. **Anchor stat is correlational and self-selected** (pass2 §B): the 154% / 9% / 91% Faros figures (pass1 §1) carry the whole argument but never separate AI-causation from team-self-selection, and the article simultaneously claims AI inflates PR size *and* that process controls fully prevent it — an unreconciled contradiction. The 400/800-line MS cliff (pass1 §2) is the better-sourced finding and should outrank Faros.

3. **Conflates context-isolation / fresh-prompt / different-model** for adversarial independence (pass2 §D) and ignores the tension with project-awareness — yet elsewhere argues `/cr`'s whole value is project context (pass1 §7). For us this is decisive: a clean-prompt sub-agent with canon access is cheap and correct; the article's "no shared context" taken literally would *blind* the reviewer to our Rejected Patterns.

4. **Vendor-selected sample presented as independent consensus** (pass2 §H): self-reported seller metrics (Greptile 3x/4x, Aviator Verify) sit beside independent findings (MS, Faros) with no epistemic distinction.

5. **Omits an eviction/freshness model for the compounding store** (pass2 §E) — directly colliding with our own Model Capacity Audit's "ghost rules if unobserved 90 days; collapse" rule [ground-truth §9]. A monotonic learned-patterns file is the exact scaffold our canon pre-authorizes removing.

6. **"Ship fast / revert faster" contradicts the L1-L5 rigor stack** (pass2 §G) and assumes prod observability/revert infra we don't have for a proposal tool. Only the pre-merge-rigor half is applicable to us.

7. **PR-as-unit + human-bottleneck framing is assumed, not argued** (pass2 §F); the article's own Ona/L4 evidence (74% lead-time cut by deterministic auto-approve) points to the higher-leverage answer — remove most PRs from the human path — which it underweights.

## (d) Does it warrant fresh external research? (be disciplined — prefer synthesize)

**Mostly NO — synthesize, don't re-research.** The actionable content reduces to a handful of harness changes (REJECT tier, separate-context adversarial pass, machine-checkable acceptance criteria, `/queue` diff/scope/CI gates, an effectiveness-metrics layer, a read-path for review findings) that all map to existing ground-truth rows in §3c/§3e/§4/§5/§6. These are **design-and-build decisions**, not open research questions, and they intersect directly with the canon's own Model Capacity Audit [§9] and the canon-only build list [§5]. Re-researching "should `/cr` reject" would re-derive what the map already frames.

**Two narrow exceptions worth a *bounded* lookup, not a deep dive:**
1. **The Gemini CLI #26397 cross-model result** (pass1 §2, pass2 §C) is the single strongest lever (43%→91%) and the most architecture-relevant to action item 5. Worth one verification pass on *what independence actually produced the gain* (different model vs. fresh prompt vs. isolated context) before we commit to a separate-context adversarial design — because pass2 §D shows the article conflates three different mechanisms with very different costs. This is corroboration of one fact, not new research.
2. **Eviction/decay for a compounding learning store** (pass2 §E) is genuinely unaddressed by both the article and our map, and it gates whether the compounding loop helps or bloats. But this should be resolved by *synthesis with our own canon* [§9 ghost-rule decay rule] + the other v2-audit article passes, not external search — the answer is already half-written in our Model Capacity Audit.

**Net:** one bounded fact-check (Gemini CLI independence mechanism); everything else is synthesize-against-the-map.
