# Grounding Pass — Agents Batch A

Source-of-truth read of eight agent bodies in `.claude/agents/`. Read in full, not summarized.
Goal: catch every embedded, load-bearing mechanism so none is dropped in V2.

All eight files present and non-empty.

---

## doc-updater

**Actual job (plain English):** Runs `/compound` after a task ships. Reads the task diff plus the four compound-question answers and produces a *draft* file proposing new entries for `docs/solutions/`, `PITFALLS.md`, `memory.md`, and `SOUL.md`. It never writes the real files — the draft is the deliverable, a human merges it at PR-review time.

**Embedded mechanisms that must carry forward:**
- **Enablement gate (file existence check):** checks for `.claude/agentic-system-enabled` (line 19-21). If absent, it prints "Agentic system not enabled…" and stops. This is a wired feature-flag-by-file pattern.
- **Read-set contract (lines 23-30):** must read the four compound answers Q1–Q4 from `@reviewer`, `git diff main..HEAD`, `docs/solutions/README.md`, `docs/solutions/TEMPLATE.md`, `PITFALLS.md`, `.claude/memory.md`, `.claude/SOUL.md`. The Q1–Q4 hand-off from `@reviewer` is a concrete inter-agent protocol.
- **Four proposal categories with explicit thresholds (lines 32-53):** solutions/ (non-obvious decision from Q1, alternatives from Q2), PITFALLS (Q3 least-confident reveals a recurring trap), memory.md (mistake corrected, from Q4/reviewer), SOUL.md ("High bar… most sessions produce zero").
- **Template-filling contract:** solutions/ entry must be in `TEMPLATE.md` format; PITFALLS in "section heading + paragraph + symptom + fix" format.
- **Output gate (lines 57-81):** writes `.claude/compound-draft-[task-slug].md` with a fixed four-section skeleton, then returns a "Draft written" block. Hard rule: nothing is written to actual files.
- **Frontmatter:** `model: sonnet`, `permissionMode: plan`, `tools: Read,Edit,Glob,Grep,Bash`.

**V2 disposition flag + why:** **KEEP (CHANGE-DELIVERY).** The compound/learning loop is core to a self-improving fleet, and a draft-then-human-merge gate is exactly the right safety boundary for a side-effect that mutates canon docs. CHANGE-DELIVERY: the `.claude/agentic-system-enabled` file-flag is a V1 enablement hack — under the plugin+marketplace distribution model this becomes "skill is installed" rather than a sentinel file. Re-audit `model: sonnet` → for synthesis quality on Opus 4.8 this is a candidate to bump; drafting canon entries is a reasoning task, not a mechanical one. This is also a **side-effect-adjacent skill** — but it already self-limits to writing a draft, so `disable-model-invocation` is less urgent here than for true mutators; still worth flagging so the model doesn't auto-fire `/compound` mid-task.

**Autonomy hook:** Strong. In a bug→PR flow this runs as the final stage after the reviewer, producing the compound draft as part of the PR so the learning loop closes without a human prompt. Cloud-scheduled: a nightly "harvest learnings from today's merged PRs" routine could invoke it across the day's diffs. The draft-not-write boundary keeps it safe to run unattended.

---

## explorer

**Actual job (plain English):** Read-only codebase search specialist. Given a specific question and a breadth level (quick / medium / thorough), it greps/globs/reads and returns structured findings with file:line evidence. Never edits.

**Embedded mechanisms that must carry forward:**
- **Breadth-level contract (lines 17-23):** three named tiers — quick (top 5, stop when answered), medium (exhaustive within named scope), thorough (cross-cutting all layers, trace imports, map dependency graph). The caller passes the level; behavior is governed by it.
- **Search strategy (lines 25-30):** symbol-name grep first → file-pattern glob → read most-relevant in full → follow imports one level deep at layer boundaries → stop when answered ("do not over-search").
- **Fixed output schema (lines 32-46):** Question / Findings (file:line + why relevant) / Answer (2–5 sentences) / Gaps. The Gaps section is a load-bearing honesty mechanism — it forces declaring what wasn't searched.
- **Frontmatter:** `model: sonnet`, `permissionMode: plan`, read-only tools (`Read,Grep,Glob,Bash`).

