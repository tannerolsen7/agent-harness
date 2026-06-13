# Pass 3 — Apply: Every vs. Our Harness (against the ground-truth map)

Building on pass2: the deep stance pass 2 §A isolated — *deterministic seams, agentic cells* — is the lens for this pass. The test for every Every "candidate" is not "is it a good idea" but "does our ground-truth map (`CANONICAL-HARNESS-AS-IS.md`) show a real gap, or did we already build it / already reject it." No gap survives here without a `[canon §X]` / `[disk §Y]` / `[absent]` citation.

A blunt fact frames everything below: I checked disk. **Three of the article's load-bearing premises about *our* harness are false against ground truth.** That collapses most of its "Application to This System" section before it starts (pass2 §C-1, §C-2).

---

## (a) What we ALREADY do

1. **STRATEGY.md already exists.** The article's flagship candidate (pass1 §6-C-A, §7 "transfers fully") is to *add* STRATEGY.md to `.claude/`. We have it: `STRATEGY.md` at repo root (1.4 KB, present on disk), recorded in the ground-truth map: *"`STRATEGY.md` | ⚠️ (templates only in canon) | ✅ Disk has it"* `[map §3a]`. The article advised us to build a file we shipped. Its own open question — "does CONTEXT.md already serve this?" — is doubly moot: both `CONTEXT.md` (15 KB, PR #92) `[map §3a]` *and* STRATEGY.md already exist. The genuine question is the *reverse* of the article's: do we now have overlapping middle layers (CONTEXT.md domain-why vs. STRATEGY.md product-intent) with no writer/freshness rule — exactly the drift pass 2 §B-1 warned the new layer would cause? That's a §4 memory-model concern, not an Every adoption.

2. **The four adversarial techniques already exist as agents.** The article's "explicit `/cr-security` upgrade" candidate (pass1 §6-C-C) is to add assumption-violation / composition-failure / cascade-construction / abuse-case lenses. We have all four as named agents: `lens-assumption.md`, `lens-composition.md`, `lens-cascade.md`, `lens-abuse.md` on disk. Ground truth: *"Disk has 23 agents including all 4 lenses (assumption/composition/cascade/abuse)"* `[map §3d]`, and they run as `/cr`'s adversarial pass: *"Pass 11 `@reviewer` (4 lenses)"* `[map §3c]`. Every's "four attack techniques" and our four lenses are the same construct. **This is convergent design, not a gap.**

3. **The adversarial pass is already always-on in review.** Every's "adversarial reviewer runs on every PR" (pass1 §4) is matched: our `/cr` runs the 4-lens adversarial pass as part of the standard 9-pass + adversarial structure on the full branch diff `[map §3c]`. The always-on/guaranteed-invocation property pass 2 §C-3 examined is already how `/cr` is wired.

4. **Compounding-after-review timing is already our structure.** The article's "transfers fully — already in the system: `/compound` is the final step before merge" (pass1 §7) is accurate: `/compound` exists on disk and in canon `[map §3b]`. We already treat capture as a near-merge step.

5. **The autonomous-loop north star is already our explicit target.** `/lfg` ≈ our AFK/unattended run. The harness already has UNATTENDED worktree mode + Tier-0 credential isolation built for exactly this (`worktree-create.sh` prod-key firewall, *"a genuine disk advance over canon"* `[map §3e, §6]`). Every corroborates the direction; it does not introduce it (pass 2 §D-2).

## (b) REAL gaps it exposes — each cited

