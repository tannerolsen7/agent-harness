# Cluster Findings 3 — Skills / Context / Composition / Distribution-Unit

**Cluster aggregator output.** Consolidates the pass-3 "apply vs our harness" analyses for 9 articles
into one deduplicated, citation-anchored gap list. Governing rule (inherited from
`CANONICAL-HARNESS-AS-IS.md`): every realGap cites a ground-truth map section (`[map §X]`) or a
confirmed absence (`[absent]`). Anything already built is moved to **alreadyDo**, not re-proposed.

**Articles covered:** commands-vs-skills, osmani-agent-skills, zapier-skillmd,
harness-engineering-survey, basis-monorepo-deep, basis-canon-not-canon, packmind, augment-code,
mcp-servers.

---

## 1. realGaps (deduplicated across the cluster)

### G1 — No installable distribution unit: skills carry no machine-readable ownership/router contract, and the harness cannot leave event-vendor
**Citation:** `[map §1]` (runtime skill list mixes project/global/plugin layers, "cannot tell which
layer owns each, nor which will travel"); `[map §3b]` (26 disk skills, no registry); `[map §0, §8]`
("never been installed anywhere but event-vendor; multi-project is a goal, not a state").
**Sources:** commands-vs-skills (b4), zapier (b1), harness-survey (b4), basis-monorepo-deep (a, interop
format-only).
**The gap, sharpened by the cluster's own corrections:**
- Two-part, not one: (i) add a frontmatter contract (`owning-layer` / situational triggers /
  required-tools), (ii) build/decide the **consumer** that reads it. Frontmatter alone is the
  "documentation, not infrastructure" trap (zapier b1; commands-vs-skills b1) — `[map §1]` confirms
  **no router exists**.
- Plugin-as-package is the **§8 endpoint, not a near-term build**: a plugin is a versioned release, and
  you cannot version-distribute a harness whose canon↔disk disagree on hooks, pass counts, rosters, and
  memory model. Sequence: **converge canon↔disk first, then package** (commands-vs-skills b4).
- Take the *principle* (one source, deployed outward, rebuildable from clone), not literal three-repo
  packaging (harness-survey b4).

### G2 — `block-dangerous-bash.sh` (the deterministic safety floor) is absent
**Citation:** `[map §3e, §5]` — canon's 3rd structural guard (deploys, `rm -rf`, writes to
`.git`/`.husky`/`.claude`), "ABSENT on disk… Disk has no safety-floor bash guard."
**Sources:** commands-vs-skills (b2), zapier (b2), harness-survey (b1), osmani (b, §5 registry),
augment (b2), mcp-servers (b2).
**The gap:** The single highest-value, lowest-cost item the whole cluster converges on. For
**unattended/AFK** sessions, a destructive-op rule that lives only in CLAUDE.md prose is *mis-tiered*
— advisory enforcement for a receiver that isn't watched. This is the **execution-side backstop** that
pairs with G6's activation-side flag: the flag governs who starts a skill, the bash guard governs
whether the dangerous syscall can run (commands-vs-skills b2).

