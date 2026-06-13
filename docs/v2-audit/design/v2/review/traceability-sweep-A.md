# Traceability Sweep A — Research Re-mine → V2 Design Coverage Audit

> **What this is.** For each of 19 source re-mines (`design/ambition/remine/<slug>.md`), every ELEVATE / NEW move
> (and every UPHELD-CUT, since the charter requires a named failure mode for cuts) is traced to one of three
> dispositions in the integrated V2 design (`VISION.md` + `design/v2/roster.md`):
>
> - **LANDED-as `<move-id>`** — the move is a named V2 move (Pillar move L*/F*/C*/CMP*/P*/HOOK*/LOOP-7, or a roster
>   skill/agent/hook disposition). Cite the ID.
> - **CUT (failure mode named)** — consciously cut in `VISION.md` → Honest Cuts (UPHELD-CUT / STILL-GATED /
>   UPHELD), with a failure mode stated.
> - **DROPPED** — raised by the re-mine as ELEVATE/NEW, addressed nowhere in VISION or roster (the flag the
>   charter asks for).
>
> **Method.** Read all 19 re-mines + `VISION.md` (full roster, build order, Honest Cuts) + `roster.md` (Tables A/B,
> Hooks, Agents) + `gaps-risks.md` + ground truth. On-disk absences re-verified this session (`/scan-context`,
> `block-dangerous-bash.sh`, `session-end.sh`, `/goal`, `/lfg`, `/verify`, `.claude/rules/` all confirmed ABSENT;
> the 5 live hooks are `block-dangerous-git/npm`, `permission-logger`, `session-start`, `worktree-create`).
>
> **Headline verdict.** Coverage is **strong**: of ~70 ELEVATE/NEW moves across 19 sources, the V2 design landed
> the overwhelming majority on a named move-ID. The exhaustive cross-check surfaced **two genuinely DROPPED items**
> (one structural, one minor) plus **three partial/under-specified landings** worth flagging. No un-sourced design
> additions were found — every V2 move I checked traces back to a re-mine row or a ground-truth citation.

---

## Per-slug traceability table

