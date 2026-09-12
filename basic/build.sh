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
(cd "$HERE/roc" && "$ROC" build BasicApp.roc --target=wasm32 --opt=speed --output="$NEXT/basic.wasm")
cp "$HERE/web/basic.html" "$NEXT/"
ls -la "$NEXT"
echo "preview: http://143.244.172.148:9203/basic/basic.html"
