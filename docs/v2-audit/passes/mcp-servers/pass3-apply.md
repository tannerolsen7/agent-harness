# Pass 3 — Apply: the article against OUR harness (ground-truth map)

Building on pass2: Pass 2 isolated two durable instruments and one time-bound verdict [pass2 §7] — Instrument A (the two-question gate), Instrument B (the trifecta as a design invariant) — and showed the article's biggest blind spot is the *consume* side, which it waves through as "near-zero exposure" while its own trifecta logic applies there unchanged [pass2 §2]. It also showed "remove one leg" collapses for a client-proposal agent [pass2 §3], that the keep-it-small doctrine and the trifecta verdict point at the same coarse tools from opposite directions [pass2 §4], and that the article never considers a *dev-agent-only* MCP server — the one variant its own framework would rate best [pass2 §5]. This pass tests all of that against `CANONICAL-HARNESS-AS-IS.md` and the disk facts I verified.

Citations: `[map §X]` = CANONICAL-HARNESS-AS-IS.md; `[disk: path]` = verified file; `[absent]` = confirmed absence.

---

## (a) What we ALREADY do

1. **We consume MCP, deliberately and narrowly — exactly the article's "consume now" posture** [pass1 "Application"]. Disk has a dedicated governance doc `.claude/mcp.md` with a "Currently configured" table (`chrome` / `chrome-devtools-mcp`), a "Via claude.ai connectors" table (Supabase, Figma, Vercel), and explicit "When to add more (triggers, not now)" and "What NOT to add" sections [disk: `.claude/mcp.md`]. The article's standing rule "consume to build faster; defer building" is, in substance, **already disk policy** — the article validates an existing stance rather than exposing a gap here.

2. **We do NOT expose our own MCP server** [absent — no `.mcp.json` server we author; `.claude/mcp.md` lists only third-party consumed servers]. The article's "defer building" verdict matches reality: there is no event-vendor-authored server anywhere in the map [map §3b skills, §6 disk-only registry — none is an MCP server].

3. **We already practice "few, high-impact tools over 1:1 wrappers" at the data layer** [pass1 "What makes a good server"]. Our `src/data/` boundary is exactly intent-level functions (`getCurrentUser`, query funcs) that components/actions call — CLAUDE.md mandates "Supabase query functions MUST live in `src/data/`" and "Components are I/O only." The article's tool-design discipline is our existing architectural discipline under a different name.

4. **We already treat tool/skill *descriptions as the trigger surface*** [pass1 "What makes a good server"]. The map records "Phrase-keyed skill descriptions → 'trigger should be the situation, not the words'" as a Page-13 replace item [map §9]. The article's "description is the trigger, same as Agent Skills" is the same principle we've already audited.

5. **We already gate destructive MCP tool calls instead of allowlisting them** — `.claude/mcp.md` "Permissions hygiene" says: "For destructive MCP tools (e.g. SQL writes via Supabase, posting to external services), let the prompt fire each time rather than allowlisting" [disk: `.claude/mcp.md`]. And `settings.json` allowlists only *read* Supabase MCP tools (`list_tables`, `get_logs`, `get_advisors`, etc.) — `execute_sql`/write tools are deliberately absent from the allow list [disk: `.claude/settings.json` lines 103–117]. This is **the human-in-the-loop the spec mandates** [pass1 "Security surface"], already wired for the consume side.

6. **The trifecta's "egress" leg is already constrained by the Tier-0 firewall** [map §3e `worktree-create.sh` prod-key firewall; §6 disk-only registry "prod-key firewall (Tier-0 credential isolation)"]. The article's "no external egress from the same agent that reads private data" [pass1 "Application"] partially exists as infrastructure: agent worktrees get isolated/scoped credentials, not raw prod keys.

---

## (b) REAL gaps it exposes (each cited)

1. **The consume side has no trifecta audit — and per Pass 2 §2 that's where our live exposure actually is.** Our policy gates *destructive* MCP tools [disk: `.claude/mcp.md` Permissions hygiene], but nothing in the map encodes the *combination* check: an agent simultaneously holding Supabase-MCP read of prod data + Notion/web untrusted content + any egress tool. The map confirms `.env.local` points at **production** Supabase [map §"Testing" note reproduced in memory; `.claude/settings.json` line 14 "the Supabase project is production"], so leg (1) private-prod-data is *always present* for any agent with Supabase MCP. No map section encodes a trifecta gate for consumed tools — Instrument B [pass2 §7] is **unencoded** [absent]. This is the single most actionable yield.

2. **Instrument A (the two-question gate) is documented prose, not an enforced gate.** `.claude/mcp.md` "Adding a new MCP" and "When to add more" give *triggers* but not the article's two binary questions (will a non-deterministic agent consume it? does it fuse private-data + untrusted-input + egress?) [disk: `.claude/mcp.md`]. The map's enforcement column shows our floor is "overwhelmingly advisory" with "no deterministic backstop for the bulk of skill bodies, CLAUDE.md rules" [map §3e Net enforcement picture] — an MCP-addition gate would be one more advisory rule unless tied to the (absent) `block-dangerous-bash.sh`-style structural guard [map §5 "block-dangerous-bash.sh — 3rd structural guard, ABSENT on disk"].

