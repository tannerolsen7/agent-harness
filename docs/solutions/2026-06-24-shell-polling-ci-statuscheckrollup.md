# Problem: Shell Polling Loops Lose Time and Misread CI Check State

**Problem class:** A script polls a long-running external operation (CI) after completing a gate sequence. The polling loop runs shorter than expected, silently misclassifies check results, and leaves a consumed gate sentinel in an unexpected state when the operation fails.

## When this bites you

You open a PR from a script. The script says it's waiting for CI. Fifteen seconds later it exits, declaring CI passed — or worse, declaring it failed on a check that was actually still running. You look at the PR: checks are still pending or show a different result than what the script reported.

Alternatively, CI genuinely fails. You fix the bug, try to re-run `pr.sh`, and it complains the `.cr-ok` sentinel is gone. You have to run the full code review again before you can retry the PR push.

Both outcomes are surprising because the script appeared to work — it ran to completion without errors.

## Root cause

Three independent issues compound:

**1. `SECONDS` is not a duration counter from script start.**
Bash's `SECONDS` builtin tracks elapsed time since the shell process started, not since the script started. If the script took 40 seconds to reach the polling loop, and the timeout is 600, the effective polling window is 560 seconds — but it varies unpredictably depending on how long the preceding steps took. On a fast machine where the PR creates in two seconds, you get nearly the full window. On a slow network, you get much less. Resetting to zero (`SECONDS=0`) before the loop is the only way to guarantee a consistent window.

**2. GitHub's `statusCheckRollup` field has two record shapes, not one.**
The GraphQL field mixes two types:
- `CheckRun` records: use `status` (e.g., `"COMPLETED"`) and `conclusion` (e.g., `"FAILURE"`, `"TIMED_OUT"`).
- `StatusContext` records: use `state` in lowercase (e.g., `"failure"`, `"pending"`).

A jq filter written for one type silently skips the other. A repo using only `StatusContext` checks (common with older integrations or external status reporters) looks like it has no pending checks, causing the loop to exit `none` immediately. A repo mixing both types can report `passed` while a `StatusContext` check is still `"pending"`.

**3. The sentinel is consumed before polling starts, and intentionally stays consumed.**
The script clears its error trap and permanently deletes the `.cr-ok` sentinel as soon as the PR is created — before CI polling begins. If CI polling exits with failure, the sentinel is already gone. You cannot retry `pr.sh` without re-running `/cr` to produce a new sentinel. This is the correct behavior (the PR exists; the review is spent), but it is not obvious from reading the code.

## The fix

**Reset `SECONDS` before the polling loop (`scripts/pr.sh` line ~147):**

```bash
SECONDS=0
while [ "$SECONDS" -lt "$_CI_TIMEOUT" ]; do
  ...
  sleep 15
done
```

This gives the loop exactly `$CI_POLL_TIMEOUT` seconds (default: 600) regardless of how long the preceding steps took.

**Handle both GitHub check types in the jq filter (`scripts/pr.sh` line ~149):**

```bash
_CI_JQ='.statusCheckRollup // [] |
  if length == 0 then "none"
  elif any(.[]; (.__typename == "CheckRun" and .status == "COMPLETED"
      and (.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "STARTUP_FAILURE"))
    or (.__typename == "StatusContext" and (.state == "failure" or .state == "error")))
  then "failed"
  elif any(.[]; (.__typename == "CheckRun" and .status != "COMPLETED")
    or (.__typename == "StatusContext" and .state == "pending"))
  then "pending"
  else "passed"
  end'
```

`.__typename` is present in the response and lets you branch on the correct field names for each type.

**Add a skip escape hatch (`scripts/pr.sh` line ~138):**

```bash
if [ -z "${CI_POLL_SKIP:-}" ]; then
  ...polling loop...
fi
```

`CI_POLL_SKIP=1` lets tests and environments where the CI API is unavailable or unvalidated skip the loop without modifying the script.

## Why not poll before consuming the sentinel?

The sentinel must be consumed at the moment the PR is created, not at the moment CI passes. The sentinel records that a specific review ran against a specific commit. Once the PR exists, that review is spent — regardless of whether CI passes or fails. Holding the sentinel until CI finishes would create a false impression that the review can be reused after a CI failure.

The correct mental model: the `.cr-ok` sentinel authorizes creating the PR, not landing the branch. CI failure requires a new commit, a new review, and a new sentinel.

## What doesn't work

**Using `SECONDS` without resetting it:** The value at loop entry is unpredictable. On a fast machine in a test environment you might get nearly the full window. On a slow network you get much less. The difference is silent — the loop just exits earlier than expected.

**Filtering `statusCheckRollup` by `conclusion` alone:** `conclusion` is only populated on `CheckRun` records after they complete. Using it as the primary filter causes `StatusContext` checks to vanish — they have no `conclusion` field. The loop exits `passed` while external status checks are still pending.

**Filtering by `state` alone:** The inverse problem. `state` is only on `StatusContext` records. `CheckRun` records have `status` and `conclusion`. Filtering only on `state` misses all native GitHub Actions checks.

**Treating `none` as an error:** Some repos have no CI configured. The `none` case is normal and should exit cleanly, not fail or hang. The filter handles it by checking `length == 0` first.

**Polling without a timeout:** CI can be arbitrarily slow. Without `CI_POLL_TIMEOUT`, the script hangs indefinitely. The timeout plus a human-readable "still running" message lets automation move on while giving humans a URL to watch.

## Tags

ci-polling, sentinel, bash-SECONDS, statusCheckRollup, github-checks, jq, gate-ordering, CI_POLL_SKIP, CheckRun, StatusContext, pr-gate, shell-scripting
