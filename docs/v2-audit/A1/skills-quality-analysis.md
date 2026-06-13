# Pass A1 — Quality / Analysis / Strategy Skills Inventory

FACT-ONLY ground-truth inventory. Records what exists and what each skill claims to do. No evaluation or recommendation.

Scope: 9 skills under `.claude/skills/`: debug, incident, post-mortem, perf, spike, evaluate-solution, review-strategy, setup-strategy, behavior-change.

Verification legend: CONFIRMED-PRESENT / CONFIRMED-ABSENT established via Glob/Bash from repo root `/Users/tanner/Dev/event-vendor`.

---

## Shared verification results (apply across skills)

Referenced files at repo root:
- `STRATEGY.md` CONFIRMED-PRESENT · `CONTEXT.md` PRESENT · `AGENTS.md` PRESENT · `CLAUDE.md` PRESENT · `PITFALLS.md` PRESENT · `TASKS.md` PRESENT · `README.md` PRESENT · `docs/TESTING.md` PRESENT · `docs/solutions/README.md` PRESENT · `docs/adr/README.md` PRESENT · `docs/research/` PRESENT · `docs/specs/` PRESENT · `.claude/memory.md` PRESENT.
- `TASK-TEMPLATE.md` CONFIRMED-ABSENT at repo root. It lives at `.claude/TASK-TEMPLATE.md` (CONFIRMED-PRESENT). debug, spike, and incident all reference it by the bare name `TASK-TEMPLATE.md` (e.g. debug SKILL.md:110, spike SKILL.md:198, incident SKILL.md:280). Path-vs-claim mismatch.

Sub-agents referenced (top-level `.claude/agents/`):
- `incident-responder.md` PRESENT (model: sonnet) · `solution-evaluator.md` PRESENT (model: sonnet) · `spike-orchestrator.md` PRESENT (model: opus) · `investigator.md` PRESENT · `explorer.md` PRESENT · `doc-updater.md` PRESENT · `reviewer.md` PRESENT.
- `benchmark-runner` CONFIRMED-ABSENT (referenced as future in perf).
- `strategy-lens-pm/-cto/-challenger` live as `.md` files inside `.claude/skills/review-strategy/` (not in `.claude/agents/`); all three PRESENT. Frontmatter declares `model: claude-sonnet-4-6` on all three.

Sibling skills referenced:
- PRESENT: feature, debug, hotfix, migrate, refactor, design, evaluate-solution, spike, compound, tdd, cr, cr-security, setup-strategy, review-strategy, behavior-change, post-mortem, incident, perf.
- CONFIRMED-ABSENT: `prototype-interface` (referenced by spike, repeatedly), `scan-context` (referenced by review-strategy frontmatter).

Other:
- `Templates` directory (spike SKILL.md:218 "Templates → agents/spike-orchestrator.md") CONFIRMED-ABSENT outside worktrees. The actual file is `.claude/agents/spike-orchestrator.md`.
- `.claude/agentic-system-enabled` sentinel (post-mortem implies "sentinel projects" where `@doc-updater` writes) CONFIRMED-ABSENT at repo root.
- `hotfix-postmortem` token CONFIRMED-ABSENT in current `TASKS.md` (post-mortem claims a `[hotfix-postmortem]` task entry triggers it).

---

## debug

**1. What it is / purpose / trigger.** Investigates an observed symptom, finds root cause, writes a failing test confirming it, and produces a filled `TASK-TEMPLATE.md` for `/feature` (frontmatter:2-10; body:12-16). Output is explicitly "not a fix" (:14). Triggers: "something's wrong", "this is broken", "why is X happening", "track down this bug", `/debug` (:6-8). Do NOT use when cause is known — go to `/feature` Tiny (:8-9).

**2. Workflow.**
- Step 0 Orient (:28-40): read `memory.md`, `PITFALLS.md`, search `docs/solutions/` and `docs/research/`. If PITFALLS documents the failure, surface and skip to Step 3 (:37-39).
- Step 1 Reproduce (:44-61): form hypothesis, find smallest path, run it, confirm symptom. Two failed attempts → write BLOCKING question to `.claude/questions.md` (:55-60). No Step 2 without reproduction (:61).
- Step 2 Bisect (:66-87): identify failure boundary layer; read files using `@investigator` when the bug crosses a layer boundary or spans 3+ files, else grep (:71-73); trace data; confirm causality. STOP AND SURFACE on auth/RLS/data-access, ambiguous location, schema-migration fix, or out-of-scope symptom (:79-87).
- Step 3 Failing test (:92-105): write test reproducing root cause, must fail for right reason; add to `docs/TESTING.md` under "Known gaps" tagged `[BUG] confirmed failing — awaiting fix via /feature` (:103-104).
- Step 4 Task spec (:108-145): fill `TASK-TEMPLATE.md` as Tiny task with embedded template (TASK / SUCCESS CRITERIA / SCOPE / CONSTRAINTS / ROOT CAUSE / OPEN QUESTIONS / REFERENCES / SIZE / PRE-GRILL).
- Final report + Done criteria (:149-175): fix NOT written; `/feature` owns the fix (:174).

