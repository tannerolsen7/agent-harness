# CHECK — Adversarial anti-duplication gate on MASTER-FINDINGS.md

**Role:** doer≠checker at the decision level. I did not write MASTER-FINDINGS. I attacked every
gap on 5 axes (phantom/already-built · duplicate · citation-invalid · overstated · mis-moved) and
ground-truthed the load-bearing disk claims directly (the prior audit rotted; absence-claims were
not taken on faith).

---

## (a) VERDICT: **SOUND-WITH-CORRECTIONS**

The document does NOT repeat the V1-planning failure. The three V1 phantoms it was built to prevent
are all correctly handled: `learned-patterns.md` is in §F reject-as-literal (not a gap); the bug-fix-test
rule is filed as an *enforcement-boundary* gap that **explicitly rejects** the phantom file as its home
(C2-G9 lines 130-132); `/simplify` is correctly filed as a canon-only absence to build (MOVE 3), not as
a disk mechanism to wire. The §E anti-phantom list is accurate against disk. The spine (advisory→deterministic)
is correctly cited to map §3e.

The corrections are: **1 dropped gap** that should be restored (C2-G13), **2 overstatements** to narrow,
**1 citation that was stale-but-happens-to-be-right** and must be re-grounded so the design doesn't rely
on a rotted premise, and **2 label omissions**. No gap is a true phantom. Nothing needs to be killed
outright. The document is usable as the Phase-3 input after these corrections.

---

## (b) Kill / merge / downgrade / citation-fix list (with evidence)

### [CITATION-FIX — load-bearing] MOVE 2: autoMode "the classifier ignores the file"
**Gap text:** "autoMode policy is in the file the classifier ignores → unattended runs governed by bare
defaults *right now*; also can't travel with the repo. [C4-G4]"

**Problem:** The *source* citation (cluster-4 G4) is built on a STALE live-check — it claimed
"`~/.claude/settings.json` has no autoMode key" and "project custom entries appear 0 times," and
cluster-4 itself flags (line 317) that its snapshots predate commits #99/#100 which ADDED the autoMode
block. On disk **today**, the autoMode block IS present in committed `.claude/settings.json`
(`settings.json:6-32`, environment/allow/soft_deny/hard_deny, each led by `$defaults`). So the literal
premise of the C4-G4 live-check is false now.

**Verdict: SURVIVES — but the citation must be re-grounded.** I tried hard to kill this on "the block
exists now, so the gap is closed." It survives because the *conclusion* is correct for a different,
stronger reason than C4-G4 gave: per official Claude Code docs (`auto-mode-config.md` §"where the
classifier reads configuration" + `settings.md` autoMode row: **"Not read from shared project settings"**),
autoMode in committed `.claude/settings.json` is **architecturally ignored** — by design, so a cloned
repo can't inject allow rules. The classifier reads autoMode only from `~/.claude/settings.json`,
`.claude/settings.local.json`, or managed settings. I verified on disk that `.claude/settings.local.json`
exists but contains **only a `permissions` block — no autoMode**. So "governed by bare defaults right now"
is TRUE, and the distribution-conflict sub-item (the one policy that runs unattended is the one file the
commit-and-distribute thesis cannot commit/review/distribute) is the *strongest* survivor in the cluster.
**Action for design:** replace the citation rationale "the file the classifier ignores [because absent]"
with "the file the classifier ignores **by design** (not-read-from-shared-project-settings) [docs:
auto-mode-config.md; verified settings.local.json carries no autoMode]." Do not let the design lean on
the rotted "appears 0 times" framing.

### [DOWNGRADE] §D: "bug-fix TDD has no executable home [C2-G9]"
**Gap text:** "bug-fix TDD has no executable home [C2-G9]"

**Problem:** Overstated as compressed in §D. `/tdd` SKILL.md line 48 explicitly governs bug fixes
("If this is a bug fix: write the behavior as it SHOULD work, not as it does"). So bug-fix TDD is not
homeless — it has *advisory* guidance.

**Verdict: DOWNGRADE to "bug-fix TDD has no *deterministic enforcement* outside pure functions."** The
real gap (verified) is narrower than "no executable home": CLAUDE.md lines 86-94 scope failing-test-first
to new pure functions in `src/data`/`src/schemas`/`src/utils` ONLY; a bug fix to a component, a server
action, or the `/p/[token]` renderer has no reproducing-test *requirement*. The cluster file (C2-G9) is
actually correctly scoped ("not enforced outside pure functions, and has no executable home" — the
"executable home" = an *enforcement* store, not advisory prose). The §D one-liner dropped the "outside
pure functions / enforcement" qualifier and reads as a duplicate-of-`/tdd` phantom. **This is the exact
V1 failure shape the gate exists to catch — but the cluster got it right; only the §D compression is
loose. Fix the §D wording, do not kill.** Note the cluster ALSO pre-rejects the phantom `learned-patterns.md`
as its home — the gate's #1 enemy is already disarmed here.

