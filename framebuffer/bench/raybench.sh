#!/bin/bash
# raytrace-on-screen's trace as a native bench. rocemit writes the demo's
# chapters, RayBench.roc (hand-written) drives Raytracer over the demo's scene
# and camera, and roc builds it with the dev backend, as build.sh builds the
# page. Each mode runs three times; the time is the whole process's.
#
#   framebuffer/bench/raybench.sh [frames] [trace|render]...
#
# `trace` finds every pixel's closest hit and nothing else; `render` is
# rt-render, shading and all. The checksum must not move when the time does.
# `OPT=speed` builds with LLVM instead, which is allowed for a bench this
# small: it prints how long the build took, and a minute is the limit.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
OPT="${OPT:-dev}"
OUT="$HOME/build/roc-apps/gen/raybench"
frames="${1:-30}"
[ $# -gt 0 ] && shift
modes="${*:-trace render}"

rm -rf "$OUT"
mkdir -p "$OUT/emit" "$OUT/roc"
"$ROCEMIT" --by-reach "$HERE/../demos/raytrace-on-screen.codex" "$OUT/emit" > /dev/null
# The demo's own app and its memory are not the bench's.
cp "$OUT/emit"/*.roc "$OUT/roc/"
rm -f "$OUT/roc/RaytraceOnScreen.roc" "$OUT/roc/Mem.roc"
cp "$HERE/RayBench.roc" "$OUT/roc/"
start=$SECONDS
(cd "$OUT/roc" && "$ROC" build --opt="$OPT" RayBench.roc --output="$OUT/bench") > "$OUT/build.log" 2>&1 || { tail -20 "$OUT/build.log"; exit 1; }
echo "built with --opt=$OPT in $((SECONDS - start)) s"

TIMEFORMAT='%R'
for mode in $modes; do
    times=""
    for _ in 1 2 3; do
        t=$( { time "$OUT/bench" "$frames" "$mode" > "$OUT/$mode.out"; } 2>&1 )
        times="$times $t"
    done
    echo "$(cat "$OUT/$mode.out") | $frames frames, seconds:$times"
done