**V2 disposition flag + why:** **KEEP.** A read-only, structured-output search sub-agent is a clean context-isolation primitive — it keeps a large search off the main agent's context window and returns only the distilled findings + Gaps. The breadth-level dial is a genuinely good design and should survive verbatim. Re-audit `model: sonnet`: for thorough cross-layer dependency mapping, Opus 4.8 reasoning may be worth it, but quick/medium searches are mechanical — consider keeping sonnet as default and letting the caller request a stronger model for thorough. Not a side-effect skill (read-only), so no `disable-model-invocation` concern.

**Autonomy hook:** Strong and foundational. Any autonomous bug→PR flow needs a search primitive to map the blast radius before touching code; `explorer` is that primitive. The investigator and incident-responder both effectively do exploration inline — explorer is the reusable, isolated version. Cloud-scheduled flows that audit the codebase ("find all data functions missing cache()") would lean on it.

---

## hotfix-guard

**Actual job (plain English):** A binary merge-gate enforcer for hotfix branches, spawned by `/hotfix` before merge. Checks exactly three gates — required TASKS.md entries exist for the declared mode, a *new* failing test targeting the root cause was added, and the diff stays inside the declared scope — and returns PASS/FAIL. Fixes nothing, suggests nothing.

**Embedded mechanisms that must carry forward:**
- **Mode-driven TASKS.md entry gate (Gate 1, lines 26-46):** reads `.claude/hotfix-scope-[slug].md` to get MODE. full-fix requires a `[hotfix-postmortem]` entry; mitigation-only requires both `[hotfix-correction]` and `[hotfix-postmortem]` entries, each with `[~]` or `[ ]` status. This couples the guard to the `/hotfix` skill's TASKS.md bookkeeping convention — a wired cross-artifact contract.
- **New-test gate (Gate 2, lines 48-62):** `git diff main...HEAD -- '*.test.*' '*.spec.*'`, requires at least one *new* `+` test block — explicitly not a modification of an existing test. Does not judge quality, only existence.
- **Scope-not-exceeded gate (Gate 3, lines 64-81):** parses the allowed-files list out of `.claude/hotfix-scope-[slug].md`, diffs `git diff main...HEAD --name-only`, flags any file outside the list. Test files from Gate 2 are implicitly in-scope.
- **The scope file itself (`.claude/hotfix-scope-[slug].md`) is the load-bearing artifact** — it carries MODE and the allowed-file list that two of three gates read.
- **Binary output contract (lines 83-104):** fixed report block, all-three-must-pass, "No partial passes," no advisory findings.
- **Frontmatter:** `model: sonnet`, `permissionMode: plan`, **legacy tool names** `read_file,list_files,bash` (snake_case — older schema than the camelCase `Read,Grep` used elsewhere; needs normalization in V2).

**V2 disposition flag + why:** **KEEP (CHANGE-DELIVERY).** A deterministic merge gate is exactly what an autonomous hotfix flow needs to be trustworthy. CHANGE-DELIVERY for two reasons: (1) the `read_file,list_files,bash` tool names are legacy and must be normalized to current schema; (2) every gate is mechanical string/diff comparison — `model: sonnet` is arguably over-powered, and a deterministic gate ideally shouldn't depend on model judgment at all. Worth re-auditing whether parts of this should be a hook/script rather than an agent. Not a mutator (read-only), so no `disable-model-invocation` concern — but its determinism is its value, so resist any V2 change that makes it "smarter."

**Autonomy hook:** Strong. This is precisely the gate that lets a bug→PR autonomous hotfix merge without a human eyeballing it — the three gates encode the human's pre-merge checklist. In a cloud-scheduled incident-response flow, it is the last automated checkpoint before the PR is marked mergeable.

---

## implementer

**Actual job (plain English):** Implements exactly one TDD slice per invocation — one behavior, one test, one implementation, one commit. Runs the strict red-green loop (test must fail first), runs the full suite + tsc, and commits only when green. Never batches, never commits a failing test.

