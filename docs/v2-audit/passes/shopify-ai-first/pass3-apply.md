# Pass 3 — Apply: this article against OUR harness (CANONICAL-HARNESS-AS-IS.md)

Building on pass2: I take the pass-2 conclusions as the lens — specifically pass2 §D (comprehension debt and
review bottleneck are one human-bandwidth ceiling from two ends), pass2 §F (Shopify's guardrail is admittedly
unenforced cultural norm), pass2 §H (the one durable claim: optimize for human review + understanding, not
output), and pass2 §A (mechanisms are inseparable from the CEO mandate, so most don't transfer). I map these
onto the ground-truth map. Every gap below cites a `[GT §X]` row or a confirmed absence. No gap without a
citation.

Citations use the section numbers of `CANONICAL-HARNESS-AS-IS.md` (the multi-project ground-truth map).

---

## (a) What we ALREADY do (cite ground-truth rows)

1. **The comprehension-debt guardrail is already our discipline rule — and ours is stronger.**
   Building on pass1 §5 and pass2 §F: Shopify's guardrail is a cultural norm Farhan models. Ours is the
   3-question discipline rule ("what does this do/where could it fail/what would you change") wired into the
   pre-commit *checkpoint* and the `/grill-with-docs` Phase-1 three-human-questions, which the map marks **keep
   verbatim** as reasoning discipline `[GT §9 "Keep verbatim"]`. We have the same intent with *more*
   structure. The article's headline warning is, for us, already a named-and-kept rule — not a gap.

2. **Parallel-agent execution is built.** Building on pass1 §4 (10 agents, human merges): we have worktree
   provisioning (`worktree-create.sh` / `worktree-add.sh`) and `/queue` batches, with the Tier-0 prod-key
   firewall around them `[GT §3e "worktree-create.sh (disk-only)", §6 "worktree-create.sh + prod-key
   firewall"]`. The article's "parallel execution" pattern is one we already run — and our version adds a
   credential-isolation layer Shopify's description never mentions.

3. **Adversarial review already exists in `/cr` and `/cr-security`.** Building on pass1 Pass-4 (security as
   adversarial pairing): our `@reviewer` runs an explicit **abuse-case lens** (one of 4 lenses), and `/cr`'s
   final pass is adversarial (the map's "Pass 11 @reviewer (4 lenses)" / canon's "P9 = Devil's Advocate, 4
   attack vectors") `[GT §3c, §3d]`. `/cr-security` is a dedicated security pass `[GT §3c]`. The article's
   "ask the AI to attack the code" is partially already our posture.

4. **The review gate as the quality backstop is already our architecture.** Building on pass2 §H and pass1
   Pass-4 (review is the binding constraint): our entire ship pipeline is review-gated — `/cr` writes a
   `.cr-ok` sentinel consumed by `pr.sh`, and the pre-push hook validates it `[GT §3e pre-push, §3f Scripts]`.
   We *already treat human/agent review as the gate before merge.* Shopify's "humans review all production
   code" is, for us, the `.cr-ok` chain.

5. **Tool-agnostic stance ≈ the proxy's transferable nugget.** Building on pass1 §1 and pass2 §B (only the
   API-boundary principle survives downscaling): the canon is explicitly a **"tool-agnostic AI-Native
   Engineering System"** `[GT §0.1, §1]`. The one transferable part of the proxy (don't couple CLAUDE.md to a
   specific tool) is already the canon's design intent. No proxy to build.

## (b) REAL gaps this article exposes (each cites a ground-truth section / confirmed absence)

1. **No session-end review artifact exists — the Design Challenge has no answer in our harness.**
   Building on pass2 §D/§H (review is the acute ceiling) and pass1's Design Challenge (spec the minimal
   session-end handoff for <15-min review). Ground truth: `/handoff` is **documented in canon, ABSENT on disk**
   `[GT §3b "Documented in canon, ABSENT on disk: /handoff", §5 "/handoff (detailed)"]`. So there is **no
   structured session-end output** the compound agent produces to make review fast and comprehension-preserving.
   This is a real, citable gap: the article's single most concrete deliverable (the session-end review spec) maps
   onto a confirmed disk absence. *Caveat from `[GT §9]`:* the Model Capacity Audit pre-flags `/handoff`'s "60%
   context tracking" as a *capability proxy to replace* with coherence self-assessment — so the gap is "a
   session-end review artifact," NOT "build `/handoff` as canon specified it." The article's framing (review-/
   comprehension-preserving handoff) is actually the *better* spec for that absent artifact than the canon's own.

2. **Memory has no mechanism that detects comprehension debt — only correctness.**
   Building on pass2 §D (reversion rate measures the acute axis; comprehension debt is the chronic axis nothing
   detects) and pass2 §F. Ground truth: our memory model is five/six stores tuned for *corrected mistakes and
   recurring findings* — `memory.md`, `RECURRING-FINDINGS.md` (auto-counted by `/cr`), `PITFALLS.md`, plus the
   auto-memory `feedback_*` store `[GT §4]`. Every freshness/promotion rule is about *correctness traps*, and
   freshness rules exist for only 3 of the stores `[GT §4 "freshness rules exist for only 3 stores"]`. **Nothing
   in the memory model tracks whether the human still understands what the agent built.** That is the chronic
   axis from pass2 §D, and it is a confirmed structural absence in `[GT §4]`. This is the article's most useful
   gap-exposure for us.

