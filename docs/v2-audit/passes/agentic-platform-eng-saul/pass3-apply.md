# Pass 3 — Apply: "Agentic Platform Engineering" → our harness

Building on pass2: applied against `CANONICAL-HARNESS-AS-IS.md`. Citation rule honored — **no gap appears
without a `[ground-truth §X]` row or a confirmed `[absent]`.** Every "Better/Equal/Gap" claim from the
page (pass1 §7) is re-tested against the map, not inherited (pass2 §H).

---

## (a) What we ALREADY do — with ground-truth rows

- **Layers / per-directory context docs.** We have `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `SOUL.md`,
  `ARCHITECTURE.md`, `INDEX.md`, `AI-WORKFLOW.md` — all present on disk [ground-truth §3a]. The article's
  "Brain" *content* exists; what we lack is **cumulative directory-scoped loading** (pass2 §B), confirmed
  below as a real gap.
- **Skills as explicit reusable procedures.** ~26 disk skill dirs [ground-truth §3b], invoked explicitly
  (`/cr`, `/feature`, `/tdd`, `/queue`, …) — exactly the article's "skills, never auto-loaded" model
  (pass1 §3.1). The page's "Better — more opinionated, enforcement gates" claim (pass1 §7) is *supported*
  by the map (the pass-structure machinery in §3c). But pass2 §H/§G caution: "more elaborate" is graded
  against the **Model Capacity Audit** (§9), not celebrated.
- **Always-on rules.** `PITFALLS.md` + `RECURRING-FINDINGS.md` exist [ground-truth §4]; the page's "Rules ≈
  PITFALLS" mapping (pass1 §7) holds.
- **Human-in-the-loop / unattended gating.** `.cr-ok` sentinel chain, pre-push hook, UNATTENDED worktree
  mode, autoMode lists [ground-truth §3e, §0]. The page's "Better" on human-in-loop (pass1 §7) is fair.
- **Memory / compound learning.** Five canon stores + a 6th auto-memory store [ground-truth §4]. The page's
  "Equal" holds; the "resource-catalog inventory missing" sub-claim maps to a real absence (below).
- **CI feedback loops.** `ci.yml` + `integration.yml`, `/cr` 9-pass pipeline [ground-truth §3c, §3f].
- **Per-task isolation (partial).** `worktree-create.sh` + the **Tier-0 prod-key firewall** /
  `gen-local-env.sh` / `test-local.sh` [ground-truth §3e, §6] — a disk *advance* the canon lacks. This is
  *more* than the page credited ("worktrees per task — we do this"): we also have credential isolation,
  which is the part that actually matters for the devbox analogy (pass2 §H).

## (b) REAL gaps this article exposes — each citing the map

1. **No cumulative / directory-scoped context loading.** Our context docs are **flat at repo root**; there
   is no parent→child layer cumulation and no file-pattern scoping. Confirmed: the map's component table
   lists single root-level docs with no per-directory layer mechanism [ground-truth §3a], and the canon's
   own "curated context / scoping" is **not** among declared hooks or mechanisms [absent from §3e, §5]. The
   article's scoping insight (pass2 §B) is the transferable core and we don't implement it. *Severity:*
   token/clarity, not safety — and partly *already pre-authorized to shrink*, since "phrase-keyed skill
   descriptions → trigger should be the situation" is a Model-Capacity-Audit replace item [ground-truth §9].
2. **No hard retry cap with defined human-handoff on agentic loops.** The map's `/cr` description is "9
   passes + adversarial, Opus auto-fix" with **no iteration ceiling and no REJECT/handoff tier**
   [ground-truth §3c: "No REJECT tier, no UNATTENDED branching"]. The article's max-2-retries idea (pass1
   §4.4, elevated in pass2 §E) has no analogue. *This is the article's single most valuable, model-
   independent contribution and we have a confirmed absence.* Highest-value gap.
3. **No machine-readable skill manifest / registry.** The page's Gap 3 (`library.yaml`) maps to a *real*
   absence: the map shows skills inventoried only in prose (canon ~46 vs disk 26, reconciled by hand) with
   active drift — `/dev` and `/explain` exist on disk but in **no** canon page; `dep-update` documented but
   an empty stub; `/cr-feature` retired in canon yet still referenced [ground-truth §3b, §6]. A manifest
   would mechanically catch exactly this drift. Note: `skills-lock.json` is a **confirmed phantom**
   (referenced, never built) [ground-truth §6], so this is genuinely unbuilt, not merely undocumented.
4. **No cross-project / installable harness — the article's "three-repo brain" maps to our central V2
   fact.** The map's headline: the harness "has **never been installed anywhere but event-vendor**;
   'multi-project' is a goal, not a state," recyclops/logistics-service carry no harness, and there is **no
   global `~/.claude/CLAUDE.md`** [ground-truth §0, §2, §8; canon To-Think-About #20/#22]. The article's
   `agent-library` + `agent-setup` separation is one concrete answer to this exact gap. *But* pass2 §C
   warns: adopt the **versioned-copy-with-lock** variant, not the symlink-live variant the article prefers,
   or we recreate the canon's own unresolved install-method contradiction [ground-truth §7.8].
5. **No isolation boundary equivalent to a devbox — partially mitigated, not closed.** We have worktrees +
   the Tier-0 firewall [ground-truth §3e, §6], which is *credential* isolation but **not** environment
   isolation: agents still run on the same machine/filesystem. The map confirms no sandbox/devbox component
   exists [absent from §3e, §3f, §5]. The page over-credited us here (pass2 §H); the firewall narrows the
   gap to "no disposable compute environment," which remains a confirmed absence.

## (c) Weaknesses in the article's OWN reasoning (carry from pass2)

- **Borrowed-credibility fallacy (pass2 §A, §D):** the persuasive evidence (1,300 PRs/week) belongs to
  Minions' *infra* (devboxes, selective CI, Toolshed, retry caps), not to the three-repo markdown layout
  the article prescribes. Copying the brain without the body is the trap. For us this means **Gap 4 (three-
  repo) is lower-leverage than it looks; Gap 2 (retry caps) and the existing firewall are where Minions'
  value actually lives.**
- **Symlink/DR self-contradiction (pass2 §C):** "live everywhere via symlinks" and "reproducible git DR"
  are in tension; symlinks resolve to HEAD, not a validated SHA. The article picks the weaker side.
- **Scoping ≠ separation conflation (pass2 §B):** it credits the three-repo split for benefits that come
  from scoping, which is achievable in-repo. We can capture Gap 1's value without Gap 4's repo surgery.
- **Unmade orchestration decision (pass2 §F):** "skills never auto-load" (library) vs. "blueprints automate
  the sequence" (Minions) are opposite agency stances the article never reconciles.
- **Snapshot disclaimer (pass1 header, pass2 §H):** the page itself says its gap analysis must not drive
  implementation and points at a delta page — so its "CRITICAL" ratings are hypotheses, and three of the
  five (cumulative loading, manifest, three-repo) overlap with gaps our *own* map already names
  independently, which is the real validation, not the page's grade.
- **"Better = more elaborate" liability (pass2 §G/§H):** the article's whole frame is "more curated markdown
  = more capable," never asking whether Opus 4.8 needs *less* scaffold. Our map pre-authorizes cuts here
  [ground-truth §9]; the article points the opposite direction.

## (d) Does it warrant fresh external research? (be disciplined)

**Mostly no — synthesize, with one narrow exception.**

- **No** on the three-repo architecture, symlink-vs-copy, scoping, manifest: our ground-truth map already
  names all four as gaps (§0/§2/§8, §3a, §3b) and the install-method tension is already an open canon
  contradiction (§7.8). Adding external reading repeats what the map settles. Decide these from the map +
  pass2, not new sources.
- **No** on devbox isolation as a *concept* — the gap is confirmed (§3e absent) and the design space
  (worktrees → Codespaces/Daytona) is already in the page's own fix and our backlog. If/when we decide to
  *build* disposable-environment isolation, that is an implementation spike, not research.
- **Narrow YES — one item:** the **hard-retry-cap / diminishing-returns claim (pass2 §E, gap b2)** rests on
  an *empirical* assertion about LLM retry behavior that is (i) the highest-value gap and (ii) **not**
  covered anywhere in our map or canon. Before encoding a fixed "max-2" ceiling into `/cr` auto-fix, debug,
  and refactor loops, one short verification pass on current evidence for retry-value decay on Opus-class
  models is warranted — because the number is model-dependent and Stripe's "2" was tuned on their stack,
  not ours. This is the only place re-research beats synthesis.
