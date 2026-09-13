#!/bin/bash
# The pathological programs (basic/pathological/*.bas) through basic-run:
# for each, the process's time and its mmap calls, which on Roc's default
# platform are one per heap allocation. A statement that allocates per
# execution shows as a count in the tens or hundreds of thousands.
#
#   basic/allocs.sh
#   BIN=~/build/roc-apps/gen/basic/basic-run-old basic/allocs.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BIN:-$HOME/build/roc-apps/gen/basic/basic-run}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
for f in "$HERE"/pathological/*.bas; do
    n="$(basename "$f" .bas)"
    t0=$EPOCHREALTIME
    timeout 20 "$BIN" micro "$(cat "$f")" "" > "$T/out" 2>&1
    rc=$?
    t1=$EPOCHREALTIME
    if [ $rc -eq 124 ]; then
        printf '%-16s TIMEOUT at 20 s\n' "$n"
        continue
    fi
    strace -c -f -o "$T/st" timeout 20 "$BIN" micro "$(cat "$f")" "" > /dev/null 2>&1
    printf '%-16s %9.1f ms  mmap %8s  prints %s\n' "$n" "$(echo "($t1 - $t0) * 1000" | bc)" "$(awk '$NF=="mmap"{print $4}' "$T/st")" "$(tail -c 40 "$T/out" | tr '\n' ' ')"
done
