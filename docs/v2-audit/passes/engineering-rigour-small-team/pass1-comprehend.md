# Pass 1 — Comprehend: "Engineering Rigour for a 1–3 Person Team — Process Over Model"

Faithful restatement of what the article *says*. Claims tagged (fact) = verifiable/attributed
external claim, or (opinion) = the author's judgment/recommendation. No interpretation here.

## Source provenance (as the article states it)
- Article synthesizes **four sources** around one claim. (fact, self-described)
- Named substantive sources: **Christoph Nakazawa, "Modern Engineering Values"** (cpojer.net,
  Jun 3 2026, marked "verified") and **Luca Rossi, "My AI Coding Workflow" + "How I Run the
  Tolaria Project"** (Refactoring / refactoring.fm, 2026, "verified, partly paywalled"). (fact, attributed)
- The fourth "process not model" thesis is **corroborated but has no verified author** (CodeRabbit
  AI-vs-human report, LeadDev, Aviator cited as corroboration) — the article explicitly says to
  "treat it as an uncredited argument, not an authority." (fact, self-described stance)

## The core question / thesis
- Central claim: **engineering rigour comes from the development process, not the model.** The model
  is a "multiplier, not a corrector" — generates plausible, not necessarily correct, code, and "has
  no stake in whether the thing ships." (opinion, presented as the converged thesis)
- "The teams doing this well aren't using better models; they're using better habits." (opinion)
- The author reframes the real question as: *which* of these habits earn their place at a **1–3
  person team building a commercial product**, vs. which are "org-scale ceremony or motivational
  filler." (opinion — this is the article's actual contribution)
- Short answer stated up front: adopt harness disciplines (they "scale down perfectly and you mostly
  have them"); steal failing-test-first if not formalized; **reject "full review of every PR"** in
  favor of **risk-tiered review**. (opinion / recommendation)

## What the sources converge on (the article's five points)
1. **The harness is the source of quality, not the model.** Maps Nakazawa's "guardrails" = Rossi's
   "gates" = the thesis's "better habits" → one idea: quality from deterministic checks. (opinion,
   synthesizing attributed sources)
2. **Write a failing test first, especially for bugs.** Nakazawa and Rossi "independently arrive" at
   this as "the single highest-leverage habit." Nakazawa quote: forcing a failing test first
   "significantly increases the likelihood of the model fixing the right problem in the right way."
   (fact, attributed quote)
3. **Context belongs in the repo.** Nakazawa's "Context in the Repo" = Rossi's "Guides" (AGENTS.md);
   both "treat every agent session as a new hire with amnesia." (fact/opinion, attributed)
4. **Small teams are the natural unit.** Nakazawa verbatim: "the most effective teams will be small,
   often two to three people, with clear ownership boundaries and isolated repositories." (fact,
   attributed quote)
5. **The bottleneck moved from typing to judgment.** Nakazawa: "I was bottlenecked on writing code,
   now I'm bottlenecked on exercising judgement." (fact, attributed quote)

- Rossi's organizing vocabulary, offered "to steal": **Guides, Gates, Guards.** Guides = instructions
  the agent loads (AGENTS.md + skills); Gates = deterministic checks that *block* bad output; Guards =
  fallback procedures (crash reporting, Boy Scout rule) catching what slips through. (fact, attributed
  framing)

