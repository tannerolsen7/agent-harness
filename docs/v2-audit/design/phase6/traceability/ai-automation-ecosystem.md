# Traceability — ai-automation-ecosystem

**Article shape (pass-2/pass-3):** a buyer's guide for SaaS automation platforms (n8n/Make/Pipedream/
Temporal/Retool). Pass-3's honest headline: **zero of its tools are in our stack and none belong in it.**
The application is *method-level only*. Pass-3 raised **3 method-level gaps** in (b) plus a cluster of
load-bearing (c) cautionary mirrors / caveats. This table classifies each against the V2 design corpus,
grepped (not assumed).

Classification: **APPLIED** (carried into a MOVE / memory model / enforcement sort / distribution /
loop / carry-forward) · **CUT** (consciously rejected §F or deferred §C with a reason) · **DROPPED**
(not in synthesis, not in design, not consciously cut — a real miss).

---

## (b) REAL gaps — the core

| # | Pass-3 gap (verbatim thesis) | Classification | Where it lands / why | Missing nuance (if partial) |
|---|---|---|---|---|
| b.1 | **Price the fine print on our own upstream dependency** — the Matt-Pocock skill coupling (15 vendored/symlinked skills + `/tdd` already a divergent fork, "two copies no sync") is an *un-priced owner-drift risk*. V2 has **no stated policy**: vendor-and-freeze / track-upstream / cut. | **CUT (deferred §C/§D, with reason)** | Registered as a gap and given a home, but **explicitly deferred, not decided.** Lands as C4-G12 in `MASTER-FINDINGS.md:135-136` (§D smaller-gaps): "upstream Matt-Pocock skill dependency policy (`/tdd` already forked)." The disposition is consistent across the tree: `target-file-tree.md:161` and `inventory-stores-and-files.md:224` both mark `tdd/` **KEEP (note upstream fork)** with "Upstream-divergence policy is a **MOVE-4/5 item, not a cut**." The stated reason: it's a re-audit/distribution decision, not a Phase-3 build. Legitimate deferral. | **The vendor-freeze-vs-track-vs-cut decision itself is never made** — only registered. b.1's whole point is that the risk should be *priced as a risk* (the way the enforcement gap is priced); the design inventories the coupling but the owner-drift/fork-maintenance *cost* is priced only in `cluster-findings-4.md:185` (a synthesis input), nowhere in a V2 design output. See DROPPED-1. |
| b.2 | **Add a recurring-maintenance-cost lens to the §5/§6 build-or-reject registries.** Today they decide build/document/delete but carry **no maintenance-cost column**; stateful §5 items (`branch-registry-guard.sh`+`active-branches.json`, pre-push auto-rebase sync gate, `session-end.sh`) are cheap to write, expensive to keep correct. Apply the §9 golden rule to *upkeep*, not just *existence*. | **DROPPED (mechanism never applied)** | This is the article's strongest reusable correction and it **does not appear in any registry.** Its only trace is the same `MASTER-FINDINGS.md:136` one-liner ("+ a recurring-upkeep-cost lens on the §5/§6 registers [C4-G12]"). Grepping `enforcement-sort.md`, `target-file-tree.md`, `inventory-stores-and-files.md`, `REVIEWER-CONSOLIDATION.md` for `upkeep`/`maintenance-cost`/`recurring`/`stateful.*drift`/`active-branches`/`auto-rebase`/`cheap to write` returns **nothing**. The enforcement-sort's `failure-mode-prevented` column prices *existence* (§9 applied to "should this rule exist"), never *upkeep* (§9 applied to "what's the ongoing cost to keep this mechanism correct"). The registry that builds the stateful machinery (the 7 new build items in `enforcement-sort.md:291`) has no maintenance-failure-mode column. | — (wholly dropped, not partial) |
| b.3 | **"Durability as the missing primitive" reframes our confirmed enforcement absence.** An advisory system has no checkpoint: if a run is interrupted between "skill says do X" and "X done," nothing resumes or verifies. The §3e absent structural floor (`block-dangerous-bash.sh`, `enforce-scope.sh`, branch guard) + the `.cr-ok` sentinel never verified in CI (§3f/Node 8.5c) *is* our durability gap. | **APPLIED** | The *substance* is fully carried as MOVE 1+2 and the enforcement sort. `MASTER-FINDINGS.md:16-20` makes "enforcement is overwhelmingly advisory" the spine; `enforcement-sort.md:42-93` builds `block-dangerous-bash.sh` (resolution a), `.cr-ok`→CI/branch-protection so it's "unforgeable where the model can't compute it" (resolution b, `enforcement-sort.md:61-70`), the `/cr-security` enforce-scope classifier (resolution c), and the `managed-settings.json` "deterministic floor both canon and disk lack" (`enforcement-sort.md:90`). Pass-3 itself states this "doesn't add a new gap; it gives a sharper name for one §3e/§3f already confirms" — i.e. it *strengthens* a carried gap rather than adding one. | The article's specific *durability/checkpoint-resume* framing (state persisted across a crash mid-run) is **not adopted as a name** in the design — the design keeps "advisory→deterministic," not "no checkpoint." This is a naming choice, not a missed mechanism; pass-3 explicitly called it a re-name of a confirmed absence, so no build is owed. Not counted as a separate miss. |

