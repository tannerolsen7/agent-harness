# V2 Simplification Pass — the Ranger lens applied, mechanism by mechanism

> **What this is.** An honest "where are we over-engineering?" audit of the V2 design, run through the lens of
> the Ranger article *"Why You're Overthinking Background Agents"* (see `passes/ranger-background-agents/pass2-
> penetrate.md`, `pass3-apply.md`). The user's ask, verbatim: *"Where are we over-engineering? Where can we make
> this as simple as possible? If it doesn't apply that's fine, but it's worth a pass."*
>
> **The one idea the whole pass turns on.** Ranger's transferable insight is **isolation-by-construction**: give
> the agent a genuinely disposable environment (a throwaway DB branch, no prod credentials, no external IP) and
> *most of the safety rules become unnecessary, because there is nothing dangerous in the box to act on.* You
> remove the blast radius instead of guarding it. Their entire production system runs on ~100–500 lines of glue.
>
> **The honest both-ways verdict up front.** Ranger is RIGHT that the *infrastructure and the floor* can be much
> simpler than we drew them — and a real chunk of our floor (F2/F3/F5) is guarding a production blast radius we
> *chose* to leave in the box. Ranger is SILENT on the *trust-the-output* problem — the half our charter exists
> to solve — and ends every run with a human reviewing a screenshot. So the floor simplifies hard; the review/
> verification depth does **not**. This pass cuts the first and defends the second.

---

## How to read the verdicts

- **CUT** — remove it; the design is better without it.
- **SIMPLIFY** — keep the goal, shrink the mechanism dramatically.
- **DEMOTE** — was load-bearing P0; isolation-first turns it into belt-and-suspenders → push to a later phase or
  fold into F0 as a cheap residual.
- **DEFER** — real, but not needed until a named trigger fires.
- **KEEP** — genuinely load-bearing; Ranger is silent on it and the charter needs it. Defended, not reflexive.

---

## The prioritized table

