# agent-harness — BUILD PLAN (START HERE)

This repo is the **agent-harness**: a curated, self-contained, **project-agnostic** AI coding harness
(skills + sub-agents + hooks + locks) that travels across multiple repos. This file is the single entry point
for building it. The full design record + decisions + reviews live in `docs/v2-audit/` — start with
`docs/v2-audit/ROUND-4-DECISIONS-AND-HANDOFF.md` (the decisions + the same build plan) and
`docs/v2-audit/V2-REVIEW-PACK.html` (the plain-English plan). `docs/v2-audit/V2-LAUNCH-SCOPE-AND-DEFERRED-BACKLOG.md`
is the build-now set.

---

## What V2 is (one breath)
You start every job; the harness finishes it safely and tastefully and only stops to ask about the few things
expensive to get wrong. It runs on the operator's laptop behind **locks it can't switch off** (the locks are the
*sole* safety net — no practice DB assumed). It's **project-agnostic** (no project's specifics baked in — stack
choices live in each project's config, read via adapters), **token-lean** (one capable pass wherever the model
can hold the work; separate agents only for independence/parallelism/scale), and **self-improving** (every
lesson compounds). No autonomy yet: a human starts and merges everything; no event-trigger "front door" and no
timer until after launch.

## Non-negotiable principles (honor in every task)
1. **Project-agnostic.** The harness holds only universal patterns. NEVER bake one project's stack/banned-libs/
   conventions in — read them from that project's config (adapters/roles, e.g. "run THIS project's DB-safety
   skill," not hardcoded `/supabase`).
2. **Locks are the sole net.** Deterministic guards (block-dangerous-bash fail-closed, credential firewall,
   disable-model-invocation, OS-level managed-settings) carry safety; build them first; assume nothing behind them.
3. **Deterministic > advisory.** Every mechanically-checkable rule is a hook/lint/CI gate, not a CLAUDE.md line;
   CLAUDE.md is judgment-only.
4. **One capable pass; spawn only for independence/parallelism/scale.** Never split work the model can hold;
   never load context it can already infer. Collapses (9 review passes → 1 + lint; 3 designers → 1) are **gated
   on a real-defect "bug-catch test"** — keep splits only where catch-rate drops. Keep the 4 isolated lenses.
5. **Comments earned** (why, never what). Self-documenting code does ~90%.
6. **Human in control.** Human starts and merges everything; the un-forgeable CI gate is the merge boundary.
7. **Frictionless handoff.** Every task that needs the human ends with a checklist + exact commands (cd to the
   worktree, start the dev server, open any artifact built).
8. **Honest claims.** "Un-fakeable" = the deterministic test re-run only (the model's review *opinion* is
   measured-trust). AI enforces taste, can't originate it — the human keeps the brand + final call. Never emit a
   faked human metric (e.g. "92% task success").

---

## Step 0 — Foundation: migrate the FULL canon FIRST (not a bootstrap subset)