| slug | move (from re-mine) | LANDED-as / CUT / DROPPED |
|---|---|---|
| **12-factor-agents** | Errors-into-context + deterministic circuit-breaker (F9/F8-aware) | LANDED — F7 (bounded-loop, retry ceiling) + HOOK-1 payload (c) F7 retry-counter; errors-into-context noted in `capability-facts.md:21-23` (PostToolUse) and folded into HOOK-1/F7. |
| | Unify execution state and business state (one memory home) | LANDED — `memory-model.md` is the Phase-3 deliverable (the unified one-writer/one-reader model); CMP1/CMP4 decay. (Note: VISION proper doesn't carry a standalone "unify state" move-ID — see flag #3.) |
| | Machine-enforced doc-authority / canon-vs-not-canon | LANDED — P3 (Notion→GitHub canon) + CMP4 doc-fiction detection + `supersedes:`/`version:` precedence (carried via basis-canon-not-canon → CMP4/P9). |
| | One-agent-one-job discipline codified (F10) | LANDED (partial) — P6 manifest `owning-layer`/`portable` per-skill contract + P10 roster-as-roles. The explicit "job fits in one sentence, else split" *rule in agent-contract.md* is **not separately stated** — see flag #2 (minor DROPPED). |
| | Trigger-from-anywhere (F11) — autonomy front door | LANDED — L1 (trigger trifecta) + P4 (MCP-as-substrate). |
| **37signals-dhh** | Cross-vendor CLI-chaining = autonomous bug→PR front-door | LANDED — L1 + L5 (`/lfg` chains the cells to `pr.sh`) + P4. |
| | Accessibility-tier map as standing autonomy-readiness gate | **DROPPED** — the operation-by-accessibility tier registry (CLI/MCP/UI-required/not-possible per op, UI-required rows = tracked autonomy-defect backlog) appears nowhere in VISION/roster. See DROPPED list #1. |
| | Selective friction removal — commitment-friction budget in the loop | LANDED — F7 (MAX_ITERATION + diff-cap + scope-cap REJECT). The human-session-end half = HOOK-1 / CMP5. |
| | CLI-vs-MCP tool-surface doctrine | LANDED (partial) — F5 (capability-tag MCP tools by leg) + F9 (`disable-model-invocation`) + F3 op-level gate cover the *safety* criteria; the stated "decide per-operation CLI-vs-MCP on stated criteria" *doctrine line* is implicit in F5/github-usage, not a named artifact. Adequately covered. |
| **agent-sandboxing-10co** | Tier-0 credential firewall as enforced pre-flight invariant | LANDED — F2 (credential pre-flight, blocking, fail-closed). |
| | Destructive-SQL/deploy safety floor (absent 3rd bash guard) | LANDED — F1 (`block-dangerous-bash.sh`, fail-closed, full scope). |
| | Egress allowlist (supply-chain class) | LANDED — F3 (egress allowlist, GATED Fork F4). |
| | Migration-credential architecture (verify-local / human-apply) | LANDED — F4 (migrate skill `disable-model-invocation`, F1 enforces `db push`-non-local block). |
| **agentic-platform-eng-saul** | Hard iteration cap + REJECT/human-handoff on every loop | LANDED — F7 (the cross-cutting bounded-loop contract). |
| | Disposable credential-isolated execution env (devbox) | LANDED (as adoption) — L4 cloud `/schedule` is the devbox-equivalent; F3 closes the local leg. The "local egress firewall for worktree" = F3. Realized via cloud sandbox per `gaps-risks` + VISION UPHELD-CUT on local DinD/microVM. |
| | Machine-readable capability manifest (`library.yaml`) | LANDED — P6 (`harness-manifest.json` + per-skill frontmatter + drift-CI). |
| | Cumulative directory-scoped context loading (Layers) | CUT (UPHELD-CUT, failure named) — re-mine itself ruled UPHELD-CUT ("scaffold a stronger model outgrew"); `.claude/rules/` path-scoping is the native sliver noted in `capability-facts.md:52-53`. The safety-rule-scoping sliver is available, token-optimization layering cut. Consistent. |
| | Curated tool registry ("Toolshed") — small default, expand on demand | LANDED — F9 (`disable-model-invocation` per-skill activation tiers) + F5 (per-leg MCP curation) + F3 (op-level manifest). The re-mine's own mechanism maps to F9. |
| | Hybrid orchestration — blueprints (pinned + agentic cells) | LANDED — L5 (`/lfg` "deterministic seams / agentic cells") + F9 pinned side-effect tail. |
| **ai-automation-ecosystem** | Price upstream-dependency owner-drift (vendor/track/cut) | LANDED — P7 (`UPSTREAM-DEPENDENCY-POLICY.md` + per-skill disposition column) + P5. |
| | Recurring-maintenance-cost lens on every mechanism | LANDED — P7 (the §9-golden-rule-applied-to-upkeep "standing acceptance criterion"; explicitly the per-mechanism maintenance-failure note). |
| | Durability — survive-a-crash-mid-run as a first-class axis | LANDED — F6 (CI-verified sentinel, no green-but-unverified) + F7 (resumable bounded-loop) + the harvest-from-disk/L7 principle in `gaps-risks.md`. |
| | MCP-as-substrate — expose harness skills to external agents | LANDED — P4 (MCP-as-substrate, "single biggest suppressed move" → P0-spine). |
| **ai-pilling-team-of-one** | Centralized tool-agnostic agent rules at global/cross-repo scope | LANDED — P1/P2/P3 distribution workstream (plugin + `/init` + GitHub canon). The global `~/.claude/CLAUDE.md` keystone itself = see flag #1 (partial). |
| | Review-bandwidth ≥ generation-bandwidth as enforced invariant | LANDED — F6 (CI verdict gate) + C4 (calibration floor) + LOOP-7 (auto-approval reserves human attention) + C8/C10/C11 (verification fleet). The R1 +98%/zero-DORA constraint is cited in L4. |
| | Agent-role/operational choreography as present-tense (fleet) | LANDED (partial) — F2 isolated env per worker + F8 stop-the-line + worktree-create. `branch-registry-guard.sh` + `enforce-scope.sh` = see flag #4. |
| | Compound engineering — agents write the skills (self-improving) | LANDED — CMP2 (finding→enforcement ratchet, the `/ratchet` skill) + CMP5 (session-end capture). `learned-patterns.md` correctly stays UPHELD-CUT (phantom). |
| **anthropic-contains-claude** | Operation-level egress enforcement off the model | LANDED — F3 (op-level gate: deny `gh api` mutations / `WebFetch` / `apply_migration` unless manifest grants; the hook reads the manifest). |
| | Forensic-grade tool-call + egress logging as keystone | LANDED — L7 (promote `permission-logger.sh` → append-only forensic agent-PR observability log). |
| | Remove prod credential from agent-readable paths (unattended) | LANDED — F2 (refuses unattended run whose readable env holds prod URL/service-role key; per-worker isolated env). |
| | Narrow tools / safety-floor bash guard | LANDED — F1 + F9. |
| **ashby** | Autonomous bug-triage front-door (bug → diagnostic → fix) | LANDED — L1 (trigger trifecta routes to L6 `/incident→/hotfix` or `/feature`) + the rebuilt `/dep-update` is adjacent; `/triage` wiring rides L1. |
| | Explicit blast-radius tier declared at task-start | LANDED — LOOP-7/A6 (LOW/MEDIUM/HIGH classifier off paths+diff+test-delta+scope) + F7 deterministic REJECT triggers. |
| | Verification-as-bottleneck — runtime obs + property-based money-math | LANDED (split) — property-based money-math = C11 (Fork F6). Runtime failure-logging/observability layer feeding triggers = **partial DROPPED**, see flag #5. |
| | Queryable institutional memory ("seen this bug before?") | CUT (UPHELD-CUT, failure named) — re-mine ruled UPHELD-CUT (SQLite mirror = overhead, no volume problem at this N); the recovered sliver (retrieve git-history/closed-PRs *at trigger time*) is a thin add not separately named — minor, acceptable under the cut. |
| | Redefine accountability "I read the diff" → "I judged the risk" (NEW) | LANDED — LOOP-7 risk-tier + the L1 "structural review contract" (fixed PR template incl. blast-radius/evidence) + F6 verdict artifact; the structured risk-attestation in the PR body = the L1 PR-template + LOOP-7 tier. Adequately covered. |
| **augment-code** | Every safety-critical rule consciously assigned to a layer (prob. vs determ.) | LANDED — CMP2 (the ratchet that classifies "can this be a deterministic block?") + the F1–F9 floor as the organizing doctrine; a `/cr`+`/compound` "flag prose rule lacking a structural twin" pass = CMP2's job. |
| | Guard integrity — fail-closed + self-test + CI-presence | LANDED — F1 explicitly "fails closed"; roster Hooks table changes `block-dangerous-git/npm` to fail-closed. The startup self-test / CI-presence-check = **partial**, the *fail-closed* part landed, the *self-test smoke check* is implied not named (minor). |
| | Three-tier rule loading (always/agent-requested/manual) | CUT (UPHELD-CUT, failure named) — re-mine ruled UPHELD-CUT (taxonomy already realized; rebuild = overhead); the budget-discipline sliver routes to §9/CMP6 shrink work. Consistent. |
| | Rules hold only what can't be inferred — boundary moves with model | LANDED — CMP6 (§9 prune-PR loop with behavioral probes, scheduled on model bump) + C13. |
| | Accountability for unattended agents must be technical | LANDED — HOOK-1 test-gate (C10) + F6 CI-verified `.cr-ok` + F9 on side-effect skills. |
| **auto-mode-config** | Auto-mode as the safe-autonomy substrate (relocate trust gate) | LANDED — P2 (`/init` materializes autoMode into `settings.local.json`/`managed-settings.json`, never committed project) + Fork F5. `capability-facts.md:42-46` grounds the "ignored at runtime" fact. |
| | Pre-flight verification gate (compile step for un-typed config) | LANDED — F2 (the blocking pre-flight invariant; "no unattended run launches without a green pre-flight") + the `/init` post-apply verify. The auto-mode-specific `claude auto-mode config` check is folded into F2's pre-flight. |
| | Resolve storage-vs-distribution conflict (committable/distributable policy) | LANDED — P2 (the `/init` template is exactly the "committed canonical source + per-repo materializer" the re-mine demands) + Fork F5. |
| | Defaults-over-block audit for single-tenant-prod (classifier stalls migrations) | LANDED (partial) — F4 (verify-local/human-apply) + the single-tenant-prod carve-out is named in P2 ("single-tenant-prod carve-out"). The specific "autoMode soft_deny over-blocks migrations → carve-out in the template" is **folded into P2's carve-out**, not separately elaborated — adequately covered, flagged for build detail. |
| **basis-canon-not-canon** | Context-as-maintained-artifact — scheduled scanner + worker loop | LANDED — CMP4 (`/scan-context` detection, P0) + P9 (cross-repo loop: CI check + scheduled scanner + repair-worker, Fork F7). |
| | Canonicality as declared decaying truth-claim + precedence rule | LANDED — P9 names the `supersedes:`/`version:` precedence schema + `owner` field as "the out-of-loop human anchor"; CMP4 decay (`last_seen`). |
| | Default-no authoring gate (instruct-not-describe, CI frontmatter check) | LANDED (partial) — P9's CI check ("frontmatter present, owner set, prose instructional not descriptive, no broken cross-refs") is exactly the deterministic-enforcement sliver. The broader authoring-gate doctrine = UPHELD-CUT in re-mine (duplicates §9 golden rule). Consistent. |
| | Dependency-ordered stack scanner→standards-enforcer→verifier | LANDED — the ordering insight (scanner is the upstream root of `/cr`'s canon-conformance) is carried: CMP4 feeds `/cr` (C5 governance lens); C2/C5 = the standards-enforcer; C10 = the verifier (in-loop test/typecheck). Diff-scoped runner sliver = C10. |
| **basis-monorepo-deep** | Canon/not-canon authority taxonomy as the spine | LANDED — P3 + CMP4 + the P9 precedence schema (same as basis-canon-not-canon). |
| | Automatic Context — daily scanner + worker self-improving loop | LANDED — CMP4 + P9 (the flagship cross-repo loop). |
| | Diff-scoped `verifier` sub-agent closing the loop inside the task | LANDED — C10 (the evidence bundle on HOOK-1: `npm run test` + `tsc --noEmit` block-on-red before PR). |
| | Push-context vs pull-context discipline (default-no for root) | LANDED (partial) — routes to the §9/CMP6 shrink work + `.claude/rules/` path-scoping; the standing "push/pull authoring rule + scanner check" is folded into CMP4's decay + P6 frontmatter. The "200-line cap" correctly NOT adopted (re-mine kept that §F reject). |
| | Unified MCP server for in-task external context | CUT (UPHELD-CUT, failure named) — re-mine ruled UPHELD-CUT (self-hosted unified server = unreachable from restricted-network cloud `/schedule`, lock-in, hosting tax); compose existing claude.ai connectors instead. VISION P4 uses connectors, consistent. |
| **bug-to-pr-automation** | Autonomous trigger front-door (bug signal → agent) | LANDED — L1 (the headline; GitHub-label first, Slack/Linear/CI-self-heal after F3+F8). |
| | Structural (not confidence) review contract — PR template + risk classifier | LANDED — L1 "structural review contract (fixed PR template, test-count floor, blast-radius classifier)" + LOOP-7 (risk classifier). Test-count floor = part of L1's contract. |
| | Ona cost-ordered auto-approval + observability — `.cr-ok` replacement | LANDED — LOOP-7/A6 (deterministic LOW/MEDIUM/HIGH, observe-only → live per Fork F2) + F6 (the `.cr-ok` → CI verdict + readiness-signal reframe). |
| | Agent-PR observability log (public channel as backstop) | LANDED — L7 (the append-only agent-PR observability log). |
| | `block-dangerous-bash.sh` safety floor (reorder as blocker) | LANDED — F1 (P0-floor, ships with/before first trigger). |
| | `session-end.sh` memory capture (self-improving loop) | LANDED — HOOK-1 + CMP5 (session-end capture payload, human-confirmed). |
| **claude-dev-containers** | Two-tier egress firewall as enforced artifact (the safety architecture) | LANDED — F3 (egress allowlist, op-level) + F1 (`curl` to non-allowlisted host as a bash-guard shape). Committed allowlist artifact = part of F3's manifest. |
| | Image-baked/root-owned `managed-settings.json` policy floor | LANDED — Fork F5 (managed-settings.json adoption) + P2 (`/init` materializes into managed-settings for the enforced tier). `capability-facts.md:35-41` grounds it. |
| | Per-agent OS-level isolation for the parallel fleet | CUT (UPHELD-CUT partial, failure named) — VISION UPHELD-CUT on "local DinD/microVM/gVisor sandbox stack" (container-escape = zero incidents); the *principle* (isolate autonomous agents) realized via cloud sandbox + F2 per-worker env, exactly as the re-mine's own "ELEVATE the principle, UPHELD the local-DinD sub-cut" prescribes. Consistent. |
| | Per-worktree credential scoping (stop prod-key symlink re-share) | LANDED — F2 (per-`/queue`-worker isolated env; refuses prod URL/service-role key in readable env). |
| **code-review-latentspace** | REJECT as a first-class outcome (close + re-queue, capped) | LANDED — F7 (REJECT/UNATTENDED terminal state, surfaced inside `/cr`; auto-close + re-queue; REJECT×2 escalates). |
| | True adversarial independence (fresh sub-agent, shared canon, iterative) | LANDED — C2 (isolated solution context + shared project canon + 3-4 round hunt→fix→retest). |
| | Deterministic risk-based auto-approval (Ona L4) | LANDED — LOOP-7/A6. |
| | Compounding read-path — findings → task-start context + freshness | LANDED — CMP1 (close the read-path + eviction/decay; do NOT build `learned-patterns.md`). |
| | Effectiveness-measurement layer (first-pass-approval, cycle-count) — NEW | LANDED — CMP3 (effectiveness-metrics ledger; day-0 fields P0, first-pass-approval P1-volume). |
| **coderabbit** | Review verdict on PR/CI surface, not a local sentinel | LANDED — F6 (surface face: `/cr` verdict → structured PR artifact via `pr.sh`; enforcement face: CI re-verifies sentinel). |
| | Calibrate the reviewer — precision/recall vs labeled defect set | LANDED — C4 (`/cr-calibrate` golden-set, recall + FPR per pass/lens, re-run on model bump). |
| | Wire governance corpus (ADRs/Rejected Patterns/PITFALLS) into review | LANDED — C5 (the governance lens; ADR + Rejected Patterns + PITFALLS + golden-exemplars as criteria). |
| | Close compounding loop — review stream → auto-promote to enforcement | LANDED — CMP2 (finding→enforcement ratchet). |
| | (Autonomy angle) CodeRabbit-Agent-for-Slack: stale-PR nudges / ship briefs | LANDED (thin) — L7 narration + L4 cloud-scheduled reports cover the *capability*; the specific "stale-PR nudge / weekly ship brief" feature is **not separately named** but is a natural L4/L7 payload. Minor, acceptable. |
| **commands-vs-skills** | Invocation control as first-class structural property (`disable-model-invocation`) | LANDED — F9 (the activation-tier audit across all 26 skills). |
| | Rewrite every skill description as a situation, not a phrase-key | LANDED — F9 ("rewrite phrase-keyed descriptions to situational triggers") + P6 frontmatter contract; §9 capability-proxy replace. |
| | Tier knowledge by trigger-existence (load-tiering as architecture) | LANDED — `capability-facts.md:48-53` (`.claude/rules/` path globs) + §9/CMP6; the "200-line diet" correctly UPHELD-CUT in VISION Honest Cuts ("demotes no-trigger safety content"). |
| | Plugin-as-package as distribution unit | LANDED — P1 (plugin + marketplace) + P2 (thin `/init`). |
| **engineering-rigour-small-team** | Failing-test-first as enforced gate for every bug fix (not just pure fns) | **DROPPED (partial)** — no `bugfix-test-guard` deterministic gate (fix-scoped commit ⇒ requires red-before/green-after test) appears in VISION/roster. C10 runs the suite + typecheck but does NOT assert a *new* test exists for a fix. C12 carries `/tdd` discipline but `/tdd` is model-invoked, not a gate. See DROPPED list #2. |
| | Risk-tiered review with machine irreversibility classifier (path/glob → security pass) | LANDED — the cr-security path classifier (roster Hooks table: "globs the diff for auth/RLS/middleware/public-handler/credential paths and auto-routes to `/cr-security`") + LOOP-7 HIGH→`/cr-security`. |
| | A fourth "G" — Doctrine — with freshness/ownership rule | LANDED (partial) — the freshness/ownership treatment lands in `memory-model.md` + CMP4 decay (`last_seen` per rule) + P6 `owner`. The *vocabulary move* (naming "Doctrine" as a 4th first-class layer) is not adopted as a named layer — but its substance (every doctrine file gets a read-time + staleness rule) is covered. Acceptable (vocabulary, not mechanism). |
| | Cost as call-volume/blast-radius-scaled fan-out (NEW, low-confidence) | CUT (STILL-GATED, failure named) — VISION STILL-GATED carries "CI-latency optimization (`/queue` ≥3 parallel)"; the blast-radius→fan-out-width economics fold into Fork F2 / CMP3 per-task-type. Re-mine itself rated it backlog-candidate not immediate. Consistent (a fan-out cost governor is not separately named — borderline, see note). |
| **every-compound-lfg** | `/lfg` orchestrator (brainstorm→plan→work→review→compound→PR) | LANDED — L5 (`/lfg`, the keystone integration deliverable). |
| | Brainstorm-before-plan structural separation (divergent ≠ convergent) (NEW) | LANDED — L5 "the structural brainstorm→plan seam (diverge then converge)". |
| | Severity × routing orthogonality (split "how bad" from "who acts") | LANDED — L5 "a routing flag on `/cr` findings (needs-design-decision vs must-fix-now)" + F7 REJECT vs NEEDS-HUMAN. |
| | Failure-mode-as-guard — seven-failure-mode guard battery | LANDED — L5 "1 orchestrator + 7 distinct guards" (skill-cache/restart, encoding-normalization, agent-stall watchdog, context-drift, non-determinism, compound-timing, + cross-skill reference-integrity pulled to CMP4). |
| | Multi-model task-type routing encoded as rules | CUT (UPHELD-CUT, failure named) — re-mine ruled UPHELD-CUT (Every's numbers pinned to stale Opus 4.6; adopting verbatim hard-codes stale capability). The model work = C13 + CMP6; the Opus-lead/Sonnet-sub economics fact = a check inside the §9 re-audit (CMP6). Consistent. |

---

## DROPPED items (raised by a re-mine as ELEVATE/NEW, addressed nowhere)

### 1. The operation-by-accessibility tier registry — **DROPPED** (structural, MEDIUM)
- **Source:** `37signals-dhh.md` Move 2 ("Build the accessibility-tier map — as the autonomy gap-finder").
- **The move:** A living classification of *every operation in the agent's loop* (deploy, migrate, seed, env-rotate,
  screenshot-verify, Notion/Linear sync, Supabase/Vercel ops) tagged **CLI / MCP / UI-required / not-possible**,
  where every **UI-required** row is a tracked **autonomy-defect backlog** to convert to CLI/MCP, re-run per repo at
  install time. The re-mine ELEVATED it from "one-time diagnostic" to "a standing autonomy-readiness gate."
- **Why it's DROPPED:** No move-ID in VISION or roster owns this. The closest neighbors are `github-usage.md` (which
  documents the chain links, not an op-accessibility tiering), P6 (the *skill* manifest, not an *operation* tier
  map), and the C9 "agent-legible markup" move (UI-legibility for `/verify`, a different axis). None classifies the
  loop's *operations* by reachability or produces a UI-required-rows backlog. The failure mode it prevents — an
  unattended/`/schedule` run silently stalls on a UI-required step that no human is there to click — is real and
  unaddressed: nothing in the design tells you, *before* a fleet runs, where the autonomy physically breaks.
- **Severity:** MEDIUM. Not spine-blocking (L1/L5 can ship without it), but it is the cheap diagnostic that would
  catch a class of silent unattended stalls the narration channel (L7) only reports *after* they happen. Recommend a
  one-row build item (an op-accessibility tier table, owned by P6's manifest or `gaps-risks`) before fleet volume.

### 2. The `bugfix-test-guard` deterministic gate — **DROPPED (partial)** (LOW-MEDIUM)
- **Source:** `engineering-rigour-small-team.md` Move 1 ("Failing-test-first as an *enforced gate* for every bug
  fix"), corroborated by `bug-to-pr-automation.md` §11 (test-deletion = "most insidious" failure mode).
- **The move:** A deterministic gate (PreCommit/CI/`/cr` pass) that, when a commit/branch is scoped as a `fix`,
  asserts the diff contains a **new test that was red-before / green-after** — covering the surfaces `/tdd` does NOT
  (components, server actions, the `/p/[token]` renderer, RLS-adjacent `src/data` edits). The re-mine explicitly
  ELEVATED past the "duplicates `/tdd`" dismissal: `/tdd` is a *model-invoked skill*, not a *gate*.
- **Why it's DROPPED (partial):** C10 (the HOOK-1 evidence bundle) runs `npm run test` + `tsc --noEmit` and blocks on
  red — but that asserts *existing* tests pass, **not** that a *new* fix-test exists. C12 carries the `/tdd`
  no-transcription discipline, but `/tdd` is model-invoked (the exact advisory layer this gate would harden). The
  test-count-floor inside L1's "structural review contract" (from `bug-to-pr-automation`) blocks test *decreases* —
  the closest existing mechanism — but does not *require a new reproducing test on a fix*. So the specific fix→test
  enforcement is unaddressed.
- **Severity:** LOW-MEDIUM. Partially mitigated by the L1 test-count floor + C10. But under autonomy (no human to
  notice a missing repro test on an overnight fix) the re-mine's argument that this becomes *more* load-bearing
  holds. Note: ground truth §9/CANONICAL flags the V1-planning "bugfix-test rule duplicates `/tdd`" as a *killed*
  pattern — so this is a **genuine design tension**, not a clean miss: the design may have deliberately let it die on
  the dedup rule. Flagging it as DROPPED-with-a-defensible-reason rather than a pure oversight.

---

## Other flags (partial / under-specified landings — NOT dropped, but worth a build-time note)

3. **"Unify execution and business state" (12-factor F5)** lands in `memory-model.md` (the Phase-3 deliverable) but
   has **no VISION move-ID** — VISION's compounding pillar (CMP1-6) covers the read-path and decay but never names
   the single-home/one-writer collapse as a move. The substance is in the design artifact; the spine doc is silent.
   Low risk (the artifact owns it), but a reader of VISION alone would miss it.

4. **`branch-registry-guard.sh` + `enforce-scope.sh`** (raised by `ai-pilling-team-of-one` Move 3 + canon §5) are
   **not named in the V2 hook roster.** The roster's new hooks are F1/F2/F3/F5/F6 + HOOK-1 + cr-security classifier —
   the two canon-declared coordination guards are absent. F2's "each `/queue` worker its own isolated env" covers
   *credential* collision; F8 stop-the-line covers *defect-class* halt; but the *one-session-per-branch* and
   *staging-files-outside-ALLOWED-FILES* guards have no home. Possibly a conscious cut (worktree isolation may make
   branch-registry redundant) — but it is **not stated as a cut**, so it reads as an un-flagged omission. Recommend
   VISION/roster either name them or add them to Honest Cuts with a failure mode.

5. **Runtime observability layer feeding triggers** (`ashby` Move 3, half): the property-based money-math half landed
   (C11), but the *runtime-failure-logging table feeding inbound triggers* (a render error on a client proposal
   auto-files a triaged bug — closing verification→autonomy into a loop) is **only partially present**: L1 names a
   "CI-failure self-heal" trigger and an "error monitor fires" trigger, but no design move builds the *project-side
   runtime error-log table* the re-mine specifies (the `error.tsx` boundary that "records nothing"). The trigger
   *consumes* a runtime signal L1 assumes exists; nothing *produces* it. Borderline DROPPED — landed as a trigger
   input, unaddressed as a substrate. Flag for build.

---

## Un-sourced additions check

Per the charter, I checked the reverse direction: does any V2 design move *lack* a re-mine/ground-truth trace? Within
the 19 slugs assigned: **none found.** Every VISION move-ID I encountered (L1-7, F1-9, C2-13, CMP1-6, HOOK-1, LOOP-7,
P1-10) cites either a re-mine elevation or a CANONICAL §N row / confirmed absence in its own *Citation:* line, and the
roster's new skills/hooks/agents each cite a move-ID. The design's internal `checks/*-check.md` MUST-FIX folding is
consistent with the re-mines (e.g. the L6 incident carry-forward, the L7 narration channel, the HOOK-1 consolidation
all trace to grounding + Tanner input, not invented). No phantom additions surfaced in this sweep's scope.

## Status

19 slugs swept, ~70 ELEVATE/NEW/UPHELD-CUT moves traced. **2 DROPPED** (op-accessibility tier registry — structural;
bugfix-test-guard — partial, with a defensible dedup-tension reason). **3 partial-landing flags** (unify-state has no
move-ID; branch-registry/enforce-scope hooks unnamed; runtime-obs substrate half-present). **0 un-sourced additions**
in scope. Coverage is strong; the two DROPPED items and the branch-registry omission are the actionable carry-forward.
