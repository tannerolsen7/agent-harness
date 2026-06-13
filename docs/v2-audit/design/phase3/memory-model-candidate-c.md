# Memory Model Candidate C — the NATIVE-MECHANISM model

**Designer C of three (independent).** Optimizing axis: **lean maximally on what Claude Code natively
provides** — the auto-memory subsystem as the capture layer, `.claude/rules/*.md` + `paths:` globs for
path-scoped knowledge, CLAUDE.md `@imports`, and skill `paths:` frontmatter — so that V2 owns the
**fewest possible custom files and tooling**. Every store I keep must justify itself against a native
mechanism that would otherwise do the job; every custom mechanism must justify itself against the §9
criterion ("name a failure mode the constraint prevents, or it's overhead").

**Target store count: 3** (down from 6). Justified in §1.

**One-line thesis.** Today the harness fights the platform: it hand-rolls a capture layer (memory.md
manual write-back, never automated) and a read layer (PITFALLS read wholesale by prose instruction) that
Claude Code *already provides natively* — auto-memory captures automatically, `.claude/rules/+paths`
loads scoped knowledge automatically. The native-mechanism model **deletes the hand-rolled halves and
keeps only the curated content the platform can't generate**, then adds exactly ONE custom CI check (the
drift detector) the platform genuinely lacks. The win is not "a better memory file" — it's *stop
maintaining two parallel systems that do what one native system already does.*

---

## 1. Target store set (3 stores) and why 3

| # | Target store | Native mechanism it rides | Role |
|---|---|---|---|
| **T1** | **Auto-memory** (`~/.claude/projects/.../memory/`) | The Claude Code memory SUBSYSTEM (auto-writer + auto-reader at session start) | **Capture layer.** Transient, session-scoped, auto-loaded corrected-mistakes & project facts. The *raw inbox*. |
| **T2** | **`.claude/rules/*.md`** (path-scoped) + CLAUDE.md (no-trigger floor) | Native `.claude/rules/` + `paths:` glob lazy-load; CLAUDE.md always-load | **Curated rules layer.** The durable, enforced, area-scoped knowledge: traps (ex-PITFALLS), locked decisions (ex-ADR), conventions. Loaded *only when working on matching files*. |
| **T3** | **`docs/solutions/`** | Plain files + grep/glob | **Pattern library.** Positive reusable patterns (the "how we solved X" half), found on demand. |

**Why 3 and not fewer:** Two stores would be tempting (collapse T3 into T2). I keep them separate because
they have **genuinely different lifecycles and read-triggers**: T2 rules are *constraints* read
preventively before writing (push semantics — "don't do X here"); T3 solutions are *recipes* read on
demand when solving a known-hard problem (pull semantics — "how did we do Y"). Merging them would force
one freshness rule and one read-trigger onto two different knowledge shapes — the exact mistake the
current model makes by sanctioning-and-forbidding triple-duplication. Three is the floor where each store
still has **one coherent writer/reader/freshness contract**. (Per `inventory-stores-and-files.md`, ADR
Store 5 is the existence proof that one-writer/one-trigger/one-lifecycle is achievable — I am replicating
that property three times, not inventing it.)

**Why 3 and not more:** RECURRING-FINDINGS (Store 2) and memory.md (Store 1) and PITFALLS (Store 3) and
ADR (Store 5) all collapse — see the migration table (§3). The collapse is the win.

---

## 2. Per-store contract (writer / reader / freshness / lifecycle-in-tooling)

### T1 — Auto-memory (the capture layer)

- **ONE writer:** the **Claude Code memory subsystem**, automated, no harness involvement. (`[map §4, §6]`
  — verified this session: 52 files = MEMORY.md + 32 `feedback_*` + 15 `project_*` + 3 `reference_*` +
  1 `user_*`.) This is the *already-existing automated writer* the canon's curated stores lack. **We do
  not add a custom writer here. We use the one the platform runs for free.**