Before the phase work, bring the **entire** harness into this repo — the build needs the whole roster present,
and GitHub becomes the single source of truth (this is the "Notion→GitHub canon" migration, pulled forward from
Phase 4 because it's foundational). Three parts:

1. **ALL universal skills** (from `/Users/tanner/Dev/event-vendor/.claude/skills/`, genericized as you copy):
   `cr · cr-security · debug · incident · hotfix · post-mortem · migrate · behavior-change · perf · spike ·
   evaluate-solution · refactor · review-strategy · setup-strategy · prioritize-tasks · queue · tdd · compound ·
   design · feature` (fold `dev` into the one adaptive command). Plus vendor the borrowed ones
   (`grill-with-docs · simplify · to-issues`) and adopt `zoom-out · write-a-skill · prototype · triage · to-prd`.
   - **Do NOT bring** the stack-specific adapters `supabase` / `supabase-postgres-best-practices` (those belong
     to a project, not the universal harness — a project plugs in its own DB-safety skill). **Cut** the empty
     `dep-update`. Convert `notion-sync` → a `github-sync` (canon now lives in git). Keep `explain` only if you
     want the React-learner framing (it's user-specific, not universal).
2. **ALL agents** (from `.claude/agents/` — all 23, genericized): `reviewer` + the 4 `lens-*`, `task-runner`,
   `implementer`, `spec-writer`, `explorer`, `investigator`, `hotfix-guard`, `incident-responder`,
   `security-reviewer`, `refactor-extractor`, `solution-evaluator`, `doc-updater` (generalize its hardcoded doc
   set), `ux-reviewer`, and the 6 `spike-*`.
3. **The Notion AI-Engineering-System canon** (`notion.so/358e2971cd62812a8ba8f87d6ac1466d`) → into `docs/` as
   GitHub markdown: the four layers, file-structure rules, context-doc guidance, memory system, settings/
   permissions guidance, principles, anti-rationalization tables, model-capacity audit, git discipline, the
   templates, and the roadmap ("to think about"). Reconcile any drift between the Notion docs and the working
   skill files; GitHub wins going forward; retire Notion as canon.

Commit the foundation as its own commit(s). THEN do the phase work below.

---

## Build order (dependency-ordered; `/queue` the independent items WITHIN each phase)

**Phase 0 — Safety floor (first, non-negotiable):** `block-dangerous-bash` (fail-closed, full non-git scope) ·
credential firewall (prod creds not reachable; migrations human-applied) · `disable-model-invocation` on
side-effect skills · fail-closed any `jq`-dependent hooks · `managed-settings.json` (OS-level) · basic egress
allowlist · worktree fixes: run `npm install` + assert the husky hook exists (fail-closed); standardize on
`.claude/worktrees/<slug>`.

**Phase 1 — Trust:** the un-forgeable CI verdict gate (sentinel SHA == head SHA + required deterministic checks
green) · **the bug-catch test (catch-rate), seeded from REAL escaped defects — BUILD FIRST; it gates the
collapses** · the 4-lens adversarial reviewer + governance lens · collapse the 9 analytical review passes → 1 +
free lint (gated on the bug-catch test) · model tiers by ROLE (deterministic / generation / judgment) +
re-audit on model-id change · the routing-assertion gate (block if a DB-touch skipped the DB-safety skill) ·
bounded-loop + REJECT.

**Phase 2 — The loop (human-started):** one adaptive build command + `/goal` · incident subsystem (carry
forward) · narration · shared Stop-hook · **the strict before-coding gate: data shape → UX (flow/clicks) → UI
(mockup), human-approved before any code** + the design phase (1 designer covering schema + API + front-end
architecture, judged-for-the-stack, + an independent grill) · the feature-doc hub (one source of truth per
feature) + patterns/golden-exemplars registry · the learning loop (read-path + finding→enforcement ratchet) +
reference-integrity check.

**Phase 3 — Quality systems:** UI (design-system bootstrap-if-missing → design-system-only + token-lint +
`impeccable` detector + gated rendered design-review + `/compound` feedback) · UX (tiered usability reviewer +
axe a11y gate + feature-doc click/step targets; never fake human metrics) · perf (Core-Web-Vitals budget,
measured + logged + warn, not blocking) · the data-state matrix (no data / some / lots / bad / loading; no page
shift) · clean-code / comments-earned · tests verified by delete-the-code + break-the-code (mutation).

**Phase 4 — Fleet / platform:** GitHub canon · pin + vendor the borrowed skills (grill-with-docs, simplify,
to-issues, tdd) · per-skill frontmatter contract · the self-contained add-on + thin `/init` starter kit +
`sync-harness.sh` · the deep AI-activity dashboard (per task: which task, commit SHA, trigger source, model,
skills/agents fired) · the CLAUDE.md→hooks ratchet audit · adopt zoom-out / write-a-skill / prototype / triage /
to-prd from mattpocock.

**Phase 5 — Post-launch / next steps (deferred, each with a trigger; build the core so these slot in cleanly
later):**
- **The front door — 3 auto-start triggers** (a bug/request kicks off a run with no one typing): (1) a **GitHub
  issue-label** (safe-first — no attacker-controllable text); (2) a **Slack / Linear `/fix` summon** (fires
  where the work is reported); (3) **CI self-heal** (a red build auto-triages). The free-text doors (Slack /
  Linear / CI) need the egress allowlist + lethal-trifecta guard built first; the label door doesn't.
- **The clock** — timer-based scheduled discovery runs (laptop-closed).
- **Risk-based auto-approval** — auto-merge LOW-risk changes once the catch-rate clears a measured bar (money +
  DB always stay human; the human is never the last gate that's removed first).
- **The real-time access-control UI** (toggle key/DB/resource access live) · the **fleet circuit breaker** (halt
  all repos on a repeated failure) · the **plugin marketplace + push-back-up** (a fix in one repo flows to all).

> Don't build Phase 5 now — but don't architect anything that *blocks* it: keep the pipeline summonable from
> outside (so a Slack/Linear/CI event can route in), and keep the review verdict a CI-readable artifact (so an
> external trigger can act on it). These are the known next steps once V2 launches.

---

## How to run the build
1. Build in phase order. Do NOT start a later phase until the earlier phase's gates exist.
2. Slice each phase into INDEPENDENT tasks, each with a clear contract (inputs · outputs · what it must NOT do ·
   what done looks like). Independent tasks run in parallel worktrees.
3. Run them via `/queue` → each goes through `/cr` → opens a PR. **The human merges everything** (no auto-merge).
4. Honor the non-negotiable principles above in every task.
5. Show the operator the Phase 0 task list + dependency order for approval BEFORE queuing. After each phase lands
   and is verified, surface the next phase's slice for go-ahead.

> Priority signal (from the cost/ROI review): the highest-value core is the locks (Phase 0), the un-forgeable
> gate, the direct collapses, the free UI floor (token-lint + impeccable + axe), the before-coding gate, and
> vendor-skills + sync. Lead with those. (Its "ship the product first" argument is struck — the harness is a
> separate project.)
