# LENS: composition-coherence — adversarial review of the integrated V2 design

> **Stance.** Doer≠checker, attack-not-validate. This lens reads the five V2 artifacts (`roster.md`,
> `file-tree.md`, `memory-model.md`, `github-usage.md`, `gaps-risks.md`) **as one integrated design** and asks the
> four composition questions in the charge: (1) do the artifacts agree; (2) is the build order sound; (3) are the
> WF4 checker MUST-FIX items real and still unfolded; (4) is there any internal contradiction. Every finding cites
> the artifact + line and was re-verified against the current on-disk file state this session (2026-06-11), not
> inherited from the prompt's framing or the artifacts' own assertions.
>
> **Method note (and the headline).** The five WF4 check files (`checks/*-check.md`) were written 15:29–15:33;
> the five artifacts were last modified 15:26–15:29 (`stat` confirmed). **No artifact was edited after its checker
> ran.** So the WF4 MUST-FIX items are not "folded and verified" — they are **flagged and abandoned**. I grepped
> every one against the *current* artifact text: **9 of the 9 checker MUST-FIX items remain literally unfolded.**
> The charge asked me to "verify they are real" — they are real, and they are all still open. That is this lens's
> central finding.

---

## VERDICT: UNSOUND-AS-INTEGRATED (corrections are mechanical, not architectural)

The five artifacts are individually strong and the **spine is coherent**: every VISION move has a home, the
build order's ordering invariant holds (nothing depends on something sequenced later), the roster/file-tree
rosters reconcile to 26 skills + 23 agents with nothing dropped, and the memory model's store discipline is the
right shape. **But the design is not yet integrated:** (a) the entire WF4 checker pass was run and then *not
folded back* — 9 MUST-FIX items sit open across all five artifacts; (b) there are **four genuine cross-artifact
contradictions** the per-artifact checks could not see because each checker looked at one file (the keystone's
filename, the F2 hook placement+event, the fork-numbering namespace collision, and the F8/L5 dependency stated
in three different floor-list forms). The architecture survives; the *assembly* does not. Fixing this is prose
edits + one fold-back pass, not a redesign — but shipping as-is means shipping a design whose own adversarial
review found nine defects and a builder cannot tell which "F4" is meant.

Tiered below: **6 MUST-FIX**, **5 SHOULD-FIX**, **4 CONSIDER**.

---

## MUST-FIX

### MF-1 — The WF4 checker MUST-FIX items were never folded back into ANY artifact (the whole checker pass is dangling)

This is the composition failure that subsumes most of the others. The doer-not-checker WF4 pass produced five
check files, each with real MUST-FIX findings. **I re-grepped every one against the current artifact text; none
were applied.** Modification times prove the sequencing (artifacts 15:26–15:29 → checks 15:29–15:33; no artifact
touched after). Item-by-item, verified on the live files:

