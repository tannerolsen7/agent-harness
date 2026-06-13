# Grounding Pass — Skills Batch C

Read in full: `queue`, `refactor`, `review-strategy`, `setup-strategy`, `spike`, `supabase`, `supabase-postgres-best-practices`, `tdd`. Plus every embedded file each one points at (extract-module.md, the three strategy-lens agents, the full spike agent fleet, agent-contract.md, the spbp references/ tree). The danger in this batch is identical to the "golden exemplars" precedent: **most of the real wired machinery does not live in the SKILL.md prose — it lives in sibling files and spawned agents that a summary pass silently drops.** `spike` is the worst offender: its SKILL.md is a spec, but the entire pipeline is implemented in 6 separate agent files. `refactor` is the second: its SKILL.md is 32 lines of rules and a pointer; the actual procedure + plan-file system + naming gate is all in `extract-module.md`.

Audit facts that apply across the batch (verified on disk):
- **No skill in the repo sets `disable-model-invocation`** (grep returned nothing). Several skills below are side-effect skills (`queue` pushes/opens PRs, `setup-strategy` writes STRATEGY.md and edits CLAUDE.md) that should get it in V2.
- **All sub-agents are pinned `model: sonnet` except two: `spike-orchestrator` (`opus`) and `task-runner` (`opus`).** Every reasoning-heavy lens, verifier, and synthesis agent is on sonnet. This is the single biggest model-audit finding — on Opus 4.8 the adversarial/reasoning agents are the ones that most benefit from the stronger model.

---

## queue

**Actual job (plain English):** A multi-agent backlog drainer. Reads `TASKS.md`, picks non-overlapping P0/P1 tasks, spawns one isolated-worktree agent per task running the full feature loop, collects their contract summaries into a table, then (after a human gate) pushes each branch and opens a PR sequentially. The orchestrator, not the agents, owns push/PR.

**Embedded mechanisms that must carry forward:**
- **Overlap/serialization gate (Step 1, lines 17-23):** tasks that touch `supabase/migrations/`, `CLAUDE.md`, or `AGENTS.md` as their primary change MUST be serialized, never parallelized; candidates must have non-overlapping file scope. This is a real wired conflict-avoidance rule, not advice.
- **Preflight contract (Step 2, lines 34-42):** hard-checks `scripts/worktree-add.sh`, `scripts/pr.sh`, `gh`, and root `.env.local` before spawning. Stops on any miss — "a worktree without `.env.local` will fail integration tests."
- **The `.env.local` symlink setup line baked into the agent prompt template (line 62):** `ln -sf "$(git rev-parse --show-toplevel)/.env.local" .env.local` — worktrees don't inherit it; this is load-bearing and matches a known memory pitfall.
- **Agent prompt template (Step 3, lines 57-72)** that fills the agent-contract fields (GOAL/SCOPE/DECISIONS/REFERENCES/TDD/BRANCH/STOP-AND-SURFACE). Delegates to `.claude/agent-contract.md`.
- **Sentinel verification gate (Step 5, lines 105-110):** `cat .claude/.cr-ok` must equal `feat/<slug>:<HEAD sha>`; `scripts/pr.sh` validates and *consumes* the sentinel. If missing/stale → do not push, surface and stop. This is the same `.cr-ok` gate the rest of the pipeline writes.
- **Sequential-push rule (Step 5, line 101):** never parallel — "avoid concurrent pushes on shared git state."
- **Two human gates** (line 28 "which tasks?"; line 95 "push and open PRs? [y/N]").
- **`TASKS.md` write-back (Step 6, lines 132-133):** marks `[x]`, updates the Current State block.

**V2 disposition flag + why:** **KEEP — CHANGE-DELIVERY + audit invocation safety.** This is the spine of "world-class fleet" parallel operation — exactly the new charter's headline use case. But two changes: (1) it is a **side-effect skill** (spawns agents, pushes, opens PRs) — it should get `disable-model-invocation: true` so the model can't auto-fire it mid-conversation; it should only run on explicit `/queue`. (2) Its two human gates are the right *default* but under the autonomy charter it needs an **unattended mode** (pre-approved task list + auto-push on clean sentinel + zero NEEDS-HUMAN) so a cloud-scheduled run can drain a batch with no human in the loop. The agent prompt template should be re-audited so spawned task-runners run on Opus 4.8, not pinned sonnet.

