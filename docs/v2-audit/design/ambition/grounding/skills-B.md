# Grounding Pass — Skills Batch B

Read in full (not from summaries): `explain`, `feature`, `hotfix`, `incident`, `migrate`, `notion-sync`, `perf`, `post-mortem`, `prioritize-tasks`. All nine files present and non-empty.

The recurring risk in this batch: these skills are **gate-and-artifact machines**, not prose. Their value is in the wired contracts (TASKS.md entry shapes, baseline files, triage docs, sentinel-file handoffs, sub-agent spawns, frontmatter routing). A V2 redesign that keeps the "philosophy" and drops the artifact templates keeps nothing — the artifact IS the mechanism. `incident` and `hotfix` in particular form a state machine where the document literally travels between skills.

---

## explain

- **Actual job:** Produces a teaching brief about the current uncommitted diff for a developer building a React mental model (what was built, React concepts, decisions/tradeoffs, what would break, one staff-engineer test question). It explicitly does NOT review for quality — that's `/cr`'s lane.
- **Embedded mechanisms that must carry forward:**
  - **Diff-gathering fallback chain** (`explain/SKILL.md:18-21`): `git diff HEAD`, fall back to `git diff HEAD~1` if clean, stop if no meaningful diff. This is a wired precondition, not prose.
  - **Spawns a sub-agent with a pinned model** (`explain/SKILL.md:27`): "Spawn an Agent sub-agent with **model: sonnet**." The entire teaching framing is the sub-agent prompt (`:33-68`). This is a load-bearing model pin that MUST be re-audited on Opus 4.8 — the teaching-quality reasoning may warrant Opus now, and the cost calculus that put it on Sonnet was a 4.6-era decision.
  - **Five fixed output headings** (`:74-75`) the final brief must use — a structural contract, not a suggestion.
- **V2 disposition flag:** **KEEP** (re-audit model field). Tightly scoped, single-purpose, earns its place under "clarity over minimalism." The only V2 change is the `model: sonnet` pin — on Opus 4.8 a learning brief for a developer leveling up is exactly where the better model pays off; don't let the old cost-driven Sonnet pin survive unexamined.
- **Autonomy hook:** Strong fit. A bug→PR or scheduled flow can append an `explain` brief to every PR it opens as a "what this teaches" section for human review — turns autonomous PRs into teaching moments. Could be a cloud-scheduled post-merge step that DMs the brief to Slack.

---

## feature

- **Actual job:** The master orchestration pipeline for net-new work. Sizes a feature (Tiny/Small/Medium/Large) and runs a size-appropriate sequence of OTHER skills (`/design`, `/grill-with-docs`, `/tdd`, `/simplify`, `/cr`, `/to-issues`, `/compound`) with hard human-approval gates between phases.
- **Embedded mechanisms that must carry forward:**
  - **The size→pipeline table** (`feature/SKILL.md:49-54`) — the core routing logic. Each tier names an exact ordered skill sequence. This is the spine; dropping it reduces the skill to vibes.
  - **Mandatory contract-before-spawn rule** (`:56-58`): "fill a contract for each sub-agent this feature will spawn. Use `.claude/agent-contract.md` as the template. A contract must exist before a sub-agent is invoked — never spawn without one." This is a wired hard gate referencing a real template file.
  - **Hard STOP gate at `/to-issues`** (`:111`): "STOP. Do not proceed to Step 9 until the user has confirmed the issue list." Plus the explicit rule that a human asking "did you use /to-issues?" mid-flow IS the instruction to stop — encoded as anti-rationalization (`:41`).
  - **Spec-file gate for Medium+** (`:105`): create `docs/specs/[task-slug].md`, set `human-approved: false`, do not proceed to `/design` until `human-approved: true`. Frontmatter-driven state gate.
  - **Files it reads/writes as contract:** `docs/TESTING.md` (confirmed behaviors before code), `docs/research/[topic].md` (research gap check), `docs/solutions/`, `docs/specs/`, `.claude/agent-contract.md`, `TASK-TEMPLATE.md`, `AGENTS.md` open decisions, `PITFALLS.md` (footgun proposal in done-criteria, `:163`).
  - **Compound questions block** (`:92-94`, `:119`): three fixed introspection questions asked of the implementing agent post-build. A wired self-review mechanism.
  - **Upstream-dependency declaration** (`:12-15`): depends on Matt Pocock's `/grill-with-docs`, `/tdd`, `/to-issues`, `/simplify` (external repo). V2 must preserve this dependency graph or vendor those skills.
  - **Parallel-spawn directive** (`:112`): identify independent issues and spawn sub-agents simultaneously — explicit anti-sequential instruction. This is the fleet-parallelism hook already wired in.
