# Traceability — `ai-pilling-team-of-one` → V2 design

Source pass-3: `passes/ai-pilling-team-of-one/pass3-apply.md` (section (b) REAL gaps + load-bearing
pass-2 conclusions + (c) caveats that should shape the design). Each gap classified APPLIED / CUT /
DROPPED against the V2 corpus, grounded by grep, not assumption.

The article's verdict was "confirmation, not change." Pass-3's real contribution is four cited gaps,
of which one is a factual correction. The classification below shows: the article's two strongest gaps
(global keystone, phantom correction) are squarely carried; its review-bandwidth design rule is
**registered as a smaller gap but never elevated to the first-class invariant pass-3 demanded**; and
its agent-role-coordination gap is only **partially** carried — one of the three named structural
guards (`branch-registry-guard.sh`) was dropped from every V2 build list.

---

## Per-gap table

| # | Gap / insight (pass-3) | Class | Where in V2 corpus / reason |
|---|------------------------|-------|------------------------------|
| 1 | **"Centralized rules" met at project scope but NOT at global/cross-tool scope — the page's own top idea, unbuilt where it counts.** The canon-mandated `~/.claude/CLAUDE.md` is absent; harness never installed beyond event-vendor. [pass3 b1] | **APPLIED** | This IS the V2-central structural fact. MASTER-FINDINGS **MOVE 5** ("Make the harness installable — never installed beyond event-vendor; no global `~/.claude/CLAUDE.md` [map §0,§2,§8]"). distribution.md treats it as the spine: confirmed greenfield targets, no `~/.claude/CLAUDE.md` (distribution.md:24-25); project-owned files (CLAUDE.md/AGENTS.md) scaffolded via thin `/init` template (distribution.md:65, :194, :223); convergence gate is the v1-ship blocker (distribution.md:234-241); ratified as decision **D2** (REVIEWER-CONSOLIDATION §4). Pass-3 itself recommends "re-derive 'centralized rules' as the argument for `~/.claude/CLAUDE.md`" — carried. |
| 1b | **Cross-TOOL nuance** (authors mean rules that work across Cursor/Claude Code/Devin, not just one repo). [pass3 b1; pass2 §5] | **CUT (deferred §C, reasoned)** | The cross-tool surface is consciously deferred, not dropped. MOVE 5 ships **"Claude Code only, one install path"** first, then "validate on 3 installs → *then* add Cursor/npx/UI" (MASTER-FINDINGS:96-97; distribution.md:117-118, :141, :383, :391 "No Cursor/npx/UI work begins until 3 installs are green"). The locked sequence honors converge→ship→3 installs→Cursor (REVIEWER-CONSOLIDATION:154). Reason: hypothesis-before-speculative-build + the canon's locked single-vehicle sequence. Legitimate deferral with a stated gate. |
| 2 | **Review-bandwidth ≥ generation-bandwidth is an unmodeled design constraint** — raising agent output without raising review throughput is net-negative (the +98% PRs / +154% size / zero-DORA finding). Pass-3 recommends *elevating it to an explicit V2 design invariant*. [pass3 b2; pass2 §4 "buries its best idea"] | **CUT (smaller gap §D, reasoned)** | Registered, not elevated. MASTER-FINDINGS **§D** lists "review-bandwidth ≥ generation-bandwidth as a first-class constraint [C2-G11]" among the cheap-fold-in smaller gaps. cluster-findings-2 G11 frames it identically. **But it is NOT promoted to a first-class deterministically-enforced invariant anywhere** — REVIEWER-CONSOLIDATION never mentions "throughput"; MOVE 6 builds reviewer *recall/measurement* (is `/cr` good enough), a different axis than *review throughput keeping pace with generation*. The §D filing is the reason it's CUT-not-DROPPED, but see DROPPED #2a for the missing-nuance residue. |
| 3 | **Agent-role coordination (Pillar 3, reframed) is a present problem with PARTIAL coverage** — the page's skip-list would defer building structural guards the map flags absent: `branch-registry-guard.sh`, `enforce-scope.sh`, `session-end.sh`. The agents are the team; coordination is live. [pass3 b3; pass2 §2] | **APPLIED (partial)** | Two of three guards carried: **`session-end.sh`** → MOVE 1 `session-end-capture.sh` (target-file-tree.md:95, :371; compounding-loop.md:64; REVIEWER-CONSOLIDATION M2). **`enforce-scope.sh`** → MOVE 2 resolution (c), the `/cr-security` path/glob classifier in CI (enforcement-sort.md:76, :303-305). The "agents-are-the-team / coordination is present-tense" reframe is recorded in cluster-findings-2:247. See DROPPED #3a (branch-registry guard) and #3b (scope-spec reader) for the missing pieces. |
| 4 | **The page validates us against a phantom — factual correction.** It cites `learned-patterns.md` as our built compound-engineering artifact; that file is a §6 phantom (never built). Drop the validation; real mechanism is `/compound` (real) + a *read-path*, not a file. [pass3 b4; pass2 §3] | **APPLIED** | Explicitly honored. MASTER-FINDINGS **§F** reject: "**Build `learned-patterns.md`** (×3 articles) — confirmed phantom [map §6]; the gap is a *read-path*, not a file." REVIEWER-CONSOLIDATION anti-dup gate §1: "`learned-patterns.md` not built (read-path instead)" — listed as zero rejected-pattern rebuilds. MOVE 6 builds the read-path (compounding-loop). The correction shaped the design exactly as pass-3 asked. |
| 5 | **(c) caveat: "team of one = one human" is a category error** — the harness orchestrates an agent fleet; coordination IS the problem. [pass3 c1; pass2 §2] | **APPLIED** | This reframe is the justification baked into Gap-3's carry. cluster-findings-2:247 records it verbatim as the article's correction. It is load-bearing for keeping the 23-agent roster + coordination guards rather than dismissing them (anti-phantom roster kept, §F "Collapse 23 agents → skills" rejected). |
| 6 | **(c) caveat: confirms against unverified/phantom artifacts ("enforced specs" claim asserted without citation).** [pass3 c2; pass2 §3] | **CUT (no action owed)** | The phantom half is Gap 4 (APPLIED). The "enforced specs-as-code" half pass-3 itself marks "plausible but unaudited / unverified, not confirmed" (pass3 a3). MASTER-FINDINGS §E lists `docs/specs/` as existing but does NOT claim a spec→adversarial-review *enforcement chain* — so the design correctly does NOT inherit the unverified claim. No build owed; consciously not asserted. |
| 7 | **Disciplined recommendation: do NOT re-research; locate/cite the internal "Svpino R1 / DORA" finding inside our own records (the throughput evidence is ours, an artifact to reconcile not research).** [pass3 d] | **DROPPED** | See DROPPED #2b — the owed internal-records reconciliation action has no home in any design doc. |

