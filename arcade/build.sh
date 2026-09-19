#!/bin/bash
# **A GAME'S PAGE.** Stages the Roc a game needs, builds its wasm module, and
# puts it beside the arcade's blitter and the game's own page.
#
#   arcade/build.sh snake
#
# The arcade is self-contained: its own platform under wasm/, its own player in
# web/blitter.js, and its own copy of the shape vocabulary in lib/. Nothing
# here imports anything from movie/, so this directory is a whole program.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
name="${1:?usage: arcade/build.sh <game>, a directory under arcade/}"
src="$HERE/$name"
[ -d "$src" ] || { echo "no game at $src"; exit 2; }
app="$(cd "$src" && ls *App.roc 2>/dev/null | head -1)"
[ -n "$app" ] || { echo "no <Name>App.roc in $src"; exit 2; }

OUT="$HOME/build/roc-apps/next/$name"
GEN="$HOME/build/roc-apps/gen/arcade/$name"
mkdir -p "$OUT"
rm -rf "$GEN"; mkdir -p "$GEN"

(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

cp "$HERE/lib"/*.roc "$GEN/"
cp "$src"/*.roc "$GEN/"
platform="$(cd "$HERE/wasm/platform" && pwd)/main.roc"
sed "s|platform \"[^\"]*\"|platform \"$platform\"|" "$GEN/$app" > "$GEN/$app.tmp" && mv "$GEN/$app.tmp" "$GEN/$app"

LOG="$HOME/build/roc-apps/gen/arcade/$name-build.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$OUT/$name.wasm"
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark or a
# missing module, not the exit code.
(cd "$GEN" && "$ROC" build "$app" --target=wasm32 --opt=speed --output="$OUT/$name.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$OUT/$name.wasm" ]; then cat "$LOG"; echo "build failed"; exit 1; fi

cp "$HERE/web/blitter.js" "$OUT/"
cp "$src/page.html" "$OUT/index.html"
ls -la "$OUT"
echo "dev: http://143.244.172.148:9210/$name/"
