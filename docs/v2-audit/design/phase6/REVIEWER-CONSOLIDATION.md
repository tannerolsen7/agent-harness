# Phase 6 — Reviewer Consolidation (the /cr-style pass over the whole V2 design)

**Authored by the main loop** (the workflow's reviewer agent hit the account session limit after the 5
lenses persisted; per the handoff, harvest from disk and finish from full context). Five staff-engineer
lenses attacked the integrated V2 design (Phases 3+4+5). All five verdicts: **CONCERNS** — none SERIOUS,
none forcing redesign. The integrated design is sound; the findings are ledger corrections, build-order
sequencing, capability-precision, and two free merges.

---

## 1. THE ANTI-DUPLICATION GATE (mandatory) — RESULT: **PASS with merge-discipline**

This is the gate that would have killed the V1 failures. Run against every surviving proposal across
Phases 3+4+5:

- **Phantom (already exists)? ZERO kills in the authoritative (reconciled) design.** Every build item —
  `.claude/rules/` shards, `block-dangerous-bash.sh`, `session-end-capture.sh`, `scan-context.sh`,
  `gen-rules.sh`, `migration-lint`, `repo-structure`, `dependency-cruiser`, the whole `.claude-plugin/`
  layer, the `cr-golden/` corpus, `score-cr-eval.sh`, `/cr-eval` — was re-verified ABSENT on disk this
  session. The one phantom (R2 `ban-ts-comment`, already firing) lives only in the *uncorrected draft* and
  was already caught by RECONCILIATION §C.1.
- **Rejected-pattern rebuild (§F)? ZERO.** `learned-patterns.md` not built (read-path instead);
  symlink-live explicitly rejected (versioned-copy-with-lock); trigger-word-frontloading rejected
  (tier-by-trigger-existence); 23-agents-→-skills rejected (roster kept, each §9-justified); dev-container
  stack not proposed; ROI rates refused (measured locally); autoMode-by-agent is a NEEDS-HUMAN handoff
  everywhere. The §F discipline is the strongest axis in the design.
