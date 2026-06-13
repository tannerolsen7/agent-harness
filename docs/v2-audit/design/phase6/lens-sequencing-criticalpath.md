# Phase 6 Lens — SEQUENCING / CRITICAL-PATH

**Charge.** Own whether Phases 3+4+5 COMPOSE and in what ORDER. Map the dependency graph across MOVES 1–6,
find ordering hazards, name the genuine critical path and the minimal first slice, separate hard
prerequisites from parallelizable work, test whether canon↔disk convergence is really the universal
blocker it is claimed to be, and find circularity (golden-set feeding the gate it measures).

**Method.** Read all three Phase-3 drafts + both RECONCILIATIONs + Phase-4/5 drafts + MASTER-FINDINGS +
capability-facts. Ground-truthed every load-bearing sequencing claim on disk (the artifacts rot; I trust
disk). Adversarial, cited to artifact+section and to the disk fact.

**Verdict: CONCERNS.** The phase boundaries are clean and the *intended* order (converge → extract → ship →
validate; build measurement before trusting the gate) is sound and mostly explicit. But the integrated
build-order has **four real ordering hazards the per-phase drafts each got individually right and the
assembly never reconciles** — because no artifact owns the cross-phase graph. The single worst is a
**guard-file wiring deadlock**: the MOVE-1 Stop-hook that gates the entire compounding loop cannot be
activated without either a human guard-file edit or the Phase-4 plugin's `hooks.json` — so "MOVE-1 first"
(Phase 5's premise) and "Phase 4 ships later" (the locked sequence) are in tension that no artifact names.
None of this is architectural rework; all of it is *order and prerequisite* corrections to a sound design.

---

## A. Disk ground-truth (the anchors the dependency graph hangs on — re-verified this session)

| Claim (artifact) | Disk result | Consequence for ordering |
|---|---|---|
| `.claude/rules/` ABSENT | **Confirmed** (`ls` → No such file) | NET-NEW. S1 read-path (memory-model §7), Phase-5 *promoted-findings* read-path (§2.2), and the file tree (§5) ALL depend on it. It is a **fan-in prerequisite** for three legs. |
| `block-dangerous-bash.sh` ABSENT | **Confirmed** | NET-NEW (MOVE 2). Independent of the loop — parallelizable, on the safety critical path. |
| `session-end-capture.sh` ABSENT | **Confirmed** (no `session-end*.sh`) | NET-NEW (MOVE 1). The write-back leg's emitter. |
| A `Stop` hook is **already wired** in `settings.json:191` | **Confirmed** — it plays a sound (`afplay Glass.aiff`) | **NOT in any draft.** Adding `session-end-capture.sh` means adding a SECOND Stop hook → a `settings.json` edit → a guard file the agent may not touch. See §C hazard 1. |
| `session-start.sh` "exists, wire it" (enforcement-sort R42/R43/R44) | **Confirmed wired** (settings.json:148) but its **body only truncates a log + `npm install` in remote mode** — it does NOT read memory/rituals/fetch-prune | R42/R43/R44 are a **build (write the body)**, not "wire the existing." The heartbeat the Phase-5 cadence rides does not exist yet. |
| `ci.yml` = tsc + eslint + test:unit only; no sentinel, no dep-cruiser, no eval | **Confirmed** (4 steps) | Every CI-relocated gate (enforcement-sort (b),(c),(d); migration-lint; repo-structure; scan-context; cr-eval) is a **net-new CI lane**. CI is a shared fan-in. |
| `integration.yml` = `workflow_dispatch` only | **Confirmed** | The pattern Phase-5's `cr-eval.yml` copies — real precedent. |
| `dependency-cruiser` ABSENT from package.json | **Confirmed** | MOVE-2 L2 dep. **Phase-5 §4 L2-failure-rate metric has a hard prereq on it existing.** Both drafts say so; the assembly must surface it as a cross-phase edge. |
| `.cr-ok` gitignored (`.gitignore:58`) | **Confirmed** | The forgeable-sentinel relocation (enforcement-sort (b)) is real and is the bound on the Phase-5 trust claim. |
| `/cr` Step 3b at line 174, **writes `PITFALLS.md` (line 225)**; sentinel 242–256 | **Confirmed** | **The "one real automated writer" targets a file V2 DELETES.** Retarget is a hard prerequisite ordering edge — see §C hazard 2. |
| `/compound` reads `.claude/memory.md` only (line 143); zero `feedback_*`/`project_*`/RECURRING-FINDINGS refs | **Confirmed** | Validates RECONCILIATION-phase3 §B.1 BLOCKER: auto-memory→S1 graduation is NET-NEW, not a retarget. |
| `reviewer.md` passes `PITFALLS.md` to **each of 4 lenses** (lines 18,19,32,51) | **Confirmed** | PITFALLS deletion has a **hard dependency** on `reviewer.md` being updated first, or `/cr` breaks. See §C hazard 2. |
| `scan-context` ritual `last_run: 2026-05-27` → skill ABSENT | **Confirmed phantom** | The drift detector that guards the whole convergence gate does not exist yet. |
| `skills-lock.json` EXISTS (751 B) | **Confirmed** | Phase-4 C1 correct; the manifest precedent is real. |
| `.claude-plugin/`, `cr-eval` skill, `.claude/eval/` ABSENT | **Confirmed** | Phase-4 and Phase-5 build targets are all greenfield. |

Everything load-bearing checks out. The two facts that change the ordering picture and appear in **no**
artifact are: **(1) a Stop hook is already wired** (so MOVE-1 needs a guard-file edit to add a second), and
**(2) `session-start.sh` is wired-but-empty** (so the heartbeat is a build, not a wiring).

---

## B. The integrated dependency graph (MOVES 1–6 × Phases 3–5)

```
                    ┌──────────────────────────── THE ROOT PREREQUISITE ────────────────────────────┐
                    │  CONVERGE canon↔disk (Phase-4 §3a, 9 rows) + build scan-context drift detector │
                    │  (MOVE 3 §8) which is the convergence gate's STANDING half.                    │
                    │  Blocks: plugin publish (Phase-4 §3 "v1-ship BLOCKER"). Does NOT block: §C.     │
                    └───────────────┬───────────────────────────────────────────────┬───────────────┘
                                    │                                               │
         ┌──────────────────────────┴───────────┐               ┌───────────────────┴───────────────────┐
         │  SAFETY/ENFORCEMENT spine (MOVE 2)    │               │  MEMORY/LOOP spine (MOVE 1 + 3 + 6)    │
         │  block-dangerous-bash.sh  ───────────┐│               │  .claude/rules/ scaffold (NET-NEW) ◀── fan-in of 3 legs
         │  dependency-cruiser L2 (report→enf)  ││               │      │                                 │
         │  migration-lint / repo-structure CI  ││               │      ├─ S1 read-path (paths: globs)   │
         │  .cr-ok → CI/branch-protection ──────┼┼──────┐        │      ├─ /cr 3b RETARGET PITFALLS→rules │◀─ HARD EDGE
         │  /cr-security glob classifier        ││      │        │      ├─ reviewer.md drop PITFALLS load │◀─ HARD EDGE
         │  autoMode placement (human handoff)  ││      │        │      └─ heartbeat (session-start body) │
         └──────────────────────────────────────┘│      │        │  session-end-capture.sh Stop hook ────┼─ guard-file wiring deadlock (§C-1)
                                                  │      │        │      │ (write-back leg)               │
                                                  │      │        │      ▼                                │
                                                  │      │        │  S3 task-start reader (/dev /feature) │
                                                  │      │        └───────────────┬───────────────────────┘
                                                  │      │                        │
                          ┌───────────────────────┘      └─────────┐             │
                          ▼                                         ▼             ▼
              ┌───────────────────────────┐        ┌────────────────────────────────────────────────┐
              │  MOVE 4 — §9 re-audit on   │        │  MOVE 6 / Phase-5 — MEASUREMENT (golden set)   │
              │  Opus 4.8 (deletion engine)│◀───────│  recall number bounds .cr-ok trust (enf-sort   │
              │  TRIGGERED BY DATA, not    │  feeds │  (b)); L2-failure-rate metric NEEDS dep-cruiser │◀─ cross-phase edge
              │  calendar (Phase-5 §4)     │        │  (Phase-5 §4 ← MOVE 2). NEEDS /cr to retarget   │
              └───────────────────────────┘        │  before mining "promoted" findings as seeds.   │
                                                    └────────────────────────────────────────────────┘
                                                                     │
                          ┌──────────────────────────────────────────┘
                          ▼
              ┌──────────────────────────────────────────────────────────────┐
              │  PHASE 4 — EXTRACT plugin → SHIP v1 → VALIDATE on 3 installs  │
              │  (gated on convergence + the 2 hooks existing, §3a row 3)     │
              │  PULL channel native; PUSH-BACK = 1 design field, build later │
              └──────────────────────────────────────────────────────────────┘
```

**Reading it.** Two near-independent spines descend from the convergence root: the **enforcement spine**
(MOVE 2 + MOVE 4 cut) and the **memory/loop spine** (MOVE 1 + MOVE 3 + MOVE 6). They are genuinely
parallelizable *except* at four edges (§C) and at two shared fan-ins (`.claude/rules/`, the CI lane). The
single thing both spines and all of Phase 5 need is the **measurement number**, and measurement itself has
prerequisites in BOTH spines (`/cr` retarget on the memory side, `dependency-cruiser` on the enforcement
side). That makes measurement the *last* of the foundations to fully land, not a thing you can front-load —
which collides with Phase-5's "build measurement NOW" framing. See §C hazard 3.

---

## C. The four ordering hazards (each: the edge, why it bites, the fix)

### HAZARD 1 — MUST-FIX — The guard-file wiring deadlock (MOVE-1 ↔ Phase-4 plugin)

**The edge.** Phase-5 §1 and memory-model §6 make the `session-end-capture.sh` Stop hook the write-back
leg's emitter — "the load-bearing risk in the whole model" — and Phase-5's status line says "wire the
Phase-3 write-back ... NOW (it is the precondition for the MOVE-4 re-audit)." But **a Stop hook is already
wired in `settings.json:191`** (verified — it plays a sound). Adding a second Stop hook means **editing
`settings.json`**, which is a guard file the agent is *forbidden* to touch (`permissions.deny`,
`no_agent_edits_guard_files`, restated in Phase-4 §1 as the decisive reason to ship hooks via the plugin).

So the activation of MOVE-1 has exactly two routes, and **the drafts never reconcile which comes first**:
- **(a) Human edits `settings.json`** to add the second Stop hook — a manual guard-file change, allowed but
  a human handoff, and it must happen *before* the write-back leg can run at all.
- **(b) The plugin's `hooks/hooks.json` wires it** without touching the guard file (Phase-4 §1 "the decisive
  operational win"). But the plugin ships only *after* convergence + extraction + the 3-install gate (Phase-4
  §5) — i.e. **much later than Phase-5 wants MOVE-1 running.**

