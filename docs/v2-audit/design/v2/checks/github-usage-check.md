# Adversarial check — `github-usage.md` (V2 GitHub-usage design)

> **Posture:** doer≠checker. A different agent authored `github-usage.md`; this pass *attacks* it. Charge: the
> six precision questions in the prompt + any capability claim that contradicts `capability-facts.md`. Every
> finding is grounded against ground-truth re-verified on disk this session, `VISION.md`, `DECISION-PACKAGE.md
> §4b–§4e`, and `RECONCILIATION.md §C.5/§F.5`. Tiered MUST-FIX / SHOULD-FIX / CONSIDER + a verdict.

**Verdict: SOUND-WITH-CORRECTIONS.** The design's central mechanics are correct and survive attack: the un-forgeable
half of the CI gate is genuinely un-forgeable, the plugin/permissions seam is right, autoMode lands local/managed (not
committed project), the label-trigger carve-out is preserved, and convergence is correctly scoped to the PUBLISH gate
only. No capability claim contradicts `capability-facts.md`. **But** the keystone (§4, F6) leaves the one precision the
prompt asks me to resolve — *"CI re-runs the deterministic `/cr` subset vs. trust-but-verify"* — **unresolved and
papered over by an internal inconsistency**: §4b says CI "FAILS unless … all required checks are green" (the
un-forgeable half) while the surrounding prose still frames the MUST-FIX verdict as if it gates the merge. That gap is
the one MUST-FIX. Two mis-pointed cross-refs and a VISION-divergent floor list round out the corrections.

---

## The six charges — adjudicated

