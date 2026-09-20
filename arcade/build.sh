#!/bin/bash
# **A GAME'S PAGE.** Builds <game>_web.roc into the dev channel, beside the
# arcade's game runner and the game's page.
#
#   arcade/build.sh snake
#
# **NOTHING IS STAGED AND NOTHING IS REWRITTEN.** Every file compiles where it
# is written. A game's whole self is its own directory, app files included;
# what is outside it -- the vocabulary and the two platform ends -- is reached
# as a package, because a relative import may not climb above an app file and a
# package reference may.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The compiler roc-ray pins, so both ends of a game are built by one.
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-07-14d9829/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
name="${1:?usage: arcade/build.sh <game>}"
app="$HERE/${name}_web.roc"
[ -f "$app" ] || { echo "no app at $app"; exit 2; }
[ -f "$HERE/$name/page.html" ] || { echo "no page at $HERE/$name/page.html"; exit 2; }

OUT="$HOME/build/roc-apps/next/$name"
# Cleared, so yesterday's files cannot be served beside today's.
rm -rf "$OUT"; mkdir -p "$OUT"
(cd "$HERE/web" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

LOG="$HOME/build/roc-apps/gen/arcade/$name-web.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$OUT/$name.wasm"
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark or a
# missing module, not the exit code.
(cd "$HERE" && "$ROC" build "${name}_web.roc" --target=wasm32 --opt=speed --output="$OUT/$name.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$OUT/$name.wasm" ]; then cat "$LOG"; echo "build failed"; exit 1; fi

cp "$HERE/web/shapewire.js" "$HERE/web/canvas_app_runner.js" "$OUT/"
cp "$HERE/$name/page.html" "$OUT/index.html"
ls -la "$OUT"
echo "dev: http://143.244.172.148:9210/$name/"