- **V2 disposition flag:** **KEEP** — this is the keystone. Under the new charter, this is where autonomy gets designed in. The parallel-spawn rule (`:112`) is already a fleet primitive. The risk is V2 summarizing the size table into prose — preserve it verbatim as a table. The Matt-Pocock external dependency should be resolved (vendor or plugin-bundle) so the pipeline is self-contained for distribution.
- **Autonomy hook:** This is the primary autonomy surface. A Linear/Slack-summoned "build X" can enter here, auto-size, and run Tiny/Small tiers end-to-end with the `/cr` + sentinel gates providing the safety rail. Large tier already fans out via `/to-issues` → parallel `/feature` per issue — the fleet model. Cloud `/schedule` can run the whole pipeline laptop-closed since every step is a committed skill.

---

## hotfix

- **Actual job:** Production-is-broken response with a mandatory triage gate that picks ONE of two modes (mitigation-only vs full-fix) before any code, then runs blast-radius analysis and a failing-test-first fix loop. It is a fix discipline, not a speed pass.
- **Embedded mechanisms that must carry forward:**
  - **Entry-condition guard** (`hotfix/SKILL.md:51-71`): you may NOT enter `/hotfix` directly — `/incident` must classify as `our-code-narrow`/`our-code-structural` first, OR `/debug` confirmed root cause this session. This wires hotfix as a downstream node of `incident`.
  - **Triage-gate document** (`:108-122`): a fixed-shape fill-in form (root cause, impact, code-reversible Y/N, smallest change, hotfix-sized Y/N, MODE selection, reason). Human confirms before anything proceeds. Mode is a load-bearing branch.
  - **Mitigation-options document** (`:134-148`): 2–3 named options each with "stops bleeding / ships in / leaves broken / throwaway." Cannot be silently skipped even when only one option exists (`:150-153`).
  - **TASKS.md entry templates** (`:162-186`) — exact `[~]` blocked-task shapes, differing by mode. Full-fix writes one `[hotfix-postmortem]`; mitigation-only writes `[hotfix-correction]` + `[hotfix-postmortem]`, with the post-mortem blocked on the *correction* merge, not the mitigation. This is precise wired state.
  - **Blast-radius report** (`:217-227`): spawns `@reviewer` running two named lenses (Impact, Cascade) producing a fixed-field report with a Safe/Proceed-with-risk/Stop verdict. A "Stop" verdict auto-demotes full-fix → mitigation-only.
  - **@hotfix-guard sub-agent** (`:270-280`): three pass/fail gates (required TASKS.md entries exist, failing test exists, scope not exceeded) before merge. "No partial passes." Points to `Templates → agents/hotfix-guard.md`.
  - **Failing-test-first protocol** (`:256-261`): confirm red before fix; if it passes before the fix, the test is wrong.
  - **Scope-creep stop** (`:264-266`): if the correct fix needs more than declared scope, write BLOCKING to `questions.md` and stop.
  - **Output files:** `.claude/hotfix-scope-[slug].md`, `TASKS.md`, `questions.md`.
- **V2 disposition flag:** **KEEP** — and it's a primary autonomy candidate (see below). Spawns `@reviewer` and `@hotfix-guard`: both agent `model:` fields must be re-audited on Opus 4.8 (blast-radius reasoning is exactly the high-stakes judgment Opus 4.8 improves). The `@hotfix-guard` agent body lives in Templates, not inline — V2 must carry that referenced file forward or it's a dangling spawn.
- **Autonomy hook:** This is the canonical bug→reviewed-PR path. An `incident`-classified `our-code-narrow` can flow straight to autonomous hotfix: triage doc auto-filled, mitigation chosen, failing test + fix, `@hotfix-guard` gates, PR opened for human review. The guard agent IS the autonomy safety rail. Should be summon-able from Slack/Linear ("prod is down on X") via `/incident` front door.

