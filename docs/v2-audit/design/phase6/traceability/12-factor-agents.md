# Traceability — "12-Factor Agents" pass-3 → V2 design

**Source:** `passes/12-factor-agents/pass3-apply.md` §(b) REAL gaps + the load-bearing pass-3
conclusions and §(c) caveats that shape the design.
**Method:** each distinct gap/insight classified APPLIED / CUT / DROPPED against the V2 corpus
(MASTER-FINDINGS, phase3/phase45/phase6 reconciliations, V1-TO-V2-CARRYFORWARD, enforcement-sort,
target-file-tree). Every classification grounded by grep, cited inline.

The article's own framing: its value to us is a **coherent vocabulary** naming five gaps already
present in our map (F3 authority, F5 state unification, F9 error convention, F10 scope discipline,
F11 triggers), plus a set of weaknesses-in-its-own-reasoning (§c) — one of which (the
"context-engineering compounds" assumption) is load-bearing because it collides with our §9 axis.

---

## Per-gap classification

| # | Gap / insight (pass-3 §) | Class | Where it lands (or why not) |
|---|---|---|---|
| 1 | **F3 — harness has no machine-enforced doc-authority level; context bag mixes authority levels with no tooling to separate them** (§b) | **APPLIED** | MOVE 3 memory model. `entry-as-atom`: `tier:`/`kind:`/`freshness:` are per-entry properties [phase3/RECONCILIATION §B; memory-model.md:35,256]; explicit precedence rule "auto-memory **outranked by** S1–S3 / on conflict curated stores win" [memory-model.md:290; phase3/RECONCILIATION:109]. The "no tooling to separate authority" half is closed by the `/scan-context` drift detector (R65 → L1-CI) which catches doc-stale AND doc-fiction AND decay [MASTER-FINDINGS:77–78; enforcement-sort R65, line 169]. |
| 2 | **F5 — execution + business state not unified; the same corrected-mistake fact lives in memory.md + PITFALLS.md + auto-memory (triple-duplication the canon both sanctions and forbids)** (§b) | **APPLIED** | MOVE 3 is exactly this: "one writer / one reader / one freshness rule per store," copies-per-fact **3→1** [MASTER-FINDINGS:71–76; phase3/RECONCILIATION:193]. memory.md merges into `00-safety.md` + `.claude/rules/` shards; PITFALLS monolith → path-scoped shards [phase3/RECONCILIATION §B, §D]. The strongest factor-to-row mapping in the article; directly carried. |
| 3 | **F5 — auto-memory (MEMORY.md + 51 siblings) is a "sixth store the canon's model doesn't account for"; a literal second state system outside the canonical one** (§b) | **APPLIED** | The 6th store is explicitly modeled, not ignored: "ridden as a cache, demoted in authority" [memory-model.md:271]; "the canon ignores it; the model may not" [memory-model.md:97,273]. Reclassified to a ridden cache outranked by S1–S3 [memory-model.md:290]. Carried as a named element of the 3-owned-stores + 1-ridden-cache target [phase3/RECONCILIATION §B]. |
| 4 | **F9 — no errors-into-context convention; no error-handling hook, skill rule, or PITFALLS entry; memory captures human-corrected mistakes, not runtime tool failures** (§b) | **APPLIED** | Lands as R133 (failed tool call compacts error into context, never throw/null) → relocate to L1 PostToolUse errors-into-context hook, a MOVE-1 emitter [enforcement-sort R133, line 237; MASTER-FINDINGS MOVE 1 (f), line 39]. Restored via the anti-dup check as "C2-G13" [CHECK-master-findings:160–168]. (Note: the article asserts "no PITFALLS entry"; the rule-inventory R133 sources to a PITFALLS § error-into-context-not-throw [rule-inventory:179] — but it was L3-advisory-prose-only, so the *enforced* convention was genuinely absent and is now built.) |
| 5 | **F9-aware refinement — the convention we lack is "errors→context + a deterministic max-retry / circuit-breaker in a hook" (F8-aware), not naive errors→context** (§b, §c F9-vs-F8 conflict) | **APPLIED** | Both halves are carried and explicitly split: errors-into-context = MOVE-1 part (f); the circuit-breaker/give-up half = MOVE-1 part (c) "retry-ceiling counter + REJECT/handoff tier" [MASTER-FINDINGS:38–40]. The CHECK confirms the two halves are distinct and both home in MOVE 1 [CHECK-master-findings:164–168]. The F8-aware framing ("give-up is control flow, lives in a hook") is honored by placing the breaker in the Stop-hook counter, not the model. |
| 6 | **F10 — one-agent-one-job scope discipline is uncodified; roster (23 agents) grew lane-depth not reuse; no scope-limiting design rule in SOUL/AGENTS/CLAUDE; "job fits in one sentence" has no home** (§b) | **CUT (deferred, §D) + partially APPLIED** | Registered as a smaller confirmed gap "one-agent-one-job scope discipline (roster grew lane-depth not reuse) [C2-G14]" [MASTER-FINDINGS:134], with the stated direction: at ~8–23 specialists are *clarity*; real gap = **taxonomy reconciliation**, not the article's collapse-to-skills [MASTER-FINDINGS:182–184]. Each of the 23 agents was §9-tested on disk and kept (each carries a failure-mode line) [target-file-tree:188; phase3/RECONCILIATION §D]. So the *roster* is validated (applied-as-kept); the *codified one-sentence scope rule* is registered but not built (deferred, with reason: reuse-over-lane-depth is "valid for future growth," not now). See DROPPED #1 for the missing nuance. |
| 7 | **F11 — trigger-from-anywhere is a confirmed structural absence; correctly re-scoped as downstream of the global-install gap (no installable shared harness to trigger), not a standalone plumbing task** (§b) | **CUT (hypothesis-gated, §C)** | Both halves land. The install-gap precondition = MOVE 5 (make the harness installable; converge canon↔disk → plugin/template) [MASTER-FINDINGS MOVE 5]. The trigger front-door itself is registered-not-built: "Autonomous trigger front-door (bug→PR; harness can build but can't be summoned). Gated on V2 deciding autonomy is in scope" [MASTER-FINDINGS:115], and it is decision **D3** with recommendation NO — keep hypothesis-gated [phase6/REVIEWER-CONSOLIDATION:160–164]. The re-scoping (F11 is *downstream* of install) is explicitly preserved [cluster-findings-2:93]. |
| 8 | **§c caveat — "context engineering > model choice / model choice is a rounding error" collides with our §9 Model Capacity Audit premise that a model upgrade RETIRES context-engineering scaffolds; context-engineering investment can depreciate into overhead** (§c, the article's load-bearing blind spot) | **CUT (reject-as-literal) → becomes a design pillar** | The literal claim is rejected with reason in cluster-findings-2's reject table: "Directly contradicts [map §9]: a model upgrade (Sonnet 4.6 → Opus 4.8) *retires* context-engineering scaffolds. Under fast capability gains, context-engineering investment can depreciate into overhead" [cluster-findings-2:245]. The article's *blind spot* is precisely the premise of **MOVE 4** — the §9 re-audit on Opus 4.8 as "the deletion engine," rule = "name a failure mode the constraint prevents, or it's overhead" [MASTER-FINDINGS MOVE 4, lines 85–91]. The caveat shaped the design, not just got cut. |
| 9 | **§c — "frameworks are evil" (F8 absolutism) is contradicted by the article's own pragmatic "take small modular concepts into your existing product"; read literally it condemns the vendor harness we operate inside** (§c, §a "own our prompts/control flow") | **CUT (reject-as-literal)** | "frameworks are evil" is in the consolidated reject list [MASTER-FINDINGS §F, line 190: "...'frameworks are evil' — each rejected with reason in the cluster files"]. The usable residue (own the seams you debug — prompts, context assembly, retry/branch decisions; borrow the rest) is exactly what the decision/execution split in §a already does and what MOVE 1–2 build (model proposes, hook disposes). Consciously rejected with reason. |
| 10 | **§c — F12 "stateless reducer / test the agent like a function" is true of the step, not the agent (model not deterministic given identical context; agent accretes state)** (§c, §a F12 demotion is the durable core) | **CUT (reject-as-literal, partial)** | The durable core ("demote the model to a decision-function; own control flow/prompts/state") is the §a already-do, structurally present via hooks [pass3 §a; MASTER-FINDINGS §A spine — model proposes, hook disposes]. The over-stated invariant ("the agent is a pure function / test it like a function") is implicitly cut — measurement in MOVE 6 is *recall/golden-set* eval (never-self-certify), not "test the agent as a deterministic function" [phase45/RECONCILIATION Phase 5]. The discipline is kept; the literal property is not adopted. Low-stakes; no design slot needed. |

---

## Summary of counts

- **APPLIED:** 5 (gaps #1 F3 authority, #2 F5 state, #3 F5 sixth-store, #4 F9 errors→context, #5 F9+breaker)
- **CUT (consciously rejected §F or deferred §C/§D with reason):** 5 (gaps #6 F10 scope rule [deferred], #7 F11 triggers [hypothesis-gated], #8 model-choice caveat [reject-as-literal → became MOVE 4], #9 frameworks-are-evil [reject-as-literal], #10 F12-as-property [reject-as-literal])
- **DROPPED (real misses — below):** 1 nuance

Note on #6: the *roster validation* half is APPLIED (23 agents §9-kept); only the *codified one-sentence
scope rule* is deferred, and one nuance inside it is a real miss (DROPPED #1).

---

## DROPPED — real misses

### D1. The F10 codified scope-limiting design rule has no home, and the *deletion of TASK-TEMPLATE removes its scope-discipline payload without a replacement enforcement*

The pass-3 F10 gap is twofold: (a) the roster taxonomy is inconsistent ("8 specialist agents" header over a
9-row table; "Ten" templates over 8 roles), and (b) **there is no scope-limiting design rule anywhere in
SOUL/AGENTS/CLAUDE**, so the article's proposed "an agent's job description fits in one sentence" has no home.

- Half (a), taxonomy reconciliation, is named [MASTER-FINDINGS:183 "Real gap = taxonomy reconciliation"] but
  **no concrete artifact carries the reconciliation** — it is asserted as a gap, never assigned to a MOVE,
  store, or build item. It is not in the enforcement-sort, the file tree, or the carry-forward agents row
  (which only confirms "KEEP all 23," not "reconcile the count"). This is a registered-but-unhomed half.
- Half (b), the codified scope rule, is **partially DROPPED with a coverage hole.** The scope discipline was
  carried by `TASK-TEMPLATE.md`'s `## ALLOWED FILES` section, but the file tree marks TASK-TEMPLATE
  DELETE-CANDIDATE and asserts "scope discipline covered by CLAUDE.md 'Before writing code' + the
  enforcement-sort `/cr-security` glob classifier" [target-file-tree:77]. That substitution is **wrong on the
  merits for F10**: `/cr-security`'s glob classifier forces a *security review* on auth/RLS diffs — it does
  **not** enforce a sub-agent's per-task file scope, which is what the deleted `## ALLOWED FILES` payload did.
  The enforcement-sort itself notes the reader is absent: "Its enforcement counterpart `enforce-scope.sh`
  (which would read `## ALLOWED FILES`) is **ABSENT**" [target-file-tree:77], and R71 (bg-agent scope) +
  R91 (never expand scope) stay L3 prose. So the F10 "one job, scoped" insight survives only as kept-prose
  judgment rules, while its one structural enforcement vehicle is deleted with a non-equivalent replacement
  named. **The miss:** no artifact reconciles the agent count, and no rule/mechanism encodes "an agent's job
  fits one sentence / a sub-agent's scope is enforced" — both are dismissed via a substitution that doesn't
  actually cover the F10 case.

**Where it should go:** MASTER-FINDINGS §D (smaller gaps) already lists C2-G14 — it needs a one-line
disposition added: (i) a concrete owner for taxonomy reconciliation (a `/init`-scaffolded canonical agent
roster table, or a CI count-coherence check in `repo-structure`), and (ii) an explicit acknowledgment that
deleting TASK-TEMPLATE drops per-task scope *enforcement* (not just advice), reverting it to L3 prose —
either accept that consciously or keep the ~2 KB machine-readable scope spec the file tree itself says would
be "reborn" if `enforce-scope.sh` is ever built. As written, the substitution is asserted as equivalent and
it is not.

**Why it matters:** sub-agent scope creep is a named V1 risk the `agent-contract.md` SCOPE / STOP-AND-SURFACE
discipline exists to prevent [V1-TO-V2-CARRYFORWARD:25]. Carrying agent-contract forward as prose while
deleting the only structural scope payload, and claiming `/cr-security` covers it, is the exact
"advisory-only, no deterministic backstop" pattern the whole V2 effort is trying to close (§A spine). Low
blast radius (it is one of the smaller gaps), but it is a real traceability miss, not a conscious cut.
