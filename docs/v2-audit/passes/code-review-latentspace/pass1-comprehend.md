# Pass 1 — Comprehend

**Article:** "Code Review in the Agent Era — Latent Space Analysis & 15+ Company Survey (2026)" (Notion `376e2971cd6281a8b351d84606b212c5`).

Faithful restatement of what the article SAYS. Tags: (fact) = empirical/attributable claim the article presents as measured or sourced; (opinion) = the author's judgment, recommendation, or framing. The article embeds its own editorial analysis and action items — those are tagged (opinion) here and are treated as CLAIMS, not inherited as truth.

---

## 1. The Latent Space thesis (Ankit Jain / Aviator)

- (opinion) Core provocation: code review as practiced today is already broken; AI-speed code generation will not fix it, it will expose the fracture.
- (fact, attributed to Faros AI) Study of **10,000+ developers across 1,255 teams**: high-AI-adoption teams completed **21% more tasks**, merged **98% more PRs**, but PR review time rose **91%**, average PR size rose **154%**, bug density rose **9% per developer**. DORA metrics showed no org-level improvement. Individual velocity up; system throughput flat.
- (opinion) Jain's conclusion: humans already couldn't keep up with review at human-speed authorship; the fix is not to review faster but to change what review is *for*.

### The five-layer verification model (Jain) — all (opinion), one experiment cited as (fact)
- **L1 Competitive Generation** — multiple agents solve the same problem; winner chosen by test pass rate, diff size, dependency impact, not human style judgment.
- **L2 Deterministic Guardrails** — custom linters / org-wide invariants in CI (no hardcoded creds, every endpoint authed, billing uses Money type); parse-and-fail, not LLM opinion. (fact, attributed to Aviator Verify) experiment on 6,000 lines of AI code checked 65 acceptance criteria in 6 min: 60 passed, 4 failed, 1 partial.
- **L3 Behavior-Driven Development** — specs are source of truth, code is the artifact; humans approve the *spec* before code runs. Article calls this "the most significant philosophical shift."
- **L4 Permission Architecture** — fine-grained scope limits; auth/schema/payment changes auto-escalate to human review because blast radius is disproportionate.
- **L5 Adversarial Verification** — a separate agent whose only job is to break the coder's work; coder and verifier share **no context** ("auditor doesn't prepare the books").

### Editorial analysis (article's own, (opinion))
- Model is "directionally correct but incomplete for small teams."
- L1 has real compute/coordination cost; only pays off when human re-review cost exceeds running two agents.
- L3 is hardest to operationalize (requires upstream spec discipline most teams lack).
- L5 is "most actionable for this system" — `/cr` already does a version of this, but the coding agent and review agent **share the same model and context window**, which weakens independence.
- Jain's reframe: future state is "ship fast, observe everything, revert faster" — a bet on observability infrastructure, not review rigor.

## 2. 15+ company survey (mostly (fact), attributed per company)

