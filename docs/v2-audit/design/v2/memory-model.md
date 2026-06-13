# V2 Memory + Compounding Model — the concrete stores, writers, readers, freshness, and the loop

> **What this is.** The concrete memory + compounding design for V2: the exact stores on disk, the single
> writer and single reader and single freshness rule for each, and the wired compounding loop (run →
> write-back → airlock → promote → read-path → ratchet → measure → drift). It is the world-class form of
> VISION Pillar 4 (HOOK-1, CMP1–6) standing on the SOUND conservative mechanics from
> `phase3/RECONCILIATION.md §B` (3 owned stores + 1 ridden auto-memory cache; entry-as-atom; the S3
> airlock + promotion gate; ride the platform).
>
> **Rigor contract.** Every store, writer, reader, and loop edge cites a ground-truth row (§N in
> `CANONICAL-HARNESS-AS-IS.md`) or a confirmed absence, and names the failure mode it prevents. The
> RECONCILIATION §B corrections are folded in as the authoritative position (auto-memory→S1 graduation is a
> NET-NEW `/compound` step, not a retarget; no `/note` skill; shard only where a clean `paths:` glob exists;
> `00-safety.md` absorbs memory.md's richer text VERBATIM before memory.md is deleted; "on conflict curated
> stores win" is one prose line). Doer≠checker: this is the design; the adversarial pass (WF5) is the checker.
>
> **Ground truth re-verified on disk this session (2026-06-11):** `.claude/rules/` ABSENT; `session-end.sh`
> ABSENT (§5); auto-memory = 53 files at `~/.claude/projects/.../memory/` (§6, a 6th store the canon ignores);
> `docs/RECURRING-FINDINGS.md` PRESENT (16 KB); `PITFALLS.md` = 558 lines; `docs/solutions/` = 33 docs + README
> + TEMPLATE; `docs/adr/` = 6 ADRs + README; `/cr` Step 3b is the one real automated S3 writer
> (`cr/SKILL.md:174,225`); `/compound` reads `.claude/memory.md` only — it does NOT read the auto-memory
> corpus (`compound/SKILL.md:80–164`); `/scan-context` referenced in `rituals.md` but ABSENT on disk (§6
> phantom); `.cr-ok` gitignored, never reaches CI (§3f / capability-facts.md:76).

---

## 0. The one-paragraph thesis

The harness today has the **write** side of compounding (`/cr` Step 3b auto-counts RECURRING-FINDINGS) but
the loop never closes: that ledger is **"never read by implementers"** (§4), promotion ends at a
human-read doc, the §9 re-audit is nobody's job, and `/scan-context` is canon-referenced but absent while
the canon itself cites five phantom artifacts (§6) — a *live* failure class. Underneath, the same
corrected-mistake fact lives in **three places at once** — `.claude/memory.md` + `PITFALLS.md` + auto-memory
`feedback_*` files — a triple-duplication "the canon both sanctions and forbids" (§4), reconciled only in
prose, encoded in no tooling. V2 fixes both at the root by making the **entry** the atom (not the file):
three harness-owned stores plus one ridden subsystem cache, each with one writer / one reader / one freshness
rule, wired into a loop where every run writes back through an airlock, recurring findings promote into the
implementer's *next* starting context, a finding that crosses the threshold **ratchets into a deterministic
block** (not a note), the loop's own health is **measured** (first-pass-approval, recall), and **drift is
detected in both directions on a schedule** so the canon can never quietly become fiction again. Copies-per-fact
goes **3 → 1**; the half-open loop closes; and the phantom-ref class that already bit this repo becomes a
caught CI failure.

---

## The stores

Target = **3 harness-owned stores (S1/S2/S3) + 1 ridden auto-memory cache.** Each row gives the store, its
kind, where it lives, the ONE writer, the ONE reader (+when), and the ONE freshness rule. The single-writer /
single-reader discipline is what dissolves the §4 dual-assignment ambiguity and the triple-duplication.

| Store | Kind | Lives at | ONE writer | ONE reader (+when) | ONE freshness rule |
|---|---|---|---|---|---|
| **S1 — durable constraints + decisions** (the rules + floor) | Negative, short, preventive, push-loaded ("never X here") | `.claude/rules/*.md` (NEW, path-tiered shards) + the always-load `00-safety.md` / CLAUDE.md floor | **The promotion conveyor** — `/cr` Step 3b *and* `/compound` (S3→S1, one logical writer, two trigger points); the `00-safety` floor is **human-edited only** (no-agent-edits-guard-files) | **The platform, by path.** `00-safety` + behavior floor always-loaded; area shards auto-load via native `paths:` globs when a matching file is touched (capability-facts.md:52) | **fires-or-evicts:** each entry carries `last_fired`; >90 days unfired → CMP4 eviction *candidate*. Exempt: `tier:safety` (never decays) and `kind:decision` (goes *superseded*, not stale — carries `superseded-by:`) |
| **S2 — reusable patterns** ("how we solved X") | Positive, long, recipe-shaped, pull-loaded | `docs/solutions/` (unchanged) | **`/compound`** after a merged feature (existing single-writer contract — `solutions/README.md`) | **`/dev` / `/feature` at task-start**, via a glob-injected read of `docs/solutions/` matching `area:`/`tags:` of the files the task will touch | **supersession, not time-decay** — patterns are durable; they die by being replaced (`status: active | superseded-by <file>`). A no-reference-in-365-days *archive* flag is advisory only |
| **S3 — findings INBOX / airlock** | Captured signal awaiting promotion (occurrence-counted, unverified) | `docs/RECURRING-FINDINGS.md` (the existing ledger) | **Two automated emitters, one schema, matched on `signature`:** (1) `/cr` Step 3b (exists — the one real writer, `cr/SKILL.md:174`); (2) the HOOK-1 session-end capture payload (CMP5, NEW). Humans append via the existing manual path / `/compound` — **no `/note` skill** | **task-entry skills at task-start** (CMP1) — `/dev`/`/feature`/`/cr` glob the ledger's `signature`/`Example locations` against the files about to be touched and surface matches + occurrence count, with 90-day decay on the read | **occurrence-count + status + a promotion clock:** `active | promoted | retired`, cap-at-5; ≥3 sitting `active` >14 days → CMP4 flags overdue-promotion; `active` with no new occurrence in 30 days → auto-retire (noise); retired >90 days compacted out |
| **(cache) — auto-memory** | Subsystem capture — ridden, never owned | `~/.claude/projects/.../memory/` (outside repo) | **The Claude Code memory subsystem** (free auto-writer; the harness never writes it) | **The platform** auto-loads first 200 lines / 25 KB at session start (capability-facts.md:54) | **Outranked on conflict** — "on conflict, curated stores (S1–S3) win" is one prose line in CLAUDE.md (the subsystem is not ours to hook — the model's single irreducible prose-only seam, Open Decision D3) |

**Why exactly 3 owned stores (not 2, not 4) — the cuts that hold:**

- **Not 2 (S1+S2 merged):** constraints and patterns have *opposite freshness* (a constraint can decay when
  it stops firing; a pattern is durable until superseded) and *opposite read-triggers* (path-scoped always-on
  vs. on-demand grep). Forcing one freshness + one trigger onto both re-creates the §4 dual-layer ambiguity
  we are killing. **Failure prevented:** a durable pattern decay-swept as a stale rule, or a stale rule
  surviving because it shares a file with durable patterns.
- **Not 2 (S3 inbox merged into S1):** S3 holds *unverified, observed-once* candidates; S1 holds
  *human-confirmed, always-loaded* constraints. Collapsing them removes the **promotion gate** — the airlock.
  **Failure prevented:** an un-vetted single observation auto-promoted to an always-loaded rule and ossifying.
- **Not 4 (ADR as a distinct store):** ADR projects *into* S1 as `kind:decision` (delivery), while
  `docs/adr/` stays as the long-form authoring home (Context/Decision/Alternatives/Consequences). One physical
  store, ADR lifecycle preserved as a per-entry property. **This is the D1 disposition, §"ADR" below.**
- **Auto-memory is the 4th thing on disk but NOT a 4th owned store** (§6): a cache the harness rides (reads
  free, never writes, cannot evict), explicitly demoted below S1–S3 on conflict.

**Net (the RECONCILIATION §E budgets, scored separately):** *Budget (1) — agent-context/advisory prose* falls
hard (memory.md merged & deleted; the 558-line PITFALLS monolith → ~5–6 path-scoped shards that load 1–2 per
task, not all 558 lines on every code task; the ~172 KB/`/cr`-4-lens PITFALLS pass collapses; **copies-per-fact
3 → 1**). *Budget (2) — deterministic enforcement* grows in a measured, §9-gated way (the HOOK-1 capture hook,
the CMP4 drift CI, the `gen-rules` generator). Total tracked files end ≈ flat; the advisory-prose budget and
per-task token cost fall sharply. **Never report the budget-(1) win as a total-file-count win** (RECONCILIATION
§A red flag).

---

## The three load-bearing ideas

These three ideas carry the whole model. Each dissolves a specific §-cited pathology.

### 1. Entry-as-atom — `tier:` / `kind:` / `freshness:` are per-entry properties

The disease in §4 is **file-as-the-unit-of-store**: when the *file* is the atom, the same fact lands in three
files (`.claude/memory.md` + `PITFALLS.md` + auto-memory), each file accretes with no exit, and PITFALLS.md +
memory.md get assigned to *both* Layer 1 (Context) and Layer 3 (Memory) "depending on the page" (§4 admitted
ambiguity). Making the **entry** the atom — every entry carries `tier:` (safety | area), `kind:` (trap |
decision | pattern), and `freshness:` (last_fired / superseded-by / occurrence-count) — dissolves the
dual-assignment in the *data model*, not in prose: an entry's home is now a deterministic function of its
properties (a `tier:safety` trap lives in always-load `00-safety.md`; an `area:migrations` trap lives in the
path-scoped `migrations.md` shard; a `kind:decision` projects from `docs/adr/`). **Failure prevented:** the
§4 ambiguity where the same store is "Layer 1 here, Layer 3 there," and the triple-duplication it licenses.

### 2. The S3 airlock + promotion gate — an observation cannot become an always-loaded rule without a gate

`docs/RECURRING-FINDINGS.md` is the **airlock**: the one place a finding sits at occurrences=1 without
polluting the always-loaded constraint set. Promotion to S1 requires **≥3 occurrences + a human/`/compound`
confirm** (the existing `/cr` Step 3b threshold, `cr/SKILL.md:179–225`). The gate is what makes "close the
read-path" safe — CMP1 reads the *airlock* back to implementers (cheap, advisory, occurrence-tagged) and only
the *promoted* half becomes an always-loaded S1 rule. **Failure prevented:** a single un-vetted observation
auto-promoted to an always-loaded rule and ossifying (the "forgeable/stale gate" failure); and the inverse —
a real recurring finding that never promotes because the judgment gate had no clock (§4: freshness rules exist
for only 3 stores; the promotion gate had none). CMP4 supplies the missing clock (≥3 + `active` >14 days →
flagged overdue).

### 3. Ride the platform — auto-memory + native `paths:`, invent nothing

Two native levers replace two hand-rolled layers. (a) **Auto-memory** (§6) is the free capture subsystem the
canon ignores; V2 *rides* it as an untrusted capture cache rather than hand-maintaining `.claude/memory.md` as
a parallel store — and graduates survived entries via a NET-NEW `/compound` step (RECONCILIATION §B.1: this is
a *build*, not a retarget, because `/compound` reads memory.md only today). (b) **`.claude/rules/` + `paths:`
globs** are native path-scoped lazy-loading (capability-facts.md:52) — editing a migration auto-loads
`migrations.md` only, replacing the 558-line monolithic PITFALLS read. **Shard only where a clean `paths:` glob
exists** (RECONCILIATION §B.3): `00-safety` always-loads; `migrations`/`data-layer`/`schemas`/`auth-routing`/
`architecture` are path-scoped; path-less constraints (worktree ops, destructive-op safety, the external-tool
rule) live in `00-safety` + a small always-load process section, NOT in fake shards with no trigger. **Failure
prevented:** re-hand-rolling a capture layer (auto-memory) and a delivery layer (a custom rules loader) the
platform already runs — the exact §6 mistake, and a shard with no glob that is pure overhead with worse
discoverability than the always-load floor.

---

## The compounding loop, wired concretely

The loop is: **run → write-back → S3 airlock → promote → read-path → ratchet → measure → drift-detect.** Each
edge is a named VISION move with a concrete mechanism, a citation, and a failure mode. The loop is what turns
the harness from write-only (§4: "never read by implementers") into a system that is smarter every cycle.

```
   ┌─────────────────────────────────────────────────────────────────────────────────────┐
   │                                                                                       │
   │   RUN ──HOOK-1 session-end (CMP5)──▶ S3 airlock ──promote (≥3+human)──▶ S1 rules      │
   │    ▲      (human-confirmed,            (RECURRING-      │                  │           │
   │    │       degrade-safe)               FINDINGS.md)     │                  │           │
   │    │                                       │           CMP2 ratchet:      │           │
   │    │                                  CMP1 read-path:   ≥3 ─▶ deterministic│           │
   │    │                                  S3+S1 ─▶ task-    block (hook/lint/  │           │
   │    └───────── next run starts with ◀──start context     C5 lens), not a   │           │
   │               last cycle's lessons    (90-day decay)    note               │           │
   │                                                                            │           │
   │   CMP3 metrics ledger (first-pass-approval, cycle-count) + C4 golden recall│           │
   │   CMP4 scan-context (stale + fiction + decay) ── cloud /schedule ──────────┘           │
   │                                                                                       │
   └─────────────────────────────────────────────────────────────────────────────────────┘
```

### Edge 1 — RUN → write-back: HOOK-1 session-end capture (CMP5), human-confirmed, degrade-safe

**Mechanism.** Build *one* shared `Stop`/`SubagentStop` hook surface — the canon-declared-but-ABSENT
`session-end.sh` (§5) — and treat its jobs as **payloads, not separate features** (HOOK-1): (a) the
regression-evidence bundle (test + typecheck, block-on-red — the part a hook *can* do, capability-facts.md:11–13);
(b) **the CMP5 memory-capture proposer** — propose S3/memory candidates from corrections observed during the
session; (c) F7's retry-ceiling counter; (d) the L7 narration emitter. The capture payload **proposes; the
human confirms** (deliberately NOT a deterministic mistake-detector — a capability the design does not claim);
the confirmed finding appends to **S3** (the airlock) with a `last_seen` date feeding CMP4's decay.

**Degrade-safe (Open Decision D2 — the load-bearing risk).** Whether a Stop hook can *see* the turn's
corrected-mistake signal is gated on a one-session empirical check. **If it can:** full session-end auto-capture.
**If it can't:** degrade to `/cr` 3b (already auto-writes S3) + manual append — **still better than today.** The
hook is additive, `exit 0`-only, append-only, and coexists with the existing sound-only Stop hook
(`settings.json:191`); the plugin's `hooks.json` replaces the hand-edit at extraction.

**Failure prevented:** at fleet scale the system generates failures faster than a human can hand-transcribe
lessons, and the playbook ossifies (§5: disk memory capture is "fully manual"); plus building four overlapping
Stop hooks that fight over the guard file (a second Stop hook is itself a human guard-file edit). *Citation:*
confirmed absence — §5 (`session-end.sh`); capability-facts.md:11–20.

### Edge 2 — S3 airlock → promote: the gate (≥3 + human) into S1

**Mechanism.** `/cr` Step 3b detects ≥3-occurrence findings and surfaces promotion candidates
(`cr/SKILL.md:179–225`); the write **retargets from `PITFALLS.md` to `.claude/rules/<area>.md`** (area from
the finding's matched `Area:` field — present on 36 PITFALLS entries today, so the routing is mechanical).
`/compound` is the **second** promotion trigger and gains a **NET-NEW step** (RECONCILIATION §B.1) that walks
the auto-memory corpus and surfaces survived-2+-session traps as promotion candidates — this is a *build* (today
`/compound` reads memory.md only), counted in budget (2). The candidate is emitted paste-ready; **the human
applies** (CLAUDE.md forbids silent edits to always-loaded knowledge). The clock is now in tooling: CMP4 flags
any ≥3-occurrence finding sitting `active` >14 days (overdue promotion). On promotion the entry is set
`promoted` and the drift check **asserts it now exists in S1** — a "promoted" finding can never be a phantom.

**Failure prevented:** the §4 "judgment gate with no clock" (a finding that should promote but silently never
does); and the inverse, a bad auto-promotion polluting the always-loaded set. *Citation:* §4; `cr/SKILL.md:225`;
`compound/SKILL.md:139–164`.

### Edge 3 — promote → read-path: CMP1 closes the loop into the implementer's task-start context, with 90-day decay

**Mechanism.** Bitloops drove violations down 87–100% over 8 weeks purely by feeding caught violations back as
generation context; our harness has the write side but it is **"never read by implementers"** (§4). Add a Phase-0
read step to `/dev`/`/feature`/`/cr` that globs **S3's** `signature`/`Example locations` *and* **S1's**
path-scoped rules against the files about to be touched, and surfaces matches with their occurrence count
("you are about to edit `src/data/`; a finding here recurred 4× in this area"). The **promoted half** (≥3) lands
in S1 and is *additionally* auto-delivered by native `paths:` — so the read-path is partly the platform's.
**Decay:** a pattern unobserved 90 days collapses (do NOT build `learned-patterns.md` — a §6 phantom; the
read-path IS the kept part). Measure first-pass-approval (CMP3) to confirm it works.

**Failure prevented:** an agent making the same class of mistake every run because nothing it was corrected on
is read back at the next run's start (the open read-path, §4). *Citation:* §4, §9; the `learned-patterns.md`
phantom is §6 — read-path is the kept form, the file is the killed form.

### Edge 4 — finding → enforcement: CMP2 ratchet — recurring finding becomes a deterministic block, not a note

**Mechanism.** Hashimoto's definition of harness engineering: "anytime you find an agent makes a mistake,
engineer a solution such that the agent never makes that mistake again"; our harness is "overwhelmingly
advisory." When a finding crosses ≥3 and promotes, a **ratchet pass** (a `/compound` sub-phase or `/ratchet`
skill) classifies it: *can this be a deterministic block?* — a `PreToolUse`/pre-commit hook, an `error`-severity
lint rule (with `--max-warnings 0`, because `npm run lint` exits 0 on warnings — RECONCILIATION §C.4), or a new
**C5 governance-lens criterion**. If yes, **generate the enforcement artifact in the same flow** and note only
when a deterministic block is genuinely impossible. Composes with C5 (adds criteria to the bootstrapped
governance lens), F8 (a rising failure signature *is* the mistake-trigger), and the distribution pillar (earned
blocks travel via the plugin). The enforcement is **budget (2)** (unforgeable, out-of-band); the S1 rule shard
is the *teaching copy*.

**Failure prevented:** re-finding the same bug forever instead of making it *impossible* — the difference between
a harness that writes notes and one that compounds. *Citation:* §3e (overwhelmingly advisory), §4.

### Edge 5 — measurement: CMP3 metrics ledger + C4 golden-set recall

**Mechanism.** Every source that *improved* measured something and watched it move; our model is all knowledge
stores with no row for first-pass-approval (§4). Two measurement surfaces: **(CMP3)** a lightweight
in-repo/GitHub-canon ledger per agent PR — review-cycle-count, REJECT-or-not, per-finding recurrence, PR-size
trend — surfaced as a periodic cloud-`/schedule` report. Day-0-measurable fields (cycle-count, recurrence) are
**P0**; first-pass-approval-rate and post-merge-defect attribution need real merged-PR volume → **P1** with a
volume flip-trigger. **(C4)** a `golden-set/` corpus of adversarially-seeded labeled diffs + clean diffs; a
`/cr-calibrate` CI job emits recall + false-positive-rate per pass/lens, re-run on any change to `/cr` passes /
the tier-merge rule / the model. The metrics close the loops: first-pass-approval confirms compounding;
recurrence is CMP1's eviction signal; PR-size trend tunes F7; C4 recall gates unattended self-merge.

**Failure prevented:** "review skills deployed then evaluated anecdotally" — running a self-improving loop on
vibes, with an unknown (possibly catastrophic) miss rate, right after a blind Sonnet 4.6 → Opus 4.8 swap.
*Citation:* confirmed absence — §4, §6 (`@benchmark-runner` phantom).

### Edge 6 — drift detection: CMP4 `/scan-context` (stale + fiction + decay), on a cloud schedule

**Mechanism.** Build `/scan-context` (canon-documented in `rituals.md`, ABSENT on disk — itself a live phantom,
§6), two modes against our own repo + a decay pass: **(staleness)** every path/command/skill claim in canon
still exists on disk; **(fiction)** every named artifact reference exists on disk — the more dangerous direction,
the doc-fiction class our own canon already exhibits; **(decay)** every S1 rule carries `last_fired`; >90-day
unfired → demotion candidate; flag any surviving triple-duplication (a fact in S1 + S3 + auto-memory). It
**houses the L5 cross-skill reference-integrity check**. Wired into `/compound`, `/cr`, and a cloud `/schedule`
job (the canon has **no cron** — §3e: rituals fire only at session start, so every "weekly" review ran twice
and died). The **detection half is P0**; the fix-proposing repair-worker is P1, gated on Fork F7
(auto-revert-pure-fiction vs flag-NEEDS-HUMAN).

**Failure prevented:** shipping a harness whose own canon is partly fiction — the §6 phantom-ref class (canon
cites `learned-patterns.md`, `review-log.md`, `triage-inbox.md`, `/prototype-interface`, `/scan-context`,
`@benchmark-runner`, `skills-lock.json`, `agentic-system-enabled` — all referenced, none built), worse at
fleet scale where an agent re-onboards from the stale doc thousands of times and reasons wrongly with full
confidence. *Citation:* confirmed absence — §5, §6, §3e.

---

## How the OLD triple-duplication collapses (copies-per-fact 3 → 1)

§4 names the live disease: a corrected-mistake fact lives in **`.claude/memory.md` + `PITFALLS.md` + auto-memory
`feedback_*` simultaneously**, with `/compound` itself flagging memory entries as "already covered by PITFALLS
(redundant)." Trace one fact — *"never reuse a token found in an unrelated file"* — through the collapse:

| | OLD (3 copies, §4) | V2 (1 canonical copy + 1 demoted cache) |
|---|---|---|
| `.claude/memory.md` | Copy 1 (read every session start) | **DELETED** — its richer destructive-op/incident text absorbed **VERBATIM** into `00-safety.md` first (RECONCILIATION §B.4, the KEEP-VERBATIM floor; memory.md is not deleted until the absorb target is verified to carry the richer narrative + `How to apply:` steps) |
| `PITFALLS.md` | Copy 2 (read before writing code) | **the canonical copy** — one S1 entry (`tier:safety` → `00-safety.md` always-load) |
| auto-memory `feedback_*` | Copy 3 (subsystem auto-load) | **the demoted cache** — still auto-loaded by the platform, but **outranked**: "on conflict, curated stores win" (one prose line; the subsystem is not ours to hook — D3) |

**Copies-per-fact 3 → 1** (the cache is not a 4th copy of record — it is explicitly demoted). The collapse is
not bytes moving into enforcement; it is **memory.md deleted (after verbatim absorb), PITFALLS sharded into one
canonical home per entry, and the auto-memory copy demoted by precedence.** Per-`/cr` PITFALLS token cost
(~172 KB across 4 lenses) drops to a path-scoped fraction; the always-load floor stays flat-to-down because
`00-safety` absorbs the deleted CLAUDE.md NEVER-section + memory.md safety text. This is the budget-(1) win, and
it is the whole point of the model.

---

## How scan-context catches the phantom-ref live failure class

The phantom-ref class is not hypothetical — it is the harness's **dated proof**: the audit artifact itself
rotted and shipped **four false absences** (RECONCILIATION header), and the canon references **eight** named
artifacts that exist nowhere (§6). CMP4's **fiction mode** is the deterministic catch:

1. **Enumerate every artifact reference** in canon/skills/rules — `learned-patterns.md`, `review-log.md`,
   `triage-inbox.md`, `/prototype-interface`, `/scan-context`, `@benchmark-runner`, `skills-lock.json`,
   `agentic-system-enabled`, every `paths:` glob target, every `scripts/*` referenced in CLAUDE.md.
2. **Assert each exists on disk** (the `claude-md-referenced-scripts-must-exist` rule, routed from the
   non-safety memory trap per RECONCILIATION §B.4) — a missing target is a **CI failure**, not a silent stale
   doc.
3. **Run it on every merge** (the P9 CI check) *and* on a cloud `/schedule` scan (the detection routine) — so a
   reference added today that points at a file deleted tomorrow fails the next scan, in either direction.

This converts the harness's own live failure mode (a canon that is partly fiction, undetected) into a caught,
located, ticketed failure — and it is the precondition that lets the whole compounding loop be trusted, because
a loop reading from a fictional store compounds the fiction. **Failure prevented:** the exact class that already
bit this repo, multiplied across 5+ repos where a stale canon is re-onboarded thousands of times.

---

## The ADR disposition (D1 — the biggest fork)

**Recommended disposition: project into S1 as `kind:decision`, keep `docs/adr/` long-form.** ADRs become S1
entries tagged `kind:decision` (decay-exempt — they go *superseded*, not stale; carry a `superseded-by:` field),
delivered via the path-scoped `architecture.md` shard — so the count of *physical owned stores* stays at 3 while
ADR's **document shape and supersession lifecycle are preserved as per-entry properties**. `docs/adr/` is
**retained as the authoring / long-form home** because the Context/Decision/Alternatives/Consequences shape is
load-bearing for *writing* a decision, while the S1 rule entry is the *delivery projection* (generated,
drift-CI-checked so the projection never diverges — the same `gen-rules.sh` + CMP4 assertion that keeps shards
honest).

This spends a small, bounded "two homes, one fact" cost — mitigated by **generation + drift CI** (the projection
is generated from `docs/adr/`, and CMP4 asserts shard ↔ source consistency, so it cannot silently drift into a
fourth duplication). The alternatives (flatten `docs/adr/` into S1 entries and lose the long-form shape; or keep
ADR as a distinct 4th owned store) trade strict-minimal-count against coherence-purism; the recommended middle
keeps both the 3-store count and the ADR lifecycle. **Open as D1 / RECONCILIATION §F.1 for Tanner's ratification.**
*Citation:* §4 (ADR as a canon store), §6 (no ADR phantoms today — 6 ADRs + README on disk).

---

## Open decisions this model surfaces (carry to the decision brief — do not resolve unilaterally)

- **D1 — ADR disposition:** project into S1 as `kind:decision` + keep `docs/adr/` long-form (recommended) /
  flatten to S1 / keep ADR as a distinct 4th store. (§"ADR disposition" above.)
- **D2 — HOOK-1 capture: fully automatic vs degrade.** Build the Stop hook for append-and-allow-stop (safe
  capability); gate full session-end auto-capture on a one-session empirical check (can the hook see the turn's
  corrected-mistake signal?). If it fails, degrade to `/cr` 3b + manual append. **The load-bearing risk in the
  memory model** (RECONCILIATION §F.2).
- **D3 — auto-memory authority: prose-only forever, or a capability spike?** "On conflict, curated stores win"
  is the one irreducible prose-only line (the subsystem is not hookable). Ship the prose now; decide later
  whether to spend a spike probing whether the auto-load is fence-able/priority-able (RECONCILIATION §F.3).
- **D4 — shard generation:** `scripts/gen-rules.sh` in CI (recommended, deterministic) vs a `/compound` step
  (RECONCILIATION §F.4).
- **D8 — ratify the two-budget reframe:** accept ~flat total file count as the price of determinism (recommended)
  vs hold a harder file-count line and leave more rules advisory (RECONCILIATION §A / §F.8).

---

## Status

Concrete V2 memory + compounding model: 3 owned stores + 1 ridden cache, each with one writer / one reader /
one freshness rule; the three load-bearing ideas (entry-as-atom, the S3 airlock, ride the platform); the
compounding loop wired edge-by-edge (HOOK-1 → S3 → promote → CMP1 read-path → CMP2 ratchet → CMP3/C4 measure →
CMP4 drift) on a cloud schedule. Every store, writer, reader, and edge cites a §N ground-truth row or a confirmed
absence and names its failure mode; the RECONCILIATION §B corrections are folded in as the authoritative
position; copies-per-fact collapses 3 → 1; the phantom-ref class becomes a caught CI failure. Doer≠checker: this
is the design input to the WF5 adversarial review.
