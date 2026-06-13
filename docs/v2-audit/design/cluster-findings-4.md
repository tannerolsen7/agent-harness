# Cluster Findings 4 — Review + safety/enforcement/autonomy + tooling

**Aggregator output.** Consolidates the pass-3 "apply vs our harness" analyses for 9 articles into one
deduplicated, citation-anchored gap list. Governing rule (inherited from `CANONICAL-HARNESS-AS-IS.md`):
*no gap survives without a citation to a map section or a confirmed absence.* Anything the articles
"propose" that already exists on disk is moved to `alreadyDo`, not re-proposed.

Articles in cluster: `coderabbit`, `code-review-latentspace`, `bug-to-pr-automation`,
`anthropic-contains-claude`, `claude-dev-containers`, `auto-mode-config`, `agent-sandboxing-10co`,
`playwright-mcp-debug`, `ai-automation-ecosystem`.

The cluster splits into three problem-spaces that overlap heavily on the *enforcement-is-advisory*
spine: **review** (coderabbit, code-review-latentspace), **safety/enforcement/autonomy** (bug-to-pr,
anthropic-contains-claude, claude-dev-containers, auto-mode-config, agent-sandboxing-10co), and
**tooling** (playwright-mcp-debug, ai-automation-ecosystem). The deduplication below collapses the
many ways these articles re-discover the same handful of structural absences in the map.

---

## 1. Real gaps (deduplicated across the cluster)

