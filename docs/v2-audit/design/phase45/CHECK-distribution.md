# CHECK — Distribution + Bidirectional Self-Update (adversarial, doer≠checker)

**Target:** `docs/research/v2-audit/design/phase45/distribution.md`
**Checker:** independent adversarial agent (did NOT write the artifact).
**Method:** re-ground every load-bearing claim on disk this session (Bash/Grep/Read) — the audit rots.
**Verdict: SOUND-WITH-CORRECTIONS.** The two-vehicle thesis, the forced seam, the convergence gate, and
both update paths survive a hard attack — several survive *strengthened* by empirical evidence the author
did not have. No blocker invalidates the recommendation. Four corrections are required before this feeds
the decision package; one is a factual error in a load-bearing citation, three are accuracy/over-claim
fixes. I tried hard to kill the central claim (the plugin-settings constraint that forces the seam) and it
did not die — the disk proved the mechanism works even better than the author argued.

---

## What I re-verified on disk (2026-06-11) — the ground-truth ledger

| # | Claim in distribution.md | Disk reality | Status |
|---|---|---|---|
| G1 | `.claude-plugin/` ABSENT, no `marketplace.json`, no `hooks/hooks.json` in repo | `ls .claude-plugin` → No such file; `find marketplace.json/hooks.json` → none in repo | ✅ CONFIRMED |
| G2 | `.claude/rules/` ABSENT | `ls .claude/rules` → No such file | ✅ CONFIRMED |
| G3 | `skills-lock.json` EXISTS at repo root, real (not phantom), git-tracked, SHA-256, tracks 2 supabase skills as upstream github | exists; `git ls-files` → tracked; content confirms SHA-256 + `supabase/agent-skills` source | ✅ CONFIRMED (substance) — but see C1: **size is 751 B, NOT 6.7 KB** |
| G4 | supabase + supabase-postgres-best-practices are symlinks into `~/.agents/skills/` | `ls -la` → both are symlinks → `../../.agents/skills/...` | ✅ CONFIRMED |
| G5 | committed `settings.json` carries `permissions.deny/allow`, `autoMode`, `env` — keys a plugin settings.json can't carry | top-level keys = `['env','autoMode','permissions','hooks']` | ✅ CONFIRMED (note: `additionalDirectories` claimed but NOT a top-level key on disk — see C4) |
| G6 | `block-dangerous-git.sh` reads NO project-specific allowlist internally → portable | non-comment grep for allow/PUBLIC/permission → 0 hits; only comments mention "allowed path" | ✅ CONFIRMED |
| G7 | recyclops `.claude/settings.json` = 92 bytes, one allowlist line; greenfield | 92 bytes, `{permissions.allow:[notion-fetch]}` | ✅ CONFIRMED |
| G8 | `recyclops/logistics-service/.claude` = empty | dir does **NOT EXIST** (no `.claude` at all) | ⚠️ DIRECTIONALLY OK, CITATION STALE — see C3 |
| G9 | no `~/.claude/CLAUDE.md` | `ls` → No such file | ✅ CONFIRMED |
| G10 | a plugin wires hooks via `hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}`, WITHOUT touching downstream `settings.json` | **vercel plugin on disk does EXACTLY this** (see "The kill attempt" below) | ✅ CONFIRMED — EMPIRICALLY, on a real installed plugin |
| G11 | convergence #1: `cr-feature` retired, no dir on disk | `ls .claude/skills/cr-feature` → No such file | ✅ CONFIRMED |
| G12 | convergence #2: `dep-update/` is an empty disk stub | dir exists, contains NO `SKILL.md` (truly empty) | ✅ CONFIRMED |
| G13 | convergence #9: autoMode in committed `settings.json` where classifier ignores it | `autoMode` at line 6 of `.claude/settings.json`; `settings.local.json` exists (4155 B) as the correct home | ✅ CONFIRMED |
| G14 | `/cr` desc already says ~"9 analytical passes plus an adversarial review" | desc verbatim: "9 analytical passes plus an adversarial review" | ✅ CONFIRMED |
| G15 | session-end-capture.sh / block-dangerous-bash.sh are NEW (absent) | `find` → absent on disk (only a git branch ref matches) | ✅ CONFIRMED |

