# LENS: Anti-Duplication — adversarial review of the integrated V2 design

> **Stance.** Doer-not-checker. I attack the integrated design (VISION + the 5 v2 artifacts) for the one
> failure class that would have killed the V1 rebuild: *building something that already exists, rebuilding an
> upheld rejection, or implementing the same mechanism twice under two move-IDs.* I re-verified every "absent
> on disk" claim by direct inspection of `.claude/` this session (the audit artifacts demonstrably rot — R4).
>
> **Gate applied to every surviving build item across VISION + roster.md + file-tree.md + memory-model.md +
> github-usage.md + gaps-risks.md:** (1) PHANTOM — already built / already world-class? (2) REJECTED-PATTERN —
> rebuilds a killlist/F UPHELD rejection? (3) CROSS-ARTIFACT DUPLICATE — same mechanism under two homes/owners?

## VERDICT: **PASS-WITH-MERGES**

The anti-duplication discipline is, on the whole, **excellent** — better than any other axis of this design.
Every NEW skill/hook/CI-file is genuinely absent on disk (I re-verified all of them); every killlist/F UPHELD
rejection is honored, not smuggled; the killlist/E TRULY-WORLD-CLASS items (guard-file lockout #9, the safety
doctrine, the §9 golden rule) are left alone or only *applied* (not rebuilt); and the VISION did real
self-pruning (5 move-IDs demoted to clauses, HOOK-1 collapses 3-4 hooks into one). The "single owner" discipline
for the three highest-risk shared mechanisms is *stated* correctly in the VISION.

But the discipline is **stated, not yet enforced across the artifacts**, and three concrete defects survived the
per-artifact checks precisely *because* each checker saw only one artifact:

1. **One true cross-artifact duplicate of the keystone** (F6 has two different, unreconciled file homes — a job
   in `ci.yml` vs. a new `cr-gate.yml`). This is the exact thing the VISION said is "owned once, never
   re-built," and it is live in the design.
2. **The per-artifact-check MUST-FIX items are NOT folded in** — the charter told me to "verify they are real
   and folded." They are real; they are **not folded.** One of them (roster MF-1) is itself an anti-duplication
   defect: a real built skill silently dropped, which breaks the carry-forward count the manifest/plugin will
   trust.
3. **One near-duplicate** the design dropped from its own roster (an agent referenced by a deleted skill) and
   one phantom *reference* the design itself ships (a dead glob), both of which the design's own CMP4
   reference-integrity check is built to catch — i.e. the design rots in the way it indicts.

None of these is a V1-class catastrophe (no `learned-patterns.md` rebuild, no 200-line diet, no symlink-live, no
collapse-23-agents). They are merges and fold-ins, not rejections — hence PASS-WITH-MERGES. But MUST-FIX-1 must
land before any build, because the keystone is the one mechanism the whole autonomy program rides on.

---

## MUST-FIX

### MF-1 — The keystone F6 has TWO unreconciled file homes across artifacts (the one cross-artifact duplicate that matters)

This is the precise defect the gate exists to catch, on the single most load-bearing move in the design, and it
**survived both per-artifact checks** because each checker only read one artifact.