## Where the sources disagree (and where the author lands)
- **How much to review.** Thesis is absolutist ("treat every AI PR like a human PR, full review, no
  exceptions"); Nakazawa is **risk-tiered** — ships low-risk code unstudied, reserves scrutiny for
  dangerous paths, and says he now scrutinizes *hand-written* code more than agent code. **Author's
  call: Nakazawa wins** for a team this size — a solo dev who line-reviews everything burns out; heavy
  review on irreversible/high-blast-radius classes (auth, schema, payments, the proposal-send path),
  tests carry reversible ones. The thesis is "right in spirit (never merge unread) but its literal form
  is an org ritual." (opinion / recommendation; cites attributed positions)
- **Skills vs. one big instruction file.** Rossi deliberately uses *no* skills ("simple enough to keep
  everything in AGENTS.md"). Author says the reader correctly went the other way (a skill suite)
  because their process is *not* simple (`/cr`, `/change`, `/queue`, lens agents). Lesson: not "drop
  skills" but **"don't add a skill for something a paragraph in AGENTS.md would cover."** (opinion)
- **Own your stack vs. rent it.** Nakazawa: agents make it worth owning your stack, dropping
  dependencies. Rossi: standardizes on shadcn/ui and moves on. Author's call: **Rossi's pragmatism
  beats Nakazawa's purism** for a commercial 1–3 team — own what *is* your differentiation (recipe
  layer, proposal renderer), rent the shell. Framed as "code is a liability, own only what you must."
  (opinion / recommendation)

## What to skip (does not transfer down to scale)
- **The entire Tolaria orchestration apparatus** — Canny voting boards, contributor-PR triage,
  multi-channel input routing — exists only because open source generates "200+ external issues." A
  commercial 1–3 team has no contributor firehose; "one prioritized backlog is enough." (opinion)
- **Inter-teammate PR ceremony.** Nakazawa: "code reviews on small teams should focus on alignment,
  not arguments about code… only necessary when there are open questions that haven't already been
  discussed." Don't import big-co review gates between two people. (opinion, cites attributed quote)
- **Multi-agent parallelism / worktree swarms.** Nakazawa (a "top-tier engineer") says he's
  *ineffective* running multiple agents in one project. Author: "use [worktree isolation] for safety,
  not for chasing parallel-agent throughput you can't review." (opinion, cites attributed claim)
- **"Taste, taste, taste" and vanity metrics.** Taste is "a reminder to prune scope," not a practice.
  LOC/commit counts (Nakazawa's 15K LOC/day, Rossi's 28 commits/day) are "weak proxies both authors
  admit to" — not targets. (opinion, cites attributed figures)

## Application to "this system" (the article's own embedded curator analysis — CLAIMS, to verify)
The article asserts the reader already does most of this, "and your version is more rigorous." It
frames the value as **three confirmations + one steal**:
- **Confirmation 1:** *Harness not model* = "your five pillars, especially Pillar 3 ('verify the
  system, not the model')." (claim about our harness)
- **Confirmation 2:** *Context in the repo / Guides* = "your AGENTS.md single-root decision and canon
  inversion (Node 14, Git-canonical)." (claim)
- **Confirmation 3:** *Gates / Guards* = "your CI required-check, `/cr`, hooks, and the runtime-error
  monitoring you're adding for the `/p/[token]` renderer (Ashby item 1)." (claim — "you have all three
  G's")
- **The one steal:** **make failing-test-first an explicit, enforced rule for bug fixes.** Stated as
  "the single most cross-corroborated practice here, and it's cheap." Notes current TDD is scoped to
  `src/data/` / `src/schemas/` / `src/utils/`; sources push further — *every bug fix starts with a
  failing reproducing test before the fix*. Recommends adding it as an executable constraint in
  **`learned-patterns.md`** ("bug fix with no new failing-then-passing test = MUST FIX"), described as
  "exactly the executable-constraint format your recursive-improvement synthesis already mandates."
  (recommendation referencing our internals)
- **One more:** Rossi "cut his monthly AI spend >90% by moving Claude→Codex." Offered as a "live data
  point" for a standing token-cost concern; ties to "`/goal` caps, blast-radius-scaled subagent
  fan-out." (fact, attributed figure + recommendation)

## The standing rule (article's closing prescription)
- "Rigour is a property of the process, not the model, so every new AI capability gets evaluated by
  what *gate* or *guard* it lets you remove or strengthen — never by how smart it is." (opinion)
- "Bug fixes start with a failing test. Review scales with reversibility, not with source (agent vs.
  hand-written). And a habit only earns a place in this repo if it survives the team-of-1-to-3 filter:
  if it's there to coordinate a large org, it's not for you." (opinion / standing rule)
