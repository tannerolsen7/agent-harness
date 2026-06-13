# Pass 3 — Apply

Building on pass2: this pass maps the article against the ground-truth map
(`CANONICAL-HARNESS-AS-IS.md`). Every gap cites a map section or a confirmed absence. No gap without a
citation. The discipline (from the map's own rule): a Phase-2 insight is actionable only if it maps to
a §3–§9 row — not to a canon ideal already built, nor to a disk mechanism already covering it.

## (a) What we ALREADY do (cite ground-truth rows)

Building on pass2 §1 (the article is fundamentally a *subtraction* argument that converges with our own
Page 13): most of what the article "recommends," we already have — often more rigorously, as the
article itself concedes.

- **Harness-not-model / defense-in-depth.** The article's central thesis is already our operating
  doctrine. The map's headline frames the entire V2 effort as a response to harness-vs-model gaps, and
  Page 13 (`[canon §9]`) *already* distinguishes reasoning discipline (keep) from capability proxies
  (remove). We don't just believe "process over model" — we have a pre-authorized cut list built on it.
- **Gates (deterministic blocking).** We have them: pre-commit (ESLint + `tsc` + vitest), pre-push
  (all tests + `next build` + `.cr-ok` sentinel), CI `ci.yml` + `integration.yml`, two bash guards
  (`block-dangerous-git.sh`, `block-npm-install.sh`) `[map §3e]`. The article's "Gates" G is covered.
- **Guides (context in repo).** `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md` (15 KB, PR #92), `SOUL.md`,
  `agent-contract.md`, `INDEX.md`, `AI-WORKFLOW.md`, `docs/ARCHITECTURE.md` all present `[map §3a]`.
  The article's "context = new hire with amnesia" is the explicit premise of our session-start read
  ritual (`.claude/memory.md`, `TASKS.md`, `rituals.md`, `SOUL.md`). Covered.
- **Guards (fallback).** `/cr` 9-pass + adversarial, `/cr-security`, `/incident`, `/post-mortem`,
  `/hotfix`, `permission-logger.sh` `[map §3b, §3c, §3e]`. The article's third G is covered, plus a
  disk-only logger the canon never specified `[map §6]`.
- **Risk-tiered review (the article's headline reversal).** We already enforce review-scales-with-
  reversibility, and it is *codified as policy*, not vibes: CLAUDE.md mandates `/cr-security` only when
  a commit "touched auth, middleware, or RLS"; the destructive-operation rules (PocketOS) gate exactly
  the irreversible classes the article names. Page 13's golden rule — "if you can't name a failure mode
  the constraint prevents, the constraint is overhead" `[canon §9]` — *is* the article's standing rule,
  predating it. The article's "Nakazawa wins" conclusion is our status quo.
- **TDD discipline (partial — see gaps).** Failing-test-first is already mandatory for pure functions
  in `src/data/`, `src/schemas/`, `src/utils/` (CLAUDE.md "Pure functions (TDD required)"; the `/tdd`
  skill, a project-local fork `[map §3b]`). The *habit* exists; only its bug-fix extension is open.
- **Small-team / single-backlog reality.** The "skip the Tolaria orchestration apparatus" advice is
  moot — we have no contributor firehose and one backlog (`TASKS.md`). Already aligned.
- **Worktree isolation for safety not throughput.** `worktree-create.sh` + Tier-0 prod-key firewall
  `[map §3e, §6]` exists precisely as a safety mechanism. Already built.

## (b) REAL gaps it exposes — each citing a ground-truth section or confirmed absence

Building on pass2 §4 (the failing-test-first failure mode is real but the article under-argues it) and
pass2 §5 (its flagship recommendation targets a phantom file):

1. **Bug-fix TDD is not enforced outside `src/data` / `src/schemas` / `src/utils`.** The article's
   "one steal" is a real gap *for us*: CLAUDE.md scopes TDD to pure functions only. A bug fix to a
   component, a server action (`app/(app)/*/actions.ts`), or the `/p/[token]` renderer has **no
   reproducing-test requirement.** The map confirms no hook or gate enforces this: the enforcement
   layer is "overwhelmingly advisory… neither has a deterministic backstop for the bulk of skill
   bodies, CLAUDE.md rules" `[map §3e, Net enforcement picture]`. Gap = a *bug-class* executable
   constraint, citable as a confirmed absence in the gate inventory `[map §3e]`.

2. **The article's prescribed home for that rule does not exist — `learned-patterns.md` is a confirmed
   phantom.** The article says add it to `learned-patterns.md`; the map lists `learned-patterns.md`
   under "Phantom refs… referenced on disk, never built on disk *or* in canon" `[map §6]`, and the
   correction log re-verified it as "genuinely absent" `[map §0 correction log]`. So the *real* gap is
   two-layered: (i) no bug-fix-test constraint, and (ii) **no executable-constraint store to put it
   in** — the recursive-improvement/executable-constraint mechanism the article assumes is installed is
   absent. Any V2 proposal here must pick a real home (a `/cr` pass addition or a new hook), not the
   phantom file.

3. **No deterministic backstop for the "irreversible tier" classification** (pass2 §3). The article's
   risk-tiered rule needs a path/glob classifier so "irreversible" isn't left to a tired human's
   judgment. We enforce `/cr-security` on "auth, middleware, or RLS" via *prose in CLAUDE.md*, but
   there is **no hook that detects a diff touching those paths and forces the security pass.** The map
   shows the relevant structural guards are absent: `enforce-scope.sh` ❌ and `branch-registry-guard.sh`
   ❌ on disk `[map §3e, §5]`. A "high-blast-radius path → mandatory `/cr-security`" gate would live in
   exactly that absent structural-guard slot. Citable absence: `[map §5]` (canon-only structural
   guards, not built).

4. **The article's three-G frame exposes that our "Doctrine" layer has no freshness/ownership rule**
   (pass2 §2). The map already names this as the Phase 3 crux: the advisory/doctrine layer (skill
   bodies, CLAUDE.md rules) is the part with no deterministic owner, and the memory model has
   "read-time specified for only ~5 of ~14 knowledge files; freshness rules exist for only 3 stores"
   `[map §4]`. The article's Guides/Gates/Guards frame, by having no slot for judgment-shaping
   doctrine, *confirms from the outside* that this is our least-governed layer. Gap citation: `[map §4]`.

## (c) Weaknesses in the article's OWN reasoning

Building on pass2 §4, §5, §6:

- **It targets a phantom file** (pass2 §5; restated in (b)2 with citation `[map §6]`). The flagship
  actionable recommendation is unexecutable as written. This also reveals the article was written
  against canon vocabulary, not disk reality — the precise drift the map exists to catch.
- **It violates its own standing rule** (pass2 §4). It demands failure-mode justification for cuts and
  for new capabilities, then justifies its one addition by cross-corroboration and cheapness rather
  than by naming the gate it strengthens. Good rule, inconsistent application.
- **"Risk-tiered review" assumes legible reversibility** (pass2 §3). It names the easy high-risk
  classes and leaves the dangerous-but-quiet ones (a one-line `src/data` change that widens a query;
  copy on `/p/[token]`) unaddressed, and supplies no classifier — so the rule can decay into "scrutinize
  whatever felt scary," the burnout mode it set out to prevent.
- **The Claude→Codex >90% cost anecdote is correlation-as-cause** (pass2 §6) — the exact weak-proxy
  reasoning the article condemns in LOC/commit metrics. A cost cut from a model swap almost always
  means the *workload* changed, not 10x cheaper per unit of equivalent work.
- **It is blind to the unattended-agent posture** (pass2 §7). Its attention-economizing frame assumes
  a human reviewer; our harness is built toward unattended/background runs (Tier-0 firewall, UNATTENDED
  worktree mode `[map §3e]`), where gates become *more* load-bearing, not less. The article's small-team
  filter can't see this axis at all.
- **Embedded-curator over-confidence.** It asserts harness internals ("Pillar 3," "Node 14 canon
  inversion," "Ashby item 1," "recursive-improvement synthesis") as settled — several of which this
  pass cannot confirm from the ground-truth map (the map documents 5 pillars and Node dispositions in
  memory, but "Ashby item 1" and the specific "Pillar 3 = verify the system" labeling are not in the
  map and should be treated as unverified curator claims, not facts to inherit).

## (d) Does it warrant fresh external research? (be disciplined — prefer synthesize)

**No — synthesize, don't re-research.** Justification:

- The article's substantive content is already corroborated *and* already reflected in our locked
  decisions (Page 13 `[canon §9]`, the five pillars, risk-tiered `/cr-security` policy). Its one novel
  contribution — the **team-of-1-to-3 filter** — is a *lens*, not a fact needing verification; it
  converges with our model-capability cut lens (pass2 §1) and can be folded in by synthesis alone.
- The two genuinely actionable items (bug-fix-test constraint; high-blast-radius → mandatory security
  pass) are **internal design decisions**, citable to `[map §3e]`, `[map §5]`, `[map §6]` — they need
  a home and a gate, not external evidence. The sources (Nakazawa, Rossi) are already "verified" per
  the article and add no further mechanism.
- The only thing that would warrant a *small* fresh probe is **not in this article's domain**: whether
  risk-tiered review even applies under unattended/background agent runs (pass2 §7). That is a V2
  architecture question for the Phase-3/4 synthesis, better answered against our own
  `agent_harness_vision` / unattended-mode research tree than by re-reading small-team blog posts. Log
  it as an open thread, do not spawn a research fan-out for it now.

**Net for V2:** harvest one executable constraint (bug-fix reproducing test, given a *real* home — a
`/cr` pass or hook, not the phantom `learned-patterns.md`), one structural-guard candidate
(blast-radius-path → forced `/cr-security`, filling the absent-guard slot `[map §5]`), and the
Guides/Gates/Guards vocabulary as a *framing aid* — explicitly extended with the fourth "Doctrine" G
the article omits. Everything else is confirmation of decisions already on the books.
