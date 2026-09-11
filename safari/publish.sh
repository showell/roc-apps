#!/bin/bash
# THE MANUAL STEP: promote the previewed module to the demo.
#
#   safari/publish.sh
#
# Copies ~/build/roc-apps/next/driving/safari.wasm (what safari/wasm/build.sh
# last built, and what :9202 shows) into safari/web/driving/, writes its
# provenance beside it, and commits and pushes both. The demo on :9201 serves
# the file per request with no-store, so it is live at once. Nothing else
# writes that file.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT="$HOME/build/roc-apps/next/driving/safari.wasm"
[ -f "$NEXT" ] || { echo "no previewed module at $NEXT; run safari/wasm/build.sh first"; exit 2; }
mkdir -p "$HERE/web/driving"
cp "$NEXT" "$HERE/web/driving/safari.wasm"
{
    echo "published $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "roc $("${ROC:-$HOME/build/roc-nightly/roc}" version | sed 's/Roc compiler version //')"
    echo "roc-apps $(git -C "$HERE" rev-parse --short HEAD)$(git -C "$HERE" diff --quiet -- roc wasm || echo ' +uncommitted')"
    echo "rocemit $(git -C "$HOME/showell_repos/rust-codex-compiler" rev-parse --short HEAD)"
    echo "sha256 $(sha256sum "$HERE/web/driving/safari.wasm" | cut -c1-16)  $(stat -c %s "$HERE/web/driving/safari.wasm") bytes"
} > "$HERE/web/driving/PROVENANCE"
cat "$HERE/web/driving/PROVENANCE"
git -C "$HERE" add web/driving
git -C "$HERE" commit -q -m "safari: publish the module to the demo

$(cat "$HERE/web/driving/PROVENANCE")"
git -C "$HERE" push -q
echo "live: http://143.244.172.148:9201/"
