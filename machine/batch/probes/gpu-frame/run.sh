#!/bin/bash
# MachineGpu's frame at three widths, on Roc's default platform (an mmap per
# allocation): the mmap count says whether the planes are written in place
# (flat in the width) or copied (growing with the pixels), and the time says
# what a pixel costs.
#
#   machine/batch/probes/gpu-frame/run.sh [stage]    stage: all (default) or clear
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
W="$HOME/build/roc-apps/gen/probes/gpu-frame"
mkdir -p "$W"
cp "$HERE/Probe.roc" "$HERE/../../../roc/MachineGpu.roc" "$W/"
cd "$W" && "$ROC" build Probe.roc --opt=dev --output="$W/probe" > build.log 2>&1
grep -a -m3 -A4 '✗' build.log && exit 1
for w in 160 320 640; do
    out=$(./probe "$w" "${1:-all}")
    mmaps=$(strace -f -c -e trace=mmap ./probe "$w" "${1:-all}" 2>&1 >/dev/null | awk '/mmap/ {print $4}')
    secs=$( { /usr/bin/time -f '%e' ./probe "$w" "${1:-all}" > /dev/null; } 2>&1 | tail -1)
    printf 'width %4s  pixels %7s  drawn %7s  mmap %8s  %ss\n' "$w" "$((w * w * 3 / 4))" "$out" "$mmaps" "$secs"
done
