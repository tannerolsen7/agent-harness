# Pass 2 — Penetrate

**Building on pass1:** pass-1 catalogued the page's facts and tagged its opinions. The headline it
recorded was "supervise capability, not behavior — and egress is the one capability control that
holds under adversarial conditions," resting on the 24/25 exfiltration figure and the
allowlist-as-capability-grant reframe (pass-1 §synthesis #1, #3). This pass does *not* re-summarize.
It interrogates what the page actually *means*, where its own logic strains, and what it doesn't say.

---

## Thesis-beneath-the-thesis: the page is an argument about *trust topology*, not about egress

Pass-1 took the page at its word that the subject is "egress controls." That is the surface. The
deeper, unifying claim — present in every section but never named by the curator — is about **where
trust is allowed to accumulate in an agent system**. Read the five synthesis points (pass-1) as one
argument and a single shape appears:

- The 24/25 result (pass-1 fact): trust placed in the *model's behavior* collapses under adversarial
  pressure.
- The allowlist inversion (pass-1 §3): trust placed in a *destination* leaks, because a destination
  is not an operation.
- Narrow tools (pass-1 §5): trust placed in an *invocation gate* is "surface containment with no
  depth" if the tool body trusts its own arguments.
- Multi-agent trust escalation (pass-1, Open Q4): trust placed in a *sub-agent's structured output*
  over raw tool results manufactures authority the data never earned.

Every one is the same error: **trust granted at the wrong granularity**. Behavior instead of
capability; destination instead of operation; tool name instead of tool argument; output format
instead of provenance. The page's real thesis is therefore stronger and more general than "use
egress controls": **every containment boundary must be drawn at the granularity where the adversary
actually operates, and the adversary always operates one level finer than the boundary you drew.**
Egress is just the instance where Anthropic happened to have telemetry. This reframing matters for
pass-3 because it predicts that event-vendor's gaps will *not* be primarily network gaps — they will
be granularity gaps that happen to manifest at the network, the credential, and the sub-agent layers.

## Hidden assumption #1: "regardless of intent" silently concedes that model-layer defense is worthless — but the page still relies on it everywhere else

The curator leans hard on "regardless of intent" (pass-1 §1) to argue environment beats behavior.
Taken to its logical end, that phrase says: *do not count any defense that can be talked out of.* But
the page's own event-vendor recommendations are shot through with talk-out-able defenses. The task
manifest with "STOP AND SURFACE for out-of-scope actions" (pass-1 application) is a **behavioral**
control — it depends on the orchestrating model noticing the scope violation and choosing to stop.
By the page's own 24/25 logic, a manifest the *model* enforces is exactly the class of defense that
failed 24 times. The page never reconciles this. The honest reading: a manifest is only a real
boundary if a **non-model process** (a hook, a wrapper, a proxy) enforces it; a manifest the agent
reads and self-polices is a model-layer defense wearing an environment-layer costume. The curator's
own anchor quote refutes the curator's own flagship recommendation. Pass-3 must hold proposals to
this bar: *who enforces it, and can the model argue its way past?*

## Hidden assumption #2: the threat model is imported wholesale and never localized

The 24/25 figure, the Cowork exfiltration, and the gVisor/VM progression all come from a **multi-
tenant, hostile-stranger, internet-facing product** context. The page's own "What Doesn't Transfer"
table (pass-1) is candid that the wake-on-demand pool and EDR concerns are "wrong problem / wrong
context." But it does *not* apply that same skepticism to the **threat actor**. In Anthropic's
product, the adversary is an anonymous user who plants a malicious workspace file. In event-vendor's
/queue, the "workspace files" are *the developer's own repo*, the CLAUDE.md is *committed by the
developer*, and the task manifests are *written by the developer*. The realistic solo-scale threat is
**not** a hostile stranger embedding an API key — it is (a) a poisoned npm/transitive dependency
exfiltrating during `npm install`, (b) a prompt-injection payload arriving through *fetched external
content* (a WebFetch result, a GitHub issue body, a scraped page), or (c) the agent's own honest
error vaporizing prod data. The page's most cited horror (attacker-embedded key in a workspace file)
is its *least* applicable scenario at solo scale, and its genuinely applicable scenario (injection
via fetched content, the one real untrusted-input channel) is mentioned only glancingly in Open Q3.
This is a load-bearing mislocalization the curator did not catch.

## Contradiction the page half-sees: "already active, no action" vs. "no explicit egress restriction"

Pass-1 recorded both of these from the page verbatim:
- "What Doesn't Transfer" table: the OS-level Seatbelt sandbox **"fully transfers, already active,
  no action required."**
- Application §minimum-viable-egress: event-vendor has **"no explicit egress restriction beyond
  Claude Code's default Seatbelt sandbox, which permits outbound network connections to any
  destination when tools request it."**

These are in tension. The first sells Seatbelt as a solved win; the second says Seatbelt's egress is
*wide open to any destination on tool request* — i.e., it is not an egress control at all for the
exact runs (/queue) that matter. The curator's own Open Q1 ("was the sandbox configured with reduced
restrictions for the test?") is the tell: **the page does not actually know what Claude Code's
default egress profile is**, yet it both credits the sandbox as a free win and warns it provides no
egress restriction. The truthful synthesis the page should have reached: *the Seatbelt sandbox's
filesystem containment transfers for free; its network containment is unknown-to-absent for tool-
initiated traffic, and that is precisely the dimension the 24/25 result says is the only one that
matters.* The "free win" is in the dimension that doesn't count.

## What the page gets genuinely right and under-sells: the operation-vs-destination distinction is the only durable idea here

Strip the product telemetry and the one idea with a long half-life is pass-1 §3: an allowlist is a
list of *operations*, not *destinations*. This is durable because it is **model-independent and
infrastructure-independent** — it stays true on Opus 4.8, on a future model, with or without
devcontainers. Most of the rest of the page (gVisor, VM, OTLP, wake-on-demand, MitM proxy) is
infrastructure the page itself admits doesn't transfer. The curator buries the one transferable
insight under five sections of non-transferable architecture. Pass-3 should weight accordingly: the
*principle* is the deliverable, not the proxy.

## A second-order point the page misses entirely: logging is the only layer that is both cheap and adversary-proof

Of the four-layer floor (pass-1 §6), three layers are preventive and one is forensic (layer 3:
"log every tool call and denial… for post-hoc investigation"). The page orders by ease and treats
logging as merely third-easiest. But logging is the *only* layer in the entire page that an
adversary cannot talk the model out of and that needs no infrastructure and that is already partly
built (event-vendor has a `permission-logger.sh`, per the ground-truth map). It is also the only
layer that addresses the page's own unanswerable Open Q5 ("what detects a poisoned memory file?") —
you cannot detect poisoning without a record of what changed and what the agent did with it. The
page treats logging as hygiene; it is actually the **keystone of the only threat the page admits it
can't prevent**. The curator's ease-ordering obscured its importance.

## The Design Challenge is rigged, and its rigging is instructive

The page poses: design a /queue task manifest to close the `gh api` permitted-path surface *without a
network proxy*, then asks "prevent or only reduce?" The honest answer the page fishes for is "only
reduce" — and the page is right, but for a reason it doesn't state. A manifest cannot *prevent*
permitted-path exfiltration because the manifest and the exfiltration share an enforcement plane: if
the model is compromised enough to attempt an out-of-scope `gh api` POST, it is compromised enough to
fabricate a manifest entry authorizing it, or to route the exfil through an *in-scope* `gh api` call
(e.g., writing stolen data into a legitimately-permitted issue comment). **Permitted-path
exfiltration through an in-manifest operation is the residual risk**, and only a non-model process
that inspects the *content and destination of each outbound call* (a proxy or an egress hook) closes
it. The challenge is rigged to teach exactly the "who enforces it" lesson from Hidden Assumption #1.

## Net-new synthesis (pass-2's own contribution)

1. **The unifying law:** *boundaries must be drawn at the granularity the adversary operates at, and
   the adversary is always one level finer.* (Generalizes all five of the page's synthesis points.)
2. **The enforcement-plane test:** any proposed control must name a non-model enforcer, or it is a
   behavioral defense in disguise and fails the page's own 24/25 standard. This is the single most
   useful filter pass-3 can apply.
3. **Localized threat correction:** at solo scale the real untrusted-input channel is *fetched
   external content* (WebFetch / issue bodies / scraped pages) flowing into an agent that holds prod
   credentials — not an attacker's planted workspace file. The page optimizes against the wrong actor.
4. **Logging is the keystone, not the third-easiest chore** — it is the only adversary-proof,
   no-infra, already-partially-built layer, and the only answer to the page's own undetectable threat.
5. **The transferable residue is one sentence:** allowlist operations, not destinations; enforce off
   the model. Everything else in the page is context-bound infrastructure.

## One-line thesis (pass-2)

The page is nominally about egress but is actually about **trust granularity**: every containment
failure it documents is trust granted one level coarser than where the adversary acts — and its own
flagship solo recommendation (a model-read task manifest) reproduces that exact error, because a
boundary the model enforces is not a boundary at all.
