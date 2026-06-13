# Memory Model — Candidate A (FEWEST-STORES angle)

**Designer A of three.** Optimizing axis assigned: **minimize the number of distinct memory files an
author or agent must reason about.** Aggressively merge and collapse; justify the count.

**Target store count: 3** (down from 6 on disk today). Plus the auto-memory subsystem, which is a 4th
store the harness does **not own** but must contain — so the number an author *reasons about and writes
to* is **3**; the number that *exists* is 4 (3 harness-owned + 1 subsystem-owned, demoted to a cache).

**Governing rule honored.** Every change below cites a current-state component — `[map §N]`,
`[inv Store N]` (the Phase-3 census), or a disk path — or a re-verified absence. Nothing here proposes
building something that already exists; the anti-phantom list is MASTER-FINDINGS §E. The §9 deletion
criterion ("name a failure mode the constraint prevents, or it's overhead") is applied to every cut.

---

## 0. Why 3, and why not fewer

The six stores today are not six *kinds* of knowledge. They are **two kinds of knowledge at three
lifecycle stages, plus a subsystem cache**. The fragmentation is historical, not conceptual.

**Two kinds of knowledge:**
- **Constraints** (corrected mistakes, traps, locked decisions) — "do not do X / always do Y / Z is
  decided." Lives today in memory.md `[inv Store 1]`, PITFALLS.md `[inv Store 3]`, adr/ `[inv Store 5]`,
  and the `feedback_*` half of auto-memory `[inv Store 6]`. **Same knowledge, four files.**
- **Patterns** (reusable positive solutions) — "here is how we solved X, reuse it." Lives today in
  solutions/ `[inv Store 4]`, and the `project_*`/`reference_*` half of auto-memory `[inv Store 6]`.

**Plus the pipeline-observation staging area:** RECURRING-FINDINGS `[inv Store 2]` — not a third *kind*,
but the **inbox** where the automated writer (`/cr` Step 3) drops candidate constraints before a human
promotes them. It is a *stage*, not a *kind*.

So the natural collapse is:

