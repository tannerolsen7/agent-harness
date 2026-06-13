# Traceability — "Basis monorepo (deep)" pass-3 → V2 design

**Source:** `passes/basis-monorepo-deep/pass3-apply.md` §(b) REAL gaps (6 cited) + the load-bearing
pass-3/pass-2 conclusions and §(c) caveats that should shape the design.
**Method:** each distinct gap/insight classified APPLIED / CUT / DROPPED against the V2 corpus
(MASTER-FINDINGS, phase3/phase45/phase6 reconciliations, V1-TO-V2-CARRYFORWARD, enforcement-sort,
target-file-tree, distribution, compounding-loop). Every classification grounded by grep, cited inline.

The article's own framing (pass-2 §H, pass-3 §d): the **transplantable kernel** is (i) the
canon/not-canon authority cut, (ii) the push-vs-pull context distinction, (iii)
self-consistency-as-invariant (canon as unit-testable prose), and (iv) instruction-not-description
authoring; the **non-transplantable shell** is the scale-amortized daily-worker automation, the
100-nested-file scaling story, and the dedicated-team supply. Pass-3 grounds each gap to a ground-truth
row and declares "mostly no — synthesize, don't re-research."

---

## Per-gap classification

| # | Gap / insight (pass-3 §) | Class | Where it lands (or why not) |
|---|---|---|---|
| 1 | **No canon/not-canon authority taxonomy — and our memory model is the exact corpus that needs it; the triple-duplication the canon both sanctions and forbids (same fact in memory.md + PITFALLS + auto-memory `feedback_*`) has no ontology to collapse it** (§b1, the Phase-3 crux) | **APPLIED** | MOVE 3 is precisely this. "Unify the memory model (one writer / one reader / one freshness rule per store)… triple-duplication the canon both sanctions and forbids… collapses duplication in *tooling* not prose" [MASTER-FINDINGS:71–76]. Copies-per-fact **3→1** [phase3/RECONCILIATION:55,193; phase6/REVIEWER-CONSOLIDATION:124]. The authority cut is materialized as `entry-as-atom` (`tier:`/`kind:`/`freshness:` per-entry) + the explicit precedence rule "on conflict, curated stores win / auto-memory outranked by S1–S3" [phase3/RECONCILIATION:108–110; D3]. Self-consistency-as-invariant (pass-2 §B — canon as unit-testable prose) is the `/scan-context` drift detector: doc-stale AND doc-fiction AND decay, a CI check (R65 L3→L1-CI) [MASTER-FINDINGS:77–79; enforcement-sort R65 line 169]. Directly carried; the article's load-bearing principle is the load-bearing MOVE. |
| 2 | **Declared-canon-vs-verified-canon is unmodeled (pass-2 §G third state); ground-truth proves the rot is real — the audit artifact itself rotted (4 stale absence-claims), Basis's staleness/contradiction failure mode occurring inside our own canon with no scanner to catch it** (§b2) | **APPLIED** | This is the design's *most-cited* live failure class. "doc-fiction (phantom refs are our *live* failure class; the audit itself rotted, map §0)" [MASTER-FINDINGS:77–78]. The `/scan-context` drift detector is built precisely to catch the declared-but-rotted state — three pointer-integrity assertions + stale-glob + decay, deterministic CI, blocks merge [memory-model-candidate-c:292–313; memory-model.md:386]. The harness-manifest convergence gate (distribution §3b) operationalizes the declared-vs-verified split at the *inventory* level: "every manifest path resolves on disk… every disk skill/agent/hook appears in the manifest… canon-documented skill either exists on disk or is flagged `status: deferred`" [distribution:257,282–288]. The third state is modeled and given a scanner — exactly pass-3's prescription. |
| 3 | **No automated context-maintenance loop — but the sized gap is the LIGHTWEIGHT tier (manual/periodic consistency check + owner/last-verified frontmatter), NOT the full daily-agent automation, which is scale-amortized and unjustified for a single-project harness** (§b3 + the pass-2 §C1 amortization correction) | **APPLIED (lightweight tier) / CUT (daily-worker tier, §F reject)** | The lightweight tier is built: `/scan-context` runs **every push + a weekly ritual**, not a daily worker [V1-TO-V2-CARRYFORWARD:23; compounding-loop:24]. The drift detector asserts pointer-integrity/freshness on repo-resident stores in the existing `ci.yml` lane — no standing daily agent [memory-model-candidate-c:308; enforcement-sort R65]. The decay clocks (180d/365d/30d) + phantom-ref detector are the periodic consistency check [target-file-tree:427]. **The daily-worker shell is consciously rejected** as scale-amortized: the dev-container/VM/microVM stack is "wrong threat model at solo scale" [MASTER-FINDINGS §F line 177] and the §9 "name a failure mode or it's overhead" engine (MOVE 4) is the explicit guard against inheriting amortization-derived machinery. **See DROPPED #1** — the *owner/last-verified frontmatter* half of the lightweight tier is the one piece pass-3 names that is not concretely carried. |
| 4 | **No diff-scoped `verifier` that closes inside the task — `/cr` runs at feature end (9 passes + adversarial), CI never verifies `.cr-ok` (the Node 8.5c gap); there is no in-loop, pre-human, diff-scoped test/hook runner; re-grounded to today's `/cr` + `/tdd`** (§b4) | **APPLIED** | Both halves land. The forgeable-`.cr-ok`/CI hole is MOVE 2's most-cited cluster-2 gap: "Relocate the forgeable stop authority to CI — `.cr-ok` is model-computed and never verified by CI… New stop authority = MUST-FIX=0 AND CI-required-checks-green on the sentinel SHA, enforced in CI/branch-protection where the model can't forge it" [MASTER-FINDINGS:56–59; enforcement-sort R66/R68/R69, resolution (b)]. The in-loop diff-scoped verifier is MOVE 1's task-completion gate: "machine-enforced verification gate at task-completion [C1-G2, C4-G3]" via the Stop/PostToolUse hook surface that "CAN run tests and block-on-red" [MASTER-FINDINGS:34–44]. Constraint carried verbatim: the gate "buys regression-trust, not correctness-trust — must NOT write `.cr-ok`" [MASTER-FINDINGS:44]. The `.cr-ok` unforgeability mechanism is sharpened in phase6 S5 (CI mechanizes the lane that already exists; judgment passes accepted as coverage-bounded) [phase6/REVIEWER-CONSOLIDATION:83–85]. |
| 5 | **No unified external-context MCP for in-task debugging — global MCP is `notion` only; no single server exposing GitHub issues + Supabase logs + analytics for an agent mid-debug; severity LOWER for us (single project), frame as targeted, defer until a 2nd project exists** (§b5 + §d exception 2) | **CUT (deferred, §C, with reason)** | Registered-not-built, exactly as pass-3 scopes it. "**MCP trifecta gate** [C3-G11] — registered, scoped small, deferred behind the §9 re-audit / a build decision" [MASTER-FINDINGS:127–128]. The deferral reason matches the article's own ("defer until a second project exists" / build-what's-needed-now): pass-3 §d says "No external research warranted now; it would be premature." Distribution treats `mcp.md` as PROJECT-owned with the Playwright-rejected decision local, and a plugin "MAY ship an `.mcp.json` *shape*, but the decisions stay local" [distribution:196] — i.e. the unification is a future plugin-registry shape, not a v1 build. Consciously deferred with stated reason. |
| 6 | **No root-file token-budget discipline — `CLAUDE.md`/`CONTEXT.md` (15 KB) are auto-context with no default-no / instruction-not-description audit ever run; the real action is separating PUSH-context (audit hard for default-no) from PULL-context (must be correct, need not be small)** (§b6 + pass-2 §D) | **APPLIED (push/pull distinction + path-scoping) — one nuance DROPPED** | The push-vs-pull distinction is the conceptual backbone of the two-budget reframe: budget (1) = "files the agent *reads* as forgeable prose" [phase3/RECONCILIATION:39–53]; the M1 correction re-books the rule shards as budget (1) and states the win mechanism in pull-context terms — "shards load 1–2 per task (on their path) instead of all ~574 PITFALLS lines on every code task" [phase3/RECONCILIATION:47–51; phase6/REVIEWER-CONSOLIDATION:42–44]. Path-scoped `.claude/rules/` IS pull-context done right (correct-when-relevant, not pre-loaded). The line-count fetish is rejected and replaced with the right principle: "tier by *trigger-existence*, not line-count" [MASTER-FINDINGS:83,172]. CLAUDE.md is KEEP-TRIM with concrete cuts [target-file-tree:133]. **The DROPPED nuance:** the *push-context default-no audit as a discipline* against the always-loaded root files — specifically `CONTEXT.md` (15 KB), which pass-3 names by size — is not carried: CONTEXT.md is flatly **KEEP** with no audit row [target-file-tree:136]. See DROPPED #2. |

