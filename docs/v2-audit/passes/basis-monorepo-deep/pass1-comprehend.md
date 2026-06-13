# Pass 1 — Comprehend: "Basis Monorepo Ergonomics for Agents (Deep Analysis)"

**Source.** "Making Our Monorepo Ergonomic for Agents" — Basis Engineering Blog (Michael
Crabtree, Ryan Moffat, Bhavdeep Sethi, Seth Schiesel; Atlas team). Notion node:
`367e2971cd6281af9f91e713a77235bf` ("Deep Analysis").

**Sourcing note (load-bearing).** The assigned "Deep Analysis" page is a **stub** — it is frozen
mid-draft at "Status: Interview phase — awaiting Tanner's answers" and the fetched body cuts off
after the two headline metrics. The complete analysis of the same article lives in two sibling
nodes I pulled to reconstruct what the article says: the verbatim company essay
(`373e2971cd62813ab032faacfd0402e4`) and a fuller curator write-up
(`367e2971cd628179bf39dcb33814f5ac`, "Full Analysis"). The Full-Analysis page is explicitly
flagged **"SNAPSHOT — canonical: false … frozen 2026-05-21 … must not be used to make
implementation decisions."** Its gap table and roadmap are therefore **curator CLAIMS** to verify
in pass 3, not article facts. Below, article facts come from the verbatim essay; curator framings
are tagged as such.

---

## 1. What the article claims it achieved (fact — reported by Basis)

Basis is a production accounting-AI company (3 years old; the curator adds "Khosla-backed, $34M",
which is curator-sourced, not in the essay). Over three months their Atlas team — whose stated
charge is "internal agents and context," treating the codebase itself as the product whose users
are agents — reports:

- **>5x token usage per developer** (fact, self-reported; explicitly chosen as their primary
  success metric).
- **2.5x weekly commit velocity** (fact, self-reported).
- **100% of the engineering team working with multiple worktrees** by the end (fact,
  self-reported).

These are self-reported production outcomes, not externally measured (fact about their epistemic
status).

## 2. The core problem framing (fact — the article's central claim)

A codebase is now **two things at once**: source that runs in production, and *context that agents
use to make decisions* (fact, as stated). A human onboards once and accumulates a mental model over
months; an agent **re-onboards every single trajectory** (fact, as stated). Basis went from "a
handful of onboardings a month" to "thousands a month," so "any small inconsistencies,
contradictions, and gaps compound quickly, while previously they may have gone unnoticed" (fact, as
the article asserts the mechanism). Implication the article draws: optimize only for #1 and agents
"constantly guess" about #2 (opinion/claim).

## 3. The five principles (fact — the article enumerates these)

1. **Canonicality** — every artifact is *either* source-of-truth-about-today *or*
   record-of-intent/history, **never both**; agents need an explicit map of what to trust.
2. **Localization** — context lives as close to use as possible; moves up only as it becomes
   genuinely shared.
3. **Verifiability** — agents need their work verified; mechanisms named are sub-agent roles,
   pre-commit hooks, and tests.
4. **Interoperability** — no layer binds to one AI vendor; "AI tech is moving too fast"; they use
   `AGENTS.md` and symlink `CLAUDE.md` to it.
5. **Default-no** — auto-loaded context must earn its place; "tokens that earn no behavior are a
   tax"; phrasing it negatively is deliberate because "default-include" balloons files.

