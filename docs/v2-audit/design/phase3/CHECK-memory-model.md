# Adversarial Check — V2 Memory Model (Phase 3)

**Checker ≠ doer.** Attacking `docs/research/v2-audit/design/phase3/memory-model.md` on the six required
axes. Every load-bearing claim was re-ground-truthed on disk this session (Bash/Grep/Read) — the audit
rots, so I trusted nothing the doc asserted without re-running it.

**Verdict: SOUND-WITH-CORRECTIONS.**

The model's spine is correct and well-defended: entry-as-atom dissolves the dual-assignment in the data
model (not prose), the airlock/promotion-gate guard against auto-promotion is the right "do not
over-collapse" constraint, and riding auto-memory + native `paths:` instead of hand-rolling is the
correct read of C. The citations are unusually disciplined — I tried to kill several and most survived.
But there are **two high-severity blockers** (one a RED-FLAG net-additions problem the doc never
reconciles; one a phantom/capability claim about `/compound` reading auto-memory that is false on disk),
plus four required corrections. None is fatal to the model — all are fixable without re-architecting.

---

## Ground-truth log (what I re-verified, and the result)

| Claim in doc | Disk check | Result |
|---|---|---|
| `.claude/rules/` ABSENT | `ls .claude/rules` → No such file | ✅ confirmed |
| `**Area:**` on 36 PITFALLS entries | `grep -c '\*\*Area:\*\*' PITFALLS.md` → 36 | ✅ count exact — **but see Blocker 1 / Correction A: the field is free-text, not a categorical enum** |
| RECURRING-FINDINGS half-open (ref'd only by PITFALLS + cr/SKILL) | `grep -rl` excl. audit tree → exactly `cr/SKILL.md`, `PITFALLS.md`, the file itself | ✅ confirmed — the half-open loop is real |
| `/cr` Step 3b = real automated writer | `cr/SKILL.md:174` "Step 3b — Recurring findings update"; `:225` "write PITFALLS.md entry" | ✅ confirmed |
| auto-memory = 52 files | `ls .../memory/` → 52 (MEMORY.md + 51 siblings) | ✅ confirmed |
| `session-end.sh` ABSENT | `ls .claude/hooks/` → 5 hooks, none session-end | ✅ confirmed |
| `scan-context` phantom ritual | `rituals.md:13-15` lists it (`last_run: 2026-05-27`); no skill body | ✅ confirmed phantom |
| `rituals.md` has `last_run`/`frequency` heartbeat | `:9-10` `frequency: weekly` etc. | ✅ confirmed — heartbeat layer exists |
| memory.md safety floor dup'd in CLAUDE.md | `head -40 .claude/memory.md` = verbatim PocketOS trio, also in CLAUDE.md | ✅ confirmed |
| `/compound` Steps 5/6/9 do graduation | `compound/SKILL.md:72,80,139` | ⚠️ **partly false — see Blocker 2** |
| capability-facts: `paths:` native, Stop-hook hedged on force-continue | re-read in full | ✅ doc's hedging matches the source |

---

## Axis 1 — PHANTOM (the #1 failure class)

**One genuine phantom found (Blocker 2). The rest survive.**

- `.claude/rules/` — correctly cited as ABSENT and labeled "net-NEW build, not a relocation." Matches
  FRESH GROUND TRUTH. **Not a phantom.**
- The Stop hook (§6) — correctly grounded against `session-end.sh` removed in #70. **Not a phantom.**
- `scripts/scan-context.sh` — correctly replaces the *phantom* `/scan-context` ritual (referenced-but-
  absent), and the doc explicitly cites that phantom rather than re-proposing the ritual. **Good — this is
  the doc using the anti-phantom rule correctly.**
- **`/note` skill/wrapper (§3 S3 writer, §ii)** — proposed as a "thin `/note "<finding>"` append wrapper."
  `ls .claude/skills/ | grep note` → absent. This is a **net-NEW skill**, and the doc does not flag it as
  new or cite its absence. It is a minor phantom-adjacent: the doc smuggles in a new skill while the whole
  model's thesis is "fewer mechanisms, rename the work not the skill" (it explicitly refuses C's `/distill`
  on exactly this ground). **Correction C below.**

