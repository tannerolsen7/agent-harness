# V2 Harness — STATUS & HANDOFF (resume point)

> **⚠️ PIVOT (2026-06-11, late session). READ `NEW-CHARTER-AND-SUCCESS-CRITERIA.md` FIRST.** Tanner judged
> the Phase 0–6 synthesis **too conservative** (37 world-class sources → only 6 wiring-tweaks). The
> anti-ambition charter ("fewer files = red flag / simple & boring / minimize footprint / defer everything")
> is **RETIRED**. New charter: world-class is the only goal; autonomy (bug→PR, Slack/Linear) is first-class;
> clarity beats minimalism; scale test = world-class not solo; keep the rigor (doer≠checker, cite, no
> phantoms). Resolved decisions (D1–D5, Supabase-out, notion-sync-out, GitHub-as-canon, `/schedule`-is-cloud,
> commands→skills, golden-exemplars carried, Notion→GitHub migration) + the deliverable success criteria + the
> ambition re-mine to run are ALL in `NEW-CHARTER-AND-SUCCESS-CRITERIA.md`. The §B "6 MOVES" below are the
> *old, conservative* spine — the ambition re-mine replaces them. Everything else (ground-truth map, passes,
> mechanics, rigor) is kept.


**Last updated:** 2026-06-11. Phases 0–6 DONE. **The deliverable is assembled: `DECISION-PACKAGE.md`** (at
the v2-audit root). No harness code has been changed — this was research + design. Remaining: Tanner reads
the package, answers the 5 decisions (D1–D5), and a future session executes the migration first-slice.