| # | Mechanism | Verdict | What to do instead | Why (plain language) |
|---|---|---|---|---|
| 1 | **F0 — isolation-by-construction** (disposable per-job DB branch + no prod creds + no external IP + side-effect outbox) | **KEEP — and promote to *the* P0** | Build it first. Make it the thing the floor is measured against, not one move among nine. The Supabase-branching speed check is the only real risk. | This is the single highest-leverage move in the whole design and it is currently buried as "F0" among equals. Once the agent runs in a box that can't reach prod, three other floor moves stop being load-bearing. Build this and the floor shrinks on its own. |
| 2 | **F2 — credential firewall** (blocking pre-flight that refuses a run if prod keys are readable) | **DEMOTE → fold into F0** | Don't ship a separate refuse-if-prod-keys pre-flight hook as P0. F0 *provides* a safe DB instead of *refusing* an unsafe one. Keep a one-line assertion ("env URL is the disposable branch, not prod") as a residual inside F0, not a standalone floor pillar. | Ranger's better move (pass3 §c): the positive version of the credential firewall is "give the agent a throwaway DB," not "block the run when prod keys are present." If F0 is done right, the prod key is never in the box, so the thing F2 guards against can't happen. F2-as-separate-move is guarding a danger F0 removes. |
| 3 | **F3 — egress allowlist + operation-level gate** (OS network allowlist; deny `gh api` mutations / `WebFetch` / `apply_migration` unless a task manifest grants them) | **DEMOTE / DEFER (Fork F4)** | If cloud `/schedule` is the primary execution surface (it is already restricted-network), F3 is *secondary hardening*, not floor. Ship the cloud path first; build the local-unattended egress hook only if/when local-unattended becomes a first-class surface. | The design already flags F3 as GATED on Fork F4 — this pass just sharpens it: the operation-level manifest gate is the heaviest single sub-mechanism in the floor (a hook reading a manifest to decide whether each `gh api` call is allowed). That is real machinery built for a local-unattended surface that may never be primary. Don't build it on spec. |
| 4 | **F5 — MCP lethal-trifecta gate** (capability-tag every MCP tool by leg; refuse when all three co-reside; + a tool-description pin-and-diff lockfile) | **SIMPLIFY hard + scope to one path** | Drop the general "tag every tool, compute the leg-union, refuse on trifecta" engine. Replace with: *in the disposable box, leg-1 (prod private data) is gone, so the trifecta can't complete.* Keep one narrow check only on the **Slack/CI free-text trigger path** (the one leg that adds untrusted content). The pin-and-diff MCP lockfile is a separate, cheaper supply-chain control — keep that, cut the leg-union engine. | F5's whole premise is "because `.env.local` is prod Supabase, every agent permanently holds leg 1." F0 deletes that premise. With no prod data in the box, the lethal trifecta is structurally incomplete for the default path. The general capability-tagging engine is enterprise machinery defending a blast radius we removed. |
| 5 | **The 3-store memory model + the `last_seen`/decay "ridden cache"** (CLAUDE.md NEVER-section + memory.md + PITFALLS, each restating rules; plus per-rule `last_seen` decay, >90-day demotion, triple-duplication flags) | **SIMPLIFY** (the store consolidation) / **DEFER** (the decay engine) | Do the copies-per-fact 3→1 consolidation now (it's a genuine win — one home per rule, path-scoped shards). But **defer the decay machinery** (`last_seen` clocks, 90-day demotion, triple-dup detection) until there's enough rule churn to need it. A 558-line PITFALLS in a solo repo does not yet have a decay problem. | The store consolidation is simpler-than-before and earns its place. The decay engine is the over-built part: it's solving fleet-scale rule-rot before the fleet exists. Ship the consolidation; add the clock when rule count or repo count actually creates rot. (Hypothesis-before-speculative-build.) |
| 6 | **The ~43-move roster itself** (5 pillars, 43 top-level move IDs) | **KEEP the content, CUT the framing as a build plan** | The *count* is honest (verified: 43 distinct move IDs) and the moves are individually grounded. But 43 moves presented as one program reads as a smell even when it isn't. Re-present as: **the 5-move minimal floor + F0 + the spine (L1/L2/L4/L5/L7), and everything else explicitly Phase-2+.** Ship ~8 things; have 35 documented-but-not-built. | The count isn't the problem; treating it as a to-build list is. The design already tiers honestly (P0-floor / P0-spine / P1 / GATED), but the *surface area* invites over-building. The fix is presentation discipline, not cutting grounded moves: name the ~8-move V2-that-ships loudly, demote the rest to a backlog with triggers. |
| 7 | **C4 — reviewer calibration / golden-set harness** (`golden-set/` of adversarially-seeded labeled diffs + `/cr-calibrate` CI job emitting recall + FP-rate per pass/lens, re-run on every model/pass change) | **KEEP — but DEFER the per-pass/per-lens granularity** | Build a small golden-set (10–20 seeded defects) and one aggregate recall number now. **Defer** per-pass and per-lens recall breakdowns until you're actually tuning individual lenses. The blocking-promotion-on-stale-recall rule stays. | The *principle* (don't ship auto-merge on a gate with an unknown miss rate) is exactly the trust-half Ranger punts on — keep it. The *granularity* (recall + FP per pass AND per lens, re-run on every change) is more measurement apparatus than a pre-auto-merge harness needs on day one. One honest aggregate recall number gates the autonomy decision; the per-lens breakdown is a tuning luxury. |
| 8 | **Two-vehicle distribution** (plugin + marketplace + thin `/init` template) | **KEEP — but DEFER the whole pillar behind its real trigger** | The two-vehicle split is correct and forced by the 27-byte proof — don't redesign it. But it is **P3/Phase-3, gated on a 2nd repo existing.** The honest move is to stop spending design energy polishing it now and build it when install #2 is real. | The plugin is the right answer to template drift — *when there is a second repo to drift.* Today the harness has been installed exactly once (event-vendor). Building marketplace channels, version pinning, and push-back-up before a 2nd install is solving a distribution problem that doesn't exist yet. Keep the design; don't build ahead of the trigger. |
| 9 | **The harness-manifest.json** (per-skill frontmatter contract + a consumer reading `name`/`required-tools`/`owning-layer`/`portable`/`scope`/`disable-model-invocation`; "single owner of the task manifest" for F3/F5/L1) | **SIMPLIFY** | Ship the per-skill frontmatter (cheap, useful for F9 anyway). **Defer the full manifest consumer** until the plugin needs it (it's a distribution prerequisite, not a floor one). Drop the "single task-manifest owner for F3/F5/L1" coupling — F3 and F5 are themselves being demoted (#3, #4), so the manifest loses two of its three consumers. | The manifest's justification leans heavily on F3/F5/L1 all needing one task-manifest. Demote F3 and F5 (isolation-first) and the manifest is mostly a distribution artifact — which is gated behind the plugin (#8). Frontmatter now; the consumer when the plugin ships. |
| 10 | **The lens panel / 4-reviewer setup** (`@reviewer` fans out 4 isolated single-class lenses in parallel; C2 adversarial independence; C5 governance lens added as a 5th) | **KEEP — do not touch** | Keep the 4-lens isolation, the stay-in-lane rule, the shared-canon/isolated-solution framing, and add C5. This is the half Ranger never had to build. | This is the trust-the-output machinery. Ranger ends every run with a human reading the diff; we are deliberately going deeper so we can *remove* that human at low risk. The Gemini-CLI 43%→91% merge-readiness number (pass3 §d) is the strongest evidence in the corpus that adversarial independence is load-bearing. Cutting this to "look simpler" would cut the exact thing that makes unattended output trustworthy. |
| 11 | **F6 — the unforgeable + visible CI verdict gate** (CI re-checks `sentinel-SHA == head-SHA AND required checks green`; verdict posted as a queryable artifact) | **KEEP — the one thing to defend hardest** | Build it exactly as specified. The `.cr-ok` → CI-required-check move is the keystone. | Verified on disk: `.cr-ok` is gitignored (`.gitignore:58`), CI is only `ci.yml`+`integration.yml` — the review verdict literally never reaches CI, so the model grades its own homework and a cloud agent can't read whether review happened. This is the single thing that converts "the model agreed with itself" into a real boundary once the human leaves the merge path. Ranger doesn't need it because a human reviews every PR; we do, precisely because we don't. **This is the line not to cross when simplifying.** |
| 12 | **The autonomy program sequencing** (Phase 0 floor → Phase 1 spine → 1.5 compounding → 2 quality → 3 distribution → 4 self-improving) | **KEEP the ordering, SIMPLIFY Phase 0** | The phase ordering is genuinely good (no trigger fires before its floor). The simplification: **Phase 0 collapses from 5 floor moves + 2 preconditions to F0 + F6 + F7 + F9.** F2 folds into F0; F1 stays; F3/F5 leave Phase 0 entirely. | The sequencing discipline is a strength — keep it. But the "minimal floor is 5 moves" claim is itself slightly inflated once isolation-first lands: F0 absorbs F2, and F3/F5 were never truly P0 for the label-trigger path. The genuinely-minimal Phase 0 is *the box (F0) + the un-forgeable finish line (F6) + the loop bounds (F7) + the side-effect lockout (F9) + the destructive-bash guard (F1).* |
| 13 | **F1 — block-dangerous-bash.sh** (fail-closed PreToolUse guard: `rm -rf` outside worktree, DROP/TRUNCATE/DELETE-no-WHERE, prod deploy, non-local `db push`, writes to `.git`/`.claude`) | **KEEP** | Build it, fail-closed, full scope. Cheap and deterministic. | Even in a disposable box, `rm -rf` outside the worktree and writes to guard files are real local damage. This is ~80 lines, deterministic, runs under `disable-model-invocation`, and prevents the named incidents (Replit prod-DB deletion, PocketOS). Low cost, real value — the floor's cheapest honest pillar. |
| 14 | **F7 — bounded-loop contract** (MAX_ITERATION + REJECT/UNATTENDED terminal state) and **F8 — fleet circuit breaker** | **KEEP F7 / DEFER F8** | F7 is P0 — an unattended loop with no retry ceiling is the "5 polished PRs solving the wrong problem" failure. F8 (stop-the-line across the fleet) is genuinely P0-*before-fleet-volume*, which doesn't exist yet — defer to the fleet trigger. | F7 bounds *one* loop and is needed the moment the first trigger fires. F8 bounds *the fleet* and is needed the moment you run many repos at volume. The design already tiers them this way; this pass just affirms it — don't build the fleet circuit breaker before there's a fleet. |
| 15 | **F9 — disable-model-invocation on side-effect skills** | **KEEP** | Tier every skill; gate the irreversible side-effect skills. | Cheap (frontmatter), deterministic, and the substrate that makes side-effect skills safe to keep installed. *One honest caveat the design already flags:* the "removes from context" guarantee is uncorroborated on the target CC version — verify it, or F9 is +1 advisory line, not a removal. |
| 16 | **L7 — narration / observability channel** (continuous status stream + append-only agent-PR log) | **KEEP — but SIMPLIFY to one surface** | Keep it; it's the trust precondition for unattended runs and Ranger independently confirms it (screenshots-to-Slack). But pick **GitHub as the single paging surface** (Fork F9 recommendation) so it rides the substrate F6 already builds — no new Slack/Linear connector, no new F5 leg. | Ranger's "post a screenshot to the channel the human already watches" is direct evidence this is the right shape, not gold-plating. The simplification is *don't add a connector-credential surface*: anchor narration + the log on GitHub (PR comments + a roll-up) and you avoid re-introducing a trifecta leg you just spent F5 removing. |
| 17 | **CMP4 — `/scan-context` bidirectional drift detection** (staleness + doc-fiction + decay; houses the L5 reference-integrity check) | **SIMPLIFY** | Build the **reference-integrity check** now (it's cheap and the canon *already* cites 5 phantom artifacts — a live bug). **Defer** the staleness/decay/fiction-classification engine and the cross-repo P9 loop until canon lives in one place (GitHub) and a 2nd repo exists. | The reference-integrity half is a real, present bug fix (grep for a named artifact, fail if absent). The full bidirectional-drift-with-decay engine is fleet-scale context-rot machinery built before the fleet. Ship the grep; defer the engine. |
| 18 | **C8/C9/C10 — `/verify` render gate + agent-legible markup mandate + evidence bundle** | **KEEP C10 + C9-lite / SIMPLIFY C8** | Keep the C10 test+typecheck-block-on-red hook payload (cheap, high-value regression trust). Keep the `data-testid`/aria mandate (C9) — it's free at commit time via lint. **Simplify C8**: the headless-CI render gate with fail-closed tenant assertion + pixel-diff baseline is real work — build it when the first UI-fix autonomy run is real, not before. | The screenshot/render gate is the half of Ranger we *do* keep (their PM reviews a screenshot). But pixel-diff baselines and a fail-closed tenant assertion are a meaningful build; sequence it to the first autonomous UI fix. The cheap regression-trust half (run the tests, block on red) ships immediately. |
| 19 | **LOOP-7 / A6 — risk-based auto-approval** (non-LLM LOW/MEDIUM/HIGH classifier; LOW auto-approves into the F6 floor) | **KEEP the design, DEFER the build (Fork F2)** | It's already correctly gated: ships observe-only (classify + log, human merges) until C4 recall clears a floor. Don't build the live auto-approve lane until calibration justifies it. | This is the genuine payoff of the whole program, and it's correctly sequenced behind measurement. No change except: don't let it pull C4's full granularity (#7) forward — observe-only needs only the aggregate recall number. |
| 20 | **The CHANGELOG / Notion→GitHub canon migration (P3) + push-back-up (P8) + cross-repo loop (P9)** | **DEFER the cross-repo halves; KEEP the source-of-truth move** | Move canon to GitHub now (it makes convergence a `git diff` and unblocks the cloud agent — real, present value). **Defer** push-back-up automation (gated: 2nd repo installs) and the P9 repair-worker (gated: Fork F7). | The "GitHub as canon" move pays off today (a cloud agent can't reliably read Notion). The cross-repo *distribution* machinery is, again, solving a fleet problem before the fleet. The design already gates these — affirm the gates, don't build ahead. |

---

## The simplest version that still works

**The smallest V2 that delivers all three charter goals — autonomy, safety, and learning — is roughly *eight*
built things, not forty-three.** Everything else is documented-with-a-trigger, not built.

**The box (safety, the cheap way):**
1. **F0 — isolation-by-construction.** A disposable per-job DB branch, no prod credentials in the box, the
   cloud `/schedule` restricted-network surface as the default, and a side-effect outbox in unattended mode.
   *This one move absorbs F2 and demotes F3 and F5.*
2. **F1 — block-dangerous-bash.sh**, fail-closed. Cheap local-damage guard that survives even in the box.
3. **F9 — disable-model-invocation** on irreversible side-effect skills (verify the "removes from context"
   guarantee first).

**The finish line (trust, the half Ranger skips):**
4. **F6 — the un-forgeable CI verdict gate.** `.cr-ok` becomes a CI required-check on the shipped SHA. *The
   keystone. The one thing to defend hardest.*
5. **The 4-lens adversarial reviewer + C5 governance lens**, isolated-solution / shared-canon. The trust-the-
   output machinery Ranger never had to build.
6. **C4-lite — one golden-set, one aggregate recall number** that gates auto-merge. Not per-lens, not per-pass.

**The loop (autonomy):**
7. **The spine: L1 (GitHub-label trigger first) → worktree → /cr → F6 → pr.sh**, with **F7** (bounded loop +
   REJECT) wrapping it and **L7** (narration + log, on GitHub) making it legible. `/goal` and `/lfg` are the
   continuation + orchestration primitives that close it.

**The learning (compounding):**
8. **CMP1 (read-path: recurring findings → implementer task-start context) + CMP2 (finding→enforcement
   ratchet)** + the cheap **reference-integrity check** half of CMP4. Close the read-path; ratchet repeat
   findings into deterministic blocks. *Defer the decay engine and the cross-repo loop.*

**What got cut or deferred to get here:**
- **F2** folded into F0 (provide a safe DB, don't refuse an unsafe one).
- **F3 / F5** demoted from floor to gated hardening — isolation-first makes the prod blast radius they guard
  *absent*, not *guarded*. F5's tool-tagging engine is cut; only a narrow check on the free-text trigger path
  and the cheap MCP pin-and-diff lockfile survive.
- **The memory decay engine** (`last_seen` clocks, 90-day demotion) deferred until rule-rot is real.
- **The full distribution pillar** (marketplace channels, version pinning, push-back-up automation, the manifest
  *consumer*) deferred behind the 2nd-repo trigger. Frontmatter and "GitHub-as-canon" ship now; the plugin
  machinery doesn't.
- **The P9 cross-repo context loop + repair-worker** deferred behind the fleet trigger and Fork F7.
- **F8 fleet circuit breaker** deferred behind fleet-volume.
- **C4 per-lens/per-pass granularity, C8 pixel-diff render gate** sequenced to their first real consumer.
- **The 43-move program** stays as a grounded backlog with explicit triggers — it is not the build list.

That is a world-class harness: it runs unattended in a box that can't hurt prod, it can't ship code the model
graded itself, an independent adversarial reviewer attacks every diff with a measured catch-rate, and it gets
smarter every cycle. The cut machinery isn't *wrong* — it's **early**. Each deferred item has a named trigger
that turns it back on the moment it earns its place.

---

## Complexity we should NOT cut — and why

These are the places where "make it simpler" is the wrong instinct. Ranger is **silent** on every one of them,
because Ranger ends each run with a human reviewing a screenshot — and our charter exists to *remove* that human
at scale. Cut these to look lean and you cut the exact thing that makes unattended output trustworthy.

1. **F6 — the un-forgeable CI verdict gate.** The whole point. Today the verdict dies in a gitignored file the
   model writes and reads itself. Without F6, "autonomy" means "the model agreed with itself and pushed to
   main." Verified on disk; not hypothetical. *This is the single line not to cross.*

2. **The 4-lens adversarial independence (C2) + governance lens (C5).** The Gemini-CLI 43%→91% merge-readiness
   jump is the strongest quantified evidence in the corpus that an independent adversarial pass catches what the
   author's own context can't. A canon-aware reviewer that can flag a locked-ADR violation is a moat no SaaS
   review tool can replicate. This is the trust half, and it stays deep.

3. **C4 reviewer calibration (the *principle*, even as we simplify the granularity).** You cannot ship auto-merge
   on a quality gate whose miss rate you've never measured — *especially* after a blind Sonnet→Opus model swap.
   One honest aggregate recall number is the minimum; it is the thing that licenses removing the human. Simplify
   the apparatus, never the principle.

4. **C11 — money-math property-based invariants** (when built). A wrong total on a $30k-client proposal is the
   exact disaster the product cannot ship, and under autonomy the loop could quietly weaken its own example
   tests. A human-authored invariant the loop *cannot* weaken is the right kind of un-forgeable. (Gated on the
   `fast-check` install — that gate is fine; the mechanism is not over-engineering.)

5. **F7 — the bounded-loop + REJECT contract.** Ranger never had to bound an unattended overnight loop because a
   human watched every run. We do. The "5 polished, all-green PRs solving the wrong problem, straight to a tired
   human" failure is unique to the autonomy we're building, and a retry ceiling + a real REJECT terminal state is
   the cheap, deterministic answer.

**The through-line:** Ranger solved *"make it cheap and safe to RUN an agent, with a human reviewing each
result."* We are solving the harder second half — *"make the output trustworthy enough to safely remove that
human."* Simplify the floor toward Ranger's isolation-first model as hard as it will go. Keep the review,
verification, and un-forgeable-finish-line depth exactly where it is. The two halves are complementary, and the
honest simplification is: **a much lighter floor, the same review spine.**
