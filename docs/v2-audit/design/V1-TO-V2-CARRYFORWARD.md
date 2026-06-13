# V1 → V2 Carry-Forward Ledger

**Why this exists.** The Phase 0–6 design worked at the *architecture* level (the 6 MOVES: memory model,
enforcement, distribution, the loop). It did **not** do a per-asset "what does V1 actually have, and what
happens to each thing in V2" pass — so concrete, wired mechanisms (golden exemplars is the clearest) were at
risk of being summarized away. This ledger is that pass: **every real V1 asset gets an explicit V2
disposition — keep / change-how / cut — grounded in the actual file on disk, not in a prior summary.**

Disposition key: **KEEP** (carried as-is, better home) · **CHANGE** (kept but its delivery changes) ·
**CUT** (removed, with reason) · **MOVE** (relocated). Re-verified on disk 2026-06-11.

---

## A. Mechanisms I had glossed — now explicitly carried (the user's concern, answered)

These are real, wired V1 mechanisms that did NOT appear as first-class items in the Phase 3–6 design. Each
is now given a concrete V2 home.

| V1 mechanism (cited) | What it actually is | V2 disposition |
|---|---|---|
| **Golden exemplars** `AGENTS.md:300` | A table: per layer (data fn, schema, util, page, server action, client component, integration test) → the *canonical example file* → why it's the bar. Read by `implementer.md:21`, `task-runner.md:51`; enforced by `lens-composition.md:25` ("golden exemplar divergence… a silent new standard"). | **KEEP + CHANGE (better).** The *mechanism* is portable and load-bearing. In V2 it's delivered **path-scoped**: each layer's exemplar pointer lives in that layer's `.claude/rules/<area>.md` ("canonical example: `src/data/proposals.ts` — match its teamId scoping, Zod-on-response, trigger-awareness"), so it auto-loads exactly when you touch that layer instead of being a table you must remember to open. `lens-composition` still checks divergence. The *content* (which files) is project-owned, scaffolded by `/init`. |
| **The design system** `AGENTS.md:8` + `docs/design/{tokens,components}.md` + `briefs/` + `handoff/` | "All UI work MUST reference the design files before writing any component." Tokens (color/type/spacing/Tailwind @theme), component patterns + anti-patterns, per-screen briefs, and the actual design source (jsx/html). | **KEEP.** `docs/design/` stays project-owned. The *rule* ("UI work reads tokens+components first; deviation is flagged") becomes a path-scoped rule on component paths (`src/components/**`, renderer paths). `handoff/` (the bulky design source) stays as the record. Cut nothing — this is real, used by the `ux-reviewer` agent and the design briefs. |
| **The 5 rituals** `rituals.md` | Named recurring jobs with `last_run`/`frequency`: `improve-codebase-architecture` (weekly refactor pass), `scan-context` (weekly drift check), `model-review` (on-release — audit each agent's `model:` field vs the current lineup), `prioritize-tasks` (weekly), `stale-branch-audit` (14d → `scripts/gc.sh`). | **KEEP + CHANGE (the clock moves to cloud).** Each ritual carries forward, but the *firing mechanism* moves from "fires only if the agent remembers to check `last_run`" to a **cloud `/schedule` routine** (runs on Anthropic's servers, laptop-independent). `scan-context` becomes the CI drift detector (it runs every push *and* on the weekly routine). `model-review` is especially worth keeping — it's the discipline that re-audits agent models on a release (directly relevant to the Opus 4.8 re-audit). |
| **The human diff-review checklist** `diff-review.md` | "What only a human can catch": did-this-do-what-I-asked, scope-creep naming, the "huh, why is this here?" test, the 60-second manual golden-path smoke (incl. `/p/[token]` in incognito as the client), DB/migration safety — explicitly the half **no agent can verify.** | **KEEP-VERBATIM (correcting an earlier error).** Phase 3 said "fold into `/cr`" — that was wrong: this is the *human* checkpoint, the opposite of the AI review. It stays a standing human checklist after `/cr` reports clean. It is the "manual-QA coverage blocker" on the keep-verbatim floor. Cutting or folding it into the AI pass would delete the one check that catches "code is correct but the feature is broken end-to-end." |
| **The sub-agent contract** `agent-contract.md` | The required template every spawned sub-agent fills: GOAL (outcome, not "implement X"), SCOPE (exact files, STOP-AND-SURFACE outside them), DECISIONS-ALREADY-MADE, REFERENCES (file:line required reading), TDD-REQUIREMENT, etc. | **KEEP.** This is the discipline that makes sub-agent runs self-contained and prevents scope creep. Portable → ships in the plugin as the agent-spawning template. The Phase-3 design kept it as a line item; this records *what it does* so it isn't degraded. |
| **The spec layer** `docs/specs/` + `spec-writer` agent | Behavioral specs (`change-quote-request.md`, `proposal-status-state-machine.md`) — agent-readable module contracts. | **KEEP.** Project-owned. The `spec-writer` agent (kept) writes them. Small today (2 specs) but real; MASTER-FINDINGS §C flagged "per-feature spec layer" as a deferred extension — the *existing* layer carries forward unchanged. |
| **Decision discipline** `AGENTS.md` §MVP-scope/Open/Resolved/Rejected/Known-limitations | The structured record of what's in scope, what's undecided (agents must STOP-AND-SURFACE, never resolve), what's locked, what's rejected-with-reason, and the v1 data-layer's known limits. | **KEEP.** Project-owned context. The "surface open decisions, never resolve unilaterally" rule (R59/R102) is L3 tier-1. The Rejected-Patterns list pairs with the harness-level §F reject list. |
| **The codebase map** `AGENTS.md` §"What exists in the codebase" | An inventory of every layer's real files (layouts, shell/proposal/renderer components, data access, schemas, types, utils, constants, migrations). | **KEEP.** Project-owned orientation; read by `explorer`/`implementer`. Generated-ish (could be drift-checked), but stays. |
| **`docs/agents/git-ops.md`** | Agent-readable git-ops contract. | **KEEP** (verify it doesn't duplicate CLAUDE.md's git workflow; merge if it does). |

