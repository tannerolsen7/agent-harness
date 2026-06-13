# Phase 6 Lens — BUDGET-SIMPLICITY (the "simple & boring is a feature" / two-budget line for the WHOLE V2)

**Lens charge.** Hold the two-budget line for the *integrated* V2 design (Phases 3+4+5 together). Sum the
aggregate budget-(2) delta; test whether it is defensible *in total*; apply the MOVE-4 deletion engine to
the proposal set itself (cut/merge mechanisms without losing a failure mode); and test whether budget (1)
*actually* falls or is just relocated into shards the agent still reads.

**Method.** Read all three reconciliations (authoritative) + the three Phase-3 drafts + the two Phase-4/5
drafts + MASTER-FINDINGS + capability-facts. Ground-truthed every load-bearing disk claim myself
(2026-06-11): `.claude/rules/` ABSENT; hooks = 5 on disk (→7 proposed); scripts = 8 (→11 proposed); skills
= 26 dirs (→25); `PITFALLS.md` = 574 lines / 37 `**Area:**` fields; `reviewer.md` passes `PITFALLS.md` to
4 lens agents in parallel (lines 18/19/32 verified); `ci.yml` = 4 steps, no sentinel/eval lane; **zero**
skills carry `disable-model-invocation` or `paths:` today. Disk agrees with the corpus.

**Verdict: CONCERNS.** The aggregate budget-(2) is honest in *magnitude* and every line item names a §9
failure mode — I could not find a phantom or a rejected-pattern rebuild in the build set, and I attacked
that hardest. But the two-budget *ledger itself is mis-kept*: the rule shards are double-classified, booked
as budget (2) "out-of-band, unforgeable" in the authoritative RECONCILIATION §A while being booked as
"NEW knowledge files the agent reads" in the file tree. They are budget (1). That misbooking is not
cosmetic — it is the exact favorable-proxy substitution the two-budget rule was written to forbid, committed
by the very table that defines the rule. Once corrected, budget (1) still net-falls (I verified the
arithmetic), so the design survives — but the decision package must state the corrected ledger, or it ships
the same self-flattering accounting V1 died of. Two real merges are also available in budget (2).

---

## 1. The aggregate budget-(2) delta — is it defensible in total?

**Stated aggregate (phase45/RECONCILIATION line 43): ≈ +16 to +20 out-of-band files/mechanisms.** I
re-enumerated it line-by-line against the source artifacts:

| Phase | Items | Count |
|---|---|---|
| **3** | `block-dangerous-bash.sh`, `session-end-capture.sh` (hooks); `scan-context.sh`, `migration-lint`, `repo-structure` (CI scripts); `gen-rules.sh` (generator); `dependency-cruiser` (dev-dep + config); ~5–6 rule shards; `.cr-ok`→CI + `/cr-security` classifier (2 CI jobs); commitlint hook | **~+9–11** |
| **4** | `plugin.json`, `marketplace.json`, `hooks/hooks.json`, `harness-manifest.json`, `VERSION`/CHANGELOG, `gen-manifest.sh` | **~+4–6** |
| **5** | `cr-golden/` corpus, `score-cr-eval.sh`, `/cr-eval` skill (now); `cr-eval.yml` lane (later) | **+3 now, +1 later** |

The +16–20 is **arithmetically honest** and I will not dispute the magnitude. The harder question the lens
owns: **has V2 quietly become mechanism-heavier than V1 in a way the per-phase §9 justifications miss in
aggregate?**

**Answer: no aggregate phantom, but one aggregate accounting failure.** I ran the §9 survivor test across
the *whole* build set looking for the failure the per-phase reviewers would each miss — a mechanism that is
§9-justified locally but redundant once you see the other phases' builds. I found **two genuine merges**
(§3) and **zero phantoms** (the build set never rebuilds something that exists per MASTER-FINDINGS §E, never
resurrects a §F rejected pattern — I checked each of the ~18 items against both lists). So the magnitude is
defensible *after* the two merges trim it to roughly **+14–18**. The defensibility problem is not the count.
**It is that the count is split into the two budgets incorrectly, and the misbooking inflates the "budget
(1) falls / budget (2) §9-gated" story into looking cleaner than it is.**

---

## 2. MUST-FIX — the rule shards are misclassified; the two-budget ledger is mis-kept

This is the topConcern. The two-budget rule (RECONCILIATION-phase3 §A) defines the budgets precisely:

