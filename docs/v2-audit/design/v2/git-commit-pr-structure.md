# V2 Commit & PR Structure Doctrine — How an AI Builds Reviewable Change

> **What this artifact is.** The research-grounded doctrine for *how the V2 harness shapes its output as git history*:
> the size of a commit, the contents of a commit message, the size of a PR, when to ship one PR vs. a stack of PRs,
> and how all of that makes the **human review fast and effective**. The thesis the whole document defends:
> **the bottleneck has moved from writing code to reviewing it** — an AI now writes code faster than any human can
> read it (Claude Code was ~4% of all GitHub commits as of March 2026). The single most valuable thing the harness
> can do is hand the reviewer changes shaped so review is *fast and high-confidence*. Every rule below is justified
> by that one goal. Plain-language throughout: a smart non-expert should be able to follow and teach it.
>
> **How to read this.** Part 1 is the research (senior/staff practice, with sources and the real numbers). Part 2
> applies it to our harness — what we already do well, what to add, and the concrete doctrine to adopt.

---

## Part 0 — The one-paragraph thesis

A reviewer's attention is the scarce resource, not the AI's typing speed. The empirical record is blunt about this:
defect detection collapses once a single review crosses ~400 lines (87% of bugs caught under 100 lines, ~28% caught
over 1,000), and reviewers self-report being **3× more likely to thoroughly review a small change than skim a large
one**. So the harness must produce **small, atomic commits** that build into a **small, single-idea PR**, and when a
feature is genuinely too big for one ~400-line PR, it must split it into a **stack of small PRs** that each stand on
their own. Good commit *messages* (a real "why" in the body) and good commit *sequence* (read top to bottom like a
short story) are not hygiene — they are the review's table of contents. This is what senior engineers do by instinct
and what the harness must do by rule, because an AI has no instinct to keep changes small — left alone it writes the
whole feature in one shot.

---

# PART 1 — How senior/staff engineers structure code changes (the research)

## 1. Commit granularity — atomic commits and the "story of commits"

**The rule.** An *atomic commit* contains exactly **one logical change** — one feature step, one bug fix, one
refactor step, one docs update — and leaves the codebase in a working state (compiles, tests green). It never mixes
concerns: you do not bundle a formatting sweep with a logic change, because the reviewer then can't tell which lines
matter.

**Why "atomic."** Like an atom, it's the smallest unit that still means something on its own. Two tests of whether a
commit is atomic:
1. **The revert test** — can you `git revert` this one commit cleanly without dragging unrelated work back with it?
2. **The sentence test** — can you describe it in one sentence without using "and"? If the message needs "and," it's
   probably two commits.

**The "story of commits."** This is the senior-engineer idea that matters most for review. The *sequence* of commits
on a branch should read like a short narrative: setup → the change, step by step → cleanup. A reviewer who reads the
commits in order should watch the change *assemble itself* and understand the author's reasoning at each step,
**without ever reading the final squashed blob**. Atomic commits "reflect the developer's intent and mental model as
the feature was built" — the reviewer gets the step-by-step logic, not a wall of diff. This is also why atomic
commits make `git bisect` and `git revert` cheap: each commit is a clean save-point, so finding or undoing the commit
that introduced a bug takes seconds, not an archaeology session.

**When to squash vs. keep history.** Two different audiences:
- **The branch, in review** → keep the granular commits. The reviewer wants the story.
- **`main`, after merge** → squash to **one commit per logical change** (a PR that is itself one logical idea
  becomes one clean commit on main). `main`'s history should be a list of *shippable units*, not a transcript of
  every "fix typo" and "address review comment." This is precisely our project's existing **squash-merge to main**
  policy — the granular story lives on the branch and in the PR; main stays clean.

