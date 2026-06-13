# V2 Design — Corrections Ledger (the fold-back the WF5 reviewer required)

> **Why this exists.** WF5's reviewer found the load-bearing defect was that WF4 ran its own adversarial review
> and folded back *none* of the 9 checker MUST-FIX items. This ledger records the fold so the expensive
> adversarial pass is consumed, not theater. **The HTML deliverable (`V2-HARNESS-REVIEW.html`) is the ASSEMBLED,
> CORRECTED position; where a `design/v2/*` artifact or `VISION.md` disagrees with the HTML, the HTML wins**
> (same "later-doc-wins" convention the project uses for RECONCILIATION). Verdict carried: **READY-TO-DELIVER,
> conditional on the HTML reflecting these** — architecture sound, every defect mechanical.

## Anti-duplication gate: PASS-WITH-MERGES (zero phantom rebuilds; every §F rejection stays dead).

## MUST-FIX — resolved in the HTML
- **MF-A (keystone honesty)** — F6 is the un-forgeable **deterministic** gate (sentinel-SHA == head-SHA + CI re-runs
  `tsc`/`eslint`/`test` on that SHA); the 9+4 `/cr` judgment passes are **coverage-bounded trust-but-verify**
  (miss-rate measured by C4 recall), surfaced to the PR but **not the merge gate**. Struck "where the loop cannot
  forge it." → folded into VISION delta #3 (done) + the HTML's GitHub + keystone sections.
- **MF-B (the 9 WF4 checker folds)** — (1) `evaluate-solution` KEEP row added → **22 KEEP** reconciled; (2) rule
  shards are **Budget 1** (+4 files: 2 monoliths→6 shards; win = per-task load + copies-per-fact 3→1, not file
  count); (3) 3 memory-traps routed (check-branch-before-commit→00-safety; claude-md-referenced-scripts→drift-CI);
  (4) PITFALLS routing is **Area-GUIDED**, residuals hand-routed to 00-safety (not "mechanical"); (5) S1 has **two
  complementary readers** (passive `paths:` auto-load + active CMP1 glob, same files, never disagree); (6) S1
  writers **split** (area shards: conveyor `/cr` 3b + `/compound`, ≥3+confirm; 00-safety: human-only); (7) = MF-A;
  (8) the two §3a cross-refs → §2; (9) gaps-risks drops the "re-ran verification this session" checker-voice.
- **MF-C (fork namespace)** — FLOOR moves stay **F1…F9**; DECISION forks renamed **DF1…DF11** everywhere in the HTML
  (bare "F4" was ambiguous: migration-credential floor vs egress-depth decision).
- **MF-D (F2 placement)** — credential pre-flight is **PreToolUse / SessionStart** (fail-closed), NOT `session-end.sh`
  (Stop fires *after* exfiltration). The HTML floor shows it as a pre-flight with a `hooks/` home.
- **MF-E (two dropped floor guards)** — **ADDED to the floor:** `branch-registry-guard.sh` + `active-branches.json`
  (two unattended sessions stomp the same branch) and the **main-branch agent hard-block re-wire** (the dormant
  `.githooks/pre-commit` block is wired out; an agent can commit straight to `main`, bypassing the worktree+PR spine).
- **K1** — F6 single home = **`cr-gate.yml` (NEW)**, stated identically. **K3** — the §6 `@benchmark-runner` phantom
  resolves into **two** runners (perf-budget under `/perf`; review-calibration under `/cr-calibrate`). **K4** — the
  ratchet is the **`/compound` sub-phase** (one home). **K5** — the reference-integrity check is **owned by CMP4
  (`scan-context`), consumed by `/lfg`**. **K6** — the notion-sync mechanisms land in the **re-pointed `/compound`
  Step 8 + the canon-PR template**.

## SHOULD-FIX — reflected
- SF-A: name the **Phase-0 probes** (force-continue Stop semantics; C8 headless render; managed-settings honored on
  macOS; `disable-model-invocation` removes-from-context) as preconditions, not assumed facts.
- SF-B counts: scripts **6→9**; skills **26→22 core + 7 new**; agents **23**; the spine carries **~44 distinct move
  IDs** (VISION's "33 moves" undercounts — the HTML states the honest count).
- SF-C: `auth-routing` shard glob → `app/**,proxy.ts` (proxy is at repo root; `src/proxy.ts` absent).
- SF-D: P4 file home = `summon.yml`. SF-E: the deferred-trigger prerequisite = **{F3, F5, F8}**.
- SF-F: the `memory.md→00-safety` verbatim-absorb gets a **CMP4 fiction-mode assertion** blocking the deletion PR
  until the text is present; S2/auto-memory monotonicity named.
- SF-G: the **floor's** failure modes are externally-grounded (Replit, PocketOS, the 24/25 red-team); the **spine's**
  are program-internal (true only if autonomy is the goal — legitimate under the charter, stated plainly). Gap #4's
  "one deliberate search for autonomous-fleet rollbacks" elevated to a pre-Phase-1 action.

## DROPPED-MOVE dispositions (HTML reflects)
- **Fold-in (structural one-row):** op-accessibility tier registry (37signals); accountability-binding classification
  doc (linear — **precondition for CMP6** so it can't over-prune a safety gate); temporal-gap enforced invariant
  (loop-engineering — CI fails a ritual with no clock).
- **Gate-with-note (watch / trigger=X):** comprehension-debt ledger; canonical typed task object (trigger=2nd repo);
  skill-promotion rung; `/simplify` subtractive enforcement; import-vetting screen on new imports; pause-resume
  checkpoints; cross-repo cost telemetry; dev-agent-only internal MCP (trigger=2nd consumer).
- **Conscious-cut-with-reason (named in Honest Cuts):** bugfix-test-guard (genuine `/tdd`-dedup tension — a decision);
  evaluable pass/fail per skill; adversarial-generation pass in `/cr-security`; review-capacity AFK + queue-depth
  sensor; Hot-Potato fan-out; between-pass gates + chain-reliability; per-pass abstention + liveness;
  process-vs-knowledge authoring gate.
- **Conscious GATE worth ratifying → a NEW fork:** the IMPACT-LOG / outcome-retro store (the one strong ELEVATE-now
  overruled into a gate).

## CONSIDER (in the HTML's honest-assessment / risks)
- C-i dogfood P9/CMP4 over `design/v2/**` (would mechanically catch K1, SF-C, the §3a mis-pointers — the design indicts
  context-rot and shipped a tree with context-rot in it). C-ii **global fleet kill-switch** (new risk + new fork).
- C-iii copies-per-fact 3→1 is the *curated* count; physical copies = 2 (+1 demoted, un-evictable auto-memory).
- C-iv no cost ceiling on the compounding loop's own nightly `/schedule` runs. C-v the **harvest-from-disk method's own
  failure mode**: "the file exists" = done, so a half-written/wrong slug is harvested as complete — *this very review
  found exactly that* (the WF4 checks existed on disk and their existence was mistaken for resolution).

## NEW forks the review surfaced (added to the decision brief)
DF12 keystone framing (CI re-runs a deterministic `/cr` subset, or accept trust-but-verify?); DF13 ratify the
IMPACT-LOG gate or pull into CMP3 day-0; DF14 global fleet kill-switch now or per-loop halts only; DF15 floor-guard
completeness (build branch-registry + main-branch block, or consciously cut as worktree-redundant).
