#!/bin/bash
# **FAST TRACK'S PAGE.** Tests the rules, builds the page into the dev
# channel, and plays it.
#
#   fasttrack/build.sh          http://<box>:9210/fasttrack/
#
# In order: SquareValues.roc against its generator; the Roc expects (the
# rules, Example.elm's tests, the codes, the strategy); the
# wasm host; the app, with LLVM, and again with the dev backend; the page's
# reader, generated from the platform's types by glue/JsGlue.roc;
# backends_check.mjs, which plays the two builds against each other and
# fails on any difference (this nightly has miscompiled the page both ways);
# then page_check.mjs, which plays four hundred clicks through the built page
# and paints the last board to shot.png beside it. Any of them failing fails
# the build.
#
# FAST=1 is for looking at a change quickly: no tests, the dev backend only,
# no second build and no checks -- about ten seconds. Not for a commit that
# changes the game.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The compiler every roc-apps page builds with: ../roc-nightly.txt.
ROC="${ROC:-$HOME/build/roc-nightly/$(cat "$HERE/../roc-nightly.txt")/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"

LOG="$HOME/build/roc-apps/gen/fasttrack"
mkdir -p "$LOG"

# **ROC EXITS NON-ZERO FOR A WARNING**, so every verdict below is an error
# mark or a missing artifact, never the exit code.
# **THE PAGE IS REPLACED ONLY BY A BUILD THAT PASSED.** Everything is built
# into a staging directory beside DEST, which takes its place at the end; a
# failed build leaves the page as it was.
DEST="${OUT:-$HOME/build/roc-apps/next/fasttrack}"
OUT="$DEST.staging"
rm -rf "$OUT"; mkdir -p "$OUT"
# **A FRESH CACHE FOR THE WASM BUILDS**: on nightly 09-22 a wasm build that
# reuses the cache of an earlier one can crash the compiler (SIGSEGV).
CACHE="$(mktemp -d)"
trap 'rm -rf "$OUT" "$CACHE"' EXIT
publish() { rm -rf "$DEST.old"; [ -d "$DEST" ] && mv "$DEST" "$DEST.old"; mv "$OUT" "$DEST"; rm -rf "$DEST.old"; }

if [ -n "${FAST:-}" ]; then
    (cd "$HERE/web" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
    (cd "$HERE" && XDG_CACHE_HOME="$CACHE" "$ROC" build web.roc --target=wasm32 --opt=dev --output="$OUT/fasttrack.wasm") > "$LOG/build-dev.log" 2>&1 || true
    if grep -q "✗" "$LOG/build-dev.log" || [ ! -s "$OUT/fasttrack.wasm" ]; then cat "$LOG/build-dev.log"; echo "build failed"; exit 1; fi
    "$ROC" glue "$HERE/../glue/JsGlue.roc" "$OUT" "$HERE/web/platform/main.roc" > "$LOG/glue.log" 2>&1 || { cat "$LOG/glue.log"; echo "glue failed"; exit 1; }
    cp "$HERE/web/fasttrack.js" "$OUT/"
    cp "$HERE/web/page.html" "$OUT/index.html"
    publish
    echo "dev (FAST, dev backend, unchecked): http://143.244.172.148:9210/fasttrack/"
    exit 0
fi
# **THE SQUARE VALUES ARE GENERATED**: SquareValues.roc must be what
# gen_square_values.roc writes from the ranking today.
(cd "$HERE" && "$ROC" gen_square_values.roc) > "$LOG/SquareValues.roc" 2> "$LOG/gen.log" || true
cmp -s "$LOG/SquareValues.roc" "$HERE/SquareValues.roc" || { diff "$HERE/SquareValues.roc" "$LOG/SquareValues.roc" | head; echo "SquareValues.roc is stale: roc gen_square_values.roc > SquareValues.roc"; exit 1; }
(cd "$HERE" && "$ROC" test web.roc) > "$LOG/test.log" 2>&1 || true
if grep -q "✗" "$LOG/test.log" || ! grep -q "^All ([0-9]*) tests passed" "$LOG/test.log"; then
    cat "$LOG/test.log"; echo "tests failed"; exit 1
fi
tail -1 "$LOG/test.log"

(cd "$HERE/web" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

start=$(date +%s)
(cd "$HERE" && XDG_CACHE_HOME="$CACHE" "$ROC" build web.roc --target=wasm32 --opt=speed --output="$OUT/fasttrack.wasm") > "$LOG/build.log" 2>&1 || true
if grep -q "✗" "$LOG/build.log" || [ ! -s "$OUT/fasttrack.wasm" ]; then cat "$LOG/build.log"; echo "build failed"; exit 1; fi
echo "wasm (LLVM): $(( $(date +%s) - start )) s"

# The same source through the dev backend, beside the build rather than in it.
DEV="$LOG/dev-build"
rm -rf "$DEV"; mkdir -p "$DEV"
(cd "$HERE" && XDG_CACHE_HOME="$CACHE" "$ROC" build web.roc --target=wasm32 --opt=dev --output="$DEV/fasttrack.wasm") > "$LOG/build-dev.log" 2>&1 || true
if grep -q "✗" "$LOG/build-dev.log" || [ ! -s "$DEV/fasttrack.wasm" ]; then cat "$LOG/build-dev.log"; echo "dev build failed"; exit 1; fi

"$ROC" glue "$HERE/../glue/JsGlue.roc" "$OUT" "$HERE/web/platform/main.roc" > "$LOG/glue.log" 2>&1 \
    || { cat "$LOG/glue.log"; echo "glue failed"; exit 1; }
cp "$HERE/web/fasttrack.js" "$OUT/"
cp "$OUT/roc_glue.js" "$DEV/"
node "$HERE/web/backends_check.mjs" "$OUT" "$DEV" || { echo "the LLVM and dev builds disagree"; exit 1; }
cp "$HERE/web/page.html" "$OUT/index.html"
"$ROC" version | sed 's/Roc compiler version /roc /' > "$OUT/BUILT"

SHOT="$OUT/shot.png" node "$HERE/web/page_check.mjs" "$OUT" || { echo "page check failed"; exit 1; }
publish
ls -la "$DEST"
echo "dev: http://143.244.172.148:9210/fasttrack/"
