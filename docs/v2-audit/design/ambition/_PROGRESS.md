# Ambition Re-mine + Rebuild — Execution Progress (resume here)

## ✅ COMPLETE (2026-06-11). Deliverable: `docs/research/v2-audit/V2-HARNESS-REVIEW.html` (world-class rebuild).
All 6 pipeline steps done. WF5 verdict: READY-TO-DELIVER; anti-dup gate PASS-WITH-MERGES (zero phantoms).
Every WF4+WF5 must-fix folded into the HTML (honest keystone / 22-KEEP roster w/ evaluate-solution / DF1-DF15
fork rename / 2 restored floor guards / honest gaps). Fold recorded in `design/v2/CORRECTIONS-LEDGER.md`
(the HTML is the assembled position; where artifacts disagree, HTML wins). ~95 sub-agents across 5 workflows;
session limit hit twice, zero value lost (phasing + persist-to-disk). Awaiting Tanner's decisions (esp. DF2,
DF12, DF15) → then a future session executes the first slice (the 5-move minimal floor + the keystone gate).


**This file tracks the POST-PIVOT execution** (the world-class redo). Charter: `NEW-CHARTER-AND-SUCCESS-CRITERIA.md`.
Method: fan out subagents; every agent persists its artifact to disk; HARVEST FROM DISK (session limit
interrupts big runs); re-verify any "doesn't exist" claim on disk before relying on it.

## Pipeline (6 steps)
1. **WF1 — 37-source ambition re-mine** → `design/ambition/remine/<slug>.md`  ✅ DONE (37/37, ~99k words,
   134 ELEVATE / 19 NEW / all 37 autonomy-relevant). Quality spot-checked (bug-to-pr E6, stripe E3+U3,
   harness-io E1+U2 — honest, cited, named failure modes on cuts). Run wf_ea655dcc-74c.
2. **WF2 — 4 kill-list attacks + skill/agent grounding + 25 owed traceability** → `design/ambition/killlist/`, `design/ambition/grounding/`, `design/phase6/traceability/`
3. **WF3 — vision synthesis (autonomy/craft/platform → 1) + adversarial check** → `design/ambition/VISION.md`, `design/ambition/VISION-CHECK.md`
4. **WF4 — rebuild the V2 design on the vision, doer≠checker each** → `design/v2/*.md`, `design/v2/checks/*.md`
5. **WF5 — adversarial review (lens panel + reviewer; anti-dup gate mandatory)** → `design/v2/review/*.md`
6. **Deliver** `V2-HARNESS-REVIEW.html` against §4 success criteria.

## Disk re-verification done this session (audit-rot corrections)
- 26 skills, 23 agents, 5 Claude hooks confirmed on disk.
- ABSENT confirmed: `.claude/rules/`, `.claude-plugin/`, `block-dangerous-bash.sh`, `session-end*.sh`,
  `enforce-scope.sh`, `branch-registry-guard.sh`, `gen-harness/scan-context/gen-rules`, `cr-golden/`.
