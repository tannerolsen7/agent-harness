# Adversarial check — V2 Target File Tree (doer≠checker)

**Checker role:** I did NOT write `target-file-tree.md`. I attacked it on the 6 mandated axes and
ground-truthed every load-bearing claim on disk this session (2026-06-11). I tried hard to kill at least
one load-bearing claim; results below.

**Verdict: SOUND-WITH-CORRECTIONS.**

The tree is structurally honest and citation-disciplined — it does not commit the #1 failure (phantom
re-proposal), it does not assume a capability the platform lacks, and it is refreshingly candid that the
raw file-count win is small (the author states this up front rather than hiding it behind a `wc -l`
headline). It survives the phantom, capability, and citation gates. But it carries **one high-severity
content-loss error** (the memory.md "verbatim" claim is false on disk), **one overstated load-bearing
claim** (the PITFALLS split is *not* mechanical), and **several count/gitignore inaccuracies** that must
be corrected before this feeds a decision package. None are fatal to the design direction; all are
fixable in place.

---

## Disk re-verification ledger (what I checked, what I found)

| Claim in doc | Disk result | Status |
|---|---|---|
| `.claude/rules/` ABSENT | `ls .claude/rules` → No such file | ✅ TRUE — shards are genuinely net-new |
| `block-dangerous-bash.sh` / `enforce-scope.sh` / `session-end.sh` / `branch-registry-guard.sh` ABSENT | all 4 absent; 5 hooks present (git, npm, perm-logger, session-start, worktree-create) | ✅ TRUE |
| `dep-update/` empty (no SKILL.md) | confirmed — only skill dir missing SKILL.md | ✅ TRUE |
| 23 agents, all wired | 23 `.md` files; reviewer spawns 4 lenses; spike orchestrator dispatches 6 | ✅ TRUE |
| `reviewer.md` passes `PITFALLS.md` to 4 lens agents in parallel | reviewer.md L18/19/32/42-46: passes CONTEXT/AGENTS/PITFALLS(/TESTING) to each of 4 lenses, spawned in one message | ✅ TRUE — the ~172 KB/review figure is structurally real |
| PITFALLS `**Area:**` field on 36 entries | `grep -c` = 36; 36 `## <slug>` entries total | ✅ TRUE (count) — but see CORRECTION 2 on "mechanical" |
| autoMode in `settings.json`, not `settings.local.json` | settings.json:6 has `autoMode`; settings.local.json has none | ✅ TRUE |
| `.cr-ok.consumed` untracked | `git ls-files` shows no cr-ok files tracked | ✅ TRUE (but gitignore pattern claim wrong — CORRECTION 4) |
| supabase skills are symlinks | both → `../../.agents/skills/...` | ✅ TRUE |
| docs/ (excl research) = 93 | `find docs -type f -not -path 'docs/research/*'` = 93 | ✅ TRUE |
| AGENTS.md "Open Decisions: None open" is a doc-fiction | L362 `_None open._` vs L48/L415 referencing deferred open decisions | ✅ TRUE — real contradiction, correctly flagged |
| memory.md safety trio "already verbatim in CLAUDE.md" | **FALSE** — different format + richer content | ❌ KILLED — see BLOCKER 1 |

---

## The kill attempt (mandated) — one load-bearing claim DID NOT survive

I went after the single most load-bearing deletion in the tree: **memory.md → MERGE → DELETE-CANDIDATE,
justified as "Safety trio → already verbatim in CLAUDE.md floor … The *file* dies; no fact is lost."**

**It does not survive disk inspection.** The two are NOT verbatim:

- `.claude/memory.md:28` (destructive-operation-hard-stop) reads: *"...(DELETE, DROP, TRUNCATE,
  volume/file/record deletion, git reset --hard, git push --force, curl mutations to external APIs,
  Supabase RPC that **writes or deletes data**)..."* followed by a **`Why:`** (the full Cursor/Railway
  9-second incident narrative) and a **`How to apply:`** (write out resource/reversibility/authorization
  before any mutating call).
