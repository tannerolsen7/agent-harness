# CHECK — Adversarial Verdict on CANONICAL-HARNESS-AS-IS.md

**Checker role:** Adversarial. I did not write the map. I tried to break it by ground-truthing its
disk claims against the real filesystem and tracing every load-bearing claim to one of the five cluster
files or HARNESS-AS-IS.md. Governing rule enforced: *no claim survives without a citation to a real
source — a canon page, a disk fact, or a confirmed absence.*

---

## (a) VERDICT: **UNSOUND** — must not advance to Phase 2 until corrected.

The map is ~85% solid and most of its canon-vs-disk reconciliation is well-cited. But it contains **three
false absence/categorization claims about disk state that the real filesystem flatly contradicts**, and
those three are not peripheral — two of them (`CONTEXT.md`, `docs/ARCHITECTURE.md`) are promoted into the
§5 "canon-only, build-or-reject" registry and the §3a reconciliation table as *confirmed absences*. Under
the map's own governing rule ("no proposal survives without a citation to a row in this map — a real
component or a confirmed absence"), a confirmed-absence row that is actually present is the single most
dangerous defect possible: it manufactures phantom build work and would let a "build CONTEXT.md" proposal
survive Phase 6 against a file that already exists with 15 KB of committed content. This is precisely the
phantom-survives-the-gate failure the rule exists to kill. The map inherited these errors from
HARNESS-AS-IS.md but *amplified* them (HARNESS-AS-IS hedged "phantom-referenced"; the synthesis hardened
them into build-or-reject candidates) and did not ground-truth them.

Correct the F-tagged findings below and it becomes sound-with-corrections.

---

## (b) FINDINGS

### F1. [WRONG] `CONTEXT.md` is claimed absent/phantom — it EXISTS on disk, git-tracked, 15 KB.

**Quote (multiple sites):**
- §0 / §1 coupling: "event-vendor adopted these skills' *vocabulary* … but never created the file."
- §3a table: "`CONTEXT.md` | ✅ ("the *why*", hardest doc) | ❌ phantom | … **Referenced by 6+ skills, never created**"
- §5 registry: "`CONTEXT.md` | §04 | The "why" doc; referenced by 6+ disk skills, **never created**"
- §How-later-phases-cite: "`/simplify` is a canon-only absence (§5)" framing treats CONTEXT.md the same way.

**Problem:** `CONTEXT.md` is present at repo root: `-rw-r--r-- 15092 Jun 4 00:45 CONTEXT.md`, **tracked in
git** (`git ls-files --error-unmatch CONTEXT.md` → TRACKED), header reads "# CONTEXT.md — The *why*
behind this project's structure. Read this before writing code." Committed in `a70db76` (wave-1 slice A,
#92). The 20+ skills/agents that reference `CONTEXT.md` (behavior-change, design, setup-strategy, cr,
review-strategy×4, compound, incident, feature, reviewer, security-reviewer, ux-reviewer, task-runner,
lens-*, spike-*…) **resolve correctly** — they are not dangling. The map's central "phantom CONTEXT.md is
explained here / partial adoption of an upstream ecosystem" thesis (§1 first bullet) is built on a false
premise.

**Root cause:** HARNESS-AS-IS §7 and §2 assert "CONTEXT.md … ABSENT at repo root." That disk audit was
wrong (or run against a stale tree); the synthesis copied it without ground-truthing. The governing rule
demands the synthesis verify confirmed-absence rows; it did not.

**Fix:** Reclassify `CONTEXT.md` as ✅/✅ Aligned in §3a. Delete it from §5. Delete the "phantom
CONTEXT.md" coupling bullet in §1 and the §0 thesis sentence. Remove it from the Executive-summary
"Biggest phantom/stale problems" framing. Re-examine the entire "partial adoption of an upstream
ecosystem" claim — its keystone evidence is gone. Note: the map *also* repeats this in
"How later phases cite this map" — fix there too.

---

### F2. [WRONG] `docs/ARCHITECTURE.md` is claimed absent — it EXISTS on disk, git-tracked.

**Quote:**
- §3a table: "`docs/ARCHITECTURE.md` | ✅ §03 (tech-debt ledger) | ❌ | n/a | **Canon-declared, absent**"
- §5 registry: "`docs/ARCHITECTURE.md` | §03 | Tech-debt ledger for one-shot blockers" (listed as a
  canon-only item to build-or-reject).

