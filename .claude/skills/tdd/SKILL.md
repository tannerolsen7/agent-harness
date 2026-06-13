---
name: tdd
description: Implements a confirmed behavior using red-green-refactor with
  vertical slices. Use when the user says "/tdd", "implement this", "write
  the code for", "build this slice", or "make this test pass". Requires a
  confirmed behavior in docs/TESTING.md before starting. One behavior = one
  test = one implementation = one commit. Never batches multiple behaviors.
---

# TDD — Vertical Slice Red-Green-Refactor

## The loop — Canon TDD (specify → encode → fulfill)

This skill is the Canon TDD loop. Every slice moves through three named moves, in order:

1. **Specify** — state the one behavior you are about to build, drawn from docs/TESTING.md or the user (never from the implementation).
2. **Encode** — write that behavior as a single failing test (red). Run it; confirm it fails for the right reason.
3. **Fulfill** — write the minimum code to make the test pass (green). Run it; confirm it passes. Refactor only if genuinely needed.

Hold to this named loop. The behavioral rules below serve the loop — they are not a substitute for it.

---

## Anti-rationalization (read before proceeding)

| Rationalization | Rebuttal |
|---|---|
| "I'll write the test after the implementation" | There is no after. A test written after implementation is a transcription, not a spec. Write the failing test first. |
| "This function is too simple to need a test" | Simple functions break in simple ways. One edge case, one null, one wrong type. Write the test. |
| "I can't write the test first because I don't know the interface yet" | Then you're not ready to implement. Stop and design the interface first. |
| "Tests pass, so it's correct" | Passing tests prove the behaviors you tested. Did you test the right behaviors? |

---

## Step 0 — The rule that prevents the most common failure

**No transcription tests.** Expected behavior comes from `docs/TESTING.md`
or from the user — never from reading the implementation. Reading the code
to derive expected values produces tests that pass even when behavior is wrong.

---

## Step 1 — Confirm the behavior before touching code

- Find the target behavior in `docs/TESTING.md` → confirmed behaviors
- If not there: **stop and ask the user** before proceeding
- Add the confirmed behavior to `docs/TESTING.md` before writing any test
- If this is a bug fix: write the behavior as it SHOULD work, not as it does

---

## Step 2 — Design the interface

Before writing the first test, confirm the public interface (function signature,
server action, data function, schema, etc.).

Read the target source file and adjacent tests to understand:
- The existing interface shape
- Test infrastructure already in place (see `docs/TESTING.md` → Mock infrastructure)
- `PITFALLS.md` entries that apply to this area
- Relevant `docs/solutions/` entries

Tests written through the wrong interface have to be rewritten from scratch.

---

## Step 3 — Decompose into vertical slices

Break the feature into the smallest independently-shippable behaviors.
One behavior = one slice = one commit.

Each slice must be completable in one loop iteration and provable by a single test.

**Examples of correctly-sized slices:**

| Too large | Right size |
|---|---|
| "Add the user-profile feature" | "Return null from getUser when the id is not found" |
| "Fix all validation edge cases" | "Reject an access token shorter than 8 characters" |
| "Refactor the orders data layer" | "Extract computeOrderTotal into a standalone pure function" |

---

## Step 4 — Loop: one vertical slice at a time

**Repeat until the feature is complete. Do not batch tests. Do not batch code.**

For each slice:
1. Pick the next slice from the decomposition
2. Write the confirmed expected behavior as a comment before the test
3. Write the test for this ONE slice (it should fail — red)
4. Run `npx vitest run <test-file>` — confirm it fails for the right reason
5. Write minimum code to make this test pass (green) — nothing more
6. Run again — confirm it passes
7. Refactor only if genuinely unclear or obvious duplication from this slice
8. Commit test + implementation together as one atomic commit
9. → Next slice

**Key discipline:** do not write the next test until the previous slice is committed.

---

## Step 5 — Test patterns for this codebase

- **Never mock the database / backend.** Integration tests for the data-access layer hit a real test database, per the project's test setup — not a mock.
- **Seed rows via the project's admin/seed client** in `beforeAll` when no app-level write function exists yet for the table.
- **Spy sparingly.** Error paths that cannot be triggered organically (e.g. an auth-service failure) may use a narrow `vi.spyOn` on that one boundary — the only accepted spy pattern. Never spy to fake the behavior under test.
- **Pure functions** (utils, schemas, domain logic) need no infrastructure — test directly with inputs and expected outputs.
- See `docs/TESTING.md` → Mock infrastructure for established patterns before inventing new ones.

---

## Step 6 — Update TESTING.md after each slice

After the slice's test passes:
1. Add the behavior to the "What's tested today" table
2. Remove it from "Known test gaps" if fully covered
3. If previously unconfirmed, move from "Code-observed" to "Confirmed behaviors"