**Embedded mechanisms that must carry forward:**
- **GOLDEN EXEMPLARS — the canonical example the carry-forward warning is about (lines 17-24):** before writing code it must read `.claude/SOUL.md`, every PITFALLS.md section heading (and any matching section in full), and **"AGENTS.md — Architecture section. Read the golden exemplars for every layer you will touch. Do not write a new file in a layer without reading the canonical example first,"** plus the specific TESTING.md entry. The golden-exemplars read is load-bearing and explicitly enforced here — this is the mechanism the prompt flagged as the clearest example of a thing summarized away. **MUST carry forward.**
- **Red-green loop with transcription guard (lines 26-48):** (1) write test, run `npx vitest run <file>`, must fail — **if it passes before implementation, stop and write a BLOCKING question in `.claude/questions.md`** (the "test is a transcription" guard). (2) minimum implementation. (3) full suite `npm run test` — if a prior test breaks and can't be fixed in 2 attempts, stop + BLOCKING question. (4) `npx tsc --noEmit`, zero new errors. (5) commit, message format `[slice-slug]: behavior description`.
- **`.claude/questions.md` BLOCKING hand-off protocol** — the universal "I'm stuck, human decide" channel, written rather than fixed.
- **Hard rules (lines 50-59):** one behavior per invocation; never commit failing test or type errors; no `any`; no `@ts-ignore`; no `console.log` outside tests; touch only files this slice requires.
- **Structured output with Observations hand-off (lines 62-73):** "Slice complete" block (behavior / test file:line / impl files / commit sha) plus an **Observations** section addressed to `@reviewer` or `@task-runner` — explicit downstream hand-off.
- **Frontmatter:** `model: sonnet`, `permissionMode: default` (it writes and commits — the only one in this batch with default permission mode and commit authority).

**V2 disposition flag + why:** **KEEP.** This is a core autonomy workhorse — the agent that actually writes code under TDD discipline. The golden-exemplars read and the transcription guard are both must-keep mechanisms. Re-audit `model: sonnet`: under Opus 4.8 this is the strongest candidate in the batch to upgrade — implementation quality directly determines PR quality in a bug→PR flow, and Opus reasoning reduces the BLOCKING/retry rate. It is a **mutator with commit authority** running at `permissionMode: default`; in V2 verify its allowed Bash patterns are pre-committed if it's ever spawned in a background/cloud flow (per the project's background-agent rule). Not a "skill" so `disable-model-invocation` doesn't apply, but its commit authority is the highest-stakes in this batch.

**Autonomy hook:** Central. In bug→PR: investigator produces the failing test + task spec → implementer consumes the spec, makes it green, commits → reviewer/lens agents gate it. It is the build stage of the autonomous loop. Cloud-scheduled: a routine that picks a `[~]` TASKS.md slice off the queue and ships it overnight is exactly this agent's job. The one-slice-per-invocation discipline is what makes unattended runs safe and reviewable.

---

## incident-responder

**Actual job (plain English):** Classifies a production/staging incident through structured evidence-gathering *before any fix*, spawned by `/incident`. Attempts reproduction, runs six evidence checks, assigns an incident type with a confidence level, proposes a route, and writes a triage document. Never fixes, never mutates state (except the triage doc), never sends user comms.

