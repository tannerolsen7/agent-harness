# Cluster C — Skills & Agents as Documented (Canon Inventory)

**Audit basis:** FACT-ONLY extraction from the canonical "AI-Native Engineering System" (Notion). Governing rule: no claim without a citation. Every claim below is tagged `[CANON-DECLARES]` and sourced to one of the four cluster pages.

**Pages read (100% of content):**
- **[05]** 05 · Pipeline Skills — `358e2971cd6281efb87ffd69b4f8ceb6` (as of 2026-06-04)
- **[06]** 06 · Workflow Skills — `358e2971cd628193b041ec371dfdc82b` (as of 2026-06-04)
- **[11]** 11 · Skill Ecosystems — `358e2971cd62814f880cd347942ef671` (as of 2026-06-04)
- **[TPL]** Templates — `359e2971cd62819e9142c30b99fecb6c` (as of 2026-06-09)

Citations reference page tag + the section the claim appears in. Child/linked template pages (individual `SKILL.md` / agent `.md` bodies) were NOT fetched — only the Templates index that lists them. Where a skill/agent is known only by its index listing, it is tagged accordingly.

---

## 1. Skills named across these pages

`[CANON-DECLARES]` columns: Canon's stated purpose · Pass/step structure if given · upstream-external vs project-built per canon.

