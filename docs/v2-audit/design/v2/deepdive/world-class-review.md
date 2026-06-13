# World-Class Review — How We Catch Bugs Before They Ship, and How We Let Agents Run All the Way to a PR/MR Safely

> Plain-English deep-dive. Source spine: `design/ambition/VISION.md` (the five pillars; CRAFT moves C2/C4/C5/C6/C8/C9/C10/C11/C12/C13, FLOOR moves F1/F2/F6/F7/F8/F9, LOOP move LOOP-7). Review re-mines drawn on in full: `coderabbit.md`, `code-review-latentspace.md`, `ramp-inspect-agent.md`, `when-is-llm-call-worth-it.md`, `engineering-rigour-small-team.md`, `augment-code.md`. Roster rows: `design/v2/roster.md` (`cr`, `cr-security`, `reviewer`, the four lenses, `security-reviewer`, `task-runner`, `ux-reviewer`).
>
> Two corrections applied throughout: (1) **Slack and Linear are first-class ways to start work**, on equal footing with a label in your git host — a person can report a bug or kick off a feature from either, and it gets routed and run. (2) **Git-host-agnostic** — "your git host" (GitHub, GitLab, or other), "pull/merge request (PR/MR)", "CI pipeline", "protected branch", "issue/ticket". The plugin install, the canon-in-repo, and the CI gate all generalize. (3) Where this references running an agent "until it's done," it uses **Claude Code's built-in continuation loop** (run until a stopping condition), not a new skill.

---

## Why review is the whole game now

Start with the one fact that reorders everything. When agents write most of the code, **writing stops being the bottleneck and checking becomes it.** CodeRabbit's data makes this concrete: pull/merge requests that an AI co-authored draw about **1.7x more review comments per line** than human-written ones (`coderabbit.md`). So the more code your fleet produces, the *faster* review cost grows — it grows super-linearly. And review does not parallelize the way generation does, because it has always ended in one person's judgment at the merge gate. That one person is the ceiling. No number of parallel agents lifts a ceiling set by one human's attention.

So "world-class review" is not a nice-to-have polish layer. It is the load-bearing wall of the whole autonomous system. If review is weak, every agent you add makes the problem worse, not better. If review is excellent, every agent you add compounds.

