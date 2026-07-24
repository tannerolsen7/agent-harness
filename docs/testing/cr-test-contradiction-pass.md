## /cr Pass 6 test contradiction check

Closes a gap where agents add tests for new behavior but never revisit
existing tests whose assertions the new behavior now contradicts. This is
already solved for work routed through `/behavior-change` (its Phase 3 test
inversion analysis), but `/cr` runs on every branch regardless of routing, so
it is the one checkpoint that can catch a stale, contradicted test no matter
which skill did the work.

### Confirmed behaviors

- **Pass 6 — Test Quality flags a test whose assertion the diff contradicts:**
  Given a diff that changes behavior without updating an untouched test in the
  same file/shard whose assertion the new behavior falsifies, `/cr` Pass 6
  reports a MUST FIX finding naming that test, its old assertion, and why the
  new behavior makes it wrong — with a recommended disposition (delete with
  reason / update the assertion / split into old-context and new-context
  cases).

- **Suspected-but-unconfirmed contradictions are advisory, not blocking:**
  Given a diff where Pass 6 suspects a test may now be wrong but cannot name
  the specific input/output that would prove it, the finding is reported as
  "Something to Think About," not MUST FIX — so an unconfirmed guess never
  blocks a merge.

- **`/behavior-change` cross-references the `/cr` backstop:** Phase 3 (test
  inversion analysis) in `/behavior-change` states that `/cr` Pass 6 performs
  the same contradiction check as a backstop for work misrouted through
  `/feature`, so a reader of either skill alone learns the other exists.