---

## (c) Load-bearing caveats / cautionary mirrors

Pass-3 §(c) is partly "why most of the article doesn't apply" (domain mismatch, catalog rot — correctly
inert) and partly transferable warnings the design should heed. The two transferable ones:

| # | Pass-3 (c) caveat | Classification | Where it lands / why |
|---|---|---|---|
| c.1 | **Uneven skepticism is a cautionary mirror** — the article credulously repeats self-benchmarks ("13x faster" Windmill, "8–10 hrs/wk" Bardeen) while nuking ROI surveys. The transfer: treat *our own* un-benchmarked harness claims (e.g. canon's "operates at 60% of model capacity") with the same skepticism. | **APPLIED** | Carried two ways. (1) Reject-the-rates is locked: `MASTER-FINDINGS.md:175-176` §F rejects importing the ROI/recall numbers (incl. "MCPTox 60-72%") as "single-source/uncontrolled/self-disowned; adopt mechanisms, never rates." (2) Never-self-certify is the spine of MOVE 6 measurement: `MASTER-FINDINGS.md:108` ("triage calibration, never self-certify"), built out in `compounding-loop.md:223,288,382` (the `/cr` golden set is human-confirmed, the gate must not self-certify). The "60% of model capacity is a vendor-of-self number" specific instance isn't quoted, but the discipline it asks for is the operative one in MOVE 4's §9 re-audit (`MASTER-FINDINGS.md:85-91`) and MOVE 6's measurement. | 
| c.2 | **Rigid registers can mis-file spanning items** — the article's taxonomy leaks at every tool that spans categories (n8n is both Cat 1 and Cat 4). Transferable warning: our §5/§6/§4/§9 buckets can mis-file an item that spans them — e.g. the prod-key firewall is *simultaneously* a disk-only advance (§6) *and* part of the structural floor (§3e). "Don't let the register hide a spanning item." | **DROPPED** | Grepping the whole corpus for `spanning`/`mis-file`/`register.*hide`/`prod-key.*both`/`item that span` returns nothing relevant (only an unrelated R26 "mis-filed schema"). The design's registers (enforcement-sort, target-file-tree, memory-model) each file an item into exactly one bucket; no register carries a "spans-buckets" flag or a cross-register reconciliation note for the prod-key-firewall-style item that is both an anti-phantom advance (§E) and a structural-floor member (MOVE 2). See DROPPED-2. |

> Pass-3 §(c) also flags **domain mismatch** ("anyone citing n8n/Temporal as a V2 build item makes the
> category error") and **catalog rot** — these are correctly *not* gaps; the design honors them by simply
> not importing any tool. The §F reject list's "Dev-container/VM/microVM stack — wrong threat model"
> (`MASTER-FINDINGS.md:177-179`) is the closest analogue of "don't import a domain-mismatched solution,"
> and it is APPLIED. The budget-matrix-contradicts-prose mirror (don't re-list a "free" mechanism whose
> real cost is recurring) is the same point as b.2 and shares its DROPPED status.

---

## (d) Pass-3's own conclusion (load-bearing)

Pass-3 (d) concluded **synthesize, do not commission new research**, and folded its findings to "three
things into the existing map." That conclusion is honored: nothing in the design commissioned n8n/Temporal
research (the category error it warned against), and all three items reached MASTER-FINDINGS as synthesis,
not research. The conclusion itself is APPLIED — but it is the *vehicle* by which b.1 was deferred and b.2
was reduced to a one-liner, which is exactly how those two became under-carried.

---

## Verdict summary

- **b.1 (upstream-skill policy):** CUT — registered (§D / `tdd` tree rows) and deferred to MOVE 4/5 with a
  stated reason ("not a cut, a re-audit/distribution decision"). Legitimate, but the *risk-pricing* half is
  a real miss (DROPPED-1).
- **b.2 (recurring-maintenance-cost lens):** DROPPED — the article's single strongest reusable correction
  exists only as one line in §D; it was never applied as a column/lens in any registry. The enforcement
  sort prices existence, never upkeep.
- **b.3 (durability = enforcement floor):** APPLIED — fully carried as the MOVE 1+2 spine and the
  enforcement sort's unforgeable-floor builds. (The "durability/checkpoint" *name* wasn't adopted, but
  pass-3 itself framed this as a re-name, not a new build.)
- **c.1 (skepticism of self-benchmarks):** APPLIED — §F reject-the-rates + MOVE 6 never-self-certify.
- **c.2 (registers mis-file spanning items):** DROPPED — no spans-buckets flag or cross-register
  reconciliation note anywhere; the prod-key-firewall-spans-§6-and-§3e example has no home.

---

## DROPPED items (carried into the structured return)

**DROPPED-1 — owner-drift risk is inventoried but never *priced as a risk* (the decision is never made).**
- *Belongs in:* MOVE 4 (the §9 re-audit / deletion engine) or MOVE 5 (distribution) — the place that is
  *supposed* to make the vendor-freeze/track/cut call. Concretely: a one-line disposition on the `tdd/` and
  `supabase*` rows of `target-file-tree.md` / `distribution.md` that states the policy, not "MOVE-4/5 item."
- *Why it matters:* `/tdd` has *already* forked ("two copies, no sync"). An un-decided upstream policy means
  the next upstream change to `mattpocock/skills` either silently diverges further or silently overwrites the
  local fork — the exact owner-drift failure the article (and the harness's own PITFALLS on skill-cache
  staleness, C2-G8) warns about. D1 in `REVIEWER-CONSOLIDATION.md:70-71` (`harness-manifest` references
  `skills-lock.json`'s hash, mark `owner: upstream`) solves the *hash-drift detection* mechanics but does
  **not** decide the *policy* (freeze vs track vs cut). The risk is priced only in `cluster-findings-4.md:185`,
  a synthesis input, not a design output.

**DROPPED-2 — no register carries a "spans-buckets" flag; spanning items can be silently mis-filed.**
- *Belongs in:* the memory model / file-tree register design (`phase3/RECONCILIATION.md`,
  `target-file-tree.md`) and the anti-dup gate (`REVIEWER-CONSOLIDATION.md`) — a cross-register
  reconciliation note for any item that is simultaneously an anti-phantom advance (§E) and a structural-floor
  member (MOVE 2), the prod-key firewall being the named example.
- *Why it matters:* the audit's own registers are single-bucket. The prod-key firewall is filed in §E
  (anti-phantom, `MASTER-FINDINGS.md:152-153`) as "already built," which is correct — but its *other* identity
  as part of the deterministic egress/credential floor (MOVE 2, C4-G2/C4-G10) means a reader who only sees the
  §E row could conclude "credential isolation is done" and miss that the *operation-granularity egress floor*
  around it is still ABSENT. That is precisely "the register hides a spanning item." No design artifact flags
  this dual membership.
