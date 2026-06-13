# Pass 2 — Penetrate: hidden theses, assumptions, contradictions

Building on pass1: the article (pass1 §2, §3) presents "API + CLI + Skills" as a single coherent
architecture and the CLI as "the agent's operating lever" (pass1 §3). pass1 §7–§9 record the article's
own application candidates and its honesty table. This pass goes underneath those: what is the article
actually arguing, what does it take for granted, where does it contradict itself or its corpus, and
what net-new structure emerges when you separate the layers it fuses.

## A. The hidden thesis: a SUBJECT/OBJECT inversion the article never names

Building on pass1 §2 and §7: the article treats 37signals' lesson and event-vendor's situation as the
SAME lesson ("the principle applies to development tools"). They are not. 37signals made *its product*
(Basecamp, a thing other people's agents operate) agent-accessible — event-vendor *is the agent's own
workbench*. 37signals is solving "how do OTHER people's agents drive MY product." event-vendor's harness
question is "how does MY agent drive MY tools." The article collapses these by analogy (pass1 §7 CLI
candidate) but they sit on opposite sides of the agent. The inversion matters because it changes WHO
benefits from a CLI:

- For 37signals, the CLI is a **product surface** — revenue/retention logic ("users choose their own
  AI"). The payoff is external.
- For event-vendor, a CLI over dev tools is **internal harness ergonomics** — the payoff is the agent's
  own autonomy and the reduction of UI-required steps in *its* loop.

This is the single most load-bearing reframing in the whole article for our purposes, and the article
does it implicitly in one table row (pass1 §9) without acknowledging the subject/object flip. Everything
in Pass 3 hinges on keeping these straight.

## B. "API + CLI + Skills" is three different bets fused into one slogan

Building on pass1 §2: the article presents the triad as one architecture with "two independent
confirmations" (pass1 §6, Vercel). Penetrating it, the three components are NOT co-equal and do NOT
share a justification:

- **API** is table-stakes determinism — a structured, scriptable surface. Old idea (REST predates agents).
- **CLI** is the article's actual novel claim: a *text-first, chainable* surface that an agent composes
  with OTHER CLIs (GitHub + Sentry + Basecamp — pass1 §3). The novelty is **composability across tools
  owned by different vendors**, not "CLI vs UI."
- **Skills** is *knowledge encoding* so the agent doesn't rediscover usage each session (pass1 §2).

These answer three different questions: *can* the agent act (API), can it *chain* actions cheaply across
tools (CLI), does it *know how* without relearning (Skills). The article's "two independent confirmations"
(pass1 §6) is weaker than presented: two companies converging on "expose API+CLI+docs" is partly just two
companies discovering that agents read text and run commands — a low bar that almost any tooling strategy
clears. The convergence is real but under-discriminating; it doesn't validate the *specific* triad over,
say, "API + MCP + docs."

## C. The unexamined assumption: CLI as the privileged surface — but agents now have MCP

Building on pass1 §3's claim that "CLI surface area determines how deeply agents operate a product":
the article (research-dated 2026-05) never weighs CLI against **MCP**, which is the other answer to the
exact same problem (give the agent a typed, discoverable, chainable tool surface). This is a real blind
spot, and it is verifiable from our own environment: this very session exposes dozens of MCP tools
(Notion, Supabase, Vercel, Figma, Gmail, Chrome) as first-class, schema-typed, deferred-loadable tools.
The article's "CLI vs UI" dichotomy is a 2025 framing; the live 2026 reality is **CLI vs MCP vs UI**, and
the interesting question — which the article never asks — is *when is a CLI better than an MCP server*:

- CLI wins on **cross-vendor chaining in one bash call**, on being inspectable/loggable as plain text,
  and on working in any shell without a running MCP host.
- MCP wins on **typed schemas, discoverability, and per-call permissioning** (our harness gates tools
  via `permissions.allow`; a CLI hides inside one allowed `bash` pattern and is invisible to that gate).

The article's silence here is the deepest hole in its reasoning. It universalizes a CLI thesis without
noticing that the agent ecosystem it's writing for already has a competing standard. (Tested concretely
in Pass 3c.)

## D. The contradiction the article half-buries: "remove all friction" vs. "burnout from removed friction"

Building on pass1 §2 (the API was avoided because "cumbersome, slow, expensive" — friction to remove)
and pass1 §5 (burnout because agents "remove friction so completely that natural stopping points
disappear"). The same word — friction — is the villain in §2 and the safety mechanism in §5. The article
notices the burnout but never reconciles the two: *some* friction was load-bearing (it paced the human),
and the agent-accessibility project's whole point was to delete friction indiscriminately. The honest
synthesis the article gestures at but doesn't state: **friction removal must be selective — kill the
friction that gates ACTION, preserve the friction that gates COMMITMENT/PACE.** This is exactly the
distinction our own canon already encodes elsewhere (the Model Capacity Audit's "if you can't name a
failure mode the constraint prevents, it's overhead" — but inverted: *some* constraints prevent a HUMAN
failure mode, not a quality one). The article has the raw material for this and leaves it unassembled.

## E. What the article takes for granted

1. **That a CLI is cheap to build and maintain.** 37signals has a team of 34 and treats CLIs as a
   product line. The article's solo-transfer (pass1 §9 "build CLI-first for any recurring admin op")
   silently assumes the maintenance cost of a hand-rolled CLI is near-zero for one person — it isn't;
   a CLI is a second interface to test, version, and document. The article never prices this.
2. **That house-skills is structurally transferable.** pass1 §7 proposes reading house-skills before
   authoring skills, but flags as an OPEN QUESTION whether it even uses the same frontmatter shape. The
   article recommends the reference *before* confirming the structures are comparable — recommendation
   ahead of verification.
3. **That "agent-accessibility" is a single axis.** It conflates (a) can-the-agent-reach-it with (b)
   can-the-agent-reach-it-SAFELY. 37signals exposing Basecamp to *any* user-chosen agent is a product
   bet with a permission model behind it; the article's transfer drops the permission dimension entirely
   — which, for a harness that runs UNATTENDED agents against a prod Supabase, is the dimension that
   actually matters.
4. **That the skeptic's conversion validates the tools.** pass1 §1 — "he updated when the tools got good
   enough." This is survivorship framing: one prominent convert is an anecdote, not evidence the tools
   crossed a general threshold. The article leans on DHH's authority to carry a claim his authority
   doesn't actually support.

## F. Net-new analysis: the two genuinely portable ideas, stripped of the product story

Stripping the 37signals product narrative and the solo-transfer hand-waving, exactly TWO ideas survive
as harness-relevant, and they are NOT the ones the article emphasizes:

1. **The agent's tool surface should be classified by accessibility tier, and UI-required steps are the
   tax on autonomy.** This is the article's Design Challenge (pass1 §8) and it is genuinely good *as a
   diagnostic* — not as a mandate to build CLIs, but as a way to find the steps that break an unattended
   run. The deliverable isn't "more CLIs," it's "a map of where the agent still needs a human/browser."
2. **Friction removal is not monotonically good; pace/commitment friction is load-bearing and must be
   re-introduced deliberately once action-friction is gone.** (Per §D.) This is the article's most
   original contribution and it's buried under the burnout anecdote.

The CLI-evangelism and house-skills-reference, by contrast, are the WEAKEST transfers — the first because
it ignores MCP (§C) and prices CLIs at zero (§E1), the second because it's unverified (§E2).

## G. Where the article argues against our own canon's direction — and is RIGHT to

Building on pass1 §2's "don't bake AI into the product": our harness's whole trajectory is the opposite
— it bakes deep, opinionated AI workflow INTO the project (skills, hooks, pipelines). The article's
contrast with Shopify (pass1 §6) maps our harness onto the *Shopify* side (prescriptive, baked-in), not
the 37signals side. That's fine and correct for a *harness* (it's the agent's environment, not a product
sold to users). But it surfaces a real tension worth naming: every skill body we add is the OPPOSITE of
"users choose their own AI" — it's "this harness prescribes exactly how the agent works." The article
gives us no reason to change that (a harness *should* be opinionated), but it does sharpen the question
of which prescriptions are load-bearing vs. scaffolding the model has outgrown — which is precisely the
§9 Model-Capacity-Audit question the ground-truth map already foregrounds.
