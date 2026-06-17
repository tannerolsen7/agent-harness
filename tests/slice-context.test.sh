#!/usr/bin/env bash
# Tests for scripts/slice-context.sh — the context slicer.
#
# Covers the gated signature-extraction path plus the loud-failure and safe-fallback
# behaviors confirmed in docs/TESTING.md.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SLICE="$ROOT/scripts/slice-context.sh"

[ -f "$SLICE" ] || { echo "slice-context.test: $SLICE not found"; exit 1; }

pass=0; fail=0
ok() { pass=$((pass+1)); }
no() { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ── Signature extraction (the gated path): TS/JS ──────────────────────────────

cat > "$TMP/sample.ts" << 'TS'
import { z } from "zod";

export function computeTotal(items: Item[]): number {
  let sum = 0;
  for (const it of items) {
    sum += it.price;
  }
  return sum;
}

const formatName = (u: User): string => {
  const first = u.first.trim();
  return `${first} ${u.last}`;
};

export class Cart {
  add(item: Item): void {
    this.items.push(item);
  }
}

interface Item {
  price: number;
}

type User = { first: string; last: string };
TS

out=$(bash "$SLICE" "$TMP/sample.ts")

printf '%s\n' "$out" | grep -q 'export function computeTotal' && ok || no "ts: missing exported function signature"
printf '%s\n' "$out" | grep -q 'const formatName' && ok || no "ts: missing arrow-function const"
printf '%s\n' "$out" | grep -q 'export class Cart' && ok || no "ts: missing class declaration"
printf '%s\n' "$out" | grep -q 'interface Item' && ok || no "ts: missing interface declaration"
printf '%s\n' "$out" | grep -q '^type User' && ok || no "ts: missing type alias"

# Body lines must be dropped.
printf '%s\n' "$out" | grep -q 'sum += it.price' && no "ts: body line 'sum += it.price' leaked into slice" || ok
printf '%s\n' "$out" | grep -q 'this.items.push' && no "ts: body line 'this.items.push' leaked into slice" || ok

# Output is smaller than input.
in_lines=$(wc -l < "$TMP/sample.ts")
out_lines=$(printf '%s\n' "$out" | wc -l)
[ "$out_lines" -lt "$in_lines" ] && ok || no "ts: slice ($out_lines lines) not smaller than input ($in_lines lines)"

# ── Signature extraction: Python ──────────────────────────────────────────────

cat > "$TMP/sample.py" << 'PY'
import os

def load(path):
    with open(path) as f:
        return f.read()

class Store:
    def get(self, key):
        return self.data[key]
PY

out=$(bash "$SLICE" "$TMP/sample.py")
printf '%s\n' "$out" | grep -q '^def load' && ok || no "py: missing def signature"
printf '%s\n' "$out" | grep -q '^class Store' && ok || no "py: missing class signature"
printf '%s\n' "$out" | grep -q 'return f.read' && no "py: body line leaked into slice" || ok

# ── Signature extraction: shell ───────────────────────────────────────────────

cat > "$TMP/sample.sh" << 'SH'
#!/usr/bin/env bash
do_thing() {
  local x=1
  echo "$x"
}
function other_thing {
  echo two
}
SH

out=$(bash "$SLICE" "$TMP/sample.sh")
printf '%s\n' "$out" | grep -q 'do_thing()' && ok || no "sh: missing 'name()' function form"
printf '%s\n' "$out" | grep -q 'function other_thing' && ok || no "sh: missing 'function name' form"
printf '%s\n' "$out" | grep -q 'local x=1' && no "sh: body line leaked into slice" || ok

# ── Header anchoring ──────────────────────────────────────────────────────────

cat > "$TMP/doc.md" << 'MD'
# Title
Some prose that should be dropped.
## Section
More prose.
MD

out=$(bash "$SLICE" "$TMP/doc.md")
printf '%s\n' "$out" | grep -q '^# Title' && ok || no "md: missing top heading"
printf '%s\n' "$out" | grep -q '^## Section' && ok || no "md: missing sub heading"
printf '%s\n' "$out" | grep -q 'Some prose' && no "md: prose leaked into slice" || ok

# ── Missing file fails loud ───────────────────────────────────────────────────

if bash "$SLICE" "$TMP/does-not-exist.ts" >/dev/null 2>"$TMP/err"; then
  no "missing file: exited 0 (want non-zero)"
else
  ok
fi
[ -s "$TMP/err" ] && ok || no "missing file: no stderr message"

# ── No path given fails loud ──────────────────────────────────────────────────

if bash "$SLICE" >/dev/null 2>"$TMP/err2"; then
  no "no path: exited 0 (want non-zero)"
else
  ok
fi
grep -qi usage "$TMP/err2" && ok || no "no path: stderr lacks a usage message"

# ── Unknown file type falls back to whole file ────────────────────────────────

cat > "$TMP/data.xyz" << 'XYZ'
alpha
beta
gamma
XYZ
out=$(bash "$SLICE" "$TMP/data.xyz")
[ "$(printf '%s\n' "$out" | wc -l)" -eq 3 ] && ok || no "unknown type: did not print whole file"
printf '%s\n' "$out" | grep -q 'beta' && ok || no "unknown type: dropped a content line"

# ── --full bypasses slicing ───────────────────────────────────────────────────

out=$(bash "$SLICE" --full "$TMP/sample.ts")
printf '%s\n' "$out" | grep -q 'sum += it.price' && ok || no "--full: body line was dropped (should print whole file)"

echo ""
echo "slice-context: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