---

## B. The Notion → GitHub migration (now an explicit workstream)

**The fact that reframes distribution:** the harness travels today by **pointing a new repo at a Notion
"setup page"** and letting the agent reconstruct the harness from those prose instructions. That's why other
repos audited as "nearly empty" — they're partial, *divergent reconstructions* from a setup prompt, not
copies. This is worse than drift: it's drift *at the rebuild level* (each repo gets a different harness
depending on when it was set up and how the agent interpreted the prose).

**So "Notion → GitHub" is not just deprecating docs — it's replacing the distribution mechanism AND
migrating the canon.** Two parts:

1. **Replace the setup mechanism.** The Notion setup page → the **plugin + `/init` template**. A new repo
   runs `/plugin install agent-harness` (exact, versioned, identical every time) instead of
   reconstructing-from-prose. This is the cleanest possible framing of MOVE 5.
2. **Migrate the canon content.** Everything valuable in the Notion "AI-Native Engineering System" (the 15
   reference pages, setup prompts, the Model-Capacity Audit, the research corpus, the changelog) → markdown
   in the `agent-harness` repo. After migration, **the repo is the single source of truth**; Notion becomes,
   at most, a read-only archive. `/notion-sync` is removed (nothing to sync to).

**Migration sub-steps (a real checklist):**
- Inventory the Notion pages (the research-registry already lists 50 — reuse it).
- For each: export to repo markdown, or mark "archive only" (superseded/event-vendor-specific).
- Resolve the 9 canon-internal contradictions (map §7) *during* export (later-dated page wins).
- The exported canon becomes the `agent-harness` repo's `/docs` + the README "this is a system" explainer.
- Cut `/notion-sync`; update any skill that referenced Notion as canon (`/compound` Step for Notion sync).
- **This is the convergence gate's content half** — you can't ship the plugin until the canon lives in git.

