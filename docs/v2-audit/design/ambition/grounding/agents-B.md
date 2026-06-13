# Grounding Pass — Agent Bodies, Batch B

Read in full from `.claude/agents/`. Goal: catch every embedded, load-bearing mechanism so none is summarized away in V2. Eight agents below; all eight files present and non-empty.

The clearest precedent for the risk this pass guards against: **golden exemplars**. That mechanism is wired here — `lens-composition` body line 25 literally enforces "golden exemplar divergence" as a Must Fix. Prior design summaries dropped it. Below, each agent's wired mechanisms are quoted with file:line.

---

## lens-cascade

- **Actual job:** A single-failure-class adversarial specialist. Given a design contract or a branch diff, it traces one question only — for each failure path, what breaks, who catches it, how far it propagates, and what the user/downstream system ultimately observes (blast radius). It does not fix; it surfaces.
- **Embedded mechanisms that must carry forward:**
  - **Fixed output contract template** (lines 41-53): `FINDING / EVIDENCE / SEVERITY / BLAST RADIUS / RECOMMEND`, one block per cascade path. BLAST RADIUS is a *required* field unique to this lens (line 65) — it is the load-bearing differentiator; a generic cascade reviewer would drop it.
  - **Explicit clean-statement contract** (lines 56-59): "A clean lens is meaningful signal" — must emit `## Cascade Construction — Clean`, never silently omit. This pairs with reviewer.md line 93 ("state it explicitly rather than omitting").
  - **Hard rules as machine gates** (lines 63-67): every FINDING cites `file:line`; every RECOMMEND actionable in one PR; project-specific SEVERITY rubric where **High = silent wrong value shown to user** (the domain's named worst case, line 36).
  - **Input contract** (lines 12-17): receives mode + input + pre-read context (`CONTEXT.md, AGENTS.md, PITFALLS.md`) *passed in by reviewer* — it does NOT re-read them. Isolation depends on this.
  - **Frontmatter:** `tools: Read,Glob` · `model: sonnet` · `permissionMode: plan` (read-only, cannot mutate).
- **V2 disposition flag + why:** **KEEP.** A distinct attack lens with a non-redundant output field (blast radius). Under the clarity-over-minimalism charter this earns its file. **Re-audit `model: sonnet` on Opus 4.8** — adversarial cascade tracing across layers is exactly the reasoning-heavy work where the upgraded model pays off; one of the four parallel lenses, so cost multiplies but quality of the gate is load-bearing.
- **Autonomy hook:** Yes. In a bug→PR flow this lens runs inside `reviewer` (implementation mode, /cr Pass 11) over the autonomous diff. Its High findings (line 89, reviewer) block the PR from progressing — making it a natural automated quality gate for unattended PRs. Cloud-scheduled review of an open PR diff would invoke it the same way.

---

## lens-composition

- **Actual job:** A single-failure-class adversarial specialist that asks only "what breaks when this module is used alongside existing ones?" — layer-rule violations, naming collisions, shared-state conflicts, circular deps, and crucially **golden-exemplar divergence** and **silent new standards**.
- **Embedded mechanisms that must carry forward:**
  - **GOLDEN EXEMPLAR ENFORCEMENT** (line 25): "does this follow the designated golden exemplar pattern in AGENTS.md, or does it diverge without a documented reason? Divergence without reason is a silent new standard." **This is the exact mechanism the carry-forward ledger named as the one prior design dropped.** It is wired here as a checked attack vector, not prose. Must survive V2.
  - **"Silent new standard" → always Must Fix** (lines 30, 59): "does this introduce a second way to do something the codebase already does one way? If yes, that's always Must Fix." Encoded as a SEVERITY override: line 60 — "High = introduces silent new standard or breaks layer contract." This is a hard escalation rule, not a judgment call.
  - **Reads AGENTS.md architecture rules as the contract** (line 24): component-contains-business-logic and util-imports-from-store are named concrete checks tied to AGENTS.md.
  - **Reads `docs/solutions/` and PITFALLS.md for pattern contradictions** (line 29): "which is current?" — cross-references the solutions catalog and pitfalls ledger as live inputs.
  - **Fixed output contract** (lines 36-47): `FINDING / EVIDENCE / SEVERITY / RECOMMEND`, EVIDENCE must cite "exact file, AGENTS.md section, or pattern."
  - **Clean-statement contract** (lines 49-53).
  - **Frontmatter:** `tools: Read,Glob` · `model: sonnet` · `permissionMode: plan`.
- **V2 disposition flag + why:** **KEEP — highest priority of this batch.** It carries the golden-exemplar mechanism and the silent-new-standard auto-escalation. These are the codebase's anti-drift immune system. **Re-audit `model: sonnet` on Opus 4.8** — cross-referencing AGENTS.md, solutions/, PITFALLS.md and reasoning about "which is current" is exactly where the stronger model reduces false-clean verdicts.
- **Autonomy hook:** Yes, and it is the most important autonomy gate here. An autonomous bug→PR agent will not know the golden-exemplar pattern unless this lens enforces it on the diff. Wiring this lens into the unattended /cr Pass 11 is what prevents a fleet of parallel agents from each silently inventing a second way to do things. Cloud-scheduled drift audits could run this lens standalone over recent merges.

---

## refactor-extractor

- **Actual job:** Extracts *exactly one* module from a source file per invocation — reads a plan file, moves the listed symbols (pure move, zero logic change), adds transitional re-exports, runs all verifications, and commits. Spawned by `/refactor` for splits of 4+ modules.
- **Embedded mechanisms that must carry forward:**
  - **PLAN FILE AS SOURCE OF TRUTH** (line 13): "Read `.claude/refactor-plan.md` — this is your source of truth, not your context window." Reads the next `[ ]` module from a state list (line 14), and **writes back** `[x] module_name` on completion (line 64). This is a durable cross-invocation state machine on disk — survives context loss, enables resumable multi-agent extraction.
  - **BLOCKING HAND-OFF PROTOCOL** (line 17): on any baseline verification failure → "STOP, write a blocking note in `.claude/questions.md`, and stop." `.claude/questions.md` is a wired hand-off channel to the human/orchestrator.
  - **Two-hats discipline encoded** (lines 30-32, 68): "Notice a bug? Write it in your summary under 'Notes for next extraction.' Fix it later. Different hat." Logic regression → **REVERT** the extraction (line 49). This is the CLAUDE.md refactor rule made executable.
  - **Ecosystem-keyed re-export table** (lines 35-42): TS/Python/Go/Java each get a specific re-export syntax; Go has none → update callers from the callsite map in the plan.
  - **Transitional marker convention** (line 42): every re-export tagged `// transitional — remove after callers updated`.
  - **Commit message template** (lines 57-62) and **output template with "Notes for next extraction"** (lines 76-87) — the latter is the inter-agent baton between sequential extractions.
  - **Frontmatter:** `tools: Read,Edit,Bash,Glob,Grep` · `model: sonnet` · `permissionMode: default` (this one **writes and commits** — the only mutating agent in the batch).
- **V2 disposition flag + why:** **KEEP.** The plan-file state machine + blocking hand-off is exactly the kind of durable mechanism the charter says earns its place; do not collapse it into prose. **Re-audit `model: sonnet` on Opus 4.8** — pure mechanical moves are sonnet-appropriate and cost-sensitive (runs N times for N modules), but the "spot a logic regression and revert" judgment leans toward the stronger model; lean KEEP-sonnet unless regressions slip. **Not a disable-model-invocation candidate** — it is genuinely model-driven work, not a deterministic side-effect.
- **Autonomy hook:** Yes — this is already an autonomy primitive. The plan file + questions.md hand-off means a fleet/cloud-scheduled flow can drive a large refactor across many invocations without a human in the loop, each invocation resuming from disk state and stopping cleanly on the first failure. Pair with `permissions.allow` coverage for its Bash/commit calls (background agents get no prompts).

---

## reviewer

- **Actual job:** The adversarial-review **orchestrator**. Reads context files once, spawns four isolated lens agents in parallel, deduplicates and consolidates their findings into a tiered Must-Fix/Address/Advisory report. Two modes: design (from `/grill-with-docs` Phase 2) and implementation (/cr Pass 11). Surfaces only; never fixes.
- **Embedded mechanisms that must carry forward:**
  - **FAN-OUT TO FOUR NAMED LENS SUB-AGENTS IN PARALLEL** (lines 38-46): single message, four tool calls — `@lens-assumption`, `@lens-composition`, `@lens-cascade`, `@lens-abuse`. **Note: this batch only contains 2 of the 4 lenses; `@lens-assumption` and `@lens-abuse` are referenced but not in this read set — flag for the sibling batch.**
  - **ISOLATION INVARIANT** (lines 39-40): "Each lens agent receives only its input + context — no cross-lens contamination. Isolation is required: an assumption-violation lens primed on cascade failures produces contaminated findings." This is a load-bearing architectural property, not a nicety — V2 must not "optimize" it into a single shared-context reviewer.
  - **CONTEXT PRE-READ + PASS-DOWN** (lines 30-34, 50-52): reviewer reads `CONTEXT.md, AGENTS.md, PITFALLS.md` (+ `docs/TESTING.md` in impl mode) and passes content directly — "Do not ask agents to re-read these." Saves N re-reads and guarantees all lenses see identical context.
  - **STOP-AND-SURFACE escalation conditions** (lines 23-26, 92): any High finding touching auth/RLS/DB boundary, a cascade reaching outside `SCOPE`, or a finding needing un-covered domain knowledge → halt and escalate.
  - **TIERED REPORT TEMPLATE** (lines 61-81): Must Fix (High) / Address Before /cr (Medium) / Advisory (Low) / Clean Lenses / Summary with counts and "Blocking progression" line.
  - **GATE SEMANTICS** (line 89): "High findings block: to implementation (design mode) or to /cr progression (implementation mode)." This agent is the blocking gate between phases.
  - **Dedup rule** (line 57): same root issue from two lenses → list once with both tags.
  - **Output to stdout only** (line 22): "Does not write files."
  - **Frontmatter:** `tools: Read,Glob` · `model: sonnet` · `permissionMode: plan`.
- **V2 disposition flag + why:** **KEEP — structural backbone.** This is the orchestration spine that makes the four lenses a gate rather than four loose opinions. Under the clarity charter, keep the explicit fan-out. **Re-audit `model: sonnet` on Opus 4.8** — the consolidation/dedup/escalation judgment is reasoning-dense and gate-critical; strong candidate to promote to the stronger model even if the leaf lenses stay sonnet. Do NOT merge into /cr's prose — its isolation invariant and fan-out are the value.
- **Autonomy hook:** Yes — central. In autonomous bug→PR, this is the gate that decides whether an unattended diff may progress. Its High-finding block (line 89) and STOP-AND-SURFACE on auth/RLS (line 92) are exactly the guardrails that let a fleet open PRs without a human pre-reading every diff. Cloud-scheduled nightly review of open PRs would invoke reviewer in implementation mode. For unattended use, the four child lenses' Bash/Read patterns must be pre-allowed.

---

## security-reviewer

- **Actual job:** Runs the `/cr-security` review over diffs touching auth, authz, RLS, middleware, data boundaries, credentials, or public handlers. Read-only. Returns **MUST FIX only** — there is no IMPORTANT/NITS tier in security.
- **Embedded mechanisms that must carry forward:**
  - **CONTEXT READ CONTRACT** (lines 17-20): before reviewing, reads `AGENTS.md → Architecture` (data-layer boundaries), `CONTEXT.md → auth model and tenant isolation`, `PITFALLS.md → security entries`. PITFALLS is a live input.
  - **TWO-PASS + SUPABASE CHECKLIST** (lines 22-49): Pass 1 Auth/Authz, Pass 2 Data Boundary Integrity, then a **named Supabase-specific checklist** — RLS-disabled tables, `auth.uid()` vs `user_metadata`, UPDATE-without-SELECT policy, views without `FORCE ROW LEVEL SECURITY`, storage.objects missing INSERT+SELECT+UPDATE policies, JWT staleness (`auth.jwt()` vs `getSession()`), service_role reachable from browser, **SECURITY DEFINER without explicit REVOKE EXECUTE** (line 48 — directly mirrors the CLAUDE.md migration rule). This checklist is the load-bearing asset; it encodes the project's hard-won RLS pitfalls.
  - **SINGLE-TIER OUTPUT CONTRACT** (lines 50-58): `### MUST FIX — [file:line] issue → fix`; if clean, exactly "No security findings." Explicitly forbids IMPORTANT/NITS, code summary, and encouragement.
  - **AUTO-TRIGGER CONDITION in frontmatter** (lines 3-7): "Use when a task diff includes any of these areas, **or when @task-runner detects auth-adjacent file changes.**" This is a wired auto-invocation hook from `@task-runner` — must carry forward.
  - **Frontmatter:** `tools: Read,Grep,Glob` · `model: sonnet` · `permissionMode: plan`.
- **V2 disposition flag + why:** **KEEP — non-negotiable.** The Supabase checklist is irreplaceable institutional knowledge and maps 1:1 to CLAUDE.md/PITFALLS rules. **Re-audit `model: sonnet` on Opus 4.8 — strongest upgrade candidate in the batch:** security false-negatives are the most expensive failure mode (RLS/tenant-isolation bypass), and the charter's world-class bar argues for the strongest model on the security gate specifically. Possible **MERGE relationship to note:** it overlaps conceptually with a security lens inside `reviewer`, but its single-tier MUST-FIX-only contract and Supabase checklist are distinct enough to stay separate — keep as the dedicated `/cr-security` gate, not folded into the four-lens reviewer.
- **Autonomy hook:** Yes — critical for autonomy. Its `@task-runner` auto-trigger (line 6) means an autonomous pipeline can self-route auth-adjacent diffs to security review without human judgment about whether security review is needed. For bug→PR on auth/RLS code this is the gate that must pass before merge. CLAUDE.md already mandates `/cr-security` alongside `/cr` for auth/middleware/RLS diffs — this agent is its executable form.

---

## solution-evaluator

- **Actual job:** Researches and produces a *named* build-vs-buy recommendation (never a list of options) for a capability/dependency. Spawned by `/evaluate-solution`. Uses live `web_search` for real pricing and community-health data, answers seven required questions, and writes one eval file.
- **Embedded mechanisms that must carry forward:**
  - **WRITES ONE NAMED FILE** (lines 22, 157): `.claude/solution-eval-[slug].md`, using "the format from `skills/evaluate-solution/SKILL.md` — Output section." Cross-references the skill file as the canonical template — that coupling must survive.
  - **SEVEN REQUIRED QUESTIONS as a hard contract** (lines 83-134): Fit / cost-at-current-scale / cost-at-10x / operational cost / lock-in (Low|Med|High) / build cost / community health (Active|Slow|At Risk|Abandoned). "An evaluation with missing answers is not complete" (line 86).
  - **LIVE-RESEARCH MANDATE** (lines 38-40, 177): "Do not rely on training data for pricing or health signals — both change. Use web_search." Includes scripted query templates (lines 42-78).
  - **RECOMMENDATION DECISION LOGIC** (lines 135-153): explicit branch rules — clear winner / build-cheaper-over-18-months / core-differentiation→build / no-fit→build / close→name-a-lean-and-ask-one-question. Hard rule: **"Never produce: 'It depends on your priorities.' Name the answer."**
  - **INCOMPLETE GATE + "Human steps required" protocol** (lines 184-209): if Q2/Q3 cost data is missing → mark `Recommendation: INCOMPLETE — pending human steps above`, list specific human actions, and do not finalize until data supplied. A wired human-in-the-loop hand-off.
  - **Surface-to-human summary template** (lines 160-173).
  - **Frontmatter:** `tools: read_file,list_files,bash,web_search` · `model: sonnet` · `permissionMode: plan`. **Note the lowercase/snake_case tool names** (`read_file`, `web_search`) — inconsistent with the `Read,Glob,WebSearch` casing used by every other agent in the batch; flag as a possible drift/portability bug for V2.
- **V2 disposition flag + why:** **KEEP, with CHANGE-DELIVERY on the tool names.** The seven-question contract + named-recommendation discipline is exactly the kind of mechanism the charter wants explicit. **Re-audit `model: sonnet` on Opus 4.8** — multi-source financial reasoning + 18-month TCO modeling is reasoning-heavy and run infrequently (cost-insensitive), so promote. **Normalize the tool casing** to match the harness (`Read`, `WebSearch`, `Bash`) or it may silently fail to bind under V2's tool registry.
- **Autonomy hook:** Partial. Triggerable from an autonomous flow (incident route → "evaluate build vs buy") and writes a durable file, so a cloud-scheduled "re-audit our dependency health quarterly" routine could invoke it. But its INCOMPLETE/human-steps gate (lines 187-209) deliberately blocks full autonomy when pricing data is private — by design it hands back to a human rather than guessing. That gate is correct and should be preserved, not autonomized away.

---

## spec-writer

- **Actual job:** Writes confirmed-behavior entries into `docs/TESTING.md` from a task contract + `@explorer` findings, *before* implementation. Never invents behaviors; only confirms what is explicitly in scope. Never edits implementation files.
- **Embedded mechanisms that must carry forward:**
  - **READS AND MATCHES docs/TESTING.md FORMAT EXACTLY** (lines 17-19, 38-40): "understand the existing format and structure exactly. Match it. Do not invent a new format." `docs/TESTING.md` is both the input template and the write target. This is a golden-exemplar-style "match the existing artifact" mechanism for the spec/test layer.
  - **INPUT CONTRACT** (lines 20-23): consumes the **task contract** and **@explorer findings** — a wired hand-off from an upstream `@explorer` agent (referenced, not in this batch — flag for sibling batch).
  - **NEVER-INVENT GATE** (lines 27-31): behavior implied but not stated → flag as open question, do not spec. This is what keeps the spec honest.
  - **ONE-BEHAVIOR-PER-ENTRY + edge-cases-are-behaviors rules** (lines 33-39): empty/error/loading/one/many/null each a separate entry.
  - **OUTPUT TEMPLATE** (lines 43-54): writes entries to TESTING.md, then returns `Entries written / Open questions / Not in scope`.
  - **Frontmatter:** `tools: Read,Edit,Glob` · `model: sonnet` · `permissionMode: plan` (writes only to docs/TESTING.md).
- **V2 disposition flag + why:** **KEEP.** It is the spec gate that feeds TDD (CLAUDE.md mandates tests-first for pure functions); its "match TESTING.md exactly" + "never invent" rules are the anti-drift mechanism for the test layer, analogous to golden exemplars for code. `model: sonnet` is appropriate (format-matching, low-ambiguity); **lower-priority Opus re-audit** — promote only if spec quality proves a bottleneck. **Possible disable-model-invocation consideration:** No — it is model-driven authoring, not a deterministic side effect.
- **Autonomy hook:** Yes. In an autonomous feature/bug→PR pipeline this runs after `@explorer` and before implementation, producing the spec the TDD loop tests against. Its open-questions output is the natural human-escalation point when a behavior is ambiguous — i.e., it knows when to stop and ask, which is what makes it safe inside an unattended loop.

---

## spike-adversarial-verifier

- **Actual job:** Adversarially attacks a spike's synthesis output to find what the writers assumed and what would invalidate the recommendation. Spawned by `@spike-orchestrator` after synthesis. Explicitly tries to *break* the recommendation — not be balanced.
- **Embedded mechanisms that must carry forward:**
  - **CONSUMES STRUCTURED SYNTHESIS FLAGS** (lines 16-21, 26-31): receives the confirmed question + full synthesis incl. reflect answers + all research-pass outputs. **Starts with the reflect answers** (the synthesis agent's own admissions of uncertainty) as first targets, and hunts every `[SYNTHESIS ASSUMPTION]` flag. This is a tight contract with the spike pipeline's upstream output schema — those flags must exist for this agent to work.
  - **"REFLECT QUESTION 3 = THE LOAD-BEARING ASSUMPTION"** (lines 33-38): a specific, named protocol — the synthesis agent designates its single most-depended-on assumption as reflect Q3, and this verifier tests it directly. A precise inter-agent convention that V2 must keep on both ends.
  - **SOURCE-QUALITY CHECKS with explicit staleness thresholds** (lines 52-58): vendor-incentive citations, >18mo for fast-moving libs / >36mo for stable, "production" claims that are actually toy examples.
  - **FIXED OUTPUT TEMPLATE with tiers** (lines 72-89): Critical / Significant / Minor, plus a distinctive **"What I could not find to challenge"** section (lines 80-82) — the steelman residue that marks the strongest parts of the recommendation. Unusual and valuable; do not drop.
  - **DECISION-RIGHTS BOUNDARY** (lines 88-90, 93-94): "Critical findings lower confidence. The orchestrator decides how much. You report. You don't decide." And it runs **in parallel with `@spike-user-verifier`** (line 93, referenced, not in this batch).
  - **NEGATIVE CONSTRAINTS** (lines 60-67): does not rewrite the recommendation, no counter-recommendation, no praise, no softening.
  - **Frontmatter:** `tools: WebSearch,WebFetch,Read` · `model: sonnet` · `permissionMode: plan` (it actively re-searches the web to confirm/contradict claims).
- **V2 disposition flag + why:** **KEEP.** The reflect-Q3 protocol and the "what I could not break" steelman section are non-obvious wired mechanisms that a summary would flatten. Aligns with the charter's research rigor. **Re-audit `model: sonnet` on Opus 4.8** — breaking a recommendation by finding contradicting sources is exactly reasoning-and-research-heavy work where the stronger model finds harder-to-spot flaws; promotion candidate, and spikes are infrequent so cost is not a barrier.
- **Autonomy hook:** Yes. A cloud-scheduled or fleet-driven `/spike` can run end-to-end with this verifier as the automated adversary that lowers confidence before any recommendation is acted on — a self-checking research loop. Its report-don't-decide boundary (line 90) keeps the orchestrator (or human) as the final arbiter, which is the right shape for an unattended pipeline.

---

## CARRY-FORWARD ALERTS (mechanisms this batch was most at risk of losing)

1. **Golden-exemplar enforcement** — `lens-composition.md:25`. The exact mechanism the ledger flagged as dropped before. It is a *checked attack vector* ("divergence without reason = silent new standard"), not prose. MUST survive V2.
2. **"Silent new standard → always Must Fix" auto-escalation** — `lens-composition.md:30,59-60`. A hard SEVERITY override, not a judgment call. The anti-drift rule for a parallel agent fleet.
3. **Plan-file state machine + `.claude/questions.md` blocking hand-off** — `refactor-extractor.md:13-17,64`. Durable cross-invocation state on disk that makes resumable, unattended multi-module refactors possible. Easy to summarize into "reads a plan and commits" and lose the resumability + STOP protocol.
4. **Lens isolation invariant + four-way parallel fan-out** — `reviewer.md:38-46`. "No cross-lens contamination" is load-bearing architecture; a V2 "simplification" to one shared-context reviewer would silently degrade the gate. Also: 2 of the 4 lenses (`@lens-assumption`, `@lens-abuse`) are NOT in this batch — confirm they survive elsewhere.
5. **Security Supabase checklist** — `security-reviewer.md:40-49`. Eight named Supabase/RLS checks (incl. SECURITY DEFINER + REVOKE EXECUTE, FORCE RLS on views, storage policy triad) that encode the project's hard-won pitfalls 1:1 with CLAUDE.md. Irreplaceable; do not abstract into "do a security review."
6. **`@task-runner` auto-trigger for security review** — `security-reviewer.md:6`. The wired condition that lets an autonomous pipeline self-route auth-adjacent diffs to the security gate without human judgment.
7. **Seven-question contract + "name the answer / INCOMPLETE human-steps gate"** — `solution-evaluator.md:83-153,187-209`. The decision discipline and the human-in-the-loop block when pricing is private.
8. **spike reflect-Q3 protocol + "what I could not find to challenge" steelman section** — `spike-adversarial-verifier.md:33-38,80-82`. Precise two-ended inter-agent convention and the steelman residue; both flatten under summarization.
9. **spec-writer "match TESTING.md exactly / never invent"** — `spec-writer.md:17-31`. Golden-exemplar-equivalent for the test layer; the gate that keeps autonomously-generated specs honest.
10. **Fixed per-agent OUTPUT TEMPLATES + mandatory clean-statements** — all eight agents. Each has a strict report contract (BLAST RADIUS field, MUST-FIX-only tier, tiered Critical/Significant/Minor, etc.). These templates ARE the inter-agent wiring; replacing them with free-form prose breaks downstream consolidation (esp. reviewer's dedup).

**Cross-batch flags for the sibling pass:** referenced-but-not-in-this-batch agents — `@lens-assumption`, `@lens-abuse` (reviewer), `@explorer` (spec-writer), `@spike-orchestrator` / `@spike-user-verifier` (spike-adversarial-verifier), `@task-runner` (security-reviewer). Confirm these survive V2 or the hand-off contracts above dangle.

**Tool-casing drift:** `solution-evaluator.md:9` uses `read_file,list_files,bash,web_search` (snake_case) while every other agent uses `Read,Glob,Bash,WebSearch`. Normalize in V2 or risk a silent tool-binding failure.

**Model re-audit summary (Opus 4.8):** promote candidates in priority order — `security-reviewer` (most expensive failure mode), `reviewer` (gate consolidation), `lens-composition` (drift detection), `spike-adversarial-verifier` (research-breaking), `solution-evaluator` (TCO reasoning, cost-insensitive). Keep on sonnet (cost/cadence-sensitive, low-ambiguity): `refactor-extractor` (runs N×, mechanical), `spec-writer` (format-matching), `lens-cascade` (leaf lens, runs ×4 — but watch for missed silent-wrong-value cascades). **No disable-model-invocation candidates in this batch** — all eight are genuinely model-driven reasoning agents, not deterministic side-effect skills.
