# Pass 3 — Apply against ground-truth

Building on pass2: pass 2 established that the page is a *screening function* (adopt / borrow /
reject, scored as structural-gain − context-tax − drift) applied to addyosmani/agent-skills as the
worked example — but that it scores that screen against an **idealized, canon-level** picture of our
harness, not against what runs on disk. Pass 2's six load-bearing findings drive this pass:

1. "Structural beats advisory" is a **budget** argument, not a capability one — verify coverage per row.
2. Borrow #2 (cross-model escalation) is **internally contradicted** — bounded to classes that already
   have an oracle, recommended where none exists.
3. Borrow #1 targets **`learned-patterns.md`, a phantom** — and is only non-advisory if something greps it.
4. The router rejection assumes **permanent single-project Claude-Code scope** — V2's stated goal contradicts it.
5. The page's structural/advisory contrast **over-credits our disk** — our floor is thinner than it assumes.
6. The real deliverable is the **screen itself**, not the 23 verdicts.

This pass joins those to the ground-truth map (`CANONICAL-HARNESS-AS-IS.md`), citing concrete rows.
The decisive join, repeating pass 2's finding: **the page is written against the synthesis/decision
layer** (`project_layer5_inputs.md` — Pillars 1/3/4/5, Nodes 2.1/12/13.1/17, R1/R2) **while the map
is the as-is inventory layer** (canon/disk/global, §3–§9). Where a Pillar claim has no map row, it is
*unverified against disk*, and I say so.

---

## (a) What we ALREADY do — the page's REJECTs, re-scored against disk

The page rejects six overlaps as "Pillar 1 regressions." Pass 2's finding #5 warned these lean on
canon, not disk. Re-scoring each against the map:

| Their skill | Page's claimed disk mechanism | Map verdict | Honest disposition |
|---|---|---|---|
| code-review-and-quality | "`/cr` = four fresh-context lens agents + REJECT + adversarial pass" | `/cr` **is built** (canon §05 + disk; map §3b lists it aligned). But map §3c: disk `/cr` is "9 parallel passes + Pass 11 `@reviewer` (4 lenses). **No REJECT tier, no UNATTENDED branching.**" The four lens agents (assumption/composition/cascade/abuse) **are real** (§3d, 23 agents). | **REJECT stands**, but the "+ REJECT" half of the rationale is canon/aspiration, not disk. The four-lens fresh-context design is genuinely ours and genuinely stronger than an in-context checklist. |
| spec-driven-development | "`/change` has a reversibility gate" | **No `/change` skill exists** in the map's skill inventory (§3b lists cr, cr-security, feature, design, compound, tdd, queue, refactor, spike… — no `/change`). The reversibility-gate language is a Layer-5 *design* concept, not a disk skill. | **REJECT direction is right** (we don't want two spec front doors), but the cited gate **is unverified against disk**. The thing we'd be "protecting" may not be built. |
| security-and-hardening | "`/cr-security` is F2 recall-weighted + reversibility hard-stops" | `/cr-security` **is built** (map §3c). Disk has **3 passes** (canon documents 2; §6 disk-only row). "F2 recall-weighted" appears **nowhere in the map** — Layer-5 vocabulary. | **REJECT (borrow vocab) stands** as direction; the tri-state Always/Ask-first/Never is a real format worth borrowing. The "F2-weighted" superiority claim is unverified. |
| test-driven-development | "`/tdd` has ratchets + mutation testing" | `/tdd` **is built** — and notably a **project-local fork** (map §1: 5.2 KB, diverged from global Matt-Pocock tdd, "two copies, no sync"). "Ratchets + mutation testing" **not in the map** — Layer-5 claim. | **REJECT (steal Prove-It) stands.** But note the map flags `/tdd` as an *un-synced fork* — a maintenance liability the page doesn't mention. |
| git-workflow-and-versioning | "Tier-0 worktree isolation is structural" | **Confirmed by the map** (§3e `worktree-create.sh` WorktreeCreate hook + prod-key firewall; §6 disk-only "genuine disk *advance* — Tier-0 credential isolation canon lacks"). The strongest, best-grounded REJECT. | **REJECT stands, fully disk-verified.** This is the one row where "ours is structural" is unambiguously true. |
| personas (code-reviewer / security-auditor) | "fresh-context lens design (Node 12) exists to prevent contamination" | The 4 lens agents are real (§3d). "Node 12" is Layer-5 vocabulary, not in the map, but the *mechanism it names* (fresh-context sub-agents) is on disk. | **REJECT stands.** In-context personas would indeed re-contaminate; our agents run fresh-context. |