**3. Produces / enforces.** Writes: a failing test, a `docs/TESTING.md` `[BUG]` entry, a filled `.claude/TASK-TEMPLATE.md`. Gates: no proceed without reproduction; no fix written. Sub-agent: `@investigator` (conditional).

**4. Enforcement type per step.** All steps ADVISORY (markdown). No hook/CI/script named. The `tsc --noEmit` line in the embedded SUCCESS CRITERIA (:122) is enforced by the pre-commit hook only when `/feature` later runs — not by debug. The "must fail" test gate (:96-98) is advisory self-check.

**5. Cross-references.** Reads `memory.md`, `PITFALLS.md`, `docs/solutions/`, `docs/research/`, writes `docs/TESTING.md`, `.claude/questions.md`, `.claude/TASK-TEMPLATE.md`. Spawns `@investigator`. Feeds `/feature`. Anti-rationalization table (:19-24).

**6. Overlaps.** Heavily overlaps **incident** (both reproduce-first, both STOP-and-surface on auth/RLS). incident SKILL.md:9-10 names the boundary: if `/debug` already confirmed a root cause in our code, classification is done and `/hotfix` is the direct entry. incident also lists `/debug → /hotfix` as a route (incident:32-33). Overlaps **post-mortem** in PITFALLS.md authorship (debug Step 0 reads it; post-mortem writes it). Overlaps **behavior-change** Q3 (behavior-change:73-75 routes defects to `/debug → /hotfix`).

**7. Claim-vs-reality.** `@investigator` CONFIRMED-PRESENT. `memory.md`, `PITFALLS.md`, `docs/solutions/`, `docs/research/`, `docs/TESTING.md` all PRESENT. `TASK-TEMPLATE.md` referenced bare but lives at `.claude/TASK-TEMPLATE.md` (PRESENT there). `/feature` PRESENT. `.claude/questions.md` not verified as a standing file (written on demand).

---

## incident

**1. What it is / purpose / trigger.** Runs before any fix/debug/hotfix; classifies an incident into one of 8 types via structured evidence gathering and routes it (frontmatter:1-11; body:13-23). Triggers: "something is broken", "a user reported", "production issue", "bug report", "users can't", "something seems wrong" (:4-7). Exception: if `/debug` already confirmed root cause in our code, `/hotfix` is the direct entry (:9-10, :42).

**2. Workflow.** 8 incident types table with routes (:26-36): user-error, data-problem, third-party, config-infra, our-code-narrow, our-code-structural, capability-gap, security.
- Phase 0 Reproduce (:85-116): exact steps, match environment; three outcomes — Reproduced/Not-reproducible(stop, surface)/Intermittent(confidence Low).
- Phase 1 Evidence (:120-166): 6 checks — Check 1 behavior vs spec (reads TESTING.md, CONTEXT.md); Check 2 recent changes (git log 7 days); Check 3 dependency health (package.json + changelog/status); Check 4 data state (produce query, do NOT execute unless `incident-db-query-enabled: true` in settings.json :150-153); Check 5 security signals (cross-tenant/privilege/abuse → flag immediately :157-162); Check 6 PITFALLS.md match.
- Phase 2 Classify (:169-184): confidence High/Low/Split.
- Phase 3 Triage document (:187-243): writes `.claude/incident-[slug].md` with full template incl. "Human steps required" section.
- Autonomy model (:247-265) + Route handoff (:269-288): triage doc travels with the confirmed route.
- Current limitations table (:291-308) lists checks requiring human action; flags table (:310-317).

**3. Produces / enforces.** Writes `.claude/incident-[slug].md`. Spawns `@incident-responder` (:285). No code written (:38, :41). Feeds /debug, /hotfix, /migrate, /evaluate-solution, /feature, security path (:287).

**4. Enforcement type per step.** All ADVISORY. No hook/CI/script. Check 4's gate (`incident-db-query-enabled` flag) is documented as INERT: SKILL.md:319-322 explicitly states the flag "cannot currently be added to `.claude/settings.json` — Claude Code's schema validation rejects unrecognized top-level keys" and the skill "will always prompt humans." So the conditional auto-query path is structurally unreachable today.

