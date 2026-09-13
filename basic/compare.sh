#!/bin/bash
# Two runs of basic/run.sh, transcript by transcript: the gate a new
# interpreter passes against the old one.
#
#   basic/compare.sh ~/build/roc-apps/gen/basic-old ~/build/roc-apps/gen/basic-new
#
# Each suite's transcripts are compared byte for byte. A program either side
# stopped at its time limit (an empty transcript with TIMEOUT in that run's
# log) is listed apart, since it has nothing to compare. Differences are
# listed by name, to be read one by one.
set -u
A="$1"; B="$2"
for suite in nbs games; do
    [ -d "$A/$suite" ] && [ -d "$B/$suite" ] || continue
    same=0; differ=(); timed=()
    for f in "$A/$suite"/*.out; do
        n="$(basename "$f" .out)"
        if grep -qE "^$n +[0-9.]+ ms +[0-9]+ bytes +TIMEOUT" "$A/$suite.log" "$B/$suite.log" 2>/dev/null; then
            timed+=("$n")
        elif cmp -s "$f" "$B/$suite/$n.out"; then
            same=$((same + 1))
        else
            differ+=("$n")
        fi
    done
    printf '%s: %d identical, %d differ, %d timed out on a side\n' "$suite" "$same" "${#differ[@]}" "${#timed[@]}"
    [ ${#differ[@]} -eq 0 ] || printf '  differ: %s\n' "${differ[*]}"
    [ ${#timed[@]} -eq 0 ] || printf '  timed out: %s\n' "${timed[*]}"
done