### [DOWNGRADE] MOVE 1 part (a): "machine-enforced verification gate at task-completion"
**Gap text (MOVE 1):** "(a) machine-enforced verification gate at task-completion [C1-G2, C4-G3]"

**Problem:** Partial overlap with §E already-built ("Deterministic commit/push floor: pre-commit
(eslint+tsc+vitest); pre-push (tests+next build+.cr-ok)"). A reader could think the gate exists.

**Verdict: SURVIVES as worded — the constraint is already correctly drawn.** I tried to kill it as a
duplicate of the pre-commit/pre-push floor. It survives because MASTER-FINDINGS itself draws the precise
distinguishing line in §E: "Gap is *timing* — commit/push, not task-completion — and *axis* — code-shape,
not render/behavior." That is exactly right and verified: the floor fires at git boundaries, nothing fires
at *subtask-done*. The MOVE 1 constraint ("must NOT write `.cr-ok` or become a capability unlock") is also
correctly carried from map §9. Clean. No change.

### [MERGE-NOTE] MOVE 2 `.cr-ok`→CI relocation vs MOVE 6 read-path
**Gap text:** MOVE 2 "Relocate the forgeable stop authority to CI ... [C2-G1, C3-G9, C4-G3]"

**Problem checked:** Is C4-G3 (verification gate) double-counted — it appears under MOVE 1(a) AND MOVE 2?
**Verdict: NOT a duplicate — correctly split.** C4-G3 has two facets: the *task-completion gate* (MOVE 1,
runtime) and the *CI-verified stop authority* (MOVE 2, branch-protection). These are different mechanisms
at different points in the loop; citing the same source article under both is legitimate because the
article named both. Verified the underlying fact: CI does **not** reference `.cr-ok` (grep of `.github/`
returns nothing) — the 8.5(c) gap is real on disk. No merge needed.

### [SURVIVES] MOVE 2: `block-dangerous-bash.sh`
Ground-truthed: `.claude/hooks/` contains block-dangerous-git.sh, block-npm-install.sh,
permission-logger.sh, session-start.sh, worktree-create.sh — **no block-dangerous-bash.sh**. Confirmed
absence. "Most-cited single gap" is consistent with C3-G2 + C4-G1. Clean.

### [SURVIVES] MOVE 1: session-end.sh ABSENT — but add removal context
Ground-truthed absent. **New evidence the design should carry:** session-end.sh was not merely never
built — it was **deliberately removed** in commit a6076d6 (#70, "remove session-end hook"): "The hook's
only behavior was a `claude --print` session analysis that never surfaced output to the user (stdout
discarded by the harness)." This STRENGTHENS MOVE 1 (the surface is genuinely needed and a prior naive
attempt failed for a specific, avoidable reason — output discarded) and feeds Phase-2b check #1 (what a
Stop hook can actually surface). Survives, with a sharper hypothesis.

### [SURVIVES] MOVE 3: drift detector + invocation-control frontmatter
Verified: `/scan-context` and `/simplify` skill dirs are absent on disk. 25/26 skills have frontmatter
(dep-update is the empty stub — matches map §3b), and **0 have any invocation-control field**
(`disable-model-invocation`/`user-invocable`/`allowed-tools`) beyond `description` — confirming C3-G6
"0/26 invocation-control frontmatter." No CI check validates any knowledge artifact (verified). Clean.

### [SURVIVES] MOVE 6: @benchmark-runner phantom + RECURRING-FINDINGS read-path
Verified: no `benchmark-runner` agent on disk (phantom confirmed). RECURRING-FINDINGS.md is referenced by
**exactly one** skill/agent body — `.claude/skills/cr/SKILL.md` — and by no implementer/agent. This is
the strongest single confirmation of "pipeline-only, never read by implementers." Clean — I could not
break this.

### [SURVIVES] §E anti-phantom list — spot-audited, accurate
CONTEXT.md exists (15KB) ✓; chrome-devtools-mcp configured + Playwright explicitly rejected in
`.claude/mcp.md` ✓; permission-logger.sh disk-only ✓; worktree-create.sh prod-key firewall present ✓;
6th store auto-memory exists ✓; `/loop` and `/goal` correctly NOT on disk (loop is runtime-only, goal
deferred) ✓. The reject-list (§F) "Build learned-patterns.md ×3" correctly maps to the §6 phantom.

