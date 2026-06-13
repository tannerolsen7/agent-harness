# The bug-catch test

**What it is (plain):** a pile of code with bugs deliberately hidden in it. We ask the robot's
reviewer to review each piece and count how many planted bugs it finds. That percentage is the
**catch rate**. It is the measuring stick that tells us how good the review actually is.

**Why it exists:** later we want to *simplify* the review (`/cr` runs 9 separate analytical
passes; the plan is 1 strong pass + free deterministic checks). We only allow that simplification
**if the catch rate does not drop** (R4-D20, R4-D32 #1). So the measuring stick is built *first*,
before the review is touched. It also measures the risk-classifier (do "looks-trivial-but-isn't"
cases get caught? — R4-D32 #5).

## Layout

```
bug-catch/
  cases/NNN-slug.md   one planted bug each: frontmatter (id, category, severity, bug, catch,
                      holdout) + the code under review
  score.sh            reads a results TSV → catch rate + a conservative lower bound
  results/            run outputs (gitignored); one TSV per run: "<case-id>\t caught|missed"
```

## How a run works (the model-in-the-loop part)

Scoring requires actually running the reviewer on each case — that uses the model, so a full run
costs tokens. Run it occasionally (before/after a review change), **not** every commit.

1. For each case in `cases/`, show **only the code block** to the reviewer (the real `/cr` analytical
   review, or a single representative review pass) — never show the frontmatter (it names the bug).
2. Decide **caught** vs **missed**: caught = a finding clearly identifies the planted bug as
   described in the case's `catch:` line. A vague or unrelated finding does not count.
3. Append `‹case-id›␉caught` or `‹case-id›␉missed` to `results/‹run›.tsv`.
4. `bash bug-catch/score.sh results/‹run›.tsv` → prints `n`, `caught`, `recall`, and the
   **95% Wilson lower bound**.

## The gate (how it protects the collapse)

Gate on the **lower bound**, never the point estimate — a small real drop hides in luck on a
small set (R4-D32 #1). To allow a review change: run the test **before**, apply the change, run
**after**; keep the change only if the after lower-bound is **not below** the before lower-bound.
`score.sh` prints the number; the before/after comparison is the gate.

## Honesty rules (from the plan)

- **Real bugs beat invented ones.** Bugs the robot would imagine are bugs it already catches —
  that inflates recall. This repo has no history yet, so these seed cases are common *universal*
  bug patterns to bootstrap the machine. **Every escaped bug (found post-merge) becomes a new
  case** — that is how the set grows honest, toward the ~80–100 the plan wants (auto-grow).
- **Hold some out.** Cases with `holdout: true` are never tuned against (anti-Goodhart). Rotate
  which ones are held out over time.
- **Plant bugs from a different source than the reviewer** where possible (avoids shared blind
  spots).

## Auto-grow (a missed bug → a new case)

When a bug escapes review and is found later, add a `cases/NNN-slug.md` reproducing it (minimal
code + the `catch:` criterion). The set then permanently tests for that class. This is the
RECURRING-FINDINGS pipeline pointed at the reviewer.

## Status

Seed: a small starter set of universal patterns (target ~12–15 to start; grows to ~80–100 from
real escaped defects). Categories still to seed are listed at the bottom of this file as they are
added.
