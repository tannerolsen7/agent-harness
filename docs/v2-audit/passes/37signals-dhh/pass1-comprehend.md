# Pass 1 — Comprehend: what the article says

Article: "37signals — Agent-Accessibility Architecture & the Skeptic's Conversion (DHH, 2026)"
Notion id `36ce2971cd628159a2fbc3a6b6f1a494`. Primary source: DHH blog "Basecamp becomes
agent accessible" (2026-03-25); secondary: Pragmatic Engineer "DHH's new way of writing code"
(2026-04-08); plus basecamp/house-skills GitHub (MIT). Research date 2026-05-26.

This pass is faithful, not interpretive. It records what the page asserts and tags each major
point (fact) — externally checkable / sourced — or (opinion) — the author's judgment or framing.
The page is itself a curated research write-up with its own synthesis and "application" section;
those internal analyses are recorded here as the article's claims, to be tested in later passes,
not inherited as ground truth.

## 1. The narrative spine: skeptic converted

- DHH said in July 2025 (Lex Fridman) he doesn't use AI tools — types all his code; by April 2026
  (Pragmatic Engineer) he "barely writes any code by hand." A ~9-month skeptic-to-agent-first flip. (fact — both endpoints sourced/"Verified" in the ledger)
- The article frames this as not capitulation: "DHH didn't change his standards; he found a way to
  maintain them with different tools" — quoting Pragmatic Engineer "his standards of quality and craft
  remain the same." (opinion — the framing; the quote is fact)
- Author's read: the conversion tracks when coding agents became capable of end-to-end tasks rather
  than autocomplete; "DHH wasn't wrong about 2024-era AI tools. He updated when the tools got good
  enough to deserve updating." (opinion)

## 2. The central architecture: API + CLI + Skills (make the product agent-ACCESSIBLE, don't bake AI IN)

- 37signals tried 18 months of AI-feature experiments; nothing good enough shipped INTO products. (fact, primary/"Verified")
- Instead they made Basecamp operable by EXTERNAL agents via three components (fact, primary):
  1. **Revamped API** — all features API-accessible; previously possible but "cumbersome, slow, and
     expensive, so most people just didn't"; agents eliminate that friction.
  2. **New CLI** — dedicated command-line interface for Basecamp and all 37signals products.
  3. **Skill (house-skills)** — public MIT skill library teaching agents how to use Basecamp; "encodes
     product knowledge so agents don't have to rediscover it each session."
- DHH's stated strategic judgment: rather than baked-in AI features that may go unused, make the
  product friendly to external agents — "Users will want to choose their own AI rather than have one
  chosen for them." (fact — DHH's stated position; secondary-verified for the quote)
- "Agents have emerged as the killer app for AI" — DHH's stated position. (fact, primary/"Verified")
- "LLMs [are] smarter when they can check thinking using tools; file system gives them memory between
  prompts." (fact — attributed to DHH, primary/"Verified")

## 3. The CLI is the agent's operating lever (not a dev shortcut)

- DHH is building CLIs for all 37signals products: Basecamp, Fizzy, HEY. (fact, secondary/"Verified")
- Rationale: agents can CHAIN CLIs — detect a Sentry error, look up the related Basecamp thread, write
  a fix, post a PR, update Basecamp — all via CLI orchestration, no UI/browser/human handoff for
  routine steps. (fact — the rationale is DHH's, secondary/"Verified"; the worked example is illustrative)
- Author's claim: "CLI surface area is what determines how deeply agents can operate a product. A
  product with a complete CLI is fully agent-accessible. A product without one requires browser
  automation or screen-reading." (opinion — the author's product-strategy generalization)

## 4. Shape Up needs rewriting (the methodology signal)

- DHH says Shape Up's 2-month/6-week shaping cycle "needs rewriting" because AI acceleration has made
  that timeline feel slow. (fact, secondary/"Verified")
- Author's read: if agents change execution velocity enough that planning/shaping is now the
  bottleneck rather than implementation, the methodology must be rebuilt from that new constraint; the
  author calls this "the most honest signal in this research." (opinion)

## 5. The burnout warning (named as "load-bearing")

- DHH: "The dopamine loop of shipping with agents is intoxicating and can lead to higher risk of
  burnout." (fact — DHH quote, secondary/"Verified")
- DHH sleeps 8 hours, no alarm, deliberately, even during the AI gold rush. (fact, secondary/"Verified")
- Author's mechanism (opinion): agents remove friction so completely that natural stopping points
  disappear; a human writing code hits blockers that force rest, an agent removes blockers so the
  engineer keeps steering; "the ceiling on sustainable velocity is no longer technical; it's human."
- The article flags this as the FIRST explicit mention of agent-induced burnout in its research corpus,
  and notably from the convert, not the skeptic. (opinion/observation)

## 6. Cross-page connections the article draws

- **Independent confirmation of the same three-layer architecture:** Vercel named the SAME API + CLI +
  Skills agent-accessibility pattern; 37signals arrived at it independently, from a product-philosophy
  angle vs. Vercel's platform-strategy angle — "two independent confirmations." (opinion/synthesis;
  the Vercel claim is cross-referenced, not re-sourced here)