The honest starting point (from VISION.md's thesis): our V1 reviewer is **the deepest in the corpus** — 9 analytical passes plus a 4-lens adversarial pass — but it has five fatal-at-scale weaknesses. It is **invisible** (its verdict dies in a gitignored `.cr-ok` file that never reaches CI), **un-independent** (the adversarial pass shares the coder's context, so it inherits the coder's blind spots), **un-calibrated** (nobody has measured whether it catches 1-in-5 bugs or 4-in-5), **advisory** (it asks nicely instead of blocking), and **write-only** on the learning side (findings get counted but never read back). Every one of those is a seam where a human used to silently backstop the system. The moment the human leaves the loop, each seam becomes a live failure surface.

The rest of this document is two questions, answered concretely:

1. **How are we making the code-review process itself world-class?** (Every mechanism, what it adds, the exact failure it catches.)
2. **How do we make agents safe to run all the way up to a PR/MR — and give humans the best possible chance to catch the bugs that get past the agents?**

---

# PART 1 — How the review process becomes world-class

Think of this as a stack of independent checks, each tuned to catch one *class* of failure that the others structurally cannot. The power is in the independence: a bug has to slip past every layer, and each layer is blind to a *different* thing, so they don't all miss the same bug together.

## 1.1 The independent adversarial pass — a fresh reviewer that doesn't trust the coder

**The single strongest, most-measured mechanism in all the research.** (`code-review-latentspace.md`, Move 2, → VISION C2.)

Here is the evidence. Google's Gemini CLI ran an experiment (issue #26397): one model writes the code, a *separate* model hunts for bugs in it, the first fixes them, the second re-checks — and they repeat this 3–4 times. This loop lifted **merge-readiness from 43% to 91%** on a test set, *before any human ever looked.* That is the single largest pre-human quality jump cited anywhere in the corpus. Doubling-plus of mergeability, from independence and iteration alone.

The principle behind it is one sentence: **"the auditor doesn't prepare the books."** A reviewer who shares the coder's context inherits the coder's rationalizations. If the coder talked itself into "this edge case can't happen," a reviewer reading that same reasoning will nod along. Our V1 problem is exactly this: the adversarial pass runs *inside the same `/cr` invocation, over the same branch, sharing the coding session's context window* (`code-review-latentspace.md`, citing §3c). It is structurally incapable of the independence that produced the 43%→91% gain. It's the same brain double-checking itself.

But — and this is the subtle part the Gemini experiment got *wrong* and our design gets right — pure "no shared context" would also blind the reviewer to our own rules. A reviewer who knows nothing about our project would re-argue settled decisions and miss our tenant-isolation rules in `src/data/`. So the right design is a precise split, which the research names directly:

> **Isolated solution context + full project canon.**

In plain terms: the fresh reviewer does **not** see *how* the coder arrived at the solution (no coding-session reasoning, no author's justifications, no chain of edits). But it **does** get full read access to project canon — CLAUDE.md, AGENTS.md, the Rejected Patterns, PITFALLS, the ADRs (Architecture Decision Records — short docs recording locked design choices and *why*). And its job is framed as an attack: **"find what breaks this,"** not "review this."

And it runs as the **iterate-until-clean loop**, not one pass: hunt → fix → retest → hunt again, for a few rounds, bounded by an iteration cap. The 43%→91% number is from the *loop*, not a single pass. A single fresh pass is good; the loop is what produced the doubling.

- **What it adds:** Independence (it doesn't share the coder's blind spots) plus canon-awareness (it knows our rules) plus iteration (it converges instead of pointing once and stopping).
- **The failure it catches:** the "confidently-wrong solution that the coder rationalized and the same-context reviewer rubber-stamped." This is the failure mode with no human in the inner loop — there's no one to catch the rationalization, so the independent adversary *is* the catch.

## 1.2 The four lenses — four specialists, each blind on purpose

The adversarial pass is not one reviewer; it's an **orchestrator (`@reviewer`) that fans out four isolated lenses in parallel** (roster: `reviewer`, `lens-abuse`, `lens-assumption`, `lens-cascade`, `lens-composition`). Each lens attacks exactly **one** class of failure, and is forbidden from drifting into another lens's territory. Here's the why behind each design rule:

**Each lens = one failure class.** A reviewer told to "find all the problems" finds the easy ones and tires out. A reviewer told to find *only one specific kind* of problem goes deep on it. The four:

| Lens | The single question it holds | Its required, differentiating field |
|---|---|---|
| `lens-assumption` | "What does this code treat as guaranteed that isn't?" (caller behavior, env state, timing, data shape, error states, external systems) | — |
| `lens-abuse` | "What happens when a caller uses this interface incorrectly *but plausibly*?" (7 probe categories) | **LIKELIHOOD** |
| `lens-cascade` | "For each failure path: what breaks, who catches it, how far does it propagate, what does the user finally see?" | **BLAST RADIUS** |
| `lens-composition` | "What breaks when this module is used *alongside* the existing ones?" (layer-rule violations, naming collisions, circular deps, **golden-exemplar divergence**) | — |

**The "stay-in-lane" rule.** When a lens notices a problem that belongs to a *different* lens, it notes it briefly and does **not** start doing that other lens's job (roster, `lens-assumption`). This is what keeps four parallel reviewers from collapsing into four copies of the same general review. Stay-in-lane is the mechanism that makes the parallelism *non-overlapping* — four genuinely different angles instead of four overlapping ones.

**Pre-read + pass-context (lenses don't re-read).** The orchestrator reads the project canon **once** (CONTEXT/AGENTS/PITFALLS) and **passes it into each lens** (roster, `reviewer`). The lenses don't each re-read the canon — they receive it. This saves context budget and, more importantly, guarantees every lens reviews against the *same* understanding of the rules.

**The isolation invariant.** No cross-lens contamination — each lens gets the file contents but never another lens's output. VISION says this explicitly: "V2 must **not** optimize it into one shared-context reviewer" (roster, `reviewer`). The reason is the same as `review-strategy`'s finding: a lens primed on another lens's critique *softens its own findings* to avoid looking redundant. Isolation keeps every lens at full force.

- **What it adds:** four deep, non-overlapping attacks instead of one shallow broad one.
- **The failure each catches:** a hidden assumption (assumption), a plausible misuse (abuse), a small bug that silently propagates into a wrong value the user sees (cascade), and a change that quietly breaks composition with existing modules or diverges from a golden exemplar (composition). Different classes, different lenses, no shared blind spot.

## 1.3 The REJECT tier — the reviewer can say "this is the wrong approach"

Today `/cr` has three exits: **MUST FIX** (auto-fixed), **NEEDS HUMAN**, **SUGGESTION**. All three assume the work is *worth finishing* and just needs polish (`code-review-latentspace.md`, Move 1, → VISION F7). There is no exit that says: *"this solves the wrong problem — close it and re-spec."*

Why this gap is dangerous specifically under autonomy: imagine an overnight `/queue` run produces five beautifully-polished, all-tests-green PRs/MRs that solve the *wrong problem*, touch files outside their declared scope, or balloon past the size a human can review. With no concept of approach-level failure, the system ships all five up the chain to a tired human at 9 AM. **"Functionally correct, wrong problem" is invisible to a reviewer reading the diff cold** — it's only visible when the diff is checked *against the spec*.

REJECT is the fix. It is a fourth outcome with **deterministic triggers** (no model opinion needed):

1. **Scope explosion** — files touched outside the spec's declared scope.
2. **Diff over a hard ceiling** (the research's default is ~800 lines; treat as tunable).
3. **CI failing with no auto-fix path** (the strongest single predictor of "this won't merge").
4. **Auth/schema/payment change with zero or negative test delta** (a risky change that *removed* test coverage).
5. **The diff demonstrably solves a different problem than the spec states.**

A REJECT **auto-closes and re-queues** the task with a reason note. It does **not** escalate to a human — that's the point; it's the autonomous circuit breaker that keeps wrong work from reaching the human at all. But it's bounded: REJECT → re-spec → REJECT *twice* escalates to the human-paging surface (so it can't loop forever). VISION (F7) is precise that this is **three mechanisms — close, annotate-and-re-queue, cap-and-escalate** — not just a fourth label.

- **What it adds:** the ability to refuse an approach, not just polish it.
- **The failure it catches:** the polished-but-wrong overnight PR that wastes the human's scarcest resource — attention — on work that should never have reached them.

## 1.4 Calibration — measuring whether the reviewer actually catches bugs

Here is the most uncomfortable honest fact in the whole review research: **nobody has measured whether `/cr` catches 1-in-5 defects or 4-in-5.** And we just swapped the model under it (Sonnet 4.6 → Opus 4.8) **blind** — no re-measurement (`coderabbit.md` Move 2; `when-is-llm-call-worth-it.md` Move 1; → VISION C4).

The principle, borrowed from how AI-native teams build product features: a probabilistic system **degrades silently.** Our deterministic CI (type-check, lint, tests) cannot see this, because those tools test *the code under review* — they never test *whether the reviewer still reviews well.* You can swap a model, watch all the green checks pass, and never notice that `/cr` quietly stopped catching a whole class of bug. You find out when a defect `/cr` "reviewed" reaches main.

The fix is a **golden set** and a recall measurement, and it's cheaper than it sounds:

- Build a `cr-golden/` corpus: a few dozen **adversarially-seeded labeled diffs** — a diff with a *known* missing fallback, a known `as`-cast-without-narrowing, a known cross-tenant RLS hole, a known open-redirect — plus a set of **clean** diffs.
- A CI job (`/cr-calibrate`) runs `/cr` against the corpus and emits **recall** (what fraction of the seeded bugs did it catch?) **per pass and per lens**, plus a **false-positive rate** on the clean diffs (how much noise does it generate?).
- **Re-run it on every model swap** and on any change to the `/cr` passes or the tier-merge rule. A stale or dropped recall **blocks** promoting `/cr` as a trusted gate, and **caps** `/queue`/`/schedule` self-merge until recall clears a stated floor.

The cost objection ("we don't have the volume / the golden set") is wrong at *harness* scale (`when-is-llm-call-worth-it.md`): a product classifier needs thousands of labeled examples, but a code-review regression probe needs ~30 — *and the team already has them in git history.* Every past bug that shipped is a golden negative; every past `/cr` MUST-FIX is a golden positive.

The doctrine to hold onto (VISION C4): **a calibrated `/cr` is a *triage* layer, never a *terminal* authority.** Measuring it tells you how much to trust it. It does **not** make it the thing that decides what ships — that's the deterministic gate in Part 2. Calibration is what turns "we hope the reviewer is good" into "we know its miss-rate and we gate on it."

- **What it adds:** a number you can trust and watch over time.
- **The failure it catches:** shipping autonomy on a quality gate with an *unknown, possibly catastrophic* miss-rate — and silent regression on every model bump.

## 1.5 The governance lens — the thing no SaaS reviewer can replicate

This is the **highest-defensibility move** in the review research, and it's the one that converts our reviewer from "a local copy of CodeRabbit" into "a reviewer no SaaS tool can build" (`coderabbit.md` Move 3, → VISION C5).

The insight is about what's called **memory locality.** A tool like CodeRabbit can reason over three things: the diff, the diff's code-graph neighbors, and the live web. It **structurally cannot** reason over a *fourth* thing — your historical design decisions, your locked architectural choices, your team's hard-won conventions. That fourth set is exactly what we have sitting on disk and currently *don't* feed into review: `docs/adr/` (the locked decisions), AGENTS.md's **Rejected Patterns** (things we explicitly decided *not* to do), PITFALLS.md (bugs we've already been bitten by), and the **golden-exemplars** table (the canonical correct example for each layer).

Consider three real examples of a change that is **diff-local in text but governance-global in meaning**:

- A migration that violates a locked ADR — looks fine line-by-line; contradicts a decision made months ago for reasons not visible in the diff.
- A role-check placed in an RLS policy — this is an **explicitly Rejected Pattern** in this project (roles live in `src/data/` only). The diff looks reasonable; it violates a locked rule.
- A schema-file/folder collision — a **known PITFALL** that TypeScript resolves silently and wrongly.

A reviewer that doesn't read the governance corpus will wave all three through. A reviewer that *does* will flag each one and cite the specific ADR/pattern/PITFALL it violates.

The mechanism: a **dedicated `/cr` lens whose input is the locked-decision corpus** (`docs/adr/` + Rejected Patterns + PITFALLS + the golden-exemplars table), instructed to flag any diff hunk that contradicts a locked decision and **cite the specific rule.** The `lens-composition` already carries the seed of this — its **"golden-exemplar divergence = Must-Fix"** rule and its "silent new standard → always Must-Fix" auto-escalation (roster, `lens-composition`). C5 generalizes that into a full governance lens.

Why this is the moat: this corpus *is* our canon, and (per the PLATFORM pillar) it's moving into the git repo as the single source of truth. **Wiring it into review is the same thing as enforcing canon at the merge boundary** — automatically, in every repo, without a human re-checking. A SaaS reviewer has no access to your durable project memory; we have ours sitting right there.

- **What it adds:** enforcement of *your* locked decisions, conventions, and known traps — the one thing depth-on-a-generic-reviewer can never give you.
- **The failure it catches:** a PR that silently violates a locked ADR, resurrects a rejected pattern, steps on a known PITFALL, or diverges from a golden exemplar — none of which a generic reviewer can even see.

## 1.6 The structural review contract — fixed template, test floor, risk classifier

These are the **deterministic** scaffolding around the smart review — the parts that need no model judgment and therefore can't be rationalized away.

**Fixed PR/MR template.** Every autonomous PR/MR carries a fixed, scannable structure (detailed in Part 2). This makes the human's job a constant-shape scan instead of a fresh archaeology dig each time.

**Test-count-never-decreases floor.** A change that *removes* test coverage while touching a risky path is one of the REJECT triggers above, and it's the kind of thing a deterministic check catches perfectly: count the tests before, count them after, block if it went down on a sensitive path. The research from the small-team source sharpens this into a specific gate — **for any commit scoped as a `fix`, the diff must contain a new test that was red-before / green-after** (`engineering-rigour-small-team.md`, Move 1). Today TDD is mandatory only for *pure functions*; a bug fix to a component, a server action, or the `/p/[token]` renderer has **no reproducing-test requirement.** A `bugfix-test-guard` closes that hole deterministically.

**Blast-radius / keyword risk classifier.** A **non-LLM** classifier reads the diff and tags risk from: which paths it touches (auth, middleware, `proxy.ts`, RLS/migration files, `src/data/**`, the proposal-send path, `/p/[token]/**`), diff size, test delta, and whether files are in declared scope (`code-review-latentspace.md` Move 3; `engineering-rigour-small-team.md` Move 2). On a hit to a sensitive path, it **forces** the security review (`/cr-security`) to run and refuses the merge sentinel until it did. Today that rule is *prose in CLAUDE.md* ("run `/cr-security` when a commit touches auth/middleware/RLS") — which is exactly the advisory layer that evaporates when no human remembers to follow it. Making it a **path-glob classifier in CI** turns "the agent remembered to run security review" into "the diff content forced it" (roster, `the cr-security path classifier`).

The deepest principle under all three (from `augment-code.md`, Move 1): **every rule is consciously assigned to a layer — probabilistic prose OR deterministic enforcement, never confused.** A model *probably* follows written prose; the probability is below 1.0 no matter how well you write it. So any rule that *matters* must live where the runtime physically cannot bypass it. The structural contract is where the must-hold review rules live.

- **What it adds:** the parts of review that don't need a brain — and therefore can't be skipped, tired-out, or talked-around.
- **The failure it catches:** the "agent forgot to run the security review on an auth change," the "fix shipped with no reproducing test," the "PR ballooned and nobody noticed."

## 1.7 Layered, cost-ordered gates — cheap checks first, expensive checks last

The final design principle ties the stack together: **order the gates from cheapest to most expensive, and let a cheap gate's failure stop the line before an expensive gate ever runs.**

The ordering (`augment-code.md` on the deterministic-vs-probabilistic split; `when-is-llm-call-worth-it.md` Move 3 on chaining probabilistic steps):

1. **Static / deterministic (cheapest):** type-check, lint, the test suite, the path-glob risk classifier, diff-size check, scope check. Milliseconds-to-seconds, zero model cost, can't be argued with.
2. **Semantic (medium):** the 9 analytical `/cr` passes plus the governance lens — model reasoning, but bounded.
3. **Agentic (most expensive):** the 4-lens adversarial fan-out, the iterate-until-clean loop, `/cr-security`'s deep passes — multiple model calls, parallel sub-agents.

Why order matters beyond cost: chained probabilistic steps **multiply their failure** (`when-is-llm-call-worth-it.md` Move 3). Three 90%-reliable steps end-to-end is 0.9³ = 73%. A 9-pass review plus a 4-lens fan-out is a *long* probabilistic chain. The fix is **deterministic gates between probabilistic passes**: after `/cr`'s auto-fix pass, deterministically re-run type-check/lint/tests *before* the next pass trusts the fix. The deterministic checkpoint stops one bad pass from poisoning everything downstream while the chain still reports success. (The scope limit, stated honestly: do **not** cut review passes to chase a reliability number — depth is our differentiator; the deterministic gates between passes recover the reliability without sacrificing depth.)

- **What it adds:** you never pay for an expensive agentic review on a diff a free type-check already rejected; and a bad pass can't silently poison the chain.
- **The failure it catches:** wasted cost, and silent compounding failure across a long probabilistic pipeline.

---

# PART 2 — Making agents safe to run all the way to a PR/MR, and giving humans the best chance to catch what's left

Part 1 was about catching bugs. Part 2 is about two things at once: (a) bounding what an unattended agent can *do* so it's safe to let it run to a PR/MR with no human watching, and (b) handing the human, at the PR/MR boundary, the best possible shot at catching whatever got past every machine layer.

The framing to hold: **the keystone is un-forgeable on the deterministic checks; the deep judgment is trust-but-verify with a measured miss-rate.** We'll be honest about exactly where the hard floor ends and the measured-trust begins.

## 2.1 The deterministic safety floor — bounding an unattended run

When a human drives every session, advisory rules are enough — the human is the backstop catching the tail. **The moment an unattended trigger fires, an advisory rule is a suggestion and a hardcoded guard is the only real control** (`augment-code.md`, Move 5; VISION Pillar 2). So before any trigger can fire unattended, a small deterministic floor must be wired. The minimal floor is five moves (VISION):

- **F1 — destructive-command block (fail-closed).** A guard that blocks irreversible shell actions *before they run*: prod deploys, `rm -rf` outside the worktree, `DROP`/`TRUNCATE`/`DELETE`-without-`WHERE`, destructive migration pushes, writes to `.git`/`.claude`/hook files. **Fail-closed** is the non-negotiable detail (`augment-code.md`, Move 2): if a dependency the guard needs (like `jq`) is missing, the guard must **block**, not pass. Our two *existing* guards currently **fail open** — if `jq` is missing they let the operation through. That means under exactly the stripped-down conditions where you most need the guard (a fresh cloud sandbox), the guard evaporates *and looks like it ran.* "A guard that fails open is probabilistic enforcement in a costume." Fail-closed + a startup self-test that proves the guard blocks a known-bad input is the fix.
- **F2 — credential firewall (blocking pre-flight).** The highest-severity incident class is credential exfiltration that needs *no exploit at all* (in one red-team, 24 of 25). For this project specifically, `.env.local` points at **production** with a service-role key (full tenant-isolation bypass). A blocking pre-flight hook **refuses any unattended run whose readable env holds a prod URL or service-role key**, and gives each parallel worker its own isolated env.
- **F6 — the unforgeable + visible verdict gate (THE KEYSTONE — its own section below).**
- **F7 — the bounded-loop contract.** A hard **retry ceiling** (default 2–3) plus the REJECT/NEEDS-HUMAN terminal state. LLM retries hit diminishing returns and start producing "creative but wrong fixes harder to review than the original problem." The ceiling stops an unattended agent from spinning forever or stopping half-done with no one paged.
- **F9 — `disable-model-invocation` on side-effect skills.** This frontmatter flag *removes a skill from the model's context*, making it a safe actuator that **only a pinned orchestrator step can summon** — never the model on its own judgment. Open-PR, deploy, send-Slack, migration-apply all get it. Today **0 of 26 skills** carry any invocation control. This is the substrate that makes side-effect skills safe to leave in an autonomous path.

Two more, sequenced just after:

- **F8 — stop-the-line circuit breaker.** F7's ceiling bounds *one* loop; F8 bounds the *fleet*. On N repeats of the same normalized failure signature across the fleet, it writes a stop-the-line marker, stops opening new PRs in that class, and pages a human. The failure it prevents: "the fleet doesn't fail once, it fails twenty times" — 20 PRs stacked on one broken assumption across multiple repos before anyone looks.
- **F5 — the MCP trifecta gate** (for the Slack/Linear/free-text path specifically). An agent becomes an exfiltration vector the moment it simultaneously holds (1) private-data access, (2) untrusted-content exposure, (3) egress. Because the Slack/Linear summon path **ingests attacker-controllable text** (anyone can type a bug report), it adds the untrusted-content leg — so this path needs the trifecta gate before it goes live, where a plain label trigger does not.

> **Correction applied — Slack and Linear are first-class triggers.** A person can report a bug or kick off a feature from **Slack or Linear**, on equal footing with a label/issue in your git host, and it gets routed and run. Because those surfaces carry attacker-controllable free-text, they ride a slightly larger floor (F5 + egress) than a label trigger — but they are *first-class entry points*, not a second-phase afterthought. The routing is the same: the trigger hands the task to a worktree-isolated agent that runs the full review stack and opens a PR/MR.

- **What the floor adds:** a small set of controls *below the model's reach* that bound what an unattended run can do.
- **The failure it catches:** the destructive command, the leaked prod credential, the infinite/half-done loop, the fleet-wide cascade, the model invoking a deploy on its own judgment.

## 2.2 THE KEYSTONE — the un-forgeable, visible verdict gate (F6), stated honestly

This is the most important single mechanism, and the one we must describe with complete honesty about what it does and does *not* guarantee.

**The V1 problem.** Today the loop's own model passes agree on zero MUST-FIX, write a `.cr-ok` file, and push. *The thing being graded computes its own passing grade.* Worse, that `.cr-ok` sentinel is **gitignored and never reaches CI** (`coderabbit.md` Move 1, → VISION F6). So at the merge boundary: the model agreed with itself, and the proof is a file CI can't even see. A cloud agent that clones the repo has no `.cr-ok` and no laptop to honor it — it literally cannot tell whether review happened.

**The fix has two faces, one deliverable** (VISION F6; roster, `the CI verdict gate`):

- **Enforcement face:** a CI required-check that parses the `branch:sha` sentinel and **fails unless the sentinel SHA == the head SHA AND all required deterministic checks (type-check, lint, tests) are green** — made mandatory via **protected-branch rules.** The branch cannot merge on a stale or absent review.
- **Surface face:** `/cr` writes its **full verdict** (MUST-FIX-resolved, NEEDS-HUMAN, SUGGESTION, REJECT, recurring-findings delta, lens findings) to a **structured artifact** that the PR/MR-open script posts to the PR/MR. Now any human or agent at the boundary can *read* what review found.

The doctrine renames itself from "cross-MODEL" to **"cross-AUTHORITY"**: the thing that certifies "ready to merge" is no longer the same authority that produced the code.

**Now the honest precision** — VISION states this exactly, and it must not be overstated (VISION headline delta #3, "the invisible seam, stated honestly"):

> The un-forgeable part of F6 is the **SHA-match plus the deterministic checks** (type-check, lint, tests re-run by CI on the exact shipped SHA). Those are recomputed by CI, and the model writes no record CI trusts — so they **cannot be forged.** The deep **9-pass + 4-lens judgment** is **coverage-bounded trust-but-verify**: its miss-rate is *measured* by the C4 golden-set recall, and its verdict is posted to the PR as a queryable artifact — but **it is not itself the merge gate.**

So F6 does **not** claim to make "the model agreed with itself" un-shippable. It makes the *deterministic floor* un-forgeable, and it puts a *measured bound* on the judgment half. That's the honest keystone: the deterministic checks are a wall; the deep judgment is a measured probability with a known miss-rate, surfaced for the human, not trusted as terminal.

- **What it adds:** a finish line the model cannot draw for itself — CI re-computes it on the shipped code.
- **The failure it catches:** the loop merging because the reviewer agents shared the generator's blind spots; the forgeable, invisible sentinel; the cloud agent that can't tell whether review happened.

## 2.3 The structured, scannable PR/MR — so a human reviews in under 15 minutes

When the deterministic floor and the deep review have done their work, what reaches the human should be **a constant, scannable shape**, not a raw diff to excavate from scratch. Every autonomous PR/MR carries a fixed template:

- **Problem** — what was wrong (1–2 sentences).
- **Root cause** — *why* it was wrong.
- **Solution** — what this change does and why it's structured this way.
- **Test coverage** — what tests were added/changed, and the red-before/green-after evidence for any fix.
- **Blast radius** — which paths it touches and the risk tier the classifier assigned (so the human knows where to look hardest).
- **Evidence** — the bundle: test output (green), type-check (clean), the `/cr` verdict artifact, and for any UI change a before/after screenshot.

Why this shape specifically: it maps onto **this project's own discipline rule** — the three questions any change must answer (*what does this do and why is it structured this way / where could this fail / what would you change*). Problem + Root-Cause + Solution answer the first; Blast-Radius answers the second; Test-Coverage + Evidence prove it. The research backs the throughput claim: a machine-generated PR summary plus the evidence bundle is what lets a human **review intent over proof** instead of re-deriving correctness (`ramp-inspect-agent.md` — Ramp's shift from "human catches the regression" to "human reviews intent and design," which drove ~30% of merged PRs *with no usage mandate*). And at fleet scale, a before/after screenshot is the *only* way a human reviewing five repos' PRs can confirm a visual change without checking out each branch (`ramp-inspect-agent.md`, the visual-artifact guardrail).

- **What it adds:** a fixed, evidence-backed shape that a human can scan in well under 15 minutes.
- **The failure it catches:** the human burning their scarce attention re-deriving what the PR even does, and missing the actual bug because they ran out of patience.

## 2.4 The session-end review artifact + evidence bundle carried into the PR/MR

The evidence in the PR/MR isn't assembled by hand at the end — it's produced by a **single shared session-end hook** that fires at task completion (VISION HOOK-1; roster, `the shared session-end Stop hook`). This is one hook carrying several **payloads**, built once:

- **Regression evidence bundle (C10):** run `npm run test` + `npx tsc --noEmit` and **block on red.** This is the part a hook *can* deterministically do (`ramp-inspect-agent.md`, Move 1). It buys **regression-trust, not correctness-trust** — the semantic checkpoint stays, and this hook must **not** write `.cr-ok` (that would launder a regression check into a capability unlock).
- **The render artifact (honest capability limit):** a hook **cannot** *require* an artifact (like a screenshot) to exist before completion (`when-is-llm-call-worth-it.md` capability fact; VISION C10/capability preconditions). So the screenshot is **verify-if-present + advisory at the hook**, and the **hard render gate lives on the CI leg** (`/verify`, C8) against a preview deploy. This honesty matters: we don't claim the hook compels the screenshot; CI does.
- **The narration emitter + the retry counter** also hang off this one hook (so we don't build four competing Stop hooks fighting over the guard file).

The deepest reason this layer exists, stated plainly (`augment-code.md`, Move "accountability for unattended agents"): the usual accountability answer — *"the person who pushes the PR owns it"* — **assumes a person is present.** At 3 AM, in a cloud schedule, there is no person pushing in real time. So the cultural backstop must be replaced by a **technical** one that travels with the unattended run: the session-end test gate, the CI-verified verdict, and `disable-model-invocation` on side-effect skills. The culture stays for human merges; the technical floor covers the unattended ones.

- **What it adds:** an evidence bundle that the PR/MR *carries*, produced deterministically at session end.
- **The failure it catches:** "the agent reported done, opened a PR, and the regression shipped because nothing deterministic re-ran the suite."

## 2.5 Surfacing blast-radius and risk — pointing the human at the right lines

A human reviewing a 200-line diff has a budget of attention. The system spends it well by **telling the human where the danger is.** The non-LLM risk classifier (§1.6) tags every diff LOW/MEDIUM/HIGH off paths-touched + diff-size + test-delta + scope. That tier rides into the PR/MR's **Blast Radius** section, and `lens-cascade`'s **BLAST RADIUS** field surfaces, for each failure path, *what the user ultimately observes* (its highest-severity rubric entry is literally "silent wrong value shown to user").

So the human doesn't read the diff uniformly. They read the **HIGH-risk hunks first** — the auth edit, the RLS-adjacent `src/data` query, the money math, the `/p/[token]` client-facing render. The system has already done the triage of *where to look.*

- **What it adds:** attention spent on the lines that can actually hurt.
- **The failure it catches:** the human skimming evenly and missing the one risky hunk buried in a mostly-boring diff.

## 2.6 The human diff-review checklist — what only a human can catch

Even with everything above, the human is the last line for a specific *category* of bug that no machine layer reliably catches. The checklist:

1. **The "huh, why is this here?" test.** Scan the diff for anything that doesn't obviously belong. A line that has no clear reason to exist is the single highest-signal smell — it's where a hallucinated import, a leftover debug call, a subtly-wrong constant, or a scope-creep edit hides. A machine reviewer rationalizes "maybe it's needed"; a human's "that's weird" instinct is the catch.
2. **The 60-second manual smoke.** For any user-facing change, *actually click the thing.* Open the preview deploy, do the one action the PR claims to fix, confirm it does what the Problem/Solution says. The agent's screenshot proves it *rendered*; the human's click proves it *works the way a person expects.*
3. **Intent vs. spec.** Does the diff solve the problem the spec stated, or a *different* problem it solved well? (REJECT catches the deterministic versions; the human catches the subtle "technically in scope but missed the point" version.)
4. **The tenant trap.** For anything touching `src/data/`, RLS, or a shared surface: a screenshot taken authed as the *wrong tenant* renders perfectly — RLS isolation is invisible to the DOM (VISION C8). The human is the one who asks "are we sure this is scoped to the right team?" The `/verify` render gate has a **fail-closed tenant assertion** for the automatable part, but the judgment of "does this leak across tenants" is human-backstopped.
5. **The taste call.** Is this the *right* solution, or a working one? Would I structure it differently, and why? (The discipline rule's third question — the one a model will always answer "looks fine" to.)

- **What it adds:** the categories — odd-smelling code, real-world behavior, intent, cross-tenant leaks, taste — that machine layers structurally under-catch.
- **The failure it catches:** the bug that passes every green check because it's *correct code solving the wrong thing*, or *correct-looking code with a subtle human-obvious wrongness.*

## 2.7 Auto-approve ≠ auto-merge — the agent is never the last gate

This is the rule that makes risk-based auto-approval safe (VISION LOOP-7; roster, `risk-based auto-approval`). A **deterministic non-LLM classifier** sorts PRs/MRs LOW/MEDIUM/HIGH:

- **LOW** → auto-**approves** into the F6 CI floor. **Auto-approve is not auto-merge.** The deterministic CI gate (F6: SHA-match + green checks) is still the last thing standing between the PR and main. The agent records an approval; the *floor* merges.
- **MEDIUM** → routes to the full `/cr` flow.
- **HIGH** (auth/schema/payment) → forces `/cr-security` + **mandatory human sign-off.**

The merge decision **carries no model judgment** — that's why it's safe under `disable-model-invocation`. And the agent is **never the last gate**: even on LOW, the deterministic floor is. This is the move that dissolves the human-review-capacity bottleneck (Ona's independent 74% lead-time reduction, `code-review-latentspace.md` Move 3) *without* making the agent the final authority. It ships **observe-only** (classify + log, human merges) until C4 recall clears a floor — then live LOW-auto, conservatively (for a $30k-client tool, money math and `src/data/` stay MEDIUM+ by policy).

- **What it adds:** most PRs out of the human path, with the deterministic floor — not the agent — as the final gate.
- **The failure it catches:** the agent grading its own homework all the way to main; the human becoming the throughput ceiling on low-risk changes.

## 2.8 The compounding layer — review that makes the *next* review better

One mechanism that isn't a gate but makes every gate sharper over time: **findings read back into the next run's starting context, and recurring findings ratchet into deterministic blocks.**

- **CMP1 — close the read-path.** Today RECURRING-FINDINGS is auto-counted but **"never read by implementers."** Bitloops proved the payoff: feeding every caught violation back as generation context drove violations down **87–100% over 8 weeks** — from *context accumulation*, not model upgrades (`code-review-latentspace.md` Move 4). So: load recurring findings into the implementer's **task-start context**, with a freshness model (a pattern unobserved 90 days decays out).
- **CMP2 — the finding→enforcement ratchet.** When a finding crosses ≥3 occurrences and promotes, **classify it**: can this become a deterministic block — a hook, a lint rule, or a new C5 governance-lens criterion? If so, **generate the enforcement artifact in the same flow** (`coderabbit.md` Move 4). This is Hashimoto's definition of harness engineering: "engineer a solution so the agent never makes that mistake again." Otherwise you keep re-finding the same bug forever instead of making it *impossible.*
- **CMP3 — the effectiveness ledger.** Track **first-pass-approval-rate, review-cycle-count, REJECT-or-not, per-finding recurrence, PR-size trend** per agent PR (`code-review-latentspace.md` Move 5). You cannot run a self-improving loop on vibes — first-pass-approval is the signal that confirms compounding is actually happening, and recurrence is CMP1's eviction signal.

- **What it adds:** a review system that gets measurably smarter every cycle instead of re-learning the same lesson nightly.
- **The failure it catches:** an agent making the same class of mistake every run because nothing it was corrected on is read back — and a "self-improving" loop you can't actually confirm is improving.

---

# GAPS — review mechanisms in the research we are NOT yet using and should

Honest list of what the research teaches that the V2 design under-built or left as a thread, flagged so the author can surface it. Each is a real, citable mechanism.

1. **A stale-PR / ship-brief agent on the chat surface (Slack/Linear).** CodeRabbit ships a *proactive* chat agent: stale-PR nudges, weekly ship briefs, incident triage (`coderabbit.md`, Autonomy angle #1). A fleet across 5+ repos *needs* this — no human watches five PR queues. The vision treats Slack/Linear as *inbound triggers* (summon work) but does **not** yet design the *outbound* proactive review agent (nudge me about the PR that's been sitting for 3 days). **New design item:** a scheduled review-housekeeping agent that surfaces stale PRs/MRs and a ship brief to the chat surface. Git-host-agnostic and chat-surface-agnostic.

2. **The fallback / abstention contract on every reasoning pass.** `when-is-llm-call-worth-it.md` Move 4: every reasoning pass should return a structured result with an explicit **confidence/abstention field**, and the orchestrator needs a *defined* response to "pass abstained / returned malformed output" (re-run once, then NEEDS-HUMAN — **never silently continue**). The current design has F7's retry ceiling but no uniform **pass-result contract** with an abstention signal. Under autonomy a silently-failed review pass marks a regression "resolved." **New design item:** a uniform pass-result contract with a confidence/abstention field that side-effect skills check before firing.

3. **The "layer-assignment audit" as a standing review pass.** `augment-code.md` Move 1: a pass over CLAUDE.md and skill bodies that classifies each rule as *probability-shifter* (fine as prose) or *must-be-structural* (needs a hook/CI/lint twin), and flags every safety-critical prose rule with **no structural twin** as a build target. The vision *applies* this principle (it's why F1/F6/etc. exist) but does **not** wire it as a recurring `/cr` + `/compound` pass that keeps finding newly-added prose rules that should be structural. **New design item:** a recurring "does this safety-critical rule have a structural twin?" audit pass.

4. **Guard-integrity self-test in CI as a first-class invariant.** `augment-code.md` Move 2: beyond fixing the two existing fail-open guards, establish **fail-closed + startup self-test + CI-presence-check** as a *standing contract every structural guard must satisfy* — a CI smoke test that asserts each guard actually blocks a known-bad input, so a silently-degraded guard surfaces loudly. The vision names fail-closed (F1) but does **not** yet make the periodic guard-self-test a named CI job. **New design item:** a `guard-integrity` CI check that proves every guard blocks a known-bad input on every run.

5. **The "Doctrine" governance layer with freshness/ownership.** `engineering-rigour-small-team.md` Move 3: the judgment-shaping layer (SOUL/values, "honest assessment over validation," the discipline rule, the PocketOS reasoning) is the **least-governed** part of the harness — no owner, no freshness rule — so it rots silently until an agent reasons from stale values. **New design item:** name Doctrine as a first-class layer and give every doctrine file a declared loading ritual + a staleness rule, surfaced at session start like the `last_run > 7 days` ritual check already is.

6. **Property-based testing on money math as a review oracle (C11, fork-gated).** Example tests check the cases someone thought of; PBT asserts an *invariant* over hundreds of generated inputs (`total = sum(line items)`; tax never on service fees; no negative totals; integer-cents round-tripping exact) and is the human-authored oracle the loop **cannot weaken** (`recursive-self-improvement` via VISION C11). This is gated on a dependency decision (`fast-check`, Fork F6) — flag it as a *pending* review mechanism, not a built one, because money math on a $30k-client tool is exactly where a silently-weakened test is most expensive.

7. **Per-task-type "what's safe to auto-approve" learned from the ledger.** CMP3's per-task-type signal tells you *which kinds of work the agent one-shots vs. flails on* — which should feed the LOOP-7 classifier's thresholds. The vision lists CMP3 and LOOP-7 separately but does **not** yet wire the **per-task-type recurrence data into the auto-approval thresholds.** **New design item:** feed CMP3's per-task-type first-pass-approval back into LOOP-7's LOW/MEDIUM cutoffs, so auto-approval scope is *earned by measured reliability*, not set by a guess.

8. **Calibrate `/cr-security` and the lenses, not just `/cr` overall.** C4 calibrates `/cr`; the research is explicit that the **same protocol applies to `/cr-security` (golden vulnerable diffs) and each of the 4 lenses** (`when-is-llm-call-worth-it.md` Move 1). The vision's C4 emits per-pass/per-lens recall, but the golden-set design currently centers on `/cr`; **make sure `/cr-security` gets its own golden vulnerable-diff corpus** — security false-negatives are the most expensive miss, and they're the one we're least allowed to leave unmeasured.

---

# THE LAYERED DEFENSE — the full ordered stack between "agent thinks it's done" and "merged to main"

Read top to bottom. A bug has to survive **every** layer to reach main, and each layer is blind to a *different* thing — so they don't all miss the same bug together. (Cheapest/most-deterministic first; the human and the un-forgeable CI floor last.)

1. **The agent's own claim of "done"** — the weakest signal; trusted for *nothing* that ships (it may control continuation, never certification).
2. **The bounded-loop ceiling (F7)** — if the agent has retried past the cap, or the diff exploded, or it's solving the wrong problem → **REJECT and re-queue**, never reaching review at all.
3. **The session-end hook (C10/HOOK-1)** — `npm run test` + `npx tsc --noEmit` re-run deterministically; **block on red.** Regression-trust before a PR can even open.
4. **The deterministic structural contract** — diff-size check, scope check, test-count-never-decreases / `bugfix-test-guard`, and the **path-glob risk classifier** that forces `/cr-security` on any sensitive-path hit. No model judgment; can't be skipped.
5. **The 9 analytical `/cr` passes + the governance lens (C5)** — semantic review against the code *and* against the locked ADRs / Rejected Patterns / PITFALLS / golden exemplars. Catches the violation-of-canon a generic reviewer can't see.
6. **The independent 4-lens adversarial pass (C2), run as the iterate-until-clean loop** — a fresh reviewer with isolated solution context + full project canon, four non-overlapping lenses (assumption / abuse / cascade / composition), hunt→fix→retest for 3–4 rounds. The 43%→91% mechanism. Catches the confidently-wrong solution the coder rationalized.
7. **`/cr-security` on any sensitive-path diff (forced by layer 4)** — single-tier MUST-FIX-only review of auth/RLS/data-boundary changes, chaining the Supabase security checklist. The hard guardrail at the most expensive failure seam.
8. **Calibration as the meta-layer (C4)** — *not in the per-PR path*, but standing over it: the golden-set recall that tells you how much to trust layers 5–7, re-run on every model swap, capping self-merge until recall clears a floor. The thing that keeps the trust honest.
9. **The structured, evidence-backed PR/MR (Problem / Root-Cause / Solution / Test-Coverage / Blast-Radius / Evidence)** — the verdict artifact (F6 surface face) posted to the PR/MR; blast-radius tier surfaced so the human looks at the right lines.
10. **Risk-based routing (LOOP-7)** — LOW auto-*approves* into the floor; MEDIUM → `/cr`; HIGH (auth/schema/payment) → `/cr-security` + **mandatory human.** Auto-approve ≠ auto-merge.
11. **The human diff review** — the "huh, why is this here?" test, the 60-second manual smoke on a preview deploy, intent-vs-spec, the tenant trap, the taste call. The categories machines under-catch.
12. **The keystone CI verdict gate (F6) on a protected branch** — the **un-forgeable** last wall: CI re-runs the deterministic checks on the **exact shipped SHA** and fails unless the sentinel SHA == head SHA AND all required checks are green. The model writes no record CI trusts. **This is the only layer that cannot be forged** — and it is *last*, after both the agent and the human.

**The one honest caveat, restated:** layers 3, 4, and 12 are **un-forgeable** (pure deterministic re-computation). Layers 5, 6, 7 are **trust-but-verify with a measured miss-rate** (calibrated by layer 8). Layer 11 is the irreplaceable human catch for the categories no machine reliably gets. The keystone makes the *deterministic floor* impossible to fake and puts a *measured bound* on the judgment half — it does **not** claim to make a confidently-wrong-but-deterministically-green change impossible to merge. That residual risk is exactly what layer 11 (the human) and layer 8 (calibration) exist to bound, and we name it rather than paper over it.
