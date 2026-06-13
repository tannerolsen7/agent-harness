# Pass 3 — Apply: the article against OUR harness (vs. CANONICAL-HARNESS-AS-IS)

Building on pass2: the real thesis is a **trust contract** — make the agent emit evidence a human or a
deterministic gate can independently check, not a natural-language claim (pass2 §1). The actionable
sub-distinction is that **debugging and verification are different loops** wrongly fused (pass2 §7):
verification belongs in CI as a deterministic gate; debugging belongs in the interactive session. The
fatal blind spot for *us specifically* is that the article assumes **attended operation** (pass2 §4) and
a **bug reachable from the rendered UI** (pass2 §2) — both false for a data-layer/RLS/unattended harness.
I apply those four to the ground-truth map.

Every gap below cites a row in `CANONICAL-HARNESS-AS-IS.md` (`[map §X]`) or a confirmed disk absence I
verified this session (`[verified]`).

---

## (a) What we ALREADY do

- **We already run a browser MCP — and it's the article's "deepest signal" tool, not the one it
  recommends as default.** `.mcp.json` at repo root configures `chrome-devtools-mcp`; `.claude/mcp.md`
  row describes it as "drive Chrome to visually verify UI work — screenshots, console logs, evaluate JS,
  tab/focus" `[verified]`. The article ranks Chrome DevTools MCP as deepest-signal but *headed-only,
  unattended-unsafe, ~18,000-token* (pass1 §3, §6). So we already adopted the heavy end of the spectrum.
- **We already made the Playwright-vs-Chrome decision the article frames as open.** `.claude/mcp.md`
  "Explicitly rejected" list: "**Playwright MCP — overlaps with `chrome-devtools-mcp`; running both is
  redundant**" `[verified]`. The article's central recommendation (default to Playwright MCP's a11y
  snapshot, pass1 §7, §10) is a path we have a *recorded rejection* against. This is the most important
  collision: the article argues for the tool we deliberately did not adopt.
- **We already gate at PR with a multi-pass review.** `/cr` (9 passes + adversarial) + `/cr-security`
  run before push, writing the `.cr-ok` sentinel `[map §3c]`. The article's "at PR open: autonomous
  review" insertion point (pass1 §8) maps onto an existing gate — ours just has no *browser-evidence*
  leg.
- **We already separate render-correctness from behavior-correctness in spirit** via the manual-QA
  coverage blocker, which canon keeps verbatim as a safety constraint `[map §9, "manual-QA coverage
  blocker"]`. The article's "separate does-it-render from does-it-behave" (pass1 §9) is the same split,
  un-automated on our side.
- **We already have a `/debug` skill and CLAUDE.md rule** routing unknown-cause bugs through it before
  any fix `[map §3b lists `debug` as aligned]`. The article's observe-diagnose-fix loop (pass1 §4
  workflow 1) is the interactive half we already own conceptually.

## (b) REAL gaps it exposes (each cited)

1. **No browser-evidence leg in CI or `/cr` — verification is still a claim, not an artifact.** Our CI is
   `ci.yml` + `integration.yml` = tsc/lint/vitest only, no browser stage `[verified: package.json has no
   playwright/E2E dep; .github/workflows has no browser job]`. The map confirms the deeper hole: "Node
   8.5(c) gap — CI never verifies `.cr-ok`" and "`.cr-ok` chain … gitignored, never reaches CI"
   `[map §3f]`. So even our existing review evidence doesn't reach CI. The article's trust-contract
   thesis (pass2 §1) lands exactly here: **agent UI claims are taken on faith because there is no
   deterministic artifact gate.** This is a real, citable gap — but see (c)/(d) on whether browser
   tooling is the right fix vs. closing the `.cr-ok`-to-CI hole first.

2. **No `data-testid` / agent-legibility instrumentation — and no rule requiring it.** `grep` finds
   **zero** `data-testid` across `src/` and `app/` `[verified]`. The map's instrumentation expectations
   live nowhere: no CLAUDE.md rule, no design-token doc covers it. Per pass2 §6, this is really an
   *accessibility* gap masquerading as a debugging gap — and the map has no row asserting we meet WCAG
   markup standards `[absent: no design/a11y instrumentation row in §3a governance docs]`. The cheap,
   durable win the article surfaces is "make markup agent-legible," which for us is currently unmet and
   un-mandated.

3. **The unattended-run mismatch is unaddressed for browser work.** Our harness's design center is
   unattended operation — `worktree-create.sh` + Tier-0 prod-key firewall + UNATTENDED mode are
   disk-only advances `[map §3e, §6]`. Yet our *only* configured browser MCP is `chrome-devtools-mcp`,
   which the article documents as **headed-only, breaks in overnight/headless runs** (pass1 §6; pass2
   §4). So we have a structural contradiction the map exposes by juxtaposition: **an unattended harness
   wired to an attended-only browser tool** `[map §3e worktree/UNATTENDED rows + verified .mcp.json]`.
   Any overnight agent that tries visual verification will fail silently — the exact silent-failure class
   the map already worries about for background agents `[map §3f, settings/permissions rows]`.

