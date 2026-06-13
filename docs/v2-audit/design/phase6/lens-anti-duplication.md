# Phase 6 — Lens: ANTI-DUPLICATION (the gate that would have killed the V1 failures)

**Charge.** Take every surviving proposal across Phases 3+4+5 (every new file, hook, script, skill, rule
shard, store change, CI job, manifest, the plugin, the eval corpus) and test each against three duplication
classes: (1) **PHANTOM** — already exists on disk/runtime (MASTER-FINDINGS §E + as-is map §3–§6); (2)
**REJECTED** — rebuilds a §F reject-as-literal pattern; (3) **CROSS-PHASE DUPLICATE** — two phases
independently propose the same mechanism under different names. Verdict per item: genuinely-new /
phantom-KILL / rejected-KILL / merge-with-X.

**Method honored.** Read the authoritative corpus (both RECONCILIATION files are authoritative over drafts)
+ MASTER-FINDINGS + as-is map + capability-facts. Ground-truthed every load-bearing presence/absence claim
on disk this session (2026-06-11) rather than trusting the audit artifacts — audit artifacts rot, and this
lens exists precisely because they do.

**Verdict: CONCERNS.** The integrated design is *substantially* clean on the duplication axis — the
anti-phantom discipline is real, the §F rejects are honored, and the worst cross-phase candidates were
already caught and merged by the authors themselves. I could not break the core. But three things survive:
one phantom that lives on in an uncorrected DRAFT (superseded by RECONCILIATION but still on disk and
citable), one genuine cross-phase adjacency (`harness-manifest.json` vs the real `skills-lock.json`) that is
acknowledged-but-not-reconciled, and one under-counted generator that is a soft merge candidate. None is a
SERIOUS V1-class failure; all three are precisely the kind of residue this gate exists to name.

---

## What I ground-truthed on disk (so these verdicts don't rot)

| Claim under test | Disk result (2026-06-11) | Bearing |
|---|---|---|
| `.claude/rules/` ABSENT | `ls` → No such file | shards genuinely-new ✅ |
| `.claude-plugin/` ABSENT, no `marketplace.json`/`hooks.json` | absent | plugin layer genuinely-new ✅ |
| hooks on disk = 5 (not 7) | `block-dangerous-git`, `block-npm-install`, `permission-logger`, `session-start`, `worktree-create` | `block-dangerous-bash` + `session-end-capture` genuinely-new ✅ |
| `session-end-capture.sh`, `block-dangerous-bash.sh`, `scan-context.sh`, `gen-rules.sh`, `gen-manifest.sh`, `harness-manifest.json` | ALL absent | all genuinely-new ✅ |
| `skills-lock.json` (repo root) | EXISTS, **751 B**, tracks 2 upstream supabase skills, `npx skills add`-managed | map §6 "phantom" was the stale claim; Phase-4 C1 correction confirmed ✅ |
| global `~/.agents/.skill-lock.json` | EXISTS, **6,715 B**, 15 mattpocock skills | confirms Phase-4 C1: the 6.7 KB file is the *global* one, conflated in the draft ✅ |
| `ci.yml` | 3 run steps (tsc, eslint, test:unit), no eval/sentinel lane | `cr-eval.yml` genuinely-new ✅ |
| `integration.yml` | `workflow_dispatch:` only | the model `cr-eval.yml` copies is real, not duplicated ✅ |
| `@typescript-eslint/ban-ts-comment` | **fires as ERROR** on `// @ts-ignore` inside `src/` (tested) | the draft enforcement-sort R2 "relocate/add" IS a phantom — see F-1 |
| `import/no-cycle` | already ESLint `error` | enforcement-sort correctly treats as already-present ✅ |
| `learned-patterns.md`, `review-log.md`, `triage-inbox.md` | appear in NO surviving proposal | §F rejects honored ✅ |
| `symlink-live` | appears only as the explicitly-rejected option | §F honored ✅ |
| `/loop`, scheduler, `CronCreate` rebuild | no proposal rebuilds them; loop rides `rituals.md` heartbeat | anti-phantom honored ✅ |

