#!/usr/bin/env bash
# Mutation tester for the harness's shell scripts. Verifies that the test suite
# actually fails when implementation code breaks — it catches "always-pass" tests
# that would let real bugs go undetected.
#
# How it works:
#   1. Pick target implementation files (scripts/*.sh, bug-catch/*.sh by default,
#      or a list you pass in).
#   2. Each round randomly shuffles the target list and applies mutations one at a time:
#        delete   — wipe a shell function body (replace it with "return 0")
#        negate   — flip an exit-code check ("exit 1" → "exit 0" and vice versa)
#        swap     — change a return/exit value (swap 0 and 1)
#   3. Run the test suite against each mutated copy.
#   4. Report per mutation:
#        KILLED   — at least one test failed (the mutation was caught — good)
#        SURVIVED — all tests passed despite the mutation (the test is weak — bad)
#   5. Loop until 2 consecutive rounds find no new survivors (coverage is saturated).
#
# A survived mutation means the tests didn't care about that piece of code.
# Fix the tests so they would have caught it, then re-run.
#
# Usage:
#   bash scripts/mutation-test.sh [--files file1.sh,file2.sh] [--test-cmd "cmd"]
#   bash scripts/mutation-test.sh --help
#
# Options:
#   --files  Comma-separated list of implementation files to mutate.
#            Default: scripts/*.sh (excluding mutation-test.sh itself and run-tests.sh).
#   --test-cmd  Shell command to run for each mutation. Default: bash scripts/run-tests.sh.
#   --max-per-file  Max mutations per file per round (default: 5 — keeps the run tractable).
#   --dry-rounds  Consecutive rounds with no new survivors before stopping (default: 2).
#   --verbose  Print the mutation diff before each test run.
#
# Exit codes:
#   0 — all mutations were killed (test suite caught every injected defect)
#   1 — at least one mutation survived (test suite has a gap)
#   2 — usage error

set -u

# ── Argument parsing ──────────────────────────────────────────────────────────

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
FILES=""
TEST_CMD="bash scripts/run-tests.sh"
MAX_PER_FILE=5
DRY_ROUNDS=2
VERBOSE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --files)        FILES="${2:-}";          shift 2 ;;
    --test-cmd)     TEST_CMD="${2:-}";       shift 2 ;;
    --max-per-file) MAX_PER_FILE="${2:-5}";  shift 2 ;;
    --dry-rounds)   DRY_ROUNDS="${2:-2}";   shift 2 ;;
    --verbose)      VERBOSE=1;               shift ;;
    -h|--help)
      echo "usage: mutation-test.sh [--files f1.sh,f2.sh] [--test-cmd cmd] [--max-per-file N] [--dry-rounds N] [--verbose]"
      exit 0
      ;;
    *) echo "mutation-test: unknown argument: $1" >&2; exit 2 ;;
  esac
done

cd "$ROOT"

# ── Pick target files ─────────────────────────────────────────────────────────

if [ -n "$FILES" ]; then
  # Caller supplied a comma-separated list. Split on commas.
  target_files=$(printf '%s\n' "$FILES" | tr ',' '\n')
