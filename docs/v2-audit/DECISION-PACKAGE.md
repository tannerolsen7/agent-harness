# V2 Harness — DECISION PACKAGE

**For:** Tanner. **Status:** research + design complete (Phases 0–6); no harness code changed. **Your job:**
read this, answer the 5 decisions in §2, then a future session executes the first migration slice (§7).

Every claim cites a current-state component (`[map §N]` = `CANONICAL-HARNESS-AS-IS.md`; a disk path) or a
confirmed absence re-verified on disk. The deep artifacts are linked, not dumped (§9). The method throughout:
fan out subagents, **doer ≠ checker** (every design was attacked by a separate adversarial agent), depth over
speed. The checkers earned their keep — they caught two design artifacts hiding a file-count increase, a
phantom rule, a false "verbatim" deletion claim, and an accounting error in my own synthesis.

---

## 1. The thesis, in one paragraph

The harness is **mechanism-rich and wiring-poor.** Its failures are not missing features — they are
*temporal and authority* failures: a missing clock (rituals fire only if the model remembers), a forgeable
gate (`.cr-ok` is written by the model it's supposed to gate), a rotting audit (this very audit was caught
stale mid-run), a half-open loop (findings are written but never read back), and a single-project artifact
the canon calls "global." V2 is therefore **not more features — it is wiring, convergence, enforcement-
relocation, and deletion.** The shape of success is *fewer files the agent reads, more deterministic
enforcement it can't forge, and one canonical home per fact* — delivered as something installable beyond
event-vendor. Six consolidating MOVES carry ~30 cited gaps; the design collapses them onto a single memory
model, a three-layer enforcement model, one compounding loop, and a plugin.

**The honest headline number (corrected after adversarial review):** V2 ends with **roughly flat total
tracked files**, but the two budgets move oppositely — see §3. That is the consolidation, and it only reads
as a win if you count the two budgets separately (D5).

---

## 2. THE DECISION BRIEF — 5 forks (recommendation first)

These are the only genuine forks (collapsed from ~26 scattered open items; the rest had an obvious
recommendation and are resolved in the artifacts). Each: recommendation → why → tradeoff → citation.

### D1 — ADR disposition *(the biggest design fork)*
**Recommend:** project the 5 ADRs into the constraint store S1 as `kind: decision` entries (decay-exempt,
supersession-tracked, delivered by `paths:`) **AND retain `docs/adr/` as the long-form authoring home.**
**Why:** keeps the physical store count at 3 while preserving the ADR document shape (Context/Decision/
Alternatives/Consequences) and its supersession lifecycle; wires decisions into path-load + `/cr`.
**Tradeoff:** costs a small "two homes, one fact" (mitigated — the S1 entry is a generated projection,
drift-checked). The alternatives: *delete `docs/adr/`, flatten to one-line S1 entries* (strictly minimal,
loses the long-form) or *keep ADR as a distinct 4th owned store* (coherence-pure, re-grows the count).
**Cite:** memory-model §1/§4; file-tree §4.

### D2 — Ratify revising the canon's LOCKED single-vehicle distribution decision?
**Recommend:** YES — ship a **two-vehicle split**: a Claude Code **plugin + marketplace** for the portable
mechanism (skills, agents, hooks, the safety floor), a **thin template/`/init`** for project-owned files
(CLAUDE.md, AGENTS.md, permissions, autoMode, area rules). **Why:** a material fact changed since the
2026-05-18 lock — plugin-marketplace maturity. A plugin makes `/plugin update` (the pull path) native, and
wires hooks via `hooks.json` *without editing the downstream guard file* (the one install step that today
requires a human to touch the most dangerous file). The locked *sequence* (converge → ship → 3 installs →
Cursor → npx → UI) is honored intact; the revision *reduces* downstream tooling (the template plan deferred
`harness-update.sh`; the plugin deletes that future work). **Tradeoff:** it overrides a *locked* decision —
but the seam is **forced**, not chosen: a plugin's settings.json physically cannot carry permissions/autoMode
(verified — the live vercel 0.43.0 plugin ships a 27-byte settings.json with zero permissions). So any
vehicle must hand permissions to the project anyway. **Cite:** distribution §1; capability-facts; canon-locked §A.