| Checker MUST-FIX | What it demanded | Current artifact state | Folded? |
|---|---|---|---|
| **roster MF-1** | Add `evaluate-solution` row to skills Table A | `roster.md` Table A still ends at `tdd` (L60); `evaluate-solution` appears **only** as the agent `solution-evaluator` (L167), never as a skill. "22 KEEP" (L66) still asserted, still 21 enumerated. | **NO** |
| **file-tree MF-1** | Move "+5–6 rule shards" out of Budget (2) into Budget (1); state the honest +4-file ledger | `file-tree.md` L232 still books "+5–6 rule shards" under **Budget (2)**; the Budget (1) bullet (L226–228) still lists deletions only. | **NO** |
| **file-tree MF-2** | Explicitly route all 3 non-safety memory traps (`check-branch-before-commit`, `claude-md-referenced-scripts-must-exist`) before memory.md deletion | Only `enforcement-boundary-layering` is routed (L81). The other two appear **nowhere** in the tree; L72 still claims "3 non-safety traps routed." | **NO** |
| **memory-model MF-1** | Drop "so the routing is mechanical"; restate Area-GUIDED + name operation-scoped residuals (RECONCILIATION §D.2 BLOCKER) | `memory-model.md` L179 reads "…present on 36 PITFALLS entries today, **so the routing is mechanical**" verbatim. | **NO** |
| **memory-model MF-2** | Reconcile S1's "ONE reader" against CMP1's second read-path | L54 store table still says S1 reader = "**The platform, by path.**"; L198 still says "the read-path is partly the platform's" with no reconciliation. | **NO** |
| **memory-model MF-3** | Split S1's writer cell (conveyor vs human-only `00-safety`) | L54 still bundles "one logical writer, two trigger points" + "`00-safety` floor is human-edited only" as one cell. | **NO** |
| **github-usage MF-1** | Add the one sentence resolving "CI re-runs deterministic subset vs trust-but-verify" | **Zero** matches for "trust-but-verify" or "coverage-bounded" in `github-usage.md`. The §4a/§0 prose still over-claims judgment-half un-forgeability. | **NO** |
| **github-usage MF-2** | Fix two mis-pointed `§3a` cross-refs → `§2` | L59 still "(§3a, never committed project settings)"; L98 still "§8, §3a". §3a is "The trigger trifecta" (L166); the claim lives in §2 (L143). | **NO** |
| **gaps-risks MF-1/2/3** | Own the checker-voice frame; reconcile sibling artifacts; question the design effort's own independence | `gaps-risks.md` L184/L269 still asserts "this checker re-ran the verification"; **zero** references to `file-tree`/`github-usage`/`memory-model`; no design-effort-independence gap added. | **NO** |

**Why this is the load-bearing finding.** The charge presumes "their MUST-FIX must be folded; verify they are
real." They are real (I re-derived each against disk independently of the checker), and they are **uniformly
unfolded.** A design that ran its own adversarial review and then ignored every blocking finding is, by the
charter's own standard ("doer-not-checker; KEEP THE RIGOR"), not done. The irony is exact: the design ships a
CMP4/P9 reference-integrity loop to catch drift between docs, while itself carrying a checker→artifact drift it
never closed.

**Required correction.** Run the fold-back pass. Each MUST-FIX above is a localized prose edit (the checks
specify the exact replacement). After folding, re-assert the counts that the fixes touch (roster "22 KEEP";
file-tree budget ledger). Do **not** mark WF4 "resolved" until a re-grep confirms zero of the nine strings
survive.

---

### MF-2 — The keystone (F6) has TWO different filenames across artifacts — `ci.yml` job vs new `cr-gate.yml`

The single most load-bearing control in the whole design (F6, "THE KEYSTONE") is specified with **conflicting
file homes**:

- `file-tree.md` L146: "`ci.yml` [CHG] — **gains the F6 STOP-AUTHORITY job**" — i.e. a job added to the
  **existing** `ci.yml`. L185 landing table repeats: "F6 verdict gate (KEYSTONE) | `.github/workflows/ci.yml`
  STOP-AUTHORITY job". L247 ("`ci.yml` enforces").
- `github-usage.md` L238: "A CI job (`.github/workflows/**cr-gate.yml**`, NEW)". L395 diagram: "cr-gate.yml (F6
  enforcement)". L421 lists `cr-gate.yml` among "confirmed-absent" NEW files. L452 verifies "no `cr-gate`" on
  disk.
- `roster.md` L131 names it neither — "the CI verdict gate … CI required-check".

So one artifact says the keystone is a **new workflow file** (`cr-gate.yml`) and the other says it is a **new job
inside the existing `ci.yml`**. These are not interchangeable: a separate required workflow vs a job in an
existing workflow have different branch-protection wiring, different `on:` triggers, and different
"confirmed-absent" status (a new file is absent; a new job in an existing file is not). The file-tree even lists
`ci.yml` as `[CHG]` while github-usage lists `cr-gate.yml` as `[NEW]` — they cannot both be the build target.

**Required correction.** Pick one home for F6 and state it identically in all three artifacts (the roster should
name it too). If the intent is a new required workflow, file-tree's `ci.yml [CHG]` line is wrong; if the intent
is a job in `ci.yml`, github-usage's `cr-gate.yml [NEW]` is wrong and its "confirmed-absent" list must drop it.
This is the keystone — its filename cannot be ambiguous.

---

### MF-3 — F2 credential pre-flight: artifacts disagree on the hook AND the event, and one placement is non-functional

