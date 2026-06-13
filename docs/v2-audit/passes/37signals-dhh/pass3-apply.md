# Pass 3 — Apply: against our harness and the ground-truth map

Building on pass2: pass2 §A established the subject/object inversion (37signals exposes its PRODUCT to
others' agents; our harness is the agent's OWN workbench); pass2 §F distilled the two genuinely portable
ideas (an accessibility-tier MAP as a diagnostic, and selective friction removal that preserves
pace/commitment friction); pass2 §C named the article's deepest hole (CLI thesis ignores MCP); pass2 §E
named its unpriced assumptions. This pass tests those against `CANONICAL-HARNESS-AS-IS.md` (cited as
[GT §N]) and decides what, if anything, the article warrants for V2.

Governing rule of the map: no proposal survives without citing a row — a real gap or a confirmed absence.

## (a) What we ALREADY do

- **CLI-first dev tooling is already our reality, not an aspiration.** The article's headline candidate
  (pass1 §7, pass2 §F1) — expose dev tools via CLI — is largely already done. [GT §3f] lists disk
  scripts `pr.sh`, `worktree-add.sh`, `gc.sh`, `gen-local-env.sh`, `test-local.sh`, `seed.ts` and CI
  `ci.yml` + `integration.yml`; the agent already operates the project through Supabase CLI, git, npm,
  and `scripts/*`. The "build CLI-first for recurring admin ops" principle (pass1 §9) is the existing
  pattern, not a gap.
- **Skills-as-encoded-product-knowledge already exists, at scale.** The article's "Skills" leg (pass1
  §2) and house-skills-as-reference (pass1 §7) describe what [GT §3b] already documents: ~26 project
  skill dirs plus 15 global skills. We don't need house-skills as a *reference for skill structure* —
  we have a far larger, project-tuned skill corpus already running.
- **Tool-surface gating already exists and is stricter than 37signals'.** pass2 §E3's permission
  dimension is already a first-class mechanism here: `permissions.allow` / `additionalDirectories`
  [GT §2], the three bash/git/npm guard hooks [GT §3e], and the UNATTENDED prod-key firewall
  (`worktree-create.sh`, [GT §3e, §6]). 37signals' "any user-chosen agent" model has no analogue to our
  Tier-0 credential isolation — on the permission axis we are *ahead* of the article's frame.
- **Selective-friction doctrine already exists in canon.** pass2 §D/§F2's "kill action-friction, keep
  the load-bearing kind" is already the spirit of [GT §9] Model Capacity Audit's golden rule ("if you
  can't name a failure mode that the constraint prevents, the constraint is overhead") and its explicit
  Keep list (destructive-operation rules, manual-QA blocker). We already distinguish keep-vs-remove
  friction by failure-mode.

## (b) REAL gaps it exposes (each cites a row / confirmed absence)

1. **No accessibility-tier MAP of the agent's own operations exists — and the map's own scope confirms
   the absence.** pass2 §F1's one strong deliverable (classify every agent op: CLI / API / UI-required /
   not-possible) is genuinely absent. The ground-truth map inventories skills, agents, hooks, scripts,
   memory [GT §1, §3a–§3f] but contains **no operation-by-accessibility classification anywhere** —
   there is no row that says "operation X still requires a browser/human." This is a *confirmed absence*
   in the as-is map. It matters specifically for the UNATTENDED path: the prod-key firewall and
   `worktree-create.sh` [GT §3e] exist *because* unattended runs happen, but nothing maps which steps in
   an unattended loop still fall back to UI-required/manual. Low-cost, diagnostic-only — fits pass2 §F1
   exactly (a map, not a mandate to build CLIs).

