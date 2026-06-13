# Pass 3 — Apply: the article against OUR harness (ground-truth-cited)

Building on pass2: I take the pass-2 conclusions — the "two documents" thesis (pass2 §1), the
"agents-are-the-team" reframe (pass2 §2), the phantom-validation error (pass2 §3), the buried
review-bandwidth design rule (pass2 §4), the global-scope blind spot (pass2 §5), and the
skip-operational/keep-guardrails contradiction (pass2 §6) — and test each against
`CANONICAL-HARNESS-AS-IS.md`. Every gap below cites a ground-truth row or a confirmed absence.

## (a) What we ALREADY do (the page's "confirmation" claims, verified)

- **Centralized agent rules at the *project* layer — TRUE.** Map §3a row `CLAUDE.md (repo root)` =
  ✅/✅ "Aligned in purpose"; `AGENTS.md` = ✅/✅. The page's "centralized, tool-agnostic agent rules…
  made structural" claim (pass1 §D) holds *at the repo level*. Confirmed.
- **Compound engineering / reusable skills — TRUE (but not via the file the page names).** Map §3b
  lists `/compound` as on-disk-and-in-canon-aligned, and the runtime skill list confirms `/compound`
  exists. The *mechanism* is real; the page's specific cite (`learned-patterns.md`) is not (see (b)).
