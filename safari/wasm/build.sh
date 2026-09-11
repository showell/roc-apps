#!/bin/bash
# Build the browser module: the host (zig, against the roc checkout), then the
# app on the nightly compiler, into web/driving/safari.wasm, the absolute path
# web/blitter.js fetches.
#
#   safari/wasm/build.sh
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
cd "$HERE"
"$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global"
cd "$HERE/../roc"
"$ROC" build SafariApp.roc --target=wasm32 --opt=speed --output="$HERE/../web/driving/safari.wasm"
ls -la "$HERE/../web/driving/safari.wasm"