---

## Load-bearing pass-3/pass-2 conclusions and §(c) caveats (each must shape the design)

| # | Conclusion / caveat (pass §) | Class | Where it lands (or why not) |
|---|---|---|---|
| 7 | **§c — No control for model improvement; the 5x/2.5x is uncontrolled (three months of context work overlaps three months of model gains); "our v2 should NOT adopt a Basis mechanism on the strength of these numbers alone"** (pass-3 §c1, pass-2 §E — the single biggest evidentiary weakness) | **CUT (reject-as-literal, §F, with reason)** | The numbers are explicitly refused: "**Import the ROI/recall numbers** (80% self-written… 5x/2.5x… ) — single-source/uncontrolled/self-disowned; **adopt mechanisms, never rates**" [MASTER-FINDINGS:175–176]. The model-improvement confound is *operationalized* into MOVE 4 (the §9 re-audit on Opus 4.8) and MOVE 6's never-import-rates rule: "Neither imports the corpus's disowned ROI/recall rates… adopt *mechanisms*, never *rates*… measured locally, from this harness's own runs" [compounding-loop:299–304]. The caveat shaped the design (local measurement only), not merely got cut. |
| 8 | **§c — Interoperability is asserted but only format-deep; layers 4–5 (roles + MCP) are current-harness-shaped; "symlink AGENTS.md" decouples vocabulary not architecture; don't inherit interop as "achieved"** (pass-3 §c2, pass-2 §F) | **CUT (caveat honored — design does NOT over-claim portability)** | The V2 design explicitly does NOT claim vendor-interop as achieved: distribution is Claude-Code-plugin-only for v1, with "**No Cursor/`.codex`/UI** — deferred behind the 3-install gate" [distribution:141; MASTER-FINDINGS:97 "one install path… *then* add Cursor/npx/UI"]. The roster/MCP architecture is treated as Claude-Code-shaped and kept as such (23 portable *roles*, but shipped via a CC plugin, not a vendor-neutral format) [distribution:189]. So the caveat is honored by *deferring* multi-vendor interop, not by inheriting Basis's principle-4 as done. The honest downgrade ("format-level only") is the operative stance. |
| 9 | **pass-2 §C — amortization masquerading as principle: the daily-scanner/daily-worker economy is justified by volume; a reader at lower volume inherits pure overhead; the monorepo/100-nested-file and dedicated-team preconditions are non-transplantable** (pass-2 §C1/C2/C3, pass-3 §a scope note) | **CUT (reject-as-literal / non-transplantable shell, with reason)** | The non-transplantable shell is consciously excluded. Daily-worker automation → lightweight tier (gap #3). The monorepo nested-`AGENTS.md` scaling story is N/A at single-package scale and is not adopted (the design uses `.claude/rules/` `paths:` shards, the single-project analogue) [phase3/RECONCILIATION §B.3]. Dedicated-team supply → the §9 engine ("name a failure mode or it's overhead," MOVE 4) is the explicit discipline against inheriting machinery sized for a company we aren't [MASTER-FINDINGS:85–91]. The "estimation: harness-first cadence" + hypothesis-before-speculative-build rules are the standing guard. |
| 10 | **pass-3 §a — the curator's "Equal — we enforce scope per task" rating is half-true: `enforce-scope.sh` is canon-declared (TASK-TEMPLATE ALLOWED FILES) but NOT confirmed on disk** (§a scope-enforcement caveat) | **CUT (partially) — flagged, not built; same TASK-TEMPLATE seam as 12-factor's F10 miss** | The declared-vs-disk gap for `enforce-scope.sh` is named: it is "canon-declared but… in the 'declared, NOT on disk' registry." The file tree records the matching absence: "Its enforcement counterpart `enforce-scope.sh` (which would read `## ALLOWED FILES`) is **ABSENT**" [target-file-tree:77]. This is consciously *not built* (per-task file-scope enforcement stays L3 prose via R71/R91). Caught and registered; not a silent drop. (This is the same TASK-TEMPLATE scope-enforcement seam already flagged DROPPED in `12-factor-agents.md` D1 — cross-listed, not double-counted here.) |

---

## Summary of counts

- **APPLIED:** 4 (gaps #1 authority taxonomy / memory unification, #2 declared-vs-verified canon → drift detector, #4 diff-scoped verifier + `.cr-ok`→CI, and the push/pull mechanism of #6)
- **CUT (consciously rejected §F or deferred §C with reason):** 6 (gap #3 daily-worker tier [reject] while lightweight tier applied, #5 unified MCP [deferred §C], #7 model-improvement confound / import-rates [reject §F → shaped MOVE 4/6], #8 interop-as-format-only [honored by deferring multi-vendor], #9 amortization/non-transplantable shell [reject], #10 `enforce-scope.sh` declared-not-built [flagged])
- **DROPPED (real misses — below):** 2 nuances

Note: gap #3 and gap #6 are split classifications — the dominant mechanism is APPLIED, with one nuance each
landing in DROPPED. Counted as APPLIED in the table above where the load-bearing mechanism is carried;
their missed nuances are itemized below.

---

## DROPPED — real misses

### D1. The lightweight-tier OWNER / last-verified frontmatter — the one piece of gap #3 pass-3 names by mechanism — has no home

Pass-3 §b3 sizes the gap precisely: not the full daily-agent automation (correctly cut as scale-amortized),
but the **lightweight tier = "a manual/periodic consistency check + owner/last-verified frontmatter."** And
§d exception 1 is even more specific: "Owner/last-verified frontmatter + a CI consistency check — before
building, do a *bounded* check of how the existing global Matt-Pocock skills already expect frontmatter, so
we extend their convention rather than invent a parallel one."

- The **CI consistency check** half is fully APPLIED (the `/scan-context` drift detector — gap #2/#3).
- The **owner / last-verified frontmatter** half is **DROPPED.** The corpus's frontmatter work is entirely
  about *invocation-control* frontmatter (`disable-model-invocation`/`user-invocable`/`allowed-tools`) on
  skills [MASTER-FINDINGS §G item 2; phase6/REVIEWER-CONSOLIDATION S4] and `paths:` globs on rules — there is
  **no `owner:` / `last_verified:` frontmatter on the knowledge artifacts** (rules shards, solutions, ADRs)
  anywhere in the memory model, file tree, or distribution manifest. The drift detector checks pointer
  *existence* and *glob non-emptiness*; it does not check a per-doc `last_verified` clock or a per-doc
  `owner`. The decay clocks exist as store-level freshness rules, but the *artifact-level owner/last-verified
  stamp* that pass-3 specifically prescribes — and the bounded "extend Matt-Pocock's existing frontmatter
  convention rather than invent a parallel one" scoping step — appears nowhere.

**Where it should go:** the memory-model store schema (S1 rules / S2 solutions) should add `owner:` +
`last_verified:` to the entry/shard frontmatter, and the `/scan-context` detector should assert a
`last_verified` staleness clock against it (this is the "third state" certification pass-2 §G demands —
declared-canon-passing means *recently re-verified*, not merely *referenced*). The bounded prerequisite (read
the global Matt-Pocock skills' frontmatter convention first, per §d exception 1) should be named as a
pre-build check so the convention is extended, not forked.

**Why it matters:** without a `last_verified` stamp, the drift detector catches *broken* references and
*empty* globs but cannot catch the failure that actually happened to this audit — a doc that is structurally
valid (every ref resolves) but **semantically rotted** (its claims went stale while its links stayed intact).
Pass-2 §G's whole point is that "canon is a liability until the scanner certifies it" — and certification
requires a freshness stamp the design currently lacks. This is the precise mechanism pass-3 sized as the
*real, justified* lightweight-tier gap, and it is the one piece of it not carried.

### D2. The push-context default-no audit discipline against the always-loaded root files (CONTEXT.md / CLAUDE.md) is not carried — only pull-context path-scoping is

Pass-3 §b6 (with pass-2 §D) makes a two-part point: (i) separate push-context from pull-context, and (ii)
**run a default-no / instruction-not-description audit against the push-context** — naming `CONTEXT.md`
(15 KB) and a long `CLAUDE.md` as auto-context that "nothing in the map asserts a default-no audit has ever
run against."

- The **pull-context** half is fully APPLIED: `.claude/rules/` `paths:` shards are correct-when-relevant
  lazy-load, and budget (1)'s per-task read cost falls hard [phase3/RECONCILIATION:47–51].
- The **push-context audit** half is **DROPPED for CONTEXT.md.** CLAUDE.md gets concrete push-context cuts
  (delete the NEVER-section, delete the behavior-principles duplicate) [target-file-tree:133] — so the root
  *process* file is audited. But `CONTEXT.md` (15 KB, the file pass-3 names explicitly) is dispositioned a
  bare **KEEP** with no default-no / instruction-not-description audit: "The 'why' doc (PR #92)… passed to
  lens agents by `reviewer.md`. Keep." [target-file-tree:136]. It is always-loaded push-context AND is fanned
  out to 4 `/cr` lenses (the same ~172 KB multiplier that made the PITFALLS monolith the headline budget-(1)
  cost), yet it never gets the "is this instruction or merely description? does it earn always-load?" pass.

**Where it should go:** the MOVE-4 §9 re-audit (the deletion engine, "name a failure mode the constraint
prevents, or it's overhead") should explicitly include the *always-loaded push-context root files*
(`CONTEXT.md`, and CLAUDE.md's residual prose) in its scope, applying pass-2 §D's instruction-vs-description
test to each — not just the NEVER-list and rules shards. A one-row disposition in target-file-tree for
CONTEXT.md ("audit for default-no / split the instruction half into a path-scoped shard, keep the narrative
half") would close it.

**Why it matters:** push-context is where default-no actually bites (it is taxed on *every* session and
*every* lens pass), and it is the one budget pass-2 §D says to "minimize aggressively." Leaving a 15 KB
always-loaded, lens-multiplied doc as an unaudited KEEP is the exact push-context bloat the distinction was
drawn to prevent — the design fixed the pull-context side (path-scoping) and the process-file side (CLAUDE.md
cuts) but left the named push-context "why" doc unaudited. Low blast radius (one file), but it is a real
traceability miss against an insight pass-3 grounded to a specific 15 KB artifact.