### D3 — Is the autonomous trigger front-door in V2 scope?
**Recommend:** NO — keep it hypothesis-gated. **Why:** MOVES 1–6 build exactly the substrate autonomy needs
(write-back, a measured gate, the bash guard, the heartbeat). Deciding autonomy *after* the substrate exists
avoids the forbidden speculative build (building a bug→PR classifier before the harness can even be
summoned). **Tradeoff:** V2 still can't be "summoned" (`/goal`, scheduler, bug→PR) — if you *want* autonomy
as a V2 goal, that cluster comes into scope and enlarges the build set. **Cite:** MASTER-FINDINGS §C, §H.2.

### D4 — MOVE-1 write-back: full-auto, or degrade-safe? *(the load-bearing risk)*
**Recommend:** ship the **degrade-safe** version now (`/cr` Step 3b auto-writes + a manual append), AND run a
one-session capability probe before committing to full Stop-hook auto-capture. **Why:** the Stop hook
receives `transcript_path` (a *path*, not the conversation) — to know "a mistake was corrected this turn" it
must parse the transcript and run a *semantic* heuristic. A regex scan is forgeable and low-precision; if
detection genuinely needs an LLM, the "deterministic out-of-band writer" claim collapses to "deterministic
trigger + probabilistic detection." **Tradeoff:** degrade-safe is strictly better than today's prose-only
write-back and carries zero risk; full-auto is nicer but hangs on an unverified capability. This is **the
single load-bearing open risk in the whole design** — but its worst case is bounded by the degrade path.
**Cite:** capability lens MF-1; compounding-loop §1.

### D5 — Ratify the corrected two-budget accounting as the meaning of "fewer files"?
**Recommend:** YES. Accept that V2 ends with **~flat total tracked files**: budget (1) — the forgeable
advisory prose the agent *reads* every session (the thing that hurt V1) — falls hard; budget (2) — out-of-band
§9-gated enforcement the agent never reads — grows. **Why it's a real decision:** the binding principle says
"more files = RED FLAG," and a literal reading would *reject* this design. The reframe (count two budgets,
minimize the one that hurt V1) is what resolves it — and an adversarial lens proved I had *misbooked* the
rule-shards into the wrong budget in my first synthesis, so this is not a rubber stamp. **Tradeoff:** hold a
hard total-file-reduction line instead and you must leave more rules advisory (forgeable). **Cite:**
RECONCILIATION-phase3 §A (corrected); budget-simplicity lens.

---

## 3. The two-budget ledger (the corrected numbers — read this before §4)

"Fewer files" splits into two budgets that move in opposite directions. Counting them as one (a raw
`find | wc -l`) is what let V1 accumulate forgeable scaffold and call it progress.

| Budget | What it is | V2 direction |
|---|---|---|
| **(1) Agent-context / advisory prose** | Files the agent *reads* every session — forgeable, attention-costing (CLAUDE.md, memory.md, the PITFALLS monolith, **and the `.claude/rules/` shards, which are read-prose**) | **DOWN, hard** |
| **(2) Out-of-band deterministic enforcement** | Hooks, CI scripts, lint/dep-cruiser configs, manifests, packaging — run *outside* the agent's context, **un**forgeable | **UP, only where each item names a §9 failure mode** |

- **Budget (1) falls** because: `PITFALLS.md` (574 lines, today read *wholesale* and passed to 4 `/cr` lens
  agents in parallel ≈ **172 KB per review**) and `memory.md` (166 lines) are deleted; their content becomes
  ~6 path-scoped `.claude/rules/` shards that load **1–2 per task on their path**, not all 574 lines on every
  code task; copies-of-each-fact drop **3 → 1** (the same corrected-mistake fact stops living in memory.md +
  PITFALLS + auto-memory at once). *Correction the budget-simplicity lens forced:* the win is **path-scoping
  (load less often)**, not "moving bytes into unforgeable enforcement" — the shards are still forgeable prose,
  they just load when relevant.
- **Budget (2) grows ≈ +13–17** (down from +16–20 after two free merges), every item §9-justified
  (names a failure mode), zero phantoms, zero rejected-pattern rebuilds.
- **Total tracked files: ~flat to modestly up.** Permitted *iff* budget (1) falls (it does) and every
  budget-(2) item is §9-gated (it is). That is decision **D5**.

---

## 4. THE V2 DESIGN (teachable depth)

### 4a. The single memory model — 6 stores → 3 owned + 1 ridden cache
*(detail: [memory-model.md](design/phase3/memory-model.md), corrections in [RECONCILIATION §B](design/phase3/RECONCILIATION.md))*

