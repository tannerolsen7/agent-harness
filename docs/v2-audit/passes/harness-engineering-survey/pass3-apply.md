# Pass 3 — Apply

Building on pass2: apply the survey to OUR harness as it *actually exists* per `CANONICAL-HARNESS-AS-IS.md`
(the ground-truth map). The discipline rule from that map governs: **no claim survives without a citation to a
map row or a confirmed absence.** Because the article is a snapshot frozen 2026-05-21 whose baseline is an
unverified mental model (pass2-E), the first job is to *ground-truth its self-assessment* before extracting any
gap.

---

## (a) What we ALREADY do — the article's "gaps" that ground-truth proves false or stale

The survey's most confident gap claims (pass1 Part 4) collide with the map. Citing rows:

1. **"No hooks layer / we have zero hooks (CRITICAL, Gap 1)" — FALSE on disk.** The map's §3e Hooks table lists
   five live Claude hooks plus three git hooks: `block-dangerous-git.sh`, `block-npm-install.sh`,
   `session-start.sh`, `permission-logger.sh`, `worktree-create.sh`, plus pre-commit/pre-push/post-checkout
   [map §3e; §1 "5 Claude hooks, 3 git hooks"]. The article's flagship CRITICAL gap is its single most stale
   claim. What is *actually* missing is narrower — see (b) gaps 1–3.
2. **"No isolated execution environment (Gap 5, AFK blocker)" — substantially FALSE.** Disk has
   `worktree-create.sh` implementing a **Tier-0 prod-key firewall** + worktree provisioning, called out by the
   map as "a genuine disk *advance* over canon" [map §3e `worktree-create.sh`; §6 disk-only registry]. This is
   exactly the Stripe-devbox-style isolation (pass1 Part 2 source 5) the article says we lack.
3. **"Memory is manual / no auto-capture (EQUAL table)" — partly FALSE.** Disk runs a sixth, auto-written
   memory store the canon doesn't even model: auto-memory `MEMORY.md` + 51 siblings, "written by the Claude
   Code subsystem, not any skill" [map §4; §6]. The ECC-Hermes "auto-captured session history" the article
   envies (pass1 Part 4) partially exists.
4. **"`/cr-feature` / verification loops" framing — STALE.** The article references `/cr-feature` as live
   (pass1 Part 3 source 24). The map records `/cr-feature` **RETIRED v0.85, folded into `/cr`**; disk correctly
   has no `/cr-feature` [map §3b]. Our verification loop is the live 9-pass `/cr` + 2–3-pass `/cr-security`
   [map §3c].
5. **"8 specialist agent templates" — STALE undercount.** Disk has **23 agents** including the 4 review lenses,
   hotfix-guard, solution-evaluator, incident-responder, 6 spike agents [map §3d]. The routing the article asks
   for (Gap 9) is partly embodied in skills that already route to sub-agents (e.g. `/cr`, `/refactor`,
   `/queue`) [map §3d; §1].
6. **"SOUL.md as engineering character" — CONFIRMED present, aligned.** `.claude/SOUL.md` exists and is map-
   aligned [map §3a row `.claude/SOUL.md`]. The article's BETTER claim here is the one self-assessment that
   ground-truths true.
7. **Spec-first / context docs the article credits us with — CONFIRMED.** `docs/TESTING.md`, `CONTEXT.md`
   (15 KB, PR #92), `docs/ARCHITECTURE.md`, `AGENTS.md` all exist [map §3a]. The article's "we have CONTEXT.md;
   may need tech-stack.md" (pass1 Part 3 source 3) is reasonable but minor.

**Bottom line for (a):** roughly half the article's gap analysis describes a harness we already surpassed. This
is the pass2-E prediction confirmed against disk — the baseline was a mental model, and the map is newer.

## (b) REAL gaps it exposes — each citing a ground-truth row or confirmed absence

Filtered to claims that survive ground-truthing. Each maps to a §3–§9 row per the map's citation rule.

1. **No `block-dangerous-bash.sh` safety-floor guard — CONFIRMED ABSENT.** The map marks the canon's third bash
   guard (deploys, `rm -rf`, writes to `.git`/`.husky`/`.claude`) as "**ABSENT on disk**" [map §3e
   `block-dangerous-bash.sh`; §5 build-or-reject]. The article's Gap 1/Gap 5 PreToolUse-deny instinct is right
   *here specifically*, even though its "zero hooks" framing is wrong (pass2-B: this is the *deterministic
   floor* half of "hooks"). This is the single highest-value, lowest-cost item the article points at.
2. **No defined stopping condition for retries — CONFIRMED ABSENT.** The map records `/cr` has "no REJECT tier,
   no UNATTENDED branching… no Pass 10" and CI "never verifies `.cr-ok`" (the 8.5(c) gap) [map §3c; §3f]. The
   article's Stripe "max 2 CI rounds then human" (pass1 Part 2 source 5; pass2-F2) is a real missing primitive
   for AFK runs — the map confirms no bounded-retry/handoff machinery exists.
3. **No sensors / measurement loop — CONFIRMED ABSENT.** The map's net enforcement verdict: "**Both agree the
   system is overwhelmingly advisory** — neither has a deterministic backstop for the bulk of skill bodies,
   CLAUDE.md rules, or the autoMode lists" [map §3e net picture]. There is **no eval/drift/quality-scoring store
   anywhere** in §3–§9. This is the article's Gap 4, and it is the survey's sharpest surviving diagnostic
   (pass2-F3): we are all guides, almost no sensors.
4. **The harness cannot leave event-vendor — CONFIRMED ABSENT (the central structural fact).** The map's
   headline: "the harness the canon describes as 'global / multi-project' is, on disk, a **single-project
   artifact**… There is no installable, shared, version-controlled harness" [map §0; §8]. The article's Gap 2
   (three-repo / cross-project sharing) names the single most important real gap — but per pass2-G, take the
   *principle* (one source, deployed outward, rebuildable from clone), not the three-repo packaging.
5. **No global `~/.claude/CLAUDE.md` — CONFIRMED ABSENT.** "Canon-mandated, absent globally — values live only
   in project SOUL" [map §3a `~/.claude/CLAUDE.md`; §2; §5]. The article's "cumulative layer loading" EQUAL row
   (pass1 Part 4) points at this; the global behavior layer genuinely does not exist on disk.
6. **No harness-self security audit — CONFIRMED as a real absence, but scoped down.** Disk *does* have real
   security machinery (Tier-0 firewall, `block-dangerous-git`, PreToolUse guards) [map §3e; §6], so the
   article's "never been audited / no AgentShield" (Gap 3) overstates. The true gap: no *systematic* audit pass
   over CLAUDE.md/settings.json/MCP/skills for injection + over-permission — nothing in §3–§9 records one. A
   `/cr-security`-style sweep of the harness *files themselves* is a citable net-new (no row covers it).
7. **No context-rot / staleness check on harness files — CONFIRMED ABSENT, with a live exemplar.** The map's
   own correction log proves the rot is real: `HARNESS-AS-IS.md` "predates files the repo has since created"
   and "the project audit artifact itself rots" [map correction-log §0]. The article's Gap 7 (`agents-lint` in
   CI) targets a confirmed failure mode — our own audit drifted. Caveat from pass2-D: prefer a *derived* check
   over a *maintained* manifest.

