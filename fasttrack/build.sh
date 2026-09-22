#!/bin/bash
# **FAST TRACK'S PAGE.** Tests the rules, builds the page into the dev
# channel, and plays it.
#
#   fasttrack/build.sh          http://<box>:9210/fasttrack/
#
# In order: the Roc expects (the rules, Example.elm's tests, the codes); the
# wasm host; the app, with LLVM; the page's reader, generated from the
# platform's types by glue/JsGlue.roc; then page_check.mjs, which plays four
# hundred clicks through the built page and paints the last board to
# shot.png beside it. Any of them failing fails the build.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The compiler canvas_apps builds with, so the two pages share one.
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-07-14d9829/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"

LOG="$HOME/build/roc-apps/gen/fasttrack"
mkdir -p "$LOG"

# **ROC EXITS NON-ZERO FOR A WARNING**, so every verdict below is an error
# mark or a missing artifact, never the exit code.
(cd "$HERE" && "$ROC" test web.roc) > "$LOG/test.log" 2>&1 || true
if grep -q "✗" "$LOG/test.log" || ! grep -q "^All ([0-9]*) tests passed" "$LOG/test.log"; then
    cat "$LOG/test.log"; echo "tests failed"; exit 1
fi
tail -1 "$LOG/test.log"

OUT="$HOME/build/roc-apps/next/fasttrack"
# Cleared, so yesterday's files cannot be served beside today's.
rm -rf "$OUT"; mkdir -p "$OUT"
(cd "$HERE/web" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

start=$(date +%s)
(cd "$HERE" && "$ROC" build web.roc --target=wasm32 --opt=speed --output="$OUT/fasttrack.wasm") > "$LOG/build.log" 2>&1 || true
if grep -q "✗" "$LOG/build.log" || [ ! -s "$OUT/fasttrack.wasm" ]; then cat "$LOG/build.log"; echo "build failed"; exit 1; fi
echo "wasm (LLVM): $(( $(date +%s) - start )) s"

"$ROC" glue "$HERE/../glue/JsGlue.roc" "$OUT" "$HERE/web/platform/main.roc" > "$LOG/glue.log" 2>&1 \
    || { cat "$LOG/glue.log"; echo "glue failed"; exit 1; }
cp "$HERE/web/fasttrack.js" "$OUT/"
cp "$HERE/web/page.html" "$OUT/index.html"
"$ROC" version | sed 's/Roc compiler version /roc /' > "$OUT/BUILT"

SHOT="$OUT/shot.png" node "$HERE/web/page_check.mjs" "$OUT" || { echo "page check failed"; exit 1; }
ls -la "$OUT"
echo "dev: http://143.244.172.148:9210/fasttrack/"
