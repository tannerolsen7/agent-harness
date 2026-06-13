# Ambition Re-mine — Stripe Minions: Unattended Coding Agents at Scale (Kaliski, 2026)

## What this source is (plain English, 2-3 sentences)
A curated research page on Stripe's "Minions" — agents that write **1,300+ PRs/week, all
agent-authored, zero human-written code**, run unattended, every one human-reviewed before merge.
The article's central thesis is that this works because of **human-DX infrastructure that predated
the LLMs** (10-second pre-warmed devboxes, deep test suites, fast CI, a 500-tool MCP "Toolshed" with
per-task curation, deterministic+agentic "blueprints", a 2-retry CI ceiling) — and that Minions are
triggered most often by a **Slack emoji** because the real engineering problem is "activation energy"
(idea → first line of code), not execution. It is the single richest source in the corpus on
*autonomy-at-scale*: a production system where agents fire from where the idea lives and run with no
human in the driver's seat.

## The full-ambition moves this source teaches

### Move: The Slack-emoji trigger — fire the agent where the idea already lives (activation-energy collapse)
- **Plain-English what & why:** At Stripe the *most common* way a Minion is launched is reacting to a
  Slack message with an emoji. No repo clone, no terminal, no branch, no `gh issue` ceremony — the
  thought ("this bug should be fixed", "add this flag") becomes a running agent at the exact surface
  where the thought occurred, with zero context switch. Kaliski: "I can't remember the last time I
  started work in a text editor." The failure this prevents is the silent tax of *activation energy*:
  ideas that never become work because the friction of starting (open editor, find file, set up branch)
  is higher than the idea's perceived value. Collapse that friction and the latent backlog in people's
  heads actually ships. They also expose CLI, web, and **automated-system** triggers — i.e. another
  system, not just a human, can summon a Minion.
- **The mechanism:** Build the autonomous front-door our harness deliberately lacks: a summon path from
  where work is discussed/tracked → a cloud agent run. Concretely, a `/schedule`- or connector-driven
  listener (Slack reaction, Linear/GitHub issue label, comment mention) that hands the captured intent
  to a cloud Claude Code run, which clones the repo, runs the committed skills (`/feature` →
  `/cr` → `scripts/pr.sh`), and returns a reviewed PR URL. A side-effect skill with
  `disable-model-invocation:true` (open-PR, post-back-to-Slack) makes the side effects safe.
- **Citation:** pass1 (Kaliski) "Triggered via Slack emoji (most common), CLI, web, **automated
  systems**"; pass1 thesis 6 "activation energy, not execution, is the engineering problem." Our
  absence: the harness is **single-project, single-human** with no trigger front-door —
  `[canon §0 headline; §8 "never been installed anywhere but event-vendor"]`; cross-project reality is
  "Multi-project is a goal, not a state" `[§8]`. No Slack/Linear summon row exists anywhere in §1–§9 —
  **confirmed absence.**
- **Conservative disposition:** §C-deferred *and* actively argued-against. pass3 §(b) gap #4 reclassifies
  this as "a gap to **resist**, not build" — "with one human review gate, driving activation toward a
  Slack-emoji trigger increases queue pressure on the exact bottleneck we can't scale… the actionable
  item is **review-load management**, not trigger-friction reduction." MASTER-FINDINGS folds it into the
  "review-bandwidth ≥ generation-bandwidth" smaller gap [C2-G11], not a trigger build.
