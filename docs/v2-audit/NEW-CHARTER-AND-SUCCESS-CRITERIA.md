# V2 Harness — NEW CHARTER + SUCCESS CRITERIA (read this first, next session)

**Why this file exists.** Mid-effort, Tanner delivered a decisive critique: the Phase 0–6 synthesis was
**too conservative** — 37 sources from teams with hundreds of world-class engineers collapsed into 6
wiring-tweaks, because the effort ran under an anti-ambition charter ("fewer files = red flag, simple &
boring, minimize footprint, hypothesis-gate everything"). That charter is **retired.** This file is the new
charter, every decision resolved in conversation, and the success criteria for the deliverable. The prior
work (ground-truth map, memory-model mechanics, the rigor method) is kept; the **ambition level** is redone.

---

## 1. THE NEW CHARTER (overrides the original binding principles)

- **North star:** the BEST agent harness these 37 world-class sources can teach us to build. NOT "better
  than V1," NOT "minimal." World-class is the only goal.
- **Autonomy is FIRST-CLASS:** bug → reviewed PR, summoned from Slack/Linear, self-improving loops.
  Designed in, never deferred. (Reverses the original §C "defer the trigger front-door.")
- **Clarity beats minimalism.** More skills/agents/hooks/mechanisms is FINE when each earns its place and
  its job is obvious. **"Fewer files = red flag" is RETIRED.** Never reject an idea for adding files. The
  test is "is the structure simple, clear, understandable, and does it work" — not "is it small."
- **Scale test = world-class, not solo.** Tanner runs PARALLEL AGENT FLEETS across 5+ repos. "Too much /
  over-engineered for a solo dev / our economics differ" is **NOT a valid rejection** — strike that reasoning
  wherever the original synthesis used it.
- **KEEP THE RIGOR (this is what makes it world-class, not a kitchen sink):** every adoption cites a source;
  do not re-propose what genuinely already exists *at world-class quality* (but "we have a weak version" =
  a real upgrade, not a phantom); **doer≠checker** — every artifact verified by a separate adversarial agent;
  ground-truth on disk (artifacts rot); be honest when an idea is a genuinely bad fit. Ambition WITH discipline.

---

## 2. RESOLVED DECISIONS (from conversation — these are settled)

- **D1 — ADR disposition:** BOTH — keep `docs/adr/` long-form AND auto-load a short `kind: decision` version
  via path-scoped rules. (Clarity-over-file-count made this the easy call.)
- **D2 — Distribution:** Plugin + marketplace (portable mechanism) + thin `/init` template (per-repo files).
  A plugin physically can't carry permissions (verified: live vercel 0.43.0 plugin ships 27-byte settings).
  Revises the canon's locked "template-only" decision.
- **D3 — Autonomy: IN SCOPE AS THE GOAL** (reversed from "defer"). bug→PR, Slack/Linear. Build the safe
  foundation first *because* autonomy needs it; the trigger adapter is the last, small step.
- **D4 — Write-back capture:** ship degrade-safe (`/cr` 3b auto + manual append) now; probe whether a Stop
  hook can deterministically detect a corrected-mistake from the transcript before going full-auto.
- **D5 — File count: DROPPED.** Clarity/understandability is the north star, not file count. (This is what
  invalidated the conservative synthesis.)
- **Supabase skills (`/supabase`, `/supabase-postgres-best-practices`): OUT of the core** — per-project
  add-on a Supabase repo installs itself.
- **`/notion-sync`: REMOVED. GitHub becomes the single source of truth (canon), not Notion.**
- **How the harness travels TODAY (the missing fact):** each repo is set up by **pointing it at a Notion
  "setup page"** and letting the agent reconstruct the harness from prose. So the 5+ repos are **divergent
  reconstructions**, not copies — worse than drift. The plugin replaces this with exact, versioned installs.
- **NEW WORKSTREAM — Notion → GitHub migration:** (a) replace the setup mechanism (Notion setup page → plugin
  + `/init`); (b) migrate the canon content (the AI-Native Engineering System pages, setup prompts, research)
  into the `agent-harness` repo markdown; then the repo is canon and Notion is archive-only. This is the
  convergence gate's content half.
- **`/schedule` is cloud-side** (verified official docs): routines run on Anthropic infra, "keep working when
  your laptop is closed," clone the repo, run committed skills, call claude.ai connectors. → it is the
  heartbeat AND the autonomy trigger substrate; the old "machine asleep" durability spike is MOOT. Caveats:
  restricted network by default, no *local* MCP servers (only claude.ai connectors), ±few-min stagger.
- **Commands vs skills (verified):** commands are legacy; skills are the unified form; the harness is correctly
  all-skills. Real lever = per-skill invocation control. **`disable-model-invocation: true` removes a skill
  from context entirely** (confirmed — closes the earlier open risk). Use it for side-effect skills
  (`/cr-eval`, `/deploy`, "open PR", "send Slack"); this is also what makes autonomy safe.
- **Golden exemplars (the carry-forward miss Tanner caught):** a real, wired V1 mechanism (AGENTS.md:300, read
  by `implementer`/`task-runner`/`lens-composition`) that the design summarized away. Now in
  `design/V1-TO-V2-CARRYFORWARD.md`. In V2 it's delivered path-scoped (each layer's exemplar loads when you
  touch that layer). This exposed a class problem — see §3.

---

## 3. THE CONSERVATIVE-SYNTHESIS CRITIQUE (what to redo, and how)

