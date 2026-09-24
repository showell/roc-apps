#!/bin/bash
# Build BASIC into the DEV channel: the wasm host (zig, against the roc
# checkout), the app on the nightly compiler, and the page.
#
#   basic/build.sh
#
# Lands at ~/build/roc-apps/next/basic/, served on :9210 by roc-site.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# **NOT ../roc-nightly.txt**: BasicApp crashes every nightly after 09-11
# (findings/basic-compiler-crash), so BASIC builds on the last one that works.
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-11-793f9d8/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/basic"
mkdir -p "$NEXT"
(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
# **THE DEV BACKEND, AS FOR basic-run.** The page sleeps a millisecond a
# PRINT on purpose, so it has no use for LLVM's speed.
# **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is not
# the verdict: an error is marked ✗, and a failed build leaves no module.
# The log stays out of the served directory.
LOG="$HOME/build/roc-apps/gen/basic/build-page.log"
mkdir -p "$(dirname "$LOG")"
# Built beside the page and moved in only when it built: a failed build
# leaves the page's module as it was.
NEW="$(mktemp -d)"
trap 'rm -rf "$NEW"' EXIT
rm -f "$NEXT/build.log"
(cd "$HERE/roc" && "$ROC" build BasicApp.roc --target=wasm32 --opt=dev --output="$NEW/basic.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$NEW/basic.wasm" ]; then
    cat "$LOG"; echo "build failed"; exit 1
fi
mv "$NEW/basic.wasm" "$NEXT/basic.wasm"
cp "$HERE/web/index.html" "$HERE/web/basic.html" "$NEXT/"
ls -la "$NEXT"
echo "dev: http://143.244.172.148:9210/basic/"
