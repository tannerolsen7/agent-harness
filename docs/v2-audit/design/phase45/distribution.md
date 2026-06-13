# Phase 4 — Distribution + Bidirectional Self-Update (the design, recommendation-first)

**What this is.** The decision package for making the harness *installable beyond event-vendor* — the
V2 thesis. Built on the corrected Phase-3 conclusion (`phase3/RECONCILIATION.md`), the ground-truth map
(`CANONICAL-HARNESS-AS-IS.md`), the native-capability facts (`design/capability-facts.md`), and the
canon's own locked sequence (`canon-locked-decisions.md §A`). Every proposal cites the exact component it
changes (`[map §N]`, `[tree §N]`, a disk path) or a confirmed absence re-verified on disk this session.

**Re-verified on disk, 2026-06-11 (not taken on faith — audit artifacts rot):**
- `.claude-plugin/` ABSENT; no `marketplace.json`; no `hooks/hooks.json` anywhere — the harness ships as
  raw `.claude/` files wired through `settings.json`, never as a plugin. The plugin route is greenfield.
- `.claude/rules/` ABSENT — confirms the Phase-3 shard set is net-new.
- **`skills-lock.json` EXISTS at repo root** (6.7 KB, `npx skills add`-managed; tracks the 2 supabase
  skills as upstream github sources with SHA-256 hashes). **The map's §6/HARNESS-AS-IS §7 "phantom" claim
  for `skills-lock.json` is STALE — it is real on disk.** This is load-bearing for requirement 3 (it is
  the existing precedent for a machine-readable manifest, and it means the 2 supabase skills are *already*
  externally-sourced, not ours to ship).
- `.claude/skills/supabase` + `supabase-postgres-best-practices` are **symlinks** into
  `~/.agents/skills/` (verified `ls -la`) — upstream, not authored here.
- `settings.json` wires all 5 hooks via `$CLAUDE_PROJECT_DIR/.claude/hooks/*.sh`, and carries
  `permissions.deny/allow`, `autoMode`, `additionalDirectories`, `env` — **exactly the keys a plugin's
  settings.json CANNOT carry** (`capability-facts`: plugin settings = `agent`+`subagentStatusLine` only).
  This is the hard constraint that shapes the whole split.
- Cross-project install targets confirmed greenfield: `recyclops/.claude/settings.json` = 92 bytes (one
  allowlist line); `recyclops/logistics-service/.claude` = empty; no `~/.claude/CLAUDE.md` [map §0,§8].
- Hooks reference `$CLAUDE_PROJECT_DIR` internally; a plugin re-paths these to `${CLAUDE_PLUGIN_ROOT}`
  (the one mechanical change shipping-as-plugin requires). `block-dangerous-git.sh` reads NO
  project-specific allowlist internally → genuinely portable mechanism. `worktree-create.sh` +
  `gen-local-env.sh` are coupled to the worktree layout but portable in logic (read `supabase status`,
  not hardcoded paths).

---

## 0. The honest two-budget delta for the distribution layer (stated up front, per the binding rule)

