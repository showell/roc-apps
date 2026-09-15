#!/bin/bash
# Build the machine into the PREVIEW root: the wasm host (zig, against the roc
# checkout), the app on the nightly compiler, the page, and a disk image.
#
#   machine/build.sh
#
# Lands at ~/build/roc-apps/next/machine/, served on :9203 by safari-web-next.
# The image is upstream's block-select-drives.disk (128 sectors), copied from
# the checkout; it is never committed here.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
CHECKOUT="${CHECKOUT:-$HOME/showell_repos/cobblestone-u61}"
NEXT="$HOME/build/roc-apps/next/machine"
mkdir -p "$NEXT"
(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
# **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is not
# the verdict: an error is marked ✗, and a failed build leaves no module.
LOG="$HOME/build/roc-apps/gen/machine/build-page.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$NEXT/machine.wasm"
(cd "$HERE/roc" && "$ROC" build MachineApp.roc --target=wasm32 --opt=dev --output="$NEXT/machine.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$NEXT/machine.wasm" ]; then
    cat "$LOG"; echo "build failed"; exit 1
fi
cp "$HERE/web/machine.html" "$NEXT/"
cp "$CHECKOUT/codex/test/block-select-drives.disk" "$NEXT/drive0.img"
ls -la "$NEXT"
echo "preview: http://143.244.172.148:9203/machine/machine.html"