**Problem:** `docs/ARCHITECTURE.md` is present (`2171 bytes`), **git-tracked**, with real content:
"# Architecture — Layering model, tech debt, and migration path for the event-vendor codebase," including
a layering-model diagram. Committed in `d4ba0a8` / `475fd4c`. It is not absent. It is a build-or-reject
candidate for nothing — it is already built.

**Fix:** Reclassify as ✅/✅ Aligned in §3a (with whatever drift note is warranted — its content is thin,
2 KB, but it exists). Delete from §5.

---

### F3. [MISCATEGORIZED] The `.githooks/pre-commit` "location divergence" is presented as canon-only — disk HAS it.

**Quote:**
- §3e: "pre-commit | ✅ `.githooks/pre-commit` | ✅ `.husky/pre-commit` | … | **Location divergence**
  (canon `.githooks` via `core.hooksPath`; disk husky)"
- §5 registry: "`.githooks/pre-commit` (vs husky) | §08 | Canon's pre-commit location differs from disk"
- §3f: "Canon's structural pre-commit is `.githooks/`-based; disk's is husky."

**Problem:** Disk has BOTH. `.githooks/pre-commit` exists on disk (`676 bytes`, executable) and its body
is a near-verbatim match to the canon's `.githooks/pre-commit` template (main-branch protection via
`[ ! -t 0 ]` → exit 1 for agents, warn+exit 0 for humans; `npx tsc --noEmit`; `npx vitest run` with
exit-2-means-no-tests handling). So the canon's structural pre-commit *is on disk* — the map's claim that
it is canon-only / a pure "location divergence" is half-wrong. The real, more interesting fact the map
missed: **`core.hooksPath` is set to `.husky/_`, so `.githooks/pre-commit` is dormant — it is on disk but
NOT the active hook.** The active hook is `.husky/pre-commit` (lint + tsc + test:unit). This is a genuine
divergence, but it is "canon's pre-commit script is present-but-unwired," not "canon's pre-commit is
absent / a location difference." Listing it in §5 as a thing-to-build is wrong; it exists.

**Fix:** Move `.githooks/pre-commit` out of §5. In §3e, change the divergence to: "both present;
`core.hooksPath=.husky/_` so the canon-style `.githooks/pre-commit` is dormant and `.husky/pre-commit`
(lint+tsc+test:unit, NO main-branch agent block) is the live gate." This is materially different — the
live husky pre-commit does NOT carry the canon's main-branch-agent hard-block, which is a real enforcement
gap the map currently hides behind "location divergence."

---

### F4. [WRONG] `recyclops-logistics-service` is described as having an "empty `.claude/`" — the repo does not exist on disk.

**Quote:**
- §0: "`recyclops-logistics-service/.claude` is empty."
- §1 table: "Other repos | `recyclops/.claude`, `recyclops-logistics-service/.claude` | one-line
  allowlist / empty"
- §2 inventory block: "`~/Dev/recyclops-logistics-service/.claude/   # empty`"
- §8: "**recyclops-logistics-service** — empty `.claude/`. No harness."

**Problem:** There is no `~/Dev/recyclops-logistics-service` directory at all (`ls` → no such dir; glob
`~/Dev/*logistics*` → no matches). You cannot verify a `.claude/` is "empty" inside a repo that is not on
the machine. The map asserts a specific disk fact ("empty") about a path that doesn't exist. (The canon
*does* reference an upstream "logistics-service" repo in cluster-C §4/§11 vendoring history — but that is
a canon claim about Tanner's other machine/repos, not a verifiable event-vendor-machine disk fact. The map
presents it in the disk-inventory voice of §2/§8.)

**Fix:** Change to "`recyclops-logistics-service` — not present on this machine (cannot verify); canon
references it as a vendoring-history repo [cluster-C §4]." Do not assert "empty `.claude/`." The
cross-project conclusion ("never installed anywhere but event-vendor") still holds on the evidence, but
the supporting fact is mis-stated.

---

### F5. [OVERSTATEMENT] "Canon documents a more advanced and more complete harness" is asserted as the headline while the map's own evidence shows disk leads canon in several places.

**Quote:** §0: "It documents a *more advanced and more complete* harness than exists on disk."