The F2 credential firewall (minimal-floor, "single highest-severity incident class") is placed inconsistently,
and one placement defeats its own purpose:

- `roster.md` L127 (hooks table): a **dedicated NEW hook**, event **"PreToolUse / session-start (blocking)"**,
  "Refuses any unattended run whose readable env holds a prod URL / service-role key … blocking, fails closed."
- `file-tree.md` L181 (landing table): F2 lands as "`init/` + **a pre-flight in `hooks/session-end.sh`/start**".

A credential pre-flight whose job is to **block before** an unattended run touches a prod credential **cannot
live in `session-end.sh`** — `Stop`/session-end fires at the *end* of a turn, after the tool calls (including any
exfiltration) have already executed. The roster's "PreToolUse / session-start" placement is the only correct one;
the file-tree's "pre-flight in `session-end.sh`" would detect the prod credential only after the agent had a full
turn to use it — converting a fail-closed floor into an after-the-fact log. Compounding it: **the file-tree's
own `hooks/` tree (L84–90) lists no credential hook at all** — F2's enforcement half is homeless in the tree,
present only in the landing-table prose. (Same defect class as file-tree-check SF-2, which flagged F3/F5 hooks
missing from the tree; F2 is a third, and it is minimal-floor, so more severe.)

**Required correction.** Fix file-tree to (a) place the F2 pre-flight on **PreToolUse / SessionStart**, not
`session-end.sh`, and (b) give it a dedicated line in the `hooks/` tree, matching the roster's hook entry.

---

### MF-4 — The fork-numbering namespace collides: "F4" means migration-credential (floor) AND egress-depth (decision), disambiguated only by an inconsistently-applied "Fork" prefix

The design runs **two parallel F-numbered namespaces** that overlap on the same integers:

- **FLOOR moves** (Pillar 2): F1 destructive-block, **F2** credential firewall, **F3** egress allowlist, **F4**
  migration-credential, **F5** MCP-trifecta, F6 verdict gate, F7 bounded-loop, F8 circuit-breaker, F9
  disable-model-invocation.
- **DECISION forks** (VISION L763–790): **F2** autonomy-rollout/auto-approval-threshold, **F3** which-trigger-
  ships-first, **F4** egress-depth, **F5** managed-settings.json, F7 repair-worker-aggressiveness, F8 `/lfg`
  driver, F10 convergence-scope.

The only thing separating "F4 = migration-credential" from "F4 = egress-depth" is the word "Fork", and it is
**not applied consistently**:

- `file-tree.md` L182 (one line): "**F3** egress allowlist … (GATED **Fork-F4**)" — here F3 = floor move
  (egress allowlist) and Fork-F4 = decision (egress depth), while the very next landing row L183 is "**F4**
  migration-credential" (floor). So "F4" and "Fork-F4" mean two different things three lines apart.
- `roster.md` L53 "behind the **F2 credential firewall**" (floor F2) vs L84 "live LOW-auto **per Fork F2**"
  (decision F2 = autonomy rollout) — both correct in their own namespace, but a reader must track which F2.
- `github-usage.md` §8 fork table uses F1/F3/F7/F9/F10/F11 (decision namespace) while the body uses F1/F2/F6/F7/F9
  as "the minimal floor" (floor namespace).

A downstream builder reading "gate this on F4" in isolation **cannot tell** whether it means the migration-
credential floor hook or the egress-depth decision. This is precisely the cross-reference ambiguity the design's
own CMP4/P9 reference-integrity checks exist to catch — and the design seeds it into its own spec.

**Required correction.** Rename one namespace. Recommended: keep FLOOR moves as `F1…F9` and rename DECISION forks
to a distinct prefix (e.g. `DF1…DF11` or `Fork-A…Fork-K`), then sweep all five artifacts + VISION. At minimum,
make the "Fork" prefix mandatory and verified on every decision-fork reference (a `gen-rules`/grep gate), so
bare `F4` is unambiguously the floor move.

---

### MF-5 — `memory-model` Edge 2 and `file-tree` MF-2 describe the SAME promotion-routing step but contradict each other on whether it is mechanical