**5. Cross-references.** Reads TESTING.md, CONTEXT.md, package.json, PITFALLS.md, git log. Writes `.claude/incident-[slug].md`, `.claude/settings.json` (flags, described as currently impossible). Spawns `@incident-responder`. Feeds /debug, /hotfix, /migrate, /evaluate-solution, /feature, security path.

**6. Overlaps.** Overlaps **debug**: both reproduce-first; incident is positioned as the upstream classifier that routes INTO debug (:32-33). Boundary stated at :9-10. Overlaps **evaluate-solution**: third-party/capability-gap types route to it (:30,:34; evaluate-solution:36-41 lists incident as a trigger). Overlaps **post-mortem** indirectly (incident → hotfix → post-mortem chain via PITFALLS authorship). Routes to migrate, refactor, feature, security path.

**7. Claim-vs-reality.** `@incident-responder` CONFIRMED-PRESENT (model: sonnet). Routes /debug, /hotfix, /migrate, /evaluate-solution, /feature, /refactor all PRESENT. `incident-db-query-enabled` settings flag: self-documented as non-functional (:319-322). `.claude/incident-[slug].md` written on demand.

---

## post-mortem

**1. What it is / purpose / trigger.** Investigates a hotfix after it ships to find what allowed the bug and what would have caught it; produces PITFALLS.md + memory.md candidates (frontmatter:1-9; body:11-16). Triggers: "run post-mortem", "investigate the hotfix", `/post-mortem`; also when a `[hotfix-postmortem]` task is promoted to active in TASKS.md (:6-8). Runs after merge, not during the hotfix (:8-9).

**2. Workflow.**
- Entry (:27-41): run with slug `/post-mortem [slug]`; reads TASKS.md `[hotfix-postmortem]` entry, `git diff main hotfix/[slug]`, PITFALLS.md, memory.md. If branch deleted, read merged commit (:40).
- Three questions (:45-81): Q1 what allowed this (structural condition); Q2 what test would have caught it (pre-existence test); Q3 what pattern needs to change (rule for all future work).
- Output two candidates (:85-103): PITFALLS.md candidate block + memory.md candidate block.
- Review and write (:107-115): present both, human approves/edits/rejects each independently; on approval write to PITFALLS.md and memory.md; on sentinel projects `@doc-updater` writes; mark `[hotfix-postmortem]` task `[x]`.
- Done criteria (:119-129).

**3. Produces / enforces.** Candidate entries for `PITFALLS.md` and `memory.md` (not auto-written — review required :116). Updates `TASKS.md`. `@doc-updater` writes on sentinel projects (:113, :130).

**4. Enforcement type per step.** All ADVISORY. "Not optional — the [hotfix-postmortem] task in TASKS.md blocks until this runs" (:23) is a stated discipline, not a hook; no script enforces the block. The `git diff main hotfix/[slug]` read is a plain command, not a gate.

**5. Cross-references.** Reads TASKS.md, PITFALLS.md, memory.md, git diff/merged commit. Writes PITFALLS.md, memory.md, TASKS.md. `@doc-updater`. Feeds PITFALLS.md + memory.md (:128). Triggered by hotfix merge.

**6. Overlaps.** Overlaps **debug** and **incident** as PITFALLS.md/memory.md authorship sources (debug Step 0 / incident Check 6 read what post-mortem writes). Sits downstream of `/hotfix` (which is outside this slice). Overlaps with `/compound` conceptually (both produce PITFALLS/memory candidates) — not cross-referenced in the file.

**7. Claim-vs-reality.** `@doc-updater` CONFIRMED-PRESENT. `PITFALLS.md`, `memory.md`, `TASKS.md` PRESENT. `[hotfix-postmortem]` token CONFIRMED-ABSENT in current TASKS.md — the triggering task entry described at :6-8 and :23 is not currently present. "Sentinel projects" mechanism: `.claude/agentic-system-enabled` (the doc-updater gating sentinel per its agent description) is CONFIRMED-ABSENT at repo root.

---

## perf

**1. What it is / purpose / trigger.** Makes a correct-but-slow operation faster/cheaper without changing behavior (frontmatter:1-13). Triggers: "this is slow", "query is taking too long", "too many re-renders", "memory is climbing", "we're hitting timeouts", named perf target (:6-9). Not for behavior change (/behavior-change), broken code (/hotfix), or cleanup (/refactor) (:10-12).

