# Phase 6 — Lens: COMPOSITION-COHERENCE

**Charge.** Attack ONE failure class across the WHOLE integrated V2 design (Phases 3+4+5 together): do
MOVES 1–6 cohere into one system, or fight each other at the seams? A single-artifact checker reads one
draft and confirms its central claim. The seams *between* drafts are exactly what no single checker owns —
the memory model assumes the distribution split; the distribution split assumes the memory model; the
compounding loop rides `/cr` Step 3b that the enforcement sort is simultaneously relocating to CI. This
lens lives in the gaps.

**Method.** Read the two RECONCILIATIONs (authoritative) + the three Phase-3 drafts + both Phase-45 drafts
+ MASTER-FINDINGS + capability-facts. Then ground-truth the load-bearing seam claims on disk myself, because
audit artifacts rot (the corpus says so repeatedly, and it is right — see C1 below).

**Disk re-verification this session (2026-06-11):**
- Project auto-memory at `/Users/tanner/.claude/projects/-Users-tanner-Dev-event-vendor/memory/` = **50
  `feedback_*`/`project_*`/`reference_*` files + `MEMORY.md` (9914 B, the auto-loaded index)**. The corpus
  consistently says "52 files" / "auto-memory at 52" — disk says 50 + MEMORY.md. Minor, but the corpus
  number is already stale by 2.
- **`reference_*` is a THIRD prefix** in auto-memory (3 files). The memory model §5 and the drift detector's
  de-dup signature (§8/§5) name only `feedback_*`/`project_*`. The `reference_*` class is unaccounted for.
- **`.claude/rules/` ABSENT, `.claude-plugin/` ABSENT, `scripts/gen-rules.sh` ABSENT, `scripts/scan-context.sh`
  ABSENT** — confirmed. Every load-bearing mechanism the design composes through is net-new.
- **A `Stop` hook is ALREADY wired in `settings.json:191`** — it plays `Glass.aiff`. MOVE-1's
  `session-end-capture.sh` is the *second* Stop hook, not the first. No draft mentions the incumbent.
- **TWO files effectively named "memory":** `.claude/memory.md` (10249 B, what `/compound` Step 9 reads at
  `compound/SKILL.md:143`) and the auto-memory `MEMORY.md` (the CC subsystem cache). The design deletes the
  former and rides the latter. These are different files; the naming collision is a live trap.
- **`/compound` reads `.claude/memory.md` only** (line 143) — confirms RECONCILIATION §B.1: the
  auto-memory→S1 graduation is net-new, not a retarget. Verified.
- **`/cr` Step 3b is at `cr/SKILL.md:174`; Step 4 (MUST-FIX) at 192; sentinel write at 240.** The skill's own
  Step-0 meta-check (line 36) documents a structural-ordering rule about 3b. Load-bearing for C5 below.
- **PITFALLS `**Area:**` field: 36 entries** — confirmed; the shard split key is real.

**Verdict: CONCERNS.** The design is more coherent than I expected — the two RECONCILIATIONs already caught
the biggest cross-artifact lie (the two-budget double-count) and the central seam (plugin-can't-carry-
permissions) is genuinely forced, not chosen. I could not break the load-bearing structural claims. But I
found **five real integration seams that no single-artifact checker tested**, two of which are MUST-FIX
because they will silently produce the exact failure class (drift, phantom, lost-fact) the design exists to
prevent. The whole-system story holds; specific seams leak.

---

## What I attacked hardest and could NOT break (stated first, per the no-rubber-stamp rule)

I spent the most effort trying to break the claim that **"auto-memory is a demoted cache, prose-only
conflict rule" composes with the distribution's "ship empty scaffolds" story** — i.e. that when the harness
ships to a downstream project that *also* has its own CC auto-memory, the model's authority ordering still
holds. My hypothesis was: the conflict rule ("on conflict, curated stores win") is written into the plugin's
`00-safety.md`, but auto-memory is *user-scoped and per-project* (verified: it lives at
`~/.claude/projects/<project-hash>/memory/`, outside any repo) — so a downstream install gets a DIFFERENT
auto-memory than event-vendor's, and the conflict rule has to govern a cache the plugin author never saw.

