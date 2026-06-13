# Pass 1 — Comprehend: what the article SAYS

Source: Notion "🔌 Research · MCP Servers — What They Actually Are, What It Takes to Build One, and When It's Worth It (2026)" (id `37be2971cd6281aa9e51dd14945a7a71`). Faithful restatement; tags = (fact) verifiable/sourced · (opinion) the author's judgment. The article embeds its own "Application to This System" section — those are treated as the author's CLAIMS (tagged opinion), not inherited as ground truth; Pass 3 tests them against the canonical map.

## Core thesis (as stated)
- An MCP server is **not a new kind of backend**; it is a **thin, standardized adapter** that lets an AI agent *discover and call* your tools at runtime instead of a human pre-wiring calls. (opinion — framing)
- The hard parts are **not the protocol** — they are **auth** (for remote) and **security** (agent + tools + untrusted input). (opinion, security-grounded)
- For event-vendor specifically: **keep consuming MCP servers; defer building one** — because the first server you'd build touches private client data *and* sends proposals out, "two-thirds of the recipe for a data-exfiltration hole." (opinion — the verdict)

## What a server / API / MCP server is
- A server = a program that waits for requests, answers, waits again; the frontend's `fetch('/api/proposals')` hits one. "Backend" ≈ those programs + DB + plumbing. (fact)
- An API = the menu of requests a server agrees to answer; a human dev reads docs and codes calls in a fixed order. (fact)
- **An MCP server is the same idea, one twist: the customer reading the menu is an LLM, not a human-written client.** (opinion — the central reframe)

## MCP vs REST (the one distinction that matters)
- REST: human-written client, fixed developer-coded sequence; caller learns the API from docs ahead of time; HTTP conventions standardized; best when steps are known/fixed. (fact)
- MCP: an LLM/agent **decides at runtime** which tool to call; the agent asks the server "what can you do?" and reads machine-readable descriptions; **what's standardized is how a model discovers capabilities and invokes them**; best when work is open-ended. (fact)
- Ecosystem analogy: **"USB-C for AI"** — each side implements MCP once, avoiding an N×M custom-glue explosion. (fact — common framing)
- Therefore "just wrap my REST API as MCP" is **right only if an agent will actually consume it**, else pointless. (opinion)

## Mechanics (kept simple)
- Protocol: **JSON-RPC 2.0** over a session; you never hand-write it, the SDK does. (fact)
- Three roles: **host** (app the user touches — Claude Desktop, Cursor, ChatGPT), **client** (connector inside host managing one server), **server** (your program). "Server" usually means a process you run, often locally. (fact)
- Three exposed things: **Tools** (model invokes — like POST), **Resources** (model reads — like GET), **Prompts** (templates). **Tools are 90% of the value.** (fact for the taxonomy; "90%" is opinion)
- Two transports: **stdio** (local; host launches your server as a subprocess; no network, no auth — good for personal/dev tools) and **Streamable HTTP** (remote web service; needs real auth). The old HTTP+SSE two-endpoint transport was **deprecated in 2025**; Streamable HTTP replaced it (SSE survives as an optional streaming mode inside it). (fact)
- Governance: Anthropic created MCP (Nov 2024), **donated it to the Linux Foundation's Agentic AI Foundation Dec 2025** (co-founded with Block and OpenAI; backed by Google, Microsoft, AWS, Cloudflare). Vendor-neutral; consumed by ChatGPT, Gemini, Copilot, Cursor, VS Code; **10,000+ public servers**, official registry; current spec `2025-11-25`. "Real and durable, not a single-vendor bet." (fact on governance; durability claim is opinion)