Sources: [Atomic Git Commits — Sandro Dzneladze (Medium)](https://medium.com/@sandrodz/a-developers-guide-to-atomic-git-commits-c7b873b39223),
[Atomic commits — gitbybit](https://gitbybit.com/gitopedia/best-practices/atomic-commits),
[Building Code Quality Culture Through Commit Standards — victoria.dev](https://victoria.dev/posts/building-code-quality-culture-through-commit-standards/),
[Atomic Commits Explained — PHP Architect](https://www.phparch.com/2025/06/atomic-commits-explained-stop-writing-useless-git-messages/).

## 2. Commit messages — conventional commits and "what + why, not how"

**Conventional Commits** is the structured format we already use: `type(scope): short description`, then an optional
body, then optional footers. The types (`feat`, `fix`, `chore`, `refactor`, `test`, `docs`) let both humans and tools
parse intent at a glance and can drive automated changelogs and version bumps.

**Why the body matters — "what + why, not how."** The diff already shows *how* (the literal line changes). The
reviewer can read the code. What the reviewer (and future-you, six months later, debugging at 2am) cannot recover
from the diff is **why** — why this change was necessary, what alternatives were rejected, what trade-off was
accepted. The single most repeated piece of guidance across every current source: *"The body should explain why, not
what, since the diff shows what changed."* A good body answers: what problem this solves, what approach was chosen and
what was rejected, and any consequence a future reader needs to know (breaking change, migration step). Wrap the body
at ~72 characters so it reads cleanly in terminals and tools.

**The payoff is deferred but large.** "Taking the time to write a good commit body pays dividends when debugging
issues months later." The subject line tells you *which* commit; the body tells you *whether you can safely touch it*.

Sources: [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/),
[Conventional Commits — Marc Nuri](https://blog.marcnuri.com/conventional-commits),
[Commit Message Best Practices — Commitizen](https://commitizen-tools.github.io/commitizen/tutorials/writing_commits/).

## 3. PR / MR size — the research on review effectiveness vs. size

This is the part with the hardest numbers, and it is the empirical backbone of the whole doctrine.

**The ~200–400 line sweet spot (SmartBear / Cisco).** SmartBear's large study at Cisco — the most-cited code-review
dataset — found defect detection is highest when a single review covers **roughly 200–400 lines of code**, reviewed
in about **60–90 minutes**, catching **70–90% of defects**. Past ~400 lines, reviewers are overwhelmed and start
missing bugs.

**The effectiveness cliff.** The drop-off is not gentle, it's a cliff:
- Review effectiveness ~**80–90%** at 200 lines.
- Falls **below 70%** once a review exceeds ~400 lines.
- Falls **below 50%** at ~1,000 lines.
- Defect *detection rate* drops from **87% for PRs under 100 lines to ~28% for PRs over 1,000 lines**.
- PRs in the ~200–400 line range have about **40% fewer post-merge defects** than larger PRs.

**Reviewer behavior is the mechanism.** Reviewers reported being **3× more likely to thoroughly review a small
(~500-line) PR than to merely skim a 2,000-line one.** Size doesn't just reduce *how well* a reviewer can review — it
changes *whether they review at all* vs. rubber-stamp. A 2,000-line PR doesn't get a 4×-longer review; it gets a
glance and an LGTM.

**Merge speed (Google's millions-of-reviews data).** Small changes also *move* faster:
- Changes **under 100 lines** → median review turnaround **under 1 hour** at Google.
- **100–500 lines** → median ~4 hours.
- **Over 1,000 lines** → median **24+ hours**, and they receive *significantly fewer substantive comments* (i.e. a
  big PR is both slower *and* worse-reviewed). At Google, **90% of code reviews touch fewer than 10 files** — which
  is *why* their reviews are famously fast (median latency under ~4 hours).

**The one-sentence takeaway:** *small PRs merge faster AND get better reviews.* There is no trade-off here — small
wins on both axes. Keep PRs under ~400 lines of substantive change; treat ~200 lines as the comfortable target.

Sources: [Modern Code Review: A Case Study at Google — ICSE 2018 (Sadowski et al.)](https://sback.it/publications/icse2018seip.pdf),
[Characteristics of Useful Code Reviews — Microsoft Research](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/bosu2015useful.pdf),
[Empirically supported code review best practices — Graphite](https://graphite.com/blog/code-review-best-practices),
[Does PR size actually matter? — cubic](https://www.cubic.dev/blog/does-pr-size-actually-matter),
[The Hidden Cost of Slow Code Reviews: Data from 8M PRs — Vitalii Petrenko](https://vitalii4reva.medium.com/the-hidden-cost-of-slow-code-reviews-data-from-8-million-prs-9926849f1428).

## 4. Stacked PRs / stacked diffs — small PRs for big features

**The problem they solve.** Sometimes a feature genuinely cannot fit in one ~400-line PR *and* cannot be cut down
without shipping something incoherent. The naive options are both bad: one giant PR (un-reviewable, per §3), or a pile
of independent PRs that don't actually build a working feature. **Stacking** is the third way.

**What stacking is.** Break the feature into a *chain* of small PRs where each one builds on the previous:
```
main ← feature-step-1 ← feature-step-2 ← feature-step-3
```
Each PR targets the branch below it (not `main`), so each PR's diff shows **only that step's changes** — small,
self-contained, individually reviewable. "Stacking makes the unit of change an individual commit, rather than a pull
request composed of several commits." The reviewer reviews and approves step-1, then step-2's diff is just step-2,
and so on. As each lands, the tooling rebases the rest so the lowest unmerged PR re-targets `main`.

**When it helps.**
- A large feature that decomposes into a *dependency line* (B needs A, C needs B): schema → data layer → UI, each a
  reviewable PR.
- You want review to *start* on step-1 while you're still writing step-3 (pipelined review).
- You want each step to land on `main` independently and keep `main` always-releasable.

**The trade-offs (be honest).**
- **Rebase churn.** When `main` moves or an early PR gets change-requested, you must rebase the whole stack.
  Engineers at Uber described rebasing becoming "almost a daily habit." The saving grace: conflicts in small diffs
  are small, so each rebase is cheap — and modern tooling automates most of it.
- **Reviewer-availability bottleneck.** Downstream PRs are blocked until upstream ones are reviewed. If reviews are
  slow, the stack stalls.
- **Tooling dependency.** Doing this with raw git is painful; in practice you need a tool to manage branch bases and
  restacking.

**Tooling (and the 2026 shift that matters for us).**
- **Phabricator / `arc`** (Meta, open-sourced) popularized stacked diffs outside Google — now unmaintained.
- **Graphite** (`gt`) — a GitHub-native stacking tool; passes unknown commands through to `git`.
- **Sapling** (`sl`, Meta) — powerful but replaces git commands wholesale; no bundled review UI.
- **GitHub native Stacked PRs** — **shipped to private preview April 2026.** This is the big one for an AI harness:
  GitHub now has a first-party `gh stack` CLI (`gs init` / `gs add` / `gs push` / `gs submit`), a native "stack map"
  UI, simultaneous merge of ready layers, and **auto-rebase of the rest on merge**. Critically, it ships an **agent
  skill**: `gh skill install github/gh-stack` teaches Claude Code / Codex / Cursor to *create and manage stacks as
  part of an agentic workflow* — including taking one large branch diff and splitting it into a stack. By early 2026
  developers were already prompting agents to "break this feature into stacked PRs, each under 200 lines, each doing
  one logical thing that makes sense on its own."

Sources: [Stacked Diffs — The Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/stacked-diffs),
[Stacked diffs — Graphite guide](https://graphite.com/guides/stacked-diffs),
[GitHub Stacked PRs (gh-stack)](https://github.github.com/gh-stack/),
[Stacked PRs Meet Coding Agents — Codex Blog](https://codex.danielvaughan.com/2026/04/16/stacked-prs-coding-agents-gh-stack-sapling-codex-skill/),
[GitHub adds Stacked PRs to speed complex code reviews — InfoWorld](https://www.infoworld.com/article/4158575/github-adds-stacked-prs-to-speed-complex-code-reviews/).

## 5. Branching — trunk-based development and "one PR = one reviewable idea"

**Trunk-based development (TBD).** Everyone integrates into one shared branch (`main`/trunk) frequently. Work happens
on **short-lived branches** — DORA's research defines "short-lived" as **under one day**; the healthy pattern is
"branch in the morning, merge by end of day." A branch that lives longer than a couple of days is drifting toward a
long-lived feature branch, which TBD explicitly rejects (long-lived branches mean big, painful, conflict-prone
merges — the exact opposite of small reviewable PRs).

**One developer per branch** (or two, pairing). The review cycle has to be **fast — hours, not days** — or branches
pile up faster than they merge.

**"One PR = one reviewable idea."** The governing principle: a PR should express exactly one coherent intention. If a
change can't be done in roughly a day (including review and QA), it gets **split** — into stacked PRs, or into a
refactor PR followed by a feature PR (this is the "two hats" rule as a *branching* strategy — see §6), or into
shippable steps behind a feature flag. Recent commentary is explicit that **TBD + short-lived branches is the sweet
spot precisely now that AI coding agents are in the loop**, because agents generate change fast and the only way to
keep `main` releasable is to keep each integrated unit small and frequent.

Sources: [Short-Lived Feature Branches — trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/short-lived-feature-branches/),
[Trunk-based Development — Atlassian](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development),
[How we do trunk-based development — PostHog](https://posthog.com/product-engineers/trunk-based-development).

## 6. The senior/staff mental model — how they actually decompose a feature

The numbers above are *what*; this is the *how*. Experienced engineers don't think "write feature, then chop it into
commits." They decompose **before** writing, along these axes:

- **Vertical slices, not horizontal layers.** A junior (and an unsupervised AI) builds horizontally: all the schema,
  then all the data layer, then all the UI — nothing works until the last layer lands, and nothing is reviewable
  until then. A senior builds **vertically**: one thin slice that goes through *every* layer and actually works
  end-to-end, then widens. Each slice is independently shippable and independently reviewable.
- **Tracer bullets** (from *The Pragmatic Programmer*). Build the smallest end-to-end path first — it "lights up" the
  whole architecture, gets feedback fast, and proves the approach before you invest in breadth. Our `/feature` skill
  already enforces this and explicitly notes that "AI's natural inclination is to build horizontal layers in
  isolation. You are here to enforce the opposite."
- **Two hats** (Kent Beck). At any moment you wear exactly one hat: the **structure hat** (refactor — change shape,
  not behavior) or the **behavior hat** (add/change what the system does). Never both in one commit. So a feature
  that needs groundwork becomes: *refactor PR/commit to make room* → *feature PR/commit that uses the room*. The
  reviewer of the refactor verifies "behavior unchanged"; the reviewer of the feature verifies "new behavior
  correct." Mixing them forces the reviewer to do both at once and they do neither well.
- **Keep `main` always-releasable.** Every slice that lands leaves `main` shippable. This is what makes small,
  frequent merges safe — you're never in a "half a feature is on main and it's broken" state. Feature flags hide
  not-yet-complete UI while the plumbing lands incrementally.

The senior's decomposition output is therefore: an ordered list of vertical slices, each one a tracer-bullet-sized
unit of behavior, each one (or each small group) a PR under ~400 lines, sequenced so a reviewer reads them as a
story and `main` stays green the whole way.

Sources: [The stacking workflow — stacking.dev](https://www.stacking.dev/),
[Tracer bullets / Pragmatic Programmer — as encoded in our `/feature` skill],
[Continuous Code Review — trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/continuous-review/).

---

# PART 2 — Applying this to the V2 AI harness

Our harness already has strong bones. The job here is to (a) name what's already correct so we don't re-litigate it,
(b) state the *commit + PR structure doctrine* explicitly as a rule the AI follows, and (c) identify the **one real
gap** — stacked PRs — and specify how it fits our worktree + review pipeline.

## 7. What our doctrine already covers (do not change — confirm and keep)

| Best practice (Part 1) | Where it already lives in our harness |
|---|---|
| Atomic commit = one logical change, working state | TDD rule: one-behavior → one-test → one-implementation → **one commit**; pre-commit hook keeps each commit green (lint + `tsc` + tests). |
| Structure ≠ behavior in one commit | **Two-hats rule** (CLAUDE.md → Refactoring; `/behavior-change` and `/refactor` skills enforce the split). |
| Conventional commits with a real "why" | CLAUDE.md → Commit workflow: `type(scope): desc` + **required body** stating *why*. |
| Clean `main` history | **Squash-merge to main** — one commit per logical change. |
| Vertical slices / tracer bullets, not horizontal layers | `/feature` Step 0 sizing + tracer-bullet rule; `/tdd` enforces vertical slices. |
| Short-lived, single-author branches | One worktree per task (`scripts/worktree-add.sh`); `/queue` gives each task its own branch; CLAUDE.md forbids two sessions sharing a branch. |
| Review before merge | `/cr` (9-pass + adversarial) gated by the un-fakeable `.cr-ok` sentinel consumed by `scripts/pr.sh`. |
| Decompose large features into independent units | `/feature` sizes Tiny/Small/Medium/Large and decomposes Medium+ via `/to-issues` into parallel worktree slices; `/queue` runs them. |

**Verdict: ~85% of the senior/staff playbook is already enforced — and enforced by *hooks and sentinels*, not just
prose, which is stronger than most human teams.** The gaps are specific and additive, below.

## 8. What to ADD

### Gap A (the big one): a stacked-PR path for sequential, dependent slices

Our current decomposition has a blind spot. `/feature` + `/queue` decompose a Medium+ feature into **parallel,
independent** slices — different files, no shared dependency — and runs them as concurrent worktrees, each opening
**its own PR to `main`**. That's perfect when slices are independent. But many real features decompose into a
**dependency line**, not a parallel fan-out:

```
migration (schema) → data-layer function → server action → UI
```

Here slice 2 *needs* slice 1's code to exist. Today the harness has two bad options: (1) cram the whole line into one
worktree and open **one large PR** (violates §3 — the review cliff), or (2) force-fit it into the parallel model where
it doesn't belong (slice 2's PR won't compile without slice 1). **Stacked PRs are the missing third option**, and
they map cleanly onto what we already have.

**The doctrine to adopt:**

- **`/feature` decompose classifies each slice-set as PARALLEL or SEQUENTIAL.** `/to-issues` already labels parallel
  vs. sequential — promote that label to *decide the merge vehicle*:
  - **PARALLEL (independent slices)** → today's model unchanged: one worktree per slice, each opens its own PR to
    `main`, `/queue` runs them concurrently.
  - **SEQUENTIAL (dependency line)** → **a stack of PRs**: one branch per slice, each based on the previous, each a
    single reviewable idea under ~400 lines.
- **Tooling: adopt GitHub native Stacked PRs + the agent skill.** This is the decisive 2026 development. Run
  `gh skill install github/gh-stack` once so the harness can drive `gh stack` (`gs init` / `gs add` / `gs push` /
  `gs submit`). The skill is *designed* for agents to create and manage stacks — exactly our use case. (When the
  feature exits private preview; until then, stacks can be created manually by setting each PR's base to the branch
  below it.) This keeps us on first-party GitHub tooling rather than adding a third-party dependency (Graphite/
  Sapling), consistent with the V2 "GitHub as the spine" direction in `github-usage.md`.
- **Each layer in the stack still runs the full slice loop** — TDD, `/simplify`, and **its own `/cr` + `.cr-ok`
  sentinel**. The sentinel is per-branch:per-sha, so it already works for a stack; each stacked branch gets reviewed
  and certified independently before its PR opens via `scripts/pr.sh`. Nothing in the sentinel mechanism needs to
  change — only the orchestration that opens N stacked PRs instead of N parallel ones.

**How stacking interacts with squash-merge.** Each stacked PR squash-merges to `main` as one clean commit, bottom-up,
exactly like a normal PR — so our clean-`main` policy is preserved. GitHub's native stacking auto-rebases the
remaining stack as each bottom PR lands, which removes the rebase-churn objection that makes manual stacking painful.

### Gap B: write the "why" from the design contract, not from the diff

The harness already requires a commit body. Tighten *what goes in it*: the AI has unique leverage here because it
**already produced the design contract, the rejected alternatives, and the compound-question answers** ("hardest
decision," "alternatives rejected," "least confident about"). Those are *exactly* the "why" a senior writes by hand.
**Doctrine: the commit/PR body is populated from the design contract + compound answers, not re-derived from the
diff.** This makes our "why" better than a typical human's, for free — and it's the single highest-leverage thing the
AI can do to speed review (see §10).

### Gap C: a hard PR-size budget with an explicit escape hatch

We have a sizing step but no *line budget* on the resulting PR. Add one, with the research number:

- **Target ~200 lines, soft cap ~400 lines** of substantive change per PR (exclude generated files, lockfiles,
  snapshots from the count).
- If a single slice's PR would exceed ~400 lines, that is the **trigger to stack** (Gap A), not to ship a big PR.
- The escape hatch is explicit, not silent: if the AI believes a >400-line PR is genuinely indivisible (e.g. a
  single generated migration, a mechanical rename touching many files), it must **say so in the PR body and name why
  it can't be split** — surfaced to the human as a NEEDS-HUMAN, never waved through. ("Indivisible" is a claim a
  human approves, not one the AI grants itself — mirrors our existing anti-rationalization posture.)

### Gap D (small): commit-sequence sanity in `/cr`

`/cr` reviews the *full branch diff*. Add a light check that the **commit sequence reads as a story**: each commit
atomic, no commit mixing structure+behavior (two-hats), no "fix typo / address review" noise that should have been
squashed into its parent before review. This is cheap (it's reading `git log --oneline main..HEAD`, which `/cr`
already gathers in Step 1) and it protects the property that makes branch review fast: the reviewer can read commits
in order instead of the whole blob.

## 9. The decision rule — single small PR vs. a stack

A compact rule the harness can apply mechanically at decompose time:

```
Size the feature (/feature Step 0).
├─ Tiny / Small, fits in ≤ ~400 lines        → ONE small PR. (today's path, unchanged)
└─ Medium / Large (won't fit in one PR)       → decompose into slices, then:
   ├─ slices are INDEPENDENT (parallel)       → N parallel PRs to main, run via /queue
   │                                            (different files, no shared dep — today's path)
   └─ slices form a DEPENDENCY LINE (B needs A)→ STACK of small PRs (gh stack),
                                                 each ≤ ~400 lines, each its own /cr + sentinel,
                                                 squash-merged bottom-up into main
```

Plain-language version: **default to one small PR. Go parallel when the pieces don't depend on each other. Go stacked
when they do and the whole thing won't fit under ~400 lines.** Never the fourth option — one giant PR — without an
explicit, human-approved "indivisible" justification.

## 10. Why this makes human review FAST and effective (the whole point)

Tie it back to the thesis. Every rule above converts directly into reviewer speed and confidence:

- **Small PRs (≤~400 lines)** keep the reviewer inside the window where they catch 70–90% of defects instead of ~28%
  — and where they *actually review* instead of skimming (the 3× thoroughness effect). A reviewer can confidently
  approve a 200-line PR in minutes; a 2,000-line PR gets a glance and a rubber stamp. Small is the difference between
  *reviewed* and *not really reviewed*.
- **Atomic commits in a story sequence** give the reviewer a table of contents. They read the branch as setup → step
  → step → cleanup and follow the reasoning, instead of reverse-engineering intent from one giant squashed diff.
- **A real "why" in every body** answers the reviewer's first question before they ask it ("why is this like this?
  what was rejected?"). Because the AI populates it from the design contract, the reviewer gets context a human
  author often omits under deadline.
- **Two-hats separation** lets the reviewer verify one property per commit — "behavior unchanged" *or* "new behavior
  correct" — never both tangled together, which is where reviewers miss bugs.
- **Stacked PRs** turn an un-reviewable 1,500-line feature into five ~300-line reviews that can each be approved
  fast, can be reviewed *in parallel with later layers still being written*, and each keep `main` releasable.
- **A clean, squash-merged `main`** means the *next* reviewer (and `git bisect`, and the future debugger) reads
  `main` as a list of shippable decisions, not a transcript.

The harness's deepest leverage: an AI can do **all** of this *consistently, every time, by rule* — small PRs, atomic
commits, real "why," correct merge vehicle — which is exactly the discipline human teams know they should follow and
routinely abandon under deadline pressure. The bottleneck is review; this doctrine is how the harness spends the
reviewer's attention well.

---

## 11. Concrete additions, summarized (the change list)

1. **Stacked-PR path** for SEQUENTIAL slice-sets in `/feature` decompose + `/queue`; adopt GitHub native Stacked PRs
   and `gh skill install github/gh-stack`; keep per-branch `.cr-ok` and squash-merge unchanged. *(Gap A — the main
   addition.)*
2. **Body-from-contract rule**: populate commit/PR "why" from the design contract + compound answers, not the diff.
   *(Gap B)*
3. **PR-size budget**: target ~200, soft cap ~400 substantive lines; exceeding it triggers a stack, not a big PR;
   "indivisible" is a human-approved NEEDS-HUMAN claim. *(Gap C)*
4. **Commit-sequence check in `/cr`**: verify the commit log is atomic, two-hats-clean, and reads as a story.
   *(Gap D)*

Everything else in Part 1 is **already enforced** by our hooks, sentinels, and skills (§7) and should be confirmed,
not rebuilt.

---

## Sources (consolidated)

- [Modern Code Review: A Case Study at Google — ICSE 2018](https://sback.it/publications/icse2018seip.pdf)
- [Characteristics of Useful Code Reviews — Microsoft Research](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/bosu2015useful.pdf)
- [SmartBear/Cisco code review study, summarized — Graphite](https://graphite.com/blog/code-review-best-practices)
- [Does PR size actually matter? — cubic](https://www.cubic.dev/blog/does-pr-size-actually-matter)
- [The Hidden Cost of Slow Code Reviews: 8M PRs — Petrenko](https://vitalii4reva.medium.com/the-hidden-cost-of-slow-code-reviews-data-from-8-million-prs-9926849f1428)
- [A Developer's Guide to Atomic Git Commits — Dzneladze](https://medium.com/@sandrodz/a-developers-guide-to-atomic-git-commits-c7b873b39223)
- [Atomic commits — gitbybit](https://gitbybit.com/gitopedia/best-practices/atomic-commits)
- [Atomic Commits Explained — PHP Architect](https://www.phparch.com/2025/06/atomic-commits-explained-stop-writing-useless-git-messages/)
- [Building Code Quality Culture Through Commit Standards — victoria.dev](https://victoria.dev/posts/building-code-quality-culture-through-commit-standards/)
- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Conventional Commits — Marc Nuri](https://blog.marcnuri.com/conventional-commits)
- [Commit Message Best Practices — Commitizen](https://commitizen-tools.github.io/commitizen/tutorials/writing_commits/)
- [Stacked Diffs — The Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/stacked-diffs)
- [Stacked diffs — Graphite guide](https://graphite.com/guides/stacked-diffs)
- [GitHub Stacked PRs (gh-stack)](https://github.github.com/gh-stack/)
- [GitHub adds Stacked PRs to speed complex code reviews — InfoWorld](https://www.infoworld.com/article/4158575/github-adds-stacked-prs-to-speed-complex-code-reviews/)
- [Stacked PRs Meet Coding Agents — Codex Blog](https://codex.danielvaughan.com/2026/04/16/stacked-prs-coding-agents-gh-stack-sapling-codex-skill/)
- [Short-Lived Feature Branches — trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/short-lived-feature-branches/)
- [Trunk-based Development — Atlassian](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development)
- [How we do trunk-based development — PostHog](https://posthog.com/product-engineers/trunk-based-development)
- [The stacking workflow — stacking.dev](https://www.stacking.dev/)
