# Adversarial check — `design/v2/file-tree.md`

**Checker role:** adversarial (doer≠checker). A different agent authored the file-tree; this attacks it on the
charge's six axes (two-budget honesty + completeness). Ground truth re-verified on disk this session
(2026-06-11). Citations to the artifact are by line number.

**Verdict: SOUND-WITH-CORRECTIONS.** The tree's spine holds: every VISION move (44 IDs) has a landing-table
row, the full 26-skill and 23-agent rosters reconcile to a home with no item dropped, no proposed `[NEW]` file
duplicates something already on disk (all seven claimed absences re-confirmed absent), and the
memory.md→00-safety verbatim-absorb BLOCKER is carried with the deletion explicitly gated on it. The
two-budget framing is conceptually right and the per-task-load win is real and well-evidenced. But two
load-bearing claims are mis-stated in a way that flatters budget (1), and three smaller completeness gaps
exist — one of which (the under-delivered memory-trap routing) directly undercuts the §B.4 safety BLOCKER the
tree leans on. None is fatal; all are correctable in place.

---

## MUST-FIX

### MF-1 — Budget (1) is presented as deletions-only; the +6 shard additions are mis-booked into budget (2), flattering the win the charge exists to police.

This is the precise "store-count win masquerading as a file-count win" the charge asks me to detect.

- The two-budget table (line 27) **and** the Phase-6 correction the tree cites (`RECONCILIATION §A`, lines
  44–53) both explicitly re-book `.claude/rules/` shards into **budget (1)** — a `paths:`-scoped markdown rule
  is loaded INTO the agent's context and is "exactly as forgeable as the PITFALLS prose it was split from."
- But the **Honest Budget Summary** files the shards the other way: line 232 lists "**+5–6 rule shards**"
  under **Budget (2) — deterministic enforcement**, and the Budget (1) bullet (lines 226–228) lists **only
  deletions** (PITFALLS, memory.md, NEVER-section) with **no shard additions counted against it**.
- Net effect: budget (1) reads as a pure "large win" while its own +6 file additions are parked in the budget
  the charter says is allowed to grow. The honest budget-(1) **file** ledger is `−2 monoliths + 6 shards = +4
  files`; what falls is **per-task load** (1–2 shards on-path vs. 558 lines always) and **copies-per-fact**
  (3→1). The tree states those two real wins correctly — but by misfiling the shards it hides the +4 file delta
  and lets the reader infer a file-count win that isn't there.

