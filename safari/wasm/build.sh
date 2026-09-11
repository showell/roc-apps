#!/bin/bash
# Build the browser module into the PREVIEW root, never the demo: the host
# (zig, against the roc checkout), then the app on the nightly compiler.
#
#   safari/wasm/build.sh
#
# The preview root is ~/build/roc-apps/next/: the page's files copied from
# safari/web/ and the fresh module at driving/safari.wasm, served on :9203 by
# the safari-web-next service. The demo on :9201 serves safari/web/ itself,
# whose module only safari/publish.sh writes.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next"
mkdir -p "$NEXT/driving"
cp "$HERE/../web/index.html" "$HERE/../web/blitter.js" "$NEXT/"
cd "$HERE"
"$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global"
cd "$HERE/../roc"
"$ROC" build SafariApp.roc --target=wasm32 --opt=speed --output="$NEXT/driving/safari.wasm"
ls -la "$NEXT/driving/safari.wasm"
echo "preview: http://143.244.172.148:9203/   publish with safari/publish.sh"