### G3 — No context/drift detector: `/scan-context` is canon-documented but absent on disk
**Citation:** `[map §5]` ("`/scan-context`… Documented skills with no disk dir"); `[map §0 correction
log]` (live proof the rot is real — `HARNESS-AS-IS.md` itself carried 4 stale absence-claims that
ground-truthed false).
**Sources:** packmind (b1, "single highest-value mapping"), basis-canon-not-canon (b2), basis-monorepo-deep
(b3), harness-survey (b7).
**The gap, with the cluster's build-spec sharpening:** the detector must catch **both drift directions**,
not one:
- **doc-stale** (code moved, doc didn't), and
- **doc-fiction / ghost rules** (doc asserts a rule the code never followed). `[map §6]` proves
  doc-fiction is our *live* failure class — phantom refs `learned-patterns.md`, `review-log.md`,
  `triage-inbox.md`, `skills-lock.json`, `agentic-system-enabled`, plus `/cr-feature` still referenced
  after retirement (`[map §3b]`). A pure doc-vs-code scanner (the articles' default model) would miss
  our own stale self-references.
- Must also run the **decay side** (`[map §9]` "ghost rules if unobserved 90 days; collapse"), which
  today is prose-only, "encoded in no tooling" `[map §4]`. Build the staleness *and* decay sides
  together (packmind b1, b3).

### G4 — The memory model is incoherent: triple-duplication, an unmodeled 6th store, no automated writer
**Citation:** `[map §4]` (Phase-3 crux: triple-duplication the canon "both sanctions and forbids";
`/compound` flags entries "already covered by PITFALLS (redundant)"; freshness rules for only 3 of ~14
stores); `[map §6]` (auto-memory `MEMORY.md` + 51 siblings — a 6th store "not in the canon at all,"
no writer/reader/freshness); `[map §3e, §5]` (`session-end.sh` Stop hook canon-declared, absent on
disk; "disk's memory is fully manual").
**Sources:** osmani (b2, b3), basis-monorepo-deep (b1), basis-canon-not-canon (b3, b4), packmind (b2,
b4), commands-vs-skills (b3, mis-tiered triggerable stores).
**The gap, deduplicated into one target:** ONE coherent model that (a) accounts for the auto-memory
store, (b) gives every store one writer / one reader / one freshness rule, (c) collapses the
triple-duplication in **tooling, not prose**, (d) adds the absent automated writer (`session-end.sh`).
Two cluster-specific reframes:
- The "anti-rationalization table format" borrow (osmani) is real but **reframed from "restructure a
  template" to "decide the store, then bind its format to an enforcer"** — a format with nothing that
  greps it is the advisory downgrade the source warns against.
- Tiering correction (commands-vs-skills b3): the *triggerable* duplicated stores
  (PITFALLS/RECURRING-FINDINGS) are mis-tiered into always-loaded and should demote toward tier-2/3;
  the *un-triggerable* safety floor (`[map §9]` keep-verbatim) must **stay** tier-1 regardless of
  length. The gap is "mis-tiered triggerable content," not "shrink the root."

### G5 — Skill descriptions are phrase-keyed (the §9 anti-pattern), not situational
**Citation:** `[map §9]` — "Phrase-keyed skill descriptions → trigger should be the situation, not the
words" listed as a capability proxy to **replace**. `[verified, commands-vs-skills]` the live `/cr`
description literally enumerates trigger-words ("when the user says '/cr', 'run a code review'…").
**Sources:** commands-vs-skills (b1), zapier (c, last bullet), mcp-servers (a4).
**The gap:** descriptions are the trigger surface but encode *words*, not *situations*. The fix is to
**rewrite descriptions as situations**, which simultaneously satisfies §9 and moves activation
conditions into where the model reads them. NB this is also the trap in G6/G1: any new `triggers`
frontmatter must be situational or it hard-codes the exact §9 anti-pattern.

### G6 — Zero structural invocation-control frontmatter on side-effectful skills
**Citation:** `[verified, commands-vs-skills]` 0/26 skills use `disable-model-invocation`,
`user-invocable`, `paths`, or `context: fork`; frontmatter is `name`+`description` only.
**Sources:** commands-vs-skills (b2).
**The gap, tier-bounded:** the flag is a *trigger-gate* (who starts the skill), not a *kill-gate*. For
**reversible** side effects (`/queue` opening a PR) the flag is the correct, cheap tier. For
**irreversible** ones (force-push, migration apply) the structural backstop is the PreToolUse guard
G2, not the flag. Adopt the flag for reversible skills; route irreversible ones to G2.

### G7 — Subtractive enforcement has no home: `/simplify` is canon-documented but absent on disk
**Citation:** `[map §3b]` ("Documented in canon, ABSENT on disk… `/simplify`"); `[map §5]` (canon-only
build-or-reject); `[map §"How later phases cite this map"]` names `/simplify` as a canon-only absence
to wire.
**Sources:** osmani (b1, "page's strongest gap").
**The gap:** every guard/skill in §5/§6 is **additive or preventative** — nothing drives *removal*.
This is the deletion half of the Model Capacity Audit (§9) the cluster repeatedly endorses in
principle but has no mechanism for. Build-or-reject `/simplify` (or fold a deprecation pass into the
G3 drift detector's decay side).

### G8 — No stop-the-line / defect-halt for unattended runs, and no Stop hook that verifies test output
**Citation:** `[map §3c]` (`/cr` has "no REJECT tier, no UNATTENDED branching… no Pass 10"); `[map §3e,
§5]` (`session-end.sh` Stop hook canon-declared, absent — an unattended session can complete with
red/unrun tests); `[map §3f]` (`ci.yml` runs per-PR but nothing halts a *series* of agent PRs on a
recurring failure).
**Sources:** osmani (b4), harness-survey (b2, Stripe "max 2 CI rounds then human"), augment (b3),
packmind (b5, "unattended runs have the least context-maintenance support").
**The gap:** the harness is explicitly heading toward unattended/AFK operation (`[map §0, §6]`) yet has
no bounded-retry/handoff primitive and no Stop-hook check that test output is green before a session
completes. Two coupled needs: (i) a defect-class halt that stops stacking PRs on a known-broken
foundation, (ii) a Stop hook that verifies tests before "ownership" defers to a review that may never
scrutinize it.

### G9 — CI never verifies the `.cr-ok` sentinel (the "8.5(c) gap")
**Citation:** `[map §3f]` — "CI never verifies `.cr-ok`… gitignored, never reaches CI."
**Sources:** osmani (b5), basis-monorepo-deep (b4), augment (b6), harness-survey (b2).
**The gap:** the whole push-gate depends on a sentinel that lives entirely in the advisory layer with
no deterministic backstop at the CI boundary. This is the most direct application of the cluster's
recurring "evidence-based verification is honor-system" insight turned **on ourselves**.

### G10 — No canon/not-canon authority taxonomy or precedence rule; no CI check validates any knowledge artifact
**Citation:** `[map §0, §7]` (bidirectional drift; canon internally inconsistent — two feature loops,
two reviewer names, Pages 12↔13 contradict, resolved only by an undocumented "later-dated wins"
convention); `[map §3a]` (no `authority-map` row); `[map §3e, §3f]` (CI validates code via `ci.yml`
but **no CI check validates any knowledge artifact** — nothing would have caught the §7 contradictions).
**Sources:** basis-canon-not-canon (b1, b6), basis-monorepo-deep (b1, b2).
**The gap, with the cluster's correction:** a binary canon/not-canon **label** is too crude — our §7
failures are *canon-vs-canon* (two pages disagree), so we need the **precedence rule** ("later-dated
wins") made **explicit and machine-checkable**, plus a CI/scanner check for contradictions and
duplicated instructions. This is the ontology that lets G3's scanner and G4's dedup actually run.

### G11 — MCP: consume side has no trifecta gate, and tool/MCP descriptions are outside `/cr` scope
**Citation:** `[absent]` (no map section encodes a combination check for an agent holding prod-data
read + untrusted input + egress); `[map §3e Net enforcement picture]` ("overwhelmingly advisory… no
deterministic backstop"); `[map §3c]` (`/cr` is 9 passes over the branch diff, **no pass for
tool-poisoning / rug-pull review** of MCP tool definitions or SKILL.md description frontmatter).
**Sources:** mcp-servers (b1, b3).
**The gap:** `.claude/mcp.md` gates *destructive* MCP tools but encodes no *combination* (trifecta)
check — and `.env.local` targets **production** Supabase, so the private-prod-data leg is always
present for any agent with Supabase MCP. Two yields: (i) encode the trifecta gate for **consumed**
tools (the genuinely new control, where our *live* exposure actually sits), (ii) bring consumed
third-party MCP tool descriptions into a `/cr`-style pin/diff (they can rug-pull; nothing pins them).
Instrument A (the two-question MCP-addition gate) folds into `.claude/mcp.md` but is advisory unless
tied to G2.

---

## 2. alreadyDo (confirmed built — do NOT re-propose)

- **Unified skills machinery; no legacy `.claude/commands/`.** All 26 skill dirs use `SKILL.md`;
  25/26 carry `name`+`description` frontmatter. The "command vs skill?" migration question is moot for
  us. `[map §3b]`, `[verified, commands-vs-skills]`.
- **AGENTS.md + CLAUDE.md as dual root, skills-based harness.** `[map §3a]`. The "your harness is
  already skills-based with AGENTS.md as the single root" framing is correct (commands-vs-skills a).
- **`/cr` with 4 real fresh-context lens agents** (assumption/composition/cascade/abuse), 9 passes +
  adversarial over the branch diff. `[map §3c, §3d]`. Fresh-context personas already prevent the
  contamination in-context personas would cause (osmani a).
- **`/cr-security` built** (3 disk passes). `[map §3c]`.
- **Tier-0 worktree isolation + prod-key firewall** (`worktree-create.sh`, `gen-local-env.sh`,
  `test-local.sh`) — a genuine disk *advance* the canon lacks; the strongest, fully disk-verified
  enforcement we have. `[map §3e, §6]`. (osmani a, zapier a, harness-survey a, mcp-servers a6).
- **PreToolUse guards** `block-dangerous-git.sh`, `block-npm-install.sh`; pre-commit (tsc/lint/vitest),
  pre-push (tests + `next build`), `.cr-ok` sentinel chain. `[map §3e, §3f]`. (NB: these *exist* but
  fail-open on missing `jq` — see rejectAsLiteral / G2 context; and `.cr-ok` is not CI-verified — G9.)
- **A real memory layer** — five canon stores + a 6th auto-memory store; freshness exists for 3 stores
  (memory 90-day `last_seen`, RECURRING-FINDINGS cap-at-5, PITFALLS changelog). `[map §4]`. We
  materially *exceed* the sources on manual memory richness; the gap is coherence (G4), not existence.
- **23 sub-agents** incl. 4 review lenses, hotfix-guard, solution-evaluator, incident-responder, 6
  spike agents — exceeds every source's roster count. `[map §3d]`.
- **Skills as on-demand, trigger-gated procedures** (~26 dirs; "if the task touches Supabase, invoke
  `/supabase`"). The localization / cross-folder-knowledge pattern is built. `[map §3b]`.
- **`src/data/` as intent-level tool boundary** — "few high-impact tools over 1:1 wrappers" is our
  existing architecture under a different name (mcp-servers a3). `[CLAUDE.md]`.
- **Default-no / curation as a hard rule** — "Build what's needed now," "no abstraction until the 3rd
  occurrence," and §9's golden rule ("if you can't name a failure mode the constraint prevents, it's
  overhead"). Default-no applied to *rules themselves*, stronger than the sources' default-no on
  context lines. `[map §9]`, `[CLAUDE.md]`.
- **MCP consume-not-build posture, with destructive tools gated** — `.claude/mcp.md` "consume to build
  faster; defer building"; settings.json allowlists only *read* Supabase MCP tools; we expose no
  authored MCP server. `[disk: .claude/mcp.md, settings.json]`, `[map §6]`. (mcp-servers a1, a2, a5).
- **Two-layer architecture in skeleton** — probabilistic context layer (CLAUDE.md/CONTEXT.md/SOUL.md/
  AGENTS.md/PITFALLS.md) + deterministic enforcement layer (5 Claude + 3 git hooks). The three-tier
  rules taxonomy (always_apply ≈ CLAUDE.md, agent_requested ≈ skills, manual ≈ `/skill`) is already
  mapped onto our layers. `[map §3a, §3e, §3b]`. (augment a1, a2).
- **Context docs split finer than the sources' single "playbook"** — CLAUDE.md + AGENTS.md + CONTEXT.md
  (15 KB, PR #92) + SOUL.md all present and aligned. `[map §3a]`. (packmind a, harness-survey a6/a7).

---

## 3. rejectAsLiteral (article advice WRONG for us if taken literally)

- **"Front-load trigger words into the `description`" (commands-vs-skills, zapier).** This *is* `[map
  §9]`'s phrase-keyed-descriptions capability proxy — the exact thing the Model Capacity Audit says to
  remove. Fatal if inherited verbatim; salvageable only as "situational description." → G5.
- **"Shrink the root CLAUDE.md to ~200 lines" / treat line-count as the audit metric (commands-vs-skills,
  harness-survey).** The principle is **trigger-existence, not length**. Blindly shrinking risks
  demoting no-trigger safety content (`[map §9]` keep-verbatim: destructive-op/PocketOS rules, prototype-
  deletion, tracer-bullet-first) into a tier that only loads on match — i.e., never loading when needed.
- **`disable-model-invocation` as "structural enforcement" for irreversible actions (commands-vs-skills).**
  It is a trigger-gate, not a kill-gate; it does not make a force-push or migration-apply safe. Routing
  irreversible actions to it instead of to G2's bash guard would leave the dangerous syscall reachable.
- **Cross-model escalation for irreversible classes (auth/schema/RLS/payments) (osmani borrow #2).**
  Internally contradicted: it "can flag but never block… skipped in every non-interactive context (CI,
  `/loop`)," yet is aimed exactly at the classes with no CI oracle and most likely to be skipped
  unattended. Adopt only with a forcing function (don't let `/cr` close a MUST-FIX in an irreversible
  class without the second-model pass), or it inherits the honor-system hole.
- **"Daily workers auto-implement scanner findings" / closed agent-fixes-agent loop (basis).** Actively
  dangerous at solo scale: our own rules forbid agent edits to guard files/settings without human
  handoff and forbid unattended mutation (`[memory: No agent edits to guard files]`, `[CLAUDE.md
  destructive-op floor]`). Keep maintenance **detection** automated; keep **repair** human-gated.
- **Default-no / push-all-rules-down-to-on-demand-skills (basis, packmind).** Applied naively this
  moves the omnipresent destructive-operation floor and Tier-0 credential rules into on-demand skills —
  precisely the rules that must load *always* because they're never task-relevant until they save you.
  Default-no must be **subordinated** to §9 "keep verbatim — safety," not allowed to override it.
- **Target `/cr-feature` (zapier's central exercise; harness-survey, basis framing).** `/cr-feature`
  was **RETIRED v0.85**, folded into `/cr`; disk correctly has no `/cr-feature` `[map §3b, §5, §7]`.
  Re-target every such recommendation to `/cr` or drop. The single biggest staleness across the cluster.
- **Phantom skill `/change` (commands-vs-skills, osmani).** No `/change` exists `[verified]`; the real
  migration skill is `/migrate`. Recommendations citing `/change`'s "reversibility gate" rest on a
  skill that isn't there.
- **"Align /cr to nine report-sections" (zapier).** Our `/cr` is parallel *passes*, not a nine-*section
  report* `[map §3c]`. Aligning section names blindly cargo-cults a shape we don't have.
- **"Encode 2–3 pieces of Tanner's head-knowledge as knowledge-skills" without a gate (packmind).** A
  knowledge-skill is the *most* drift-prone artifact; without a "does the model already infer this on
  Opus 4.8?" gate this manufactures exactly the ghost rules `[map §6, §9]` warn against.
- **"Add a hooks layer / we have zero hooks (CRITICAL)" (harness-survey Gap 1).** FALSE — `[map §3e]`
  lists 5 Claude + 3 git hooks. The narrow real absence is `block-dangerous-bash.sh` (G2), not "hooks."
- **Cite the sources' ROI numbers as evidence (all marketing-heavy articles).** 5x/2.5x (Basis),
  90%/34-FTE/11% (Zapier), 91%/5%/25% (Packmind), +25%/40–60%/60–80%/67% (Augment), 178k⭐/98%-coverage
  (survey), MCPTox 60–72% / 8,000+ servers (mcp). All single-source, uncontrolled, or self-disowned by
  their own pages. Adopt *ideas*; never cite the *numbers* in a V2 proposal.

---

## 4. crossThemes (patterns recurring across cluster articles)

1. **"Structural beats advisory" — but it's a budget claim wearing a capability costume.** Every
   article (Augment, Zapier, Basis, Harness-survey, commands-vs-skills) argues deterministic enforcement
   over prose. `[map §3e]` confirms our floor is "overwhelmingly advisory." But the correct test is
   **match enforcement-tier to receiver** (unattended ⇒ deterministic), not "more hooks always." Several
   of our "deterministic" guards are fake-deterministic (fail-open; wired-out `.githooks/pre-commit`).
2. **Frontmatter/format is inert without a consumer.** Recurs in commands-vs-skills, zapier,
   basis-deep, osmani: every "add a contract/table/label" recommendation must name what **greps or
   blocks** it, or it ships the advisory downgrade it warns against. "Enforce" = a hook/CI/gate acts on
   it, not that a CLAUDE.md line mentions it.
3. **The sources audit *their* example's enforcement and exempt *ours*.** osmani, augment, zapier,
   harness-survey, basis all run "their advisory vs our structural" — and the map shows the honest
   picture is "advisory vs mostly-advisory-with-a-few-gates." The durable move is to **turn each
   article's lens back on our own disk** (where every real gap below was found).
4. **Subtraction is under-theorized everywhere; we already authorize it.** Packmind, Augment, Basis,
   Harness-survey all give a monotonic add-on-failure ratchet with no decay rule. `[map §9]` (Model
   Capacity Audit) is the decay rule the whole cluster lacks — and it's *ours*, in writing, just not in
   tooling (G3 decay side, G7 `/simplify`).
5. **Context *currency/accuracy*, not volume, is the moat — and our context rots provably.** Packmind,
   Basis, Harness-survey converge here; `[map §0 correction log]` is the live proof (`HARNESS-AS-IS.md`
   rotted). Drives G3 (scanner) and G10 (contradiction CI).
6. **Distribution/portability is the central structural fact of V2.** commands-vs-skills, osmani,
   harness-survey, basis all land on `[map §8]`. Every one couples it with: converge first, then
   package; take the principle, not the literal packaging.
7. **The model-capability boundary moved (Sonnet 4.6 → Opus 4.8), invalidating scaffolds.** §9 recurs
   as the lens that kills phrase-keyed triggers, option-count forcing, and ghost rules — and augment (b7)
   sharpens it into a missing capability: nothing re-classifies a rule as "now inferable → delete."

---

## 5. freshResearchWarranted (genuine, bounded checks only)

Every pass-3 concluded **synthesize, don't re-research**; all actionable items map to existing §3–§9
rows. Only these bounded *verification* checks survive (none is an open-ended research project):

- **Agent Skills frontmatter schema check (~10 min).** Before writing any invocation-control frontmatter
  (G1/G6), confirm the *current, exact* canonical field names against the published Agent Skills /
  agentskills.io spec — whether the keys are `disable-model-invocation` / `user-invocable` /
  `allowed-tools` (article spelling) vs the spec's actual names, and whether Routines honor them. Flagged
  by **both** commands-vs-skills (d) and zapier (d) — do it once, for both.
- **Claude Code hard-limit facts (one pass).** Verify the survey's asserted "40K char CLAUDE.md cap,
  256KB read limit, IMPORTANT used 4×" — falsifiable platform facts with **no map row**; if true and our
  root is near the cap, it's a concrete cut (informs G4 tiering). harness-survey (d).
- **`vitest` diff-scoped test selection by changed-path (~10 min).** Only *if* a future slice adds a
  diff-scoped pre-PR test gate beyond the existing pre-commit chain. basis-canon-not-canon (d).

**Explicitly NOT research (internal synthesis joins, not the web):** the Layer-5 ↔ map join (is
`/change`, the `/cr` REJECT tier, F2-weighting, ratchets, the Ashby `feature_flag` column
decided/planned or merely named?) — osmani (d); reading how existing Matt-Pocock skills expect
frontmatter so we extend rather than fork their convention — basis-deep (d); a drift-detector *design*
spike reading our own repo+canon — packmind (d); correcting the "Playwright MCP / ProofShot" factual
error against `.claude/mcp.md` before mcp-servers feeds any proposal — mcp-servers (b5, done in pass3).