Today there are **six** memory stores, but they hold **three kinds of knowledge** smeared across six files,
two of which the harness doesn't even own. The fix is to make the **entry** the unit, not the **file**:

| Store | Kind | Lives at | One writer / one reader / one freshness |
|---|---|---|---|
| **S1 — `.claude/rules/*.md` + CLAUDE.md floor** | durable constraints (traps + decisions), path-tiered | `.claude/rules/` (NEW) + CLAUDE.md | writer: `/cr` + `/compound` (through the promotion gate); reader: native `paths:` lazy-load + always-loaded safety floor; freshness: fires-or-evicts (180 d), safety + decisions exempt |
| **S2 — `docs/solutions/`** | reusable patterns | unchanged | writer: `/compound` after merge; reader: `/dev`+`/feature` at task-start; freshness: supersession |
| **S3 — `docs/RECURRING-FINDINGS.md`** | captured-signal *inbox* (the airlock) | unchanged | writer: `/cr` 3b + the MOVE-1 Stop emitter; reader: task-start glob; freshness: 30-day decay + promotion clock |
| *(cache)* **auto-memory** | subsystem capture — **ridden, not owned** | `~/.claude/.../memory/` | written by the CC subsystem; read free at session start; **outranked by S1–S3 on conflict** |

Three ideas make this work, and they're worth understanding because they're the load-bearing moves:

1. **Entry-as-atom dissolves the dual-layer ambiguity.** Today PITFALLS.md and memory.md are each assigned
   to *both* "Context" and "Memory" layers depending on which canon page you read — because the *file* was
   the unit. Make each *entry* carry `tier:` (when it loads — always, or by path) and `kind:` (how it decays
   — a trap fires-or-evicts; a decision supersedes), and "Context vs Memory" stops being two layers a file
   lives in and becomes two properties of one entry. The ambiguity disappears *in the data model, not in
   prose.*
2. **The airlock (S3) has a promotion gate.** A finding observed *once* sits in the S3 inbox at
   occurrences=1. Only after it recurs (≥3) and a human confirms does it promote to S1 (the always-loaded
   constraint set). This is the one guard against an un-vetted single observation auto-promoting to a rule
   and ossifying — the "forgeable/stale gate" failure. **An automated writer drops into the airlock, never
   straight into S1.**
3. **Ride the platform, don't hand-roll.** Auto-memory is the free automated capture writer the curated
   stores lack — so `memory.md` is deleted and auto-memory *is* the raw-capture inbox (demoted to an
   untrusted cache: it auto-loads stale facts first, so on any conflict the curated stores win). And
   `.claude/rules/` + `paths:` globs is the platform's **native** path-scoped lazy-load (confirmed in the
   official memory docs) — not a custom loader. We invent nothing the platform already does.

Every store gets a **tool-driven exit** (promote up or decay out), so no store grows monotonically — the
property all six stores lack today (decay is documented for 3, executed for none). One CI check
(`scan-context.sh`, finally building the long-referenced-but-absent `/scan-context`) runs the decay clocks
AND catches *doc-fiction* (phantom references — the live failure class that rotted this very audit) AND
*doc-staleness*, in the lane that already exists.

### 4b. Enforcement — the Three-Layer model + the §9 deletion engine
*(detail: [enforcement-sort.md](design/phase3/enforcement-sort.md), corrections in [RECONCILIATION §C](design/phase3/RECONCILIATION.md))*

Today **~86% of the 118 binding rules are advisory prose with no mechanism** — the model can simply ignore
them. The sort relocates every rule to the layer that can actually hold it:

- **L1 — deterministic hook** (PreToolUse exit-2 / git hook / ESLint-error): fires on agents *and* humans.
- **L2 — architecture test** (`dependency-cruiser` in CI): "components may not import the data layer," etc.,
  checked every CI run for every developer.
- **L3 — judgment**: stays prose because it genuinely needs a model's reading of intent.

The discipline is the **§9 deletion criterion**: *"name a failure mode the constraint prevents, or it's
overhead."* Every L1/L2 assignment carries a one-line failure mode; a rule with none is demoted or deleted.
Result: **~64 of 118 rules (54%) relocate to a deterministic layer**, collapsing onto **7 build items** (the
absent `block-dangerous-bash.sh` 3rd guard; the `.cr-ok`→CI relocation; the `/cr-security` path classifier;
`dependency-cruiser` L2; one `migration-lint` CI script absorbing 8 safety-critical rules; one
`repo-structure` script; the autoMode placement fix). The **keep-verbatim safety floor** (PocketOS
destructive-op rules, tracer-bullet-first, the 3 pre-commit questions) stays — those are kept regardless of
length because they have *no trigger* (they apply to every operation).

