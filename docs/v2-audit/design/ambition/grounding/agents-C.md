# Grounding Pass — Agent Bodies Batch C

Source: actual `.claude/agents/*.md` bodies read in full (not summaries).
Scope: spike-orchestrator, spike-researcher, spike-slice, spike-synthesis, spike-user-verifier, task-runner, ux-reviewer.
Charter: world-class is the only goal; autonomy first-class; clarity over minimalism; cite to ground-truth or confirmed absence.

All seven files present and non-empty.

---

## 1. spike-orchestrator

**Actual job (plain English):** The conductor of the entire `/spike` research pipeline. It never researches or writes the dossier itself — it sharpens the question, decides depth (single vs. three-pass), spawns five specialist sub-agents in a fixed sequence, gates between them, assigns a confidence tier, assembles the final 4-part output, and files the findings to `docs/research/` (plus PITFALLS/TESTING/TASK-TEMPLATE side effects).

**Embedded mechanisms that must carry forward:**
- **Required-reads contract before any work** (lines 18–23): `CONTEXT.md`, `AGENTS.md`, `memory.md`, `docs/research/`, `PITFALLS.md`. This is a wired context-loading protocol, not prose.
- **Staleness gate** (lines 25–27): if `docs/research/[topic].md` exists and is ≤30 days old, surface immediately — the spike may already be answered. This is a dedup/cache check that prevents redundant research.
- **Human confirmation gate before spawning** (lines 41–43): must get explicit confirmation of the sharpened question; "Do not spawn any agents before confirmation is received." A hard human-in-the-loop gate.
- **Fixed spawn sequence with context-threading** (Steps 3–6, lines 68–131): researcher (1 or 3 passes, each pass fed prior-pass output) → synthesis → two verifiers in parallel (`@spike-adversarial-verifier` + `@spike-user-verifier`) → slice. The three-pass threading (lines 77–84) is the literal implementation of the CLAUDE.md "3-pass research" doctrine.
- **Slice retry budget** (lines 128–130): one retry with context; second failure = Blocked, no further retries. A wired retry bound.
- **Confidence-tier rubric** (Step 7, lines 134–149): Settled / Leaning / Open / Blocked with explicit conditions, plus the rule "if the slice test fails: drop confidence one tier and record the revised question."
- **Output structure bound to an external skill file** (line 155): assembles output "following the structure in `skills/spike/SKILL.md`" — a cross-reference to a skill template that must travel with this agent.
- **PITFALLS.md entry template** (lines 177–184): a literal fill-in format (topic / confirmed-false-date / what we tried / what happened / Do not / Instead) — a gate-write protocol that other agents in the repo also consume.
- **Filed-findings expiry rule** (lines 173–174): "30 days from today OR when the affected dependency releases a major version — whichever comes first." A concrete TTL contract on the research artifact.
- **STOP AND SURFACE conditions** (lines 201–212): hard escalation triggers — question contradicts AGENTS.md, touches auth/RLS/billing, conflicts with prior research, slice hits a CLAUDE.md NEVER rule, or any pass changes scope. These are load-bearing safety interlocks.
- **Branching hand-off outputs** (Step 9): pass → `/feature` + filled TASK-TEMPLATE; fail → `/debug` handoff with failing test at file:line; Blocked → `/prototype-interface` proposal. Three distinct downstream routes.
- **Frontmatter:** `tools: Task,Read,Write,Bash`; `model: opus`; `permissionMode: default`. The `Task` tool is what lets it spawn sub-agents — load-bearing.

**V2 disposition flag + why:** **KEEP.** This is the spine of the spike system and every gate here earns its place under the world-class bar. The 3-pass threading and STOP-AND-SURFACE interlocks are exactly the rigor the charter wants. Re-audit `model: opus` → bump to Opus 4.8 (orchestration + tier-assignment reasoning benefits). Note: references `@spike-adversarial-verifier` (lines 105, 231) which is NOT in this batch — confirm it still exists in V2; if it was cut, this orchestrator breaks.

