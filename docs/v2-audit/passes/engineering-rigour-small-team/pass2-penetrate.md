# Pass 2 — Penetrate

Building on pass1: this pass does not re-summarize. It interrogates what the article *means*, what
it assumes, where it contradicts itself, and what it takes for granted. Net-new analysis only.

## 1. The real thesis is narrower (and better) than the headline
Building on pass1's "core question" and "what to skip" sections: the article's banner claim ("rigour
comes from process not model") is the *least* load-bearing thing in it. The article itself concedes
this is "true" and immediately pivots — its actual thesis is a **filter**, not a claim:

> a habit only earns a place in this repo if it survives the team-of-1-to-3 filter.

This is the article's one original move. Everything else (Guides/Gates/Guards, failing-test-first,
context-in-repo) is borrowed and already widely held. The penetrating read is that **"process over
model" is a Trojan horse for a *subtraction* argument**: the author is using a popular, agreeable
thesis as cover to argue that most of the celebrated discipline is org-scale ceremony that a small
team should *delete*. The five "converge" points (pass1 §convergence) are throat-clearing; the three
"skip" categories and the "risk-tiered review" reversal are the payload. Read this way, the article is
philosophically aligned with the ground-truth map's own Page 13 "Model Capacity Audit" (`[canon §9]`):
both say *name the failure mode the constraint prevents, or cut it.* The article arrives at the same
deletion-bias from the **team-size** axis that Page 13 arrives at from the **model-capability** axis.
Those are two independent justifications for the same cut list — a convergence the article does not
notice, and the single most useful thing in it.

## 2. The Guides/Gates/Guards frame hides a category the harness depends on
Building on pass1's restatement of Rossi's three-G vocabulary: the frame is clean but **lossy**. It
has no slot for the thing that makes our harness distinctive — **the advisory layer**: skill bodies,
CLAUDE.md prose, SOUL/values, reasoning discipline. In the three-G model, those collapse into
"Guides," but Guides-as-loaded-instructions and Guides-as-*judgment-shaping-doctrine* are different
animals. A Gate blocks deterministically; a Guide-instruction tells the agent *what to do*; but the
PocketOS destructive-op rules, the "honest assessment over validation" principle, the discipline
rule's three questions — those shape *how the agent reasons*, and they are neither deterministic nor
mere instructions. The three-G frame, applied literally, would tempt a reader to demote all
non-blocking doctrine to "just a Guide" and then ask "can a Gate replace it?" — which is exactly the
capability-proxy-vs-reasoning-discipline distinction the ground-truth map flags as the hard line
(`[canon §9]`: "keep verbatim — reasoning discipline / safety"). **The frame is useful for what it
makes blockable and dangerous for what it makes invisible.** Net-new: the harness needs a *fourth* G
the article doesn't supply — call it **Doctrine** (judgment-shaping, non-blocking, non-instructional).
That is the layer the article's own "standing rule" lives in, so the frame can't even describe its own
conclusion.