**2. Workflow.** Enforces 3 things: committed baseline artifact before optimization, a numeric target, before/after comparison as merge gate (:20-37). Execution contexts table (:64-81): script / server-function / db-query / ui-component / data-pipeline.
- Entry gate (:106-150): classify context, name bottleneck, set target (6 questions). Q6 interface change → run `/design contract` first (:141-150).
- Phase 1 Baseline artifact (:152-206): measurement method table; human runs measurement (agent "cannot run production profiling" :173-176); write+commit `.claude/perf-baseline-[slug].md` with `perf(baseline): [slug] — before: [metric]`, no optimization code in commit (:200-206).
- Phase 2 Behavior lock (:209-240): full suite green; characterization tests if gap.
- Phase 3 Optimize (:243-291): branch `perf/[slug]`, optimize smallest change, suite stays green, scope rule (second bottleneck → `.claude/backlog-[slug].md`), behavioral-equivalence rule.
- Phase 4 After measurement (:295-326): same method; fill After block; target hit or Option A continue / Option B revise target with surfaced reason; noise rule (<5% delta, run 5×).
- Pre-/cr gate (:329-347): Gate 1 baseline complete, Gate 2 behavioral equivalence; compound Q1–Q4 required.
- Final report (:351-367).

**3. Produces / enforces.** Writes `.claude/perf-baseline-[slug].md` (before+after), characterization tests if needed, `.claude/backlog-[slug].md` for deferred bottlenecks. Branch `perf/[slug]`. Feeds /cr, /compound.

**4. Enforcement type per step.** All ADVISORY within the skill. The actual blocking happens downstream: pre-commit hook (tsc/lint/tests) on each commit and `/cr` `.cr-ok` sentinel before push are the structural gates — referenced indirectly via "→ /cr → merge" (:101, :307). The "baseline before optimization commit" rule (:154-155, :200-206) is a stated hard rule with NO script enforcing commit ordering. `@benchmark-runner` named as FUTURE (:174-176, :374-380), does not exist.

**5. Cross-references.** `/design contract` (interface changes), `/refactor` (structure-first), `/cr`, `/compound`. `@explorer` optional for hot-path tracing (:371-372, :382). Writes `.claude/perf-baseline-[slug].md`.

**6. Overlaps.** Explicitly de-conflicts itself against /behavior-change, /hotfix, /refactor in frontmatter (:10-12) and "What this is not" (:40-49). Shares the characterization-test-before-touching discipline with **behavior-change** (perf:226-231 ≈ behavior-change Phase 3 intent) and with `/refactor`'s "tests before movement". Shares "@explorer for 3+ file tracing" with debug's `@investigator` heuristic (different agents, same threshold language).

**7. Claim-vs-reality.** `@explorer` CONFIRMED-PRESENT. `@benchmark-runner` CONFIRMED-ABSENT (self-labeled future). `/design`, `/refactor`, `/cr`, `/compound` PRESENT. Baseline path `.claude/perf-baseline-[slug].md` consistent across :300/:334/:357/:385.

---

## spike

**1. What it is / purpose / trigger.** Answers a question before committing to design/implementation; produces a decision (recommendation + confidence + cited evidence + verification + user-impact + TDD slice), not a feature (frontmatter:1-11; body:13-19). Triggers: "can we use X for Y", "is this approach viable", "I'm not sure if", "should we", "what's the best way to", "research X", `/spike` (:4-8). Spawns an orchestrator that runs autonomously (:9-10).

**2. Workflow.** Spawns `@spike-orchestrator` which owns the pipeline (:57-58). Pipeline (:60-82): sharpen question → confirm with human (one required gate) → decide depth (1 or 3 passes) → research agents (parallel per pass) → synthesis dossier → synthesis reflect (3 questions) → adversarial verifier → user verifier → slice agent writes TDD test (one retry) → assemble → file findings.
- Research depth (:86-104): single pass vs three passes (Understanding / Deeper / Application).
- Confidence tiers (:107-114): Settled / Leaning / Open / Blocked, each with a next step (Settled→/feature; Open/Blocked→`/prototype-interface`).
- Output (:118-198): Decision Summary (4 lenses: Engineering/Operations/User/Finance-scale + Dissent + Sources), Research Dossier, TDD Slice block, Filed Findings.
- Done criteria (:202-214).

**3. Produces / enforces.** Updates `docs/research/[topic].md`; proposes PITFALLS.md candidate; adds TESTING.md tracer bullet; fills `TASK-TEMPLATE.md`. Spawns `@spike-orchestrator` (which per its own def spawns spike-researcher, spike-synthesis, spike-adversarial-verifier, spike-user-verifier, spike-slice). Human gate: question confirmation before research (:63).

