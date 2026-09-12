#!/bin/bash
# THE MANUAL STEP: promote the previewed gallery to the demo.
#
#   gpu/publish.sh
#
# Copies ~/build/roc-apps/next/gpu/ (what gpu/build.sh last built: the page,
# the manifest and the module, and what :9203/gpu/ shows) into gpu/live/,
# writes its provenance beside them, and commits and pushes. The demo on
# :9204 serves gpu/live/ per request with no-store, so it is live at once.
# Nothing else writes that directory. The three files go together because
# the manifest numbers the demos the module dispatches.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT="$HOME/build/roc-apps/next/gpu"
[ -f "$NEXT/gallery.wasm" ] || { echo "no previewed gallery at $NEXT; run gpu/build.sh first"; exit 2; }
mkdir -p "$HERE/live"
cp "$NEXT/gallery.html" "$NEXT/gallery.js" "$NEXT/gallery.wasm" "$HERE/live/"
{
    echo "published $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "roc $("${ROC:-$HOME/build/roc-nightly/roc}" version | sed 's/Roc compiler version //')"
    echo "roc-apps $(git -C "$HERE" rev-parse --short HEAD)$(git -C "$HERE" diff --quiet -- gpu/roc gpu/wasm gpu/web gpu/gallery.py || echo ' +uncommitted')"
    echo "rocemit $(git -C "$HOME/showell_repos/rust-codex-compiler" rev-parse --short HEAD)"
    echo "kernels $(git -C "${KERNELS_ROOT:-$HOME/showell_repos/cobblestone-u58}" rev-parse --short HEAD) ${KERNELS_ROOT:-$HOME/showell_repos/cobblestone-u58}"
    echo "sha256 $(sha256sum "$HERE/live/gallery.wasm" | cut -c1-16)  $(stat -c %s "$HERE/live/gallery.wasm") bytes  $(grep -c 'id:' "$HERE/live/gallery.js") demos"
} > "$HERE/live/PROVENANCE"
cat "$HERE/live/PROVENANCE"
git -C "$HERE" add live
git -C "$HERE" commit -q -m "gpu: publish the gallery to the demo

$(cat "$HERE/live/PROVENANCE")"
git -C "$HERE" push -q
echo "live: http://143.244.172.148:9204/gallery.html"