2. **The pace/commitment-friction stopping point is genuinely unencoded — the memory/Stop-hook gap is
   the place it would live, and that's absent.** pass2 §D/§F2 and pass1 §7's stopping-point candidate
   map to a confirmed structural absence: [GT §3e] records `session-end.sh` (Stop hook) as **canon-
   declared, ABSENT on disk** ("disk's memory is fully manual"), and [GT §5] lists it as a canon-only
   item to build-or-reject. A session-end mechanism is the natural home for an explicit
   stopping/pace-discipline signal (DHH's burnout warning, pass1 §5). So the gap is real and *already
   on the build-or-reject ledger* — the article adds a *reason* (pace-friction) to a slot the map
   already flagged empty, not a new slot. This is the article's single best contribution: a rationale
   for [GT §5] `session-end.sh` beyond memory-capture.

3. **CLI surface is invisible to the permission gate — a real safety gap the article's CLI-evangelism
   accidentally surfaces.** pass2 §C: a CLI hides inside one allowed `bash` pattern, so the per-tool
   `permissions.allow` gate [GT §2] does not see individual CLI subcommands. The map confirms the
   enforcement layer is "overwhelmingly advisory" with "no deterministic backstop for the bulk of skill
   bodies / autoMode lists" [GT §3e net-picture]. The article's push toward MORE CLI chaining (pass1 §3)
   would *widen* that ungated surface unless paired with the bash guards [GT §3e]. This is a gap the
   article creates rather than fixes, but it's citable: pushing CLI-first without a `block-dangerous-bash.sh`
   ([GT §5], canon's 3rd guard, **absent on disk**) is exactly the unattended-risk the firewall exists
   to contain. The article's own thesis strengthens the case for building [GT §5]'s missing bash guard.

## (c) Weaknesses in the article's OWN reasoning

- **CLI thesis ignores MCP entirely** (pass2 §C). Verifiable from this very session's tool surface
  (Notion/Supabase/Vercel/Figma MCP servers). The article universalizes "CLI determines agent depth"
  (pass1 §3) without weighing the typed, discoverable, per-call-permissioned alternative that the 2026
  agent ecosystem already standardized. For our harness — where tools ARE gated per-call [GT §2] — MCP
  is often the *better* fit than the ungated CLI the article champions (pass3 §b3).
- **Subject/object inversion unacknowledged** (pass2 §A): 37signals' lesson is about a PRODUCT surface
  for others' agents; the article transfers it to our agent's OWN tooling by bare analogy. The economic
  logic ("users choose their own AI") does not transfer; only the diagnostic does (pass2 §F1).
- **Prices CLIs at zero for a solo dev** (pass2 §E1) — a CLI is a second tested/versioned/documented
  interface; the article's "build CLI-first for any recurring admin op" (pass1 §9) ignores that cost.
  Our project rule "do not extract a shared abstraction until the third occurrence" cuts directly against
  reflexive CLI-building.
- **Recommends house-skills as a reference before confirming structural comparability** (pass2 §E2;
  the article itself flags the frontmatter shape as an open question, pass1 §7). Recommendation ahead
  of verification.
- **Leans on authority for a threshold claim** (pass2 §E4): one prominent convert is an anecdote, not
  evidence agents crossed a general capability bar.
- **Doesn't reconcile its own friction contradiction** (pass2 §D): friction is villain in §2, safety in
  §5; the synthesis (selective removal) is left unassembled.

## (d) Does it warrant fresh external research?

Mostly **no — synthesize, don't re-research.** Disciplined verdict:

- The two portable ideas (pass2 §F) are actionable from the as-is map alone: the accessibility-tier map
  (pass3 §b1) is an internal audit, no external input needed; the pace-friction rationale for
  `session-end.sh` (pass3 §b2) attaches to an item already on [GT §5]'s ledger.
- The house-skills reference question (pass1 §7, pass2 §E2) is **not worth fresh research** — we have a
  larger project-tuned skill corpus [GT §3b]; reading an external library to learn skill structure is
  low-yield given the anti-duplication gate already governs additions [GT "How later phases cite this map"].
- The **one** narrow, bounded lookup that *could* pay off is **CLI-vs-MCP for agent tool surfaces**
  (pass2 §C) — but only if V2 actually proposes expanding the agent's tool surface. It is a decision
  input, not open-ended research, and should be deferred until a concrete proposal needs it. Default:
  **synthesize**; trigger external lookup only on a live CLI-vs-MCP build decision.

## Bottom line for V2

The article's headline (build CLIs / read house-skills) is largely **already done or low-yield** here
[GT §3b, §3f]. Its real, citable value is two-fold and narrow: (1) a one-time **accessibility-tier audit
of the agent's own operations** as a diagnostic for unattended-run gaps (confirmed-absent in the as-is
map, pass3 §b1), and (2) a **pace/commitment-friction rationale** that gives [GT §5]'s already-flagged,
absent `session-end.sh` a second reason to exist beyond memory-capture (pass3 §b2). Both map to existing
rows; neither warrants new external research.