---

## incident

- **Actual job:** The classify-first front door for ALL "something is wrong" reports. Reproduces, gathers evidence across 6 checks, assigns one of 8 incident types with a confidence level, writes a triage doc, and routes to the correct downstream skill. No code is written here.
- **Embedded mechanisms that must carry forward:**
  - **8-type classification table → route map** (`incident/SKILL.md:26-36`): each type maps to a named route (`/migrate`, `/debug`→`/hotfix`, `/evaluate-solution`, `/feature`, communication draft, config correction, security path). This is the routing brain for the whole incident subsystem.
  - **Phase 0 reproduce gate** (`:85-117`): three outcomes (reproduced / not-reproducible-after-2-attempts → STOP / intermittent → proceed at Low confidence). Non-reproducible is a hard stop, not a soft warning.
  - **6 evidence checks** (`:120-167`): behavior-vs-spec (reads `TESTING.md`/`CONTEXT.md`), recent changes (git log 7d), dependency health (package.json + changelog), data-state (produces a query, does NOT execute unless `incident-db-query-enabled: true`), security signals (auto-flags regardless of other evidence), and **PITFALLS.md match** (`:163-166` — reads PITFALLS, short-circuits to classification on a hit).
  - **Triage document template** (`:189-243`): the full `.claude/incident-[slug].md` shape including a "Human steps required" section with paste-back instructions. This doc is the unit of handoff.
  - **Route-handoff protocol** (`:269-287`): "the triage document travels with it. The receiving skill reads it at entry — it is the context that replaces the normal orient step." Table maps each route to what consumes the doc. This is the cross-skill state-passing wire.
  - **Spawns `@incident-responder`** (`:285`) — agent `model:` to re-audit on Opus 4.8 (classification under uncertainty is high-value reasoning).
  - **Capability flags** (`:150-152`, `:310-322`): `incident-db-query-enabled`, `incident-log-access-enabled`, `incident-monitoring-mcp` — gate agent autonomy on evidence gathering. **Critically noted as currently inert** (`:319-322`): Claude Code's settings.json schema rejects these unknown top-level keys, so they're documentation-only and the skill always prompts the human. This is a real wired-but-blocked autonomy lever.
- **V2 disposition flag:** **KEEP** — keystone of the incident/hotfix/migrate subsystem; nothing downstream is safe to enter without it. Under the new charter the inert-flag problem (`:319-322`) is the headline V2 fix: with MCP-based DB/log/monitoring access (autonomy first-class), checks 4/5 become agent-executable and the "Current limitations — human steps required" table (`:296-308`) shrinks. The route-handoff doc-travel protocol is exactly the kind of mechanism prior summaries drop — preserve it explicitly.
- **Autonomy hook:** This is the front door for ALL autonomous incident response. Slack/Linear/PagerDuty alert → `/incident` auto-reproduces + gathers evidence + classifies → routes to autonomous `/hotfix` or `/migrate`. The capability flags + an observability MCP are precisely what convert this from "agent drafts queries for human" to "agent investigates and routes" laptop-closed. The security-signal isolation-only stop (`:259-261`) is the right autonomous safety boundary to keep.

---

## migrate

