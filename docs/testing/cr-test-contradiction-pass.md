## /cr Pass 6 test contradiction check

Closes a gap where agents add tests for new behavior but never revisit
existing tests whose assertions the new behavior now contradicts. This is
already solved for work routed through `/behavior-change` (its Phase 3 test
inversion analysis, which sweeps every test that exercises the changed
behavior across the whole suite), but that phase only runs when work is
routed there. `/cr` runs on every agent-driven push regardless of routing, so
it acts as a partial, narrower-scoped backstop — checking only the files and
shards a diff already touches — for the case where work was routed through
`/feature` instead.

### Confirmed behaviors

- **Pass 6 — Test Quality's prompt instructs the reviewer to flag a test
  whose assertion the diff contradicts, scoped to touched files/shards:**
  Given a diff that changes behavior without updating an untouched test in a
  file the diff touches, or in a test file that implements a shard entry the
  diff touches, whose assertion the new behavior falsifies, the Pass 6
  instruction directs the reviewer to report a MUST FIX finding naming that
  test, its old assertion, and why the new behavior makes it wrong — with a
  recommended disposition (delete with reason / update the assertion / split
  into old-context and new-context cases). This confirms the instruction text
  is present and correctly scoped — not that a live reviewer run was
  observed catching a real contradiction.

- **Suspected-but-unconfirmed contradictions are advisory, not blocking:**
  The Pass 6 instruction directs the reviewer to report a suspected-but-
  unpinned contradiction as "Something to Think About," not MUST FIX — so an
  unconfirmed guess never blocks a merge.

- **`/behavior-change` cross-references the `/cr` Pass 6 partial backstop:**
  Phase 3 (test inversion analysis) in `/behavior-change` states that `/cr`
  Pass 6 performs a narrower version of the same contradiction check — scoped
  to touched files/shards, and only on agent-driven pushes — as a partial
  backstop for work misrouted through `/feature`, so a reader of either skill
  alone learns the other exists and knows the coverage differs.