| Skill | Canon's stated purpose | Pass/step structure if given | Upstream vs project-built (per canon) |
|---|---|---|---|
| `/cr` | Full pre-merge review against the complete branch diff before merging to main [05] | 9 passes (P1–P9) + Devil's Advocate 4 vectors + Step 3b recurring-findings + Opus auto-fix; see §3 [05] | **Custom (yours)** — listed under "Custom" in skill-sources table [11] |
| `/cr-security` | Security review; opt-in, run manually before committing any change touching auth, middleware/route guards, public unauthenticated handlers, RLS policies, cross-team isolation, share tokens [05] | 2 passes (Pass 1 Security & Auth Sonnet; Pass 2 Data Boundary Integrity Sonnet) + Opus auto-fix; see §3 [05] | **Custom (yours)** [11] |
| `/cr-feature` | ⛔ RETIRED v0.85 — do not install; folded into `/cr` [TPL] | n/a (retired) | Custom (retired) [TPL] |
| `/feature` | Sized feature pipeline orchestrator; sizes the task (Tiny/Small/Medium/Large) and runs the matching pipeline [06][TPL] | Size table: Tiny=1 behavior, Small=2–5, Medium=6–15, Large=16+, each with a distinct pipeline string; final report format defined [06] | **Custom (yours)** [11] |
| `/design` | Design before commitment; two modes — `explore` (don't know the design) and `contract` (know the design) [06] | explore: propose 2–3 options w/ tradeoffs; contract: 4 topics (business need, interface, constraints, state) then 2 checks (simplicity, deep module) [06] | Custom (event-vendor action items reference `/design contract`) [11] |
| `/tdd` | Test-driven development, red-green-refactor; vertical slices — one behavior, one test, one implementation, one commit; never batches [11]. Canon also documents an extended 9-step per-slice loop [06] | Per-slice loop: 9 steps (comment→red→confirm red→green→confirm green→refactor→update progress doc→commit→next) [06] | **Upstream (Matt Pocock)**, but **extended** as custom (`/tdd (extended)` appears in Custom column) [11] |
| `/compound` | Capture solved problems; run after a feature merges when implementation introduced a non-obvious pattern [06][TPL] | 10 steps (read diff/spec/compound answers → progress doc → spawn Sonnet extractor → review → write solutions doc → PITFALLS check → memory check → append TASKS backlog → delete progress doc → quarterly memory review) [06] | **Custom (yours)** [11] |
| `/incident` | Classify first, route second, fix third; runs before /debug, /hotfix, /feature; 8 incident types [06] | Phase 0 reproduce (2 attempts) → Phase 1 six evidence checks (parallel) → Phase 2 classify (High/Low/Split) → triage doc → surface → human confirms [06] | Custom (template listed) [TPL] |
| `/evaluate-solution` | Build vs. buy; researches pricing/GitHub health/issues/build cost, names a choice [06] | 7 required questions (fit, cost now, cost 10x, operational cost, lock-in, build cost, community/longevity health); recommendation = one sentence named choice [06] | Custom (template listed) [TPL] |
| `/debug` | Investigate, confirm, hand off; output = root cause + failing test + Tiny task spec for /feature; fix never written here [06] | 5-step loop (Orient → Reproduce → Bisect → Write failing test → Produce task spec) + STOP AND SURFACE conditions [06] | Custom (template listed) [TPL] |
| `/hotfix` | Production broken; triage first, fix right; requires /debug confirmed root cause; triage gate before code [06] | Two modes (full-fix / mitigation-only); triage gate loop; TASKS.md entries before code; gate = @hotfix-guard (3 checks) [06] | Custom (template listed) [TPL] |
| `/migrate` | Move state safely; pre-flight first, execute once; owns state-mutation PRs only [06] | 5 migration types; 4 irreversibility tiers; Phase 0 sequencing → Phase 1 pre-flight → Phase 2 rollback → Phase 3 dry-run → Phase 4 execution → Phase 5 verification [06] | Custom (template listed) [TPL] |
| `/dep-update` | Dependency version updates; audit before trusting; classifies mode + bump type [06] | 2 entry modes (pre-bump / post-bump); 5 phases (changelog classification, usage surface map, type-level verification, behavioral equivalence audit, test+smoke); audit-depth-by-bump-type table; security-urgency mode [06] | Custom (template listed) [TPL] |
| `/behavior-change` | Change what the system does without breaking dependents; existing-correct → new behavior [06] | 5 mandatory pre-phases (entry gate, caller impact analysis, external caller check, test inversion analysis, rollback plan); then /tdd w/ modified sequence [06] | Custom (template listed) [TPL] |
| `/perf` | Correct but slow; measure first, ship proof; only for measured slowness [06] | 3 non-negotiables (baseline artifact, target defined first, after-measurement hits target); 5 execution contexts; loop Phase 1–4 + @reviewer perf mode + /cr [06] | Custom (template listed) [TPL] |
| `/simplify` | Reuse, duplication, efficiency (appears in feature loop after /tdd) [06] | Not given (single loop step) | Custom (referenced in feature loop) [06] |
| `/handoff` | Context-exhaustion handoff; agent initiates proactively at ~60% context [06] | 5 actions at ~60% (stop at clean boundary, write progress doc, materialize contract, surface to human, wait for approval); anti-rationalization table [06] | Custom (referenced; no template page listed) [06] |
| `/scan-context` | Context drift detection; staleness, broken references, contradictions [06][11] | 3 passes per file (broken reference, pattern consistency, staleness); outputs `context-drift-report.md`; severity tiers [06] | **Custom (yours)** — `/scan-context` in Custom column [11] |
| `/grill-with-docs` | Challenge the design against the existing domain model; two-phase (you first, then agent); updates CONTEXT.md, creates ADRs inline [11][06] | Phase 1 (your 3 answers) → Phase 2 (agent grill) → spawn @reviewer (design mode, 4 lenses); ADRs only when hard-to-reverse + surprising + real tradeoff [06][11] | **Upstream (Matt Pocock)** [11] |
| `/grill-me` | Non-code version of /grill-with-docs; relentless interview about a plan/design [11] | Not given | **Upstream (Matt Pocock)** [11] |
| `/to-issues` | Breaks a plan into independently-shippable GitHub Issues; one acceptance criterion each; requires `gh` CLI [11][06] | Not formally structured; canon adds a decomposition checklist [06] | **Upstream (Matt Pocock)** [11] |
| `/to-prd` | Turns conversation into a PRD, submits as GitHub Issue; no interview [11] | Not given | **Upstream (Matt Pocock)** [11] |
| `/improve-codebase-architecture` | Finds deepening opportunities; weekly ritual ("once every few days" per Pocock) [11][06] | Step 1 explore (deletion test) → Step 2 present candidates → Step 3 grilling loop; tracked in rituals.md [06] | **Upstream (Matt Pocock)** [11] |
| `/diagnose` | Disciplined diagnosis loop for hard bugs and perf regressions [11] | reproduce → minimise → hypothesise → instrument → fix → regression-test [11] | **Upstream (Matt Pocock)** [11] |
| `/zoom-out` | Explains code in the context of the whole system; for unfamiliar sections [11] | Not given | **Upstream (Matt Pocock)** [11] |
| `/prototype` | Builds a throwaway prototype to flush out a design; delete when done [11] | Not given | **Upstream (Matt Pocock)** — note: `prototype` "not in the global store," must be copied from upstream `skills/engineering/prototype/` [11] |
| `/prototype-interface` | Build to learn (logic/architecture); runs when /design explore options can't be evaluated without running them; delete after [06] | 6 steps (read options → build minimal per option → run hardest scenario → PROTOTYPE REPORT → present → delete all) [06] | Custom (referenced in feature loop; no separate template page listed) [06] |
| `/prototype-ui` | Build to learn (UI/interaction); 3–5 distinct variations using real components; delete non-chosen [06] | 7 steps (read TESTING.md → read AGENTS.md → generate 3–5 variations → Chrome MCP capture → VARIATION REPORT → present → delete others) [06] | Custom (referenced in feature loop) [06] |
| `/triage` | Triages a backlog of issues through a state machine of triage roles [11] | Not given | **Upstream (Matt Pocock)** [11] |
| `/caveman` | Ultra-compressed communication mode; cuts token usage ~75% [11] | Not given | **Upstream (Matt Pocock)** — listed under "Productivity skills" [11] |
| `/write-a-skill` | Creates new skills with proper structure [11] | "Skill-building pattern (Yan)": 7 steps (pick hard task → do once → ask agent to make skill → run on same task → correct in session → ask to update → repeat) [11] | **Upstream (Matt Pocock)** [11] |
| `/git-guardrails-claude-code` | Sets up hooks to block dangerous git commands before they execute [11] | Not given | **Upstream (Matt Pocock)** — "Misc skills" [11] |
| `/setup-pre-commit` | Sets up Husky pre-commit hooks (lint-staged, Prettier, type check, tests) [11] | Not given | **Upstream (Matt Pocock)** — "Misc skills" [11] |
| `/supabase` | General Supabase guidance; RLS security checklist, CLI workflow, Edge Function/storage patterns [11] | Not given (checklist-based) | **Upstream (Supabase)** — `npx skills add supabase/agent-skills` [11] |
| `/supabase-postgres-best-practices` | Schema design, query performance, RLS patterns [11] | Not given | **Upstream (Supabase)** [11] |
| `/setup-strategy` | (Named in Custom column; template page `skills/setup-strategy/SKILL.md`) [11][TPL] | Not described in these pages | **Custom (yours)** [11] |
| `/review-strategy` | (Named in Custom column; template page `skills/review-strategy/SKILL.md`) [11][TPL] | Not described in these pages | **Custom (yours)** [11] |
| `/prioritize-tasks` | (Named in Custom column; tracked in rituals.md weekly; template page exists) [11][06][TPL] | Not described in these pages | **Custom (yours)** [11] |
| `/queue` | Orchestration system; spawns @task-runner agents w/ worktree isolation [06][TPL] | Not detailed on these pages; template `skills/queue/SKILL.md` + "Steps 3–8" sub-page [TPL] | Custom (template listed) [TPL] |
| `/refactor` | (Template page `skills/refactor/SKILL.md` + agent `refactor-extractor.md`) [TPL] | Not described on these pages | Custom (template listed) [TPL] |
| `/spike` | (Template `skills/spike/SKILL.md` + 6 spike agents, listed at top of Templates page) [TPL] | Not described on these pages | Custom (template listed) [TPL] |
| `/post-mortem` | Post-mortem skill (referenced by /hotfix as mandatory before merge) [06][TPL] | Not detailed; template `skills/post-mortem/SKILL.md` [TPL] | Custom (template listed) [TPL] |
| `/notion-sync` | (Template `skills/notion-sync/SKILL.md`) [TPL] | Not described | Custom (template listed) [TPL] |
| `/setup` | Interactive bootstrap; gets a project running with the full system in one command [11] | 9 steps (env check → create files → install hooks → install agents → TASKS.md → orchestration prompt → install skills → repo-platform setup → Prompt 2) [11] | **Custom (yours)** — "Build in `.claude/skills/setup/SKILL.md`" [11] |
| `/vibe-check` | (Template page `skills/vibe-check/SKILL.md` only) [TPL] | Not described | Custom (template listed) [TPL] |
| Anthropic `skill-creator` | Official skill-creation tool; generates SKILL.md AND runs 20-query eval loop (10 should-fire, 10 should-not); use INSTEAD of `/write-a-skill` for new skills [11] | 20-query eval loop [11] | **Upstream (Anthropic)** — `npx skills@latest add anthropics/skills` [11] |

### Upstream sub-skills named but NOT recommended for install (catalogued only)
| Skill / artifact | Source per canon | Canon's disposition |
|---|---|---|
| `continuous-learning-v2` | everything-claude-code (affaan-m) [11] | "Steal the concept" — don't install wholesale [11] |
| `AgentShield` | everything-claude-code [11] | "Steal the idea" — security scanner, 1,282 tests / 102 rules [11] |
| `rules/common` | everything-claude-code [11] | Install selectively (language-agnostic rules only) [11] |
| Addy Osmani anti-rationalization-table pattern | addyosmani.com/blog/agent-skills [11] | "Reference, not a package" — steal the pattern, don't install [11] |

---

## 2. Agents / sub-agents named across these pages

`[CANON-DECLARES]` stated role.

| Agent | Stated role (per canon) |
|---|---|
| `@reviewer` | Adversarial four-lens review (assumption violation, composition failures, cascade construction, abuse cases); produces consolidated summary; spawned by /grill-with-docs (design mode) and /cr (implementation mode); owns the 4 compound questions as required output block [06][TPL] |
| `@explorer` | Broad codebase search specialist; pass a question + breadth (quick/medium/very thorough); used for 3+ location searches [06][TPL] |
| `@spec-writer` | TESTING.md entry writer; never invents behaviors [TPL] |
| `@implementer` | TDD slice executor; reads SOUL.md + PITFALLS.md [TPL] |
| `@doc-updater` | /compound draft producer; proposes only, never writes files directly [06][TPL] |
| `@security-reviewer` | /cr-security, RLS, auth review; auth triggers adapted per stack [TPL] |
| `@ux-reviewer` | Multi-persona UX review (P10 scope); reads project personas from CONTEXT.md [TPL] |
| `@task-runner` | /queue task orchestrator; manages its own specialist sub-agents (@explorer, @implementer, @reviewer); reads questions.md before any commit (blocking enforcement); Opus model; build last [06][TPL] |
| `@investigator` | Bug investigation specialist — root cause + failing test + task spec; agentic form of /debug; spawned when bug requires broad search across 3+ files/layers; same STOP AND SURFACE conditions [06][TPL] |
| `@hotfix-guard` | Hotfix gate — runs 3 checks; gate equivalent of /cr for /hotfix [06][TPL] |
| `@incident-responder` | Incident classification agent (paired with /incident) [06][TPL] |
| `@solution-evaluator` | Build-vs-buy research agent (paired with /evaluate-solution) [06][TPL] |
| `@refactor-extractor` | Module-extraction agent (paired with /refactor) [TPL] |
| `@spike-orchestrator` | Spike pipeline orchestrator (template at top of Templates page) [TPL] |
| `@spike-researcher` | Spike research pass agent [TPL] |
| `@spike-synthesis` | Spike synthesis agent [TPL] |
| `@spike-adversarial-verifier` | Spike adversarial verifier [TPL] |
| `@spike-user-verifier` | Spike end-user-lens verifier [TPL] |
| `@spike-slice` | Spike TDD-slice writer [TPL] |

**Canon's agent-install groupings (per [TPL]):**
- "Agent templates (v0.19)" — **Ten** committed specialist templates; build order: @reviewer first, then @explorer, then @spec-writer + @implementer + @doc-updater + @security-reviewer + @ux-reviewer together, then @task-runner last. [TPL]
- "Agents — All **8** specialist agents for the /queue orchestration system" — table lists reviewer, explorer, spec-writer, implementer, doc-updater, security-reviewer, ux-reviewer, task-runner, investigator (**9 rows despite the "8" header** — see §6 contradictions). [TPL]

---

## 3. `/cr` and `/cr-security` — documented pass-by-pass structure (exact)

### `/cr` — Full pre-merge review, **9 passes** `[CANON-DECLARES]` [05]
Run against the complete branch diff before merging to main. Each pass + model + focus exactly as written:

| Pass | Model | Focus (verbatim) |
|---|---|---|
| **P1 — Correctness & Spec** | Sonnet | Spec drift, domain constraints, PITFALLS.md rules |
| **P2 — Domain Safety** | Sonnet | Stack/domain-specific failure modes (silent wrong value vs explicit --) |
| **P3 — TypeScript Discipline** | Sonnet | No implicit any, no non-null assertions without narrowing, discriminated unions |
| **P4 — Layer Boundaries** | Sonnet | Reads AGENTS.md architecture before reviewing |
| **P5 — Readability & Naming** | Sonnet | Naming consistency, magic numbers, comments explain WHY not WHAT |
| **P6 — Test Quality** | Sonnet | Same as @reviewer's test pass, full branch diff |
| **P7 — Doc Drift & Footprint** | Haiku | Mechanical leftovers + doc contradictions (all MUST FIX) |
| **P8 — Architectural Drift** | Sonnet | Searches codebase for existing patterns before reviewing diff |
| **P9 — Devil's Advocate** | Sonnet | Stress-tests reasoning — why this approach, what does it make harder |

**P9 — Devil's Advocate (expanded), 4 attack vectors** [05]: 1. Worst-case data · 2. Upstream failure · 3. 10x scale · 4. Future change cost. Every vector with a real finding is MUST FIX; vectors with none noted "considered — no issue."

**Step 3b — Recurring findings update** (after synthesis, before auto-fix) [05]: read `docs/RECURRING-FINDINGS.md` → normalize signature per finding → match/append → identify promotion candidates (threshold ≥3 or judgment) → surface to user → on confirmation promote to PITFALLS.md + update RECURRING-FINDINGS.md status.

**Auto-fix (Opus)** [05]: "Compile all MUST FIX from **P0–P10** → one Opus agent → apply fixes → run tests → one retry → surface remaining." Also: "**P0 spec integrity findings are never auto-fixed.**"

> **`[CANON-DECLARES]` internal numbering inconsistency:** The pass TABLE lists exactly **P1–P9** (9 passes). The Auto-fix paragraph references "**P0–P10**" and "**P0 spec integrity**." The page never defines a P0 or a P10 in its own table. (See §6.)

### `/cr-security` — Security review, **2 passes** `[CANON-DECLARES]` [05]
Opt-in; run manually before committing any change touching: authentication, middleware/route guards, public unauthenticated handlers, RLS policies, cross-team isolation, share tokens.

| Pass | Model | Verdict policy | Checks (verbatim) |
|---|---|---|---|
| **Pass 1 — Security & Auth** | Sonnet | Every finding is MUST FIX | auth checks only on client that could be bypassed; server actions missing auth; queries returning another user's data; unsanitized input; hardcoded secrets; env vars exposed to client; redirect targets from user input |
| **Pass 2 — Data Boundary Integrity** | Sonnet | Every finding is MUST FIX | data access layer isolation (nothing touches the SDK outside the designated layer); subscription path structure; partial fields guarded at the boundary; every subscription returns a typed Unsubscribe |

**Auto-fix (Opus)** [05]: compile MUST FIX → one Opus agent → apply fixes → run tests → surface NEEDS HUMAN items.

### Does the canon's pass list differ from a "9-pass + adversarial" description?
`[CANON-DECLARES]`:
- The **`/cr` table is exactly 9 passes (P1–P9)**, and the 9th pass (P9) **IS** the "Devil's Advocate" / adversarial pass. So the canon's `/cr` = **"9 passes, with adversarial as P9"** — NOT "9 passes PLUS a separate 10th adversarial pass."
- This **differs from the harness-side "9 analytical passes plus an adversarial review" framing** (e.g. the live `/cr` skill description), which treats adversarial as an *additional* pass on top of 9. Count reconciliation: harness-framing implies 10 (9 + adversarial); canon table shows 9 (adversarial folded in as P9).
- Separately, the canon's own auto-fix text says "**P0–P10**," implying an **11-slot range** that the canon's own table does not enumerate. The numbering is internally inconsistent within page [05].
- `/cr-security` is uniformly described as **2 passes** with no adversarial pass.

---

## 4. Page 11 — evaluation framework, upgrade process, named ecosystems

### Skill ecosystem evaluation framework (criteria for adopting a skill) `[CANON-DECLARES]` [11]
1. Does it do something your current skills don't? If not, skip it.
2. Can you steal the pattern without installing the repo? Usually yes.
3. If installing, use the minimal path — copy specific files, not the full installer.
4. Never stack install methods. One install path per repo.

Stated rationale [11]: avoid "182 conflicting skills and sessions that spend 40% of their context on tool descriptions."

### Upgrade process `[CANON-DECLARES]` [11]
- Watch for patterns worth stealing, not repos worth installing.
- When something genuinely new is found, add it to the reading list in **01 · Reading List**.
- When you steal a pattern, add it to the relevant Notion page with a source link.
- When a new version of an installed repo ships, review the changelog before upgrading — don't auto-upgrade.
- Pocock's skills: `npx skills@latest` prompts before overwriting; review what changed.
- everything-claude-code: check CHANGELOG.md before pulling — ships frequently, breaking changes between versions.
- Stated goal: "not to have the most skills. It's to have the right ones, maintained, that you actually use."

### Named upstream sources / ecosystems `[CANON-DECLARES]` [11]
| Ecosystem | URL (per canon) | Canon's install verdict |
|---|---|---|
| **Matt Pocock / skills** | github.com/mattpocock/skills | Install (vendored). Lean, doesn't conflict. |
| **Addy Osmani** (Google engineer) | addyosmani.com/blog/agent-skills | Don't install — reference only; steal anti-rationalization table + five non-negotiables |
| **everything-claude-code (affaan-m)** | github.com/affaan-m/everything-claude-code | Install **selectively** — never the full installer. (Canon stats: 171K stars, Anthropic hackathon winner, 48 agents, 182 skills, 68 legacy command shims) |
| **AI Hero / aihero.dev** | aihero.dev / github.com/mattpocock/skills | Same as Pocock (it IS Pocock's course platform) — read the articles |
| **Supabase / agent-skills** | supabase.com/docs/guides/getting-started/ai-skills.md | Install — `npx skills add supabase/agent-skills`; security checklist is the value |
| **Anthropic / skill-creator** | github.com/anthropics/skills | Install — use for new skills; 20-query eval loop is the differentiator |
| **Every.to compound-engineering plugin** | (named, no URL) | **Don't install** unless starting from scratch — "26 agents, 23 commands, 13 skills … largely redundant and may conflict" |

### Vendoring / install mechanics `[CANON-DECLARES]` [11]
- Pocock skills are **vendored** into each repo's `.claude/skills/<name>/` (committed copies), NOT global, NOT symlinked. Decided **2026-06-01** after the `.agents/skills/`+symlink pattern broke across git worktrees on events-service and logistics-service.
- **Vendored set (events-service, logistics-service):** `tdd`, `grill-with-docs`, `prototype`, `improve-codebase-architecture`, `to-issues` — "the only Pocock skills these repos reference."
- Supabase skills **do** use `.agents/skills/` + symlinks in `.claude/skills/` (different mechanic from Pocock).
- **Never edit Pocock skill files directly** — customization goes through CONTEXT.md / AGENTS.md / PITFALLS.md.

### Progressive disclosure + conventions `[CANON-DECLARES]` [11]
- 3 load levels: YAML frontmatter (always loaded) → SKILL.md body (loaded when relevant) → references/ (navigated when needed). Body should stay under 5,000 words.
- Required conventions: file must be exactly `SKILL.md` (case-sensitive); folder names kebab-case only; no README.md inside skill folder; `references/` for long-tail; `allowed-tools` for review skills (review skills should never write files / run migrations).

---

## 5. Templates page — copy-paste starting points provided

`[CANON-DECLARES]` every template file the canon lists. (These are listed as linked child pages or in tables; individual bodies were not fetched.)

### Core project files [TPL]
- `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `PITFALLS.md`

### docs/ files [TPL]
- `docs/TESTING.md`, `docs/RECURRING-FINDINGS.md`, `docs/solutions/TEMPLATE.md`, `docs/solutions/README.md`, `docs/spec.md` (Medium+ template), `docs/research/ convention`

### Tool config / process files [TPL]
- `memory.md`, `TASK-TEMPLATE.md`, `agent-contract.md`, `AI-WORKFLOW.md`, `INDEX.md`, `settings.json`, `Global config`, `SOUL.md`, `TASKS.md`, `rituals.md`, `STRATEGY.md` (two separate template pages listed), `LAST-SYNC.md`, `DESIGN-CRITERIA.md`, `progress-[slug].md`

### Hooks / CI / scripts [TPL]
- `.husky/pre-push`, `.husky/post-checkout`, `.githooks/pre-commit`, `.github/workflows/ci.yml`, `scripts/pr.sh`, `CODEOWNERS`, PR / MR template
- Hook scripts: `block-npm-install.sh`, `block-dangerous-git.sh`, `block-dangerous-bash.sh`

### Skill templates (`skills/<name>/SKILL.md`) [TPL]
- `feature`, `cr`, `cr-feature` (⛔ RETIRED v0.85 — do not install), `cr-security`, `tdd`, `compound`, `debug`, `design`, `vibe-check`, `notion-sync`, `queue` (+ a separate "queue/SKILL — Steps 3–8" page), `refactor`, `setup-strategy`, `review-strategy`, `prioritize-tasks`, `hotfix`, `post-mortem`, `incident`, `evaluate-solution`, `behavior-change`, `migrate`, `perf`, `dep-update`, `spike`

### Agent templates (`agents/<name>.md`) [TPL]
- `reviewer` (listed 3×: v0.19 group, Agents table, and a standalone page), `explorer`, `spec-writer`, `implementer`, `doc-updater`, `security-reviewer`, `ux-reviewer`, `task-runner` (listed twice in the v0.19 group), `investigator`, `refactor-extractor`, `hotfix-guard`, `incident-responder`, `solution-evaluator`
- Spike agents (top of page): `spike-orchestrator`, `spike-researcher`, `spike-synthesis`, `spike-adversarial-verifier`, `spike-user-verifier`, `spike-slice`

### "Which files need project context?" buckets [TPL]
- **Copy as-is:** RECURRING-FINDINGS.md, solutions/TEMPLATE.md, solutions/README.md, memory.md (seed), TASK-TEMPLATE.md, TESTING.md (structure)
- **Edit paths only:** settings.json (swap user + repo-name), AI-WORKFLOW.md (naming)
- **Edit manually:** Global config file
- **Agent writes from context:** CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md, agent-contract.md, INDEX.md, TESTING.md (mock infra), skills/cr/SKILL.md (P2 domain pass), skills/cr-security/SKILL.md (auth triggers)

---

## 6. Version markers / contradictions / draft / TODO notes

`[CANON-DECLARES]`:

**Version markers**
- `/cr-feature`: "⛔ RETIRED v0.85 — do not install; folded into /cr." [TPL]
- "Agent templates (**v0.19**)" — ten committed specialist agent templates. [TPL]
- Vendoring decision dated **2026-06-01**. [11]
- "Skill Description Engineering — resolved" — page marked resolved and incorporated. [11]

**Contradictions / internal inconsistencies**
1. **/cr pass numbering:** table = P1–P9 (9 passes), but auto-fix text references "**P0–P10**" and "**P0 spec integrity**." No P0 or P10 is defined in the page's own table. [05]
2. **Agent count vs rows:** the "Agents" section header says "**All 8 specialist agents**," but the table lists **9 rows** (reviewer, explorer, spec-writer, implementer, doc-updater, security-reviewer, ux-reviewer, task-runner, investigator). Separately the v0.19 group says "**Ten** committed specialist agent templates" but its build-order names 8 roles (task-runner appears twice in the listing). [TPL]
3. **`/migrate` duplicated:** page 06 contains TWO near-identical `/migrate` sections (heading repeated), with slightly different irreversibility-tier wording ("clean-revert → compensate → window → permanent" vs "clean-revert / compensate / window / permanent") and different "Five migration types" risk-cell phrasing. Appears to be an un-deduplicated edit. [06]
4. **`/tdd` upstream-vs-custom:** listed as upstream Pocock in the sources table, but ALSO appears as "/tdd (extended)" in the Custom column, AND has its own custom template page `skills/tdd/SKILL.md`. Canon treats it as upstream-base + custom-extension simultaneously. [11][TPL]
5. **`reviewer.md` / `task-runner.md` listed multiple times** on the Templates page (reviewer 3×, task-runner 2×) — appears to be accidental duplication of linked child pages. [TPL]

**TODO / action-item / draft notes**
- "**Custom skill maintenance — event-vendor action items**" (Priorities 1–4) — explicit list of known gaps between Notion docs and actual skill files [11]:
  - **P1 Sync custom skills with Notion:** `/cr-feature` add four-question compound block + ⛔ gate (Q4 is new); `/grill-with-docs` add Phase 1 + Phase 2 (two-phase structure "does not exist in the current skill file"); TASK-TEMPLATE.md add PRE-GRILL + 4-item compound; `/design contract` add deep module check; `/visual-design` replace ASCII wireframes with 3-option approach.
  - **P2 Move long content to `references/`:** `/cr` + `/cr-feature` move pass-by-pass detail + anti-rationalization tables to `references/`.
  - **P3 Add `allowed-tools`** to `/cr`, `/cr-feature`, `/cr-security`.
  - **P4 Description audit** on each custom skill.
- Anti-rationalization tables for pipeline skills "live in **12 · Anti-Rationalization Tables**" and must be added to skill files "when you build the skills." [05][06]
- Templates page caveat: "These are starting-point scaffolds, not copies of production files. Some are copy-paste ready. Others need project context." [TPL]

---

## Notable

### Skills the canon DOCUMENTS that may NOT exist on disk
(Disk list given for cross-check: behavior-change, compound, cr, cr-security, debug, dep-update(empty), design, dev, evaluate-solution, explain, feature, hotfix, incident, migrate, notion-sync, perf, post-mortem, prioritize-tasks, queue, refactor, review-strategy, setup-strategy, spike, supabase, supabase-postgres-best-practices, tdd.)

- **`/cr-feature`** — canon documents it as ⛔ RETIRED v0.85, yet the **event-vendor action items still reference syncing it** (P1, P2, P3 all name `/cr-feature`). Documented-but-retired; not in the disk list. Internal canon contradiction (retired in Templates, still actively maintained in action items). [TPL][11]
- **`/scan-context`** — fully documented (3-pass drift detection, template page `skills/scan-context/SKILL.md` referenced) but **NOT in the disk skill list**. Likely-missing-on-disk candidate.
- **`/handoff`** — documented in detail (~60% context rule, 5 actions, anti-rationalization) but **no template page and NOT in disk list**.
- **`/simplify`** — appears as a feature-loop step and in /feature size pipelines, but **NOT in disk list** and no template page. (Note: a `/simplify` exists at the global/harness layer, not the project layer — out of scope for this cluster.)
- **`/prototype-interface`, `/prototype-ui`, `/visual-design`** — documented (06 + action items) but **none in disk list**; `/prototype` exists only as upstream Pocock (and per canon "not in the global store").
- **`/setup`** — documented as a custom bootstrap skill ("Build in `.claude/skills/setup/SKILL.md`") but **NOT in disk list**.
- **`/vibe-check`** — has a template page but **NOT in disk list**.
- **Upstream Pocock skills** the canon documents that are NOT project-disk skills (expected — they're the global "Matt Pocock" layer): `/grill-with-docs`, `/grill-me`, `/to-issues`, `/to-prd`, `/improve-codebase-architecture`, `/diagnose`, `/zoom-out`, `/prototype`, `/triage`, `/caveman`, `/write-a-skill`, `/git-guardrails-claude-code`, `/setup-pre-commit`. The disk list shows none of these as project skills — consistent with the "global layer has 15 generic Matt Pocock skills" framing.
- **Anthropic `skill-creator`** — documented as the recommended new-skill tool; upstream, not on the project disk list.

### Skills on disk the canon (these 4 pages) OMITS or barely documents
- **`dev`** — in disk list; **never named on any of the four cluster pages.** Undocumented in this cluster.
- **`explain`** — in disk list; **never named on these pages.** (Closest canon analogue is upstream `/zoom-out`, but `/explain` itself is not documented here.)
- **`spike`** — in disk list; canon provides template pages (skills/spike/SKILL.md + 6 spike agents) but **gives no purpose/pass description on pages 05/06/11.** Template-only.
- **`refactor`** — in disk list; template page exists (skills/refactor/SKILL.md + refactor-extractor agent) but **no purpose/pass description in this cluster.** Template-only.
- **`notion-sync`** — in disk list; **template page only, no descriptive documentation** in this cluster.
- **`queue`** — in disk list; referenced operationally (spawns @task-runner) and has template pages, but **no standalone purpose/pass section** on these pages. Template + incidental mentions only.
- **`post-mortem`** — in disk list; only referenced as a /hotfix dependency + template page; **no standalone description** in this cluster.
- **`review-strategy`, `setup-strategy`, `prioritize-tasks`** — in disk list and named in the Custom column / template pages, but **no purpose/pass detail** on these four pages beyond the name.
- **`dep-update(empty)`** — disk list flags it empty; canon documents `/dep-update` in **full** (2 modes, 5 phases, audit-depth table, security mode). **Canon is richer than disk here** — the disk skill is an empty stub against a fully-specified canon entry.

### Cross-cutting note
The canon's **purpose/structure documentation is concentrated in pages 05–06** (pipeline + workflow skills); **pages 11 + Templates are install/inventory layers.** Several disk skills (`spike`, `refactor`, `queue`, `notion-sync`, `post-mortem`, `review-strategy`, `setup-strategy`, `prioritize-tasks`) exist on disk and have template pages but receive **no behavioral documentation in this cluster** — their pass/step structure would live on other canon pages not in scope here (e.g. the individual SKILL.md template child pages, or pages 07–10/12–16). This cluster cannot confirm those skills are undocumented system-wide — only that they are undocumented *in pages 05/06/11/Templates*.