- **RE-JUDGMENT under the new charter: ELEVATE — this is the single most-suppressed move in the file.**
  pass3's logic ("cheaper activation just loads the one scarce reviewer") was *correct under the old
  conservative charter* where there is one human reviewer and no durable autonomy. The new charter
  **reverses both premises**: autonomy is first-class and the scale is parallel agent fleets across 5+
  repos, not one solo dev triaging a queue by hand. Under that scale the Slack/automated-system trigger
  is not "queue pressure on a bottleneck" — it is *the entire north star* ("bug → reviewed PR, summoned
  from Slack/Linear … designed in, never deferred"). And the resolved fact that **cloud `/schedule`
  exists and runs on Anthropic infra** kills the only remaining objection (no durable substrate). This
  should be in-scope-now and built bigger than the article: not just human-emoji summon but the
  *automated-system* trigger (a failing CI job, a Linear "bug" label, a Sentry alert) firing a cloud
  Minion. The pass3 dismissal is the textbook instance of the "doesn't apply to solo" scale-bias the
  charter strikes.

### Move: The numeric retry ceiling — hard-stop at N attempts, hand to a human (protect the review gate)
- **Plain-English what & why:** A Minion gets **at most 2 CI-fix rounds**; after that it stops and hands
  back to a human. The stated failure mode (the article's only mechanism with a real *why*): LLMs hit
  diminishing returns on retries and start producing "creative but wrong fixes that are harder to review
  than the original problem." The ceiling exists primarily to **protect reviewability** — past N
  attempts the diff degrades into something a human can't cheaply trust, so you cut losses while the
  output is still reviewable. It costs nothing: it is a counter and a contract rule.
- **The mechanism:** Add an explicit attempt counter + hard-stop to the fix loops that currently have
  none: `/cr`'s "Opus auto-fix" loop `[canon §3c]` and any `@task-runner` / `/dev` CI-fix retry. After N
  (the article's empirical default is 2; we should pick a number and write the failure mode beside it)
  the agent writes a NEEDS-HUMAN handoff with the failing state, rather than looping. In a cloud run this
  is what bounds an unattended Minion's blast radius before it produces an unreviewable mess.
- **Citation:** pass1 "Max 2 CI retry rounds, then hand back to a human"; pass2 §2.4 "the one place the
  article supplies a failure mode… exists **to protect the human review gate**." Our absence: "no hook
  or contract rule that counts agent fix-attempts and forces a human handoff after N… the auto-fix loop
  in `/cr` has no stated attempt ceiling" — **confirmed absence** `[§3c "Opus auto-fix"; §3e, §5]`.
- **Conservative disposition:** §C/§D — pass3 §(b) gap #1 admits it as "a **tier-1 contract rule** —
  words in a doc, near-zero cost" but immediately hedges with a "disciplined caveat: verify whether
  existing STOP-AND-SURFACE wording already implies one-retry-then-stop before adding redundant text."
  MASTER-FINDINGS does not give it a top-level MOVE; it dissolves into the advisory-floor discussion.
- **RE-JUDGMENT under the new charter: ELEVATE (modestly, but unambiguously in-scope-now).** This is the
  cleanest, cheapest, best-evidenced mechanism in the source and it is the one safety primitive that
  *becomes load-bearing precisely when autonomy turns on*. In an attended session a human notices the
  agent thrashing; in an **unattended cloud Minion** nothing stops a degenerate retry loop except a
  committed ceiling. The conservative "maybe it's already implied, ship simple first" hedge is exactly
  backwards for an autonomy charter: an *implied* stop is not a stop. Write the counter, write the
  number, write the one-line failure mode beside it (per §9). It is not "bigger" in scope — it is small
  — but it moves from "maybe redundant, verify first" to "non-negotiable floor for any unattended run."

### Move: Blueprint discipline — label every pipeline step D/A/G and convert should-be-D-but-advisory steps into real gates
- **Plain-English what & why:** Stripe's orchestration is a "blueprint" = a state machine where some
  transitions are **deterministic code** (linters, branch-push — hardcoded, never left to the model) and
  some are **agentic loops** (implement the feature, fix CI). The contribution is not the architecture
  (everyone converges on this) — it's the **classification discipline**: deciding *in advance* which
  steps may never be left to the model. "Each deterministic node is one fewer thing that can go wrong,"
  and at hundreds of runs/day that compounds into reliability. The article's Design Challenge sharpens
  it: audit your pipeline, label each step D (deterministic gate) / A (agentic) / G (human gate), and a
  step you *treat as required in prose but enforce nowhere* is a mislabeled-D that should become a real
  gate. The deeper rule (pass2 §2.2): a D is legitimate **only when justified by a failure mode**, not by
  distrust of the model.
- **The mechanism:** Run the D/A/G labeling against our actual floor, then **build the should-be-D-but-
  advisory gates that are absent on disk**: `block-dangerous-bash.sh` (canon's 3rd guard, ABSENT),
  `enforce-scope.sh` (ABSENT), `branch-registry-guard.sh` (ABSENT), and re-wire the **main-branch agent
  hard-block** that today sits in the *dormant* `.githooks/pre-commit` while the live husky shim lacks
  it. Each new gate ships with a one-line failure mode or it doesn't ship.
- **Citation:** pass1 "Orchestration is a blueprint: deterministic nodes + agentic loops"; pass2 §2.2.
  Our absence — the exact list of should-be-D gates that are prose-only: `[§3e, §5]` (`block-dangerous-
  bash.sh`, `enforce-scope.sh`, `branch-registry-guard.sh` all "Canon structural, **absent on disk**";
  main-branch block "wired out") and the blunt finding "Both agree the system is **overwhelmingly
  advisory** — neither has a deterministic backstop for the bulk of skill bodies, CLAUDE.md rules, or the
  autoMode lists" `[§3e Net enforcement picture]`.
- **Conservative disposition:** §A-already-built for the *pattern* + §B-real-gap for the *labeling*.
  pass3 §(a) says "the D/A separation Stripe sells is **structurally present already**… What we lack is
  the labeling, not the structure" and §(b) gap #2 correctly identifies the absent gates. This one is
  *not* badly suppressed — pass3 handled it well.
- **RE-JUDGMENT under the new charter: ELEVATE (bigger build than pass3 framed).** pass3 was right that
  the pattern exists and the gates are absent, but under the conservative charter it framed the fix as a
  "classification exercise" (tier-2, do the labeling). Under autonomy, the absent gates stop being a
  documentation nicety and become **the deterministic blast-radius floor for unattended runs**. A cloud
  Minion with no `block-dangerous-bash.sh`, no `enforce-scope.sh`, no branch-registry guard, and the
  main-branch block wired out is an autonomy system with its safety floor *missing*. So this is
  in-scope-now as a **build** (write the three absent guards + re-wire the main-branch block), not merely
  a labeling exercise. The "overwhelmingly advisory" finding `[§3e]` is the single biggest deterministic-
  enforcement gap in the whole map, and this move is the direct fix.

### Move: Toolshed + per-task tool curation — surface ~15 of ~500 tools per run to avoid "token paralysis"
- **Plain-English what & why:** Stripe centralizes ~500 internal tools behind one MCP server (Toolshed),
  but each Minion receives a **curated ~15-tool subset** chosen *at task time* — giving all 500 caused
  "token paralysis" (the model drowns in options and degrades). The principle: control what is *surfaced*
  per run, not what *exists*. Same idea applies to rules — global rules are scoped by directory/file
  pattern and picked up as the agent moves through the filesystem (the *same* rule files human tools
  read; no agent-specific duplication).
- **The mechanism:** For us this is mostly **already satisfied by a different mechanism** — skills load
  on invocation, not globally, and CLAUDE.md scopes rules per area `[§1; CLAUDE.md "Changed → Update"
  table]`. The forward-looking residue *under the new charter*: at fleet scale across 5+ repos with the
  MCP trifecta + connectors, the runtime tool surface grows toward Stripe's problem. The mechanism worth
  pre-building is a **per-task / per-skill tool-curation manifest** (which MCP tools a given skill or
  cloud run is allowed to see) so a Minion summoned from Slack isn't handed the full connector surface.
- **Citation:** pass1 "Toolshed… ~500 internal tools… curated ~15-tool subset… giving all 500 caused
  token paralysis"; pass2 §2.7 "what transfers is the *principle*… not the *mechanism* (a centralized
  MCP registry with task-time curation)." Our state: skills "loaded on invocation" `[§1]`; "We have **no
  500-tool token-paralysis problem** — our tool surface is small" (pass3 §a).
- **Conservative disposition:** §A-already-built / §F-overstated-transfer. pass3 §(a) "Not a gap…the
  principle is already satisfied"; the article's "transfers Fully" is marked an overstatement (only the
  principle transfers). MASTER-FINDINGS registers an "MCP trifecta gate" [C3-G11] deferred behind a build
  decision.
- **RE-JUDGMENT under the new charter: UPHELD-CUT (as a present build) — but flagged as a near-horizon
  watch.** Even at world-class fleet scale, building a Toolshed-style centralized MCP registry *today*
  solves a problem we don't have: our tool surface is genuinely small and skills already curate on
  invocation. The named failure mode the constraint would prevent — "token paralysis from too many tools"
  — does not occur at our current surface, so a registry now is overhead per the §9 golden rule. **The
  honest cut is the *registry mechanism*, not the *principle*.** The principle (curate per task) is
  already live. The one piece that genuinely activates under the autonomy charter is the narrow
  per-skill/per-cloud-run **tool-allow manifest** (don't hand an unattended Slack-summoned Minion every
  connector) — that is real and small, and belongs to the trigger move above, not to a Toolshed rebuild.

### Move: "Fork, don't build" — choose the agent runtime by where your moat lives
- **Plain-English what & why:** Stripe forked Goose (Block's open-source harness) rather than building a
  custom agent loop, because their differentiation (the "moat") is in the *environment* (devboxes,
  Toolshed, blueprints), not the loop. Ramp built "Inspect" from scratch because its moat required deep
  custom integration. The stated decision criterion: build when integration depth requires it; otherwise
  fork. The useful residue (pass2 §2.3): ask "**where does our differentiation actually live?**" *before*
  picking tools.
- **The mechanism:** Not a build — a decision lens for V2: we *are* the Claude Code harness, not a forked
  runtime. The moat question says our differentiation is the *context + skills + enforcement floor*, not
  the agent loop — which validates staying on Claude Code and investing in skills/hooks/distribution
  rather than forking a runtime.
- **Citation:** pass1 thesis 4 + Open Question #4 (article admits it does **not** know why Stripe chose
  Goose). Our direction is framed as "global, GitHub-hosted, bidirectional self-update" `[§0 headline;
  §8]` — an installability question, not a runtime-fork question.
- **Conservative disposition:** §C-narrowly / §weakness-flagged. pass3 §(c) "post-hoc… unfalsifiable as
  stated… Use the moat question, discard the pseudo-criterion"; pass3 §(d) "a **build-plan decision, not
  a research gap**."
- **RE-JUDGMENT under the new charter: UPHELD-CUT.** pass2's critique is correct and survives the charter
  change: the criterion is reverse-engineered from the outcome and unfalsifiable (any result "confirms"
  where the moat was). The failure mode cutting it: adopting an unfalsifiable decision rule would let us
  rationalize *any* runtime choice after the fact. Keep the *moat question* as a one-time V2 lens (it
  cleanly validates "stay on Claude Code, invest in distribution"), discard the pseudo-criterion. Nothing
  about parallel-fleet scale rehabilitates it.

### Move: Machine payment — agents as economic actors (software built for agent consumers)
- **Plain-English what & why:** A separate Stripe demo had an agent autonomously spend **$5.47** to plan
  a birthday party — browser sessions, venue research, physical mail, a carbon offset — paying for each
  service on demand. The horizon thesis: some software will be built for *agent* consumers (an API an
  agent pays for), not human users (no UI/login/dashboard).
- **The mechanism:** None for our harness. There is no event-vendor surface where the agent is an
  economic actor.
- **Citation:** pass1 "machine-payment demo… spent $5.47"; pass1 thesis 8. Our state: "maps to nothing in
  the ground-truth map (**no row**)… confirmed absence of any related row in CANONICAL-HARNESS-AS-IS.md
  §1–§9" (pass3 §d).
- **Conservative disposition:** §C-quarantined-as-horizon. pass3 §(d) "Quarantine, don't research… file
  as watch-item, do **not** spend research budget."
- **RE-JUDGMENT under the new charter: UPHELD-CUT.** Even at parallel-fleet world-class scale, machine
  payment has no surface in a proposal-tool harness; the failure mode of building toward it is pure
  speculative debt (the charter's own "build what's needed now"). Quarantine as horizon is correct. This
  is the one place the conservative synthesis and the new charter agree without tension.

## Autonomy angle
This is the **most autonomy-rich source in the corpus** and the one the conservative synthesis most
suppressed. Direct teachings:
- **Summon from where the idea lives:** Slack-emoji trigger as the *most common* launch path, plus
  CLI / web / **automated-system** triggers (another system, not a human, fires a Minion). This is the
  bug→PR / Slack-summon front-door the old charter deferred and pass3 told us to *resist*.
- **Unattended-by-design:** Minions "run unattended — no human watches during execution," with the
  deterministic floor + 2-retry ceiling as the safety rails that *make* unattended runs safe. This is the
  exact "designed in, never deferred" posture the new charter demands.
- **The retry ceiling is an autonomy-safety primitive:** it only becomes load-bearing once a human is no
  longer in the loop to notice thrashing.
- **No self-improving loop and no cloud-scheduling mechanism** are taught here directly (those come from
  the goal-loop / scheduler sources) — but the resolved fact that **cloud `/schedule` exists on Anthropic
  infra** is precisely the substrate that lets us implement Stripe's "unattended + automated-system
  trigger" model without the durability objection pass3 leaned on.

## The single biggest move (one paragraph)
**Build the autonomous trigger front-door — summon a cloud Minion from where the work is discussed
(Slack reaction / Linear or GitHub issue label / automated-system signal) → cloned repo → committed
skills (`/feature` → `/cr` → `scripts/pr.sh`) → a reviewed PR URL posted back.** This is the move the
conservative synthesis most directly inverted: pass3 §(b) gap #4 told us to *resist* lowering activation
energy because it "loads the one scarce reviewer," and MASTER-FINDINGS demoted it to a review-bandwidth
footnote [C2-G11]. Both rest on the retired premises — one solo reviewer, no durable autonomy substrate.
The new charter makes autonomy first-class, the real scale is parallel fleets across 5+ repos, and the
resolved fact that cloud `/schedule` runs on Anthropic infra removes the durability objection entirely.
Stripe proves this works in production at 1,300 PRs/week with every PR still human-reviewed before merge
— i.e. you get the activation-energy collapse *without* surrendering the review gate. It is world-class
because it is the only source in the corpus showing the complete autonomous loop running unattended at
scale with the safety rails (deterministic floor + numeric retry ceiling + isolation) that keep the
output reviewable. Pick this up first; the retry ceiling and the absent D-gates (`block-dangerous-bash.sh`,
`enforce-scope.sh`, `branch-registry-guard.sh`, main-branch hard-block) are the safety floor that makes
the front-door safe to open.
