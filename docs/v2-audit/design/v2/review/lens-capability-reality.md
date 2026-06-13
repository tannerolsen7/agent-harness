# Lens: CAPABILITY-REALITY — adversarial review of the integrated V2 design

> **Lens charge.** Attack every move against `design/capability-facts.md`. Flag any move that assumes a
> non-existent capability. Adjudicate the KEYSTONE PRECISION: does the design honestly state F6 = SHA-match +
> CI-recomputed deterministic checks (un-forgeable) while the 9+4 `/cr` judgment passes are coverage-bounded
> trust-but-verify (surfaced, NOT the merge gate) — or does it over-claim that F6 makes "the model agreed with
> itself" un-shippable? Doer-not-checker: I re-verified every load-bearing capability and absence on disk this
> session before relying on it (the audit rotted mid-effort — R4 — so I trusted nothing from the artifacts).

## Disk re-verification performed this session (2026-06-11) — so the attack stands on facts

- Hooks on disk: `block-dangerous-git.sh`, `block-npm-install.sh`, `permission-logger.sh`, `session-start.sh`,
  `worktree-create.sh`. **ABSENT (confirmed):** `block-dangerous-bash.sh`, `session-end*.sh`, `.claude/rules/`,
  `.claude-plugin/`, `.claude/harness-manifest.json`, `docs/research/v2-audit/golden-set/`. ✅
- `.claude/settings.json`: Stop hook at line 191 (a sound only); `autoMode` block at line 6. ✅
- `.gitignore:58` = `.claude/.cr-ok` (gitignored). ✅
- `scripts/pr.sh`: builds `EXPECTED="${CURRENT_BRANCH}:${HEAD_SHA}"` (line 17), then `mv`s the sentinel to
  `.cr-ok.consumed.$$`, `cat`s it, and `rm`s it (lines 31–45) — **the sentinel is consumed locally before the PR
  opens.** ✅
- `.github/workflows/`: only `ci.yml` (runs `tsc`/`eslint`/`test:unit` on the head SHA) + `integration.yml`. CI
  has **zero** knowledge of `.cr-ok`. ✅