- **Budget (1)** = "Files the agent *reads* as forgeable prose every session" — "the real V1 disease.
  Forgeable, attention-costing."
- **Budget (2)** = "Hooks, CI scripts, lint/dep-cruiser configs, **path-scoped shards** — run *outside* the
  agent's context, unforgeable" (line 42, verbatim).

**The shards are in budget (2) per the authoritative §A table. They belong in budget (1).** A
`.claude/rules/migrations.md` shard is markdown the agent **reads** via native `paths:` auto-load. The agent
can read it and ignore it — it is exactly as **forgeable** as the `PITFALLS.md` prose it was split from. It
is *not* "run outside the agent's context"; being loaded into the agent's context is the entire point of a
`paths:`-scoped rule. Calling it "unforgeable enforcement" is false: nothing about a markdown rule is
enforced — enforcement is what the *hooks and CI scripts* (the real budget-2 items) do. The shard is the
**teaching copy**; the migration-lint CI script is the **enforcement**. The design itself says this in
enforcement-sort §5 ("the shard is the *teaching* copy at the agent's pre-write moment" vs "the rules CI
*enforces*") — and then the §A budget table books the teaching copy as if it were the enforcement.

**This is corroborated by the design contradicting itself across artifacts:**
- `target-file-tree.md` lines 17, 286, 395: the 8 shards are **"NEW knowledge files"**, "the entire
  sanctioned net-new *knowledge-file* addition," counted in the knowledge-file (budget-1-class) ledger.
- `RECONCILIATION-phase3 §A` line 42 + §E line 186: the shards are budget **(2)**, "out-of-band... outside
  the agent's context, unforgeable."

The *same artifact* cannot be both a knowledge file the agent reads and an out-of-band mechanism outside the
agent's context. One of the two reconciliation/tree pairs is wrong, and §A is the one that's wrong.

**Why this is MUST-FIX, not pedantry.** The two-budget rule exists *specifically* to stop a budget-(1)
proxy being presented as a total win (that is the §A meta-finding: "memory-model headlined stores 6→3 while
adding ≈+9 files... Each checker caught it"). Booking the shards as budget (2) commits the identical
substitution at the reconciliation level: it moves ~5–6 *read-prose* files off the budget that is supposed
to fall and onto the budget that is allowed to grow, making budget (1) look like it falls more than it does
and budget (2) look like pure unforgeable-enforcement growth when ~6 of its items are actually forgeable
prose. **The favorable proxy the rule forbids is baked into the ledger that defines the rule.**

**Recommendation.** Re-book the rule shards into budget (1). Restate §A's budget-(2) row to list only the
genuinely out-of-band items (hooks, CI scripts, lint/dep-cruiser configs, manifests, packaging) and strike
"path-scoped shards" from it. Then re-run the budget-(1) ledger honestly (§2a below). The design still
passes — but it passes on a true ledger, which is the whole point.

### 2a. Does budget (1) *actually* fall once shards are booked correctly? — I attacked this hardest; yes, it does

The lens's sharpest required attack: *is some "deleted" prose just relocated into shards the agent still
reads?* I built the corrected budget-(1) ledger:

**Removed from budget (1):** `PITFALLS.md` (574 L, today read *wholesale* and passed to 4 `/cr` lenses in
parallel ≈ 172 KB/review — verified); `memory.md` (166 L, always-read); the CLAUDE.md terminal NEVER-list
section (~16 L); and copies-per-fact 3→1 (the same corrected-mistake fact stops living in memory.md +
PITFALLS + auto-memory simultaneously).

**Added to budget (1):** `00-safety.md` (always-loads — it *is* read every session); the 6 path-scoped area
shards (`migrations`, `data-layer`, `schemas`, `auth-routing`, `architecture`, `harness-hooks` — read 1–2
per task, on their path only); and the `/cr-eval` skill description line **unless** `disable-model-invocation`
is set (Phase 5 §A correctly closes this to 0).

**Net verdict: budget (1) net-falls — but via a different mechanism than §A claims.**
- `00-safety.md` always-loads, but it absorbs the *deleted* NEVER section + memory.md safety text, so the
  always-load surface is **flat-to-slightly-down**, not up.
- The 6 area shards are the real lever: the agent reads **1–2 on their path** instead of **all 574 PITFALLS
  lines on every code task**. Per-task read budget falls hard; the 172 KB/`/cr` lens cost collapses.
- Copies-per-fact 3→1 is real and load-bearing.

So the relocation worry is **answered — budget (1) genuinely falls** — but the *reason* is "path-scoping
cuts per-task read load," **not** §A's claim that the bytes move "OUT of forgeable prose INTO unforgeable
enforcement." For the shards, the bytes stay *in* forgeable prose; they just load less often. That is still
a real win (it is the single biggest read-budget reduction in the whole design), but it must be stated as
*what it is*. **MUST-FIX: correct the §A mechanism claim for the shards from "moved to unforgeable
enforcement" to "path-scoped to load 1–2-per-task instead of all-558-always."** The win survives the honest
restatement; the false mechanism claim does not.

---

## 3. SHOULD-FIX — two genuine budget-(2) merges (apply MOVE-4 to the proposal set)

I ran the deletion engine on the build set itself. Most candidates the brief flagged do **not** collapse
(§4) — but two do:

**Merge A — `gen-rules.sh` + `gen-manifest.sh` → one generator.** Both are the identical I/O class: *walk
the harness on disk → emit a generated artifact from a template* (`gen-rules` emits the `.claude/rules/*.md`
shards from the canonical corpus; `gen-manifest` emits `harness-manifest.json` from
`.claude/{skills,agents,hooks,rules}`). They share the disk-walk, run in the same CI step, and a change to
the rules taxonomy must regenerate both anyway. Keeping them as two scripts is the kind of premature split
the "simple & boring" line exists to prevent. **Collapse to one `gen-harness.sh` with two emit targets**
(or one script, two subcommands). Saves 1 budget-(2) file; loses no failure mode (the manifest's
existence/no-orphan/frontmatter/wiring checks are done by `scan-context`, the *verifier*, not by the
generator). Note: this does **not** merge `scan-context.sh` in — it has a different contract (it *asserts*
and exits nonzero; it never writes), and folding a generator and its own verifier into one script destroys
the doer≠checker separation. Keep `scan-context` separate.

**Merge B — fold `commitlint` into the `repo-structure` CI lane rather than shipping it as a separate
commit-msg hook + dep.** The enforcement-sort lists commitlint (R86) as a net-new git hook **plus** a new
npm dep (RECONCILIATION-phase3 §C.6 flags the dep under ASK-first). A conventional-commit-format check is a
~10-line regex over `git log origin/main..HEAD` subject lines — it fits inside the already-proposed
`repo-structure` CI script (which already greps the tree) with no new dependency and no new hook file.
Shipping `@commitlint/*` + a husky `commit-msg` hook to enforce a regex is exactly the "more machinery than
the failure mode needs" smell. **Recommendation: drop the commitlint dep + hook; add a 10-line subject-line
check to `repo-structure`.** Saves 1 budget-(2) file + 1 dependency (and one ASK-first prompt); loses no
failure mode (malformed history is still caught, in CI, for humans and agents).

These two merges trim the aggregate from +16–20 to roughly **+14–18** with zero coverage loss. Neither is
load-bearing on its own — but the "simple & boring" line is held by taking the cuts that are free, and these
two are free.

---

## 4. CONSIDER — candidates the brief flagged that I tested and did NOT cut (and why)

Honest reporting requires naming what I attacked and *couldn't* break:

- **"Are 5–6 shards + a generator + a drift detector + a manifest all needed, or do some collapse?"** —
  Mostly needed. The generator + manifest collapse (Merge A). The **drift detector (`scan-context`) does
  not collapse** into either — it is the verifier with the opposite exit contract, and it is the single
  mechanism that catches this audit's *own* live failure class (doc-fiction/phantom refs; the audit rotted).
  Cutting it re-opens the failure that motivated the whole effort. The **5–6 shards do not collapse to
  fewer** — the split key is the existing `**Area:**` field (37 entries verified), so the boundaries are
  mechanical, not invented; and RECONCILIATION-phase3 §B.3 already correctly cut the 2 *fake* shards
  (`git-worktree`, the external-tool entry) that had no clean `paths:` glob, folding them into the always-load
  floor. That cut already happened; there is no further free shard merge.

- **"Can gen-rules.sh + scan-context.sh + gen-manifest.sh be one script?"** — gen-rules + gen-manifest: yes
  (Merge A). scan-context: no (doer≠checker; different exit contract). Two-of-three, not three-of-three.

- **"Does the migration-lint + repo-structure + dependency-cruiser trio overlap?"** — **No overlap; do not
  merge.** Three distinct input domains: `migration-lint` reads **SQL text** under `supabase/migrations/**`;
  `repo-structure` reads the **filesystem tree** (file-pairing, layout, error.tsx-per-group, image domains);
  `dependency-cruiser` reads the **import AST/graph** (`src/components` may-not-import `src/data`, no
  `supabaseAdmin` outside the allowlist). No tool can do another's job — an import-graph tool can't read SQL,
  a SQL grep can't see the import graph. Forcing them into one script would be a worse design (one mega-script
  with three unrelated parsers) than three focused ones. **This trio is correctly three mechanisms.** Each
  absorbs many rules (migration-lint = 8 safety-critical migration rules in one script; dep-cruiser = ~10
  import-boundary rules), which is the "many rules per mechanism" consolidation the design correctly claims.

- **"Is the golden-set CI lane premature?"** — Correctly handled. `cr-eval.yml` (the scheduled lane +
  recall-floor regression gate) is explicitly **DESIGN-NOW-BUILD-LATER** (compounding-loop §5, §6), gated on
  the minimal harness producing a baseline number first, with the explicit reasoning that "a floor set before
  baseline data is an arbitrary forgeable gate." That is the correct application of hypothesis-before-
  speculative-build to a mechanism — the lane is *not* in the +16–18 build-now count (it's the "+1 later").
  No cut needed; the deferral is already right.

I attacked the dependency-cruiser hardest as a deletion candidate (it costs a new dev-dep, the only ASK-first
install in the set). I could not cut it: its rules (R9/R10/R76/R123/R126 — layer-boundary and
service-role-bypass) are import-graph-shaped and several are safety-critical and irreversible; neither
ESLint-error nor a filesystem grep can express "module A may not import module B." It earns its dep. The
honest note already in enforcement-sort §4 (ship in report-mode first, then enforce) is the right risk
control.

---

## 5. The one place the design is cleanest on my axis (couldn't break it)

The **§9 survivor pass on the existing roster** (25 skills + 23 agents) is rigorously met and I could not
turn it into a cut my lens would defend. The file tree applied a one-line failure-mode to every survivor,
cut only the genuinely empty `dep-update/` stub, and *tested and rejected* the brief's own "lens/spike agents
are reuse-cuts" hypothesis on disk (the 4 lenses are spawned by `reviewer.md` — I re-verified line 4 + 42–45;
the 6 spike agents by the spike orchestrator). The two soft merge-candidates (`setup-strategy`+`review-strategy`;
`prioritize-tasks` vs `/queue`) are correctly left as *flagged open decisions requiring a body-diff*, not
executed — which is the right discipline (don't blind-merge things that each name a distinct failure mode
today). This half of the design holds the "simple & boring" line correctly: it does not add roster mechanism,
and it resists the temptation to cut wired, load-bearing agents for a cosmetic count win. The budget problem
is entirely in the *new mechanism ledger's bookkeeping* (§2) and two free merges (§3) — not in the roster.

---

## 6. Summary ledger (what the decision package should carry, corrected)

- **Budget (1) — agent-read forgeable prose: NET-FALLS** (PITFALLS monolith + memory.md + NEVER-section
  deleted; copies-per-fact 3→1; per-task read load collapses via path-scoping). **Correct the mechanism
  claim**: the shards fall by *loading 1–2-per-task*, not by "moving to unforgeable enforcement." **Re-book
  the 5–6 shards INTO budget (1)** (they are read-prose).
- **Budget (2) — genuinely out-of-band enforcement/packaging: ≈+14–18 after the two merges** (was +16–20),
  every item §9-justified, zero phantoms, zero rejected-pattern rebuilds. Apply Merge A (gen-rules +
  gen-manifest → one generator) and Merge B (commitlint → fold into repo-structure).
- **Total tracked files: ~flat-to-modestly-up**, which the two-budget rule permits *iff* budget (1) falls
  (it does) and every budget-(2) addition is §9-gated (it is). **The design satisfies the two-budget rule —
  on a corrected ledger.** It does not satisfy it on the ledger as currently written, because that ledger
  misbooks read-prose as out-of-band enforcement, which is the exact favorable proxy the rule forbids.
