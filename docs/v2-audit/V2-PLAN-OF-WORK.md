# V2 Harness — Plan of Work

Status: **planning / research**. No harness code is being changed yet. This is the
authoritative plan for producing V2 of the AI agent harness.

## The governing rule (this is what V1-planning got wrong)

**No proposal survives without a citation.** Every surviving V2 item must point to
either (a) the exact current-state component it changes, or (b) a confirmed absence.
"The research says X is good" is not a reason to build X. The earlier Layer 6 effort
failed because proposals were evaluated against an *imagined* harness — it proposed
`learned-patterns.md` (duplicate of `docs/RECURRING-FINDINGS.md`), a bugfix-test rule
(duplicate of `/tdd`), and `/simplify` wiring (skill doesn't exist locally). Ground
truth comes first; every claim is checked against it.

## Principles (set by Tanner — these are binding)

- The harness is **global / multi-project**. It is NOT event-vendor-specific. Canonical
  form lives in **Notion** + the global `~/.claude`, not just in this repo's copy.
- **Empower the model** where possible; keep code and data **safe**.
- **Production-capable.** Simple and boring is a **feature**. We are not trying to impress.
- Goal: a harness that lets engineers build world-class systems they **trust and rely on** —
  simple code, simple to understand, simple for both agents and humans to extend, works
  every time.
- The harness must **compound** — measurably better every time it's used.
- Honest assessment over validation. No flattery.

## Cross-cutting method (applies to EVERY phase)

- **Use subagents thoroughly.** Fan out widely — decompose each phase into independent
  slices and run them in parallel rather than reasoning serially in one context.
- **Doer ≠ checker.** Every artifact — each audit slice, each article pass, each design
  decision, each redesign proposal — is verified by a *separate* agent that did NOT
  produce it. The checker is given the source material + the governing rule and is
  prompted **adversarially** to find what is wrong, unsupported, duplicative, or assumed.
  Nothing advances to the next phase until an independent agent has checked it. This is
  not only the Phase 6 gate — it is continuous throughout.
- **Depth over speed; research before deciding.** World-class judgment is the bar, not
  fast decision-making. **When in doubt, do MORE research before deciding** — spawn fresh
  research passes, read more sources, check more of the codebase. A small final decision
  set is the product of rigor (most questions resolved by evidence), never of skipping
  investigation. Never collapse to a quick decision to look efficient.
- **Research is not bounded by the provided articles.** The Notion article set is a
  starting corpus, not a limit. When the articles don't answer a question — about the
  model's current capabilities, a tool, a pattern, a competing approach, or a design
  tradeoff — go find new sources (web, official docs, primary sources) and persist them
  as new research. A gap in the corpus is itself a finding, not a stopping point.

## Phases

### Phase 0 — Canonical ground truth
Read the *AI-Native Engineering System* Notion page
(https://app.notion.com/p/AI-Native-Engineering-System-358e2971cd62812a8ba8f87d6ac1466d)
→ inventory every skill, agent, command, file, hook, and memory mechanism as the harness
exists **across projects**. Merge with:
- the on-disk project audit already produced (see `HARNESS-AS-IS.md` + `A1/` in this folder)
- the global `~/.claude` (skills/agents present globally but not in this repo, e.g.
  `/simplify`, `/grill-with-docs`, `/to-issues`)
Output: **CANONICAL-HARNESS-AS-IS.md** — the multi-project ground-truth map.

### Phase 1 — Enumerate the research
Read the *Research* Notion page
(https://app.notion.com/p/Research-367e2971cd6281df8c99d02af2a2f011)
→ the full, exact list of articles. Output: an article registry so 3-pass coverage is
provable and complete.

### Phase 2 — Three passes per article (PROOF REQUIRED)
One sub-agent per article. Three **separately persisted** files per article so the work
is verifiable — no dressing up a single read as three. Each pass must cite the prior pass.
- **Pass 1 — Comprehend:** what the article actually says. Fact vs. opinion tagged.
- **Pass 2 — Penetrate:** the deeper thesis, patterns, contradictions, what it assumes.
- **Pass 3 — Apply:** checked against CANONICAL-HARNESS-AS-IS — what we already do, real
  gaps in *our* system, gaps in the *article's* reasoning, how it applies, and whether it
  warrants spawning fresh research.

### Phase 3 — Redesign the composed harness
File structure + memory system, designed around how agents, subagents, skills, commands,
and memory actually compose. Output: target architecture — a concrete file tree and a
single coherent memory model that replaces today's triple-duplicated layers
(`.claude/memory.md` ↔ `PITFALLS.md` ↔ auto-memory, plus `RECURRING-FINDINGS.md`,
`docs/solutions/`, `docs/adr/`).

### Phase 4 — Distribution & self-update
Get the harness to **GitHub** (must-have; used on many projects). Design the two update
paths: a project pulls harness improvements down, and a project pushes harness-worthy
improvements back up to the global/GitHub canon.

### Phase 5 — Compounding
The single loop that makes the harness measurably better every use — wired into the
redesigned structure, not bolted on.

### Phase 6 — Staff-level review gate (Tanner's requirement)
A panel of staff-engineer lens agents + a reviewer running a /cr-style pass over
everything above. The anti-duplication gate ("does this already exist?") is mandatory.
The reviewer decides what must be fixed, fixes it, and returns to Tanner with **only the
decisions that are genuinely his** — not raw output.

## Definition of done

Two layers must both hold.

**Success of this effort (design phase):**
- An accurate, multi-project CANONICAL-HARNESS-AS-IS exists.
- Every research article has three provable, separately-persisted passes.
- Zero phantom or duplicate proposals survive — every surviving item carries a citation,
  and an independent agent tried and failed to kill it as a duplicate.
- One clear file structure + one coherent memory model defined.
- GitHub distribution + bidirectional self-update designed; one compounding loop defined.
- Independently reviewed; only genuine decisions surface.
- **Test:** Tanner can understand the design well enough to teach it. If not, not done.

**Success of the harness itself (in use):**
- Safe by construction (structural, not advisory); the `push --no-verify` / direct
  `gh pr create` bypass is closed.
- Empowers the model; constrains only where blast radius demands.
- Simple and boring; likely **fewer** files and mechanisms than V1. Consolidation and
  deletion count as success.
- Compounds: a mistake caught once becomes a structural rule the next project inherits,
  with no manual step that silently rots.
- Lives on GitHub; updates flow both ways.
- Trusted enough to rely on for production.

**Warning sign:** if V2 ends with more files and more mechanisms than V1, that is a red
flag, not a win.

## What gets returned to Tanner

A decision package, NOT a research dump:
1. **Decision brief** — the small set (≈4–8) of real forks only Tanner can settle. Each
   one screen: decision, recommendation first, one-line why + tradeoff, citation. The
   smallness is the product of rigor (most questions resolved by evidence), never of
   skipping research.
2. **The V2 design (teachable depth)** — file tree, single memory model (who writes /
   reads / when), how agents/subagents/skills/commands/memory compose, distribution +
   self-update, compounding loop, and a sequenced migration path (what's deleted at each
   step).
3. **Rejected list** — everything proposed and killed, with reasons and evidence.
4. **Proof of process** — ground-truth map, all three-pass files, independent-checker
   verdicts; linked, not dumped. Read only to challenge a conclusion.

NOT returned: raw article summaries, a pile of mechanisms to approve one-by-one, or an
idea-list to pick from.

## Confirmed findings from the project-level audit (already done)

These are facts from `HARNESS-AS-IS.md` that the earlier plan got wrong and that V2 must
respect:
- `/cr` has **no REJECT tier and no UNATTENDED branching** — the whole "Node 12.2 fix"
  solved a non-existent problem.
- `/simplify` does **not exist locally** (it's a global skill) — 6.2.1 was wrong.
- `/compound` does **not** count recurrences and never touches `RECURRING-FINDINGS.md`;
  recurrence counting is a `/cr`-pipeline mechanism (≥3 occurrences → human-confirmed
  promotion → `PITFALLS.md`).
- `learned-patterns.md`, `review-log.md`, `triage-inbox.md` — all **absent** (proposed,
  never built).
- **Node 8.5(c) gap is real**: CI never verifies `.cr-ok` (it's gitignored, never reaches
  the runner). `git push --no-verify` or a direct `gh pr create` bypasses the whole chain.
- Memory layer is **triple-duplicated**; phantom references abound (`CONTEXT.md`,
  `.claude/agentic-system-enabled`, `skills-lock.json`, `/prototype-interface`,
  `/scan-context`, `@benchmark-runner`); `dep-update/` is an empty dir.
- Enforcement is **overwhelmingly advisory**; the only real structural spine is the
  `.cr-ok` sentinel chain + git hooks + PreToolUse Bash guards.
