# Pass 1 — Comprehend: "Bug-to-PR Automation — Automated Bug Triage (2026)"

Faithful restatement of what the article says. Claims tagged `(fact)` = verifiable/sourced
empirical claim; `(opinion)` = the author's judgment, recommendation, or framing. The article is a
primary research compilation (Stripe/Linear/Sentry/etc. sources listed at the foot) — it does **not**
embed its own multi-pass curator analysis, so there is nothing here to treat as second-hand "claims."

---

## 1. The five-stage pipeline (the spine)

The article frames every tool stack as a variation on one spine (the list says "five stages" but
enumerates six steps):

1. **Bug surfaces** — error monitor (Sentry), CI failure, issue tracker (Linear/Jira/GitHub Issues), or Slack report
2. **Trigger fires** — webhook, label, severity threshold, or scheduled scan
3. **Agent triages** — gathers stack trace, recent commits, affected files, repro steps, similar past issues
4. **Fix-or-escalate decision** — agent scores confidence + blast radius; below threshold escalates with full context, above proceeds
5. **Agent writes fix, opens PR** — isolated sandbox, runs tests, structured PR description, requests review
6. **Human review gate** — low-risk may auto-approve; high-risk always human; merge always human-controlled

**Central thesis (opinion, the most load-bearing claim):** "the bottleneck has moved from writing the
fix to reviewing it. The agent submitting the PR is solved. The review contract — what context,
evidence, and risk surface a human needs to trust it — is still being standardized."

## 2. Company case studies (mostly fact, sourced)

- **Stripe Minions** — 1,300+ PRs/week (fact); 30% of all bugs resolved autonomously during "Atlas
  Fix-It Week" (fact); deterministic orchestrator prefetches context (Slack/Jira/docs/Sourcegraph MCP)
  *before* the LLM runs (fact); curates ~15 task-relevant tools from a ~500-tool internal MCP
  "Toolshed" — agents never see the full catalog (fact); isolated devbox per run, pre-warmed ~10s,
  **no internet, no prod access** (fact); core agent is a fork of Goose in six infra layers (fact);
  **hard cap of 2 retries**, then flag a human (fact); interleaves LLM steps with hardcoded
  deterministic gates (fact).
- **Coinbase Forge** — 5% of merged PRs from background agents (fact); PR cycle time ~150h → ~15h, 10x
  (fact); built by 2 engineers, now serves 1,000+ (fact); isolated cloud sandboxes, full shell access
  (fact); "converged independently on the same architecture as Stripe and Ramp" (fact/framing).
- **Ramp Inspect** — same pattern; integrates with Slack + Linear rather than new interfaces (fact);
  inspired LangChain's Open SWE (fact).
- **LangChain Open SWE** — released Mar 17 2026; LangGraph + Deep Agents; isolated sandbox + curated
  toolsets + subagent orchestration + workflow integration; positioned as **the reference
  architecture** to build on, "don't design this from scratch" (fact + opinion).
- **Linear Agent** — public beta Mar 24 2026; Triage Intelligence (auto assignee/label/project,
  duplicate detect); deterministic Triage Rules; Agent Automations (NL instructions on triage entry);
  Code Intelligence (May 2026, code-aware triage, not yet full fix-PR) (fact). Adoption: coding agents
  in 75%+ of enterprise workspaces; agent-authored work 5x in 3 months; ~25% of new issues
  agent-authored (fact). CEO "declared issue tracking dead — tracker becoming an agent work queue"
  (opinion, attributed).
- **Sentry Seer/Autofix** — 3-step flow (Root Cause → Solution → Code Gen, can span repos) (fact);
  configurable stopping points (after Root Cause / after Plan / after PR Drafted) (fact); auto-trigger
  on 10+ events in 14 days (fact); can hand off implementation to Claude Code or Cursor (fact); AI PR
  Review `@sentry review` + `@sentry generate-test` (open beta May 2026) (fact).
- **GitHub Copilot Cloud Agent** — tech preview May 14 2026; assign issue → plan → branch → draft PR;
  `@copilot` in a PR; Playwright MCP auto-configured (fact). "Excels at low-to-medium complexity tasks
  in well-tested codebases" (opinion/framing).