- **BLOCKER 2 — `/compound` does NOT read auto-memory; §5 and §3 assert it does.** §5 says *"`/compound`
  Step 9 (now clocked) **reads the `feedback_*`/`project_*` corpus**; any entry that survived 2+ sessions…
  is graduated into S1."* §1 cites `[compound/SKILL.md:72,83,143]` for "graduates a survived **auto-memory**
  /finding into a rule." I read the skill: `grep -niE 'feedback_|project_|auto-memory|subsystem|projects/.*memory'
  compound/SKILL.md` returns **nothing**. Step 9 (`:139-163`) reads `.claude/memory.md` only — the
  *curated* file, not the auto-memory subsystem dir. Steps 5/6 target PITFALLS.md and memory.md. **No
  existing `/compound` step touches the `~/.claude/projects/.../memory/` corpus at all.** So the doc's
  load-bearing claim "the graduation conveyor for auto-memory already exists, we just retarget it" is
  **false** — graduating auto-memory→S1 is a *net-new capability for `/compound`*, not a retarget of an
  existing step. This directly weakens the §0 "rename the work, not the skill" promise and undercuts §5's
  de-dup/recall-signal mechanism (which presumes `/compound` already walks the corpus). The model still
  works, but this is a **build, not a wiring**, and must be re-labeled. **This is the load-bearing claim I
  killed — see "Kill attempt" below.**

## Axis 2 — CITATION-INVALID

Citation discipline is the doc's strongest quality. Spot-checks held: `[cr/SKILL.md:174]`, `[:225]`,
`[inv Store N pathology M]` map cleanly, the 36-Area count is exact, the `.claude/rules/` and
`session-end.sh` absences are real. **One invalid citation:** the `[compound/SKILL.md:72,83,143]`
attribution for "graduates a survived **auto-memory** entry" — lines 72/80/143 are about PITFALLS-promotion
and **memory.md** review, none about auto-memory (Blocker 2). The line numbers exist; the *claim they
support* does not. **Correction B.** No other change lacks a citation.

## Axis 3 — MORE-NOT-FEWER (the RED FLAG) — **BLOCKER 1**

**This is the most serious finding. The doc measures the wrong quantity and hides the increase.**

The doc's headline win is *"owned-store count 6 → 3"* and *"Files physically deleted: 2."* Both are true.
But the binding principle's red flag is about **files / stores / mechanisms** — and on **files and
mechanisms the model is a net ADDITION**, which the doc never states. My independent tally:

**Files DELETED: 2** — `.claude/memory.md`, `PITFALLS.md`.

**Files/mechanisms ADDED (all net-new, all verified absent on disk):**
1. `.claude/rules/` dir + **8 shard files** (`00-safety`, `migrations`, `data-layer`, `schemas`,
   `auth-routing`, `harness-hooks`, `git-worktree`, `architecture`) — §7.
2. `scripts/gen-rules.sh` — §7 / Open Decision 4.
3. `scripts/scan-context.sh` — §8.
4. `.claude/hooks/session-end-capture.sh` (Stop hook) — §6.
5. `/note` skill/wrapper — §3 (Axis 1).
6. New CI assertions wired into `ci.yml` — §8 (a mechanism, even if not a "file").
7. New `rituals.md` entry + ritual-heartbeat clocking of `/compound` — §3 (a mechanism).

**Net file delta: −2 + ~11 = ≈ +9 files** (8 shards + 2 scripts + 1 hook, before counting `/note` and CI
wiring). The *store* count drops 6→3+1; the *mechanism/file* count **rises substantially.** The 43 KB→2 KB
read-cost reduction is a real and good win, and entry-as-atom genuinely collapses duplication — but the
disk footprint grows, and **the doc never reconciles this.** A V2 artifact with ~9 more files than V1,
presented as a consolidation, is precisely the RED FLAG the brief names. The doc is not *wrong* that this
is a net improvement (fewer authoritative homes for a fact, deterministic decay, native delivery) — but it
**fails the requirement to honestly judge net delta** and instead picks the one metric (owned-store count)
that improves. **Correction A: the doc must state the net file delta explicitly, justify the +9 against the
binding principle, or shrink it** (e.g. fewer shards — the 8-way split is a judgment call, not forced;
several shards have 1–4 entries and could merge; `gen-rules.sh`+`scan-context.sh` could be one script).

I do **not** rate this UNSOUND, because the additions are *mechanisms that retire advisory prose* (the
spine thesis: "fewer files, more wiring" — but here it's "more files, more wiring, less prose"). The
honest framing is: **this trades 2 monolithic always-read files for ~11 small deterministic ones.** That
may be the right trade. But it must be *named and defended as an increase*, not hidden behind the
store-count drop.

## Axis 4 — §9-OVERHEAD (name a failure mode or it's overhead)

Mostly clean — almost every store/rule carries a named failure mode. Two soft spots:

- **The 8-shard granularity is not justified per-shard.** `git-worktree.md` and `harness-hooks.md` are
  both "advisory / no clean path glob" (worktree ops have no file path; the doc admits `paths: (advisory)`).
  A shard with `paths: (advisory — worktree/branch ops)` does **not** auto-load via the native mechanism —
  there's no file being edited to trigger it. So `git-worktree.md` gets none of the §7 path-scoping benefit
  and is just a file you still have to know to read. **Failure mode for keeping it as a separate shard:
  unnameable** — it behaves identically to a section of an always-loaded file but with worse discoverability.
  Either fold worktree/branch traps into `00-safety.md` (always-load) or accept they stay advisory-prose.
  **Correction D.**
- The `referenced=0 in 365d` archive flag for S2 (§2) is explicitly downgraded to "advisory, low-harm" by
  the doc itself — which is the doc *correctly* applying §9 (an unused-but-correct pattern is low-harm).
  Good. Not overhead because it's advisory-only.

The KEEP-VERBATIM floor (PocketOS trio, tier:safety always-load) is honored throughout. ✅

## Axis 5 — REQUIREMENT-MISS (must satisfy EVERY Phase-3 requirement)

| Requirement | Met? | Note |
|---|---|---|
| Concrete store set | ✅ | S1/S2/S3 + ridden cache, named with disk homes |
| Per-store 1 writer / 1 reader / 1 freshness + lifecycle-in-tooling | ✅ (with caveat) | §2 contracts are explicit; "one logical writer, two trigger points" is a defensible relaxation, honestly flagged |
| 6 → target migration | ✅ | §(i) BEFORE→AFTER table, per-store disposition |
| Account for auto-memory | ⚠️ | §5 rides/demotes/fences it — but the graduation mechanism it relies on (`/compound` reading the corpus) **does not exist** (Blocker 2). The *disposition* is sound; the *implementing tooling* is mis-cited as existing |
| Resolve PITFALLS/memory dual-assignment | ✅ | §4 entry-as-atom (`tier:`+`kind:`) — genuinely dissolves it in the data model. **Strongest part of the doc** |
| Collapse triple-duplication in tooling | ⚠️ | Collapses it to "one place to write a constraint (S1 via the gate)" — correct in principle. But the auto-memory copy is *demoted by a prose line* (§5 authority rule), explicitly "the one prose line the model cannot replace with tooling." So duplication-collapse is *enforced in tooling for S1/PITFALLS/memory.md, but the auto-memory third copy is collapsed only by prose.* Honestly flagged as Open Decision 3, so not a miss — but the requirement "in tooling not prose" is **partially** met |
| Native `.claude/rules/` + `paths:` tiering | ✅ | §7, correctly native, cites capability-facts |
| MOVE-1 automated writer landing IN a store | ✅ | §6 — lands in S3, the airlock; correctly diagnoses #70 as "output went nowhere" |
| Drift/decay detector (stale + fiction + decay) | ✅ | §8 — three classes, one CI check, deterministic. Well-specified |
| RECURRING-FINDINGS read-path | ✅ | §9 — task-start glob + promoted-half via `paths:`. Closes the half-open loop |
| FEWER than 6 stores | ✅ stores / ❌ files | 3 owned + 1 ridden < 6 stores. But see Blocker 1: **more files** |

**No hard requirement is wholly missed.** Two are partially met and honestly flagged (auto-memory tooling,
prose-only third-copy collapse).

## Axis 6 — CAPABILITY-VIOLATION

Checked every mechanism against `capability-facts.md`. **No outright violation; one risk correctly
isolated; one unverified assumption.**

- **§6 Stop hook — correctly scoped.** The doc relies only on "append-and-allow-stop" (the
  non-controversial capability: "Stop hooks CAN run shell commands"), explicitly *refuses* the hedged
  force-continue path, and flags the empirical check as Open Decision 2 / the load-bearing risk. This is
  exactly the discipline the brief demands. ✅ **But** — the deeper unverified assumption is not
  force-continue, it's **whether a Stop hook can even *see the turn's corrected-mistake signal*** to know a
  candidate constraint exists. capability-facts says a Stop hook runs shell commands and can read state; it
  does **not** confirm the hook receives "the model was corrected this turn" as structured input. The doc
  acknowledges this ("⚠️ Verify empirically that the Stop hook can see the turn's correction signal") — so
  it's flagged, not violated. Keep it flagged as load-bearing. ✅ (honest)
- **§5 auto-memory authority demotion** — the doc correctly does **not** assume the subsystem is hookable;
  it explicitly states "the subsystem is not ours to hook" and makes the conflict-rule a prose floor,
  flagging hookability as Open Decision 3. **No capability over-claim.** ✅
- **autoMode / managed-settings** — not invoked by this artifact (correctly — that's MOVE 2's turf). No
  violation.
- **The one to watch:** §7 assumes `.claude/rules/*.md` shards auto-load by `paths:` glob. capability-facts
  confirms "`.claude/rules/` with `paths` globs = native path-scoped lazy-loading" — ✅ supported. But the
  `git-worktree.md` shard has **no path glob** (worktree ops aren't file-path-triggered), so it will **not**
  auto-load — a latent capability mismatch the doc papers over with `paths: (advisory)`. See Correction D.

---

## Kill attempt (required) — did a load-bearing claim survive?

**Target: "The graduation conveyor already exists — we rename the work, not the skill."** This is the
doc's §0 thesis-level promise and its single strongest defense against the "more mechanisms" charge: it
claims every promotion/graduation path is an *existing* `/cr` or `/compound` step merely *retargeted*, so
the model adds no new graduation skill (and explicitly rejects C's `/distill` on this ground).

**Result: PARTIALLY KILLED.** For the S3→S1 trap-promotion path, it survives — `/cr` Step 3b and the
PITFALLS-write at `:225` genuinely exist and a retarget is real wiring. **But for the auto-memory→S1
graduation path it is false:** no `/compound` step reads `feedback_*`/`project_*` (grep returns nothing;
Step 9 reads `.claude/memory.md` only). So the claim "the disk already has the steps that do `/distill`'s
job" is **half true** — true for curated-finding promotion, **false for auto-memory graduation**, which is
the exact job §5 leans on most. The model didn't avoid building a graduation mechanism; it relabeled a
*non-existent* `/compound` capability as existing. The load-bearing claim **does not fully survive.** This
is Blocker 2, and it's why the verdict is SOUND-WITH-CORRECTIONS rather than SOUND.

---

## BLOCKERS (high-severity — must fix)

1. **NET-FILE-INCREASE UNRECONCILED (RED FLAG).** The model deletes 2 files and adds ≈11 (8 shards + 2
   scripts + 1 hook, plus `/note` + CI wiring). The doc reports only "owned-store 6→3" and "2 files
   deleted," never the +9 file delta. A consolidation artifact that grows the file count by ~9 must state
   and defend that, or shrink it. Pick: (a) explicitly justify "+9 files trades 2 always-read monoliths for
   N deterministic small ones" as the right trade, OR (b) reduce shard count (the 8-way split is a judgment
   call; merge 1–4-entry shards; combine `gen-rules.sh`+`scan-context.sh`).

2. **PHANTOM/MIS-CITED `/compound` auto-memory graduation.** §5 + §1 + §3 assert `/compound` Steps 5/6/9
   already read the auto-memory corpus and graduate entries to S1 — they do not (verified: zero references
   to `feedback_*`/`project_*`/the memory subsystem dir in `compound/SKILL.md`; Step 9 reads
   `.claude/memory.md` only). Graduating auto-memory→S1 is a **net-new `/compound` capability**, not a
   retarget. Re-label it as a build, fix the `[compound/SKILL.md:72,83,143]` citation, and re-cost the §5
   de-dup/recall-signal mechanism (which presumes `/compound` walks the corpus).

## CORRECTIONS (specific, required)

- **A.** State the net file delta explicitly in §(i) and the §0/§1 framing (≈ −2 / +11). Defend it against
  the binding principle or reduce additions. Do not present store-count-6→3 as if it were the file-count win.
- **B.** Fix the citation `[compound/SKILL.md:72,83,143]` → those lines support *curated*-finding/memory.md
  promotion, not auto-memory graduation. Either re-cite to the real (curated) steps and drop the
  "auto-memory" wording, or mark the auto-memory graduation as net-new with no existing citation.
- **C.** The `/note` append wrapper (§3 S3 writer) is a **new skill** — cite its absence and justify it, or
  replace it with the existing manual-append-to-file path. The model's own thesis ("rename the work, not the
  skill") forbids quietly adding one.
- **D.** Resolve the `git-worktree.md` (and `harness-hooks.md` advisory portion) shard: a shard with no
  `paths:` glob does **not** native-auto-load (capability-facts), so it gains none of §7's benefit and is
  pure overhead with worse discoverability than a section in `00-safety.md`. Fold path-less traps into the
  always-load floor or accept they remain advisory-prose — don't dress them as path-scoped shards.

## NON-BLOCKING (note for the decision package)

- §4 (entry-as-atom resolving the dual-assignment) and §6 (emitter-defined-by-destination fixing #70) are
  the two strongest, fully-grounded contributions — keep verbatim.
- The "one logical writer, two trigger points" relaxation (S1 and S3) is a defensible reading of the
  one-writer requirement and is honestly flagged; not a blocker.
- The auto-memory third-copy duplication is collapsed only by a prose authority line (honestly flagged as
  Open Decision 3). The requirement says "in tooling, not prose" — this is the one place it can't be, by the
  subsystem's nature. Acceptable, but the decision package should surface it as the model's single
  remaining prose-only seam, not bury it.