**4. Enforcement type per step.** All ADVISORY. The single human confirmation gate (:63) is a markdown instruction. The TDD slice "must fail/pass" determination is advisory self-check. No hook/CI/script named.

**5. Cross-references.** Spawns `@spike-orchestrator`. Feeds `/feature` (Settled/Leaning + slice passes), `/debug` (slice fails), `/prototype-interface` (Open/Blocked). Output `docs/research/[topic].md`. References `/design contract`, `/prototype-interface`. Cites "Templates → agents/spike-orchestrator.md" (:218).

**6. Overlaps.** Overlaps **evaluate-solution**: evaluate-solution:9-11 states it is "invoked from /spike when feasibility involves a third-party option"; spike's Finance/scale lens (:137-138) overlaps evaluate-solution's Q2/Q3 cost analysis. Overlaps **debug** as a downstream consumer (failed slice → /debug :185). Both spike and evaluate-solution write to `docs/research/[topic].md` (collision-prone shared output target). Overlaps the broader research/deep-research skill conceptually (not cross-referenced here).

**7. Claim-vs-reality.** `@spike-orchestrator` CONFIRMED-PRESENT (model: opus); its child agents (spike-researcher, spike-synthesis, spike-adversarial-verifier, spike-user-verifier, spike-slice) all CONFIRMED-PRESENT in `.claude/agents/`. `/feature`, `/debug`, `/design` PRESENT. **`/prototype-interface` CONFIRMED-ABSENT** — referenced repeatedly (:25,:113,:189,:220) as the Open/Blocked next step and in "What this is not"; the skill does not exist. **`Templates` directory CONFIRMED-ABSENT** (non-worktree) — the actual path is `.claude/agents/spike-orchestrator.md`, not "Templates → agents/…" (:218). `TASK-TEMPLATE.md` referenced bare; lives at `.claude/TASK-TEMPLATE.md`.

---

## evaluate-solution

**1. What it is / purpose / trigger.** Build-vs-buy analysis; produces a recommendation with financial cost (current + 10×), operational cost, lock-in, build cost, tradeoffs (frontmatter:1-12). Triggers: "should we use X", "is there a library for", "what would it cost to use", "build or buy"; routed from /incident (third-party / capability-gap), /spike (feasibility w/ third-party option), /feature (new capability) (:7-11, :36-41). Spawns `@solution-evaluator`.

**2. Workflow.** Seven required questions (:46-90): Q1 fit, Q2 cost at current scale (actual pricing-page numbers), Q3 cost at 10×, Q4 operational cost, Q5 lock-in risk, Q6 build cost, Q7 community/longevity health. Output document `.claude/solution-eval-[slug].md` template (:92-131). Recommendation format — single sentence, named choice, never "it depends" (:133-142). Autonomy model (:144-156). After: doc travels to /design contract / /feature / /spike; stored in `docs/research/[topic].md` with 30-day stale signal (:158-164). Current limitations / human-steps table (:172-189): pricing behind login, internal usage metrics, private repos, vendor SLA. A recommendation produced without Q2/Q3 cost data is marked INCOMPLETE (:186-189).

**3. Produces / enforces.** Writes `.claude/solution-eval-[slug].md`, then `docs/research/[topic].md`. Spawns `@solution-evaluator`. Gate: all 7 questions required; missing Q2/Q3 → INCOMPLETE (:46-47, :186-189). Feeds /design contract, /feature, /spike decision record.

**4. Enforcement type per step.** All ADVISORY. The "all seven required" and "INCOMPLETE without Q2/Q3" rules (:46-47, :186-189) are markdown discipline — no script validates the document. No hook/CI.

**5. Cross-references.** Spawns `@solution-evaluator`. Invoked from /incident, /spike, /feature. Feeds /design contract, /feature, /spike. Output `docs/research/[topic].md`.

**6. Overlaps.** Overlaps **spike**: spike routes third-party feasibility here (spike + evaluate-solution share `docs/research/[topic].md` output). Overlaps **incident**: incident's third-party and capability-gap types route here (incident:30,:34,:280). Q6 build-cost overlaps spike's recommendation lens. Both spike and evaluate-solution have adversarial/lens structures, dissent, and a single-named-recommendation contract.

**7. Claim-vs-reality.** `@solution-evaluator` CONFIRMED-PRESENT (model: sonnet). `/incident`, `/spike`, `/feature`, `/design` PRESENT. `docs/research/` PRESENT. `.claude/solution-eval-[slug].md` written on demand. No absent references found.

---

## review-strategy

