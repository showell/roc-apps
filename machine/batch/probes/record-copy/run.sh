#!/bin/bash
# Time 20,000,000 bumps of one field over four record shapes (the field alone;
# beside a 64-field record stored inline; beside the same record in a list of
# one; beside it in a Box), through a function call and inline, on Roc's dev
# backend natively. Fastest of three runs each.
#
#   machine/batch/probes/record-copy/run.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
N="${N:-20000000}"
W="$HOME/build/roc-apps/gen/probes/record-copy"
mkdir -p "$W"
cd "$W" && python3 "$HERE/gen.py" && "$ROC" build Probe.roc --opt=dev --output="$W/probe" > build.log 2>&1
grep -a -m3 -A6 '✗' build.log && exit 1
for how in call inline; do
    for shape in bare wide boxed box; do
        best=999
        for k in 1 2 3; do
            t=$( { /usr/bin/time -f '%e' ./probe "$N" "$shape" "$how" > out.txt; } 2>&1 | tail -1)
            best=$(python3 -c "print(min($best, $t))")
        done
        printf '%-7s %-6s %6s s   answer %s\n' "$how" "$shape" "$best" "$(cat out.txt)"
    done
done
