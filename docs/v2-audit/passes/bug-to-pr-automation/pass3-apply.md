# Pass 3 — Apply: the article against OUR harness (ground-truth map)

Building on pass2: this pass lands the pass-2 conclusions on `CANONICAL-HARNESS-AS-IS.md`. Every gap
cites a ground-truth section (`§N`) or a confirmed absence. No gap without a citation.

The governing translation: pass2-A/B established the real architecture is **a deterministic state
machine with one stochastic transition, gated front (trigger + context prefetch + tool curation) and
back (review contract + risk classification)**. Our harness *is already that shell* for the
feature/fix pipeline — it just has no **trigger front-door** and an **advisory rather than structural**
back gate. That framing decides what's a real gap vs. noise below.

---

## (a) What we ALREADY do — and the article would tell us to keep

- **The deterministic back-gate already exists.** Pass2-B says the LLM must be sandwiched in
  deterministic code. We have it: pre-commit (ESLint + `tsc --noEmit` + vitest), pre-push (full
  integration tests + `next build` + `.cr-ok` sentinel validation), and CI (`ci.yml` + `integration.yml`)
  [ground-truth §3e, §3f]. The article's "interleave LLM steps with hardcoded deterministic gates"
  (pass1 §11) is our existing pipeline, not a gap.
- **Retry/runaway discipline is partially native.** Pass1 §11's "hard cap 2 retries / token budgets"
  maps onto our `block-npm-install.sh`, `block-dangerous-git.sh`, and the autoMode/UNATTENDED settings
  hardened in PR #99/#100 [§3e]. We already constrain unattended runs.
- **Tool-misuse-cascade defense partly present.** Pass1 §11 "task-scoped tool restrictions (~15 tools
  not 500), circuit breakers on MCP" — our `.claude/mcp.md` allowlist discipline and the
  `permission-logger.sh` [§3e disk-only] are the seed of this; background agents already run on a
  committed `permissions.allow` list (memory: background-agent Bash permissions).
- **The PR-quality context file the article's Action Item #5 demands already exists.** "Write an
  AGENTS.md — improves agent PR quality measurably" (pass1 §12) — we have `AGENTS.md` **and** `CLAUDE.md`
  **and** `CONTEXT.md` (15 KB, PR #92) [§3a]. The single most-emphasized action item is already done;
  the article would mark this complete for us.
- **The review contract exists as a 9-pass `/cr` + adversarial review** [§3c], which is *more* review
  rigor than any tool in the article applies. Pass2-C said agents trade writing-time for reviewing-time;
  our `/cr` is exactly the structured reviewer the article says is "still being standardized."
- **Isolated sandbox = worktrees.** Pass1 §2's "isolated devbox, no prod access" maps to our
  `worktree-create.sh` + Tier-0 prod-key firewall (`gen-local-env.sh`, `test-local.sh`) [§6 disk-only] —
  a genuine disk *advance* the canon lacks. We already have the article's #1 safety primitive.
- **Minimal-diff + no-refactor-while-fixing is already doctrine.** Pass1 §6 / §11 scope-creep defense =
  our "Two hats: structure and behavior never change in the same commit" refactor rule (CLAUDE.md). The
  article's "make the minimum change, do not refactor anything you don't need to touch" is already a
  standing rule.
- **Destructive-keyword denylist already exists and is stronger than Ona's.** Pass1 §2 Ona's high-risk
  keywords (`payment`, `db/migrate`, `destroy_all`) ≈ our destructive-operation rules + the
  `block-dangerous-git.sh` guard [§3e]. Our PocketOS-incident rules are the keep-verbatim safety floor
  [§9].

## (b) REAL gaps it exposes (each cites a ground-truth row or confirmed absence)

1. **No trigger front-door exists at all.** Pass2-F: the entire pipeline presupposes an error
   monitor / issue tracker / CI-failure surface that summons the agent. Our harness has **no
   error-monitor integration, no issue-tracker webhook, no CI-failure→agent trigger** — the only
   "triggers" on disk are `SessionStart`/`WorktreeCreate`/`post-checkout` hooks [§3e], which fire on
   *human* actions, never on a *bug signal*. Confirmed absence: nothing in §3e–§3f ingests a Sentry
   event, a GitHub issue label, or a CI failure. Our `/queue` and `/feature` are human-invoked. **This
   is the single largest gap the article exposes** — our agents are fully build-capable but have no
   autonomous front door.
2. **The back-gate is advisory, not structural, for the review *contract* itself.** Ground-truth §3e
   states outright: "**Both agree the system is overwhelmingly advisory** — neither has a deterministic
   backstop for the bulk of skill bodies, CLAUDE.md rules, or the autoMode lists." Pass2-D/H: the
   trustworthy gate must be *structural* (blast radius, test-count floor, keyword denylist), not
   model-confidence. We have `/cr` (a strong reviewer) but **no deterministic "test count never
   decreased" check** and **no automated blast-radius/risk classification** in the pipeline. Citation:
   §3e (advisory floor) + confirmed absence of any test-count-floor or risk-classifier script in §3f's
   script list (`pr.sh, worktree-add.sh, gc.sh, gen-local-env.sh, test-local.sh, seed.ts`).
3. **`.cr-ok` is exactly the capability-gate the canon already flagged for downgrade — and Ona shows
   the better design.** §9 Model Capacity Audit explicitly lists "**The `.cr-ok` sentinel as a
   capability gate → document as a readiness signal, not a capability unlock.**" Pass2-E/H: Ona's
   static→semantic→agentic auto-approval with public-channel observability is the structural
   replacement. The gap: `.cr-ok` is a binary present/absent token [§3f], with **no risk tiering and no
   observability trail** — the §8(c) hole ("CI never verifies `.cr-ok`", gitignored, never reaches CI)
   means it's not even enforced server-side. Article exposes both the design weakness (§9 row) and a
   concrete better pattern.
4. **`block-dangerous-bash.sh` absence is the missing safety-floor for autonomous runs.** Pass1 §11's
   defenses against runaway/cascade assume a bash safety guard. Ground-truth §3e + §5 confirm the
   canon's **3rd structural guard `block-dangerous-bash.sh` (deploys, `rm -rf`, writes to
   `.git`/`.husky`/`.claude`) is ABSENT on disk.** If we ever wire any autonomous trigger (gap #1), this
   guard becomes load-bearing — the article's "tool-misuse cascade" failure mode lands directly here.
5. **No `session-end.sh` memory-capture means agent runs don't compound.** Pass1 §2 Cursor's "memory
   tool — learn from past runs" and pass2-G. Ground-truth §3e + §5: canon's `session-end.sh` (Stop →
   memory candidates) is **absent; disk memory is fully manual.** An autonomous bug-fix loop that can't
   write back what it learned is the un-compounding version the article implicitly warns against.
