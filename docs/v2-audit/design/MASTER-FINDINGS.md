# MASTER FINDINGS — consolidated Phase-2 synthesis (the Phase-3 input)

Built from the 4 cluster aggregations (`cluster-findings-1..4.md`), which consolidated 37 article
pass-3 analyses, each cited to `CANONICAL-HARNESS-AS-IS.md` (`[map §N]`) or a confirmed absence. This
is the deduplicated cross-cluster picture. **Governing rule honored:** every gap cites a map row or a
confirmed absence; everything the articles "propose" that already exists is in the anti-phantom list
(§E), not the gap list.

The pending adversarial anti-duplication gate runs against THIS file (doer≠checker at the decision
level — it also catches cross-cluster duplicate gaps the per-article checkers could not).

---

## A. The spine (every cluster's master theme)

**Enforcement is overwhelmingly advisory.** `[map §3e Net enforcement picture]` — "neither canon nor
disk has a deterministic backstop for the bulk of skill bodies, CLAUDE.md rules, or the autoMode
lists." All four clusters independently make this their center of gravity (C1-CT-A, C2-CT1, C3-CT1,
C4-CT1). Nearly every real gap below is one facet of *converting advisory → deterministic at the right
point in the loop* — and, dually, *deleting advisory scaffold the current model no longer needs*.

A second, quieter spine: **our failures are temporal/authority failures, not missing-mechanism
failures** — a missing clock, a forgeable gate, a rotting audit, an un-measured reviewer, a half-open
loop. The harness is mechanism-rich and wiring-poor. This is why V2 should end with **fewer files and
more wiring**, not more features.

---

## B. The 6 consolidating moves (≈30 cited gaps collapse onto these)

The design (Phases 3–5) is these six structural moves, not thirty features. Each move absorbs a cluster
of cited gaps. This is the "consolidation = success" shape.

### MOVE 1 — Build ONE Stop/PostToolUse hook surface (many payloads, not many features)
Five articles independently reach for the *same missing mechanism* `[map §3e, §5: session-end.sh
ABSENT]`. Payloads it hosts: (a) machine-enforced verification gate at task-completion [C1-G2, C4-G3];
(b) memory write-back / session-end candidate proposer — the *write* half of the compounding loop
[C1-G1, C4-G7]; (c) retry-ceiling counter + REJECT/handoff tier [C1-G3]; (d) render/visual-output gate
[C1-G4, C4-G11]; (e) explicit stop/pace signal [C1-G1]; (f) errors-into-context on tool failure (restored C2-G13 — fits
PostToolUse; the give-up/circuit-breaker half is the (c) retry counter). **Build the surface once; treat
these as emitters.** Constraint (carried from sources): the verification gate buys *regression-trust, not
correctness-trust* — it must NOT write `.cr-ok` or become a capability unlock; the human semantic
checkpoint stays [ramp; notion-spec; map §9]. **Capability reality** (`capability-facts.md`): a
Stop/SubagentStop hook CAN run tests and block-on-red, but **no hook can compel a screenshot artifact** —
so the render-gate payload is "verify-if-present + advisory," not a hard gate; and `session-end.sh` was
*deliberately removed in #70* because its output was discarded — MOVE 1 fixes that by making the emitter's
output land somewhere (MOVE 3 memory + MOVE 6 loop).

### MOVE 2 — Relocate enforcement to deterministic layers (the Three-Layer Enforcement Model)
Canon's own backlog already frames this (`design/canon-locked-decisions.md` §B). Sort every NEVER rule
into **L1 deterministic hook** / **L2 architecture test (dependency-cruiser in CI)** / **L3 judgment**,
and move rules down. Concrete absences this resolves:
- `block-dangerous-bash.sh` — the 3rd structural guard (deploys, `rm -rf`, boundary writes to
  `.git`/`.husky`/`.claude`, destructive SQL, curl-to-non-allowlist). **Most-cited single gap; one
  unified guard, not four.** [C3-G2, C4-G1; map §3e, §5]
