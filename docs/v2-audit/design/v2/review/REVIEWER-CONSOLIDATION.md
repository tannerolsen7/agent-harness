# REVIEWER CONSOLIDATION — Authoritative /cr-style review of the integrated V2 design

> **Role.** Adversary first, consolidator second. This pass reads all four lenses
> (`lens-anti-duplication`, `lens-capability-reality`, `lens-composition-coherence`,
> `lens-honesty-proportionality`), both traceability sweeps (A, B), and the five WF4 per-artifact checks
> (`checks/*-check.md`), de-duplicates their findings, folds in the known WF4 must-fixes, and renders one
> verdict the HTML deliverable must reflect. Every "absent on disk" claim the consolidation relies on was
> **re-verified by direct inspection this session (2026-06-11)** — the charter warns the audit rots, and it
> did mid-effort (R4).
>
> **Disk re-verification this session (the consolidation stands on facts):**
> `.claude/hooks/` = exactly 5 (`block-dangerous-git.sh`, `block-npm-install.sh`, `permission-logger.sh`,
> `session-start.sh`, `worktree-create.sh`). **ABSENT:** `block-dangerous-bash.sh`, `session-end.sh`,
> `enforce-scope.sh`, `branch-registry-guard.sh`, `.claude/rules/`, `.claude/.claude-plugin/`.
> `.github/workflows/` = exactly `ci.yml` + `integration.yml`. **ABSENT:** `cr-gate.yml`, `summon.yml`.
> `proxy.ts` at **repo root** — `src/proxy.ts` **ABSENT**. `evaluate-solution/SKILL.md` **PRESENT (8925 B)**.
> Every NEW build item the design proposes is genuinely absent; zero phantom rebuilds.

---

## 1. THE ANTI-DUPLICATION GATE RESULT

## **PASS-WITH-MERGES.**

Anti-duplication is the strongest axis of this design, and it earns the PASS on hard evidence, re-verified this
session:

- **Zero phantom rebuilds.** Every NEW skill/hook/CI-file (`goal`, `lfg`, `verify`, `scan-context`, `ratchet`,
  `cr-calibrate`, `init`, `block-dangerous-bash.sh`, `session-end.sh`, `cr-gate.yml`, `summon.yml`, `.claude/rules/`,
  `.claude-plugin/`, `harness-manifest.json`, `golden-set/`) is genuinely absent on disk. Confirmed by `ls`.
- **Every killlist/F UPHELD rejection stays dead.** Collapse-23→1 ("dead," roster.md:22,145); no-shared-context
  reviewer (C2 keeps the ISOLATION INVARIANT + full canon pre-read); 200-line diet / front-load-trigger-words
  (rewritten to situational triggers, tier-by-trigger-existence); model-confidence auto-merge (LOOP-7 is a non-LLM
  classifier); `learned-patterns.md` the file (read-path CMP1 built, file scanned-for as a phantom); symlink-live
  (versioned plugin + lock); local DinD/microVM (cloud sandbox); Toolshed/Saul machinery (absent). Nothing resurrected.
