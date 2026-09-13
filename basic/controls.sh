#!/bin/bash
# The controls (basic/controls/*.bas): the smallest programs, each adding one
# thing to the one before, run through basic-run at 1,000 and at 10,000
# iterations. What changes between the two counts of mmap calls (one per heap
# allocation on Roc's default platform), over the 9,000 extra iterations, is
# what one iteration allocates. Each control is held to 0, or to the number
# in controls/expected.txt with its reason.
#
#   basic/controls.sh
#   BIN=/path/to/basic-run basic/controls.sh
#
# **A CONTROL THAT STARTS ALLOCATING NAMES THE FEATURE THAT DID IT**, which
# is the point: read them in order, and the first one off is the change's.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BIN:-$HOME/build/roc-apps/gen/basic/basic-run}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
count() { # listing
    strace -c -f -o "$T/st" timeout 20 "$BIN" micro "$1" "" > "$T/out" 2>&1
    awk '$NF=="mmap"{print $4}' "$T/st"
}
bad=0
for f in "$HERE"/controls/*.bas; do
    n="$(basename "$f" .bas)"
    src="$(cat "$f")"
    small="$(count "${src//@N@/1000}")"
    if [[ "$src" == *@N@* ]]; then
        big="$(count "${src//@N@/10000}")"
        per="$(echo "scale=2; ($big - $small) / 9000" | bc)"
    else
        big="-"; per="-"
    fi
    want="$(awk -v n="$n" '$1==n{print $2}' "$HERE/controls/expected.txt")"
    want="${want:-0}"
    mark="ok"
    if [ "$per" != "-" ] && [ "$(echo "$per > $want + 0.05 || $per < $want - 0.05" | bc)" = 1 ]; then mark="OFF (held to $want)"; bad=$((bad + 1)); fi
    tailtext="$(tail -c 30 "$T/out" | tr '\n' ' ')"
    printf '%-16s %6s mmap at 1,000  %6s at 10,000  %5s per iteration  %s\n' "$n" "$small" "$big" "$per" "$mark"
    case "$tailtext" in *overflowed*|*HALTED*|*UNSUPPORTED*) echo "    it printed: $tailtext";; esac
done
echo "$bad off"
