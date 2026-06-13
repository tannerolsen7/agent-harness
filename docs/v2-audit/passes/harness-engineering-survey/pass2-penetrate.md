# Pass 2 — Penetrate

Building on pass1: this pass does not re-summarize. It reads the article's structure for what it *takes for
granted*, where its own evidence cuts against its own recommendations, and what net-new analysis the survey
enables that the survey itself never draws out. Citations point to pass1 sections.

---

## A. The article's deepest thesis is two theses, and they fight each other

Building on pass1's Part 1 and Part 6, the survey actually advances **two** doctrines and never notices they
pull in opposite directions:

- **Thesis A — "Add structure" (the harness-as-moat thread).** The five primary sources (pass1 Part 2) and the
  whole Priority Action Map (pass1 Part 5) are *additive*: build hooks, build a three-repo system, build
  sensors, build a context graph, build manifests, build security scanners. More machinery → more capability.
- **Thesis B — "Remove instruction" (the ETH thread).** The single result the author elevates to "most
  important" (pass1 Part 6, the ETH finding) says the opposite: context that is comprehensive or
  already-inferable *degrades* the agent and *raises* cost. The corrective is *subtraction* — minimal, surgical,
  human-written, "fewer instructions at all."

The author never reconciles these. The CLAUDE.md-audit gap (pass1 Part 4, Gap 8) is the only place Thesis B
touches the action map; everywhere else the plan is pure Thesis A. **Net-new reading:** the survey's own
strongest evidence (ETH, and the LangChain "max reasoning budget scored *worse*" result in pass1 Part 1) is a
warning against the additive plan it spends Parts 2–5 building. A faithful synthesis would have made
*subtraction a first-class tier*, not a single MEDIUM-priority line item. This is the central unexamined
contradiction.

## B. "Hooks" is doing two jobs the article conflates

Building on pass1's Gap 1 ("No hooks layer (CRITICAL)") and the ECC/Stripe descriptions (pass1 Part 2): the
word "hooks" silently spans two different control types from Böckeler's own taxonomy (pass1 Part 1).
- A **PreToolUse deny on `rm -rf`** is a *guide* made deterministic — a feedforward floor that fires before the
  act.
- A **Stop hook that runs tests and forces continuation**, or a drift detector, is a *sensor* — feedback after
  the act.
The article files the first under Gap 1 (hooks) and the second under Gap 4 (sensors), as if they were different
layers, when mechanically they are the *same lifecycle mechanism* pointed at different moments. **Net-new:** the
real axis is not "hooks vs sensors" but **deterministic-floor (block bad acts) vs measurement-loop (detect
quality drift).** A harness can have a rich deterministic floor and *zero* measurement, or vice-versa. Collapsing
both into "we have zero hooks" hides which of the two a given harness actually lacks — and as Pass 3 shows, our
harness has a great deal of the first and almost none of the second.

## C. The survivorship bias the survey never names

Building on pass1 Part 2's flagship numbers — Stripe's 1,000 PRs/week, OpenAI's 1M lines / 1,500 PRs, Spotify's
1,500 PRs, ECC's "178k ⭐," Carlini's 100K-line compiler — every primary exhibit is a *success story selected
because it succeeded*. The survey reads them as "here is what a good harness contains," but they are equally
consistent with "here is what large pre-existing infrastructure + a strong team + a forgiving domain (compilers,
SDKs, internal tooling) can absorb." Stripe's own quoted lesson (pass1 Part 2, source 5) half-admits this — *the
infrastructure existed years before LLMs* — which means the causal arrow may run **mature-engineering-org →
agent throughput**, not **harness features → throughput**. **Net-new:** none of these exhibits is a single
developer with a Next/Supabase app and parallel worktrees, which is the actual subject. The survey imports
enterprise-scale conclusions into a one-person context without adjusting for scale, and the "5+ pp benchmark
swing" stat (pass1 Part 3) is measured on benchmarks, not on a $30k-proposal-tool repo.