## What it takes to build one
- Official SDKs (Python, TS, Java, Kotlin, C#) do the heavy lifting; in Python FastMCP you annotate `@mcp.tool()` and the SDK generates JSON schema from type hints. (fact)
- **Effort ladder** (the article's table): (fact, sourced as a rough estimate)
  - Local stdio, a few tools → a few hours (~50 lines minimal).
  - Remote + bearer-token auth, hosted → 1–3 days.
  - Remote + **full OAuth 2.1**, multi-tenant, hardened → 1–2+ weeks.
- **"The cliff is auth."** Local stdio = weekend toy. Remote multi-user → OAuth 2.1 (your server becomes an OAuth Resource Server delegating to an IdP) = "real backend project." Internal/single-tenant → bearer-token check is the pragmatic minimum. (opinion, grounded)

## What makes a *good* server (cites Anthropic "Writing effective tools for AI agents")
- **The model chooses tools by their descriptions** → tool descriptions are a **prompt-engineering surface**, not an afterthought. Article notes this is the same "description is the trigger" principle as Agent Skills. (fact — Anthropic guidance; the Skills parallel is opinion)
- **Build few, high-impact tools — not a 1:1 wrapper of every endpoint.** Prefer `search_clients` / `create_proposal` over raw `list_rows`. Too many tools → "tool confusion" + context bloat. (fact/opinion blend — Anthropic-sourced)
- **Namespace** names (`eventvendor_create_proposal`), paginate, truncate, return instructive errors. (fact — guidance)
- Anthropic "Code execution with MCP" (Nov 2025): at hundreds of tools the **tool definitions alone** can consume **150k+ tokens** before the model reads the request; presenting tools as a **code API imported on demand** cut one example from **150k → 2k tokens**. **Headline maintenance problem = tool-count bloat** — the reason the "keep it small" discipline exists. (fact — sourced numbers; "headline problem" framing is opinion)

## The security surface (stated as mandatory reading)
- Core truth (Simon Willison): **these vulnerabilities are not bugs in MCP** — they are inherent any time you give an LLM tools + untrusted input, and **there is no universal fix.** (opinion — attributed; widely held)
- **Prompt injection** — hidden instructions in data/tool output the model obeys as commands. (fact)
- **Tool poisoning** — malicious instructions hidden *in a tool's description*, visible to the model but not the user; demo: innocent `add(a,b)` whose docstring secretly tells the model to read a credentials file and exfiltrate via a spare parameter. (fact — Invariant Labs research)
- **Rug pulls** — an approved tool silently changes its definition later; pin and diff tool descriptions. (fact)
- **The "lethal trifecta"** (Willison; called the single most useful rule): catastrophic when one agent simultaneously has **(1) private-data access + (2) untrusted-content exposure + (3) ability to send data out.** Any agent with all three is an exfiltration vector. **Design rule: break the trifecta — remove one leg.** (fact for the framework; design rule is opinion)
- **Confused deputy / OAuth misconfig** — server acting with more authority than the user has; scope tokens tightly. (fact)
- The spec mandates a **human in the loop** able to deny tool calls, plus `Origin` validation and localhost binding for local servers. Willison: treat those "SHOULD"s as "MUST"s. (fact — spec; advice is opinion)
- **Verification flags (the article's own hedges):** MCPTox 60–72% attack-success figures and "8,000+ exposed servers" are secondary/unconfirmed — "directionally credible but secondary; treat as reported-not-confirmed." (the article explicitly tags these — important for Pass 2)

## Hype vs real — decision criteria (the article's checklist)
- **Earns its keep when:** the consumer is a **non-deterministic agent** that must discover/choose tools at runtime; you serve **many heterogeneous clients** (Claude/ChatGPT/Cursor) and don't want N integrations; the workflow is **open-ended**; you already have **3–4+ AI integrations** (shared auth/error/schema pays off). (opinion — criteria)
- **Overkill / "AI slapped on" when:** the caller is **deterministic code** in a fixed sequence (plain REST/SDK is simpler/faster/debuggable/mature); **high-throughput batch** with known endpoint/schema; a **single known integration** with a few endpoints. (opinion)
- Reality check: GitHub, Supabase, Stripe MCP servers are **thin wrappers over existing REST APIs**; MCP doesn't replace your API, it sits in front of it *for agent consumption*. **No agent consumer → no reason to build.** (fact + opinion)

## Application to event-vendor (the article's own claims — to verify in Pass 3)
- **Verdict: consume now, defer building; if you ever build, scope it tiny and treat the trifecta as the design constraint.** (opinion)
- Consuming is high-leverage and already done: **Supabase MCP** (schema/queries/migrations during dev — read-only/branch-scoped per Supabase's prod-write caution), **Playwright MCP** (the "ProofShot pipeline, Node 3.5"), **Notion MCP**. These run locally under the builder's own credentials → near-zero security exposure; "the right use of MCP for a solo builder." (claim)
- Building/exposing an own server is overkill **because of the trifecta, not effort**: a `search_clients` + `create_proposal` server has (1) private client PII (article cites "the exact PII your build plan already rules must never sit in fixtures or agent context (Ashby addition #2)") and (2) external send; add any untrusted input (client free-text brief, scraped venue page) → all three legs. For $20k+ proposals tied to real people, not a feature-flag concern. (claim)
- Bar to build = **concrete validated demand** — e.g. customers want to drive the product from *their own* Claude/ChatGPT, or an in-app AI assistant needs one reusable tool layer across multiple agent surfaces. (claim)
- Even then, **plain function-calling against `src/data/` Supabase queries is likely simpler** than a full MCP server until there's a genuine *second* agent consumer — mapped to **Pillar 5** (code is a liability; don't add surface area) and **Pillar 2** (any send/write is irreversible → hard human-in-the-loop gate, never autonomous). (claim)
- If/when built: start **local stdio**, one or two high-value tools, **human confirmation on every send/write**, **break the trifecta** (no external egress from the agent that reads private data), go remote+OAuth only when an external client needs it. **Tool descriptions are a reviewed surface** (injection territory, live in repo) → they fall under `/cr` like any code. (claim)

## The standing rule (as the article proposes it)
- For event-vendor: **consume MCP servers to build faster; do not expose one until a real agent consumer exists.** Evaluating any "should we add an MCP server": ask first "will a non-deterministic agent actually consume this, or is a REST/SDK call simpler?"; second "does this tool give one agent private data + untrusted input + external egress?" First = "a plain API works" → marketing. Second = "yes" → the design is wrong before a line is written. (opinion — the proposed rule)

## Sources the article cites
modelcontextprotocol.io spec (2025-11-25); Anthropic — Donating MCP / Agentic AI Foundation (Dec 9 2025), Code execution with MCP (Nov 4 2025), Writing effective tools for AI agents, Advanced tool use; official TS/Python SDKs; Simon Willison (prompt injection + lethal trifecta); Invariant Labs (tool poisoning + WhatsApp exfiltration). Self-flagged secondary: MCPTox 60–72%, "8,000+ exposed servers."