---

## (a) Consciously cut — legitimate, with reason

- **Gap 1b (cross-tool / Cursor / Devin scope):** deferred §C — behind the 3-install gate, per the
  canon's locked sequence + hypothesis-before-speculative-build (distribution.md:383,:391).
- **Gap 2 (review-bandwidth invariant):** registered §D as a cheap fold-in [C2-G11]. CUT-not-DROPPED
  because it IS in the synthesis — but pass-3's specific ask ("ELEVATE to an explicit first-class
  invariant") was downgraded to a smaller-gap line (residue → DROPPED #2a).
- **Gap 6 (unverified "enforced specs" claim):** consciously not asserted; §E records `docs/specs/`
  existence without the unverified enforcement chain. No action owed.

## (b) REAL gaps (DROPPED — not in synthesis, not in design, not consciously cut)

- **#3a — `branch-registry-guard.sh` + `active-branches.json` dropped from every V2 build list.**
  Pass-3 Gap 3 names this as one of three absent structural guards the article's skip-list would
  wrongly defer. Grep result: `branch-registry-guard.sh` appears ONLY in (i) `capability-facts.md:74`
  / CHECK files confirming it ABSENT, and (ii) `cluster-findings-4:188` as a *recurring-upkeep-cost*
  caution ("cheap to write, expensive to keep correct"). It is **NOT a build item in MOVE 1/2,
  enforcement-sort.md, target-file-tree.md, RECONCILIATION, distribution, or any phase-6 decision.**
  Branch-ownership coordination across the parallel-agent fleet is named as a live present-tense
  problem (pass2 §2) but has no carrier. The other two guards landed; this one silently did not.
  *Where it should go:* MOVE 2 enforcement-sort (an L1/CI branch-ownership guard), or an explicit
  §C-deferral with a stated reason (currently it is neither built nor consciously deferred — only
  flagged as expensive-to-maintain, which is not the same as a disposition).

