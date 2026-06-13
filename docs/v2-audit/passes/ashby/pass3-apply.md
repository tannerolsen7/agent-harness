# Pass 3 — Apply to OUR harness vs. the ground-truth map

Building on pass2: the transferable core is pass2's "deeper thesis" (defensibility migrates from
*writing* to *judging* code; the apparatus exists to make cheap generation safe) and pass2's
"category gap" insight (a pre-merge-only stack is structurally blind to *runtime*, not merely
thin). pass2 also flagged two risks to discipline here: (i) the article asserts equivalences by
*equation* (lens-* = custom review binary), and (ii) several recommended actions may duplicate
existing mechanisms. Every gap below cites a ground-truth row or a confirmed disk absence; no gap
survives without one.

Ground-truth = `docs/research/v2-audit/CANONICAL-HARNESS-AS-IS.md`. Disk facts verified this session.

## (a) What we ALREADY do — the article's "already in place" is largely TRUE
- **Defense-in-depth verification.** Confirmed by ground-truth §3e (hooks) and §3f (scripts/CI):
  pre-commit (ESLint + tsc + vitest), pre-push (integration + `next build` + `.cr-ok` chain), `/cr`
  9-pass + adversarial. Our stack is *denser* than Ashby's named layers. Building on pass2's "the
  culture is the moat," our moat is encoded as deterministic hooks + a multi-pass review skill.
- **Risk-tiered autonomy mechanisms exist.** Ground-truth §3b lists `/queue`, `/spike`, `/design`,
  `/supabase`, `/cr-security`; CLAUDE.md carries the destructive-op rules (PocketOS) and guard-file
  human-handoff rule (memory: `no_agent_edits_guard_files`). The *mechanisms* of sidekick vs.
  delegate are real. (But the *vocabulary/explicit tier* is not — see gap 3.)
- **Code-quality-as-compounding is operationalized.** CLAUDE.md "Keeping docs current" table +
  the five-store memory model (ground-truth §4) means every hygiene entry is re-read by the next
  agent. This is a faithful, arguably stronger instance of Ashby's "clean codebase is leverage."
- **Expertise-in-skill-files.** Verified on disk: `lens-abuse/assumption/cascade/composition.md`
  agents exist (ground-truth §3d roster of 23 agents includes "all 4 lenses"). The article's claim
  that these *are* Ashby's edge-case reviewer-as-prompts is directionally right at our scale.

## (b) REAL gaps it exposes — each with a citation
1. **No runtime safety net below the merge gate. [confirmed absence]** Verified: no
   Sentry/observability/feature-flag dependency in `package.json` or `next.config.ts`; the
   ground-truth map documents the harness end-to-end and mentions **no runtime/error-monitoring
   layer anywhere** (§3e hooks and §3f CI are entirely pre-merge; §0–§9 never list an observability
   component). This is pass2's *category gap*, not a quality gap. **Caveat correcting the article:**
   the article says "nothing watching the public `/p/[token]` share page" — but `app/p/[token]/error.tsx`
   **does exist** (an error boundary). The true gap is narrower and therefore *more precise*: there
   is a boundary that *renders* a fallback but **nothing that records the failure** — a silently
   broken render for a $30k client is caught visually but leaves no signal an agent or human can act on.
2. **No PII-handling rule for real client data. [confirmed absence]** Verified: grep of CLAUDE.md
   finds no `PII` / `synthetic` / `fixture` rule. Ground-truth §3a/§3e document credential/Tier-0
   guards (the prod-key firewall, `worktree-create.sh`) but **no rule governs real client PII** (names,
   emails, event details) entering test fixtures or agent context. This is the one axis where pass2
   noted we are *ahead* of Ashby (credentials) yet the symmetric data-class (PII) is uncovered.
   Cheap to close (a CLAUDE.md rule + a fixture grep), and it's a genuine §6-style disk gap, not a
   canon item.
3. **"Blast radius" tier is a mechanism without a name. [ground-truth §3b + disk]** The mechanisms
   exist (gap-(a)) but the *explicit tier* does not: grep shows "blast radius" appears in `.claude/
   AI-WORKFLOW.md` **only once**, incidentally, in the hotfix row of the work-state table (line 83) —
   not as a classification an agent must declare before choosing autonomy. The work-state table
   (`AI-WORKFLOW.md` §"Choosing the right work state") keys on *signal → work state → entry point*,
   never on blast radius. So the article's recommendation to add a blast-radius column is a real,
   small, well-targeted addition — it makes pass2's "blast-radius must be legible at task-start"
   *enforceable by naming* rather than left implicit.