**Embedded mechanisms that must carry forward:**
- **Reproduction-first gate (Phase 0, lines 42-62):** two attempts; on failure writes triage with `Reproduction: FAILED` and stops; intermittent → record N-of-M pattern, flag category, proceed at Confidence: Low. "Never classify without first attempting reproduction."
- **Six fixed evidence checks (Phase 1, lines 63-130)** — each with concrete commands: (1) behavior-vs-spec (`cat docs/TESTING.md`, `cat CONTEXT.md`); (2) recent changes (`git log --since=7 days` on files + package.json); (3) dependency health (web_search the dep's issues/changelog, status page); (4) data state (produce read-only query, **do not execute unless `incident-db-query-enabled: true` in settings.json** — a wired settings flag); (5) **security signals** — auth bypass / RLS changes / cross-tenant access; **if any signal: write `SECURITY SIGNAL DETECTED`, propose isolation only, stop all other work**; (6) `cat PITFALLS.md` — match → classify at Confidence: High (PITFALLS match).
- **Classification table (Phase 2, lines 131-154):** eight incident types each mapped to primary evidence; three confidence levels (High / Low / Split, with "pick the safer route" rule for Split).
- **Triage document gate (Phase 3, lines 155-160):** writes `.claude/incident-[slug].md`; **"Do not surface results to the human before this file is written"**; format defers to `skills/incident/SKILL.md` Phase 3 — a cross-artifact format dependency.
- **Proposed-routes-by-type table (lines 162-173):** each type → specific downstream skill (`/migrate`, `/evaluate-solution`, `/debug`→`/hotfix`, `/feature`) + immediate action. This is the routing brain that hands off to other skills.
- **STOP AND SURFACE conditions (lines 193-199):** repro fails, security signal, contradictory evidence across 3+ checks, symptom touches auth/RLS/payment, classification would require mutating data.
- **Frontmatter:** `model: sonnet`, `permissionMode: plan`, `tools: read_file,list_files,bash,web_search` (**legacy snake_case tool names again** — normalize in V2).

**V2 disposition flag + why:** **KEEP (CHANGE-DELIVERY).** Incident triage that gathers evidence before touching anything is exactly the safety posture an autonomous fleet needs at the front door of production problems. CHANGE-DELIVERY: legacy tool names need normalization; the `incident-db-query-enabled` settings flag and the `skills/incident/SKILL.md` Phase-3 format dependency must be re-wired under the new distribution model. Re-audit `model: sonnet`: classification under ambiguity (Split confidence, contradictory evidence) is real reasoning — strong Opus 4.8 upgrade candidate. The security-signal short-circuit and "propose isolation only, never fix security" rule are non-negotiable and must survive verbatim. Read-only (except triage doc), so no `disable-model-invocation` concern.

**Autonomy hook:** Very strong and exactly on-charter. This is the agent a Slack/Linear "something's broken in prod" trigger should summon: it auto-reproduces, gathers evidence, classifies, and routes — handing off to `/debug`→`/hotfix`→implementer→hotfix-guard for the autonomous fix-and-PR loop. Cloud-scheduled: could be wired to an alerting webhook (PagerDuty/Sentry) to triage incidents before a human is even awake. The "draft comms, human sends" and "isolation-only for security" boundaries keep unattended operation safe.

---

## investigator

**Actual job (plain English):** Investigates a bug that crosses a layer boundary or spans 3+ files, spawned by `/debug`. Finds and confirms the root cause, writes a *failing* test that proves it, and fills a `TASK-TEMPLATE.md` ready for `/feature (Tiny)`. Read-heavy, write-limited (only the failing test + task spec). Never fixes.

**Embedded mechanisms that must carry forward:**
- **Pre-read contract (lines 16-21):** `.claude/SOUL.md`, every `PITFALLS.md` heading (matching sections in full), and `memory.md` entries for the area. Same orient-on-canon discipline as implementer.
- **Three-artifact contract (lines 23-34):** produces (1) confirmed root cause as file:line + one paragraph, (2) a failing test written/run/confirmed-red, (3) a filled `TASK-TEMPLATE.md` for `/feature (Tiny)`. **Explicitly does not produce a fix** — if it knows the fix, it goes in the **PRE-GRILL** section of the task spec and stops (lines 32-34, 115).
- **Investigation loop (lines 36-66):** Orient (search PITFALLS/memory/solutions, surface footgun immediately) → Reproduce (hypothesis, smallest path, 2 attempts then BLOCKING) → Bisect (trace value source→symptom, follow imports one level at layer boundaries) → Confirm ("partial explanations are not root causes") → Write failing test (must fail first; "a passing test against a broken system is a false negative — worse than no test") → Fill task spec.
- **BLOCKING hand-off protocol (lines 67-88):** seven STOP conditions (ambiguous between two locations, touches auth/RLS/data boundary, requires migration, symptom outside search scope, a CLAUDE.md NEVER rule would be violated by the fix, systemic/multiple root causes). BLOCKING block has a fixed shape including "Can do while waiting."
- **Output schema (lines 90-115):** Reproduction / Root cause / Failing test / **PITFALLS.md (New entry warranted | Existing §N matched | None)** / Task spec / Gaps. The PITFALLS.md disposition line is a wired learning-loop touchpoint.
- **Frontmatter:** `model: sonnet`, `permissionMode: default` (writes test + spec), `tools: Read,Grep,Glob,Bash,Edit`.

**V2 disposition flag + why:** **KEEP.** The investigator→implementer pipeline (root cause + failing test in → green implementation out) is the spine of an autonomous bug→PR flow, and handing off a failing test rather than a fix is the right separation of concerns. Re-audit `model: sonnet`: root-cause bisection across layers is genuinely hard reasoning — strong Opus 4.8 upgrade candidate, on par with implementer. The PRE-GRILL "know the fix but don't apply it" discipline and the seven BLOCKING conditions (especially auth/RLS/migration → stop) are must-keep guardrails. Possible **MERGE-CANDIDATE** consideration in V2: investigator and incident-responder overlap on reproduce-and-classify, but they serve different entry points (bug vs. production incident) and have different write authority — keep separate unless V2 consolidates the debug/incident skills.

**Autonomy hook:** Central to bug→PR. A Linear/Slack bug report triggers `/debug` → investigator confirms root cause + writes the red test + fills the task spec → implementer makes it green → reviewer + lens agents gate → PR. It is the "understand the bug" stage. Its failing-test output is the hand-off contract that makes the downstream implementation verifiable and the whole loop trustworthy unattended.

---

## lens-abuse

**Actual job (plain English):** A single-lens adversarial reviewer spawned by `@reviewer` in parallel with three other lens agents. Attacks exactly one failure class: "what happens when a caller uses this interface incorrectly but plausibly?" — the tired-engineer-at-11pm mistake, not security fuzzing.

**Embedded mechanisms that must carry forward:**
- **Reviewer hand-off contract (lines 13-18):** receives Mode (design | implementation), Input (design contract text OR full branch diff), and pre-read Context (CONTEXT.md, AGENTS.md, PITFALLS.md — **pre-read by reviewer**, so the lens doesn't re-read them). This is a deliberate context-passing optimization in the lens-composition architecture.
- **Single attack question + seven probe categories (lines 20-36):** missing input, double-call-without-waiting, empty input, out-of-order call, stale reference, wrong-layer call (component calling data fn directly — **ties to AGENTS.md layer rules**), type-boundary misuse (teamId where eventId expected).
- **Fixed finding schema (lines 38-59):** FINDING / EVIDENCE / SEVERITY / **LIKELIHOOD** / RECOMMEND per abuse case, or an explicit "Clean" statement. LIKELIHOOD is required and distinguishes this lens from the others.
- **Hard rules (lines 61-67):** every FINDING names a specific misuse (not "could be misused"); every RECOMMEND hardens the interface (**never "add documentation"**); SEVERITY rubric (High = silent wrong behavior/corruption); surface-only, never fix.
- **Frontmatter:** `model: sonnet`, `permissionMode: plan`, `tools: Read` only (most restricted in the batch — read-only single tool).

**V2 disposition flag + why:** **KEEP.** The four-lens parallel adversarial review (abuse / assumption / + composition / cascade implied) is a strong, well-factored review architecture and a clear "clarity over minimalism" win — each lens earns its place by attacking one failure class hard rather than a single reviewer doing all four shallowly. Do not merge the lenses into one agent; the parallelism and single-lane discipline are the value. Re-audit `model: sonnet`: adversarial reasoning is a candidate for Opus 4.8 upgrade, but lens cost multiplies by four-parallel — weigh cost vs. the reviewer doing a smaller number on a stronger model. Read-only, no `disable-model-invocation` concern. **Carry-forward risk: the reviewer pre-reads context and passes it in — a prior design that summarizes "reviewer spawns lenses" would lose this context-passing contract.**

**Autonomy hook:** Strong. The lens swarm is the quality gate in an autonomous PR flow — after implementer commits, `@reviewer` fans out the four lenses against the diff, and their structured findings drive auto-fix / NEEDS-HUMAN routing before the PR is allowed to merge. This is what lets an unattended bug→PR flow ship code that's been adversarially reviewed without a human reading every line.

---

## lens-assumption

**Actual job (plain English):** Sibling single-lens adversarial reviewer, spawned by `@reviewer` in parallel. Attacks exactly one failure class: "what does this design or implementation treat as guaranteed that isn't?" — unstated/unenforced assumptions.

**Embedded mechanisms that must carry forward:**
- **Identical reviewer hand-off contract (lines 13-18):** Mode + Input + pre-read Context (CONTEXT.md, AGENTS.md, PITFALLS.md pre-read by reviewer). Same lens-composition wiring as lens-abuse.
- **Single attack question + six probe categories (lines 20-30):** caller behavior assumed-not-enforced, environment state assumed-not-verified (auth assumed), timing assumed-not-guaranteed, data shape assumed-not-validated, error states assumed-impossible, external-system assumptions (API/Supabase row/network).
- **Fixed finding schema (lines 32-46):** FINDING / EVIDENCE (must cite exact file:line / interface / contract section) / SEVERITY / RECOMMEND (actionable in one PR), or "Clean."
- **Stay-in-lane rule (line 59):** "if you notice something that belongs to another lens (composition, cascade, abuse), note it briefly and move on — do not run that lens yourself." This is the explicit mechanism that keeps the four-lens parallelism non-overlapping — **load-bearing for the lens architecture.**
- **Hard rules (lines 54-60):** every FINDING cites a specific location (no generic observations); every RECOMMEND actionable in one PR (no architectural rewrites); surface-only.
- **Frontmatter:** `model: sonnet`, `permissionMode: plan`, `tools: Read` only.

**V2 disposition flag + why:** **KEEP.** Same rationale as lens-abuse — part of the four-lens parallel review swarm; the single-lane discipline and the explicit stay-in-lane rule are what make the parallel architecture coherent. Re-audit `model: sonnet` for Opus 4.8 (adversarial reasoning) with the same cost caveat. Read-only, no `disable-model-invocation` concern. The "RECOMMEND actionable in one PR, no architectural rewrites" constraint is what keeps lens output mergeable in an autonomous flow — must keep.

**Autonomy hook:** Same as lens-abuse — a parallel member of the reviewer's quality-gate swarm in the autonomous PR flow. The assumption lens is the one most likely to catch the auth/timing/external-system gaps that bite in production, so it's especially valuable as a pre-merge gate for unattended deploys.

---

## CARRY-FORWARD ALERTS

Embedded mechanisms in THIS batch the prior design was most at risk of dropping:

1. **GOLDEN EXEMPLARS (implementer, AGENTS.md Architecture).** "Read the golden exemplars for every layer you will touch. Do not write a new file in a layer without reading the canonical example first." This is the exact mechanism the grounding prompt flagged. It is enforced in the implementer body and is the thing that makes generated code match house style. MUST survive V2 verbatim, and the AGENTS.md exemplar rows it reads must survive with it.

2. **The four-lens parallel review architecture + its three wired contracts:** (a) `@reviewer` pre-reads CONTEXT.md/AGENTS.md/PITFALLS.md and passes them into each lens (context-passing optimization); (b) each lens attacks exactly one failure class; (c) the **stay-in-lane rule** (lens-assumption line 59) that keeps lenses non-overlapping. A summary like "reviewer runs adversarial review" loses all three. Note: only 2 of 4 lenses are in this batch (abuse, assumption) — composition and cascade are referenced but live elsewhere; V2 must keep the set complete.

3. **The investigator→implementer hand-off contract:** investigator outputs a *confirmed failing test* + filled TASK-TEMPLATE.md with the fix in PRE-GRILL (never applied); implementer consumes the spec and makes it green. The "hand off a red test, not a fix" separation is the spine of the autonomous bug→PR loop and is easy to flatten into "investigator finds and fixes bugs," which would destroy it.

4. **`.claude/questions.md` BLOCKING channel** (implementer + investigator) — the shared written hand-off for "stuck, human decide." It is the universal stop-and-surface protocol across the build agents; if dropped, agents lose their safe-failure exit.

5. **Settings/file-flag wiring that gates behavior:** `.claude/agentic-system-enabled` (doc-updater enablement) and `incident-db-query-enabled: true` (incident-responder Check 4 — whether it may execute a read-only query). These are concrete config-driven behavior switches, not prose; under the V2 plugin/marketplace distribution model they need an explicit re-wiring decision, not a silent drop.

6. **The incident-responder routing brain + security short-circuit:** the eight-type classification → proposed-route table (`/migrate`, `/debug`→`/hotfix`, `/feature`, etc.) is the hand-off map for autonomous incident handling, and the "SECURITY SIGNAL DETECTED → isolation only, never fix, stop everything" rule is a non-negotiable safety boundary. Both are easy to lose to a "triages incidents" summary.

7. **hotfix-guard's three deterministic gates and their backing artifact** (`.claude/hotfix-scope-[slug].md` carrying MODE + allowed-file list). The gates are mechanical and their value is determinism — a V2 that makes the guard "smarter" or summarizes it as "checks the hotfix" loses the trustworthy binary merge gate that lets autonomous hotfixes merge unattended.

**Cross-cutting V2 audit items surfaced:** (a) **Legacy snake_case tool names** in hotfix-guard and incident-responder (`read_file,list_files,bash`) vs. camelCase elsewhere — normalize. (b) **All eight agents are `model: sonnet`** — the four reasoning-heavy ones (implementer, investigator, incident-responder, doc-updater) are upgrade candidates on Opus 4.8; the deterministic/mechanical ones (hotfix-guard, explorer-quick) may stay sonnet. (c) **Two agents run `permissionMode: default` with write/commit authority** (implementer, investigator) — verify their required Bash patterns are pre-committed to `permissions.allow` before any background/cloud-scheduled spawn (project background-agent rule).
