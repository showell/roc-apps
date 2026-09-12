#!/bin/bash
# basic.wasm, built once: the host (zig, against the roc checkout) and then
# the interpreter app (the Roc compiler). Each phase is timed on its own.
#
#   basic/build-wasm.sh
#
# Lands in $OUT, by default where basic/runner.mjs reads it.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
OUT="${OUT:-$HOME/build/roc-apps/gen/basic}"
mkdir -p "$OUT"
t0=$(date +%s.%N)
(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
t1=$(date +%s.%N)
# **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is
# not the verdict: an error is marked ✗, and a build that failed leaves no
# fresh output.
rm -f "$OUT/basic.wasm"
(cd "$HERE/roc" && "$ROC" build BasicApp.roc --target=wasm32 --opt=speed --output="$OUT/basic.wasm") 2>&1 | tee "$OUT/build.log" || true
t2=$(date +%s.%N)
if grep -q "✗" "$OUT/build.log" || [ ! -s "$OUT/basic.wasm" ]; then echo "build failed: $OUT/build.log"; exit 1; fi
printf 'zig, the host:              %6.2f s\n' "$(echo "$t1 - $t0" | bc)"
printf 'Roc compiler, the app:      %6.2f s\n' "$(echo "$t2 - $t1" | bc)"
ls -la "$OUT/basic.wasm"