- **Cross-phase duplicate? One genuine adjacency (reconcile, don't kill) + two already-merged-by-authors.**
  The drift-check and golden-set-freshness were *already folded* into the single `scan-context` detector by
  the authors. The golden-set-as-4th-store objection was anticipated and disarmed (it's a CI fixture, agent
  never reads it). The surviving one: **`harness-manifest.json` overlaps the real `skills-lock.json`** on the
  skills dimension (two generated hash manifests; nothing asserts they agree → a drift seam inside the
  drift-catcher). **Resolution: reconcile, not delete** (D-1, fixed below).

**Verdict: the design does not repeat the V1 phantom-proposal failure.** The gate passes.

---

## 2. CONSOLIDATED TIERED FINDINGS (deduped across the 5 lenses)

### MUST-FIX (must be reflected before the design is acted on)

- **M1 — [budget] The rule shards were misbooked as budget (2); they are budget (1).** The exact
  favorable-proxy substitution the two-budget rule forbids, in the table that defines it. **FIXED by the
  reviewer** — RECONCILIATION-phase3 §A corrected (re-booked to budget (1); mechanism claim fixed from
  "moved to unforgeable enforcement" → "path-scoped to load 1–2 per task"). Budget (1) still net-falls; the
  decision package carries the corrected ledger.
- **M2 — [sequencing] Guard-file Stop-hook deadlock.** A `Stop` hook is *already* wired
  (`settings.json:191`, a sound). The MOVE-1 `session-end-capture.sh` is a SECOND Stop hook → a guard-file
  edit the agent may not make. Route (a) human edits now; route (b) the plugin's `hooks.json` (ships LAST).
  Phase 5 wants MOVE-1 NOW. **Resolution (build-order):** the first slice includes a paste-ready NEEDS-HUMAN
  edit adding `session-end-capture.sh` as a second Stop hook (additive, `exit 0` only, append-only, never
  `decision:block`, coexists with the sound hook); the plugin `hooks.json` replaces the hand-edit at
  extraction. Added to the migration path.
- **M3 — [sequencing] PITFALLS-deletion triangle.** `/cr` Step 3b WRITES `PITFALLS.md` (line 225);
  `reviewer.md` passes it to each of 4 lenses; V2 DELETES it. Delete-before-retarget breaks the review gate
  silently. **Resolution (build-order):** atomic "PITFALLS retirement" unit — (i) build `.claude/rules/` +
  generator → (ii) retarget `/cr` Step 3b write to `.claude/rules/<area>.md` → (iii) update `reviewer.md` to
  load the relevant shard not the monolith (this IS the 172 KB→~2 KB token win) → (iv) only then flag
  `PITFALLS.md` DELETE-CANDIDATE.
- **M4 — [capability] The Stop-hook write-back's hard part is detection, and it may not be deterministic.**
  The hook receives `transcript_path` (a PATH, not content); to know "a mistake was corrected this turn" it
  must read+parse the transcript JSON and run a *semantic* heuristic — a regex/keyword scan is forgeable and
  low-precision, the kind of thing the harness rejects elsewhere. If detection needs an LLM, the
  "deterministic out-of-band writer" claim collapses to "deterministic trigger + probabilistic detection."
  **This is THE load-bearing open risk — it becomes a Tanner decision** (D4). The degrade path (`/cr` 3b +
  manual append) is real and bounds the worst case.

### SHOULD-FIX (reviewer-resolved; reflected in the package)

- **S1 — [anti-dup] D-1: `harness-manifest.json` must reference `skills-lock.json`'s hash** for the 2
  upstream supabase skills (mark them `owner: upstream`), not recompute it — single source of truth — or add
  a drift assertion the two agree. **Resolved (design rule).**
- **S2 — [budget/anti-dup] Merge A: fold `gen-rules.sh` + `gen-manifest.sh` into one `gen-harness.sh`**
  (two subcommands; same disk-walk, same CI lane). Keep `scan-context.sh` separate (it's the verifier —
  doer≠checker). **Resolved (−1 budget-2 file).**
- **S3 — [budget] Merge B: drop `commitlint` (dep + commit-msg hook); fold a ~10-line subject-line regex
  into the `repo-structure` CI script.** **Resolved (−1 file, −1 dep, −1 ASK-first prompt).**
- **S4 — [capability] `disable-model-invocation` "removes from context" is documented but uncorroborated on
  disk** (0 skills use it anywhere; the on-disk reference documents only "user-only invocation"). The
  `/cr-eval` budget-(1)=0 rests on it. **Resolved:** demote to conditional — "budget-(1)=0 *iff*
  `disable-model-invocation` drops the description from the skill index; verify on the target CC version;
  else +1 line." Costs nothing (the fallback was already written).
- **S5 — [capability] Rephrase `.cr-ok`→CI.** What CI can mechanize is *precisely the lane that already
  exists* (`tsc`/`eslint`/`test:unit`) made the required gate on the sentinel SHA via branch protection —
  NOT a re-execution of `/cr`'s judgment passes (genuinely un-mechanizable). **Resolved (wording).**
- **S6 — [sequencing] "Build measurement NOW" overstates independence.** Split: (a) NOW, zero deps — the
  ~6–10 hand-authored adversarial cases + deterministic scorer + `/cr-eval`, run once vs Opus 4.8 for the
  baseline; (b) LATER — the historical-finding mine (waits on the PITFALLS retarget, M3) and the
  L2-failure-rate signal (waits on `dependency-cruiser`). **Resolved (build-order).**
- **S7 — [sequencing] Convergence is the PUBLISH gate, not the program gate.** It blocks only plugin
  extraction/publish. The bash guard, dep-cruiser, `.cr-ok`→CI, and the recall baseline have ZERO dependency
  on canon==disk. **Resolved:** the enforcement + memory + measurement spines run in PARALLEL with
  convergence; only extraction waits on it.

### CONSIDER (noted in the package)

- **C1 — [capability]** The deterministic eval scorer needs `/cr` to emit a per-finding `defect_class` token
  (today it emits prose tiers) — a small `/cr` output-format requirement; without it the "deterministic
  comparison" quietly needs an LLM to map prose→class = laundering. Name it as a precondition.
- **C2 — [capability]** `metadata.pathPatterns` (a plugin-skill convention, 60× in the vercel plugin) ≠
  native `paths:` (the rules auto-load mechanism). Rules shards use **bare `paths:`** or they won't
  auto-load. Don't conflate.
- **C3 — [anti-dup] F-1:** stamp the superseded Phase-3 *drafts* (enforcement-sort R2/R101; the inflated
  "~64 deterministic" count) with an "AUTHORITATIVE: see RECONCILIATION §C" banner so no downstream reader
  re-imports the phantom from the draft. **Reviewer note added below.**
- **C4 — [sequencing]** The golden-set self-feeder is acyclic ONLY via the human-confirm gate — bind the
  §3.6 auto-feeder explicitly behind human-confirm enforcement.
- **C5 — [sequencing]** `session-start.sh` is wired-but-EMPTY (body only truncates a log + remote `npm
  install`). R42/R43/R44's heartbeat is a BUILD, not a "wire the existing." Relabel.
- **C6 — [anti-dup/budget] Tally fix:** `gen-manifest.sh` was omitted from the Phase-4 budget-(2) line;
  after Merge A it folds into `gen-harness.sh` anyway, so the corrected aggregate is below.

**[Authoritative-draft note, per C3]:** Where the Phase-3 *draft* files (`memory-model.md`,
`enforcement-sort.md`, `target-file-tree.md`) and a RECONCILIATION disagree, **the RECONCILIATION wins.**
Specifically: enforcement-sort R2 = keep (already L1), R101 = warn→error bump, and the "~64 rules
deterministic" headline is −1 (R2 removed from the relocate count). The drafts are the audit trail, not the
position.

---

## 3. CORRECTED AGGREGATE BUDGET (what the decision package carries)

- **Budget (1) — agent-read forgeable prose: NET-FALLS.** Deleted: `PITFALLS.md` monolith (574 L, read
  wholesale + passed to 4 `/cr` lenses ≈172 KB/review), `memory.md` (166 L), the CLAUDE.md NEVER-section
  (~16 L); copies-per-fact **3→1**. Added: `00-safety.md` (always-load, but absorbs the deleted safety text
  → flat-to-down) + ~6 area shards (read **1–2 per task on their path**, not all 574 lines every task). The
  per-task read budget falls hard. **This is the real V2 win, and it is in budget (1), not (2).**
- **Budget (2) — genuinely out-of-band enforcement/packaging: ≈ +13–17** (down from the drafts' +16–20
  after Merge A and Merge B), every item §9-justified, zero phantoms, zero rejected-pattern rebuilds.
- **Total tracked files: ~flat to modestly up** — permitted by the two-budget rule *because* budget (1)
  falls and every budget-(2) item names a failure mode.

---

## 4. THE GENUINE DECISIONS FOR TANNER (collapsed from ~26 scattered opens → 5 real forks)

Most of the ~26 open items across the phases have an obvious recommendation and are **resolved** here
(distribution channel hosting → same account; push-back automation → field-now/PR-later; auto-memory
authority → ship prose now; eval seeding ratio → minimal-first; the soft skill merges → body-diff then
merge; the 3rd install → Tanner names a target during migration; ratify the two-budget reframe → yes, on the
corrected ledger). The five that genuinely change what gets built, where a reasonable person could choose
differently:

**D1 — ADR disposition (the biggest design fork).** Project ADRs into S1 as `kind: decision` entries AND
retain `docs/adr/` as the long-form authoring home *(recommended)* — vs. delete `docs/adr/` and flatten to
one-line S1 entries — vs. keep ADR as a distinct 4th owned store. *Tradeoff:* the recommendation costs a
small "two homes, one fact" (mitigated by generation + drift CI) to preserve the Context/Decision/
Alternatives/Consequences shape and supersession lifecycle; full-delete is strictly minimal but loses the
long-form; 4th-store is coherence-pure but re-grows the store count. *Citation:* memory-model §1/§4; tree §4.

**D2 — Ratify revising the canon's LOCKED single-vehicle distribution decision → two-vehicle (plugin +
thin template)?** *(recommended: YES).* *Why:* a material capability fact changed since the 2026-05-18 lock
(plugin-marketplace maturity); a plugin makes PULL-update native and wires hooks WITHOUT touching the
downstream guard file; the locked *sequence* (converge→ship→3 installs→Cursor→npx→UI) is honored intact; the
revision *reduces* downstream tooling. *Tradeoff:* it overrides a locked decision (the thing the canon says
not to do lightly) — but three of the four revision conditions are met and the seam is forced (a plugin
physically cannot carry permissions/autoMode — verified vs the live vercel 0.43.0 plugin = 27-byte
settings). *Citation:* distribution §1; capability-facts; canon-locked §A.