- **GitHub Agentic Workflows** — tech preview Feb 13 2026; plain-Markdown workflows in
  `.github/workflows/` compiled by `gh aw`; **self-healing CI** (transient vs permanent triage, fix
  PRs); read-only by default, writes require pre-approved "safe outputs"; **PRs never auto-merged**
  (fact).
- **Cursor Automations + BugBot** — Automations launched Mar 5 2026 (event-triggered);
  **BugBot graduated reviewer → fixer** late Feb 2026; **35%+ of BugBot Autofix suggestions merged**
  (fact); agents have a memory tool, learn across runs (fact).
- **GitLab Duo** — Fix CI/CD Pipeline Flow posts a link to an MR with the fix; GitLab 18.x (fact).
- **OpenHands GitHub Resolver** — open-source; `fix-me` label → fix attempt + PR via GitHub Action;
  self-host with a PAT + LLM key (fact). "Best for teams that want maximum control" (opinion).
- **Devin** — fully autonomous ticket→PR; iterates on review comments; **13.86% of real-world GitHub
  issues end-to-end on SWE-bench** (fact, benchmark); ~$500/mo (fact); excels at bounded bugs,
  migrations, clear specs (opinion).
- **Greptile** — graph index + swarm PR review; v3 multi-hop, v4 fewer false positives; **catches 100%
  of high-severity bugs in benchmarks** vs 57% Copilot / 36% CodeRabbit (fact), but **higher false
  positive rate (11 vs CodeRabbit's 2)** (fact).
- **Ona auto-approval** — 3-step risk classification (static → semantic → agentic/Claude Code);
  high-risk keywords `destroy_all`, `payment`, `db/migrate`; **10% of low-risk PRs still need human to
  prevent drift**; every auto-approval posted to a public Slack channel; **time-to-first-approval
  2h49m → under 5 min, lead time −74%**; live Mar 13 2026 (fact).
- **Checkmarx** — Triage Assist + Remediation Assist for security vulns (Mar 2026) (fact).

## 3. Trigger mechanisms (ranked by signal quality — opinion ranking over factual descriptions)

1. **Error-monitor threshold** (highest signal) — bug is real, reproducible, user-facing; trace attached.
2. **Webhook from issue tracker** (most flexible) — `repository_dispatch` POST pattern given.
3. **CI failure event** (proactive) — failing test attached = ideal agent context.
4. **Label-based** (team-controlled) — `fix-me`/`agent`/`copilot`; best for teams building trust.
5. **Manual Slack command** (lowest friction) — `/minion fix <ticket>`.

**Recommendation (opinion):** small teams start with **label-based or error-monitor-threshold** —
highest signal-to-noise, no webhook infra on day one.

## 4. Triage sequence (the prescribed pre-fix steps)

Parse report → gather error context → search codebase → check recent git history → detect duplicates →
assess blast radius → estimate confidence → route decision. **Stripe's key insight (fact + emphasis):**
the orchestrator does steps 1–5 **deterministically before the LLM runs**, so the LLM's context budget
is spent reasoning about the fix, not gathering basics.

## 5. Fix-vs-escalate decision logic (2026 "consensus" — opinion synthesized from deployments)

- **Fix autonomously when:** single file / bounded area; a failing test already exists; trace points to
  a line; similar bugs fixed before; confidence above threshold (**teams set 70–85%**); **no payment,
  auth, migration, or data-destructive code**; low blast radius + good coverage.
- **Escalate when:** multi-service/repo; ambiguous root cause; schema/auth/payment changes; **2 failed
  attempts (Stripe's hard cap)**; below threshold; **P0/P1** (humans own these); touches > N files;
  **any cross-tenant data / permissions / security**.
- **Escalation handoff must include:** full triage context, root-cause hypothesis (even if uncertain),
  relevant files, what was attempted, suggested next steps. "This context package is what separates a
  useful escalation from dumping the problem back on a human cold" (opinion).
- **Automation continuum:** full autopilot (typos, dep bumps, config, doc links) → batch approval
  (10–50, low-stakes) → one-by-one (the standard) → human-owned (P0/P1, auth, payment, migrations).

## 6. The PR submission contract (prescriptive — opinion/standard)

A fixed PR template: **Problem / Root Cause / Solution / Test Coverage / Blast Radius / Evidence /
Confidence**. Trustworthy agent PR = tests *run* (output attached), specific root cause (line +
function), explicit blast radius, agent flags its own uncertainty, **minimal change** (no refactor
while fixing). Watch for: tests deleted to pass; "what changed" without "why the bug existed"; diffs
large vs stated scope; missing repro test.

## 7. Human review of agent PRs (opinion + Ona facts)

Agent PRs answer **different questions** than human PRs: did it understand the real root cause or treat
a symptom; is scope proportional; were tests *modified* (could mask failures); does blast radius match
the claim. Auto-approval = Ona's 3-stage pipeline (static → semantic → agentic). Suggests a dedicated
"agent PR" queue and a two-agent review chain (PR-Agent first pass before human).

## 8. Overnight operation (opinion + a couple of facts)

- **Don't** batch to one end-of-sprint review (Stripe: "10pm-Friday walls of findings"); run each PR
  through the risk pipeline at creation time.
- **PR queue cap** — hold the remainder past N for morning.
- **Infra (fact):** "GitHub's infrastructure buckled under agent commit volume in early 2026" —
  consolidate into meaningful commits, don't push every small change (also cuts CI cost).
- Recommended overnight flow: queue curated labeled issues before EOD → run in isolated sandboxes, no
  prod access → morning Slack digest → **block merges until ≥1 human reviewed** → **hard 2-retry cap**.
- **Cost controls:** per-task token budgets; hard iteration limits; cheaper models for
  triage/classification, stronger for code gen; monitor agent cost on the CI dashboard.

## 9. Build-vs-buy (opinion)

**Buy first** for 2–5 eng teams: Sentry Seer (error→root cause), Linear Agent (triage), Copilot Cloud
(issue→PR), Greptile/PR-Agent (review agent PRs), GitHub Agentic Workflows (CI→fix), Playwright MCP
(browser verify). **~$500–800/mo for a 5-person team — "much less than one engineer's time on triage."**
**Build when:** you need custom context (internal MCP/docs/APIs), domain-specific bug taxonomy,
volume exceeds per-use pricing, or need no-internet sandboxes. If building, **use Open SWE as the base**.
"Buy until the seams show; then build the thin layer that custom-fits your context" (opinion).

## 10. Browser/visual verification (opinion + facts)

Playwright MCP (auto-configured for Copilot) and Stagehand are the production browser tools. Add as a
**post-fix step**: change → spin browser → reproduce original bug → before/after screenshots → attach
to PR → flag visual regressions. "Optional but significantly increases reviewer confidence for
frontend bugs" (opinion).

## 11. Failure modes + defenses (the most transferable section — fact-grounded)

- **Test deletion** (most insidious) → require test count never decreases; lint for added skip
  annotations; human review of any test-file change.
- **Runaway retry loops** → hard cap 2 retries; token/iteration budgets; cost alerts.
- **Tool-misuse cascades** (fastest-growing failure mode H1 2026) → task-scoped tool restriction
  (~15 tools, not 500); circuit breakers on MCP calls.
- **Intent drift** (step 40+ of a long task, distorted objective) → reflection after each failure;
  task-complexity limits; structured milestone check-ins.
- **Hallucinated root cause** → require a reproduction case; verify bug manifests before fix and not after.
- **Scope creep** → explicit "make the minimum change, do not refactor anything you don't need to touch."

## 12. Action items (the article's own priority list, named for "event-vendor or any small team")

1. Sentry Seer Autofix at "Stop after Root Cause."
2. Linear Agent Triage Intelligence.
3. GitHub Copilot Cloud Agent for one bug type, measure 30 days.
4. Slack channel as the agent-PR log.
5. **Write an AGENTS.md (or equivalent)** — "This single file improves agent PR quality measurably."
6. Three-stage risk pipeline for auto-approval — only after 30 days of manual review first.
7. Playwright MCP verification for UI bugs.
8. **Hard limits before scaling overnight:** 2-retry max, per-task token budget, PR queue cap (~10).

---

### One-line thesis (faithful)

The PR-*writing* half of bug-to-PR is effectively solved across the industry; the unsolved, standardizing
half is the **review contract** — the structured context, evidence, blast-radius, and risk-classification
that lets a human (or a second agent) trust and gate an agent-authored fix — and the discipline (retry
caps, tool-scoping, minimal-diff, test-count floors, no overnight auto-merge) that keeps the pipeline
from generating expensive noise.