- `CLAUDE.md:264` reads: *"...(DELETE, DROP, TRUNCATE, volume delete, `rm`, `git reset --hard`, `git push
  --force`, curl mutations to external APIs, Supabase RPC that **mutates rows**)..."* — terser, **no
  incident narrative, no How-to-apply.**

Same *intent*, materially **different wording and strictly less content** in CLAUDE.md. So "no fact is
lost" is false: the incident-narrative `Why:` and the `How to apply:` steps in memory.md are NOT in the
CLAUDE.md floor. Worse, memory.md also holds non-safety traps the doc hand-waves —
`enforcement-boundary-layering` (L84, PreToolUse-vs-git-hook routing), `claude-md-referenced-scripts-must-exist`
(L108), `check-branch-before-commit` (L120) — which must each land in a *named* shard, not "merged away."

**Verdict on the kill: the claim is wounded, not the design.** The fix is small (the new `00-safety.md`
shard must absorb memory.md's richer text **verbatim**, and the three process traps must be explicitly
routed), but the doc as written would license deleting memory.md on a false premise. That is a
content-loss risk and a KEEP-VERBATIM-floor risk, so it is a blocker.

---

## Axis-by-axis findings

### 1. PHANTOM (the #1 failure class) — PASS
No item proposes building something in MASTER-FINDINGS §E. The 8 `.claude/rules/` shards are the only
net-new knowledge files and `.claude/rules/` is confirmed absent (native mechanism, not a custom loader).
The author explicitly tested the prompt's "lens-depth/spike agents are reuse-cuts" hypothesis on disk,
found them wired (reviewer spawns the 4 lenses; spike orchestrator dispatches 6), and correctly **rejected
the cut**. That is the anti-phantom discipline working. The 2 new hooks (`block-dangerous-bash.sh`,
`session-end-capture.sh`) and CI scripts are cited to confirmed absences. **No phantom.**

### 2. CITATION-INVALID — PASS (with one soft spot)
Every disposition row carries a citation (`[map §N]`, `[inv …]`, `[§9]`, enforcement-sort, or a
re-verified disk path). The one soft spot: several `[inv B1]`/`[inv B5]` census-row citations point to an
inventory I did not re-derive (the `inv` rows live in an upstream census, not re-shown here). I spot-checked
the disk facts those rows assert (spent walkthroughs, empty `notes/`, 7 worktrees) and they hold, so the
citations are *substantively* valid even though the `inv` row IDs are opaque. Not a blocker.

### 3. MORE-NOT-FEWER (RED FLAG) — PASS, and honestly self-reported
My independent net-delta count (next section) agrees with the doc's: **knowledge files net ≈ −2 to −3;
total tracked files including new mechanisms ≈ flat to slightly up.** The doc does NOT sneak in net
additions disguised as cuts — it states plainly that the count win is small and that the real win is
duplication-collapse + path-scoped loading, not `wc -l`. This is the correct, non-flattering framing the
binding principle demands. The one place it *understates its own additions* is the mechanism count (see
CORRECTION 3): +2 hooks +4 CI/gen scripts +1 dev-dep is a real `+7 executable files`, which the doc does
disclose in §9/§10 but buries under the "mechanisms delete prose" argument. Acceptable — but the headline
"FEWER knowledge files" must always travel with "roughly flat total files," which it does.

### 4. §9-OVERHEAD — MOSTLY PASS
The §9 survivor test is applied to **every** skill and agent with a one-line failure mode — this is the
requirement met most rigorously. Two soft spots I probed:
- `prioritize-tasks` vs `/queue` and `setup-strategy`+`review-strategy` are flagged as merge-candidates
  but KEPT pending a body-diff. That is the correct conservative call (each names a distinct failure mode
  today); not overhead-by-omission.
- `INDEX.md` and `README.md` are KEPT "drift-checked" — their §9 justification is "phantom-ref vector,"
  which is a real failure mode (the audit itself rotted). Survives.
No kept item lacks a nameable failure mode. **Clean.**

### 5. REQUIREMENT-MISS — PARTIAL (see corrections)
- "fewer files than V1 (counted)" — met, but the count table has an arithmetic error (CORRECTION 3).
- "every change annotated + cited" — met.
- "§9 applied to all skills/agents" — met (all 26 skills + 23 agents carry a line).
- "clutter resolved" — met (§6 resolves every named clutter item).
- "new `.claude/rules/` shown with paths globs" — met (§5 table has `paths:` per shard).
- "plugin-vs-project-owned split marked" — met (§7).
- "before/after count + net mechanism delta" — met but with the count inconsistency.
**The requirements are substantively satisfied; the misses are precision/accuracy, not omission.**

### 6. CAPABILITY-VIOLATION — PASS
I checked the three named traps:
- **Compel a screenshot:** the doc references the render-gate ONLY as a deferral (`[MASTER-FINDINGS §C]`,
  L246/L455). It does NOT assume any hook compels a screenshot artifact. ✅ consistent with
  capability-facts.md.
- **autoMode from committed project settings:** the doc correctly relocates autoMode OUT of committed
  `settings.json` into `settings.local.json`/`managed-settings.json` (L87/L304/§9), exactly per
  capability-facts.md "Not read from shared project settings." ✅
- **Force-continue on Stop:** `session-end-capture.sh` is scoped as a *writer* landing output in S3 (fixing
  #70's discarded output), NOT as a force-continue gate. The doc does not assert force-continue semantics
  that capability-facts.md flagged "verify empirically." ✅
**No capability violation.**

---

## Independent net-file-delta (my own count, not the doc's)

| Zone | BEFORE (disk-verified) | AFTER (proposed) | Δ |
|---|---|---|---|
| `.claude/` top-level files | 17 (incl `.cr-ok`, `.cr-ok.consumed`) | 9 | −8 |
| `.claude/rules/` shards | 0 (absent) | 8 | +8 (NEW, sanctioned) |
| `.claude/skills/` dirs | 26 (23 real bodies + 2 symlink + 1 empty) | 25 dirs (23 bodies + 2 symlink) | −1 (dep-update) |
| `.claude/agents/` | 23 | 23 | 0 |
| `.claude/hooks/` | 5 | 7 | +2 (mechanism) |
| repo-root `*.md` | 8 | 7 | −1 (PITFALLS→shards) |
| `docs/` (excl research) | 93 | 93 (planning+exploration MOVE to archive/; −1 `.gitkeep`) | 0 |
| `scripts/` | 7 (gc, gen-local-env, pr, seed, test-local, worktree-add, README) | 10 (+gen-rules, scan-context, migration-lint/repo-structure) | +3 (mechanism) |

**Net knowledge files: ≈ −2 to −3.** **Net total tracked files (incl mechanisms): ≈ flat (+1 to +2).**

I confirm the doc's headline is honest: this is **NOT** a file-count blowout, and the load-bearing wins
(copies-per-fact 3→1; PITFALLS 43 KB-always → ~2 KB path-scoped; every store gains a decay clock) are real
and are NOT captured by the count. The MORE-NOT-FEWER red flag does **not** fire — but only because the
author refused to inflate the headline. A future revision must not be allowed to drop the "roughly flat
total" caveat.

---

## BLOCKERS (high-severity — must fix before decision package)

**B1. memory.md "verbatim in CLAUDE.md" is FALSE — content-loss + KEEP-VERBATIM-floor risk.**
memory.md's safety entries are NOT verbatim in CLAUDE.md (different wording; CLAUDE.md lacks the incident
`Why:` narratives and the `How to apply:` steps). The disposition "the file dies; no fact is lost" is
unsupported. Required: change the memory.md row to **MERGE-INTO `00-safety.md` (verbatim absorb) THEN
DELETE-CANDIDATE**, and explicitly route the three non-safety memory traps
(`enforcement-boundary-layering`→`harness-hooks.md`, `claude-md-referenced-scripts-must-exist`→a CI/drift
rule, `check-branch-before-commit`→`git-worktree.md`). Until the absorb target exists and is verified to
carry the richer text, memory.md must NOT be deleted. This intersects the KEEP-VERBATIM FLOOR
(destructive-op/PocketOS rules) — deleting the richest copy of those rules on a false "already verbatim"
premise is exactly the failure the floor exists to prevent.

**B2. The "PITFALLS splits mechanically by `**Area:**`" claim is overstated and load-bearing for §5.**
The shard design rests on "the split key is the existing Area field … so boundaries are *mechanical*, not
invented." On disk, several Area values are prose code-path descriptions with **no single `paths:` glob**:
`**Area:** Any code path that deletes a team … that cascades to proposals` (cascade-delete),
`**Area:** Any skill or agent code that calls external tools` (which is `.claude/skills/**` +
`.claude/agents/**`, NOT the `harness-hooks.md` glob of `.claude/hooks/**, scripts/**`), and the worktree
ops (which the doc itself concedes are "advisory — glob optional"). The bucketing is **Area-*guided* but
judgment-*required*, and at least 3–4 entries resist path-scoping entirely** because they gate *operations*
(deletes, worktree adds), not *file edits*. Required correction: downgrade "mechanical" to "Area-guided,
with N entries (cascade/worktree/cross-cutting) that are operation-scoped and load into `00-safety.md` or
remain advisory in `git-worktree.md`." Name the residual entries explicitly so `gen-rules.sh` has a
deterministic rule for them — otherwise the "generated projection, drift-checked" promise (Open Decision 5)
cannot be deterministic, because the un-globbable entries have no mechanical home.

---

## CORRECTIONS (required, lower-severity)

**C1. Worktree count: the doc says "7 stale worktrees"; disk shows exactly 7 dirs** (agent-a6813…,
agent-ad856…, agent-aee11…, feat-proposal-transitions-atomic-rpc, spike-wave-1, tasks-md-update,
tier-0-local-env). The doc is *correct* at 7 — but note the FRESH GROUND TRUTH block in the prompt said
"8 dirs, several stale." Disk = 7. Flag the prompt's ground-truth as stale here, and keep the doc's 7.
(The doc survives this one; recording it so the next reader trusts disk over the prompt block.)

**C2. Skills count arithmetic in §10 is internally inconsistent.** Headline/§1/§3/§8 say "26 → 25"
(−1 dep-update). The §10 count-table row says "23 (26 dirs, 3 = symlink/empty) → 22 + 2 symlink = 24
dirs." 26 dirs − 1 empty = **25 dirs** (23 bodies + 2 symlink), not 24. Fix the §10 row to "26 dirs (23
bodies + 2 symlink + 1 empty) → 25 dirs (23 bodies + 2 symlink)" so the table matches the headline.

**C3. Mechanism file additions are real and must stay in the headline.** Independent count: +2 hooks,
+3 scripts (the doc variously says +3 and +4 — `gen-rules`, `scan-context`, `migration-lint`,
`repo-structure` is four script *names* but §8 lists scripts as 8→11 = +3; reconcile to a single number),
+1 dev-dep. The doc discloses these in §9/§10 but the §8 consolidated tree says scripts "8 → 11" while disk
shows **7** scripts today (gc, gen-local-env, pr, seed, test-local, worktree-add, README), not 8. Fix the
scripts BEFORE to **7** and restate the delta (7 → 10 = +3, or 7 → 11 if repo-structure is separate).
The dev-dependency (`dependency-cruiser`) is correctly flagged ASK-FIRST per CLAUDE.md — good.

**C4. gitignore pattern claim is inaccurate.** The doc asserts (row `.cr-ok` live) "Add `.cr-ok*` …
(already is per sort)." Disk `.gitignore:57-58` is `.claude/.cr-feature-ok` and `.claude/.cr-ok` —
**not** `.cr-ok*`. `.cr-ok.consumed` is in fact untracked (verified via `git ls-files`), but it is
untracked because it was never added, NOT because a `.cr-ok*` glob covers it. Correction: state the actual
patterns and, if `.consumed` residue should be permanently ignored, the recommendation to **add**
`.claude/.cr-ok*` is valid and should be phrased as a new change, not "already is."

**C5. ADR count drift.** §4 and §8 say "adr/ (6)" in one place and "5 ADRs + README" in another. Disk =
5 ADR files + README = 6 entries. Both are defensible but pick one convention ("5 ADRs + README") and use
it consistently so the count table is unambiguous.

---

## What I could NOT kill (claims that survived my attack)

- The **reviewer.md 4-lens PITFALLS pass** (the token-cost spine of the whole consolidation argument) —
  verified true on disk, ~172 KB/review is real. This is the strongest load-bearing claim and it holds.
- The **`.claude/rules/` net-new / native-mechanism** framing — absent on disk, native per
  capability-facts.md. Holds.
- The **anti-phantom discipline** — no §E item re-proposed; the reuse-cut hypothesis correctly tested and
  rejected. Holds.
- The **honest count framing** — my independent count matches; the red flag does not fire. Holds.
- **No capability violation** on the three named traps. Holds.

---

## Bottom line

The design direction is sound and the artifact is unusually honest about its own modest count win. It is
**not** a more-files-than-V1 regression. The two blockers are *accuracy* defects in load-bearing claims
(memory.md verbatim; PITFALLS mechanical-split) that would, if uncorrected, license a content-losing
deletion and promise a deterministic generator that cannot be deterministic for the un-globbable entries.
Fix B1+B2 and the five corrections and this is ready to feed the decision package.