**Autonomy hook:** Strong fit. A cloud-scheduled or bug→PR flow could invoke `/spike` non-interactively to research a recurring unknown (e.g., "is dependency X's new major safe to adopt?"). The blocker is the **human confirmation gate** (lines 41–43) and STOP-AND-SURFACE — for autonomous runs these need an explicit "auto-confirm if the question already names all three [eval target / decision / good-enough]" path, or the scheduled run stalls. The filed-findings artifact + 30-day expiry makes it a natural recurring cloud routine ("re-spike anything expiring this week").

---

## 2. spike-researcher

**Actual job (plain English):** The web-research worker for one pass of a spike. Searches the web, reads docs, and reports what authoritative sources literally say — with a citation on every claim. It explicitly does NOT synthesize or recommend. Spawned once per pass (1, 2, or 3), each later pass fed the earlier passes' output.

**Embedded mechanisms that must carry forward:**
- **Per-pass behavioral contract** (lines 19–48): Pass 1 = Understanding (what/how/what sources say), Pass 2 = Deeper (contradictions, buried limitations, failure reports, post-mortems), Pass 3 = Application (which patterns match THIS codebase's architecture/scale, fed `CONTEXT.md`). This is the operational definition of the 3-pass doctrine at the worker level.
- **Source-quality hierarchy** (lines 24–28): prefer primary sources (library docs, eng blogs, peer-reviewed benchmarks); avoid SEO farms, uncited tutorials, undated/unvoted SO answers. A wired source-selection rule.
- **Mandatory citation format** (lines 51–56): `[Title — Author/Org, URL, Date]`; uncited claims MUST be labeled `[UNCITED — agent reasoning]` and are "hypotheses, not findings." This is the integrity mechanism the whole pipeline's trust rests on.
- **Rigid output template** (lines 60–74): Sources consulted / Findings / Contradictions found / Gaps (what sources didn't say) / Uncited reasoning. The "Contradictions" and "Gaps" sections are deliberately preserved downstream (synthesis is told not to smooth them).
- **Frontmatter:** `tools: WebSearch,WebFetch,Read`; `model: sonnet`; `permissionMode: plan`. Plan mode = read-only safety for a web-facing agent.

**V2 disposition flag + why:** **KEEP** (worker role) but **re-audit model field.** `model: sonnet` is defensible for a "report what sources say, don't reason" role, but Pass 2 (find buried contradictions / post-mortems) and Pass 3 (apply to this architecture) are genuinely hard reasoning — on Opus 4.8 economics the quality lift may justify Opus for Pass 3 at minimum. Recommend: Sonnet for Pass 1, Opus 4.8 for Pass 2/3, or simply Opus 4.8 throughout given the fleet-scale charter retires "our economics differ." The citation-integrity contract is world-class and must not be dropped.

**Autonomy hook:** Yes — this is the literal research muscle of any autonomous "investigate before acting" loop. A bug→PR flow that hits an unfamiliar library error could spawn this to gather cited evidence. WebSearch is already noted as needing to be in the allowlist for background agents (per memory: "WebSearch in allow for bg agents") — that allowlist entry is the enabling precondition for autonomous use.

---

## 3. spike-slice

**Actual job (plain English):** Writes exactly ONE TDD test that confirms or kills the spike's riskiest assumption, runs it, and reports Passes/Fails/Blocked. It never implements a solution and never fixes — it proves or disproves, with a single retry budget.

**Embedded mechanisms that must carry forward:**
- **Riskiest-assumption selection rule** (lines 22–34): read the adversarial verifier's Critical findings first; the riskiest assumption = the one the recommendation most depends on AND has the least direct evidence. Fallback if no Critical findings: use synthesis reflect-answer #3 (the load-bearing assumption). This is a wired hand-off dependency on BOTH the adversarial verifier and the synthesis reflect pass.
- **Minimum-test constraints** (lines 38–52): runnable without shipping code, asserts exactly one behavior, fails-if-false / passes-if-true. If it can't be tested without shipping code or prod data → Blocked.
- **Single-retry protocol with falsification-vs-bad-test discrimination** (lines 60–75): distinguish "assumption is false (record Fails)" from "test is wrong (one retry)." Hard cap: second failure records Fails, no further retries.
- **TASK-TEMPLATE.md fill contract on pass** (lines 80–89): TASK / SUCCESS CRITERIA / SCOPE / ROOT CAUSE (N/A — greenfield) / REFERENCES (spike record) / SIZE: Tiny. A literal template the agent must populate.
- **TESTING.md tracer-bullet write on pass** (line 81): adds the passing test to `docs/TESTING.md` under tracer bullets — a gate-write that feeds the broader test-spec system.
- **Three-way next-step routing** (Step 4): Passes → TASK-TEMPLATE; Fails → `/debug` handoff with failing test at file:line; Blocked → `/prototype-interface` proposal. Mirrors the orchestrator's routing.
- **Rigid output format** (lines 106–125) keyed on the three result states.
- **Frontmatter:** `tools: Read,Write,Bash,Edit`; `model: sonnet`; `permissionMode: default`. Has Write/Edit/Bash — it actually creates and runs a test file.

**V2 disposition flag + why:** **KEEP.** The "one test, one retry, never implements" discipline is exactly the kind of tight contract the world-class bar rewards — it prevents the slice from sprawling into implementation. `model: sonnet` is reasonable (writing one focused test), but the assumption-selection reasoning (lines 22–34) is subtle; re-audit toward Opus 4.8 if slice quality is ever weak. Side-effect note: it WRITES test files and to TESTING.md — not a candidate for `disable-model-invocation` (it must be model-driven), but its Bash/Write surface should be sandboxed in autonomous runs.

**Autonomy hook:** Strong — this is the "prove it before you build it" gate that an autonomous build loop needs to avoid shipping on an unverified assumption. In a bug→PR flow, a slice agent could write the failing regression test before the fix is implemented (red→green discipline). The Blocked→`/prototype-interface` route is the honest escape hatch when autonomy hits something only a human/running-system can resolve.

---

## 4. spike-synthesis

**Actual job (plain English):** Turns the raw research-pass outputs into the decision document (4-lens recommendation + dissent + sources), then interrogates its own writing via a required structured reflect pass that surfaces its assumptions and smoothed contradictions. It does NOT assign confidence or write the slice — those belong to the orchestrator and slice agent.

**Embedded mechanisms that must carry forward:**
- **Four-lens + dissent + sources contract** (lines 22–31): Engineering / Operations / User (what the user FEELS, not what the system logs) / Finance-scale / Dissent (strongest credible counter — REQUIRED) / full citation list. Output format bound to `skills/spike/SKILL.md` (line 23). The User-lens framing ("what failure the user feels") is the conceptual seed the user-verifier later expands.
- **Citation-traceability rule + `[SYNTHESIS ASSUMPTION]` flag** (lines 36–39): every claim must trace to a research citation; uncited claims must be flagged — and these flags "become primary verifier targets." A wired hand-off that feeds the verifiers' work queue.
- **Anti-smoothing rule** (lines 47–51): "Do not rephrase findings to make them cleaner. Preserve contradictions and gaps exactly… Smoothing contradictions is how important findings disappear." This is THE mechanism that protects the researcher's contradiction/gap sections from being lost — directly relevant to the carry-forward concern in this grounding pass.
- **Required structured reflect pass** (lines 54–77): three forced questions — (1) what did I assume the research didn't confirm, (2) what contradictions did I smooth over, (3) what would most change this if I'm wrong (the load-bearing assumption). Appended under `### Synthesis Reflect`. "The verifiers receive this reflect output as primary input." This is a wired three-way dependency: reflect→verifiers AND reflect#3→slice's fallback assumption-selection.
- **Frontmatter:** `tools: Read,Write`; `model: sonnet`; `permissionMode: plan`. Plan mode despite Write — note potential mismatch (it must Write the dossier); confirm V2 permission is consistent.

**V2 disposition flag + why:** **KEEP — and protect the reflect pass + anti-smoothing rule explicitly in V2.** These two mechanisms (lines 47–51 and 54–77) are precisely the kind of embedded, load-bearing machinery the charter warns gets summarized away. The reflect pass is the quality-determining step for the entire downstream verification chain. Re-audit `model: sonnet`: synthesis + honest self-interrogation is high-value reasoning — strong candidate for Opus 4.8. Also re-check `permissionMode: plan` vs. its need to Write (lines 8, 82) — looks like it should be `default` to actually emit the dossier file, or it relies on returning text to the orchestrator (clarify in V2).

**Autonomy hook:** Indirect but important. In an autonomous research→decision loop, this is the step that produces the auditable decision record a human can later review asynchronously. The forced dissent + reflect pass is what makes an autonomously-produced recommendation trustworthy enough to act on without a human in the loop at synthesis time.

---

## 5. spike-user-verifier

**Actual job (plain English):** Holds exactly one question — "if this recommendation is wrong, what does the USER experience?" — and assesses stakes from the end-user's perspective. It is explicitly NOT a UX review and produces no counter-recommendation; it's a consequences-to-the-human assessment. Runs in parallel with the adversarial verifier.

**Embedded mechanisms that must carry forward:**
- **Lens-to-user-failure mapping** (lines 26–35): for each technical lens (engineering/ops/scale) it derives the concrete user-felt failure (spinner / error / stale data / silent data loss / timeout / lost work / dropped request). A wired translation table from system-failure to human-experience.
- **CONTEXT.md personas consumption** (lines 19–22, 37–43): reads the User personas section; if absent, reasons from domain and lowers confidence. This is a file-read dependency that ties the agent to `CONTEXT.md`.
- **"Who bears the cost" + "user not in the room" analysis** (lines 37–44, 78–80): forces identification of the unrepresented stakeholder — a deliberate blind-spot check.
- **Load-bearing-assumption hand-off** (lines 45–48): explicitly consumes the synthesis reflect's named assumption (reflect #3) and asks which user bears the consequence if it's false. Wired dependency on synthesis output.
- **Explicit non-goals** (lines 56–63): does NOT assess UX/visual design, does NOT counter-recommend, does NOT rewrite the summary. Keeps it from colliding with `ux-reviewer`.
- **Rigid output format with a confidence rating** (lines 67–85): includes a `Confidence in user impact assessment [High/Medium/Low]` tied to whether personas were present.
- **Frontmatter:** `tools: Read`; `model: sonnet`; `permissionMode: plan`. Read-only — pure assessment.

**V2 disposition flag + why:** **KEEP, but MERGE-CANDIDATE worth examining.** Its job is tightly scoped and genuinely distinct from the adversarial verifier (stakes-to-human vs. logic-attack) and from `ux-reviewer` (consequences-if-wrong vs. friction-of-the-built-UI). Under "clarity over minimalism" the separation is justified — keep it separate. The only merge question is whether the adversarial verifier could absorb the user-lens as a sub-section; recommendation: KEEP separate because a single agent holding two adversarial postures tends to dilute both. `model: sonnet` is fine for a read-only single-lens assessment; low priority for an Opus bump.

**Autonomy hook:** Yes — in an autonomous decision loop this is the agent that flags "this is safe to ship without a human" vs. "a real user gets hurt if we're wrong here." Its confidence rating could gate whether an autonomous flow proceeds or escalates to a human. The "user not in the room" check is a valuable autonomy safety net.

---

## 6. task-runner

**Actual job (plain English):** The per-task orchestrator inside a `/queue` parallel worktree. For ONE task it runs the full build pipeline — explorer → spec-writer → implementer → reviewer → (conditional) ux-reviewer → (conditional) security-reviewer → doc-updater — manages the `questions.md` blocking protocol, writes the `.cr-ok` sentinel, updates TASKS.md, and returns a summary to `/queue`. It does not write code itself.

**Embedded mechanisms that must carry forward:**
- **Required-reads + task-claim on start** (lines 21–31): reads SOUL.md, CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md; claims the task by appending `(@task-runner)` to the TASKS.md line; reads `questions.md` and surfaces any prior BLOCKING entry before proceeding.
- **GOLDEN EXEMPLAR hand-off** (lines 48–53): **"For each behavior… invoke @implementer with: the single behavior, the relevant TESTING.md entry, AND the golden exemplar from AGENTS.md for this layer."** This is the exact "golden exemplars" mechanism the grounding-pass brief flagged as the canonical example of a load-bearing wired contract that prior summaries dropped. It is read from AGENTS.md and injected per-implementer-invocation. MUST carry forward.
- **One-behavior-per-invocation rule** (lines 49, 54): "Never batch slices — one invocation per behavior." A wired granularity contract that keeps slices reviewable.
- **Spec = confirmed behaviors only** (lines 44–46): spec-writer returns TESTING.md entries that are "confirmed behaviors, not invented ones" — written to `docs/TESTING.md`. Gate-write.
- **Reviewer fix-loop with bounded retries** (lines 56–60): MUST FIX → loop @implementer then re-run @reviewer; "Max 2 fix loops before surfacing to human." Bounded autonomy.
- **Conditional UX gate** (lines 62–66): if diff touches component/CSS → invoke @ux-reviewer; its MUST FIX treated identically to reviewer MUST FIX.
- **Conditional security gate** (lines 68–72): if diff touches auth/middleware/RLS/credentials/data-boundaries/unauthed API routes → invoke @security-reviewer; "All security findings are MUST FIX — loop @implementer until clean." A hard, non-bypassable gate.
- **Compound draft, NOT direct doc writes** (lines 74–80): @doc-updater produces `.claude/compound-draft-[task-slug].md`; "Do not write to docs/solutions/, PITFALLS.md, or memory.md — the draft is for human review at PR time." A deliberate separation of automated drafting from canonical doc commits.
- **questions.md BLOCKING / NON-BLOCKING protocol** (lines 81–106): literal templates for both; BLOCKING → STOP, do not commit, mark TASKS.md `[~]` with pointer; NON-BLOCKING ASSUMPTION → record alternative + "Review before: merge" → continue. This is the core human-in-the-loop interlock for parallel autonomous work.
- **Mandatory pre-commit gate** (lines 108–114): re-read questions.md before EVERY commit; any unanswered BLOCKING for this task-slug → STOP. "This check runs before every commit, without exception."
- **`.cr-ok` sentinel write** (line 119): `echo "$(git rev-parse --abbrev-ref HEAD):$(git rev-parse HEAD)" > .claude/.cr-ok` — the exact sentinel format the pre-push hook validates (`branch:sha`). This is the wired bridge between the agent and the push-gate hook. (Note: memory warns sentinel must use ABSOLUTE worktree path — V2 should reconcile this `echo > .claude/.cr-ok` relative write against that rule.)
- **Completion checklist + summary contract** (lines 116–127): verify no open BLOCKING, all MUST FIX resolved, write sentinel, TASKS.md `[x]`, return structured summary (slug, SHAs, FRICTION REPORT path, compound-draft path, NON-BLOCKING assumptions, branch name).
- **Frontmatter:** `tools: Read,Edit,Bash,Glob,Grep`; `model: opus`; `permissionMode: auto`. `permissionMode: auto` is what lets it run unattended in a worktree — load-bearing for autonomy. Notably it has Edit but the prose says it doesn't implement — Edit is for TASKS.md/questions.md bookkeeping.

**V2 disposition flag + why:** **KEEP — highest-priority carry-forward in this batch.** This agent is the densest concentration of wired, load-bearing machinery: golden exemplars, the security/UX conditional gates, the questions.md protocol, the `.cr-ok` sentinel contract, and the compound-draft separation. Every one of these is exactly what the charter says must not be summarized away. `model: opus` → re-audit to Opus 4.8 (orchestration + gate-judgment is the core competency). `permissionMode: auto` is correct for autonomous worktree runs and is a feature under the autonomy-first charter, not a risk to remove.

**Autonomy hook:** This IS the autonomy engine. It already runs unattended (`permissionMode: auto`) in a parallel worktree, drives a full bug→reviewed→sentinel→PR-ready pipeline, and self-gates via questions.md + the security gate. For a bug→PR autonomous flow, task-runner is the natural top-level driver: `/queue` feeds it a task contract, it produces a `.cr-ok`-sentineled, reviewed, security-checked branch ready for `scripts/pr.sh`. The questions.md BLOCKING protocol is the clean escalation path when autonomy must hand back to a human. The single gap for cloud-scheduled use: it assumes a human reviews the compound-draft and NON-BLOCKING assumptions at PR time — a fully autonomous flow needs a defined consumer for those artifacts.

---

## 7. ux-reviewer

**Actual job (plain English):** A read-only UX auditor that drives Chrome MCP over any diff touching components/CSS and runs two sequential passes: (1) a Don't-Make-Me-Think structural audit across 7 laws producing a 0–10 confusion score, and (2) a five-persona-plus-project-personas friction walkthrough. Distinguishes regressions from net-new friction and emits a FRICTION REPORT.

**Embedded mechanisms that must carry forward:**
- **Pre-review context reads** (lines 18–26): CONTEXT.md User personas (project-specific personas), docs/TESTING.md (specified states for the surface), diff→affected-surface identification, and iterative-vs-new-surface classification. Wired file-read + diff-analysis protocol.
- **Pass 1 — 7 DMMT laws with explicit failure signals** (lines 29–96): Self-evidence, Scanning, Mindless clicks, Omit needless words (happy talk → MUST FIX), Trunk Test navigation, Conventions, First-load surface. Each law has a concrete "failure signal." This is a full embedded rubric, not prose.
- **Confusion score + top-3 pause points** (lines 88–96): `Confusion score: N/10` plus the three specific UI moments a first-timer would pause. A quantified, comparable metric.
- **Pass 2 — five built-in personas with concrete eval criteria** (lines 99–130): First-time, Power user (≤2 clicks target for frequent actions), Error-prone (validation-message specificity), Slow-connection (loading indicator + submit-disable), Accessibility (WCAG 2.1 AA: Tab-reachable, aria/labels, ≥4.5:1 contrast, focus return after modal). These are wired, testable checks.
- **Project-persona extension from CONTEXT.md** (lines 127–130): evaluate each project persona; if none, note it. Same CONTEXT.md dependency as user-verifier.
- **Regression vs net-new classification** (lines 134–139): "Regressions are always MUST FIX." A wired severity rule.
- **FRICTION REPORT output format + severity reconciliation** (lines 142–180): structured report; final line — **"MUST FIX items are treated identically to MUST FIX from @reviewer."** This is the wired contract that ties ux-reviewer's output back into task-runner's fix-loop (task-runner line 66 consumes exactly this).
- **Frontmatter:** `tools: Read,Glob,MCP(chrome/*)`; `model: sonnet`; `permissionMode: plan`. The `MCP(chrome/*)` grant is load-bearing — it's the only agent here that drives a real browser. Plan mode + read-only is appropriate.

**V2 disposition flag + why:** **KEEP** (clear, earns its place; clarity-over-minimalism strongly supports a dedicated UX agent with a full rubric). **CHANGE-DELIVERY caveat:** the `MCP(chrome/*)` dependency must be verified present in any autonomous/cloud environment — Chrome MCP availability is the single point of failure; if the cloud runner lacks it, the agent silently can't do Pass 1/2 walkthroughs. Re-audit `model: sonnet`: the DMMT rubric and accessibility checks are pattern-application (Sonnet-appropriate), but multi-persona judgment quality could lift on Opus 4.8 at fleet scale — low-to-medium priority. Not a `disable-model-invocation` candidate (must be model-driven). The "MUST FIX == @reviewer MUST FIX" reconciliation line MUST survive into V2 or task-runner's UX gate loses its teeth.

**Autonomy hook:** Yes, with a hard dependency. In an autonomous build→PR flow, task-runner already invokes ux-reviewer conditionally on component/CSS diffs (line 64), and its MUST FIX items feed the implementer fix-loop. For cloud-scheduled/laptop-closed runs the blocker is **headless Chrome MCP availability** — that must be provisioned in the cloud runner or the UX gate degrades to a no-op silently (a real failure mode worth a guard). The confusion-score metric is also a candidate for a self-improving loop: track confusion scores over time and flag regressions across the fleet.

---

## CARRY-FORWARD ALERTS

The embedded mechanisms in THIS batch most at risk of being summarized away — preserve them verbatim into V2:

1. **GOLDEN EXEMPLARS (task-runner lines 48–53).** The exact mechanism the brief named: per-behavior, @implementer is invoked WITH the golden exemplar read from AGENTS.md for that layer. This is the load-bearing implementer-quality contract. Prior designs dropped it. Must carry forward, and the AGENTS.md "golden exemplar per layer" source rows must exist for it to read.

2. **`.cr-ok` SENTINEL FORMAT + CONTRACT (task-runner line 119).** `echo "branch:sha" > .claude/.cr-ok`. This is the wired handshake the pre-push hook validates. Drop it and the agent→hook bridge breaks. (Also: reconcile the relative-path write here against the memory rule requiring an absolute worktree path.)

3. **questions.md BLOCKING/NON-BLOCKING PROTOCOL + per-commit gate (task-runner lines 81–114).** The core human-in-the-loop interlock for parallel autonomous work — literal templates, STOP semantics, and "checked before every commit, without exception." This is the autonomy safety mechanism; easy to flatten into "asks questions when blocked" and lose the enforced gate.

4. **NON-BYPASSABLE SECURITY GATE (task-runner lines 68–72).** "All security findings are MUST FIX — loop @implementer until clean." Conditional trigger list (auth/middleware/RLS/credentials/data-boundaries/unauthed API). Must stay hard.

5. **COMPOUND-DRAFT SEPARATION (task-runner lines 74–80).** Automated doc drafting writes to `.claude/compound-draft-*`, NEVER directly to docs/solutions/PITFALLS/memory — those are human-reviewed at PR time. A deliberate canon-protection boundary.

6. **ANTI-SMOOTHING RULE + REQUIRED REFLECT PASS (spike-synthesis lines 47–77).** "Smoothing contradictions is how important findings disappear" + the three forced reflect questions. These protect the researcher's contradiction/gap sections and feed the verifiers AND the slice's fallback assumption-selection. The single most "summarizable-away" intellectual mechanism in the spike pipeline.

7. **CITATION-INTEGRITY CONTRACT (spike-researcher lines 51–56).** `[UNCITED — agent reasoning]` labeling; "uncited claims are hypotheses, not findings." The trust foundation of the whole research chain.

8. **FRICTION-REPORT → @reviewer SEVERITY RECONCILIATION (ux-reviewer line 179 / task-runner line 66).** "MUST FIX items are treated identically to MUST FIX from @reviewer." Cross-agent contract; if dropped, the UX gate stops blocking.

9. **THREE-PASS THREADING + STOP-AND-SURFACE INTERLOCKS (spike-orchestrator lines 77–84, 201–212).** The literal context-threading between passes and the hard escalation triggers (auth/RLS/billing, AGENTS.md contradiction, CLAUDE.md NEVER rule). Safety + the doctrine's actual implementation.

10. **EXTERNAL TEMPLATE BINDINGS.** Multiple agents bind their output to `skills/spike/SKILL.md` (orchestrator line 155, synthesis line 23) and fill `TASK-TEMPLATE.md` / `PITFALLS.md` / `docs/TESTING.md` (orchestrator, slice). If these template/skill files don't travel with the agents in V2, the agents produce malformed output. The bindings are invisible unless you read the bodies — exactly the drop risk.

**Model re-audit summary (Opus 4.8):** orchestrator (opus→4.8, high value), task-runner (opus→4.8, high value), synthesis (sonnet→4.8 candidate — self-interrogation is high reasoning), researcher Pass 2/3 (sonnet→4.8 candidate), slice (sonnet, low priority), user-verifier (sonnet, fine), ux-reviewer (sonnet, low-medium). No agent in this batch is a `disable-model-invocation` candidate — all are model-driven reviewers/orchestrators, none are pure side-effect skills.

**Cross-batch dependency flag:** spike-orchestrator references `@spike-adversarial-verifier` (lines 105, 231) — NOT in this batch. Confirm it survives in V2; the orchestrator's verifier-parallel step and the slice's riskiest-assumption selection both depend on it.
