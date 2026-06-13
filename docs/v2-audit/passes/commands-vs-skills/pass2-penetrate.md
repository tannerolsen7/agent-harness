# Pass 2 — Penetrate

Building on pass1: I take pass1's separation of **durable mechanics** (the verified middle section)
from **claim-about-us recommendations** (the four "Application" sharpenings + Standing Rule), and
pass1's flag that the article embeds no curator passes — so the only thing to demote is the author's
own advocacy. Below I find the deeper thesis the article is actually arguing, the assumptions it
takes for granted, its internal contradictions, and net-new analysis it does not contain.

---

## 2.1 The real thesis, stated sharper than the article states it

Pass1 named two axes (who-triggers, how-it-loads). The article treats them as co-equal. They are not.
The deeper claim — which the article gestures at but never isolates — is that **the
command-vs-skill "merge" collapsed a packaging distinction but left a *control* distinction
standing, and that control distinction is now expressed entirely in one YAML field**
(`disable-model-invocation`). Everything else — filename, directory, body length — is now cosmetic.
The article's true thesis is: **invocation control is the only load-bearing decision left, and it has
moved from "which artifact type you choose" to "which frontmatter flag you set."** That is a sharper
and more useful claim than "there are two axes," because it tells you the *entire* old taxonomy
(command vs skill vs prompt) reduces to two flags plus a description string.

## 2.2 The hidden assumption: that the trigger model is reliable enough to *rely on*

The article's mechanic — "description IS the trigger, body is inert at activation time" (pass1, fact)
— is presented as a fix: move spawn conditions into the description and they will fire. **This takes
for granted that the model's description-matching is reliable enough to be load-bearing for
safety-adjacent behavior** (spawning a security-reviewer, parallelizing work). But the same article,
two sections earlier, warns "you do not want Claude *deciding* to deploy because the code looks
ready" — i.e., it distrusts model-judgment for side effects. **There is an unstated tension:** the
article wants model-judgment to be *trustworthy enough to trigger sub-agent spawns from a
description* but *untrustworthy enough to need a hard `disable-model-invocation` flag for deploys.*
These can both be true (low-stakes spawn vs irreversible deploy), but the article never draws the
line. The missing principle is: **description-triggering is appropriate exactly when a false-positive
trigger is cheap and reversible.** That is Pillar-2 logic (reversibility gates autonomy) applied to
*triggering*, which the article applies to *execution* but not to *activation*.

## 2.3 Contradiction: "description is the trigger" vs the canon's own anti-pattern