---

## A. PHANTOM class — does it already exist on disk/runtime?

I tested every surviving build item against MASTER-FINDINGS §E (already-built) + map §3e/§4/§5/§6 +
the runtime tool list. Results:

**Genuinely-new (verified absent on disk):** `.claude/rules/*` shards · `block-dangerous-bash.sh` ·
`session-end-capture.sh` · `scan-context.sh` (the long-documented-but-absent `/scan-context`, map §5/§6) ·
`gen-rules.sh` · `migration-lint` · `repo-structure` · `dependency-cruiser` config+dep · `.cr-ok`→CI
branch-protection · `/cr-security` glob classifier · the whole `.claude-plugin/` layer (`plugin.json`,
`marketplace.json`, `hooks/hooks.json`, `harness-manifest.json`, VERSION/CHANGELOG) · `gen-manifest.sh` ·
`.claude/eval/cr-golden/` corpus · `score-cr-eval.sh` · `/cr-eval` skill · `cr-eval.yml`. **No phantom-KILL
in the authoritative (reconciled) design.**

**The one phantom that survives — but only in an UNCORRECTED DRAFT (F-1, SHOULD-FIX).** The Phase-3
enforcement-sort DRAFT, line 106, classifies **R2 (`no @ts-ignore`)** as `current: L3 → TARGET: L1 …
**relocate** … "add ESLint @typescript-eslint/ban-ts-comment error"`. I tested this on disk: a `// @ts-ignore`
inside `src/` already produces `error … @typescript-eslint/ban-ts-comment` (ships transitively via
`eslint-config-next/typescript`). **Proposing to "add" an already-firing rule is the exact V1 failure class
this gate exists to kill.** RECONCILIATION-phase3 §C.1 *already caught this* ("[BLOCKER] R2 is a phantom —
reclassify `keep (already L1)`") — so the authoritative position is correct. The residue is that the
superseded draft still sits on disk carrying the phantom, the headline "≈64 rules become deterministic" count
was computed *with R2 in the relocate column*, and a downstream reader who cites the draft (not the
reconciliation) re-imports the phantom. **This is a documentation-hygiene defect, not a live design defect**
— but the whole reason for the anti-phantom gate is that uncorrected artifacts get cited. Same hazard, smaller
blast radius, applies to draft enforcement-sort's R101 (`next/image`) — RECONCILIATION §C.3 corrects it from
"net-new" to "warn→error bump," but the draft still reads net-new.

**Anti-phantom POSITIVES worth crediting (the gate working):**
- The design treats the **auto-memory subsystem** as ride-don't-rebuild (memory-model §5) — it does NOT
  hand-roll a capture layer the CC subsystem already runs. That is the §F `learned-patterns.md` rejection
  applied correctly.
- The compounding loop **rides the existing `rituals.md` heartbeat** rather than building a scheduler; the
  runtime `CronCreate`/`/loop`/`/schedule` substrate is left untouched and the scheduler is correctly
  *deferred* (MASTER-FINDINGS §C), not rebuilt.
- `cr-eval.yml` is explicitly modeled on the existing `integration.yml` `workflow_dispatch` pattern — a
  reuse of an established lane shape, not a new CI substrate.
- `skills-lock.json`: the map §6 called it a phantom; Phase 4 **re-verified it is real on disk and corrected
  the map** instead of proposing to build it. That is the anti-phantom rule run in the *correct* direction
  (trust disk over the rotted audit). Credit where due.

---

## B. REJECTED class — does it rebuild a §F reject-as-literal pattern?

Tested each §F entry against the surviving proposals. **Zero rejected-KILLs.** Specifically:

| §F rejected pattern | Surviving design's posture | Verdict |
|---|---|---|
| `learned-patterns.md` (monotonic store, ×3 articles) | Not built. The "read-path not a file" fix is S3 task-start glob + native `paths:` — exactly §F's prescription. | honored ✅ |
| symlink-live install | Built as **versioned-copy-with-lock** via `/plugin install @version` (validated SHA); symlink-live named only to reject it (distribution §1, §4a). | honored ✅ |
| front-load trigger-words / shrink-root-to-200-lines | Tiering is by trigger-EXISTENCE not line-count (memory-model §7; file-tree CLAUDE.md trim). | honored ✅ |
| collapse 23 agents → skills | Roster kept at 23, each carrying a §9 failure-mode line; collapse explicitly rejected (file-tree §3). | honored ✅ |
| dev-container/VM/microVM/token-proxy stack | Not proposed; enforcement is "allowlist operations not destinations, off the model" (bash guard + egress carve-out). | honored ✅ |
| import-the-rates (ROI/recall numbers) | Phase 5 §4 explicitly refuses imported rates; measures recall LOCALLY from this harness's own runs. | honored ✅ |
| "no shared context" for the reviewer | Lens agents keep shared project canon, isolated solution context (file-tree §3 keeps all 4 lenses wired). | honored ✅ |
| paste autoMode into settings.json by the agent | autoMode placement is a NEEDS-HUMAN handoff in every phase (enforcement-sort (e); distribution §3a.9, §7.6). | honored ✅ |
| Playwright MCP / `/cr-feature` / `/change` | `cr-feature` references are slated for DELETION at convergence (distribution §3a row 1); none rebuilt. | honored ✅ |

The §F discipline is the strongest axis in the whole design. I attacked it hardest at the
distribution layer (where a "make it installable" instinct most tempts a symlink-live or a re-vendoring of
upstream skills) and it held: the 2 supabase skills are explicitly NOT re-shipped in the plugin (they stay
`npx skills add`/`skills-lock.json`-sourced — distribution §2 table + §7.7), which is the precise inverse of
the re-vendoring failure.

---

## C. CROSS-PHASE DUPLICATE class — two phases, same mechanism, different name

This is where the real risk lives (the per-phase checkers cannot see across phases). Four candidates from the
brief, plus two I found:

### C-1. Distribution drift-check vs Phase-3 `scan-context` drift detector — **MERGE, already executed (clean)**
The brief asks: does the distribution drift-check duplicate the Phase-3 scan-context detector? **No — Phase 4
explicitly reuses it.** distribution.md:282 names the manifest drift-CI as "`scan-context.sh`, the
`/scan-context` phantom finally built — MOVE-3," and §6 line 406 states the scan-context check is "already
counted in the Phase-3 mechanism budget." The cross-phase budget summation (phase45/RECONCILIATION) lists
scan-context **once** (Phase 3) and does not re-count it under Phase 4. This is the correct outcome — one
detector, extended with manifest assertions — and the authors did the merge themselves. **Genuinely-new is
only the *manifest assertions* layered onto the existing detector, not a second detector.** Clean.

### C-2. Golden-set freshness check vs the scan-context detector — **MERGE, already executed (clean)**
Phase 5 §3.6 could have built a second freshness mechanism for the golden set. It explicitly does not:
"**The drift detector (memory-model §8) is extended to assert golden-set freshness — one more class of
fiction/decay check, in the lane that already exists. No new owner mechanism; ride the heartbeat + the drift
CI.**" The `backs_rule:` pointer from a golden case to an S1 rule is "wiring, not a merge" and is checked by
the *same* detector. This is the textbook correct resolution. Clean.

### C-3. Golden set vs a 4th memory store — **NOT a duplicate (correctly distinguished)**
Phase 5 §3.2 pre-empts exactly this: the golden set is a **CI fixture corpus** (`.claude/eval/cr-golden/`,
same class as `scripts/seed.ts` or integration fixtures), NOT an owned memory store — "the agent never reads
it during normal work." It rides the writer/reader/freshness *discipline* of a store without being one. The
distinction is real and load-bearing: budget (1) = 0 because the agent doesn't read it. Clean — and it is the
single cleanest "don't invent a 4th store" guard in the set.

### C-4. `harness-manifest.json` vs `skills-lock.json` — **GENUINE ADJACENCY, acknowledged-but-not-reconciled (D-1, SHOULD-FIX)**
This is the one cross-phase/cross-artifact duplication that survives scrutiny. Both are generated,
git-tracked, machine-readable manifests that list **skills with a source + a content hash**:
- `skills-lock.json` (real, on disk, 751 B): writer = `npx skills add`; scope = *which upstream skills this
  project pulls* (the 2 supabase skills, SHA-256, github source); consumer = the skills-add tooling.
- `harness-manifest.json` (proposed, distribution §3b): writer = `gen-manifest.sh`; scope = *the full owned
  inventory* (all skills+agents+hooks+rules, with owner/failureMode/wiring/hash); consumer = the
  `scan-context` drift-CI / convergence gate.

distribution.md is **aware** of the overlap — §3b says the manifest is "modeled on the existing
`skills-lock.json` (which already does exactly this for upstream skills)" and §3a row 7 calls skills-lock "the
*precedent* for the harness-manifest." So this is not a blind phantom; the author saw it. **But seeing a
precedent and citing it is not the same as reconciling two overlapping mechanisms.** Two generated
hash-of-skill manifests with different writers will drift: when an upstream supabase skill updates, `npx
skills add` rewrites `skills-lock.json`'s hash but `gen-manifest.sh` must independently recompute the same
skill's hash in `harness-manifest.json`, and nothing asserts the two hashes agree. That is a *new* drift seam
introduced by the very mechanism meant to catch drift. **This is precisely the failure class the gate guards:
a second inventory that overlaps the first.** It does not rise to phantom-KILL (the manifest's
agents/hooks/rules coverage is genuinely-new and skills-lock cannot carry it), so the resolution is
merge-discipline, not deletion: harness-manifest must either (a) mark the 2 upstream skills `owner: upstream`
and **reference skills-lock's hash rather than recomputing it** (single source of truth for the upstream-skill
hash), or (b) the design must state the precise non-overlap boundary and add a drift assertion that the two
manifests agree on any shared skill. Until one of those is specified, two hash manifests can disagree silently.