**Problem:** The map self-corrects this only for the prod-key firewall (§3e, §6) and concedes "disk ⊇
canon tree roster" for agents (§3d) and a 6th memory store (§4). But the headline still leads with
"canon is more advanced." On the evidence in the map itself, DISK is ahead of canon on: (1) agent roster
(23 vs canon's 7–10); (2) the prod-key/Tier-0 firewall (`gen-local-env.sh`/`test-local.sh`/
`worktree-create.sh`); (3) the auto-memory 6th store; (4) `/cr-security` 3rd Supabase pass (canon 2);
(5) `permission-logger.sh`. Canon is ahead on: 3 structural guards canon names that disk lacks
(block-dangerous-bash, enforce-scope, branch-registry-guard), `session-end.sh`, the pre-push sync gate,
and ~9 documented-but-unbuilt skills. The honest framing is "canon documents a broader *structural floor*
disk hasn't built; disk has built *operational mechanisms* (credential firewall, more agents, more passes)
canon never specified" — not a blanket "canon is more advanced." The current headline spins the
relationship in canon's favor and undersells the disk's lead.

**Fix:** Rewrite the §0 sentence to a two-directional statement. The map has the evidence; it just doesn't
lead with it.

---

### F6. [UNSUPPORTED] §3b skill-count arithmetic does not reconcile and "(one empty)" undercounts.

**Quote:** §1 layer-2 row and §3b: "disk has **26** project skill dirs (one empty)."

**Problem:** 26 is correct (verified: 26 dirs). But the §3b "On disk AND in canon, aligned" list
enumerates 23 names, then adds `dev`, `explain` (disk-only) = 25, plus `dep-update` (empty stub) = 26.
That checks out — but the map never shows this arithmetic, and `supabase-postgres-best-practices` is
listed as "aligned/on disk" when it is in fact a **symlink** to `~/.agents/skills/`, not a project-local
skill dir (verified: `lrwxr-xr-x … -> ../../.agents/skills/supabase-postgres-best-practices`). The map
elsewhere (§1) correctly calls it a symlink, but §3b's "aligned" list silently treats it as a peer of the
real local skills. Minor, but the map should not have a skill in two categories without noting it.

**Fix:** Footnote §3b that `supabase-postgres-best-practices` is the symlinked global skill (per §1), not
a project-local body, so the "23 aligned" count mixes one symlink with 22 real dirs.

---

### F7. [OMISSION] The map drops the live-vs-dormant pre-commit enforcement gap (consequence of F3).

**Problem:** Because the map mis-files pre-commit as a "location divergence," it never surfaces that the
**active** `.husky/pre-commit` lacks the canon's main-branch agent hard-block (`[ ! -t 0 ]` → exit 1 on
main), which the dormant `.githooks/pre-commit` *does* have. An agent committing on `main` is structurally
blocked by the canon template but NOT by the live husky hook. That is a real, V2-relevant enforcement
divergence the map omits entirely. HARNESS-AS-IS §3 documents the husky pre-commit body but never compares
it to the present-on-disk `.githooks` version.

**Fix:** Add a §3e/§8 row: "Live pre-commit (`.husky`) omits the main-branch agent block that the
present-but-dormant `.githooks/pre-commit` enforces — agents are not structurally blocked from committing
on main at commit time (only at push, via pre-push)."

---

### F8. [UNSUPPORTED→OK-but-flag] §5 lists `/simplify` as a canon-only absence, but the map elsewhere says the name resolves to a global/built-in.

**Quote:** §5: "`/scan-context`, `/handoff`, `/setup`, `/simplify`, `/prototype-*`, `/vibe-check`,
`/ideate` | §06/§11 | Documented skills with no disk dir."

**Problem:** Lumping `/simplify` with `/scan-context` et al. is imprecise. HARNESS-AS-IS §7 and the live
skill list both show `/simplify` *resolves* (to a global/built-in), unlike `/scan-context` which resolves
to nothing. The map's own §How-later-phases note even says "`/simplify` is a canon-only absence (§5), not
a disk mechanism to wire" — but `/simplify` IS a usable command at runtime (it's in the available-skills
list), so "build it" is the wrong disposition; "it already resolves upstream, decide whether to vendor"
is. Also `/ideate` appears in §5 but I found no citation for `/ideate` in any cluster file or HARNESS-AS-IS
— it looks invented. (cluster-C lists `/vibe-check`, `/scan-context`, `/handoff`, `/setup`,
`/prototype-interface`, `/prototype-ui`, `/visual-design` — never `/ideate`.)

**Fix:** Split `/simplify` out (resolves upstream — vendor-or-leave, not build). **Remove `/ideate` or
add its citation** — as written it is an uncited claim and violates the governing rule.

---

