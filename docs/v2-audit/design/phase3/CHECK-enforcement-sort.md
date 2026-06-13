# Adversarial Check — `enforcement-sort.md` (Phase 3)

**Role:** adversarial checker (doer≠checker). **Date:** 2026-06-11. **Method:** read the artifact, then
ground-truthed every load-bearing disk claim with my own Bash/Grep/Read (the audit rots — I did not trust
the artifact's "disk-re-verified" header). Cross-checked phantoms against MASTER-FINDINGS §E and the fresh
ground-truth block. Cross-checked R-numbers and rule text against `phase3/rule-inventory.md` (134 entries,
confirmed).

**Verdict: SOUND-WITH-CORRECTIONS.**

The sort is structurally correct, every row carries a failure mode, the keep-verbatim floor is honored,
and its load-bearing disk claims (`.cr-ok` never reaches CI; autoMode ignored in committed project
settings; `block-dangerous-bash`/`enforce-scope`/`.claude/rules` absent; dependency-cruiser absent;
commitlint/migration-lint absent) all **survived** my re-verification. But I killed one load-bearing
claim outright (a genuine PHANTOM — R2), found one more partial phantom (R101), and the headline
"consolidation = fewer files" framing is **misleading on the binding-principle axis**: the artifact
reduces *rules-per-mechanism* but **adds 6–9 net new files/mechanisms**. That net-positive delta must be
stated honestly, not hidden behind a rule-count headline. Neither issue sinks the sort; both require
correction before it feeds the decision package.

---

## Axis-by-axis

### 1. PHANTOM — propose building/keeping something that already exists? (the #1 failure class)

**KILLED ONE LOAD-BEARING CLAIM. R2 is a phantom.**

- **R2 (no `@ts-ignore`/`@ts-expect-error`) — PHANTOM relocate.** The artifact (table line 106) lists R2 as
  `current: L3`, `TARGET: L1`, verdict **relocate**, mechanism "add ESLint `@typescript-eslint/ban-ts-comment`
  error." I probed it: a file in `src/` containing `// @ts-ignore` already produces
  **`error … @typescript-eslint/ban-ts-comment`** under `npm run lint` today. The rule ships transitively
  via `eslint-config-next/typescript` (it is not in `eslint.config.mjs` text, which is why a config grep
  misses it — but it FIRES). So R2 is **already L1**, exactly like R1. The artifact proposes adding a rule
  that already exists and already errors. **Correct disposition: `keep (already L1)`, not `relocate`.** This
  is the same failure class the governing citation rule exists to prevent ("NEVER propose building something
  that already exists"). I tried hardest to kill this one and it died.

- **R101 (`next/image`) — PARTIAL phantom.** Table line 205 lists R101 as relocate via "ESLint
  `@next/next/no-img-element` (error)." I probed it: the rule is **already active but at `warning`
  severity** (ships via `core-web-vitals`). And critically: `npm run lint` = bare `eslint` with **no
  `--max-warnings 0`** — I confirmed a warning exits 0. So the *rule exists* but is *not enforcing*. The
  relocation is therefore real (warn→error is a true state change) but the artifact mis-describes it as
  net-new; it must say "bump existing `no-img-element` from warn→error." Downgrade from phantom to
  citation-imprecision, but it must be corrected.

- **The `npm run lint` warning-blindness is a structural finding the sort half-misses.** Several "relocate
  to ESLint" rows (R30 `multiline-comment-style`, R36 `vi.mock` ban, R37 snapshot ban, R106 viewport) are
  only L1 **if the rule is set to `error`**. `no-console` is `warn` today and does not block. Any new
  ESLint rule the sort adds at `warn` is **not L1** — it is advisory-with-a-squiggle. The build list must
  state: every relocate-to-ESLint row requires `error` severity AND either `--max-warnings 0` in the lint
  script or error-level rules only. Otherwise the "≈64 rules become deterministic" headline silently
  overcounts. *(This is also a CAPABILITY-adjacent issue — see axis 6.)*

- **No other phantoms.** I checked the rest of MASTER-FINDINGS §E against the build list. The sort does NOT
  re-propose `/cr` (it correctly treats it as existing and re-homes only its *gate*), does NOT re-propose
  `block-dangerous-git`/`block-npm-install` (cites them as the template), does NOT re-propose `/loop` or
  `/compound`, does NOT build `learned-patterns.md`. `session-start.sh` is correctly cited as EXISTING-but-
  orphaned (I confirmed it only truncates a perm-log and runs `npm install` on remote — it does NOT read
  memory/TASKS/rituals; R42/R43/R44 wiring is genuinely net-new behavior on an existing file, not a phantom).
  R52/R53 skill-`paths:` activation: I confirmed **0/26 skills use `paths:` or `disable-model-invocation`**
  — genuinely net-new, not phantom. **Axis verdict: 1 dead claim (R2), 1 partial (R101); rest clean.**

### 2. CITATION-INVALID — any change lacking a map-row / disk-path / confirmed-absence citation?

**PASS.** Every table row cites a source (CLAUDE/AGENTS/PITFALLS) and every relocation rides a cited
resolution (a)–(e) or a MOVE/map reference. I spot-verified the load-bearing absences myself:
`block-dangerous-bash.sh`, `enforce-scope.sh`, `branch-registry-guard.sh`, `session-end.sh`, `.claude/rules/`
— **all ABSENT** (confirmed). `dependency-cruiser` — **not in package.json** (confirmed). `.cr-ok` is
`.gitignore:58` and appears in **NO** `.github/workflows/*.yml` — resolution (b)'s core claim that it
"never reaches CI" is **TRUE on disk** (I grepped both ci.yml and integration.yml). commitlint + commit-msg
hook + any migration-lint check — **all absent** (confirmed; R86/R92/R93/etc. are genuinely net-new). The
one citation imprecision is R2/R101 above (cited as relocate, actually already-enforced / enforced-at-warn).

### 3. MORE-NOT-FEWER (the RED FLAG) — does it ACTUALLY reduce files/mechanisms?

**THIS IS THE WEAKEST PART OF THE ARTIFACT AND MUST BE CORRECTED.** The artifact's headline ("7 build
items absorb ~64 rules… fewer files, more wiring") **conflates two different deltas** and reports the
favorable one:

- **Rules-per-mechanism delta: genuinely down.** ~64 advisory rules collapse onto 7 mechanisms. True, and
  good. The cross-file *rule echo* (R20≡R103, R5≡R126, R44≡R85, R52≡R95, R66≡R68≡R69) is correctly deduped
  to one home each. The DELETE list (NEVER-section, R30, R54, R55) is real subtraction. This axis is fine
  *for rules*.

- **Files/mechanisms delta: NET POSITIVE. The binding principle is about files/mechanisms, not rules.**
  My independent count of net-new *artifacts* the build list introduces:
  1. `block-dangerous-bash.sh` — **+1 hook file**
  2. CI-relocated stop authority — **+1 CI job** + **+1 committed `/cr` artifact** (the gitignored sentinel
     must be replaced by a CI-readable artifact) + branch-protection config (off-disk)
  3. `/cr-security` path classifier — **+1 CI job** (and likely +1 script)
  4. `dependency-cruiser` — **+1 npm dependency** + **+1 `.dependency-cruiser.js` ruleset** + **+1 CI step**
  5. `migration-lint` — **+1 CI script**
  6. `repo-structure` — **+1 CI script**; **commitlint** — **+1 commit-msg hook** + **+1 dep** + **+1
     config**
  7. autoMode placement — net-zero **or +1** (`managed-settings.json` if the enforced floor is built)

  **Net delta: roughly +6 to +9 files/mechanisms** (3–4 hooks/scripts, 2–3 CI jobs, 1 depcruise config +
  dep + ruleset, possibly 1 managed-settings file). The DELETE column removes **zero files** — it deletes
  the *CLAUDE.md NEVER section* (prose lines, not a file), R30/R54/R55 (rule lines), and dedups echoes
  (prose). **So on the binding-principle's own axis — files/stores/mechanisms — this artifact is a NET ADD,
  not a reduction.** The artifact's "Convergence check" ("No new mechanism is invented here") is *true* in
  the narrow sense that MASTER-FINDINGS MOVE 1+2 already *named* these mechanisms — but "already named in a
  sibling finding" is not "already exists on disk." Six-to-nine things get built that do not exist today.

  **This is defensible** — enforcement-relocation legitimately costs files; you cannot make an advisory rule
  deterministic without *some* deterministic artifact. The §9 criterion ("name a failure mode → not
  overhead") is satisfied for every one of these mechanisms (the migration-lint absorbs 8 safety-critical
  rules; the bash guard absorbs the PocketOS class; etc.). **But the artifact must STOP claiming "fewer
  files."** The honest framing is: *"This sort trades ~64 lines of unenforced prose for ~7 enforcing
  mechanisms (+6–9 files). It reduces advisory surface and rule-duplication; it does NOT reduce file count.
  The file-count win, if any, must come from MOVE 3 (memory-store consolidation) and MOVE 4 (deletion
  engine), not from this sort."* Required correction below.

### 4. §9-OVERHEAD — any kept/added rule/store/file with NO nameable failure mode?

**PASS, with two soft flags.** Every table row has a failure-mode column, including the keeps. The two
weakest:
- **R28/R29 (comment style)** — the artifact itself flags these as DELETE-candidates and demotes the
  three-way split to one L3 line. Acceptable; arguably should be a harder DELETE since "noise comments; low
  harm" is barely a failure mode. Not a blocker.
- **R70 (surface PR URL), R119, R121** — flagged demote/niche; failure modes are "minor UX gap" /
  "truncated page." These survive §9 only weakly. Fine to keep-but-de-emphasize as the artifact does.

No *added* mechanism lacks a failure mode. The migration-lint, bash-guard, depcruise, CI-stop-authority,
and security-classifier each name a concrete (often safety-critical) failure mode. Clean.

### 5. REQUIREMENT-MISS — does it satisfy EVERY Phase-3 requirement for this artifact?

**Mostly PASS. One requirement is under-specified.**

| Requirement | Status |
|---|---|
| Every rule sorted L1/L2/L3 | ✅ all R1–R134 in the table |
| Each L1/L2 carries a failure mode | ✅ failure-mode column populated for every row |
| §9 demote/delete applied | ✅ DELETE/demote/dedup section present and reasoned |
| Keep-verbatim floor honored | ✅ R77–R82, R38, R39, R41, R57, R59/R91 all kept (R77 keeps prose + gains backstop; R78–R82 stay tier-1 L3). I confirmed all are present in rule-inventory and none are cut. |
| block-dangerous-bash absorption | ✅ resolution (a), explicit absorbed-rule list |
| `.cr-ok` → CI relocation | ⚠️ **under-specified.** resolution (b) correctly diagnoses forgeability and re-homes R66/R68/R69, but hand-waves the *mechanism*: "a CI job that re-derives MUST-FIX=0 from a committed `/cr` artifact (not the gitignored sentinel)." There is **no such committed artifact today**, and `/cr` writing one that CI trusts re-introduces the *same* forgeability one layer up (the model writes the artifact CI reads). The artifact acknowledges the coverage-bound caveat but does not resolve *who writes the CI-trusted record and why the model can't forge it*. This is the load-bearing unforgeability claim and it is left as an exercise. Needs sharpening (correction below) — not wrong, incomplete. |
| `/cr-security` path-classifier | ✅ resolution (c), glob set named (`proxy.ts`, `**/middleware*`, `src/data/**`, RLS migrations) |
| layer-boundary → dependency-cruiser | ✅ resolution (d), rule set R9/R10/R11/R24/R76/R90/R110/R123/R126 named; correctly notes ASK-FIRST for the dep and report-mode-first per canon |
| autoMode placement fix | ✅ resolution (e), correct home (local/managed), correct human-handoff (no agent edits to guard files) |
| new hooks/tests named | ✅ the 7-item build list names each |

### 6. CAPABILITY-VIOLATION — assume a mechanism can do what capability-facts says it cannot?

**Mostly PASS — three things to watch, one is a real correction.**

- **CORRECTION: warning-severity ESLint is not L1.** (Cross-ref axis 1.) `capability-facts.md` doesn't
  cover this but disk does: `npm run lint` exits 0 on warnings. Any relocate-to-ESLint row that lands at
  `warn` is NOT a deterministic gate. The sort must require `error` + (error-only OR `--max-warnings 0`).
  Without this, R101 and any future warn-level rule are advisory, not L1 — a silent overcount.
- **R133 (errors-into-context) on PostToolUse** — capability-facts confirms PostToolUse can inject feedback
  but **cannot rewind/retry a tool**. The artifact lists R133 as L1 "PostToolUse errors-into-context hook"
  without claiming retry — consistent with capability-facts. ✅
- **autoMode (resolution e)** — the artifact correctly states autoMode is "Not read from shared project
  settings" and moves it to local/managed. This is the *exact* capability-facts finding. It does NOT assume
  a committed-settings autoMode is honored. ✅ And it correctly routes the fix as a human handoff (managed-
  settings is agent-unreachable; I confirmed neither the macOS nor Linux managed path exists on this
  machine — it's an available-but-unbuilt lever, matching the artifact).
- **Stop-hook force-continue (resolution b / MOVE 1 dependency)** — the CI-relocated stop authority leans
  on a CI gate (unforgeable) rather than a Stop-hook force-continue, which is the *safer* reading given
  capability-facts flags force-continue semantics as "verify empirically." The artifact does not over-claim
  Stop-hook behavior here. ✅ (It would be a violation if it claimed a Stop hook *compels* the model to
  re-run `/cr`; it does not — it puts the gate in branch-protection.)

---

## Did I kill a load-bearing claim? Report.

**Yes — two, one fully.**
1. **R2 phantom (FULLY KILLED).** "Add `ban-ts-comment` as an ESLint error" — the rule already errors
   today. Proven by probe. This is a true phantom under the governing citation rule.
2. **"Fewer files" headline (KILLED on the binding-principle axis).** Independently counted: the build list
   is **+6 to +9 net files/mechanisms**, and the DELETE column removes **zero files**. The rule-count
   reduction is real; the file/mechanism-count reduction is **negative**. The artifact's own RED-FLAG axis
   is not satisfied by this sort alone — it's satisfied (if at all) only when combined with MOVE 3/MOVE 4.

Both survived as *corrections*, not as fatal flaws — the sort's core thesis (relocate advisory→deterministic,
one home per rule, keep-verbatim floor intact) holds. Hence SOUND-WITH-CORRECTIONS, not UNSOUND.

---

## Blockers (high-severity — fix before this feeds the decision package)

1. **R2 is a phantom.** Re-classify R2 as `keep (already L1)` — `@typescript-eslint/ban-ts-comment` already
   errors via `eslint-config-next/typescript` (proven by probe). Remove R2 from the L1 *relocate* count;
   move it to the "already L1" set alongside R1. Adjust the "≈30 L1 / ≈64 deterministic" headline by one.
2. **The "fewer files / consolidation = success" framing is false on the binding-principle axis and must be
   corrected.** State the true net delta: **+6 to +9 net new files/mechanisms, 0 files deleted.** Reframe
   the win as "advisory-surface reduction + rule-deduplication," and explicitly hand the *file-count*
   reduction to MOVE 3 (memory stores) and MOVE 4 (deletion engine). Do not let a rules-per-mechanism count
   stand in for a file-count claim — the binding principle counts files/stores/mechanisms.

## Required corrections (specific)

1. **R2 → `keep (already L1)`** (blocker 1).
2. **R101 → "bump existing `@next/next/no-img-element` from warn→error"**, not a net-new relocate. It is
   already present at `warn` and does not block (`npm run lint` exits 0 on warnings — proven).
3. **Add a global L1-ESLint precondition to the build list:** every relocate-to-ESLint row (R2 already-ok,
   R30, R36, R37, R101, R106) is L1 **only at `error` severity** with either error-only rules or
   `--max-warnings 0` added to the `lint` script. Without this the deterministic-count overstates. (Note
   `no-console` is `warn` today and does not block — the template to avoid.)
4. **Sharpen resolution (b)'s unforgeability mechanism.** "CI re-derives MUST-FIX=0 from a committed `/cr`
   artifact" needs one more sentence answering: *who writes that artifact and why can't the model forge it
   the same way it forges `.cr-ok`?* Either (a) CI itself re-runs the deterministic subset of `/cr` (the
   parts that are tests/lint, not the judgment passes) so the model never writes the trusted record, or
   (b) accept it as a coverage-bounded trust-but-verify gate and SAY SO. As written it risks moving the
   forge one layer up. (Not a blocker — the diagnosis is right and the CI-required-checks-on-sentinel-SHA
   half IS unforgeable; only the MUST-FIX=0 half is hand-waved.)
5. **commit-msg/commitlint (R86) and dependency-cruiser (R90 dep-ban half) both require new npm
   dependencies** — surface them under the project's "ASK before installing any npm package" rule (R60).
   The artifact does this for dependency-cruiser but not for commitlint. Add commitlint to the ASK list
   (name/purpose/downloads/types) before counting R86 as built.

---

## Net file delta (my independent assessment)

**NET POSITIVE: +6 to +9 files/mechanisms; 0 files deleted.** Breakdown: `block-dangerous-bash.sh` (+1
hook), `commit-msg` commitlint hook (+1 hook), `migration-lint` script (+1), `repo-structure` script (+1),
`.dependency-cruiser.js` ruleset (+1) + dependency-cruiser dep + a CI-trusted `/cr` record file (+1), plus
2–3 new CI *jobs/steps* (stop-authority, cr-security classifier, depcruise step) and possibly
`managed-settings.json` (+1). The DELETE column removes prose (the CLAUDE.md NEVER section, R30/R54/R55
lines) and dedups cross-file echoes — **zero files removed.** The artifact's "consolidation" is real for
*rules* (≈64 collapse onto 7 mechanisms, cross-file echo deduped) but **inverted for files/mechanisms**.
This does not make the sort wrong — enforcement-relocation costs files, and every added mechanism passes §9
with a nameable (often safety-critical) failure mode — but the artifact MUST stop presenting it as a
file-count reduction. The binding-principle file-count win lives in MOVE 3 + MOVE 4, not here.
