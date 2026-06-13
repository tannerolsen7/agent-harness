# Pass 2 — Penetrate: deeper thesis, hidden assumptions, contradictions

Building on pass1: this pass takes the three headline ideas (pass1 §A), the rules taxonomy
(§B), the cultural-accountability claim (§C), and the curator's own "Application" extrapolation
(§E) and pushes past what the page *says* to what it *assumes*, *omits*, and *quietly
contradicts*. New analysis only — not a re-summary.

---

## 1. The real thesis is narrower than the page's three headlines suggest

Building on pass1 §A, the page presents three co-equal ideas — the FTE metaphor, the Context
Engine, and probabilistic-vs-deterministic enforcement. They are not co-equal. **Two of the
three are load-bearing for us; one is a vendor moat that doesn't transfer**, and the page's own
"What doesn't transfer" table (pass1 §F) admits it: the Context Engine is "mechanism differs."
Strip the vendor-specific Context Engine and the page collapses to a single, sharp claim:

> **Context is what shifts the probability of correct behavior; enforcement is what removes the
> tail risk. You need both layers, and you must not confuse one for the other.**

Everything else — the metaphor, the rule taxonomy, the table-vs-prose figure — is in service of
that one claim. The page is strongest when read as an argument about **two layers that must not
be conflated**, and weakest when read as an argument about indexing technology.

## 2. The hidden assumption under the FTE metaphor: context is additive and durable

Building on pass1 §A, the contractor/employee metaphor smuggles in an unexamined premise: that
**FTE context is a stock you accumulate**, like an employee's tenure. The metaphor implies that
more context files = more FTE-ness = better behavior, monotonically. This is the same
assumption that produces bloated `CLAUDE.md` files. The metaphor has no concept of **context
decay, contradiction, or cost** — a real FTE also carries stale assumptions, cargo-culted
rituals, and "we've always done it this way" reflexes. The page never asks: *what is the FTE
equivalent of a context file that has gone stale or now contradicts the model's own better
judgment?* This is precisely the failure mode our ground-truth map already names — the canon's
own Page-13 Model Capacity Audit calls these "ghost rules" and "capability proxies" the current
model no longer needs (map §9). **The FTE metaphor, taken literally, argues *against* the very
pruning the canon mandates.** That tension is invisible inside the page.

## 3. "Rules are probabilistic" and "tables beat prose +25%" are in quiet tension

Building on pass1 §A.3 and §D: the page treats both as supporting the same conclusion
(structure your context). They actually pull apart. If compliance is fundamentally
*probabilistic* (§A.3), then a +25% improvement from tables is a probability shift — useful, but
by the page's own logic **it can never be relied upon for anything that matters**, because the
whole point of the probabilistic framing is that the remaining tail is what hooks/CI exist to
catch. So the +25% figure, even if true, is an argument for *better odds on the cheap stuff*,
not for moving any safety-critical rule out of the deterministic layer. The page half-sees this
(its "Application" §1 limits table-conversion to "conditional logic, not all content") but never
states the limit as a principle: **table-conversion is a probability optimization and therefore
belongs only to rules that are NOT also enforced by a hook.** Spending effort table-formatting a
rule that should instead be a hook is mis-spent effort dressed as rigor.

## 4. The three-tier taxonomy is a *loading* model, not an *enforcement* model — and the page conflates them

Building on pass1 §B, the always_apply / agent_requested / manual taxonomy answers one question:
*when does this text enter the context window?* It says nothing about *whether the agent obeys
it once loaded*. The page's open-question #2 (pass1 §H) actually spots this — "is the probabilism
in the load decision or in the agent following the rule once loaded?" — but then the synthesis
forgets it and maps the three tiers cleanly onto CLAUDE.md/skills/prompts as if loading were the
whole story. The penetrating point: **a rule can fail at three independent stages — not loaded,
loaded-but-ignored, obeyed-then-rationalized-away** — and the taxonomy only addresses the first.
Our harness's anti-rationalization tables and the `memory.md` "steps cannot be rationalized away"
rule exist precisely because stages two and three are real and the loading taxonomy is blind to
them. Augment can be blind to stages 2–3 because its Context Engine + managed product absorbs
them; a solo harness cannot.

## 5. "Automation bias is cultural, not technical" is the page's most dangerous claim for an *unattended* harness