- **Relocate the forgeable stop authority to CI** — `.cr-ok` is model-computed and "never verified by
  CI" (Node 8.5c). New stop authority = `MUST-FIX=0 AND CI-required-checks-green on the sentinel SHA`,
  enforced in CI/branch-protection where the model can't forge it. **The most-cited gap of cluster 2.**
  [C2-G1, C3-G9, C4-G3; map §3f, §3c]
- Path/glob classifier that *forces* `/cr-security` on auth/RLS/middleware diffs (today: prose only).
  [C2-G10; map §5 enforce-scope.sh absent]
- Layer-boundary checks (today: advisory `/cr` Pass 4) → deterministic dependency-cruiser tests in CI.
  [canon Three-Layer L2]
- autoMode policy lives in committed `.claude/settings.json`, which the classifier does **not read by
  design** (`capability-facts.md`; docs: "Not read from shared project settings") → unattended runs
  governed by bare defaults *right now*. Correct home = `settings.local.json` (personal) or
  **managed-settings.json** (enforced, agent-unreachable). [C4-G4, gate CITATION-FIX]
- Egress / outbound control for unattended `/queue` — operation-granularity, not destination; the
  prod key is readable, so fetched content + key = injection→exfil. [C4-G2, C4-G10]

### MOVE 3 — Unify the memory model (one writer / one reader / one freshness rule per store)
The Phase-3 crux `[map §4]`. Today: triple-duplication the canon "both sanctions and forbids," a 6th
store (auto-memory) the canon doesn't model, freshness for only 3 of ~14 stores, read-time for ~5 of
14, and the reconciliation living "only in prose, encoded in no tooling." One coherent model that:
accounts for auto-memory; gives every store one writer/reader/freshness; collapses duplication in
*tooling* not prose; adds the absent automated writer (MOVE 1's session-end emitter). Absorbs:
- The drift/context-rot detector (`/scan-context` documented, absent) — must catch **doc-stale AND
  doc-fiction AND decay** (phantom refs are our *live* failure class; the audit itself rotted, map §0).
  No CI check validates any knowledge artifact today. [C3-G3, C3-G10]
- Subtractive enforcement has no home (`/simplify` documented, absent) — the *deletion* half of §9.
  [C3-G7]
- Skill descriptions phrase-keyed (§9 anti-pattern) + 0/26 invocation-control frontmatter; tier by
  *trigger-existence*, not line-count. [C3-G5, C3-G6]

### MOVE 4 — Run the §9 Model Capacity re-audit on Opus 4.8 (the deletion engine + disciplining method)
Not a feature — the **trigger + criterion** for the already-owed, pre-authorized cut `[map §9; §0
headline]` (judgments were made against Sonnet 4.6; re-audit due on a model update → now Opus 4.8).
Rule: **"name a failure mode the constraint prevents, or it's overhead."** Every rule labeled
Deterministic in MOVE 2 must carry a one-line failure mode or be demoted; every phrase-keyed trigger,
option-count proxy, and unobserved-90-day ghost rule is a candidate cut. **This is the engine that makes
V2 SMALLER.** [C1-G5, C2-CT5, C3-CT7, C4 (ai-automation)]

### MOVE 5 — Make the harness installable (converge canon↔disk → GitHub template repo)
The V2-central structural fact: never installed beyond event-vendor; no global `~/.claude/CLAUDE.md`
`[map §0, §2, §8]`. Honor the canon's **locked** sequence (`design/canon-locked-decisions.md` §A):
**converge canon↔disk FIRST**, then ship the `agent-harness` GitHub *template repo* (Claude Code only,
one install path), validate on 3 real installs, *then* add Cursor/npx/UI. Adopt **versioned-copy-with-
lock, NOT symlink-live** (symlinks resolve to HEAD not a validated SHA, recreating the canon's own
install-method contradiction). A machine-readable skill manifest catches the prose-inventory drift.
[C1-G7, C1-G6, C2-G6, C3-G1; Phase 4]

### MOVE 6 — Close the compounding loop (write-back + read-path + measurement), wired into MOVES 1 & 3
Structurally half-open in *both* directions [C4-CT4]: no write-back from runs (session-end absent →
MOVE 1) and no read-path of findings into task-start context (`RECURRING-FINDINGS.md` is "pipeline-only,
never read by implementers" `[map §4]`; the locked-decision corpus isn't wired into `/cr` as criteria).
The precondition both halves need is **measurement** — no eval/golden-set/recall for `/cr`, the
load-bearing-yet-least-tested component (`@benchmark-runner` is a phantom). Build *continuous recall
measurement* (triage calibration, never self-certify; seed with adversarial diffs). [C2-G3, C4-G5,
C4-G8, C2-G4; Phase 5]

---

## C. Gaps that survive but are HYPOTHESIS-GATED or DEFERRED (do not build now)
Per the harness's own "hypothesis-before-speculative-build" rule — register, don't build:
- **Autonomous trigger front-door** (bug→PR; harness can build but can't be summoned). Gated on V2
  deciding autonomy is in scope; building the classifier first is the forbidden speculative build.
  [C4-G6]
- **`/goal` loop primitive** — blocked behind MOVE 2 (CI-verified `.cr-ok`, REJECT tier, bash guard).
  [C2 reject]
- **Scheduler/heartbeat** [C2-G2] — substrate exists (`CronCreate`/`/schedule`/`/loop` already in the
  runtime); gated on a 15-min durability spike (fires when the machine sleeps?).
- **Property-based testing for money-math** [C2-G12] — gated on a `fast-check`×Vitest-4 dependency vet.
- **Full egress firewall** (proxy/pfctl) [C4-G2] — research-gated; the config-level carve-out is the
  now-half.
- **Per-feature spec layer + skill-promotion rung** [C1-G8] — real, but sequence after the memory
  model; must ship an independent review pass + retirement rule.
- **Outcome/impact tracking** [C2-G15], **visual render gate full build** [C1-G4b], **MCP trifecta
  gate** [C3-G11] — registered, scoped small, deferred behind the §9 re-audit / a build decision.

## D. Smaller confirmed gaps (cheap, real, fold into the relevant move)
PII-handling rule for real client data [C1-G9]; governance coherence (accountability rationale,
blast-radius tier, workflow rejected-approaches log, fragmented task object) [C1-G10]; bug-fix TDD has
no *deterministic enforcement* outside pure functions (DOWNGRADE: `/tdd` covers bug fixes advisorily; CLAUDE.md scopes the requirement to `src/data`/`schemas`/`utils`) [C2-G9]; cross-skill reference-integrity + skill-cache staleness guards [C2-G8];
one-agent-one-job scope discipline (roster grew lane-depth not reuse) [C2-G14]; review-bandwidth ≥
generation-bandwidth as a first-class constraint [C2-G11]; upstream Matt-Pocock skill dependency policy
(`/tdd` already forked) + a recurring-upkeep-cost lens on the §5/§6 registers [C4-G12]; `/cr` routing
field splitting NEEDS-HUMAN into needs-design-decision vs must-fix-now [C2-G7]; per-worktree credential
scoping [C4-G10].

---

## E. Anti-phantom list (ALREADY BUILT — never re-propose; the gate enforces this)
Consolidated from all 4 clusters' alreadyDo. A proposal touching any of these must cite why the
*existing* mechanism is insufficient, not propose it fresh.
- **`/cr` 9-pass + 4-lens adversarial review** over the full branch diff; `/cr-security` [map §3c,§3d].
  (More review rigor than any tool the corpus studies. "Add an AI reviewer" = already in-process.)
- **Deterministic commit/push floor:** `block-dangerous-git.sh`, `block-npm-install.sh` (exit 2);
  pre-commit (eslint+tsc+vitest); pre-push (tests+`next build`+`.cr-ok`); CI `ci.yml`+`integration.yml`
  [map §3e,§3f]. The "interleave LLM with deterministic gates" thesis IS our pipeline. (Gap is *timing*
  — commit/push, not task-completion — and *axis* — code-shape, not render/behavior.)
- **Tier-0 prod-key firewall** (`worktree-create.sh`/`gen-local-env.sh`/`test-local.sh`) — a disk
  *advance over canon*; refuses vitest unless URL is 127.0.0.1 [map §3e,§6]. (Credential isolation, not
  environment/devbox isolation — the narrower gap is real.)
- **Worktrees + `/queue` parallel isolation; 23-agent roster** incl. 4 lenses, 6 spike agents, task-
  runner [map §3d,§3e].
- **Six-store memory layer exists** (memory.md, RECURRING-FINDINGS, PITFALLS, solutions, adr, auto-
  memory); freshness for 3 stores [map §4]. Gap is *coherence* (MOVE 3), not existence.
- **`/loop` already exists** (interval poller, runtime skill) — do NOT build `/loop`. **`/compound`
  exists** (near-merge capture). **Ritual layer exists** (`.claude/rituals.md`, 5 rituals) — gap is the
  missing clock, not the layer.
- **CONTEXT.md (15KB, PR#92), STRATEGY.md, ARCHITECTURE.md, AGENTS.md, SOUL.md all present** [map §3a].
- **`claude auto-mode` artifact authored** (rich soft/hard-deny `$defaults`) — *content* done; only its
  *placement* is broken (MOVE 2) [C4 live-check].
- **`permissions.deny` guard-file lockout + "no agent edits to guard files"** standing rule [map §3e].
- **`chrome-devtools-mcp` configured; Playwright explicitly rejected** in `.claude/mcp.md` [verified].
- **PocketOS destructive-op denylist, Two-hats, 3-question pre-commit, tracer-bullet-first** — keep-
  verbatim [map §9]. **Unified skills machinery** (no `.claude/commands/`; 25/26 have frontmatter).
- **The §9 golden rule + selective-friction doctrine** already ours (predates the articles).

## F. Reject-as-literal (consolidated — these become the Rejected List in the decision package)
- **Front-load trigger-words into descriptions** / **shrink root to 200 lines** — the §9 anti-pattern
  and a line-count fetish; the principle is *situational triggers* + *tier-by-trigger-existence*.
- **Build `learned-patterns.md`** (×3 articles) — confirmed phantom [map §6]; the gap is a *read-path*,
  not a file; monotonic stores with no eviction collide with §9 decay.
- **Import the ROI/recall numbers** (80% self-written, 1,300 PRs/wk, 16.6%/1-in-5, 5x/2.5x, 91%, Faros
  154%/9%/91%, MCPTox 60-72%) — single-source/uncontrolled/self-disowned; adopt mechanisms, never rates.
- **Dev-container/VM/microVM/gVisor/token-proxy stack** — wrong threat model at solo scale; container-
  escape caused none of the documented incidents. Residue = "allowlist operations not destinations,
  enforce off the model."
- **"No shared context" for the adversarial reviewer** — would blind it to Rejected Patterns/ADRs;
  correct design = *shared project canon, isolated solution context*, same model.
- **Collapse 23 agents → skills / "hundreds→one"** — a threshold claim (real at hundreds) sold as
  universal; at ~8–23 specialists are clarity. Real gap = taxonomy reconciliation, not a pivot. (But
  leland P4's *reuse over lane-depth* direction is valid for future growth.)
- **Symlink-live install** — resolves to HEAD not a SHA; use versioned-copy-with-lock.
- **Paste autoMode block into settings.json by the agent** — forbidden (no agent edits to guard files);
  prepare + verify + surface paste-ready for a human.
- **Adopt Playwright MCP / spec-with-implementer-self-verification / target `/cr-feature` (retired) /
  `/change` (phantom) / auto-merge-on-confidence-score / demo-velocity metric / CLI-first-for-everything
  / cost-margin gates / "frameworks are evil"** — each rejected with reason in the cluster files.

## G. Bounded capability checks (Phase 2b — NOT research projects; several are "run the binary on disk")
1. **What a Claude Code Stop/PostToolUse hook can intercept/block at task-completion** — make-or-break
   for MOVES 1–2 (can it see "subtask done," run tests, block on red, require a screenshot artifact,
   without writing `.cr-ok`?). Check harness/`claude-api` hook docs. [C1-FR2, C2-FR1, C4]
2. **Agent Skills frontmatter schema** — exact field names (`disable-model-invocation`/`user-invocable`/
   `allowed-tools`?) before writing any (MOVE 2/3). ~10-min spec check. [C3-FR, commands-vs-skills+zapier]
3. **autoMode honored in `.claude/settings.local.json`?** + **default `/queue` egress profile** +
   **`chrome-devtools-mcp` headless in UNATTENDED?** + **host `managed-settings.json` honored on native
   macOS?** — each is one command/one session against the machine. [C4-FR4, FR5]
4. **Scheduler durability** (`CronCreate` fires when machine sleeps?) — 15-min spike, gated on MOVE/heartbeat.
5. **`fast-check` × Vitest 4** dependency vet — gated on the PBT decision.
6. **AI-reviewer eval methodology** (how teams measure a reviewer got worse after a model swap) — the one
   genuinely-external thread, gated on building the eval harness (MOVE 6). Short pass, not a deep dive.
7. **Claude Code hard limits** (CLAUDE.md char cap, read limit) — falsifiable platform facts; informs
   MOVE 3 tiering.

---

## H. What this means for the decision brief (the real forks for Tanner)
Most questions are resolved by evidence above. The genuine forks that remain (to be sharpened in Phase 6):
1. **Distribution vehicle: GitHub *template repo* (canon-locked) vs. Claude Code *plugin + marketplace*
   (Tanner's 2026-06-11 nudge — "easily added with npx").** Capability-facts confirm the plugin route is
   the *native, current* mechanism: a marketplace.json on a git repo, `/plugin install`, **ships hooks +
   skills + agents + MCP**, and is **version-pinned + `/plugin update`** — so it ALSO supplies the
   Phase-4/5 "pull updates down" path the template plan explicitly defers. Caveat: a plugin's settings.json
   carries only `agent`+`subagentStatusLine` (permissions stay project/managed), and the canon's locked
   plan (2026-05-18) predates plugin-marketplace maturity. **Recommendation leaning: plugin+marketplace for
   the behavioral harness (skills/agents/hooks) + a thin template/`init` for the project-owned files
   (CLAUDE.md/AGENTS.md/CONTEXT.md/settings permissions) — converge canon↔disk first either way.** This is
   now the central Phase-4 fork, and it folds in the old "self-update now vs. defer" question (plugins make
   pull-update native; push-back-up stays a compounding-loop design, MOVE 6).
2. **Is the autonomous trigger front-door in V2 scope?** — gates a whole cluster (C4-G6, `/goal`,
   scheduler). Hypothesis-gated.
3. **How far does MOVE 4 (the deletion engine) cut?** — the §9 keep-verbatim floor is the boundary;
   how aggressively to prune skills/agents/rules is a judgment with blast radius.
4. **Memory model shape** (MOVE 3) — the single biggest design decision; needs the concrete model.
5. **Eval/measurement investment** (MOVE 6) — build the golden-set harness now, or defer behind installs?
These five + ~1–3 that Phase 3 design surfaces = the ~4–8 decision brief.
