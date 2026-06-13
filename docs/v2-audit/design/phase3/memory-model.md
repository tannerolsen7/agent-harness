# V2 Memory Model — the single recommendation (Phase 3 synthesis)

**This is the decision, not a menu.** One model, grafted from the strongest element of each of the three
candidates (A = fewest-stores, B = cleanest-lifecycle, C = native-mechanism) and the disk census
(`inventory-stores-and-files.md`). Every claim below cites a current-state component (`[map §N]`,
`[inv Store N]`, a disk path) or a re-verified absence. Nothing here builds something that already exists
(anti-phantom: MASTER-FINDINGS §E). Re-verified on disk this session: `.claude/rules/` ABSENT;
`session-end.sh` ABSENT; auto-memory at 52 files; RECURRING-FINDINGS referenced outside the audit tree
**only** by `PITFALLS.md` + `.claude/skills/cr/SKILL.md` (the half-open loop, confirmed by grep);
PITFALLS carries an `**Area:**` field on 36 entries (the split key is real); `rituals.md` already has a
`last_run`/`frequency` heartbeat **and already lists `scan-context` as a ritual** with `last_run:
2026-05-27` (so `/scan-context` is referenced-but-absent — a live phantom).

---

## 0. The thesis, in one paragraph

The six stores today are **not six kinds of knowledge**. They are **three kinds — captured signal,
durable constraints, reusable patterns — smeared across six files, two of which the harness doesn't even
own.** The disease is not "too many files" (Candidate A's framing) and it is not purely "no lifecycle
exit" (Candidate B's framing) and it is not purely "fighting the platform" (Candidate C's framing) — it
is **all three at once, and they share one root: file-as-the-unit-of-store.** When the *file* is the
atom, the same fact lands in three files (duplication), each file accretes with no exit (monotonic
growth), and the harness hand-rolls a capture layer the platform already runs (auto-memory). Make the
**entry** the atom, give each entry one writer / one reader / one freshness rule, and the six collapse to
**three stores the harness owns + one subsystem cache it rides.**

The recommendation grafts:
- **From C (native-mechanism):** ride the auto-memory subsystem as the *capture inbox* instead of
  hand-maintaining `memory.md`; ride native `.claude/rules/+paths` for path-scoped delivery instead of a
  43 KB monolithic read. **This is C's load-bearing insight and it is correct.**
- **From B (cleanest-lifecycle):** every store must have a *tool-driven exit* — promote up or decay out —
  and the conveyor (promotion + eviction) lives in tooling, not prose. **B's "no monotonic-growth store"
  property is the discipline the whole model is organized around.**
- **From A (fewest-stores):** layer the *entry*, not the *file* — `tier:` and `freshness:` become
  per-entry properties, which is what actually dissolves the PITFALLS/memory dual-assignment. And A's
  honesty about the **promotion gate** (why FINDINGS-as-airlock cannot merge into the canonical store)
  is the correctness constraint that stops the model from over-collapsing. **A's floor-of-3 reasoning is
  the right count.**

What I **discard**: C's claim that auto-memory is "the spine" and `memory.md` can simply be deleted with
its safety floor already in CLAUDE.md (it is — but the *graduation writer* C invents, `/distill`, is a
new skill the model doesn't need: `/compound` already has Steps 5/6/9 that do exactly this work, verified
below); B's `.claude/journal.jsonl` as a **new** capture file (it re-hand-rolls the capture layer the
subsystem already runs — exactly the mistake C correctly names; the JSONL schema is right but its *home*
should be the existing RECURRING-FINDINGS ledger + the free subsystem, not a third new file); A's
**merge of ADR into KNOWLEDGE** (the cut A itself flags as its single most aggressive move — I keep ADR
as its own store, see §1, because its document shape and supersession lifecycle are load-bearing and the
fewest-stores win does not justify flattening Context/Decision/Alternatives/Consequences).

---

## 1. The target store set — **3 harness-owned stores + 1 ridden subsystem cache**

| # | Store | Kind | Lives at | Native lever it rides |
|---|---|---|---|---|
| **S1** | **`.claude/rules/*.md` + CLAUDE.md safety floor** | **Durable constraints** (traps + locked decisions), path-tiered | `.claude/rules/` (NEW) + CLAUDE.md (always-load floor) | native `paths:` glob lazy-load `[capability-facts.md]` |
| **S2** | **`docs/solutions/`** | **Reusable patterns** ("how we solved X") | unchanged | plain files + glob |
| **S3** | **`docs/RECURRING-FINDINGS.md`** (the ledger) | **Captured signal / promotion inbox** (the airlock) | repo root `docs/` | the existing `/cr` 3b auto-writer `[cr/SKILL.md:174]` |
| *(cache)* | **Auto-memory** (`~/.claude/projects/.../memory/`) | **Subsystem capture** — ridden, not owned | outside repo | the CC memory subsystem (free auto-writer + 25 KB auto-load) |

**Why exactly 3 owned stores (not 2, not 4):**

- **Why not 2 (merge S2 patterns into S1 constraints)?** Rejected, same reasoning in all three candidates
  and it is correct: constraints are *negative, short, preventive, push-loaded* ("never X here" — loads
  before you write); patterns are *positive, long, recipe-shaped, pull-loaded* ("how did we do Y" — loaded
  when you have the matching problem). They have **opposite freshness** (a constraint can decay when it
  stops firing; a pattern is durable until superseded) and **opposite read-triggers** (path-scoped
  always-on vs. on-demand grep). Forcing one freshness + one trigger onto both re-creates the dual-layer
  ambiguity we are killing. §9 failure prevented: a durable pattern decay-swept as a stale rule, or a
  stale rule surviving because it shares a file with durable patterns. **Split stands.**

