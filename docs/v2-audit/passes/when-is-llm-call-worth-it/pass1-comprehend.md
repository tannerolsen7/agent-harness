# Pass 1 — Comprehend: "When Is an LLM Call Worth It? — Decision Framework"

Faithful restatement of what the article says. Claims tagged (fact) / (opinion). No interpretation.

## Core question / thesis
- The right question is not "can AI do this?" but "does AI uniquely solve something deterministic code cannot, at a cost and latency the product can sustain?" (opinion — framing)
- Most problems people reach for AI on are already solvable, often better, by scripts/APIs/conditionals/deterministic code. (opinion)
- "Gartner 2026: only 28% of enterprise AI projects succeed" — presented as a scoping problem, not a model-quality problem. (fact-as-cited; the 28% is an attributed statistic, the interpretation is opinion)
- The doc explicitly is "not cheerleading for AI." (stance)

## The 7-gate decision framework (work in order, stop at first NO)
1. **Gate 1 — Can a deterministic solution solve this?** If input is well-structured and rules fully specifiable, write the rule. Regex/conditional/lookup/scripted API "does not hallucinate, does not add 2 s latency, costs fractions of a cent, same output every time." Heuristic: if an if/switch/regex would work, use it. (opinion + fact on determinism properties)
2. **Gate 2 — Unstructured/ambiguous input?** LLMs earn cost when input can't be fully specified in advance (messy NL, inconsistent formats, multiple valid phrasings, contextual nuance). Structured JSON / typed form / predictable API response → almost certainly no LLM. (opinion)
3. **Gate 3 — Is output language/judgment or a deterministic result?** LLMs are text-in/text-out; well-suited for drafted reply, summary, classification from ambiguous signals, explanation. Poorly suited when correct output is a number/date/price/boolean/anything formally verifiable. (fact on LLM nature + opinion on fit)
4. **Gate 4 — Cost at expected volume?** Estimate (calls/day)×(avg tokens/call)×(cost/1K tokens). Output tokens cost 3–5x input tokens. (fact) Model routing — 80–95% on cheap fast tier, escalate hard cases — is "the standard production pattern." (fact/observed)
5. **Gate 5 — Latency budget?** Complex LLM ops take 2–5 s E2E (TTFT <500 ms achievable; E2E <2 s a common SLA target). (fact) Synchronous user-facing path → latency is a "UX tax." Background/async has headroom. Real-time loops (physics, pricing, routing) can't accommodate LLM latency at all. (opinion + fact)
6. **Gate 6 — Can you test it reliably?** LLM outputs probabilistic; can't use exact-output unit tests — must assert behavioral properties across statistical samples. If you can't define "correct" programmatically or via judge model, you can't detect regressions. Untestable behavior in a production path = maintenance liability. (fact + opinion)
7. **Gate 7 — Unique value or commodity/FOMO?** Adding AI because competitors have it is FOMO, not product reasoning. Many "AI-enhanced" features could be a well-designed deterministic UI and no user would know. (opinion)

## Clear LLM use cases (LLM provides what deterministic code structurally cannot)
- NL interface over structured data (intent → structured query; the query execution stays deterministic). (fact/pattern)
- Classification of unstructured inputs (ticket routing, sentiment, messy tagging); note: traditional ML classifiers compete for high-volume/latency-sensitive (ms vs 2–5 s). (fact)
- Drafting & summarization (variation is the feature) — example cited: Monica's floral proposal descriptions. (pattern)
- Extraction from unstructured docs (contracts, resumes, invoices) — JSON-schema-enforced structured output on probabilistic extraction. (pattern)
- Copilot patterns (AI suggests, human decides) — reduces cost of probabilistic errors because wrong suggestions are corrected before they matter. (opinion/pattern)
- Agentic tasks with bounded scope + human checkpoints (code review agents, research agents, change-request analyzers). (pattern)

## When NOT to use an LLM
- Anything with a correct/verifiable answer (tax, pricing, inventory, order status, date arithmetic, checksums) — LLM can be the *interface* but computation must be deterministic. (opinion, strongly asserted)
- High-volume low-latency processing (thousands/min) — LLM latency+cost unviable; use ML/rules at microsecond latency. (fact)
- Compliance/audit-required decisions (loans, access control, regulatory) — probabilistic + opaque audit trail disqualifies. (opinion)
- Simple CRUD + workflow orchestration — if-statements and API calls; LLM adds ~2 s and ~$0.01. (opinion)
- Structured data transformation (CSV/JSON reshaping) — a parsing library is faster/cheaper/correct. (fact)
- Search/retrieval of known items — DB query or full-text; semantic search only when intent is fuzzy and keyword fails. (opinion)
- FOMO features. (opinion)

## Gray areas (judgment, not rule)
- Classification at scale — start LLM, migrate to fine-tuned ML/rules if volume/SLA/cost demand. (opinion)
- Structured output extraction — but consistent input format → template extractor cheaper/more reliable; LLM only for genuinely messy. (opinion)
- Recommendation systems — collaborative filtering for "users who bought X"; LLM for personalized *explanation* or reasoning over sparse data. (opinion)
- Form assistance/autocomplete — known vocabulary → deterministic; generative reasoning ("what else might a client want?") → LLM. (opinion)

