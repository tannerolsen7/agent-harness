#!/usr/bin/env bash
# Verify bug-catch/score.sh: catch rate + 95% Wilson lower bound, and that we gate on the lower
# bound (a perfect rate on a small set still yields a humble lower bound, well below 100%).
# Tests PROPERTIES, not boundary-sensitive exact decimals (the lower bound for 10/10 lands right
# on a rounding knife-edge — pinning it is fragile across awk/float implementations).
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCORE="$ROOT/bug-catch/score.sh"
[ -f "$SCORE" ] || { echo "bug-catch-score.test: $SCORE not found"; exit 1; }

pass=0; fail=0
# extract the first percentage on a matching line, as a bare number
field() { printf '%s' "$2" | awk -v key="$1" '$0 ~ key {for(i=1;i<=NF;i++) if($i ~ /%$/){v=$i; sub(/%/,"",v); print v; exit}}'; }
num_lt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a+0 < b+0)}'; }   # a < b ?
num_in() { awk -v a="$1" -v lo="$2" -v hi="$3" 'BEGIN{exit !(a+0 >= lo+0 && a+0 <= hi+0)}'; }
ok() { pass=$((pass+1)); }
no() { echo "  MISS: $1"; fail=$((fail+1)); }

# 8 caught / 2 missed
out=$(printf '001\tcaught\n002\tcaught\n003\tcaught\n004\tcaught\n005\tcaught\n006\tcaught\n007\tcaught\n008\tcaught\n009\tmissed\n010\tmissed\n' | bash "$SCORE")
r=$(field 'recall' "$out"); l=$(field 'lower bound' "$out"); n=$(printf '%s' "$out" | awk '/cases/{print $2}')
[ "$r" = "80.0" ] && ok || no "8/10 recall = $r (want 80.0)"
[ "$n" = "10" ] && ok || no "8/10 n = $n (want 10)"
num_lt "$l" "$r" && ok || no "8/10 lower ($l) should be < recall ($r)"
num_in "$l" 45 53 && ok || no "8/10 lower ($l) outside expected band 45-53"

# 10 caught / 0 missed — recall 100% but lower bound must be humble (the whole point of gating on it)
out=$(printf '%s\tcaught\n' 1 2 3 4 5 6 7 8 9 10 | bash "$SCORE")
r=$(field 'recall' "$out"); l=$(field 'lower bound' "$out")
[ "$r" = "100.0" ] && ok || no "10/10 recall = $r (want 100.0)"
num_lt "$l" 90 && ok || no "10/10 lower ($l) should be well below 100 (got >=90)"
num_in "$l" 68 74 && ok || no "10/10 lower ($l) outside expected band 68-74"

# no verdicts → exit 2
printf 'x\ty\n\n' | bash "$SCORE" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok || no "no verdicts should exit 2, got $rc"

# --traps: the classifier-guard breakdown over the real trap subset (009-013 are trap:true cases).
# Non-trap ids (001) are excluded from the trap tally; under-calls = missed traps (R4-D32 #5).
out=$(printf '001\tcaught\n009\tcaught\n010\tcaught\n011\tcaught\n012\tmissed\n013\tmissed\n' | bash "$SCORE" --traps /dev/stdin)
tc=$(printf '%s' "$out" | awk '/^trap cases:/{print $3}')
uc=$(printf '%s' "$out" | awk '/^under-calls:/{print $2}')
tr=$(field 'trap recall' "$out")
[ "$tc" = "5" ] && ok || no "--traps trap cases = $tc (want 5; non-trap 001 excluded)"
[ "$uc" = "2" ] && ok || no "--traps under-calls = $uc (want 2; 012+013 missed)"
[ "$tr" = "60.0" ] && ok || no "--traps trap recall = $tr (want 60.0)"
# default output is unchanged by the feature: overall recall still prints (4/6 = 66.7%)
orec=$(field 'recall' "$out")
[ "$orec" = "66.7" ] && ok || no "--traps overall recall = $orec (want 66.7; trap block must not disturb it)"

echo ""
echo "bug-catch-score: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
