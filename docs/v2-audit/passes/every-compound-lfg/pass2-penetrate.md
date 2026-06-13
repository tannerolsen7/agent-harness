# Pass 2 — Penetrate: Hidden Thesis, Assumptions, Contradictions

Building on pass1: this pass does not restate the claims. It opens them up — what the article *takes for granted*, where its own framing fights itself, and what net-new structure emerges once you read the claims against each other rather than in sequence.

---

## A. The buried thesis pass 1 only half-named

Pass 1 §1 records the surface thesis ("methodology, not a tool"). The *deeper* thesis, never stated outright but load-bearing across the whole article, is:

> **Determinism at the seams, freedom in the cells.** Every's real contribution is not any single artifact — it's a consistent architectural stance: *make the boundaries between agent actions deterministic, and let the agent be agentic only inside the boxes.* 

This unifies four otherwise-separate pass-1 claims that the article presents as a list:
- pass1 §3.1 (`/lfg` fixed sequence) — the **macro seam**: step order is not the agent's choice.
- pass1 §5 (blueprint cross-ref to Stripe) — the article itself half-sees this ("deterministic nodes; agentic freedom inside work and review"), but files it under "cross-page connections" instead of recognizing it as the *spine of Every's whole design*.
- pass1 §4 (three-tier review: "routing is deterministic (file patterns)") — the **micro seam**: which reviewer fires is not the agent's choice.
- pass1 §6 (severity/routing orthogonality) — the **output seam**: disposition is structured, not narrated.

So the article's nine "transferable patterns" are not nine ideas. They are **one idea applied at four altitudes** (pipeline, review-trigger, review-output, model-selection). That is the synthesis the article gestures at but never commits to — and it matters for pass 3, because it changes the unit of adoption from "copy these features" to "find every place our harness lets the *model* decide a boundary that should be deterministic."

## B. Hidden assumptions the article never examines