- **ONE reader:** the subsystem itself, **automated at session start** — first 200 lines / 25 KB of
  `MEMORY.md` auto-loaded (`capability-facts.md`). No prose instruction, no hook. The model gets the
  capture layer whether or not it "remembers to read memory.md" — which is the current failure mode of
  Store 1.
- **ONE freshness rule:** **30-day decay, enforced by eviction** (see lifecycle below). The subsystem
  stamps age and warns (the "5 days old… verify against current code" banner observed this session) but
  **does not evict** — so it grows monotonically (52 files and climbing) and stale entries inside the
  25 KB cap displace fresh signal (e.g. `project_test_gaps_nh7.md` = "PRs #32/33/34 pending merge", long
  since resolved, still loaded). The 30-day window is deliberately *shorter* than memory.md's 90-day rule
  because T1 is an **inbox, not an archive**: anything worth keeping past 30 days has graduated to T2.
- **LIFECYCLE-IN-TOOLING (the mechanism, not prose):**
  - **Graduation:** a new custom skill **`/distill`** (replaces `/compound` Step 9, see §6) runs the
    promotion sweep: any `feedback_*` entry that has survived 2+ sessions and names a *codebase trap*
    (not a one-off process correction) is rewritten as a `.claude/rules/<area>.md` entry (→ T2). This is
    the *only* path from capture to curation. Output lands IN T2 (a committed file), not in a discarded
    `claude --print` stream — directly fixing the #70 session-end failure (output discarded).
  - **Eviction:** because the harness *cannot write to or delete* the auto-memory store (the subsystem
    owns it — `[map §6]`, "the harness does not control it and cannot see its write cadence"), eviction
    is **advisory-surfaced, not executed**: `/distill` emits a list of `feedback_*`/`project_*` files
    older than 30 days that were never graduated, with the one-line `rm` batch for Tanner to run. This is
    the honest version — I do **not** claim to evict a store I provably can't write to. The decay *is*
    enforced, just at the human-handoff boundary that the destructive-op rules require anyway.

  > **The hard native-mechanism constraint (named honestly):** the auto-memory subsystem is a black box
  > the harness neither writes nor prunes. The native-mechanism model's strongest move — "use the free
  > auto-writer as the capture layer" — is bounded by this. T1 gives us automatic capture + automatic
  > load *for free*, but its curation/eviction must be pulled *out* into T2 (which we own) via `/distill`.
  > A model that pretended to control T1's contents would be fiction. This one doesn't.

### T2 — `.claude/rules/*.md` + CLAUDE.md (the curated rules layer)

- **ONE writer:** the **`/distill`** skill (graduation from T1) and **`/cr`** (direct codification of a
  trap caught in review — replaces the RECURRING-FINDINGS→PITFALLS promotion, see §3, §10). Both write to
  `.claude/rules/<area>.md`. A human edits CLAUDE.md's no-trigger safety floor directly (guard-file
  discipline — `[memory: no_agent_edits_guard_files]` keeps that human-gated).
- **ONE reader:** **native `paths:` glob auto-load** (`capability-facts.md`: "`.claude/rules/` with
  `paths` globs = native path-scoped lazy-loading… load only when working on matching file types"). When
  the model edits `src/data/*.ts`, `.claude/rules/data-layer.md` loads automatically — *and only that
  rule*. When it edits a migration, `.claude/rules/migrations.md` loads. **This is the fix for the 43 KB
  monolithic PITFALLS read** (`[map §4]`, "43 KB read wholesale… no path-scoping"). The no-trigger safety
  floor (destructive-op trio, the NEVER list) stays in always-loaded CLAUDE.md because it has no file
  trigger — *tier by trigger-existence, not line-count* (`_EMERGING-FINDINGS §3`).
- **ONE freshness rule:** **changelog-driven + a phantom-reference CI gate** (the drift detector, §9). No
  per-entry time-decay — these are durable constraints by construction (a trap doesn't expire; it's fixed
  or it isn't). The decay axis that matters for T2 is *fiction* (a rule referencing a file/section that no
  longer exists), not staleness — and that's what the CI gate catches.
- **LIFECYCLE-IN-TOOLING:**
  - **In:** `/distill` (from T1) and `/cr` (from review) append/update `.claude/rules/<area>.md`.
  - **Validate:** the **`rules-integrity` CI check** (§9) fails the build if any `.claude/rules/*.md`
    references a path/section that doesn't exist (doc-fiction / phantom-ref — our *live* failure class,
    `[map §0]`) OR if a rule's `paths:` glob matches zero files (doc-stale — the rule guards a deleted
    area).
  - **Out:** a rule is removed by a human when the trap is structurally impossible (e.g. a lint rule now
    catches it). `/cr` flags removal candidates; removal is human-gated (guard-adjacent content).