The original synthesis (`design/MASTER-FINDINGS.md`) systematically down-weighted world-class ideas via
three reflexes. Treat all three as **suspect kill-lists** to re-examine under the new charter:
- **§E "already built"** set the bar at *existence*, not *world-class*. "We have `/cr`" ≠ "we have
  CodeRabbit/Ramp-grade review." Re-ask: do we have the world-class version or a weak one to upgrade?
- **§F "reject as literal"** — re-ask each: right, or conservative bias? (e.g. sandboxing rejected as "wrong
  threat model at solo scale" — but autonomy changes the threat model.)
- **§C "deferred / hypothesis-gated"** — where the biggest ideas died (the autonomous trigger front-door,
  `/goal`, the scheduler). Under "autonomy is the goal + cloud `/schedule` exists," most should move to
  IN-SCOPE-NOW.
- **The "doesn't apply to solo / our economics differ" dismissal** recurs across the 37 pass-3 files — every
  instance is a suspect.

**The redo (Phase 2.5 — the ambition re-mine, NOT yet run):** re-read all 3 passes of every source (the full
idea lives in pass-1/pass-2, before the conservative "apply to us" filter in pass-3), challenge every
dismissal, and build the **world-class harness vision** — expect MORE and BIGGER moves than the original 6.
A workflow was designed for this but hit a JS parse error before launch; rebuild it cleanly. Structure:
(A) 37 re-mines + 4 kill-list attacks (§E/§F/§C/scale-bias) → (B) vision synthesis (3 lenses: autonomy /
craft / platform → 1 synthesis) → (C) adversarial check ("world-class or over-engineered? proportionate to
37 elite sources? rigor intact?"). Persist to `design/ambition/`.

**The research is genuinely deep and real** (don't re-research it): 37 articles × 3 passes = 111 files in
`passes/`, each gap cited to the ground-truth map, adversarially checked. The problem was never research
depth — it was the conservative *filter*. Mine the existing passes harder; only spike where a pass-3 flagged
a bounded check.

---

## 4. SUCCESS CRITERIA — the deliverable HTML (`V2-HARNESS-REVIEW.html`)

A standalone HTML page (self-contained, inline CSS, works offline). Written in **plain/6th-grade English for
someone with 5 years of software experience** (explain harness- and Claude-Code-specific concepts simply;
don't over-explain PRs/CI/git). It MUST contain ALL of:
1. **A teach-test overview** — enough that Tanner can fully teach this harness to someone else. *If he can't
   teach it after reading, it's not good enough.*
2. **What skills, agents, commands, hooks, etc. will be in V2** — each with a simple description AND a "why"
   (the failure it prevents). Reflect the world-class roster, not the conservative one.
3. **The file structure and WHY it was chosen** (clarity-first).
4. **What makes V2 *decisively* better than V1.**
5. **How we use GitHub** (canon + plugin install/update + channels + the un-fakeable CI gate + push-back +
   the Notion→GitHub migration).
6. **How the harvest-from-disk path works when compaction/limits hit** (and why V2 inherits it as a principle).
7. **What was left out of the research even though it probably should've been included** (honest gaps).
8. **The decisions Tanner must make**, with enough information to decide clearly.
9. The 5 forks / honest assessment / open risks content.
10. Reflect the **new charter** (world-class, autonomy first-class, clarity over minimalism) and every
    resolved decision in §2 — including Supabase-out, notion-sync-out, GitHub-canon, `/schedule`, golden
    exemplars carried, and the Notion→GitHub migration.

**Process requirement (explicit from Tanner):** run **thorough adversarial reviews (doer≠checker)** over the
re-mine, the vision, and the design BEFORE delivering the HTML. Do not come back with the HTML until the
reviews are done and their findings folded in.

---

## 5. RESUME STATE

**DONE & kept:** ground-truth map (`CANONICAL-HARNESS-AS-IS.md`), the 37×3 passes (`passes/`), the
memory-model/enforcement/distribution mechanics (Phase 3–6, but their AMBITION is being redone), the
carry-forward ledger (`design/V1-TO-V2-CARRYFORWARD.md`), `DECISION-PACKAGE.md`, the current (conservative)
`V2-HARNESS-REVIEW.html` (to be replaced).

**IN-FLIGHT / TODO next session, in order:**
1. **Run the ambition re-mine** (§3) — the world-class vision. THIS IS THE NEW SPINE. Persist to
   `design/ambition/`.
2. **Finish the research→design traceability audit** (got ~12/37 in `design/phase6/traceability/`; rebuild &
   complete) — surfaces what the conservative synthesis DROPPED.
3. **Run the still-owed skill/agent body grounding pass** — read every `SKILL.md` + agent body for other
   embedded mechanisms like golden exemplars that must carry forward.
4. **Rebuild the design** on the world-class vision (the ambitious MOVE set), with doer≠checker on each.
5. **Thorough adversarial reviews** over everything (lens panel + reviewer; anti-duplication gate mandatory).
6. **Deliver the new `V2-HARNESS-REVIEW.html`** against the §4 success criteria.

**Method reminders:** fan out subagents widely; doer≠checker on every artifact; agents persist to disk (the
account session limit interrupts big runs — harvest from disk files, not workflow returns); cite every
proposal to a source or a confirmed absence; re-verify absences on disk. Workflow scripts are plain JS — no
TypeScript type syntax (that caused the re-mine launch to fail).