6. **No "agent PR" observability log.** Pass1 §12 Action Item #4 ("Slack channel as the agent PR log")
   and pass2-E (public-channel observability as the automation backstop). Confirmed absence: no
   notification/log sink in §3e–§3f; `permission-logger.sh` exists [§6] but logs permission calls, not
   PR outcomes. If we move toward any auto-approval (#2/#3), this is the prerequisite observability and
   we don't have it.

## (c) Weaknesses in the article's OWN reasoning (carry these as caveats, don't inherit)

1. **"Writing is solved" is refuted by the article's own yield numbers** (pass2-C): 13.86% Devin / 5%
   Forge / 35% BugBot. For *our* single-vendor, pre-revenue codebase the relevant rate is the
   *unselected* one, which the article never reports — so its optimism over-projects to our context.
2. **The "confidence score" gate is internally contradictory** (pass2-D): it tells us to gate on a
   number whose own "hallucinated root cause" failure mode says is uncorrelated with correctness. We
   should adopt the *structural* proxies (blast radius, keyword denylist, P-level) and ignore the
   self-graded confidence number.
3. **Buyer's-guide framing assumes a substrate we don't have** (pass2-F): Sentry+Linear+GitHub-Issues
   as a given. We are on GitHub but have no error monitor and (per ground-truth) no issue-tracker
   integration — so 5 of the article's 8 action items are blocked on infrastructure decisions the
   article treats as free. Its "$500–800/mo, less than one engineer" math assumes a 5-engineer team;
   our economics (solo + parallel-agent batches, memory: harness-first cadence) are different and it
   never models them.
4. **"Never auto-merge" stated as law while Ona auto-approves** (pass2-H) — the article never names the
   auto-approve≠auto-merge distinction that is the entire safety model. We must encode the real rule:
   "the agent is never the *last* deterministic gate before main," which our pre-push + CI already
   satisfy.
5. **Silent on escaped-defect cost × volume** (pass2-I) — the unpriced risk of a merged wrong fix. For a
   $30k-client proposal tool this asymmetry is the whole game; the article's generation-cost focus is
   the wrong ledger for us.

## (d) Does it warrant fresh external research? — Disciplined answer: **mostly no; one narrow yes.**

- **No** on the architecture, triggers, failure modes, and review contract. This article is itself a
  broad, well-sourced synthesis (15+ named sources). Pass1/2 already extract the transferable core
  (deterministic shell, structural gate, Ona's cost-ordered risk pipeline, failure-mode table). Re-
  researching would duplicate it. Synthesize into the V2 build plan instead — specifically against §5
  (build `block-dangerous-bash.sh`, `session-end.sh`) and §9 (downgrade `.cr-ok` to a readiness signal
  with a risk-tiered, observable replacement). These map to existing ground-truth rows; no new facts
  needed to act.
- **One narrow YES, only if V2 decides to build gap #1 (a trigger front-door).** *If* we choose to wire
  an autonomous trigger, a focused spike is warranted on exactly two questions the article answers only
  at enterprise scale: (i) what is the **minimum viable trigger surface for a solo/duo repo with no
  error monitor** — is GitHub-Issues-label (`fix-me`, OpenHands-style, pass1 §3.4) the zero-infra
  entry, and does it fit our existing worktree+`/cr` shell without new services; (ii) the **test-count
  floor + blast-radius classifier** as a concrete pre-push check (gap #2/#3) — is there a lightweight
  deterministic implementation, since the article describes Ona's but gives no code. Both are
  *implementation* spikes tied to a build decision, not open-ended research. Gate per memory
  "hypothesis-before-speculative-build": do **not** spike until V2 has decided a trigger front-door is
  in scope — building the classifier before deciding we want autonomous triggers is the speculative
  build the harness rules forbid.

---

### Bottom line for V2

The article confirms our **shell is right** (isolated worktrees, deterministic pre-commit/pre-push/CI,
strong `/cr` reviewer, AGENTS/CONTEXT context files all present — §3a, §3e, §3f, §6) and isolates two
ground-truth-cited gaps worth carrying forward: **(1) we have no autonomous trigger front-door**
[confirmed absence, §3e] and **(2) our review/readiness gate is advisory, not structural, and `.cr-ok`
is already flagged for downgrade** [§3e advisory floor + §9 explicit row]. The article's Ona
auto-approval pattern is the most directly reusable design for fixing (2). Everything else it
recommends is either already built (§3a/§6) or blocked on an infrastructure-scope decision the article
never surfaces (pass2-F).
