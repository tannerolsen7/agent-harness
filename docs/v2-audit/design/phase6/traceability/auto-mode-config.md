# Traceability — auto-mode-config (pass-3 gaps vs V2 design)

Source: `docs/research/v2-audit/passes/auto-mode-config/pass3-apply.md` (+ pass2-penetrate.md).
Each distinct gap/insight the pass-3 raised, classified APPLIED / CUT / DROPPED against the V2 design
corpus. Grounded by grep, not assumption. The article self-marks `canonical: false` — its (c) items are
critiques of the *article's own execution* (it never ran `claude auto-mode config`), not design gaps; they
are recorded but only the ones that imply a build/decision are counted.

This is one of the highest-yield articles in the set: its core maps to a confirmed, live, currently-broken
on-disk state the as-is map never covered (the project's `autoMode` block sits in the file the classifier
ignores). The cluster rollup (`cluster-findings-4.md` G4) carried it as MOVE 2 (C4-G4); the adversarial
gate `CHECK-master-findings.md` re-grounded the citation (the original "appears 0 times" snapshot was
stale — re-grounded to "Not read from shared project settings *by design*").

---

## Per-gap table

| # | Gap / insight (pass-3) | Class | Where it lands / why cut / why missed |
|---|---|---|---|
| b1 | **The config is in the file the classifier ignores** — the project authored the correct `autoMode` artifact but placed it in committed `.claude/settings.json`, which the classifier does NOT read; unattended `/queue` runs are governed by bare defaults right now. Relocate to the honored file and verify. | **APPLIED** | Carried as MOVE 2 / C4-G4, *citation re-grounded* (stronger than the article's). `MASTER-FINDINGS.md:64-67` ("autoMode policy lives in committed `.claude/settings.json`, which the classifier does **not read by design** → unattended runs governed by bare defaults *right now*. Correct home = `settings.local.json` or **managed-settings.json**"). Concrete fix = enforcement-sort resolution (e) (`enforcement-sort.md:86-93`, `:318-320`); convergence checklist row 9 (`distribution.md:255`); file-tree disposition (`target-file-tree.md:87-88,328,378`); anti-dup gate honored (`lens-anti-duplication.md:100`); capability-confirmed (`capability-facts.md:42-45`; `lens-capability-reality.md:187` "authoritatively confirmed"). The stale "appears 0 times" framing was explicitly replaced by `CHECK-master-findings.md:28-52`. This is the article's actionable core, fully carried. |
| b2 | **No pre-flight verification mechanism exists** — the article's own Design Challenge is unbuilt. A hook/script that parses `claude auto-mode config`, checks the effective `environment` destinations + `$defaults` presence against a /queue destination manifest, exits non-zero, wired as a /queue pre-run check. The *absence of this gate is why the misconfiguration went unnoticed.* | **DROPPED** | Not in any design file. Grep for "pre-flight / effective config / verification mechanism / re-run config" across `phase3/ phase45/ phase6/ MASTER-FINDINGS RECONCILIATION CARRYFORWARD` returns **only the source** `cluster-findings-4.md:263-265` — never folded into a MOVE, an enforcement-sort row, a CI script, or a deferred/§C item. The design carries the *one-time placement fix* (b1) but not the *standing verification gate* that would catch a future re-misplacement or a defaults-drift. MOVE 1's Stop-hook surface and the `scan-context` drift detector are the natural homes, but neither names "verify `auto-mode config` effective output." See DROPPED #1 below. |
| b3 | **Defaults will over-block the project's normal migration / `src/data/` write path.** Built-in `soft_deny` ("Production Deploy: running production database migrations"; "Modify Shared Resources… persistent changes to database records") + the project's own "the Supabase project IS production" environment fact → the default classifier reads `supabase migration up` and `src/data/` writes as production mutation → soft-block → **unattended /queue stall.** Needs an explicit allow carve-out for CLI-driven migrations, or a real local/prod distinction the classifier can reason over. | **DROPPED** | Only the *placement* half of C4-G4 survived into MASTER-FINDINGS; the **over-block sub-item was dropped on rollup.** `cluster-findings-4.md:83-91` carries all three G4 sub-items (relocate / **resolve the prod-migration over-block** / distribution conflict), but `MASTER-FINDINGS.md:64-67` folds in only relocate + (implicitly) distribution. Grep for "carve-out / CLI-driven migration / local-prod / over-block / stall / 127.0.0.1" across the design files finds carve-outs **only for egress** (`MASTER-FINDINGS.md:123`), never for the migration soft-block. Not in §C deferred, not in §D smaller gaps, not consciously cut. pass2 §G calls this "the central operational risk for THIS project specifically" — and it is a real miss. See DROPPED #2 below. |
| b4 | **The autoMode artifact has no commit/review/sync home — structural conflict with the harness's commit-and-distribute V2 thesis.** auto-mode is honored only user-level or in a gitignored local file, so the one policy that actually runs unattended is the one the V2 distribution model cannot commit/review/distribute; it won't travel with the repo to a second install. Either accept per-machine un-synced setup (documented) or build a `~/.claude` generator. | **APPLIED** | Carried as the cross-phase resolution. Enforcement-sort (e) names **`managed-settings.json` — "enforced, agent-unreachable — the deterministic floor both canon and disk lack"** (`enforcement-sort.md:89-90`), i.e. the answer to "where can an enforced policy live." Distribution resolves the *travel* conflict: a plugin **physically cannot carry permissions/autoMode** (verified vs live vercel 0.43.0 = 27-byte settings; `distribution.md:79-81`, `REVIEWER-CONSOLIDATION.md:157`), so autoMode stays **PROJECT/managed, never plugin-shipped**, and the `/init` template scaffolds it into the *correct* file (`distribution.md:195,255,435-436`; `:328` file-tree "never plugin-shipped; human-only edit"). The conflict the article surfaces is acknowledged and given the explicit disposition "per-project/per-machine, not distributed via the harness." |
| b5 | **Delivery mechanism collides with the no-agent-edits-to-guard-files invariant.** The article's "paste this block into your settings" workflow conflicts with `permissions.deny` blocking `Write(.claude/settings.json / settings.local.json)` + the standing "no agent edits to guard files" rule. The artifact must be a paste-ready NEEDS-HUMAN handoff; the agent prepares + verifies, a human writes. | **APPLIED** | Carried as a §F reject-as-literal AND a process rule everywhere. `MASTER-FINDINGS.md:186` (§F): "Paste autoMode block into settings.json by the agent — forbidden (no agent edits to guard files); prepare + verify + surface paste-ready for a human." Enforcement-sort (e) "**Forbidden:** the agent editing settings.json/guard files itself… prepare + surface paste-ready for a human" (`enforcement-sort.md:90-92,320`). Anti-dup gate confirms honored (`lens-anti-duplication.md:100`; `REVIEWER-CONSOLIDATION.md:25`; `lens-capability-reality.md:196`). cluster R3 (`cluster-findings-4.md:260-265`). Fully carried. |
| T (thesis) | **Auto-mode relocates the trust decision from runtime prompt to config-time prose; the deliverable is a *verification discipline* around the autoMode block, not the block itself** (pass2 §A; pass3 bottom-line). "Silent misclassification is the risk now" — config-time trust has no compile step, so the operator must re-introduce the verification the prompt gave for free. | **DROPPED (as a named frame)** | The *placement* half of this thesis is carried (b1). The *discipline* half — its concrete instantiation IS the pre-flight script (b2) — is dropped. Grep for "config-time / relocate trust / verification discipline / silent misclassification" across design files returns **zero hits**; the design has no standing mechanism that re-introduces the verification the synchronous prompt used to provide. This is the parent insight of b2 and shares b2's miss. Not double-counted as a separate build (it = b2's owed gate), but flagged so the frame isn't lost: the design treats autoMode as a one-time placement fix, not as a config-time-trust surface needing ongoing verification. |
| E (provenance) | (pass2 §E) **auto-mode is the first enforcement layer in this harness that reasons about *intent / provenance / data-flow* rather than *string shape*** — it can cover the vast advisory-only surface (skill bodies, CLAUDE.md rules) that has no deterministic backstop. | **CUT (subsumed — not a distinct build)** | This is pass2's *interpretive* read, not a (b) gap; pass3 does not re-raise it as a build item. The advisory-backstop problem it points at IS the design spine (`MASTER-FINDINGS.md:16-20` "enforcement is overwhelmingly advisory"), addressed by MOVE 2's deterministic relocation and the `managed-settings.json` floor (b4). The narrower claim "use the classifier as a general advisory backstop" is not adopted as a mechanism — correctly, since the classifier only runs unattended and isn't a commit/CI gate. Not a miss: subsumed by MOVE 2 + b4, no separate disposition owed. |