## D. Hidden assumption: a manifest/graph is needed because *tools* can't see, when the real cost is *humans* maintaining it

Building on pass1's EQUAL table and Gaps 2/6/7 (three-repo, `library.yaml`, context graph, context-rot): the
survey treats "machine-readable manifest" and "context graph" as unalloyed goods because "the agent can't
navigate the chain" (Nimbalyst, pass1 Part 2 source 3). The unexamined assumption is that the bottleneck is
*agent navigability*. But every one of these artifacts — `library.yaml`, `skills-index.yaml`, HANDOFF.md, the
node graph — is a **second source of truth that a human must keep in sync with the first** (the actual skill
files, the actual commits). The ETH finding (pass1 Part 6) is precisely that a stale/redundant context artifact
is *net-negative*. **Net-new contradiction inside the article:** Gap 6 says "build a manifest"; Gap 7 says
"build a linter because manifests/context go stale"; the article never notices that Gap 7 exists *because* of
Gap 6 — it proposes the disease and the medicine as two separate improvements. The disciplined move is to
prefer artifacts that are **derived** (generated from the skill files at read time) over artifacts that are
**maintained** (a hand-kept YAML that drifts).

## E. The article grades a strawman of "our system" — its baseline is unverified

Building on pass1 Part 4's closing note: the entire gap analysis rests on assertions about "our harness" that
the author never inspected against disk — "we have zero hooks," "never been audited," "CLAUDE.md likely too
long," "`/cr-feature`," "`agentic-system-enabled` sentinel," "8 specialist agent templates." These are stated
with the same confidence as the externally-sourced facts, but they are **introspective guesses**. A gap analysis
is only as good as its baseline, and this baseline is a snapshot of a *mental model*, not a filesystem. The page
banner ("frozen 2026-05-21… must not be used to make implementation decisions") is the author conceding exactly
this. **Net-new:** the article's most actionable section (Parts 4–5) is its least evidence-backed; its
least actionable section (Part 1 history) is its most. Value-per-claim runs *opposite* to the article's own
ordering of importance.

## F. What the survey gets genuinely right, sharpened

Building on pass1 Parts 1, 5, 6 — three load-bearing insights survive scrutiny and should not be discounted
just because the action map around them is flawed:
1. **The Hashimoto ratchet** (pass1 Part 1): "every agent mistake → a permanent structural fix so it never
   recurs." This is a *process* claim, not a feature claim, and it is the survey's most durable idea. It is also
   testable against any harness: *does a corrected mistake become an enforced rule, or just a note?*
2. **Stripe's "max 2 CI rounds then human"** (pass1 Part 2, source 5): a concrete, falsifiable stopping
   condition. Most harnesses (per the EQUAL table, pass1 Part 4) have *no* defined stopping condition; this is a
   genuinely missing primitive for unattended runs, and it is cheap.
3. **Guides vs sensors** (pass1 Part 1): even after the Pass-2-B critique, the taxonomy's real payload is the
   observation that almost every harness is *all guides, no sensors* — it can instruct but cannot measure
   whether instruction is working. That asymmetry is the survey's sharpest diagnostic, independent of the
   (weaker) prescription to "build an eval framework."

## G. The one structural idea worth more than the article gives it

Building on pass1 Part 2 source 1 (three-repo) and Gap 2: stripped of the enterprise framing, the kernel is
**"the harness must be able to leave the repo it was born in."** The author files this as a HIGH cross-project
gap and immediately over-specifies the solution (three separate repos, Backstage catalogs, per-tool adapters).
**Net-new:** the *principle* (one editable source, deployed outward, version-controlled, rebuildable from
clone) is sound and is the survey's best contribution to a redesign; the *implementation* it prescribes is a
large-org shape that a single operator should resist on the article's own ETH grounds (every adapter folder is
another artifact to keep in sync). Separate the principle from the packaging.