**Net for (a):** Two REJECTs are fully disk-grounded (**git-workflow / Tier-0 worktree**, and
**personas / fresh-context lenses**). Three are *directionally* correct but lean on canon-or-Layer-5
mechanisms the map cannot confirm as built (**`/change` reversibility gate, `/cr` REJECT tier,
F2-weighting, ratchets**). The page's blanket "we already enforce this structurally" is true for ~2
of 6 and aspirational for the rest — exactly pass 2's finding #5. We *do* already have: `/cr` with 4
real fresh-context lens agents (§3d), `/cr-security` (§3c), a `/tdd` fork (§1), and Tier-0 worktree
isolation (§3e, §6). We do **not** have: `/change`, a REJECT tier, or the measured properties the
page attributes to these skills.

---

## (b) REAL gaps — each cites a ground-truth section or confirmed absence

These are the page's contributions that map to an actual hole, not to something already built.

1. **Subtractive enforcement has no home (page's strongest gap).** The page: "every Pillar-5 tool
   prevents *adding*; nothing drives *removal*." Map confirmation: the disk-only/canon-only registries
   (§5, §6) contain **only additive or guard mechanisms** — `block-dangerous-bash.sh`, `enforce-scope.sh`,
   `branch-registry-guard.sh`, net-diff guards — and **no deletion-driving skill or hook anywhere**.
   `/simplify` is documented in canon but **absent on disk** (§3b: "Documented in canon, ABSENT on
   disk… `/simplify`"; §5 canon-only). So "adopt code-simplification + deprecation" maps to a genuine
   canon-only absence (§5) — **build-or-reject**, and the map's own closing example (§"How later
   phases cite this map") already names `/simplify` as a canon-only absence to wire. **REAL GAP.**

2. **Memory-capture / `learned-patterns.md` format has no enforced store.** The page wants the
   anti-rationalization three-column table (excuse → why-wrong → MUST-FIX) as the *shape* for
   `learned-patterns.md`. Map (§6): `learned-patterns.md` is a **confirmed phantom** — "referenced on
   disk, never built on disk *or* in canon." And the **memory model itself is the Phase-3 crux** (§4):
   triple-duplication the canon "both sanctions and forbids," an auto-memory 6th store the canon
   ignores, freshness rules for only 3 of ~14 stores. So the gap is real but **bigger than a format
   choice** — pass 2 finding #3: the borrow only matters if (i) we decide to build the store at all
   (§4) and (ii) something *greps* the table (else it's the advisory downgrade the page warns of).
   **REAL GAP — but reframed from "restructure a template" to "decide the store, then bind its format
   to an enforcer."**

3. **No `session-end.sh` to auto-propose memory candidates.** Adjacent to the page's memory-format
   point and confirmed structural: map §3e and §5 — `session-end.sh` (Stop hook) is **canon-declared,
   absent on disk**; "disk's memory is fully manual." Any anti-rationalization-table store the page
   recommends has **no automated writer** today. **REAL GAP** (this is the enforcement half pass 2 said
   the page omits).

4. **Stop-the-line for unattended runs.** The page: halt forward work on a defect class until
   root-caused; "without it an unattended run keeps stacking PRs on a known-broken foundation."
   Map confirmation: disk `/cr` has **"no UNATTENDED branching"** (§3c) and the only UNATTENDED-mode
   mechanism on disk is the worktree prod-key firewall (§3e) — there is **no defect-class halt** in any
   hook, CI workflow, or skill in §3e/§3f. The CI workflow (`ci.yml`, §3f) runs tsc/lint/vitest per-PR
   but **nothing halts a *series* of agent PRs** on a recurring failure. **REAL GAP**, and it bears on
   the map's headline V2 driver (autonomous/unattended operation, §0).

5. **CI never verifies the `.cr-ok` sentinel ("8.5(c) gap").** Not raised by the page directly, but
   the page's whole "honor-system verification" critique lands here on *our* side: map §3f — "The Node
   8.5(c) gap (CI never verifies `.cr-ok`) is a disk fact… canon's `.cr-ok` chain has the same hole
   (gitignored, never reaches CI)." Our own review-gate is the same self-reported pattern the page
   indicts in Addy's TDD checklist. **REAL GAP** — and it is the most direct application of the page's
   "evidence-based verification is honor-system" insight to us (pass 2 finding #6 territory: turn the
   lens on ourselves).

6. **Feature-flag / staged-rollout discipline is absent.** The page: "feature flags are entirely
   absent… your Ashby renderer item assumes a `feature_flag` column. Staged rollout is unbuildable
   without it." The map does not contain a feature-flag mechanism in any layer (§3a–§3f), and the
   Ashby renderer / `feature_flag` column are Layer-5 items not in the map. So this is **a real
   absence in the map's terms** (no rollout primitive anywhere) but its *dependency* (the renderer
   assumption) is **unverified against the map** — cite as a confirmed-absence gap with a Layer-5
   dependency to check. **REAL GAP (absence confirmed; the dependency needs the Layer-5 join).**

7. **"Critics never build" is unhooked.** The page wants the orchestration doctrine ("personas never
   invoke personas; depth ≤ 1") codified as an AGENTS.md rule. Map relevance: we run **23 agents**
   including 4 review lenses (§3d) with **no documented orchestration-depth constraint** in the map's
   hook/agent inventory. The map shows the *agents* exist but no rule prevents an agent invoking an
   agent. **REAL GAP — but a doctrine/AGENTS.md rule, low-cost**, and consistent with the map's
   advisory-vs-structural framing (a rule, not a hook, unless we add an enforcement point).

**Not a real gap (page over-reaches):** "Trust levels per context source." The page calls our
three-tier loading "token budget, not graded trust." The map's three-tier loading and the
trust-taxonomy idea are **both Layer-5/canon concepts** — the map's context-doc inventory (§3a) does
not expose a trust-grading mechanism *or* its absence as a structural item. This is a **synthesis-layer
refinement, not a map-citable gap.** Defer to Layer-5, do not promote to a build item on this article's
authority alone.

---

## (c) The article's own weaknesses

1. **It audits Addy's enforcement and exempts ours (pass 2's asymmetry, now map-confirmed).** The
   page's entire proof is "frontmatter is name+description → advisory → doesn't transfer," yet it never
   runs that lens on us. The map does (§3e): our system is "**overwhelmingly advisory**… neither has a
   deterministic backstop"; we are **missing** the canon's 3rd bash guard, scope guard,
   branch-registry guard, and session-end hook; our live pre-commit is "a **67-byte husky shim**" that
   lacks the canon's main-branch agent block, with the canon-matching `.githooks/pre-commit` **wired
   out** (`core.hooksPath=.husky/_`). So the clean "their advisory vs our structural" dichotomy is, on
   disk, **advisory vs mostly-advisory-with-a-few-gates.** Several REJECTs are right in *direction* but
   overstate how structural we are — see (a).

2. **Its highest-leverage borrow targets a phantom and omits the enforcer.** Borrow #1 binds to
   `learned-patterns.md` (map §6: phantom) and to "the Node 13.1 entry template" (not in the map). The
   page never specifies *what greps the table*, so as written the borrow would ship the exact advisory
   downgrade it warns against (pass 2 finding #3). A format with no enforcement point is prose.

3. **Borrow #2 is internally contradicted (pass 2 finding #2).** The page proves cross-model
   escalation "can flag but never block… skipped in every non-interactive context (CI, `/loop`)," then
   recommends it for "irreversible classes (auth/schema/RLS/payments)" — precisely the judgment classes
   where **no CI oracle exists** and where it's most likely to be skipped unattended. Its own
   reconciliation ("complements the CI oracle, never replaces it") concedes the value is *bounded to
   classes that already have an oracle* — i.e. it adds least where the page aims it. Adopt only with a
   forcing function (don't let `/cr` close a MUST-FIX in an irreversible class without the second-model
   pass), or it inherits the same honor-system hole.

4. **"Structural displaces advisory" is a budget claim wearing a capability costume (pass 2 finding
   #1).** A cheap in-context check and an expensive fresh-context gate are not mutually exclusive on
   *correctness*; they're only rivalrous on *context budget* (Pillar 4). So "importing theirs is a
   regression" is really "we already pay for the strong version, so the weak one is pure tax" — true
   only where the strong version covers the same failure mode. The map (§3c) shows `/cr`'s pass
   structure is **contested across three sources** — "ours is structurally stronger" is less settled
   than the categorical table implies.

5. **The router rejection assumes permanent single-project scope — the map contradicts it as a
   goal.** The rejection turns on "Claude-Code-only harness." The map's headline (§0, §8): V2's binding
   principle is **global, GitHub-hosted, multi-project, installable**; "the harness has never been
   installed anywhere but event-vendor; 'multi-project' is a goal, not a state." If V2 succeeds, the
   cross-harness portability the page dismisses (Cursor/Gemini/Copilot) **becomes live**. The router
   verdict is sound *for today's shape* and silently assumes that shape is permanent. Mark
   scope-dependent, not settled.

6. **Pillar/Node vocabulary is unbridged to the map.** The page reasons almost entirely in Layer-5
   terms (Pillars 1/3/4/5, Nodes 2.1/12/13.1/17, R1/R2, "Ashby renderer," "F2-weighted"). The map
   uses **none** of these. Every verdict that rests on a Pillar/Node referent without a map row is, per
   pass 2 finding (assumptions #1–#3), **unverified against disk.** This is a readability/auditability
   weakness: the page is persuasive *if you already hold the Layer-5 model*, and unfalsifiable if you
   don't.

7. **It under-counts our own duplication risk while warning about Addy's.** It cautions "23 new skills
   is 23 things that can drift," but ignores that we already carry an **un-synced `/tdd` fork** (map §1)
   and a canon that is **internally inconsistent** on `/cr` numbering, two feature loops, two reviewer
   names (map §7). The drift it fears from imports already exists natively; the screen should be turned
   inward too.

---

## (d) Fresh research warranted? (prefer synthesize)

**No new external research is warranted.** Everything actionable resolves by *synthesis* against the
map and the Layer-5 inputs — and the map's own rule (§"How later phases cite this map") forbids
promoting any insight that doesn't land on a §3–§9 row. The four genuinely map-citable gaps —
**subtractive enforcement / `/simplify` (§5), the memory-store + format + `session-end.sh` writer
(§4, §3e/§5), stop-the-line for unattended (§3c), and the `.cr-ok`/CI honor-system hole (§3f)** —
are all *decisions to make*, not *facts to discover*. The page already did the primary-source reading
(README, marketplace.json, three SKILL.md, orchestration-patterns.md, code-reviewer.md, via raw
GitHub); re-fetching the repo would only re-confirm pass 1.

Two narrow synthesis joins remain, both internal — not web research:

- **The Layer-5 ↔ map join.** Confirm against `project_layer5_inputs.md` whether `/change`, the `/cr`
  REJECT tier, F2-weighting, ratchets, the Ashby `feature_flag` column, and Nodes 13.1/2.1/17 are
  *decided/planned* or merely *named*. This is the join pass 2 (assumption #3) and (a)/(b) flagged as
  the recurring unknown. It is a read of an existing in-repo doc, not new research.
- **Verify one external micro-fact only if a borrow ships:** that addyosmani/agent-skills frontmatter
  is in fact `name`+`description`-only (the page's load-bearing fact). It is checkable in one `curl`
  of a raw SKILL.md if/when we formalize "their skills are advisory" in an ADR — but it is not blocking
  for the four gap decisions above.

**Synthesize, don't research.** The single highest-value synthesis artifact (pass 2 finding #6): lift
the page's implicit **adopt / borrow / reject screen** out as a reusable AGENTS.md-level rule for
vetting *any* external skills library — "does it add a structural capability you lack (adopt), a format
you can bind to an existing gate (borrow), or a prose duplicate of something you already *enforce*
(reject)?" — with pass 2's correction baked in: **"enforce" means a hook/CI/gate greps or blocks it,
not that a CLAUDE.md line mentions it.** That screen is the durable deliverable; the 23 verdicts are
the worked example.

---

## Application summary (map-cited)

- **Already do (disk-verified):** `/cr` with 4 fresh-context lens agents (§3d); `/cr-security` (§3c);
  Tier-0 worktree isolation + prod-key firewall (§3e, §6); a `/tdd` fork (§1). → The page's
  git-workflow and personas REJECTs are fully grounded; the rest are directional.
- **Real gaps (map-cited):** subtractive enforcement / `/simplify` absent (§5, §3b); memory-store
  format + automated writer `session-end.sh` (§4, §3e/§5); stop-the-line / no UNATTENDED defect halt
  (§3c); `.cr-ok` not CI-verified (§3f); feature-flag/rollout primitive absent (no map mechanism);
  "critics never build" unhooked (§3d, doctrine-level).
- **Page weaknesses:** exempts our own (mostly-advisory) enforcement floor from its lens (§3e);
  borrow #1 targets a phantom and omits the enforcer (§6); borrow #2 self-contradicts; "structural
  displaces advisory" is a budget claim; router rejection assumes permanent single-project scope (§0,
  §8 contradict); Pillar/Node vocabulary unbridged to the map.
- **Research:** none external; two internal synthesis joins (Layer-5 ↔ map; lift the screen as an
  AGENTS.md rule). Prefer synthesize.