**Disk hooks actually present (5):** `block-dangerous-git.sh`, `block-npm-install.sh`, `permission-logger.sh`,
`session-start.sh`, `worktree-create.sh`. **Skills: 26 dirs** (incl. 2 symlinks + 1 empty `dep-update`).
**Agents: 23.** All consistent with RECONCILIATION §D/§E.

---

## The kill attempt (the load-bearing claim I tried hardest to break)

The entire two-vehicle recommendation rests on ONE capability fact: **a plugin's `settings.json` is limited
to `agent`+`subagentStatusLine`, therefore the plugin physically cannot ship the permissions/autoMode/deny
block, therefore the seam (plugin-for-mechanism + template-for-permissions) is FORCED, not chosen** (§1).
If that fact is wrong, the seam collapses and the recommendation is decorative.

I attacked it with a real installed plugin instead of the doc/spec. Findings from
`~/.claude/plugins/cache/claude-plugins-official/vercel/0.43.0`:

1. The vercel plugin's `.claude/settings.json` is **27 bytes: `{"enabledPlugins": {}}`** — it carries
   NEITHER `agent` NOR `subagentStatusLine` NOR any permissions block. So the *literal* capability-facts
   phrasing ("plugin settings.json = `agent`+`subagentStatusLine` only") is **imprecise** — a shipped plugin
   doesn't put behavioral keys there at all.
2. **But the load-bearing direction is CONFIRMED and STRENGTHENED:** the vercel plugin ships **NO permissions
   block anywhere**, and it wires its hooks through a top-level **`hooks/hooks.json`** using
   `node "${CLAUDE_PLUGIN_ROOT}/hooks/..."` — exactly the mechanism distribution.md §1/§2 proposes. A real,
   widely-installed plugin proves: (a) plugins do NOT and CANNOT carry the project permissions block (vercel
   doesn't try), and (b) `hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}` is the *production* hook-wiring path,
   touching zero downstream guard files.
3. **The plugin marketplace + versioned-copy-with-lock is not hypothetical — it is live on this machine.**
   `~/.claude/plugins/installed_plugins.json` shows 2 installed plugins (notion 0.1.0, vercel 0.43.0), each
   pinned to a `gitCommitSha`. The official `marketplace.json` entries use `source: git-subdir` with both a
   `ref` (`v1.5.5`) AND a `sha`. **This is the exact "versioned-copy-with-lock, NOT symlink-live" property
   the doc claims (§4a) and §9-requires — and it is already the platform's default behavior.**

**Verdict on the kill attempt: the central claim SURVIVED.** The seam is genuinely forced. The only damage
is to the *precision* of the capability-facts wording, not to the recommendation. I record the correction
(C2) so the decision package doesn't repeat an imprecise spec claim that a skeptical reader could disprove
in 30 seconds with the same `cat` I ran — which would wrongly discredit a sound recommendation.

---

## Axis-by-axis findings

### 1. PHANTOM — does it propose building/keeping something that already exists? → CLEAN, with one nuance
- Cross-checked against MASTER-FINDINGS §E (anti-phantom) and the live runtime. The doc proposes
  `plugin.json`, `marketplace.json`, `hooks/hooks.json`, `harness-manifest.json`, `gen-manifest.sh`,
  `session-end-capture.sh`, `block-dangerous-bash.sh` — **all confirmed ABSENT in the repo** (G1, G15). No
  phantom build.
- It correctly does NOT re-propose `/loop`, `/compound`, `CronCreate`/`schedule` (MASTER §E, §C; these are
  runtime-present) — push-back §4b explicitly leans on `/compound` and the PULL channel rather than new
  tooling. Good.
- **Nuance (not a phantom, but a missed-existing-asset):** the doc treats the plugin marketplace mechanism
  as a thing to stand up, but **a working marketplace + plugin install/update substrate already exists on
  this machine** (`known_marketplaces.json`, `installed_plugins.json`, 2 live plugins). This does not change
  any proposal — `agent-harness` still needs its own marketplace repo — but the doc should cite the live
  substrate as proof-of-mechanism (it currently cites only `capability-facts`). Strengthens §1/§4a at zero
  cost. **Minor; fold into C2.**

### 2. CITATION-INVALID — any change lacking a map-row / disk-path / confirmed-absence? → ONE factual error (C1), one stale citation (C3)
- Every proposal row in §2's manifest and §3a's checklist carries a `[map §N]` / `[tree §N]` / verified-disk
  citation. The discipline is real and mostly accurate (G3, G5, G6, G11–G14 all check out).
- **C1 (factual error in a load-bearing citation):** the doc says `skills-lock.json` is "**6.7 KB**". On disk
  the repo's `skills-lock.json` is **751 bytes**. The 6.7 KB (6715-byte) file is **`~/.agents/.skill-lock.json`**
  — the *global* skills lockfile, a different file. The doc conflated the two. The *substance* survives (the
  751-byte repo file is real, git-tracked, uses SHA-256, tracks the 2 supabase skills as upstream github
  sources — all verified), so the argument that "skills-lock.json is the existing precedent for a
  machine-readable manifest" stands. But the cited size and the implied scale are wrong and must be corrected
  — this is exactly the kind of stale-number that the doc's own §3b manifest is meant to prevent.
- **C3 (stale citation, directionally harmless):** §1/§5 cite `recyclops/logistics-service/.claude` as
  "empty `.claude` [map §8]". On disk there is **no `.claude` dir there at all** — the directory does not
  exist. The CANONICAL map §8 itself carries the stale "empty" claim (it says "empty"; reality is "absent"),
  and the doc inherited it without re-verifying — a violation of the governing "audit artifacts ROT,
  re-verify absence yourself" rule. Directionally it only *strengthens* the greenfield argument (absent is
  even more greenfield than empty), so no proposal changes; but a validation-install target the decision
  package names must be described accurately. Fix to "no `.claude` present (greenfield)."