- `file-tree.md:146` + `:185`: F6 is a **job added to the existing `ci.yml`** — "`ci.yml` [CHG] gains the F6
  STOP-AUTHORITY job." There is **no `cr-gate.yml` anywhere in the file-tree** (verified: `grep cr-gate
  file-tree.md` → zero hits).
- `github-usage.md:238` + `:395` + `:421`: F6 is a **NEW separate workflow file** — "A CI job
  (`.github/workflows/cr-gate.yml`, **NEW**) that…" and it is listed in github-usage's own "no phantom rebuilds"
  paragraph (`:421`) as a genuinely-new artifact.

So the two artifacts disagree on whether F6 is a *modification to a file that exists* or a *new file*, and
**neither references the other.** The VISION is explicit (`VISION.md:91`): "The keystone CI verdict gate is
**owned once** (in THE FLOOR) and referenced — never re-built — elsewhere." Here it is described twice, two
different ways, in two artifacts that both claim to own its implementation. A builder reading file-tree builds a
`ci.yml` job; a builder reading github-usage builds `cr-gate.yml`; a fleet building from both ships two gates or
stalls on the contradiction. The github-usage-check's MF-1 is about the *trust-but-verify framing* of F6 — it
does **not** catch this file-home split (I checked). The file-tree-check's MF-list is budget/routing — it
doesn't catch it either. This is a genuine blind spot between the two passes.

**Why MUST, not SHOULD:** F6 is "the keystone; hard prerequisite for any unattended push" (VISION). Resolving
its interface is also entangled with the still-open **Fork F1** (verdict-artifact surface — Checks API vs
committed file vs PR), which github-usage recommends resolving via the **GitHub Checks API**. A Checks-API
`cr-gate` run is naturally its *own* check, which argues for github-usage's separate-file model; but file-tree
draws it as a `ci.yml` job. **Required correction:** pick ONE home in ONE artifact and have the other reference
it — recommend a dedicated `cr-gate.yml` (matches the Checks-API recommendation, keeps the keystone enforcement
separable and independently-required via branch protection), and change `file-tree.md:146/185` to add
`cr-gate.yml [NEW]` under `.github/workflows/` and drop the "ci.yml gains the F6 job" framing. State once, in the
file-tree's move-landing table, that F6's home is `cr-gate.yml` and `ci.yml` is unchanged except as an input
required-check.

### MF-2 — The per-artifact-check MUST-FIX items are real but NOT folded into the artifacts (the charter's explicit ask)

The charter: *"THE PER-ARTIFACT CHECKS already run … their MUST-FIX must be folded, verify they are real."* I
verified each against disk and against the current artifact text. **They are real and they are not folded.** The
checks live as separate `checks/*.md` files; the design artifacts they critique are unchanged. Three of the
unfolded items are directly in my lens:

- **roster-check MF-1 (an anti-duplication defect): `evaluate-solution` is silently dropped from roster Table
  A.** Verified on disk: `.claude/skills/evaluate-solution/` exists (8.9 KB `SKILL.md`, a real wired skill).
  Verified in the artifact: `grep evaluate-solution roster.md` returns **only the `solution-evaluator` *agent*
  row** (line 167) — the *skill* has no Table-A row, no disposition, no failure-mode line. This breaks the
  roster's own asserted invariant ("all 26 skills carry a failure-mode line") and its "22 KEEP" count (only 21
  enumerated). It is an anti-duplication concern because the P6 manifest, the plugin extraction (P10), and `/init`
  all consume the roster's skill count as ground truth; a dropped real skill = a carry-forward integrity hole =
  the V1 failure class (`/simplify`-wiring-style omission). **Fold:** add the `evaluate-solution` KEEP row.
- **file-tree-check SF-3 (a phantom reference the design itself ships): the `auth-routing.md` shard glob points
  at `src/proxy.ts`, which does not exist.** Verified on disk: the proxy lives at repo root
  (`/Users/tanner/Dev/event-vendor/proxy.ts`), there is no `src/proxy.ts`. Verified in artifact:
  `file-tree.md:79` still reads `paths: app/**,src/proxy.ts,middleware*`. A glob that matches nothing means the
  shard **never auto-loads when the agent edits the proxy** — the "fake shard that doesn't auto-load" failure the
  tree itself warns against (line 46), and a live instance of the doc-fiction class CMP4 exists to catch. **Fold:**
  change to `app/**,proxy.ts`; correct/drop the dead `middleware*` glob.
- **file-tree-check MF-2: the §B.4 BLOCKER's 3 memory-trap routings — only 1 is delivered.** Verified:
  `grep check-branch-before-commit; grep claude-md-referenced-scripts` in file-tree.md → **zero hits** for both;
  only `enforcement-boundary-layering` is routed (line 81). memory.md's deletion is gated on all three being
  routed, so two traps can be silently lost — a duplication-adjacent loss (a fact that exists once, dropped to
  zero). **Fold:** name both routings before the tree is treated as complete.

**Why MUST:** the charter made folding these an explicit deliverable, and roster-MF-1 specifically is an
anti-duplication defect (a dropped real skill corrupts the count three downstream platform moves trust). Either
fold them or, if the design intends the `checks/` files to be a separate resolution pass, state that explicitly
and gate the build on it — do not leave verified MUST-FIX items floating beside unchanged artifacts.

---

## SHOULD-FIX

### SF-1 — `@benchmark-runner` is being *built* in two places under two move-IDs without a single owner

- `roster.md:50` (the `perf` skill row): "**BUILD `@benchmark-runner`** (wire measurement into CI/MCP so the
  agent runs Phase 1/4 itself)."
- `roster.md:79` + `file-tree.md:161,191` (C4 `/cr-calibrate` + `golden-set/`): the calibration corpus +
  recall/FP CI job — also a "benchmark runner," for review precision rather than perf.

These are two genuinely different benchmark harnesses (perf-budget vs. review-recall), which is *defensible* —
but `@benchmark-runner` is a **single named phantom in CANONICAL §6** (`HARNESS-AS-IS §7`), and the design now
resurrects that one name's intent under two owners (`perf` and `C4`) with no statement that they are distinct.
This is the "same mechanism under two move-IDs" shape, half-realized. **Fix:** state explicitly that the §6
`@benchmark-runner` phantom resolves into TWO distinct, separately-owned runners (perf-budget under `/perf`;
review-calibration under `/cr-calibrate`), so the manifest doesn't ship one ambiguous `@benchmark-runner` or two
agents fighting over the name. One sentence; prevents a real downstream collision.

### SF-2 — `scan-context` and `ratchet` are double-homed; one is correct, one needs the fork resolved before build

Both appear under two homes, and the gate must distinguish the legitimate split from the latent duplicate:

- **`scan-context` (CMP4): LEGITIMATE split, leave it** — `skills/scan-context/` (the skill body, detection) +
  `.github/workflows/scan-context.yml` (the P9 CI leg, every-merge reference-integrity). This is the
  VISION-intended skill-body + CI-leg pairing (CMP4 detection P0 / P9 CI P0), not a duplicate. No fix; flagged so
  the record shows it was attacked and held.
- **`ratchet` (CMP2): an unresolved fork carried as "or"** — `file-tree.md:102` and `memory-model.md:210` and
  `VISION.md:472` all say "a `/compound` sub-phase **or** a `/ratchet` skill." That "or" is honest at vision
  altitude but **must be resolved before build**, or you get the duplication this gate polices: a builder makes
  `skills/ratchet/` *and* a `/compound` sub-phase, both classifying findings into deterministic blocks. **Fix:**
  pick one (recommend the `/compound` sub-phase — CMP2 composes with `/compound`'s existing promotion conveyor
  and avoids a side-effect skill that must be F9-gated) and state it once, the way Fork F8 is named for `/lfg`.

### SF-3 — `/lfg`'s "cross-skill reference-integrity check" is the same mechanism as CMP4's fiction-scan — confirm it's one owner, not two

`VISION.md:181` pulls the "cross-skill reference-integrity CI check" out of the `/lfg` 7-guard battery as a
precondition; `file-tree.md:176` routes it to `scan-context/`; `memory-model.md:245` says CMP4 "houses the L5
cross-skill reference-integrity check." This is *correctly* consolidated to one owner (CMP4/scan-context) in the
artifacts — but the VISION text still describes it as an `/lfg` guard ("pulled out as its own move
(CMP4-adjacent)"), which reads as if `/lfg` owns a copy. **Fix:** add a one-line statement in roster/file-tree
that the reference-integrity check is **owned by CMP4 (`scan-context`) and consumed by `/lfg`**, never
implemented inside `/lfg` — matching the F6 "owned once, referenced" pattern. Otherwise the 7-guard battery and
CMP4 each look like they build it.

---

## CONSIDER

### C-1 — The render gate (C8/C10) is three-homed but correctly so; record it held

`verify/` skill + `verify.yml` CI + the `session-end.sh` HOOK-1 "verify-if-present" payload. I attacked this as a
possible triple-implementation and it **holds**: capability-facts.md:18-20 forces exactly this split (a hook
*cannot* compel an artifact → advisory at hook; the hard gate is CI/C8). The three homes are one render check at
three enforcement strengths, not three implementations. No fix; flagged as attacked-and-clean so the next pass
doesn't re-litigate it.

### C-2 — Auto-memory + curated stores: "copies-per-fact 3→1" is the curated count; physical copies = 2

memory-model.md is careful (line 270) but the headline "3→1" coexists with an un-evictable auto-memory cache that
still holds copy #2 (demoted, not deleted). This is not a duplication *defect* (the cache is explicitly demoted
and un-ownable), but downstream docs that cite "3→1" without "(+1 demoted cache)" will drift into an over-claim —
the same budget-honesty class the file-tree-check MF-1 polices. Pair the headline with "(+1 demoted,
un-evictable)" wherever it travels.

### C-3 — `notion-sync` mechanisms "carried forward" need one named receiving home (else they're carried-in-prose-lost-in-practice)

github-usage-check SF-3 already flagged this; I confirm it as an anti-duplication-adjacent risk: the five
transferable mechanisms (comprehensive-diff, guard-file exception, dedicated-branch, LAST-SYNC receipt, sentinel
handoff) are asserted as "carried into the GitHub-canon path" in both roster.md:49 and github-usage.md:67 but
**neither names the file that receives them.** A mechanism carried in two prose descriptions with no concrete
home is how you get it re-implemented twice (in `/compound` Step 8 *and* a canon-PR template). Name the single
home (recommend: the re-pointed `/compound` Step 8 + the canon-PR template it writes).

---

## What I attacked and it HELD (no finding — the discipline that earns the PASS)

- **PHANTOM check — every NEW build item is genuinely absent on disk (re-verified this session).** `ls .claude/`
  confirms: no `rules/`, no `.claude-plugin/`, no `harness-manifest.json`, no `golden-set/`, no
  `block-dangerous-bash.sh`, no `session-end.sh`, and skills `goal`/`lfg`/`verify`/`scan-context`/`ratchet`/
  `cr-calibrate`/`init` all ABSENT. `.github/workflows/` holds only `ci.yml` + `integration.yml` (no `cr-gate`,
  no `summon`, no `scan-context`, no `verify`, no `cr-calibrate`). The roster's "23 agents, 26 skills, 5 hooks"
  is exact. **Zero phantom rebuilds.**
- **PHANTOM check — TRULY-WORLD-CLASS items are left alone, not rebuilt.** killlist/E #9 (guard-file lockout +
  no-agent-edits): the design only *applies* it (as the P9 repair-worker denylist, the `/init` human-handoff) —
  never re-specs it. The §9 golden rule (E #12) is used as the per-item "name a failure mode" discipline, not
  rebuilt. The PocketOS safety doctrine (E #11 doctrine-half) is carried verbatim into `00-safety.md`. Correct.
- **REJECTED-PATTERN check — every killlist/F UPHELD rejection stays dead.** Verified against `F-rejected.md`:
  #1 front-load-trigger-words / 200-line diet → roster rewrites to situational triggers + tiers by
  trigger-existence (honored); #5 no-shared-context reviewer → C2 is explicitly "isolated solution, shared
  canon," reviewer.md keeps the ISOLATION INVARIANT with full canon pre-read (honored); #6 collapse-23-agents→1 →
  roster.md:22,145 calls it "dead," all 23 kept with distinct failure modes (honored); model-confidence
  auto-merge → LOOP-7 is a **non-LLM** classifier, the confidence-score form stays dead (honored);
  `learned-patterns.md` the file → CMP1 builds the read-path, NOT the file; memory-model.md:203-204 + CMP4's
  fiction-scan list it as a phantom to *catch* (honored); symlink-live → P1 is versioned plugin + lock,
  github-usage.md:126 calls symlink-live "the drift it is meant to prevent" (honored); local DinD/microVM →
  realized via cloud sandbox + managed-settings, never a local container (honored); Toolshed registry / Saul
  three-repo machinery → not present (honored). **Nothing resurrected.**
- **CROSS-ARTIFACT check — the three named high-risk shared mechanisms are single-owned in VISION and (mostly)
  in the artifacts.** (a) **The task-manifest:** `harness-manifest.json` is the single declared owner;
  F3/F5/L1/P8 all *reference* it (file-tree.md:121,182,184,211; github-usage.md:304) — no second manifest
  invented. HELD. (b) **The model re-audit:** C13 (one-time) / CMP6 (recurring) / P10 (referenced-only) are
  explicitly de-conflicted in VISION.md:436,722 and file-tree.md:199,205 — P10 "references, doesn't restate."
  HELD. (c) **The CI verdict gate:** single-owner *intent* is stated (VISION.md:91, roster.md:131 "F6 owns the
  boundary; C1/C7/LOOP-7 are consumers, not parallel implementations") — but the *file home* is duplicated
  (MF-1). The principle holds; the execution split is the one real cross-artifact duplicate.

---

## Bottom line for the parent

**PASS-WITH-MERGES.** Anti-duplication is the strongest axis of this design: zero phantom rebuilds (all NEW items
re-verified absent on disk), every killlist/F UPHELD rejection honored, every killlist/E TRULY-WORLD-CLASS item
left alone or only applied, and the three highest-risk shared mechanisms single-owned *in principle*. The blocking
work is small and concentrated: **MF-1** — the keystone F6 has two unreconciled file homes (`ci.yml` job vs.
`cr-gate.yml`) that survived both per-artifact checks because each saw one artifact; pick one. **MF-2** — the
per-artifact-check MUST-FIX items are real but unfolded, and one of them (roster's dropped `evaluate-solution`
skill) is itself an anti-duplication / carry-forward defect that corrupts the skill count the manifest, plugin,
and `/init` will trust. Fold MF-2, reconcile MF-1's one home, resolve the `ratchet` fork (SF-2) and the
`@benchmark-runner` two-owner ambiguity (SF-1) before the manifest is serialized, and the design is clean on
duplication.