**Fix:** move "+5–6 rule shards" out of the Budget (2) bullet (line 232) into Budget (1), and rewrite the
Budget (1) bullet to state the honest ledger: budget-(1) **files** rise +4 (2 monoliths → 6 shards) while
**per-task read load and copies-per-fact fall sharply** — the win is load/duplication, not file count. This is
the one correction that makes the whole "two budgets, scored honestly" thesis self-consistent with its own
header. (Note: `RECONCILIATION §E` line 197 carries the same misfile; the baseline predates the Phase-6
correction. The file-tree adopted the correction in its header (line 27) but not in its summary — fix the
summary, don't re-inherit the baseline bug.)

### MF-2 — The tree claims "3 non-safety traps routed" but explicitly routes only 1; the §B.4 BLOCKER gates memory.md deletion on all 3.

`RECONCILIATION §B.4` (a `[BLOCKER]`, cited by the tree at line 72/75) requires, before memory.md is deleted,
that the three non-safety memory traps be **explicitly routed**:
- `enforcement-boundary-layering` → `harness-hooks.md`
- `claude-md-referenced-scripts-must-exist` → a drift-CI rule
- `check-branch-before-commit` → the always-load process section

The file-tree routes only the **first**. Grep of the entire tree finds `enforcement-boundary-layering` once
(line 81) and **neither** of the other two anywhere in the document. Line 75 (`00-safety.md`) names a generic
"always-load process section" but does not name `check-branch-before-commit` as landing there, and **no line
routes `claude-md-referenced-scripts-must-exist`** — `scan-context.yml` does adjacent "reference-integrity"
work but the script-existence rule is a distinct check and the routing is never made explicit.

Since memory.md's deletion is gated (line 72: "deleted ONLY after absorb verified") on these routings being
real targets, leaving two unrouted means two traps can be **silently lost** at deletion time — the exact
failure §B.4 was written to prevent. The charge's question (4) is specifically whether the tree protects the
verbatim-absorb floor against a false "already there"; here the safety-floor entries are protected, but the
**non-safety** half of the same BLOCKER is under-delivered.

**Fix:** in the tree, explicitly route `check-branch-before-commit` into `00-safety.md`'s always-load process
section (name it on line 75) and `claude-md-referenced-scripts-must-exist` into a named drift-CI rule
(`scan-context.yml` or `repo-structure.sh` — pick one and name it). Then the "3 traps routed" claim on line 72
becomes true.

---

## SHOULD-FIX

### SF-1 — P4 (MCP-as-substrate) has a landing-table row but NO file home in the target tree.

P4 appears only once in the document — the landing table (line 209): "externally-summonable endpoints
(`RemoteTrigger`-style) routing into the shell." There is **no corresponding file or directory** anywhere in
the target tree (lines 61–162): no endpoint script, no `mcp-server/`, nothing. The one `.mcp.json` in the tree
(line 134, `.claude-plugin/plugin/.mcp.json`) is "MCP servers the harness **ships**" — i.e. the harness as MCP
*client*, which is the **opposite** of P4's "make the harness **summonable**" (server/endpoint).

This matters because P4 is tagged **P0-spine** in VISION ("the distribution half of L1; built in lockstep with
L1") — not a deferred/gated item. The charge's question (3) is "a home for EVERY VISION move." P4's home is
prose-only. Either the tree needs a concrete artifact (an entry-point script / endpoint manifest) or an
explicit GATED/deferred note explaining why a P0-spine move ships without a file. As drawn it's a hand-wave at
spine altitude.

### SF-2 — F3 and F5 enforcement hooks are named in the landing table but absent from the `hooks/` tree listing.

F3 ("hook reading it," line 182) and F5 ("session/pre-tool guard hook," line 184) each require an enforcement
hook. The `.claude/hooks/` listing (lines 84–90) contains only `block-dangerous-git`, `block-npm-install`,
`block-dangerous-bash`, `permission-logger`, `session-start`, `session-end`, `worktree-create` — **no egress
hook, no trifecta guard hook.** Their *data* half (the manifest) has a file home (line 121); their
*enforcement* half does not.

This is **less severe than SF-1** because F3 is `GATED(Fork F4)` and F5 is "P0 only for the Slack/CI path" —
both are explicitly outside the minimal floor and the tree marks them GATED. But a reader building the tree
would find the manifest with nothing reading it. Add the guard hook(s) as gated/placeholder entries in
`hooks/`, or a one-line note that their hook ships with the F3/F5 workstream, so the manifest isn't a
data-structure with no consumer in the file layout.

### SF-3 — `auth-routing.md` shard glob points at a non-existent path (`src/proxy.ts`); the real file is `proxy.ts` at repo root.

Line 79: `auth-routing.md  paths: app/**,src/proxy.ts,middleware*`. On disk **`src/proxy.ts` does not exist**
— the proxy lives at the **repo root** (`./proxy.ts`; confirmed via `find` and the `PUBLIC_PATHS` grep). A
`paths:` glob that doesn't match the actual file means the shard **will not auto-load when the agent edits the
proxy** — which is the entire point of the shard and exactly the "fake shard that doesn't auto-load" failure
the tree itself warns against (line 46). `middleware*` is also a dead glob (no middleware file at root; Next 16
renamed it — the tree's own `nextjs16-middleware-filename` rule references this). The shard mechanism is the
tree's core load-bearing claim; a wrong glob silently no-ops it.

**Fix:** change the glob to `app/**,proxy.ts` (root) and drop or correct `middleware*` to the actual Next-16
filename the project uses.

### SF-4 — Agent accounting double-counts `spike-orchestrator`; the "(remaining 9)" label is off by one.

The agents block names 9 explicit + `spike-*.md (6)` (which on disk includes `spike-orchestrator`) +
"(remaining 9)" — but the remaining-9 list (line 114) **also** lists `spike-orchestrator`, and contains only 8
distinct non-spike, non-explicit agents (doc-updater, explorer, implementer, investigator, refactor-extractor,
solution-evaluator, task-runner, ux-reviewer). The **total is correct (23, all wired, none dropped)** — this
is purely a mislabel: `spike-orchestrator` counted in both the spike-6 and the remaining bucket, which should
read "(remaining 8)." No agent loses a home; fix the label so the completeness index is auditable.

---

## CONSIDER

### C-1 — Header "26 → 25 core" doesn't match the 22-skill list it then enumerates.

Line 92 says "26 → 25 core"; line 93 lists exactly **22** core-kept skills (26 − dep-update − notion-sync −
2× supabase-MOVE = 22). The "25" doesn't reconcile to any clean subset. Every skill's disposition is
individually correct and complete (verified: all 26 on disk accounted for; 7 new added). This is a cosmetic
header number; make it "26 → 22 core kept + 7 new (29 total)" or similar so the arithmetic is checkable.

### C-2 — `.cr-ok` marked `[KEEP]` is not on disk (it's a transient gitignored sentinel).

Line 122 marks `.claude/.cr-ok [KEEP]`; it is **absent on disk right now** because it's a runtime-generated,
gitignored sentinel (written by `/cr`, consumed by `pr.sh`). This is **not** a harmful phantom — the *mechanism*
is real and the `.gitignore:57-58` entry confirms it. But labeling a transient sentinel `[KEEP]` alongside
static files invites a reader to expect a tracked file. Consider tagging it `[KEEP-MECHANISM]` or noting
"transient, gitignored — survives as runtime signal" so it isn't mistaken for a committed artifact.

### C-3 — `scripts/` header says "7 → 10" but only 6 source scripts exist on disk.

Line 138: "7 → 10". Disk shows 6 source scripts (`gc`, `gen-local-env`, `pr`, `seed.ts`, `test-local`,
`worktree-add`) plus `README.md` + a `.sql` helper. The `[KEEP]` line (140) lists exactly those 6. So the
baseline is 6, not 7, and 6 + 3 new (`gen-rules`, `migration-lint`, `repo-structure`) = 9, not 10. (If
`README.md`/`link_user_to_team.sql` are counted the base is 8.) Minor; reconcile the header count to the
enumerated list.

---

## What the tree gets RIGHT (verified, not assumed)

- **Move completeness (charge 3):** all 44 VISION move IDs (L/F/C/CMP/P/HOOK-1/LOOP-7) have a landing-table
  row — extracted both sets and diffed; zero orphans. C1/C3/C7/L3 correctly demoted-to-clause per VISION
  Honest Cuts, noted at line 168.
- **Roster completeness (charge 3):** 26 skills → all dispositioned (22 keep / 2 DEL / 2 MOVE) + 7 new; 23
  agents → all have a home, none dropped (the only error is a label, SF-4). The "collapse 23→1" reflex is
  correctly dead.
- **Verbatim-absorb safety floor (charge 4):** the tree protects the KEEP-VERBATIM floor correctly — line 72
  gates memory.md deletion on absorb-verified; line 50 explicitly states memory.md's richer incident narrative
  is absorbed verbatim before deletion. I confirmed on disk that memory.md's `destructive-operation-hard-stop`
  / `token-scope-assumption` / `staging-is-not-isolated` entries carry fuller `Why:`/`How to apply:` text than
  CLAUDE.md's terser NEVER-section copy — so the verbatim requirement is real and correctly honored **for the
  safety entries**. (The gap is only the *non-safety* half — MF-2.)
- **No harmful phantom rebuild (charge 5):** all seven claimed absences re-confirmed ABSENT on disk
  (`.claude/rules/`, `.claude-plugin/`, `block-dangerous-bash.sh`, `session-end.sh`, `enforce-scope.sh`,
  `harness-manifest.json`, `golden-set/`). Every `[NEW]` is genuinely new; no `[NEW]` duplicates a present
  file. Existing Stop hook confirmed sound-only (settings.json:191 area).
- **Doesn't chase a flat total (charge 6):** explicitly, repeatedly. Lines 38–40 forbid chasing
  `find | wc -l`; the summary carries two budgets, not one number. This is correct under the charter — the
  problem is the *internal misfile* (MF-1), not a covert minimalism relapse.
- **Native mechanism honesty:** correctly grounds `.claude/rules/` + `paths:` as native lazy-load
  (`capability-facts.md:52-54`), correctly limits sharding to clean-glob areas (~5–6, not 8), and correctly
  routes path-less constraints to always-loaded `00-safety.md`.

---

## Verdict

**SOUND-WITH-CORRECTIONS.** The architecture, completeness, and safety-floor protection are sound and
verified. Two MUST-FIX items are bookkeeping/routing honesty failures, not design failures: MF-1 (shards
misfiled into budget (2), flattering budget (1) — the exact pattern the charge polices) and MF-2 (only 1 of 3
required memory-trap routings delivered, under-cutting the §B.4 deletion BLOCKER). Both are fixable by editing
prose in this file. The SHOULD-FIX set (P4 homeless at spine altitude; F3/F5 hooks unlisted; a dead proxy
glob; an agent mislabel) tightens completeness and the shard mechanism's reliability. Fix MF-1 and MF-2 and the
tree is SOUND.