> **Honest note:** this updates prior project memory that treated Notion as the canonical engineering record
> (`reference_notion_engineering_system`, `feedback_compound_evaluation_scope`). The direction is now
> GitHub-canonical. That memory should be revised once the migration is confirmed underway.

---

## C. The categories already covered (recorded for completeness, with the corrections)

These were handled in Phase 3–6; listed so the ledger is complete, with any correction noted.

| Category | V2 disposition | Correction / note |
|---|---|---|
| **Skills (26)** | KEEP 22 core; CUT `dep-update` (empty stub); **MOVE OUT** `supabase` + `supabase-postgres-best-practices` (per-project Supabase add-on); **CUT** `notion-sync` (Notion deprecated); ADD `cr-eval`. `dev`/`explain` need canon docs. 2 soft merges flagged. | The supabase + notion-sync moves are this round's user decisions. |
| **Agents (23)** | KEEP all 23 (each wired, each a distinct failure mode). | The per-body grounding pass (running now) confirms each agent's actual job + flags any embedded mechanism (like golden-exemplar reading) that must carry forward. |
| **Hooks (5→7)** | KEEP 5; ADD `block-dangerous-bash.sh`, `session-end-capture.sh`. | `session-start.sh` body is near-empty — wiring it is a build, not a config tweak. |
| **Memory (6 stores)** | → 3 owned (rules / solutions / findings-inbox) + 1 ridden auto-memory cache; entry-as-atom; promotion gate; decay clocks. | The drift detector catches phantom refs (the live failure class). |
| **Enforcement (118 rules)** | ~64 relocate to L1 hooks / L2 CI tests; keep-verbatim safety floor intact; `.cr-ok`→CI. | R2 was a phantom (already enforced) — corrected. |
| **Git hooks / CI / scripts** | KEEP pre-commit/pre-push/CI; ADD migration-lint, repo-structure, scan-context, gen-harness; `dependency-cruiser` (L2). | commitlint folds into repo-structure (no new dep). |
| **Worktree + /queue + prod-key firewall** | KEEP — the parallel-isolation + Tier-0 credential firewall are a genuine disk advance. | The worktree lifecycle (AI-WORKFLOW.md) carries forward; `gc.sh` = the stale-branch ritual. |
| **Governance docs** (CLAUDE, AGENTS, CONTEXT, SOUL, INDEX, STRATEGY, mcp, AI-WORKFLOW) | KEEP all; project-owned (except SOUL/agent-contract/AI-WORKFLOW ship as plugin defaults a project may override). | CLAUDE.md NEVER-section trims as rules relocate. |
| **ADRs (5)** | Decision D1: project into rules as `kind: decision` + keep `docs/adr/` long-form. | Recommended. |
| **Distribution** | Plugin + thin template; Notion setup page → plugin (§B). | Decision D2. |

---

## D. Completeness status (honest)

**Fully grounded this round** (read the real file): golden exemplars, design system, rituals, diff-review,
agent-contract, specs, decision discipline, AGENTS.md structure, distribution mechanism.

**Grounding pass running now:** every skill `SKILL.md` body + every agent `.md` body, to itemize each one's
actual job and flag any *embedded* mechanism (like an agent that reads golden exemplars) that must carry
forward — so no second "golden exemplars" hides inside a skill/agent body.

**Still owed a deeper read** (flagged, not yet done): the full content of `CONTEXT.md`, `docs/design/tokens.md`
+ `components.md` (to confirm the design rules carry), and `docs/planning/03-security.md` (referenced by the
diff-review DB-safety step). These are project-owned and not at risk of being *cut*, but their *mechanisms*
deserve the same explicit treatment golden exemplars just got.