It survives, and here is why: the conflict rule is **content-free about *which* facts** — it only states an
*ordering* ("curated S1–S3 outrank the auto-cache on conflict"). That ordering is universal regardless of
what the downstream cache contains. The rule travels as one prose line in the safety floor and governs any
auto-memory, including one the author never saw. The distribution doc (§2 memory table) correctly marks
auto-memory as **NOT shipped** ("it's the CC subsystem's, user-scoped") and ships only the *ordering line*.
That is the right decomposition: ship the rule, never the cache. The seam holds. **This is the design's
cleanest composition** and I want it on record that I tried to break it and could not.

What I *could* break is adjacent to it — the de-dup *signature* mechanism that the conflict rule's enforcement
half depends on (C2). The ordering composes; the de-dup signal that's supposed to make the ordering
actionable does not, in two ways.

---

## MUST-FIX

### C1. The drift detector ("surface, never auto-edit") and `gen-rules.sh` ("generated projections") form a CIRCULAR trust seam that no draft resolves — the generator can launder a phantom past the detector that is supposed to catch it.

This is the deepest integration contradiction in the design, and it is invisible to any single-artifact
reader because the generator lives in the file-tree/memory-model drafts and the detector's contract lives in
memory-model §8 — but the *interaction* lives in neither.

The composition the design asserts:
- `scripts/gen-rules.sh` **generates** the `.claude/rules/*.md` shards as *projections* of the canonical
  constraint corpus (memory-model §7; tree §5). "The shards are generated projections … the drift CI asserts
  shard ↔ source consistency so the projection never drifts."
- The drift detector (`scan-context.sh`, memory-model §8) **asserts** "every `.claude/rules/*.md` entry ↔ a
  backing canonical entry (shard projection integrity)."
- The drift detector "**SURFACES** candidates … does NOT auto-edit knowledge docs (CLAUDE.md forbids silent
  deletion) — the clock is in tooling, the apply keeps a human" (§8, repeated in §3).

Here is the seam. **What is the "canonical source" that the shards are a projection OF?** The memory model
never names a physical canonical-corpus file. PITFALLS.md is DELETED (tree §2, memory-model §i row 3). The
shards ARE the post-deletion home of the constraints. So after the one-time migration, there is no separate
"source" — **the shards are both the projection and the source.** `gen-rules.sh` then has nothing to project
*from* except the shards themselves, and the drift check "shard ↔ backing canonical entry" checks the shard
against… the shard. The integrity assertion is vacuously true. The projection-vs-source framing is a fiction
the moment PITFALLS dies.

Two ways this breaks under integration:

1. **If the canonical source is retained** (the constraints live in some master file and shards are
   regenerated from it), then we have re-created the exact "two homes, one fact" the memory model spent its
   whole thesis killing — and worse, the ADR projection (memory-model §1: `docs/adr/` retained as long-form +
   projected into `architecture.md`) ALREADY admits one such two-home pair. Now EVERY shard is a two-home
   pair. The design's own headline ("the same fact stops existing in 3 files and exists in exactly one
   canonical place") is false: it exists in the canonical corpus AND its projected shard.

2. **If the canonical source is NOT retained** (shards are authoritative, no master), then `gen-rules.sh` has
   no job — there is nothing to generate — and the drift detector's "projection integrity" check is checking
   nothing. The design lists `gen-rules.sh` as a §9-justified budget-(2) mechanism (tree §9; phase45
   summation +1 generator). A generator with no source to project from is **a §9 ghost** — exactly the class
   MOVE 4 is supposed to evict. The design ships an evictable mechanism in the same package that builds the
   eviction engine.

The drift detector's "surface, never auto-edit" rule makes this *worse*, not better. Because the human
applies edits by hand (the apply keeps a human), a human editing a shard directly is the EXPECTED path — but
then the next `gen-rules.sh` run, if there is a source, **silently overwrites the human's hand-edit** with the
projection (the whole point of generation is determinism). So either the generator clobbers human edits (and
"surface, never auto-edit" is violated by the generator even though the detector honors it), or the generator
is inert. The detector and the generator cannot both have their stated contract.

