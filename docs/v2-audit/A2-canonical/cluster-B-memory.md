# Cluster B — Memory & Context Model (CANON inventory, fact-only)

**Audit scope:** What the canonical "AI-Native Engineering System" (Notion) *declares* about the harness memory + context model. No recommendations. No design. Every claim cited.

**Sources read (with `as of` timestamps from fetch):**
- `04 · Context Docs` — https://app.notion.com/p/358e2971cd628181ac04fb8f50430fce (as of 2026-05-18T00:35:37Z)
- `07 · Memory System` — https://app.notion.com/p/358e2971cd628147a8c6d1f9ed880936 (as of 2026-06-05T00:13:24Z)
- `02 · The Four Layers` — https://app.notion.com/p/358e2971cd628135ad40fd2a1279203a (as of 2026-06-04T15:48:45Z) — *cross-reference; defines the layer the docs sit in*
- `03 · File Structure` — https://app.notion.com/p/358e2971cd62819cb46bf0c56ded95b4 (as of 2026-06-04T15:50:46Z) — *cross-reference; on-disk layout + ownership table*

All four are children of `Reference` → `AI-Native Engineering System`. Pages 04 and 07 reference but do not duplicate **08 · Settings & Permissions** (hook wiring) and the **Templates** page (template bodies); those were not fetched — page 04/07 already declare the purposes the audit asks for. Where a fact appears in only one page, the citation names that page; where pages agree, both are cited.

---

## Point 1 — Every context/memory FILE the canon defines

[CANON-DECLARES] for every row below. Citations in the Source column. "Writer+trigger" and "Reader+when" are reproduced from the canon's own language; where the canon is silent on a field, it is marked *(not stated)*.