The single most important relocation: **`.cr-ok`'s stop authority moves to CI.** Today `.cr-ok` is written
by the model and is gitignored, so it never reaches CI — the gate that says "review passed" is forged by the
thing being gated. The fix: make the *existing* CI lane (`tsc`/`eslint`/`test`) the required gate on the
sentinel SHA via branch protection (mechanizable, unforgeable); the judgment passes (the 9 + 4 lenses) stay
*coverage-bounded trust* — and §4d's measurement is what supplies the bound.

### 4c. Composition — how the 6 MOVES form ONE loop

The pieces are not six features; they are one self-improving loop with the enforcement and memory models as
its rails:

```
  a RUN  →  WRITE-BACK (Stop emitter → S3 airlock)  →  PROMOTE (≥3 + human → S1)
                                                              │
   next RUN  ←  READ-PATH (S3 task-start glob + S1 paths: auto-load)  ←──┘
        └────────────────── MEASUREMENT (does /cr catch what the loop records?) ──────────────────┘
```

A run surfaces a finding → it lands in the S3 airlock (write-back) → if it recurs and a human confirms, it
promotes to S1 → the next run *reads* it at task-start before repeating the mistake (read-path) → and
**measurement** asks the question that makes the whole thing trustworthy: does `/cr` actually catch the
defects the loop records? Without that number you can't tell a compounding loop from a rotting one. The
enforcement model (4b) is the loop's *rails* (it relocates the constraints the loop promotes into
unforgeable layers); the L2 architecture-test failure-rate over time is a *compounding metric* — falling =
the relocated constraints are landing; flat-zero = a rule never fires and becomes a §9 deletion candidate
(the loop feeding the deletion engine).

### 4d. The compounding loop's new leg — measurement
*(detail: [compounding-loop.md](design/phase45/compounding-loop.md))*

`/cr` is the most load-bearing, **least-tested** component (9 passes + 4 adversarial lenses; the whole push
gate hangs on it) — and its recall is **unmeasured**; no golden set exists anywhere; `@benchmark-runner` is
a phantom. The genuinely-new work is a **recall harness** that measures whether `/cr` catches real defects:

- A **golden set** = a fixed collection of diffs whose defects are *already human-confirmed*, so `/cr`'s
  output can be scored against the known answer, not against the model's own opinion. Seed it with
  **adversarial / known-defective** diffs (historical MUST-FIX findings, escaped bugs from `fix:` history,
  ~6–10 hand-authored cases each built to defeat one pass) — *not* friendly ones (every verifier today is
  calibrated against a friendly single-vendor audience).
- It lives as a **CI fixture corpus** (`.claude/eval/cr-golden/`), **not** a 4th memory store — the agent
  never reads it during normal work (so budget (1) = 0).
- **Never self-certify:** the label is external and human-confirmed; the *scorer* is a deterministic
  script (tag-match), not an LLM grading the review. This is what bounds the `.cr-ok`→CI trust claim: recall
  on the golden set is the *number you put on* how far to trust the judgment passes.
- It gets its **own** writer/reader/freshness (or it becomes the next stale gate): coverage decay (a new
  defect class with no case → gap) + distribution decay (cases scored against a retired model → re-confirm).

**Build the minimal harness now** (it's the precondition for the Opus-4.8 §9 re-audit — without it, the
re-audit is opinion, not measurement); defer the scheduled lane and auto-feeder behind a baseline number.

### 4e. Distribution + self-update — the two-vehicle split
*(detail: [distribution.md](design/phase45/distribution.md))*

The harness has **never been installed beyond event-vendor**; there's no global `~/.claude/CLAUDE.md`;
recyclops has none. "Multi-project" is aspirational — closing that gap is the V2 thesis. The split (D2):

- **Plugin + marketplace** ships the portable mechanism (23 agents, ~23 skills, all hooks, the universal
  `00-safety.md` floor, portable scripts) — version-pinned, `/plugin update` as the native **pull** path,
  hooks wired via the plugin's `hooks.json` *without touching the project guard file*.
- **Thin template / `/init`** scaffolds the project-owned files the plugin *cannot* carry — CLAUDE.md,
  AGENTS.md, permissions, autoMode, the project's own area-rule shards — with `[TODO]` placeholders.
