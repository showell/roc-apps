#!/bin/bash
# Device writes through a list of one against a Box, natively on the dev
# backend on Roc's default platform: time (fastest of three) and the mmap
# count, which is the allocation count, so a 32 KB list copied per write shows
# as one mmap per write.
#
#   machine/batch/probes/device-write/run.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
N="${N:-200000}"
W="$HOME/build/roc-apps/gen/probes/device-write"
mkdir -p "$W"
cd "$W" && python3 "$HERE/gen.py" && "$ROC" build Probe.roc --opt=dev --output="$W/probe" > build.log 2>&1
grep -a -m3 -A6 '✗' build.log && exit 1
for write in scalar card; do
    for shape in list box; do
        best=999
        for k in 1 2 3; do
            t=$( { /usr/bin/time -f '%e' ./probe "$N" "$shape" "$write" > out.txt; } 2>&1 | tail -1)
            best=$(python3 -c "print(min($best, $t))")
        done
        mm=$(strace -f -c -e trace=mmap ./probe "$N" "$shape" "$write" 2>&1 >/dev/null | awk '/mmap/ {print $4}')
        printf '%-7s %-5s %6s s   mmap %8s   answer %s\n' "$write" "$shape" "$best" "$mm" "$(cat out.txt)"
    done
done