| File | Purpose | Writer + trigger | Reader + when | Distinct-from-neighbors | Source |
|---|---|---|---|---|---|
| `.claude/SOUL.md` | "Engineering character of the system" — north-star definition of world-class code, engineering values held regardless of task pressure, the non-negotiables, and its own update mechanic. "What doesn't change under pressure, across projects, across machines." One page; if growing past a page, content is in the wrong file. | Human confirms; agent *proposes* additions during `/compound` if a new cross-project principle emerged. "Nothing is written automatically." Populated by `/setup` from the canonical Notion template. | Read at session start (per 03's `.claude/CLAUDE.md` annotation: "read SOUL.md + memory.md + TASKS.md + rituals.md"). | NOT process rules (CLAUDE.md), NOT architecture (AGENTS.md), NOT domain (CONTEXT.md), NOT project-specific mistakes (memory.md), NOT codebase traps (PITFALLS.md). Same content across all projects; travels with repo. | 04 §SOUL.md; 03 (structure + session-start annotation) |
| `CLAUDE.md` (project root) | "Process rules and coding discipline." Read at session start alongside global config. Sections: project overview, stack, commands, before-writing-code, dev-workflow tier table, keeping-docs-current table, TS rules, architecture rules, file/export conventions, code style, testing, safe-change rules, destructive-op rules (copied verbatim from 10 · Principles), commit format, before-finishing checklist, NEVER list. | Human or Doc Updater agent, "New process rule or coding constraint." | Read at session start "by any tool alongside global config." | Process/discipline only. SOUL = values; AGENTS = architecture; CONTEXT = why. | 04 §CLAUDE.md; 03 ownership table |
| `~/.claude/CLAUDE.md` (global) | "Personal behavior config — applies across all projects." Carries personal behavior preferences (how direct to be, when to push back, teaching style). | *(not stated explicitly; human)* | "applies across all projects" *(read timing not stated beyond global)* | Distinct from SOUL.md: global CLAUDE = personal behavior preferences; SOUL = engineering values. "Both travel everywhere; they answer different questions." | 04 §SOUL.md (Relationship to global CLAUDE.md); 03 structure |
| `AGENTS.md` (project root) | "Product context, architecture, scope, and open decisions" — the *what*. Store/module responsibilities, layer rules, routing table, golden exemplars, MVP scope, open decisions, resolved decisions table, rejected patterns, known limitations. | Human or Doc Updater agent, "Scope, architecture, or decisions change." | *(implied at design/before-code time; specific read timing not stated)* Lists required reading before writing code. | The *what* vs CONTEXT's *why*. Holds golden exemplars + open decisions. | 04 §AGENTS.md; 02 Layer 1; 03 ownership table |
| `CONTEXT.md` (project root) | The *why* behind the project — domain model, business rules, vision, the flywheel, how we ship, live data flow, state machines. "The hardest document to write and the most valuable." | `/grill-with-docs` • human, "During grilling sessions." Explicitly: "Don't write CONTEXT.md from scratch — let it grow through grilling sessions." | "The document a new agent reads to understand the domain without asking questions" *(read at onboarding/before-feature)* | The *why* vs AGENTS' *what*. Excludes implementation detail, ADR-material, and anything obvious from code. | 04 §CONTEXT.md; 02 Layer 1; 03 ownership table |
| `PITFALLS.md` (project root) | "Codebase-specific traps that produce silent bugs." Canonical statement of each trap (Area, Rule, Why, Symptoms, Source). "Only things specific to *this* codebase that an agent gets wrong on first attempt." Pattern-level; one entry per class of error; "permanent until retired." | Human confirms promotion from RECURRING-FINDINGS.md (threshold ≥3 or judgment); OR added directly for known traps. | "Implementing agents before writing code." Also "Referenced by pipeline pass prompts" (by heading, not restated inline). | Pattern-level/permanent vs memory.md (session-level) and RECURRING-FINDINGS.md (PR-level, pipeline-only). The *canonical* statement of a codebase rule. | 04 §PITFALLS.md; 07 §three-documents; 02 Layer 3; 03 ownership table |
| `.claude/memory.md` | "Corrected mistakes" / "What went wrong in sessions." Read at session start. Session-level granularity; one rule per corrected mistake. "Only rules earned by real mistakes — not aspirational." | Human + agent (prompted). Trigger: "When a mistake is corrected in session." Entry must be added "before the session ends or it's lost." A Stop hook proposes candidates at session end. | "Every agent at session start, before any work begins." | Session-level corrections vs PITFALLS (pattern-level canonical) and RECURRING-FINDINGS (pipeline-only). Rule: "Do not duplicate what's already in PITFALLS.md." | 04 §memory.md; 07 §three-documents; 02 Layer 3; 03 ownership table |
| `docs/RECURRING-FINDINGS.md` | "What the pipeline keeps catching." A log of findings with occurrence counts, file locations, and promotion status. PR-level granularity; tracks frequency across the codebase over time. | `/cr` Step 3b — "Automatically on every `/cr` run." "Don't edit this file manually." | "The pipeline synthesis step only — not implementing agents." | The only store NOT read by implementing agents. Accumulator/staging ground that *feeds* PITFALLS.md via promotion. | 07 §three-documents + §format; 02 Layer 3; 03 ownership table |
| `docs/solutions/` (+ `README.md`, `TEMPLATE.md`) | "Solved problems worth reusing." Each entry: Problem, What we tried first, Solution (file paths/function names), Why it works, When to reuse, When NOT to reuse, Related. | `/compound` proposes, human reviews. Trigger: "After features with non-obvious patterns." | Skimmed before writing code: "Skim docs/solutions/README.md — know what patterns are already solved." | Reusable solution patterns (positive — "do this") vs PITFALLS (negative traps — "avoid this"). | 07 §docs/solutions format; 04 (before-writing-code skim); 02 Layer 1; 03 ownership table |
| `docs/adr/` | "Architectural decision records." Write only when ALL three: hard to reverse, surprising without context, result of a real tradeoff. Format: Context, Decision, Alternatives considered, Consequences. File naming `NNNN-short-title.md`. | `/grill-with-docs` proposes, human confirms. Trigger: "When all three ADR conditions are met." | *(implied: skimmed before designing; per project CLAUDE convention "skim docs/adr/README.md")* | Locked architectural decisions w/ tradeoff record vs solutions (reusable patterns) and PITFALLS (traps). | 07 §docs/adr format; 02 Layer 1; 03 ownership table |
| `docs/TESTING.md` | "Confirmed behaviors (the spec), what's tested, known gaps, mock infrastructure." | `/tdd` agent, "Before writing any test." | *(implied: spec read before/during TDD)* | The spec/behavior ledger; not a memory store per se but listed in the Context layer. | 02 Layer 1; 03 structure + ownership table |
| `docs/ARCHITECTURE.md` | "Layering model, tech debt, migration path." Holds the tech-debt table used to identify one-shot blockers. | *(not stated in ownership table)* | Referenced when identifying tech-debt one-shot blockers. | Architecture/tech-debt ledger; distinct from AGENTS.md (live arch rules) and ADRs (point decisions). | 03 structure + §tech-debt-as-one-shot-blocker |
| `.claude/INDEX.md` | "Annotated index of external resources." | *(human; not stated explicitly)* "once external resources need to be findable." | Listed in AGENTS' "required reading before writing code." | Pointer/index to external resources; not a memory or trap store. | 02 Layer 1; 03 structure; 04 (AGENTS required-reading list) |
| `.claude/rituals.md` | "Weekly ritual tracking (last run dates)." | *(updated as rituals run; not stated)* | Read at session start (per `.claude/CLAUDE.md` annotation). | Ritual cadence tracker; not a knowledge store. | 03 structure |
| `TASKS.md` | "Agent task queue (replaces todo.md)." | Human + `/queue` (updates status markers), "When backlog changes; when tasks are claimed or completed." | Read at session start. | Work queue; not a memory store. | 03 structure + v0.16 ownership additions |
| `.claude/questions.md` (per worktree) | "Blocked questions from this worktree's task." | `@task-runner` writes, human answers, "When a parallel task hits a BLOCKING decision." | Human (answers). | Per-worktree blocking-question channel; ephemeral. | 03 structure + v0.16 ownership additions |
| `.claude/compound-draft-[slug].md` (per worktree) | "/compound draft before human review." | `/compound` (draft). | Human review before any promotion is written. | Staging buffer for /compound proposals (solutions/ + memory.md + SOUL.md candidates) before human gate. | 03 structure; 04 §SOUL update mechanic |
| `.claude/agentic-system-enabled` (sentinel) | "Sentinel: present = agent orchestration authorized." Gates /queue, @task-runner, @doc-updater auto-compound, auto-loader hook ONLY. Does NOT affect human dev workflows. | *(presence-based; human)* | Orchestration features check for presence. | Empty sentinel file, not content. | 03 structure + §sentinel scope |

*(Note: `TASK-TEMPLATE.md`, `agent-contract.md`, `AI-WORKFLOW.md`, `settings.json`, agents/, hooks/, skills/ are listed in 03's structure but are templates/config/orchestration, not memory/context knowledge stores — included here only for completeness of what 03 enumerates.)*

---

## Point 2 — The declared "how they differ and compound" model (page 07)

[CANON-DECLARES], reproduced from `07 · Memory System` → "The three documents" and "How they relate", verbatim distinctions:

**07 frames the memory system as "Three documents with three distinct jobs. Easy to conflate — the distinction matters."** The three are memory.md, RECURRING-FINDINGS.md, PITFALLS.md. (Note: docs/solutions/ and docs/adr/ also have formats on page 07 but are NOT part of the declared "three documents" of the memory system.)

| Axis | `memory.md` | `RECURRING-FINDINGS.md` | `PITFALLS.md` |
|---|---|---|---|
| **Source** | "You corrected an agent during a session." | "The pipeline flagged the same class of finding across multiple PRs." | "Promoted from RECURRING-FINDINGS.md (threshold or judgment) or added directly for known traps." |
| **Content** | "'We tried X, it broke, never do X' — as a direct constraint." | "A log of findings with occurrence counts, file locations, and promotion status." | "Canonical statement of each trap — Area, Rule, Why, Symptoms, Source." |
| **Granularity** | "Session-level. One rule per corrected mistake." | "PR-level. Tracks frequency across the codebase over time." | "Pattern-level. One entry per class of error, permanent until retired." |
| **Read by** | "Every agent at session start, before any work begins." | "The pipeline synthesis step only — not implementing agents." | "Implementing agents before writing code. Referenced by pipeline pass prompts." |
| **Grows** | "When you correct an agent and add the rule before the session ends." | "Automatically on every `/cr` run (Step 3b)." | "Via human-confirmed promotion, or direct addition for known traps." |
| **Discipline note (verbatim)** | "if you don't add the rule before the session ends, the mistake recurs." | "don't edit this file manually. Let the pipeline maintain it. Your job is to confirm or skip promotion candidates." | "pipeline pass prompts reference PITFALLS.md by heading rather than restating inline. This prevents drift between the review system and the authoritative doc." |

**[CANON-DECLARES] explicit overlap statement (07, "How they relate"):** "A pattern can appear in all three: Starts as a session correction (memory.md) · Keeps getting caught in review (RECURRING-FINDINGS.md) · Gets codified so agents avoid it at write time (PITFALLS.md)." — i.e., the canon *intends* the same pattern to live in three stores simultaneously, at three different lifecycle stages.

---

## Point 3 — Promotion / compounding flow between stores

[CANON-DECLARES]. Two distinct flows are documented.

### 3a. The findings → PITFALLS promotion flow (07 "How they relate" + "Promotion flow")

Declared pipeline (verbatim ASCII from 07):
```
Session mistake (you correct the agent)
        ↓
  memory.md  (read at session start — prevents repeat)

Pipeline catches a finding in a PR
        ↓
  RECURRING-FINDINGS.md  (accumulates, counts occurrences)
        ↓ (threshold ≥3 or judgment — you confirm)
  PITFALLS.md  (canonical, read by implementing agents)
        ↓
  Pipeline pass prompts reference PITFALLS.md  (enforced at review)
```

**Trigger to promote (verbatim):**
- "Auto-flag (threshold): any active finding with Occurrences ≥3 not previously flagged."
- "Judgment-flag: any finding assessed as high-impact at lower count — security gap, systemic pattern, something pipeline passes don't yet cover. Agent must provide one-sentence reasoning."

**Human gate (verbatim):** Promotion candidate is surfaced as `Confirm? (y/n)`.
- "On confirmation (y): write new PITFALLS.md entry, move RECURRING-FINDINGS.md entry to Promoted/retired."
- "On skip (n): leave in Active findings. Will re-flag after one more occurrence past threshold."

**Promotion candidate format (verbatim):**
```
1. [signature] — Occurrences: N.
   Reason: [threshold | judgment: <one sentence>].
   Suggested target: PITFALLS.md | /cr pass P# | docs/[other]
   Confirm? (y/n)
```
Note: suggested target may also be a `/cr` pass (P#) or `docs/[other]`, not only PITFALLS.md.

**Status field values (from RECURRING-FINDINGS schema):** `active | promoted-to-pitfalls | promoted-to-pass | retired`.

### 3b. The memory.md lifecycle / promotion (07 "Memory evolution" → "The lifecycle")

Declared lifecycle (verbatim ASCII):
```
Session mistake (agent corrected)
        ↓
  Stop hook proposes candidate
        ↓
  You review — add to memory.md with last_seen date
        ↓
  Agent reads at session start — update last_seen when it fires
        ↓
  Quarterly /compound review
        ↓
  Stale → remove or promote to PITFALLS.md
  Healthy → keep, reset last_seen
  Redundant → remove (PITFALLS.md already covers it)
```

**Human gate (verbatim):** "A Stop hook proposes memory.md candidates at session end... You review — add to memory.md." For SOUL.md: "Human confirms. Nothing is written automatically. The proposal goes in the /compound draft file alongside solutions/ and memory.md candidates" (04 §SOUL update mechanic).

**docs/solutions promotion (07 "Active maintenance"):** Two `/feature` done-criteria gates — (1) "If a feature changed a documented pattern → update the affected solution doc in place"; (2) "If a feature revealed a new footgun → check PITFALLS.md and propose an entry if missing." Generated/proposed by `/compound`, human reviews.

**SOUL.md promotion (04):** "reviewed during /compound. If a new principle emerged... that should apply across all future work everywhere, the agent proposes an addition here. Human confirms."

---

## Point 4 — Line limits, freshness/staleness, and indexing rules

[CANON-DECLARES]:

- **SOUL.md size limit:** "SOUL.md is one page. If it's growing past a page, content is in the wrong file." (04)
- **memory.md `last_seen` field:** mandatory per-entry. "The `last_seen` field enables the quarterly stale review in `/compound` Step 7. Update it when the rule fires." (04). Format fields: `name`, `type` (feedback|convention|gotcha|architecture), `last_seen: YYYY-MM-DD`, then the rule, `Why:`, `How to apply:`. (04)
- **memory.md staleness review:** "Every ~90 days, run Step 7 of `/compound` to flag entries not seen in 90+ days, entries that contradict current patterns, and entries redundant with PITFALLS.md. The review surfaces candidates; nothing is modified automatically." (07 "Stale entry review"). Lifecycle outcomes: Stale → remove or promote to PITFALLS.md; Healthy → keep, reset last_seen; Redundant → remove. (07)
- **RECURRING-FINDINGS example-location cap:** "Example locations: file:line (cap at 5, drop oldest when full)." (07 format)
- **RECURRING-FINDINGS signature rules:** "short, stable, lowercased, hyphen-separated... Same class of error → same signature." (07)
- **RECURRING-FINDINGS promotion threshold:** Occurrences ≥3 (auto-flag). (07; 02 Layer 2)
- **docs/solutions indexing/tagging trigger:** "Add YAML frontmatter tags when directory grows past ~10 entries." (07). Seed count: "6 entries is a good starting point." (07)
- **docs/solutions seed count (alt phrasing, 04/02):** README skimmed before code; canon recommends seeding ~6 entries.
- **Changelog-to-PITFALLS review (staleness for PITFALLS):** "After applying any changelog entry — especially one that fixes a previous workaround or retires a previous approach — check PITFALLS.md for entries whose workarounds have been superseded. Stale entries should be either (a) removed... or (b) updated... This prevents context rot where agents apply retired workarounds because PITFALLS.md still recommends them." (07)
- **PITFALLS permanence:** entries are "permanent until retired" (07 granularity row).
- **memory.md add-or-lost rule:** "Add the entry before the session ends or it's lost." (04)
- **No explicit line/byte limits stated** for CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md, memory.md (only SOUL.md has a stated size cap). *(canon silent)*

---

## Point 5 — Places the canon admits overlap / redundancy / "this is confusing"

[CANON-DECLARES] — the canon's own admissions of conflation risk and intentional redundancy:

1. **07 opening line:** "Three documents with three distinct jobs. **Easy to conflate — the distinction matters.**"
2. **02 Layer 3:** "Three distinct documents. **Easy to conflate — don't.**"
3. **07 "How they relate":** "**A pattern can appear in all three**" — the canon explicitly sanctions the same knowledge living in memory.md AND RECURRING-FINDINGS.md AND PITFALLS.md at once (different lifecycle stages). This is declared as intended, not a defect.
4. **memory.md de-dup rule (04):** "Rules for adding entries: ... **Do not duplicate what's already in PITFALLS.md.**" — an explicit instruction acknowledging memory.md and PITFALLS.md can overlap.
5. **memory.md stale-review "Redundant" outcome (07):** "Redundant → remove (PITFALLS.md already covers it)." — the lifecycle itself expects memory.md entries to become redundant with PITFALLS.md and need pruning.
6. **Drift-prevention rule (07 + 04):** "pipeline pass prompts reference PITFALLS.md by heading rather than restating inline. **This prevents drift between the review system and the authoritative doc.**" — canon names drift between the pass prompts and PITFALLS.md as a hazard it is actively guarding against.
7. **Changelog-to-PITFALLS review (07):** explicitly names "**context rot**" — agents applying retired workarounds because PITFALLS.md still recommends them — as a failure mode to police.
8. **SOUL vs global CLAUDE.md (04):** the canon spends a dedicated paragraph distinguishing them ("Both travel everywhere; they answer different questions") — an acknowledgment that these two are confusable.
9. **04 SOUL "What does NOT belong" list:** enumerates five *other* files (CLAUDE.md, AGENTS.md, CONTEXT.md, memory.md, PITFALLS.md) that SOUL content could be mistaken for — an admission that the boundaries between all six are non-obvious enough to require an explicit exclusion list.

---

## Point 6 — Version markers / contradictions / draft notes on these pages

[CANON-DECLARES]:

- **Fetch timestamps differ across pages** (page state "as of"): 04 = 2026-05-18; 07 = 2026-06-05; 02 = 2026-06-04; 03 = 2026-06-04. Page 04 is ~2.5 weeks older than the other three. *(observed metadata, not page body)*
- **03 explicit version marker:** "**New in v0.16 — ownership table additions (Notion table — add these rows manually):**" lists SOUL.md, TASKS.md, .claude/questions.md rows. **This is a standing draft/TODO note in the canon** — the rows are declared but the page admits they must be "add[ed] manually" to the ownership table, i.e., not yet integrated.
- **03 has a duplicated `## Naming conventions` heading** — appears twice (once after the v0.16 additions block, once again immediately below). The first instance contains only the v0.16 additions; the second is the real naming-conventions list. *(structural artifact / likely editing residue)*
- **07 forward-reference loop:** under docs/solutions "Active maintenance," the text says "For the stale review process and the session-end hook... see **07 · Memory System**." — page 07 **references itself** as the place to find this. *(self-referential pointer; likely a copy artifact from a template where this block lived elsewhere)*
- **Dreaming feature note (07, draft/conditional):** "Anthropic's **Dreaming** feature (announced Code with Claude 2026, currently in research preview)... When Dreaming becomes generally available, evaluate replacing the session-end hook with it." — a forward-looking conditional, not yet active. Marked research-preview.
- **No explicit "DRAFT" watermark** on any of the four pages; no superseded/deprecated banners. *(canon silent)*
- **Cross-reference targets not yet verified in this cluster:** 07 points to **08 · Settings & Permissions** for the session-end Stop hook script + settings.json wiring; that page was not fetched. The *existence* of the hook is declared in 03 (`session-end.sh # Stop: propose memory candidates`) and 07, so the claim is corroborated across two pages even without 08.

---

## Notable — where the canon's own memory model is ambiguous or self-overlapping (this is what V2 must fix)

These are observations about *the canon's internal consistency*, drawn strictly from the cited text — not proposals.

1. **The "three documents" of the memory system are not the only memory-bearing files, and the canon is inconsistent about the boundary.** Page 07 titles the system "Three documents" (memory.md, RECURRING-FINDINGS, PITFALLS) — but the same page also defines formats for **docs/solutions/** and **docs/adr/**, and page 02's Layer-1 "Context" list folds CONTEXT/AGENTS/PITFALLS/adr/solutions/TESTING/memory/INDEX all together. So PITFALLS.md and memory.md are claimed by BOTH "Layer 1 — Context" (02) AND "Layer 3 — Memory" (02/07). The same files are assigned to two different layers depending on which page you read.

2. **The canon explicitly sanctions triple-storage of the same knowledge** ("A pattern can appear in all three") while simultaneously instructing de-duplication ("Do not duplicate what's already in PITFALLS.md," "Redundant → remove"). Whether a pattern *should* live in three stores or be pruned to one is governed by two rules that point in opposite directions; the reconciling principle (it's the same knowledge at different *lifecycle stages*) is stated only in prose, not encoded in any tooling described.

3. **No store is declared as the single source of truth across the set.** PITFALLS.md is called "the canonical statement" *for codebase traps*; SOUL.md is "one page" canonical *for values*; AGENTS.md holds open decisions; CONTEXT.md holds business rules. There is no declared rule for what happens when, e.g., a business rule in CONTEXT.md contradicts a trap in PITFALLS.md, or a memory.md entry contradicts an AGENTS.md resolved-decision. The de-dup rules only cover the memory.md↔PITFALLS.md pair.

4. **memory.md staleness is policed (90-day last_seen review); PITFALLS.md staleness is policed by a *different, unscheduled* mechanism (changelog-to-PITFALLS review); RECURRING-FINDINGS has a cap-at-5/drop-oldest rule; CONTEXT/AGENTS/CLAUDE/solutions have no declared freshness rule at all.** Freshness governance is per-file and uneven, with three different triggers (calendar-quarterly, changelog-driven, capacity-driven) and several files ungoverned.

5. **Read-time is unspecified for most files.** Only memory.md ("session start, before any work"), SOUL/rituals/TASKS (session start, per 03 annotation), PITFALLS ("before writing code"), and solutions/README ("skim before code") have explicit read triggers. AGENTS.md, CONTEXT.md, ADRs, ARCHITECTURE.md, INDEX.md, TESTING.md have implied-but-unstated read timing. An agent cannot derive from the canon exactly *when* it must read AGENTS.md vs CONTEXT.md.

6. **Ownership of RECURRING-FINDINGS → memory.md has no path.** The promotion graph flows findings→PITFALLS and memory→PITFALLS, but RECURRING-FINDINGS findings never feed memory.md, and memory.md never feeds RECURRING-FINDINGS. memory.md and the pipeline-findings loop are two separate funnels that only converge at PITFALLS.md. A recurring pipeline finding and a session correction about the *same* issue are tracked independently until both happen to be promoted.

7. **Draft residue is present in the canonical layout doc (03):** an un-applied "v0.16 ownership additions (add these rows manually)" block and a duplicated `## Naming conventions` heading mean the ownership table the audit relies on is itself declared-incomplete by its own page.

---
*End of inventory. Fact-only. No proposals. All claims tagged [CANON-DECLARES] with page citations in-line.*