**Autonomy hook:** This is the most autonomy-native skill in the batch. A cloud `/schedule` run could: read `TASKS.md`, select the pre-tagged `auto-ok` P1 tasks, spawn the worktree fleet, and for any task that returns `done` + valid sentinel + 0 NEEDS-HUMAN, push and open the PR with no human gate. Bug→PR flows feed it by appending a task row. The only thing standing between today's `queue` and full autonomy is the two `[y/N]` prompts — gate them behind an `UNATTENDED` flag.

---

## refactor

**Actual job (plain English):** Safe file-splitting. One mode (extract-module): move symbols out of a too-big file into new sibling modules, one module per commit, with tests proving behavior is unchanged at every step. The SKILL.md is a thin gate (two rules + baseline); the real engine is `extract-module.md`.

**Embedded mechanisms that must carry forward:**
- **The two hard rules (SKILL.md lines 9-16):** tests-before-movement (characterization test from outside before touching any symbol; no test → run `/tdd` first), and two-hats (structure and behavior never change in the same commit).
- **Step 0 baseline gate (SKILL.md lines 18-27):** vitest + tsc + lint + build must ALL be green before starting. "If anything is red before you start: stop. Not your problem to introduce."
- **`.claude/refactor-plan.md` — the plan-file system (extract-module.md lines 8-34).** This is the load-bearing memory mechanism: a written table of modules (single-responsibility, no "and"), symbols-to-move, a callsite map, a circular-import check result, and a `[ ]/[x]` state checklist. "This file is your memory. It survives context resets, agent handoffs, and interruptions." This is exactly the kind of wired artifact (like golden exemplars) a summary would erase.
- **The naming gate (extract-module.md lines 36-40):** each module needs a one-sentence responsibility with no conjunctions; explicitly rejected names: `utils`, `helpers`, `common`, `shared`, `misc`, `base`. "Can't name it? The split isn't cohesive yet."
- **The transitional re-export pattern (lines 65-71)** to keep callers green during the move, removed in a final caller-update pass.
- **Per-module commit template (lines 84-91)** and the clean-move verification checklist (lines 79-83: source no longer *defines* moved symbols, no new circular imports, zero logic changes in diff).
- **Logic-regression abort rule (line 77):** if verification fails on a logic regression → REVERT the extraction, stop, surface. You changed behavior during a structural move.
- **Sub-agent handoff (lines 122-126):** for 4+ modules, spawn the `refactor-extractor` sub-agent — one agent per module, **run sequentially**, each reads `.claude/refactor-plan.md` as its source of truth. Ends with `/cr`.

**V2 disposition flag + why:** **KEEP.** The plan-file + naming gate + per-module test gate is genuinely world-class discipline and not derivable from prose alone — it must survive verbatim. `refactor-extractor` is pinned `model: sonnet` (confirmed) and should be **re-audited to Opus 4.8** since semantic-preserving moves with circular-import reasoning are exactly where the stronger model earns its keep. Not a side-effect skill (commits only, ends at `/cr`, no push), so no `disable-model-invocation` needed — but it IS model-invocable, and the description's "for renaming a symbol... proceed — no skill invocation needed" carve-out is good and should stay.

**Autonomy hook:** A bug→PR or "this file is too big" cloud flow can run `/refactor` end-to-end autonomously: it self-gates on green baseline, writes its own plan file as durable memory (survives the laptop-closed cloud run), and terminates at `/cr`. The plan-file is the durability primitive that makes an unattended multi-module extraction recoverable if the run is interrupted. Only blocker: it needs `/tdd` to have produced characterization tests first — an autonomous flow must chain `/tdd` → `/refactor`.

---

## review-strategy

**Actual job (plain English):** Stress-tests `STRATEGY.md` by spawning three adversarial reviewers (PM, CTO, Challenger) **in parallel as isolated sub-agents**, then consolidates their MUST-REVISIT/CONSIDER findings. It never edits STRATEGY.md — surface only; the human decides.