## Cost model
- Token economics: output 3–5x input; ~1,000-token GPT-4-class call ≈ $0.005–$0.015; 10K/day ≈ $50–150/day ($1.5–4.5K/mo); 100K/day ≈ $15–45K/mo; Haiku/Mini tiers cut 10–20x with capability tradeoffs. (fact-as-cited)
- Hidden cost = state: most tokens are conversation history/system prompts/re-sent context, not user messages; unbounded context windows are the primary cost-overrun cause; prompt caching cuts stable content to ~10% of standard rates. (fact)
- 80/20 routing: 80–95% on fast/cheap tier, escalate hard cases; needs an evals-based escalation trigger. (fact/pattern)
- Self-hosting crossover ≈ $300K/mo API spend; below that API-first wins once eng time is counted. (fact-as-cited)
- Gross margin: AI-native (inference in every interaction) 50–65% vs 78–85% traditional SaaS — a reason to be precise about which interactions need inference. (fact-as-cited + opinion)
- Viability threshold heuristic: if per-call LLM cost > 10% of revenue per transaction (or per seat/expected calls), economics are uncomfortable — re-examine necessity, cheaper tier, or async/batch. (opinion/heuristic)

## The Boring Software Principle
- Most reliable software does one thing correctly every time and fails clearly — an engineering requirement, not aesthetic. (opinion, strongly asserted)
- LLMs fight this via three systemic properties: **non-determinism** (same input → different output by design; harder regression/debug/audit), **latency** (500 ms–5 s per synchronous request), **cost at scale** (linear with usage; value must scale too). (fact)
- Discipline: build the boring version first; ship if it solves the problem; reach for LLM only when boring version structurally cannot work. Explicitly equated with "Build what's needed now." (opinion)

## Latency & reliability in UX
- Thresholds: <100 ms instant; 100–500 ms noticeable-OK; 500 ms–2 s aware-of-waiting (OK only if output clearly valuable); 2–5 s slow (needs streaming/progress/expectation-setting); >5 s synchronous → abandonment/trust loss. (fact-as-cited)
- LLM synchronous calls usually 2–5 s without streaming; streaming moves *perceived* start earlier but doesn't reduce total time. (fact)
- **Compounding reliability:** 3 chained 90%-reliable steps → 0.9³ = 73% E2E; each step compounds failure. Mathematical case for minimal LLM steps + deterministic validation/fallbacks. (fact)
- **Fallback obligation:** every LLM call in a product path must have defined behavior on failure/low-confidence; "return an error" is not a product experience; fallback = deterministic default / cached result / simpler model / non-AI path; must be designed before the call is added. (opinion, strongly asserted)
- Async vs sync placement: move LLM calls into a job queue where possible to keep the sync path fast. (opinion/pattern)

## Testing implications
- What breaks: exact-match assertions (flake), snapshot tests (false-fail on every model update), deterministic coverage metrics (misleading — 100% wrapper coverage ≠ testing model behavior). (fact)
- What works: property-based assertions (output satisfies a contract); statistical eval (run N times on golden set, measure pass rate — 95% baseline, regression at 85%); judge models (a 2nd LLM evaluates — expensive but effective); structured outputs as test surface (Zod/Pydantic → schema validation, deterministic+fast); behavioral probes (adversarial inputs to catch capability regressions across model updates). (fact/pattern)
- **Structured output bridge:** enforcing JSON-schema output makes the LLM behave "like a typed function call" — probabilistic inside, schema-validated shape out. (opinion/pattern)
- Cost of untested LLM behavior: regression is silent until a user hits it; evals belong in CI as first-class, not post-hoc QA. (opinion, strongly asserted)

## How AI-native companies actually decide (observed patterns)
- First question: does the problem require language understanding? Linear/Notion use LLMs for search-intent, summarization, draft generation — not sorting/filtering/CRUD. (fact-as-cited)
- Volume+latency kills naive impls; Stripe fraud / Datadog anomaly use ML/rules for the high-volume baseline, LLM only for escalated hard cases (~90% deterministic fast path / 10% LLM). (fact-as-cited)
- 20–30% of initial budget goes to evaluation infrastructure — evals built before features. (fact-as-cited)
- Co-pilot pattern dominates enterprise (Copilot, Cursor, Notion AI): augmentation not automation; human in loop for every consequential output; changes acceptable error rate from near-zero to "whatever a human reviewer catches." (fact-as-cited + opinion)
- Structured outputs are the production standard: prose → end users; structured data → downstream code; treat LLM output as unvalidated user input and validate accordingly. (fact/pattern)
- Model routing is a cost lever not a quality compromise (Braintrust, Scale AI); routing logic is often itself a lightweight classifier/rules on input features. (fact-as-cited)
- **"Is this reversible?" test for autonomous/agentic actions:** write actions to a staging buffer before commit; require human confirmation for irreversible operations — the production safety pattern, not theoretical. (fact/pattern)

## Application to event-vendor (the article's own mapping)
- LLMs NOT needed: proposal totals/tax/pricing (arithmetic); filter by status/date/client (DB queries); change-request lockout windows (timestamp comparison); notifications (triggered function); CRUD for catalog/proposals/line-items (forms+API). (application)
- LLMs could earn cost: generating personalized proposal descriptions from structured catalog data; parsing a client's unstructured brief ("romantic, garden-style, dusty pink") into structured search params; summarizing change-request history into a human-readable narrative. (application)
- Correct pattern for this stack: LLM calls (1) in server actions/edge functions never components; (2) Zod-validated structured output; (3) defined deterministic fallback on low-confidence/invalid; (4) async/background where possible; (5) tested via property assertions + small golden set, not exact-match. (application)
- Standing rule: when planning a feature, write the deterministic version first; ship if it solves it; add an LLM only if the deterministic version structurally cannot serve the need. "AI is one of many tools — not the organizing principle." (application)

## One-line thesis
Build the boring deterministic version first; spend an LLM call only where ambiguous input or language generation is the actual product value, and only behind structured-output validation, a defined fallback, evals-in-CI, and a cost/latency budget that the transaction can sustain.