### [SURVIVES] §C deferred items — absence verified
No egress/proxy control on disk; no `/goal` skill; no scheduler hook. All correctly registered-not-built.
The "CronCreate/`/schedule`/`/loop` substrate already in the runtime" claim is consistent (these are
runtime tools, not project skill dirs — verified no project dirs, which matches "already in the runtime").

---

## (c) Gaps I tried HARDEST to kill — and they SURVIVED (the design can rely on these)

1. **MOVE 2 / C4-G4 autoMode placement.** Best kill attempt: "the block exists in settings.json now,
   so this is stale rot — close it." Survived: official docs confirm committed project settings.json is
   **not read** for autoMode by design, and settings.local.json carries no autoMode block — so the
   conclusion holds for a *stronger* reason than the original citation. The single most important survivor
   because it is the highest-severity *currently-broken* state. (Citation must be re-grounded — see (b).)

2. **§D / C2-G9 bug-fix TDD.** Best kill attempt: "this duplicates `/tdd`, which handles bug fixes at
   line 48 — it's the V1 bugfix-test phantom again." Survived as a *downgraded enforcement* gap: `/tdd`
   is advisory and CLAUDE.md scopes the *requirement* to pure functions only; component/server-action/
   renderer bug fixes have no reproducing-test requirement. The cluster correctly rejects the phantom home.

3. **MOVE 6 / RECURRING-FINDINGS "never read by implementers."** Best kill attempt: "surely something
   reads it." Survived: grep proves exactly one reader (`/cr` SKILL.md), zero implementers. Hard fact.

4. **MOVE 2 `.cr-ok`→CI.** Best kill attempt: "CI must verify it somewhere." Survived: `.github/` has no
   reference to `.cr-ok`. The forgeable-stop-authority gap is a verified disk fact.

5. **MOVE 1 session-end surface.** Best kill attempt: "it was removed on purpose — leave it dead."
   Survived and strengthened: it was removed for a *fixable* reason (output discarded), not because the
   need was wrong.

---

## (d) Gaps the cluster files contain that MASTER-FINDINGS DROPPED

1. **[RESTORE] C2-G13 — "errors-into-context + a deterministic circuit-breaker convention is absent."**
   This appears **nowhere** in MASTER-FINDINGS — not in any MOVE, not in §C deferred, not in §D. Verified
   it is a real confirmed absence: the hook inventory (`.claude/hooks/`) has no hook that handles tool-error
   compaction; the memory model captures human-corrected mistakes, not runtime tool failures fed back to
   the agent. The cluster scoped it well: "errors→context **+** a deterministic max-retry/circuit-breaker
   in a hook." Its circuit-breaker/give-up half PARTIALLY overlaps MOVE 1 part (c) ("retry-ceiling counter
   + REJECT/handoff tier [C1-G3]") — but the **errors-into-context half is distinct and unabsorbed**:
   C1-G3 is about retry *count*; C2-G13 is about *feeding the tool error back into agent context so the
   retry is informed*. **Recommendation:** fold C2-G13's errors-into-context half into MOVE 1 as a sixth
   payload (it is exactly a Stop/PostToolUse-adjacent hook concern), and note its breaker half already
   lives in MOVE 1(c). Do not leave it silently dropped — it is a 12-factor F9 mechanism with a clean
   citation.

2. **[LABEL-FIX, minor] C2-G5 — "doc-authority / freshness Doctrine layer."** MOVE 3 cites C3-G5 and
   C3-G6 but not C2-G5, even though MOVE 3's own text ("freshness for only 3 of ~14 stores, read-time for
   ~5 of 14") is *verbatim C2-G5 content*, and C3-G10 (authority taxonomy) is cited. So C2-G5's substance
   IS absorbed into MOVE 3 — this is a missing citation label, not a dropped gap. Add `C2-G5` to the MOVE 3
   citation line for traceability.

---

## Summary of required edits before Phase 3

| # | Action | Item | Why |
|---|---|---|---|
| 1 | CITATION-FIX | MOVE 2 autoMode (C4-G4) | Re-ground on "not-read-from-shared-project-settings by design" (docs-verified), not the stale "appears 0 times" snapshot |
| 2 | DOWNGRADE wording | §D bug-fix TDD (C2-G9) | Narrow to "no *deterministic enforcement* outside pure functions"; `/tdd` line 48 gives advisory guidance |
| 3 | RESTORE | C2-G13 errors-into-context | Dropped entirely; fold the errors→context half into MOVE 1 (breaker half overlaps C1-G3) |
| 4 | LABEL-FIX | Add C2-G5 to MOVE 3 citations | Substance already absorbed; citation missing |

Everything else stands. No gap is a phantom; no gap names something already built without citing why the
existing mechanism is insufficient; the §E anti-phantom list holds against disk.
