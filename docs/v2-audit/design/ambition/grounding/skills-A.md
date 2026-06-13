# Grounding Pass — Skills Batch A

Source: read in full from `.claude/skills/<name>/SKILL.md`. Goal: catch every embedded, load-bearing mechanism so none is summarized away in V2.

Charter lens: world-class only; autonomy is first-class (bug→reviewed-PR, Slack/Linear summon, cloud /schedule, self-improving loops); clarity beats minimalism (more files fine if each earns its place); keep the rigor (cite ground-truth, name genuine bad fits).

Batch covers 9 requested files. **8 read successfully; 1 absent** (`dep-update/SKILL.md` — see below).

---

## behavior-change

**Actual job (plain English):** Manages the case where the system *currently does X, should now do Y, and X was correct at the time*. It is not a feature, refactor, or bug fix. The whole point is protecting *existing callers who were right to assume the old behavior* — internal callsites, external consumers, and existing tests that now silently assert the wrong thing.

**Embedded mechanisms that must carry forward:**
- **Entry gate / 4-question classifier** (`SKILL.md:62-85`): a hard router. Q3 "defect → STOP route to /debug → /hotfix"; Q4 "interface changes → run /design contract before Phase 1." This is a wired hand-off protocol between skills, not prose. Misclassification is flushed here.
- **Anti-rationalization table** (`:50-59`): 6 named rationalizations + rebuttals (e.g. "test failures are expected" → classify, don't bulk-delete red tests). This is a behavioral guard, load-bearing.
- **Phase 1 caller-impact contract** (`:114-144`): spawns **`@explorer`** sub-agent; fills a per-callsite template with a mandatory verdict + action; "every callsite has a verdict and an action, no blank impact field" is the done-signal. >10 callsites → surface summary to human.
- **Phase 2 external-caller checklist** (`:147-176`): explicit 4-question form (API response? webhooks/events? external data consumers? documented consumers in CONTEXT/AGENTS/docs?). External exposure → coordination *before* Phase 3. This is the "external systems are invisible" defense.
- **Phase 3 Test Inversion analysis** (`:179-218`): the unique mechanism. Classifies every existing test into OUTDATED / VALID / COVERAGE GAP / UNAFFECTED before any code. Rule: "do not delete a test without classifying it first." "No tests cover this behavior" is itself a surfaced finding → write characterization tests first.
- **Phase 4 Rollback plan** (`:221-243`): state-safety question; state-unsafe + no migration plan → BLOCKING to `questions.md`. Feature-flag / phased-rollout decision captured before code.
- **Phase 5 reordered TDD** (`:247-294`): test inversion executes *before* the new failing test is written; net-coverage bar ("must cover new behavior at least as well as old").
- **Phase 6 Doc-sync checklist** (`:297-317`): gates /cr (TESTING.md, CONTEXT.md, AGENTS.md, docs/specs, PITFALLS.md, API docs). "Not a /cr finding — it gates /cr."
- **Pre-/cr gate** (`:321-333`): Gate 1 caller-impact verified, Gate 2 doc-sync complete; "compound questions block Q1–Q4 still required before /cr."
- **Artifact location** (`:367`): pre-phase artifacts live in `.claude/behavior-change-[slug].md`.

**V2 disposition flag + why:** **KEEP.** The Test-Inversion phase is a genuinely unique, world-class mechanism that exists in no other skill — exactly the kind of embedded mechanism the carry-forward ledger warns gets summarized to "does a behavior change." Do NOT collapse this into /feature. Possible CHANGE-DELIVERY note: it is heavy prose; the four phase-templates + the entry gate are the load-bearing parts and should be preserved as fill-in contracts, not narrative.

**Autonomy hook:** Strong fit. A bug→PR flow that detects "this is a deliberate behavior change, not a defect" should route here automatically; the entry gate's classifier is exactly the decision an autonomous router needs. The external-caller check (Phase 2) is the gate that should *block* an autonomous deploy and summon a human when external exposure exists — that is the one human-in-the-loop checkpoint to wire, not remove.

---

## compound

**Actual job (plain English):** The post-merge learning-capture / self-improvement loop. After a feature merges it writes a reusable solution doc, then sweeps for PITFALLS / memory / allowlist / Notion-changelog updates and a session retrospective. This is the codebase's "get smarter every cycle" mechanism.

**Embedded mechanisms that must carry forward:**
- **Step 1 inputs** (`:27-33`): reads merged PR diff, `.claude/TASK-TEMPLATE.md`, compound-question answers, docs/TESTING.md entries.
- **Step 2 solution-extractor sub-agent (Sonnet)** (`:36-49`): writes against **`docs/solutions/TEMPLATE.md`** — a wired template-fill contract. "Do not summarize what was built. Capture what's reusable."
- **Step 4 write target** (`:64-69`): `docs/solutions/YYYY-MM-DD-short-description.md`.
- **Step 5 PITFALLS.md promotion** (`:71-77`): standard format (Area, Rule, Why, Symptoms, Source) — explicit "say so if no" rule.
- **Step 6 memory.md update** (`:79-85`): same explicit-negative rule.
- **Step 7 permission-log → allowlist** (`:87-104`): reads `/tmp/claude-perm-log-${HASH}.jsonl` (HASH = md5 of `$CLAUDE_PROJECT_DIR`), diffs against `settings.json permissions.allow`, groups candidates Safe-to-add vs Review-first. **Does NOT write settings.json directly** — surfaces and waits. This is a self-improving harness loop, fully wired.
- **Step 8 Notion AI-engineering changelog** (`:106-124`): versioned subpage bump (v0.84→v0.85), settings.json/hooks/skills template sync. This is the canonical-record sync.
- **Session retrospective** (`:128-135`): the **"86% audit"** — "what slowed this session that was NOT writing code?" + learning-capture for CONTEXT.md. Load-bearing data feed for system-growth decisions.
- **Step 9 quarterly memory review** (`:139-163`): ~90-day stale/outdated/redundant sweep with a fixed report format; "do not modify memory.md, surface candidates."

**V2 disposition flag + why:** **KEEP** — but with a **CHANGE-DELIVERY** flag on Step 8. Per the new charter, GitHub is canon (Notion→GitHub migration is happening), so the Step-8 Notion-changelog sync must be re-pointed at the GitHub canonical record, not deleted. The self-improvement loop (Steps 5/6/7 + retro) is exactly the "self-improving loops, designed in" the charter demands — this is a flagship autonomy skill. The TEMPLATE.md dependency (`docs/solutions/TEMPLATE.md`) must survive — it is a golden-exemplar-class file read by the sub-agent.

**Autonomy hook:** Central to the self-improving fleet. A cloud-scheduled nightly /compound across merged PRs would auto-grow PITFALLS / RECURRING-FINDINGS / allowlist with human-confirm gates. Step 7 (permission-log → allowlist candidate) is the precise loop that lets a fleet reduce its own future permission prompts over time. Wire the human-confirm checkpoints as Slack/Linear approvals rather than inline waits.

---

## cr

**Actual job (plain English):** The full pre-merge gate. Runs 9 analytical review passes + an adversarial 4-lens pass in parallel against the whole branch diff, auto-fixes Must-Fix items with Opus, updates the recurring-findings ledger, and writes the `.cr-ok` sentinel that the pre-push hook validates. This is *the* quality gate of the whole pipeline.

**Embedded mechanisms that must carry forward:**
- **`.cr-ok` sentinel** (`:240-254`): the load-bearing gate. Encodes `branch:sha`; written to the **absolute** `${REPO_ROOT}/.claude/.cr-ok` (relative form does not match the sub-agent path allowlist); Write-tool fallback if redirect denied; "any commit after invalidates it." The pre-push hook and `scripts/pr.sh` consume this. Anti-rationalization row explicitly bans writing it directly (`:21`).
- **Step 0 docs-only fast path** (`:25-39`): single Haiku doc-review when diff is all .md/.claude/config. Includes a **skill-structure meta-check**: scans `.claude/skills/**/*.md` for user-input-wait instructions mid-pipeline and flags them MUST FIX (cites its own Step-3b prompt as the bug example). This is a self-policing mechanism for skill design — directly relevant to V2 skill authoring.
- **9 named passes** (`:60-139`): P1 Correctness/Spec, P2 Domain Safety (Supabase error handling, teamId guard, status-trigger correctness, `get_proposal_by_share_token` allowlist), P3 TS Discipline, P4 Layer Boundaries, P5 Readability, P6 Test Quality (incl. **transcription-test check**), P7 Doc Drift & Footprint (Haiku, mechanical + doc-contradiction), P8 Architectural Drift, P9 Devil's Advocate. Several passes read PITFALLS.md / AGENTS.md before reviewing — wired file dependencies.
- **Pass 11 Adversarial Review** (`:143-153`): spawns **`@reviewer`** which spawns **four lens sub-agents** (assumption violation, composition failures, cascade construction, abuse cases). Findings tagged `[P11-assumption|composition|cascade|abuse]`. "Full agent: Templates → agents/reviewer.md" — a wired sub-agent template file.
- **Step 3b RECURRING-FINDINGS.md ledger** (`:174-189`): normalized signatures, occurrence counts, auto-flag promotion at ≥3 occurrences, judgment-flag at lower. This is a self-improving review loop — repeated findings get promoted to PITFALLS or a /cr pass prompt.
- **Step 4 Opus fix agent + hook-file escape hatch** (`:192-209`): "fix only listed, NEEDS HUMAN if >~15 lines / architectural / ambiguous." **Hook-file escape hatch**: Must-Fix in `.claude/hooks/*.sh` is NOT routed to the Opus agent (settings.json deny blocks it) → NEEDS HUMAN with paste-ready command; sentinel withheld until human confirms.
- **Step 8 mandatory /compound evaluation** (`:260-273`): "always runs; only the outcome varies."

**V2 disposition flag + why:** **KEEP** — this is the spine. Two re-audit flags under the charter: (1) the per-pass **model: fields** (Sonnet/Haiku/Opus) must be re-audited on Opus 4.8 — several Sonnet passes may now warrant Opus-class reasoning, and the Haiku passes (P7, docs-only) should be re-benchmarked. (2) The `@reviewer` 4-lens fan-out and the RECURRING-FINDINGS ledger are exactly the "golden exemplar"-class wired mechanisms the carry-forward warning is about — they must not be flattened into "/cr does a review." CHANGE-DELIVERY note: the sentinel-path workaround prose is harness-version-specific and should be re-derived for V2's distribution model (plugin+marketplace), not copied verbatim.

**Autonomy hook:** This is the heart of bug→reviewed-PR. An autonomous flow runs /cr, and the `.cr-ok` sentinel + `scripts/pr.sh` consumption is what lets an agent open a PR without a human pre-approving the diff. For cloud /schedule, the entire pass set runs committed-as-skills with no laptop. The RECURRING-FINDINGS auto-promotion is a self-improving loop that should keep running unattended. The one place to keep a human gate: NEEDS HUMAN items (hook files, >15-line fixes) must summon a human via Slack/Linear rather than block silently.

---

## cr-security

**Actual job (plain English):** The security-only review, opt-in, run alongside /cr whenever a change touches auth, RLS, public endpoints, share tokens, or data boundaries. 3 parallel passes, **every finding is MUST FIX** (no suggestion tier), auto-fixed by Opus.

**Embedded mechanisms that must carry forward:**
- **Trigger surface** (`:13-21`): explicit list — auth/middleware/route guards, public unauth handlers (`/p/[token]`, `/no-team`, `/auth/callback`), RLS, cross-team isolation, share tokens / `get_proposal_by_share_token`, server actions, new Postgres functions.
- **Pass 1 Security & Auth** (`:36-46`): includes the project-specific footguns — redirect built from user input must use only `resolved.pathname`; PUBLIC_PATHS pages inside `(app)` still hit the group auth gate.
- **Pass 2 Data Boundary Integrity** (`:47-55`): Supabase only in `src/data/`; `get_proposal_by_share_token` allowlist (no `team_id`, `share_token`, `viewed_at`, `responded_at`, `deleted_at`, contact fields); every mutation takes `teamId`; new tables RLS via `private.team_ids()`; `REVOKE EXECUTE ... FROM PUBLIC` after `CREATE OR REPLACE FUNCTION`.
- **Pass 3 wired /supabase skill invocation** (`:56-68`): "Invoke the `/supabase` skill and run its security checklist." Then 9 concrete checks (user_metadata vs app_metadata in RLS, JWT-claim staleness, user deletion without session revocation, service_role in client, views needing `security_invoker=true`, UPDATE policy needing companion SELECT, missing `FORCE ROW LEVEL SECURITY`, definer-in-exposed-schema REVOKE, storage RLS needing INSERT+SELECT+UPDATE). This is a wired skill→skill hand-off plus a hard checklist.
- **Step 3 Opus auto-fix + NEEDS HUMAN** (`:71-79`): runs `npx vitest run`, surfaces failures without retry.

**V2 disposition flag + why:** **KEEP** — security is non-negotiable at the world-class bar. Re-audit the three passes' `model:` fields on Opus 4.8 (currently all Sonnet for review, Opus for fix). MERGE-CANDIDATE consideration *rejected*: do NOT fold this into /cr — it is opt-in, has a no-suggestion-tier discipline, and its Pass 3 chains into /supabase. Keeping it separate is the correct clarity-over-minimalism call. CHANGE-DELIVERY: the embedded checklist duplicates content the `/supabase` skill owns; in V2 consider sourcing Pass 3's checklist *from* the /supabase skill body to avoid drift, rather than maintaining two copies.

**Autonomy hook:** This is the mandatory human-or-hardened gate for any autonomous change touching auth/RLS. A bug→PR flow that touches the trigger surface MUST run cr-security; because every finding is MUST FIX, an autonomous agent cannot ship unfixed findings — the right design is auto-fix what's safe, summon a human (Slack/Linear) on any NEEDS HUMAN security item. This is precisely where autonomy needs a hard guardrail, not full self-approval.

---

## debug

**Actual job (plain English):** Investigates an observed symptom to a *confirmed* root cause, writes a failing test that proves it, and hands off a filled TASK-TEMPLATE.md to /feature. **It deliberately does NOT write the fix** — root-cause + failing test + spec only.

**Embedded mechanisms that must carry forward:**
- **Step 0 Orient** (`:28-41`): reads memory.md, PITFALLS.md, searches `docs/solutions/` and `docs/research/`. If PITFALLS already documents the failure mode → confirm + skip to Step 3. Wired file dependencies.
- **Step 1 Reproduce** (`:44-61`): hypothesis from description alone; 2-attempt limit → BLOCKING question to `.claude/questions.md`. "Do not proceed without confirmed reproduction."
- **Step 2 Bisect + STOP-AND-SURFACE rules** (`:64-88`): spawns **`@investigator`** when bug crosses a layer boundary or spans 3+ files; hard stop+surface if root cause touches auth/RLS/data-access, is ambiguous between two locations, needs a schema migration, or escapes initial search scope. These are wired escalation gates.
- **Step 3 failing test as contract** (`:90-105`): test must fail for the right reason; added to `docs/TESTING.md` under "Known gaps" with `[BUG] confirmed failing — awaiting fix via /feature`.
- **Step 4 TASK-TEMPLATE.md fill** (`:107-145`): full template incl. ROOT CAUSE with file:line, OPEN QUESTIONS (surface, don't resolve), and **PRE-GRILL** 3-question block pre-filled by /debug.
- **Done criteria** (`:165-175`): "Fix has NOT been written — /feature owns the fix" is an explicit hand-off boundary.

**V2 disposition flag + why:** **KEEP.** The investigate→test→hand-off split is a deliberate, valuable separation (test-before-fix discipline). The wired `@investigator` spawn and the STOP-AND-SURFACE escalation gates are load-bearing and must carry forward. Re-audit any model field on the spawned investigator for Opus 4.8.

**Autonomy hook:** This is the front half of bug→reviewed-PR. A Slack/Linear bug report is the natural trigger ("/debug from this issue"). /debug produces the failing test + spec autonomously; the STOP-AND-SURFACE gates (auth/RLS/migration/ambiguous) are exactly the points where an autonomous loop should pause and summon a human before /feature continues. The TASK-TEMPLATE.md output is the machine-readable hand-off an autonomous /feature run consumes — keep that contract stable.

---

## dep-update

**FILE ABSENT.** `/Users/tanner/Dev/event-vendor/.claude/skills/dep-update/` exists as an **empty directory** with no `SKILL.md` (verified: `find ... -type f` returns nothing; dir created May 26, `total 0`). There is no skill body to ground.

**V2 disposition flag + why:** **CUT-CANDIDATE / unbuilt-stub.** This is a placeholder directory, not a skill. Either (a) it was scaffolded and never written, or (b) it is dead. Under the charter, dependency updates are a real autonomy target (a cloud-scheduled "/dep-update" that opens reviewed PRs for safe bumps is genuinely world-class). Recommendation: treat as a **NEW-build slot**, not a carry-forward — there is no embedded mechanism to preserve, only an intent signaled by the directory name. Flag to the build plan: design dep-update as an autonomous, /schedule-driven flow (changelog read → safe-bump classification → /cr → PR) rather than resurrecting an empty stub.

**Autonomy hook:** High-value if built: cloud-scheduled weekly dependency sweep, gated by /cr, opening reviewed PRs for non-breaking bumps and summoning a human for majors. Pairs with the project rule "NEVER install a dependency without asking" — so the human-confirm gate is mandatory and already a project norm.

---

## design

**Actual job (plain English):** Two-mode system-design front door. `explore` produces 2–3 options-with-tradeoffs when the design is unknown; `contract` formalizes a known design into a handoff document (the input to /grill-with-docs and /feature). For Medium+ tasks it also drives decomposition into shippable, parallelizable slices.

**Embedded mechanisms that must carry forward:**
- **Upstream-skill dependency banner** (`:14-18`): hard external dependency — `/grill-with-docs`, `/tdd`, `/to-issues` are Matt Pocock's skills, installed via `npx skills@latest add mattpocock/skills`; pointer to `.claude/INDEX.md → Required global skills`. This cross-repo dependency is load-bearing and easily lost in V2.
- **Mode router + size policy** (`:20-29`): Tiny → skip both; Small+ → contract mandatory; explore optional-when-uncertain; "for any task where agents will implement: run contract before handing off."
- **Explore prompt** (`:49-64`): a fillable contract — layer ownership, public interface, patterns followed/broken, tradeoffs, "what does this make harder in 6 months." "If agent produces one option: ask for two alternatives" (`:73`).
- **Contract four-questions** (`:93-129`): Business need / Interface / Constraints / State ownership, each with project-specific hooks (teamId scoping, Supabase RLS). **Simplicity check** ("dumbest version that would still work?" + "what breaks for Monica if we leave that out?").
- **Handoff document format** (`:133-161`): the canonical TASK-TEMPLATE contract — What&Why, Context (name files so agent doesn't recreate), Done Looks Like (checkable), Interface Contract (inputs/outputs/constraints/state), Out of Scope, Relevant Files. The "Critical sections — do not skip" block (`:163-176`) names Interface Contract / Out of Scope / Done Looks Like as non-negotiable.
- **Decomposition logic** (`:184-194`): tracer-bullet first (slice touching all layers), dependency map, parallel-vs-sequential labeling (worktrees), independent-shippability check; "run /to-issues then apply this reorder."

**V2 disposition flag + why:** **KEEP**, with a **CHANGE-DELIVERY** flag on the external-dependency banner. Under the charter (distribution = plugin+marketplace + thin /init template), the dependency on Matt Pocock's `/grill-with-docs`, `/tdd`, `/to-issues` must be made explicit in the marketplace manifest / /init template or vendored — otherwise a fresh install of V2 has a dangling skill graph. The four-questions contract and the handoff-document format are golden-template-class and must survive verbatim as the cross-skill interchange format (debug, behavior-change, feature all hand off via TASK-TEMPLATE).

**Autonomy hook:** `explore` is a fan-out-friendly research step (multiple option-agents in parallel). For autonomous flows, /design contract is the machine-readable spec an agent generates and then a human approves before /feature — the natural human checkpoint in a Linear-summoned build. The decomposition step (parallel slices in worktrees) is exactly the fleet-scale primitive the charter targets: one /design contract → N parallel worktree agents.

---

## dev

**Actual job (plain English):** The single-task end-to-end orchestrator: Phase 0 scope check → Phase 1 write-failing-tests → Phase 2 implement → Phase 3 /cr review+auto-fix → Phase 4 doc update → Phase 5 tsc+commit. It is the "do the whole TDD loop for one task" driver, and it delegates review to /cr.

**Embedded mechanisms that must carry forward:**
- **Phase 0 scope gate** (`:20-31`): reads CLAUDE.md + AGENTS.md for MVP scope; lists pure functions to write; stops on open-decision touch; stops on ambiguity (one question); **stops on new npm package** (name, downloads, publish date, ships-types). Wired project guardrails.
- **Phase 1 Test-Writer sub-agent** (`:34-55`): exact framing — Vitest, colocated, happy + ≥2 edge cases per function, **real Supabase for src/data/ (never mock the DB)**, no snapshots, zero implementation. Then runs `npx vitest run` and *confirms tests fail* — "if they pass before implementation, something is wrong."
- **Phase 2 Implementation-Writer sub-agent** (`:58-81`): exact framing carrying the full TS/Zod/layer discipline (no any, no as-without-narrowing, z.infer derivation, named-interface props, logic out of components, Supabase only in src/data/, named exports). Retry loop until green.
- **Phase 3 wired /cr invocation** (`:84-94`): "Invoke the `/cr` skill and follow its instructions exactly," diff = `git diff HEAD`; re-run vitest after auto-fixes.
- **Phase 4 Doc-Updater sub-agent** (`:96-116`): CLAUDE.md / AGENTS.md / docs/design tokens+components; edit-in-place, terse, explicit-negative.
- **Phase 5 tsc + conventional commit** (`:118-130`).

**V2 disposition flag + why:** **KEEP** — but flag for **re-audit of the sub-agent framings on Opus 4.8**. The three spawned agents (test-writer, implementation-writer, doc-updater) carry exact prompt framings that encode the project's discipline; these are load-bearing and must carry forward, but the model assignment (currently generic "Agent sub-agent") should be set deliberately for 4.8. MERGE note: /dev and /feature overlap heavily; V2 should decide which is the canonical single-task driver rather than maintaining two near-duplicate orchestrators (clarity, but also non-duplication). Do NOT cut the embedded sub-agent framings when consolidating.

**Autonomy hook:** /dev is the natural "do this whole task autonomously" entry point for a Linear-summoned or bug→PR flow: it self-contains scope-check → TDD → review → doc → commit. Cloud /schedule can run /dev against a committed task spec with laptop closed. The Phase 0 stops (open decision, ambiguity, new package) are the human-summon points; everything between them runs unattended.

---

## evaluate-solution

**Actual job (plain English):** Build-vs-buy analysis. Researches a third-party option (pricing pages, GitHub health, changelog) and produces a *single named recommendation* with financial cost at current and 10x scale — never "it depends." Spawns `@solution-evaluator`.

**Embedded mechanisms that must carry forward:**
- **`@solution-evaluator` sub-agent** (`:166`): the wired research agent.
- **Invocation routing table** (`:34-42`): wired entry from /incident (third-party finding / capability gap), /spike (feasibility w/ external option), /feature (new capability could be a library), and direct. This is a skill-graph that must be preserved.
- **Seven required questions** (`:46-90`): Q1 fit, Q2 cost-now, Q3 cost-10x, Q4 operational cost, Q5 lock-in, Q6 build-cost, Q7 community health. "A recommendation without all seven is incomplete." Q2/Q3 financial cost is explicitly non-optional.
- **Output document contract** (`:93-131`): writes `.claude/solution-eval-[slug].md` with a fixed structure incl. Re-evaluation triggers and **Sources** (pricing URL + date checked).
- **Recommendation format** (`:133-142`): always a single sentence with a named choice; explicit ban on "here are the tradeoffs, it depends."
- **Autonomy model** (`:144-156`): clear recommendation → present with reasoning; genuinely close → present both, name a lean, ask the one tie-breaking question; human makes final call.
- **After-the-evaluation flow** (`:158-167`): doc travels as REFERENCES into /design contract, /feature, /spike; stored at `docs/research/[topic].md` with **30-day stale signal**.
- **Human-steps-required table** (`:172-185`): explicitly flags gated pricing, internal usage metrics, private repos, vendor SLA as human inputs; recommendation marked **INCOMPLETE** without Q2/Q3 data.

**V2 disposition flag + why:** **KEEP.** This is a clean, well-bounded decision skill with a strong anti-wishy-washy discipline. Re-audit `@solution-evaluator` model on Opus 4.8 (research + costing reasoning benefits from the strongest model). The seven-question contract and the routing table are load-bearing and easily summarized away to "does build-vs-buy" — preserve both. The 30-day stale-signal and Sources-with-date mechanism are the rigor the charter demands; keep them.

**Autonomy hook:** Re-run trigger ("re-evaluate when scale/pricing changes") is a natural cloud-/schedule job: periodically re-check pinned solution-eval docs against current pricing/GitHub health and flag staleness. In a bug→PR / capability-gap flow, /incident or /feature auto-routes here before committing to a build. The Human-steps table defines exactly where an autonomous run must pause for a human (gated pricing, internal metrics) — keep those as Slack/Linear asks.

---

## CARRY-FORWARD ALERTS — embedded mechanisms this batch is most at risk of dropping

1. **behavior-change → Phase 3 Test Inversion** (OUTDATED/VALID/COVERAGE-GAP/UNAFFECTED classifier). Exists in no other skill; the single most likely thing to vanish if behavior-change is summarized as "does a behavior change." Golden-exemplar-class.
2. **cr → `.cr-ok` sentinel (`branch:sha`, absolute path) + RECURRING-FINDINGS.md ledger + `@reviewer` 4-lens fan-out + hook-file escape hatch.** Four distinct wired mechanisms inside one skill; the sentinel is consumed by the pre-push hook and `scripts/pr.sh` — drop it and autonomous PR-opening breaks. The 4-lens fan-out is the literal parallel to the "golden exemplars" warning.
3. **compound → Step 7 permission-log→allowlist loop + Step 2 `docs/solutions/TEMPLATE.md` fill + Step 8 canonical-record sync + "86% audit" retrospective.** The self-improving-fleet machinery; Step 8 needs re-pointing to GitHub canon, not deletion.
4. **cr-security → Pass 3 wired `/supabase` invocation + the 9-item Supabase checklist + every-finding-is-MUST-FIX discipline.** The skill→skill chain and the no-suggestion-tier rule are the load-bearing parts; easy to flatten into a generic "security review."
5. **design → external-dependency banner (`mattpocock/skills`: grill-with-docs, tdd, to-issues) + the TASK-TEMPLATE handoff format + decomposition (tracer-bullet, parallel-slice) logic.** The cross-repo skill dependency is invisible in a summary and will produce a dangling skill graph in a fresh V2 install. The handoff format is the interchange contract shared by debug/behavior-change/feature.
6. **debug → `@investigator` spawn + STOP-AND-SURFACE escalation gates (auth/RLS/migration/ambiguous/scope-escape) + `[BUG]` TESTING.md entry + "fix NOT written, /feature owns it" boundary.** The escalation gates are the autonomy-safety checkpoints.
7. **dev → the three exact sub-agent framings (test-writer / implementation-writer / doc-updater)** which encode the project's full TS/Zod/layer/TDD discipline. If /dev and /feature are merged, these framings must not be lost in the consolidation.
8. **evaluate-solution → `@solution-evaluator` + seven-question contract + Human-steps-required table + 30-day stale signal.** The routing table (who invokes it) and the human-input boundary are the parts a summary drops.
9. **dep-update → NOTHING TO CARRY (empty stub).** Risk here is the inverse: V2 might "preserve" a skill that does not exist. Flag it as a NEW-build autonomy slot, not a carry-forward.