### G1 — The absent 3rd bash guard (`block-dangerous-bash.sh`) is the single most-cited gap
**Citation:** `[canon §5 / §08 build-or-reject row]` + `[disk §3e: "Canon's 3rd guard — ABSENT on disk.
Disk has no safety-floor bash guard"]`.
**Sources:** anthropic-contains-claude (Gap 5), claude-dev-containers (gap b1), agent-sandboxing-10co
(gap b1), bug-to-pr-automation (gap 4).
Four articles independently land on the same canon-specified, disk-absent structural guard, each
supplying a different concrete failure mode it would catch: destructive SQL in migrations
(`DROP TABLE`/`TRUNCATE`/`DELETE`-without-`WHERE`, Replit July-2025 incident — agent-sandboxing #12);
`curl`-exfil of `~/.claude`/`.env` to a non-allowlisted host (claude-dev-containers threat-model-2,
anthropic-contains-claude layer-1); runaway/tool-misuse cascade in autonomous runs
(bug-to-pr §11). This is one build with a unified scope (deploys, `rm -rf`, boundary writes to
`.git`/`.husky`/`.claude`, destructive SQL patterns, curl-to-non-allowlist), not four hooks — scoping it
as the single canon-mandated guard avoids the §6 phantom-proliferation pattern. The existing CLAUDE.md
"destructive operations must have a rollback path" rule is *advisory prose*, not an enforced hook, so
this is a genuine absence, not a dup.

### G2 — No egress / outbound-network control of any kind for unattended `/queue`
**Citation:** `[absent]` — no egress hook in `[§3e]`, no network guard in `[§3f]` scripts, none in
`[§5]` canon-only list; `[verified: WebFetch(*), gh api *, supabase *, apply_migration all in the
92-entry allow list]`.
**Sources:** anthropic-contains-claude (Gaps 1, 2 — "the single largest gap the article surfaces"),
agent-sandboxing-10co (gap b2), claude-dev-containers (gap b4, as a documented allowlist).
The allow list grants trust at *destination* granularity (`WebFetch(*)`, `Bash(gh api *)`,
`Bash(npm install*)`, `apply_migration`) not *operation* granularity. The precise solo threat is fetched
external content (an unrestricted `WebFetch(*)` result) flowing into a session that simultaneously holds
the prod service-role key — the injection→exfiltration path. Decompose the disposition:
- **Build-or-config now:** drop `WebFetch(*)`, `gh api *`, `apply_migration` from the *unattended* allow
  set unless a non-model enforcer validates the operation (anthropic-contains-claude's cleanest immediate
  win); document the legitimate-egress allowlist (Anthropic inference, Supabase cloud, GitHub API, npm,
  Vercel) as an artifact even before any firewall exists (claude-dev-containers gap b4).
- **Research-gated:** a full proxy-based egress firewall (Privoxy/`pfctl`) — agent-sandboxing rates the
  solo mechanism "maintenance difficult"; see freshResearchWarranted FR1.
Per the enforcement-plane test (anthropic-contains-claude pass2): any egress control must name a
non-model enforcer (hook/wrapper) or it is a behavioral defense in disguise.

### G3 — The review/readiness gate is advisory, not structural; `.cr-ok` is already flagged for downgrade and never reaches CI
**Citation:** `[§3e: "Both agree the system is overwhelmingly advisory — neither has a deterministic
backstop for the bulk of skill bodies, CLAUDE.md rules, or the autoMode lists"]` + `[§3f Node 8.5(c)
gap: "CI never verifies .cr-ok" … "gitignored, never reaches CI"]` + `[§9: ".cr-ok sentinel as a
capability gate → document as a readiness signal, not a capability unlock"]`.
**Sources:** coderabbit (gap b1 — verdict invisible at PR/CI boundary), bug-to-pr-automation (gaps 2, 3),
agent-sandboxing-10co (a1 — gate advisory at CI layer), playwright-mcp-debug (gap b1),
ai-automation-ecosystem (gap b3 — "durability = our enforcement floor").
Five articles converge from different angles: the review *runs* (we have a strong `/cr`), but its verdict
is a binary local sentinel with no risk tiering, no observability trail, and no server-side enforcement —
so the reviewer's output is invisible exactly where CodeRabbit's structural advantage lives (on the PR, in
CI's view, auditable). bug-to-pr adds the missing deterministic checks the gate should carry: a
"test-count never decreased" floor and an automated blast-radius/risk classifier (confirmed absent from
the §3f script list). Ona's static→semantic→agentic, cost-ordered, publicly-observable auto-approval is
the most directly reusable replacement design. This is the cluster's spine: most other gaps are facets of
"the floor is advisory."

### G4 — The project's `autoMode` policy block sits in the file the classifier ignores — unattended runs are governed by bare defaults *right now*
**Citation:** `[confirmed absence — not in the as-is map; auto-mode predates it, appears in no §3 row]` +
`[live-check: claude auto-mode config shows defaults only; project custom entries appear 0 times;
~/.claude/settings.json has no autoMode key]`.
**Sources:** auto-mode-config (gaps b1, b2, b3, b4 — "the actionable core of the entire article").
Highest-severity *currently-broken* state in the cluster. The project built the correct `autoMode`
artifact (environment/allow/soft_deny/hard_deny, each led by `"$defaults"`, with the right event-vendor
entries) but placed it in committed `.claude/settings.json`, which the classifier does **not** read.
Consequences, both live: (a) unattended `/queue` runs won't trust the github/supabase/npm destinations the
tasks need, and (b) the default `soft_deny` ("Production Deploy: running production database migrations")
will over-block the project's own production-Supabase migration and `src/data/` write path → unattended
stall. Three coupled sub-items:
- **Relocate** the validated block to `~/.claude/settings.json` (or test `.claude/settings.local.json`),
  re-run `claude auto-mode config` until custom entries appear. Mechanical fix, but routes through a human
  per the no-agent-edits-to-guard-files rule (see rejectAsLiteral R3).
- **Resolve the prod/migration over-block** — needs an explicit allow carve-out for CLI-driven migrations
  against the configured remote, or a real local/prod distinction the classifier can reason over. Maps to
  `[§9]` ("the constraint catches *legitimate* work").
- **Distribution conflict (architectural, cross-theme):** auto-mode is honored only user-level or in a
  gitignored local file, so the one policy that actually runs unattended is the one the harness's
  commit-and-distribute V2 thesis (`[§0]`) **cannot commit, review, or distribute** — it won't travel
  with the repo to a second install (`[§8]`).

### G5 — No effectiveness-measurement layer and no calibration of `/cr`'s own output quality
**Citation:** `[§4 — the entire memory/metrics model is about *knowledge* stores, not *effectiveness*
metrics; no row for first-pass-approval-rate, review-cycle-count, or post-merge-defect tracking]` +
`[§6: @benchmark-runner is a phantom — "Referenced on disk, never built"]`.
**Sources:** bug-to-pr-automation (gap 5), coderabbit (gap b2).
You cannot compound what you don't measure. Nothing in canon or disk records a measurement of `/cr`'s
precision/recall (three sources can't even agree on its pass count — `[§3c]`), nor first-pass-approval
rate / cycle count / per-task-type tracking. This blocks the compounding loop both articles name as the
real lever. The methodology for *how* to calibrate an AI reviewer against a labeled defect set is the one
narrow external thread (see FR2). Aligns with canon backlog #12 (Skill Effectiveness Analytics).

### G6 — No autonomous trigger front-door; the harness can build but cannot be summoned by a bug signal
**Citation:** `[confirmed absence — nothing in §3e–§3f ingests a Sentry event, a GitHub issue label, or a
CI failure; the only triggers (SessionStart/WorktreeCreate/post-checkout) fire on *human* actions]`.
**Sources:** bug-to-pr-automation (gap 1 — "the single largest gap the article exposes").
`/queue` and `/feature` are human-invoked. The entire bug→PR pipeline presupposes an error
monitor / issue tracker / CI-failure surface that summons the agent; we have none. This is the gap that
gates everything autonomous — and is explicitly **hypothesis-gated**: per the harness's
"hypothesis-before-speculative-build" rule, do *not* build the trigger or its dependent classifier until
V2 decides an autonomous front-door is in scope. The minimum-viable-trigger question (is a GitHub-Issues
label the zero-infra entry?) is bounded research *conditional on that decision* (see FR1). Aligns with
canon backlog #16 (CI-Orchestrator), #18 (Human-in-the-Loop Trigger System).

### G7 — No memory write-back from agent runs (`session-end.sh` absent) — autonomous runs don't compound
**Citation:** `[§3e + §5: canon's session-end.sh (Stop → memory candidates) is ABSENT; disk memory is
fully manual]`.
**Sources:** bug-to-pr-automation (gap 5b), agent-sandboxing-10co (b3, as the closest declared item to a
timeout — but it does memory-capture, not timeout).
An autonomous loop that can't write back what it learned is the un-compounding version the articles warn
against. Note: this is the *write* half; G8 below is the *read* half of the same compounding-loop hole.

### G8 — Review findings have no read-path into task-start context (the compounding loop is half-open)
**Citation:** `[§4: RECURRING-FINDINGS.md is "pipeline-only … never read by implementers"]` + `[§6:
learned-patterns.md is a known phantom to be killed by the anti-duplication gate]`.
**Sources:** code-review-latentspace (gap 6), coderabbit (gap b3 — locked-decision corpus not wired into
`/cr` passes).
This is a **read-path gap, not a missing-file gap** — and the articles' literal advice ("build
`learned-patterns.md`") is a trap that would duplicate `docs/solutions/` + `RECURRING-FINDINGS.md`
(`[§4]`). The real absences: (a) `RECURRING-FINDINGS.md` is counted but never fed back to implementers at
task start; (b) the locked-decision corpus (`docs/adr/`, Rejected Patterns, PITFALLS) is *not*
demonstrably wired into `/cr` as review criteria — so `/cr`'s "governance-awareness" is asserted, not
mechanized. Both are the failure CodeRabbit can't solve (memory-locality) showing up as *our* latent
limitation unless explicitly closed.

### G9 — No machine-checkable acceptance criteria, diff-size gate, or file-scope gate in the pipeline
**Citation:** `[§3e: enforce-scope.sh (blocks staging files outside ALLOWED FILES) is canon-structural,
ABSENT on disk; listed in §5]` + `[absent: no map row for a line-count gate, machine-verified
acceptance-criteria file, or CI-precondition on PR open]`.
**Sources:** bug-to-pr-automation (gaps 3, 4), code-review-latentspace (gap 3), anthropic-contains-claude
(gap 4 — `/queue` task scope has no non-model enforcer; nearest primitive `enforce-scope.sh` is absent).
Three facets, distinct citations: (a) the spec discipline in CLAUDE.md is human-readable prose with no
committed, machine-verified acceptance-criteria artifact; (b) `enforce-scope.sh` is a citable canon-only
absence; (c) a diff-size cap and a CI-pass-before-PR precondition exist in neither layer. **Reject the
articles' magic numbers** ("5 PRs <400 lines") — adopt the *structure* (a cap/scope-gate exists), set the
thresholds ourselves (see rejectAsLiteral R1).

### G10 — Per-worktree credential scoping: the shared prod `.env.local` symlink partially defeats the Tier-0 firewall
**Citation:** `[absent: per-worktree credential isolation at the .env.local layer]` + `[§6 Tier-0 firewall
isolates *local-stack* creds, not the shared prod .env.local]` + `[memory: vitest reads .env.local which
is prod; No .env credential reuse]`.
**Sources:** claude-dev-containers (gap b2 — "cheapest defensible hardening, needs no container"),
anthropic-contains-claude (Gap 3 — `.env.local` agent-readable, "one injected WebFetch result instructing
read+POST of `.env.local` is the whole exploit").
The Tier-0 firewall isolates which *test* stack vitest sees; it does **not** remove the prod service-role
key from a path the agent can `Read`, and the symlink re-shares one prod credential into every worktree.
This extends the existing §6 firewall from test-DB isolation to outbound/read isolation — a real residual
absence directly adjacent to G2.

### G11 — Unattended harness wired to an attended-only browser MCP; no project-owned visual-verification skill
**Citation:** `[§3e worktree/UNATTENDED rows + verified .mcp.json configures chrome-devtools-mcp,
headed-only]` + `[§1 runtime-skill-list coupling: /verify, /run appear in the live registry but are not
project skills on disk]` + `[verified: zero data-testid across src/ and app/; no a11y-instrumentation row
in §3a]`.
**Sources:** playwright-mcp-debug (gaps b2, b3, b4, b5).
A map-internal contradiction surfaced by juxtaposition: our design center is unattended operation, yet our
only configured browser MCP (`chrome-devtools-mcp`) is headed-only and breaks in overnight runs — any
overnight agent attempting visual verification fails silently. Sub-items: (a) no project-owned, travelling
browser-verification skill (the `/verify`/`/run` we "have" are borrowed global/upstream skill names, not
committed); (b) zero agent-legible markup (`data-testid`/`aria-label`) and no rule mandating it — an
accessibility gap masquerading as a debugging gap; (c) for an RLS product, no guard that the agent is
acting as the *intended tenant* before trusting a browser snapshot (highest-severity false-confidence
case). **None of this requires Playwright** (see rejectAsLiteral R4) — the durable value is tool-agnostic.

### G12 — No policy for the upstream Matt-Pocock skill dependency, and no recurring-maintenance-cost lens on the build-or-reject registries
**Citation:** `[§1 "CONTEXT.md coupling" — global skills pull project structure toward an upstream
ecosystem's layout]` + `[§3b — /tdd is a divergent project-local fork, "two copies, no sync"]` + `[§5/§6
registries decide build/document/delete but carry no maintenance-cost column]`.
**Sources:** ai-automation-ecosystem (gaps b1, b2).
Two method-level gaps the buyer's-guide article transfers cleanly: (a) **owner-drift risk is un-priced** —
15 skills are vendored/symlinked from `mattpocock/skills` upstream and `/tdd` has already forked; V2 has no
stated policy (vendor-and-freeze / track-upstream / cut); (b) **§5/§6 dispositions lack a recurring-cost
lens** — several stateful §5 items (`branch-registry-guard.sh` + `active-branches.json`, pre-push
auto-rebase sync gate, `session-end.sh`) are cheap to write and expensive to keep correct. Apply the §9
golden rule to *upkeep*, not just *existence*. Low-effort, high-leverage register corrections.

---

## 2. Already do (anti-phantom list — do NOT re-propose)

- **`/cr` 9-pass + adversarial review against the full branch diff**, with all 4 lenses
  (assumption/composition/cascade/abuse) `[§3c, §3d]`. More review rigor than any tool the cluster
  studies. The "add an AI first-pass reviewer" proposal describes a capability we run in-process.
  *(coderabbit, code-review-latentspace, bug-to-pr, playwright-mcp-debug)*
- **`/cr-security`** dedicated security/auth/data-boundary review (INVOKER-aware, tenant-isolation-aware)
  `[§3c, §6]`. *(coderabbit, code-review-latentspace)*
- **Adversarial / Devil's-Advocate verification pass already exists** — only its *independence* is in
  question, not its existence `[§3c]`. *(code-review-latentspace)*
- **Deterministic pre-PR floor:** `block-dangerous-git.sh`, `block-npm-install.sh` (exit 2); pre-commit
  (ESLint + `tsc --noEmit` + vitest); pre-push (`.cr-ok` + integration tests + `next build`); CI
  (`ci.yml` + `integration.yml`) `[§3e, §3f]`. The "interleave LLM with deterministic gates" thesis is our
  existing pipeline. *(coderabbit, code-review-latentspace, bug-to-pr, agent-sandboxing-10co)*
- **Tier-0 prod-key firewall** (`worktree-create.sh` + `gen-local-env.sh` + `test-local.sh`) — refuses
  vitest unless URL is `127.0.0.1` `[§3e, §6]`. The article's layer-4 "creds-not-in-the-box" / "scoped key"
  / "isolated devbox" recommendations re-derive a control we already ship — *better* than their
  prescriptions (they aim at a Supabase credential tier that doesn't natively exist; we isolate the stack).
  *(anthropic-contains-claude, claude-dev-containers, auto-mode-config, agent-sandboxing-10co, bug-to-pr)*
- **`permission-logger.sh`** PostToolUse logger exists `[§3e, §6]` — the raw material for layer-3 logging
  (but not yet forensic-grade; see G2/G3 observability). *(anthropic-contains-claude)*
- **Config-file deny-listing is doctrine:** `permissions.deny` blocks `.claude/hooks/**`,
  `.claude/settings*.json`, `.claude/agents/**`, `.env*`, `supabase/config.toml`; "No agent edits to guard
  files" is a standing rule `[§3e; memory]`. *(claude-dev-containers, auto-mode-config,
  agent-sandboxing-10co)*
- **`claude auto-mode` exists exactly as described** (`config`/`critique`/`defaults`); the project already
  authored the recommended `autoMode` artifact and the rich `$defaults` soft/hard-deny lists are real
  `[live-check]`. The *content* of the recommendation is done — only its *placement* is broken (G4).
  *(auto-mode-config)*
- **Minimal-diff / no-refactor-while-fixing ("Two hats")** and the **destructive-operation/PocketOS
  denylist** are standing CLAUDE.md rules `[§9 keep-verbatim]`. The article's scope-creep and
  high-risk-keyword defenses are already doctrine. *(bug-to-pr)*
- **AGENTS.md + CLAUDE.md + CONTEXT.md all present** `[§3a]` — the "write an AGENTS.md to improve agent PR
  quality" action item is the single most-emphasized recommendation in bug-to-pr and it's already done.
  *(bug-to-pr)*
- **A browser MCP is already configured** (`chrome-devtools-mcp`, the *deepest-signal* tool) and the
  **Playwright-vs-Chrome decision is already made** — `.claude/mcp.md` records an explicit rejection of
  Playwright MCP as redundant `[verified .mcp.json + mcp.md]`. *(playwright-mcp-debug)*
- **`/debug` skill + CLAUDE.md rule** routing unknown-cause bugs through it before any fix `[§3b]`.
  *(playwright-mcp-debug)*
- **The four buyer's-guide disciplines are our audit's spine already:** "name a failure mode or it's
  overhead" is verbatim canon §9; reversible-vs-irreversible is load-bearing in §9 + estimation doctrine;
  "refuse cross-category comparison" is the map's citation rule; "price labor as first-class cost" is the
  harness-first cadence `[§9; §0; memory]`. Convergent corroboration, not new instruction.
  *(ai-automation-ecosystem)*

---

## 3. Reject as literal (article advice wrong for us if taken verbatim)

### R1 — "5 PRs <400 lines" / specific REJECT thresholds / "400/800-line cliff" as hard numbers
**Why wrong:** Confidence is inversely correlated with evidence in these articles — they *admit* "no broad
industry consensus on a specific number" then issue one. The anchor stats (Faros 154%/9%/91%) are
correlational and self-selected, conflating AI-causation with team self-selection. Adopt the *structure*
(a diff-size/scope cap and a REJECT tier should exist — G9, and the REJECT-tier concept is well-motivated)
but set the thresholds ourselves as tunable defaults. *(code-review-latentspace, coderabbit)*

### R2 — "No shared context" for the adversarial reviewer (different model / fresh prompt / empty context)
**Why wrong:** The article conflates three different independence mechanisms with very different costs, and
taking "no shared context" literally would **blind the reviewer to our Rejected Patterns and locked ADRs** —
colliding with code-review-latentspace's own pass1 §7 claim that `/cr`'s whole value is project context.
The correct design for us: **shared project canon, isolated solution context** — a fresh sub-agent with
clean task framing but full access to CLAUDE.md / Rejected Patterns / PITFALLS. Not a different model.
*(code-review-latentspace; the Gemini-CLI 43%→91% result is what makes independence load-bearing — but
verify *which* mechanism produced the gain before committing, FR3.)*

### R3 — "Paste this autoMode block into your settings.json" (the article's delivery path)
**Why wrong:** The project forbids the agent from writing settings files (`permissions.deny` blocks
`Write(/.claude/settings.json)`; "No agent edits to guard files" is a hard NEEDS-HUMAN handoff). The
agent must *prepare and verify* (run `claude auto-mode config`), and surface paste-ready content for a
human. Notably, the existing block landed in the wrong file precisely because it was human-pasted with no
agent to run the verification command and catch it. *(auto-mode-config)*

### R4 — "Adopt Playwright MCP, default to a11y snapshots"
**Why wrong:** Collides with a *recorded rejection* in `.claude/mcp.md` (Playwright redundant alongside
`chrome-devtools-mcp`) — and the article's own "running both is redundant" logic is *consistent* with our
rejection; it would only argue we picked the wrong one of two, a narrower claim than its framing implies.
The durable value (browser-evidence-in-CI, agent-legible markup, resolve the unattended/headed-only
contradiction — G11) is **tool-agnostic and requires no Playwright**. Also reject importing the iterative
*debug* loop into the *verification* path: the article fuses two loops that belong apart (CI wants only the
deterministic pass/fail artifact). *(playwright-mcp-debug)*

### R5 — Adopt the dev container / VM / DinD / microVM / OrbStack / MitM-token-proxy / gVisor stack
**Why wrong:** Wrong threat model for a single-developer-own-repo system. Container-escape caused **none**
of the documented incidents (§9 golden rule: a constraint that prevents no nameable failure mode is
overhead). The articles' own tables concede most of this doesn't transfer at solo scale; the dev-container
page is explicitly "Candidate, not Adopted." The transferable residue is one principle — *allowlist
operations not destinations, enforce off the model* — captured in G1/G2, not the infrastructure.
*(claude-dev-containers, anthropic-contains-claude, agent-sandboxing-10co)*

### R6 — Build a `learned-patterns.md` compounding store
**Why wrong:** `learned-patterns.md` is a §6 phantom the anti-duplication gate is explicitly designed to
kill — it duplicates `docs/solutions/` + `RECURRING-FINDINGS.md` (`[§4]`). The real gap (G8) is a
*read-path*, not a new file. Also reject the articles' **monotonic** learning store with no eviction model —
it collides head-on with canon §9's "ghost rules if unobserved 90 days; collapse," the exact scaffold our
canon pre-authorizes removing. *(code-review-latentspace, coderabbit)*

### R7 — "Never auto-merge" stated as inviolable law / gate on a model confidence score
**Why wrong:** Two confusions. (a) The "never auto-merge" law conflates auto-approve with auto-merge — the
real rule is "the agent is never the *last* deterministic gate before main," which our pre-push + CI
already satisfy; Ona's cost-ordered auto-approve (≠ auto-merge) is the higher-leverage pattern the article
underweights. (b) A self-graded confidence number is, by the article's own "hallucinated root cause"
failure mode, *uncorrelated with correctness* — gate on **structural** proxies (blast radius, keyword
denylist, P-level, test-count floor), never on the model's self-assessed confidence. *(bug-to-pr)*

---

## 4. Cross-themes (patterns recurring across the cluster)

1. **The enforcement floor is advisory, not structural — the cluster's master theme.** Every safety/review
   article re-discovers `[§3e]`'s "overwhelmingly advisory … no deterministic backstop." It manifests as
   the absent 3rd bash guard (G1), the missing egress enforcer (G2), the advisory review gate + unverified
   `.cr-ok` (G3), the absent scope/diff/acceptance gates (G9), and ai-automation-ecosystem's reframe of all
   of it as a **durability gap** (no checkpoint survives an interrupted run). Nearly the whole cluster is
   one structural deficiency seen from different doors.

2. **Trust granularity / the enforcement-plane test.** "The adversary is one level finer than the boundary
   you drew" (anthropic-contains-claude) and "make the agent emit evidence a deterministic gate can check,
   not a natural-language claim" (playwright-mcp-debug) and "gate on structural proxies, not model
   confidence" (bug-to-pr) are the same law: any control must name a *non-model enforcer* or it is a
   behavioral defense in disguise. This is the acceptance criterion for every G1–G3, G9 build.

3. **The articles audit the literature/threat-model, not the current disk — and under-credit shipped work.**
   Snapshots predate commits #99/#100 (Tier-0 isolation, autoMode/UNATTENDED). Every safety article
   re-derives the prod-key firewall, config deny-listing, or the destructive-op denylist as if missing.
   The aggregator's job is to subtract these (§2 alreadyDo) before counting gaps.

4. **The compounding loop is structurally half-open in both directions.** No write-back from runs (G7,
   `session-end.sh` absent) and no read-path of findings into task-start context (G8). Measurement is the
   precondition both halves need (G5). Three articles + the canon backlog (#8, #12) point at the same
   incomplete loop.

5. **The harness's distribution model collides with per-machine/un-committable config.** auto-mode's
   policy can't travel with the repo (G4); the upstream-skill coupling pulls structure toward an external
   ecosystem (G12). Both surface the §0/§8 "never installed anywhere but event-vendor" reality as a
   *design* constraint, not just a fact.

6. **Most articles' headline subject is the least actionable part.** The container, the 10-company
   taxonomy, the SaaS tool catalog, the specific reviewer SaaS — each article's nominal topic is a mirage;
   the durable signal is a tool-agnostic principle or a single map-cited absence. Resist gaps manufactured
   from the headline.

---

## 5. Fresh research warranted (strict — most pass-3s concluded "synthesize, don't re-research")

**FR1 — Minimum-viable autonomous-trigger surface + lightweight deterministic blast-radius/test-count
classifier — CONDITIONAL on V2 deciding the autonomous front-door is in scope.**
Bounded, two questions: (i) is a GitHub-Issues label (`fix-me`, OpenHands-style) the zero-infra trigger
entry for a solo/duo repo with no error monitor, and does it fit the existing worktree+`/cr` shell without
new services; (ii) is there a lightweight deterministic implementation of a test-count-floor +
blast-radius classifier (the articles describe Ona's but give no code). **Gate:** do *not* spike until V2
commits to a trigger front-door — building the classifier first is the speculative build the harness rules
forbid (G6). *(bug-to-pr-automation)*

**FR2 — AI-reviewer evaluation methodology: how teams measure false-positive/false-negative rates against
a labeled defect set.** Genuinely open and internal-facing — `@benchmark-runner` is a confirmed phantom
`[§6]`, so we have no measurement harness for `/cr`. This is the only thread that would actually move G5,
and it's a methodology question the corpus + map cannot answer. Short external pass, not a deep dive.
*(coderabbit, bug-to-pr-automation)*

**FR3 — One verification (not research): which independence mechanism produced the Gemini-CLI #26397
43%→91% gain — different model vs. fresh prompt vs. isolated context?** Decides the adversarial-pass
design (R2). This is corroboration of one fact before committing, not new research. *(code-review-latentspace)*

**FR4 — Capability checks better answered by *executing the binary on disk* than by external research
(flag, do not fan out):** (a) Claude Code's actual default `/queue` egress profile — a one-session
empirical check of what the sandbox permits outbound, and whether the built-in Bash/Seatbelt sandbox
exposes a usable egress allowlist (would make a Privoxy/`pfctl` proxy unnecessary — gates the build-vs-buy
half of G2); (b) does `.claude/settings.local.json` (gitignored) honor `autoMode`, resolving G4's
relocate-vs-generator decision; (c) can `chrome-devtools-mcp` run headless in UNATTENDED context, or is
reversing the Playwright rejection required (gates G11). Each is one command/one session against the
machine, executed during synthesis — not a research spawn.
*(anthropic-contains-claude, claude-dev-containers, agent-sandboxing-10co, auto-mode-config,
playwright-mcp-debug)*

**FR5 — One doc-check, deferred to V2-decision time:** whether host-level `managed-settings.json` at
`/etc/claude-code/` is honored by Claude Code running natively on host macOS (not just in a container) and
is un-writable by the non-root agent user. If confirmed, it becomes the deterministic, agent-unreachable
policy floor BOTH canon and disk lack — the highest-value, lowest-cost item the dev-containers article
yields. One targeted read of the settings-precedence doc, not a research pass. *(claude-dev-containers)*

**Everything else: synthesize against the map.** Eight of nine pass-3s explicitly concluded the actionable
content reduces to design-and-build decisions mapping to existing §3e/§3f/§4/§5/§6/§9 rows, not open
research questions.
