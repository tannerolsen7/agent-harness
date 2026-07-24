## Property-test coverage gate (scripts/property-test-gate.sh)

Ships the enforcement leg of the property-based-testing capability (VISION C11 /
killlist §C #4) into the project-agnostic harness. The design docs specify "a
coverage-style blocker on the pricing module" — any change to invariant-critical
logic must be covered by a property test. The harness cannot ship the money-math
tests themselves (it has no app, no test framework, and cannot install
`fast-check`), so it ships the reusable gate that enforces the coverage. A
consuming project declares which modules are invariant-critical, and which files
count as their property tests, in `.claude/property-invariants.json`.

This is the same shape as the `database-safety-adapter` / `check-routing.sh`
extension point: the harness owns the check, the project owns the declaration,
and the gate is inert until the project opts in.

### Confirmed behaviors

- **No config → inert:** When `.claude/property-invariants.json` is absent, the
  gate exits 0 and prints that it is inert.

- **Empty invariants array → explicit no-op:** When the config is present with an
  empty `invariants` array, the gate exits 0 and prints "0 invariants declared —
  nothing enforced," distinct from the "all covered" message, so an accidentally
  emptied config is visible.

- **Invariant module changed with a matching property test present → pass:**
  When a changed file matches an invariant's `modulePattern` and at least one
  committed file matches that invariant's `testPattern`, the gate exits 0.

- **Invariant module changed with no matching property test → block:** When a
  changed file matches an invariant's `modulePattern` but no committed file
  matches its `testPattern`, the gate exits 1 and names the invariant, the file
  that triggered it, and the `testPattern` to satisfy.

- **No invariant module changed → pass:** When no changed file matches any
  invariant's `modulePattern`, the gate exits 0.

- **A plain unit test does not satisfy the gate:** A changed invariant module
  whose only test lacks the `.property.`/`.prop.` marker is blocked.

- **Matching is case-insensitive:** A lowercase `modulePattern` still matches a
  PascalCase path (e.g. `tax` matches `src/utils/TaxCalculator.ts`), so a
  money-math file is not silently missed on a naming-case difference.

- **A pattern beginning with `-` is treated as a regex, not a grep option:** An
  invariant whose `modulePattern` starts with `-` matches paths normally rather
  than erroring as an unknown option.

- **Multiple invariants are each enforced independently:** With more than one
  invariant declared, the gate blocks if any one touched module lacks its
  property test, and passes only when every touched module is covered.

- **Coverage is judged against committed state, not the index:** A property test
  that is staged but not committed does not count — the gate reads the committed
  tree (`git ls-tree HEAD`), matching the committed diff, so its verdict reflects
  what a push actually contains.

- **A stale base that already contains HEAD → fail-closed:** When the resolved
  base ref already contains HEAD (which would make the diff empty and pass
  silently), the gate exits 2 rather than passing.

- **A modulePattern matching no committed file → non-blocking warning:** A likely
  typo (wrong path, case, or anchor) that would make an invariant never fire
  prints a warning to stderr but does not block, since a project may declare an
  invariant for a module it has not created yet.

- **Malformed or invalid config → fail-closed (block):** The gate exits 2 when
  the config is not valid JSON, is missing the `invariants` array, has an
  invariant with a missing/empty/non-string `modulePattern` or `testPattern`, has
  identical `modulePattern` and `testPattern` (the module would satisfy its own
  coverage), has a tab or newline inside a pattern (which would corrupt parsing),
  or contains a pattern that is not a valid regular expression.

- **Missing node → fail-closed (block):** When the config is present but `node`
  is not available, the gate exits 2 rather than skipping the check.