The distribution layer adds files. All of them are **budget (2)** (out-of-band packaging/manifests run
OUTSIDE the agent's session context) — none is advisory prose the agent reads every session. Budget (1)
is **unchanged-to-slightly-down** by distribution (the plugin lets a *downstream* project inherit the
harness without copying any always-read prose into its root; and `00-safety` ships once instead of being
re-pasted per project). The new budget-(2) files, each §9-justified:

| New file (budget 2) | §9 failure mode it prevents | Who reads it |
|---|---|---|
| `.claude-plugin/plugin.json` | Without it, hooks/skills/agents have no version identity → a downstream project can't tell which harness SHA it runs, can't pin, can't get a clean `/plugin update` → recreates "every project drifts silently" [map §0]. | Claude Code runtime, never the agent |
| `.claude-plugin/marketplace.json` | Without it there is no install/update *channel* — install degrades to clone-and-manual-copy (the canon's template plan), which ships no update path and "can't cleanly deliver hooks" [`capability-facts`]. | CC runtime at `/plugin marketplace add` |
| `hooks/hooks.json` (in plugin) | Without it, hooks must be wired by editing the downstream project's `settings.json` — a guard file the agent is forbidden to touch [memory: no_agent_edits_guard_files] AND that already carries permissions/autoMode. A plugin `hooks.json` wires hooks WITHOUT touching the guard file. | CC runtime |
| `harness-manifest.json` (generated) | Without it, prose-inventory drift (canon says 46 skills, disk has 26 [map §3b]) has no machine check → "you can't version-distribute a harness whose canon and disk disagree" [`canon-locked §A`]. The manifest is the convergence gate's assertion target. | CI drift check (`scan-context`), never the agent |
| `VERSION` / changelog in plugin repo | Without it, "which fixes are in this install" is unanswerable → no rollback target, no release-channel discipline. | humans + `/plugin update` |

**Net distribution budget-(2) delta: +4 to +5 packaging/manifest files, all §9-justified, all outside
the agent's read-context.** Budget (1) for a *fresh* downstream install is *near-zero new prose* (it
inherits skills/agents/hooks/safety-floor; it authors only its own CLAUDE.md/AGENTS.md/area-rules — which
it would need regardless of harness). This is the correct shape: distribution is pure budget (2). I will
NOT present "one plugin" as a file-count win — it is +5 packaging files that BUY a native update channel
and decouple hook-wiring from the guard file.

---

## 1. THE VEHICLE FORK — recommendation and defense

### Recommendation: a TWO-VEHICLE split (revise the canon's single locked vehicle)

> **Behavioral harness → Claude Code PLUGIN + marketplace.** (skills, agents, hooks, the `00-safety`
> floor, portable scripts, MCP registry shape.)
> **Project-owned files → a thin TEMPLATE/`/init` skill.** (CLAUDE.md, AGENTS.md, CONTEXT.md,
> settings.json permissions/autoMode, area-specific `.claude/rules/*` shards, mcp.md.)
> **Converge canon↔disk FIRST (§3) — non-negotiable, and the canon already locks it.**

This is *not* "plugin instead of template." It is **plugin for the portable mechanism + template for the
project-owned content** — because the hard capability constraint forces exactly this seam.

### Why the seam is forced, not chosen (the load-bearing argument)

The canon's locked decision (`canon-locked §A`, 2026-05-18) picks ONE vehicle: a GitHub Template Repo,
"click template → fill `[TODO]`s → use skills," with **plugins, npx, and sync scripts explicitly deferred**.
That decision predates plugin-marketplace maturity and rests on a false premise: that a single vehicle can
carry the whole harness. On disk it cannot, for a reason the 2026-05-18 plan could not have known:

- **A plugin CANNOT ship the permissions/autoMode/deny block.** Verified against the live
  `settings.json`: that file carries `permissions.deny` (the guard-file lockout), `permissions.allow` (50+
  Bash patterns), `autoMode` (the soft/hard-deny `$defaults`), `additionalDirectories`, and `env`. A
  plugin's settings.json is restricted to `agent`+`subagentStatusLine` [`capability-facts`]. So **the
  plugin physically cannot deliver the project's safety permissions** — those MUST be project/user/managed
  and human-authored. Any single-vehicle plan that ships "the harness" must therefore *still* hand the
  project a settings.json to fill in. The template plan already accepts this (it's the `[TODO]` fill step);
  the plugin plan accepts it too (the thin template carries it). **Both vehicles converge on: mechanism
  ships automatically, permissions are authored per-project.** The only question is whether the *mechanism*
  travels as a versioned plugin or as copied template files.

- **A Template Repo cannot deliver an update channel.** `[capability-facts]`: "GitHub template repo is
  NOT a plugin channel — it's clone + manual copy, ships no install/update mechanism, and can't cleanly
  deliver hooks or pull updates." The canon itself *defers* `harness-update.sh` precisely because the
  template has no native pull path. **The plugin makes the entire Phase-4 PULL requirement native**
  (`/plugin install`, version pinning, release channels, `/plugin update` — `capability-facts`). Choosing
  the template means hand-rolling the update tooling the canon deferred; choosing the plugin means the
  update path *already exists*.

- **A plugin wires hooks WITHOUT touching the guard file.** This is the decisive operational win. Today
  hooks are wired by `$CLAUDE_PROJECT_DIR/.claude/hooks/*.sh` entries inside `settings.json` — a file the
  agent is *denied* edit access to (`permissions.deny: Edit(/.claude/settings.json)`) and that a human must
  hand-edit per project. A plugin ships `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}` paths and CC wires
  them at install time — **zero edits to the downstream guard file.** For a system whose own memory says
  "never edit guard files" [memory: no_agent_edits_guard_files], this is not a nicety; it removes the one
  step of harness install that *requires* a human to touch the most dangerous file.

### Why revising a LOCKED decision is warranted here (not decision-churn)

The canon-locked rule is "reconcile and extend, don't re-decide." Three of the four conditions for a
legitimate revision are met:

1. **A material fact changed since the lock.** The 2026-05-18 decision predates the plugin-marketplace's
   ability to ship hooks+skills+agents with a version-pinned update channel. The lock was made under "no
   plugin maturity"; that constraint is gone (`capability-facts` verified the mechanism exists today). A
   locked decision made under a now-false constraint is exactly what the "reconcile with current reality"
   clause licenses revisiting.
2. **The revision honors, not breaks, the locked SEQUENCE.** The canon's sequence is *converge → ship v1
   → validate on 3 installs → add Cursor → add npx → UI*. The plugin slots in as the **v1 ship vehicle**
   and the validation gate is unchanged (§5). We are not jumping ahead to npx/Cursor/UI — those stay
   deferred. We are swapping the *v1 carrier* from "template repo" to "plugin + thin template," which is a
   strictly-more-capable v1 that still gates on the same 3 installs.
3. **The revision REDUCES downstream tooling, not adds it.** The template plan defers `harness-update.sh`
   as future work *to be built*; the plugin route deletes that future work (the channel is native). Picking
   the plugin is the lower-machinery choice over the harness's lifetime — which is the Winchester-Mystery-
   House discipline the canon-locked note itself invokes.

**The one place I honor the lock verbatim:** the project-owned files (CLAUDE.md/AGENTS.md/permissions)
still travel as a **template/`[TODO]`-fill** exactly as locked. The canon's `[TODO]`-placeholder mechanic
and the "explain AGENTS.md vs CLAUDE.md" validation condition (§5) survive intact. So the revision is
surgical: plugin for the half a plugin is *better* at (versioned portable mechanism + update channel +
guard-file-free hook wiring), template for the half a plugin *cannot* carry (permissions + project
knowledge).

### What I explicitly do NOT do (reject-as-literal)

- **No npx `skills add` for the project harness in v1** — deferred per the locked sequence. (Note: the 2
  upstream supabase skills *already* arrive via `npx skills add`/`skills-lock.json`; that's the upstream
  ecosystem's channel, kept as-is — the plugin does not re-ship them.)
- **No symlink-live install** — rejected [map/MASTER §F]: symlinks resolve to HEAD, not a validated SHA,
  recreating the canon's own install-method contradiction. The plugin is versioned-copy-with-lock by
  construction (§4).
- **No Cursor/`.codex`/UI** — deferred behind the 3-install gate (§5).

---

## 2. THE PROJECT-OWNED vs PLUGIN-SHIPPED SPLIT — the concrete manifest

This deepens `tree §7` (which marked the split but deferred the design to here) into a per-file
disposition. Three columns: **PLUGIN** (portable mechanism, version-shipped), **PROJECT** (this codebase's
knowledge/permissions, authored locally), **SPLIT** (a plugin floor + project-authored extensions).

### Plugin repo layout (`agent-harness` — the extracted, Monica/Fern-stripped repo)

```
agent-harness/                         ← the standalone repo (canon-locked name)
  .claude-plugin/
    plugin.json                        NEW  — name, version, author, components manifest
    marketplace.json                   NEW  — the install/update channel descriptor
  hooks/
    hooks.json                         NEW  — wires the hooks via ${CLAUDE_PLUGIN_ROOT} (NOT project settings.json)
    block-dangerous-git.sh             PLUGIN — re-pathed; reads no project allowlist (verified portable)
    block-npm-install.sh               PLUGIN — portable
    block-dangerous-bash.sh            PLUGIN — NEW (MOVE-2 build); the 3rd structural guard, universal
    session-start.sh                   PLUGIN — portable (CLAUDE_PROJECT_DIR-based)
    session-end-capture.sh             PLUGIN — NEW (MOVE-1 writer)
  agents/                              PLUGIN — all 23 (portable roles; tree §3 kept all)
  skills/                              PLUGIN — 23 authored bodies (the 2 supabase symlinks do NOT travel — see below)
  rules/
    00-safety.md                       PLUGIN — the universal PocketOS/destructive-op floor (KEEP-VERBATIM)
  templates/                           PLUGIN — scaffolds the /init skill copies into a fresh project:
    CLAUDE.md.template                 (with [TODO] placeholders — the canon's locked fill-in mechanic)
    AGENTS.md.template
    CONTEXT.md.template
    settings.json.template             (permissions/autoMode skeleton — human fills + authors)
    rules-area.md.template             (the shape an area shard takes)
    mcp.md.template
  scripts/                             SPLIT — portable workflow scripts only (see table)
    gc.sh  pr.sh  worktree-add.sh  gen-rules.sh  scan-context.sh
  SOUL.md  agent-contract.md  AI-WORKFLOW.md  INDEX.md  diff-review.md  rituals.md   PLUGIN (as defaults; project may override)
  README.md                            — "this is a system" explainer (canon-locked requirement)
  CHANGELOG.md / VERSION               NEW — release discipline
  harness-manifest.json                NEW (generated) — the drift-check target (§3)
```

### The per-file disposition table

| File / dir | Owner | Why (cite) |
|---|---|---|
| `skills/**` (23 authored bodies) | **PLUGIN** | Portable procedures [tree §7]. **Exception:** `supabase` + `supabase-postgres-best-practices` are upstream symlinks tracked by `skills-lock.json` (verified) — they do NOT ship in the plugin; a downstream project runs `npx skills add supabase/agent-skills` itself (or the `/init` skill prompts it). Re-shipping them would fork the upstream source. |
| `agents/**` (23) | **PLUGIN** | Portable roles, project-agnostic [tree §3, §7]. All 23 pass §9. |
| `hooks/*.sh` (7: 5 live + 2 new) | **PLUGIN** | Scripts are portable; `block-dangerous-git` reads no project allowlist (verified). Re-path `$CLAUDE_PROJECT_DIR`→`${CLAUDE_PLUGIN_ROOT}` where the script is plugin-relative; keep `$CLAUDE_PROJECT_DIR` where it must resolve the *consuming* project (session-start, worktree). |
| `hooks/hooks.json` | **PLUGIN (NEW)** | Wires hooks at install WITHOUT editing the downstream guard `settings.json` — the decisive win (§1). |
| `rules/00-safety.md` | **PLUGIN** | The universal safety floor (PocketOS/destructive-op). A fresh install gets it FREE [tree §7; KEEP-VERBATIM floor]. |
| `rules/<area>.md` (migrations, data-layer, schemas, auth-routing, architecture, harness-hooks, git-worktree) | **PROJECT** | Their `paths:` globs and traps are *this* Next/Supabase codebase's shape [tree §5, §7]. A fresh project authors its own from `rules-area.md.template`. The plugin does NOT ship event-vendor's PITFALLS-derived shards. |
| `permissions` (settings.json allow/deny) | **PROJECT** | Plugin can't carry it [`capability-facts`]; guard file, human-only [memory: no_agent_edits_guard_files]. `/init` copies a skeleton; human authors. |
| `autoMode` block | **PROJECT** (or managed) | Plugin can't carry it; per-machine/per-project; correct home is `settings.local.json` or `managed-settings.json` [enforcement-sort (e); `capability-facts`]. |
| `mcp.md` | **PROJECT** | The allowlist + "Playwright rejected" decision is this project's [tree §7]. Plugin MAY ship an `.mcp.json` *shape*, but the decisions stay local. |
| `CLAUDE.md / AGENTS.md / CONTEXT.md / TASKS.md / STRATEGY.md / README.md` | **PROJECT** (from `.template`) | Irreducibly this project's product/scope/process [tree §2, §7]. Ship as `[TODO]` templates (canon-locked). |
| `SOUL.md / agent-contract.md / AI-WORKFLOW.md / INDEX.md / diff-review.md / rituals.md` | **PLUGIN (as default)** | Portable agent-discipline docs [tree §7]; ship as plugin defaults a project MAY override. (A project that edits them shadows the plugin copy.) |
| `docs/**` (solutions, adr, specs, RECURRING-FINDINGS, design, TESTING, ARCHITECTURE) | **PROJECT** | Captured knowledge about *this* codebase [tree §4, §7]. README/TEMPLATE *shapes* ship as plugin scaffolds; the *content* stays. |
| `scripts/gc.sh, pr.sh, worktree-add.sh, gen-rules.sh, scan-context.sh` | **PLUGIN** | Generic workflow [tree §7]. |
| `scripts/seed.ts, test-local.sh, gen-local-env.sh, migration-lint` | **PROJECT** | `seed.ts` and the migration-lint ruleset are event-vendor's; `gen-local-env`/`test-local` are Supabase-stack-shaped but project-tuned [tree §7]. (Note: `gen-local-env` reads `supabase status` generically — a *Supabase* project gets it nearly free; a non-Supabase project doesn't want it. SPLIT leans PROJECT.) |
| `skills-lock.json` | **PROJECT** | The upstream-skill lockfile is per-project (which upstream skills THIS project pulls) [verified on disk]. Not the harness's to ship. |

### The S1/S2/S3 memory model under distribution (the Phase-3 model carried forward)

The corrected memory model is **3 owned stores (S1 rules+floor / S2 solutions / S3 findings-inbox) + 1
ridden auto-memory cache** [`RECONCILIATION §B`]. Under distribution:

| Store | Ships as | Why |
|---|---|---|
| **S1 — rules** | **SPLIT.** `00-safety.md` ships as a PLUGIN floor (full content, universal). Area shards ship as **empty-scaffold templates** (`rules-area.md.template`) — a fresh install gets the *schema and the safety floor*, authors its own traps. | The safety floor is universal; the traps are codebase-specific [tree §5/§7]. You cannot ship event-vendor's `migrations.md` to a non-Supabase project. |
| **S2 — solutions** | **PROJECT-content; PLUGIN ships the README+TEMPLATE+frontmatter schema only as an empty scaffold.** | Solutions are reusable patterns *about this codebase* [tree §4]. The *structure* (frontmatter tags, status/superseded-by) is portable; the entries are not. |
| **S3 — findings-inbox** (`RECURRING-FINDINGS.md`) | **PROJECT-content; PLUGIN ships the empty file + the `/cr` 3b writer + the promotion-gate schema.** | The airlock *mechanism* (writer, decay clock, promotion gate) is portable; the findings are this project's [tree §4; memory-model §2]. |
| **auto-memory cache** | **NOT shipped — it's the CC subsystem's, user-scoped.** | Outside our model to ship; "on conflict, curated stores win" is the one prose line that travels in `00-safety`/CLAUDE template [RECONCILIATION §B.5, D3]. |

**Rule: S1's safety floor is the ONLY memory content that ships as content. Everything else in S1/S2/S3
ships as an empty scaffold (schema + writer + clock), not as event-vendor's accumulated entries.** This is
the anti-phantom guard for distribution: a fresh install must not inherit another project's traps as if
they were its own.

### What a fresh install gets FREE vs MUST AUTHOR

| Free (inherited from plugin, version-pinned) | Must author (project-owned, `/init`-scaffolded) |
|---|---|
| 23 agents, 23 skills, all hooks wired (no guard-file edit) | `CLAUDE.md` / `AGENTS.md` / `CONTEXT.md` (fill `[TODO]`s) |
| `00-safety.md` destructive-op floor | `settings.json` permissions + autoMode (human-authored) |
| `SOUL/agent-contract/AI-WORKFLOW/rituals` defaults | Its own `.claude/rules/<area>.md` shards (traps + globs) |
| `gen-rules.sh`, `scan-context.sh`, `pr.sh`, `gc.sh` | Its own `mcp.md` decisions; its own `skills-lock.json` upstream picks |
| S2/S3 schemas + writers + decay clocks (empty) | Its own product knowledge in `docs/**` |
| The `/plugin update` channel | (Supabase-shaped scripts only if it's a Supabase project) |

---

## 3. CONVERGE CANON↔DISK FIRST — the locked precondition and its gate

You cannot version-distribute a harness whose canon and disk disagree [`canon-locked §A`; map §7]. The
convergence gate is the **v1-ship blocker**: until it passes, no plugin publishes. It has two halves — a
**one-time reconciliation** of the 9+ live divergences, and a **standing machine-readable manifest check**
that keeps prose-inventory drift from re-opening.

### 3a. The one-time convergence checklist (must all clear before v1 publish)

Each row cites the divergence from the map. "Resolve to" states the single converged truth.

| # | Divergence (cite) | Resolve to |
|---|---|---|
| 1 | `cr-feature` RETIRED v0.85 but still referenced in canon Page-11/14 [map §3b,§7.2] | DELETE all `cr-feature` references from canon; disk is already correct (no dir). |
| 2 | `dep-update/` canon-documented-in-full, disk = empty stub [map §3b,§6] | CUT the empty disk dir [tree §3]; mark canon entry "deferred — not built." Do NOT ship a body-less skill (phantom-trigger surface). |
| 3 | `session-end.sh` ABSENT on disk, present in canon's locked v1 tree [map §3e; canon-locked §A] | BUILD `session-end-capture.sh` (MOVE-1 writer) before it appears in the manifest; OR strike it from the canon tree. (Recommend build — it's the loop's write half.) |
| 4 | `/cr` pass-count drift: canon "9 incl. adversarial" vs disk "9 + Pass 11" vs runtime "9 plus adversarial" [map §3c] | Pick ONE numbering. Recommend disk's: "9 analytical passes + 1 adversarial review pass (4 lenses)." Fix the canon's internal "P0–P10" auto-fix-prose bug. Update the `/cr` skill description (today it says "9 analytical passes plus an adversarial review" — already close; lock it). |
| 5 | `/cr-security` pass count: canon 2 vs disk 3 [map §3c,§6] | Reconcile to disk's 3 (the richer, running version); update canon. |
| 6 | `dev`, `explain` skills on disk, ABSENT from canon [map §3b,§6] | DOCUMENT both in canon (they pass §9 [tree §3]). Convergence = add to canon, not delete from disk. |
| 7 | `skills-lock.json` listed as phantom in map §6 but EXISTS on disk (verified this session) | CORRECT the map: it's real. It is the *precedent* for the harness-manifest (3c). |
| 8 | The 9 canon internal contradictions [map §7]: two feature loops, two reviewer names, Pages 12↔13, 60% trigger, agent counts, pre-push sync-gate, upstream install method, v0.16 ownership table | Apply "later-dated page wins" mechanically; record each resolution in the convergence log. These are canon-internal — they don't block the *plugin* but they DO block a coherent README. |
| 9 | autoMode block sits in committed `settings.json` where the classifier ignores it [`capability-facts`; map §3e] | Placement fix (human handoff): move to `settings.local.json`/`managed-settings.json`. This is a convergence item because the plugin's `/init` template must scaffold autoMode in the *correct* file, not the ignored one. |

**Gate rule:** the plugin's `harness-manifest.json` (3c) is generated from disk; a CI check asserts every
manifest entry exists on disk AND is documented in canon, and every canon-documented skill/agent/hook
either exists on disk or is explicitly flagged `status: deferred`. **Convergence = manifest, disk, and
canon agree.** Publish is blocked on a green convergence check.

### 3b. The machine-readable skill/agent/hook manifest (catches prose-inventory drift)

The canon claims ~46 skills; disk has 26 [map §3b]. Prose inventories rot (the map itself carried a stale
`skills-lock.json` phantom — proven this session). The fix is a **generated manifest, not a hand-counted
list**, modeled on the existing `skills-lock.json` (which already does exactly this for upstream skills):

```jsonc
// agent-harness/harness-manifest.json  (GENERATED by scripts/gen-manifest.sh, checked in CI)
{
  "version": "1.0.0",
  "generatedFrom": "<git-sha>",
  "skills":  [ { "name": "cr", "path": "skills/cr/SKILL.md", "hash": "...", "owner": "plugin",
                 "hasFrontmatter": true, "failureMode": "MUST-FIX defects merge to main" }, ... ],
  "agents":  [ { "name": "reviewer", "path": "agents/reviewer.md", "hash": "...", "wiredBy": "cr,grill-with-docs" }, ... ],
  "hooks":   [ { "name": "block-dangerous-git", "event": "PreToolUse", "owner": "plugin" }, ... ],
  "rules":   [ { "name": "00-safety", "owner": "plugin", "alwaysLoad": true },
               { "name": "migrations", "owner": "project", "paths": "supabase/migrations/**" }, ... ]
}
```

The drift-CI (`scan-context.sh`, the `/scan-context` phantom finally built — MOVE-3) asserts:
1. **Existence** — every manifest path resolves on disk (catches canon-claims-X-disk-lacks-X).
2. **No-orphans** — every disk skill/agent/hook appears in the manifest (catches disk-has-X-canon-ignores).
3. **Frontmatter** — every skill has the required frontmatter (the 0/26 invocation-control gap [MASTER §C]).
4. **Wiring** — every agent's `wiredBy` skill exists (catches lens/spike orphaning if a skill is cut).
5. **Owner coherence** — `owner: plugin` files live in the plugin repo; `owner: project` are NOT shipped.

This is the budget-(2) manifest the §0 table justifies. It is the convergence gate's *standing* half: the
one-time checklist (3a) clears the backlog; the manifest check keeps it clear on every publish.

---

## 4. THE TWO UPDATE PATHS

### 4a. PULL (downstream inherits harness updates) — BUILD NOW, native

The plugin makes this native and the design is mostly "use the mechanism correctly, don't reinvent it":

- **Versioned-copy-with-lock, NOT symlink-live.** `/plugin install agent-harness@1.2.0` copies a
  *validated SHA* into the downstream `~/.claude/plugins/`. This is the explicit rejection of symlink-live
  [map/MASTER §F]: a symlink resolves to the plugin repo's HEAD, so a downstream project silently runs
  whatever was last pushed — un-validated, possibly mid-convergence. The version pin IS the validated-SHA
  lock. **This single property is why the plugin route does not recreate the canon's own install
  contradiction.**
- **Release channels:** `stable` (only post-3-install-validation versions) and `next` (event-vendor
  dogfoods here first). event-vendor runs `next`; a second project runs `stable`. A bad harness change is
  caught on `next` before it reaches `stable`.
- **`/plugin update` is the pull command.** Downstream sees "1.2.0 → 1.3.0 available," reads the
  CHANGELOG, updates deliberately. No auto-update (a harness change is behavior-affecting; auto-pulling it
  is the same forgeable-authority risk as symlink-live).
- **What pull does NOT touch:** the project-owned half (§2). `/plugin update` updates skills/agents/hooks/
  `00-safety`; it never overwrites the project's `CLAUDE.md`, permissions, or area shards. The seam in §2
  is exactly what makes pull safe — there is no project content to clobber.

### 4b. PUSH-BACK-UP (a project's learned patterns flow to the shared harness) — DESIGN NOW, BUILD LATER

This is the compounding loop's **outer ring** — the inner ring (a project learns within itself: S3→S1
promotion) is Phase 5. The outer ring asks: when event-vendor's S3 surfaces a trap that is *universal*
(not Next/Supabase-specific), how does it graduate into the *plugin's* `00-safety` or a shared skill so
every downstream install inherits it?

**Per the hypothesis-before-speculative-build rule, this is DESIGNED now and BUILT later.** Building
push-back tooling before any downstream install exists is the forbidden speculative build — there is
nothing to push *to* yet. The design (wired to Phase 5):

1. **The signal already exists** — the S3→S1 promotion gate (Phase 5 / `/compound`) already classifies a
   finding as promotable. Push-back adds ONE field to that gate: `scope: project | universal`. A
   `universal` promotion is a push-back candidate.
2. **The channel is a PR to the `agent-harness` repo**, not new tooling. When `/compound` promotes a
   `universal` finding, it surfaces it as "candidate harness PR: this trap belongs in the shared
   `00-safety`/`<skill>`." A human reviews and opens the PR. **No auto-push** — a change to the shared
   harness affects every downstream project; it gets the same human gate as a destructive op.
3. **The plugin's release discipline closes the loop:** the harness PR lands on `next`, event-vendor
   dogfoods it, it graduates to `stable`, downstream installs `/plugin update` and inherit it. The PULL
   path (4a) IS the delivery half of push-back.

**Built now:** nothing beyond the `scope:` field on the Phase-5 promotion gate (one field, cheap, no
speculative tooling). **Built later (gated on ≥2 installs existing):** any automation that opens the
harness PR for you. Until there are two projects, there is no "back up" to push to — event-vendor IS the
harness. The honest resolution: **the outer ring is a one-field design hook now, a tooling build after
installs prove the inner ring works.**

```
  PROJECT (event-vendor)                         SHARED HARNESS (agent-harness plugin)
  ┌─────────────────────┐                        ┌──────────────────────────────┐
  │ run → S3 inbox      │  /compound promote     │ next channel ── dogfood ──┐   │
  │  (RECURRING-FINDINGS)│  scope: universal      │                          ▼   │
  │      │ S3→S1 (inner) │ ─────PR (human gate)──▶│ 00-safety / shared skill     │
  │      ▼               │                        │           │                  │
  │  .claude/rules/      │ ◀──── /plugin update ──│ stable channel (validated)   │
  └─────────────────────┘     (PULL = delivery)   └──────────────────────────────┘
        inner ring (Phase 5)                              outer ring (this design, built later)
```

---

## 5. MIGRATION PATH + VALIDATION GATE

Honor the canon's locked sequence and its 4-condition "3 real installs" gate [`canon-locked §A`]. The
sequence, with the plugin slotted in as the v1 vehicle:

```
STEP 0  CONVERGE canon↔disk (§3a checklist green; §3b manifest check green)        ← v1-ship BLOCKER
          └─ build the 2 hooks that the manifest references (session-end-capture, block-dangerous-bash)
             so the manifest isn't a phantom; apply the autoMode placement fix; resolve the 9 contradictions.
STEP 1  EXTRACT agent-harness repo — strip ALL Monica/Fern's/event-vendor content [canon-locked §A]
          ├─ ships: §2 PLUGIN column only (mechanism + 00-safety + templates + portable scripts)
          ├─ strips: area shards, docs/** content, seed.ts, mcp decisions, permissions — these are
          │         project-owned (§2); the repo carries only their .template skeletons
          └─ adds:  .claude-plugin/{plugin,marketplace}.json, hooks/hooks.json, harness-manifest.json, README
STEP 2  SHIP v1 — publish the plugin to its marketplace (git repo); event-vendor installs it from `next`
          └─ event-vendor becomes the FIRST consumer of its own extracted harness (dogfood; validates the
             extraction didn't drop a wire). This is install #0 and does NOT count toward the gate (same author).
STEP 3  VALIDATE on 3 REAL installs (the canon's unchanged 4-condition gate):
          (1) installed via /plugin install — no author-copied files
          (2) all [TODO]s filled without asking the author
          (3) ≥1 skill (/cr, /tdd, /dev) ran and produced correct output
          (4) the installer can explain AGENTS.md vs CLAUDE.md without looking it up
          └─ candidate real targets: recyclops (greenfield .claude, 92 bytes [map §8]),
             recyclops/logistics-service (empty .claude [map §8]) — both are genuine non-event-vendor
             installs. The 3rd is the first external/non-Tanner project, OR a clean fresh repo.
STEP 4  ONLY AFTER 3 green installs → add Cursor adapter → add `npx skills add` → build UI [canon-locked §A]
```

**Why event-vendor's dogfood install (Step 2) does not satisfy the gate:** condition (1) is "no
author-copied files" and the whole point of the gate is *the README works for someone who isn't you*
[canon-locked §A]. event-vendor installing its own extracted harness proves the *extraction* is clean (no
dropped wires), which is necessary but not the gate. recyclops is the first install that tests the README.

**The gate is a STOP, not a checkpoint.** No Cursor/npx/UI work begins until 3 installs are green. This is
the canon's anti-Winchester-Mystery-House discipline, and the plugin route does not relax it — it just
makes Steps 2–3 mechanically cleaner (install via `/plugin install` instead of clone-and-copy).

---

## 6. The honest two-budget delta for the WHOLE distribution layer (closing)

- **Budget (1) — agent-context/advisory prose:** distribution is **neutral-to-favorable**. The plugin
  ships no new always-read prose into a downstream project's root; `00-safety` ships once (version-pinned)
  instead of being re-pasted per project; a fresh install's budget (1) is *only what it must author for
  itself* (its own CLAUDE.md/AGENTS.md/area-rules — which it needs regardless of the harness). The
  harness's existence stops *increasing* budget (1) per project.
- **Budget (2) — out-of-band packaging/manifests/channels:** **+4 to +5 files** (`plugin.json`,
  `marketplace.json`, `hooks/hooks.json`, `harness-manifest.json`, `VERSION`/CHANGELOG), each §9-justified
  in §0, plus `gen-manifest.sh` and the `scan-context.sh` drift check (the latter already counted in the
  Phase-3 mechanism budget). None is read by the agent in-session.
- **The net:** distribution is **pure budget (2) growth** that BUYS (a) a native version-pinned update
  channel the canon's template plan had to defer and hand-roll, (b) hook-wiring that never touches the
  downstream guard file, and (c) a machine-readable convergence gate against prose-inventory rot. **No
  budget-(1) cost; no favorable-proxy claim** — I am not calling "one plugin" a file-count win; it is +5
  packaging files that earn their place by §9.

The distribution layer does not make the harness *smaller*. It makes the harness *exist in more than one
place without drifting* — which is the V2 thesis, and which the file count was never going to capture.

---

## 7. Genuine open decisions (forks for Tanner — recommendation-first)

1. **Revise the canon's locked single-vehicle decision?** *Recommend YES — two-vehicle split (plugin for
   mechanism + thin template for project-owned).* Defended in §1: a material capability fact changed since
   the 2026-05-18 lock, the sequence is honored, and it reduces (not adds) downstream tooling. Tanner must
   ratify revising a locked decision.
2. **Where does the `agent-harness` marketplace live?** Same GitHub account (`tannerolsen7`) as a new repo,
   recommended (matches the autoMode source-control trust block). A separate org is premature at solo scale.
3. **`next` vs `stable` channel discipline — adopt now or after install #2?** *Recommend define both now,
   enforce `next`-then-`stable` only once a second project exists* (before that, event-vendor is both).
4. **Push-back automation timing:** *Recommend the `scope: project|universal` field on the Phase-5
   promotion gate NOW; the PR-opening automation only after ≥2 installs.* Confirm this honors
   hypothesis-before-speculative-build to Tanner's satisfaction.
5. **The 3rd validation install:** recyclops + logistics-service are 2 genuine targets; what is the 3rd?
   (A truly external/non-Tanner project most rigorously satisfies condition (4); a clean fresh repo is the
   low-friction fallback.) Tanner picks.
6. **autoMode placement during extraction:** the `/init` template must scaffold autoMode into
   `settings.local.json`/`managed-settings.json` (the honored file), NOT committed `settings.json` (where
   the classifier ignores it) [§3a.9]. This is a human-handoff guard-file edit — confirm Tanner applies it,
   not an agent [memory: no_agent_edits_guard_files].
7. **Do the upstream supabase skills stay `npx skills add`, or fold into the plugin?** *Recommend stay
   upstream* (forking them into the plugin breaks the `skills-lock.json` sync with `supabase/agent-skills`).
   The `/init` skill prompts the install instead.
```