- **Contrast with Shopify:** Shopify built an internal proxy + connected MCP servers + shipped an AI
  Toolkit (baked-in); 37signals declined to bake in AI and made products externally accessible. Both
  coherent; difference is product philosophy (prescriptive workflow vs. user-chosen tools). (opinion/synthesis)
- **Burnout as net-new:** no other company in the corpus named the friction-removal burnout risk;
  worth tracking as the compound agent removes more activation energy. (opinion)

## 7. The article's OWN "Application to this system" (extrapolation — explicitly "not yet adopted")

These are the article's self-authored candidates for event-vendor. Recorded as the article's claims;
tested against ground truth in Pass 3.

- **house-skills as a reference:** read house-skills before authoring any new event-vendor skill, to
  see how 37signals scopes skill instructions (include vs. omit). Open question the article itself
  poses: does house-skills use YAML frontmatter (the "Zapier pattern") or a different structure —
  which would inform a "frontmatter upgrade candidate." (opinion/candidate)
- **CLI strategy for event-vendor's own dev tools:** event-vendor has no vendor-side products yet, but
  the principle applies to dev tooling — Supabase CLI, Vercel CLI, custom scripts should be explicit
  tools in the agent contract. Candidate: audit the agent contract for what's invocable via CLI vs.
  what needs UI/API, and make the CLI surface explicit in AGENTS.md. Open question: are there
  event-vendor admin operations that currently require browser actions that could be CLI-exposed? (opinion/candidate)
- **Explicit stopping points / pace design in the agent contract:** the compound agent's "AFK north
  star" removes friction (the goal) but creates DHH's burnout risk. Candidate: add explicit stopping
  points to the agent contract and the AFK eligibility criteria — "when does Tanner stop?" — a session
  ends when compound questions answered, changelog written, TASKS.md updated. Open question: already
  implicit, or does it need to be named explicitly? (opinion/candidate)

## 8. The article's "Design Challenge" (its proposed exercise)

Audit the compound agent's current tool access and classify each operation: CLI-accessible /
API-accessible / UI-required / Not possible. Then: (1) which UI-required ops could be made
CLI-accessible cheaply; (2) which "not possible" ops are worth enabling and what it'd take; (3) write
the AGENTS.md additions documenting the CLI surface the agent is allowed to use. (opinion/exercise)

## 9. "What doesn't transfer at solo scale" (the article's own honesty table)

- API+CLI+Skills architecture → principle transfers fully (Supabase CLI + Vercel CLI + custom scripts).
- house-skills library → transfers "as a reference" (fork/adapt).
- Shape Up rewrite → "Signal only" (solo dev doesn't use Shape Up).
- CLI-first for all products → transfers fully as principle (CLI-first for any recurring admin op).
- Deliberate pace (8h sleep) → personal discipline, "already Tanner's call."
- Burnout-risk design → principle transfers (explicit stopping points in agent contract).

## 10. The article's own hypotheses-vs-findings (self-scored)

- Expected 37signals = the AI skeptic counterpoint → marked ❌ "significantly wrong" (the skeptic
  converted). (fact — self-scored)
- Expected no meaningful AI features shipped → ✔️ confirmed "with a twist" (no AI INTO products; made
  product agent-accessible instead). (fact — self-scored)
- Expected small team (34) would limit them → ❌ wrong (the architecture is elegant BECAUSE it doesn't
  require building AI internally; designed for a small team). (fact — self-scored)
- "Surprised": Shape Up needs rewriting; DHH abandoning his own methodology is a striking signal.

## Net thesis of the article (as stated)
The agent-accessibility frontier is not "put AI in your product" but "make your product operable by
whatever agent the user brings" — and the lever for that is API + **CLI** + Skills, with the CLI
surface area as the determinant of how autonomously agents can operate. Secondary but flagged as
load-bearing: agent velocity removes the friction that used to force rest, so deliberate stopping
points become a design concern, not just a personal one.