**This is the #1 composition failure** because both mechanisms pass their own single-artifact checker — the
file-tree checker confirmed `gen-rules.sh` is a sound mechanism; the memory-model checker confirmed the drift
detector is a sound mechanism — but **nobody checked whether a generated-projection model and a
surface-never-auto-edit model can hold the same files at once.** They cannot without a named, retained
canonical source AND an explicit rule that hand-edits go to the source, never the shard. That rule does not
exist in any draft.

**Recommendation.** Resolve the source question explicitly before any build:
- **Name the retained canonical corpus file** (e.g. `.claude/rules/_source/<area>.md` or a single
  `constraints.yaml`), make the `<area>.md` shards pure generated artifacts (gitignored or clearly marked
  `GENERATED — do not hand-edit`), and route ALL writers (`/cr` 3b, `/compound`, human) to the source, never
  the shard. Then `gen-rules.sh` has a real job and the drift check is meaningful.
- OR drop `gen-rules.sh` entirely, make the shards authoritative and hand/skill-edited, and replace
  "projection integrity" with "shard well-formedness" (frontmatter valid, paths resolve). This is the simpler/
  boring choice and probably correct at solo scale — but it must be a stated decision, because it deletes a
  mechanism the budget summation currently counts (+16–20 becomes +15–19) and changes the drift contract.

Either is fine. Shipping *both contracts over the same files* is the incoherence.

---

### C2. The auto-memory de-dup "signature" signal that powers BOTH the conflict-resolution enforcement AND the graduation-out conveyor is under-specified across three drafts, and the disk has a prefix class (`reference_*`) the signal does not cover — so the cross-MOVE signal silently drops a third of the cache.

The de-dup signature is a load-bearing *connector* between MOVE 3 (memory) and the compounding loop — it is
how auto-memory feeds promotion. Memory-model §5: "the drift detector computes a signature per `feedback_*`
file and asserts coverage in S1. Covered → expected redundancy … Uncovered → a promotion candidate
('auto-memory learned something S1 missed')." This same signal is cited in §8 (the detector) and is the
mechanism that makes §5's "ride/demote/fence" actionable rather than prose.

Three composition problems, found only by reading the three drafts against the disk together:

1. **The signature scheme names `feedback_*` (§5) and "`feedback_*`/`project_*` corpus" (§8, RECONCILIATION
   §B.1) but the disk also carries `reference_*` files** (`reference_agent_harness_research_tree.md`,
   `reference_ai_native_engineering_research.md`, `reference_notion_engineering_system.md` — verified). These
   are research-pointer entries, not codebase traps — so arguably they SHOULD be excluded from promotion. But
   the design never says so. If the detector globs `feedback_*`/`project_*`, the `reference_*` files are
   silently invisible to the coverage check — fine for promotion, but it means the "assert coverage in S1"
   completeness claim is false (the cache is not fully accounted for, which §5's whole "the model must
   account for it" premise demands). If the detector globs `*`, the `reference_*` files generate permanent
   false-positive promotion candidates (research pointers that will NEVER be in S1, surfaced forever as
   "auto-memory learned something S1 missed"). Either way the signal is wrong on a class the design did not
   know was there.

2. **"Signature" is never defined, and it has to mean the SAME thing in three places** that were written by
   three different drafts: the S3 `signature`-matched write schema (memory-model §2 S3 — the field two
   emitters dedup on), the auto-memory de-dup signature (§5/§8 — a hash per `feedback_*` file), and the
   golden-set's `signature`/`Example locations` glob the read-path matches against (compounding-loop §2,
   memory-model §9). These are three DIFFERENT signature concepts wearing one word. The S3 one is a per-finding
   content key; the auto-memory one is a per-file hash; the read-path one is a path-glob match. A reader
   composing the loop will assume they unify (the drafts encourage this — "matched on `signature` so there is
   no write-contention"). They do not. If an implementer wires the auto-memory de-dup to emit an S3 row, the
   two signature schemes have to reconcile, and nothing says how.

3. **The graduation-out conveyor (§5 "graduate-out: `/compound` Step 9 reads the corpus") depends on a
   capability RECONCILIATION §B.1 just demoted to net-new** — `/compound` does NOT read the corpus today
   (verified: `compound/SKILL.md:143` reads `.claude/memory.md`, a different file). So the de-dup signal
   feeds a conveyor that doesn't exist yet. That's acknowledged as a build. But the *measurement* of whether
   the conveyor works (does promotion actually catch what the cache learned?) is the compounding loop's
   golden set — which seeds from "historical promoted MUST-FIX findings" (loop §3.2 source 1), NOT from
   auto-memory graduations. So the one new conveyor (auto-memory→S1) is the one path with no measurement
   coverage in the loop. The cross-MOVE wiring lands the auto-memory signal in a promotion path that the
   measurement leg doesn't watch.

**Recommendation.** (a) Define "signature" once, in one place, with the three distinct senses named and
disambiguated (rename two of them — e.g. `finding-key`, `cache-hash`, `path-match`). (b) State the
auto-memory glob explicitly and decide `reference_*`'s disposition (recommend: exclude by prefix, document the
exclusion so the coverage claim stays honest). (c) Add one golden-case source: "auto-memory graduations that
later proved real," so the new conveyor is measured like the others. These are cheap and they close a seam
that will otherwise drop ~3 files of cache and emit permanent false-positive promotion noise — the
"forgeable/stale gate" failure the whole memory model exists to prevent, reintroduced through the back door.

