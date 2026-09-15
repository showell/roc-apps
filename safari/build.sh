#!/bin/bash
# Build Safari into the DEV channel: the wasm host (zig, against the roc
# checkout), the app on the nightly compiler, and the page.
#
#   safari/build.sh
#
# Lands at ~/build/roc-apps/next/safari/, served on :9210 by roc-site. The page
# is safari/web/'s copy of safari-codex's index.html and blitter.js.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/safari"
mkdir -p "$NEXT"
(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
# **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is not
# the verdict: an error is marked ✗, and a failed build leaves no module.
# The log stays out of the served directory.
LOG="$HOME/build/roc-apps/gen/safari/build-page.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$NEXT/safari.wasm"
(cd "$HERE/roc" && "$ROC" build SafariApp.roc --target=wasm32 --opt=speed --output="$NEXT/safari.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$NEXT/safari.wasm" ]; then
    cat "$LOG"; echo "build failed"; exit 1
fi
cp "$HERE/web/index.html" "$HERE/web/blitter.js" "$NEXT/"
ls -la "$NEXT"
echo "dev: http://143.244.172.148:9210/safari/   publish with site/publish.sh safari"