**1. What it is / purpose / trigger.** Orchestrates three adversarial reviewers against `STRATEGY.md` — PM, CTO, Challenger lenses — in parallel as isolated sub-agents; isolation required so lenses don't soften each other (frontmatter:1-9). Run after `/setup-strategy`, when strategy shifts, or when `/scan-context` flags STRATEGY.md stale (:7-8).

**2. Workflow.**
- Prerequisites (:11-14): `STRATEGY.md` must exist; if not, stop and tell user to run `/setup-strategy`.
- Step 1 (:18-26): orchestrator reads STRATEGY.md, CLAUDE.md, AGENTS.md, CONTEXT.md and passes content directly (no re-read by agents).
- Step 2 (:29-40): spawn `@strategy-lens-pm`, `@strategy-lens-cto`, `@strategy-lens-challenger` in a single message, in parallel; each receives only file contents, no prior lens output.
- Step 3 (:44-61): consolidated summary template (MUST REVISIT total, most-flagged section, clean sections, recommended action).
- Hard rules (:64-69): all three lenses every time; do not rewrite STRATEGY.md — surface only.

Lens files (each: tools: Read, model: claude-sonnet-4-6, permissionMode: plan):
- `strategy-lens-pm.md`: "specific enough to act on?" 5 attack questions (:22-27).
- `strategy-lens-cto.md`: "matches technical reality?" 5 attack questions (:22-27).
- `strategy-lens-challenger.md`: "what assumption kills this?" 5 attack questions (:23-27).
All three share MUST REVISIT / CONSIDER / Clean output format and identical hard rules.

**3. Produces / enforces.** Produces a consolidated MUST REVISIT / CONSIDER summary. Spawns 3 lens agents. Does NOT rewrite STRATEGY.md (:69). No file written by default.

**4. Enforcement type per step.** All ADVISORY. The prerequisite stop (:13-14) is a markdown self-check. Parallel-isolation is an instruction, not enforced by code. Lens frontmatter `permissionMode: plan` is a runtime constraint on those agents (read-only posture) but applies to the agents, not gating the workflow.

**5. Cross-references.** Reads STRATEGY.md, CLAUDE.md, AGENTS.md, CONTEXT.md. Spawns the 3 lens agents (colocated in the skill dir). References `/setup-strategy` (prereq + update mode) and `/scan-context` (staleness trigger).

**6. Overlaps.** Paired with **setup-strategy** (produces STRATEGY.md; review-strategy stress-tests it). Structurally mirrors the build/review-side `reviewer` + lens-* agent fan-out pattern (lens-abuse/assumption/cascade/composition exist in `.claude/agents/`) — same parallel-isolated-lens architecture applied to strategy instead of code. No scope overlap with debug/incident/perf.

**7. Claim-vs-reality.** Three lens agents CONFIRMED-PRESENT (in `.claude/skills/review-strategy/`, not `.claude/agents/`). `STRATEGY.md`, `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md` all PRESENT. `/setup-strategy` PRESENT. **`/scan-context` CONFIRMED-ABSENT** — named in frontmatter (:8) as a staleness trigger; no such skill. Lens model `claude-sonnet-4-6` is a frontmatter string, not a file (not verifiable as present/absent in repo).

---

## setup-strategy

**1. What it is / purpose / trigger.** Interviews the user to produce `STRATEGY.md`; reads existing codebase context to infer answers first; wires STRATEGY.md into the session-start orient step (frontmatter:1-9). Run once per project at setup or when strategy shifts. Run `/review-strategy` after (:8).

**2. Workflow.**
- Step 1 Detect tier (:11-19): Tier 1 if `CONTEXT.md` exists (infer from codebase); Tier 2 if a URL exists in CLAUDE.md/README.md/project file (web-fetch landing page/socials/store listing); Tier 3 structured interview.
- Step 2 Tier 1 (:22-55): read CONTEXT.md, AGENTS.md, CLAUDE.md, docs/TESTING.md, docs/specs/, data models; infer primary user/core problem/stage/constraints/out-of-scope; present draft + gaps with forced-choice options.
- Step 2 Tier 2 (:57-62): web-fetch public presence; draft with gap-flagging.
- Step 2 Tier 3 (:66-81): structured interview, one question at a time, 7 forced-choice questions.
- Step 3 Write file (:85-92): on confirmation write `STRATEGY.md` to repo root with template format; add `context-meta` block (`review-frequency: monthly`, today as `last-reviewed`); if CLAUDE.md session-start block lacks a STRATEGY.md read instruction, add it; report and recommend `/review-strategy`.
- Hard rules (:96-102): never write without confirmation; never open-ended when forced-choice possible; Tier 1 infer-first; keep under 400 words; push back once on vague answers.