---

## SHOULD-FIX

### C3. The two-vehicle split (plugin + template) creates a THIRD drift axis — plugin-version vs project-files vs canon — and the convergence gate only covers ONE of the three pairings.

The distribution doc's convergence gate (§3) is built to keep **canon ↔ disk** in sync (the harness-manifest
asserts manifest = disk = canon). That is the pairing the canon-locked decision names. But the two-vehicle
split introduces a NEW pairing the gate was not designed for:

- **Axis 1: canon ↔ disk** (covered by §3 manifest check).
- **Axis 2: plugin-version ↔ project-authored-files.** A downstream project pins `agent-harness@1.2.0`
  (plugin: skills/agents/hooks/`00-safety`). The project authors its OWN `.claude/rules/<area>.md` shards,
  its OWN permissions, its OWN CLAUDE.md from the `1.2.0` templates. When the plugin updates to `1.3.0` and
  changes the `rules-area.md.template` SHAPE (say, adds a required frontmatter field the drift detector now
  asserts), the project's hand-authored `1.2.0`-era shards are now schema-stale against the `1.3.0`
  detector — but `/plugin update` "never overwrites the project's area shards" (§4a, correctly, to avoid
  clobbering). So the project's drift detector (shipped by the plugin) will start failing against shards the
  project authored under the old schema, with no migration path. **The plugin can update the rule that
  validates project files without updating the project files** — a drift the §3 gate doesn't model because §3
  only watches canon↔disk inside ONE repo.

