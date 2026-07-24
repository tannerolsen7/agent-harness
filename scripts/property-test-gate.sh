#!/usr/bin/env bash
# Property-test coverage gate — host-agnostic, project-agnostic. The enforcement leg of
# the property-based-testing capability (VISION C11 / killlist §C #4): "a coverage-style
# blocker on the pricing module." Any change to an invariant-critical module must be
# covered by a property test.
#
# The harness cannot ship the property tests themselves (no app, no test framework, cannot
# install fast-check). It ships this gate. A consuming project declares, in
# .claude/property-invariants.json, which modules are invariant-critical (modulePattern)
# and which files count as their property tests (testPattern). This is the same extension
# pattern as check-routing.sh / the database-safety adapter: harness owns the check, the
# project owns the declaration.
#
# Rule: if a CHANGED file matches an invariant's modulePattern, at least one TRACKED file
# must match that invariant's testPattern — otherwise BLOCK. Existence in the tree is
# enough (a change to already-covered logic is not forced to re-edit the property test);
# this gate proves a property test EXISTS, not that it catches breaks — mutation-test.sh is
# the companion that proves the latter. Path matching is case-insensitive so a lowercase
# pattern still catches a PascalCase file (e.g. `tax` matches `TaxCalculator.ts`).
#
# FAIL-CLOSED on every error path (a silent skip would let uncovered invariant logic merge):
# missing node, malformed config, missing invariants array, a missing/empty/identical/
# tab-or-newline pattern, an invalid regex, a git failure, or an unresolvable base ref all
# BLOCK (exit 2). Inert ONLY when .claude/property-invariants.json is absent (project opted
# out). No jq dependency — config read via node.
# Test-only overrides: PROPINV_CONFIG, PROPINV_CHANGED, PROPINV_TRACKED, PROPINV_BASE.
#
# Exit codes: 0 = OK (inert, 0 invariants declared, or every touched module is covered)
#             1 = BLOCK (an invariant module changed with no matching property test)
#             2 = setup/config error (fail-closed)
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CFG="${PROPINV_CONFIG:-$ROOT/.claude/property-invariants.json}"

[ -f "$CFG" ] || { echo "property-test-gate: no config ($CFG) — coverage gate inert (project opted out)."; exit 0; }
command -v node >/dev/null 2>&1 || { echo "property-test-gate: node required to read $CFG — BLOCKING (fail-closed)." >&2; exit 2; }

# Single node pass: parse + validate + emit one TAB-separated line per invariant
# (name<TAB>modulePattern<TAB>testPattern). Captured via $(...) || exit 2, so a node exit(2)
# is visible to the shell — unlike check-routing.sh's process-substitution reads, whose
# failures can be swallowed under set -e. Rejects, fail-closed: a non-array invariants field;
# a missing, empty, or non-string modulePattern/testPattern (an empty pattern matches every
# line, so it would report everything "covered"); identical module and test patterns (the
# module file would satisfy its own coverage — the gate could never block); and a tab or
# newline inside a pattern (would corrupt the TSV the loop parses).
INVARIANTS=$(node -e '
  const fs = require("fs");
  let c;
  try { c = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); }
  catch (e) { console.error("property-test-gate: invalid property-invariants.json — " + e.message); process.exit(2); }
  if (!Array.isArray(c.invariants)) { console.error("property-test-gate: config has no \"invariants\" array — BLOCKING (fail-closed)."); process.exit(2); }
  const bad = (v) => typeof v !== "string" || v.length === 0;
  for (const inv of c.invariants) {
    const name = inv && inv.name ? String(inv.name) : "(unnamed)";
    if (!inv || bad(inv.modulePattern) || bad(inv.testPattern)) {
      console.error("property-test-gate: invariant \"" + name + "\" has a missing or empty modulePattern/testPattern — BLOCKING (fail-closed).");
      process.exit(2);
    }
    if (inv.modulePattern === inv.testPattern) {
      console.error("property-test-gate: invariant \"" + name + "\" has identical modulePattern and testPattern — the module file would satisfy its own coverage, so the gate could never block. BLOCKING (fail-closed).");
      process.exit(2);
    }
    if (/[\t\n]/.test(inv.modulePattern) || /[\t\n]/.test(inv.testPattern)) {
      console.error("property-test-gate: invariant \"" + name + "\" has a tab or newline in a pattern — BLOCKING (fail-closed).");
      process.exit(2);
    }
    process.stdout.write(name + "\t" + inv.modulePattern + "\t" + inv.testPattern + "\n");
  }
' "$CFG") || exit 2