**3. Produces / enforces.** Writes `STRATEGY.md` (repo root) + a CLAUDE.md session-start edit. Gate: never write without user confirmation (:98). Web-fetch in Tier 2.

**4. Enforcement type per step.** All ADVISORY. "Never write without confirmation" (:98) is a markdown rule; no hook enforces it. The CLAUDE.md edit it performs (:90-92) is itself a guard-file-adjacent write done by the skill.

**5. Cross-references.** Reads CONTEXT.md, AGENTS.md, CLAUDE.md, docs/TESTING.md, docs/specs/, README.md. Writes STRATEGY.md, CLAUDE.md. Feeds `/review-strategy` (explicitly recommended after). References STRATEGY.md template ("see STRATEGY.md" :89).

**6. Overlaps.** Directly paired with **review-strategy** (input/output relationship). No overlap with the analysis/debug cluster. Shares the "infer from codebase context" reading set (CONTEXT.md, AGENTS.md) with incident Check 1 and behavior-change Phase 2.

**7. Claim-vs-reality.** All referenced read targets PRESENT: CONTEXT.md, AGENTS.md, CLAUDE.md, docs/TESTING.md, docs/specs/, README.md. `STRATEGY.md` already PRESENT (so "produce once" has already run, or file pre-exists). `/review-strategy` PRESENT. No absent references.

---

## behavior-change

**1. What it is / purpose / trigger.** Intentionally changing what the system does in an existing situation — not a bug fix, refactor, or new capability (frontmatter:1-10). Use when "the system currently does X, it should now do Y" and X was correct at the time. Triggers: "change how this works", "the behavior needs to change", "update the logic so that", "we want this to behave differently" (:5-7). Routes elsewhere: new capability → /feature, internal restructure → /refactor, defect → /hotfix (:7-9).

**2. Workflow.** Risk profile vs /feature (:18-31). Entry gate classify (:62-86): 4 questions; Q3 defect → STOP route to /debug→/hotfix; Q4 interface change → run /design contract first.
- Phase 1 Caller impact analysis (:114-144): spawn `@explorer`, document every internal callsite (assumes/impact/action). >10 callsites → surface summary.
- Phase 2 External caller check (:147-176): API response? webhooks/events? external-consumed data? documented consumers? Any exposure → surface before Phase 3.
- Phase 3 Test inversion analysis (:179-219): classify each test OUTDATED/VALID/COVERAGE GAP/UNAFFECTED; do not delete without classifying; no-tests-found is itself a finding requiring characterization tests first.
- Phase 4 Rollback plan (:222-243): state-safe to revert? rollback procedure within 24h? feature flag/phased rollout? State-unsafe + no migration plan → BLOCKING to questions.md.
- Phase 5 Implementation (:247-294): branch `behavior-change/[slug]`; execute test inversion; new failing test; minimum impl; update VALID tests; write COVERAGE GAP tests; tsc; update affected callsites; full suite. Net coverage must not drop.
- Phase 6 Doc sync (:297-318): checklist — TESTING.md, CONTEXT.md, AGENTS.md, docs/specs/[slug].md, PITFALLS.md, API docs. Gates /cr.
- Pre-/cr gate (:321-334): Gate 1 caller impact verified, Gate 2 doc sync complete; compound Q1–Q4 required.
- Final report (:338-357).

**3. Produces / enforces.** Writes `.claude/behavior-change-[slug].md` (caller impact doc, test inversion list, rollback plan, doc sync checklist :366-367). Branch `behavior-change/[slug]`. Spawns `@explorer` (Phase 1); `@reviewer` optional for 5+ affected callsites (:361-363). Feeds /cr, /compound.

**4. Enforcement type per step.** All ADVISORY within the skill. Doc sync "gates /cr" (:297, :329-331) is stated discipline — the actual structural block is the downstream `/cr` `.cr-ok` sentinel + pre-push/pre-commit hooks, not anything in this file. The "tsc --noEmit" step (:272) becomes structural only at commit via the pre-commit hook. BLOCKING-to-questions.md is a self-imposed stop.

**5. Cross-references.** Spawns `@explorer` (required Phase 1), `@reviewer` (optional). Routes to /debug→/hotfix (defect), /refactor, /feature, /design contract. Reads/writes TESTING.md, CONTEXT.md, AGENTS.md, docs/specs/, PITFALLS.md, questions.md. Feeds /cr, /compound. Output `.claude/behavior-change-[slug].md`.

