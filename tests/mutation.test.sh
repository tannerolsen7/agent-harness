#!/usr/bin/env bash
# Tests for scripts/mutation-test.sh.
#
# Each test creates a tiny synthetic implementation file and a matching test command,
# then runs mutation-test.sh against them. The tests verify:
#
#   1. delete-body mutation is generated correctly (function body gets replaced).
#   2. negate-exit mutation is generated correctly ("exit 1" becomes "exit 0").
#   3. swap-return mutation is generated correctly ("return 0" becomes "return 1").
#   4. A real test that checks return value catches the swap-return mutation (KILLED).
#   5. A vacuous test that always passes lets the swap-return mutation SURVIVE.
#   6. Missing --files argument with no default targets exits non-zero.
#   7. --help exits 0 and prints usage.
#
# No network access, no real test-suite runs — each test supplies its own --test-cmd
# so the harness tests are never invoked during this unit check.
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MTEST="$ROOT/scripts/mutation-test.sh"

[ -f "$MTEST" ] || { echo "mutation.test: $MTEST not found"; exit 1; }
[ -x "$MTEST" ] || { echo "mutation.test: $MTEST not executable"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

TMP=$(mktemp -d)

# ── Helper: write a minimal shell script to $TMP/<name> ───────────────────────

write_impl() { # <name> <content>
  local name="$1" content="$2"
  printf '%s\n' "$content" > "$TMP/$name"
  chmod 755 "$TMP/$name"
}

# ── 1. delete-body mutation output ───────────────────────────────────────────

write_impl "impl_body.sh" '#!/usr/bin/env bash
do_work() {
  echo "real work"
  return 0
}
do_work'

# Source the mutation function directly by pulling it out of the script.
# Easier: just run mutation-test.sh and confirm the mutant differs.
# We use a test-cmd that always fails ("exit 1") so we can confirm
# mutation-test.sh sees the mutation and reports KILLED (not skipped).
out=$(bash "$MTEST" \
  --files "$TMP/impl_body.sh" \
  --test-cmd "exit 1" 2>&1)
if printf '%s\n' "$out" | grep -q 'delete-body.*killed'; then
  ok
else
  no "delete-body mutation should be KILLED when test-cmd always fails (got: $out)"
fi

# ── 2. negate-exit mutation output ────────────────────────────────────────────

write_impl "impl_exit.sh" '#!/usr/bin/env bash
guard() {
  if [ -z "$1" ]; then
    exit 1
  fi
  echo ok
}
guard "$@"'

out=$(bash "$MTEST" \
  --files "$TMP/impl_exit.sh" \
  --test-cmd "exit 1" 2>&1)
if printf '%s\n' "$out" | grep -q 'negate-exit.*killed'; then
  ok
else
  no "negate-exit mutation should be KILLED when test-cmd always fails (got: $out)"
fi

# ── 3. swap-return mutation output ────────────────────────────────────────────

write_impl "impl_return.sh" '#!/usr/bin/env bash
check() {
  return 0
}
check'

out=$(bash "$MTEST" \
  --files "$TMP/impl_return.sh" \
  --test-cmd "exit 1" 2>&1)
if printf '%s\n' "$out" | grep -q 'swap-return.*killed'; then
  ok
else
  no "swap-return mutation should be KILLED when test-cmd always fails (got: $out)"
fi

# ── 4. A real test CATCHES the swap-return mutation ────────────────────────────
# The implementation returns 0. The test checks that it returns 0.
# After the mutation flips it to return 1, the test fails → KILLED.

write_impl "impl_checked.sh" '#!/usr/bin/env bash
status() {
  return 0
}'

# Write a test command that sources impl_checked.sh and asserts status() returns 0.
write_impl "test_real.sh" "#!/usr/bin/env bash
. $TMP/impl_checked.sh
status; rc=\$?
[ \$rc -eq 0 ] || exit 1"

out=$(bash "$MTEST" \
  --files "$TMP/impl_checked.sh" \
  --test-cmd "bash $TMP/test_real.sh" 2>&1)
if printf '%s\n' "$out" | grep -q 'swap-return.*killed'; then
  ok
else
  no "real test should KILL swap-return mutation (test checks return value) (got: $out)"
fi

# ── 5. A vacuous test LETS the swap-return mutation SURVIVE ───────────────────
# The test never calls the function, so it always passes even when the function
# is broken. This is the "always-pass" pattern mutation testing is meant to catch.

write_impl "impl_unchecked.sh" '#!/usr/bin/env bash
status() {
  return 0
}
# nothing calls status — tests that source this can vacuously pass'

# Vacuous test: always exits 0 no matter what the implementation does.
write_impl "test_vacuous.sh" "#!/usr/bin/env bash
# This test never calls the function being mutated.
exit 0"

out=$(bash "$MTEST" \
  --files "$TMP/impl_unchecked.sh" \
  --test-cmd "bash $TMP/test_vacuous.sh" 2>&1)
if printf '%s\n' "$out" | grep -q 'swap-return.*SURVIVED'; then
  ok
else
  no "vacuous test should let swap-return SURVIVE (got: $out)"
fi

# mutation-test.sh should exit 1 when any mutation survived.
bash "$MTEST" \
  --files "$TMP/impl_unchecked.sh" \
  --test-cmd "bash $TMP/test_vacuous.sh" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && ok || no "exit code should be 1 when a mutation survives (got $rc)"

# ── 6. No applicable targets exits 2 ─────────────────────────────────────────
# Passing a non-existent file should exit 2 (usage / nothing to mutate).

bash "$MTEST" \
  --files "/nonexistent/path/nothing.sh" \
  --test-cmd "exit 0" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok || no "nonexistent file should exit 2 (got $rc)"

# ── 7. --help exits 0 ────────────────────────────────────────────────────────

bash "$MTEST" --help >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok || no "--help should exit 0 (got $rc)"

# ── 8. All mutations killed → exit 0 ─────────────────────────────────────────
# When the test-cmd always fails (simulating a test suite that catches everything),
# every attempted mutation is killed and the script exits 0.

write_impl "impl_all_killed.sh" '#!/usr/bin/env bash
greet() {
  echo hello
  return 0
}
greet'

bash "$MTEST" \
  --files "$TMP/impl_all_killed.sh" \
  --test-cmd "exit 1" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok || no "all mutations killed should exit 0 (got $rc)"

# ── 9. File with no function / no exit 1 / no return 0 → skipped, exit 2 ─────
# A file that matches none of the three patterns produces no mutations.
# mutation-test.sh should report "nothing to mutate" and exit 2.

write_impl "impl_empty.sh" '#!/usr/bin/env bash
# This file has no mutation targets.
echo "hello world"'

bash "$MTEST" \
  --files "$TMP/impl_empty.sh" \
  --test-cmd "exit 0" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok || no "file with no mutation targets should exit 2 (got $rc)"

# ── Cleanup ────────────────────────────────────────────────────────────────────

rm -rf "$TMP"

echo ""
echo "mutation: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
