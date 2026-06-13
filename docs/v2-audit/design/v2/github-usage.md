# V2 GitHub-Usage Design — Canon · Plugin · Channels · The Un-fakeable Gate · Push-back · Observability

> **What this artifact is.** The concrete design for *how V2 uses GitHub*: as the single source of truth (canon
> migrated off Notion), as the distribution channel (plugin + marketplace), as the trigger front door (L1), as the
> **un-fakeable CI gate** that makes the review verdict real (F6 — the keystone), as the cross-repo push-back loop
> (P8/P9), and as the observability surface (L7). Every item cites a ground-truth row (§N in
> `../../CANONICAL-HARNESS-AS-IS.md`) or a confirmed absence re-verified on disk this session, and names the
> **failure mode** it prevents — the charter rigor (doer≠checker, no phantom rebuilds, cite or confirm-absent).
>
> **Charter posture.** World-class only; autonomy first-class; clarity beats minimalism (more files are fine when
> each earns its place). This is the *distribution + enforcement spine* of the five-pillar vision
> (`../ambition/VISION.md` pillars 1 + 5). The conservative baseline (`../../DECISION-PACKAGE.md §4e`) is sound on
> mechanics — its two-vehicle split, its "convergence = `git diff`" framing, its "27-byte proof" are carried
> forward verbatim — but its minimalism is *not* re-anchored: where the baseline defers (push-back automation,
> cross-repo loop, the verdict-artifact surface), this design specifies the world-class form and gates it on a
> named flip-trigger rather than dropping it.

---

## 0. Why GitHub at all — the one-paragraph thesis

Today the harness has **three layers that disagree** (§0): a Notion canon (the design target, ahead on doctrine), a
project disk (the only place the rich harness runs), and a near-empty global layer. The source of truth is a Notion
page a cloud agent **cannot reliably read or write** (the WAF blocks on security content — auto-memory
`feedback_notion_write_waf_block`), it lives in a *different system* than the artifact it ships (guaranteeing
forever-drift — §7 lists nine canon-internal contradictions), and the install mechanism is "reconstruct from a Notion
page" (§8: the harness has **never been installed anywhere but event-vendor**). The harness's deepest asset — its
`/cr` verdict — dies in a **gitignored `.cr-ok`** that **never reaches CI** (§3f; `.gitignore:58` verified this
session), so the loop grades its own homework and a cloud agent cannot even read whether review happened. **GitHub
fixes all four at once:** it is the system a cloud `/schedule` agent can read/write, it co-locates canon with the
artifact (convergence becomes a `git diff` — the publish gate), it is the native distribution + update channel
(plugin + marketplace), and it is the one place a CI required-check can re-verify the verdict on the exact shipped
SHA where the loop **cannot forge it**. This artifact is how V2 *uses* GitHub to become a distributable, self-gating,
fleet-scale harness.

---

## 1. GitHub as canon — the Notion → GitHub migration (P3)

**Move:** P3 (VISION pillar 5). **Tag:** P0 for the source-of-truth move; the migration content-half *is* the
convergence work. **Cite:** RESOLVED FACTS; §0, §7; `compound/SKILL.md:108` (Step 8); `.claude/skills/notion-sync/`
present on disk (verified this session).

**The failure mode it prevents.** A distributed harness whose source of truth a cloud agent cannot reliably
read/write (Notion WAF blocks on security terminology) and that lives in a different system than the artifact it
ships — *guaranteeing forever-drift*. The proof is on disk: §7 enumerates **nine canon-internal contradictions** (two
feature loops, two reviewer names, Pages 12↔13 conflicting), and the audit that produced this very file was caught
**rotting mid-run** (shipped four false absence-claims — `DECISION-PACKAGE §6.3`). Canon-in-Notion is a *live*
drift-generator, not a hypothetical one.

**What moves, where it lands.**

| Notion artifact (today) | GitHub home (V2) | Form |
|---|---|---|
| AI-Native Engineering System (15 numbered Reference pages, §1) | `agent-harness/docs/canon/` | Git Markdown, one file per reference page |
| Changelog (→v1.1) — `compound` Step 8 writes here (`compound/SKILL.md:116`) | `agent-harness/CHANGELOG.md` | conventional-changelog, version tags = git tags |
| Templates / Setup Prompts / Quick-Start | `agent-harness/docs/canon/templates/` + the `/init` skill (P2) | the setup-page-reconstruction is **replaced** by `/init` |
| Incidents / To-Think-About backlog | `agent-harness` GitHub Issues (labeled `incident` / `backlog`) | issues, not pages — queryable, linkable to PRs |
| `settings.json` template subpage (`compound/SKILL.md:120`) | `agent-harness/docs/canon/settings-template.md` + `/init` materializer | content committed; placement is a human/`/init` step (§3a, never committed project settings) |