**Embedded mechanisms that must carry forward:**
- **The isolation contract (SKILL.md lines 4-8, 31, 64-65):** the three lenses spawn simultaneously in a single message, each receiving **only file contents, no prior lens output.** This is the same lens-isolation thesis as the `/cr` lens composition — "a PM lens that has already read the CTO critique softens its own findings." Contamination between lenses degrades findings. This is the load-bearing mechanism, not the prose.
- **"All three lenses spawn every time — no skipping based on apparent quality" (line 66).** Hard rule.
- **Three wired lens-agent files**, each a real spawned sub-agent with its own attack-question battery:
  - `strategy-lens-pm.md` — "specific enough to act on?" (would two people agree who the user is; does out-of-scope exclude things users need before paying; is north star measurable).
  - `strategy-lens-cto.md` — "matches technical reality?" (do constraints conflict with AGENTS.md/CONTEXT.md; are 'validated' claims actually still bets; most expensive wrong assumption).
  - `strategy-lens-challenger.md` — "what assumption kills this?" (single fatal assumption treated as fact; what a competitor does this has no answer to; simpler version that wins).
- **Shared output contract across all three:** MUST REVISIT / CONSIDER / Clean, with strict semantics ("MUST REVISIT means an agent acting on this section would make wrong decisions"), grounded-in-files-only, "do not rewrite STRATEGY.md."
- **All three lens agents are `tools: Read`, `model: sonnet`, `permissionMode: plan`** (confirmed) — read-only, can't mutate.

**V2 disposition flag + why:** **KEEP — MERGE-CANDIDATE (loose).** The lens-isolation pattern here is a duplicate of the `/cr` lens-composition pattern (batches A/B). Keep the skill, but in V2 the three strategy lenses should be recognized as the same architectural primitive as the `/cr` lenses and share one lens-runner harness rather than three bespoke agent files. The bigger flag: **these are the reasoning-heavy adversarial agents most penalized by the sonnet pin** — re-audit all three `model:` fields to Opus 4.8; a strategy-killing assumption is exactly what a weaker model misses. Not a side-effect skill (surface-only, no writes), so no `disable-model-invocation` needed.

**Autonomy hook:** Strong fit for cloud `/schedule`. The skill's own description already names the trigger: "when `/scan-context` flags STRATEGY.md as stale." A scheduled monthly run (STRATEGY.md carries `review-frequency: monthly`) can fan out the three lenses and post the consolidated MUST-REVISIT report to Slack/Linear with no human until a finding lands. Because it's surface-only it's safe to run fully unattended — the human gate is reading the report, not approving an action.

---

## setup-strategy

**Actual job (plain English):** A one-time (or strategy-shifted) interview that produces `STRATEGY.md`. It first auto-detects how much context exists (Tier 1 codebase / Tier 2 public URL / Tier 3 cold interview), infers as much as it can, then asks only forced-choice gap questions, and on confirmation writes the file and wires a STRATEGY.md read into the CLAUDE.md session-start block.

**Embedded mechanisms that must carry forward:**
- **The three-tier detection ladder (lines 13-19):** CONTEXT.md present → Tier 1 (infer from codebase); else URL present → Tier 2 (web-fetch public presence); else → Tier 3 (structured interview). This is a real branching contract.
- **Tier-1 inference-first rule (lines 22-55):** read CONTEXT.md/AGENTS.md/CLAUDE.md/specs/data-model, draft STRATEGY.md from inference, then present "Gaps I couldn't infer" with forced-choice options. "infer first, ask second — don't ask what you can read."
- **The forced-choice interview battery (Tier 3, lines 70-80):** 7 ordered questions (primary user, core problem, stage, validated-vs-bet, decided constraints, north star, out-of-scope), one at a time, forced-choice where possible.
- **Two wired side-effect writes (Step 3, lines 86-92):** (1) writes `STRATEGY.md` with a `context-meta` block carrying `review-frequency: monthly` + today's `last-reviewed` date; (2) **edits `CLAUDE.md`** to add a session-start "read STRATEGY.md" instruction if absent. This second write is the cross-file wiring that's easy to drop in a summary.
- **Hard gates (lines 96-102):** never write STRATEGY.md without confirmation; never ask open-ended when forced-choice is possible; keep file < 400 words ("a grounding doc for agents, not a business plan"); push back once if an answer is too vague for an agent to act on.

**V2 disposition flag + why:** **KEEP — give `disable-model-invocation: true`.** This is a **side-effect skill** — it writes STRATEGY.md AND mutates CLAUDE.md. It should never auto-fire from the model's context mid-conversation; it must only run on explicit `/setup-strategy`. The auto-wiring of the session-start read into CLAUDE.md is genuinely good and must survive. Run-once nature is fine; the value is the inference ladder + the forced-choice discipline. No sub-agents, runs in main context, so no model: pin to audit.