## Phases 4–6 DONE
- **Phase 4 (distribution)** `design/phase45/distribution.md` + CHECK + `phase45/RECONCILIATION.md` —
  two-vehicle split (plugin+marketplace for mechanism / thin template for project-owned), forced seam
  (plugin can't carry permissions — verified vs live vercel 0.43.0 = 27-byte settings). NO blockers.
- **Phase 5 (compounding loop)** `design/phase45/compounding-loop.md` + CHECK — wire the Phase-3
  write-back/read-path; build the genuinely-new `/cr` recall harness (adversarial golden set, deterministic
  scorer, never self-certify, R-5 freshness). NO blockers; one budget-(1) fix (`disable-model-invocation`).
- **Phase 6 (lens panel + reviewer)** `design/phase6/lens-*.md` (5 lenses) +
  `design/phase6/REVIEWER-CONSOLIDATION.md` — all 5 verdicts CONCERNS (none SERIOUS, no redesign). The
  anti-duplication gate PASSED. Lenses caught: the rule-shards budget-misbooking (a real error in my §A —
  now FIXED in phase3/RECONCILIATION §A), two MUST-FIX build-order hazards (guard-file Stop-hook deadlock;
  PITFALLS-deletion triangle), and sharpened the Stop-hook capability risk (D4). Reviewer-resolvable fixes
  applied; 5 genuine Tanner decisions surfaced. (The reviewer agent hit the session limit; consolidation +
  package authored by the main loop from the persisted lens files — the planned-for harvest-from-disk path.)

## Phase 3 DONE (design) — `design/phase3/`
Memory model + enforcement sort + target file tree, each adversarially checked (doer≠checker). All three
verdicts **SOUND-WITH-CORRECTIONS**. **Read `design/phase3/RECONCILIATION.md` first** — it is the
authoritative corrected Phase-3 conclusion; the three drafts + their CHECK files are the audit trail.
- `phase3/memory-model.md` (+ `CHECK-memory-model.md`): 6 stores → 3 owned (S1 `.claude/rules/`+CLAUDE.md
  floor / S2 `docs/solutions/` / S3 `docs/RECURRING-FINDINGS.md` airlock) + 1 ridden auto-memory cache;
  entry-as-atom (`tier:`/`kind:`) dissolves the PITFALLS/memory dual-assignment; promotion gate (S3→S1)
  + decay clocks in one drift CI. Corrections: auto-memory→S1 graduation is a NET-NEW `/compound` step
  (not a retarget); cut the smuggled `/note` skill; shard only where a clean `paths:` glob exists (8→~5–6);
  `00-safety.md` must absorb memory.md's richer safety text VERBATIM before deletion.
- `phase3/enforcement-sort.md` (+ CHECK): 118 rules → ~64 relocated to L1/L2/CI onto 7 mechanisms; keep-
  verbatim floor intact. Corrections: R2 is a phantom (`ban-ts-comment` already errors → keep); warn-level
  ESLint isn't L1 (need `--max-warnings 0`); sharpen `.cr-ok`→CI (CI re-runs the deterministic `/cr` subset
  so the model can't forge the record).
- `phase3/target-file-tree.md` (+ CHECK): the honest one — knowledge files net ≈ −2/−3, total tracked ≈
  flat; RED FLAG does NOT fire. §9 survivor pass on all 26 skills + 23 agents (only cut: empty dep-update).
- **THE convergent meta-finding (RECONCILIATION §A):** "fewer files" splits into TWO budgets — (1)
  agent-context/advisory-prose (minimize hard) and (2) out-of-band deterministic enforcement (grows, §9-
  gated). Total files ≈ flat; advisory-prose + copies-per-fact (3→1) + per-task token cost fall sharply.
  Report BOTH budgets downstream; never present a store-count win as a file-count win.
- **8 consolidated open decisions** for the brief in RECONCILIATION §F (ADR disposition is the biggest).

## Where we are
- **Phase 0 DONE** → `CANONICAL-HARNESS-AS-IS.md` (3-layer ground-truth map; independently checked —
  the checker caught 4 stale absence-claims, all corrected; see its §0 Correction log). Supporting:
  `A2-canonical/cluster-A..E.md` (canon extracts) + `A2-canonical/CHECK-canonical-map.md`.
- **Phase 1 DONE** → `research-registry.md` (50 Notion pages dispositioned; 37 primary 3-passed).
- **Phase 2 DONE** → 37 articles × 3 passes in `passes/<slug>/pass1|2|3 .md` (+ probe CHECK). Aggregated
  into `design/cluster-findings-1..4.md` → **`design/MASTER-FINDINGS.md`** (the key file: ~30 cited gaps
  collapsed onto **6 consolidating MOVES**, anti-phantom list §E, reject list §F, gated/deferred §C,
  bounded checks §G, decision forks §H).
- **Adversarial gate DONE** → `design/CHECK-master-findings.md` — verdict **SOUND-WITH-CORRECTIONS**, no
  phantoms; 4 corrections applied to MASTER-FINDINGS (autoMode citation, restore errors-into-context,
  downgrade bug-fix-TDD, label fix). Notable: `session-end.sh` was *deliberately removed* (#70) because
  its output was discarded — strengthens MOVE 1.
- **Capability facts DONE** → `design/capability-facts.md` (hooks, frontmatter schema, settings
  precedence + managed-settings, CLAUDE.md limits, **plugin/marketplace distribution**).
- **Canon-locked decisions captured** → `design/canon-locked-decisions.md` (GitHub Publishing locked
  plan; Three-Layer Enforcement Model). Backlog page IDs → `design/design-inputs-backlog.md`.
- **Running insight log** → `passes/_EMERGING-FINDINGS.md`.

## The 6 consolidating MOVES (the V2 design spine — detail in MASTER-FINDINGS §B)
1. **One Stop/PostToolUse hook surface** (verification gate, memory write-back, retry-ceiling, render-
   check, errors-into-context) — one surface, many emitters. (Hooks CAN run tests + block-on-red; CANNOT
   compel a screenshot — verify Stop force-continue empirically.)
2. **Relocate enforcement to deterministic layers** (Three-Layer model): L1 hooks (`block-dangerous-bash.sh`,
   `/cr-security` path-classifier, autoMode→local/managed, egress), L2 dependency-cruiser arch-tests in
   CI (layer boundaries), L3 judgment. **Relocate the forgeable `.cr-ok` to CI** (MUST-FIX=0 AND CI-green
   on sentinel SHA).
3. **Unify the memory model** — one writer/reader/freshness per store; account for the 6th store (auto-
   memory); collapse triple-duplication in tooling not prose; add the drift/decay detector; situational
   (not phrase-keyed) skill descriptions; tier by trigger-existence via native `.claude/rules/`+`paths`.
4. **Run the §9 Model Capacity re-audit on Opus 4.8** — the DELETION ENGINE: "name a failure mode or it's
   overhead." This is what makes V2 *smaller*. Honor the §9 keep-verbatim floor.
5. **Make the harness installable** — converge canon↔disk FIRST, then ship as **plugin+marketplace**
   (Tanner's nudge; capability-confirmed: ships hooks/skills/agents, version-pinned, `/plugin update`)
   and/or template repo for project-owned files. Versioned-copy-with-lock, never symlink-live.
6. **Close the compounding loop** — write-back (MOVE 1) + read-path (RECURRING-FINDINGS→task-start) +
   measurement (a `/cr` golden-set/recall harness; `@benchmark-runner` is a phantom). Wired into MOVES 1&3.

## Decision-brief forks so far (MASTER-FINDINGS §H — sharpen in Phase 6)
1. **Distribution vehicle: plugin+marketplace (recommended) vs. template repo** — folds in pull-update.
2. **Is the autonomous trigger front-door in V2 scope?** (gates `/goal`, scheduler, bug→PR).
3. **How aggressively does MOVE 4 cut?** (§9 keep-verbatim is the floor).
4. **The memory model shape (MOVE 3)** — biggest single design decision.
5. **Eval/measurement now or after installs (MOVE 6)?**

## Binding constraints (do not violate)
- No proposal survives without a citation (map row or confirmed absence). Anti-phantom list = MASTER-
  FINDINGS §E. Audit artifacts ROT — re-verify any absence-claim on disk before relying on it.
- Harness is global/multi-project; canonical = Notion + global ~/.claude. Empower the model; keep code/
  data safe; simple & boring is a feature; **V2 with MORE files/mechanisms than V1 is a red flag.**
- Doer≠checker continuous; depth over speed; research-when-in-doubt; honest assessment, no flattery.
- Note: the global `~/.claude` is nearly empty (no global CLAUDE.md); the rich harness lives ONLY in
  event-vendor; recyclops has none. "Multi-project" is currently aspirational — that's the V2 thesis.

## NEXT (Phases 4–6 + assembly) — concrete tasks
1. **Phase 4 — distribution + bidirectional self-update.** Plugin+marketplace (recommended; ships
   hooks/skills/agents, version-pinned `/plugin update` = the pull path) vs. GitHub template repo; the
   plugin-vs-project-owned split (file-tree §7 sketched it); push-back-up wired to the compounding loop.
   Converge canon↔disk FIRST (canon's locked sequence). Honor capability-facts: a plugin's settings.json
   carries only `agent`+`subagentStatusLine`; permissions stay project/managed.
2. **Phase 5 — the single compounding loop.** Write-back (MOVE 1 Stop emitter → S3) + read-path
   (S3/S1 task-start reads) are mostly designed in the memory model; the GENUINELY-NEW half is
   **measurement** — a `/cr` golden-set/recall harness (triage calibration, never self-certify; seed with
   adversarial/known-defective diffs; `@benchmark-runner` is a phantom). Wire into MOVES 1 & 3.
3. **Phase 6 — lens panel + reviewer.** Staff-engineer lens agents + a `/cr`-style reviewer over
   everything; **anti-duplication gate MANDATORY** (check every surviving item against CANONICAL map §E/§F);
   reviewer fixes what's fixable, returns ONLY genuinely-Tanner's decisions.
4. **Assemble the decision package:** (1) decision brief ~4–8 forks (RECONCILIATION §F + MASTER-FINDINGS
   §H), (2) the V2 design at teachable depth, (3) rejected list (§F), (4) proof-of-process linked.
   Use subagents + doer≠checker throughout. Persist every artifact under `docs/research/v2-audit/`.

## Watch-outs
- Account **session limit** can interrupt big workflows (resets ~3:20am Denver). The Phase-2 full run hit
  it after 71 agents/2M tokens but the doer FILES persisted — harvest from disk, not just workflow returns.
- Per-article CHECK.md files were NOT all generated (budget); the doer≠checker gate was moved to the
  aggregation level (CHECK-master-findings.md) — a documented, deliberate adaptation.
- Notion MCP works from background workflow agents (proven). Ground-truth map path:
  `docs/research/v2-audit/CANONICAL-HARNESS-AS-IS.md`.