### C-5. `gen-manifest.sh` vs `gen-rules.sh` — **soft merge candidate + budget undercount (D-2, CONSIDER)**
Two new generator scripts, same shape ("read disk → emit a checked-in artifact → CI asserts it"):
`gen-rules.sh` emits the rule shards; `gen-manifest.sh` emits the inventory manifest. They are not the *same*
mechanism (different outputs) so this is not a hard duplicate — but they are close enough to flag as a
CONSIDER-level "could be one `gen.sh` with two subcommands," especially since both run in the same CI lane and
both feed the same `scan-context` drift check. Separately, a budget-honesty note relevant to this lens:
`gen-manifest.sh` appears in distribution §6 ("plus `gen-manifest.sh` and the scan-context.sh drift check")
but is **NOT** enumerated in the phase45/RECONCILIATION cross-phase summation's Phase-4 line (which lists
plugin.json, marketplace.json, hooks.json, harness-manifest, VERSION/CHANGELOG — five items, no gen-manifest).
So the +4–5 Phase-4 figure undercounts by one script. Minor, but the two-budget rule's whole point is that
budget (2) growth is honestly tallied per §9 item; a dropped generator is a (small) tally error.

### C-6. `session-end-capture.sh` vs `/cr` Step 3b — **NOT a duplicate (correctly framed as two emitters, one schema)**
I checked whether the Stop-hook writer and the existing `/cr` 3b writer are two mechanisms doing one job.
memory-model §6 + compounding-loop §1 frame them as "one logical writer, two trigger points (review-time vs
session-end), matched on `signature` so there is no write-contention." That is the correct framing — same row
schema, same store (S3), same matching key. Not a duplicate; a deliberate second emitter of one shape.
Naming is consistent across phases (`session-end-capture.sh` everywhere; never the dead `session-end.sh`).
Clean.