- **Why not 2 (merge S3 inbox into S1)?** Rejected — this is A's load-bearing point and it is the single
  most important "do not over-collapse" guard. S3 holds *unverified, observed-once* candidates; S1 holds
  *human-confirmed, always-loaded* constraints. Collapsing them removes the **promotion gate** — the one
  place a finding can sit at occurrences=1 without polluting the always-loaded constraint set. §9 failure
  prevented: **an un-vetted single observation getting auto-promoted to an always-loaded rule and
  ossifying** (the "forgeable/stale gate" failure, `_EMERGING-FINDINGS §2`). The inbox is the airlock.
  Keep it.

- **Why not 4 (keep ADR as a 4th owned store)?** This is the genuine fork, and I split from Candidate A
  here. A merges `docs/adr/` into the constraint store for the file-count win; B and C both keep ADR
  distinct (B as S3, C merges it into rules). **I keep ADR's *content* but fold it into S1's
  `.claude/rules/` delivery surface AS a distinct entry-class** (`kind: decision`), so the count of
  *physical stores* stays at 3 while ADR's **document shape and supersession lifecycle are preserved as a
  per-entry property** (see §4 — entry-level layering makes this free). Concretely: ADRs become
  `.claude/rules/architecture.md` entries tagged `kind: decision`, decay-exempt, supersession-tracked —
  AND `docs/adr/` is **retained as the authoring/long-form home** because the Context/Decision/
  Alternatives/Consequences shape is load-bearing for *writing* a decision, while the rules entry is the
  *delivery* projection. This is the one place I spend a small amount of "two homes for one fact"
  complexity, and §4/§7 explain why it's a projection (generated, CI-checked for drift), not a duplicate.
  **Net: ADR is not a 4th store; it is a `kind:` within S1, with `docs/adr/` as its source-of-truth long
  form.** If Tanner disagrees, the fork is in §10 (Open Decision 1).

**The auto-memory subsystem is the 4th thing on disk but NOT a 4th owned store.** It is a cache the
harness rides (reads for free, never writes, cannot evict). It is in the set because the model *must
account for it* (`[inv Store 6 pathology 1]` — canon ignores it; we may not), but it is reclassified from
"store of record" to "untrusted capture cache," outranked by S1–S3 on any conflict. §2 below.

**Net: 6 owned-and-half-owned stores → 3 owned + 1 ridden cache.** The win is not the count drop alone;
it is that **the same corrected-mistake fact stops existing in 3–4 files and exists in exactly one
canonical place** (S1), with the cache copy explicitly demoted.

---

## 2. Per-store contracts — ONE writer · ONE reader (+when) · ONE freshness · LIFECYCLE-IN-TOOLING

### S1 — `.claude/rules/*.md` + CLAUDE.md floor — the durable-constraint store

The merge of `PITFALLS.md` + `.claude/memory.md` (traps) + `docs/adr/` (decisions). One canonical
constraint corpus; native `.claude/rules/*.md` shards deliver the path-scoped subset.

- **ONE writer:** **`/cr`** (codifies a trap caught in review — the existing Step 3b → PITFALLS path,
  retargeted at `.claude/rules/`, verified `[cr/SKILL.md:225]` "write PITFALLS.md entry") **and
  `/compound`** (graduates a survived auto-memory/finding into a rule — the existing Steps 5/6/9,
  retargeted, verified `[compound/SKILL.md:72,83,143]`). These are **one logical writer split across two
  trigger points** (review-time vs. compound-time), both producing the same entry shape, both writing
  through the promotion gate (S3 → S1), never editing each other's entries. The CLAUDE.md no-trigger
  safety floor (PocketOS destructive-op trio — KEEP-VERBATIM) is **human-edited only**
  `[memory: no_agent_edits_guard_files]`. *No new `/distill` skill* — C invented one; the disk already
  has the three `/compound` steps that do its job, and adding a skill violates the binding principle
  (fewer mechanisms, not more). We **rename the work, not the skill**: `/compound` Steps 5/6/9 become the
  graduation conveyor (§3).