3. **Tool/MCP descriptions are not in `/cr` scope — the article's explicit recommendation, and a real hole.** The article says tool descriptions "live in your repo, so they fall under `/cr` like any other code" [pass1 "Application"]. The map's `/cr` is 9 passes over the branch diff [map §3c] with no pass for *tool-poisoning / rug-pull review of MCP tool definitions or `.claude/skills/*/SKILL.md` description frontmatter*. With no event-vendor-authored MCP server today this is low-urgency for *authored* tools, but it bites now for **consumed third-party MCP descriptions**, which can rug-pull [pass1 "Security surface"] and which no map process pins or diffs [absent — no pin/diff of MCP tool descriptions in §3e hooks or §3f CI].

4. **No SDK / MCP-package supply-chain trust gate** [pass2 §5]. The map's only dependency discipline is `block-npm-install.sh` (asks before install) [map §3e] and the `dep-update` skill — which is an **empty stub on disk** [map §6 "dep-update/ empty dir — canon documents it fully but disk never built it"]. A consumed MCP server's SDK/package is precisely the rug-pull/supply-chain surface the article warns about, and our update discipline for it is unbuilt [absent — `dep-update` SKILL.md].

5. **The article exposes a stale claim in the *research corpus itself*, which the map's "audit artifacts rot" rule says to flag** [map §0 Correction log: "the project audit artifact itself rots… any 'ABSENT' claim must be re-verified"]. The article states we run a **"Playwright MCP" for the "ProofShot pipeline"** [pass1 "Application"]. Disk contradicts the *name*: our configured local MCP is **`chrome` / `chrome-devtools-mcp`** [disk: `.claude/mcp.md` Currently configured], and **Playwright MCP is explicitly on the "What NOT to add" list** ("overlaps with `chrome-devtools-mcp`; running both is redundant") [disk: `.claude/mcp.md` What NOT to add]. The underlying engine was once wired via `@playwright/mcp` per `[disk: LAST-SYNC.md v1.0]`, so the article conflates the browser engine with the named server. Not a harness gap per se, but a **citable factual error to correct** before this article feeds any V2 proposal — exactly the re-verification §0 demands.

---

## (c) Weaknesses in the article's OWN reasoning

1. **The asymmetry is unjustified — consume is policed leniently, build rigorously** [pass2 §2]. The article's own trifecta logic applies to our *consumed* Supabase-MCP-over-prod setup, yet it calls consuming "near-zero exposure because… your own credentials, locally." Pass 2 §2 shows own-credentials is the *confused-deputy condition*, not a mitigation. Against our ground truth this is a real miss: the map says our Supabase target *is* production [map §settings line 14], so the article under-rates the live risk it should be flagging.

2. **"Break the trifecta — remove one leg" is non-actionable for our exact product** [pass2 §3]. For a proposal agent, legs (1) private data and (3) egress are the product; only leg (2) untrusted input is removable, and the article itself lists client free-text as a core input. So its headline mitigation collapses to "split the reading agent from the sending agent" — which it states once and never elevates. Our harness *does* have the splitting primitive (per-worktree credential isolation [map §3e]), so the article under-credits the one defense we actually hold.

3. **It never considers a dev-agent-only MCP server** [pass2 §5] — the variant its own criteria ("a non-deterministic agent will consume this" [pass1 "Hype vs real"]) rate most favorably, since our `/queue`/sub-agent/background-agent fleet [map §1, §3d 23 agents] *is* a non-deterministic consumer with no customer egress. The article's build/no-build framing is binary-customer-facing and skips the category most relevant to a *harness* audit.

4. **It leans on Anthropic-as-vendor framing while arguing vendor-neutrality** — minor, but "this is real and durable, not a single-vendor bet" [pass1 "Mechanics"] is asserted from Anthropic's own donation announcement; the durability claim is opinion dressed as governance fact (Pass 1 tagged it). Low impact on the verdict, which Pass 2 §6 shows is robust to its weakest evidence anyway.

5. **The keep-it-small / trifecta tension is left unreconciled** [pass2 §4]: coarse intent-tools are good for the model and bad for blast radius, and the article doesn't connect its own "code execution with MCP" insight (a code-API gate between read and send) to the fix. For us that reconciliation is *already* our architecture — `src/data/` functions with the action layer interposing — so the article misses that the answer is plain function-calling, which it endorses elsewhere but doesn't link to its own coarse-tool warning.

---

## (d) Does it warrant fresh external research?

**No — synthesize, don't re-research.** Disciplined call:

- The protocol/mechanics/security content is **stable, well-sourced, and not the bottleneck** for any V2 decision: we are deferring building, so OAuth 2.1 / transport details are not on the critical path [pass1 "What it takes"; verdict matches map §6 absence of any authored server].
- The two actionable yields — encode Instrument B (trifecta gate for *consumed* tools) and bring MCP/tool descriptions into `/cr` scope — are **internal engineering decisions against existing map sections** [map §3c `/cr`, §3e hooks, §5 missing `block-dangerous-bash.sh`], not questions about the outside world. They need a design decision, not a literature search.
- The one external-facing nuance (MCPTox 60–72%, "8,000+ exposed servers") the article **already hedges as reported-not-confirmed** [pass1 "Security surface — verification flags"; pass2 §6]. Re-researching unverified scare stats is low-value and the verdict doesn't rest on them.
- **One small internal verification, not external research:** correct the "Playwright MCP / ProofShot" claim against disk before this feeds a proposal [gap (b)5] — that's a 2-minute fact-fix, already done in this pass.

**Net for V2:** harvest the two instruments, not the verdict. Fold Instrument A into `.claude/mcp.md`'s "Adding a new MCP" as the explicit two-question gate; pursue Instrument B (a consumed-tool trifecta check) as the genuinely new control — it targets §3e's "overwhelmingly advisory" enforcement gap where our *live* MCP exposure actually sits, not the unbuilt server the article spends most of its words on.