**The four re-points (the migration's enforcement half):**

1. **`/compound` Step 8 re-pointed to GitHub.** Today Step 8 ("Notion AI engineering system update",
   `compound/SKILL.md:108-120`) opens the Notion Changelog page and adds a versioned subpage. V2 re-points it to
   *commit the canon delta to `agent-harness/docs/canon/` + append `CHANGELOG.md`*, opened as a PR. The
   transferable mechanisms of `/notion-sync` are **carried forward, not lost** (VISION P3): the
   comprehensive-diff-over-changelog discipline, the guard-file exception, the dedicated-branch rule, the LAST-SYNC
   receipt, and the sentinel handoff — they become the shape of the canon-PR, not Notion-write mechanics.
2. **`/notion-sync` removed as a ritual.** The skill (`.claude/skills/notion-sync/SKILL.md`, 11 KB, present on disk)
   is retired. *Failure mode prevented by removal:* keeping a ritual that writes to a WAF-blocked, drift-prone,
   cloud-agent-hostile store is keeping the forever-drift generator alive. (Memory `feedback_capture_process_decisions`
   and `feedback_compound_evaluation_scope` note that `/compound` *drives* the canonical sync — so the driver moves to
   Step-8-to-GitHub, the sync target changes, the discipline survives.)
3. **GitHub becomes the single source of truth.** The canon's own backlog already states this is the goal:
   "GitHub Publishing — *in progress (agent-harness migration); next gate: 3 real installs*" (§8, To-Think-About #20).
   V2 closes it: `agent-harness` Markdown is canonical; Notion is decommissioned (or downgraded to a read-only mirror
   if the human still wants page-browsing — but it is **never** a writer).
4. **Convergence becomes a `git diff` — the publish gate.** Once canon and the shipping artifact are *both* Git, the
   canon↔disk convergence the whole distribution rides on (§0: "bidirectional drift") stops being a manual
   cross-system reconciliation and becomes a mechanical diff between `agent-harness/docs/canon/` and the live
   `.claude/` tree. A generated `harness-manifest.json` (P6) is the diff's machine-checkable input; `scan-context`
   (CMP4) is the checker. **Convergence blocks plugin *extraction* only — not the safety/enforcement/measurement
   work, which runs in parallel** (`DECISION-PACKAGE §4e`, a sequencing-lens correction carried forward verbatim).

**Fork it rides (F10 — convergence scope as the publish gate).** Resolve all nine §7 contradictions before first
publish, **or** publish from a declared-precedence (`supersedes:`) snapshot and resolve lazily — trading
first-publish latency against shipping a known-imperfect canon. *Recommendation surfaced, not resolved:* publish from
a `supersedes:`-declared snapshot (the out-of-loop human anchor P9 already requires) so the migration is not held
hostage to a nine-contradiction cleanup; resolve the nine lazily as the cross-repo loop (P9) opens tickets. **This is
Tanner's call (F10).**

---

## 2. Plugin install + update — the pull path (P1 + P2)

**Move:** P1 (plugin + marketplace) + P2 (the thin `/init` template). **Tag:** P1, built *after* canon↔disk
convergence (the publish gate); the manifest schema (P6) is committed now. **Cite:** RESOLVED FACT; confirmed absence
— §8, §3a; `capability-facts.md:56-71` (plugin/marketplace capability); the 27-byte proof
(`DECISION-PACKAGE §4e`, capability-facts.md:59-60).

**The failure mode it prevents.** *Template-copy drift.* When every repo holds a hand-copied `.claude/` folder (or a
symlink that resolves to HEAD), they silently diverge and **nothing updates them** — exactly today's state (§8:
recyclops has a one-line allowlist; logistics-service is empty; "multi-project is a goal, not a state"). A second
failure mode P2 prevents: a fresh install where the plugin lands but the repo runs **bare-default permissions and
bare-default auto-mode** — the safety classifier the whole autonomy program rides on, effectively off.

**The pull path — three native mechanisms (`capability-facts.md:61-64`):**

```
agent-harness repo
├── .claude-plugin/marketplace.json     ← the descriptor (NEW; ABSENT today — verified)
├── plugin/
│   ├── hooks/hooks.json                 ← wires the Stop/PreToolUse hooks WITHOUT touching the downstream guard file
│   ├── skills/                          ← the portable ~23-skill roster (P10, after prune+dedup)
│   ├── agents/                          ← the 23-agent roster (P10, after the phantom-prune)
│   ├── .mcp.json                        ← P4's MCP-as-substrate endpoints
│   └── settings.json                    ← LIMITED to agent + subagentStatusLine keys ONLY (the 27-byte proof)
└── docs/canon/                          ← the migrated canon (§1) — the publish-gate diff target
```

1. **`/plugin marketplace add <agent-harness git-url>`** then **`/plugin install agent-harness`** — install via git
   (npm / local-path also supported, `capability-facts.md:64`).
2. **`/plugin update`** is the **native pull path** — version-pinned, release-channel-aware, holds a lock
   (`capability-facts.md:63`). An improvement merged to `agent-harness` reaches every installed repo via
   `/plugin update agent-harness@1.2.0` — a *validated SHA, not symlink-live* (a symlink resolves to HEAD and
   re-creates the drift it is meant to prevent — `DECISION-PACKAGE §4e`, UPHELD-CUT in VISION).
3. **Version pin + lock** — `/plugin install agent-harness@1.2.0` pins; the lock survives the next session. This is
   how the fleet stays coherent: a repo runs the version it pinned until a human (or P8's push-back) bumps it.

**The 27-byte proof (the seam the design is forced onto).** A plugin's `settings.json` carries **only**
`agent` + `subagentStatusLine` keys (`capability-facts.md:59-60`) — the live vercel 0.43.0 plugin ships a
**27-byte settings.json with zero permissions**. So a plugin **physically cannot carry `permissions` or `autoMode`**.
This is not a limitation to route around — it is *why P2 exists.*

**P2 — the thin `/init` template, for what a plugin CAN'T carry.** A `/init` skill materializes the per-repo files the
plugin physically cannot deliver, from a committed canonical template:

- `CLAUDE.md` / `AGENTS.md` skeletons (with `[TODO]` placeholders for project specifics).
- The `permissions.allow` / `permissions.deny` baseline — **including the guard-file lockout** (a
  TRULY-WORLD-CLASS item: deny agent writes to `settings.json` / `settings.local.json` / `.claude/hooks/**`, per
  auto-memory `feedback_no_agent_edits_guard_files`).
- The auto-mode policy — materialized into **`settings.local.json` (personal) or `managed-settings.json`
  (enforced), NEVER committed project settings**. *Why never committed:* `capability-facts.md:42-46` proves the
  classifier **ignores `autoMode` in committed project `settings.json` by design** — the exact inert-config bug live
  on disk today (the autoMode block sits in `.claude/settings.json:6-32`, ignored at runtime). The committed template
  carries the *content*; a human or `/init` *places* it locally.

**The no-self-edit boundary holds.** `/init` itself is an F9 `disable-model-invocation:true` skill (it mutates
guard-adjacent files); the agent *prepares* paste-ready content, the **human applies** guard-file/settings changes
(auto-memory `feedback_no_agent_edits_guard_files`, `feedback_full_hook_script_on_fix`: surface the complete file to
paste, never a diff). This is the same handoff already disciplined in V1 — V2 just gives it a materializer.

---

## 3. Channels — how a bug becomes a summoned agent (L1)

**Move:** L1 (VISION pillar 1, the trigger front-door trifecta) wired through P4 (MCP-as-substrate). **Tag:** P0-spine
— **GitHub label first**, Slack/CI-self-heal after F5 + F3. **Cite:** confirmed absence — §3e (only triggers on disk
fire on human actions — `session-start.sh`, rituals at session start); elevated by `bug-to-pr-automation.md`,
`stripe-minions-kaliski.md`.

**The failure mode it prevents.** The engineer stays the **per-repo dispatcher** — the exact ceiling autonomy exists
to lift. Today *every* trigger fires only when a human starts a session (§3e: rituals "fire only at session start," no
cron, no webhook). No bug summons an agent on its own.

### 3a. The trigger trifecta (each routed to the right subsystem)

| Channel | What fires it | Free-text injection surface? | Ships | Routes into |
|---|---|---|---|---|
| **GitHub `fix-me` label** | a human (or a monitor) labels an issue | **No** — a label is a controlled token, not attacker text | **FIRST** | classifier → `/incident`→`/hotfix` (L6) **or** `/feature` |
| **Slack / Linear `/fix` summon** | someone types `/fix` where the bug is reported | **Yes** — ingests attacker-controllable issue text | After F5 + F3 | same router; F5 trifecta-gates the untrusted-content leg |
| **CI-failure self-heal** | a required check goes red on a branch | **Yes** — failure logs may carry injected content | After F5 + F3 | transient-vs-permanent triage → L6 incident path |

**Why the label trigger ships first (the ordering carve-out — VISION L1, coherence-check T2-2).** A `fix-me` label
carries **no attacker-controllable free-text**, so it is safe *before* F3 (egress allowlist) and F8 (fleet circuit
breaker) land. The Slack/Linear summon and CI-self-heal ingest attacker-controllable issue text — *the canonical
prompt-injection surface* — so they wait for F5 (the MCP lethal-trifecta gate) + F3 (egress). The label trigger needs
only the **minimal floor {F1, F2, F6, F7, F9}** — not F5 — to be safe.

**L1 must name which downstream path each trigger takes (coherence-check T1-3).** A `fix-me` label or a CI-red is
*often an incident*, not a feature — it routes into the **L6 incident subsystem** (`/incident`→route→`/hotfix`→
`@hotfix-guard`→PR), where the `.claude/incident-[slug].md` triage doc travels to the receiving skill and replaces
its orient step, and a **security signal triggers an isolation-only short-circuit (never auto-fix)**. Flattening every
trigger into `/feature` would silently lose the routed production-incident state machine — which *is* the canonical
bug→reviewed-PR loop the charter centers on. The classifier on the front door decides: incident-class → L6;
feature-class → the feature loop.

### 3b. The mechanism — a GitHub Action on the label, P4 as the summon substrate

```
issue gets `fix-me` label
        │
        ▼
.github/workflows/summon.yml  (GitHub Action — NEW; ABSENT today, §3e)
        │   on: issues: { types: [labeled] }, if: label == 'fix-me'
        ▼
P4 MCP-as-substrate entry point  ──►  the existing worktree shell
        │  (RemoteTrigger-style inbound event → scripts/worktree-add.sh)
        ▼
classifier → /incident→/hotfix (L6)  OR  /feature
        │
        ▼
worktree → work → /cr → F6 verdict → scripts/pr.sh  ──►  opened PR
```

**P4 is the distribution half of L1** (VISION P4, P0-spine, built in lockstep with L1): today the harness is purely an
MCP *client*, driveable only by a human at a prompt; P4 exposes externally-summonable endpoints so an inbound GitHub
event routes into the existing shell. The side-effecting tail (open-PR, deploy) is gated by **F9**
(`disable-model-invocation`); the run pairs with cloud `/schedule` so it fires **laptop-closed**; it ships with the
structural review contract (fixed PR template, test-count floor, blast-radius classifier — L1). Cloud `/schedule`
already runs committed skills, so durability is moot (VISION P4).

**Fork it rides (F3 — which trigger surface ships first).** The vision recommends **label-first** (lowest credential
surface, no free-text injection); Slack/Linear adds a connector-credential surface (F5 must account for it); CI
self-heal needs transient-vs-permanent triage. *Recommendation surfaced:* confirm label-first. **Tanner's call (F3).**

---

## 4. The un-fakeable CI gate — F6, the keystone

**Move:** F6 (VISION pillar 2, **the keystone**; merged with C1 — one CI workstream, two faces). **Tag:** P0-floor;
hard prerequisite for any unattended push. **Cite:** §3f lines 229-231 (Node 8.5(c): "CI never verifies `.cr-ok`");
`.gitignore:58` (`.claude/.cr-ok` gitignored — verified this session); `scripts/pr.sh` (sentinel parse-and-consume,
read this session); `.github/workflows/ci.yml` (the existing tsc/eslint/test lane, read this session). Elevated by
`recursive-self-improvement.md` Move 1, `coderabbit.md` Move 1.

### 4a. The failure mode it prevents (and the V1 contrast)

Today the loop's own model passes agree on zero MUST-FIX, write `.cr-ok`, and push — **the thing being graded
computes its own passing grade** — and that sentinel is **gitignored** (`.gitignore:58`) so it **never reaches CI**
(§3f). `scripts/pr.sh` validates `branch:sha` *locally* and *consumes* the file; CI (`ci.yml`) runs
`tsc`/`eslint`/`test:unit` but has **no knowledge the review ever happened**. Once a human leaves the merge path, this
forgeable gate is the only thing between "the model agreed with itself" and "shipped to main." **V1's verdict is
local, gitignored, never in CI, and forgeable.**

### 4b. The deliverable — one workstream, two faces (F6 = F6 + C1 merged)

**(enforcement face) — the un-fakeable gate.** A CI job (`.github/workflows/cr-gate.yml`, NEW) that:

1. **Parses `branch:sha`** from the verdict artifact (the `.cr-ok` content shape `pr.sh` already produces —
   `${BRANCH}:${HEAD_SHA}`, read this session).
2. **FAILS unless** `sentinel_sha == head_sha` **AND** all required checks (`tsc`, `eslint`, `test:unit`,
   integration) are green. Sentinel-SHA-mismatch ⇒ stale review (commits added after `/cr`) ⇒ **fail**.
3. **Made required via branch protection** on `main` — so the gate is the actual boundary, not advice. The loop
   **cannot forge it**: the sentinel must come from a *committed/queryable* artifact (the surface face below), not a
   gitignored local file the model writes and reads itself.

**The keystone relocation:** `.cr-ok` survives as the **readiness** signal (the local "I ran `/cr`" flag `pr.sh`
checks); the **CI gate is the enforceable boundary**. The doctrine rename is **cross-MODEL → cross-AUTHORITY**: the
generator and the reviewer can share a model, but the *authority* that certifies shipping is CI on a sentinel'd SHA —
a different authority than the loop. **F6 owns this one boundary; C7, LOOP-7, and the `/verify` gate (C8) are
*consumers* of it, never parallel implementations** (VISION F6).

**(surface face) — the verdict as a queryable GitHub artifact.** `/cr` writes its full verdict (MUST-FIX-resolved,
NEEDS-HUMAN, SUGGESTION, REJECT, RECURRING-FINDINGS delta, lens findings) to a **structured artifact** that
`scripts/pr.sh` posts to the PR. *Why this matters for autonomy:* a cloud agent (LOOP-7's classifier, P9's
repair-worker) can **read whether review happened and what it found** — impossible today (the verdict dies in a
gitignored file). The surface is what makes the verdict *queryable*; the enforcement face is what makes it
*unforgeable*.

### 4c. The crucial design point — the sentinel must reach CI

The single change that converts V1's forgeable gate into V2's un-fakeable one: **the verdict artifact must be
something CI can read.** That rules out the current gitignored `.cr-ok` (`.gitignore:58`). The artifact must live
where both branch-protection CI and a cloud agent can query it — which is exactly **Fork F1**.

**Fork it rides (F1 — verdict artifact surface).** PR comment vs PR body vs a committed `review/<sha>.json` file vs
the **GitHub Checks API**. Constraint: must be **queryable by a cloud agent AND enforceable by CI**. *Recommendation
surfaced, not resolved:* the **GitHub Checks API** (a first-class `cr-gate` check run, posted by `pr.sh`/the Action)
satisfies both natively — it is a required check (branch protection enforces it) and is queryable via `gh api`
without parsing PR prose; a committed `review/<sha>.json` is the fallback if Checks-API write scope is undesirable.
**This is Tanner's call (F1); it also affects C7 and LOOP-7.**

---

## 5. Push-back-up + the cross-repo loop (P8 + P9)

**Moves:** P8 (push-back-up promotion gate) + P9 (cross-repo context-maintenance loop). **Cite:** confirmed absence —
§8 (the harness has never been installed beyond event-vendor); elevated by `harness-engineering-survey.md` (P8),
`basis-canon-not-canon.md` / `basis-monorepo-deep.md` / `packmind.md` / `harness-io.md` (P9).

### 5a. P8 — the promotion gate that flows improvements upstream

**The failure mode it prevents.** When a fleet runs across 5+ repos, an improvement made in one repo **never reaches
the others** without a path back up — the 5 repos drift *apart*, each accreting local improvements the others never
see.

**The mechanism — one field + a human-gated PR + the existing pull path:**

```
a repo's /compound promotes a learned pattern
        │
        ▼
promotion gate (the P6 manifest) reads:  scope: project | universal
        │
        ├─ project   → stays local (this repo's .claude/rules/, docs/solutions/)
        │
        └─ universal → opens a HUMAN-GATED PR against the agent-harness plugin repo
                              │
                              ▼  (merged by a human)
                       /plugin update  carries it DOWN to every installed repo (§2)
```

- **`scope: project|universal`** is a single field on the promotion gate (the P6 `harness-manifest.json`) — designed
  *now*, not speculatively built. A `universal` change opens a **human-gated PR** against `agent-harness`; the
  automation is gated.
- **The pull path closes the ring.** `/plugin update` (§2) is how an upstream-merged universal change reaches the
  fleet — push-back-up and the pull path are the **same loop's two halves**.

**Fork / flip-trigger.** P8's **human-gated PR path is P1 (build now)**; the **automation is GATED** on the
flip-trigger **"a 2nd repo installs the plugin"** (VISION P8; `DECISION-PACKAGE §4e`: "there's nothing to push *to*
until a second project exists" — hypothesis-before-speculative-build, auto-memory
`feedback_hypothesis_before_speculative_build`). Until then: one field + a human-gated PR, no automation.

### 5b. P9 — the cross-repo self-improving context loop (CMP4 on a cloud clock)

**The failure mode it prevents.** Undetected **context rot** at fleet scale: a human reads a slightly-stale doc and
shrugs; an agent re-onboards from it *thousands of times* and reasons wrongly with full confidence. The harness has a
**live, dated proof** — this very audit rotted and shipped four false claims (§7; `DECISION-PACKAGE §6.3`).

**The mechanism — three legs in dependency order (P9 = CMP4 run on a clock, across the fleet):**

1. **A CI check on every merge** (P0 — detection) — validates every knowledge artifact: frontmatter present, `owner`
   set, prose instructional not descriptive, **no broken cross-refs** (the reference-integrity check — our canon cites
   five phantom artifacts today, §6: `learned-patterns.md`, `review-log.md`, `triage-inbox.md`, `@benchmark-runner`,
   `/scan-context`). This is the GitHub-resident half of CMP4's `scan-context.sh`.
2. **A scheduled scanner** (P0 — detection) — a cloud `/schedule` routine opening **GitHub Issues** for
   stale / fiction / contradiction / duplication / decay, *across the fleet*, in dependency order. P9's
   `scan-context` cloud routine is **detection now** (the CI check + the scheduled scanner).
3. **The repair worker** (P1 — GATED on Fork F7) — opens scoped, `/cr`-gated, **human-merged** fix PRs. Safety
   designed in: a declared `owner` + a machine-checkable `supersedes:` / `version:` precedence schema (the
   out-of-loop human anchor that stops the loop eating its own tail), and the worker **denied write access to guard
   files / settings / the destructive-op floor** (E #9 as the worker's path-scope denylist — consistent with
   auto-memory `feedback_no_agent_edits_guard_files`).

**Fork it rides (F7 — repair-worker aggressiveness).** Does a context-repair worker get a deterministic
**auto-delete lane for pure-fiction refs** (provably absent on disk) while *gating* staleness demotions to
NEEDS-HUMAN? The line between "self-correcting" and "self-modifying." **Detection (legs 1+2) is P0 and ungated; the
repair-worker (leg 3) is P1, gated on F7.** Tanner's call.

---

## 6. Observability — the agent-PR log + the narration channel (L7)

**Move:** L7 (VISION pillar 1, the narration / legibility channel — Tanner design input, 2026-06-11). **Tag:**
P0-spine — co-ships with L1/L4. **Cite:** confirmed absence — no narration/notification sink in §3e–§3f;
`permission-logger.sh` (§3e disk-only) logs **permission calls, not run progress or PR outcomes**. Elevated by
`bug-to-pr-automation.md` (Slack-channel-as-agent-PR-log), `shopify-ai-first.md` (session-end review artifact).

**The failure mode it prevents.** An autonomous run that only reports at the end leaves the operator **blind during
the run** — a confidently-wrong long run isn't visible until it's expensive to unwind; the operator can't
course-correct and can't safely let the fleet run unattended. *A fleet across 5+ repos is illegible without it.*

**Two surfaces, both GitHub-anchored:**

1. **The agent-PR observability log (append-only forensic feed).** Promote `permission-logger.sh` (today logs
   permission calls only — §3e) into an **append-only feed of every autonomous action**: trigger fired, PR opened +
   link, risk tier (LOOP-7's LOW/MEDIUM/HIGH), auto-approved-vs-escalated, F6 verdict outcome. On GitHub this is the
   PR itself as the unit of record — every autonomous PR carries the verdict artifact (§4b surface face) + a
   structured comment trail — plus a roll-up the cloud `/schedule` job appends to (`agent-harness/docs/observability/`
   or a GitHub Project). **The log is the prerequisite for safe auto-approval (LOOP-7).**
2. **The continuous narration stream.** Every long autonomous primitive (`/goal`, `/lfg`, the L1 front door, cloud
   routines) emits a short human-readable status after each milestone (just-finished / running-now / next /
   waiting-on) to **wherever the human watches** — the human-paging surface of **Fork F9**. **The narration is the
   prerequisite for trusting the fleet at all.** (Dogfooded in the session that authored the vision — those check-ins
   *were* the feature.)

**Fork it rides (F9 — human-paging surface: Slack, Linear, or GitHub?).** This surface is **shared** by L7's
observability/narration, the L1 Slack summon, and every F7/F8 escalation — and it is a connector-credential surface
**F5 must account for** (a Slack/Linear connector adds the untrusted-content + egress legs of the lethal trifecta).
*Recommendation surfaced:* if **GitHub** is the paging surface, L7 rides entirely on the canon/CI/PR substrate this
artifact already builds — **no new connector-credential surface, no new F5 leg** — at the cost of less push-style
immediacy than Slack. Slack/Linear buys immediacy at the cost of a connector F5 must gate. **This is Tanner's call
(F9); it affects L1, L7, F5, F7, F8.**

---

## 7. How the GitHub surfaces compose — one diagram

```
                          ┌─────────────────── agent-harness repo (GitHub = CANON, §1) ───────────────────┐
                          │  docs/canon/  ·  CHANGELOG.md  ·  marketplace.json  ·  plugin/{hooks,skills,   │
                          │  agents,.mcp.json,settings.json(27B)}  ·  harness-manifest.json (P6)           │
                          └───────────────┬──────────────────────────────────────────┬───────────────────┘
                  /plugin install/update  │  (PULL, §2)                  human-gated  │  (PUSH-BACK-UP, §5a)
                          ▼               │                              universal PR │
   ┌──────────────── a fleet repo (event-vendor, recyclops, …) ─────────┴────────────┴──────┐
   │                                                                                          │
   │   L1 trigger (fix-me label → summon.yml → P4 → worktree)  ──►  /incident|/feature        │
   │        │                                                                                 │
   │        ▼                                                                                 │
   │   work → /cr  ──writes──►  verdict artifact (queryable, §4b surface)                     │
   │        │                          │                                                      │
   │        ▼                          ▼                                                      │
   │   scripts/pr.sh (consumes .cr-ok readiness)  ──►  cr-gate.yml (F6 enforcement, §4b):     │
   │                                                   FAIL unless sentinel-SHA==head-SHA      │
   │                                                   AND required checks green  ◄─ branch    │
   │                                                                                protection │
   │   L7: every autonomous action → PR + observability log + narration stream (§6) ──► F9     │
   │   P9: scan-context CI check (every merge) + scheduled scanner (issues) + repair-worker    │
   └──────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. The forks this artifact surfaces (Tanner's calls — do not resolve unilaterally)

| Fork | The decision | This artifact's recommendation (surfaced, NOT resolved) | Affects |
|---|---|---|---|
| **F1** | Verdict artifact surface | **GitHub Checks API** (required + queryable natively); committed `review/<sha>.json` as fallback | F6 §4, C7, LOOP-7 |
| **F3** | Which trigger ships first | **GitHub label** (no free-text injection; minimal floor only) | L1 §3, F5, F3-egress |
| **F7** | Repair-worker aggressiveness | **Detection ungated (P0); repair-worker auto-delete pure-fiction only, gate staleness to NEEDS-HUMAN** | P9 §5b, CMP4, CMP6 |
| **F9** | Human-paging surface | **GitHub** (adds no connector-credential / F5 leg) vs Slack/Linear (immediacy, +connector) | L1, L7 §6, F5, F7, F8 |
| **F10** | Convergence scope = publish gate | **Publish from a `supersedes:`-declared snapshot; resolve nine §7 contradictions lazily** | P1, P3 §1, P9 |
| **F11** | Marketplace hosting + `/init` depth | (surfaced for completeness — private `agent-harness` marketplace; `/init` lays the safety floor, not an opinionated full scaffold that ships event-vendor assumptions) | P1, P2 §2, P8 |

---

## 9. Honest limits — what this artifact does NOT claim

- **No phantom rebuilds.** `summon.yml`, `cr-gate.yml`, `marketplace.json`, the migrated `docs/canon/`, the
  observability log roll-up are all **confirmed-absent today** (§3e/§3f/§8; `.gitignore:58`; `.github/workflows/`
  holds only `ci.yml` + `integration.yml`, verified this session). Each names a failure mode. Nothing here re-builds
  a TRULY-WORLD-CLASS item or resurrects a rejected pattern.
- **`/plugin` capability is documented, lightly corroborated.** The plugin/marketplace mechanism rests on
  `capability-facts.md:56-71` (official docs + the 27-byte vercel-plugin proof). The `disable-model-invocation`
  "removes from context" lever (§2, F9) is documented but **uncorroborated on the target CC version**
  (`DECISION-PACKAGE §6.2`) — verify before relying on it as a hard isolation guarantee; else F9 is +1 advisory
  line, not a removal.
- **F6's force-multiplier is branch protection, a repo-admin act.** Making `cr-gate` *required* (§4b step 3) is a
  GitHub-settings change a human applies once per repo — not something the agent can self-enable (consistent with the
  no-self-edit-guard-files boundary). The CI job is buildable by the agent; the *requiredness* is a human handoff,
  surfaced as paste-ready settings.
- **Push-back automation and the repair-worker are gated, not shipped** (§5). The human-gated PR path and detection
  are P1/P0; the automation waits on its flip-trigger (a 2nd install) / Fork F7 — per
  hypothesis-before-speculative-build. This is deliberate, not a gap.

---

## Citations index (ground-truth this artifact rests on)

- **§0** — three-layer bidirectional drift; the central structural fact ("multi-project is aspirational").
- **§3e** — hooks: triggers fire only on human session-start; `permission-logger.sh` logs permission calls, not
  run progress; `block-dangerous-bash.sh` absent.
- **§3f** — scripts/CI: the Node 8.5(c) gap ("CI never verifies `.cr-ok`"); canon's `.cr-ok` chain shares the hole.
- **§6** — disk-only phantom refs (`learned-patterns.md`, `@benchmark-runner`, `/scan-context`, …) — P9's
  reference-integrity targets.
- **§7** — nine canon-internal contradictions (the convergence-scope fork F10's workload).
- **§8** — cross-project reality: never installed beyond event-vendor; To-Think-About #20 ("GitHub Publishing — in
  progress; next gate: 3 real installs").
- **Disk, verified this session** — `.gitignore:58` (`.cr-ok` gitignored); `scripts/pr.sh` (sentinel parse/consume,
  `${BRANCH}:${HEAD_SHA}`); `.github/workflows/{ci,integration}.yml` (no `cr-gate`, no `summon`); `compound/SKILL.md:108-120`
  (Step 8 → Notion Changelog); `.claude/skills/notion-sync/SKILL.md` present.
- **VISION.md** — pillars 1+5; L1, L6, L7, F6, F9, P1, P2, P3, P4, P6, P8, P9; the minimal floor {F1,F2,F6,F7,F9};
  the eleven forks F1/F3/F7/F9/F10/F11.
- **capability-facts.md** — `:42-46` (autoMode ignored in committed project settings); `:56-71` (plugin ships
  hooks/skills/agents/.mcp.json + a settings.json limited to agent+subagentStatusLine; marketplace = native
  pull/update; the 27-byte proof); the `disable-model-invocation` caveat.
- **DECISION-PACKAGE §4e** — the two-vehicle split, "convergence first as the publish gate," symlink-live UPHELD-CUT,
  push-back-as-outer-ring, the 27-byte proof.
```