**D3 — Is the autonomous trigger front-door in V2 scope?** *(recommended: NO — keep hypothesis-gated).*
*Why:* MOVES 1–6 build the enabling substrate (write-back, measured gate, bash guard, heartbeat); deciding
autonomy *after* that substrate exists avoids the forbidden speculative build (building the classifier
first). *Tradeoff:* deferring means the harness still can't be "summoned" (bug→PR, `/goal`, scheduler) in
V2; if Tanner wants autonomy as a V2 goal, the cluster (C4-G6) comes into scope and changes the build set.
*Citation:* MASTER-FINDINGS §C, §H.2.

**D4 — The MOVE-1 write-back automation: run the one-session capability probe to attempt full-auto, or ship
the degrade-safe version now?** *(recommended: ship degrade-safe — `/cr` 3b auto + a manual append — AND run
the probe before committing to the Stop-hook auto-capture).* *Why:* whether a *deterministic* script can
detect a corrected-mistake from the transcript JSON is unverified and may be semantic (needing an LLM, which
breaks the "deterministic writer" claim). *Tradeoff:* degrade-safe is strictly better than today's prose-only
write-back and risk-free; full-auto is nicer but hangs on the unverified detection. This is **the single
load-bearing open risk in the whole design.** *Citation:* capability lens MF-1; compounding-loop §1;
RECONCILIATION-phase3 D2.

**D5 — Ratify the corrected two-budget accounting as the basis for "fewer files."** *(recommended: YES).*
Accept that V2 ends with **~flat total tracked files** — budget (1), the forgeable advisory prose the agent
reads (the thing that hurt V1), falls hard; budget (2), out-of-band §9-gated enforcement, grows. *Why it's a
real decision:* the binding principle says "more files = RED FLAG," and a literal reading would reject this
design; the reframe (count two budgets, minimize the one that hurt V1) is the lens that resolves it. *Tradeoff:*
hold a hard total-file-reduction line instead and you must leave more rules advisory (forgeable). *Citation:*
RECONCILIATION-phase3 §A (corrected); budget-simplicity lens.

---

## 5. Verdict

**READY-WITH-FIXES → cleared to assemble the decision package.** No lens found a SERIOUS concern or forced
redesign. The reviewer-resolvable items (M1, S1–S7, C1–C6) are applied or recorded above. The two MUST-FIX
sequencing hazards (M2, M3) are build-order corrections folded into the migration path, not redesign. The
one load-bearing capability risk (M4) is surfaced as decision D4 with a bounded worst case. The
anti-duplication gate passed. The build-order critical path and first slice (from the sequencing lens §E)
carry into the package's migration section.
