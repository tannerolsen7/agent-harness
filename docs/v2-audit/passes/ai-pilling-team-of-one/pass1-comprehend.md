# Pass 1 — Comprehend: "AI-Pilling a Team — The Readiness Framework, Filtered for a Team of One"

**Source.** Notion page `37be2971cd628148a7f2ea60d5f54513`. Synthesis of Claire Vo & Zach Davis,
"AI-Native EPD Org" (Maven course), Vo's "3 Workflows to Make Your Codebase AI-Ready" (chatprd.ai),
and Davis on Lenny's Podcast. The page is *not* a neutral article — it is already a curated/filtered
write-up that bundles (a) a faithful summary of the Vo/Davis framework with (b) the curator's own
verdicts on how it maps to "this system" (our harness). Per task instructions, all of (b) is treated
as **claim-to-verify**, not inherited fact, and is tagged below.

> **Provenance caveat the page itself states (fact).** The original "AI-pill your team" LinkedIn post
> is gated; per-item wording is "verified-in-substance, paraphrased." The LaunchDarkly throughput
> figures are the authors'/LaunchDarkly's self-reported numbers, "not independently audited." A second
> source (LinkedIn #5, `lnkd.in/epJRFjyi`) was unresolvable (403 to non-logged-in fetch) and is an
> open item. So even the framework summary rests on paraphrase, not primary text.

---

## A. The spiky thesis

- **(opinion — the authors', endorsed by curator)** *"Your codebase is the bottleneck. Not the models.
  If a new hire can't get productive in your repo, agents can't either."* The page calls this the part
  "worth tattooing on the wall."
- **(opinion)** The curator's framing claim: the framework "has a genuinely useful core wrapped in a
  layer of large-org change-management," and "the job here is to separate the two."

## B. The three-pillar framework (the authors')

**Pillar 1 — Technical Readiness ("the codebase is the bottleneck"). (opinion, org-size-agnostic core)**
Six specifics, all paraphrased by the curator:
1. **(opinion)** *Stop chasing incremental velocity.* Don't settle for "PRs up 20-30%"; restructure for
   multiples.
2. **(opinion)** *Centralize agent rules.* One rules system across tools (Cursor, Claude Code, Devin),
   not per-tool duplicated docs.
3. **(opinion)** *Specs/PRDs code-adjacent.* Specs live in-repo as version-controlled, agent-readable
   Markdown — "what's good for humans is also good for LLMs."
4. **(opinion)** *Fast feedback loops + guardrails* (automated PR review, visual regression) so agent
   output can be trusted.
5. **(opinion)** *Background agents* in cloud sandboxes so people ship without local-env setup.
6. **(opinion)** *Compound engineering / skills:* turn anything done >once into a reusable Markdown
   skill — and have agents write the skills.

**Pillar 2 — Cultural Readiness (adoption). (opinion)** "Convert skeptics by engineering their first
win, not by mandating tools." Build a champion network; make AI use visible/contagious across functions.

**Pillar 3 — Operational Readiness (roles + process). (opinion)** Recalibrate timelines built when
implementation was the expensive part; navigate role evolution (engineers→reviewers, PMs prototyping,
designers shipping frontend); rethink spec-to-ship when prototyping is nearly free.

**Proof point cited. (fact, but self-reported)** At LaunchDarkly the program drove 150 engineers using
AI weekly, with ~36% of committed frontend code AI-generated. The page flags these as self-reported.

## C. The team-of-one filter (the curator's central move)

**Transferable — technical pillar "scales down cleanly." (opinion)**
- **Specs-as-code in the repo** — "highest-leverage, near-zero-cost… single most portable idea."
- **Centralized, tool-agnostic agent rules** — one source of standing instruction.
- **Compound engineering / reusable skills** — "compounds *harder* solo" because you are your own
  bottleneck; every automated rep buys back your time directly.
- **Background agents + guardrails** — solo founder gets the biggest *relative* multiplier; "closest
  thing to hiring without hiring, but only safe behind real gates."

**Skip — "manager-of-large-org advice." (opinion)**
- The entire **Cultural pillar** (no skeptics to convert when it's you).
- **"Make the case to your board"** (n/a unless fundraising on a velocity narrative).
- **Role-evolution choreography** (in a team of 1–3 everyone wears every hat already).
- **Org-wide metrics** (150 eng, 36%) — "credentialing, not a target."

**The "2-3x PRs" caveat. (opinion + cited internal finding)** PR *volume* is rarely the binding
constraint for a tiny team — judgment, product direction, review bandwidth are. The curator ties this
to a prior internal finding ("Svpino R1"): more PRs (+98%) and bigger PRs (+154%) with *zero* DORA
improvement. Verdict: take the mindset reframe ("'I'm blocked' is outdated"), leave the volume target.

## D. The curator's "Application to This System" — ALL CLAIMS-TO-VERIFY

The page asserts the framework "mostly validates where you already are." Specific claims (each is a
claim about OUR harness that pass 3 must check against the ground-truth map):
- **(claim)** *"Codebase is the bottleneck"* = our entire harness thesis; quotable directly in AGENTS.md.
- **(claim)** *Specs-as-code* = our `/change` → `docs/specs/` decision (cites "Node 14"); "yours is
  enforced, theirs is advisory… you're ahead."
- **(claim)** *Centralized agent rules* = our AGENTS.md single-root, "made structural."
- **(claim)** *Compound engineering / skills* = our `/compound` + **`learned-patterns.md`** "executable
  constraints… you've built the rigorous version."
- **(claim)** The one forward-looking item is *"engineer the first win"* — irrelevant for converting
  yourself, becomes the playbook "the day you bring Monica deeper… or add your first 1-2 engineers."
  Parked alongside a "Leland Eight-Principles team-alignment doc."
- **(claim)** **Net:** "this is a confirmation page, not a change page."

## E. The standing rule the page proposes (claim-to-verify)

- **(opinion/proposed rule)** When reading team-AI-adoption advice, keep only the technical-readiness
  layer (codebase, agent rules, specs-as-code, guardrails) — true at any size — and discard the
  cultural/operational layers until a team exists. And: never adopt a throughput target ("2-3x PRs") as
  a goal; the binding constraint is review bandwidth.

## F. What the page does NOT do
- It does not engage with global vs project harness scope, memory model, hooks/enforcement, or any of
  the structural drift the ground-truth map centers on. Its lens is "adoption readiness," not harness
  architecture. Its "Application" section is therefore thin on our actual V2 questions (noted for p3).
