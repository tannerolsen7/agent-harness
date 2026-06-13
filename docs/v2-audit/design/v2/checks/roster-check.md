# Adversarial Check — `roster.md` (Anti-Duplication & Carry-Forward Integrity)

**Artifact:** `design/v2/roster.md`
**Checker stance:** doer ≠ checker — a different agent wrote the roster; this pass attacks it.
**Charge:** (1) every NEW skill/hook genuinely ABSENT (not a phantom rebuild); (2) every KEEP justified vs CUT/MERGE; (3) every CUT/MERGE doesn't drop a grounding-flagged mechanism; (4) settled cuts (notion-sync, supabase-out, dep-update) + prune-before-ship gate reflected; (5) no §F rejected pattern smuggled in; (6) spot-check 3 grounding mechanisms have homes.
**Ground truth re-verified on disk this session** (`/Users/tanner/Dev/event-vendor/.claude/`): 26 skill dirs, 23 agent bodies, 5 hooks. ABSENT confirmed: `block-dangerous-bash.sh`, `session-end.sh`, `enforce-scope.sh`, `.claude/rules/`, `.claude-plugin/`, and skills `goal`/`lfg`/`verify`/`scan-context`/`ratchet`/`cr-calibrate`/`init`.

---

## VERDICT: SOUND-WITH-CORRECTIONS

The roster is overwhelmingly sound on anti-duplication (no phantom rebuilds — every NEW skill/hook is genuinely absent on disk, all verified) and on carry-forward of the *flagged-as-droppable* mechanisms (test-inversion, golden exemplars, refactor plan-file, incident doc-travel, 4-lens isolation, TDD ledger all homed). The §F upheld rejections are honored, not smuggled. **But there is one hard carry-forward integrity defect: a real, fully-built skill — `evaluate-solution` — is silently dropped from Table A.** It has no disposition, no failure-mode line, and no frontmatter note, directly violating the roster's own stated invariant ("all 26 skills carry a failure-mode line") and producing an internal count contradiction ("22 KEEP" asserted, only 21 enumerated). One MUST-FIX, two SHOULD-FIX, two CONSIDER.

---

## MUST-FIX

### MF-1 — `evaluate-solution` skill is entirely absent from Table A (a genuine KEEP, silently dropped)

The most serious carry-forward integrity hole, and exactly the failure class the roster exists to prevent.

**Evidence (disk):** `.claude/skills/` contains 26 dirs. Diffing disk against the skill names Table A dispositions:
```
ON DISK but NOT in roster Table A: evaluate-solution
```
`evaluate-solution/SKILL.md` is 8925 bytes — a real, wired skill (not the empty `dep-update` stub). Table A lists 26 rows but counts `dep-update` (the empty stub) and **omits `evaluate-solution`**, so only 25 of the 26 disk skills are dispositioned, and only **21 KEEP rows actually appear** in Table A (verified by tally).

**Why this is a defect, not a quibble:**
- The roster's own header (lines 19, 60-66) asserts "all 26 skills + 23 agents carry a failure-mode line" and the summary claims "**22 KEEP**." Table A enumerates **21 KEEP**. The missing 22nd is precisely `evaluate-solution`. The number is asserted but not delivered — the table contradicts its own count.
- `V1-TO-V2-CARRYFORWARD.md:72` independently states the settled skill math: "**KEEP 22 core**; CUT dep-update; MOVE OUT supabase ×2; CUT notion-sync." 26 − 1 − 2 − 1 = 22. That math *requires* `evaluate-solution` to be one of the 22 KEEP. The roster drops it, breaking the reconciliation with the settled decision.
- The skill carries embedded mechanisms a "summary pass" would erase — the exact thing the grounding warns about: multi-skill routing wiring (invoked from `/incident`, `/spike`, `/feature` per its frontmatter `description`), the named-recommendation-not-options discipline, the mandatory financial-cost-at-1x-and-10x rule, the **human-confirm gate** ("The human makes the final call... the agent does not proceed to /design or /feature until the human confirms," SKILL.md:154-155), and the **"Human steps required" output section** (SKILL.md:172-176) — a deliberate human-in-the-loop block that must be preserved, not autonomized away.
- It is also a side-effect / `disable-model-invocation` candidate question that goes unasked: it writes `.claude/solution-eval-[slug].md` and is auto-invoked from three other skills — the F9 activation-tier audit needs a row for it.