## (c) Weaknesses in the article's OWN reasoning (independent of our harness)

1. **Two contradictory theses, unreconciled (pass2-A).** The additive action map (Parts 2–5) is contradicted by
   the article's own elevated finding — ETH's "comprehensive context harms" + LangChain's "max budget scored
   worse." Subtraction is one MEDIUM line item where it should be a tier. Our map *already authorizes* the
   subtraction the article underweights: Page 13's Model Capacity Audit pre-authorizes removing capability
   proxies [map §9]. The article never reaches this conclusion its own evidence demands.
2. **Unverified baseline (pass2-E).** Half its gaps are stale against disk (section (a)). A gap analysis whose
   "current state" is introspective guesswork cannot be trusted for prioritization — which is exactly why the
   page banner forbids using it for implementation decisions.
3. **Survivorship bias (pass2-C).** Every flagship exhibit (Stripe/OpenAI/Spotify/ECC/Carlini) is a large org
   or a forgiving domain; conclusions are imported into a single-operator Next/Supabase context without scale
   adjustment. Stripe's own lesson (infra predated LLMs) hints the causation is org-maturity, not features.
4. **"Hooks" conflates floor and sensor (pass2-B).** Filing deterministic blocks (Gap 1) and measurement loops
   (Gap 4) as different "layers" obscures that we have lots of the former [map §3e] and ~none of the latter.
5. **Manifest/graph self-contradiction (pass2-D).** Gap 6 proposes hand-maintained manifests; Gap 7 proposes a
   linter *because such artifacts go stale* — disease and cure as two separate "improvements." Against our map,
   this is the triple-duplication trap restated [map §4]: more sources of truth, more drift.
6. **Citation softness.** Several headline numbers ("178k ⭐," "1,282 tests / 98% coverage," "84% reduction in
   prompts," Anthropic's "40–60%") are single-source and uncheckable here; the article presents them with the
   same weight as the peer-reviewed ETH study. Treat as opinion-grade until verified (pass1 tagging).

## (d) Does it warrant fresh external research? — Mostly NO; synthesize.

Disciplined verdict per source-of-truth rule: **prefer synthesize over re-research.** Most of what this survey
offers is already metabolized by adjacent corpora and the map.
- **Do NOT re-research:** the AGENTS.md/context-file body (ETH, Augment, ASDLC, Kaplan) — it overlaps the
  existing "AI-Native Engineering Research" and "Agent-harness research tree" already in Notion + memory; and
  the three-repo / cross-project thesis, which the map already states as its central V2 driver [map §0; §8]. No
  new read changes those decisions.
- **Two narrow, high-value verifications worth a *targeted* check (not open-ended research):**
  1. **The Claude Code hard limits** the article asserts — "40K char CLAUDE.md cap, 256KB read limit, IMPORTANT
     used 4×" (pass1 Part 4 Gap 8 / Part 3 source 17). These are *falsifiable platform facts* that would
     directly drive a CLAUDE.md audit, and our map has no row on CLAUDE.md size. If true and our root CLAUDE.md
     is near the cap, it's a concrete cut. Worth one verification pass; do not boil the ocean. (Note: our own
     guidance already says skill files hinder when they restate what the model knows [memory: skill-file design;
     map §9] — same direction.)
  2. **`block-dangerous-bash.sh` content** — not external research, but a one-time look at the canon §08 spec
     [map §5] before building, since it's the top (b) item.
- **Net:** this article's value is as a *cross-check and vocabulary source* (guides/sensors; the Hashimoto
  ratchet; Stripe's bounded-retry), not as a research target. It earns **one bounded verification** (Claude Code
  limits) and otherwise feeds synthesis. The real gaps it surfaces — (b)1 bash guard, (b)2 stopping condition,
  (b)3 sensors, (b)4 portability, (b)6 harness-self audit — are all already citable in the map and need building,
  not more reading.