- **Axis 3: plugin-shipped `00-safety.md` ↔ project's CLAUDE.md safety floor.** The memory model puts the
  KEEP-VERBATIM destructive-op trio in BOTH the CLAUDE.md always-load floor (memory-model §1, §7) AND
  `00-safety.md` (the shard with no `paths:`, tree §5). RECONCILIATION §B.4 made `00-safety.md` absorb the
  *richer* copy verbatim. Now distribution ships `00-safety.md` as a PLUGIN file (distribution §2: "PLUGIN —
  the universal safety floor") while CLAUDE.md is PROJECT-owned (from template). **So the safety floor lives
  in a plugin-owned file AND a project-owned file, and `/plugin update` can change one but not the other.** A
  `1.3.0` that strengthens `00-safety.md` leaves every downstream project's CLAUDE.md floor at the `1.2.0`
  wording — the two copies of the KEEP-VERBATIM safety text drift, and KEEP-VERBATIM is the one class where
  drift is most dangerous. The memory model's "the same fact lives in exactly one canonical place" is broken
  specifically for the highest-stakes content, by the distribution layer, after the memory model already
  fought to deduplicate it.

This is a genuine emergent property of composing MOVE 3 (memory dedup) with MOVE 5 (two-vehicle distribution):
each is locally coherent; together they re-duplicate the safety floor across an ownership boundary that
`/plugin update` cannot cross.

**Recommendation.** (a) Pick ONE home for the destructive-op safety floor across the vehicle boundary: EITHER
it lives only in plugin `00-safety.md` (and CLAUDE.md *references* it, doesn't copy it — but then a project
that doesn't load the rule loses the floor, so this needs the always-load guarantee verified for plugin-shipped
rules), OR it lives only in project CLAUDE.md (and the plugin ships it as a template the `/init` copies once,
never updates — accepting it won't get security updates). The current "both, plugin-owned and project-owned,
verbatim" is the worst case. (b) Add the plugin-template-version ↔ project-authored-shard pairing to the
convergence/drift design: the project's shards should carry a `template-version:` field, and the drift
detector should flag when the plugin's template schema has moved past the project's authored shards (a
migration prompt, not a silent failure). This is the third drift axis made visible.

### C4. "Entry-as-atom (tier:/kind:)" composes with the plugin's S1 split ONLY if the frontmatter schema is identical across plugin-shipped and project-authored shards — but the schema lives in no single owned place, so the two halves can diverge.

The memory model's spine is entry-as-atom: every constraint carries `tier:`, `kind:`, `last_fired:`,
`superseded-by:` (memory-model §4). The distribution split says `00-safety.md` (the entries with
`tier: safety`) ships from the PLUGIN, while area shards (entries with `tier: area`) are PROJECT-authored from
a `rules-area.md.template`. So the **entry schema is defined in two vehicles**: the plugin authors safety
entries; the project authors area entries from a template. The drift detector (shipped by the plugin) asserts
frontmatter validity on BOTH.

The composition risk: entry-as-atom only "dissolves the dual-assignment" (memory-model §4's central claim) if
`tier`/`kind`/`last_fired` mean the same thing in a plugin-shipped entry and a project-authored entry. There
is no single owned schema file — the schema is implicit in `00-safety.md` (plugin), the
`rules-area.md.template` (plugin), and the drift detector's assertions (plugin). Three implicit copies of one
schema, two of which the project can edit (it authors its shards; it MAY override `00-safety`? — distribution
§2 says SOUL/contract are overridable plugin defaults; it's unstated whether `00-safety` is). If a project
adds a `kind:` value the plugin's detector doesn't know, or the plugin adds a `tier:` the project's shards
don't use, entry-as-atom's "one data model" fractures along the vehicle seam. The elegant dissolution of the
PITFALLS/memory dual-assignment (the model's proudest result) is only as coherent as the least-synchronized
copy of an unwritten schema.

**Recommendation.** Ship the entry schema as a SINGLE explicit artifact in the plugin (a JSON-schema or a
documented frontmatter contract in `rules/_schema.md`), have the drift detector validate against THAT file
(not against implicit assertions), and version it with the plugin. Then entry-as-atom has one source of truth
that travels, and the plugin/project split can't silently diverge the data model. Cheap; closes the seam
between MOVE 3's atom and MOVE 5's split.

### C5. The compounding loop's write-back rides `/cr` Step 3b, whose own skill flags a structural-ordering constraint — and the loop adds a SECOND writer (the Stop hook) to the same row without re-checking that ordering, while the enforcement sort simultaneously relocates the `.cr-ok` authority Step 3b sits next to.

Three MOVES touch `/cr` Step 3b and they were designed in three drafts:
- **Compounding loop (MOVE 6):** Step 3b is "the one real automated writer"; the Stop hook is a *second*
  emitter of the *same row shape*, matched on `signature` (loop §1, memory-model §2 S3).
- **Enforcement sort (MOVE 2):** the `.cr-ok` stop authority that `/cr` writes (Step 7, line 240) relocates
  to CI/branch-protection (enforcement-sort (b), R66/R68/R69). RECONCILIATION §C.5 sharpens this to "CI
  re-runs the deterministic subset" + trust-but-verify for the judgment passes.
- **`/cr` itself (disk):** the skill's Step-0 meta-check (line 36, verified) documents a *structural bug
  class* about exactly this region — "a user-input wait that blocks critical-path steps on a non-critical
  question is a MUST FIX." The skill was already hardened so that Step 3b promotion candidates are *collected
  but not surfaced* until Step 5 (lines 187, 215), specifically so a docs-curation question doesn't gate the
  Step-4 MUST-FIX fixes.

The composition the loop proposes — a Stop hook writing the same S3 row as Step 3b — does not account for
WHEN the Stop hook fires relative to this carefully-ordered pipeline. Step 3b fires mid-`/cr` (line 174,
before MUST-FIX at 192). The Stop hook fires at *turn end* — which, during a `/cr` run, could be after the
whole pipeline, or (if `/cr` is one turn) at a different point entirely. Two emitters writing the same
`signature`-matched file at different lifecycle points is fine ONLY if the matching is truly idempotent — but
the loop never verifies that the Stop hook's "corrected mistake this turn" signature and Step 3b's "recurring
finding from review" signature collide correctly. If they DON'T match (different signature derivation — see
C2.2), the same finding gets written TWICE (once by 3b as a review finding, once by the Stop hook as a
session-end finding), inflating the occurrence count and tripping the ≥3 promotion threshold on what is really
ONE observation. **The promotion gate — the model's single most important "don't over-collapse" guard — can be
forged by a double-write across two emitters the loop deliberately added.** That is the airlock leaking, via
the exact mechanism (the second writer) the loop introduces.

Meanwhile the enforcement sort is hollowing out the `.cr-ok` authority three steps away in the same skill. The
loop's §3.4 correctly ties measurement to bounding the `.cr-ok` trust claim — so the loop KNOWS Step 7's
authority is moving — but it doesn't notice that moving the authority changes what "a `/cr` run completed"
*means* for the Stop hook's trigger. If `.cr-ok` is no longer the gate (branch-protection is), then the Stop
hook can't key off "`.cr-ok` was written" to know a review happened; it has to detect the correction signal
independently — which is precisely the load-bearing-risk capability (D2) the design already flags as
unverified. The three MOVES touching this skill each assume the others' version of Step 3b's surroundings.

**Recommendation.** (a) Make the two S3 emitters share ONE signature derivation, defined once (folds into
C2.2), and add an idempotency assertion to the drift detector: an S3 row's occurrence count may not increment
twice for the same `(signature, turn-id)`. (b) State the Stop-hook trigger explicitly relative to the new
`.cr-ok`-relocated world: the Stop hook detects the correction signal from the transcript (D2's unverified
path), NOT from `.cr-ok` existence — and gate the loop's "two emitters" claim on the same one-session
empirical check D2 already owns, because if the Stop hook can't reliably distinguish its writes from 3b's,
the second emitter should degrade to OFF (3b alone), not double-write.

---

## CONSIDER

### C6. The incumbent `Stop` hook (sound-player) is invisible to the whole design — a small but real composition gap.

`settings.json:191` already wires a `Stop` hook that plays `Glass.aiff`. MOVE-1's
`session-end-capture.sh` is the *second* Stop hook. Claude Code runs multiple Stop hooks; coexistence is
fine — but the distribution doc ships hooks via plugin `hooks.json` (`${CLAUDE_PLUGIN_ROOT}`) while the
sound-player is a project `settings.json` inline command. So a downstream install gets the capture hook from
the plugin and NOT the sound-player (project-specific). That's correct, but no draft notes that the capture
hook composes with whatever Stop hooks the *consuming* project already has — including possibly another
capture hook if the project rolls its own. Worth one sentence in distribution: "plugin Stop hooks are
additive to project Stop hooks; the capture hook must be idempotent against re-entry." Connects to C5's
double-write concern.

### C7. The "ship empty scaffolds" story and the read-path wiring assume a maturity the fresh install lacks — the loop's read-path surfaces "this recurred 4× here" against an EMPTY S3, so a fresh install's compounding loop is inert until it accrues its own findings, which no draft states as the expected cold-start.

Distribution §2 ships S2/S3 as **empty scaffolds** (schema + writer + clock, no entries). The compounding
loop's read-path (loop §2, memory-model §9) surfaces "you are about to edit X; a finding here recurred 4× in
this area" — but on a fresh install S3 is empty, so the read-path surfaces nothing for weeks/months until the
project accrues ≥1 finding, and the promotion threshold (≥3) means S1 area shards stay empty even longer (the
project authors them from template, but the *promoted-finding* entries that the loop is supposed to feed don't
exist). This is CORRECT behavior — you can't inherit another project's traps (the anti-phantom guard,
distribution §2 "must not inherit another project's traps") — but it means **the compounding loop's
value is zero on day one of a new install and ramps slowly**, and nothing in the validation gate (§5, the
3-install gate) accounts for this. The gate's condition (3) is "≥1 skill ran and produced correct output" —
it does NOT test that the compounding loop compounds, because on a fresh install it provably can't yet. So the
3-install validation validates everything EXCEPT the V2 thesis (the loop). The design ships its central
mechanism in a state where its own acceptance gate cannot exercise it.

**Recommendation.** State the cold-start explicitly as expected, and add a note that the compounding loop is
validated on event-vendor (the mature install, Step 2 dogfood) not on the fresh installs — i.e. the loop's
acceptance evidence comes from the dogfood, the README's acceptance comes from the fresh installs, and these
are different validations. Currently §5 blurs them. Cheap honesty fix; prevents a false "we validated the
loop on 3 installs" claim later.

### C8. `reference_*` aside, the corpus's "52 files" auto-memory count is already stale to disk's 50+MEMORY.md — a tiny instance of the exact rot the design is built to prevent, in the design's own numbers.

Noted for the record because it's thematically load-bearing: the design repeatedly cites disk re-verification
as its discipline (and is right to). Its own auto-memory count drifted by 2 between drafting and this review.
Not a flaw in the architecture — but it is direct evidence that the *prose-inventory drift* the drift detector
targets is real and fast, which strengthens the case for C1's resolution (a generated, not hand-counted,
source of truth). Use it as supporting evidence in the decision package, not as a finding against the design.

---

## Summary of the integration picture

The design composes into ONE system at the level that matters most: the two RECONCILIATIONs already caught the
cross-artifact budget double-count, and the load-bearing seams I attacked hardest (the auto-memory authority
ordering riding to a downstream cache the author never saw; the forced plugin/template split) genuinely hold.
The architecture is coherent.

The leaks are at the **mechanism-interaction** seams that sit between drafts and that no single-artifact
checker owned:
- **gen-rules.sh ⊗ drift-detector** (C1): generated-projection and surface-never-auto-edit cannot both govern
  the same files without a named, retained source — and the design deleted the source.
- **de-dup signature ⊗ three MOVES** (C2): one word, three meanings, one uncovered disk prefix; the signal
  that powers conflict-resolution and graduation is under-specified and incomplete.
- **memory-dedup ⊗ two-vehicle distribution** (C3, C4): the split re-duplicates the KEEP-VERBATIM safety
  floor and the entry schema across an ownership boundary `/plugin update` cannot cross — undoing MOVE 3's
  central win for the highest-stakes content.
- **Stop-hook second-writer ⊗ /cr Step 3b ⊗ .cr-ok relocation** (C5): three MOVES touch one skill region;
  the second emitter can double-write through the promotion gate the design most wants to protect.

None is fatal. All are fixable with the specific, cheap closures named above (define the source; define the
signature once; pick one home for the safety floor; ship the schema as one artifact; make the emitters
idempotent). Fix C1 and C2 before any build — they reintroduce the precise failure classes (phantom mechanism,
forgeable promotion gate, drift) the whole V2 exists to eliminate. C3–C5 before the second install, where the
vehicle seam first bites.