1. **That STRATEGY.md is a *layer*, not a *duplicate*.** (Building on pass1 §4, §6-C-A.) The article asserts a clean three-tier stack — product (vague) / strategy (Every's new middle) / code (CLAUDE.md). It never asks the obvious adversarial question: *what stops STRATEGY.md from becoming a fourth place the same fact lives?* Its own open question #3 ("how does STRATEGY.md stay current?") is the symptom — a layer with no writer, no trigger, and no freshness rule is not a layer, it's drift waiting to happen. The article introduces a new context file while its own failure-mode list (pass1 §3.14: **context drift**) is the exact tax that new file incurs. **The article does not connect its own context-drift failure mode to its own STRATEGY.md proposal.** That is the sharpest internal blind spot in the piece.

2. **That "orthogonal" severity and routing are actually independent.** (Building on pass1 §4, §6-C-B.) The article treats severity × routing as a clean 3×3 grid. But the cells are not equiprobable, and some are near-empty: a CONSIDER/author finding and a MUST-FIX/author finding differ only in severity, while MUST-FIX/tech-debt is almost a contradiction in terms (if it truly must be fixed, how is it backlog?). The article's own design challenge quietly admits this by asking for a "SHOULD-FIX/tech-debt finding that would currently block unnecessarily" — i.e. the real bug it's fixing is **one specific cell** (product-decision findings hard-blocking merges), not a missing dimension. The honest framing is narrower than "add a dimension": it's "stop treating *needs-a-human-decision* as *blocks-the-merge*." That's a routing flag with maybe two useful values, not an orthogonal axis.

3. **That public failure-mode candor implies the system works.** (Building on pass1 §2, §4-last.) The article reads "they documented their failures" as *evidence of maturity* ("they eat their own cooking"). The opposite inference is equally available and the article never weighs it: a 6-person team publishing seven distinct production failure modes for an "unattended overnight" system is also evidence the unattended run is **frequently not unattended**. The author's own open question #1 ("how often does /lfg actually run unattended vs. require mid-session intervention?") concedes this — but the synthesis still presents `/lfg` as a shipped north star rather than as an aspirational mode with a documented failure tax. Candor and reliability are being conflated.

4. **That the "13+ → 5–7 reviewers" reduction is a count problem.** (Building on pass1 §7.) The article frames solo-scale adaptation as *fewer reviewers*. The thing it doesn't examine: Every's three *tiers* (always-on / conditional / stack-specific) are an architecture, and you can keep all three tiers with far fewer agents. The transferable unit is the **tier structure**, not a headcount. Reducing 13 personas to 5 while losing the conditional-routing tier would throw away the actual insight (determinism at the seam, §A) and keep only the cosmetic part (named personas).

## C. Where the article contradicts itself or its sources

1. **`/cr-feature` is named as a live target three times** (pass1 §6-C-B, §7, §8 design challenge) — "the system's `/cr-feature` produces findings but doesn't distinguish routing from severity." This is presented as settled fact about the harness it's advising. It is an **un-verified inheritance from the secondary Notion page** (the article admits in Source Reliability that *all claims derive from* that landscape page). Pass 3 must adjudicate whether `/cr-feature` even exists on disk before any of C-B/§8 can be actioned. The article built a whole Design Challenge on an unchecked premise.

2. **"Already in the system" claims, stated with no inspection.** (pass1 §7.) Three rows assert the harness *already* has something: three modes ("naming is the remaining step"), compounding timing ("`/compound` is the final step before merge"), and the AFK three-mode mapping. None is checked against the harness; all are inherited from the secondary page. The article is simultaneously (a) advising a system and (b) asserting facts about that system it never looked at. That's the central methodological weakness, and it's structural, not incidental — the Source Reliability box says so explicitly.

3. **Determinism claim vs. non-determinism failure mode.** (pass1 §4 "routing is deterministic" vs. §3.14 "non-determinism: same prompt, different outputs.") The article celebrates deterministic *routing* (which reviewer fires) without noting that the reviewers themselves are non-deterministic (what they *say*). So "always-on tier is guaranteed" guarantees the *invocation*, not the *finding*. The guarantee is weaker than the prose implies, and the article's own failure list contains the refutation.

## D. Net-new analysis (not in the article)

1. **The failure-mode list is the only part of the article with no adoption proposal — and it's the most adoptable part.** (Building on pass1 §3.14, §5-last.) The article calls failure modes "the most transferable artifact" and then, in its "Application to This System" section, proposes adopting STRATEGY.md, routing fields, and adversarial techniques — *none of the failure modes*. The richest, most concrete, most verifiable content (seven named, reproducible failure classes) gets zero candidate actions. The transferable move the article missed: **turn each failure mode into a guard or a check**, because each is a deterministic, detectable condition (encoding → a normalization/lint pass; context drift → a task-version staleness check; skill cache → a session-restart rule; cross-skill file refs → a reference-integrity test). This is a far stronger pass-3 lead than the three context/review proposals the article foregrounds.

2. **`/lfg` is the same north star our own audit already names — which means the article is confirming, not introducing.** Every's `/lfg` (autonomous brainstorm→plan→work→review→compound→PR) is structurally the "AFK / unattended overnight run" that our harness already treats as its target. So the article's *highest-confidence* claim is the one that adds the *least* to us: it's external corroboration of a direction we've already chosen, not a new capability. The genuinely new things are the smaller ones — the middle context layer, the routing flag, the four adversarial lenses, and (per D-1) the failure-mode-as-guard reframe.

3. **"Compound immediately after review" is a claim about *session economics*, not workflow.** (Building on pass1 §3.13.) The article lists timing-criticality as a failure mode but doesn't extract its real lesson: knowledge capture has a *half-life inside a context window*. The reason `/compound` must run before the session ends is that the nuance lives in the model's active context, not in any file. This reframes compounding from "a step in a pipeline" to "a context-eviction deadline" — which is a sharper, more general principle than the article states and bears directly on any memory model.

---

**One-line of pass 2:** The article's nine patterns are one stance — *deterministic seams, agentic cells* — applied at four altitudes; its sharpest blind spots are that it proposes a new context layer (STRATEGY.md) without noticing that layer incurs its own documented context-drift tax, treats a single bad review-routing cell as a whole missing dimension, asserts unverified "already in the system" facts inherited from a secondary page, and leaves its single most adoptable artifact — the seven production failure modes — with no adoption proposal at all.