- **ONE reader (+when):** two read paths, one native mechanism each, zero prose-only reads:
  1. **Safety + behavior floor — always.** The KEEP-VERBATIM destructive-op trio + standing behavior
     principles live in CLAUDE.md (always-loaded by the platform) — they have **no file trigger** because
     they apply to every operation, so they cannot be path-scoped (`_EMERGING-FINDINGS §3`: no-trigger
     safety content stays tier-1 regardless of length; KEEP-VERBATIM FLOOR honored). This replaces the
     prose "read memory.md every session" instruction `[inv Store 1]` with the platform's always-load.
  2. **Area constraints — by path, natively.** Everything else shards into `.claude/rules/<area>.md` with
     `paths:` globs (`capability-facts.md`: "`.claude/rules/` with `paths` globs = native path-scoped
     lazy-loading"). Editing a migration loads `.claude/rules/migrations.md` only; editing a schema loads
     `.claude/rules/schemas.md` only. This replaces the **43 KB monolithic PITFALLS read** `[inv Store 3
     pathology 3]` with a ~2 KB scoped load. The split key is the **existing `**Area:**` field** present
     on 36 PITFALLS entries (verified this session) — so the split is mechanical, not judgment.
- **ONE freshness rule:** **fires-or-evicts, with two decay-exempt classes.** Each entry carries
  `last_fired: YYYY-MM-DD` (stamped by the `/cr` pass or deterministic hook that *catches a violation*
  referencing it — B's insight: a rule earns its keep by catching something, which is a stronger signal
  than memory.md's `last_seen`-on-read). An entry not fired in **180 days** is surfaced by the drift
  detector (§8) as an eviction candidate. **Exempt:** `tier: safety` (never decays — applies always) and
  `kind: decision` (the ADR class — does not go *stale*, it goes *superseded*; carries a `superseded-by:`
  field instead, A's correct borrow from ADR's clean lifecycle).
- **LIFECYCLE-IN-TOOLING:**
  - **In (promotion S3 → S1):** `/cr` Step 3b + `/compound` Steps 5/9, retargeted from `PITFALLS.md` to
    `.claude/rules/<area>.md`. The skill steps exist; only the write *path* changes. Net-new code: a path
    retarget + the area-routing line. The shards are **generated projections** of the canonical entries; a
    `scripts/gen-rules.sh` (or a `/compound` step) regenerates them, and the drift CI (§8) asserts shard ↔
    source consistency so the projection never drifts.
  - **Out (eviction):** the drift detector (§8) flags `last_fired > 180d` (non-exempt) and dangling
    `superseded-by:` pointers; removal is **surfaced as a candidate, human-applied** (CLAUDE.md forbids
    silent edits to always-loaded knowledge; a bad auto-eviction loses a real constraint). The *clock* is
    in tooling; the *apply* keeps a human. This is B's honest seam, and it is correct.

### S2 — `docs/solutions/` — the reusable-pattern store

- **ONE writer:** `/compound` after a merged feature (existing, correct — `docs/solutions/README.md`:
  "Run /compound after the feature is merged"). Unchanged. This is the one store that already has a clean
  single-writer contract today `[inv Store 4]`; keep it.
- **ONE reader (+when):** **`/dev` and `/feature` at task-start**, via a glob-injected read step — the
  one wiring change S2 needs. Today solutions are "found only if the worker greps" `[inv Store 4 pathology
  1]`. The fix (shared by B and C, correct): a one-line task-start step that globs `docs/solutions/` for
  `tags:`/`area:` matching the files the task will touch, and loads matching pattern docs into context.
  The existing README grep-by-tag snippet becomes the *implementation* of that step. **No new index, no
  new store.**
- **ONE freshness rule:** **supersession, not time-decay** — patterns are durable; they die by being
  replaced (a `status: active | superseded-by <file>` frontmatter field, borrowed from ADR `[inv Store
  5]`). Optionally a `referenced:` no-reference-in-365-days *archive* flag (B's edge) — included as a
  drift-detector advisory, not a hard rule, because an unused-but-correct pattern is low-harm.
- **LIFECYCLE-IN-TOOLING:** the **unmet ">10 entries → add frontmatter tags" migration** (now at 33
  entries, never run — `[inv Store 4 pathology 3]`) becomes a **one-time migration + a CI assertion** that
  every solution doc carries `area:`, `tags:`, `status:`. The unenforced self-rule (§9 overhead) becomes
  enforced. The same drift CI flags any dangling `superseded-by:` pointer (a phantom ref — our live
  failure class).

### S3 — `docs/RECURRING-FINDINGS.md` — the captured-signal inbox (the airlock)

Kept as a file (not turned into B's new `journal.jsonl` — the existing ledger already has the schema, the
one real automated writer, and the signature-matching). The fix is to **wire its read-path shut and add
the second writer**, not to replace it.

- **ONE writer (logically) — two automated emitters, one schema, one matching key:**
  1. `/cr` Step 3b (exists — the **one real automated writer on disk**, `[cr/SKILL.md:174]`; appends/
     increments on the `signature` field).
  2. **The MOVE-1 session-end emitter** (the absent automated writer, §6) — a `Stop`/`SubagentStop` hook
     that **appends the same finding shape to this ledger** when a run surfaces a candidate constraint
     outside `/cr`. Both machines, both *appending observations*, matched on `signature` so there is no
     write-contention. (This is the deliberate, justified exception to strict one-writer: both produce the
     *same row kind* — one logical writer, two trigger points, exactly like S1.)
  - Humans add via a thin `/note "<finding>"` append wrapper, **never by hand-editing prose** — so the
    "added directly to PITFALLS outside the loop" path `[inv Store 3]` is removed; every trap enters here
    and promotes like everything else.
- **ONE reader (+when):** **task-entry skills at task-start** — this is the MOVE-6 fix and the close of
  the half-open loop. Today this ledger is "written by the pipeline, read only by the pipeline" `[inv
  Store 2 pathology 1]` (grep-confirmed: only PITFALLS + cr/SKILL.md reference it). We add a Phase-0 read
  step to `/dev`/`/feature`/`/cr` that globs the ledger's `signature`/`Example locations` against the
  files about to be touched and surfaces matches with their occurrence count ("you are about to edit X; a
  finding here recurred 4× in this area"). The finding becomes visible **at the moment an implementer is
  about to repeat it** — closing the loop in tooling. **The promoted half** (≥3 occurrences) lands in S1
  and is *additionally* delivered by native `paths:` auto-load (C's insight: the promotion target became a
  path-scoped store that auto-loads, so the read-path is partly the platform's).
- **ONE freshness rule:** **occurrence-count + status + a promotion clock.** Existing: `active | promoted
  | retired`, occurrence cap-at-5 `[inv Store 2]`. **New clock** (closing the "judgment gate with no
  clock" pathology, `[inv Store 2 pathology 2]`): an entry at occurrences ≥3 sitting `active` >14 days is
  flagged by the drift detector (§8) as an overdue promotion. **Decay:** an `active` entry with no new
  occurrence in **30 days** auto-retires (B's anti-noise teeth — a one-off observation that never recurred
  is noise). Retired rows >90 days old are compacted out (the file cannot grow monotonically).
- **LIFECYCLE-IN-TOOLING:** append/increment by the two emitters (one exists, one is §6); promotion-out to
  S1 by `/cr`/`/compound` (retargeted); auto-retire-on-promotion (existing status transition,
  `[cr/SKILL.md:225]`); the overdue-promotion + 30-day-decay clocks (drift CI, §8); compaction of old
  retired rows (drift CI). On promotion the entry is set `promoted` and the **drift check asserts it now
  exists in S1** — so a "promoted" finding can never be a phantom promotion.

---

## 3. The lifecycle conveyor — promotion + eviction in tooling (grafting B's spine onto existing skills)

Two mechanisms move knowledge between stages. Both are **real tooling**; neither is a new skill — they are
the **existing `/cr` and `/compound` steps given a clock and a retargeted write path.**

**Mechanism A — promotion (S3 inbox → S1 canonical).** The conveyor from captured-signal to durable-
constraint. Encoded replacement for today's clockless "human confirms before promotion" and the unrun
`/compound` Step 9.
- `/cr` Step 3b already detects ≥3-occurrence findings and surfaces promotion candidates `[cr/SKILL.md:
  183-225]`. **Retarget the write from `PITFALLS.md` to `.claude/rules/<area>.md`** (area from the
  finding's matched Area field). The candidate is *emitted* (paste-ready), the human/`/compound` applies
  it — CLAUDE.md forbids silent edits to always-loaded knowledge, and a bad auto-promotion pollutes S1.
  **But the clock is now in tooling:** the drift detector flags any ≥3-occurrence finding sitting `active`
  >14 days, so the judgment gate keeps its human but loses its ability to silently never-fire.
- `/compound` Steps 5/6/9 are the **second promotion trigger** — graduating a survived auto-memory entry
  or a feature-revealed trap into S1. Step 9 today is detection-only ("Do not modify memory.md. Surface
  candidates and wait for direction" — verified `[compound/SKILL.md:164]`) and runs "every ~90 days"
  (visibly unrun — dates are weeks stale). **The fix is the clock, not a new skill:** `rituals.md` already
  lists rituals with `last_run`/`frequency` and *already lists `scan-context`* — we add `/compound` (or a
  `memory-distill` ritual) to that heartbeat with `frequency: weekly`, so the session-start ritual check
  surfaces it on schedule. The missing primitive was a heartbeat, and **the heartbeat layer already
  exists** (`rituals.md`) — this is wiring, not a new mechanism (`_EMERGING-FINDINGS §1`).

**Mechanism B — eviction / decay (the drift detector, §8).** The exit conveyor B's whole model is built
around. One pass, all stores, all time-boxed: S3 entries auto-retire at 30 days no-recurrence; retired
rows compact at 90 days; S1 rules flag at `last_fired > 180d` (non-exempt); S2 solutions flag at
`referenced = 0 in 365d`. Every entry has a tool-driven path *out* — promote up or decay out. **No store
grows without an encoded exit.** That is the property today's six stores collectively lack `[inv
cross-store synthesis: "decay executed for none"]`, and it is the heart of the recommendation.

---

## 4. Resolving the PITFALLS.md / memory.md dual-layer (Context vs Memory) assignment

Both files are assigned to **BOTH Layer 1 (Context) and Layer 3 (Memory)** depending on canon page `[inv
Store 1 pathology 3; inv Store 3 pathology 2; map §4]`. The ambiguity exists because the *file* was the
unit of layering, and these files hold content belonging to different layers.

**Resolution (A's insight, made concrete): layer the ENTRY, not the FILE.** Once memory.md and PITFALLS
collapse into S1, there is no "PITFALLS file" or "memory file" to assign — there is one constraint store,
and each *entry* carries:
- `tier:` — *when it loads*. `tier: safety` → always-loaded (CLAUDE.md floor, ex-"Layer 1"). `tier: area`
  → path-loaded via `.claude/rules/` (native lazy context).
- `kind:` — *how it decays*. `kind: trap` → fires-or-evicts (180d). `kind: decision` → supersession-only
  (the ADR lifecycle).
- `last_fired:` / `superseded-by:` — *the freshness clock* (ex-"Layer 3 / Memory").

So **Context and Memory stop being two layers a file lives in and become two properties of one entry**:
*when it loads* (tier) and *when it decays* (freshness/kind). The dual-assignment was an artifact of
treating the file as the atom. Make the entry the atom and it disappears — **in the data model, not in
prose.** This is also exactly what lets ADR fold into S1 as a `kind: decision` entry-class without losing
its lifecycle (§1, Open Decision 1): the entry carries its own layer + decay, so a decision and a trap can
co-reside in `.claude/rules/architecture.md` and still behave differently.

---

## 5. The auto-memory subsystem (the canon-invisible 6th store) — ridden as a cache, demoted in authority

The canon ignores it; the model may not `[inv Store 6 pathology 1]`. It has the one property nothing else
has: a **fully automated writer + reader the harness does not control** — the CC memory subsystem writes
`feedback_*`/`project_*` and auto-loads the first 25 KB of `MEMORY.md` at session start
(`capability-facts.md`). We cannot stop it writing and cannot evict from it.

**This is where C is right and C is wrong simultaneously, and the graft splits the difference:**
- **C is right** that this is the free automated capture writer the curated stores lack, and that
  hand-maintaining a parallel `memory.md` is the harness re-implementing it by hand. So: **stop
  maintaining `memory.md`** (delete the file; its safety floor is already verbatim in CLAUDE.md, verified
  `[inv Store 1; map §9]`; its behavior rules are verbatim dups of CLAUDE.md → Agent behavior principles).
  Auto-memory *is* the capture inbox for raw corrected-mistakes.
- **C is wrong** to call it "the spine." A store the harness cannot write, cannot evict, and that auto-
  loads *stale facts first* (`project_test_gaps_nh7` claiming PRs are still open weeks after merge — `[inv
  Store 6 pathology 1]`) cannot be the authoritative spine. **It is a cache, not a store of record.**

**Disposition — ride + demote + fence:**
- **Read:** free, automatic (session-start auto-load). We use it.
- **Authority:** explicitly **outranked by S1–S3.** On any conflict between an auto-memory fact and a
  curated store, the curated store wins. This is the *one prose line the model cannot replace with
  tooling*, because the subsystem is not ours to hook — it goes in the CLAUDE.md floor: *"Auto-memory is a
  point-in-time cache (it carries a staleness banner). On any conflict, `.claude/rules/` and
  `docs/solutions/` win."* (Flagged as Open Decision 3 — is the subsystem hookable to make this a
  mechanism?)
- **Graduate-out:** `/compound` Step 9 (now clocked, §3) reads the `feedback_*`/`project_*` corpus; any
  entry that survived 2+ sessions and names a *codebase trap* (not a one-off process correction) is
  graduated into S1 — landing the durable knowledge in a store the harness owns and CI-checks.
- **Evict:** we cannot prune the subsystem. `/compound` *surfaces* a list of `feedback_*` files >30 days
  never-graduated with a paste-ready `rm` batch for Tanner (human-gated — destructive-op rules require it
  regardless). This is the honest version: decay is **enforced at the human-handoff boundary**, not
  faked as an eviction the harness can't perform.
- **De-dup signal (inverting the pathology):** the drift detector computes a signature per `feedback_*`
  file and asserts coverage in S1. Covered → expected redundancy (the cache caching the canonical store),
  no noise. **Un**covered → a *promotion candidate* ("auto-memory learned something S1 missed"). The
  subsystem cache becomes a free recall signal for what `/compound` forgot to capture — A's inversion,
  kept.

§9 verdict: we do not delete auto-memory (we can't, and trying is overhead). We **ride, demote, fence.**
Failure mode prevented: a stale subsystem fact treated as current truth because it auto-loaded first.

---

## 6. The absent automated WRITER (MOVE 1) — landing output IN a store

`session-end.sh` was **deliberately removed in #70 because its `claude --print` output was discarded —
never surfaced** `[FRESH GROUND TRUTH; map §3e]`. The lesson is precise: the failure was not "no emitter,"
it was **"emitter output went nowhere."** So the V2 emitter is defined **by its destination, not its
trigger** — the unifying correction across all three candidates, and they all land it correctly.

- **Mechanism:** a **`Stop`/`SubagentStop` hook** (`.claude/hooks/session-end-capture.sh`) that, on a run
  surfacing a candidate constraint (a corrected mistake, a recurred `/cr` MUST-FIX), **appends a row to
  S3 (`docs/RECURRING-FINDINGS.md`)** in the existing `signature`-matched schema. It does **not** write S1
  directly — it writes the airlock, and promotion (§3) moves it up.
- **Why S3, not S1:** landing in the inbox preserves the **promotion gate** — human-confirmed before a
  fact becomes an always-loaded constraint (§1, the floor-of-3 reasoning). An automated writer dropping
  straight into the always-loaded set is exactly the "un-vetted single observation ossifying" failure.
  S3 is the airlock.
- **Why this fixes #70:** the #70 emitter's output was discarded because it had **no store to land in and
  no reader.** Now there is: S3 has a real automated writer (`/cr` 3b) *and*, post-MOVE-6, a real
  task-start reader (§2). The row is appended to a file read at the next relevant task. **Output lands in
  a store and is read** — the exact thing #70 lacked.
- **Capability caveat (honest):** `capability-facts.md` is internally hedged on Stop-hook *force-continue*
  semantics. This emitter needs only **append-and-allow-stop** (write a row, never block) — the
  *non-controversial* Stop-hook capability (the guide confirms Stop hooks "CAN run shell commands"). We do
  **not** rely on the hedged force-continue path. ⚠️ Verify empirically that the Stop hook can see the
  turn's correction signal before relying on full automation (one-session check, MASTER-FINDINGS §G). If
  it can't, the writer degrades to `/cr` 3b (already auto) + the `/note` manual append — still strictly
  better than today, just not fully-automatic. **This is the load-bearing risk in the whole model**
  (Open Decision 2).

---

## 7. Path-scoped tiering via native `.claude/rules/` + `paths:` globs (net-new build — ABSENT today)

`.claude/rules/` is **ABSENT** (re-verified: `ls .claude/rules` → No such file). So this is a **net-new
build, not a relocation** — but it builds a *native* mechanism, not a custom loader (`capability-facts.md`:
"`.claude/rules/` with `paths` globs = native path-scoped lazy-loading"; "Skills can carry their OWN
`hooks:` and `paths:` frontmatter").

**Design:**
- The canonical constraint corpus is the set of entries (ex-PITFALLS + ex-ADR + ex-memory traps). The
  `.claude/rules/<area>.md` shards are **generated projections**, each with `paths:` glob frontmatter.
- **The split is mechanical, not judgment:** every PITFALLS entry already carries an `**Area:**` field
  (36 verified this session). Split by that field. Proposed shards (from the actual Area values observed):
  ```
  .claude/rules/
    00-safety.md          paths: (none → always loads)   PocketOS trio + NEVER list — KEEP-VERBATIM, never decays
    migrations.md         paths: ["supabase/migrations/**"]        REVOKE-after-CREATE-FUNCTION, no-CONCURRENTLY, RLS-tenant-only, grants, DEFINER token RPCs
    data-layer.md         paths: ["src/data/**","app/**/actions.ts"] cache()-wrap, no-Supabase-from-component, public-write-RPC, write-input Zod
    schemas.md            paths: ["src/schemas/**"]                 schema-file-folder-collision, timestamptz-offset, discriminated-payload location
    auth-routing.md       paths: ["proxy.ts","app/**/middleware.ts","app/(auth)/**"] PUBLIC_PATHS-at-root, redirect-pathname-only
    harness-hooks.md      paths: [".claude/hooks/**","scripts/**",".claude/settings*.json"] permission-path-relative, hook-pattern-match, perm-log, heredoc-commit
    git-worktree.md       paths: (advisory — worktree/branch ops)  worktree-remove, post-merge-branch-persist, rebase-migration-renumber, pre-push sentinel
    architecture.md       paths: ["src/**"]   the 5 ADRs as kind:decision entries (supersession-tracked, decay-exempt)
  ```
- **Tier-0 safety does NOT shard** — `00-safety.md` (and the CLAUDE.md floor) have no `paths:` because they
  apply everywhere; they load always, regardless of length (`_EMERGING-FINDINGS §3`; KEEP-VERBATIM FLOOR).
  **Tier by trigger-existence, not line-count.**
- **Generation, not hand-maintenance:** `scripts/gen-rules.sh` (or a `/compound` step) regenerates the
  shards when a canonical entry changes. The drift CI (§8) asserts shard ↔ source consistency so the
  projection never drifts. (Whether generation is a script or a skill step is Open Decision 4 — leaning
  script: "boring/deterministic, runs in CI" per the binding principle.)
- **What it replaces:** the prose "MUST read PITFALLS before writing in any affected area" (a 43 KB
  wholesale read with the relevant trap buried in 558 lines — `[inv Store 3 pathology 3]`) becomes a
  native, deterministic, scoped load of the 1–6 relevant rules. §9 failure prevented: the model paying
  43 KB token cost on every code task with the relevant constraint buried (present-but-unread). Path-
  scoping makes the relevant constraint *unavoidable* on its path and *free* (absent) everywhere else.

---

## 8. The drift / decay detector — STALE + FICTION (phantom-refs) + DECAY (one detector, in CI)

`/scan-context` is **referenced-but-absent** — it is listed in `rituals.md` (`last_run: 2026-05-27`) yet
no skill body exists `[map §6]`; **no CI check validates any knowledge artifact today** (`capability-
facts.md`). Phantom refs are our **live failure class** — the audit itself rotted (`[map §0]`). This is
**one CI check** (`scripts/scan-context.sh`, run in the existing `ci.yml` lane, deterministic) plus the
non-repo half handled by `/compound`. It catches all three classes the requirement names:

1. **DECAY (the unrun sweep, now executed).** S1 rules `last_fired > 180d` (non-exempt) → eviction
   candidate. S3 entries `active` with no occurrence in 30 days → auto-retire; retired rows >90 days →
   compact. S3 `active` + occurrences ≥3 + >14 days → overdue-promotion flag. S2 solutions `referenced=0`
   in 365 days → archive candidate. This converts the manual, visibly-unrun `/compound` Step 7 sweep
   `[inv Store 1 pathology 4]` into a check that runs every PR/push — the missing *clock*
   (`_EMERGING-FINDINGS §1`) is now CI-cadence, surfacing staleness within one PR cycle instead of "never."

2. **DOC-FICTION / phantom-refs (the live class).** For every `.claude/rules/*.md`, `docs/solutions/*.md`,
   and the knowledge docs (CLAUDE.md, AGENTS.md, INDEX.md, mcp.md): resolve every `§`-ref, backtick path,
   `@`-import, `paths:` glob target, and `superseded-by:` pointer against disk; **fail the build if any
   resolves to nothing.** Specific assertions: every `.claude/rules/*.md` entry ↔ a backing canonical
   entry (shard projection integrity, §7); every FINDINGS entry marked `promoted` exists in S1 (no phantom
   promotion); every cited script/migration/skill exists (the `claude-md-referenced-scripts-must-exist`
   rule from memory.md — *itself encoded as a check, not re-stated as prose*). **This is the assertion that
   would have caught the audit's own rot, and the phantom `/scan-context` ritual pointing at a non-existent
   skill.**

3. **DOC-STALE (claim-vs-reality, bounded).** A rule's `paths:` glob matching **zero files** (it guards a
   deleted area) → stale flag. Plus the auto-memory de-dup signal (§5): each `feedback_*` uncovered in S1
   → promotion candidate, not noise. (The PR-state staleness — `project_test_gaps_nh7` — is checked by
   `/compound`, not CI, because auto-memory lives outside the repo: `gh pr view` on entries matching `PR
   #\d+ (open|pending)` → surface for eviction. Honest boundary: the non-repo store can't be CI-gated.)

**One detector, three classes, deterministic, in CI** — replacing the absent `/scan-context` and the three
prose freshness rules that never executed. It **surfaces** (CI annotation + paste-ready), it does not
auto-edit knowledge docs (CLAUDE.md forbids silent deletion) — the clock is in tooling, the apply keeps a
human. §9 verdict: every assertion names a failure mode (stale rule fired, phantom ref followed, broken
workflow hit, learned-fact lost) — none is overhead.

---

## 9. Closing the RECURRING-FINDINGS read-path (MOVE 6) — consolidated

Today S3 is "written by the pipeline, read only by the pipeline" `[inv Store 2 pathology 1]` (grep-
confirmed). A finding logged here is invisible at the moment an implementer is about to repeat it. **Two
read-paths close it, both in tooling:**
1. **Sub-threshold findings (occurrences 1–2):** a Phase-0 read step in `/dev`/`/feature`/`/cr` globs the
   ledger's `signature`/`Example locations` against the files the task will touch and surfaces matches
   with their count — *before* code is written (§2 S3 reader). The implementer sees "this recurred 4× in
   this area" before the 5th repeat.
2. **Promoted findings (≥3 occurrences):** land in S1 `.claude/rules/<area>.md` and are delivered by
   native `paths:` auto-load whenever any implementer touches that area (§7). The read-path for the
   promoted half is *the platform's path-scoping* — no custom reader (C's insight, correct).

S1 tells you the *promoted* constraints for this path; S3 tells you the *not-yet-promoted-but-recurring*
ones. Together both halves of the constraint pipeline are readable at the point of work. §9 failure
prevented: **the harness observing the same mistake N times, codifying it, and still letting the (N+1)th
implementer repeat it because nothing put the observation in front of them** — the half-open loop, closed.

---

## (i) STORES BEFORE → AFTER

| # | Today's store (BEFORE) | Disposition | AFTER (target) | Files deleted / merged | Mechanism |
|---|---|---|---|---|---|
| 1 | `.claude/memory.md` (166 L) `[inv S1]` | **MERGE → DELETE file** | S1 (`.claude/rules/` + CLAUDE.md floor) | **File deleted.** Safety trio → CLAUDE.md floor (already there, verified) as `tier: safety`; behavior rules → deleted (verbatim CLAUDE.md dups); codebase traps → `.claude/rules/<area>.md`. Capture role → auto-memory (free). **DELETE-CANDIDATE** (CLAUDE.md forbids silent deletion). | one-time migration; capture replaced by subsystem |
| 2 | `docs/RECURRING-FINDINGS.md` (16 KB) `[inv S2]` | **KEEP + WIRE** | S3 (the airlock) | Nothing deleted. Add the §6 Stop-hook second writer + the §2/§9 task-start reader + the §3 promotion clock + §8 decay. | half-open loop wired shut, not removed |
| 3 | `PITFALLS.md` (558 L / 43 KB) `[inv S3]` | **SPLIT → DELETE monolith** | S1 (`.claude/rules/*.md`) | **File deleted** after split by its existing `**Area:**` field into ~7 path-scoped shards. 43 KB-every-task → ~2 KB-when-relevant. **DELETE-CANDIDATE.** | native `paths:` lazy-load (§7) |
| 4 | `docs/solutions/` (33 + README + TEMPLATE) `[inv S4]` | **KEEP + WIRE** | S2 | Nothing deleted. Run the unmet frontmatter-tags migration; add `/dev`+`/feature` task-start reader; add `status:`/`superseded-by:`; CI frontmatter assertion. | one-time migration + drift CI |
| 5 | `docs/adr/` (5 + README) `[inv S5]` | **PROJECT INTO S1, RETAIN long-form** | S1 `.claude/rules/architecture.md` (`kind: decision`) + `docs/adr/` retained as source | **Nothing deleted.** ADRs become decay-exempt, supersession-tracked S1 entries delivered by `paths:`; `docs/adr/` stays as the Context/Decision/Alternatives/Consequences authoring home + wired into `/cr` as criteria (its one gap). | entry-level layering (§4); projection generated + CI-checked |
| 6 | Auto-memory (52 files) `[inv S6]` | **RIDE as cache (cannot delete)** | demoted untrusted cache | **Not deleted (can't).** Reclassified: read free, authority-outranked by S1–S3, graduated-out by `/compound`, stale surfaced for human `rm`, de-dup → recall signal. | §5 (ride/demote/fence) |

**Owned-store count: 6 → 3** (S1 constraints, S2 patterns, S3 inbox) **+ 1 ridden cache.** Files
physically deleted: **2** (`.claude/memory.md`, `PITFALLS.md`) + 3 behavior-rule dup entries. **The win is
not the count — it is that the same corrected-mistake fact stops living in 3–4 places and lives in exactly
one canonical home (S1), with the cache copy explicitly demoted and the duplication collapse enforced by
*there being only one place to write a constraint* (S1, via the promotion gate), not by a prose note.**

---

## (ii) LIFECYCLE DIAGRAM — which hook/skill/CI does each write / promote / evict

```
                              ┌─────────────────────── AUTO-MEMORY (subsystem cache, ridden) ───────────────────────┐
                              │  WRITE: CC memory subsystem (free, automatic)                                        │
                              │  READ:  session-start auto-load (25 KB) — OUTRANKED by S1–S3 on conflict (CLAUDE.md) │
                              └───────────────┬──────────────────────────────────────────────┬─────────────────────┘
                                              │ graduate (survived 2+ sessions, is a trap)    │ stale >30d → surface rm batch
                                              │   /compound Step 9  (CLOCKED via rituals.md)  │   (human-gated, destructive-op rule)
                                              ▼                                               ▼
   ┌──────────────────┐   Stop-hook append    ┌────────────────────────────┐   promote (≥3 occ)        ┌─────────────────────────────────┐
   │  RUN SIGNAL      │  session-end-capture  │  S3  RECURRING-FINDINGS.md  │  /cr 3b + /compound 5/9   │  S1  .claude/rules/*.md + floor │
   │ (corrected       │ ───────────────────▶  │  (airlock / inbox)         │ ─────────────────────────▶│  (durable constraints)          │
   │  mistake, /cr    │   /cr Step 3b append   │  WRITE: /cr 3b + Stop hook │  (retarget PITFALLS→rules;│  WRITE: /cr + /compound          │
   │  MUST-FIX)       │   /note (human append) │         + /note            │   human applies; clocked) │   (gate: human-applied)          │
   └──────────────────┘                        │  READ: task-start glob     │                           │  READ: native paths: lazy-load   │
                                               │   (/dev /feature /cr P0)   │◀── sub-threshold read ────│   (+ CLAUDE.md always-load floor)│
                                               │  DECAY: 30d no-recur→retire│                           │  DECAY: last_fired>180d (non-    │
                                               │   90d retired→compact (CI) │                           │   exempt) → evict candidate (CI) │
                                               │  CLOCK: ≥3 & >14d active →  │                           │  EXEMPT: tier:safety, kind:      │
                                               │   overdue-promotion (CI)   │                           │   decision (supersession only)   │
                                               └────────────────────────────┘                           └─────────────────────────────────┘

   ┌────────────────────────────┐   write after merged feature        READ: /dev /feature task-start glob (tags/area)
   │  S2  docs/solutions/        │ ◀── /compound (existing writer)     DECAY: referenced=0 in 365d → archive candidate (drift CI)
   │  (reusable patterns)        │                                     SUPERSEDE: status:/superseded-by: frontmatter
   └────────────────────────────┘

   ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   │  DRIFT / DECAY DETECTOR  —  scripts/scan-context.sh  (CI, deterministic, replaces phantom /scan-context ritual) │
   │   • DECAY:    S1 last_fired>180d · S3 30d-retire/90d-compact/≥3&14d-overdue · S2 referenced=0/365d              │
   │   • FICTION:  every §-ref / path / @-import / paths: glob / superseded-by: resolves on disk → else FAIL build   │
   │              + every rules entry ↔ backing source (shard integrity) + every "promoted" finding exists in S1    │
   │   • STALE:    empty paths: glob (rule guards deleted area) + auto-memory feedback_* uncovered-in-S1 → promote   │
   │   ( PR-state staleness on auto-memory → /compound + `gh pr view`, NOT CI — auto-memory is outside the repo )    │
   │   SURFACES candidates (CI annotation + paste-ready); does NOT auto-edit (CLAUDE.md forbids silent deletion)     │
   └──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Writer / promoter / evictor per store, named:**
- **S1 write:** `/cr` Step 3b + `/compound` Steps 5/9 (retargeted PITFALLS→rules). **Promote-in:** same.
  **Evict:** drift CI flags `last_fired>180d`; human applies. **Generate shards:** `scripts/gen-rules.sh`.
- **S2 write:** `/compound` (existing). **Read:** `/dev`/`/feature` task-start glob. **Evict:** drift CI
  archive flag; human applies.
- **S3 write:** `/cr` Step 3b (exists) + `session-end-capture.sh` Stop hook (§6) + `/note`. **Read:**
  task-start glob in `/dev`/`/feature`/`/cr`. **Promote-out:** `/cr`+`/compound` → S1. **Evict:** drift CI
  (30d-retire, 90d-compact).
- **Auto-memory:** subsystem writes; `/compound` graduates-out + surfaces-for-rm; drift signal feeds
  promotion. Harness never writes it.
- **The heartbeat that makes the clocked steps actually fire:** `rituals.md` (`last_run`/`frequency`,
  surfaced at session start) — add `/compound` / `scan-context` at `weekly`. The layer already exists.

---

## (iii) GENUINE OPEN DECISIONS (real forks — recommendation first)

**1. ADR: project-into-S1 with retained long-form, OR keep `docs/adr/` as a full 4th owned store?**
*Recommendation: project into S1 as `kind: decision` entries AND retain `docs/adr/` as the long-form
authoring home (the model above).* This keeps the physical store count at 3 while preserving the ADR
document shape and wiring decisions into path-load + `/cr`. The fork: Candidate A would *delete* `docs/adr/`
entirely (flatten to one-line entries) for a cleaner file-count; a coherence-purist would make ADR a
distinct 4th store with no S1 projection. My middle path costs a small "two homes, one fact" (mitigated by
generation + drift CI). **Overrule toward A's full-delete if you never read the long-form ADRs and want
the count strictly minimal; overrule toward a 4th store if the projection/sync overhead annoys you more
than a fourth file.** This is the single biggest fork.

**2. Is the MOVE-1 Stop-hook capture fully automatic, or does it degrade to `/cr`-3b + `/note`?**
*Recommendation: build the Stop hook for append-and-allow-stop only (the non-controversial capability),
and treat full session-end auto-capture as "verify-then-rely."* `capability-facts.md` is hedged on whether
a Stop hook can see the turn's corrected-mistake signal. If the one-session empirical check (MASTER-
FINDINGS §G) fails, the automated-writer half degrades to `/cr` Step 3b (already auto) + `/note` manual —
still strictly better than today's prose-only memory.md write-back, but not fully-automatic. **This is the
load-bearing risk in the model.** Decide whether to gate the whole MOVE-1 build on the empirical check or
ship the degraded form first and upgrade if the hook proves capable.

**3. Can the harness influence auto-memory's load/authority, or is "S1 wins on conflict" forever a prose
line?** *Recommendation: ship the prose conflict-rule in the CLAUDE.md floor now; spend one session
probing whether the subsystem is hookable.* The §5 demotion currently rests on a single prose line ("on
conflict, curated stores win") because the CC memory subsystem is not ours to hook — it is the *one* place
in the model that is prose-only, by necessity. If there is a supported way to fence/prefix/suppress the
subsystem's auto-load (or to mark curated stores higher-priority), that line becomes a mechanism and the
last prose-only seam closes. **Decide whether this is worth a capability spike or accepted as a permanent
prose floor.**

**4. Shard generation: `scripts/gen-rules.sh` (CI-deterministic) or a `/compound` step (capture-time)?**
*Recommendation: a small `scripts/gen-rules.sh` run in CI.* Per the binding principle (boring &
deterministic is a feature), a generator that runs in the same lane as the drift detector is more robust
than a generation step buried in a skill that only fires when someone runs `/compound`. The fork is small
and either works; flagging it because it determines *when* the path-scoped shards re-sync from canonical
(every push vs. every compound). Lean script.