- **GitHub Copilot Code Review** — (fact) agentic tool-calling architecture (Mar 2026); High/Medium/Low severity; June 2026 added agent skills + medium-analysis tier; custom review instructions; consumes Actions minutes (usage-based) as of Jun 1 2026. (opinion, GitHub's stated philosophy) AI review is first-pass, not final authority.
- **Vercel** — (fact) ships PR review in Vercel Agent (multi-step reasoning for security/logic/perf). (fact) shifted from docs to *runnable tools* (a safe-rollout skill is a tool that wires the flag + rollout plan + rollback conditions, not a Notion page). (fact) agent adoption was bottom-up, not mandated.
- **Cognition (Devin)** — (fact) 2025 review: human reviewers exchange **11.8% more review rounds** for AI code; AI suggestions adopted at lower rate than human suggestions. (opinion, Cognition's model) Devin replaces tasks not roles; architecture/product logic stay human; optimized for async unsupervised structured tasks.
- **Sourcegraph (Cody/Amp)** — (fact) exited mass market, killed Cody Free/Pro, enterprise-only ($59/user/mo). (opinion) differentiator is cross-repo code intelligence. (fact) new Amp product runs Smart Mode on Claude Opus 4.7, includes agentic review; (fact) limitation: response truncation ~200 lines interrupts large-diff review.
- **Cursor** — (fact) background agents clone repos in isolated Ubuntu VMs, run against a spec, open a PR; up to 8 parallel; approval is non-optional for production. (fact) Plan Mode (2026): agent reads docs/rules, asks clarifying questions, generates editable Markdown plan before code — (opinion) "a pre-execution spec gate, matching Jain's L3."
- **Aviator** — (fact) three-layer model in practice (not five): Org Invariants, Domain Contracts, Acceptance Criteria. (opinion) Swiss cheese model; Verify is the most direct spec-driven deterministic pre-review.
- **Greptile** — (fact) builds a full codebase graph (functions, connections, historical change patterns) before reviewing; cross-file + regression detection. (fact) has **never shipped code generation** → no conflict of interest ("auditor doesn't prepare the books" as product decision). (fact, self-reported) 3x more bugs caught, 4x faster merges.
- **Graphite** — (fact) core value is stacked diffs (small dependent PRs merging in sequence); AI review secondary. (opinion) stacked diffs are the structural answer to PR-size: a 1,000-line agent PR is unreviewable; five 200-line stacked PRs are a different class of artifact. (fact, reported) stacking forces agents to scope work more narrowly.
- **Qodo** — (fact/opinion) review-gate specialist; runs before merge, flags missing tests/logic errors/uncovered edge cases; no IDE assistant features — purely a quality checkpoint.
- **Augment Code (Intent)** — (fact/opinion) structured oversight over autonomous delegation (inverse of Devin); every task within a defined scope boundary, expansion requires human confirmation; "developer-in-the-loop." Tradeoff: lower velocity ceiling, higher predictability.
- **Microsoft (internal)** — (fact) systematic review catches 60-90% of defects pre-prod, cuts maintenance cost 40%. (fact) effectiveness vs PR size: <400 lines = highest detection; 400-800 = drops 50%; 800+ = drops 90%. (fact, policy) PRs >400 lines require senior sign-off before review begins.
- **Elementor** — (fact) internal opinionated review agent enforcing *this team's* patterns, not general best practice. (fact, measured over 6 mo) fewer review cycles + fewer post-merge regressions. (opinion) matches L2 not L5.
- **Ona** — (fact) risk-classification layer auto-approves low-risk PRs without human review → **74% lead-time reduction**. Risk classification is deterministic (paths touched, diff size, auth/schema/payment touched). (opinion) an implementation of L4 at the review stage.
- **Bitloops** — (fact) compounding quality loop: violations caught are recorded + made available as context for future generation. Over **8 weeks**: security violations 15→2 (87%), architectural 12→1 (92%), compliance 8→0 (100%). (opinion/finding) improvement came from context accumulation, not model updates.
- **Warp** — (fact/opinion) pre-review prep discipline: read related PRs, check linked issues, understand intent; review structured as understand purpose → verify approach → check implementation → validate tests. A discipline, not a tool, but it compounds.
- **Google (Gemini CLI, Discussion #26397)** — (fact) iterative cross-model review (A writes, B hunts bugs, A fixes, B retests, repeat) improved merge readiness **43% → 91%** on a test PR set; **3-4 rounds** of bug-hunt/fix before human review produced the result. (opinion) closest public L5 implementation with quantified results.

## 3. Tracking skill/agent effectiveness over time ((opinion) framework)

- (opinion) Gap in most systems: review skills deployed then evaluated anecdotally.
- Metrics to track: **first-pass approval rate** (primary quality signal), **review cycle count per PR**, **post-merge defect rate attributed to agent PRs** (tracked separately from human PRs), **violation recurrence rate** (same mistake 3x → spec context not accumulating), **PR size trend** (leading indicator of future bottleneck).
- Compounding mechanism: a **persistent learning store** the agent reads at the start of each run; violations recorded (what, why it violates, correct pattern). (fact, citing Bitloops) 87-100% reduction demonstrates this is not theoretical.
- (opinion, application claim) For a Claude Code harness this maps to: `/cr` MUST FIX findings written to a project-specific patterns file (e.g. `.claude/learned-patterns.md`) read at task start; `/compound` should explicitly capture *review findings* as a category.
- Multi-agent measurement: score coder by first-pass approval, reviewer by post-merge defect catch, adversarial agent by false-positive rate; A/B test one agent at a time; same-task comparisons across agent versions.

## 4. The rejection question — when should `/cr` say no? ((opinion), high relevance to our harness)

- (opinion) Current `/cr` has three buckets: MUST FIX (auto-fixed), NEEDS HUMAN, SUGGESTION. None is "this approach is fundamentally wrong; close the PR and re-spec." Article calls this "not a minor gap."
- Rejection warranted when: (1) **scope explosion** (touches more files than spec; combines substantive + unrelated edits — "top rejection trigger for agentic PRs"); (2) **misunderstood requirements** (functionally correct, wrong problem — only detectable by checking diff against spec); (3) **unreviewable diff size** (>400 drops 50%, >800 drops 90% → reject, re-submit as stacked diffs); (4) **failed CI with no clear fix path** (strongest predictor of non-merge → close and re-queue, don't escalate to human); (5) **auth/schema/payment changes with zero/negative test delta**.
- (opinion) Why it matters: without REJECT, the system has no concept of approach-level failure and biases toward shipping something rather than stopping. For a small team running `/queue` overnight, the morning queue can hold well-polished PRs solving the wrong problem.
- (opinion, recommendation) Add a `REJECT` classification to `/cr`: triggers = diff >800 lines, CI failing with no auto-fix, files outside spec scope, auth/schema with zero test delta. Rejected PR closes automatically and re-queues with a reason note.

## 5. Overnight runs and team dynamics ((opinion)/structural guidance)

- Overnight workflow: write spec before EOD → agent executes overnight → wake to a branch + verification report + summary; morning starts with review not writing. Argument: fresh-eyes review catches more; ~15h of idle compute converted to productive time.
- **2-3 engineers**: review bottleneck is acute; practical limit **3-5 overnight PRs total, each <200 lines**. The agent's principal usually reviews (unavoidable conflict of interest); mitigation = mandatory AI pre-review (CodeRabbit or `/cr` reviewer mode) — human reads the AI reviewer's findings, not the diff cold.
- **10+ engineers**: rotation viable; spec author should not be primary reviewer.
- PR caps: per-engineer reviewable capacity in a 2h morning window = 3-5 PRs (~200 lines each); 400-line degradation threshold; 800-line hard ceiling; step limits per session recommended. For a 2-3 person team on `/queue`: **5 PRs total, each <400 lines**.
- Morning review windows: dedicated blocks (e.g. 9-11 AM with explicit done-by time) over ad-hoc; a daily message listing PRs >24h old.

## 6. `/queue` and `/feature` integration ((opinion)/recommendation)

- Core question: should `/queue` require each task go through `/feature` first? Depends on whether `/feature` adds spec refinement, clarifying questions, explicit definition-of-done before code (then gating = direct L3 implementation) or is just a pipeline wrapper (then gate is overhead).
- (fact-ish/finding) Agents that one-shot entire features run out of context mid-implementation and produce unfinished, undocumented work. Best overnight output comes from teams that write *more carefully* when the agent runs unsupervised.
- (opinion) Overnight spec file needs five sections: problem statement, acceptance criteria, files in scope (explicit), success condition (automated check), what should NOT change.
- (opinion, recommendation) **Tiered gate**: require `/feature` output for tasks touching auth, schema, new UI surfaces, or cross-module changes; allow direct `/queue` for contained mechanical tasks.
- Structural `/queue` changes proposed: (1) diff-size cap as hard gate (>400 fail + re-queue); (2) CI must pass before PR opens (else auto-close + re-queue with log); (3) file-scope enforcement (touching out-of-scope files flags before PR opens); (4) mandatory `/cr` before PR + add REJECT; (5) machine-generated PR summary required.

## 7. CodeRabbit positioning ((opinion))

- (fact) two-click setup, auto PR summaries, inline security scans, GitHub-native, <5 min to surface issues, learns team preferences. (fact, cited 2026 review) scored **1/5 on completeness** vs Greptile/Augment — fast but misses architectural reasoning, no codebase graph, no cross-file patterns, truncates large diffs.
- (opinion, application) For THIS system CodeRabbit is "not currently used and not necessary"; internal `/cr` with project context (CLAUDE.md, AGENTS.md, ADRs, Rejected Patterns, immediately updatable) outperforms it for this codebase. Reconsider if team grows to 5+ engineers and 20+ PRs/week (fast triage layer before `/cr`).
- (fact) CodeRabbit's "agentic SDLC" vision: review before code (spec review), during generation (guardrail checks), after merge (behavior monitoring) — matches Jain's five layers; signals market moving away from post-commit review.

## 8. Path to one-shot features ((opinion))

- One-shot is not a near-term goal. Real north star: **agent PRs senior engineers approve on first review, no revision cycles** (measurable via first-pass approval rate).
- Stage 1: 2-4 revision cycles, review time dominates, humans fix implementation + approach errors. Stage 2: technically correct but needs human judgment on approach, 1-2 cycles. Stage 3: first-pass pass for contained well-specified tasks, review confirmatory. Stage 4: first-pass across all task types, one-shot is norm for routine work.
- Stage 1→2 lever ((opinion), citing Bitloops + Gemini CLI): context accumulation + iterative adversarial testing. For this system: (1) `/compound` captures `/cr` MUST FIX findings as learned patterns; (2) `/cr` adversarial pass with a **separate context** (currently shares context with the coding session); (3) track first-pass approval rate per task type.
- Stage 2→3 lever: spec discipline — `/feature` must produce **machine-checkable acceptance criteria**, not human-readable descriptions.

## 9. Key findings + 10 application action items ((opinion))

Eight synthesized findings (bottleneck moved to review capacity; review must happen earlier; adversarial independence matters; missing REJECT is a gap; compounding is real/measurable; PR size is a quality proxy; conflict-of-interest is real but manageable; spec discipline is the leverage point).

Ten action items aimed explicitly at "this system": (1) add REJECT to `/cr`; (2) diff-size gate on `/queue`; (3) CI-pass-before-PR in `/queue`; (4) capture MUST FIX in `.claude/learned-patterns.md` via `/compound`; (5) run `/cr` adversarial pass with fresh prompt/separate context; (6) require `/feature` for auth/schema/new-UI/cross-module; (7) track first-pass approval rate per task type; (8) machine-generated PR summary in `/queue`; (9) nightly `/queue` cap of 5 PRs <400 lines for a 2-3 person team; (10) 9-11 AM morning review ritual.

**Note for later passes:** items 4 (`learned-patterns.md`), 5 (adversarial-context), and the REJECT-tier claim all make specific assertions about OUR harness's current state. Pass 3 must check each against the ground-truth map rather than inheriting the article's description.
