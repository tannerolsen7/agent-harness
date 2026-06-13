# Canon-locked design decisions (Phases 3–4 must build on these, not reinvent)

Extracted from the canon's own backlog pages. These are decisions the canon has *already made*. V2's
job is to reconcile them with current (drifted) reality and extend them — not re-decide them.

## A. Distribution — GitHub Publishing (canon page `35ae…7229`, updated 2026-05-18)

**LOCKED:**
- Repo name: **`agent-harness`** (functional, tool-agnostic). Display/npm brand name deferred.
- The work *in progress* IS the migration: **extract the harness from event-vendor into a standalone
  `agent-harness` repo, stripped of all Monica/Fern's content**, with a README explaining it as a system.
- v1 distribution = **GitHub Template Repository, Claude Code only, ONE install path**: click template →
  fill `[TODO]` placeholders → use skills. **Explicitly NOT in v1:** sync scripts, `harness-update.sh`,
  `.cursor/`, `.codex/`, npx. Those are deferred until the template path is proven.
- Locked sequence: **Migrate → Ship v1 template → Validate (3 real installs) → Add Cursor → Add `npx
  skills add` → Build UI.**
- **"Real install" validation gate (4 conditions, all true):** (1) installed via GitHub template, no
  author-copied files; (2) all `[TODO]`s filled without asking the author; (3) ≥1 skill (`/cr`/`/tdd`/`/dev`)
  ran and produced correct output; (4) the installer can explain `AGENTS.md` vs `CLAUDE.md` to someone
  else without looking it up. **3 such installs = the README works.**

**V2-relevant tensions (citable):**
- **Locked but UNEXECUTED.** Map §8: the harness has never been installed anywhere but event-vendor;
  recyclops/logistics-service has no harness. The migration is "happening now" per a 2026-05-18 page, but
  no `agent-harness` repo / install exists on disk. The plan is real; the execution is the gap.
- **The locked v1 tree is itself drifted:** it lists `cr-feature/` (RETIRED v0.85, map §3b), `todo.md`
  (migrated → `TASKS.md` v0.16), `session-end.sh` (ABSENT on disk, map §3e), `skills-lock.json` (on disk
  it's `~/.agents/.skill-lock.json`, not a project file). So even the distribution artifact must be
  convergence-gated (commands-vs-skills pass3 §b4: "you can't version-distribute a harness whose canon
  and disk disagree").
- **Self-update is DEFERRED by canon, but Tanner's V2 brief REQUIRES designing both update paths.** This
  is a genuine decision-brief fork: honor the canon's "template first, learn from 3 installs, defer sync
  tooling" sequencing (Winchester-Mystery-House risk of premature machinery), vs. design bidirectional
  update now. Recommendation will likely be: template-repo pull path now (it's the locked, low-risk
  win), push-back path designed conceptually + wired to the compounding loop, but not built as tooling
  until installs exist.

## B. Enforcement — Three-Layer Enforcement Model (canon page `35ae…d725`, Active)

Canon's own answer to the map's central finding ("enforcement is overwhelmingly advisory"). The frame:

- **Layer 1 — Deterministic hooks (binary, always enforced, agents AND humans).** Examples: no `any`,
  no `console.log` outside tests, no `it.only`/`describe.only`, tsc passes, tests pass, conventional
  commit format, no credential/service-role access outside scoped tasks, **no direct DB SDK calls
  outside the data layer (by import pattern)**, no `git push` without confirmation. Mechanism: Husky
  pre-commit (humans) + PreToolUse settings.json (agents), same rules. **Status: "ready to implement
  now — an afternoon of work."** Motivated by the two real event-vendor incidents (credential search;
  skipped `/cr-feature`) — "caught by the developer, not by the system."
- **Layer 2 — Architecture tests (dependency-cruiser in CI).** Encode layer-boundary rules as test
  files: e.g. `^src/components` may not import `^src/data`. **Runs on every CI run, every commit, every
  developer** — unlike a PreToolUse hook that only fires on an agent tool call. *This converts today's
  advisory `/cr` Pass 4 (layer boundaries) into a deterministic CI check.* Status: not-ready — needs the
  layer map + report-mode false-positive testing first.
- **Layer 3 — Probabilistic (judgment).** Prefer-boring, surface-assumptions, abstraction quality,
  golden-exemplar compliance, solution-doc updates. Stays. Goal: **move as many rules DOWN to L1/L2 as
  possible so L3 holds only what genuinely needs judgment.**

**The sorting task (concrete Phase 3 work):** for every CLAUDE.md/PITFALLS NEVER-rule, decide L1/L2/L3.
Canon gives a starter table (L1: no-any, no-console.log, tsc, no-it.only, no-credential-search,
conventional-commits; L2: no-component→data, no-business-logic-in-components, layer-map compliance,
missing-tests; L3: prefer-boring, abstraction quality, golden exemplar, spec-sync).

**V2 connections the canon itself draws:** L2 arch-test failure-rate over time = a compounding metric
("whether layer discipline is holding") → feeds Skill Effectiveness Analytics. This is the bridge between
enforcement (Phase 3) and the compounding loop (Phase 5).

**Convergence with research:** matches commands-vs-skills pass3 (trigger-gate ≠ kill-gate; route
irreversible ops to the absent `block-dangerous-bash.sh`), recursive-self-improvement pass3 (relocate the
stop authority to CI where it can't be forged), and anthropic-contains-claude (operation-level egress +
total tool-call logging + bounded blast radius as the no-infra floor). The independent lines converge on:
**move enforcement from advisory markdown to deterministic hooks (L1) + CI arch-tests (L2), and relocate
the forgeable gates to where the model can't compute them.**