## 3. Hidden assumption: review and reversibility are cleanly knowable in advance
Building on pass1's "how much to review" disagreement: the author resolves it elegantly — "review
scales with reversibility, not with source" — but this **smuggles in an assumption that
reversibility/blast-radius is legible at review time.** It often isn't. A one-line change to a
`src/data/` function that *looks* reversible can silently widen an RLS-adjacent query; a "low-risk"
copy change on `/p/[token]` is on the single client-facing surface where one bad render costs a $30k
client. The author names auth/schema/payments/proposal-send as the high-blast-radius classes, but the
hard cases are the ones that *don't announce themselves*. The honest version of the rule needs a
**default-to-scrutiny tiebreaker** and a cheap classifier (which paths/globs are always "irreversible
tier") — otherwise "scales with reversibility" degrades into "scales with whatever the tired solo dev
*felt* was risky," which is the burnout failure mode dressed up as discipline. The article gestures at
the right rule but leaves the classification mechanism — the part that would make it *executable* —
entirely to the reader.

## 4. The article contradicts its own standing rule on the one thing it tells you to add
Building on pass1's "one steal" and "standing rule": the standing rule says *every new capability is
evaluated by what gate/guard it lets you remove or strengthen — never by how smart it is.* But the
"one steal" — enforce failing-test-first on bug fixes — is justified by **cross-corroboration and
cheapness**, not by naming the gate it strengthens or the failure mode it closes that the existing
`/tdd` scope leaves open. It's a *good* addition, but the article applies its own rigour
inconsistently: it demands failure-mode justification for cuts (pass1 "skip" list) and for new
capabilities (standing rule), then adds a rule on authority/popularity grounds. The failure mode *does*
exist and is nameable (a bug fix that changes behavior with no characterization test can silently
re-break or mask the bug, and nothing in the current `src/data`-scoped TDD covers bug fixes to
*components* or *actions*) — but the article doesn't do that work; it leans on "most cross-corroborated."
By its own standard that's the weak-proxy move it warns against.

## 5. What the author takes for granted about our harness (the embedded-curator risk)
Building on pass1's "Application to this system" claims: the article speaks with insider confidence
about the reader's internals — "your five pillars," "Pillar 3," "Node 14 canon inversion," "Ashby item
1," "`learned-patterns.md`," "recursive-improvement synthesis." These are asserted as *settled facts of
the harness*. Pass 3 must verify each against the ground-truth map, because the map already shows the
harness's self-description is unreliable: `learned-patterns.md` is a **confirmed phantom** — referenced
on disk, never built (`[disk HARNESS-AS-IS §7]`, map §6 "Phantom refs"). So the article's flagship
recommendation ("add the rule to `learned-patterns.md`") **targets a file that does not exist.** This
is not a small slip; it reveals the article was written against the *aspirational canon's vocabulary*,
not against disk reality — the exact failure mode the ground-truth map was built to catch ("no proposal
survives without a citation to a row in this map"). The article cites the canon's imagined furniture as
if it were installed. Net-new: the article is itself an instance of the **canon↔disk drift** the map
documents, which makes it a useful *test case* for the map even where its recommendations miss.

## 6. The token-cost aside is the article's most under-argued claim
Building on pass1's "one more" (Rossi's Claude→Codex >90% spend cut): this is dropped in as a "live
data point" with no examination. It's a 2026 datapoint about a *different developer's* workflow on a
*different model pairing*, offered to a reader the article elsewhere insists has a "more rigorous"
process. A >90% cost cut from a model swap almost always means the *workload changed* (fewer/cheaper
calls, less fan-out), not that the new model is 10x cheaper per equivalent unit of work. Presenting it
as a tool-choice lever without separating "cheaper model" from "less work per task" is the same
correlation-as-cause sloppiness the article condemns in LOC metrics. For a reader whose real cost
driver is *subagent fan-out and parallel worktrees* (which the article elsewhere tells them to use
sparingly), the actual lever is **call volume and blast-radius-scaled fan-out**, not vendor. The
article half-sees this ("the same lever") but buries it under a vendor anecdote.

## 7. Unexamined tension: "delete org ceremony" vs. a harness built for unattended autonomy
Building on pass1's "skip" list (esp. multi-agent parallelism and PR ceremony): the article's whole
frame assumes a **human-in-the-loop solo dev** whose scarce resource is *attention*, and optimizes to
spend that attention well. But the ground-truth map describes a harness increasingly built for
**unattended/background agent runs** (Tier-0 credential firewall, UNATTENDED worktree mode, sentinel
chains, `permission-logger.sh`). In an unattended run there *is no human attention to economize* — so
"risk-tiered review that lets tests carry the reversible paths" inverts: the deterministic gates become
*more* load-bearing, not less, because no one is watching. The article's advice ("use worktree
isolation for safety, not parallel throughput") is sound, but it doesn't grapple with the fact that the
reader has deliberately built toward the very parallel/unattended posture Nakazawa calls himself
"ineffective" at. The unresolved question the article raises but won't touch: **does risk-tiered,
attention-economizing review even apply when the reviewer is also an agent?** That is the genuinely
open problem for *this* harness, and the article's small-team frame is blind to it.
