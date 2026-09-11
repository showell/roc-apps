#!/bin/bash
# Every safari spec through rocemit, then roc, against the Codex verdict.
#
#   safari/emitted.sh             all 54 units
#   safari/emitted.sh ViewYaw     one
#
# The units are safari-codex's `units/<Spec>.codex` (the resolved program) and
# `units/<Spec>.expected` (the verdict the Rust interpreter froze). rocemit is
# rust-codex-compiler's Roc emitter. Three outcomes, counted apart: PASS and
# FAIL are roc's output against the verdict; REFUSED is rocemit declining a
# form it has not built, with the reason -- not a failure and not a pass.
#
# Outputs go under ~/build/roc-apps/gen, never here.
set -u
ROC="${ROC:-$HOME/build/roc/out/bin/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
UNITS="${SAFARI_UNITS:-$HOME/showell_repos/safari-codex/units}"
OUT="$HOME/build/roc-apps/gen"
mkdir -p "$OUT"
[ -x "$ROC" ] || { echo "no roc at $ROC"; exit 2; }
[ -x "$ROCEMIT" ] || { echo "no rocemit at $ROCEMIT; cargo build --release --bin rocemit, or set ROCEMIT"; exit 2; }
[ -d "$UNITS" ] || { echo "no units at $UNITS"; exit 2; }
pass=0; fail=0; refused=0
for u in "$UNITS"/*Spec.codex; do
    n="$(basename "$u" .codex)"
    [ $# -eq 0 ] || [ "$n" = "$1Spec" ] || continue
    if ! "$ROCEMIT" "$u" > "$OUT/$n.roc" 2> "$OUT/$n.refused"; then
        refused=$((refused + 1)); echo "REFUSED $n  $(head -1 "$OUT/$n.refused")"; rm -f "$OUT/$n.roc"; continue
    fi
    rm -f "$OUT/$n.refused"
    "$ROC" run "$OUT/$n.roc" > "$OUT/$n.out" 2> "$OUT/$n.err"
    if diff -q "$OUT/$n.out" "$UNITS/$n.expected" > /dev/null; then
        pass=$((pass + 1)); echo "PASS $n"
    else
        fail=$((fail + 1)); echo "FAIL $n"; grep -m1 -E "✗|crashed" -A3 "$OUT/$n.err" | head -4; diff "$OUT/$n.out" "$UNITS/$n.expected" | head -4
    fi
done
echo "$pass pass, $fail fail, $refused refused"
[ $fail -eq 0 ] && [ $refused -eq 0 ]