# changed + tracked file lists. Prefer test overrides; otherwise derive from git. A git
# failure is fail-closed (exit 2) to keep the documented 0/1/2 contract instead of leaking a
# raw git exit code. An unresolvable base is a CI misconfig (config is present), not an opt-out.
if [ -n "${PROPINV_CHANGED+x}" ]; then
  changed="$PROPINV_CHANGED"
else
  BASE="${PROPINV_BASE:-}"
  [ -z "$BASE" ] && [ -n "${GITHUB_BASE_REF:-}" ] && BASE="origin/$GITHUB_BASE_REF"
  [ -z "$BASE" ] && [ -n "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}" ] && BASE="origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
  [ -z "$BASE" ] && BASE="origin/main"
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || BASE=main
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || {
    echo "property-test-gate: base ref not found ($BASE) but config is present — BLOCKING (fail-closed)." >&2
    echo "  Ensure CI fetches the base branch (fetch-depth/GIT_DEPTH 0 + 'git fetch origin <base>')." >&2
    exit 2
  }
  # A base that already contains HEAD (a stale/unfetched local `main` fast-forwarded past the
  # feature branch) yields an empty diff and would silently pass. Treat it as a CI misconfig.
  if git merge-base --is-ancestor HEAD "$BASE" 2>/dev/null; then
    echo "property-test-gate: base ref ($BASE) already contains HEAD — stale or wrong base; CI must fetch the real base. BLOCKING (fail-closed)." >&2
    exit 2
  fi
  changed=$(git diff --name-only "$BASE"...HEAD) || { echo "property-test-gate: git diff failed — BLOCKING (fail-closed)." >&2; exit 2; }
fi

if [ -n "${PROPINV_TRACKED+x}" ]; then
  tracked="$PROPINV_TRACKED"
else
  # Read COMMITTED files (ls-tree HEAD), not the index (ls-files) — the diff above is committed
  # state, so a staged-but-uncommitted test file must not count as coverage for a pushed commit.
  tracked=$(git ls-tree -r --name-only HEAD) || { echo "property-test-gate: git ls-tree failed — BLOCKING (fail-closed)." >&2; exit 2; }
fi

# matches <text> <pattern> — 0 if any line matches, 1 if none. Case-insensitive (-i) so a
# lowercase pattern still catches PascalCase paths. `--` so a pattern starting with '-' is a
# regex, not a grep option. A here-string (not `printf | grep`) feeds the text, so a grep that
# matches early can't raise a SIGPIPE that pipefail would misread as an invalid-regex error.
# A real invalid regex (grep exit ≥2) is fail-closed (exit 2).
matches() {
  local text="$1" pat="$2" rc=0
  grep -qiE -- "$pat" <<<"$text" || rc=$?
  if [ "$rc" -ge 2 ]; then
    echo "property-test-gate: invalid regex in config ('$pat') — BLOCKING (fail-closed)." >&2
    exit 2
  fi
  return "$rc"
}

blocked=0
count=0
# TSV read via heredoc (not process substitution): the loop runs in the current shell, so
# `blocked` and `count` survive it, and INVARIANTS is already one computed string.
while IFS=$'\t' read -r name modpat testpat; do
  [ -z "$name" ] && continue
  count=$((count + 1))
  # Validate both patterns' regex syntax on every invariant, even when the module didn't
  # change, so a broken config fails closed regardless of the diff (matches() exits 2 on an
  # invalid regex; the 0/1 match result here is intentionally ignored).
  matches "" "$modpat" || true
  matches "" "$testpat" || true
  # A modulePattern that matches no tracked file is almost always a typo (wrong path, case, or
  # anchor) that would make the invariant silently never fire. Warn — don't block — because a
  # project may legitimately declare an invariant for a module it has not created yet.
  if ! matches "$tracked" "$modpat"; then
    echo "property-test-gate: warning — invariant '$name' modulePattern matches no tracked file; check the pattern (typo? wrong path or case?)." >&2
  fi
  if matches "$changed" "$modpat"; then
    if ! matches "$tracked" "$testpat"; then
      hit=$(grep -m1 -iE -- "$modpat" <<<"$changed" || true)
      {
        echo "property-test-gate: BLOCKED — invariant '$name' module changed ($hit) with no matching property test."
        echo "  A change to invariant-critical logic must be covered by a property test."
        echo "  Add a test file matching:  $testpat"
      } >&2
      blocked=1
    fi
  fi
done <<EOF
$INVARIANTS
EOF

if [ "$blocked" -ne 0 ]; then
  exit 1
fi
if [ "$count" -eq 0 ]; then
  echo "property-test-gate: config present but 0 invariants declared — nothing enforced. OK."
  exit 0
fi
echo "property-test-gate: $count invariant(s) checked — each touched module has a matching property test file (existence only; run mutation-test.sh to confirm the tests catch breaks). OK."
exit 0
