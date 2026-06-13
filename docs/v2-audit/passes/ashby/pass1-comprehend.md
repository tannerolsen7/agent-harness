# Pass 1 — Comprehend: "Ashby — AI-Native Engineering Process & Practices (2026)"

Faithful restatement of what the article says. The article (a Notion research page) embeds
its *own* TL;DR, Sources, and a 3-pass analysis (Pass 1/2/3) plus recommended actions. Per
the audit rule, those embedded passes are treated as **the article's claims**, not inherited
fact. This pass records what the article asserts; verification happens in pass2/pass3.

Primary source behind the page: Colin Howe (Head of Engineering EMEA, Ashby), "AI, Ashby
Engineering, and the Future," plus an Ashby team page, an HN thread, and an Ashby product PR.

## The central thesis
- **"The cost of writing code is heading towards zero. The cost of producing meaningful
  software is not."** (opinion — a framing claim, stated as Ashby's thesis)
- Corollary: **"Writing is now cheap. Verification is the bottleneck, and our investment needs
  to follow."** (opinion)
- Historical gloss (from HN): the biggest cost of code was always the activities *around* it —
  planning, communicating, reviewing, validating. AI commoditizes keystrokes, not those. (opinion)

## The headline quantitative claim
- **Since August 2025, >50% of new production code at Ashby has been AI-generated, "without
  quality degradation."** (claimed as fact by Ashby; the article itself later flags it as
  unverifiable — see pass2)
- Ashby **does not track token usage** and **does not mandate AI adoption** — "no coercion layer
  beneath the statistic." (fact about Ashby's stated policy)

## Stated practices (article's Pass 1, "What They Say")
- **Two ground rules:** (1) empathy can't be outsourced to AI; (2) you are responsible for what
  you ship. (fact — quoted policy)
- **Two operating modes:** *Sidekick* (human decides, AI assists) for high-blast-radius work —
  migrations, security, architecture; *Delegate* for small-blast-radius prototyping/local tooling.
  (fact — quoted policy)
- **Tooling:** Cursor (unlimited tokens), Claude Max, Codex, agent frameworks; DangerJS +
  CodeRabbit + a **custom in-house edge-case-bug review tool** they prefer because they control
  context + token budget. (fact — reported tooling)
- **Git-metadata substrate:** issues/PRs/comments cloned to **SQLite** so engineers and in-house
  LLMs can answer "has anyone seen this bug before?" (fact — reported)
- **Skill files** committed to repos, updated weekly. (fact — reported)
- **Bug-triage automation:** Claude Code reads incoming bugs, produces diagnostic reports; cut
  some Support fixes from hours to ~10 minutes. (fact — reported, with a metric)
- **Verification investment:** 65 new Playwright E2E tests in four weeks (70% authored by non-QA
  engineers), plus more fuzzing + static analysis. (fact — reported, with a metric)
- **Specs reframed:** write specs *for humans, not LLMs*; code review shifts from line-by-line to
  "does this change make sense / where's the risk / are the abstractions sound." (opinion/practice)

## Human-side claims
- AI displaces **mechanical work** (syntax, glue, keystrokes), not engineers; judgment, taste,
  accountability stay human. (opinion)
- "Meet the Team": remote-first, 24 countries, "releases changes and new features multiple times
  per day"; notably **barely mentions AI in the core coding workflow**. (fact — page content)

## Product externalization
- Ashby's expansion into Agents, Assistant, and MCP support reframes the internal philosophy as a
  customer-facing product: assistive → action-oriented automation. AI PM Anika Zaman frames it as
  "AI can now take on much larger parts of those workflows." (fact — PR content)

## The article's own Pass 3 (its application to event-vendor) — recorded as CLAIMS to test
The page asserts event-vendor "already has Ashby's substrate" and lists:
- **Already in place:** defense-in-depth verification (pre-commit → pre-push → /cr); risk-tiered
  autonomy (/supabase, /cr-security, destructive-op rules, guard-file handoffs; /queue=delegate,
  /spike+/design=sidekick); code-quality-as-compounding (agents re-read CLAUDE/AGENTS/memory/
  PITFALLS/solutions); expertise-in-skill-files (lens-* agents = Ashby's custom review tool as prompts).
- **Gaps it claims Ashby reveals:** (1) no runtime safety net below the merge gate (no error
  monitoring / feature flag / nothing watching public `/p/[token]`); (2) no log of *failed
  AI/workflow experiments*; (3) nothing aggregates agent-run signal into "where do agents stumble";
  (4) incident-to-rule loop may be manual; (5) PII handling incomplete (no rule for real client
  PII in fixtures/agent context).
- **Recommended actions:** runtime error log + minimal feature flag for the renderer; PII rule +
  pre-commit grep; "blast radius" tier in the work-state table; "Rejected Approaches" section +
  wire /post-mortem//incident to auto-append memory rules; periodic agent-stumble aggregation;
  document lens-*/markdown as the right-sized substrate equivalents.

These are the article's *conclusions*, not verified facts. Pass 3 of this audit tests each against
the ground-truth map and disk.
