#!/bin/bash
# What one statement of each kind costs: each control (basic/controls/*.bas)
# run at 100,000 iterations through basic-run, best of three, less the bare
# FOR/NEXT loop (02-for). A control with INPUT or PRINT is left out: its time is
# the transcript's. Run it with nothing else on the box.
#
#   basic/controls-time.sh
#   BIN=/path/to/basic-run N=10000 basic/controls-time.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BIN:-$HOME/build/roc-apps/gen/basic/basic-run}"
N="${N:-100000}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
for f in "$HERE"/controls/*.bas; do
    n="$(basename "$f" .bas)"
    src="$(cat "$f")"
    [[ "$src" == *@N@* ]] || continue
    [[ "$src" == *INPUT* || "$src" == *PRINT* ]] && continue
    best=999999999
    for k in 1 2 3; do
        t0=$EPOCHREALTIME
        "$BIN" micro "${src//@N@/$N}" "" > /dev/null 2> "$T/err"
        t1=$EPOCHREALTIME
        us=$(echo "($t1 - $t0) * 1000000 / 1" | bc)
        [ "$us" -lt "$best" ] && best=$us
    done
    printf '%s\t%s\n' "$n" "$best" >> "$T/rows"
done
base=$(awk -F'\t' '$1=="02-for"{print $2}' "$T/rows")
printf '%-26s %12s %20s\n' control "us an iteration" "the statement, us"
sort -t$'\t' -k2 -n "$T/rows" | awk -F'\t' -v base="$base" -v n="$N" '{ printf "%-26s %12.2f %20.2f\n", $1, $2 / n, ($2 - base) / n }'