- **The seam is forced:** a plugin's settings.json carries only `agent`+`subagentStatusLine` (verified —
  the live vercel plugin ships 27 bytes, zero permissions). So permissions are *always* project-authored,
  whatever the vehicle. S1's safety floor ships as content; S1-area/S2/S3 ship as **empty scaffolds** (schema
  + writer + clock) so a fresh install never inherits another project's traps.
- **Pull** = `/plugin install agent-harness@1.2.0` (a validated SHA, **not** symlink-live — a symlink
  resolves to HEAD and re-creates the drift it's meant to prevent). **Push-back-up** (a project's *universal*
  learned pattern flows back to the shared harness) is the loop's outer ring: designed now as one field
  (`scope: project|universal` on the promotion gate) + a human-gated PR; the automation is built later (per
  hypothesis-before-speculative-build — there's nothing to push *to* until a second project exists).
- **Convergence first** — but only as the *publish* gate. You can't version-distribute a harness whose canon
  and disk disagree (the canon claims 46 skills; disk has 26; `cr-feature` is retired-but-still-referenced).
  A 9-row one-time checklist + a generated `harness-manifest.json` (checked by `scan-context`) is the gate.
  **Crucially, convergence blocks only plugin extraction — not the safety/enforcement/measurement work**,
  which runs in parallel (a sequencing-lens correction).

### 4f. Migration path — the build order (with the hazards the lenses caught)

The phases each got their internal order right, but **no single artifact owned the cross-phase graph**, so
the sequencing lens found ordering hazards that only exist *between* phases. The build order, corrected:

**First slice (proves every load-bearing mechanism once, serializes nothing behind convergence):**
1. **`block-dangerous-bash.sh`** — the most-cited single gap, zero dependencies, pure safety win. Ship it
   alone first; it de-risks every unattended run.
2. **`.claude/rules/` scaffold + `00-safety.md` + ONE area shard (`migrations.md`) + the generator** — prove
   the native `paths:` mechanism end-to-end on the densest area before sharding everything.
3. **The "PITFALLS retirement" unit for that one area** *(MUST-FIX ordering, hazard M3)*: build rules →
   **retarget `/cr` Step 3b's write** from `PITFALLS.md` to the shard → **update `reviewer.md`** to load the
   shard not the 43 KB monolith (this *is* the token win) → **only then** flag `PITFALLS.md` for deletion.
   Delete-before-retarget would silently break the review gate (Step 3b writes a dead path; `reviewer.md`
   hands 4 lens agents a missing file).
4. **The minimal golden set (~6–10 adversarial cases) + deterministic scorer + `/cr-eval`, run once vs Opus
   4.8** — the baseline recall number that bounds the `.cr-ok` trust claim and makes the §9 re-audit
   data-driven.

**Named human handoffs (the agent may not edit guard files):**
- Add `session-end-capture.sh` as a **second** Stop hook *(MUST-FIX, hazard M2)* — a Stop hook is already
  wired (a sound at `settings.json:191`); the new emitter must be additive, `exit 0`-only, append-only. This
  is a paste-ready guard-file edit now; the plugin's `hooks.json` replaces it at extraction.
- Move the **autoMode** block from committed `settings.json` (where the classifier ignores it by design) to
  `settings.local.json` / `managed-settings.json`.

**Then:** shard the remaining areas → converge canon↔disk → extract the `agent-harness` repo (strip all
Monica/Fern's content) → ship the plugin → validate on 3 real installs (recyclops, recyclops/logistics-
service, + one external) → only then Cursor/npx/UI.

**Parallelizable (not blocked by convergence):** the whole enforcement spine (dep-cruiser report-mode,
migration-lint, repo-structure, `.cr-ok`→CI, `/cr-security` classifier) + the measurement baseline.

---

## 5. REJECTED — with reasons *(the full list: [MASTER-FINDINGS §F](design/MASTER-FINDINGS.md))*

These were proposed (often by multiple sources) and **rejected** — included so the decisions aren't
re-litigated later:

- **`learned-patterns.md`** (a monotonic "learned patterns" file, proposed ×3) — confirmed phantom; the gap
  is a *read-path*, not a file. A monotonic store with no eviction collides with the §9 decay rule.
- **Front-load trigger-words into skill descriptions / shrink CLAUDE.md to 200 lines** — the §9
  anti-pattern; the principle is *situational triggers* + *tier-by-trigger-existence*, not a line-count fetish
  or keyword-stuffing.
- **Import the ROI/recall rates** (80% self-written, 91%, 16.6%, etc.) — single-source/self-disowned; adopt
  *mechanisms*, never *rates*. Measure recall locally instead.
- **Dev-container / VM / microVM / token-proxy stack** — wrong threat model at solo scale; container-escape
  caused none of the documented incidents. The residue: "allowlist operations not destinations, enforce off
  the model."
- **Symlink-live install** — resolves to HEAD not a validated SHA; use versioned-copy-with-lock (the plugin).
- **Collapse the 23 agents into skills** — a threshold claim (real at *hundreds*) sold as universal; at ~23,
  specialists are clarity. Tested on disk: the 4 lenses are spawned by `reviewer.md`, the 6 spike agents by
  the orchestrator — all wired. Only the empty `dep-update/` stub is cut.
- **"No shared context" for the adversarial reviewer** — would blind it to the project's Rejected Patterns
  and ADRs; correct design = shared project canon, isolated solution context.
- **A new `/note` or `/distill` skill** — the existing `/compound` and a manual append already do the work;
  "rename the work, not the skill."
- **Playwright MCP / `/cr-feature` (retired) / `/change` (phantom) / auto-merge-on-confidence / a
  `@benchmark-runner` agent** — each rejected with reason in the cluster files.

---

## 6. The honest open risks (don't let these get buried)

1. **D4 — the Stop-hook detection capability** is unverified and may not be deterministic. Worst case is
   bounded (degrade to `/cr` 3b + manual append), but it gates the *full-auto* write-back.
2. **`disable-model-invocation` "removes from context"** (the lever that makes `/cr-eval` cost budget (1) =
   0) is documented but uncorroborated on disk — verify on the target CC version; else `/cr-eval` is +1 line.
3. **The audit artifacts rot.** Three RECONCILIATION files (`phase3`, `phase45`, this package) are
   authoritative over the drafts; any absence-claim must be re-verified on disk before it's acted on. This is
   not a footnote — it is the failure class that motivated the whole effort, and it recurred *during* it.

---

## 7. What you do next

1. Answer **D1–D5** (§2). Only D1 (ADR shape) and D2 (ratify the locked-decision revision) materially change
   the design; D3–D5 mostly ratify recommendations.
2. A future session executes the **first slice** (§4f) — it touches all three phases, proves every mechanism
   once, and needs only two paste-ready human guard-file edits from you.
3. The `/cr` recall baseline run (§4d) doubles as the **Opus-4.8 §9 re-audit's** missing measurement — run
   it early; it turns the deletion engine from opinion into data.

---

## 8. Proof of process (linked, not dumped)

- **Ground truth:** [CANONICAL-HARNESS-AS-IS.md](CANONICAL-HARNESS-AS-IS.md) — the 3-layer map; every gap
  cites a row here.
- **Synthesis:** [MASTER-FINDINGS.md](design/MASTER-FINDINGS.md) (6 MOVES, anti-phantom §E, reject §F) +
  its adversarial gate [CHECK-master-findings.md](design/CHECK-master-findings.md).
- **Phase 3 (design):** [memory-model](design/phase3/memory-model.md) · [enforcement-sort](design/phase3/enforcement-sort.md)
  · [target-file-tree](design/phase3/target-file-tree.md) — each with a `CHECK-*.md`; reconciled in
  [phase3/RECONCILIATION.md](design/phase3/RECONCILIATION.md).
- **Phases 4–5:** [distribution](design/phase45/distribution.md) · [compounding-loop](design/phase45/compounding-loop.md)
  — each with a `CHECK-*.md`; reconciled in [phase45/RECONCILIATION.md](design/phase45/RECONCILIATION.md).
- **Phase 6 (review):** 5 lens reviews [phase6/lens-*.md](design/phase6/) + the
  [REVIEWER-CONSOLIDATION.md](design/phase6/REVIEWER-CONSOLIDATION.md) (anti-duplication gate result, tiered
  findings, the 5 decisions).
- **Method:** every artifact was produced by a doer and attacked by a separate adversarial checker;
  load-bearing absence-claims were re-verified on disk because the audit itself was caught rotting. The
  checkers caught: two artifacts hiding a file-count increase, a phantom rule (R2), a false "verbatim"
  deletion (a KEEP-VERBATIM-floor risk), a budget-misbooking in the synthesis, and two cross-phase build-order
  hazards no single-artifact review could see.
