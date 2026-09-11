#!/bin/bash
# Every ported spec through roc, its output against the Codex spec's verdict.
#
#   safari/run.sh            all of them
#   safari/run.sh ViewYaw    one
#
# Outputs go under ~/build/roc-apps/safari, never here.
set -u
ROC="${ROC:-$HOME/build/roc/out/bin/roc}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HOME/build/roc-apps/safari"
mkdir -p "$OUT"
[ -x "$ROC" ] || { echo "no roc at $ROC"; exit 2; }
pass=0; fail=0
for f in "$HERE"/*Spec.roc; do
    n="$(basename "$f" .roc)"
    [ $# -eq 0 ] || [ "$n" = "$1Spec" ] || continue
    "$ROC" run "$f" > "$OUT/$n.out" 2> "$OUT/$n.err"
    if diff -q "$OUT/$n.out" "$HERE/$n.expected" > /dev/null; then
        pass=$((pass + 1)); echo "PASS $n"
    else
        fail=$((fail + 1)); echo "FAIL $n"; head -5 "$OUT/$n.err"; diff "$OUT/$n.out" "$HERE/$n.expected" | head -6
    fi
done
echo "$pass pass, $fail fail"
[ $fail -eq 0 ]