This is a cross-artifact contradiction the per-artifact checks each half-saw. Both artifacts describe the
S3→S1 promotion write (a `/cr` 3b / `/compound` finding promoted into `.claude/rules/<area>.md`):

- `memory-model.md` L179: "the write retargets from `PITFALLS.md` to `.claude/rules/<area>.md` (area from the
  finding's matched `Area:` field … **so the routing is mechanical**)."
- `file-tree.md` L141: "`gen-rules.sh` [NEW] — **deterministically shards** path-globbable PITFALLS entries …
  operation-scoped residuals **named & routed by hand**" — i.e. explicitly **non**-mechanical for the residuals.

So the file-tree already encodes the RECONCILIATION §D.2 correction (split is hand-guided for residuals) in its
`gen-rules.sh` description, while the memory-model still asserts the routing is "mechanical." Two artifacts
describing one mechanism disagree on its central property. (This is memory-model-check MF-1 unfolded **and** a
file-tree↔memory-model contradiction — it is worse as an integration defect than as a single-file defect,
because the file-tree is *already right* and the memory-model contradicts it.)

**Required correction.** Fold memory-model-check MF-1: restate Edge 2 as "Area-GUIDED for the path-globbable
majority; operation-scoped residuals routed by hand to `00-safety.md`," matching the file-tree's own
`gen-rules.sh` line. Then the two artifacts agree.

---

### MF-6 — `evaluate-solution` is absent from the roster but present in the file-tree's kept-skill list — the two rosters do not reconcile

Beyond roster-check MF-1 (the skill missing from Table A), this is a **cross-artifact** inconsistency the
single-file check could not flag:

- `file-tree.md` L93 lists the 22 core-kept skills and **includes `evaluate-solution`** explicitly:
  "cr, cr-security, … queue, **evaluate-solution**, behavior-change, …".
- `roster.md` Table A **omits it entirely** (verified: present only as the agent `solution-evaluator`, L167).

So the file-tree's roster says 22 kept skills *including* evaluate-solution, while the roster's Table A enumerates
21 and never dispositions evaluate-solution. The two "rosters" that are supposed to be the same set **disagree by
one skill**, and the disagreement is exactly the skill with a human-in-the-loop gate (the
"human-steps-required" output, the three-skill auto-invoke surface) that most needs an explicit F9 disposition.
The P6 manifest and `/init` materialization both consume "the roster" — they will get two different answers
depending on which artifact they read.

**Required correction.** Add the `evaluate-solution` row to roster Table A (disposition + failure mode + F9
note), making the roster's set identical to the file-tree's L93 list and closing the "22 KEEP" count.

---

## SHOULD-FIX

### SF-1 — `scripts/` count "7 → 10" disagrees with the file-tree's own enumerated 6 baseline (and the disk truth is 6)

`file-tree.md` L138: "scripts/ [CHG] 7 → 10". The `[KEEP]` line (L140) enumerates exactly **6** source scripts
(`gc`, `gen-local-env`, `pr`, `seed.ts`, `test-local`, `worktree-add`); disk confirms 6 source scripts. 6 + 3 new
(`gen-rules`, `migration-lint`, `repo-structure`) = **9, not 10**. This is file-tree-check C-3 unfolded; it is a
SHOULD here (not a CONSIDER) because the manifest/`/init` will trust the count. Reconcile to "6 → 9".

### SF-2 — Header "26 → 25 core" contradicts the 22-skill list the same section enumerates

`file-tree.md` L92 header says "26 → 25 core" but L93 lists exactly **22** core-kept (26 − dep-update −
notion-sync − 2× supabase = 22). The "25" reconciles to no clean subset. file-tree-check C-1 unfolded. Make it
"26 → 22 core kept + 7 new". (Pairs with MF-6 — once evaluate-solution is in the roster, both rosters and this
header must read 22.)

### SF-3 — `auth-routing.md` shard glob points at `src/proxy.ts`, which does not exist; the proxy is at repo root