### T3 — `docs/solutions/` (the pattern library)

- **ONE writer:** **`/compound`** after a merged feature (unchanged from today — `docs/solutions/README.md`:
  "Run /compound after the feature is merged"). This is the one part of today's model that already has a
  clean single-writer contract; I keep it.
- **ONE reader:** **`/dev` and `/feature` at task-start**, via a **glob-injected read** — the one wiring
  change T3 needs. Today solutions are "found only if the worker greps for it" (`inventory… Store 4`, "no
  read-path into work"). The native lever: skill `paths:` frontmatter + a one-line task-start step that
  greps `docs/solutions/` for tags matching the task's touched paths. (This is the *minimum* read-path —
  not a custom index, not a new store.)
- **ONE freshness rule:** **NONE by time** (positive patterns are durable) — but subject to the same
  **`rules-integrity` phantom-ref CI gate** as T2 (a solution doc that references a deleted file is a
  doc-fiction failure the detector must catch). This closes the README's unmet ">10-entry frontmatter
  tag" self-rule problem by making the read-path tag-driven and CI-validated rather than hand-indexed.
- **LIFECYCLE-IN-TOOLING:**
  - **In:** `/compound` writes `docs/solutions/YYYY-MM-DD-*.md` with `paths:`/`tags:` frontmatter
    (frontmatter now *required*, not "add when >10 entries" — the migration the README deferred).
  - **Validate:** `rules-integrity` CI gate (phantom-ref + tag-presence).
  - **Out:** superseded solutions get a `superseded-by:` frontmatter field (mirroring ADR's clean
    supersession lifecycle — the model `inventory…` calls "the cleanest store"). No deletion needed.

---

## 3. Migration table — all 6 of today's stores → target (per-store row)

