#!/bin/bash
# Build the games into the PREVIEW root: the host (zig, against the roc
# checkout), then each app on the nightly compiler, then the pages.
#
#   games/build.sh
#
# Lands at ~/build/roc-apps/next/games/, served on :9203 by safari-web-next.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/games"
mkdir -p "$NEXT"
cd "$HERE/wasm"
"$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global"
cd "$HERE/roc"
"$ROC" build G2048App.roc --target=wasm32 --opt=speed --output="$NEXT/2048.wasm"
cp "$HERE/web/2048.html" "$NEXT/"
ls -la "$NEXT/2048.wasm"
echo "preview: http://143.244.172.148:9203/games/2048.html"