`file-tree.md` L79: "`auth-routing.md` paths: `app/**,src/proxy.ts,middleware*`". On disk the proxy is
**`./proxy.ts`** (repo root), not `src/proxy.ts`, and there is no root `middleware*` file. A `paths:` glob that
matches nothing means the shard **never auto-loads when the agent edits the proxy** — the exact "fake shard that
doesn't auto-load" failure the tree warns against (L46). Since the shard mechanism is the memory-model's core
budget-(1) claim, a dead glob silently no-ops the load-bearing area rule. file-tree-check SF-3 unfolded. Fix to
`app/**,proxy.ts` and correct/drop `middleware*`.

### SF-4 — P4 (MCP-as-substrate, P0-spine) has a landing-table row but no file home in the tree

`file-tree.md` L209 lists P4 in the landing table ("externally-summonable endpoints, RemoteTrigger-style") but
the target tree (L61–162) has **no** endpoint script / server / manifest for it. The one `.mcp.json` (L134) is
the harness as MCP *client* (servers it ships), which is the opposite of P4's "make the harness *summonable*"
(server). P4 is tagged **P0-spine** in VISION (built in lockstep with L1), not deferred — so a P0 move shipping
with a prose-only home is a spine-altitude gap. github-usage §3b L194–203 does give P4 a concrete home
(`summon.yml` → P4 entry point → worktree shell), so the fix is to **import that into the file-tree** (the two
artifacts already agree on the mechanism; only the file-tree omits the file). file-tree-check SF-1.

### SF-5 — The deferred-trigger prerequisite is stated three ways across VISION and github-usage (F5+F3 / F3+F8 / F5-only)

github-usage-check SF-1, unfolded. `github-usage.md` §3a L171–172 says Slack/CI triggers ship "After **F5 + F3**";
VISION L138–139 says they "wait for **F3 + F8**"; VISION L109/L136 frames **F5** as the gate "for the Slack/Linear
summon path." Three different prerequisite sets for the same deferred legs. The "F5 + F3" reading is the most
coherent (F5 = trifecta gate for untrusted content; F3 = egress), but it is a **silent resolution of a VISION
inconsistency**, which the charter forbids. Surface it: reconcile to {F3, F5, F8} or flag as a Tanner thread. (This
also interacts with MF-4: "F5" here is the floor move, "F8" the circuit-breaker floor move — confirm namespace.)

---

## CONSIDER

### C-1 — Dogfood the P9 reference-integrity check on `design/v2/**` — it would have caught MF-1/2/4