### 3. TWO-BUDGET VIOLATION — does it sneak net additions in as wins? → NO. This is the cleanest part of the artifact.
- Independent assessment of **budget (1) — agent-context/advisory prose the agent reads each session:**
  The distribution layer adds **zero** budget-(1) files. `plugin.json`, `marketplace.json`, `hooks.json`,
  `harness-manifest.json`, `VERSION`/CHANGELOG are all runtime/CI/human-read, never loaded into the agent's
  session context. I confirmed the analog on the vercel plugin: its `plugin.json`/`hooks.json`/marketplace
  descriptor are runtime-consumed, not prose the agent skims. **Budget (1) genuinely does NOT rise** from
  distribution. The doc's claim that budget (1) is "neutral-to-favorable" (a fresh install inherits the
  safety floor version-pinned instead of re-pasting it) is *plausible but unproven* — there is no second
  install yet to measure the "ships once instead of re-pasted per project" saving. **It is a sound forward
  claim, correctly hedged ("neutral-to-slightly-down"), not an over-claim.** Acceptable.
- **Budget (2) — out-of-band packaging/mechanism:** the doc states **+4 to +5** packaging files
  (`plugin.json`, `marketplace.json`, `hooks/hooks.json`, `harness-manifest.json`, `VERSION`/CHANGELOG) plus
  `gen-manifest.sh`, and reuses the already-counted `scan-context.sh`. Each row in the §0 table names a §9
  failure mode (drift, no-update-channel, guard-file-edit, prose-inventory-rot, no-rollback-target). I tested
  each failure mode for nameability — all five hold (see axis 4). **The doc does NOT present "one plugin" as a
  file-count win** — it explicitly refuses to (§0 last line, §6 last bullet). This is the binding rule honored
  correctly: a budget-(2) increase, each item §9-justified, budget (1) not raised. **No violation.**
