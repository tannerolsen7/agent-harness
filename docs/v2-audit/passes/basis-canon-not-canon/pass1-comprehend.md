# Pass 1 — Comprehend: what the Basis article says

Source: "Research · Basis — Canon/Not-Canon, Context Maintenance & Agent-Native Org Design (2026)"
(Notion `36ce2971cd6281608dcbc56b81d4cddb`). Primary underlying source: Basis Engineering blog "Making
Our Monorepo Ergonomic for Agents" (Atlas team). The article author could not fetch the blog directly;
all blog claims are routed through two earlier frozen Notion snapshot pages. This pass records what the
article **says**, tagging claims `(fact)` / `(opinion)`. Faithful, not interpretive.

> Provenance caveat (the article's own): every "blog post" claim is **secondhand** — derived from prior
> Notion snapshots, not the original article. The article flags this and tags those rows "Verified" only
> in the sense of internally cross-checked. I carry that caveat forward; "(fact)" below means "the
> article asserts it as verified," not "I independently confirmed it."

## Who Basis is (framing)
- Basis is a production accounting-AI company: \$100M Series B at \$1.15B valuation, Feb 24 2026; \$138M
  total raised; ~30% of top-25 accounting firms as customers. (fact — Business Wire / multiple, primary)
- It builds **long-horizon agents** that "autonomously work on complex accounting workflows over many
  hours." (fact — Business Wire)
- The **Atlas team** owns internal agents + context across engineering, sales, and talent. (fact — CPA
  Practice Advisor / IAB)
- Thesis-level claim: Basis's internal engineering practices **mirror** its external product philosophy,
  which makes its report uniquely credible — "eating their own cooking." (opinion — author's framing)

## The reframe that drives everything
- A human onboards to a codebase once; an **agent onboards from scratch every task**. Basis went from a
  handful of human onboardings/month to **thousands of agent onboardings/month**, so every inconsistency
  or gap "gets hit thousands of times instead of occasionally." (fact, as reported)
- Therefore: **your codebase is now two things at once** — source code that runs, and context agents use
  to decide. Optimize only the first and agents guess at the second. (opinion — the article's central
  reframe)

## The five principles (the spine)
Canonicality, Localization, Verifiability, Interoperability, Default-no. (fact — listed as Verified)

## Canon vs not-canon (the "foundational unlock")
- **Canon** = treat as source of truth about the *current* system: root `AGENTS.md`, nested `AGENTS.md`,
  skills, `docs/`, inline comments/docstrings. (fact)
- **Not-canon** = intent / history / hypothesis: `.specs/`, Linear tickets, `.notes/`. (fact)
- The failure mode: agents (and humans) **treat not-canon as canon** — a Linear ticket describing a
  never-built feature, a spec for an abandoned direction — and then "reason incorrectly with complete
  confidence." (opinion — the article's diagnosis)
- The distinction lets agents use non-canon for *why* (history) without taking it as *is* (authority).
  (opinion)

## Default-no ("every token loaded is a tax")
- Context loaded automatically must earn its place; default-include makes files balloon, default-exclude
  makes every line justify itself. (fact — stated as a Basis principle)
- "Stating it negatively is intentional" — default-no is a deliberate architectural stance, distinct
  from the softer "be selective," which "invites well-intentioned drift." (opinion)

## The six-layer architecture (as a cost/dependency graph)
1. **Root `AGENTS.md`** (~300 lines) — seen by every agent every session; highest cost, highest leverage;
   "prime real estate." (fact: ~300 lines / treated as prime real estate)
2. **100+ nested `AGENTS.md`** — the primary scaling mechanism; "100 without paying for them" in sessions
   that don't touch those dirs. (fact: 100+ files; opinion: the scaling argument)
3–4. **Skills + sub-agent roles** — on-demand, loaded only when needed. (fact)
5. **Unified MCP** — external API layer (Linear, Slack, Better Stack, PostHog, dev database). (fact)
6. **Tests** — enforcement backstop. (fact)
- Each layer has "a single job and doesn't bleed into the others." (opinion)

## Sub-agents
- **Verifier sub-agent**: runs **diff-scoped** tests + pre-commit hooks (not the full suite — too slow),
  before the PR surfaces to humans. (fact)
- **Standards-enforcer sub-agent**: validates changed code against **all applicable** `AGENTS.md` files +
  skills, before PR. (fact)

## Automated context maintenance (the piece the article says no one else has)
1. **CI/CD check** — validates frontmatter, descriptive prose, grammar on every merge. (fact)
2. **Daily scanner** — sweeps skills + `AGENTS.md` for staleness, contradictions, duplicated
   instructions, broken references, missing context for recent changes. (fact)
3. **Daily workers** — pick up scanner tickets, implement small scoped fixes. (fact)
- This is only possible **because canon was defined**: canonical content is *supposed to be
  self-consistent* so a scanner can check it for contradictions; non-canon is *allowed* to disagree with
  itself. (opinion — the load-bearing connective claim)
- Canonical artifacts carry an explicit `owner` field in YAML frontmatter; CI validates it. (fact)

## The three authoring problems (named precisely)
1. **Describing instead of instructing** — "SRC is where we put source code" teaches nothing; "Never use
   inline imports to work around circular deps; fix the module structure" changes behavior. (fact +
   opinion-by-example)
2. **Everything marked must-follow** — when everything is important, nothing is; priority must be embedded
   in prose. (opinion)
3. **Cross-folder knowledge in the wrong place** — knowledge needed by frontend agents can't live only in
   the backend `AGENTS.md`; the fix is to put cross-folder knowledge in **skills loaded on demand**.
   (opinion / prescription)
- After codifying standards they deployed agents to audit every directory, found **nine projects with
  thousands of lines of violations**, then deployed agents to fix violations **agents had themselves
  perpetuated**; the rewrite touched **20–30% of the codebase**. (fact, as reported)

## Long-horizon-specific argument
- Stale/inconsistent context is **more dangerous for long-horizon agents**: a small wrong assumption
  early "propagates through hours of subsequent reasoning." Short-horizon agents (Stripe Minions, Ramp
  Inspect) have bounded tasks / fixed windows. (opinion — the article's distinctive-tension claim)
- "Trust and reviewability are non-negotiable. You can't delegate accountability in finance." The internal
  engineering architecture is the same one the product required. (fact: quote, primary-adjacent; opinion:
  the mirror argument)

## Reported outcome metrics (3 months)
5x token usage/developer; 2.5x commit velocity; 100% of engineering on multiple worktrees. (fact, as
reported — all secondhand via snapshots)

## The article's own "Application to This System" (EXPLICITLY flagged extrapolation, not adopted)
These are the article's *candidates*. Pass 1 records them as the article's claims; Pass 3 verifies them
against our ground-truth map. They are **not** findings to inherit.
- **Authority map**: an `authority-map.md` per project `.claude/`; add `canonical: true/false` frontmatter
  to `docs/specs/` and `docs/solutions/`; make `/feature` Plan read specs as *intent*.
- **Default-no authoring gate** for `CLAUDE.md` / `AGENTS.md` — "the most actionable item, requires no new
  tooling"; run the five Basis rules; cut descriptive lines; move dir-specific lines to nested files.
- **Verifier as diff-scoped** complement to a Ramp verification-loop candidate; diff-scoped tests + typecheck
  for a "compound agent @task-runner" gate.
- **Automated context maintenance: start manual, target weekly** via `/scan-context`; classify canon/not-canon
  first so the scanner can find canon↔not-canon contradictions.
- **YAML frontmatter `owner` + `last-verified`** on canonical files, starting with `docs/solutions/`, added
  to the `/compound` output template.

## Design challenge (the article's call to action)
Audit event-vendor's `.claude/`, classify every artifact canon vs not-canon, name files an agent would
**over-trust**, and for ≥3 of them state the *specific wrong reasoning* an agent would do.

## Open questions the author flags
"Clueso" reference is **unresolved** (in the research index, in no external source). Plus 5 questions for
Michael Crabtree (verification-loop differences, violation categories, pre-systematization starting state,
stale-vs-wrong scanner handling, agent-native sales/talent).