- **#3b — The scope-spec READER half of `enforce-scope.sh` is dropped; `TASK-TEMPLATE.md` is deleted
  with its payload, not retargeted.** The CI path/glob classifier (resolution c) is carried, but the
  *machine-readable per-task scope spec* (`## ALLOWED FILES`, the thing `enforce-scope.sh` was
  designed to read) is a DELETE-CANDIDATE (target-file-tree.md:77,:296): "If MOVE-2 ever builds
  `enforce-scope.sh`, a ~2 KB scope spec is reborn then." So the V2 design carries security-diff
  scope enforcement but NOT per-task file-scope isolation — a real piece of the multi-agent
  scope-isolation coordination pass-3 flagged. *Where it should go:* note explicitly in MOVE 2 that
  per-task file-scope isolation is deferred (not just inert-doc-deleted), so it isn't lost.

- **#2a — Review-bandwidth was registered but NOT elevated to the first-class invariant pass-3
  explicitly recommended.** Pass-3 recommendation (ii): "elevate review-bandwidth ≥
  generation-bandwidth to an explicit V2 design invariant given the advisory-floor / CI-sentinel
  gaps." The design files it as a §D smaller gap and never states an invariant binding multiplier
  scale (`/queue`, 23 agents) to review/verification capacity. MOVE 6's recall harness measures
  reviewer *quality*, not reviewer *throughput-vs-generation*. The specific nuance — "a harness that
  raises generation without raising review throughput is net-negative" as a design constraint on the
  multiplier itself — is the dropped residue. *Where it should go:* a one-line invariant in
  MASTER-FINDINGS §A spine or the compounding-loop measurement design.

- **#2b — The owed internal-records action ("locate/cite the Svpino R1 / DORA finding") has no
  home.** Pass-3 §(d) and cluster-findings-2:306 both name this as an internal-records reconciliation
  the corpus owes (the throughput evidence is cited as *ours*, not the authors'). No design doc
  carries a TODO/action to find and cite it. *Where it should go:* a carry-forward ledger entry or a
  one-line action in the compounding-loop measurement section, so the claim isn't left resting on an
  un-located internal artifact.

## (c) Already-built confirmations (pass3 §a) — no action, correctly not re-proposed

Project-layer centralized rules (CLAUDE.md/AGENTS.md), `/compound`, `docs/specs/`/`docs/adr/`,
pre-commit/pre-push/`/cr`/CI guardrails, background-agents-behind-gates — all in MASTER-FINDINGS §E
anti-phantom list. The Cultural pillar (champions/board-case) maps to nothing and is correctly
skip-able for a solo operator (pass3 b note) — no carrier needed, not a miss.

---

## Counts

- **Distinct gaps/insights raised by this pass-3:** 7 (4 from §b, 3 load-bearing §c/§d conclusions).
- **APPLIED:** 4 (Gaps 1, 3-partial, 4, 5).
- **CUT (reasoned defer/reject):** 3 (Gap 1b deferred, Gap 2 registered-§D, Gap 6 not-asserted).
- **DROPPED (real misses):** 4 residues — #3a (branch-registry guard), #3b (scope-spec reader),
  #2a (review-bandwidth invariant not elevated), #2b (Svpino-finding location unowned).

Note: Gaps 2 and 3 are split — the *mechanism* is carried (CUT/APPLIED) but a *key nuance* of each is
DROPPED, per the strict rule. Gap 1 splits into 1 (APPLIED) + 1b (CUT-deferred).
