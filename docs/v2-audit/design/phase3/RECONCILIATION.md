# Phase 3 — Reconciliation (doer≠checker resolved; the authoritative Phase-3 conclusion)

**What this is.** The three Phase-3 design artifacts (`memory-model.md`, `enforcement-sort.md`,
`target-file-tree.md`) were each attacked by a separate adversarial checker. All three verdicts:
**SOUND-WITH-CORRECTIONS** — no UNSOUND, no architectural rework. This file records the convergent
meta-finding, applies the checkers' corrections as the authoritative position, and carries the
deduplicated open decisions forward to the decision package. Phases 4–6 build on THIS file, not the
uncorrected drafts.

Re-verified on disk 2026-06-11 by the checkers (not taken on faith): `.claude/rules/` absent;
`@typescript-eslint/ban-ts-comment` already errors via `eslint-config-next/typescript`; `npm run lint`
exits 0 on warnings; `reviewer.md` passes full `PITFALLS.md` to each of 4 lens agents in parallel;
`/compound` does NOT read the auto-memory corpus; memory.md's safety text is richer than CLAUDE.md's;
worktrees on disk = 7 (the prompt's "8, several stale" was itself stale — disk wins).

---

## A. The convergent meta-finding (the most important Phase-3 result)

**Two of the three artifacts independently drifted into a net file/mechanism INCREASE and reported a
favorable proxy** — `memory-model.md` headlined "stores 6→3" while adding ≈+9 files; `enforcement-sort.md`
headlined "7 mechanisms absorb 64 rules" while adding +6–9 files and deleting zero. Each checker caught it
independently. The file tree (whose explicit job was "fewer files") did NOT drift — it confronted the count
honestly and its checker confirmed **the RED FLAG does not fire**.

This is not three separate bugs. It is one structural truth the binding principle's surface reading hides:

> **Enforcement-relocation and native path-scoping BOTH cost disk files. You cannot make a forgeable
> advisory rule deterministic without creating *some* deterministic artifact (a hook, a CI script, a lint
> config). Splitting a 43 KB monolith into path-scoped shards is more files by construction.**

### The resolution — count TWO budgets, not one `find | wc -l`

The binding principle ("a V2 with MORE files/mechanisms than V1 is a RED FLAG") is a heuristic against the
**V1 failure mode: accumulating advisory scaffold the model no longer needs.** It is not a law that raw
file count must monotonically fall. The honest objective splits into two budgets that move in opposite
directions and must be scored separately:

| Budget | What it is | V2 direction | Why |
|---|---|---|---|
| **(1) Agent-context / advisory-prose** | Files the agent *reads* as forgeable prose (CLAUDE.md, memory.md, the PITFALLS monolith, AGENTS architecture rules) — **AND the `.claude/rules/` shards, which are read-prose loaded via `paths:`** | **DOWN, aggressively** | This is the real V1 disease. Forgeable, attention-costing, never-decaying. |
| **(2) Out-of-band deterministic enforcement** | Hooks, CI scripts, lint/dep-cruiser configs, manifests, packaging — run *outside* the agent's context, unforgeable | **UP, only where each item names a §9 failure mode** | This is the cure: the *enforcement* (the hook/CI script) is unforgeable. The shard is the *teaching copy*; the migration-lint CI is the enforcement. |

> **[Phase-6 correction — budget-simplicity lens].** The first draft of this table misbooked the
> `.claude/rules/` shards as budget (2) "out-of-band, unforgeable." That is **wrong**: a `paths:`-scoped
> markdown rule is loaded INTO the agent's context and is exactly as forgeable as the PITFALLS prose it was
> split from — it is **budget (1)**. The shards are re-booked above. The win is still real but the
> *mechanism* is different from what the draft claimed: **budget (1) falls because the shards load 1–2 per
> task (on their path) instead of all ~574 PITFALLS lines on every code task** (and the ~172 KB/`/cr` 4-lens
> pass collapses), **NOT** because "bytes move into unforgeable enforcement." The corrected budget-(1) ledger
> still net-falls (00-safety absorbs the deleted NEVER-section + memory.md safety, so always-load is
> flat-to-down; the 6 area shards cut per-task read load; copies-per-fact 3→1). The design satisfies the
> two-budget rule on the *corrected* ledger — which is the whole point of the rule.

**Reconciled position:** V2 *minimizes budget (1) hard* (copies-per-fact 3→1; 43 KB-always-read →
~2 KB-when-relevant; ~64 rules relocated out of prose) and *accepts measured growth in budget (2)* (each
new hook/script/shard passing §9). **Total tracked files end roughly flat; the agent's advisory-prose
budget falls sharply; copies-per-fact and per-task token cost fall sharply.** That is the consolidation the
principle actually asks for. Every downstream artifact must report BOTH budgets and must never present a
budget-(1) win (store count, rules-per-mechanism) as if it were a total-file-count win.

**This is itself a decision-brief item** (D8 below): accept ~flat total file count as the price of
determinism, or hold a harder file-count line and leave more rules advisory? Recommendation: accept it —
budget (1) is what hurt V1, and budget (2)'s growth is §9-gated. But Tanner should ratify the reframe,
because it modifies how the binding principle reads for the rest of V2.

---

## B. Corrected MEMORY MODEL (deltas to the draft; model architecture stands)

The spine is correct and survives: **entry-as-atom** (tier:/kind:/freshness as per-entry properties)
dissolves the PITFALLS/memory dual-assignment in the data model; the **S3 airlock + promotion gate** is the
right "don't over-collapse" guard; **riding auto-memory + native `paths:`** instead of hand-rolling is the
correct read. Target = **3 owned stores (S1 rules+floor / S2 solutions / S3 findings-inbox) + 1 ridden
auto-memory cache.** Apply these corrections:

1. **[BLOCKER] Auto-memory graduation is a NET-NEW `/compound` capability, not a retarget.** Verified:
   `/compound` reads `.claude/memory.md` only — zero references to the `feedback_*`/`project_*` corpus.
   The draft's "the graduation conveyor already exists, we just retarget" is TRUE for curated-finding
   promotion (`/cr` 3b → S1 is real) but FALSE for auto-memory→S1. Re-label it a small net-new `/compound`
   step (walk the corpus, surface survived-2+-sessions traps as promotion candidates). Fix the
   `[compound/SKILL.md:72,83,143]` citation — those lines are PITFALLS/memory.md promotion, not auto-memory.
   It still passes §9 (the cache learns things S1 missed), but it is a build, counted in budget (2).

2. **[CORRECTION] Cut the `/note` skill — it is net-new and smuggled.** The draft refuses C's `/distill` on
   "rename the work, not the skill," then quietly introduces `/note`. Use the existing manual append path
   (a human edits `docs/RECURRING-FINDINGS.md`, or `/compound` appends) — no new skill.

3. **[CORRECTION] Shard ONLY where a clean `paths:` glob exists.** Two draft shards have no real path
   trigger (`git-worktree.md`; the cross-cutting "any skill/agent calling external tools" entry). A shard
   with no `paths:` glob does NOT native-auto-load — it is pure overhead with worse discoverability than a
   section of the always-load floor. **Rule: an area becomes a shard iff it has a clean file-path glob.**
   Path-less / operation-scoped constraints (worktree ops, destructive-op safety, the external-tool rule)
   live in the always-loaded `00-safety.md` + a small always-load "process" section, NOT in fake shards.
   This drops the shard set from 8 → ~5–6 (`00-safety` always-load; `migrations`, `data-layer`, `schemas`,
   `auth-routing`, `architecture` path-scoped; `harness-hooks` keeps its real `.claude/hooks/**,scripts/**`
   glob). Improves budget (2).

4. **[BLOCKER, from file-tree check] `00-safety.md` must absorb memory.md's RICHER safety text VERBATIM
   before memory.md is deleted.** memory.md's destructive-op entries carry the full Cursor/Railway incident
   `Why:` narrative + `How to apply:` steps that CLAUDE.md's terser version lacks. "No fact is lost" is
   false as drafted. The merge must copy the richest copy verbatim (KEEP-VERBATIM floor), and the three
   non-safety memory traps must be explicitly routed: `enforcement-boundary-layering` → `harness-hooks.md`;
   `claude-md-referenced-scripts-must-exist` → a drift-CI rule; `check-branch-before-commit` →
   the always-load process section (ex-`git-worktree`). Until the absorb target exists and is verified to
   carry the richer text, **memory.md is not deleted.**

5. **[NON-BLOCKING, surface it]** The auto-memory third-copy duplication is collapsed by ONE prose line
   ("on conflict, curated stores win") because the CC memory subsystem is not ours to hook. This is the
   model's single remaining prose-only seam (Open Decision D3). Surface it; don't bury it.

Net: the model is sound; the corrections re-label one build honestly, cut one skill, tighten the shard
rule, and protect the safety floor on deletion.

---

## C. Corrected ENFORCEMENT SORT (the relocation stands; framing + 2 facts fixed)

The sort's thesis holds: **~64 of 118 rules relocate from advisory L3 to deterministic L1/L2/CI** onto ~7
mechanisms, the keep-verbatim floor is intact, every row names a failure mode, cross-file echoes are
deduped to one home. Corrections:

1. **[BLOCKER] R2 is a phantom — reclassify `keep (already L1)`.** `@typescript-eslint/ban-ts-comment`
   already errors today (ships via `eslint-config-next/typescript`; invisible to a config-text grep but it
   fires). Proposing to "add" it is the exact V1 failure class. Move R2 beside R1; drop it from the
   L1-*relocate* count.

2. **[BLOCKER] "Fewer files" framing is false on the binding-principle axis — restate honestly.** The
   build list is **+6 to +9 net files/mechanisms; 0 files deleted** (DELETE column removes prose lines and
   dedups echoes, not files). Reframe per §A: this sort is a **budget-(1) advisory-surface reduction +
   rule-dedup**, paid for in **budget (2)** growth — the file-count reduction lives in MOVE 3/MOVE 4, not
   here. Stop letting rules-per-mechanism stand in for file count.

3. **[CORRECTION] R101 (`next/image`) is already active at `warn` — it's a warn→error bump, not net-new.**

4. **[CORRECTION] Warning-severity ESLint is NOT L1.** `npm run lint` exits 0 on warnings (proven;
   `no-console` is `warn` and doesn't block). Every relocate-to-ESLint row (R30, R36, R37, R101, R106) is
   L1 only at `error` severity AND with `--max-warnings 0` added to the lint script (or error-only rules).
   Add this as a precondition to the build list or the "≈64 deterministic" count overstates.

5. **[CORRECTION] Sharpen the `.cr-ok`→CI unforgeability mechanism.** The forgeable half is "CI re-derives
   MUST-FIX=0 from a committed `/cr` artifact" — but if the *model* writes that artifact, the forge just
   moves one layer up. Resolve to ONE of: (a) **CI itself re-runs the deterministic subset of `/cr`** (the
   tests/lint/typecheck passes — not the judgment passes) so the model never writes the trusted record; or
   (b) accept it explicitly as a **coverage-bounded trust-but-verify** gate and say so. The
   CI-required-checks-green-on-sentinel-SHA half IS genuinely unforgeable; only the MUST-FIX=0 half needs
   this. Recommendation: (a) for the mechanizable passes + (b) honestly stated for the rest.

6. **[CORRECTION] commitlint (R86) needs a new npm dep** — surface under the ASK-before-install rule (R60),
   same as `dependency-cruiser` already is.

The 7 build items are unchanged and each passes §9: `block-dangerous-bash.sh`, `.cr-ok`→CI/branch-
protection, `/cr-security` glob classifier, `dependency-cruiser` L2 (report-mode first), one
`migration-lint` CI script (absorbs 8 safety-critical migration rules), one `repo-structure` CI script +
commitlint, and the autoMode placement fix (human handoff — agent must not edit guard files).

---

## D. Corrected FILE TREE (direction sound; 2 load-bearing claims + counts fixed)

The file tree is the most honest artifact and needs the least reframing. Corrections:

1. **[BLOCKER] memory.md "verbatim in CLAUDE.md" is false** — same as §B.4. The disposition becomes
   **MERGE-INTO `00-safety.md` (verbatim absorb) THEN DELETE-CANDIDATE**, with the 3 non-safety traps
   explicitly routed. Do not license deleting the richest copy of a KEEP-VERBATIM safety rule on a false
   "already there" premise.

2. **[BLOCKER] The PITFALLS split is Area-GUIDED, not "mechanical."** 3–4 entries are operation-scoped, not
   file-path-globbable (cascade-delete; worktree ops; "any skill/agent calling external tools"). Downgrade
   the "mechanical, generated, drift-checked" claim: `gen-rules.sh` can deterministically shard the
   path-globbable entries; the operation-scoped residuals must be **explicitly named** and routed to
   `00-safety.md` / the always-load process section, or `gen-rules.sh` cannot be deterministic for them.
   (Folds into §B.3 — shard only where a clean glob exists.)

3. **[CORRECTIONS] Count fixes:** scripts BEFORE = **7** not 8 (→10 with the 3 new = +3); skills **26 dirs
   → 25** (23 bodies + 2 symlink; −1 dep-update); ADR = **5 ADRs + README**; worktrees = **7** (disk, not
   the prompt's 8); `.gitignore` has `.claude/.cr-ok` + `.claude/.cr-feature-ok` literally (not a `.cr-ok*`
   glob) — recommend ADDING `.claude/.cr-ok*` as a new change, phrased as new.

**The §9 survivor pass is the rigorously-met requirement:** all 26 skills + 23 agents carry a failure-mode
line. Only cut: `dep-update/` (empty stub). The prompt's "lens/spike agents are reuse-cuts" hypothesis was
**tested on disk and rejected** — the 4 lenses are spawned by `reviewer.md`, the 6 spike agents by the
spike orchestrator; all wired, all load-bearing. Two soft merge-candidates flagged, not executed
(`setup-strategy`+`review-strategy` → one `/strategy`; `prioritize-tasks` vs `/queue`) — body-diff before
cutting. `dev`/`explain` need canon *documentation* (MOVE 5 convergence), not deletion.

---

## E. The honest reconciled numbers (carry these — not the draft headlines)

- **Budget (1) — agent-context/advisory prose:** memory.md deleted; PITFALLS monolith deleted → ~5–6
  path-scoped shards (load 1–2 per task, not all 558 lines); CLAUDE.md NEVER-section deleted after its
  rules relocate; ~64 rules moved out of prose into deterministic layers. **Copies-per-fact 3→1.**
  Per-`/cr` PITFALLS token cost ~172 KB (4 lenses × 43 KB) → a fraction. **Large win.**
- **Budget (2) — deterministic enforcement:** +2 hooks (`block-dangerous-bash`, `session-end-capture`),
  +3 CI scripts (`scan-context` drift detector, `migration-lint`, `repo-structure`), +1 generator
  (`gen-rules`), +1 dev-dep (`dependency-cruiser`, ASK-first), +~5–6 rule shards, +2 CI jobs (stop-authority,
  cr-security classifier). **~+9–11, each §9-justified.**
- **Knowledge files:** net ≈ **−2 to −3**. **Total tracked files incl. mechanisms:** ≈ **flat (+1 to +2)**.
- **Biggest raw byte cuts:** 7 stale worktrees (NEEDS-HUMAN, each a full repo copy) > `.claude/` scratch
  (~48 KB: TASK-TEMPLATE 29 KB inert, grill-progress 14 KB, walkthroughs, questions.md) > PITFALLS 43 KB →
  ~16 KB sharded > memory.md 10 KB merged > docs/planning + exploration (~157 KB) archived out of skim.

---

## F. Consolidated GENUINE open decisions (deduplicated across all 3 artifacts → decision brief)

1. **ADR disposition (biggest fork).** Project into S1 as `kind: decision` + retain `docs/adr/` long-form
   (recommended) / delete `docs/adr/` and flatten to S1 entries / keep ADR as a distinct 4th owned store.
   Trade: a small "two homes, one fact" (mitigated by generation + drift CI) vs. strict minimal count vs.
   coherence-purism.
2. **MOVE-1 Stop-hook capture: fully automatic vs. degrade.** Build the Stop hook for append-and-allow-stop
   only (non-controversial capability); gate full session-end auto-capture on a one-session empirical check
   (can the hook see the turn's corrected-mistake signal?). If it fails, degrade to `/cr` 3b (already auto)
   + manual append — still better than today. **The load-bearing risk in the memory model.**
3. **Auto-memory authority: prose-only forever, or a capability spike?** "On conflict, curated stores win"
   is the model's one irreducible prose line (subsystem not hookable). Ship the prose now; decide whether to
   spend a spike probing whether the auto-load is fence-able/priority-able.
4. **Shard generation: `scripts/gen-rules.sh` in CI (recommended, deterministic) vs. a `/compound` step.**
5. **`.cr-ok`→CI unforgeability: CI re-runs the deterministic `/cr` subset (recommended) vs. accept a
   coverage-bounded trust-but-verify gate.** (§C.5.)
6. **Soft skill merges:** `setup-strategy`+`review-strategy` → one `/strategy`? `prioritize-tasks` vs.
   `/queue`? Body-diff first.
7. **`docs/design/handoff/**` (~20 files incl. screenshots):** keep as design source-of-record vs. archive
   after the referenced screens ship.
8. **Ratify the two-budget reframe (§A):** accept ~flat total file count as the price of determinism
   (recommended), or hold a harder file-count line and leave more rules advisory?

Plus the standing inherited forks from MASTER-FINDINGS §H (distribution vehicle, autonomy-in-scope,
MOVE-4 cut depth, eval timing) — sharpened in Phase 6.

---

## G. Status

All three Phase-3 artifacts: **SOUND-WITH-CORRECTIONS**, corrections recorded above as the authoritative
position. No architectural rework. The memory model, enforcement sort, and file tree — as corrected here —
are the inputs Phase 4 (distribution + self-update), Phase 5 (compounding loop + measurement), and Phase 6
(lens panel + reviewer) build on. The genuine forks (§F) accumulate toward the decision brief.