| Target store | What it holds | Collapses today's |
|---|---|---|
| **1. KNOWLEDGE.md** (constraints, path-tiered via `.claude/rules/`) | every active constraint + locked decision, one entry format, lifecycle field | memory.md + PITFALLS.md + adr/ + auto-memory `feedback_*` |
| **2. solutions/** (patterns) | reusable positive patterns, kept as a directory | solutions/ + auto-memory `project_*`/`reference_*` (by reference, see §5) |
| **3. FINDINGS.md** (the inbox) | pipeline-observed candidate constraints awaiting promotion | RECURRING-FINDINGS.md |
| *(4. auto-memory — subsystem cache, demoted, not author-facing)* | CC subsystem's own scratch; treated as untrusted cache | auto-memory (retained, fenced) |

**Why not 2?** You cannot merge FINDINGS into KNOWLEDGE without destroying the **promotion gate**.
FINDINGS holds *unverified, observed-once* candidates; KNOWLEDGE holds *human-confirmed* constraints.
Collapsing them removes the one place a finding can sit at occurrences=1 without polluting the
always-loaded constraint set. The §9 failure mode that separation prevents: **an un-vetted single
observation getting promoted to an always-loaded rule and ossifying** (this is exactly the "stale
forgeable gate" failure, R-5 in `_EMERGING-FINDINGS §2`). Keep the inbox. So the floor is 3.

**Why not merge solutions into KNOWLEDGE too (→ 2)?** Considered and rejected. Constraints are *negative
and short* ("never X"); patterns are *positive and long* (a full worked solution with code). They have
**opposite freshness rules** — a constraint decays (90-day), a pattern is durable until superseded. And
they have **opposite read-triggers** — constraints load *always/by-path* (you must not violate them
unprompted); patterns load *on-demand by grep* (you look one up when you have the matching problem).
Forcing them into one file would force one freshness rule and one read-trigger onto two things that need
different ones — re-creating the dual-layer ambiguity we are trying to kill. The §9 failure prevented by
keeping them split: **a durable pattern getting decay-swept as if it were a stale rule, or a stale rule
surviving because it shares a file with durable patterns.** Split stands.

**This is a net deletion of file-kinds (6→3) and, more importantly, a deletion of duplication: the same
corrected-mistake fact stops existing in 3–4 places and exists in exactly 1.**

---

## 1. The three target stores — full contracts

Each store specifies: **ONE writer · ONE reader (+when) · ONE freshness rule · LIFECYCLE-IN-TOOLING**
(the actual hook/skill/CI mechanism that moves or evicts knowledge — not prose).

### Store 1 — `KNOWLEDGE.md` (+ `.claude/rules/*.md` path-tier) — the single constraint store

The merge of memory.md + PITFALLS.md + adr/ + auto-memory `feedback_*`. One file holds **every active
constraint**; native `.claude/rules/*.md` shards hold the **path-scoped subset** so the model loads only
the constraints relevant to the file it is touching.

- **ONE writer:** `/compound` (the existing capture skill, MASTER-FINDINGS §E "do NOT build — exists").
  It is the *only* hand that adds, edits, decays, or promotes a constraint. Direct hand-edits are
  permitted for the human but go through the same entry format. The **automated half** (the absent
  session-end emitter) does **not** write KNOWLEDGE directly — it writes FINDINGS (Store 3), and
  `/compound` promotes from there. This keeps one writer on the always-loaded store while still landing
  the automated emitter's output *in a store* (closing MOVE 1's "output was discarded" defect — see §8).
- **ONE reader (+when):** two read paths, one mechanism each, no prose-only reads:
  1. **Safety + behavior tier — always, by hook.** The KEEP-VERBATIM floor (PocketOS destructive-op
     trio + the standing behavior principles) is injected at session start by `session-start.sh`
     `[map §3e]` (which exists and already runs — we add a read+emit of the tier-0 block, replacing the
     prose "read this every session" instruction in CLAUDE.md and memory.md's header). No-trigger safety
     content stays tier-1 regardless of length `[_EMERGING-FINDINGS §3; map §9]`.
  2. **Area constraints — by path, natively.** Everything else is sharded into `.claude/rules/<area>.md`
     with `paths:` globs (e.g. `.claude/rules/migrations.md` with `paths: ["supabase/migrations/**"]`).
     Claude Code lazy-loads the shard **only when the model touches a matching file**
     (`capability-facts.md`: "`.claude/rules/` with `paths` globs = native path-scoped lazy-loading").
     This replaces the 43 KB monolithic PITFALLS read `[inv Store 3 pathology 3]` and the prose
     "MUST read PITFALLS before writing in any affected area" with a deterministic, scoped load.
- **ONE freshness rule:** per-entry `last_seen: YYYY-MM-DD` + 90-day decay (inherited from memory.md
  `[inv Store 1]`), with **one exception encoded in the entry, not in prose**: entries tagged
  `tier: safety` or `kind: decision` (the ADR class) are **decay-exempt** — a locked architectural
  decision does not go stale at 90 days, it goes *superseded* (the ADR lifecycle, `[inv Store 5]`, the
  cleanest store — we adopt its supersession field). So one store, two freshness behaviors, both
  encoded as a per-entry field the tooling reads — not two stores.
- **LIFECYCLE-IN-TOOLING (the mechanism, not prose):**
  - **Promotion (FINDINGS → KNOWLEDGE):** `/compound` Step 5 already does this for PITFALLS
    (verified: `compound/SKILL.md:72` "Check for PITFALLS.md promotion") and `/cr` Step 3 already
    flags candidates and writes the PITFALLS entry on confirmation (`cr/SKILL.md:225`). **We retarget
    both at KNOWLEDGE.md** — the mechanism exists, only the file path changes. Net-new code: zero; it's
    a path retarget on an existing skill step.
  - **Decay/eviction:** `/compound` Step 7 already reads `last_seen` and surfaces stale entries
    (verified: `compound/SKILL.md:143` "Read .claude/memory.md. Check the last_seen date on each entry").
    **We make this a CI check, not a manual `/compound` step** (see Store-wide drift detector, §9) so
    decay actually *executes* instead of being a documented-but-unrun sweep `[inv Store 1 pathology 4]`.
  - **De-duplication (the triple-collapse) — encoded, see §6.**
  - **Shard sync:** a CI check (§9) asserts every `.claude/rules/*.md` entry has a backing KNOWLEDGE.md
    entry and vice-versa, so the path-tier never drifts from the canonical file.

### Store 2 — `docs/solutions/` — the single pattern store (kept as a directory, wired)

- **ONE writer:** `/compound` after a merged feature (README quote, `[inv Store 4]`: "Run /compound after
  the feature is merged"). Unchanged — this writer is correct today.
- **ONE reader (+when):** **`/cr` and `/dev`/`/feature` at task start, by skill step** — not "manual grep
  by whoever remembers." We add one step to the task-entry skills: glob the solutions index for the
  area/tags of the files being touched and load matching pattern docs into context. This closes the
  "no read-path into work" pathology `[inv Store 4 pathology 1]` with a skill step, not prose. The
  existing grep-by-tag read-path (README shell snippets) becomes the *implementation* of that step.
- **ONE freshness rule:** supersession, not decay — a `Status: active | superseded-by <file>` field
  added to the frontmatter (borrowed from ADR, the model store `[inv Store 5]`). Patterns are durable;
  they die by being replaced, like ADRs, not by aging out.
- **LIFECYCLE-IN-TOOLING:** the **frontmatter-tags migration that the README mandates but never ran**
  (">10 entries → add YAML frontmatter tags"; now at 33 entries, unmet `[inv Store 4 pathology 3]`)
  becomes a **one-time migration + a CI assertion** that every solution file has `area:`, `tags:`, and
  `status:` frontmatter. The unmet self-rule (§9 overhead — an unenforced constraint) becomes enforced.
  Supersession is set by `/compound` when a new pattern obsoletes an old one; the CI check flags any
  `superseded-by` pointer that dangles (a phantom ref — our live failure class).

### Store 3 — `FINDINGS.md` (renamed from RECURRING-FINDINGS) — the inbox, now read

- **ONE writer:** **two automated emitters, one file** — this is the only store with two writers, and
  they are both *machines*, both *appending observations*, never editing each other's entries (matched on
  the `signature` field, `[inv Store 2]`), so there is no write-contention:
  1. `/cr` Step 3 (exists, `cr/SKILL.md:155` — the one real automated writer on disk today).
  2. **The MOVE 1 session-end emitter** (the absent automated writer, §8) — appends the same entry shape
     when a run surfaces a candidate constraint outside `/cr`.
  Two emitters, one entry format, one matching key. (This is the deliberate exception to "one writer" —
  see §3 migration note: both writers produce *the same kind of row*, so they are one logical writer
  split across two trigger points.)
- **ONE reader (+when):** **the task-entry skills, at task start** — this is the MOVE 6 fix. Today
  FINDINGS is "written by the pipeline and read only by the pipeline" `[inv Store 2 pathology 1]`. We add
  a read step to `/dev`/`/feature`/`/cr` Phase-0: glob FINDINGS for entries whose `signature` or
  `Example locations` match the files about to be touched, and surface them ("you are about to edit
  X; a finding here recurred N times in this area"). The finding becomes visible **at the moment an
  implementer is about to repeat it** — closing the half-open loop in tooling (§10).
- **ONE freshness rule:** occurrence-count + status field (`active | promoted | retired`), inherited
  from today `[inv Store 2]`. **Plus a new clock:** an entry that reaches occurrences ≥3 **and** has sat
  `active` for >14 days is auto-flagged by the drift CI check (§9) as an overdue promotion — putting a
  clock on the "promotion is a judgment gate with no clock" pathology `[inv Store 2 pathology 2]`.
- **LIFECYCLE-IN-TOOLING:** append/increment by the two emitters (exists); promotion-out to KNOWLEDGE
  by `/compound` (retargeted, §1); auto-retire on promotion (the existing status transition,
  `cr/SKILL.md:225`); the overdue-promotion clock (new CI flag, §9). On promotion, the entry is set
  `promoted` and **the same drift check asserts it now exists in KNOWLEDGE** — so a "promoted" finding
  can never be a phantom promotion.

---

## 2. The auto-memory subsystem (the canon-invisible 6th store) — demoted to a fenced cache

The canon ignores it; we may not `[inv Store 6 pathology 1]`. It has the one property nothing else has:
a **fully automated writer + reader the harness does not control** — the CC memory subsystem writes the
`feedback_*`/`project_*` files and auto-loads the first 25 KB of `MEMORY.md` at session start
(`capability-facts.md`). We cannot stop it writing and we cannot stop it loading. So the design move is
**not to merge into it or fight it — it is to reclassify it as an untrusted cache and let the
harness-owned stores be canonical.**

- **Disposition:** auto-memory is **a cache, not a store of record.** It is allowed to exist, allowed to
  auto-load, and is *never written to by the harness and never cited as authority.*
- **Resolving the authority confusion** (`[inv Store 6 pathology 4]`: stale auto-loaded facts arrive
  *before* curated memory): KNOWLEDGE.md's tier-0 safety block is injected by `session-start.sh` **in the
  same session-start window**, and a one-line header in MEMORY.md's space (the part the subsystem lets us
  influence is limited, so we instead put the rule in CLAUDE.md tier-0): **"Auto-memory is a 5-day-stale
  cache. On any conflict, KNOWLEDGE.md and the `.claude/rules/` shards win."** This is the *one* prose
  line we cannot replace with tooling, because the subsystem is not ours to hook — flagged as an open
  decision (§11).
- **Eviction:** we cannot evict subsystem files. But we can prevent the *duplication* from compounding:
  the §6 de-dup CI check treats auto-memory `feedback_*` as **already-covered-by-KNOWLEDGE by
  construction** — because every corrected-mistake fact now has its canonical home in KNOWLEDGE, the
  `feedback_*` copies are redundant *by definition* and are never read by any harness skill. They rot
  harmlessly in the cache; nothing in the harness depends on them.
- **§9 verdict:** we do not delete auto-memory (we can't, and trying is overhead). We **demote** it. The
  failure mode this prevents: a stale subsystem fact (e.g. `project_test_gaps_nh7` claiming PRs are still
  open when they merged weeks ago, `[inv Store 6 pathology 1]`) being treated as current truth because it
  auto-loaded first. The fence ("cache, KNOWLEDGE wins") is the prevention.

---

## 3. Migration table — all 6 of today's stores → target

Per-store row, explicit disposition (merge / keep / delete / auto), with the mechanism.

| # | Today's store | Disposition | Target | Mechanism of migration |
|---|---|---|---|---|
| 1 | `.claude/memory.md` `[inv Store 1]` | **MERGE → DELETE file** | KNOWLEDGE.md | Safety trio + behavior principles → KNOWLEDGE tier-0 entries (`tier: safety`, decay-exempt). The behavior-principle duplication with CLAUDE.md `[inv Store 1 pathology 1]` is collapsed by keeping the *constraint* in KNOWLEDGE and the *standing principle* in CLAUDE.md cross-referencing it (one source). Old file deleted after the one-time migration; its header instruction ("read every session") replaced by the `session-start.sh` injection (§1, §8). **DELETE-CANDIDATE** — flag for human confirm (CLAUDE.md forbids silent deletion). |
| 2 | `docs/RECURRING-FINDINGS.md` `[inv Store 2]` | **KEEP (rename) + WIRE** | FINDINGS.md (Store 3) | Rename for clarity; keep the schema and the `/cr` Step-3 writer (the one real auto-writer). Add the second emitter (§8) and the task-start reader (§1, MOVE 6). No deletion — the half-open loop is *wired shut*, not removed. |
| 3 | `PITFALLS.md` `[inv Store 3]` | **MERGE → DELETE file** | KNOWLEDGE.md + `.claude/rules/*.md` | Each PITFALLS entry becomes a KNOWLEDGE entry; area-scoped entries also shard into `.claude/rules/<area>.md` with `paths:` globs (the net-new path-tier, §7). The monolithic 43 KB read `[inv Store 3 pathology 3]` is replaced by native lazy-load. **DELETE-CANDIDATE** after migration. |
| 4 | `docs/solutions/` `[inv Store 4]` | **KEEP + WIRE** | solutions/ (Store 2) | Directory stays. Run the unmet frontmatter-tags migration (§1 lifecycle); add the task-start reader step and the CI frontmatter assertion. No deletion. |
| 5 | `docs/adr/` `[inv Store 5]` | **MERGE → DELETE dir** | KNOWLEDGE.md (`kind: decision`, decay-exempt) | The cleanest store becomes the *template for KNOWLEDGE's lifecycle field* (supersession), and its 5 ADRs migrate in as decay-exempt decision entries. **This is the controversial cut — see §3a.** **DELETE-CANDIDATE**, high-scrutiny. |
| 6 | Auto-memory `[inv Store 6]` | **AUTO (subsystem-owned) → FENCE as cache** | — (not author-facing) | Cannot delete or write. Demoted to untrusted cache; de-dup CI treats `feedback_*` as redundant-by-construction; conflict rule "KNOWLEDGE wins" (§2). |

**Resulting author-facing store count: 3** (KNOWLEDGE.md, solutions/, FINDINGS.md). **Existing-on-disk
count: 4** (those 3 + the subsystem cache we can't remove). Down from 6.

### 3a. The ADR-merge cut — the one place this angle is aggressive, stated honestly

Merging adr/ into KNOWLEDGE is the riskiest move in this candidate, and the FEWEST-STORES mandate is
*why* I make it — so I'll name the cost plainly rather than bury it. ADR is the **cleanest store on disk**
`[inv Store 5; map §4]` — one writer, one read trigger (design start), a coherent supersession lifecycle.
Deleting a clean store to save one file looks like deletion-for-its-own-sake.

The honest case *for* the merge: an ADR is just a constraint with `kind: decision` and a supersession
lifecycle instead of a decay lifecycle. KNOWLEDGE already needs a per-entry lifecycle field (for the
safety-exempt class), so the ADR's supersession field is **not new machinery** — it's the same field.
Folding ADRs in means **one read-trigger for all constraints** ("what is locked in this area?") instead
of a separate "skim adr/README at design time" prose instruction that `/cr` doesn't even enforce
(`[inv Store 5 pathology]`: ADRs aren't wired into `/cr` as criteria). The merge *also* wires them in:
ADR entries in `.claude/rules/<area>.md` load by path, so a diff that violates a locked decision now
loads that decision into the model's context automatically — which is exactly the MOVE 6 fix the
inventory says ADR needs.

The honest case *against* (and the open decision, §11): ADRs have a distinct, valuable *document
shape* — Context / Decision / Alternatives / Consequences — that a one-line KNOWLEDGE entry flattens. A
candidate-B/C designer optimizing for *coherence* rather than *fewest stores* would likely **keep adr/ as
its own store** and only *wire* it into `/cr`. **I flag this as the single biggest fork between my angle
and a coherence-optimized angle.** My mandate says merge; I merge; but I mark it the first thing Tanner
should overrule if he values the ADR document shape over the file-count win. If he keeps adr/, the count
is 4 author-facing (still down from 6) and nothing else in this model changes.

---

## 4. Resolving the PITFALLS.md / memory.md dual-layer (Context vs Memory) assignment

Both files are assigned to **BOTH Layer 1 (Context) and Layer 3 (Memory)** depending on canon page
`[inv Store 1 pathology 3; inv Store 3 pathology 2; map §4]`. The ambiguity exists because the *file* was
the unit of layering, and these files contain content that belongs to different layers.

**Resolution: layer the ENTRY, not the FILE.** Once memory.md and PITFALLS collapse into KNOWLEDGE, the
dual-assignment dissolves because there is no longer a "PITFALLS file" or a "memory file" to assign — there
is one constraint store, and each *entry* carries a `tier:` field that determines its load behavior:
- `tier: safety` → always-loaded context (the old "Layer 1" role), injected by `session-start.sh`.
- `tier: area` → path-loaded via `.claude/rules/` (lazy context, the native tiering).
- every entry also carries `last_seen`/`status` (the old "Layer 3 / Memory" role — freshness/decay).

So **Context and Memory stop being two layers a file lives in, and become two *properties* of one
entry**: *when it loads* (tier) and *when it decays* (freshness). The dual-assignment was an artifact of
treating the file as the atom. Make the entry the atom and it disappears — **in the data model, not in
prose.** This is the cleanest resolution the FEWEST-STORES angle produces and it is angle-independent
(any candidate should adopt entry-level layering).

---

## 5. Collapsing the triple-duplication (memory.md + PITFALLS + auto-memory `feedback_*`) in TOOLING

The same corrected-mistake fact lives in three places; the canon both sanctions and forbids this
`[map §4]`; `/compound` Step 6 already *detects* it but only as a manual "surface and wait" step
(verified: `compound/SKILL.md:148` "already covered by PITFALLS.md (redundant — safe to remove)", line
164 "Do not modify memory.md. Surface candidates and wait for direction"). The reconciliation is
prose-only; we encode it.

**The collapse, in three mechanical steps:**

1. **Eliminate two of the three copies at the source (one-time migration).** memory.md and PITFALLS
   merge into KNOWLEDGE (§3). After migration there is **one** harness-owned copy of each
   corrected-mistake fact. The triple becomes a single. This is structural, not a check — you cannot
   triple-duplicate across three files when two of the files no longer exist.

2. **The third copy (auto-memory `feedback_*`) is fenced, not merged (§2).** We can't delete subsystem
   files. So a **de-dup CI check** (part of the drift detector, §9) does the reconciliation the prose
   describes: for each `feedback_*` file in auto-memory, it computes a signature and asserts the same
   constraint exists in KNOWLEDGE. If KNOWLEDGE has it → the `feedback_*` copy is *expected redundancy*
   (the cache caching the canonical store) — no action, no noise. If KNOWLEDGE *lacks* it → the check
   surfaces it as a **promotion candidate** ("auto-memory learned something the canonical store missed").
   This turns the subsystem cache from a duplication liability into a **free recall signal** for what
   `/compound` forgot to capture — inverting the pathology.

3. **Prevent recurrence:** the single writer rule (§1, `/compound` is the only hand on KNOWLEDGE) means a
   corrected-mistake fact has exactly one place it can be written. The promotion path (FINDINGS →
   KNOWLEDGE) is the only inflow. There is no second curated file for a copy to land in. The duplication
   cannot re-form because there is no second destination — **the data model, not a check, is the
   prevention.** The CI check (step 2) only guards the one copy we don't own.

This is the duplication collapse "in tooling not prose" the mandate demands: a one-time merge (kills 2 of
3 copies structurally) + a CI signature-diff (handles the 1 copy we can't delete) + a single-writer data
model (prevents re-formation).

---

## 6. Path-scoped tiering via native `.claude/rules/` + `paths:` globs (net-new — absent today)

`.claude/rules/` is **ABSENT** (re-verified this session: `ls .claude/rules` → No such file or
directory). So this is a net-new build, not a relocation `[FRESH GROUND TRUTH]`. The native mechanism is
confirmed (`capability-facts.md`: "`.claude/rules/` with `paths` globs = native path-scoped
lazy-loading"; "Skills can carry their OWN `hooks:` and `paths:` frontmatter").

**Design:**
- KNOWLEDGE.md is the **canonical single file** (one place an author reads/writes constraints).
- `.claude/rules/<area>.md` shards are **generated projections** of the area-tiered subset, each with a
  `paths:` glob front-matter. Example shards (mapping to today's PITFALLS sections + ADRs):
  - `.claude/rules/migrations.md` — `paths: ["supabase/migrations/**"]` — REVOKE-after-CREATE-FUNCTION
    rule, no-CONCURRENTLY-in-migration rule, the trigger-based-timestamp ADR.
  - `.claude/rules/data-layer.md` — `paths: ["src/data/**"]` — `cache()`-wrapping rule, role-checks-in-TS
    ADR (0003), no-Supabase-from-component rule.
  - `.claude/rules/auth-routing.md` — `paths: ["proxy.ts", "app/**/middleware.ts", "app/(auth)/**"]` —
    PUBLIC_PATHS-at-root rule, redirect-pathname-only rule.
  - `.claude/rules/schemas.md` — `paths: ["src/schemas/**"]` — the schema-file-folder-collision rule, the
    discriminated-payload-location convention.
- **Generation, not hand-maintenance:** a `/compound` step (or a small script) regenerates the shards
  from KNOWLEDGE whenever a KNOWLEDGE entry with an `area:`/`paths:` tag changes. The shards are
  *projections*; KNOWLEDGE is the source. A CI check (§9) asserts shard ↔ KNOWLEDGE consistency so the
  projection never drifts — the same phantom-ref guard that protects every other pointer in this model.
- **What this replaces:** the prose "MUST read PITFALLS.md before writing in any affected area"
  `[inv Store 3]` (a 43 KB wholesale read with no scoping) becomes a native, deterministic, scoped load
  of ~the 1–6 relevant rules. **The §9 failure mode the old monolithic read caused:** the model paying
  43 KB of token cost on every code task and the *relevant* trap being buried in 558 lines
  `[inv Store 3 pathology 3]` — i.e. a real trap present-but-unread. Path-scoping makes the relevant
  constraint *unavoidable* on the matching path and *absent* (free) everywhere else.

**Tier-0 safety content does NOT shard** — it has no `paths:` because it applies everywhere
(`_EMERGING-FINDINGS §3`: "no-trigger safety content must STAY tier-1 regardless of length"). It loads
always, via `session-start.sh`. Sharding is for area-scoped constraints only.

---

## 7. The absent automated WRITER (MOVE 1 session-end emitter) — landing output IN a store

`session-end.sh` was **deliberately removed in #70 because its `claude --print` output was discarded by
the harness — never surfaced** `[FRESH GROUND TRUTH; map §3e]`. The lesson is precise: the failure was
not "no emitter," it was "emitter output went nowhere." So the V2 emitter is defined **by its
destination, not its trigger.**

- **Mechanism:** a **Stop / SubagentStop hook** (`capability-facts.md`: Stop hooks "CAN run shell
  commands and CAN block"; this is MOVE 1's surface). On a run that produced a candidate constraint
  (e.g. a corrected mistake, a `/cr` MUST-FIX that recurred), the hook **appends a row to FINDINGS.md**
  in the existing `signature`-matched schema `[inv Store 2]`. It does **not** write KNOWLEDGE directly —
  it writes the inbox, and `/compound` promotes.
- **Why FINDINGS, not KNOWLEDGE:** landing in FINDINGS preserves the **promotion gate** (human-confirmed
  before a fact becomes an always-loaded constraint) — the same reason FINDINGS exists as a separate
  store (§0). An automated writer dropping straight into the always-loaded constraint set is exactly the
  "un-vetted single observation ossifying as a rule" failure (R-5). FINDINGS is the airlock.
- **Why this fixes #70's defect:** the #70 emitter's output was discarded because it had **no store to
  land in** — there was no inbox with a reader. Now there is: FINDINGS has a real automated writer
  (`/cr` Step 3) *and*, post-MOVE-6, a real reader (task-start). The emitter's row is appended to a file
  that is read at the next relevant task. **Output lands in a store and is read** — the exact thing #70
  lacked. This is the answer to "the writer must land its output IN a store": it lands in FINDINGS.
- **Capability caveat (honest):** the guide is internally hedged on Stop-hook "force-continue" semantics
  (`capability-facts.md`); the emitter here only needs **append-and-allow-stop** (write a row, do not
  block), which is the *non-controversial* Stop-hook capability. We do not rely on the hedged
  force-continue path. ⚠️ Verify the append-on-stop path empirically before shipping (it's a one-session
  check, MASTER-FINDINGS §G).

---

## 8. The drift / decay detector (catches doc-STALE, doc-FICTION/phantom-refs, AND DECAY)

`/scan-context` is documented but absent `[map §6; MASTER-FINDINGS §B MOVE 3]`; **no CI check validates
any knowledge artifact today** `[C3-G3, C3-G10]`. Phantom refs are our *live* failure class (the audit
itself rotted, `[map §0]`). This is one CI check (`ci.yml` job, deterministic, runs every PR/push) with
three assertions over the three target stores + the cache:

1. **DECAY (the unrun 90-day sweep, now executed).** For every KNOWLEDGE entry with `tier: area` (i.e.
   not `safety`, not `kind: decision`): if `last_seen` > 90 days → flag as decay candidate in the CI
   output. This converts `/compound` Step 7's manual, visibly-unrun sweep `[inv Store 1 pathology 4]`
   into a check that fails-soft (reports, doesn't block) every run. The clock that was missing
   (`_EMERGING-FINDINGS §1`: "our failures are temporal — a missing clock") is now a CI cron-equivalent:
   it runs on every push, so a stale entry surfaces within one PR cycle, not "whenever someone runs
   /compound" (which the dates show is ~never).

2. **DOC-FICTION / phantom-refs (the live failure class).** Three pointer-integrity assertions:
   - Every `.claude/rules/*.md` entry ↔ a backing KNOWLEDGE entry (shard projection integrity, §7).
   - Every `superseded-by <file>` pointer in solutions/ and every `Superseded by NNNN` in a `kind:
     decision` KNOWLEDGE entry resolves to a real target (no dangling supersession).
   - Every FINDINGS entry marked `promoted` exists in KNOWLEDGE (no phantom promotion, §1).
   - Every file path cited in a KNOWLEDGE/solutions entry (`Example locations`, `paths:`) exists on disk
     (catches the "doc references a moved/deleted file" rot directly).
   This is the assertion that would have caught the audit's own rot — a reference to a thing that no
   longer exists.

3. **DOC-STALE (claim-vs-reality).** The bounded version (the unbounded version is an LLM judgment, out
   of scope for a CI check): assert that no KNOWLEDGE/solutions entry references a script, migration, or
   skill that is **absent on disk** (the `claude-md-referenced-scripts-must-exist` rule from memory.md,
   line 108 — *itself a constraint we are encoding as a check rather than re-stating as prose*). E.g.
   `scripts/pr.sh was documented but never created` is exactly this class. Catching it deterministically
   is the §9 win: the failure mode prevented is **a knowledge doc directing an engineer toward a
   workflow that breaks only when they run it** (`[inv Store 4 pathology 2]`: index drift; memory.md
   pathology: referenced-but-missing scripts are silent failures).

4. **AUTO-MEMORY de-dup signal (§5 step 2).** For each `feedback_*` cache file, assert coverage in
   KNOWLEDGE; uncovered → promotion candidate, not noise.

**One detector, four assertions, deterministic, in CI** — replacing the absent `/scan-context` and the
three separate prose freshness rules that never executed. §9 verdict: every assertion names a failure
mode (stale rule fired, phantom ref followed, broken workflow hit, learned-fact lost) — none is overhead.

---

## 9. Closing the RECURRING-FINDINGS read-path (today never read by implementers)

Stated in §1 (Store 3 reader) and §7 (emitter); consolidated here because it is MOVE 6's structural core
and the mandate calls it out explicitly. Today FINDINGS is "written by the pipeline and read only by the
pipeline" `[inv Store 2 pathology 1]` — a finding logged here is **invisible at the moment an implementer
is about to repeat it.**

**The close, in tooling:** a Phase-0 read step in `/dev`, `/feature`, and `/cr` that, before any code is
written, globs FINDINGS' `signature` and `Example locations` against the files the task will touch, and
loads matching findings into context with their occurrence count. The implementer sees "this exact
mistake recurred 4 times in this area" *before* writing, not after `/cr` catches it the 5th time. This is
the read-path the inventory says does not exist — built as a skill step (one read + a glob match), not a
new file. It is the dual of the path-scoped KNOWLEDGE load (§7): KNOWLEDGE tells you the *promoted*
constraints for this path; FINDINGS tells you the *not-yet-promoted-but-recurring* ones. Together they
make both halves of the constraint pipeline readable at the point of work.

The §9 failure mode this prevents: **the harness observing the same mistake N times, codifying it in a
file, and still letting the (N+1)th implementer repeat it because nothing put the observation in front of
them.** That is the half-open loop — closed.

---

## 10. What gets DELETED, and the §9 failure-mode for each

Per the mandate: state explicitly what is deleted and the failure mode that would otherwise go
unprevented (or mark it overhead). DELETE-CANDIDATE = flag for human confirm; CLAUDE.md forbids silent
deletion.

| Deleted | Failure mode that goes unprevented by the deletion, OR "overhead" |
|---|---|
| `.claude/memory.md` (the file) `[inv Store 1]` | **None — the content is not deleted, it MOVES to KNOWLEDGE.** The *file* is overhead once its content lives in KNOWLEDGE; keeping it would re-create the duplication we just collapsed. Safety trio is preserved verbatim as `tier: safety` entries (KEEP-VERBATIM floor honored). |
| `PITFALLS.md` (the file) `[inv Store 3]` | **None — content MOVES to KNOWLEDGE + `.claude/rules/`.** The file is overhead post-migration; keeping it alongside KNOWLEDGE re-opens the dual-layer ambiguity (§4) and the monolithic-read cost (§6). |
| `docs/adr/` (the dir) `[inv Store 5]` — **high-scrutiny, see §3a** | **A document shape is lost** (Context/Decision/Alternatives/Consequences flattened to a KNOWLEDGE entry). This is the one deletion with a real cost, not pure overhead. The §9 trade: fewer stores + ADRs wired into path-load vs. the richer ADR doc form. **Flagged as the top open decision (§11).** If Tanner values the doc shape, this deletion is reversed and count is 4. |
| `RECURRING-FINDINGS.md` name (renamed to FINDINGS.md) | Not a deletion — a rename. No failure mode. |
| Auto-memory `feedback_*` files | **NOT deleted** (subsystem-owned, can't). Demoted to cache (§2). Attempting deletion is overhead (they regenerate). |

**Net file-kind change: 6 stores → 3 author-facing (+1 fenced cache).** The deletion win here is
*duplication elimination* (the same fact in 3–4 files → 1), not raw file count — consistent with the
binding principle that consolidation/convergence is the win, and with the census finding `[inv Part B
synthesis]` that the load-bearing knowledge docs are MERGE/WIRE subjects, not raw deletes.

---

## 11. Open decisions (genuine forks for Tanner)

1. **ADR merge — the biggest fork (§3a, §10).** My FEWEST-STORES mandate merges adr/ into KNOWLEDGE as
   `kind: decision` entries. A coherence-optimized candidate would keep adr/ as its own clean store and
   only *wire* it into `/cr`. Cost of merging: the ADR document shape (Context/Decision/Alternatives/
   Consequences) flattens. **This is the first thing to overrule if the doc shape matters more than the
   file-count win.** Keeping adr/ → 4 author-facing stores, nothing else changes.
2. **Can the harness influence what auto-memory loads first?** §2's conflict-resolution rule
   ("KNOWLEDGE wins on conflict") is the *one prose line I could not replace with tooling*, because the
   CC memory subsystem is not ours to hook. If there is a supported way to fence/prefix the subsystem's
   auto-load, that line becomes a mechanism. Needs a capability check (is the subsystem hookable?).
3. **Does the Stop-hook append-on-stop path work as assumed (§7)?** The capability guide is hedged on
   Stop-hook semantics. The emitter only needs append-and-allow-stop (the non-controversial path), but
   this needs the one-session empirical check (MASTER-FINDINGS §G item 1) before relying on it.
4. **Shard generation: script or `/compound` step?** §6/§7 regenerate `.claude/rules/*.md` from
   KNOWLEDGE. Whether that lives in a tiny `scripts/gen-rules.sh` (deterministic, runs in CI) or as a
   `/compound` step (runs at capture time) is a small build choice — script is more "boring/deterministic"
   per the binding principle, leaning that way, but flagging it.