3. **`session-end.sh` (Stop hook) is canon-declared but ABSENT on disk — the one place a comprehension/review
   artifact could be auto-emitted.** Building on gap #1: the natural enforcement point for a session-end review
   handoff is a Stop hook, and the map records `session-end.sh (Stop → memory candidates)` as **canon ✅ / disk
   ❌** `[GT §3e, §5 "session-end.sh (Stop hook)"]`. So even if we wanted the article's <15-min review artifact
   auto-produced, the hook to emit it does not exist. Citable absence.

4. **`/cr-security` is pattern-checking, not adversarial-generation — partial gap.**
   Building on pass1 Pass-4 (security as adversarial pairing) and pass2 (this is a *mode*, not a checklist).
   Ground truth: `/cr-security` is **2 passes in canon / 3 on disk** — "Security & Auth" + "Data Boundary
   Integrity" (+ disk's 3rd) `[GT §3c, §6 "/cr-security 3rd pass"]`. These are *named-pattern* passes. The map
   does not record any "construct the exploit / fuzz this boundary" *generative-adversarial* step. The
   `@reviewer` abuse-case lens `[GT §3d]` gestures at it (per the article's own admission), so this is a
   **partial** gap, not an empty one — worth a focused look, not a new skill. Cite: confirmed absence of an
   adversarial-generation step within the `/cr-security` pass inventory `[GT §3c]`.

5. **"Review capacity as a first-class, named constraint" is absent from our principles layer.**
   Building on pass2 §H. Ground truth: the map has no principles-layer concept of human-review throughput as the
   AFK ceiling; the closest artifacts are the `.cr-ok` gate `[GT §3f]` and the Model Capacity Audit, which is
   about *model* capability, not *human-review* capacity `[GT §9]`. Naming review capacity is a genuine
   absence — **but** see weakness (c)(3): for a solo operator this is naming, not mechanism, and the map already
   warns against constraints that don't name a failure mode `[GT §9 golden rule]`.

## (c) Weaknesses in the article's OWN reasoning (carried from pass2, applied)

1. **Self-reported numbers used as load-bearing while flagged unverified** (pass2 §G.1). The page's own Source
   Reliability section says 20% / $250 / unchanged-reverts are Thawar self-report with no independent
   verification, then the Application section leans on "reversion rates unchanged" as "the evidence the gate
   holds." For our audit this means: **do not import the reversion-rate claim as evidence for any proposal.** It
   fails our own fact-vs-opinion bar.

2. **Demo velocity's anti-Goodhart property is load-bearing on the org context it cannot survive** (pass2 §C).
   The metric resists gaming *because there is an audience that depends on the output*. Solo, there is no
   audience — so importing "demo velocity" as an AFK metric imports the word without the mechanism. Against
   `[GT §9]`'s golden rule ("if you can't name a failure mode the constraint prevents, it's overhead"), a
   solo "demo velocity" metric prevents no failure mode. **Reject as instrumentation; at most a framing note** —
   which is, to its credit, exactly where the page's own Pass-4 lands.

3. **Mechanisms presented as separable from the mandate** (pass2 §A). The article's Application section treats
   comprehension debt, review capacity, demo velocity as independently transferable, having just established
   (its own Pass 4) that they are downstream of a CEO forcing function. The transferable residue is smaller than
   the candidate list implies — which is why most of the page's candidates resolve, correctly, to "framing note"
   or "already covered."

4. **The two named constraints are never unified** (pass2 §D). The article's strongest evidence (unchanged
   reverts) speaks to the acute axis and is silent on the chronic axis it calls most important. So a harness
   that "fixes the review bottleneck" (faster review) could *worsen* comprehension debt (review gets shallower).
   Any proposal we draw from this article must address *both* axes or it solves the wrong one.

## (d) Does it warrant fresh external research? (be disciplined)

**Mostly no — synthesize, don't re-research.** Reasons:

- The article's transferable content reduces (pass2 §H) to one claim — optimize for human review + understanding
  as the binding constraint — and that claim is already actionable against our map without more sources: it
  points at gaps #1–#3 in section (b), all of which are *internal design* questions (what session-end artifact,
  what comprehension-tracking in memory, wire the Stop hook), not external-fact questions.
- The map explicitly notes this article is one node in a corpus that already includes **Ramp's verification loop**
  and **Stripe** on the same review-capacity finding (the page cites "confirmed independently by Shopify, Ramp,
  and Stripe"). The cross-source corroboration we'd seek already exists in adjacent nodes — **synthesize across
  them in Phase 4/5, don't re-fetch.**

**Two narrow, optional exceptions** (only if a later phase actually proposes building on these):

1. *The session-end review-artifact spec.* If Phase 4 decides to build the artifact from gap (b)#1, a one-shot
   look at how others structure agent session-end handoffs (Ramp's verification loop node is already in-corpus)
   would be worth it — but that is **cross-node synthesis of material we already hold**, not new external research.
2. *Adversarial-generation in security review (b)#4.* Before deciding whether it beats the existing abuse-case
   lens `[GT §3d]`, a brief look at concrete adversarial-prompt patterns (fuzzing/exploit-construction prompts)
   would be justified — but this is a focused technique lookup, not deep research, and only if (b)#4 is greenlit.

Everything else (proxy, MCP, n-of-1, cultural adoption, intern hiring, the 20%/$250 figures) is org-scale or
self-report and does not survive transfer (pass2 §A/§B/§E/§G) — **no research warranted.**