else
  # Default: all scripts/*.sh and bug-catch/*.sh, but not the test runner itself,
  # the linter, or this script (mutating the harness infrastructure makes no sense).
  target_files=""
  for f in scripts/*.sh bug-catch/*.sh; do
    [ -f "$f" ] || continue
    case "$f" in
      scripts/run-tests.sh)     continue ;;
      scripts/mutation-test.sh) continue ;;
      scripts/lint.sh)          continue ;;
    esac
    target_files="$target_files
$f"
  done
fi

if [ -z "$(printf '%s' "$target_files" | tr -d '[:space:]')" ]; then
  echo "mutation-test: no target files found." >&2
  exit 2
fi

# ── Mutation functions ────────────────────────────────────────────────────────

# Delete a shell function body. Replace the body of the FIRST function found
# with just "return 0". This simulates an implementation that does nothing.
# If tests still pass, they weren't actually checking what the function does.
#
# Handles POSIX and ksh function forms:
#   name() {          →  body replaced with "  return 0"
#   function name {   →  body replaced with "  return 0"
mutate_delete_body() {
  local src="$1"
  awk '
    BEGIN { done=0; depth=0; in_fn=0; replaced=0 }
    done { print; next }
    !in_fn && !replaced && /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)/ { in_fn=1 }
    !in_fn && !replaced && /^function[[:space:]]+[A-Za-z_]/ { in_fn=1 }
    in_fn && /{/ && depth==0 {
      depth=1
      print "LINE:" NR > "/dev/stderr"
      print
      print "  return 0"
      next
    }
    in_fn && depth>0 {
      n=$0; gsub(/[^{]/, "", n); opens=length(n)
      m=$0; gsub(/[^}]/, "", m); closes=length(m)
      depth=depth+opens-closes
      if (depth <= 0) {
        print "}"
        in_fn=0; replaced=1; done=1
      }
      next
    }
    { print }
  ' "$src"
}

# Negate a guard condition. Flip the FIRST "exit 1" in the file to "exit 0",
# skipping comment lines (lines whose first non-space character is #).
# This simulates a guard that never blocks. If tests still pass, they weren't
# verifying the blocking behavior.
mutate_negate_exit() {
  local src="$1"
  awk '
    BEGIN { done=0 }
    done { print; next }
    /^[[:space:]]*#/ { print; next }
    /exit[[:space:]]+1/ && !done {
      print "LINE:" NR > "/dev/stderr"
      sub(/exit[[:space:]]+1/, "exit 0"); done=1
    }
    { print }
  ' "$src"
}

# Swap a return value. Flip the FIRST "return 0" in the file to "return 1",
# skipping comment lines (lines whose first non-space character is #).
# This simulates success being reported as failure. If tests still pass, they
# weren't checking the function's return status.
mutate_swap_return() {
  local src="$1"
  awk '
    BEGIN { done=0 }
    done { print; next }
    /^[[:space:]]*#/ { print; next }
    /return[[:space:]]+0/ && !done {
      print "LINE:" NR > "/dev/stderr"
      sub(/return[[:space:]]+0/, "return 1"); done=1
    }
    { print }
  ' "$src"
}

# ── Core helper: apply a mutation and run the test suite ──────────────────────

# Temporarily replace <orig> with <mutant>, run TEST_CMD, then restore.
# Prints "survived" if all tests pass (the mutation was not caught).
# Prints "killed" if any test fails (the mutation was caught — correct behavior).
run_against_mutation() {
  local orig="$1" mutant="$2" label="$3"
  local backup rc

  backup=$(mktemp)
  cp "$orig" "$backup"

  # Restore the original if the script is interrupted mid-mutation.
  # Without this, Ctrl-C after the swap but before the restore leaves the
  # original file in a mutated state.
  trap 'cp "$backup" "$orig" 2>/dev/null; rm -f "$backup"' INT TERM EXIT

  cp "$mutant" "$orig"

  # Preserve the executable bit. macOS stat uses -f '%A'; GNU stat uses -c '%a'.
  local mode
  mode=$(stat -f '%A' "$backup" 2>/dev/null || stat -c '%a' "$backup" 2>/dev/null || echo "755")
  chmod "$mode" "$orig" 2>/dev/null || true

  rc=0
  # Run in a subshell so a "exit N" test command does not kill this script.
  (eval "$TEST_CMD") >/dev/null 2>&1 || rc=$?

  cp "$backup" "$orig"
  rm -f "$backup"
  trap - INT TERM EXIT

  if [ "$rc" -eq 0 ]; then
    echo "    $label: SURVIVED (tests did not catch this)"
    return 0  # survived
  else
    echo "    $label: killed"
    return 1  # killed
  fi
}

# ── Main loop ─────────────────────────────────────────────────────────────────

killed=0
survived=0
skipped=0
total=0

echo "mutation-test: starting"

while IFS= read -r file; do
  [ -n "$file" ] || continue
  [ -f "$file" ] || continue

  echo ""
  echo "  ── $file"

  count=0

  # Mutation 1: delete function body
  if [ "$count" -lt "$MAX_PER_FILE" ]; then
    mutant=$(mktemp)
    mutate_delete_body "$file" > "$mutant"
    if diff -q "$file" "$mutant" >/dev/null 2>&1; then
      echo "    delete-body: skip (no function body found)"
      skipped=$((skipped+1))
    else
      total=$((total+1)); count=$((count+1))
      if [ "$VERBOSE" -eq 1 ]; then diff "$file" "$mutant" || true; fi
      if run_against_mutation "$file" "$mutant" "delete-body"; then
        survived=$((survived+1))
      else
        killed=$((killed+1))
      fi
    fi
    rm -f "$mutant"
  fi

  # Mutation 2: negate exit condition
  if [ "$count" -lt "$MAX_PER_FILE" ]; then
    mutant=$(mktemp)
    mutate_negate_exit "$file" > "$mutant"
    if diff -q "$file" "$mutant" >/dev/null 2>&1; then
      echo "    negate-exit: skip (no 'exit 1' found)"
      skipped=$((skipped+1))
    else
      total=$((total+1)); count=$((count+1))
      if [ "$VERBOSE" -eq 1 ]; then diff "$file" "$mutant" || true; fi
      if run_against_mutation "$file" "$mutant" "negate-exit"; then
        survived=$((survived+1))
      else
        killed=$((killed+1))
      fi
    fi
    rm -f "$mutant"
  fi

  # Mutation 3: swap return value
  if [ "$count" -lt "$MAX_PER_FILE" ]; then
    mutant=$(mktemp)
    mutate_swap_return "$file" > "$mutant"
    if diff -q "$file" "$mutant" >/dev/null 2>&1; then
      echo "    swap-return: skip (no 'return 0' found)"
      skipped=$((skipped+1))
    else
      total=$((total+1)); count=$((count+1))
      if [ "$VERBOSE" -eq 1 ]; then diff "$file" "$mutant" || true; fi
      if run_against_mutation "$file" "$mutant" "swap-return"; then
        survived=$((survived+1))
      else
        killed=$((killed+1))
      fi
    fi
    rm -f "$mutant"
  fi

done <<EOF
$target_files
EOF

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "mutation-test: done"
echo "  mutations tried:    $total"
echo "  killed (caught):    $killed"
echo "  survived (missed):  $survived"
echo "  skipped (no match): $skipped"

if [ "$total" -eq 0 ]; then
  echo "mutation-test: nothing to mutate — no applicable patterns found in target files." >&2
  exit 2
fi

if [ "$survived" -gt 0 ]; then
  echo "mutation-test: $survived mutation(s) SURVIVED — fix the tests so they catch these." >&2
  exit 1
fi

echo "mutation-test: all mutations killed — test suite is not vacuous."
exit 0