**Required correction:** Add an `evaluate-solution` row to Table A — disposition **KEEP** (or KEEP + CHANGE-DELIVERY), actual-job per its SKILL.md, the failure it prevents (a build-vs-buy decision made on vibes / pricing omitted / the human-confirm gate autonomized away), and the frontmatter note (re-audit whether it is a `disable-model-invocation` target given the three-skill auto-invoke surface; pair with the `@solution-evaluator` tool-casing normalization already noted in the Agents table). After the fix, "22 KEEP" will be true and the carryforward math closes.

---

## SHOULD-FIX

### SF-1 — The "22 KEEP" / "26 skills" counts are stated as verified facts but are wrong as written

Downstream of MF-1, but worth calling out separately because the *numbers themselves* are load-bearing claims the rest of the design (manifest, plugin extraction, `/init`) will trust. The roster header says "26 skill dirs (`dep-update` is an empty stub)" and "all 26 skills carry a failure-mode line" — but only 25 distinct dirs are dispositioned (dep-update counted, evaluate-solution missing), and only 24 carry a failure-mode line in Table A (dep-update's CUT line + 23 others; evaluate-solution has none). The "Net core-harness skills: 22 KEEP" line (66) is the one that must reconcile once MF-1 lands. **Correction:** after adding the evaluate-solution row, re-state explicitly: 26 disk dirs = 22 KEEP (incl. evaluate-solution) + 1 CUT (dep-update) + 1 CUT (notion-sync) + 2 MOVE-OUT (supabase ×2). That is 26 and matches CARRYFORWARD §72.

### SF-2 — Naming drift: `/cr-calibrate` (roster + VISION) vs `cr-eval` (CARRYFORWARD §72)

The roster Table B and VISION.md name the calibration skill `/cr-calibrate`; `V1-TO-V2-CARRYFORWARD.md:72` names the same NEW skill `cr-eval` ("ADD `cr-eval`"). The roster aligns with the authoritative VISION (the spine), so the roster is internally correct — but the two-name divergence will bite the P6 manifest and `/init` materialization if not collapsed. **Correction:** state in the roster that `/cr-calibrate` supersedes the `cr-eval` working name from CARRYFORWARD (one canonical name), so the manifest doesn't ship both.

---

## CONSIDER

### C-1 — `dep-update` CUT + rebuild is correct; make the "no empty stub ships" gate explicit in one place

Anti-duplication here is *handled well*: `dep-update` (verified on disk as `total 0`, no `SKILL.md`) is CUT in Table A with the phantom-skill failure mode named, and the rebuilt `/dep-update` in Table B is flagged "**A NEW-build slot, not a carry-forward**" and "Replaces the empty dep-update stub." No empty stub ships, no double-listing as both KEEP and NEW. This is the prune-before-ship gate working. The only polish: the roster never names the gate as a *standing rule* (a directory with no SKILL.md is never carried as a KEEP; a NEW slot that reuses a dead name must say "replaces"). Consider one sentence stating it so the rule survives to the next roster pass.

### C-2 — `/tdd` and `supabase-postgres-best-practices` de-dup is correct; verify the disk facts the notes assert

Both de-dup notes check out against disk: `tdd` is a real project-local directory (`.claude/skills/tdd/` is a dir, not a symlink — a genuine divergent fork, matching the roster's "project copy is a divergent fork, classify own-forever vs re-sync, P5"); `supabase-postgres-best-practices` is a **symlink** to `../../.agents/skills/...` (matching "appears twice (project + plugin), de-dup to one source"). No correction needed — flagged only so the disposition's disk-grounding is recorded in this check.

---

## What was attacked and held (no finding)

- **Every NEW skill/hook is genuinely ABSENT (no phantom rebuild).** Verified on disk: skills `goal`, `lfg`, `verify`, `scan-context`, `ratchet`, `cr-calibrate`, `init` — all ABSENT. Hooks `block-dangerous-bash.sh`, `session-end.sh` — both ABSENT. The 5 existing hooks (`block-dangerous-git`, `block-npm-install`, `permission-logger`, `session-start`, `worktree-create`) match the roster's Hooks table exactly. The roster correctly treats the existing Stop hook as sound-only and the two existing guards as fail-open-to-fix.
- **The settled cuts are correctly reflected.** `notion-sync` CUT (mechanisms — comprehensive-diff, guard-file exception, dedicated-branch, LAST-SYNC receipt, sentinel handoff — explicitly carried forward into the GitHub-canon path); `supabase` + `supabase-postgres-best-practices` MOVE-OUT to a per-project add-on; `dep-update` CUT. All three match `V1-TO-V2-CARRYFORWARD.md:72`, `RECONCILIATION.md` ("Only cut: dep-update"), and `DECISION-PACKAGE.md:303`.
- **No §F upheld rejection is smuggled in.** The three fully-UPHELD §F rejections (`F-rejected.md` tally: items 1, 5, 6) are all honored: **#6 collapse-23-agents-→-1** is explicitly called "dead" / "rejected" (roster 22, 145); **#5 no-shared-context reviewer** is honored by the `reviewer` row's ISOLATION INVARIANT ("V2 must not optimize it into one shared-context reviewer") with full canon pre-read passed to lenses; **#1 front-load-trigger-words** is honored by "rewrite phrase-keyed descriptions to situational triggers" (F9 note). The OVERTURNED/PARTIAL slices (Playwright-headless → `/verify` C8; spec-with-independent-review → C6; egress-firewall → F3) appear as in-scope NEW items, correctly.
- **All 23 agents kept, none cut — and this is justified, not a collapse-reflex.** Spot-checked the lens agents and spike fleet: each is spawned by a parent (`reviewer` → 4 lenses with the stay-in-lane non-overlap rule; `spike-orchestrator` → 5 specialists) and carries a distinct failure-mode + embedded mechanism. The roster's "collapse 23 → 1 is dead" is the correct §F #6 application, not minimalism leaking back in.
- **Three grounding mechanisms spot-checked — all have homes.** (1) behavior-change **test-inversion classifier** (`skills-A.md:20`) → `behavior-change` KEEP + checklist line 223; (2) **golden exemplars** (`agents-A.md:67,156`) → `implementer` + `task-runner` read it, `lens-composition` enforces it, AGENTS.md §Architecture is source (checklist line 242); (3) refactor **plan-file + no-conjunction naming gate** (`skills-C.md:38-39`) → `refactor` + `refactor-extractor` KEEP (checklist line 210). All three are the exact "summarized-away" mechanisms the grounding flagged, and all are explicitly homed.
- **Capability facts are respected.** `/goal` force-continue marked "Phase-0 probe required, fallback = external re-invocation" (matches `capability-facts.md:14-16`); HOOK-1 render artifact "not hook-compellable → advisory at hook, hard at CI" (matches `:17-20`); managed-settings placement is a human handoff (matches `:42-46` + the no-self-edit memory). No over-claim.

---

## Summary line for the parent

`roster.md` is **SOUND-WITH-CORRECTIONS**. Anti-duplication is clean (zero phantom rebuilds — all NEW skills/hooks verified absent on disk; settled cuts + de-dups + prune-before-ship all correct) and §F upheld rejections are honored. The one hard defect is a carry-forward integrity hole: the real `evaluate-solution` skill (8.9 KB SKILL.md, multi-skill routing + human-confirm gate) is dropped from Table A entirely, which also makes the asserted "22 KEEP" false (21 enumerated). Fix MF-1 and the count reconciles with `V1-TO-V2-CARRYFORWARD.md:72`.