4. **`/verify` and `/run` appear in the runtime skill list but are NOT project skills on disk.** The
   live skill registry shows `verify`, `run`, `code-review`, `simplify`; `ls .claude/skills/` returns
   none of them `[verified]`. The map already names this exact hazard: "the runtime skill list mixes all
   layers … it cannot tell which layer owns each, nor which will travel" `[map §1, runtime-skill-list
   coupling]`. So the visual-verification capability the article assumes (a `/verify`-style loop) is
   *not* a committed, travelling part of our harness — it's an upstream/global skill we don't own. Real
   gap: **we have no project-owned, repeatable browser-verification skill**, only a configured MCP and a
   borrowed skill name.

5. **The tenancy false-confidence failure mode (pass2 §3) has no guard.** A browser snapshot taken as the
   wrong tenant yields a confident wrong diagnosis. Our RBAC/tenant isolation lives entirely in
   `src/data/` + RLS `private.team_ids()` `[CLAUDE.md Architecture; map references RLS-as-tenant-
   isolation]`, none of which a browser snapshot can see. There is no map row for "agent verifies it is
   acting as the intended tenant before trusting a snapshot" `[absent]`. For an RLS product this is the
   highest-severity version of the article's named visual-false-confidence risk and we have nothing for
   it.

## (c) Weaknesses in the article's OWN reasoning (that change what we should take)

- **It recommends the tool we already rejected, on grounds (token efficiency) that are real but
  cherry-picked** (pass2 §5: 200–400 vs. 15,000+ tokens are the same op 40x apart). Our `.claude/mcp.md`
  rejection of Playwright-alongside-Chrome as "redundant" is *consistent* with the article's own "running
  both is redundant" logic — so the article doesn't actually overturn our decision; it would only argue
  we picked the wrong *one* of the two. That's a narrower claim than the article's framing implies.
- **It fuses debugging and verification** (pass2 §7), so its "cap the debug loop at N" advice is wrong for
  the CI verification path we'd actually want. We should *not* import the iterative-debug loop into CI;
  we should import only the **deterministic pass/fail artifact** half.
- **It assumes attended operation** (pass2 §4) and never ranks tools on the attended-vs-unattended axis —
  the one axis that decides everything for us. Its top recommendation (Chrome DevTools MCP "deepest
  signal") is the *least* applicable to our unattended design center.
- **Its strongest forward claim (WebMCP "kill switch") over-runs its own "Watch" disposition** (pass2 §8)
  — correctly filed as future, so it generates no action for us now.
- **It demotes server-side tracing to "complementary"** while its own discriminator says logs win for the
  server-bug class that dominates a data-layer app (pass2 §2). For us the priority should be *inverted*.

## (d) Does it warrant fresh external research? (be disciplined)

**Mostly no — synthesize, don't re-research.** The ecosystem facts (pass1 §3) are a clean inventory and
the conceptual payload (trust contract; debug≠verify; accessibility==agent-legibility) is fully
extractable from this pass set plus the map. Three of the five gaps in (b) are **decisions, not unknowns**
and need no external input:
- Gap 1 (browser-evidence in CI) overlaps the existing **bug-to-pr-automation** and
  **harness-engineering-survey** passes already in this corpus — synthesize across those, don't re-fetch.
- Gap 3 (unattended vs. headed-only Chrome MCP) is a **map-internal contradiction** to resolve in Phase
  4, not a research question.
- Gap 4 (`/verify` not a project skill) is a **commands-vs-skills** question already covered by that pass
  dir — cross-reference it.

**One narrow, time-boxed external check is justified, if and only if Phase 4 decides to act on Gap 1/3:**
whether `chrome-devtools-mcp` can run **headless** in our worktree/UNATTENDED context, or whether
adopting headless **Playwright MCP** (reversing the `.claude/mcp.md` rejection) is required for unattended
visual verification. That is a concrete, falsifiable, ~30-minute capability question — not open-ended
research. Everything else here is a synthesis-and-decide task against the ground-truth map.

---

**Bottom line for V2:** the article's headline recommendation (adopt Playwright MCP, default to a11y
snapshots) collides with a *recorded rejection* in `.claude/mcp.md` and is the wrong altitude for us. Its
*durable* value is three reframes the map can act on: (1) close the verification-evidence-to-CI hole the
map already flags `[§3f]` — tool-agnostic, browser-optional; (2) mandate agent-legible/accessible markup
(`data-testid`, `aria-label`) which we have zero of `[verified]`; (3) resolve the unattended-harness /
headed-only-browser-MCP contradiction the map exposes `[§3e]`. None of these requires Playwright; all are
synthesizable now.
