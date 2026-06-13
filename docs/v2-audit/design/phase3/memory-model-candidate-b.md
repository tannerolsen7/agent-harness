# Memory Model — Candidate B (Designer B)

**Angle: CLEANEST LIFECYCLE.** Model knowledge as a pipeline of explicit *stages*, not a set of
*files*. Each stage has exactly one owner and exactly one mechanism that moves knowledge to the next
stage or evicts it. The win is not "fewer files" as a vanity metric — it is **no store that grows
monotonically with no encoded exit**. Every store in this model has a tool-enforced way for an entry
to *leave* it. That is the property today's six stores collectively lack, and it is the source of
every pathology in the census.

Re-verified on disk this session: `.claude/rules/` ABSENT; `session-end.sh` ABSENT (removed #70);
`/cr` Step 3b is the only automated writer (`.claude/skills/cr/SKILL.md:174`); `/compound` Step 9 is a
manual 90-day review that *explicitly does not modify* memory.md (`.claude/skills/compound/SKILL.md:164`
"Do not modify memory.md. Surface candidates and wait for direction"); `/compound` Step 6 proposes
memory.md entries, Step 5 checks PITFALLS promotion. Five ADRs, 33 solution docs + README + TEMPLATE,
auto-memory at 52 files.

---

## 0. The lifecycle frame (why stages, not files)

Today's defect, stated as a pipeline, is that the knowledge pipeline has **stages with no conveyor
belt between them**:

```
  CAPTURE          PROMOTE          CANONICAL         DECAY / EVICT
  (raw signal)  →  (recurs enough)→ (locked truth) →  (no longer true / never fires)
```

- **CAPTURE** exists three times over (RECURRING-FINDINGS auto, memory.md manual, auto-memory
  subsystem-auto) and they don't feed one promote step — they each promote separately or not at all.
- **PROMOTE** is manual and clockless everywhere (RECURRING→PITFALLS is "human confirms";
  memory→PITFALLS is `/compound` Step 9, optional, unrun).
- **CANONICAL** is split across PITFALLS (traps), ADR (decisions), solutions (positive patterns) — and
  PITFALLS is ALSO a capture store (direct adds), so it is two stages wearing one filename. This is the
  dual-layer (L1 Context vs L3 Memory) confusion at root: PITFALLS is assigned to both layers because it
  literally does two stage-jobs.
- **DECAY/EVICT** is documented for 3 stores and *executed for none*. Auto-memory grows monotonically
  with a 25 KB auto-load cap, so stale entries inside the cap displace fresh signal — the worst case of
  the general disease.

Candidate B fixes this by making each *stage* a single store with a single owner, and putting the
*conveyor* (promotion + eviction) in tooling. A store may only exist if it is exactly one stage.

---

## 1. Target store set — **4 stores** (down from 6)

| # | Store | Stage | Lives at |
|---|---|---|---|
| **S1** | **`.claude/journal.jsonl`** (NEW) | CAPTURE — all raw run-signal, one append-only log | `.claude/journal.jsonl` |
| **S2** | **`PITFALLS.md` + `.claude/rules/*.md`** | CANONICAL-CONSTRAINTS — corrected-mistake traps, path-tiered | repo root + `.claude/rules/` (NEW dir) |
| **S3** | **`docs/adr/`** | CANONICAL-DECISIONS — locked architecture | unchanged |
| **S4** | **`docs/solutions/`** | CANONICAL-PATTERNS — reusable positive patterns | unchanged |

Four. The justification for the count is **stage-uniqueness, not arbitrary reduction**:

- There is exactly **one CAPTURE stage**, so exactly one capture store (S1). Today there are three
  capture stores (RECURRING-FINDINGS, memory.md, auto-memory feedback_*). Collapsing three → one is the
  single largest structural win and the direct kill of the triple-duplication.
- There are **three kinds of canonical knowledge** that genuinely differ in *read trigger and
  lifecycle* — a constraint (read before editing matching files; evicted when it stops firing), a
  decision (read at design time; superseded never decayed), a pattern (read when solving a matching
  problem class; durable). These are not collapsible: a trap and an ADR have different read-triggers and
  different freshness semantics. So three canonical stores, S2–S4.
- **Why not 3?** Merging PITFALLS into ADR/solutions would re-create the dual-stage-per-file disease
  (a trap is a constraint, not a decision). **Why not 5?** Because RECURRING-FINDINGS and memory.md and
  the feedback_* corpus are all the *same stage* (CAPTURE) and must not be three files. **Why not keep
  auto-memory as a 7th?** Because we cannot delete the subsystem store, but we *can* demote it to a
  cache and stop treating it as authoritative — §4 below. It is not in the target set because it is not a
  store we own; it is an OS-level cache we read defensively.

The auto-memory subsystem store (Store 6) is **not in the target set** — it remains on disk because we
cannot turn the subsystem off, but the model below reclassifies it from "store" to "untrusted cache"
and stops writing the duplicate facts that feed it. See §4.

---

## 2. Per-store contract (one writer · one reader+when · one freshness rule · lifecycle-in-tooling)

### S1 — `.claude/journal.jsonl` — CAPTURE (NEW)

The single raw-signal log. One line per captured observation. Replaces RECURRING-FINDINGS *and* the
session-end-emitter's missing landing spot *and* the "add a memory rule before session ends" prose.

- **Writer (ONE):** the **Stop-hook session-end emitter** (`.claude/hooks/session-end-capture.sh`,
  MOVE 1's writer, landing in this store). This is the absent automated WRITER. It fires on `Stop`,
  reads the turn's correction/finding signal, and appends a JSONL record. The `/cr` Step 3b logic
  (`.claude/skills/cr/SKILL.md:174`) is *redirected* to append here too, in the same JSONL schema,
  instead of editing RECURRING-FINDINGS.md. So one schema, one file, written by hook + by `/cr` — but
  **never by a human editing prose** (humans add via a thin `/note "<finding>"` wrapper that appends a
  line, never by hand-editing the file). One writer *path*, two callers.
  - Record schema: `{ts, sha, signature, kind: trap|decision|pattern|behavior, body, occurrences:1,
    source: stop|cr|note, status: open}`.
  - `session-end.sh` was removed in #70 because its `claude --print` output was *discarded*. This writer
    does not print — it **appends a structured line to S1**. The output lands in a store. That is the
    entire fix for the #70 failure mode.
- **Reader (ONE) + WHEN:** the **promotion sweep** (a CI check / scheduled skill, §3 lifecycle below)
  reads S1 to find entries that have recurred enough to promote. Implementers do **not** read S1
  directly — it is raw and noisy. This is deliberate: raw capture should not be in the always-loaded
  context. The implementer-facing read-path is the *promoted* knowledge in S2–S4, which IS loaded (§5
  closes the RECURRING-FINDINGS read-path by making capture flow *to* S2, which IS read).
- **Freshness rule (ONE):** **time-boxed eviction.** An entry with `status: open` and no new occurrence
  in **30 days** is auto-retired (`status: retired`, kept for audit but not counted). This is the
  anti-monotonic-growth rule: a finding that logged once and never recurred is noise and decays out.
  JSONL append-only means "eviction" = a compaction pass rewrites the file dropping `retired` lines
  older than 90 days. The file cannot grow without bound because the compaction has teeth.
- **Lifecycle-in-tooling:** see §3 — the promotion sweep and the compaction pass are the two mechanisms.

### S2 — `PITFALLS.md` + `.claude/rules/*.md` — CANONICAL-CONSTRAINTS

The corrected-mistake traps. PITFALLS.md stays as the *human-browsable index*; the *enforced, loaded*
content moves into `.claude/rules/*.md` with `paths:` globs (NEW — §7). This resolves the dual-layer
(L1/L3) assignment by making PITFALLS unambiguously **L1 Context** (it is loaded, path-scoped, before
you write) and removing its capture-stage job entirely (direct adds now go to S1, not here).

- **Writer (ONE):** the **promotion sweep** (§3). PITFALLS/rules are *write-only-by-promotion* — no
  direct hand-adds (the census's "added directly when a trap is identified outside the review loop" path
  is removed; those now enter S1 via `/note` and promote like everything else). One writer: the sweep.
- **Reader (ONE) + WHEN:** the model, **path-scoped at edit time**, via native `.claude/rules/*.md`
  `paths:` glob auto-load. Reading a 43 KB monolith wholesale is gone (§7). PITFALLS.md itself is read
  only by a human browsing, or by `/cr` as a constraint corpus (§5 wiring) — not auto-injected whole.
- **Freshness rule (ONE):** **fires-or-evicts.** Each rule carries `last_fired: YYYY-MM-DD`, stamped by
  the L1 deterministic hook or `/cr` pass that references it whenever it catches a violation. A rule not
  fired in **180 days** is surfaced by the decay detector (§9) as an eviction candidate. This replaces
  the unenforced 90-day `last_seen` sweep with a signal that is *actually generated by the enforcement
  path* — a rule earns its keep by catching something.
- **Lifecycle-in-tooling:** entries arrive via the promotion sweep (S1→S2); leave via the decay
  detector (§9) flagging unfired rules. Both are tooling, not prose.

### S3 — `docs/adr/` — CANONICAL-DECISIONS (unchanged store, newly wired)

The census names this **the cleanest store** and the convergence target. Keep it verbatim as a store;
the only change is wiring it into `/cr` as review criteria (its one gap).

- **Writer (ONE):** manual, at decision time, by the human/agent (the 3-test gate: hard-to-reverse,
  surprising-without-context, real-tradeoff). This stays manual *by design* — an ADR is a judgment
  artifact, not a captured signal. Promotion-from-capture does not apply (a decision is authored, not
  observed to recur).
- **Reader (ONE) + WHEN:** **`/cr`**, at review time, loading the ADR corpus as constraints (the
  MOVE-6 read-path), PLUS the model at design time (existing CLAUDE.md "skim adr/README before
  designing"). The new contract: `/cr` fails a diff that violates an `Accepted` ADR.
- **Freshness rule (ONE):** **supersession** (`Accepted | Superseded by NNNN | Deprecated`). No
  time-decay — a locked decision is timeless until explicitly superseded. This is correct and stays.
- **Lifecycle-in-tooling:** status transitions are manual edits; the *enforcement* (a violating diff is
  caught) is the new `/cr` ADR-constraint pass (§5). Eviction = supersession, human-authored.

### S4 — `docs/solutions/` — CANONICAL-PATTERNS (unchanged store, newly read)

Reusable positive patterns. Keep the store; fix the two real gaps (no read-path; unmet >10-entry tag
migration).

- **Writer (ONE):** `/compound` after a merged feature (existing). Stays manual — a positive pattern is
  a judgment that "this is reusable," not an observed recurrence.
- **Reader (ONE) + WHEN:** a **task-start retrieval step** — the `/feature` and `/dev` skills gain a
  step that greps `docs/solutions/` by the task's domain tags and surfaces matches before writing. This
  is the read-path that closes the half-open loop for patterns. (Implemented as a skill step, not a
  hook — pattern retrieval is judgment-shaped, not a deterministic gate.)
- **Freshness rule (ONE):** **referenced-or-archived.** Each solution doc carries a `referenced:` count
  bumped when the task-start retrieval surfaces it and the agent uses it. The decay detector (§9) flags
  docs with 0 references in 365 days as archive candidates. Positive patterns are durable but not
  immortal — an unused pattern is a maintenance surface. This gives solutions the eviction edge it lacks
  today (census: "freshness rule: NONE").
- **Lifecycle-in-tooling:** the >10-entry frontmatter-tag migration becomes a **CI lint** (§9) that
  fails if a solution doc lacks required `tags:` frontmatter — making the documented-but-unenforced rule
  enforced. Archive = decay detector flag → human confirm.

---

## 3. The lifecycle conveyor — promotion + eviction in tooling (the core of this candidate)

Two mechanisms move knowledge between stages. **Both are real tooling, neither is prose.**

### Mechanism A — the **promotion sweep** (`scripts/promote.sh`, run by CI on a schedule + on demand)

This is the conveyor from CAPTURE (S1) to CANONICAL-CONSTRAINTS (S2). It is the encoded replacement for
today's "human confirms before promotion" (clockless) and `/compound` Step 9 (optional, unrun).

```
for each open entry in journal.jsonl with kind=trap:
    if occurrences >= 3:                       # the recurrence threshold, now a clock-bearing rule
        emit a PITFALLS/.claude/rules promotion CANDIDATE block to stdout
        mark journal entry status=promotion-pending
```

- **Promotion is gated, not auto-applied to canonical** — CLAUDE.md forbids silent edits to knowledge
  docs, and a bad auto-promotion would pollute the always-loaded L1 context. So the sweep *emits a
  candidate* (paste-ready rule block) and flips the journal entry to `promotion-pending`. A human or the
  `/compound` skill applies it to S2. **But the clock is now in tooling:** an entry at occurrences≥3
  that sits `promotion-pending` for >14 days is surfaced by the decay detector as a stalled promotion —
  the judgment gate keeps its human, but loses its ability to silently never-fire.
- This runs as a CI job (`.github/workflows/`) on a weekly schedule (cron) AND is invocable as a skill
  step inside `/compound`. The scheduler substrate already exists (`CronCreate`, `/schedule` — anti-
  phantom §C); this is wiring, not a new primitive.

### Mechanism B — the **compaction + decay pass** (folded into the decay detector, §9)

This is the eviction conveyor. It (a) retires S1 entries with no occurrence in 30 days, (b) drops
`retired` JSONL lines older than 90 days (the anti-monotonic-growth teeth on the capture log), (c)
flags S2 rules unfired in 180 days, (d) flags S4 solutions unreferenced in 365 days. One pass, four
stores, all time-boxed. This is the mechanism today's model lacks entirely — "decay documented, not
executed" for every store.

**Net:** every entry in the system has a tool-driven path *out* — promote up, or decay out. No store
grows without an encoded exit. That is the cleanest-lifecycle property, achieved in tooling.

---

## 4. The auto-memory subsystem store (S6 today) — accounted for, not ignored

The canon ignores it; this model cannot delete it (the Claude Code memory subsystem writes it
autonomously and auto-loads the first 25 KB at session start — `capability-facts.md`). The move is to
**reclassify it from authoritative store to untrusted read-cache**, and to **stop feeding it the
duplicate facts**.

- **Reclassification:** auto-memory is treated as a *cache of point-in-time observations*, exactly as
  its own staleness banner says ("Verify against current code before asserting as fact"). It is NOT a
  store we promote from, write to, or treat as canonical. When auto-memory and S2/S3/S4 disagree, the
  curated store wins — always. This resolves the census's "stale-first authority" pathology: the
  freshest-loading store is explicitly demoted below the curated ones.
- **Stop feeding the duplicate:** the triple-duplication's third copy (the 32 `feedback_*` files) is
  fed because corrected-mistake facts currently live in memory.md/PITFALLS prose that the subsystem
  observes and re-encodes. Once corrected mistakes flow through **S1 (journal) → promotion → S2 (rules)**
  and are NOT also hand-written into a `memory.md` the subsystem watches, the subsystem has one canonical
  source to observe, not three. We can't stop it caching, but we can stop giving it three originals to
  cache. (Empirical caveat: the subsystem's exact observation triggers are not documented; this reduces
  but may not fully eliminate cache duplication. The model's correctness does not *depend* on the cache —
  it is read defensively and overridden by S2–S4, so residual duplication is inert, not load-bearing.)
- **Decay we don't own:** we cannot evict from auto-memory. The mitigation is the authority rule above —
  a stale auto-memory entry is *outranked*, so its staleness is bounded in *consequence* even though we
  can't bound it in *existence*. This is the honest limit: §9's decay doctrine cannot reach a store the
  harness doesn't write. We neutralize it by demotion, not eviction.

**Per the requirement: the auto-memory store is migrated to `auto (cache, untrusted)` — kept on disk,
demoted in authority, no longer fed duplicate originals.** It is the one store whose lifecycle we cannot
fully own; the model names that limit rather than pretending otherwise.

---

## 5. Resolving the PITFALLS.md / memory.md dual-layer (Context vs Memory) assignment

The dual-assignment exists because both files do **two stage-jobs at once**: they are CAPTURE (you add a
corrected mistake to them) *and* CANONICAL (you read them as locked constraints). A file that is both
input and output of the pipeline cannot have one layer.

Candidate B **splits the jobs across the stage boundary:**

- **The CAPTURE job leaves both files.** Corrected mistakes are no longer hand-written into memory.md or
  directly into PITFALLS. They enter **S1 (journal)** via the Stop-hook emitter or `/note`. memory.md as
  a capture store is **deleted** (§6 migration).
- **The CANONICAL-CONSTRAINTS job stays, and becomes unambiguously L1 Context.** PITFALLS + `.claude/
  rules/` are *read before you write*, path-scoped. They are Context (L1), full stop. They are no longer
  "Memory (L3)" because the memory/capture function moved to S1.

So the dual-layer collapses by construction: **PITFALLS/rules = L1 Context (read-before-write);
the captured-memory function = S1 (a log, not a layer the model loads).** No file is in two layers
because no file does two stage-jobs. This is the resolution the census asks for, derived from the
lifecycle frame rather than asserted.

**Wiring that closes the RECURRING-FINDINGS read-path (the half-open loop):** today RECURRING-FINDINGS
is written by `/cr` and read by no implementer. In this model, capture (S1) flows by promotion into S2,
and **S2 IS read at edit time via `.claude/rules/` path-globs**. So a finding that recurs ≥3× becomes a
rule that auto-loads exactly when an implementer edits a matching file — the loop is closed *because the
read-path is the native path-glob mechanism*, not a new bespoke reader. Additionally, ADR (S3) and
solutions (S4) gain explicit readers: ADR → `/cr` constraint pass; solutions → `/feature`+`/dev`
task-start retrieval. All four stores now have a real reader at the moment the knowledge is actionable.

---

## 6. Per-store migration (all 6 of today's stores → target)

| Today's store | Action | Target | How (tooling) |
|---|---|---|---|
| **1. `.claude/memory.md`** | **MERGE + DELETE** | S1 (journal) for the capture function; safety-floor → S2 | Safety-floor content (PocketOS destructive-op trio — KEEP-VERBATIM) migrates to a tier-1 always-loaded `.claude/rules/00-safety.md` (no `paths:` glob → always loads, never decays). The behavior-rule entries (`honest-assessment`, `build-what-is-needed`, `research-before-guessing`) are **deleted as duplicates** — they live verbatim in CLAUDE.md → Agent behavior principles already (census Store 1 pathology 1). The capture function (add-a-rule-at-session-end) is replaced by S1. **memory.md the file is deleted** once content is relocated. |
| **2. `docs/RECURRING-FINDINGS.md`** | **MERGE + DELETE** | S1 (journal) | Its schema (signature, occurrences, last-seen, status, promotion path) IS the S1 journal schema — S1 is RECURRING-FINDINGS reborn as JSONL with an automated writer (Stop hook + `/cr` 3b redirected) AND a working read-path (promotion → S2 → path-glob load). The `.md` file is deleted; `/cr` Step 3b is rewired to append JSONL to S1. |
| **3. `PITFALLS.md`** | **KEEP (split) + RE-TIER** | S2 | Content stays. Capture function (direct adds) removed → all entries arrive by promotion. Read function moves to path-scoped `.claude/rules/*.md` (§7); PITFALLS.md becomes the human-browsable index + source-of-truth that rules are generated from. Resolves dual-layer (→ L1 only). |
| **4. `docs/solutions/`** | **KEEP** | S4 | Add task-start retrieval reader (`/feature`, `/dev`); add `referenced:` decay; enforce the >10-entry tag-frontmatter rule as CI lint. Store unchanged; lifecycle gains an exit edge. |
| **5. `docs/adr/`** | **KEEP** | S3 | Wire into `/cr` as a constraint corpus (its one gap). Store and lifecycle otherwise unchanged — it is the convergence template. |
| **6. Auto-memory subsystem** | **AUTO (demote to cache)** | not in target set | Cannot delete; reclassified to untrusted read-cache, outranked by S2–S4, no longer fed duplicate originals (§4). Lifecycle not owned — named as the explicit limit. |

Triple-duplication collapse (memory.md + PITFALLS + feedback_*) **in tooling, not prose:** rows 1 and 2
delete two of the three originals (memory.md behavior-rules → deleted as CLAUDE.md dups; RECURRING-
FINDINGS → folded into S1); corrected mistakes now have a **single canonical path** (S1 → promote → S2),
so the subsystem (row 6) observes one source instead of three. The collapse is enforced by *there being
only one place to write a corrected mistake* (S1), not by a prose note saying "don't duplicate." That is
the structural difference from the canon's prose-only reconciliation.

---

## 7. Path-scoped tiering via native `.claude/rules/` + `paths:` globs (NET-NEW — absent today)

`.claude/rules/` is ABSENT (re-verified). This is a net-new build, not a relocation. Native mechanism
(`capability-facts.md`): a `.claude/rules/*.md` file with `paths:` glob frontmatter auto-loads **only
when the session is working on a matching file**.

Proposed `.claude/rules/` layout (generated from PITFALLS.md by the promotion sweep, NOT hand-authored):

```
.claude/rules/
  00-safety.md              # paths: (none → always loads) — PocketOS destructive-op trio, KEEP-VERBATIM
  10-supabase.md            # paths: ["**/migrations/**","src/data/**","**/*.sql"]
  20-components.md          # paths: ["src/components/**","app/**/*.tsx"]
  30-schemas.md             # paths: ["src/schemas/**","src/data/**"]
  40-hooks-harness.md       # paths: [".claude/hooks/**","scripts/**",".claude/settings*.json"]
  50-migrations-grants.md   # paths: ["**/migrations/**"]
```

- This is the fix for "43 KB read wholesale every code task." Editing a migration loads `10-supabase` +
  `50-migrations-grants` + always-on `00-safety` — a few KB of *relevant* traps, not 558 lines.
- **Tier-by-trigger-existence, not line-count** (doctrine, EMERGING-FINDINGS §3): `00-safety.md` has NO
  `paths:` trigger, so it is tier-1 always-loaded *regardless of length* — safety content is never
  decayed or path-gated. Everything else is tier-2, loaded only on a matching trigger.
- The rules files are **generated artifacts** — PITFALLS.md remains the source, the promotion sweep
  emits/updates the `.claude/rules/*.md` partition. This avoids hand-maintaining two copies (which would
  re-introduce duplication). One source (PITFALLS index), one generated load-surface (rules).

---

## 8. The absent automated WRITER (MOVE 1 session-end emitter)

Named and landed: **`.claude/hooks/session-end-capture.sh`**, a `Stop`-hook that appends a structured
JSONL line to **S1 (`.claude/journal.jsonl`)**.

- **Why this fixes #70:** `session-end.sh` was removed because its `claude --print` output was
  *discarded* — it printed into the void. This emitter does not print; it **appends to a store the
  promotion sweep reads**. The output has a home (S1), a reader (the sweep), and a downstream effect
  (promotion → S2 → loaded at edit time). The #70 failure mode — "writer whose output goes nowhere" — is
  structurally prevented because the writer's only job is to land a line in S1.
- **What it captures:** the turn's corrected-mistake / recurring-finding signal, as a `kind:trap|
  behavior` record. It does NOT try to judge promotion (that's the sweep's clock-gated job) — it just
  captures, occurrences=1. Cheap, deterministic, non-blocking (a Stop hook that fails must not block the
  turn from ending — it appends best-effort).
- **Capability caveat (`capability-facts.md`):** a Stop hook CAN run shell and append a file; the hedge
  was about *force-continue* semantics, which this emitter does not use (it never blocks). So this is
  inside confirmed capability. Verify empirically that the Stop hook has access to the turn's correction
  signal; if not, the `/note` manual-append wrapper + `/cr` 3b auto-append are the guaranteed writers and
  the Stop emitter is best-effort enrichment.

---

## 9. The drift/decay detector — STALE + FICTION + DECAY (the one detector, three jobs)

A single CI check + skill — **`scripts/scan-context.sh`** (the documented-but-absent `/scan-context`),
run weekly by cron and on demand. It is the eviction half of the lifecycle and the doc-integrity guard.
It catches all three failure classes the requirement names:

1. **DOC-STALE** — knowledge that is old/unfired:
   - S1 entries `open` with no occurrence in 30 days → auto-retire.
   - S2 rules `last_fired` > 180 days → eviction candidate (surfaced, human confirms).
   - S4 solutions `referenced` = 0 in 365 days → archive candidate.
   - S1 `promotion-pending` > 14 days → stalled-promotion flag (the judgment gate kept its human but
     can no longer silently never-fire).
2. **DOC-FICTION (phantom refs)** — our *live* failure class (the audit itself rotted): the detector
   greps every knowledge doc (CLAUDE.md, AGENTS.md, PITFALLS/rules, ADRs, solutions, mcp.md, INDEX.md)
   for references to files/skills/hooks/scripts and asserts each referent **exists on disk**. A reference
   to `session-end.sh`, `cr-feature`, `learned-patterns.md`, an empty `dep-update/` skill, or a removed
   ADR is a CI failure. This is what would have caught the canon↔disk drift that motivated this whole
   audit. Also flags the AGENTS.md "Open Decisions: None open" contradiction class (a doc asserting a
   state the rest of the doc contradicts) where mechanically detectable.
3. **DECAY** — the compaction teeth from §3 Mechanism B: rewrite `journal.jsonl` dropping `retired`
   lines older than 90 days, so the one append-only store cannot grow monotonically.

The detector **surfaces** (CI annotation + paste-ready) rather than auto-editing knowledge docs (CLAUDE.md
forbids silent deletion). But the *clock* is in tooling — a stale rule, a phantom ref, or a bloated
journal can no longer hide. This is the "no monotonic-growth store, all decay executed" property, made
real. It also subsumes the unmet >10-entry solutions tag-migration: `scan-context` fails CI if a
solution doc is missing required `tags:` frontmatter, enforcing the documented rule the census flagged as
overhead.

---

## 10. What I DELETE, and the §9 failure-mode each deletion does/doesn't leave unprevented

| Deleted | §9 failure-mode it prevented | Verdict |
|---|---|---|
| **`.claude/memory.md` (the file)** | "Corrected mistakes are forgotten across sessions." | **Re-homed, not lost.** Safety-floor → `.claude/rules/00-safety.md` (always-loaded, KEEP-VERBATIM preserved); capture function → S1 (with an *automated* writer it never had). The failure mode is better-prevented after deletion than before (it had no automated writer; S1 does). |
| **memory.md behavior-rule entries** (`honest-assessment`, `build-what-is-needed`, `research-before-guessing`) | None — these are **verbatim duplicates** of CLAUDE.md → Agent behavior principles (census Store 1 pathology 1). | **OVERHEAD.** Deleting the duplicate prevents no failure mode CLAUDE.md doesn't already cover. The duplication itself was the cost. |
| **`docs/RECURRING-FINDINGS.md` (the file)** | "A pipeline finding is lost / never promoted." | **Re-homed to S1**, which keeps the schema, gains the Stop-hook writer, and — critically — gains a read-path (promotion → S2 → path-glob load) the `.md` never had. The half-open loop was the failure mode; deleting the dead-end file and routing to S1 is what closes it. |
| **PITFALLS.md's direct-add capture path** | "A trap found outside the review loop has nowhere to go." | **Re-homed to S1 via `/note`.** The trap still gets captured; it just enters the pipeline at CAPTURE and promotes like everything else, instead of being hand-injected into the always-loaded canonical store unvetted. No failure mode unprevented. |
| **(do NOT delete) `docs/solutions/`, `docs/adr/`** | Pattern reuse / decision-violation prevention. | **KEEP** — both name real, current failure modes (re-solving solved problems; silently violating a locked decision). Not overhead. |

I delete **two files** (memory.md, RECURRING-FINDINGS.md) and **one prose path** (PITFALLS direct-add),
collapsing three capture stores into one (S1). No safety content is deleted — it is re-homed to a
tier-1 always-loaded rule. The auto-memory store is not deleted (cannot be) but demoted. Net store count
**6 → 4** (plus the untrusted cache we don't own).

---

## 11. Honest limits of this candidate

- **The Stop-hook capture signal is unverified.** Whether a `Stop` hook can actually see the turn's
  "corrected mistake" content is an empirical check (capability-facts hedged on Stop semantics). If it
  can't, the automated-writer half degrades to `/cr` 3b auto-append + `/note` manual — still better than
  today (RECURRING-FINDINGS already auto-writes from `/cr`), but the "session-end emitter" loses its
  fully-automatic property. This is the load-bearing risk in the whole model.
- **Auto-memory duplication is reduced, not provably eliminated.** We control the originals we write; we
  do not control what the subsystem chooses to observe. The model is correct regardless (cache is
  outranked), but the "collapse the third copy" claim is bounded by not owning the subsystem.
- **Promotion stays human-gated.** Encoding the *clock* (occurrences≥3, 14-day stall flag) is in
  tooling; the *apply-to-canonical* step keeps a human because CLAUDE.md forbids silent edits to
  always-loaded knowledge and a bad auto-promotion pollutes L1 context. This is a deliberate seam, not a
  gap — but it means "promotion encoded in tooling" is *clock-in-tooling, application-gated*, which is
  weaker than fully-automatic. I judge that correct (the §9 keep-verbatim and no-silent-edit floors
  outrank full automation here), but it is a real boundary.
- **`.claude/rules/` generation adds a build.** The path-glob partition must be generated from PITFALLS
  and kept in sync by the promotion sweep — net-new machinery. Justified because it replaces a 43 KB
  wholesale read with KB-scale scoped reads, but it is *more mechanism* in service of *less loaded
  context* — the trade must be worth it (it is: token cost at every code task vs. one generator).