| # | Charge | Verdict |
|---|---|---|
| 1 | CI gate un-forgeable; model writes no trusted record CI re-reads; resolve re-run-subset vs trust-but-verify | **PARTIAL** — un-forgeable half correct; the precision is *named* (routed to F1) but **not resolved**, and §4b/surrounding prose blur whether MUST-FIX=0 gates. **MUST-FIX.** |
| 2 | Plugin/permissions seam correct (plugin can't carry permissions → `/init`) | **SOUND.** Matches `capability-facts.md:56–60`; the 27-byte proof is cited correctly; `/init` owns exactly the un-shippable files. |
| 3 | autoMode lands local/managed, NOT committed project | **SOUND.** §2 line 143–146 is exactly right and cites `capability-facts.md:42–46`. |
| 4 | Label-trigger-first injection carve-out preserved | **SOUND** (with a SHOULD-FIX: the named floor diverges from VISION's). |
| 5 | Convergence is the PUBLISH gate only (enforcement/memory run in parallel) | **SOUND.** §1 point 4 carries `DECISION-PACKAGE §4e` verbatim and correctly. |
| 6 | Any capability claim contradicting `capability-facts.md` | **NONE found.** The one soft spot (`disable-model-invocation` "removes from context") is honestly hedged in §9. |

---

## MUST-FIX

### MF-1 — The keystone (§4) does not resolve the prompt's precision, and §4b's framing blurs the forgeable half.

This is the charge the prompt singles out ("Resolve the 'CI re-runs the deterministic /cr subset vs trust-but-verify'
precision") and it is the one place the artifact is genuinely unsound-as-written.

**What is actually un-forgeable, traced to disk:**
- `pr.sh` (read this session) builds `EXPECTED="${CURRENT_BRANCH}:${HEAD_SHA}"`, then **moves the sentinel to
  `.cr-ok.consumed.$$` and `rm`s it** (lines 31–45). The sentinel is *consumed locally before the PR opens.*
- `.gitignore` (verified) ignores `.claude/.cr-ok`. So at CI time, on the pushed SHA, **the sentinel does not exist
  in the repo at all** — not stale, *absent.*
- Therefore the only thing CI can run un-forgeably is what `ci.yml` already does: `tsc` / `eslint` / `npm run
  test:unit` **on the head SHA itself** (CI checks out the SHA and runs them — the model cannot fake that).

`RECONCILIATION.md §C.5` (the baseline's own adversarial correction) states the split precisely and the artifact does
not honor it:
> "The forgeable half is 'CI re-derives MUST-FIX=0 from a committed `/cr` artifact' — but if the *model* writes that
> artifact, the forge just moves one layer up. … The CI-required-checks-green-on-sentinel-SHA half IS genuinely
> unforgeable; only the MUST-FIX=0 half needs this. Recommendation: (a) [CI re-runs the deterministic subset] for the
> mechanizable passes + (b) [trust-but-verify, honestly stated] for the rest."

And `DECISION-PACKAGE.md` (lines 174–178) locks the baseline mechanism: *"make the **existing** CI lane
(`tsc`/`eslint`/`test`) the required gate on the sentinel SHA via branch protection (mechanizable, unforgeable); the
judgment passes (the 9 + 4 lenses) stay **coverage-bounded trust**."* This is also **open decision #5** in
`RECONCILIATION §F` and **Fork F1** in VISION — *unresolved by design.*

**Where `github-usage.md` goes wrong:** §4b step 2 says the gate "**FAILS unless** `sentinel_sha == head_sha`
**AND** all required checks (`tsc`, `eslint`, `test:unit`, integration) are green." Read literally, that is **exactly
the un-forgeable trust-but-verify gate** — it does *not* re-derive MUST-FIX=0, and the deterministic checks are run by
CI on the SHA. So the *enforcement* the artifact actually specifies is sound. **The problem is the prose around it
claims more than the gate delivers** and never says which side of open-decision-#5 it lands on:
- §4a / the §0 thesis / VISION-delta-#3 all assert F6 makes "the model agreed with itself" un-shippable and that
  "done requires MUST-FIX=0 … where the loop cannot forge it." But the gate in §4b **does not check MUST-FIX=0 at
  all** — it checks SHA-match + deterministic-green. The MUST-FIX verdict is relegated to the *surface face*
  (queryable, explicitly "not the enforcement gate"). So the artifact simultaneously (a) builds the honest
  trust-but-verify gate and (b) narrates it as if it closes the judgment-forgery hole. It does not. A loop whose 9+4
  lenses share the generator's blind spot still passes this gate as long as tsc/eslint/tests are green — *which is
  precisely the failure mode §4a claims to prevent.*
- §4b step 1 ("Parses `branch:sha` from the verdict artifact — the `.cr-ok` content shape `pr.sh` already produces")
  reads as if CI ingests a `branch:sha` record. **CI cannot**, because `pr.sh` consumes the file and it is gitignored.
  §4c later corrects this ("That rules out the current gitignored `.cr-ok`") and routes the surface to Fork F1 — so
  §4b and §4c are in tension on the page. A reader of §4b alone would believe CI reads a `.cr-ok` it never sees.

**Required fix.** State the resolution the prompt demands, in §4b, in one sentence: *the enforceable gate is
SHA-match + the deterministic `tsc`/`eslint`/`test` checks re-run by CI on the head SHA (un-forgeable; the model
writes no record CI re-reads — CI computes the result itself); the 9+4 judgment passes are **coverage-bounded
trust-but-verify**, bounded by C4 golden-set recall, and are surfaced (queryable) but NOT a merge gate.* Then either
(a) commit to re-running a deterministic `/cr` subset in CI and name which passes are mechanizable, or (b) accept
trust-but-verify explicitly — per `RECONCILIATION §C.5` recommendation "(a)+(b)". Until that sentence exists, the
keystone section over-claims un-forgeability for the judgment half and leaves the named precision open.

*Failure mode if unfixed:* the design ships believing the verdict is un-forgeable when only the deterministic checks
are; the first all-green-but-wrong overnight PR (the exact F7 failure mode) merges through a gate everyone thought
caught it.

### MF-2 — Two load-bearing cross-refs to "§3a" point at the wrong section (a reference-integrity defect — the very class P9 §5b exists to catch).

- Line 59 (the §1 migration table): "placement is a human/`/init` step **(§3a, never committed project settings)**."
- Line 98 (the §2 cite): "confirmed absence — **§8, §3a**; `capability-facts.md:56-71`."

In *this* artifact, **§3a is "The trigger trifecta"** (L1 channels, line 166) — it has nothing to do with settings
placement or the never-committed-project-settings claim. That claim actually lives in **§2** (lines 143–146,
`capability-facts.md:42-46`). Both citations are mis-pointed. This is not cosmetic: §1's whole "content committed,
placement is a human step" guarantee leans on a pointer that resolves to an unrelated section, and §2's
confirmed-absence cite is partly fictional. It is the exact broken-cross-ref failure class the artifact's own §5b
leg-1 ("no broken cross-refs … our canon cites five phantom artifacts today") is built to detect — the design rots in
the same way it indicts. Fix both to point at §2 (or remove the §3a token).

*Failure mode if unfixed:* the artifact's own reference-integrity is the thing P9 enforces; shipping it with two dead
internal refs undercuts the credibility of the gate and seeds the drift it claims to end.

---

## SHOULD-FIX

### SF-1 — The named minimal floor for the label trigger diverges from VISION, and VISION's own statement is internally split — the artifact picks one side silently.

§3a (line 178) says the label trigger "needs only the **minimal floor {F1, F2, F6, F7, F9}** — not F5." That matches
VISION's minimal-floor definition (VISION line 100–110) and is defensible. **But** the *companion list for the
deferred triggers* is inconsistent across sources and the artifact doesn't flag it:
- `github-usage.md` §3a (line 171–172): Slack/Linear + CI-self-heal ship "**After F5 + F3**."
- VISION L1 (line 138–139): the Slack/CI triggers "wait for **F3 + F8**."
- VISION line 109–110 + 136: F5 is the gate "for the Slack/Linear summon path" (untrusted-content leg).

So the deferred-trigger prerequisite is stated three ways (F5+F3 / F3+F8 / F5-only) across VISION and this artifact.
The artifact's "F5 + F3" is the most *coherent* reading (F5 = the lethal-trifecta gate for untrusted content; F3 =
egress) and is arguably the right call — but it is a **silent resolution of a VISION inconsistency**, and the charter
forbids resolving open items unilaterally. Surface it: note that VISION line 139 pairs the deferred triggers with
**F3 + F8** (fleet circuit breaker), and either reconcile to {F3, F5, F8} or flag the discrepancy as a thread for
Tanner. The carve-out *itself* (label-first, no free-text, ships on the minimal floor) is **preserved correctly** —
this is only about which floor the *deferred* legs wait on.

### SF-2 — §4b step 2 lists "integration" as a required check without grounding that it gates `main`.

The gate "FAILS unless … `test:unit`, **integration** … green." On disk, `integration.yml` exists as a separate
workflow, but `ci.yml` is the one wired to `pull_request` + `push: main`, and nothing read this session establishes
that the integration lane is a *required* check under branch protection (the artifact itself says requiredness is a
human repo-admin act, §9). Listing integration as part of the un-forgeable gate without confirming it is (or will be)
branch-protection-required overstates what the gate enforces today. Either cite where integration becomes required or
mark it "(once made required, §9)."

### SF-3 — §1 retires `/notion-sync` as a ritual but the disk shows `notion-sync/SKILL.md` is the *only* file in the skill dir; the "carry the mechanisms forward" claim needs the receiving home named.

§1 re-point #2 retires `/notion-sync` and asserts its mechanisms (comprehensive-diff, guard-file exception,
dedicated-branch, LAST-SYNC receipt, sentinel handoff) "**become the shape of the canon-PR**." Verified: the skill is
present (`.claude/skills/notion-sync/SKILL.md`, 11 KB). The claim is directionally right and matches VISION P3, but
the artifact never says *where* those mechanisms land — `/compound` Step 8's new GitHub path? A new `/canon-sync`
skill? An `/init`-materialized template? As written it is an assertion without a receiving artifact, which is how
mechanisms get "carried forward" in prose and lost in practice (the exact §0 drift the design indicts). Name the
home (most likely: the re-pointed `/compound` Step 8 + the canon-PR template).

---

## CONSIDER

- **C-1 — §2's plugin tree shows `settings.json(27B)` in the `plugin/` dir.** Correct that a plugin's settings.json is
  limited to `agent`+`subagentStatusLine` (`capability-facts.md:59-60`). Minor: the diagram annotation "LIMITED to
  agent + subagentStatusLine keys ONLY (the 27-byte proof)" conflates *the live vercel plugin happens to ship 27
  bytes of zero permissions* with *the schema limit*. They're different facts (one is an existence proof, one is the
  schema cap). Harmless, but a precise reader could mistake "27 bytes" for a hard limit rather than an observed
  instance. Leave as-is or split the annotation.

- **C-2 — §4c routes the verdict surface to "Fork F1 … GitHub Checks API (recommended)."** Sound and matches VISION
  F1. Note for downstream: if F1 resolves to the Checks API, the `cr-gate` check-run is *posted by `pr.sh`/the
  Action* — i.e., **by the loop's own tooling**. A Checks API run posted by the agent's pipeline is itself a
  model-adjacent writer; it is queryable and enforceable-as-required, but it does not by itself make the *MUST-FIX=0
  content* un-forgeable (only branch-protection-required + CI-recomputed-determinism does). This reinforces MF-1: the
  surface being queryable ≠ the judgment being un-forgeable. Worth a half-sentence so F1 isn't read as "Checks API
  solves forgeability."

- **C-3 — §5b leg-1 ("a CI check on every merge … no broken cross-refs") is the right detection mechanism;** ironic
  given MF-2. If the team builds P9's reference-integrity check first and runs it on the v2 design docs themselves,
  MF-2 would have been caught automatically. Consider dogfooding the §5b check on `design/v2/**` as the first test
  case.

- **C-4 — The "minimal floor {F1,F2,F6,F7,F9}" is cited as making the label trigger safe (§3a).** But F6 *is* the
  keystone whose un-forgeability MF-1 shows is only partial for the judgment half. The label trigger's safety
  therefore rests on the deterministic half of F6 (real) plus F7's bounded-loop/REJECT (real) — not on a fully
  un-forgeable verdict. Accurate as long as MF-1's framing is fixed; flagged so the floor's safety claim inherits the
  corrected F6 scope rather than the over-claimed one.

---

## What survives the attack (so the corrections aren't read as a teardown)

- **Charge 2 (plugin/permissions seam): airtight.** Plugin ships hooks/skills/agents/.mcp.json + a settings.json
  capped at `agent`+`subagentStatusLine`; permissions/autoMode cannot ride the plugin; `/init` owns exactly those
  un-shippable files; the no-self-edit-guard-file boundary is preserved (`/init` is F9 `disable-model-invocation`,
  human applies). Matches `capability-facts.md:56-71` and `DECISION-PACKAGE §4e` verbatim.
- **Charge 3 (autoMode placement): airtight.** "materialized into `settings.local.json` (personal) or
  `managed-settings.json` (enforced), NEVER committed project settings," cited to `capability-facts.md:42-46`, and it
  correctly identifies the live inert-config bug (autoMode at `.claude/settings.json:6-32`, ignored at runtime —
  confirmed on disk this session).
- **Charge 4 (label-trigger carve-out): preserved.** Label = controlled token, no free-text injection, ships first on
  the minimal floor; Slack/CI free-text legs deferred behind the trifecta/egress gates. (Only the *floor-list naming*
  needs the SF-1 reconciliation.)
- **Charge 5 (convergence = PUBLISH gate only): correct.** §1 point 4 + the §1 cite carry `DECISION-PACKAGE §4e`'s
  "convergence blocks plugin *extraction* only — not the safety/enforcement/measurement work, which runs in parallel"
  verbatim. No over-serialization.
- **Charge 6 (capability claims): no contradiction with `capability-facts.md`.** The only documented-but-uncorroborated
  lever (`disable-model-invocation` "removes from context") is honestly hedged in §9 ("verify before relying on it as
  a hard isolation guarantee; else F9 is +1 advisory line"). Hooks-can-run-tests-and-block / no-hook-can-compel-an-
  artifact / managed-settings-model-unreachable are all used consistently with the facts file.
- **No phantom rebuilds.** `summon.yml`, `cr-gate.yml`, `marketplace.json`, migrated `docs/canon/`, the observability
  roll-up are all confirmed-absent this session (`.github/workflows/` holds only `ci.yml` + `integration.yml`;
  `.claude-plugin/` absent; `.claude/rules/` absent — all re-verified). Each item names a failure mode. Doer≠checker
  rigor holds.

---

## Verdict

**SOUND-WITH-CORRECTIONS.** Five of the six charges pass cleanly; no capability claim contradicts the facts file; the
distribution/enforcement spine is mechanically correct and grounded. The blocking work is concentrated in the keystone:
**MF-1** — resolve the prompt's named precision (the gate as specified in §4b *is* the honest trust-but-verify form, but
the surrounding prose over-claims judgment-half un-forgeability and never states which side of open-decision-#5 it
lands on; one sentence fixes it) — and **MF-2** — repair the two mis-pointed §3a cross-refs (a reference-integrity
defect in the document that designs reference-integrity checks). Address MF-1/MF-2, fold in SF-1's floor-list
reconciliation, and the artifact is SOUND.