1. **No severity × routing orthogonality anywhere in our review output.** This is the article's strongest *applicable* insight (pass1 §6, pass2 §B-2) — but note the premise correction: the article targets `/cr-feature`, which **does not exist on disk** (confirmed: no `.claude/skills/cr-feature/`; only `/feature` and `/cr`). `/cr-feature` was *"RETIRED v0.85 in canon (folded into `/cr`)… Disk correctly has no `/cr-feature`"* `[map §3b, §7.2]`. So the real target is **`/cr`**, whose ground-truth pass structure (`[map §3c]`) shows MUST FIX / NEEDS HUMAN / SUGGESTION tiers — i.e. a *severity-ish* tier set with NEEDS HUMAN smuggling a routing concept in, but **no clean orthogonal routing field** (author / design-decision / tech-debt). The gap is real and citable: `/cr`'s output (per CLAUDE.md "Pipeline resolution" and `[map §3c]`) conflates "how bad" with "who acts." Narrowed per pass 2 §B-2, the actual fix is small: split NEEDS HUMAN into *needs-design-decision* (don't hard-block) vs. *must-fix-now*. **Gap citation: `[map §3c]` (no REJECT tier, no routing dimension) + confirmed absence of any routing field in `/cr` resolution.**

2. **Failure modes have no guard/check anywhere — the article's richest artifact, unmapped.** Pass 2 §D-1: each of Every's seven failure modes is a deterministic, detectable condition, and our enforcement floor is *"overwhelmingly advisory… no deterministic backstop"* `[map §3e net-picture]`. Two of the seven map onto confirmed disk absences:
   - **Cross-skill file-reference breaks** → we have *"`/cr-feature` still referenced in canon's own Page-11/Page-14"* and a pile of *"Phantom refs (`learned-patterns.md`, `review-log.md`, `triage-inbox.md`, `/prototype-interface`, `/scan-context`…)"* `[map §6]` — i.e. we *already suffer* this failure mode (dangling references) with no reference-integrity check. **Citation: `[map §6 phantom-refs]`.**
   - **Skill cache (mid-session skill edits don't take effect)** → no session-restart rule exists in our hooks `[map §3e]` (session-start does remote npm install; no cache-invalidation concern is handled). **Citation: confirmed absence in `[map §3e]` hook table.**
   The other five (encoding, context drift, agent stalls, non-determinism, compound timing) are operational risks for our UNATTENDED mode but only become *citable gaps* if we run `/lfg`-style overnight loops at volume; today they're watch-items, not mapped absences. Disciplined call: **only the two above are real, cited gaps now.**

3. **Multi-model routing rules are not encoded.** The article: add model-routing rules to CLAUDE.md (pass1 §7). Our global config has *"`effortLevel: xhigh`"* and `switchModelsOnFlag` `[map §2]` but **no task-type→model routing doctrine** in CLAUDE.md or canon. This is a citable absence — but see (c)/(d): the article's own routing claim is pinned to **Opus 4.6** while we're on **Opus 4.8**, and our ground truth already orders a model-capacity *re-audit* `[map §9]`. The gap is real but should be folded into the §9 re-audit, not adopted as Every stated it. **Citation: `[map §2]` (no routing rules) + `[map §9]` (re-audit pending).**

## (c) Weaknesses in the article's OWN reasoning

1. **It advises a system it never inspected.** Pass 2 §C-2: the Source Reliability box admits *all* claims derive from a secondary Notion page; the "Application to This System" section then asserts disk facts ("currently has CLAUDE.md, CONTEXT.md, TASKS.md"; "`/cr-feature` produces findings"; "`/cr-security` is pattern-based") that are **wrong or stale** — STRATEGY.md exists `[map §3a]`, `/cr-feature` is retired `[map §3b]`, and the four lenses are built `[map §3d]`. Two of its three concrete candidates were already shipped before it wrote them. This is the article's defining flaw: confident prescriptions over an unchecked model of the target.

2. **It buries its best material and promotes its weakest.** Pass 2 §D-1: the failure-mode list (concrete, verifiable, and the part with real adoption leverage) gets *zero* candidate actions, while STRATEGY.md and the routing field — one already built, one aimed at a retired skill — get the spotlight. The article's own self-assessment ("failure list is the most transferable artifact") contradicts its own prioritization.

3. **It mistakes one bad cell for a missing dimension.** Pass 2 §B-2: "severity and routing are orthogonal" over-generalizes a narrow real fix (don't let *needs-a-decision* hard-block). Adopting a full 3×3 orthogonal grid would be over-engineering against CLAUDE.md's "build what's needed now" rule; the disciplined version is a two-value routing flag.

4. **It introduces a context layer while ignoring its own context-drift failure mode.** Pass 2 §B-1: STRATEGY.md is proposed with no writer/trigger/freshness rule, and the article's own open question #3 is exactly "how does it stay current?" — unanswered. Since we *already have* STRATEGY.md + CONTEXT.md, the article's unexamined drift risk is now *our* live problem, not a hypothetical.

5. **Determinism is overclaimed.** Pass 2 §C-3: "always-on tier is guaranteed" guarantees invocation, not finding-quality; the article's own non-determinism failure mode refutes the strength of the guarantee.

## (d) Does it warrant fresh external research?

**No — synthesize, don't re-research.** Reasons, disciplined per CLAUDE.md ("prefer synthesize over re-research"):

- The two genuinely actionable items — **routing flag on `/cr`** (b-1) and **failure-mode-as-guard** for cross-skill refs + skill-cache (b-2) — are *internal design decisions about our own harness*, fully specifiable from the ground-truth map. No external source would sharpen them.
- The **multi-model routing** item (b-3) does have an open external question (current Opus-4.8 task→model tradeoffs), but our ground truth already schedules that under the **Page-13 model-capacity re-audit** `[map §9]`. Routing belongs *in* that re-audit, not in a separate Every-driven research spike. Re-researching now would duplicate a planned effort.
- Every's primary sources (the MIT-licensed plugin, two every.to articles) are already inspectable and already digested by the secondary page; a fresh fetch would re-derive what pass 1 captured. The one number worth a single confirmatory check *if* we ever build heavy `/lfg` loops is the **"90% better / 15× tokens" Anthropic figure** (pass1 §3.12) — it drives orchestration economics — but it's not load-bearing for any current gap, so it stays a deferred watch-item, not a research order.

**Verdict:** Fold b-1 and b-2 into existing V2 build threads (review-output design; enforcement-floor / guard work, `[map §5]`); fold b-3 into the §9 re-audit. Zero net-new external research warranted.

---

**One-line of pass 3:** Against ground truth, Every mostly *confirms* our direction and two of its three headline candidates are already built (STRATEGY.md `[map §3a]`, the four adversarial lenses `[map §3d]`); the only real, citable gaps it surfaces are a severity-vs-routing split in `/cr` output `[map §3c]` and turning two of its seven failure modes — cross-skill reference breaks `[map §6]` and skill-cache staleness `[map §3e]` — into deterministic guards, neither of which needs fresh external research.