- **Actual job:** Safe state-mutation (schema/data/infra/service) with mandatory pre-flight, dry-run, backup, and rollback gates. Owns ONLY the state-change PR; the expand/contract code PRs around it go through `/feature`.
- **Embedded mechanisms that must carry forward:**
  - **Migration-type table** (`migrate/SKILL.md:59-67`) and **irreversibility-tier table** (`:80-86`): schema/data/infra/service/combined × clean-revert/compensate/window/permanent. Tier=permanent requires explicit human sign-off before Phase 3 (`:87`); tier=window requires documented duration (`:88`).
  - **Entry-gate classification form** (`:124-145`) — fixed fill-in driving everything downstream.
  - **Phase 0 sequencing plan / expand-contract** (`:153-181`): names PR 1 (expand, `/feature`), PR 2 (migrate, this skill), PR 3 (contract, `/feature`) in order, with explicit ownership boundaries. This is the cross-skill orchestration wire.
  - **Phase 1 pre-flight checklist A–D** (`:185-256`): Backup (with restore commands, not "restore from backup"), Lock-safety (enumerated dangerous DDL + safe strategies), Batch-strategy (>10k rows, cursor pagination, progress tracking), Dry-run-strategy (a per-type dry-run method table, `:243-249`). Each is a fill-in form, not prose.
  - **Phase 2 rollback plan** (`:260-290`): "operationally concrete — commands, not intentions," including the mandatory "what happens at 50% completion?" question.
  - **Phase 3 dry-run hard gate** (`:294-315`): human confirms "Proceed" before Phase 4. "No silent auto-proceed."
  - **Phase 4 execution** (`:319-350`): backup taken immediately before; mid-stream failure → stop, record cursor, BLOCKING to `questions.md`.
  - **Phase 5 verification** (`:352-379`): row-count + spot-check + constraint + smoke-test, human signs off before merge.
  - **Spawns `@explorer`** (optional, callsite discovery, `:405-408`).
  - **Output file:** `.claude/migrate-[slug].md`.
- **V2 disposition flag:** **KEEP**, and **flag for `disable-model-invocation` consideration / human-gate hardening.** This is the most dangerous side-effect skill in the batch — it executes irreversible DDL/data mutations. Under the new charter autonomy is first-class, but per the PocketOS destructive-operation rules in CLAUDE.md, migrate's human sign-off gates (permanent tier, dry-run proceed, verification) are exactly the enforcement that must NOT be loosened by autonomy. V2 should consider `disable-model-invocation: true` so migrate is only ever entered deliberately (via `/incident` data-problem routing or explicit human call), never auto-triggered by the model mid-conversation. The per-type dry-run table and tier system are the load-bearing safety mechanism — never summarize away.
- **Autonomy hook:** Partial and deliberately bounded. `/incident` data-problem can route here autonomously through the dry-run gate, but the permanent-tier sign-off and the Phase 3 "Proceed" gate are intentional human stops. The right autonomy is: agent does ALL pre-flight + dry-run + writes the artifact laptop-closed, then BLOCKS for human go/no-go on execution. Cloud `/schedule` could run pre-flight for a queued migration overnight and surface it ready for one-click human approval.

---

## notion-sync

- **Actual job:** Pulls the canonical AI-native-engineering template pages from Notion and diffs them against on-disk files, applying every gap. The Notion templates are source-of-truth; the changelog is only a hint. NOTE: per the new charter's RESOLVED FACTS, **GitHub is becoming canon (Notion→GitHub migration)** — so this skill's entire premise is on the chopping block.
- **Embedded mechanisms that must carry forward:**
  - **Comprehensive-diff-over-changelog principle** (`notion-sync/SKILL.md:18-30`): diff every canonical page against disk; never trust changelog prose or "Projects that need updating" hints. The diff is the application method.
  - **MCP-only Notion access** (`:33-38`): `ToolSearch select:mcp__claude_ai_Notion__notion-fetch` first; never WebFetch a Notion URL (returns garbage for authed pages — PITFALLS § notion-pages-require-mcp). Wired tool-loading precondition.
  - **Dedicated-branch hard rule** (`:47-58`): sync never mixes with feature work.
  - **Canonical-page-lag protocol** (`:70-84`): a new changelog version does NOT guarantee canonical pages updated; on lag, apply from changelog prose, surface upstream via `/compound`, note in LAST-SYNC.md. Tri-state truth handling.
  - **The canonical page-ID table** (`:97-126`) — ~20 template→Notion-ID mappings. This is the literal wired index; without it the skill has no targets.
  - **Guard-file exception** (`:146`): gaps landing in `settings.json`/`settings.local.json`/`.claude/hooks/**` are NOT applied by the agent — staged to scratch, verified, surfaced as paste-ready NEEDS HUMAN, recorded `human-pending` in LAST-SYNC.md, kept OUT of the sync PR. This encodes the no-agent-edits-guard-files rule.
  - **LAST-SYNC.md receipt** (`:167-190`): coverage table with a fixed status enum (`in-sync`/`gaps-applied`/`created`/`lag-detected`/`not-fetched`/`human-pending`); every page must appear.
  - **Scope delimiter with `/compound`** (`:204-208`): this skill owns the sync protocol; `/compound` owns project-specific learnings discovered during a sync.
  - **Sentinel handoff** (`:225-230`): runs `/cr` → writes `.cr-ok` → `scripts/pr.sh` consumes it.
  - **Co-author trailer pinned to Sonnet 4.6** (`:218`) — stale; re-audit.
