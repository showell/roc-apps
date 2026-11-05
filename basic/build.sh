#!/bin/bash
# Build BASIC into the DEV channel: the wasm host (zig, against the roc
# checkout), the app on the nightly compiler, and the page. The page is
# replaced only by a build whose page_check.mjs passed.
#
#   basic/build.sh
#
# Lands at ~/build/roc-apps/next/basic/, served on :9210 by roc-site.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../pinned-roc.sh"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/basic"
# Everything is built into a staging directory beside the page, which takes
# its place at the end, so a failed build leaves the page as it was.
OUT="$NEXT.staging"
rm -rf "$OUT"; mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
# **THE DEV BACKEND, AS FOR basic-run.** The page sleeps a millisecond a
# PRINT on purpose, so it has no use for LLVM's speed.
# The Roc compiler exits non-zero for a warning too, so its exit code is not
# the verdict: an error is marked ✗ and a warning ●, either fails the build,
# and a failed build leaves no module.
# The log stays out of the served directory.
LOG="$HOME/build/roc-apps/gen/basic/build-page.log"
mkdir -p "$(dirname "$LOG")"
(cd "$HERE/roc" && "$ROC" build BasicApp.roc --target=wasm32 --opt=dev --output="$OUT/basic.wasm") > "$LOG" 2>&1 || true
if grep -q -e "✗" -e "●" "$LOG" || [ ! -s "$OUT/basic.wasm" ]; then
    cat "$LOG"; echo "build failed"; exit 1
fi
cp "$HERE/web/index.html" "$HERE/web/basic.html" "$OUT/"
node "$HERE/page_check.mjs" "$OUT" || { echo "page check failed"; exit 1; }
rm -rf "$NEXT.old"; [ -d "$NEXT" ] && mv "$NEXT" "$NEXT.old"; mv "$OUT" "$NEXT"; rm -rf "$NEXT.old"
ls -la "$NEXT"
echo "dev: http://143.244.172.148:9210/basic/"