---

## D. The single hardest thing I tried to break (and couldn't)

The most promising kill was **the golden set as a smuggled 4th memory store** — the brief flags it explicitly
("does the golden-set duplicate a memory store?"), and a measurement corpus that carries
writer/reader/freshness contracts *looks* exactly like an owned store. I attacked it three ways: (1) it has a
writer (`/cr` 3b emits candidates), a reader (`/cr-eval`), and decay clocks — the full store signature; (2)
it lives under `.claude/`, where the other stores live; (3) it even carries a `backs_rule:` pointer INTO S1.
All three are real. But the design's distinction holds under load: the discriminating test for "is this a
memory store" is **does the agent read it to do normal work** — and it does not (budget (1) = 0). seed.ts and
the integration fixtures have the same lifecycle discipline and nobody calls them memory stores. The
`backs_rule:` coupling is checked by the existing detector and does not merge the artifacts. The design
pre-named this exact objection (§3.2 "Why this is NOT a 4th memory store") and answered it correctly. I could
not turn it into a duplicate-KILL. That the design *anticipated its own hardest duplication objection and
disarmed it* is the strongest single signal that the anti-duplication discipline was actually applied during
authoring, not just claimed.

---

## Findings (ranked)

**SHOULD-FIX**
- **F-1 (PHANTOM, draft residue).** The uncorrected Phase-3 enforcement-sort DRAFT still carries R2
  (`@ts-ignore` ban) as a "relocate/add" — disk-tested today, `ban-ts-comment` already errors. RECONCILIATION
  §C.1 caught it, but the draft and its "≈64 deterministic" headline count remain on disk and citable, and
  R101 (`next/image`) has the same draft-vs-reconciliation gap. **Fix:** stamp the superseded drafts
  ("AUTHORITATIVE: see RECONCILIATION §C — R2/R101 reclassified; this draft's relocate-count is stale") or
  recompute the headline so no downstream artifact re-imports a phantom.