- **V2 disposition flag:** **CHANGE-DELIVERY (likely CUT or fully rewritten).** Per RESOLVED FACTS, GitHub becomes canon via the Notion→GitHub migration and distribution moves to plugin+marketplace. Once templates live in a Git-distributed plugin, "sync" becomes a package update, not a Notion-diff ritual — so the Notion-fetch machinery, the page-ID table, and the changelog-lag protocol are largely obsolete. BUT the *transferable* mechanisms must survive into whatever replaces it: the guard-file exception, the comprehensive-diff discipline, the dedicated-branch rule, the LAST-SYNC receipt pattern, and the sentinel handoff. Flag the Sonnet-4.6 co-author trailer for update.
- **Autonomy hook:** Cloud `/schedule` could run a plugin/template-update sync on a cron (the GitHub-canon version), opening a `chore(system)` PR automatically with the guard-file exception protecting hooks/settings. Today's Notion-MCP version is harder to autonomize (auth, WAF blocks on security content per memory) — another reason the GitHub-canon rewrite is the right V2 move.

---

## perf

- **Actual job:** Optimize a measured bottleneck without changing behavior, gated on a committed before/after baseline artifact and a named numeric target. Ships only when the after-number hits the target.
- **Embedded mechanisms that must carry forward:**
  - **The three enforced invariants** (`perf/SKILL.md:22-37`): committed baseline artifact before any optimization code; a numeric target defined before starting; before/after comparison as the merge gate. These are the skill's reason to exist.
  - **Baseline-file template** (`:178-198`) `.claude/perf-baseline-[slug].md` with before AND after blocks, and the assertion `Optimization code exists: [ ] no (must be false when this file is committed)`. The baseline must be its own commit (`:200-206`): `perf(baseline): [slug] — before: [metric]`, no optimization code in it.
  - **Execution-context table** (`:69-76`): script/server-function/db-query/ui-component/data-pipeline, each with measurement tools + behavior-verification contract. Drives Phase 1 method.
  - **Per-context measurement-method table** (`:159-170`) — exact commands per context (`EXPLAIN ANALYZE`, React DevTools, `k6`, `tracemalloc`, etc.).
  - **Phase 2 behavior-lock** (`:209-241`): test suite green + characterization tests written if the hot path is uncovered, before any optimization. "No test was deleted to make the suite green" (`:339-341`).
  - **Scope rule** (`:265-270`): a second bottleneck found mid-optimization goes to `.claude/backlog-[slug].md`, not into this PR.
  - **Noise guard** (`:322-326`): <5% delta with high variance → run 5× and report range, don't claim improvement.
  - **Phase 4 same-method rule** (`:296-300`): after-measurement must use the identical method or the comparison is invalid.
  - **Future `@benchmark-runner` agent** (`:172-176`, `:374-381`): explicitly designed-but-unbuilt agent to own Phase 1/4 measurement once CI/MCP benchmark tooling is wired. Currently human-run.
  - **Spawns `@explorer`** (optional, hot-path tracing across 3+ files).
- **V2 disposition flag:** **KEEP** — single-purpose, strict, high-value. Under the new charter, the designed-but-unbuilt `@benchmark-runner` (`:374-381`) should be BUILT, not deferred — autonomy-first means wiring measurement into CI/MCP so the agent runs Phase 1/4 itself rather than pasting human output. That's the difference between a phantom future-note and a real autonomy upgrade. Baseline-artifact and same-method discipline must never be summarized away — they're the whole point.
- **Autonomy hook:** A scheduled/cloud flow can run perf regression detection: cron a benchmark, and on a budget breach auto-enter `/perf` with the baseline pre-filled by `@benchmark-runner`, optimize under the green-test constraint, open a PR. The human-run measurement steps are the only blocker — exactly what the new charter says to build, not defer.