- `disable-model-invocation` in any `SKILL.md`: **0 of 26** (F9's gap is real). ✅
- `data-testid` in `src/`/`app/`: **0** (C9's gap is real). ✅
- `chrome-devtools-mcp` is the configured `chrome` MCP (project `.mcp.json`) — so C8's "headed-only → CI headless
  leg" is a *real* constraint to attack, not a phantom. ✅

Every "absent on disk" claim the design rests on is true. No phantom rebuilds detected.

---

## VERDICT: SOUND-WITH-CORRECTIONS — but the KEYSTONE over-claim was diagnosed and NOT folded back, so it ships live

The capability discipline of this design is, across the board, the best-grounded I have attacked: the
hooks-can-run-tests-and-block fact is used correctly, the no-hook-can-compel-an-artifact fact is honored (C10 →
verify-if-present at hook, hard at CI via C8), the autoMode-ignored-in-committed-settings bug is correctly routed
to local/managed, `disable-model-invocation` is honestly hedged as documented-but-uncorroborated, and the
force-continue unknown is correctly named as a Phase-0 probe with a fallback. The capability-facts file is treated
as a binding constraint, not a footnote.

**But the single most load-bearing precision in the whole design — the keystone — is over-claimed in the
shipping artifacts, and the check that caught it (`checks/github-usage-check.md` MF-1) was never folded back.**
The correct answer to the keystone charge is: **F6's un-forgeable gate is SHA-match + CI-recomputed deterministic
checks (`tsc`/`eslint`/`test`) on the head SHA — the model writes no record CI re-reads, CI computes the result
itself. The 9+4 `/cr` judgment passes are coverage-bounded trust-but-verify (bounded by C4 recall), surfaced as a
queryable artifact but NOT the merge gate.** The design *builds* exactly this honest gate (github-usage.md §4b
step 2) — but then *narrates* it, in three places, as if it closes the judgment-forgery hole ("done requires
MUST-FIX=0 … where the loop cannot forge it"). It does not. A loop whose 9+4 lenses share the generator's blind
spot still passes this gate as long as tsc/eslint/tests are green — *which is precisely the failure §4a claims to
prevent.* That is MUST-FIX-1 below, and it is the one finding that, left unfixed, ships a design believing its
keystone is stronger than it is.

The remaining capability findings are smaller: two genuinely-unverified runtime assumptions (C8 headless,
managed-settings honored) that the gaps-doc names but the design treats as load-bearing; and a confirmation that
the per-artifact MUST-FIX items are real (I re-derived them) — but at least one (github-usage MF-1) and one
file-tree MF were *diagnosed in the check files and not propagated into the design artifacts*, so "verify they are
folded" returns **NOT folded** for the keystone.

---

## MUST-FIX

### MF-1 — THE KEYSTONE OVER-CLAIM: F6 is narrated as making "the model agreed with itself" un-shippable, but the gate as built only enforces SHA-match + CI-recomputed determinism. (The check caught this; it was NOT folded back.)

This is the precision the lens charge singles out, and it is the one place the integrated design is
**unsound-as-narrated**. The contradiction is internal and live in three artifacts:

**What is actually un-forgeable (traced to disk, re-verified this session):**
- `scripts/pr.sh` (lines 31–45) **consumes** the sentinel — `mv` to `.cr-ok.consumed.$$`, `cat`, `rm` — *before
  the PR opens.* `.gitignore:58` ignores `.claude/.cr-ok`. So at CI time, on the pushed SHA, the sentinel **does
  not exist in the repo at all.** The only thing CI can run un-forgeably is what `ci.yml` already does — check out
  the SHA and run `tsc`/`eslint`/`npm run test:unit` itself. The model cannot fake a result CI computes.
- `capability-facts.md:76` confirms this: "`.claude/.cr-ok` is gitignored (`.gitignore:58`) — confirms it never
  reaches CI (Node 8.5c)."

**Where the design over-claims (all three live and unfixed):**
- **github-usage.md §4b step 2 (lines 242–243)** specifies the gate correctly: "FAILS unless `sentinel_sha ==
  head_sha` AND all required checks … are green." Read literally, *this is the honest trust-but-verify gate* — it
  does NOT re-derive MUST-FIX=0. **So the enforcement the artifact specifies is sound.**
- **But github-usage.md §4a / the §0 thesis** assert F6 stops "the model agreed with itself" from shipping, and
  **§4b's "surface face" (lines 254–259)** says the MUST-FIX verdict is *queryable* — never says it is **not the
  merge gate.** The §4b step-1 phrasing ("Parses `branch:sha` from the verdict artifact … the `.cr-ok` content
  shape `pr.sh` already produces") reads as if CI ingests a `branch:sha` record; **CI cannot** (pr.sh consumed it,
  it is gitignored). §4c later corrects this — so §4b and §4c are in tension on the same page, exactly as the check
  flagged.
- **VISION.md delta-#3 (line 659)** states it most strongly and most wrongly: *"V2 (F6): 'done' requires
  **MUST-FIX=0 AND CI-green-on-SHA** enforced in branch protection where the loop cannot forge it."* The gate in
  github-usage.md §4b **does not check MUST-FIX=0 at all.** This is the spine asserting the un-forgeability of the
  judgment half, which is false.

**The verdict on the charge:** the design **over-claims.** F6 does NOT make "the model agreed with itself"
un-shippable — it makes "the model shipped red `tsc`/`eslint`/`test` or a stale-SHA review" un-shippable. The 9+4
judgment passes remain coverage-bounded trust, bounded by C4 recall, and a confidently-wrong all-green PR (the
exact F7 failure mode) sails through. The honest framing exists *as the built gate*; it is contradicted by the
prose around it and by the spine.

**Why "not folded" matters (doer-not-checker on the check itself):** `checks/github-usage-check.md` MF-1 already
diagnosed this precisely and prescribed the one-sentence fix. I grepped github-usage.md this session: it contains
**zero** instances of "trust-but-verify," "coverage-bounded," or "C4 recall" as the keystone framing, and never
states MUST-FIX=0 is "surfaced but NOT a merge gate." **The check's MUST-FIX was not propagated into the
artifact.** The prompt's instruction to "verify they are real and folded" returns: *real, not folded.*

**Required fix (fold into github-usage.md §4b AND VISION line 659):** state in one sentence — *the enforceable
gate is SHA-match + the deterministic `tsc`/`eslint`/`test` checks re-run by CI on the head SHA (un-forgeable; the
model writes no record CI re-reads); the 9+4 judgment passes are **coverage-bounded trust-but-verify**, bounded by
C4 golden-set recall, surfaced (queryable via Fork F1) but **NOT the merge gate.*** Then either (a) commit to
CI-re-running a deterministic `/cr` subset and name which passes are mechanizable, or (b) accept trust-but-verify
explicitly (`RECONCILIATION §C.5` recommends "(a)+(b)"). Correct VISION line 659 to drop "requires MUST-FIX=0 …
where the loop cannot forge it" — replace with "requires CI-green-on-SHA (un-forgeable) plus a surfaced,
recall-bounded review verdict (trust-but-verify)."

*Failure mode if unfixed:* the design ships believing its keystone is un-forgeable for the judgment half; the
first all-green-but-wrong overnight PR merges through a gate everyone — including LOOP-7's auto-approval, which
**consumes F6 as its deterministic last gate** (VISION LOOP-7) — believed caught it. The label trigger's safety
claim (minimal floor {F1,F2,F6,F7,F9}) inherits the *corrected* F6 scope: it rests on F6's deterministic half +
F7's bounded-loop, not on a fully un-forgeable verdict.

### MF-2 — Two runtime capabilities the spine leans on are UNVERIFIED, and the design treats them as load-bearing facts, not probes.

`capability-facts.md` is honest that several capabilities are reasoned-from-docs, not executed. The design
correctly elevates **force-continue** to a Phase-0 probe with a named fallback (VISION L2/C10, capability-facts.md
:13-16). But **two other unverified capabilities are used as if settled**, and only the gaps-doc (not the design
artifacts) flags them:

- **`chrome-devtools-mcp` headless (C8).** C8 routes the unattended render gate to a CI job "because
  chrome-devtools-mcp is headed-only" (file-tree.md line 100; VISION C8 line 392). I confirmed chrome-devtools-mcp
  *is* the configured MCP — but **"headed-only" and "the CI headless leg works against a preview deploy" were never
  exercised this session** (gaps-risks.md Gap #1, R2 residual). C8 is tagged a *hard* render gate on the CI leg;
  an unverified headless path is not a hard gate. **Fix:** demote C8's CI leg to "hard gate *pending* a one-run
  headless-against-preview confirmation," matching how L2 treats force-continue — a named probe, not an assumed
  fact. Add it to the Phase-0 probe list alongside force-continue.
- **`managed-settings.json` honored on macOS (F9/P2/Fork F5).** `capability-facts.md:39-41` says managed settings
  "genuinely override everything" **but the macOS managed path is verified *absent*, not verified *working*** — and
  F9's truly-unbypassable floor, P2's `/init` enforced-tier, and Fork F5 all lean on it. The design correctly makes
  *placing* it a human handoff, but never flags that **the override has never been observed to take effect on this
  OS.** **Fix:** add a one-line precondition — "managed-settings override is documented, not exercised on macOS;
  verify once before treating it as the enforced floor; until then F9's enforced tier is `deny`-in-committed-
  settings (agent-reachable) + the social rule." This keeps F9 honest about which of its two tiers is real today.

Both are "documented-but-uncorroborated" in the same class as `disable-model-invocation` "removes from context"
(which the design *does* hedge, github-usage.md §9). The asymmetry — one hedged, two not — is the defect.

---

## SHOULD-FIX

### SF-1 — `disable-model-invocation` "removes from context" is the load-bearing isolation guarantee for F9, and it is uncorroborated on the target CC version — F9 degrades to +1 advisory line if it fails, which the design under-states.

github-usage.md §9 hedges this honestly ("verify before relying on it as a hard isolation guarantee; else F9 is +1
advisory line, not a removal"). **But F9 is a P0-floor move** (VISION line 316) and the *entire* "safe actuator
only a pinned orchestrator can summon" thesis (L5/L1 side-effect tails, P4's F9-gated egress) rests on the removal
being real. capability-facts.md:30-33 confirms the *field names* and that the field exists, but **not** that
`true` removes the skill from the model's reachable set on the target version. **Fix:** promote this from a §9
footnote to a named Phase-0 probe (it is cheap: set `disable-model-invocation:true` on one skill, confirm the model
cannot invoke it). If it fails, F9's whole pillar-2 contribution collapses to advisory and the floor's "deterministic
below the model's reach" claim (VISION pillar 2) is false for the side-effect-skill lockout. This is a bigger risk
than the §9 hedge implies.

### SF-2 — CMP5's corrected-mistake capture is correctly NOT claimed as deterministic — but the gating "can the Stop hook SEE the correction signal" probe (D2) is buried, and the loop's read-back quality (CMP1) depends on it.

The memory-model and VISION both handle CMP5 correctly per the charge: the capability-facts constraint is that "no
deterministic Stop-hook can detect a corrected-mistake" (CMP5 must be human-confirmed), and the design honors this
verbatim — CMP5 "proposes; the human confirms … deliberately NOT a deterministic mistake-detector" (memory-model.md
Edge 1; VISION CMP5). **This is the right call and survives the attack.** The residual issue is sequencing: D2 (can
a Stop hook even *see* the turn's correction signal to propose from?) is a one-session empirical check
(memory-model.md D2), and if it fails, CMP5 degrades to `/cr` 3b + manual append. That degrade path is sound, but
**CMP1's read-back quality (the compounding loop's whole value) is gated on CMP5's proposer being non-noisy**
(gaps-risks.md R3). **Fix:** state explicitly that CMP1's effectiveness metric (first-pass-approval, CMP3) is the
*detector* for a noisy CMP5 — i.e., wire the degrade decision to data, not just to the one-time D2 probe. This keeps
the human-confirm gate (correct) while closing the "learns from noise" risk.

### SF-3 — The label-trigger "minimal floor makes it safe" claim inherits the corrected F6 scope; restate the floor's safety basis once MF-1 lands.

github-usage.md §3a (line 178) says the label trigger "needs only the minimal floor {F1, F2, F6, F7, F9}." Post-MF-1,
F6's contribution to that floor is its **deterministic half** (SHA-match + CI-green) plus F7's bounded-loop/REJECT —
**not** a fully un-forgeable verdict. The carve-out itself (label = controlled token, no free-text injection, ships
before F3/F5) is **capability-correct and survives** — a GitHub label genuinely carries no attacker free-text, and
the GitHub Action on `issues: {types: [labeled]}` is a real, buildable mechanism (no capability violation). Only the
*basis* of the safety claim needs the MF-1 correction threaded through, so the floor isn't read as resting on an
over-claimed gate. (This is `checks/github-usage-check.md` C-4, which I confirm is real.)

### SF-4 — Per-artifact-check MUST-FIX propagation is incomplete: at least two diagnosed MUST-FIX items were never folded into the design artifacts they target.

The prompt asks me to verify the per-artifact checks' MUST-FIX items are real and folded. I re-derived them; they
are real. But "folded" fails for at least two:
- **github-usage MF-1 (the keystone)** — NOT folded (MF-1 above; grep confirms the resolution language is absent
  from github-usage.md and the over-claim is live in VISION line 659).
- **file-tree MF-2** — the tree claims "3 non-safety traps routed" but routes only 1
  (`enforcement-boundary-layering` → `harness-hooks.md`); `check-branch-before-commit` and
  `claude-md-referenced-scripts-must-exist` are not routed anywhere in file-tree.md. Since memory.md's deletion is
  gated on all three being real targets (`RECONCILIATION §B.4` BLOCKER), this is a capability-adjacent safety gap:
  two traps can be silently lost at deletion. I re-confirmed the under-routing by reading file-tree.md lines 72–81.

**Fix:** treat the check files as a *checklist with open items*, not as "folded." Run a propagation pass that
applies each check's MUST-FIX to its target artifact, and add a CI dogfood of P9's reference-integrity check on
`design/v2/**` (the check artifacts' own C-3 suggestion) so this class of "diagnosed-but-not-applied" drift is
caught mechanically — the design indicts exactly this failure (CMP4 fiction-mode) and then exhibits it.

---

## CONSIDER

- **C-1 — No capability violation in the trigger/distribution mechanics.** I attacked these specifically: the
  GitHub Action on label (no force-continue dependency), `/plugin install`/`update` + marketplace (capability-facts
  .md:56-71 confirms the channel, the 27-byte settings cap, version pinning), the plugin-can't-carry-permissions
  seam (→ `/init`, P2), and P4's MCP-as-substrate (cloud `/schedule` runs committed skills, so durability is moot).
  All are capability-sound. The one nuance worth a downstream half-sentence: if Fork F1 resolves to the GitHub
  Checks API, the `cr-gate` check-run is *posted by the loop's own pipeline* (`pr.sh`/the Action) — queryable and
  required, but **a model-adjacent writer does not make the MUST-FIX=0 content un-forgeable**; only
  branch-protection-required + CI-recomputed-determinism does. This reinforces MF-1 (queryable ≠ un-forgeable).

- **C-2 — `chrome-devtools-mcp` and Playwright both configured (mcp.md:111 notes the overlap).** C8 keeps
  chrome-devtools-mcp for *attended* debugging and routes unattended to CI — capability-correct framing. Note only
  that the headless leg's actual driver (Playwright headless vs a headless-Chrome CI action) is unspecified; pin it
  when C8 is built so the "headless against preview deploy" assumption (MF-2) is concrete, not hand-waved.

- **C-3 — The §9 deletion engine (CMP6) has never run once — no baseline (gaps-risks.md Gap #6).** Not a
  capability violation (the behavioral-probe mechanism is sound and correctly human/NEEDS-HUMAN-gated via Fork F7),
  but CMP6 is "the safety interlock for the entire de-scaffolding program" and an interlock that has never fired is
  itself unverified. A single manual §9 run against Opus 4.8 would produce the baseline. Phase-4, so below the
  spine — flagged for completeness.

- **C-4 — No global fleet kill-switch (gaps-risks.md Gap #7, gaps-risks-check.md C-4).** F8 is per-defect-class,
  F7 is per-loop, Fork F9 is paging-not-halt. At 5+-repo laptop-closed scale, "stop the entire fleet right now" has
  no designed control. Not a capability *violation* (it is buildable), but a real absence the design never names as
  a control. Worth promoting to a named risk before fleets run at volume.

---

## Scorecard against the lens charge

| Charge | Finding |
|---|---|
| Hook compelling a screenshot/artifact (C10 must be verify-if-present + CI-leg) | **PASS** — C10 scopes render to verify-if-present at hook, hard at CI (C8), cites capability-facts.md:18-20 correctly. |
| Force-continue Stop-hook for `/goal` (named Phase-0 probe + fallback) | **PASS** — L2/C10 gate on a named Phase-0 probe with external-re-invocation fallback (VISION, capability-facts.md:13-16). |
| autoMode read from committed project settings (must be local/managed) | **PASS** — routed to `settings.local.json`/`managed-settings.json`, cites the inert-config bug (capability-facts.md:42-46). |
| `chrome-devtools-mcp` headless (must be CI preview) | **PARTIAL → MF-2** — correctly routed to CI, but the headless-against-preview path is *unverified* and treated as a hard gate. |
| A plugin carrying permissions | **PASS** — 27-byte cap honored; permissions → `/init` (P2). No violation. |
| Deterministic Stop-hook detecting a corrected-mistake (CMP5 human-confirmed) | **PASS** — CMP5 explicitly NOT a deterministic detector; human-confirms (SF-2 only sequencing). |
| **KEYSTONE: F6 honestly stated (SHA + CI-determinism un-forgeable; 9+4 = trust-but-verify, surfaced not gate) OR over-claimed?** | **OVER-CLAIMED → MF-1** — built honestly (§4b step 2) but narrated as MUST-FIX=0-un-forgeable in §4a, §4b surface, and VISION line 659. The check (github-usage MF-1) caught it; **not folded.** |
| `disable-model-invocation` removal guarantee | **HEDGED but under-tiered → SF-1** — honestly hedged in §9, but F9 is P0-floor and the hedge should be a probe. |

**Bottom line.** SOUND-WITH-CORRECTIONS. The capability discipline is genuinely world-class on six of eight axes —
no plugin-permissions violation, no autoMode-in-committed-settings violation, force-continue correctly probed, CMP5
correctly human-gated, C10 correctly CI-legged. The blocking work is the keystone (MF-1): the design *builds* the
honest SHA-match + CI-determinism gate but *narrates* it as closing the judgment-forgery hole, and the check that
caught this was never folded into github-usage.md or VISION line 659 — so the over-claim ships. Fix MF-1, fold the
two unverified-capability probes (MF-2) into the Phase-0 list, promote the F9 removal-guarantee to a probe (SF-1),
and run the check-propagation pass (SF-4), and the design's capability claims are honest end-to-end.