- **D-1 (CROSS-PHASE DUPLICATE).** `harness-manifest.json` (Phase 4) is a second generated hash-of-skill
  manifest overlapping the real `skills-lock.json` on the skills dimension. Acknowledged as "precedent" but
  not reconciled, leaving a silent drift seam (two hashes for the same upstream skill, no assertion they
  agree). **Fix:** harness-manifest marks upstream skills `owner: upstream` and *references* skills-lock's
  hash instead of recomputing it (single source of truth), OR add a drift assertion that the two agree on any
  shared skill. Do not delete the manifest — its agents/hooks/rules coverage is genuinely-new.

**CONSIDER**
- **D-2 (soft merge + budget undercount).** `gen-manifest.sh` and `gen-rules.sh` are two same-shaped
  generators feeding the same CI drift lane — candidate to fold into one `gen.sh` with subcommands. Separately,
  `gen-manifest.sh` is omitted from the phase45 cross-phase budget-(2) summation's Phase-4 enumeration (+4–5
  undercounts by one script). Reconcile the tally.
- **D-3 (watch, not a defect yet).** The convergence gate (distribution §3) and the drift detector
  (memory-model §8) both assert "every X on disk is documented / every documented X exists on disk." These are
  the same *kind* of assertion over different inventories (manifest vs knowledge-doc refs). They are correctly
  run in one lane today; flag only so a future phase does not split them into two competing existence-checkers.

---

## topConcern

The design's anti-duplication discipline is genuinely strong — every §F reject is honored, the auto-memory
and scheduler substrates are ridden not rebuilt, and the two worst cross-phase candidates (drift-check,
golden-set freshness) were already merged into single mechanisms by the authors. The one duplication that
truly survives is **`harness-manifest.json` overlapping the real `skills-lock.json`** (D-1): a second
generated hash-of-skill manifest, seen-as-precedent but not reconciled, which introduces a fresh silent
drift seam (two independently-computed hashes for the same upstream skill, with nothing asserting they agree)
inside the very mechanism whose job is catching drift. It is a SHOULD-FIX, not a KILL — the manifest's
agents/hooks/rules coverage is legitimately new — but it must reference skills-lock's hash for the shared
skills rather than recompute it, or the convergence gate will eventually certify two manifests that disagree.