---

## post-mortem

- **Actual job:** After a hotfix merges, find the structural condition that ALLOWED the bug and produce two review candidates: a PITFALLS.md entry and a memory.md entry. Makes the bug-class impossible to repeat.
- **Embedded mechanisms that must carry forward:**
  - **Reads four sources** (`post-mortem/SKILL.md:34-41`): `TASKS.md` (the `[hotfix-postmortem]` entry — symptom/cause), `git diff main hotfix/[slug]`, `PITFALLS.md` (dedup), `memory.md` (dedup). Falls back to the merged commit if the branch is deleted.
  - **The three questions** (`:44-81`): Q1 what structural condition allowed this (NOT the bug cause), Q2 what test would have caught it BEFORE introduction (not the regression guard), Q3 what pattern/rule must change across all future work. Answered in writing before candidates.
  - **Two fixed candidate templates** (`:86-104`): PITFALLS.md entry (title/what-happened/root-condition/the-rule/test-that-would-have-caught-it/first-seen) and memory.md entry (rule/source/last_seen). These are the exact shapes written to those canon files.
  - **Human-review-before-write gate** (`:107-117`): "Nothing is written automatically." On sentinel projects `@doc-updater` writes them — same review step required.
  - **TASKS.md state transition** (`:113`): mark `[hotfix-postmortem]` → `[x]` on completion.
  - **Triggered by** the `[hotfix-postmortem]` task promotion in TASKS.md (`:129`) — the wired link back to `/hotfix`'s task entry.
  - **Spawns `@doc-updater`** on sentinel projects (`:117`, `:130`) — re-audit model field.
- **V2 disposition flag:** **KEEP** (consider MERGE-CANDIDATE with `/compound`). It's the closing node of the hotfix→post-mortem arc and feeds the two canon files (PITFALLS, memory) that `incident` Check 6 and session-start rituals depend on — a true self-improving loop. Possible MERGE: `/compound` also writes process learnings to canon; the candidate-generation + human-review-write pattern overlaps. But post-mortem's three-questions discipline and PITFALLS-specific template are distinct enough to keep separate. `@doc-updater` model field to re-audit.
- **Autonomy hook:** Strong self-improving-loop fit. After an autonomous hotfix merges, a cloud-scheduled or task-triggered `/post-mortem` can auto-draft both candidates and open a PR (or surface for review) — closing the loop so the fleet learns from every incident without a human kicking it off. This is the "self-improving loops" pillar made concrete: hotfix → post-mortem → PITFALLS/memory → feeds next incident's Check 6.

---

## prioritize-tasks

- **Actual job:** Weekly ritual that reads `TASKS.md` + `STRATEGY.md`, recommends a priority reordering aligned to the north star and product stage, flags stale/blocked/misaligned tasks and backlog candidates, and waits for human confirmation before writing.
- **Embedded mechanisms that must carry forward:**
  - **Reads `STRATEGY.md` + `TASKS.md` in full** (`prioritize-tasks/SKILL.md:11-35`); extracts stage, north star, decided constraints, out-of-scope from STRATEGY; active tasks, `[backlog]` entries, BLOCKED, last-modified from TASKS.
  - **Three evaluation axes** (`:38-54`): alignment (north star / constraint conflict / out-of-scope), staleness (30+ days), backlog (High-severity 30+ days → review).
  - **Fixed recommendation format** (`:58-79`): recommended order with per-task reasons, Flags section (STALE / BLOCKED / STRATEGY MISALIGNMENT), backlog-promote and backlog-prune candidates.
  - **Human-confirm-before-write hard rule** (`:81`, `:104`): never rewrite TASKS.md until confirmed; never prune without confirmation.
  - **Ritual bookkeeping** (`:90-99`): writes `## Last prioritized: YYYY-MM-DD` to TASKS.md top and updates `rituals.md` with `last_run`/`frequency: weekly`/notes. This is what the CLAUDE.md session-start ritual check reads to know if it's overdue >7 days.
  - **Graceful degrade** (`:107`): runs even without STRATEGY.md, flagging severity-only prioritization and recommending `/setup-strategy`.