**6. Overlaps.** Explicitly de-conflicts against /feature, /refactor, /hotfix, /debug in frontmatter and "What this is not" (:34-48). Overlaps **perf**: both write characterization tests before touching code and both have a Phase-2 behavior-lock equivalent and a pre-/cr gate with compound Q1–Q4; perf forbids behavior change, behavior-change forbids structure change — adjacent halves of the same "two hats" doctrine. Overlaps **debug** via the Q3 defect off-ramp (routes into /debug→/hotfix). Phase 3 "test inversion" is stated to be unique: "the phase that doesn't exist in any other skill" (:181).

**7. Claim-vs-reality.** `@explorer` CONFIRMED-PRESENT. `@reviewer` CONFIRMED-PRESENT. `/feature`, `/refactor`, `/hotfix`, `/debug`, `/design`, `/cr`, `/compound` all PRESENT. Read/write targets TESTING.md, CONTEXT.md, AGENTS.md, docs/specs/, PITFALLS.md all PRESENT. `.claude/behavior-change-[slug].md` and `questions.md` written on demand. No absent references.

---

## Cross-skill overlap map (located, not judged)

| Overlap | Where | Boundary statement (if any) |
|---|---|---|
| debug ↔ incident | both reproduce-first + STOP on auth/RLS; incident routes into debug | incident:9-10, :42 (if debug confirmed root cause, skip to /hotfix) |
| incident ↔ evaluate-solution | third-party/capability-gap types route to eval | incident:30,:34; eval:36-41 |
| spike ↔ evaluate-solution | spike routes third-party feasibility to eval; both write `docs/research/[topic].md` | eval:9-11, :39 |
| debug ↔ post-mortem | post-mortem writes PITFALLS/memory that debug Step 0 reads | not cross-referenced |
| behavior-change ↔ perf | both characterization-tests-first + compound-Q gate; opposite "two hats" halves | both de-conflict in frontmatter |
| review-strategy ↔ setup-strategy | input/output pair around STRATEGY.md | review-strategy prereq:13-14 |
| review-strategy ↔ build-side reviewer/lens-* | same parallel-isolated-lens fan-out architecture | not cross-referenced |
| shared output collision | spike + evaluate-solution both target `docs/research/[topic].md` | — |

## Consolidated claim-vs-reality flags

CONFIRMED-ABSENT references:
- `/prototype-interface` — spike (multiple sites: :25,:113,:189,:220). No skill dir.
- `/scan-context` — review-strategy frontmatter:8. No skill dir.
- `@benchmark-runner` — perf (:174-176,:374-380), self-labeled future.
- `Templates` directory — spike:218 ("Templates → agents/…"); actual path is `.claude/agents/`.
- `TASK-TEMPLATE.md` at repo root — referenced bare by debug/spike/incident; actual location `.claude/TASK-TEMPLATE.md`.
- `[hotfix-postmortem]` TASKS.md entry — post-mortem trigger; token not present in current TASKS.md.
- `.claude/agentic-system-enabled` sentinel — implied by post-mortem "sentinel projects" + doc-updater gating; absent at repo root.
- `incident-db-query-enabled` settings flag — incident self-documents it as currently impossible to add (:319-322).

CONFIRMED-PRESENT references:
- Sub-agents: incident-responder, solution-evaluator, spike-orchestrator (+ spike-researcher/-synthesis/-adversarial-verifier/-user-verifier/-slice), investigator, explorer, doc-updater, reviewer, and the three strategy-lens-* (in skill dir).
- Sibling skills: feature, debug, hotfix, migrate, refactor, design, evaluate-solution, spike, compound, tdd, cr, cr-security, setup-strategy, review-strategy, behavior-change, post-mortem, incident, perf.
- Docs: STRATEGY.md, CONTEXT.md, AGENTS.md, CLAUDE.md, PITFALLS.md, TASKS.md, README.md, docs/TESTING.md, docs/solutions/README.md, docs/adr/README.md, docs/research/, docs/specs/, .claude/memory.md, .claude/TASK-TEMPLATE.md.

## Enforcement summary (all 9 skills)

Across all nine skills in this slice, every workflow step is ADVISORY (markdown instruction) within the skill file itself. None of these skills contains or invokes a hook/CI/script that blocks at the step described. The only STRUCTURAL enforcement they touch is downstream and shared: the pre-commit hook (tsc/lint/vitest), the `/cr` `.cr-ok` sentinel, and the pre-push hook — invoked indirectly via "→ /cr → merge". perf and behavior-change make this dependency explicit with a "Pre-/cr gate" section; the others rely on it implicitly or not at all. No script unique to debug/incident/post-mortem/perf/spike/evaluate-solution/review-strategy/setup-strategy/behavior-change was found.