- **One understatement to flag (not a violation, the honest direction):** §2's plugin manifest also moves
  2 NEW hooks (`session-end-capture`, `block-dangerous-bash`) and several NEW scripts into the plugin. These
  are already counted in the Phase-3 budget (2) (RECONCILIATION §E: "+2 hooks, +3 CI scripts, +1 generator").
  The doc correctly does not double-count them here, but a reader skimming only §0 might miss that the *total*
  V2 budget-(2) delta is the Phase-3 ~+9–11 PLUS distribution's +4–5 packaging files. **Recommend one
  sentence in §6 cross-referencing RECONCILIATION §E so the decision package sums the two layers' budget (2)
  rather than reading +4–5 as the whole V2 cost.** (C4, minor.)

### 4. §9-OVERHEAD — any added file/mechanism with no nameable failure mode? → NONE survive a challenge
I tried to demote each new file to "overhead":
- `plugin.json` → without it, no version identity → downstream can't pin/update → silent drift [map §0]. **Holds.**
- `marketplace.json` → without it, no install/update channel; degrades to clone-and-copy [capability-facts;
  confirmed live: the platform requires it — `known_marketplaces.json` keys off it]. **Holds.**
- `hooks/hooks.json` → without it, hooks must be wired by editing the downstream guard `settings.json`, which
  the agent is denied [memory: no_agent_edits_guard_files] and which carries permissions. **Holds — and the
  vercel plugin proves this is the production path, not a theory.**
- `harness-manifest.json` → without it, prose-inventory drift (canon ~46 vs disk 26) has no machine check
  [map §3b]. **Holds** — and the existing 751-byte `skills-lock.json` is a working precedent for the shape.
- `VERSION`/CHANGELOG → without it, "which fixes are in this install" is unanswerable; no rollback target.
  **Holds.**
- `gen-manifest.sh` → without it, the manifest is hand-counted and rots like the prose it replaces. **Holds.**

No added mechanism is unjustified. The §9 discipline is met.

### 5. REQUIREMENT-MISS — does it satisfy every requirement for this artifact? → ALL MET
| Requirement | Met? | Evidence |
|---|---|---|
| Vehicle fork decided + defended vs the locked sequence | ✅ | §1: two-vehicle split, recommend YES; defends as honoring the locked SEQUENCE (converge→ship→3-installs→Cursor→npx→UI) while swapping only the v1 *carrier*. The "revising a locked decision" defense names 3 of 4 legitimate-revision conditions. Sound. |
| Plugin-vs-project split as a concrete per-file manifest | ✅ | §2: per-file disposition table (PLUGIN/PROJECT/SPLIT) with citations; plugin repo layout tree. Concrete. |
| Canon↔disk convergence gate specified | ✅ | §3: one-time §3a checklist (9 rows, each cited; 4 spot-checked on disk and correct) + standing §3b machine manifest with 5 CI assertions. Publish blocked on green. |
| PULL path (native via plugin) | ✅ | §4a: `/plugin install @ver`, versioned-copy-with-lock, `next`/`stable` channels, no auto-update. Mechanism confirmed live on disk. |
| Push-back conceptual + wired to Phase 5, not over-built | ✅ | §4b: one `scope: project\|universal` field on the Phase-5 promotion gate NOW; PR-to-`agent-harness` as the channel (no new tooling); automation gated on ≥2 installs. Honors hypothesis-before-speculative-build. |
| Migration path honoring the 3-install gate | ✅ | §5: STEP 0–4; event-vendor dogfood (install #0) explicitly does NOT count toward the gate (condition (1) "no author-copied files"); gate is a STOP not a checkpoint. |
| Plugin settings.json limited to `agent`+`subagentStatusLine` respected | ✅ (with C2 precision) | §2 keeps permissions/autoMode in PROJECT, never in the plugin. Respected. The *justifying wording* is imprecise (real plugins put neither there) but the *constraint is honored more strictly than stated*. |
| Versioned-copy-with-lock not symlink | ✅ | §1 reject-list + §4a; matches MASTER §F and the live `git-subdir`+`ref`+`sha` marketplace format. |
| Two-budget delta reported | ✅ | §0 + §6 report both budgets, refuse the favorable-proxy. Best-disciplined section. |

No requirement is missed.

### 6. CAPABILITY-VIOLATION — does it assume a mechanism can do something the platform can't? → ONE imprecision (C2), no false capability
- The doc does NOT assume a plugin ships a permissions block (it explicitly keeps permissions PROJECT-side).
- It does NOT assume a self-certifying eval or an unforgeable model-written gate — §4a's "no auto-update,
  human reads CHANGELOG" and §4b's "human gate on push-back PR, no auto-push" correctly treat harness changes
  with the same human gate as a destructive op, consistent with the FORGEABLE-stop-authority doctrine
  (_EMERGING-FINDINGS §2). The convergence gate (§3b) is a CI check over a *generated-from-disk* manifest —
  not a model-written artifact — so it is not forgeable. **Good.**
- **C2 (the one imprecision):** the doc inherits capability-facts' phrasing "plugin settings.json =
  `agent`+`subagentStatusLine` only." A real installed plugin's `.claude/settings.json` carries
  `{"enabledPlugins":{}}` and the behavioral wiring lives in `plugin.json` (`commands`/`agents` arrays) and
  `hooks/hooks.json`, not in a settings.json key list. The doc's *conclusion* (plugin can't carry permissions)
  is correct and in fact under-stated; only the mechanism description is loose. Correct the justification to:
  "a plugin delivers hooks via `hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}` and agents/commands via
  `plugin.json`; it ships no permissions block by construction (verified against the live vercel plugin)."

