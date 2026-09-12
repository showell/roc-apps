#!/bin/bash
# Build BASIC into the PREVIEW root: the wasm host (zig, against the roc
# checkout), the app on the nightly compiler, and the page.
#
#   basic/build.sh
#
# Lands at ~/build/roc-apps/next/basic/, served on :9203 by safari-web-next.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT="$HOME/build/roc-apps/next/basic"
OUT="$NEXT" "$HERE/build-wasm.sh"
cp "$HERE/web/basic.html" "$NEXT/"
ls -la "$NEXT"
echo "preview: http://143.244.172.148:9203/basic/basic.html"