github-usage-check C-3 makes this point and it is correct: the design specifies a P9/CMP4 reference-integrity CI
check whose job is exactly "no broken cross-refs, every named artifact exists." Run it (even by hand) over the v2
design docs themselves and it surfaces the §3a mis-pointers (MF-1's github-usage row), the two filenames for the
keystone (MF-2), and the dead `src/proxy.ts` glob (SF-3). The design indicts a drift class it then ships. Make
`design/v2/**` the first test corpus for the check before it ships.

### C-2 — `.cr-ok [KEEP]` in the tree is a gitignored transient, not a committed file — tag it so

`file-tree.md` L122 marks `.claude/.cr-ok [KEEP]` alongside static files; it is a runtime-generated, gitignored
sentinel (absent on disk between runs). Not a harmful phantom (mechanism is real, `.gitignore:57-58` confirms),
but `[KEEP]` invites a reader to expect a tracked file. Tag `[KEEP-MECHANISM]` / "transient, gitignored".
file-tree-check C-2.

### C-3 — The memory-model's S1 dual-reader / dual-writer (MF-2/MF-3 of its check) is a real seam, not just a wording fix

Even setting aside the unfolded-check status, the integration view confirms the memory-model-check's MF-2/MF-3
are substantive: S1 genuinely is read by both the native `paths:` auto-loader (passive) and CMP1's task-start
glob (active, `/dev`/`/feature`/`/cr` Phase-0, L195), and written by both the promotion conveyor and human-only
`00-safety` edits. The fix is to *state* the two-reader/two-writer reality honestly (option (a) in the check), not
to claim "ONE" and contradict it three sections later. Flagged as CONSIDER (not MUST) only because it is folded
into MF-1's fold-back pass; do not let the fold-back paper it with a word-swap that re-asserts "ONE".

### C-4 — No global fleet kill-switch is a cross-cutting gap the gaps-doc under-ranks; it touches every loop artifact

gaps-risks-check C-4. VISION has F8 (per-defect-class) + F7 (per-loop) but no "halt the entire fleet now" control;
Fork F9 is paging, not halt. At 5+-repo scale this is a composition-level gap — it is not owned by any single
artifact, which is *why* it slipped (each artifact assumes someone else owns the stop). Either promote it to a
named risk (R6) in gaps-risks, or give it a home in the roster/file-tree (a fleet-wide `STOP` marker the
`/schedule` + `/queue` + L1 paths all check). Right now it is owned by nobody.

---

## What HELD under attack (so the verdict isn't read as a teardown)

- **Build order is sound.** VISION L681–714: the ordering invariant ("no trigger fires until the small floor it
  rides on is wired") holds end-to-end. Phase 0 = the minimal floor (F1/F2/F6/F7/F9) including the keystone F6
  *before* every consumer; L5 `/lfg` explicitly "resolve Fork F8 first" (Phase 1); LOOP-7 ships **observe-only**
  in Phase 2 (after F6 + C4) and live LOW-auto only in **Phase 4** (after C4 recall is measured). **Nothing depends
  on something sequenced later** — I traced auto-approval→F6/C4, L5→F8, the trigger trifecta→F5/F3, the plugin→
  canon convergence; all gates precede their consumers. The auto-approval-before-F6 and trigger-before-floor
  hazards the charge named are both correctly avoided.
- **Move completeness holds.** Every VISION move (L/F/C/CMP/P/HOOK-1/LOOP-7) has a file-tree landing-table row and
  a roster home; the demoted-to-clause moves (L3→L2, C1→F6, C3→F7, C7→F6+C6, C13-recurring→CMP6) are noted at
  their hosts. No orphaned move.
- **Roster integrity (anti-phantom) holds.** Every NEW skill/hook is genuinely absent on disk (re-confirmed via
  the checks' disk greps: `goal`/`lfg`/`verify`/`scan-context`/`ratchet`/`cr-calibrate`/`init`,
  `block-dangerous-bash.sh`, `session-end.sh`, `cr-gate.yml`/`summon.yml`, `.claude-plugin/`, `.claude/rules/` —
  all ABSENT). No §F rejected pattern smuggled in (collapse-23→1 explicitly dead; no-shared-context reviewer
  honored as C2 shared-canon/isolated-solution). All 23 agents kept with distinct failure modes.
- **The memory-model spine is right.** Entry-as-atom genuinely dissolves the §4 file-as-unit dual-assignment;
  the S3 airlock is the correct over-collapse guard; `learned-patterns.md` correctly NOT rebuilt (read-path is the
  kept form). The defects are at the seams, not the architecture.
- **github-usage's distribution/enforcement mechanics are right.** The 27-byte-proof plugin/permissions seam,
  autoMode→local/managed, the label-trigger-first carve-out, convergence-as-publish-gate-only — all sound and
  cited correctly. The defects are MF-1's unfolded resolution sentence + the cross-refs, not the mechanism.

---

## Bottom line for the parent

**UNSOUND-AS-INTEGRATED, mechanically correctable.** The five artifacts are individually strong and the spine
(moves, build order, anti-phantom, store discipline) is coherent. But the design was **not assembled**: (1) the
entire WF4 checker pass ran and was never folded back — **9 MUST-FIX items are open across all five artifacts**
(verified by re-grep against the current files; mod-times prove no artifact was edited after its check); and (2)
there are **four genuine cross-artifact contradictions** the per-file checks could not see — the keystone F6's
filename (`ci.yml` job vs new `cr-gate.yml`), the F2 credential hook's placement+event (correct PreToolUse vs
non-functional `session-end.sh`), the **F-number namespace collision** (bare `F4` = migration-credential floor
*and* egress-depth decision, disambiguated only by an inconsistent "Fork" prefix), and the evaluate-solution
roster↔file-tree mismatch. Fix order: **MF-1 (fold the 9 checks) first**, then MF-2/3/4/5/6 (the cross-artifact
contradictions), then the SHOULD-FIX count/glob/home reconciliations. None requires a redesign; all are prose +
one fold-back pass. Until the fold-back is done and re-grepped clean, this design is shipping with its own
adversarial review unaddressed.