**Autonomy hook:** Weakest autonomy fit in the batch — it's an interview, gated on human confirmation by design (hard rule). It does NOT belong in a bug→PR/cloud-scheduled loop. Its autonomy-adjacent value is upstream: the STRATEGY.md it produces is what `/review-strategy` (schedulable) and every agent's session-start orient step consume. Keep it human-in-the-loop.

---

## spike

**Actual job (plain English):** Answers a *decision* question before any build. The SKILL.md is a spec/output-contract; the actual work is a fully delegated agent pipeline: `/spike` spawns `@spike-orchestrator` (the only thing it does), which sharpens the question, decides 1-vs-3-pass research depth, then sequences researcher → synthesis (+ reflect) → adversarial-verifier + user-verifier (parallel) → slice (TDD test that confirms or kills the recommendation), assigns a confidence tier, assembles output, and files findings.

**Embedded mechanisms that must carry forward (this is the highest-risk section in the batch — almost none of it is in the SKILL.md prose):**
- **The full agent fleet (all confirmed on disk in `.claude/agents/`):** `spike-orchestrator` (`opus`, tools Task/Read/Write/Bash), `spike-researcher` (sonnet, WebSearch/WebFetch/Read), `spike-synthesis` (sonnet, Read/Write), `spike-adversarial-verifier` (sonnet, WebSearch/WebFetch/Read), `spike-user-verifier` (sonnet, Read), `spike-slice` (sonnet, Read/Write/Bash/Edit). The SKILL.md only names them at the bottom (lines 217, 231) — the pipeline logic is inside `spike-orchestrator.md`.
- **The one human gate (SKILL.md line 63; orchestrator Step 1):** confirm the sharpened question before *any* agent spawns. "Do not spawn any agents before confirmation is received."
- **Research-depth decision rule (single vs three passes), each pass fed the prior pass's output** (orchestrator Step 3, lines 76-85) — the same 3-pass doctrine as CLAUDE.md's research rule, wired into the spawn sequence.
- **Synthesis reflect pass — 3 structured questions** (SKILL.md lines 158-164): what I assumed the research didn't confirm / contradictions I smoothed over / what would most change this if I'm wrong. Adversarial + user verifiers run **against the post-reflect output**, not the raw dossier.
- **The TDD slice (lines 173-190):** a single test against the riskiest assumption; Pass/Fail/Blocked each routes differently (Pass → tracer bullet + filled TASK-TEMPLATE → `/feature`; Fail → drop one confidence tier + hand failing test to `/debug`; Blocked → `/prototype-interface`). One retry only (orchestrator Step 6).
- **Confidence tiers (Settled/Leaning/Open/Blocked)** with explicit next-step routing per tier.
- **Filed-findings contract (orchestrator Step 9):** writes `docs/research/[topic].md` with a **30-day-or-next-major-version expiry**; proposes a `PITFALLS.md` entry (with a fixed template) **only if an assumption failed**, presented to human before writing; adds a tracer bullet to `docs/TESTING.md` + fills `TASK-TEMPLATE.md` on pass. The orchestrator also reads prior `docs/research/[topic].md` and surfaces it if ≤30 days old ("the spike may already be answered") — a dedup gate.
- **STOP AND SURFACE conditions (orchestrator lines 203-212):** sharpened question contradicts AGENTS.md; question touches auth/RLS/billing (surface before slice runs); a prior research file conflicts; slice hits a CLAUDE.md NEVER rule; any pass significantly changes scope.

**V2 disposition flag + why:** **KEEP — re-audit the whole fleet's `model:` fields on Opus 4.8.** This is a flagship autonomy/rigor asset and must survive whole. But the model audit is acute here: **the orchestrator is `opus` while every reasoning specialist under it (synthesis, adversarial-verifier, user-verifier, slice) is `sonnet`.** Under the new "world-class is the only goal" charter, the adversarial verifier and synthesis — the agents whose job is to catch the orchestrator being wrong — are exactly the ones that should be on Opus 4.8, not the cheapest model. The researcher can stay cheaper (it's retrieval). Not a destructive side-effect skill in the dangerous sense (its writes are docs + a TDD test, and PITFALLS edits are human-gated), so `disable-model-invocation` is optional — but it DOES auto-trigger on phrases like "should we / can we use X for Y / is this viable," which is the correct behavior to keep.