**Why it bites.** Phase-5 sequences MOVE-1 as a *now* precondition for measurement and the MOVE-4 re-audit.
Phase-4 sequences the guard-file-free hook wiring as a *plugin-era* (later) capability. Neither artifact
notices that the only agent-clean way to wire the emitter is the thing that ships last. The result: either
MOVE-1 stalls waiting for the plugin (breaking Phase-5's order), or a human hand-wires a second Stop hook
now (fine, but it is an unacknowledged human-handoff prerequisite that should be in the first slice, not
discovered mid-build).

**The fix.** State the prerequisite explicitly and pick route (a) for v1: **the first slice includes a
human guard-file edit adding `session-end-capture.sh` as a second Stop hook entry** (paste-ready, NEEDS-
HUMAN, same pattern as the autoMode placement fix). The plugin's `hooks.json` (route b) *replaces* that hand
edit at extraction time. This is the same human-handoff class the autoMode fix already is — it just needs to
be named as a MOVE-1 prerequisite, not assumed away. Add it to Phase-4 §3a as a 10th convergence/setup row.

### HAZARD 2 — MUST-FIX — The PITFALLS-deletion ↔ `/cr`-writer ↔ reviewer ordering triangle

**The edge.** Three facts on disk, three artifacts, one unsequenced triangle:
1. `/cr` Step 3b **writes `PITFALLS.md`** (line 225, verified) — it is "the one real automated writer."
2. `reviewer.md` **passes `PITFALLS.md` to each of 4 lenses** (lines 18,19,32,51, verified) — `/cr`'s
   adversarial pass reads it.
3. The memory model (§(i) row 3) + file tree (§2) **DELETE `PITFALLS.md`** (split into `.claude/rules/`).

If PITFALLS is deleted **before** (1) is retargeted and (2) is updated, the next `/cr` run's Step 3b writes
to a dead path and `reviewer.md` passes a non-existent file to four parallel sub-agents. The memory model
says "retarget the write *path*" (§2 S1) and the file tree says "MOVE-1/2 *add*" — both correct in
isolation — but **neither makes the retarget-and-reviewer-update a hard PREDECESSOR of the deletion.** The
drift detector (scan-context FICTION class) would *catch* a dangling PITFALLS ref, but only after the fact,
and only if it exists yet (it doesn't — it is itself net-new).

**Why it bites.** This is the classic "delete the thing other live code reads" hazard, and `/cr` is the
single most load-bearing component (Phase-5 §3.1). A botched order doesn't just lose a file — it breaks the
review gate the whole pipeline hangs on, silently (Step 3b failing to write is not loud).

**The fix.** Encode the deletion order as a hard sequence, not three independent dispositions:
**(i) build `.claude/rules/` + gen-rules.sh; (ii) retarget `/cr` Step 3b write → `.claude/rules/<area>.md`
via the promotion gate; (iii) update `reviewer.md` to pass the relevant shard(s) instead of the PITFALLS
monolith (this is also the ~172 KB → ~2 KB token win the file tree headlines); (iv) ONLY THEN flag
`PITFALLS.md` DELETE-CANDIDATE.** Steps (ii) and (iii) are the predecessors the deletion currently lacks.
This belongs in the build-order as one atomic "PITFALLS retirement" unit.

### HAZARD 3 — SHOULD-FIX — "Build measurement NOW" has two unacknowledged upstream prerequisites

**The edge.** Phase-5 §5 + §7.6 say build the minimal recall harness **NOW** because it is the precondition
for trusting every gate and for the MOVE-4 re-audit. But the golden set's own design gives it two upstream
dependencies inside the *other* spines:
- **Seed source #1** is "real historical promoted MUST-FIX findings — mine `RECURRING-FINDINGS.md`." Those
  promoted findings live in PITFALLS today and the promotion path is mid-retarget (Hazard 2). Mining
  "promoted" findings as golden seeds while the promotion target is moving means seeding from a store whose
  schema/home is in flux. Phase-5 §3.6 even wires `/cr` Step 3b as the golden-case feeder — the *same* Step
  3b that Hazard 2 is retargeting. So the golden-set writer inherits Hazard 2's ordering.
- **The L2-failure-rate metric** (§4 item 2) is "gated on MOVE 2's `dependency-cruiser` L2 job existing" —
  Phase-5 says so explicitly. `dependency-cruiser` is ABSENT (verified). So one of the two compounding
  outcome signals cannot be wired until the enforcement spine lands its L2 rig.

**Why it bites.** Not fatal — Phase-5 already defers the L2-rate append to "build when L2 lands," and the
recall harness *can* be seeded from the hand-authored adversarial cases (source #3) alone without the
historical mine. But the framing "build measurement NOW, it is the precondition for everything" overstates
independence. Measurement is the *keystone* in the arch sense — it is placed LAST and locks the others —
not a foundation you pour first. The honest order: the **hand-authored adversarial corpus** (source #3) is
the genuine first-slice measurement (it has no upstream deps); the **historical mine** (source #1) and the
**L2-rate signal** wait on Hazard 2 and on `dependency-cruiser` respectively.

**The fix.** Split Phase-5's "build now" into two: (a) **NOW, no deps** — the ~6–10 hand-authored
adversarial cases + the deterministic scorer + `/cr-eval`, producing a baseline recall number against Opus
4.8 (this is all you need to bound the `.cr-ok` trust claim and to give MOVE-4 a measured baseline). (b)
**AFTER the PITFALLS retirement + after dependency-cruiser** — the historical-finding mine and the
L2-failure-rate time-series. This preserves Phase-5's correct insight (measurement before trust) while
fixing the false "no upstream deps" implication.

### HAZARD 4 — SHOULD-FIX — Convergence is the plugin's blocker, NOT the universal blocker (the claim is overstated)

**The edge.** Phase-4 §3 calls canon↔disk convergence "the v1-ship BLOCKER" and the locked sequence
(MASTER §B MOVE 5, restated everywhere) puts "converge FIRST" at the head of the whole program. The
sequencing question I was charged to test: **is convergence really the universal blocker?**

**Tested — and it is NOT.** Convergence blocks exactly one thing: **publishing a coherent versioned
plugin** (you cannot version-distribute a harness whose canon and disk disagree — Phase-4 §3, correct). It
does **not** block:
- `block-dangerous-bash.sh` (a self-contained safety guard — the most-cited gap; nothing about it depends on
  canon matching disk).
- `dependency-cruiser` report-mode L2 (a CI rig keyed off the actual file tree, not the canon's claims).
- The `.cr-ok` → CI relocation (branch-protection + a CI re-derive — independent of canon prose).
- The minimal golden-set recall harness (reads real diffs, not canon).
- Building `.claude/rules/` + the `/cr` retarget (operates on disk reality).

In fact the drift detector (`scan-context`, MOVE 3 §8) is *part of* the convergence gate's standing half —
so "converge first" partially depends on "build the drift detector first," which is itself a MOVE-3 build.
Convergence is a **publish-time gate**, correctly placed before STEP 1 (extract) in Phase-4 §5, but the
program-level "converge FIRST before anything" reading (inherited from the locked sequence) would
needlessly serialize the entire safety + enforcement + measurement spine behind a documentation-
reconciliation task. That is the opposite of de-risking.

**Why it bites.** If Tanner reads "converge first" as "do nothing else until canon == disk," the highest-
value, lowest-risk, fully-independent work (the bash guard, the forgeable-sentinel fix, the recall baseline)
gets queued behind a prose-reconciliation chore. The binding principle is "empower the model, keep code/data
safe" — the safety guard should not wait on a doc-merge.

**The fix.** Re-scope the claim precisely: **convergence is the PUBLISH gate (blocks STEP 1 extraction /
plugin v1), not the program gate.** The safety + enforcement + measurement spines run in PARALLEL with
convergence. Only the *extraction/ship* path waits on it. State this in the build-order so the parallelism
is licensed, not accidentally serialized.

---

## D. Circularity check (the charge's explicit question: does the golden set feed the gate it measures?)

**Examined the two candidate loops; one is benign-by-design, one needs a guard.**

1. **Golden set ← `/cr` Step 3b feeder, and golden set measures `/cr` (Phase-5 §3.6 ONE-writer).** This
   *looks* circular (the thing measured feeds its own measurement corpus) and Phase-5 is aware of it ("this
   closes the recursion"). It is **benign because the human-confirm gate breaks the loop**: Step 3b *emits a
   candidate*, a human confirms the label before it counts (`human_confirmed: true`, the never-self-certify
   rule). The scorer is deterministic, not `/cr` grading itself. So the corpus grows from the loop but the
   *label* is external. **Not a vicious cycle — but the guard (human confirm) is the ONLY thing keeping it
   acyclic.** If the §3.6 auto-feeder is built before the human-confirm step is enforced (Phase-5 defers the
   auto-feeder to "later"), the loop closes viciously: `/cr` would seed cases tagged with `/cr`'s own
   verdict, then score itself against them = authority laundering. **Sequencing rule: the human-confirm gate
   MUST exist and be enforced before the §3.6 auto-feeder is wired.** Phase-5 §5 already orders the auto-
   feeder "after the manual corpus proves the format" — good — but it does not explicitly bind the auto-
   feeder behind the human-confirm enforcement. Make that bind explicit. (SHOULD-FIX, folded into Hazard 3.)

2. **Recall number bounds `.cr-ok` trust, and `.cr-ok` gates the pipeline that produces the diffs the
   golden set is seeded from.** Traced it — **not circular**: the golden set is seeded from *historical*
   diffs (already-merged, already-human-judged), not from the current run's `.cr-ok`. The recall number is a
   coverage *bound* on a trust claim, not an input to the gate's pass/fail. No cycle.

**Net on circularity: the design is acyclic IFF the human-confirm gate precedes the auto-feeder.** That is a
real sequencing constraint, currently implicit. Make it explicit and the loop is clean. I attacked this
hardest (it is the charge's named risk) and could not find a vicious cycle that survives the human-confirm
gate — which is the honest answer: the design anticipated it.

---

## E. The genuine critical path + the recommended first slice

**Critical path** (longest chain of hard predecessors to a trustworthy, self-measuring loop):

```
build .claude/rules/ + gen-rules.sh                    (fan-in prereq; net-new native mechanism)
  → retarget /cr Step 3b write PITFALLS→rules          (Hazard 2 predecessor)
  → update reviewer.md to load shards not PITFALLS      (Hazard 2 predecessor; also the token win)
  → flag PITFALLS.md DELETE-CANDIDATE                   (only now safe)
  → wire S3 task-start reader into /dev /feature /cr    (read-path leg)
  → [human] add session-end-capture.sh as 2nd Stop hook (Hazard 1 predecessor)
  → build minimal golden set (adversarial cases) + scorer + /cr-eval
  → run once vs Opus 4.8 → baseline recall number       (bounds .cr-ok trust; gives MOVE-4 its data)
```

Everything else (the bash guard, dependency-cruiser report-mode, migration-lint, repo-structure,
`.cr-ok`→CI, `/cr-security` classifier, autoMode placement) is **off the critical path and parallelizable** —
high-value, independently shippable, and NOT blocked by convergence (Hazard 4). Phase-4 extraction/publish
is the *last* stage and is the only thing convergence truly gates.

**Recommended FIRST SLICE (the minimal value-delivering, risk-reducing increment):**

1. **`block-dangerous-bash.sh`** — the most-cited single gap, zero upstream deps, pure safety win. Ship it
   alone first; it de-risks every subsequent unattended run. (MOVE 2.)
2. **`.claude/rules/` scaffold + `00-safety.md` + ONE real area shard (`migrations.md`)** + `gen-rules.sh` —
   proves the native `paths:` mechanism end-to-end on the highest-density area before sharding all 8. This is
   the fan-in prerequisite; build it small and prove it. (MOVE 3.)
3. **The PITFALLS-retirement unit** for that one area only (retarget Step 3b for migrations findings, update
   reviewer.md, leave the rest of PITFALLS intact) — proves Hazard 2's order is correct on a slice before
   doing it wholesale.
4. **The hand-authored adversarial golden set (~6–10 cases) + deterministic scorer + `/cr-eval`, run once
   against Opus 4.8** — the baseline recall number. No upstream deps (uses hand-authored cases, not the
   historical mine), and it is the precondition for trusting the `.cr-ok` gate and for making the MOVE-4
   re-audit data-driven instead of opinion.

Slice 1 is safety; slice 2–3 prove the memory-model mechanism + the deletion order on one area; slice 4
delivers the measurement keystone in its dependency-free form. **This slice touches all three phases, proves
every load-bearing mechanism once, and serializes nothing behind convergence.** Convergence + full sharding +
extraction follow once the slice validates the pattern.

**What must be a HARD prerequisite (cannot parallelize):**
- `.claude/rules/` exists *before* any read-path leg or PITFALLS deletion.
- `/cr` Step 3b retarget + reviewer.md update *before* PITFALLS deletion (Hazard 2).
- Human Stop-hook wiring *before* the write-back leg runs (Hazard 1).
- `dependency-cruiser` exists *before* the L2-failure-rate metric (Hazard 3).
- Human-confirm gate enforced *before* the golden-set auto-feeder (Circularity §D.1).
- Convergence green *before* plugin extraction/publish (Hazard 4 — and ONLY that).

**What is genuinely PARALLELIZABLE:** the entire enforcement spine (bash guard, dep-cruiser report-mode,
migration-lint, repo-structure, `.cr-ok`→CI, `/cr-security` classifier, autoMode placement) runs alongside
the memory/loop spine; the minimal golden set runs alongside both.

---

## F. Why I did not rubber-stamp — and the one claim I attacked hardest that held

The hardest claim I tried to break was Phase-5's **"the loop measures itself — this closes the recursion"**
(§3.6) — i.e. the charge's named circularity risk (golden set feeds the gate it measures). I traced both
loops on disk-grounded facts and **could not produce a vicious cycle that survives the human-confirm gate.**
The design genuinely anticipated it: deterministic scorer + external human label + Step-3b-emits-candidate-
not-verdict. The only residual is a *sequencing* constraint (human-confirm must precede the auto-feeder),
not an architectural cycle. That is the honest result: the measurement design is the strongest artifact in
the set on my axis, and its one weakness is an unstated build-order edge, not a flawed model.

Where the design is genuinely weak on my axis is the **assembly gap**: each phase got its own internal order
right, but **no artifact owns the cross-phase graph**, so four edges that only exist *between* phases
(Hazards 1–4) are unsequenced. That is exactly the failure class a sequencing lens exists to catch, and it
is fixable with ordering statements, not redesign.

---

## G. Findings summary

| # | Severity | Finding | Fix |
|---|---|---|---|
| 1 | **MUST-FIX** | Guard-file wiring deadlock: the MOVE-1 Stop emitter (gates the whole loop, "load-bearing risk") needs a 2nd Stop hook, but a Stop hook is already wired in `settings.json:191` (verified) — so it needs a human guard-file edit OR the Phase-4 plugin `hooks.json`, which ships LAST. Phase-5 wants MOVE-1 NOW; the agent-clean wiring is the thing that ships last. Unsequenced. | Name the human guard-file edit as a MOVE-1 prerequisite in the first slice (paste-ready NEEDS-HUMAN, like autoMode); the plugin `hooks.json` replaces it at extraction. Add as Phase-4 §3a row 10. |
| 2 | **MUST-FIX** | PITFALLS deletion has three live readers/writers unsequenced: `/cr` Step 3b WRITES it (line 225), `reviewer.md` passes it to 4 lenses (lines 18/19/32/51), and V2 DELETES it — all verified on disk. Delete-before-retarget breaks the review gate silently. | Encode an atomic "PITFALLS retirement" order: build rules/ → retarget Step 3b → update reviewer.md → only then flag delete. |
| 3 | **SHOULD-FIX** | "Build measurement NOW" overstates independence: seed source #1 (historical promoted findings) inherits Hazard 2's retarget; the L2-failure-rate signal is gated on `dependency-cruiser` (ABSENT, verified). | Split Phase-5 "build now" into (a) dependency-free hand-authored corpus + scorer + baseline run NOW, (b) historical mine + L2-rate AFTER their upstreams land. |
| 4 | **SHOULD-FIX** | Convergence is claimed as the universal "v1-ship BLOCKER" / "converge FIRST" but tested-and-false as a program gate: it blocks only plugin publish/extraction. The bash guard, dep-cruiser, `.cr-ok`→CI, and the recall baseline have ZERO dependency on canon==disk. Reading it as a program gate needlessly serializes the safety spine behind a doc chore. | Re-scope: convergence is the PUBLISH gate (blocks STEP 1 extraction only). License the enforcement + memory + measurement spines to run in parallel with it. |
| 5 | **CONSIDER** | The golden-set self-feeding loop (§3.6) is acyclic ONLY because of the human-confirm gate; Phase-5 defers the auto-feeder but does not explicitly bind it behind human-confirm enforcement. If built out of order it becomes authority laundering. | Add an explicit sequencing rule: human-confirm enforcement precedes the §3.6 auto-feeder. (Folds into finding 3.) |
| 6 | **CONSIDER** | Enforcement-sort R42/R43/R44 say "wire existing `session-start.sh`" for the heartbeat, but its body (verified) only truncates a log + `npm install` in remote mode — it reads no memory/rituals/fetch-prune. The heartbeat the Phase-5 cadence rides is a BUILD, not a wiring. | Relabel R42–R44 as "write the session-start body," and note the Phase-5 ritual cadence depends on this build, not an existing reader. |

**topConcern:** No artifact owns the cross-phase dependency graph, so four ordering edges that exist only
*between* phases go unsequenced — the worst being the guard-file wiring deadlock (Hazard 1): the MOVE-1 Stop
emitter that gates the entire compounding loop can only be wired agent-cleanly by the Phase-4 plugin, which
ships last, while Phase-5 treats MOVE-1 as a now-precondition. The fix is ordering statements + a named
human handoff, not redesign.