- Existing `Stop` hook (settings.json:191) ONLY plays a sound (Glass.aiff) → M2 deadlock confirmed (a 2nd
  Stop hook needs a human settings.json edit; agent can't edit guard files).
- **ADRs = 6 not 5** (0006-vercel-as-host added post-deploy). **PITFALLS = 558 lines not 574.**
  **33 solution docs** (substantial, not "small"). auto-memory = 52 files. `.cr-ok` gitignored (CI hole real).
- Platform facts: see `design/capability-facts.md` (re-read & still accurate): Stop/SubagentStop can run
  tests+block-on-red (force-continue semantics need empirical check); no hook compels a screenshot; managed-
  settings.json = agent-unreachable floor; `.claude/rules/`+`paths` = native lazy-load; plugin+marketplace =
  native distribution+update (template repo ships no update path).

2. **WF2 — kill-list(4) + grounding(6) + traceability(25)** ✅ PARTIAL (run wf_315765f4-c87). Phase1
   ALL 10 persisted (kill-list ×4 + grounding ×6, ~37k words) BEFORE the session limit hit (reset 2:50pm
   MDT — phasing protected the high-value work). Phase2 (25 traceability checkers) ALL FAILED on the limit
   — these are the optional doer≠checker bonus; their intent (catch DROPPED) is folded into WF5's review as a
   small traceability sweep rather than re-run as 25 agents. All 4 kill-lists READ + internalized (below).

## WORLD-CLASS VISION (crystallized from re-mines + kill-lists — the WF3 input)
Thesis: V1 built the HARNESS (the cells: skills/agents/hooks) but never the LOOP (the engine that finds its
own work and closes bug→reviewed-PR unattended). Every cell exists; no engine drives them; no clock fires
them; the verdict dies in a gitignored sentinel a cloud agent can't read. V2 = the AUTONOMOUS, SELF-IMPROVING,
FLEET-SCALE harness. Pillars:
- **P-A LOOP (autonomy spine):** trigger trifecta (GitHub label / Slack-Linear summon / CI self-heal) →
  worktree→/cr→pr.sh; `/goal` (run-until-graded-stop) + REJECT/UNATTENDED routing; `/lfg` orchestrator
  (brainstorm→plan→work→review→compound→opened-PR, 7 failure-mode guards); cloud heartbeat (rituals get a
  clock); Ona-L4 deterministic risk auto-approval (LOW auto / MED /cr / HIGH human); agent-PR observability log.
- **P-S FLOOR (makes autonomy safe to switch on = the cage for the car):** block-dangerous-bash.sh (full
  scope); egress allowlist (local /queue; cloud already restricted); credential firewall → blocking pre-flight
  invariant + `supabase db push` worktree-block; managed-settings.json (model-unreachable floor);
  disable-model-invocation on every irreversible side-effect skill; MCP lethal-trifecta gate; auto-mode as a
  pillar (author→verify→distribute + single-tenant-prod carve-out); retry-ceiling/bounded-loop contract;
  `.cr-ok`→CI unforgeable terminal stop; stop-the-line defect-class circuit breaker.
- **P-C CRAFT (review/verify quality — weak→world-class):** /cr verdict-as-GitHub-artifact + hard CI gate +
  independent adversarial pass (shared canon/isolated solution ctx) + REJECT tier + governance corpus wired in
  + golden-set recall calibration; structural review contract (test-count floor, blast-radius classifier, PR
  template); per-feature spec layer (executable Verification); PBT on money-math; /verify visual gate
  (a11y+console+pixel-diff, CI vs preview, fail-closed tenant assertion, headless path); §9 deletion engine
  run on Opus 4.8 as a scheduled prune-PR loop.
- **P-M COMPOUNDING (self-improving engine):** 3 owned stores + ridden auto-memory; entry-as-atom; promotion
  gate; native paths: lazy-load; CLOSE the read-back path (RECURRING-FINDINGS→task-start); finding→enforcement
  arc; scan-context drift (stale+fiction+decay) on cloud schedule across the fleet; self-improving context loop
  (scheduled scanner→auto-PR repair worker, /cr-gated+human-merged); effectiveness-metrics ledger; sensor
  ledger+threshold alerts; degrade-safe write-back from autonomous runs.
- **P-P PLATFORM (travels as canon):** plugin+marketplace (/plugin update = pull) + thin /init template;
  convergence canon↔disk = publish gate; Notion→GitHub migration (GitHub = canon, /notion-sync removed,
  /compound Step 8 re-pointed to GitHub); harness-manifest.json; skill-provenance trust governance + per-skill
  upstream-dep disposition policy; push-back-up (scope:project|universal) once 2nd repo exists.
KILL-LIST tallies: §E 8/12 weak→upgrade (truly-world-class kept: guard-file-lockout, safety doctrine, §9
golden rule as doctrine). §F 6 overturned/partial, 3 upheld (no-shared-context, collapse-agents, 200-line
diet — each with named failure mode). §C 6/7 PROMOTE-NOW (outcome-tracking still-gated, Toolshed cut).
Scale-bias TOP5 wrongly-suppressed: trigger front-door, egress/op-enforcement plane, self-improving context
loop, Ona-L4 auto-approval, /lfg orchestrator.
GROUNDING carry-forward alerts (embedded mechanisms NOT to drop): behavior-change test-inversion classifier;
cr .cr-ok + RECURRING-FINDINGS + 4-lens spawn + hook-file escape-hatch; compound permission-log allowlist loop
+ Notion-Step8-must-repoint-to-GitHub; cr-security field allowlist; cross-skill triage-doc-travel protocol;
TASKS.md blocked-task shapes; "artifact fill-in templates ARE the skills"; spike's 6-agent pipeline; refactor
plan-file + naming gate; tdd TESTING.md ledger; review-strategy 3 lens files; queue sentinel gate; setup-
strategy edits CLAUDE.md; supabase security checklist; mattpocock external dep must be vendored; inert autonomy
levers to BUILD (incident capability flags, perf @benchmark-runner); every model: pin re-audit on Opus 4.8.

### TANNER DESIGN INPUT (2026-06-11, mid-run) — the NARRATION / LEGIBILITY CHANNEL (first-class V2 requirement)
Tanner: "I love this check in and tell me what's going on even if you're still driving. Let's add that as part
of version 2." → V2 must treat **continuous human-readable run narration** as a first-class property, not a
terminal afterthought. Any long autonomous or fleet run emits a running progress stream (what just finished /
running now / next / waiting-on), surfaced where the human watches (terminal, Slack channel, the agent-PR
observability log). This EXTENDS the already-surfaced moves — the agent-PR observability log (fleet legibility)
and the shopify session-end review artifact (carried into PR body) — from end-of-run artifacts into a
CONTINUOUS channel. Failure mode it prevents (passes §9): an autonomous run that only reports at the end leaves
the operator blind during the run — a confidently-wrong long run isn't visible until it's expensive to unwind;
the operator can't course-correct and can't safely let the fleet run unattended without it. Lands in pillar P-A
(Loop/observability). DOGFOODED this very session (these check-ins are the feature). Memory:
[[feedback_continuous_checkin_cadence]]. Fold into FINAL VISION.md + the WF4 roster (a narration emitter on
/goal, /lfg, the trigger front-door, and cloud routines).

3. **WF3 — vision synthesis** ✅ DONE (run wf_1c132ceb-e93). 3 lenses + synthesizer draft + 2 adversarial
   checkers (verdicts: OVER-AMBITIOUS-IN-PLACES + SEQUENCING-OR-CAPABILITY-GAPS — both folded in). FINAL
   authoritative `design/ambition/VISION.md` AUTHORED (33 cited moves, 5 pillars, 5-move minimal floor, 7
   "decisively better" deltas incl. Blind→Legible, 11 new forks, honest cuts, capability preconditions).
   Corrections folded: P0 re-tiered to {F1,F2,F6,F7,F9}; merged C1→F6, C3→F7, C7→F6+C6, L3→L2-clause,
   C13+CMP6+P10 model-reaudit→one pass+one probe; HOOK-1 shared Stop-surface anchor; C10 screenshot→
   verify-if-present+CI-leg (capability fix); L2 force-continue Phase-0 probe; L6 incident-subsystem restored;
   L7 narration channel (Tanner); P2 autoMode→local/managed not committed; F4 decision-before-F1-clause;
   C2 lens contracts (pre-read/one-class/stay-in-lane); P6 owns the task-manifest.

4. **WF4 — design rebuild** ✅ DONE (run wf_c0780916-1a2). 5 artifacts + 5 adversarial checks, ALL
   SOUND-WITH-CORRECTIONS. `design/v2/{roster,file-tree,memory-model,github-usage,gaps-risks}.md` +
   `design/v2/checks/*-check.md`. WF4 MUST-FIXES to fold into the HTML:
   - roster: `evaluate-solution` skill OMITTED from Table A (genuine 26th skill; "22 KEEP" was wrong) — ADD it.
   - file-tree: two-budget ledger mis-files the rules shards under budget(2); they are budget(1) (+4 files: 2
     monoliths→6 shards). Restate honestly. AND only 1 of 3 non-safety memory traps routed (route check-branch-
     before-commit→00-safety process; claude-md-referenced-scripts-must-exist→a drift-CI rule).
   - memory-model: PITFALLS routing is Area-GUIDED not "mechanical" (residuals→00-safety); S1 has a dual READER
     (native paths + CMP1 task-start glob) and dual WRITER (/cr 3b + /compound automated AND 00-safety human) —
     name+justify or split 00-safety as a sub-store.
   - github-usage: **KEYSTONE PRECISION** — the un-forgeable F6 gate = SHA-match + CI-RECOMPUTED deterministic
     checks (tsc/eslint/test); the 9+4 /cr judgment passes are COVERAGE-BOUNDED trust-but-verify (bounded by C4
     recall), surfaced but NOT the merge gate. Do NOT over-claim F6 makes "model agreed with itself" un-shippable.
     (Also 2 broken §3a cross-refs → repoint to §2.)
   - gaps-risks: drop the "re-ran on-disk verification this session" checker-voice over-claim; state what was
     re-checked vs inherited.
   Roster facts for the HTML: 26 skills (CUT dep-update; MOVE-OUT supabase + supabase-postgres-best-practices;
   CUT notion-sync→mechanisms carried; /dev-vs-/feature merge = Fork F8; review-strategy+setup-strategy soft-merge
   flagged) → 22 KEEP core. 12 NEW skills (/goal /lfg /verify /scan-context /ratchet /cr-calibrate /init + the
   trigger-summon entry, cloud heartbeat, narration channel, LOOP-7 auto-approval, /dep-update rebuilt). 23 agents
   ALL KEEP (model: re-audit Opus 4.8; security-reviewer>reviewer>lens-composition>impl/investigator/task-runner
   priority; normalize legacy snake_case tool names in hotfix-guard/incident-responder/solution-evaluator). 5
   hooks + 7 new (block-dangerous-bash F1 fail-closed, HOOK-1 shared Stop, credential pre-flight F2, egress F3,
   MCP-trifecta F5, cr-security classifier, CI verdict gate F6). No /commands dir (all-skills correct).

5. **WF5 — final adversarial review** ⏳ LAUNCHED (run wf_bef14c00-5c6). 4 lenses (anti-dup MANDATORY /
   capability-reality / composition-coherence / honesty-proportionality) + 2 traceability sweeps → reviewer
   → `design/v2/review/REVIEWER-CONSOLIDATION.md` (anti-dup verdict + consolidated MUST-FIX + dropped-moves +
   genuine Tanner decisions + READY-TO-DELIVER verdict). (First launch hit a JS brace-nesting parse error;
   relaunched with named schema consts.)

## CARRY-FORWARD: validated conservative mechanics + how the new charter shifts each
(From RECONCILIATION.md + DECISION-PACKAGE.md — these were doer≠checker-validated and are AMBITION-NEUTRAL
sound. Keep the mechanics; the charter raises ambition on top.)
- **Two-budget frame:** budget(1)=agent-READ forgeable prose (CLAUDE/memory/PITFALLS monolith + `.claude/rules`
  shards) → DOWN hard; budget(2)=out-of-band unforgeable enforcement (hooks/CI/lint/manifests) → UP, §9-gated.
  CHARTER SHIFT: file-count-as-redflag is DROPPED, so budget(2) growth (autonomy infra) needs NO apology —
  clarity is the north star. Drop the "~flat total" defensiveness.
- **Memory model (SOUND, carries):** 3 owned stores — S1 `.claude/rules/*.md`+CLAUDE.md floor (durable
  constraints, path-tiered) / S2 `docs/solutions/` (patterns) / S3 `docs/RECURRING-FINDINGS.md` (findings
  INBOX/airlock) — + ridden auto-memory cache (outranked on conflict). Entry-as-atom (`tier:`/`kind:`/
  `freshness:`). Promotion gate S3→S1 (≥3 + human). Native `paths:` lazy-load. `scan-context.sh` drift CI
  catches doc-stale AND doc-fiction(phantoms) AND decay. Shard ONLY where a clean `paths:` glob exists
  (~5–6 shards). `00-safety.md` must absorb memory.md's RICHER safety text VERBATIM before delete.
  CHARTER SHIFT: scan-context runs on cloud /schedule across the FLEET; write-back captures AUTONOMOUS runs.
- **Enforcement (SOUND, carries):** Three-Layer L1 hook / L2 dep-cruiser CI / L3 judgment; §9 deletion engine
  ("name a failure mode or it's overhead"); `.cr-ok`→CI unforgeable (CI re-runs the deterministic /cr subset
  on sentinel SHA via branch protection). 7 build items incl. `block-dangerous-bash.sh`. CHARTER SHIFT:
  bash-guard is load-bearing NOW (autonomy); ADD egress firewall (unattended cloud), retry-ceiling+REJECT
  tier, enforce-scope + branch-registry guards, structural review contract (test-count floor, blast-radius
  classifier), risk-tiered auto-approval (Ona L4), agent-PR observability log.
- **Distribution (RESOLVED D2=YES):** plugin+marketplace (portable mechanism, /plugin update = pull) + thin
  /init template (project-owned: CLAUDE/AGENTS/permissions/autoMode/area-rules). Plugin settings.json carries
  only agent+subagentStatusLine (27-byte proof) → permissions ALWAYS project-authored. Versioned-copy-with-
  lock NOT symlink-live. Convergence-first = PUBLISH gate only (enforcement/memory/measurement run parallel).
- **Compounding loop (SOUND, carries):** run → write-back(Stop→S3) → promote(≥3+human→S1) → read-path → 
  MEASUREMENT (golden-set recall harness for /cr, CI fixture `.claude/eval/cr-golden/`, deterministic scorer,
  never self-certify). CHARTER SHIFT: loop includes autonomous runs; push-back-up (scope:project|universal)
  becomes real once 2nd repo exists; measurement extends to the autonomy track + every model bump (evals-in-CI).
- **The 5 OLD decisions are mostly SETTLED by charter §2:** D1 ADR=BOTH; D2 distribution=two-vehicle YES;
  D3 autonomy front-door = REVERSED to IN-SCOPE-AS-THE-GOAL; D4 write-back=degrade-safe+probe; D5 file-count
  =DROPPED. So the NEW decision brief surfaces DIFFERENT forks (autonomy rollout depth, trigger-surface order,
  egress-firewall depth, deletion-engine cut depth, etc.) — do NOT re-litigate the settled five.

## Resume rule
On resume: check which `design/ambition/remine/*.md` exist (expect 37). Re-run WF1 for only the missing slugs.
Then proceed to WF2. Do NOT re-anchor on the conservative MASTER-FINDINGS/phase3/phase45 judgment before the
vision is synthesized — read those as anti-duplication/carry-forward input DURING the rebuild (WF4), not before.