### F9. [UNSUPPORTED] "`/visual-design`" appears in §5 and §9 but is not in the disk skill set and its canon citation is thin.

**Quote:** §5 includes `/prototype-*`; §9 lists "`/visual-design` 3" option-forcing.

**Problem:** Minor — `/visual-design` is cited in cluster-C action items and cluster-E §1/§9 status table,
so it has a canon citation (OK). But §5's "`/prototype-*`" glob silently includes `/visual-design` and
`/prototype-interface`/`/prototype-ui` without naming them; a reader can't trace the glob to specific rows.
Not a kill, but the map should name what `/prototype-*` expands to so each is independently citable
(the governing rule wants per-component traceability).

**Fix:** Expand the glob in §5.

---

### F10. [OVERSTATEMENT] §3c "runtime skill description" is treated as a third canonical source without a disk citation.

**Quote:** §3c: "Runtime skill description | "9 analytical passes **plus** an adversarial review"
(implies 10) | "3-pass""

**Problem:** The "runtime skill description" is the live `/cr` skill's `description` frontmatter — that's a
disk artifact and should carry a `[disk: cr/SKILL.md frontmatter]` cite. The map presents it as a third
framing without sourcing it. (I verified the disk `/cr` has Pass 9 + Pass 11, no Pass 10 — consistent with
the map's reconciliation. The point is citation hygiene, not correctness.)

**Fix:** Cite the runtime description to the disk skill frontmatter.

---

### Non-findings I checked and could NOT break (see §d).

---

## (c) DISK CLAIMS I GROUND-TRUTHED

| # | Synthesis claim | Result |
|---|---|---|
| 1 | `~/.agents/skills` has 15 dirs | **TRUE** — exactly 15, names match §1 table verbatim |
| 2 | `~/.claude/skills` = 15 symlinks → `~/.agents/skills` | **TRUE** — all 15 are symlinks |
| 3 | No global `~/.claude/CLAUDE.md` | **TRUE** — ABSENT |
| 4 | `~/.claude` has no agents/, no hooks/ | **TRUE** — no `agents`, no `hooks`; settings.json has no `hooks` key |
| 5 | `~/.claude.json` exists (global config) | **TRUE** — present, 33 KB |
| 6 | global settings.json: permissions + enabledPlugins + effortLevel:xhigh, NO hooks | **TRUE** |
| 7 | project `.claude/skills` = 26 dirs, one empty | **TRUE** — 26 dirs; `dep-update/` empty (no SKILL.md) |
| 8 | `/tdd` is a project-local fork, ~5.2 KB, edited 2026-06-07, diverged from global | **TRUE** — real dir, 5225 B, mtime Jun 7; global tdd is 4395 B (different) |
| 9 | `supabase-postgres-best-practices` is a symlink (project→global) | **TRUE** — symlink |
| 10 | `block-dangerous-bash.sh` absent on disk | **TRUE** — ABSENT |
| 11 | `.claude/agents` = 23 agents incl. 4 lenses + 6 spike | **TRUE** — 23 agents, all named ones present |
| 12 | `enforce-scope.sh`, `branch-registry-guard.sh`, `session-end.sh` absent | **TRUE** — all ABSENT |
| 13 | phantom files absent (learned-patterns/review-log/triage-inbox/skills-lock/agentic-system-enabled/active-branches) | **TRUE** — all ABSENT |
| 14 | `/cr-security` has 3 passes on disk (canon 2) | **TRUE** — Pass 1 Security&Auth, Pass 2 Data Boundary, Pass 3 Supabase Checklist |
| 15 | `/cr` has no Pass 10 (jumps 9→11) | **TRUE** — Pass 9 Devil's Advocate, Pass 11 Adversarial Review |
| 16 | recyclops `.claude/settings.json` = one-line notion-fetch allowlist | **TRUE** — exactly that |
| 17 | husky pre-push present (~2.4 KB) | **TRUE** |
| 18 | **`CONTEXT.md` absent/phantom** | **FALSE** — present, 15 KB, git-tracked (F1) |
| 19 | **`docs/ARCHITECTURE.md` absent** | **FALSE** — present, 2.1 KB, git-tracked (F2) |
| 20 | **`.githooks/pre-commit` is canon-only / disk uses husky** | **FALSE/MISLEADING** — `.githooks/pre-commit` present on disk (676 B, matches canon template) but dormant; `core.hooksPath=.husky/_` (F3) |
| 21 | **`recyclops-logistics-service/.claude` is empty** | **FALSE** — the repo does not exist on this machine (F4) |

21 claims checked: 17 TRUE, 4 FALSE. The 4 false ones are all disk-state claims the synthesis took on
faith from HARNESS-AS-IS without verifying — and 3 of the 4 (CONTEXT.md, ARCHITECTURE.md, .githooks)
drive phantom §5 build-or-reject rows.

---

## (d) WHAT THE MAP GOT RIGHT (I tried to break these and failed)

- **The canon "5 pillars" trap was NOT sprung.** I specifically checked whether the map cites a "5
  pillars" framing as canon. It does **not** — the map never claims "5 pillars" is in canon. cluster-E §6
  is explicit that no "N pillars" statement appears in the doctrine pages and that the user-memory "5
  pillars" must not be attributed to canon. The map's §3–§9 structure derives pillars-free from real
  rows. **Clean.** (HARNESS-AS-IS §5 does use a "5 Pillars → real mechanisms" table, but attributes the
  pillars to the *disk harness's* self-framing, not to Notion canon — also defensible.)
- **Canon internal contradictions (§7) are all real and correctly cited.** Two feature loops (cluster-A
  §6c), two reviewer names / `/cr-feature` retired v0.85 (cluster-C §6, cluster-D §7), Pages 12↔13
  anti-rationalization + 60% handoff tension with §13 winning as later-dated (cluster-E §304, Notable 1–2),
  P0–P10 vs P1–P9 numbering (cluster-C §3/§6), 8-header-over-9-rows + "Ten" templates (cluster-C §2/§6),
  pre-push sync-gate page-vs-template disagreement (cluster-D §1c/§7), upstream install-method
  contradiction (cluster-A §6d), v0.16 ownership table (cluster-A §6a, cluster-B §6). Every §7 row traces.
- **The §9 Model Capacity Audit reproduction is faithful** to cluster-E §2 — replace/keep lists, the
  Sonnet-4.6 basis, the re-audit-on-model-update cadence (now Opus 4.8), and the golden rule are all
  verbatim-accurate to cluster-E. The "canon pre-authorizes the cuts" framing is legitimate and the most
  valuable part of the map for V2.
- **The enforcement structural/advisory reconciliation (§3e net picture) is correct** apart from the
  pre-commit mis-file (F3): block-dangerous-bash / enforce-scope / branch-registry-guard / session-end are
  genuinely canon-only and absent on disk (verified); permission-logger + worktree-create prod-firewall
  are genuinely disk-only (verified); both layers are overwhelmingly advisory (matches cluster-D Notable A
  and HARNESS-AS-IS §3).
- **The memory-model §4 is sound** — the auto-memory 6th store is real and genuinely outside canon's
  model (cluster-B doesn't account for it; the user-memory MEMORY.md index confirms it exists); the
  triple-duplication sanctioned-and-forbidden tension is correctly drawn from cluster-B Notable 2 and
  Point 5.
- **The `/cr-security` 2-vs-3 and `/cr` no-Pass-10 reconciliations are correct** (verified on disk).
- **Global-layer §2 inventory is accurate** in every checkable particular (no global CLAUDE.md, 15
  symlinked skills, notion plugin, effortLevel xhigh, `~/.claude.json` present, recyclops one-liner).
- **The "multi-project is aspirational / never installed beyond event-vendor" thesis survives** even
  after F4 — recyclops genuinely has no harness, the global layer genuinely lacks the canon-mandated
  `~/.claude/CLAUDE.md`, and no installable shared harness exists. The conclusion is right; only one
  supporting fact (logistics-service "empty .claude") is mis-stated.

---

## Bottom line for the caller

The reconciliation *method* is sound and most of the map is citable and correct. But it shipped **four
false disk-state claims** inherited un-verified from HARNESS-AS-IS, three of which manufacture phantom
"build-or-reject" rows (§5) for files that already exist (`CONTEXT.md`, `docs/ARCHITECTURE.md`,
`.githooks/pre-commit`). The map's own governing rule — "no proposal survives without a citation to a
real component or a confirmed absence" — is defeated at the source if its "confirmed absences" are not
actually absent. Fix F1–F4 (the disk falsehoods), F7 (the hidden live-pre-commit gap they expose), and
F8/F10 (uncited `/ideate`, unsourced runtime description), and the map is sound. Until then it is unsound:
a downstream phase could legitimately cite §5 to "build CONTEXT.md" against a 15 KB committed file.