Building on pass1's flag that "Application" items concentrate staleness: recommendation #1
("move every spawn condition into the description, front-load trigger words") is in direct tension
with a constraint the article itself does not surface — the canon's **Model Capacity Audit** flags
**"phrase-keyed skill descriptions → trigger should be the situation, not the words"** as a
capability proxy to *replace* (this is ground-truth §9, which pass3 will cite). The article's phrase
"trigger-word-front-loaded `description`" is *literally the anti-pattern*. The article is internally
coherent only if you ignore that front-loading *words* and describing the *situation* are different
acts. A sharp description names the situation ("after a branch's review completes," "when more than
three exploratory searches are needed"); a keyword-stuffed one games the matcher. The article
conflates them, and its Standing Rule bakes the conflation in. **This is the article's most
consequential unforced error** — net-new relative to pass1, which only marked the item as a
claim-about-us.

## 2.4 What "structural" means here is weaker than the article implies

The article repeatedly equates `disable-model-invocation: true` with "structural enforcement"
(Pillar 1) and contrasts it with "a NEVER in the body = advisory hope." This is **half true and the
half it omits matters.** `disable-model-invocation` is structural *with respect to the model's
autonomy* — it removes the model's ability to auto-trigger the skill. It is **not** structural with
respect to the *action's safety*: nothing stops a human (or the model, once *you* invoke the skill)
from running the side effect. It governs *who starts it*, not *whether the dangerous thing can
happen.* A genuine structural backstop for a destructive action is a **PreToolUse/exit-2 hook** that
blocks the syscall regardless of who initiated it. So the article's "frontmatter flag IS the
structural enforcement" overstates: the flag is a *trigger-gate*, one tier weaker than a *kill-gate*.
For reversible side effects (open a PR) the trigger-gate is the right tier. For irreversible ones
(force-push, migration apply) the article's own Pillar logic should push it down to a hook — which
the article never says. (Net-new; pass3 maps this to a specific absent guard.)

## 2.5 The "799 lines" argument proves less than it claims

Recommendation #3 frames the always-loaded root as a *token-cost* problem solved by tiering. The
arithmetic (skills cost ~100 tokens until triggered; standalone files cost full length every session)
is correct (pass1, fact). But the article smuggles in an unexamined premise: **that the content in
those 799 lines is the kind that *can* move to tier 2/3 without losing its job.** Always-loaded
content earns its tier-1 cost precisely when it must shape behavior *before any task-matching has
occurred* — e.g., the destructive-operation rules, the "honest assessment over validation" stance,
the discipline checkpoint. Those cannot live in a tier-2 skill body that only loads "on description
match," because the situations they guard (an unprompted destructive command, a sycophantic drift)
have **no triggering task to match against.** The article treats line-count as fat to be trimmed; the
sharper view is that **tier-1 is for content with no trigger**, and the audit question is not "can
this move?" but "does this content have a natural trigger?" If yes → tier 2. If no → it *belongs* in
tier 1 regardless of length. The article's "~200-line target" is a number, not a principle; the
principle is **trigger-existence, not length.** (Net-new.)

## 2.6 Unexamined: the merge means our 26 body-only skills are already "the simplest form"

Pass1 recorded "a command is now the simplest form of a skill." Follow that through: it means our
existing Markdown-body skills are **already on the unified machinery** — we do not "migrate commands
to skills," we *add frontmatter to skills that lack it.* The article never states the corollary that
matters operationally: **the cost of adopting the frontmatter model is near-zero structurally** (no
file moves, no machinery change) but **high in judgment** (every skill needs a per-skill decision:
model-invocable or not, what situation triggers it, which tools to pre-approve). The work is not
plumbing; it is **26 individual control decisions**, each of which is a Pillar-1/Pillar-2 call. The
article's "audit every skill" undersells that this is a *governance* pass, not a refactor.

## 2.7 The plugin claim is a real answer but the article skips the cost

Recommendation #4 (plugin-as-package answers distribution) is the cleanest of the four — it names a
real, versioned, installable unit. But the article asserts "template-copy drifts; a plugin updates"
without pricing the plugin path: a plugin requires a **manifest, a namespace, a marketplace/registry
entry, and a version-bump discipline** — i.e., it converts the harness from "a folder of files" into
**a released product with a release process.** For a system that (per pass1's claim-about-us) has
"never been installed anywhere but one project," the plugin is the *correct destination* but a
*premature first step*: you cannot version-distribute a harness whose own canon and disk are in
bidirectional drift. The article's recommendation is right about the *endpoint* and silent about the
*precondition* (you must first converge canon↔disk before there is a stable thing to version). Net-new
sequencing insight.

## 2.8 The enforcement-tier test, extended to triggering (the durable lens this article adds)

The Zapier pass gave us an enforcement-tier test for *execution* (structural / mechanical / advisory,
matched to receiver). This article's genuine contribution, once de-hyped, is the **same test applied
to *activation*** — a third axis the Zapier lens didn't isolate:

> For each skill, two independent tier decisions:
> (A) **Activation control** — model-invoked (sharp situational description) vs explicit-only
>     (`disable-model-invocation`) vs model-only (`user-invocable:false`). Choose by *reversibility
>     of a false trigger* (§2.2).
> (B) **Load tier** — always (tier-1, for content with no trigger, §2.5) vs on-match body (tier-2)
>     vs on-demand reference/script (tier-3). Choose by *trigger-existence*, not length.

That two-decision grid is the article's transferable yield. Everything else (the four sharpenings) is
this grid pre-applied to our system — and pass3 must re-derive each against ground-truth rather than
inherit the article's answers, because §2.3 already shows one of them (front-loaded trigger words)
inverts our own canon.

## 2.9 What the author takes for granted about *us*

The article asserts as settled: Pillars 1/2/4, "open-thread #4," "Phase 1 spawning rule," a `/change`
skill, "Bucket 1 = 799 lines," "KILLED-list decision," "Node 14 Git-canonical." Pass1 flagged these
as claim-about-us pointing at a **planning/canon layer, not the ground-truth map.** The penetrating
observation: the article was written *against the V2 planning vocabulary, not against disk.* Its
confidence ("you already decided," "this is aligned") is borrowed from a layer that the ground-truth
map exists precisely to distrust. Pass3's first job is therefore **adversarial verification of the
article's premises about us**, not just its recommendations — because if `/change` doesn't exist, or
"799 lines" is wrong, the recommendation built on it is aimed at nothing.
