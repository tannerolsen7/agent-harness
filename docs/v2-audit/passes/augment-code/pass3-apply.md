# Pass 3 — Apply: the article against our harness (vs the ground-truth map)

Building on pass2: the durable kernel is pass2 §1/§8 — *probabilistic context and deterministic
enforcement are two layers; every rule must be assigned to one*. The discardable part is pass2
§6 — the page's concrete recommendations target a pre-audit canon snapshot, not disk. This pass
maps the kernel onto `CANONICAL-HARNESS-AS-IS.md`. No gap is claimed without a citation to a map
section or a confirmed absence.

---

## (a) What we ALREADY do

Building on pass2 §6 (the page's flagship "add a hooks layer" recommendation is already ~2/3
built on disk):

1. **The two-layer architecture the page argues for already exists in skeleton.** We have a
   probabilistic context layer (`CLAUDE.md`, `CONTEXT.md` (15 KB, PR #92), `SOUL.md`, `AGENTS.md`,
   `PITFALLS.md`) *and* a deterministic enforcement layer (5 Claude hooks + 3 git hooks). The
   page's "Application §2" candidate hooks are largely present: PreToolUse is covered by
   `block-dangerous-git.sh` and `block-npm-install.sh` [map §3e]; SessionStart exists
   (`session-start.sh`) [map §3e]; a prod-key firewall on worktree create exists
   (`worktree-create.sh`) — a disk advance the canon itself lacks [map §3e, §6].

2. **The three-tier rules taxonomy is genuinely already mapped onto our layers.** The page's own
   "transfers? Fully — already in the system" is correct here: always_apply ≈ `CLAUDE.md`,
   agent_requested ≈ skills loaded on invocation (~26 skill dirs [map §3b]), manual ≈ explicit
   `/skill` prompts. This is the one row where the page's "already in the system" claim survives
   contact with disk.

3. **Accountability culture is already codified as discipline, not just prose.** The page's
   "person pushing the PR owns the code" maps onto our discipline rule ("What does this do… where
   could this fail… what would you change" pre-commit checkpoint, CLAUDE.md) and the `.cr-ok`
   sentinel chain gating push [map §3e, §3f]. We already treat ownership as a gate, not a vibe.

4. **"Tables for conditional logic" is already our house style in the highest-stakes places.**
   CLAUDE.md's "Keeping docs current" and the hooks-enforcement picture are tables; the map
   itself is table-dense. The page's prose→table candidate is partly pre-adopted.

## (b) REAL gaps it exposes — each cited

Building on pass2 §5 and §7 (the page's principle, turned on our own disk, exposes places where
our "deterministic" layer is fake or our "two layers" are conflated):

1. **Our deterministic guards fail OPEN — that is probabilistic enforcement in disguise.**
   [map §3e: `block-dangerous-git.sh` and `block-npm-install.sh` both "jq fail-**open**"]. The
   page's core principle is "make violations structurally impossible." A guard that degrades to
   *permissive* when `jq` is missing makes violations structurally *possible* under the exact
   conditions (degraded environment) where you most need it. This is the page's principle used as
   a scalpel on our own §3e — a gap the page could never have named because it didn't audit disk.

2. **The canon's third structural guard is absent, and "make X structurally impossible" is its
   whole job.** `block-dangerous-bash.sh` (deploys, `rm -rf`, writes to `.git`/`.husky`/`.claude`)
   is **canon-declared, ❌ absent on disk** [map §3e, §5]. The page's "deterministic outer
   harness… make violations structurally impossible" is the precise rationale for building it; the
   page supplies the *why* the canon's bare entry lacks.

3. **Unattended operation breaks the page's accountability model, and we have nothing technical
   to replace it.** Per pass2 §5, "accountability is cultural" assumes a human pushing the PR.
   Our harness runs UNATTENDED/AFK sessions (worktree UNATTENDED mode, prod-key firewall
   [map §3e]). The map records **no Stop hook that verifies test output before completion**
   (`session-end.sh` Stop hook is canon-declared, ❌ absent on disk [map §3e, §5]) — so an
   unattended session can complete with red/unrun tests and defer "ownership" to a review that
   may never scrutinize what culture would have caught live. This is the page's §E.2 "Stop hook
   that checks test output" — a *real* absence by [map §3e], not the phantom the page imagined.

4. **STOP-AND-SURFACE / scope rules live only in the probabilistic layer.** `enforce-scope.sh`
   (block staging files outside ALLOWED FILES) is **canon-structural, ❌ absent on disk**
   [map §3e, §5]. The page's exact thesis — STOP-AND-SURFACE conditions are "rules-file entries,
   not hooks" — lands on a confirmed disk absence. The rule is real, the enforcement is missing.

5. **The hooks layer is partly wired-OUT, which is worse than absent because it looks present.**
   The canon-matching `.githooks/pre-commit` (with the main-branch agent hard-block) is
   **dormant** under `core.hooksPath=.husky/_`; the live husky shim is 67 bytes and lacks the
   block [map §3e, §3f]. Per the page's principle this is the most dangerous state: a
   deterministic control that *appears* to enforce but doesn't. Confirmed by [map §3f].

6. **CI never verifies the one sentinel the whole push-gate depends on.** The `.cr-ok` chain is
   gitignored and never reaches CI [map §3f, "Node 8.5(c) gap… same hole"]. By the page's
   two-layer logic, the readiness signal sits entirely in the probabilistic/advisory layer with
   no deterministic backstop at the CI boundary. Cited absence: [map §3f].

7. **No store/owner for "what cannot be inferred" — and the boundary is model-dependent.** The
   page's design principle (Context Engine = inferable; rules = non-inferable) presumes a stable
   line. Our map shows the line is contested: PITFALLS.md/memory.md are assigned to *both* Layer-1
   Context and Layer-3 Memory depending on the page [map §4], and the Model Capacity Audit
   [map §9] exists precisely because the inferable/non-inferable boundary moved from Sonnet 4.6 →
   Opus 4.8. Gap: we have no mechanism that re-classifies a rule as "now inferable → delete" when
   the model improves. Cited: [map §4, §9].

## (c) Weaknesses in the article's OWN reasoning

Building on pass2 §2, §3, §5:
1. **The FTE metaphor is monotonic and has no decay model** (pass2 §2). Taken literally it argues
   for *more* context files, directly against the canon's mandated pruning of ghost rules /
   capability proxies [map §9]. The page never reconciles "accumulate FTE context" with "remove
   scaffolds the model no longer needs."
2. **It never turns its own principle on its own claims** (pass2 §3, §5). "Tables beat prose
   +25%" and "accountability is cultural" both *violate* the probabilistic/deterministic split
   when applied to safety-critical rules — a +25% probability bump and a cultural norm are both
   probabilistic, yet the page presents them next to the enforcement principle without flagging
   the contradiction.
3. **The load taxonomy is mistaken for an enforcement model** (pass2 §4). always/agent/manual
   answers *when text loads*, not *whether it's obeyed*; the page's own open-question #2 spots
   this then drops it.
4. **Provenance is honest but the load-bearing figures are all single-source.** +25% tables,
   40–60% rewrite reduction, 60–80% acceptance, 67% retrieval-failure reduction — every
   quantified claim is Augment- or vendor-adjacent with "no independent confirmation found" (the
   curator says so in Source Reliability and the ledger). The page leans on numbers it
   simultaneously disowns.
5. **"The system" is a pre-audit canon snapshot** (pass2 §6): its concrete recommendations target
   a hooks-absence and a three-tier gap that disk contradicts [map §3e, §3b].

## (d) Does it warrant fresh external research?

**No — synthesize, do not re-research.** Disciplined call:
- The durable kernel (two-layer enforcement) is already independently triangulated in our corpus:
  the map notes "Augment, Harness, ETH Zurich independently arrive at the same conclusion," and
  this is one of ~15 articles in the v2-audit passes tree. Re-confirming it adds nothing.
- The actionable gaps it exposes (b1–b7) are **all already citable to existing map sections** —
  they need *building/deciding*, not more reading. The page's value was to supply the *why*
  (probabilistic→deterministic) for guards the canon already lists in §5.
- The one genuinely open empirical question — *does prose→table conversion actually move our
  agent's behavior on Opus 4.8?* — is **not answerable by external research** (the +25% is
  single-source and model/benchmark-unspecified per the page's own open-question #3). It is
  answerable only by a local A/B on our own CLAUDE.md, which is a Phase-4/5 experiment, not a
  research task. The page's own Design Challenge gate applies: "if you can't name three rules that
  have actually been violated, run a session first and observe" — that is local observation, not
  external research.

**Verdict:** one synthesized insight (the two-layer principle + the guard-integrity corollary
from pass2 §7), feeding map rows §3e/§3f/§4/§5/§9. No new external sources warranted.