- **V2 disposition flag:** **KEEP** (**CHANGE-DELIVERY → cloud-scheduled**). It's a weekly ritual whose whole trigger model is "human remembers, or session-start ritual check surfaces it." Under the new charter this is a textbook cloud `/schedule` cron job: run weekly laptop-closed, produce the recommendation, open it for one-click confirmation. The rituals.md `last_run` bookkeeping is the wired mechanism that makes the schedule idempotent and the overdue-check work — carry it forward.
- **Autonomy hook:** Direct cloud-`/schedule` fit. Weekly cron clones the repo, reads STRATEGY/TASKS, produces the reordering recommendation, and surfaces it (Slack/PR/issue) for human confirm — the write stays human-gated by design. This removes the "did anyone run the weekly ritual?" failure mode entirely.

---

## CARRY-FORWARD ALERTS

Embedded mechanisms in THIS batch the prior design was most at risk of dropping (the "summarized away" failure mode — like golden exemplars in the prior batch):

1. **The cross-skill document-travel protocol (incident → hotfix/migrate/feature).** `incident/SKILL.md:269-287`: the `.claude/incident-[slug].md` triage doc literally travels to the receiving skill and "replaces the normal orient step." This is a wired state-machine handoff, not prose. Lose it and incident/hotfix/migrate become disconnected skills instead of one routed subsystem.

2. **The exact TASKS.md `[~]` blocked-task entry shapes in hotfix.** `hotfix/SKILL.md:162-186`: full-fix vs mitigation-only write *different* entries, and the post-mortem blocks on the **correction** merge, not the mitigation. `@hotfix-guard` gates on these exact entries existing. A summary that says "creates a post-mortem task" silently breaks the guard and the blocked-state semantics.

3. **Sub-agent spawns + pinned `model:` fields across the batch.** `explain` (`model: sonnet`, :27), `incident` (`@incident-responder`), `hotfix` (`@reviewer`, `@hotfix-guard` — body in Templates, not inline), `migrate` (`@explorer`), `post-mortem` (`@doc-updater`), `perf` (`@explorer`, future `@benchmark-runner`). Every model pin is a 4.6-era decision that MUST be re-audited on Opus 4.8, and the referenced agent body files (esp. `agents/hotfix-guard.md`) must be carried forward or the spawns dangle.

4. **The artifact templates ARE the skills.** hotfix triage doc, mitigation-options doc, blast-radius report; migrate's pre-flight A–D + dry-run table + rollback plan; perf's baseline file (with "optimization code exists: no" assertion) + per-context measurement table; incident's 6-check evidence template; post-mortem's two candidate shapes. These fixed fill-in forms are the wired mechanism. Prior summaries reduce them to "writes a triage doc" — which loses the gate. Preserve verbatim as tables/templates.

5. **Inert-but-designed autonomy levers that the new charter should BUILD, not document.** incident's capability flags (`incident-db-query-enabled` etc., blocked by settings.json schema, `:319-322`) and perf's `@benchmark-runner` future-agent (`:374-381`). Under "autonomy first-class," these are the concrete next builds — not phantom future-notes. A V2 that copies them forward still inert has missed the charter.

6. **The guard-file exception (notion-sync) and human-write gates (post-mortem, prioritize-tasks, migrate, hotfix triage).** `notion-sync:146` keeps settings.json/hooks out of agent edits; post-mortem/prioritize-tasks/migrate never auto-write. These human-in-the-loop boundaries are the safety rails that make autonomy SAFE — under the new charter they are features to preserve precisely, not friction to remove.

7. **PITFALLS.md / memory.md as a live feedback loop, not docs.** post-mortem WRITES them; incident Check 6 READS PITFALLS to short-circuit classification; feature's done-criteria proposes PITFALLS entries; session-start rituals read memory. This is a wired self-improving loop across four skills. A V2 that treats PITFALLS/memory as static docs breaks the loop.