4. **No workflow-level "rejected approaches" log. [ground-truth §6 / AGENTS.md]** Verified: AGENTS.md
   "Rejected Patterns" (line 419) is a **code/architecture** decision table (e.g. "role checks in
   RLS"). There is no record of *failed agent/workflow experiments* ("we tried this autonomy approach,
   it didn't work"). This dovetails with the V2 thesis: ground-truth §0 frames V2 as a *compounding,
   self-updating* harness, and a no-failed-experiment log is precisely Ashby's collective blind spot
   (pass2 §contradictions: "no source shows a single failed AI experiment") reproduced in our harness.

## (c) Weaknesses in the article's OWN reasoning
Building on pass2's "where the article's reasoning is soft":
- **Equivalence-by-assertion.** "lens-* agents *are* Ashby's custom edge-case binary" and "markdown
  corpus *is* the SQLite substrate" are rhetorical equalities. A prompt-based adversarial reviewer
  and a maintained bug-detection tool over historical PRs are different instruments; the markdown
  corpus answers "what rules apply," not Ashby's "has anyone seen *this specific bug* before?" The
  article is right that we shouldn't *build* the SQLite DB at solo scale — but it overstates that we
  already have its capability.
- **Two recommendations risk duplication (the anti-duplication gate, ground-truth "How later phases
  cite this map," would flag these):**
  - "Add a *Rejected Approaches* section to AGENTS.md" partially overlaps AGENTS.md's existing
    **Rejected Patterns** (line 419). The *workflow* scope is genuinely new (gap-b4), but it should
    *extend* the existing section, not add a parallel one.
  - "Wire /post-mortem and /incident to **auto-append** durable rules to memory.md" **conflicts with
    a built mechanism**: `/post-mortem/SKILL.md` already produces memory.md + PITFALLS.md *candidates*
    and writes them **only on human approval** (verified: SKILL.md steps "On approval: write to
    PITFALLS.md and memory.md"). Auto-appending would *remove* a deliberate human gate — and
    ground-truth §9 "keep verbatim" protects reasoning/safety discipline. So this recommendation is
    partly already-done and partly *against* our doctrine; the real gap is only that the loop isn't
    *triggered as a final step* of those skills, not that it should become unattended.
- **It inherits Ashby's >50% number uncritically in the TL;DR** ("more than half… without quality
  degradation") even though its own Pass 2 dismantles that exact claim as unmeasured. The bottom-line
  framing ("you already have Ashby's substrate") borrows the credibility of a statistic the article
  itself proved is faith-based (pass2 §contradiction 1).
- **The runtime claim is slightly miscalibrated** (see gap-b1): asserting "nothing watching `/p/[token]`"
  is false at the boundary layer; the precise gap is *no failure logging*, which the article would
  have found by checking disk.

## (d) Does it warrant fresh external research? — No (mostly synthesize)
Disciplined answer per the audit's "prefer synthesize over re-research" rule:
- **No new research on the Ashby thesis, modes, or memory model** — pass1/pass2 fully capture it and
  it maps cleanly to existing ground-truth rows (§3b, §3e, §4, §6). Adding sources would not change a
  single disposition.
- **One narrow, *internal* (not external) follow-up is warranted before building gap-b1:** the
  runtime-logging gap touches the public `/p/[token]` renderer and would write to Supabase — so the
  build (not the audit) must invoke `/supabase` per CLAUDE.md, and must decide the error-log table +
  the optional boolean feature-flag column. That is a *design decision for V2*, surfaced here, not a
  research task.
- **No external research on observability vendors** — the recommendation is explicitly "no vendor
  yet" (a table + error boundary), consistent with CLAUDE.md "build what's needed now." Re-researching
  Sentry/feature-flag SaaS would violate the over-engineering rule pass2 already flagged.

**Net for the V2 map:** this article contributes **four citable gaps** (runtime failure-logging
§3e/§3f absence; PII rule CLAUDE.md absence; blast-radius tier §3b under-specification; workflow
rejected-approaches log §6/AGENTS.md gap) and **two corrections** to its own recommendations (don't
auto-bypass the /post-mortem human gate; extend Rejected Patterns rather than fork it). It contributes
**zero** new canon-vs-disk items beyond these — it is best used exactly as pass1 framed it: a *mirror*
that confirms the substrate is real and isolates the runtime axis as the one genuine category gap.