Building on pass1 §C: Perneti's "the person pushing the PR owns the code, period" is correct **in
a human-in-the-loop team** where a person physically merges. It is the load-bearing assumption
of the whole accountability story — and it **silently breaks the moment the agent runs
unattended**. In an AFK/UNATTENDED session there *is* no person pushing the PR in real time; the
accountability is deferred to a review that may happen hours later, against a branch the human
never watched form. The page never notices that its accountability solution is a human-presence
solution. Worse, the curator's *own* "Application" section (pass1 §E.2) is about **expanding
unattended operation** — so the page simultaneously (a) leans on cultural accountability that
requires a human in the loop and (b) recommends removing the human from the loop. That is an
unacknowledged contradiction, and it is exactly the seam where the PocketOS-class incidents live
(map §9 keeps the destructive-operation rules verbatim *because* culture is not present at 3am).
**For an unattended harness, "cultural, not technical" is not a finding to adopt — it is a gap to
close with technical means.** The page's own probabilistic-enforcement principle is the rebuttal
to its own accountability claim; it just never turns the principle on itself.

## 6. The page's notion of "the system" is the canon, and it never verified it against disk

Building on pass1 §E and §F: the "Application to This System" and "What doesn't transfer"
sections describe a system that (their words) needs to "add the hooks layer" and treats the
three-tier rules as "already in the system." This is a snapshot of the **Notion canon's**
self-image, written before any disk audit. The penetrating observation — which only the
ground-truth map can supply — is that **the disk reality is the opposite of what the page
assumes on both counts**:
- The page says "add the hooks layer (Gap 1)" as if hooks don't exist. Disk has **five Claude
  hooks + three git hooks** already (map §3e). The gap is not *absence* of a hooks layer; it is
  the layer being **partial and partly wired-out** (the canon-matching `.githooks/pre-commit` is
  dormant under `core.hooksPath=.husky/_`; map §3e, §3f).
- The page recommends exactly its "3 hooks" — PreToolUse sensitive-file block, Stop test-check,
  SessionStart TASKS injection. Disk **already has** a PreToolUse dangerous-bash/git guard
  family, a SessionStart hook, and a WorktreeCreate prod-key firewall (map §3e). So the page's
  flagship recommendation is **already ~2/3 built** and the curator didn't know.

This is the single most important thing pass 3 must do: **the page's value is not its
recommendations (stale) but its *principle* (durable).** The recommendations were aimed at a
phantom.

## 7. What the page takes for granted that is actually the hard part

Building on the above, three things the page treats as solved-by-assertion:
- **"Make violations structurally impossible" via hooks.** (pass1 §A.3) Easy to say; the hard
  part is that hooks that *fail-open* are theatre. Our map records that `block-dangerous-git.sh`
  and `block-npm-install.sh` **fail open on missing jq** (map §3e). A deterministic guard that
  silently degrades to permissive is *probabilistic enforcement wearing a deterministic costume*
  — the exact confusion the page warns against, instantiated in our own disk. The page has no
  concept of guard-integrity.
- **"What can be inferred vs what cannot."** (pass1 §B) Presented as a clean line. In practice
  the boundary is contested and shifts with model capability: Opus 4.8 can infer more from the
  codebase than Sonnet 4.6 could, which means the set of rules that "cannot be inferred" *shrinks
  over time*. The page's taxonomy is static; the boundary is a moving target the Model Capacity
  Audit (map §9) is explicitly designed to re-cut.
- **The 200k-token threshold as a clean switch.** (pass1 §A.2) Presented as full-context-below /
  index-above. It ignores that *which* tokens you load is the real variable; a badly-curated 50k
  is worse than a well-curated 150k. The threshold is a vendor-convenient simplification.

## 8. Net penetrating thesis

The page's durable contribution is one principle stated more cleanly than anywhere else in the
research: **probabilistic context and deterministic enforcement are two different layers, and
every rule must be consciously assigned to one or the other.** Its three failures are (a) it
never turns that principle on its own other claims — accountability-as-culture and tables-beat-
prose both *violate* the principle when applied to safety-critical rules; (b) its model of "the
system" is a pre-audit canon snapshot, so its concrete recommendations target absences that don't
exist on disk; and (c) it has no concept of the failure modes that make a deterministic layer
*fake* — fail-open guards, wired-out hooks, and a "cannot be inferred" boundary that moves with
the model. Pass 3 keeps the principle, discards the recommendations, and uses the ground-truth
map to find where the principle actually bites.