(Principles 1–5 are facts about the article's content; the *justifications* attached to each are the
article's opinions.)

## 4. Canon vs. not-canon (fact — the article's headline mechanism)

- **Canon** = treat as source of truth about the system today: root + nested `AGENTS.md`, skills,
  `docs/`, inline comments and docstrings.
- **Not-canon** = intent / history / hypothesis: `.specs/`, Linear tickets, `.notes/`.
- The categorization was formalized in a **documentation-standards document mapping every artifact
  type to an authority level** (fact).
- The article argues not-canon is still valuable — it answers "why was this written this way?" (the
  pre-agent answer was a Slack DM; now it's `.notes/`) — and names a concrete user: their incident
  agent "Clueso" uses non-canon context to decide bug-vs-feature (fact, as an example).
- The stated failure mode: **treating not-canon as canon** makes the agent "reason incorrectly about
  the codebase" (opinion/claim about the consequence).

## 5. The six-layer architecture (fact — enumerated)

1. **Root `AGENTS.md`** — principles, workflow definitions, communication patterns; ~300 lines;
   loaded every session; "the most high-leverage file"; "prime real estate" (curator phrase). For
   Claude they symlink it.
2. **Nested `AGENTS.md`** — 100+ across the monorepo, each scoped/narrow/operational; the article
   frames this as the primary scaling mechanism (sessions not touching a dir don't pay for it —
   curator's architect-lens gloss, consistent with the essay).
3. **Skills** — `.agents/skills/`: backend architecture, frontend patterns, testing standards,
   docs conventions, domain knowledge; **loaded on demand**.
4. **Sub-agent roles** — `.agents/roles/`: "more than half a dozen," each with its own context
   window and (per curator) model settings in YAML frontmatter. Two named: **`verifier`** (runs
   diff-scoped tests + pre-commit hooks, reports pass/fail with actionable detail) and
   **`standards-enforcer`** (validates code against all applicable `AGENTS.md` files and skills).
5. **Unified MCP** — one server exposing Linear, Slack, Better Stack logs, PostHog, and dev DB, so
   an agent can pull a ticket, check prod logs, and query the DB without manual context-paste.
6. **Tests** — Ruff, BasedPyright, ESLint, Prettier, plus detections for large files, private keys,
   merge conflicts; "the last line of defense."

## 6. The three `AGENTS.md` defects + five authoring rules (fact — enumerated)

Defects found in ~20 files: (1) **describing instead of instructing** ("SRC is where we put source
code" — the agent already knows); (2) **everything marked high-priority** — "when everything is
important, nothing is"; (3) **cross-folder knowledge in the wrong place** → move to on-demand skills.

Five authoring rules: **instruction quality** (write for agents, not humans); **hierarchy-first
placement**; **resilient references** (descriptive names over exact paths, "paths change,
descriptions are stable"); **text-only / search-friendly** (no ASCII art/binary); **default-no**.

## 7. The cleanup (fact — reported)

After codifying standards, they used agents to audit every directory, found **nine projects with
thousands of lines of violations**, then deployed agents to fix the violations agents had
perpetuated. The rewrite **touched an estimated 20–30% of the entire codebase**. Stated lesson:
"An agent-native codebase demands more local correctness than a human-only one, because every file
is context and the agents are constantly onboarding" (opinion/claim).

## 8. Maintaining canon — the "Automatic Context" system (fact — enumerated)

- **Owners**: every canonical artifact carries an explicit `owner` in YAML frontmatter; a CI check
  ensures any new skill or non-production markdown has an owner.
- **(1)** CI/CD check on every merge (frontmatter, prose, grammar / "deterministic standards").
- **(2)** A **daily scanner** sweeping skills + `AGENTS.md` for staleness, contradictions,
  duplicated instructions, broken references, missing context for recent changes.
- **(3)** **Daily workers** that pick up scanner tickets and implement small, scoped fixes.
- The stated enabler: automated maintenance is "only possible because we agreed on what is
  canonical — canonical context is, by definition, supposed to agree with itself" (the load-bearing
  claim linking §4 to §8).

## 9. Closing the validation loop + the docs/skills audience split (fact)

- A **testing skill** defines what tests are expected, when required, how structured; they
  "evaluated extensively whether their guidelines induced the right agent behavior" and iterated
  because agents were "sometimes too verbose, sometimes too lazy."
- **Inter-team structure**: one engineer on traditional test infra (Bhavdeep Sethi), one on the
  agent-behavior layer (Atlas) — agent behavior treated as a first-class requirement (fact).
- The curator (Full-Analysis, not the essay) asserts a sharper claim: **"docs/ is now explicitly for
  humans; skills are for agents," because models are post-trained to load skills.** The essay
  supports the "move cross-folder knowledge into skills" half but does **not** state the clean
  "docs = humans" binary — flag as curator amplification to verify.

## 10. What the article says is next (fact)

"Proof-based development, redesigning code review, and experimenting with automatic code
maintenance" — extending the Automatic Context machinery from the instruction layer to the code
itself.

---

## Curator-embedded claims to carry forward as CLAIMS (not inherited fact)

The Full-Analysis page embeds a gap table and roadmap. Per the audit's rules these are **claims to
verify in pass 3**, and the page itself warns they are stale (frozen 2026-05-21):

- It rates us "Better/Equal" on skills, human-in-loop, spec-before-code, nested context,
  verification, memory, scope, workflow docs — and lists **8 gaps**: (G1) no canon/not-canon, (G2)
  no 300-line root discipline, (G3) no automated context maintenance, (G4) no `verifier` sub-agent,
  (G5) no unified MCP, (G6) no `owner` frontmatter, (G7) no `standards-enforcer`, (G8) no
  docs/skills audience split.
- **Known-stale tells**: it repeatedly cites **`/cr-feature`** (retired v0.85 per ground-truth) as
  our current verification pipeline, and predates `CONTEXT.md` (PR #92). Both must be re-grounded
  before any gap is treated as real.
