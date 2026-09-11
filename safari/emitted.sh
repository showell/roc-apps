#!/bin/bash
# Every safari spec through rocemit, then roc, against the Codex verdict.
#
#   safari/emitted.sh             all 54 units
#   safari/emitted.sh ViewYaw     one
#
# The units are safari-codex's `units/<Spec>.codex` (the resolved program) and
# `units/<Spec>.expected` (the verdict the Rust interpreter froze). rocemit is
# rust-codex-compiler's Roc emitter, and it writes ONE TYPE MODULE PER CODEX
# CHAPTER plus the spec's app into gen/<Spec>/. Three outcomes, counted apart:
# PASS and FAIL are roc's output against the verdict; REFUSED is rocemit
# declining a form it has not built, with the reason -- not a failure and not
# a pass.
#
# THE STILLS ARE BAKED, NOT EMITTED. rocemit forwards a data table to
# `<Chapter>Data.name`; safari/bake_stills.py writes those modules and the
# decoder under gen/baked/, and every unit's directory gets a copy, because a
# Roc import resolves beside the importing file. A unit that never imports
# them never compiles them.
#
# Outputs go under ~/build/roc-apps/gen, never here.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc/out/bin/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
UNITS="${SAFARI_UNITS:-$HOME/showell_repos/safari-codex/units}"
OUT="$HOME/build/roc-apps/gen"
mkdir -p "$OUT"
[ -x "$ROC" ] || { echo "no roc at $ROC"; exit 2; }
[ -x "$ROCEMIT" ] || { echo "no rocemit at $ROCEMIT; cargo build --release --bin rocemit, or set ROCEMIT"; exit 2; }
[ -d "$UNITS" ] || { echo "no units at $UNITS"; exit 2; }
BAKED="$OUT/baked"
"$HERE/bake_stills.py" > /dev/null || { echo "bake_stills.py failed"; exit 2; }
pass=0; fail=0; refused=0
for u in "$UNITS"/*Spec.codex; do
    n="$(basename "$u" .codex)"
    [ $# -eq 0 ] || [ "$n" = "$1Spec" ] || continue
    d="$OUT/$n"
    if ! app="$("$ROCEMIT" "$u" "$d" 2> "$OUT/$n.refused")"; then
        refused=$((refused + 1)); echo "REFUSED $n  $(head -1 "$OUT/$n.refused")"; continue
    fi
    rm -f "$OUT/$n.refused"
    cp "$BAKED"/*.roc "$d/"
    "$ROC" run "$d/$app" > "$OUT/$n.out" 2> "$OUT/$n.err"
    if diff -q "$OUT/$n.out" "$UNITS/$n.expected" > /dev/null; then
        pass=$((pass + 1)); echo "PASS $n"
    else
        fail=$((fail + 1)); echo "FAIL $n"; grep -m1 -E "✗|crashed" -A3 "$OUT/$n.err" | head -4; diff "$OUT/$n.out" "$UNITS/$n.expected" | head -4
    fi
done
echo "$pass pass, $fail fail, $refused refused"
[ $fail -eq 0 ] && [ $refused -eq 0 ]