- **Specs-as-code — PARTIALLY TRUE.** Map §4 references `docs/adr/` (locked decisions) and the project
  uses `docs/specs/` (CLAUDE.md "New behavioral spec or agent-readable contract for a module →
  `docs/specs/`"). So agent-readable in-repo specs exist as a documented store. The page's "you're
  ahead — yours is enforced" is plausible but the map does not record a spec-referenced-through-
  adversarial-review enforcement chain, so "enforced" is unverified, not confirmed.
- **Guardrails / fast-feedback — TRUE in part.** Map §3e shows pre-commit (ESLint/tsc/vitest),
  pre-push, `/cr` 9-pass review, CI (`ci.yml`+`integration.yml`). Automated PR-review guardrail =
  `/cr`/`/cr-security`. The page's "fast feedback + guardrails so agent output can be trusted" maps to
  real disk mechanisms. Confirmed at project scope.
- **Background agents — TRUE.** Map §3e `worktree-create.sh` (UNATTENDED, prod-key firewall), plus
  `/queue`, background-agent operation referenced throughout. The page's "background agents… only safe
  behind real gates" is *already our posture* (Tier-0 credential isolation, map §3e disk-only advance).

**Verdict on the page's headline:** "confirmation, not change" is correct *for the project layer*. The
page accurately describes what we have built inside event-vendor. It is wrong by omission about scope
(see (b)).

## (b) REAL gaps it exposes — each cited

1. **The "centralized rules" ideal is met at project scope but NOT at global/cross-tool scope — the
   page's own top idea, unbuilt where it counts.** [CANONICAL §3a: `~/.claude/CLAUDE.md (global
   behavior)` = Canon ✅ / **Proj ❌ / Glob ❌** "Canon-mandated, absent globally."] Also [§5 registry:
   `~/.claude/CLAUDE.md` listed as canon-only item to build, "the global layer's missing keystone"] and
   [§8: "no global CLAUDE.md… harness has never been installed anywhere but event-vendor"]. The authors
   mean rules that work across Cursor/Claude Code/Devin *and across repos*; ours work in one repo. The
   page's praise masks this gap. **This is the article's most useful contribution: it independently
   re-derives "one centralized rules system" as the readiness keystone — which is exactly the
   canon-mandated, absent `~/.claude/CLAUDE.md`.**

2. **Review-bandwidth-vs-generation is an unmodeled design constraint.** (pass2 §4) The page supplies a
   real design rule — raising agent output without raising review throughput is net-negative (its
   +98%/+154%/zero-DORA finding). Against ground truth: [§3e "Net enforcement picture… overwhelmingly
   advisory — neither has a deterministic backstop for the bulk of skill bodies"] and [§3f "Node 8.5(c)
   gap (CI never verifies `.cr-ok`)"]. Our *generation* side is rich (`/queue`, 23 agents, worktrees);
   our *review* side is `/cr` (advisory, can be rationalized — memory `feedback_sentinel_bypass`) with a
   CI hole that never verifies the review sentinel. The page exposes that V2 has no explicit invariant
   tying multiplier scale to review/verification capacity. **Confirmed gap: no row in the map establishes
   review throughput as a first-class, deterministically-enforced constraint.**

3. **Agent-role coordination (Pillar 3, reframed) is a present problem with partial coverage.** (pass2
   §2) The page tells us to skip role/operational readiness; the map shows we *need* it for the agent
   fleet and only partially have it: [§3e `branch-registry-guard.sh` = Canon ✅ / **Proj ❌** "Canon
   structural, absent on disk"] and [§3e `enforce-scope.sh` = Canon ✅ / **Proj ❌**] and [§3e
   `session-end.sh` memory-handoff hook = **Proj ❌**]. These are exactly "role evolution / process when
   work parallelizes" — Pillar 3 content the page told us to defer. **The page's skip-list would have us
   defer building structural guards the map already flags as absent.** This is a case where the article's
   advice is actively wrong for us.

4. **The page validates us against a phantom — a factual correction.** (pass2 §3) The "Application"
   section cites `learned-patterns.md` as our built compound-engineering artifact. [CANONICAL §6 lists
   `learned-patterns.md` under disk-only phantoms "Referenced… never built"; and the closing section
   names it explicitly: "`learned-patterns.md` is §6 phantom… would be killed here."] **This is not a
   gap to build — it is a correction: the page's confirmation rests partly on a file that does not exist,
   so its "you've built the rigorous version" overstates our compound-engineering maturity.** The real
   compound mechanism is `/compound` (§3b), which is real; the *executable-constraints* file is not.

**No other gaps.** The Cultural pillar (champions, board case, contagious adoption) maps to **nothing**
in the ground-truth map and is correctly skip-able for a single human operator — the page is right there.

## (c) Weaknesses in the article's OWN reasoning

1. **"Team of one" = "one human" is the wrong unit.** (pass2 §2, §6) The harness orchestrates an agent
   fleet; coordination *is* the problem. The page's central filter ("no team to coordinate → skip
   Cultural+Operational") rests on a category error. The agents are the team.
2. **It confirms against unverified/phantom artifacts.** (pass2 §3, and (b)#4) `learned-patterns.md`
   does not exist; the "enforced specs" claim is asserted without a citation. A "you're already ahead"
   verdict reached without checking the map is exactly the failure mode the map's governing rule exists
   to stop.
3. **It buries its best idea (review-bandwidth) as a caveat and under-weights it.** (pass2 §4) The one
   first-order architectural constraint on the page is filed as a parenthetical.
4. **It treats "technically ready" as settled.** (pass2 §5) The entire V2 audit exists because the
   harness is *not* coherent (bidirectional drift, advisory floor). The page grants the premise the
   audit is built to contest.
5. **Self-contradiction: skip Operational pillar, but demand its outputs (gates/guardrails).** (pass2
   §6) "Only safe behind real gates" *is* operational readiness.
6. **Provenance is thin.** (pass1 caveat) Framework is paraphrased from a gated post; proof figures are
   self-reported and un-audited; one of two intended sources (LinkedIn #5) is unresolved. The page is a
   synthesis of secondary write-ups, not primary evidence.

## (d) Does it warrant fresh external research? — NO (disciplined synthesize-over-research)

- The framework's transferable core (specs-as-code, centralized rules, guardrails, compound skills,
  background agents) is **already covered** by other nodes in this corpus — the passes directory holds
  `notion-spec-driven`, `commands-vs-skills`, `zapier-skillmd`, `every-compound-lfg`,
  `vercel-agentic-infra`, `loop-engineering`, `goal-loop-primitive`, etc. Re-researching Vo/Davis would
  duplicate ground already worked.
- The one item that *could* merit research — the **review-bandwidth-as-binding-constraint** claim and
  its DORA/throughput evidence — is sourced to our **own internal "Svpino R1" finding** (the page cites
  it as ours, not the authors'). That is an internal artifact to *reconcile*, not an external topic to
  research. If anything is owed here, it is **locating and citing the Svpino R1 finding inside our own
  records**, not a fresh web search.
- The unresolved **LinkedIn #5** source is a known open item the page already flags; resolving it
  requires a logged-in fetch, not a research pass, and is unlikely to change any ground-truth-cited gap
  above.

**Recommendation:** synthesize, do not re-research. Fold three things into V2 planning, each tied to a
row: (i) re-derive "centralized rules" as the argument for building the canon-mandated
`~/.claude/CLAUDE.md` [§3a/§5]; (ii) elevate **review-bandwidth ≥ generation-bandwidth** to an explicit
V2 design invariant given the advisory-floor / CI-sentinel gaps [§3e/§3f]; (iii) reclassify the Cultural
pillar's "engineer the first win" as a *genuinely* deferred item (the page is right that it's not due) —
but reclassify Pillar 3 (Operational) as **present-tense agent-role coordination** and bind it to the
absent `branch-registry-guard.sh` / `enforce-scope.sh` / `session-end.sh` [§3e/§5], not to "when the
team grows." And correct the record: drop the `learned-patterns.md` validation [§6 phantom].
