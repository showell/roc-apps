#!/bin/bash
# **A GAME'S PAGE.** Builds <game>_web.roc into the dev channel, beside the
# arcade's blitter and the game's page.
#
#   arcade/build.sh snake
#
# **NOTHING IS STAGED AND NOTHING IS REWRITTEN.** Every file compiles where it
# is written: the app at the top of arcade/ is Roc's package root, and
# everything it reaches -- lib/, snake/, web/platform/ -- sits below it. A
# module inside a game may climb to ../lib because that stays within the root.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
name="${1:?usage: arcade/build.sh <game>}"
app="$HERE/${name}_web.roc"
[ -f "$app" ] || { echo "no app at $app"; exit 2; }
[ -f "$HERE/web/$name.html" ] || { echo "no page at $HERE/web/$name.html"; exit 2; }

OUT="$HOME/build/roc-apps/next/$name"
mkdir -p "$OUT"
(cd "$HERE/web" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

LOG="$HOME/build/roc-apps/gen/arcade/$name-web.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$OUT/$name.wasm"
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark or a
# missing module, not the exit code.
(cd "$HERE" && "$ROC" build "${name}_web.roc" --target=wasm32 --opt=speed --output="$OUT/$name.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$OUT/$name.wasm" ]; then cat "$LOG"; echo "build failed"; exit 1; fi

cp "$HERE/web/blitter.js" "$OUT/"
cp "$HERE/web/$name.html" "$OUT/index.html"
ls -la "$OUT"
echo "dev: http://143.244.172.148:9210/$name/"
