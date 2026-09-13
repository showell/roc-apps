#!/bin/bash
# Build BASIC into the PREVIEW root: the wasm host (zig, against the roc
# checkout), the app on the nightly compiler, and the page.
#
#   basic/build.sh
#
# Lands at ~/build/roc-apps/next/basic/, served on :9203 by safari-web-next.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/basic"
mkdir -p "$NEXT"
(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
# **THE DEV BACKEND, AS FOR basic-run.** The page sleeps a millisecond a
# PRINT on purpose, so it has no use for LLVM's speed.
# **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is not
# the verdict: an error is marked ✗, and a failed build leaves no module.
# The log stays out of the served directory.
LOG="$HOME/build/roc-apps/gen/basic/build-page.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$NEXT/basic.wasm" "$NEXT/build.log"
(cd "$HERE/roc" && "$ROC" build BasicApp.roc --target=wasm32 --opt=dev --output="$NEXT/basic.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$NEXT/basic.wasm" ]; then
    cat "$LOG"; echo "build failed"; exit 1
fi
cp "$HERE/web/basic.html" "$NEXT/"
ls -la "$NEXT"
echo "preview: http://143.244.172.148:9203/basic/basic.html"