- **Every killlist/E TRULY-WORLD-CLASS item left alone or only applied** — guard-file lockout (#9), the PocketOS
  safety doctrine, the §9 golden rule — never re-specced.
- **The three highest-risk shared mechanisms are single-owned *in principle*:** the task-manifest (`harness-manifest.json`),
  the model re-audit (C13 one-time / CMP6 recurring / P10 referenced-only), and the CI verdict gate (F6 owns the
  boundary; C1/C7/LOOP-7 are consumers).

It is **MERGES, not PASS-clean**, because the discipline is *stated* in VISION but *not enforced across the
artifacts*. The kill list below is the merge work — all are fold-ins, none is a rejection, so the gate does not FAIL.

### KILL LIST (the duplications/omissions that must be merged before the manifest is serialized)

| # | Duplication / omission | Where it lives | Disposition |
|---|---|---|---|
| K1 | **Keystone F6 has TWO file homes** — `ci.yml` job (file-tree.md:146,185) vs new `cr-gate.yml` (github-usage.md:238,395,421). The two artifacts disagree on `[CHG]` vs `[NEW]` and neither references the other. | file-tree ↔ github-usage | **MERGE to one home.** Recommend dedicated `cr-gate.yml [NEW]` (matches the Checks-API recommendation in Fork F1; keeps the keystone independently branch-protection-required). Change file-tree to add `cr-gate.yml [NEW]`, drop "ci.yml gains the F6 job." State once in the landing table. |
| K2 | **`evaluate-solution` skill silently dropped from roster Table A** — real 8.9 KB wired skill, present on disk, absent from the roster (only the `solution-evaluator` *agent* row exists). Breaks the "22 KEEP" count (21 enumerated) the manifest/plugin/`/init` will trust. file-tree.md:93 *includes* it; roster omits it — the two rosters disagree by one skill. | roster.md (Table A) ↔ file-tree.md:93 | **FOLD IN.** Add the KEEP row (disposition + failure-mode + F9 `disable-model-invocation` note for its 3-skill auto-invoke surface + human-confirm gate). Reconcile "22 KEEP." |
| K3 | **`@benchmark-runner` two-owner ambiguity** — `perf` builds a perf-budget runner (roster.md:50); C4/`/cr-calibrate` builds a review-recall runner (roster.md:79). The §6 phantom resolves into two distinct runners under two owners with no statement they are distinct. | roster.md (perf ↔ C4) | **STATE THE SPLIT** (one sentence): the §6 `@benchmark-runner` phantom resolves into TWO separately-owned runners (perf-budget under `/perf`; review-calibration under `/cr-calibrate`). Prevents one ambiguous manifest entry. |
| K4 | **`ratchet` (CMP2) carried as an unresolved "or"** — "a `/compound` sub-phase **or** a `/ratchet` skill" (file-tree.md:102, memory-model.md:210, VISION.md:472). Honest at vision altitude; a duplicate at build time (builder makes both). | file-tree / memory-model / VISION | **PICK ONE.** Recommend the `/compound` sub-phase (composes with the existing promotion conveyor; avoids a side-effect skill needing F9-gating). State it once, the way Fork F8 names `/lfg`'s driver. |
| K5 | **Reference-integrity check ownership** — pulled out of the `/lfg` 7-guard battery (VISION.md:181) yet owned by CMP4/`scan-context` (file-tree.md:176, memory-model.md:245). VISION prose still reads as if `/lfg` owns a copy. | roster / file-tree (CMP4 ↔ L5) | **STATE OWNERSHIP** (one line): the check is **owned by CMP4 (`scan-context`) and consumed by `/lfg`**, never implemented inside `/lfg` — matching the F6 "owned once, referenced" pattern. |
| K6 | **`notion-sync` carried mechanisms have no named receiving home** — comprehensive-diff, guard-file exception, dedicated-branch, LAST-SYNC receipt, sentinel handoff asserted "carried forward" (roster.md:49, github-usage.md:67) but neither names the file that receives them. Carried-in-prose = re-implemented-twice. | roster ↔ github-usage | **NAME THE HOME.** Recommend the re-pointed `/compound` Step 8 + the canon-PR template it writes. |

**Legitimately-multi-homed, attacked and HELD (no kill, recorded so the next pass doesn't re-litigate):**
- `scan-context` (CMP4) = skill body + `scan-context.yml` CI leg — VISION-intended detection+CI pairing, not a duplicate.
- The render gate (C8/C10) = `verify/` skill + `verify.yml` CI + `session-end.sh` verify-if-present payload — one
  check at three enforcement strengths, forced by capability-facts.md:18-20 (a hook cannot compel an artifact).

---

## 2. CONSOLIDATED TIERED FINDINGS

> De-duped across all 6 panel agents + 5 WF4 checks. The headline that all four lenses and the composition sweep
> independently converged on: **the entire WF4 checker pass ran and was NOT folded back.** Modification times prove
> it (artifacts 15:26–15:29 → checks 15:29–15:33; no artifact touched after); re-grep this session confirms 9 of 9
> checker MUST-FIX items remain literally unfolded. The design ran its own adversarial review and ignored every
> blocking finding. This is the load-bearing defect — and it is mechanical to fix, not architectural.

### MUST-FIX (must be reflected in the HTML deliverable)

**MF-A — The keystone F6 is OVER-CLAIMED: narrated as making "the model agreed with itself" un-shippable, but the gate as built only enforces SHA-match + CI-recomputed determinism.**
*Convergence: capability-reality MF-1, honesty MF-1, anti-duplication (entangled w/ K1), composition (C1→F6 merge inherited the over-claim), github-usage-check MF-1.*
- **Lands in:** `github-usage.md` §4a/§4b + **VISION.md line 659** + roster.md:131 ("the unforgeable last gate").
- **The fact (traced to disk this session):** `pr.sh` consumes the sentinel (`mv` → `.cr-ok.consumed.$$`, `cat`, `rm`)
  *before the PR opens*; `.cr-ok` is gitignored (`.gitignore:58`). At CI time the sentinel **does not exist in the
  repo**. The only un-forgeable thing CI can do is what `ci.yml` already does — check out the SHA and run
  `tsc`/`eslint`/`test`. The gate `github-usage.md` §4b specifies ("FAILS unless `sentinel_sha == head_sha` AND
  required checks green") **does not check MUST-FIX=0 at all** — so the *built* gate is the honest trust-but-verify
  form; the *prose around it* over-claims. A loop whose 9+4 lenses share the generator's blind spot passes this gate
  as long as tsc/eslint/tests are green — exactly the failure §4a claims to prevent.
- **THE FIX:** State in one sentence (in §4b and at VISION:659): *the enforceable gate is SHA-match + the
  deterministic `tsc`/`eslint`/`test` checks re-run by CI on the head SHA (un-forgeable; the model writes no record
  CI re-reads); the 9+4 judgment passes are **coverage-bounded trust-but-verify**, bounded by C4 golden-set recall,
  surfaced (queryable via Fork F1) but **NOT the merge gate**.* Strike "where the loop cannot forge it" from VISION
  delta #3, or scope it to the deterministic checks. Then resolve open-decision-#5 / Fork F1: either (a) CI re-runs a
  named deterministic `/cr` subset, or (b) accept trust-but-verify explicitly (RECONCILIATION §C.5 recommends a+b).
- **Why MUST in the HTML:** LOOP-7 auto-approval *consumes F6 as its deterministic last gate*, and the label
  trigger's "safe on the minimal floor {F1,F2,F6,F7,F9}" claim inherits F6's scope. Both rest on F6's deterministic
  half + F7's bounded-loop — not on a fully un-forgeable verdict. If the HTML ships the over-claim, the first
  all-green-but-wrong overnight PR merges through a gate everyone believed caught it.

**MF-B — Fold the 9 dangling WF4 checker MUST-FIX items into their target artifacts (or record the rejection in each).**
*Convergence: ALL FOUR LENSES name this; composition MF-1 is the master list; honesty MF-2 tabulates 6; anti-duplication MF-2.* The charter's instruction "verify they are real and folded" returns **real, NOT folded.** The nine, each re-grepped against the live file this session:
| # | Checker MUST-FIX | Lands in | The fix (the check specifies the exact replacement) |
|---|---|---|---|
| 1 | roster MF-1 — `evaluate-solution` dropped from Table A | roster.md | = K2 above. Add the KEEP row; reconcile "22 KEEP." |
| 2 | file-tree MF-1 — "+5–6 rule shards" mis-booked into Budget (2), flattering Budget (1) | file-tree.md:232 | Move shards into **Budget (1)**; restate the honest ledger (files **+4**: 2 monoliths → 6 shards; the win is **per-task load + copies-per-fact 3→1**, not file count). This is the exact "store-count win masquerading as a file-count win" the framing was built to police. |
| 3 | file-tree MF-2 — only 1 of 3 memory-traps routed; memory.md deletion BLOCKER gates on all 3 | file-tree.md | Route `check-branch-before-commit` → `00-safety.md` always-load section; `claude-md-referenced-scripts-must-exist` → a named drift-CI rule (`scan-context.yml` or `repo-structure.sh`). Then "3 traps routed" is true. |
| 4 | memory-model MF-1 — "so the routing is mechanical" contradicts RECONCILIATION §D.2 BLOCKER **and** file-tree's own `gen-rules.sh` line (which is already right) | memory-model.md:179 | Restate Edge 2: "Area-GUIDED for the path-globbable majority; operation-scoped residuals (cascade-delete, worktree ops, external-tool rule) named & routed by hand to `00-safety.md`." Drop "mechanical." |
| 5 | memory-model MF-2 — S1 has TWO readers (native `paths:` + CMP1 task-start glob), claims "ONE reader" | memory-model.md:54,195 | State "TWO complementary readers (passive auto-load + active CMP1 glob; same `paths:`-scoped files, never disagree)" and justify why this is not the §4 disease. |
| 6 | memory-model MF-3 — S1 has TWO writers (promotion conveyor + human-only `00-safety`) with different gates | memory-model.md:54 | Split the writer cell: "area shards: conveyor (`/cr` 3b + `/compound`, gated ≥3+confirm); `00-safety`: human-only, no automated writer." Or treat `00-safety` as a sub-store. |
| 7 | github-usage MF-1 — the F6 over-claim | github-usage.md §4b | = MF-A above. |
| 8 | github-usage MF-2 — two §3a cross-refs point at the wrong section (§3a = trigger trifecta; the claim lives in §2) | github-usage.md:59,98 | Repoint both to §2. A broken-cross-ref in the doc that designs cross-ref integrity. |
| 9 | gaps-risks MF-1/2/3 — checker-voice over-claim it elsewhere condemns; never audits its 3 sibling artifacts; never questions the design-effort's own doer≠checker independence | gaps-risks.md | Drop unearned "this checker re-ran verification" framing OR state what was checked vs inherited; add a pass over the 3 siblings (fold in the budget-proxy-drift gap at file-tree.md:21); add the design-effort-independence gap. |
- **THE FIX (umbrella):** Run the fold-back pass. Re-grep after — do not mark WF4 "resolved" until zero of the nine
  flagged strings survive. **The HTML must reflect the folded state, not the dangling state**, and must add the C-3
  dogfood (run P9/CMP4 reference-integrity over `design/v2/**`) so this drift class is caught mechanically next time.

**MF-C — The fork-numbering namespace collides: bare "F4" means migration-credential (FLOOR) AND egress-depth (DECISION), disambiguated only by an inconsistently-applied "Fork" prefix.**
*Source: composition MF-4 (a genuine cross-artifact contradiction the per-file checks could not see). Verified against VISION:763-793 (decision forks F1-F11) and the floor moves F1-F9.*
- **Lands in:** all five artifacts + VISION. file-tree.md:182 says "F3 egress allowlist … (GATED Fork-F4)" with the
  next row "F4 migration-credential" — "F4" and "Fork-F4" mean two different things three lines apart.
- **THE FIX:** Rename one namespace. Recommend keeping FLOOR `F1…F9` and renaming DECISION forks to a distinct prefix
  (`DF1…DF11` or `Fork-A…Fork-K`); sweep all five artifacts + VISION. At minimum make the "Fork" prefix mandatory and
  grep-gated so bare `F4` is unambiguously the floor move. **The HTML must use the disambiguated numbering** — a
  reader/builder cannot resolve "gate this on F4" otherwise.

**MF-D — F2 credential pre-flight is placed inconsistently AND one placement is non-functional.**
*Source: composition MF-3 (a third instance of the "hook named in landing table but missing/wrong in the tree" class; F2 is minimal-floor, so more severe than F3/F5).*
- **Lands in:** file-tree.md:181 lands F2 as "a pre-flight in `hooks/session-end.sh`/start" — but `session-end.sh`
  (Stop event) fires *after* the turn's tool calls, including any exfiltration. The roster's "PreToolUse /
  session-start (blocking, fails closed)" (roster.md:127) is the only correct placement. The file-tree's `hooks/`
  tree lists no credential hook at all.
- **THE FIX:** Place the F2 pre-flight on **PreToolUse / SessionStart** (not `session-end.sh`) and give it a dedicated
  line in the `hooks/` tree, matching the roster. The HTML's floor must show F2 as a fail-closed *pre*-flight.

**MF-E — Two FLOOR-class deterministic guards are silently DROPPED — leaving the floor pillar incomplete despite the design claiming the floor is the safety substrate the whole program rides on.**
*Source: traceability-sweep-B drops #1, #2; traceability-sweep-A flag #4. Both re-verified ABSENT on disk this session.*
- `branch-registry-guard.sh` + `active-branches.json` (stripe-minions D-gate; canon §5) — *failure mode:* two
  unattended sessions own the same branch and stomp each other's commits at fleet scale. The design built
  `block-dangerous-bash.sh` (F1) and `enforce-scope.sh` but dropped the third guard of the same cluster.
- Main-branch agent hard-block re-wire (stripe-minions + osmani Move 4 + canon §5) — the dormant `.githooks/pre-commit`
  main-branch block is wired out (`core.hooksPath=.husky/_`); zero mentions in the design. *Failure mode:* an
  unattended agent commits directly to `main`, bypassing the entire worktree+PR spine.
- **THE FIX:** Either add both as P0-floor hooks (with failure modes) OR add them to VISION Honest Cuts with an
  explicit reason (e.g., "worktree isolation makes branch-registry redundant" — *if* true; right now it is neither
  built nor consciously cut). **The HTML floor cannot claim completeness while two floor-class guards are unaccounted.**
  Decide before fleet volume; this is the cheapest gap with the highest collision cost at 5+-repo scale.

### SHOULD-FIX

**SF-A — Two runtime capabilities the spine leans on are UNVERIFIED and treated as load-bearing facts, not probes.**
*Source: capability-reality MF-2, SF-1.* (a) **C8 headless render leg** — "chrome-devtools-mcp is headed-only → CI
headless leg" was never exercised; C8 is tagged a *hard* gate. Demote to "hard gate *pending* a one-run
headless-against-preview confirmation"; add to the Phase-0 probe list beside force-continue. (b)
**`managed-settings.json` honored on macOS** — documented but never observed to take effect on this OS; F9's enforced
tier, P2's `/init`, and Fork F5 lean on it. Add a precondition: until verified, F9's enforced tier is
`deny`-in-committed-settings + the social rule. (c) **`disable-model-invocation` "removes from context"** — hedged in
github-usage §9 but F9 is P0-floor; promote to a named Phase-0 probe (cheap: set `true` on one skill, confirm
un-invokable). If it fails, F9's pillar-2 contribution collapses to advisory.

**SF-B — File-tree count reconciliations (manifest/`/init` will trust these numbers).**
*Source: file-tree-check C-1, C-3, SF-4; composition SF-1, SF-2.* (a) scripts "7 → 10" → **"6 → 9"** (disk has 6
source scripts). (b) header "26 → 25 core" → **"26 → 22 core kept + 7 new"** (pairs with K2). (c) agent label
"(remaining 9)" double-counts `spike-orchestrator` → "(remaining 8)" (total 23 is correct). (d) move count: VISION is
described as "33 moves" (file-tree.md:4) but the spine carries **44 distinct move IDs** (file-tree-check counts 44 and
reconciles every one). Reconcile to one number used consistently — a reader cannot audit "is this kitchen-sink?"
against a count that is a third low.

**SF-C — Dead shard glob: `auth-routing.md` points at `src/proxy.ts` (does not exist); proxy is at repo root.**
*Source: file-tree-check SF-3; anti-duplication MF-2; honesty MF-2; composition SF-3.* A `paths:` glob matching
nothing means the shard **never auto-loads** when the agent edits the proxy — the "fake shard" failure the tree warns
against (line 46), and a live instance of the doc-fiction class CMP4 exists to catch. Fix to `app/**,proxy.ts`;
correct/drop the dead `middleware*` glob (Next 16 renamed it).

**SF-D — P4 (MCP-as-substrate, P0-spine) has a landing-table row but no file home in the tree.**
*Source: file-tree-check SF-1; composition SF-4.* github-usage §3b *does* give it a home (`summon.yml` → P4 entry
point → worktree shell); the two artifacts agree on the mechanism, only the file-tree omits the file. Import that home
into the file-tree. Same class: F3/F5 enforcement hooks named in the landing table but absent from the `hooks/` tree
(file-tree-check SF-2) — add gated/placeholder entries or a one-line note.

**SF-E — The deferred-trigger prerequisite is stated three ways (F5+F3 / F3+F8 / F5-only).**
*Source: github-usage-check SF-1; composition SF-5.* github-usage §3a says "After F5 + F3"; VISION:138-139 says "F3 +
F8"; VISION:109/136 frames F5 as the gate. The "F5 + F3" reading is most coherent — but it is a silent resolution of a
VISION inconsistency, which the charter forbids. Reconcile to {F3, F5, F8} or surface as a Tanner thread. (Interacts
with MF-C: confirm which namespace each F refers to.)

**SF-F — Monotonic stores under-stated; the safety-text deletion is prose-only, not a wired gate.**
*Source: memory-model-check SF-1, SF-2, SF-3, SF-4.* (a) The `memory.md → 00-safety.md` verbatim-absorb-before-delete
is correctly worded but is an ordering *sentence* with no mechanism — add a one-line CMP4 fiction-mode assertion (or
migration checklist gate) that blocks the deletion PR until the absorbed text is present in `00-safety.md`. (b) S2
(solutions) and the auto-memory cache are both genuinely monotonic with no real eviction — name the truncation-of-fresh-signal
failure mode and give S2's archive flag an actor+trigger or state retention-by-design. (c) Edge 5: first-pass-approval
"confirms compounding" but has no control action on regression — name the control edge or downgrade the
"closes the loop" claim to "sensor."

**SF-G — The spine's §9 justifications are program-internal-circular in a way the floor's are not — and the evidence that would break the circularity was never sought.**
*Source: honesty MF-3; gaps-risks Gap #4.* The FLOOR (F1/F2/F5/F9) cites real external dated incidents
(Replit-July-2025, PocketOS-2026, the Anthropic red-team credential class). The SPINE (L1/L2/L4/L5/L7) is justified by
failure modes that are only failures *if autonomy is already the goal* — legitimate under the charter, but the design's
own Gap #4 concedes every corpus source is autonomy-positive ("no cited source ran an autonomous fleet and pulled
back"). State plainly in VISION that the floor's failure modes are externally-grounded while the spine's are
program-internal, and elevate Gap #4's "one deliberate search for autonomous-fleet rollbacks" to a pre-Phase-1 action.

### CONSIDER

- **C-i — Dogfood the P9/CMP4 reference-integrity check on `design/v2/**` as its first test corpus.** *(All four
  lenses + 3 checks converge.)* It would mechanically catch K1 (two keystone filenames), SF-C (dead proxy glob), and
  MF-B item 8 (the §3a mis-pointers). The design indicts context-rot and ships a tree with context-rot in it; the
  cheapest proof P9 is worth building is to run its detector on these very files.
- **C-ii — No global fleet kill-switch.** *(capability-reality C-4, composition C-4, honesty SF-4, gaps-risks-check
  C-4.)* F8 is per-defect-class, F7 per-loop, Fork F9 paging-not-halt. At 5+-repo laptop-closed scale, "stop the entire
  fleet right now" has no designed control and is owned by no artifact. Promote to a named risk (R6) and/or give it a
  home (a fleet-wide `STOP` marker the `/schedule` + `/queue` + L1 paths all check).
- **C-iii — "copies-per-fact 3→1" is the curated count; physical copies = 2** (canonical S1 + un-evictable auto-memory
  cache, demoted not deleted). Pair the headline with "(+1 demoted, un-evictable)" wherever it travels, per the
  RECONCILIATION §A red-flag rule. *(memory-model-check C-4; anti-duplication C-2.)*
- **C-iv — No cost ceiling on the COMPOUNDING loop's own nightly runs** (CMP4/CMP6/P9/CMP3 on `/schedule`, *in
  addition* to the action fleet). *(gaps-risks-check C-2; honesty SF-3.)* The harness can be viable on output and bleed
  on self-maintenance.
- **C-v — The harvest-from-disk method's own failure mode is unnamed** — "the file exists" is the completion signal, so
  a half-written/wrong slug is harvested as done and never re-run. *(gaps-risks-check C-3.)* This review found exactly
  that: the WF4 checks' slugs exist on disk and their existence was treated as resolution while their MUST-FIX items sat
  unfolded. The method's failure mode is operating in this very tree.
- **C-vi — Genuinely-DROPPED re-mine moves** beyond MF-E — see §3 ledger (op-accessibility tier registry,
  comprehension-debt ledger, canonical typed task object, subtractive-enforcement `/simplify`, import-vetting screen,
  pause-resume checkpoints, and others). Dispositioned individually below.

---

## 3. DROPPED-MOVE LEDGER

> Re-mine ELEVATE/NEW moves the two traceability sweeps found raised-by-a-source-but-addressed-nowhere. Sweep A swept
> 19 slugs (2 DROPPED + 3 partial); Sweep B swept 18 slugs (13 primary + 6 secondary DROPPED + 1 GATE + 2 partial).
> The WF4 per-artifact checks caught **none** of these — they audited internal consistency, not research→design
> coverage. That is precisely the gap the sweeps close. Each gets a disposition: **fold-in** (build it / name it) or
> **conscious-cut-with-reason** (add to VISION Honest Cuts with a failure mode).

### FOLD-IN (FLOOR-class — these break the floor-completeness claim; promoted to MF-E above)
| Move | Source | Disposition |
|---|---|---|
| `branch-registry-guard.sh` + `active-branches.json` | stripe-minions-kaliski, zapier-skillmd, canon §5 | **fold-in OR conscious-cut.** Highest-priority drop. Floor-class deterministic guard; verified absent. Build it, or cut it explicitly with the "worktree isolation makes it redundant" reason — currently neither. |
| Main-branch agent hard-block re-wire | stripe-minions, osmani Move 4, canon §5 | **fold-in.** The dormant `.githooks/pre-commit` block is wired out; an unattended agent can commit to `main`. Re-wire under the floor, or cut explicitly. |

### FOLD-IN (structural — a named one-row build item, cheap, prevents a real class of silent failure)
| Move | Source | Disposition |
|---|---|---|
| Op-accessibility tier registry (CLI/MCP/UI-required/not-possible per operation; UI-required rows = autonomy-defect backlog) | 37signals-dhh Move 2 | **fold-in (one row).** *Failure mode:* an unattended/`/schedule` run silently stalls on a UI-required step no human is there to click; nothing tells you *before* a fleet runs where autonomy physically breaks. Owned by P6's manifest or gaps-risks. MEDIUM. |
| Accountability-binding classification doc (every human/STOP gate classified never-deletable vs capability-proxy) | linear-context-execution Move 2 | **fold-in.** This is a **precondition for CMP6** (the §9 deletion engine), which the design ships without. *Failure mode:* CMP6 over-prunes a safety gate as if it were a capability proxy — the PocketOS class. Name the stop-line before the deletion engine runs. |
| Temporal-gap rule as an *enforced* invariant (CI/lint fails a ritual with no clock) | loop-engineering Move 2 | **fold-in (cheap CI check).** L4 builds the scheduler; the "no committed ritual without a clock" check is absent. *Failure mode:* the harness regresses into documented-but-inert "scheduled" rituals. |

### FOLD-IN-OR-GATE (real, but a "watch / trigger = X" note may suffice)
| Move | Source | Disposition |
|---|---|---|
| Comprehension-debt ledger (one field in the session-end handoff feeding a chronic-debt list) | shopify-ai-first Move 2 | **fold-in (lightweight).** HOOK-1/L7 build the handoff it rides on; the field/store is absent. *Failure mode:* an agent-written subsystem breaks and no human can diagnose it because nobody tracked touched-but-not-reasoned-about. |
| Canonical typed task object (converge TASKS.md / TASK-TEMPLATE / AGENTS.md open-decision / ad-hoc prompt into one typed object every entry point instantiates) | linear-context-execution Move 1 | **gate-with-note OR fold-in.** TASK-TEMPLATE survives as *a* format; the convergence-to-one move is absent. *Failure mode:* parallel agents across 5+ repos each spin up from a different partial task surface. Trigger = 2nd repo. |
| Skill-promotion rung (repeated workflow → named skill, distinct from fact-promotion) | linear-context-execution Move 3 | **gate-with-note.** CMP1-6 promote findings/blocks, not workflows. *Failure mode:* reusable processes get crammed into fact-stores (a driver of triple-duplication). |
| Subtractive-enforcement `/simplify` w/ Chesterton's Fence | osmani-agent-skills Move 2 | **gate-with-note.** `/simplify` survives only as a `/feature` step; the guarded-deletion *enforcement* is absent (CMP6 prunes scaffolding, not product dead-code). *Failure mode:* additive-only harness accretes dead code/skills/canon across 5+ repos. |
| Adopt/borrow/reject import-vetting screen on new skill imports | osmani-agent-skills Move 5 | **gate-with-note.** P5 (provenance) + P7 (disposition) govern trust/cadence of skills you *have*; neither is the admission screen on *new imports*. *Failure mode:* a marketplace world where every repo accretes a different advisory-skill pile, 23×-ing drift surface for zero capability. |
| Non-blocking checkpoints / pause-resume execution primitive | vercel-agentic-infra Move 3 | **gate-with-note.** gaps-risks #7 acknowledges "recovery semantics under-specified" as an open gap, not a designed move. *Failure mode:* a long loop dies at session-end and restarts from scratch, or freezes at a checkpoint with the task stalled. |
| Cross-repo cost/usage telemetry plane | shopify-ai-first Move 3 | **gate-with-note** (ties to C-iv). gaps-risks #2 names un-priced economics; no telemetry build move. *Failure mode:* runaway-loop solvency problem with no per-repo/per-agent token+cost accounting. |
| Dev-agent-only internal MCP server (shared tool layer over `src/data/`) | mcp-servers Move 3 | **gate-with-note.** P4 is the inverse (harness-as-server). Re-mine itself says "premature until a 2nd consumer." A conscious "watch, trigger = 2nd consumer" note satisfies it; currently neither built nor deferred. |

### CONSCIOUS-CUT-WITH-REASON (defensible to leave dead, but VISION must *name* the cut + failure mode)
| Move | Source | Reason to cut (name it in Honest Cuts) |
|---|---|---|
| `bugfix-test-guard` deterministic gate (fix-scoped commit ⇒ red-before/green-after test) | engineering-rigour Move 1 | **Genuine tension, not a clean miss.** Ground-truth/§9 flags the V1 "bugfix-test rule duplicates `/tdd`" as a *killed* pattern. C10 runs the suite + the L1 test-count floor blocks decreases, but neither *requires a new repro test on a fix*. Under autonomy the re-mine's "becomes more load-bearing" argument holds — decide explicitly: revive (narrow to surfaces `/tdd` misses) or re-affirm the dedup cut. |
| Evaluable pass/fail output contract on every skill gate | ramp-inspect-agent Move 4 | Only `/cr` tiers + the C10 bundle emit verdicts. *Failure mode:* a scheduled review agent can't triage skills that "run and produce prose." Cut or fold the contract into P6 frontmatter. |
| Adversarial-generation (exploit-construction/fuzz) pass in `/cr-security` | shopify-ai-first Move 4 | The `lens-abuse` row keeps pattern-matching; no exploit-construction step. *Failure mode:* a named-pattern pass green-lights a novel exploit when PRs may auto-approve. Name the cut or fold into `/cr-security`. |
| Review-capacity as a named AFK constraint + queue-depth sensor | shopify-ai-first Move 5 | LOOP-7 names the *bottleneck* and is the auto-approval response; the *scored principle + queue-depth/staleness sensor* is unbuilt. *Failure mode:* N agents out-generate one reviewer; queue grows unbounded or review goes shallow. |
| Hot-Potato scheduled cross-source fan-out pre-read (situational brief) | notion-spec-driven Move 4 | L4 is the scheduler substrate; the fan-out *brief* payload is unbuilt. *Failure mode:* a single agent serially crawls N sources, blows context, loses the plot on parallel work. |
| Deterministic validation gates *between* probabilistic passes + chain-reliability measurement | when-is-llm-call-worth-it Move 3 | CMP3 measures outcomes, not per-pass agreement / between-pass gates. *Failure mode:* a 9-pass/23-agent chain silently lowers end-to-end reliability (0.9ⁿ) while reporting success. |
| Fallback/abstention contract per reasoning pass + `/queue` liveness check | when-is-llm-call-worth-it Move 4 | F7 bounds the retry loop; the per-pass abstention field + dead-agent liveness is unbuilt. *Failure mode:* a pass returns garbage / an agent silently dies and the pipeline proceeds (the "background agents fail silently" hazard). |
| Process-vs-knowledge skill-authoring gate ("does the model already infer this?") | packmind Move 4 | P6 frontmatter is the home; the authoring gate is unspecified. *Failure mode:* a knowledge-skill narrating judgment the model already has is a ghost rule that drifts. |

### PARTIAL LANDINGS (present but the distinctive half is thin — build-time notes, not drops)
- "Unify execution + business state" (12-factor) lands in `memory-model.md` but carries **no VISION move-ID** — a
  reader of VISION alone misses it. (Sweep A flag #3.)
- Runtime observability substrate (ashby Move 3 half): L1 *consumes* a runtime error signal it assumes exists;
  nothing *produces* the project-side runtime error-log table. (Sweep A flag #5.)
- Kill-filter / verifiable-correct-output admission test that routes unstatable-"done" tasks to a human queue *before*
  autonomous execution — L1 + LOOP-7 cover *risk* routing; the *admission test* is thin. (Sweep B partial.)

### CONSCIOUS GATE WORTH RATIFYING (traceable, NOT silent — flagged for a Tanner confirm)
- **Outcome-keyed retro / IMPACT-LOG store** (leland-eight-principles, the single-biggest ELEVATE-now move): the
  re-mine argued hard for in-scope-now ("the reward channel for the entire autonomy program"); VISION consciously
  STILL-GATES it (≥N autonomous PRs/week) and CMP3 carves day-0 fields in. **This is the one place a strong ELEVATE was
  overruled into a GATE** — traceable and conscious (not a drop), but worth a ratify rather than silent acceptance.
  *(This becomes a candidate NEW fork — see §4.)*

**Un-sourced additions check (reverse direction): NONE found** by either sweep. Every VISION move-ID cites a
re-mine elevation or a CANONICAL §N row / confirmed absence; HOOK-1, L6, L7 are internally-sourced and explicitly
attributed. No phantom design additions.

---

## 4. THE GENUINE TANNER DECISIONS

> Reconciling VISION's 11 decision forks (F1-F11, the DECISION namespace — to be renamed per MF-C) against everything
> the review surfaced. The charter settles the OLD five (autonomy = in; file-count = dropped; distribution =
> plugin+marketplace+thin-`/init`; ADR/write-back resolved; GitHub = canon). The question for each of the 11: is it
> **genuinely-open** (not settled by the charter) AND **well-formed enough to decide**?

**All 11 are genuinely-open and well-formed — confirmed.** None is settled by the charter (the charter mandates
autonomy-first and world-class but takes no position on *how aggressively* autonomy rolls out, *which* surfaces, or the
specific dependency/hosting choices). Each names its affected moves and a recommendation. Two require the MF-A
correction threaded through before they can be decided cleanly:

| Fork | Status | Note from the review |
|---|---|---|
| **F1** — Verdict artifact surface (PR comment / body / `review/` file / Checks API) | **Open, well-formed. DECIDE WITH MF-A.** | Entangled with the keystone over-claim. github-usage recommends the Checks API; that aligns with K1's recommended `cr-gate.yml` home. But note (capability-reality C-1): a Checks-API run posted by the loop's own pipeline is a model-adjacent writer — queryable ≠ un-forgeable. Decide F1 *and* state MF-A's trust-but-verify framing together. |
| **F2** — Autonomy rollout aggressiveness + auto-approval threshold (observe-only vs live LOW-auto; does auto-merge ever touch `src/data/`/money-math?) | **Open, well-formed. Highest real-world stakes.** | honesty SF-4 / gaps-risks Gap #3: this is "the exact lever that decides what ships without a human on a $30k-client tool." Its safety rests on the *corrected* F6 scope (MF-A) + F7. Decide after C4 recall is measured, per build order. |
| **F3** — Which trigger ships first (GitHub label / Slack-Linear / CI self-heal) | **Open, well-formed. VISION recommends label-first; confirm.** | Interacts with SF-E (the deferred-trigger prerequisite stated three ways) — resolve that as part of confirming F3. |
| **F4** — Egress-firewall depth + default execution surface (is local-unattended worth supporting given cloud `/schedule` is primary? Seatbelt vs pfctl/Privoxy) | **Open, well-formed.** | Re-prioritizes a third of the floor (F3/F4 are P0 only if local-unattended ships first). Capability-correct to defer. |
| **F5** — `managed-settings.json` now, or committed settings + the social rule? | **Open, well-formed. DECIDE WITH SF-A(b).** | The macOS override is documented but never observed to take effect this session — verify once before treating it as the enforced floor. Decision depends on that probe. |
| **F6** — `fast-check` adoption (PBT dependency for C11) | **Open, well-formed.** | Standard ask-before-installing fork (name/purpose/downloads/last-publish/ships-types). Self-contained. |
| **F7** — Deletion-engine cut depth + repair-worker aggressiveness (auto-revert vs flag NEEDS-HUMAN; auto-delete lane for pure-fiction refs?) | **Open, well-formed. ADD the precondition.** | Per the DROPPED ledger: the **accountability-binding classification doc** (linear Move 2) is a *precondition* for deciding this fork — without a never-deletable-vs-capability-proxy line, the deletion engine has no principled stop. Fold that in before F7 is answered. |
| **F8** — `/lfg` canonical single-task driver: `/dev` or `/feature`? | **Open, well-formed.** | Pick before building L5 so the orchestrator doesn't bake in a duplication. (Note: this is the model for how K4's `ratchet` "or" should be resolved.) |
| **F9** — Human-paging surface: Slack / Linear / GitHub? | **Open, well-formed.** | Shared by L7, L1 summon, every F7/F8 escalation; a connector-credential surface F5 must account for. |
| **F10** — Convergence scope as publish gate (resolve all 9 §7 contradictions before first publish, or publish from a `supersedes:` snapshot and resolve lazily?) | **Open, well-formed.** | Trades first-publish latency against shipping a known-imperfect canon. |
| **F11** — Marketplace hosting (private vs public) + `/init` template depth (safety-floor-only vs opinionated full scaffold) | **Open, well-formed.** | The depth question carries a real risk: an opinionated `/init` risks shipping event-vendor assumptions into unrelated repos. |

### NEW forks the review surfaced (not in the VISION 11 — flag for Tanner)
1. **The keystone framing decision (downstream of MF-A):** once F6 is honestly named, does CI re-run a deterministic
   `/cr` subset (and which passes are mechanizable), or is the judgment half accepted as trust-but-verify? RECONCILIATION
   §C.5 recommends a+b. This is the substance of open-decision-#5; it is adjacent to Fork F1 but is its own choice. **Decide
   before the floor ships.**
2. **The IMPACT-LOG / outcome-retro store gate (ratify):** the one place a strong re-mine ELEVATE-now was overruled into
   a STILL-GATE. The re-mine claims it works with a placeholder definition on day 0 and is infrastructure, not a product
   metric; VISION treats it as volume-gated. Confirm the gate or pull it into CMP3 day-0. *(Sweep B conscious-gate.)*
3. **Global fleet kill-switch (C-ii):** not a fork VISION posed, but a genuine open decision at 5+-repo scale — build a
   fleet-wide `STOP` control now, or accept per-loop/per-class halts only? Owned by no artifact today.
4. **FLOOR-guard completeness (MF-E):** build `branch-registry-guard.sh` + the main-branch hard-block re-wire, or
   consciously cut them as worktree-isolation-redundant? A genuine decision the floor-completeness claim forces.

---

## 5. VERDICT

## **READY-TO-DELIVER — conditional on the MUST-FIX list being reflected in the HTML.**

**The architecture is sound. No SERIOUS finding forces a redesign.** All four lenses, both sweeps, and all five WF4
checks converge on the same shape: the spine is coherent (every move has a home; build order's ordering invariant holds
end-to-end — nothing depends on something sequenced later; auto-approval gates on F6/C4, L5 on F8, triggers on F5/F3,
the plugin on convergence); anti-duplication is the strongest axis (zero phantom rebuilds, every §F rejection dead,
every §E world-class item left alone); the memory-model spine (entry-as-atom, S3 airlock, read-path-not-`learned-patterns.md`-file)
is the right shape; the distribution/enforcement mechanics (27-byte plugin/permissions seam, autoMode→local/managed,
label-trigger-first, convergence-as-publish-gate-only) are mechanically correct; the honest cuts are genuinely cut; and
`gaps-risks.md` is genuinely self-critical. **The defects are at the seams, not the architecture — every one is a prose
edit, a fold-back pass, a rename sweep, or a one-row build item.**

But the design **must not ship as-is**, because it is **not yet assembled**: it ran its own adversarial review (the WF4
pass) and folded back **none** of the 9 MUST-FIX items, and the most consequential unfolded item — the keystone
over-claim (MF-A) — is live in VISION's headline. The honest-proportionality and capability-reality lenses are exactly
right that this converts an expensive adversarial pass into theater unless consumed. The composition lens's verdict
("UNSOUND-AS-INTEGRATED, mechanically correctable") is the accurate one *about the current artifact state*; it becomes
SOUND the moment the fold-back lands.

**The HTML deliverable MUST reflect:**
- **MF-A** — F6 named honestly (un-forgeable *deterministic* gate + *coverage-bounded* judgment surface; strike "where
  the loop cannot forge it"). The single most load-bearing correction; every "safe on the minimal floor" claim inherits it.
- **MF-B** — the 9 WF4 checker MUST-FIX items folded (incl. K2 evaluate-solution, the budget-ledger honesty, the
  3-trap routing, the memory-model dual-reader/writer + "mechanical" overclaim, the §3a cross-refs, the gaps-risks
  checker-voice).
- **MF-C** — the F-number namespace disambiguated (FLOOR `F1…F9` vs DECISION `DF1…DF11`/`Fork-A…K`), swept across all
  artifacts.
- **MF-D** — F2 credential pre-flight on PreToolUse/SessionStart (not `session-end.sh`), with a `hooks/`-tree home.
- **MF-E** — the two dropped FLOOR-class guards (`branch-registry-guard.sh`, main-branch hard-block) either built or
  consciously cut with a reason — the floor-completeness claim cannot stand otherwise.
- **K1** — the keystone's single file home (`cr-gate.yml`), stated identically everywhere.

Fold those, sweep the SHOULD-FIX count/glob/home/probe items, disposition the DROPPED-move ledger (§3), and ratify the
genuine Tanner decisions (§4 — the 11 forks + the 4 new ones). The design's rigor is real and world-class-aimed; it
needs the cheap half (the fold) banked to match the expensive half (the attack) it already paid for.

**Recommended sequence:** MF-A (keystone) → MF-B (fold the 9) → MF-C/MF-D/MF-E + K1 (cross-artifact contradictions) →
SHOULD-FIX reconciliations → dogfood P9 over `design/v2/**` (C-i) to confirm the drift class is closed → THEN serialize
the manifest and render the HTML.
