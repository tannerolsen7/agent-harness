# Adversarial check — `design/v2/memory-model.md`

> **Role.** Doer≠checker. A different agent wrote `memory-model.md`; this pass attacks it. Ground truth
> re-verified on disk this session (2026-06-11), not taken from the artifact's own assertions. Every finding
> below cites the artifact line and the disk/canon fact it conflicts with.

**Disk re-verification performed (so the attack stands on facts, not the artifact's claims):**
- `.claude/rules/` ABSENT ✅; `session-end.sh` ABSENT (hooks on disk: `block-dangerous-git.sh`,
  `block-npm-install.sh`, `permission-logger.sh`, `session-start.sh`, `worktree-create.sh`) ✅
- existing `Stop` hook = sound only (`settings.json:191`, `afplay Glass.aiff`) ✅
- `/compound` reads `.claude/memory.md` only (Steps 6/9); zero `feedback_*`/`project_*`/auto-memory refs ✅
  → auto-memory→S1 graduation IS net-new, as the artifact claims (Q2 below)
- `/cr` Step 3b is a real writer: reads `RECURRING-FINDINGS.md`, increments Occurrences (cap 5), auto-flags
  ≥3, writes `PITFALLS.md` on confirm (`cr/SKILL.md:155,174–226`) ✅
- `RECURRING-FINDINGS.md` PRESENT (16 KB) ✅; auto-memory = 53 `.md` files ✅
- `scan-context` referenced in `rituals.md:13`, ABSENT as a skill ✅ (live phantom)
- `Area:` field present on exactly **36** PITFALLS entries (`grep -c` confirmed) — load-bearing for MF-1 below
- `learned-patterns.md`: zero references in live canon (only in v2-audit research docs + CANONICAL §6) ✅
- CANONICAL §4 (lines 235–265): triple-duplication, the dual Layer-1/Layer-3 assignment, and "freshness
  rules exist for only 3 stores" all confirmed as cited

---

## Verdict: **SOUND-WITH-CORRECTIONS**

The spine is sound and survives the attack. Entry-as-atom genuinely dissolves the §4 file-as-unit
dual-assignment **in the data model**; the S3 airlock is the correct over-collapse guard; riding auto-memory +
native `paths:` is the right read; the loop is wired edge-by-edge with real citations; `learned-patterns.md` is
correctly NOT rebuilt; the verbatim-absorb-before-delete and the net-new graduation label are both present. But
the artifact re-opens TWO of the very dual-assignments it claims to kill (one in the store table vs. an edge, one
in the writer cell), re-asserts a "mechanical" framing its own binding correction (RECONCILIATION §D.2) rejected,
and leaves the safety-text protection and a monotonic-cache eviction as prose-only — the exact §4 failure pattern
("encoded in no tooling"). None force architectural rework; all are correctable in place.

---

## MUST-FIX

### MF-1 — Edge 2 re-asserts "mechanical" PITFALLS routing, contradicting the authoritative RECONCILIATION §D.2 BLOCKER the artifact is bound to fold in

Artifact line 179: *"the write retargets from `PITFALLS.md` to `.claude/rules/<area>.md` (area from the
finding's matched `Area:` field — present on 36 PITFALLS entries today, **so the routing is mechanical**)."*

The artifact's own rigor contract (lines 12–15) states: *"the RECONCILIATION §B corrections are folded in as
the authoritative position."* RECONCILIATION §D.2 is a **[BLOCKER]**: *"The PITFALLS split is Area-GUIDED, not
'mechanical'. 3–4 entries are operation-scoped, not file-path-globbable (cascade-delete; worktree ops; 'any
skill/agent calling external tools'). Downgrade the 'mechanical, generated, drift-checked' claim... the
operation-scoped residuals must be explicitly named."* §B.3 says the same (shard only where a clean `paths:`
glob exists). The "36 entries carry `Area:`" count is real and verified — but PITFALLS is 558 lines with many
more than 36 entries, so **~36 entries are Area-tagged and the remainder are not**, which is *precisely why* §D.2
rules the split non-mechanical. The artifact cites the 36-count as *evidence of* mechanicalness; the same fact is
the evidence *against* it. This is not a minor word choice: "mechanical" licenses an unattended `gen-rules.sh`
to route every promotion with no human naming of the operation-scoped residuals — the failure §D.2 exists to
prevent (a worktree-ops or external-tool trap silently dropped or mis-sharded into a glob it doesn't match).
**Fix:** restate Edge 2 as "Area-GUIDED for the path-globbable majority; operation-scoped residuals
(cascade-delete, worktree ops, external-tool rule) are explicitly named and routed to `00-safety.md` / the
always-load process section," matching §D.2 / §B.3 verbatim. Drop "so the routing is mechanical."

### MF-2 — S1 has TWO readers, not one: the store table says "the platform, by path"; Edge 3 makes CMP1 a second reader — the dual-assignment the model claims to dissolve

Store table, S1 reader cell (line 54): *"ONE reader (+when): **The platform, by path.** `00-safety` +
behavior floor always-loaded; area shards auto-load via native `paths:` globs."*

Edge 3 (line 195): the Phase-0 read step *"globs **S3's** `signature`/`Example locations` **and S1's
path-scoped rules** against the files about to be touched."* The artifact concedes this on line 198 (*"the
read-path is partly the platform's"*) but never reconciles it against the "ONE reader" contract.

So S1 is read by **(a)** the native `paths:` auto-loader (passive, on file-touch) **and (b)** CMP1's explicit
task-start glob (active, in `/dev`/`/feature`/`/cr` Phase-0). That is a genuine dual-reader on a store whose
defining claim is "ONE reader." It is the same shape as the §4 pathology the model is built to kill ("the same
store is Layer 1 here, Layer 3 there") — re-imported at the store↔edge boundary instead of the file boundary.
The single-reader discipline is named as "what dissolves the §4 dual-assignment ambiguity" (line 50), so a
self-inflicted dual-reader undercuts the model's central claim. **Fix:** either (a) make the S1 reader cell
honest — "TWO complementary readers: native `paths:` (passive auto-load) + CMP1 task-start glob (active,
occurrence-tagged surfacing); they read the same store for different purposes and never disagree because both
read the *same* `paths:`-scoped files" — and justify why two readers here is not the §4 disease; or (b) collapse
to one by routing CMP1 entirely through the native loader. Option (a) is likely correct, but it must be *stated*,
not left as a silent contradiction between the table and Edge 3.

### MF-3 — S1 has TWO writers (the promotion conveyor AND humans for `00-safety`); the "one logical writer, two trigger points" framing hides a real second writer with a different gate

Store table, S1 writer cell (line 54): *"**The promotion conveyor** — `/cr` Step 3b *and* `/compound`
(S3→S1, one logical writer, two trigger points); the `00-safety` floor is **human-edited only**."*

Two distinct facts are bundled as one. The "two trigger points, one logical writer" framing for `/cr` 3b +
`/compound` is defensible (both write area shards via the same promotion gate). But the trailing clause —
`00-safety` is **human-edited only** — is a *second, categorically different writer* (a human, on no automated
gate, no `≥3` threshold) writing into the *same store S1*. That is a dual-writer: the always-load safety floor
and the path-scoped area shards have **different writers and different write-gates** yet are both "S1." The model
elsewhere treats this as a feature (no-agent-edits-guard-files, correctly), but the store table presents S1 as
having a single writer discipline it does not have. **Fix:** split the S1 row's writer cell to name both writers
explicitly with their distinct gates — "area shards: the promotion conveyor (`/cr` 3b + `/compound`, gated ≥3 +
confirm); `00-safety` floor: **human-only, no automated writer** (no-agent-edits-guard-files)" — or, cleaner,
treat the always-load safety floor as a distinct sub-store (S1a human-only / S1b conveyor-written) so the
one-writer-per-store invariant is literally true rather than true-in-spirit. As written, S1 fails the "exactly
ONE writer" test the charter demands.

---

## SHOULD-FIX

### SF-1 — The verbatim-absorb-before-delete protection (Q3) is prose-only ordering, not a wired gate — the exact §4 disease ("reconciled only in prose, encoded in no tooling")

The protection is PRESENT and correctly worded (header line 14; collapse-table line 266: *"memory.md is not
deleted until the absorb target is verified to carry the richer narrative + `How to apply:` steps"*), matching
RECONCILIATION §B.4 / §D.1 [BLOCKER]. **So Q3 passes on intent.** But the protection is stated as an *ordering
sentence*, with no mechanism asserting it. The model spends an entire section (CMP4) on drift-CI that *asserts*
"a promoted finding now exists in S1" (line 185) and "every named artifact reference exists on disk" — yet does
**not** add the obvious companion assertion: *"`00-safety.md` contains memory.md's richer destructive-op
narrative + `How to apply:` steps before `memory.md` is removed."* This is a one-time migration step (lower
recurring risk than a loop leg), but leaving the single most safety-critical deletion in the whole model as an
unenforced prose promise — in a model whose thesis is "encode the reconciliation in tooling, not prose" — is a
self-inconsistency. **Fix:** add a one-line CMP4 fiction-mode assertion (or a `gen-rules`/migration checklist
gate) that blocks the `memory.md` deletion PR until the absorbed text is present in `00-safety.md`. Cheap;
converts the KEEP-VERBATIM floor from a promise into a check.

### SF-2 — S2 (solutions) is a monotonic store with only an advisory archive flag — unbounded growth, and it weakens the "supersession is the eviction" claim

Store table, S2 freshness (line 55): *"supersession, not time-decay — patterns are durable; they die by being
replaced... A no-reference-in-365-days *archive* flag is **advisory only**."* (Q5.) This does **not** collide
with decay (S2 is *designed* decay-exempt, and the model is internally consistent on that — no leg reads S2 as
decaying). So the charge's "collides with decay" does not fire for S2. **But** S2 is genuinely monotonic: a
superseded pattern presumably stays on disk as `status: superseded-by <file>`, and the only eviction is an
*advisory* 365-day archive flag with no actor and no trigger. Over many cycles `docs/solutions/` accumulates
superseded husks with no hard removal — the same accretion-with-no-exit the model indicts for the *file-as-atom*
stores (line 92). "They die by being replaced" is false as stated: the *active pointer* moves, the *file* does
not die. **Fix:** either give the archive flag a real actor+trigger (e.g., CMP4's decay pass moves
`status:superseded` + no-reference-365d entries to a `docs/solutions/_archive/` out of the glob), or state
explicitly that superseded solutions are retained-by-design and bound the growth some other way. As written it's
the only store in the model with no eviction path at all.

### SF-3 — The auto-memory cache is a monotonic store the harness cannot evict (53 files and rising), and the model's only defense is one prose line — Q5's real monotonic-store answer

The store table (line 57) is correct that the harness *cannot* write or evict the cache ("ridden, never
owned... cannot evict" — line 73). Disk confirms 53 files, growing, all auto-loaded (first 200 lines / 25 KB per
capability-facts.md:54). This is the model's genuinely-monotonic store with no eviction — and it does NOT
collide with decay only because the model has no decay hook into it (it can't). The defense ("on conflict,
curated stores win") is one prose line and is honestly flagged as the model's single irreducible prose-only seam
(D3). That honesty is correct and I do not ask to remove it. **But** the model should state the *consequence* of
the monotonicity, not just the conflict-precedence: as the 25 KB auto-load budget fills with stale `feedback_*`
entries, the *freshest* corrections may fall outside the 200-line / 25 KB window and never load at all —
silently, with no eviction the harness can perform. That is a real failure mode (freshness loss by truncation)
the model names nowhere. **Fix:** add one sentence to the auto-memory row's failure-mode: "monotonic + un-evictable
→ at >25 KB the platform truncates by recency-of-write, so the risk is *truncation of fresh signal*, not stale
override; D3's spike should also probe whether the load window is orderable." Keeps D3 prose-only but names the
cost.

### SF-4 — Edge 5: CMP3 first-pass-approval "confirms compounding" but has no defined control action on regression — a measurement leg that observes without closing (Q4)

The loop legs are mostly closed (Q4): recurrence → CMP1 eviction signal (closed); PR-size → tunes F7 (closed);
C4 recall → gates self-merge (closed). But first-pass-approval-rate (the headline compounding sensor) is wired
only to *"confirm compounding"* (lines 200, 232) — an observation, with no stated action when it *regresses*.
A self-improving loop whose primary success metric has no failure-branch is half-instrumented: if first-pass
approval falls, nothing in the model says what fires (re-run CMP4? halt a class via F8? re-calibrate via C4?).
This is softer than the dual-assignment findings — measurement legs legitimately can be detect-only — but the
artifact claims "the metrics close the loops" (line 232), and this one leg does not close. **Fix:** name the
control edge for a first-pass-approval regression (e.g., "a sustained drop trips CMP4's decay/fiction scan and
flags the most-recently-promoted S1 rules for review"), or downgrade the claim to "first-pass-approval is a
*sensor* read by the human/`/schedule` report, not an automated control input" — don't assert it "closes the
loop" if it only confirms.

---

## CONSIDER

- **C-1 — S3's reader and CMP1 are the same mechanism described twice with slightly different scope.** The S3
  reader cell (line 56) says reader = "task-entry skills... glob the ledger's `signature`/`Example locations`...
  with 90-day decay on the read." Edge 3 (line 195) describes the *same* CMP1 glob but adds S1 to it. These are
  consistent, but the reader is defined in two places; consider a single canonical definition of "the CMP1
  Phase-0 read" that both the S3 row and Edge 3 point to, so a later edit can't drift them apart (and so MF-2's
  dual-reader on S1 is impossible to reintroduce silently).

- **C-2 — Q6 (learned-patterns.md correctly NOT rebuilt): PASS, no change.** Verified twice in-artifact (lines
  199, 203–204) and against VISION CMP1 + CANONICAL §6 + disk (zero live refs). The read-path is correctly named
  as the kept form, the file as the killed form. Note only: CMP4's fiction-mode enumeration (line 286) lists
  `learned-patterns.md` as a phantom to *scan for* — good, that's the mechanism that keeps it dead. No action.

- **C-3 — Q2 (auto-memory graduation labeled NET-NEW `/compound` step): PASS.** Confirmed on disk (`/compound`
  reads memory.md only). The artifact labels it net-new in the S1 writer cell, Edge 2 (line 181), and load-bearing
  idea #3 (line 117), each citing RECONCILIATION §B.1, and explicitly counts it in budget (2) — not a free
  retarget. Correct. No action.

- **C-4 — "copies-per-fact 3→1" is the *curated* count; total physical copies of the fact = 2 (canonical S1
  entry + un-evictable auto-memory cache).** The artifact is careful about this (line 270: "the cache is not a
  4th copy of record — it is explicitly demoted"). Defensible, but the headline "3→1" and the on-disk reality
  "2 physical copies, one demoted" should not drift apart in downstream docs; consider always pairing the "3→1"
  headline with "(+1 demoted, un-evictable cache copy)" so the budget claim stays honest under the RECONCILIATION
  §A red-flag rule ("never report a budget-(1) win as a total-file-count win").

---

## Scorecard against the six charge questions

| # | Charge | Finding |
|---|---|---|
| Q1 | Every store exactly ONE writer/reader/freshness, or dual-assignment left? | **Dual-assignment left, twice.** S1 has two readers (MF-2) and two writers (MF-3). The model dissolves the *file-as-atom* dual-assignment but reintroduces a *store↔edge* one. |
| Q2 | Auto-memory graduation correctly a NET-NEW `/compound` step (not a free retarget)? | **PASS** (C-3). Net-new, cited §B.1, counted in budget (2), confirmed on disk. |
| Q3 | `00-safety.md` verbatim-absorb-before-delete of memory.md's richer safety text protected? | **PASS on intent, prose-only on enforcement** (SF-1). Correctly worded; not wired to any check despite an adjacent CMP4 that asserts exactly this class of thing. |
| Q4 | Does read-path/ratchet/measurement close the loop, or a leg open? | **Mostly closed; one soft-open leg** (SF-4). recurrence→eviction, PR-size→F7, C4→self-merge all close; first-pass-approval is observe-only with no regression action. |
| Q5 | Any monotonic store with no eviction (collides with decay)? | **No collision, but two monotonic stores with no real eviction** — S2 (advisory-only archive flag, SF-2) and the auto-memory cache (un-evictable by design, SF-3). Neither collides with decay; both are unbounded-growth risks the model under-states. |
| Q6 | `learned-patterns.md` correctly NOT rebuilt? | **PASS** (C-2). Killed file, kept read-path; CMP4 scans for it as a phantom. |

**Bottom line.** SOUND-WITH-CORRECTIONS. The architecture holds; no rework. The three real fixes (MF-1 mechanical
overclaim vs. §D.2; MF-2 S1 dual-reader; MF-3 S1 dual-writer) all sit at the seams the model itself defines as
the disease, so they matter disproportionately to their size — fixing them is the difference between a model that
*claims* one-writer/one-reader and one that *is*. SF-1 and SF-2/SF-3 close the "encoded in tooling, not prose"
gap on the two highest-stakes items (the safety-text deletion and the monotonic stores).