(c) items 1–7 of pass-3 are critiques of the *article's* execution (it never ran `claude auto-mode config`,
left strings Unconfirmed, didn't write its own Design Challenge script). They are not gaps in *our* harness;
their design-relevant residue is exactly b2 (the unbuilt script) and b1 (the unchecked misplacement), both
already rowed above. Not separately counted.

---

## DROPPED — the real misses

### DROPPED #1 — the standing pre-flight `auto-mode config` verification gate (b2 + thesis T)
**Gap.** No mechanism parses the *effective* `claude auto-mode config` output and asserts the project's
custom destinations + `$defaults` are present before an unattended run. The design carries the *one-time*
relocation (b1) but not a *recurring* check. Because there is no such gate, the original misplacement went
unnoticed for the life of commits #99/#100 — and after the relocation lands, nothing prevents a future edit
or a CC-version change from silently reverting the effective config to bare defaults.
**Why it matters.** This is the article's own Design Challenge and the instantiation of its central thesis
(config-time trust has no compile step). It is the difference between "we fixed it once" and "we can't
silently regress." For a harness whose V2 thesis is *deterministic backstops for forgeable advisory state*,
an unverified safety-policy effective-config is exactly the forgeable-state failure class.
**Where it should go.** A `scan-context`/CI drift-rule or a `/queue` pre-run check (MOVE 1 Stop-hook surface
/ MOVE 2 enforcement layer): assert `claude auto-mode config` shows the expected environment destinations +
`$defaults` lead, exit non-zero otherwise. Cheap (the article calls it "synthesis against the JSON shape
already captured"), agent-runnable (read-only command, no guard-file write).

### DROPPED #2 — the defaults over-block of the production-Supabase migration / `src/data/` path (b3)
**Gap.** The middle sub-item of C4-G4 — "resolve the prod/migration over-block" — was lost when MASTER-FINDINGS
rolled the gap up to placement + distribution only. The built-in `soft_deny` will read CLI migrations and
`src/data/` writes against the single-tenant-prod Supabase as production mutations and soft-block them,
stalling the exact /queue tasks auto-mode is meant to unblock. No allow carve-out and no local/prod
distinction is registered anywhere in the design.
**Why it matters.** pass2 §G calls this "the central operational risk for THIS project specifically" — a
*correctly*-configured classifier (placement fixed per b1) can still stall every unattended migration task.
Fixing b1 without b3 produces a classifier that trusts the right destinations but blocks the project's
normal write path. It is the inverse of the article's benign "extend, don't subtract" frame and maps to §9
("the constraint catches *legitimate* work").
**Where it should go.** A decision item adjacent to MOVE 2 / the autoMode placement fix: either (a) an
explicit `autoMode.allow` carve-out for CLI-driven migrations against the configured remote, or (b) wire a
real local (`127.0.0.1`) vs prod distinction the classifier can reason over (the Tier-0 firewall already
encodes the 127.0.0.1 boundary — `MASTER-FINDINGS.md:152` — so the fact exists, just not handed to the
classifier). Resolvable now by running `claude auto-mode critique` on a test `supabase migration up`
description (pass3 §d names this as a one-command probe).

---

## Counts

- **Total distinct gaps/insights this pass-3 raised:** 7 (the five §b REAL gaps + the pass2/pass3 thesis T
  as a load-bearing conclusion + the pass2 §E provenance insight). The (c) article-weakness items reduce to
  b1/b2 and are not separately counted.
- **APPLIED:** 3 (b1, b4, b5)
- **CUT (consciously subsumed/rejected with reason):** 1 (E — subsumed by MOVE 2 + b4; not a distinct build)
- **DROPPED:** 3 (b2 the pre-flight gate; b3 the migration over-block; T the verification-discipline frame —
  T shares b2's owed gate but is flagged so the config-time-trust framing isn't lost). Distinct real-miss
  items to surface: **2** (b2/T collapse to one owed mechanism; b3 is the second).
