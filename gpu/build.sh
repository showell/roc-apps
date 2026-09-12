#!/bin/bash
# Build the gpu gallery into the PREVIEW root: the host (zig, against the roc
# checkout), then the app on the nightly compiler, then the page.
#
#   gpu/build.sh
#
# Lands at ~/build/roc-apps/next/gpu/, served on :9203 by safari-web-next.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/gpu"
mkdir -p "$NEXT"
cd "$HERE/wasm"
"$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global"
cd "$HERE/roc"
"$ROC" build GalleryApp.roc --target=wasm32 --opt=speed --output="$NEXT/gallery.wasm"
cp "$HERE/web/gallery.html" "$HERE/web/gallery.js" "$NEXT/"
ls -la "$NEXT/gallery.wasm"
echo "preview: http://143.244.172.148:9203/gpu/gallery.html"