---

## Corrections (apply before this feeds the decision package)

- **C1 [FACTUAL, load-bearing citation].** `skills-lock.json` is **751 bytes**, not 6.7 KB. The 6.7 KB file
  is the *global* `~/.agents/.skill-lock.json` (a different file). Fix the size in the "Re-verified on disk"
  block and §3a row 7. The substantive argument (real, git-tracked, SHA-256, tracks 2 supabase skills, is the
  manifest precedent) is verified and stands.
- **C2 [PRECISION, capability + anti-self-discredit].** Restate the plugin-settings justification from
  "settings.json = `agent`+`subagentStatusLine` only" to the empirically-true mechanism: plugins wire hooks
  via `hooks/hooks.json`+`${CLAUDE_PLUGIN_ROOT}` and register agents/commands via `plugin.json`; they ship no
  permissions block (verified on the live vercel 0.43.0 plugin + the live marketplace/install substrate on
  this machine). This *strengthens* §1 and removes a claim a skeptic could disprove in one `cat`.
- **C3 [STALE CITATION].** `recyclops/logistics-service/.claude` does **not exist** (the map §8 "empty" claim
  is itself stale). Change §1/§5 to "no `.claude` present — fully greenfield." Directionally strengthens the
  install-target argument; just describe the target accurately.
- **C4 [ACCURACY, minor].** (a) §0/§1 list `additionalDirectories` as a top-level `settings.json` key; on
  disk the top-level keys are `env`/`autoMode`/`permissions`/`hooks` only — drop or relocate the claim
  (`additionalDirectories` may live under `permissions`; it is not a separate top-level key). (b) Add one
  sentence in §6 cross-referencing RECONCILIATION §E so the decision package sums the *whole* V2 budget (2)
  = Phase-3 ~+9–11 PLUS distribution +4–5, rather than reading +4–5 as the total.

None of C1–C4 changes a recommendation, a vehicle decision, the seam, the gate, or either update path. They
correct one wrong number, one loose mechanism description, one stale absence, and one summation clarity gap.

---

## What survived the attack (the load-bearing claims that held)
- The seam is **forced, not chosen** — confirmed against a live plugin, strengthened.
- `hooks/hooks.json` wires hooks without touching the downstream guard file — **proven on disk**, not asserted.
- Versioned-copy-with-lock is the platform default — **proven** (live `git-subdir`+`ref`+`sha`, pinned SHAs).
- Convergence-first is non-negotiable and the §3a checklist is accurate where spot-checked (cr-feature gone,
  dep-update empty, autoMode mis-placed, `/cr` desc already aligned).
- Push-back is designed-not-built with a single cheap field — honors hypothesis-before-speculative-build.
- Two-budget reporting is honest: budget (1) does not rise; budget (2) +4–5 each §9-justified; no
  favorable-proxy claim. **This is the most disciplined artifact in the set on the budget axis.**