**Autonomy hook:** Very strong, with one caveat. A bug→PR or "is this feasible" cloud flow can fire `/spike` and get back a cited decision + a runnable TDD slice + a filed research doc — durable across a laptop-closed cloud run because it files to `docs/research/`. The single human-confirmation gate (Step 1) is the only blocker to full autonomy; for a trusted autonomous loop it could be replaced by the orchestrator auto-accepting its own sharpened question when the input already names all three required parts (what's evaluated / decision / good-enough). The 30-day expiry + prior-research dedup gate makes it safe to schedule repeatedly without re-doing settled spikes.

---

## supabase

**Actual job (plain English):** The mandatory pre-flight skill for any Supabase work (DB/Auth/RLS/migrations/storage/Edge/supabase-js/@supabase/ssr). It's a current-docs-first discipline ("don't trust training data, fetch the changelog") plus a Supabase-specific security checklist and a migration-commit workflow. It carries no sub-agents — it's a knowledge/checklist skill loaded into the main context.

**Embedded mechanisms that must carry forward:**
- **Changelog-first rule (lines 13-16):** fetch `https://supabase.com/changelog.md`, scan for `breaking-change` tags relevant to the task, before implementing. Verify-your-work rule (line 18: run a test query after any fix). Recover-don't-loop rule (line 21: stop after 2-3 failed attempts).
- **The security checklist (lines 33-52) — the load-bearing payload.** Specific traps: never use `user_metadata`/`raw_user_meta_data` in authz (user-editable; use `app_metadata`); deleting a user doesn't invalidate tokens; JWT claims aren't fresh until refresh; never expose `service_role` in public clients (any `NEXT_PUBLIC_` ships to browser); **views bypass RLS by default → `security_invoker = true`**; **UPDATE needs a SELECT policy or it silently returns 0 rows**; don't put `security definer` functions in an exposed schema; **storage upsert needs INSERT+SELECT+UPDATE** (INSERT alone makes upsert silently fail). These map directly onto this repo's own migration rules (REVOKE-after-CREATE-FUNCTION, RLS-as-tenant-isolation).
- **Data-API exposure rule (lines 24-28):** SQL-created tables may not be auto-exposed; `anon`/`authenticated` need explicit GRANT; always enable RLS when granting public access. (Matches the repo's `0015_grants.sql` memory.)
- **CLI gotchas (lines 64-68):** discover commands via `--help` never guess; `supabase db query` needs CLI v2.79.0+ (else MCP `execute_sql`/psql); `db advisors` needs v2.81.3+ (else MCP `get_advisors`); always `supabase migration new <name>` to create a migration file — never invent the filename.
- **Schema-change workflow (lines 96-108):** use `execute_sql`/`db query` to iterate, **never `apply_migration` for local schema** (it writes a history entry every call and breaks `db diff`/`db pull`); when ready: run advisors → review checklist → `supabase db pull <name> --local --yes` → `supabase migration list --local`.
- **MCP troubleshooting ladder (lines 76-86)** and the wired feedback file: `references/skill-feedback.md` ("MUST read when the user reports this skill gave incorrect guidance"). Also a wired asset: `assets/feedback-issue-template.md`.

**V2 disposition flag + why:** **KEEP as-is (vendor skill, `metadata.author: supabase`, v0.1.2).** This is an externally-maintained skill — V2 should treat it as a pinned dependency, not rewrite it, and keep the repo's own project-specific migration rules in CLAUDE.md layered on top (they complement, don't duplicate). No sub-agents, no destructive auto-actions, so no model audit and no `disable-model-invocation` needed; its mandatory-invocation trigger (already wired in CLAUDE.md "if the task touches Supabase... MUST invoke `/supabase`") is correct and must stay.

**Autonomy hook:** Indirect but essential. Any autonomous flow that touches the DB (bug→PR fixing an RLS policy, a scheduled migration) MUST load this first — it's the safety checklist that stops an unattended agent from shipping a view that bypasses RLS or a function callable by PUBLIC. In a cloud run it's a context-injected guardrail, not an actor. Its changelog-fetch step also keeps a scheduled agent from acting on stale training data.

---

## supabase-postgres-best-practices

**Actual job (plain English):** A Postgres performance reference library. The SKILL.md is just an index (8 priority categories, prefix scheme); the actual content is ~34 individual rule files in `references/`, each with incorrect-vs-correct SQL, EXPLAIN output, and metrics. You read individual rule files on demand when writing/reviewing/optimizing SQL.

**Embedded mechanisms that must carry forward:**
- **The `references/` rule-file tree (confirmed, 34 files).** This is the entire payload — `query-missing-indexes.md`, `query-partial-indexes.md`, `conn-pooling.md`, `security-rls-performance.md`, `schema-foreign-key-indexes.md`, `lock-skip-locked.md`, `data-n-plus-one.md`, etc. The SKILL.md prose is worthless without these files; a summary that keeps the index and drops the references keeps nothing.
- **`references/_sections.md`** (confirmed present) — the section map; plus `_template.md` and `_contributing.md` (the rule-authoring contract).
- **The priority/prefix taxonomy (SKILL.md lines 28-38):** `query-` (CRITICAL) → `conn-` → `security-` → `schema-` → `lock-` → `data-` → `monitor-` → `advanced-`, impact-ordered. This is how an agent decides which rule to pull first.
- **Per-rule structure contract (lines 50-56):** why-it-matters + incorrect SQL + correct SQL + EXPLAIN/metrics + Supabase-specific notes.

**V2 disposition flag + why:** **KEEP as-is (vendor skill, `author: Supabase`, v1.1.1, dated Jan 2026).** Note: this skill is **duplicated** — it appears both as a project skill and (per the available-skills list) as a top-level/plugin skill, and `supabase-postgres-best-practices` shows up twice in the skill roster. **MERGE-CANDIDATE for de-duplication only** — pick one source (the plugin/marketplace copy is the better canon under the "distribution = plugin+marketplace" resolved fact) and drop the in-repo duplicate to avoid drift. No sub-agents, pure reference, no side effects → no model audit, no `disable-model-invocation`.

**Autonomy hook:** Reference-only; loaded as context by any autonomous DB or perf flow (`/perf`, a scheduled query-plan audit, a bug→PR fixing an N+1). It never acts — it's the knowledge an unattended agent consults before writing an index migration or a paginated query. A scheduled `/perf` cloud agent is its natural autonomous consumer.

---

## tdd

**Actual job (plain English):** The Canon-TDD implementation loop: specify → encode (one failing test) → fulfill (minimum code to green), one behavior = one test = one implementation = one commit, never batched. It's the engine that other skills (`/refactor`, `/spike` slice, `/feature`) chain into to produce characterization/behavior tests.

**Embedded mechanisms that must carry forward:**
- **The named three-move loop (lines 14-21):** Specify → Encode → Fulfill. "Hold to this named loop."
- **The no-transcription rule (Step 0, lines 36-40):** expected behavior comes from `docs/TESTING.md` or the user, **never from reading the implementation** — "reading the code to derive expected values produces tests that pass even when behavior is wrong." This is the single most load-bearing rule.
- **`docs/TESTING.md` as the behavior ledger** — wired at both ends: Step 1 (lines 44-49) requires the behavior be confirmed in TESTING.md before any test (stop and ask if absent); Step 6 (lines 113-118) writes back after each green slice (add to "What's tested today," remove from "Known test gaps," move "Code-observed" → "Confirmed behaviors").
- **Anti-rationalization table (lines 26-32):** four named rationalizations + rebuttals ("there is no after," "simple functions break in simple ways").
- **Vertical-slice decomposition (Step 3, lines 68-81)** with a concrete too-large-vs-right-size table.
- **The strict per-slice loop (Step 4, lines 88-99):** write expected-behavior comment → write ONE failing test → run, confirm it fails *for the right reason* → minimum code → confirm green → refactor only if needed → **commit test+impl together as one atomic commit** → next. "Do not write the next test until the previous slice is committed."
- **Codebase-specific test patterns (Step 5, lines 105-109):** never mock the DB (integration tests hit real Supabase); seed via `supabaseAdmin` in `beforeAll`; the only accepted spy is `vi.spyOn(supabaseAdmin.auth, 'getUser')` for auth-error paths; pure functions need no infra; consult `docs/TESTING.md` → Mock infrastructure before inventing patterns.

**V2 disposition flag + why:** **KEEP — foundational.** This is a chained-into primitive (`/refactor` requires it before movement; `/spike` slice and `/dev` use it; CLAUDE.md mandates it for all new pure functions). The `docs/TESTING.md`-as-spec-ledger wiring is the golden-exemplars-class mechanism here — it's the external source of truth that prevents transcription tests, and a summary that drops "reads/writes TESTING.md" guts the skill. Runs in main context, no sub-agents, no side effects beyond commits → no model audit, no `disable-model-invocation`. Note it's also duplicated in the skill roster (project + plugin `tdd`) — de-dup like the supabase skills.

**Autonomy hook:** Core autonomy primitive. A bug→PR flow runs `/tdd` to write the failing test that reproduces the bug *before* fixing it (red proves the repro), then fulfills to green — the test is the autonomous proof the fix works. `/refactor` and `/spike` chain it for characterization tests in unattended runs. The TESTING.md ledger gives a cloud-scheduled run durable cross-session memory of what's confirmed vs. a gap, so a laptop-closed run doesn't re-test or write transcription tests.

---

## CARRY-FORWARD ALERTS

The embedded, wired mechanisms in THIS batch most at risk of being summarized away (golden-exemplars precedent):

1. **The entire `/spike` agent fleet (6 agents) lives outside the SKILL.md.** `spike-orchestrator.md` holds the real pipeline (depth decision, pass-feeds-prior, reflect-then-verify ordering, slice routing, 30-day expiry, dedup gate, STOP-AND-SURFACE list). The SKILL.md is a spec; summarizing only the SKILL.md drops the whole machine.

2. **`refactor`'s `.claude/refactor-plan.md` plan-file system + the no-conjunction naming gate** (in `extract-module.md`, not SKILL.md). Self-described as "your memory... survives context resets." Direct golden-exemplars analogue.

3. **`tdd`'s `docs/TESTING.md`-as-behavior-ledger wiring** (read in Step 1 as the spec source, written back in Step 6) + the no-transcription rule. The skill is gutted if "reads/writes TESTING.md" is dropped.

4. **`review-strategy`'s three wired lens-agent files** (`strategy-lens-pm/cto/challenger.md`) and the **isolation contract** (parallel spawn, no cross-lens contamination). The SKILL.md names the lenses but the attack-question batteries and the isolation thesis are the load-bearing parts.

5. **`queue`'s sentinel gate (`.cr-ok` = `branch:sha`, consumed by `scripts/pr.sh`), the migration/CLAUDE.md/AGENTS.md serialization rule, and the `.env.local` symlink line** baked into its agent prompt template.

6. **`setup-strategy`'s cross-file write — it edits CLAUDE.md** to wire the session-start STRATEGY.md read. Easy to miss because it's a one-line side effect buried in Step 3.

7. **`supabase` security checklist + schema-change workflow** (views-bypass-RLS, UPDATE-needs-SELECT-policy, storage-upsert-needs-3-grants, never-`apply_migration`-for-local) and its wired `references/skill-feedback.md` + `assets/feedback-issue-template.md`.

8. **`supabase-postgres-best-practices` is nothing but its `references/` tree (34 rule files + `_sections.md`/`_template.md`).** The SKILL.md index alone carries zero substance.

**Cross-batch model + invocation flags (re-audit on Opus 4.8 / new charter):**
- **No skill repo-wide sets `disable-model-invocation`.** Add it to the two side-effect skills in this batch: **`queue`** (spawns agents, pushes, opens PRs) and **`setup-strategy`** (writes STRATEGY.md + mutates CLAUDE.md).
- **Every reasoning-heavy sub-agent is pinned `model: sonnet`; only `spike-orchestrator` and `task-runner` are `opus`.** Re-audit to Opus 4.8 specifically: the three **strategy lenses**, **`spike-adversarial-verifier`**, **`spike-synthesis`**, **`spike-user-verifier`**, and **`refactor-extractor`** — these are the catch-the-error agents the new "world-class only" bar should not run on the cheapest model.
- **Duplicate skills** (`supabase-postgres-best-practices`, `tdd` appear as both project and plugin/top-level): de-dup to the plugin/marketplace canon per the resolved distribution fact.
