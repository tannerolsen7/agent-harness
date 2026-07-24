# Property-test coverage gate (VISION C11 / killlist §C #4)

**What it is (plain):** if a change touches invariant-critical logic — money math, totals,
tax, discounts, anything with a rule that must hold for *all* inputs — it must be covered by
a **property test**. A property test asserts an invariant the model cannot argue with and
generates hundreds of adversarial inputs against it, so it is the one correctness check an
autonomous loop cannot quietly weaken. This gate is the deterministic backstop that a
declared invariant module never merges without one.

**Project-agnostic:** the harness never hardcodes what counts as "invariant-critical" or which
files count as property tests. It also does not ship the property tests themselves, or a
property-testing library (like `fast-check`) — the harness is shell + markdown and has no app
to test. The project declares its invariant modules and their property tests in
`.claude/property-invariants.json`. With no config, the gate is inert.

This is the enforcement leg of the property-based-testing capability. The other half — the
actual property tests and their human-authored invariant set — lives in the consuming
product's own code, because that is where the money math is.

## How the check works

`scripts/property-test-gate.sh`:
1. Reads `.claude/property-invariants.json` — a list of invariants, each with a `modulePattern`
   (which files are invariant-critical) and a `testPattern` (which files count as that
   invariant's property tests). Both are regular expressions matched against file paths.
2. Computes the changed files (branch vs. base, or the test-override list).
3. For each invariant: if a **changed** file matches its `modulePattern`, at least one
   **committed** file must match its `testPattern`. Existence in the committed tree is enough —
   a change to already-covered logic is not forced to re-edit the property test.
4. If an invariant module changed with no matching property test present, the gate **blocks**
   (exit 1) and names the invariant, the file that triggered it, and the pattern to satisfy.

**What it does and does not prove.** A pass means *a property-test file exists for the module*
— existence only. It does **not** prove the test asserts the right invariant or would catch a
break; `scripts/mutation-test.sh` is the companion that proves that (it breaks the code and
confirms a test goes red). The gate's success message says so, so a green check is not misread
as "verified."

**Matching is case-insensitive** so a lowercase pattern still catches a PascalCase file
(`tax` matches `TaxCalculator.ts`) — for a safety gate, over-detecting a module is safer than
silently missing one. Patterns are **POSIX Extended Regular Expressions** (`grep -E`), not
JS/PCRE — `\d`, lookahead/lookbehind, and non-greedy quantifiers are not supported.

**Fail-closed.** A present-but-broken config is a setup error, never an opt-out. All of these
**block** (exit 2): missing `node`; malformed JSON; a missing `invariants` array; an invariant
with a missing, empty, or non-string `modulePattern`/`testPattern`; a pattern equal to the
other pattern (the module would satisfy its own coverage); a tab or newline inside a pattern;
an invalid regex; a git failure; an unresolvable base ref; or a base that already contains HEAD
(a stale, unfetched base would make the diff empty and pass silently). A `modulePattern` that
matches no committed file prints a non-blocking **warning** (a likely typo). The gate is inert
(exit 0) only when the config file is absent, and prints a distinct "0 invariants declared"
message when the array is empty, so an accidentally-emptied config is visible.

## Config format

`.claude/property-invariants.json`:

```json
{
  "invariants": [
    {
      "name": "pricing",
      "modulePattern": "(^|/)src/(utils|schemas)/.*pric",
      "testPattern": "(^|/)src/(utils|schemas)/.*pric.*\\.(prop|property)\\.(test|spec)\\."
    },
    {
      "name": "tax",
      "modulePattern": "(^|/)src/(utils|schemas)/.*tax",
      "testPattern": "(^|/)src/(utils|schemas)/.*tax.*\\.(prop|property)\\.(test|spec)\\."
    }
  ]
}
```

`name` is used only in messages. `modulePattern` and `testPattern` are regexes over file
paths. **Give each invariant one concept.** Bundling several (e.g. `pric|total|tax|discount`
in one invariant) weakens the guarantee to "*some* test for the group exists," so a `discount`
test would satisfy a `pricing` change — declare them separately, as above, to keep it
per-module. The `testPattern` requires a `.property.` (or `.prop.`) marker so an ordinary unit
test does not accidentally satisfy the coverage rule, and it must differ from `modulePattern`
(an identical pattern is rejected, since the module file would satisfy its own coverage).

## Wiring it into a project

The harness ships the script; a consuming project turns it on:

1. **Add the config.** Create `.claude/property-invariants.json` with your invariant modules
   and property-test patterns.
2. **Wire the gate into CI** — this is the canonical, merge-time home, matching `check-routing.sh`.
   Add `bash scripts/property-test-gate.sh` to the project's CI verify step (e.g. alongside
   `check-routing.sh` in `ci-verify.sh`), so it runs against the exact head commit on a machine
   the agent cannot touch. (The gate is host-agnostic; it reads `GITHUB_BASE_REF` /
   `CI_MERGE_REQUEST_TARGET_BRANCH_NAME` or falls back to `origin/main`.) You *may* also add it
   to `.husky/pre-push` for faster local feedback, but treat CI as the real gate — a local
   `origin/main` can be stale, which the base-ref checks guard against by failing closed.
3. **Add the PITFALLS rule to *your* project.** In the consuming project's `PITFALLS.md`, record
   "changes to invariant-critical modules require a property test" so `/cr` flags an uncovered
   change even before the gate runs. This rule is project-specific and does not live in the
   harness's own `PITFALLS.md`.
4. **Write the property tests.** Using your project's property-testing library (e.g.
   `fast-check`), assert the human-authored invariants — for money math: `total = sum(line
   items)`; tax is never applied to service fees; no negative line/sub totals; integer-cents
   round-tripping is exact. Installing that library is a project dependency decision (ask
   before adding it), separate from this gate.

## Why existence, not "must be edited"

The rule checks that a matching property test **exists in the committed tree**, not that it was
edited in the same change. A pure refactor of pricing that keeps behavior identical should not
be forced to touch the property test. The coverage guarantee is "this invariant-critical module
has a property test at all" — the "did the test actually catch a break?" question is answered by
a separate layer (mutation testing, `scripts/mutation-test.sh`), which deliberately breaks the
code and confirms a test goes red. A file that is only staged (not committed) does not count —
the gate reads committed state so its verdict matches what a push actually contains.
