# Pass 1 — Comprehend: what the article SAYS

**Article:** "Leland (Jake Lingwall) — Eight Principles for AI Builders: Framework Analysis (2026)"
(Notion `36ce2971cd6281b090cbf32eefe58c61`). Source principles by Jake Lingwall, aibuilderday.com.
**Important:** This Notion page is not Lingwall's raw article. It is a *curator's framework analysis*
of it — claims ledger, synthesis, application, design challenge. Per task rules, the curator's
passes are treated as CLAIMS to verify in later passes, not facts to inherit. This pass faithfully
records what the page asserts.

## The eight principles (the framework itself)

1. **Everything comes back to impact** — impact is the north star for engineering decisions.
2. **Automate the repeatable** — repeatable/boring tasks should be automated.
3. **Raise the floor on quality, not just speed** — quality gates matter as much as velocity.
4. **Go 10x deeper in your lane** — specialization over breadth.
5. **Build in the open** — transparency and sharing compound value.
6. **Own the output** — humans are accountable for AI-generated work.
7. **Be trusted with data** — security and data integrity are non-negotiable.
8. **Adapt as a team** — learning systems compound.

## Method note (fact)

The page states Lingwall is a solo practitioner/framework author, not a company, so the standard
company-research template is adapted: "if you're deciding" → "when to reach for this framework";
"what doesn't transfer at solo scale" → "what does this framework assume". It says the two prior
Notion "To Think About: Leland's Eight Principles" pages (May 19, 2026) are the primary reference,
not the original article directly. (fact, self-reported provenance)

## The curator's hypotheses (opinion, written pre-research)

- Principles expected to be high-level/aspirational and map loosely — said to be *partially* confirmed:
  3 principles (3, 6, 7) are "explicitly built into the system"; 2 (1, 5) are "named gaps with no
  current mechanism." (opinion)
- Principle 1 (impact) predicted hardest to operationalize — claimed confirmed: "no mechanism tying
  shipped features to whether they mattered." (opinion)
- "Surprised" the prior system mapping was honest about weakness ("impact is assumed but not
  measured"). (opinion)

## Claims ledger (the curator's per-principle verdicts)

| # | Principle | Verifiable? (curator label) | Curator's assessment |
|---|---|---|---|
| 1 | Impact as north star | Normative | "Right — but 'impact' is undefined. What counts?" (opinion) |
| 2 | Automate the repeatable | Empirical | "Right and testable"; cites Vercel "what do you hate most?" (opinion + cited claim) |
| 3 | Raise the quality floor | Empirical | "Right and confirmed"; cites ETH Zurich, PostHog, Basis (opinion + cited claim) |
| 4 | 10x deeper in your lane | Normative | "Contested"; cites Ramp's "skill-not-agent" pivot as counter-evidence (opinion) |
| 5 | Build in the open | Normative | "Right but not operationalized"; cites GitHub ecosystem (opinion) |
| 6 | Own the output | Empirical | "Confirmed across 3 companies" (Linear, Stripe, Zapier) (opinion + cited claim) |
| 7 | Be trusted with data | Empirical | "Right and confirmed"; cites Basis (opinion + cited claim) |
| 8 | Adapt as a team | Empirical | "Right; speed of adaptation is the gap"; cites PITFALLS.md, RECURRING-FINDINGS.md, /compound (opinion + cited claim) |

Note: the "Evidence" column draws on *other* companies in the curator's wider research corpus
(Vercel, Ramp, Basis, PostHog, ETH Zurich, Linear, Stripe, Zapier, 37signals). Those cross-company
claims are second-hand here and not independently substantiated on this page. (fact about the page)

## Synthesis (curator's, opinion)

- **Gets right:** Principles 3, 6, 7 are "most defensible and most confirmed." Quality-floor is "the
  explicit design goal of the pipeline system" (names pre-grill discipline, `/cr-feature` multi-pass,
  compound questions before merge as floor-raisers). Principle 2 validated by Vercel.
- **Incomplete:** Principle 1 is "named as most important but most underspecified" — impact is not
  defined (feature delivery? adoption? revenue? avoided bugs?). The framework "doesn't address the
  compounding dimension" — how principles compound and how violating one degrades others (e.g. "1
  without 3 = fast shipping of the wrong things"; "3 without 8 = a quality floor that decays").
- **Might be wrong:** Principle 4 is "most contestable." Ramp went the opposite way (hundreds of
  specialist agents → one generalist agent with thousands of skills) because specialization overhead
  became unsustainable. The curator argues that in an AI-native system "the skill (reusable,
  composable) may be a better unit than the lane (specialist, isolated)" — while granting depth is
  still valuable on the *human* side.
- **Reframe:** The eight principles are most useful "not as instructions but as audit questions" — a
  periodic pressure-test before a major restructure, not a methodology. The page endorses the prior
  filing: "Parked — revisit condition: use as a periodic pressure-test during system audits."

## Application to event-vendor (curator's, explicitly "extrapolation — not yet adopted")

- **P1:** Define impact for event-vendor's stage before measuring. Pre-revenue: impact = user-facing
  features shipped per week actually used by Tanner or test users. At revenue: features driving
  activation/retention/conversion. Candidate: add a two-sentence impact definition to `TASKS.md`
  Current State. "Not a metric system — just a definition."
- **P5:** Build-in-the-open / GitHub Publishing is "parked, not abandoned" until the compound agent
  has run reliably 30+ days. Cites 37signals/Vercel public skill libraries as the model.
- **P8:** Adapt faster — "the scanner as the mechanism." Candidate: run `/scan-context` weekly (not
  monthly). "The mechanism already exists; the frequency is the gap."

## Design challenge (curator's)

Define impact for event-vendor, then audit the last three compound-agent sessions against it: (1)
write a two-sentence impact definition; (2) for each of the last 3 compound sessions, did it produce
something that mattered, with evidence; (3) write the `TASKS.md` Current State entry capturing the
definition. "If you can't write the two sentences, the definition doesn't exist yet."

## What the framework assumes (curator's table)

- Impact can be defined for any project — *partially* (needs per-project/stage definition).
- Deep specialization scales — *contested* (Ramp).
- Teams adapt quickly given right tools — *mostly* (needs deliberate mechanism).
- The eight principles are independent and equally weighted — *probably wrong* (they compose/conflict).
- Building in the open needs no infrastructure — *false at scale* (needs governance/quality control).

## Open questions the curator would ask Lingwall (faithful list)

1. Is Principle 4 about humans or agents? Ramp suggests specialist agents don't scale.
2. How do the eight principles compose — which tensions with which, which violation degrades all fastest?
3. What does impact measurement look like for a pre-revenue solo product (no DAU/revenue/retention)?
4. Has anyone used it as a pressure-test vs. a methodology? They produce different behaviors.

## One-line thesis (faithful)

The eight principles are a sound but high-level builder ethos; their real value is as a periodic
**audit / pressure-test** (not a workflow), and the single load-bearing gap they expose for this
system is that **impact is asserted as the north star but never defined or measured**.