| Today's store | Disposition | Target | Mechanism that moves it |
|---|---|---|---|
| **1. `.claude/memory.md`** (166 L) | **SPLIT + DELETE** | safety-floor → CLAUDE.md (T2 always-load); behavior-rules → DELETE (dup of CLAUDE.md); codebase-traps → `.claude/rules/` (T2) | Human moves the 3-rule PocketOS safety floor into CLAUDE.md (or confirms it's already there — it is: CLAUDE.md "Destructive-operation rules"). Behavior rules (`honest-assessment`, `build-what-is-needed-now`, `research-before-guessing`) are **deleted** — verbatim dup of CLAUDE.md "Agent behavior principles" (`inventory… Store 1 pathology 1`). The file `.claude/memory.md` **ceases to exist.** Capture role → T1 (auto-memory already does it for free). |
| **2. `docs/RECURRING-FINDINGS.md`** | **REPURPOSE → DELETE the file, keep the COUNTER** | T1 (signal) → T2 (promotion) | The half-open loop (`[map §4]`, written by pipeline, read by no implementer) is closed by *deleting the intermediate file* and folding its job into the two native stores: `/cr` Step 3b writes the *signature+count* to a lightweight `docs/RECURRING-FINDINGS.md`-shaped ledger that **still exists as a counter** but is now *read* at task-start via T2's path-scoping (see §10). The promotion target changes from PITFALLS-the-monolith to `.claude/rules/<area>.md`-the-scoped-file. **Net: the counter survives (it's the one real automated writer); the dead-end read-path is replaced by T2 auto-load.** |
| **3. `PITFALLS.md`** (558 L / 43 KB) | **SPLIT → DELETE the monolith** | T2 (`.claude/rules/*.md`) | The 37 sections are split by `**Area:**` field (every PITFALLS entry already has one — verified) into `.claude/rules/<area>.md` files with `paths:` globs. E.g. `claude-permission-path-is-project-relative` → `.claude/rules/settings.md` (paths: `.claude/settings*.json`); `schema-file-folder-collision` → `.claude/rules/schemas.md` (paths: `src/schemas/**`). The monolithic `PITFALLS.md` is **deleted** once split. This is the single biggest read-cost win: 43 KB-every-task → ~2 KB-when-relevant. |
| **4. `docs/solutions/`** | **KEEP → T3** | T3 (unchanged store, +read-path) | Stays as-is; gains the task-start glob read-path (§2 T3) and required frontmatter. The cleanest-writer store — no structural change, only wiring. |
| **5. `docs/adr/`** | **MERGE → T2** | T2 (`.claude/rules/architecture.md`) | The 5 ADRs are *locked architectural constraints* — exactly T2's shape (a constraint read before writing). They become `.claude/rules/architecture.md` (paths: broad — `src/**`) so an ADR auto-loads as a constraint when relevant code is touched, **and is wired into `/cr` as review criteria** (the one gap `inventory… Store 5` names: "an ADR can be silently violated… `/cr` won't catch it"). ADR's clean supersession lifecycle becomes T2's `superseded-by:` field. The `docs/adr/` dir is **deleted** after merge; supersession history preserved in git + the `superseded-by` field. |
| **6. Auto-memory** (52 files) | **KEEP → T1 (the capture layer)** | T1 | Promoted from "canon-invisible 6th store the model can't ignore" to **the explicit capture layer of the model.** No structural change to the subsystem (we can't change it). What changes: `/distill` now *graduates* its durable entries into T2 and *surfaces* its stale entries for human eviction — closing the monotonic-growth pathology (`inventory… Store 6 pathology 3`). |

**Store-count math:** 6 → delete memory.md (−1, content split to CLAUDE.md+T2+trash) → fold
RECURRING-FINDINGS file into T1/T2 counter (−1 as a *store*, the counter is now a T2 input) → split
PITFALLS into T2 (−1 monolith) → merge ADR into T2 (−1) → keep solutions as T3 → keep auto-memory as T1.
**Result: T1 (auto-memory), T2 (.claude/rules + CLAUDE.md floor), T3 (solutions) = 3 stores.**

---

## 4. Accounting for the auto-memory subsystem (the canon-invisible store)

The canon ignores it; this model makes it **the spine.** Rationale per the optimizing axis: it is the
ONLY store with a *fully automated writer the harness gets for free* AND a *fully automated reader at
session start* (`[map §6]`). Fighting it (the current model's implicit stance — memory.md duplicates its
content and is read by prose instruction) is strictly worse than riding it. So:

- **T1 = auto-memory** is the capture inbox. The harness stops hand-maintaining a parallel capture file
  (memory.md), because the subsystem already captures corrected-mistakes automatically.
- **The two pathologies we own** (`inventory… Store 6`): (3) monotonic growth / no eviction, and (4)
  stale-first authority. Both are addressed by `/distill`: graduate the durable, surface-for-eviction the
  stale. We cannot prune the store (we don't own its writes — stated honestly in §2 T1), so eviction is a
  human-handoff `rm` batch, which the destructive-op rules require regardless.
- **What we explicitly DON'T do:** we do not try to make a custom hook write *into* auto-memory (the
  subsystem owns those writes; a competing writer would race it). T1's only harness-side operations are
  *read* (free, automatic) and *graduate-out / surface-for-eviction* (via `/distill`). Clean boundary.

---

## 5. Resolving the PITFALLS.md / memory.md dual-layer (Context vs Memory) assignment

The dual-assignment (both files in BOTH Layer 1/Context and Layer 3/Memory depending on canon page —
`[map §4]`, FRESH GROUND TRUTH) is an artifact of treating *one file* as *one store*. The native-mechanism
model **dissolves the ambiguity by splitting along the layer boundary it was straddling:**

- **PITFALLS.md** was dual-assigned because it is *content that is Memory (accumulated corrected
  knowledge) delivered as Context (loaded before writing)*. Resolution: that's not a contradiction, it's a
  **pipeline** — Memory is where it's *captured* (T1), Context is where it's *delivered* (T2's
  path-scoped load). By splitting PITFALLS into `.claude/rules/*.md`, the *content* lives in the Context
  layer (loaded by native `paths:`) and its *origin* is the Memory/capture layer (T1 → graduated by
  `/distill`). One store (T2), one layer (Context-delivery), one upstream source (T1). **The dual-layer
  label disappears because the file that carried both roles no longer exists.**
- **`.claude/memory.md`** was dual-assigned for the same reason and is **deleted** (§3), so the
  ambiguity has no host. Its safety-floor → CLAUDE.md (Context, always-load). Its traps → T2 (Context,
  path-load). Its capture role → T1 (Memory). Each fragment lands in exactly one layer.

**Net:** Layer-1/Context = CLAUDE.md floor + T2 (`.claude/rules/`) + T3 (solutions, on-demand).
Layer-3/Memory = T1 (auto-memory capture). The boundary is now *capture vs delivery*, and no store sits on
both sides.

---

## 6. Collapsing the triple-duplication in TOOLING (not prose)

The triple-dup: the same corrected-mistake fact lives in `.claude/memory.md` AND `PITFALLS.md` AND
auto-memory `feedback_*` (FRESH GROUND TRUTH; `inventory…` confirms `feedback_tty_detection`,
`feedback_sentinel_*`, `feedback_no_env_credential_reuse` each have twins). Today the reconciliation
("same knowledge at different lifecycle stages") lives ONLY in prose, encoded in no tooling, and
`/compound` itself flags memory entries as "redundant with PITFALLS."

**The tooling that collapses it — `/distill` (one skill, replacing `/compound` Step 9):**

```
/distill  (run by a ritual clock, e.g. weekly — wired to the heartbeat, not "optional every ~90 days")
  1. READ auto-memory feedback_*/project_* (T1).               [native: these are files on disk]
  2. For each entry:
       - SURVIVED 2+ sessions AND is a codebase trap  → GRADUATE: write/merge into
                                                          .claude/rules/<area>.md (T2). One copy lands.
       - process/behavior correction (not a trap)     → it belongs in CLAUDE.md or is ephemeral;
                                                          surface for human triage, do not duplicate.
       - already present in a .claude/rules/*.md       → it is a DUPLICATE: surface the auto-memory
         (signature match)                               file path for eviction (rm batch). NO second copy.
       - >30 days, never graduated                     → surface for eviction (rm batch).
  3. EMIT: (a) the T2 diffs to commit, (b) the rm batch for Tanner (human-gated, destructive-op rule).
```

The collapse is structural: **a fact can be in T1 (transient capture) XOR T2 (durable, single copy).**
`/distill`'s signature-match step is the *tooling* that prevents a fact existing in both — when it finds a
T1 entry already in T2, it routes the T1 copy to eviction instead of copying it again. There is no third
location, because `PITFALLS.md` and `.claude/memory.md` no longer exist (§3). **Three copies → one copy +
a graduation pipeline that enforces "exactly one."** The reconciliation is now a skill step, not a prose
footnote.

> Why `/distill` and not "extend `/compound` Step 9"? Step 9 today is *detection only* ("Do not modify
> memory.md. Surface candidates and wait for direction" — verified) and *optional/~90-day* (so it never
> fires). `/distill` is the same detection logic with (a) an actual write target it owns (T2, committed),
> (b) a real clock (the ritual heartbeat — `_EMERGING-FINDINGS §1`: "the missing primitive is a
> heartbeat"), and (c) the dedup-by-eviction routing. It is **not a new mechanism** — it's Step 9 given
> the write authority and the clock it was missing. Net file count: `/compound` keeps Steps 1–6
> (solutions writing, T3); Step 9 moves to `/distill`. No net-new skill *capability*, one renamed/refocused
> skill body.

---

## 7. Path-scoped tiering via native `.claude/rules/` + `paths:` globs (net-new build)

`.claude/rules/` is ABSENT today (FRESH GROUND TRUTH, re-verified this session: `ls .claude/rules/` →
No such file). So this is a **net-new build, not a relocation** — but it builds a *native* mechanism, not a
custom one. The build:

1. **Create `.claude/rules/`.** One `.md` per area, each with `paths:` frontmatter:
   ```
   ---
   paths: ["src/data/**/*.ts", "app/**/actions.ts"]
   ---
   # Data-layer rules
   <traps split from PITFALLS where Area = data layer>
   <ADR constraints touching the data layer>
   ```
2. **Split PITFALLS by its existing `**Area:**` field** (every entry has one — verified) into these
   files. Areas observed: `settings.json`, `src/schemas`, migrations, data layer, hooks/shell-guards, git
   workflow, AGENTS.md-index. ~7–10 rule files, each 1–4 KB.
3. **Merge the 5 ADRs** into `.claude/rules/architecture.md` (broad `paths: ["src/**"]`) as constraints.
4. **Globs gate the load:** editing `src/schemas/foo.ts` loads `schemas.md` only; editing a migration
   loads `migrations.md` only. The 43 KB-every-task cost becomes ~2 KB-when-relevant.

**The native lever doing the work:** `paths:` glob auto-activation (`capability-facts.md` — confirmed
native). We write *content* and *globs*; the platform does the *tiering*. No custom loader, no custom
index, no `/scan-context` reader. This is the purest expression of the optimizing axis: the tiering
mechanism is the platform's, we only supply curated files.

**Keep-verbatim floor stays always-loaded:** the destructive-op trio and the NEVER list have **no file
trigger** (they apply to every operation, not a file type), so they live in CLAUDE.md (always-load), NOT
in a path-scoped rule. Tier by trigger-existence, not line-count (`_EMERGING-FINDINGS §3`; KEEP-VERBATIM
FLOOR honored).

---

## 8. The absent automated WRITER (MOVE 1 session-end emitter — output must land IN a store)

`session-end.sh` was removed in #70 because its `claude --print` output was **discarded** (FRESH GROUND
TRUTH; `[map §3e]`). The native-mechanism lesson: **don't rebuild a custom emitter whose output you then
have to find a home for — use the writer that already lands its output in a store.**

- **For the capture half:** the **auto-memory subsystem IS the automated writer** (T1). It already writes
  `feedback_*` files automatically, no hook, no discarded output. The native-mechanism model's answer to
  "build the MOVE 1 session-end emitter" is: *you don't need to — the platform's auto-writer is the
  emitter, and its output lands in T1 by construction.* This is the model's strongest claim against
  net-new tooling: **MOVE 1's memory-write-back payload is already built and running; we were ignoring
  it.**
- **For the graduation half** (the part the subsystem doesn't do — promoting durable knowledge to the
  curated layer): that is **`/distill`** (§6), whose output lands IN T2 as a committed
  `.claude/rules/*.md` diff. This is the explicit fix for #70: `/distill`'s output is a file edit + a
  commit, not a printed stream. It *cannot* be discarded — it's in the repo or the run failed.
- **For the loop-counter half:** `/cr` Step 3b (the one real automated writer today) keeps writing the
  signature counter (§10). Its output lands in a committed ledger.

So the "absent automated writer" is resolved as: **capture-writer = native subsystem (T1); curation-writer
= `/distill` → T2 (committed); loop-writer = `/cr` 3b → committed counter.** No custom session-end hook is
rebuilt; the only net-new writer is `/distill`, and it writes to a store by construction.

---

## 9. Drift/decay detector — catches doc-STALE, doc-FICTION (phantom refs), and DECAY

The single net-new custom mechanism the platform genuinely lacks (`capability-facts.md`: "No CI check
validates any knowledge artifact today"). Built as a **CI check**, not a skill (so it can't be forged or
skipped — relocation-to-deterministic, `MOVE 2` doctrine), run in the existing `npm run test:unit` /
`ci.yml` lane (verified: ci.yml runs tsc/eslint/`npm run test:unit`).

**`rules-integrity` (one node script, ~80 lines, in CI):** for every `.claude/rules/*.md` and
`docs/solutions/*.md`:

| Axis | Failure it catches | Detection |
|---|---|---|
| **doc-FICTION** (phantom ref — *our live failure class*, `[map §0]`) | A rule cites `PITFALLS § foo`, a file path, or a `@`-import that doesn't exist | Resolve every `§`-ref, backtick-path, and `paths:` glob target against disk; fail if any resolves to nothing |
| **doc-STALE** | A rule's `paths:` glob matches **zero files** (it guards a deleted area) | Run each glob; fail if a rule's glob set is empty |
| **DECAY** | A T1 (auto-memory) entry references a closed PR / merged-and-deleted branch / resolved task | `/distill` (not CI — T1 isn't in the repo) flags entries whose body matches `PR #\d+ (pending|open)` against `gh pr view` state; surfaces for eviction |

- **doc-FICTION + doc-STALE = CI (deterministic, on the repo-resident stores T2/T3).** Blocks merge.
- **DECAY = `/distill` (advisory, on the non-repo store T1).** Surfaces an eviction batch. T1 can't be
  CI-checked because it lives outside the repo (`~/.claude/projects/.../memory/`) — honest boundary.
- **Why this is the ONE custom mechanism worth building:** §9 criterion — the failure mode it prevents is
  *the one that already happened to this very audit* ("audit artifacts ROT… the audit itself rotted, map
  §0"). A phantom reference (a rule pointing at a deleted file) silently mis-directs every future agent.
  No native mechanism catches it. This earns its place; nothing else net-new does.

---

## 10. Closing the RECURRING-FINDINGS read-path (never read by implementers today)

The half-open loop (`[map §4]`, `inventory… Store 2`): written automatically by `/cr` Step 3b, read by
**nobody at implementation time** — verified this session: the only non-worktree referrers are
`PITFALLS.md` and `.claude/skills/cr/SKILL.md`. A finding is invisible at the moment an implementer is
about to repeat it.

**Native-mechanism close (no new store, no custom reader):**

1. **`/cr` Step 3b keeps writing the counter** (the one real automated writer — preserve it). But it
   writes the *signature + Area + count* into a frontmatter-tagged form.
2. **At the promotion threshold** (≥3 occurrences, today's rule), `/cr` writes the finding **directly into
   the matching `.claude/rules/<area>.md` (T2)** — *not* into PITFALLS-the-monolith (deleted). The moment
   it lands in T2, it is **auto-loaded by native `paths:` globs the next time any implementer touches that
   area.** The read-path is the platform's path-scoping — we built no reader.
3. **Below threshold** (occurrences 1–2), the finding sits in the lightweight counter ledger. To give
   *even sub-threshold* findings a read-path (the implementer-invisibility gap), the counter ledger itself
   gets a `paths:` frontmatter block per Area, so the relevant recent-but-unpromoted findings for an area
   surface alongside the T2 rules when that area is touched. (This is the one place the counter ledger
   survives as a file — but it's now a *read* T2-adjacent input, not a dead-end.)

So: **`/cr` writes (already does) → T2 `.claude/rules/` is the promotion target → native `paths:` is the
reader → the implementer sees the finding automatically when editing the relevant area.** The loop closes
because the *promotion target became a path-scoped store that auto-loads*, eliminating the need for a
custom read-path entirely. ADR-as-`/cr`-criteria (the Store-5 gap) is the same wiring: `/cr` loads
`.claude/rules/architecture.md` as review constraints.

---

## 11. What I DELETE, and the §9 failure-mode each deletion leaves unprevented (or: overhead)

| Deleted | §9 failure-mode otherwise unprevented | Verdict |
|---|---|---|
| `.claude/memory.md` (the file) | Capture of corrected-mistakes — **but T1 (auto-memory) already does this automatically.** The behavior-rule fragment dup-of-CLAUDE.md prevents *nothing* (CLAUDE.md has it verbatim). | **Overhead** — pure duplication of a native store + CLAUDE.md. Safe delete (safety floor confirmed already in CLAUDE.md). |
| `PITFALLS.md` (the monolith) | Area-scoped trap delivery — **but T2 (`.claude/rules/`) delivers the same content, path-scoped, cheaper.** | **Relocation, not loss.** Content fully preserved in T2. The monolith's only unique property (43 KB always-read) is the *defect* being fixed. |
| `docs/adr/` (the dir) | Locked-decision delivery at design time — **but `.claude/rules/architecture.md` delivers it path-scoped AND wired into `/cr`** (a strict gain — ADRs were *not* `/cr` criteria before). | **Relocation + gain.** Supersession history preserved in `superseded-by:` + git. |
| `docs/RECURRING-FINDINGS.md` (as a dead-end file) | The signature-counter — **preserved** (it's the one real auto-writer); only the dead-end read-path is deleted. | **Partial** — counter survives as a T2-adjacent input; the *half-open-ness* is the overhead removed. |
| `/compound` Step 9 (detection-only, never-fires) | Memory decay + dedup detection — **replaced by `/distill`** (same logic + write authority + clock). | **Overhead removed** — a detector with no write authority and no clock prevented no failure (it never ran; dates are 3 weeks stale, sweep visibly unrun — `inventory… Store 1`). |
| `.claude/memory.md` behavior-rules (3 entries) | Honest-assessment / build-what's-needed / research-before-guessing discipline — **CLAUDE.md "Agent behavior principles" carries them verbatim.** | **Overhead** — triple-stored (memory.md + CLAUDE.md + auto-memory `feedback_*`); two copies are pure redundancy. |

**Net deletion:** 2 files (`memory.md`, `PITFALLS.md`) + 1 dir (`docs/adr/`) + 1 skill-step
(`/compound` Step 9) + the dead-end half of RECURRING-FINDINGS. **Net new:** `.claude/rules/` (a
directory of split content — *fewer total bytes* than PITFALLS+ADR+memory.md combined, just tiered) +
`/distill` (refocused Step 9, not net-new capability) + `rules-integrity` CI check (~80 lines, the one
genuinely-new mechanism). **File-count direction: down.** 6 stores → 3.

---

## 12. The one-screen summary (what V2 actually does)

- **T1 = auto-memory** — the free native capture layer. Stop maintaining `memory.md`; the subsystem
  already captures and auto-loads. (Delete `memory.md`.)
- **T2 = `.claude/rules/*.md` + CLAUDE.md floor** — curated, path-scoped, native-`paths:`-loaded
  constraints. (Split PITFALLS + merge ADR here; 43 KB-always → ~2 KB-when-relevant.)
- **T3 = `docs/solutions/`** — pattern library, gains a task-start read-path. (Keep; wire the reader.)
- **`/distill`** (weekly ritual) — graduates T1→T2, dedups by eviction, surfaces stale for human `rm`.
  (Replaces `/compound` Step 9; the missing automated curation-writer that lands output IN a store.)
- **`/cr` Step 3b** — keeps writing the signature counter; promotes ≥3-occurrence findings *directly into
  T2*, which auto-loads to implementers. (Closes the half-open loop via native `paths:`, no custom
  reader.)
- **`rules-integrity` CI** — the one net-new mechanism: fails the build on phantom refs (doc-fiction) and
  empty globs (doc-stale). (Catches the failure class that rotted this very audit.)

The native-mechanism bet: **the platform already gives us a capture layer (auto-memory) and a tiered read
layer (`.claude/rules/+paths`) for free. Most of today's six stores are the harness re-implementing those
two layers by hand, in triplicate. V2 deletes the hand-rolled re-implementations and keeps only (a) the
curated content the platform can't generate and (b) the ONE validator the platform genuinely lacks.**
