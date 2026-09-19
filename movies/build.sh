#!/bin/bash
# **A MOVIE'S PAGE.** Stages the Roc a movie needs, builds its wasm module, and
# puts it beside the blitter and the movie's own page.
#
#   movies/build.sh safari
#   movies/build.sh capture_plot
#   movies/build.sh particles
#   movies/build.sh halloween
#
# A movie is a directory under movies/, and every one of them holds the same
# five things: <Name>.roc is the movie, <Name>App.roc is the wasm app,
# main.roc is the roc-ray app (ray/build.sh builds that one), page.html is the
# page, and whatever other Roc the movie owns sits beside them. `movie/` is the
# vocabulary they share -- Movie, Shapes, Brush, View, BrushGlsl, ShapeWire,
# Font, and the arithmetic those need. The platform is wasm/platform, which
# asks for nothing about any particular movie.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
name="${1:?usage: movies/build.sh <movie>, a directory under movies/}"
src="$HERE/movies/$name"
[ -d "$src" ] || { echo "no movie at $src"; exit 2; }
app="$(cd "$src" && ls *App.roc 2>/dev/null | head -1)"
[ -n "$app" ] || { echo "no <Name>App.roc in $src"; exit 2; }

OUT="$HOME/build/roc-apps/next/$name"
GEN="$HOME/build/roc-apps/gen/web/$name"
mkdir -p "$OUT"
rm -rf "$GEN"; mkdir -p "$GEN"

# The host is the same for every movie.
(cd "$HERE/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

cp "$HERE/movie"/*.roc "$GEN/"
cp "$src"/*.roc "$GEN/"
# The staged app is not where it was written, so its platform reference is
# rewritten to where the platform actually is.
platform="$(cd "$HERE/wasm/platform" && pwd)/main.roc"
sed "s|platform \"[^\"]*\"|platform \"$platform\"|" "$GEN/$app" > "$GEN/$app.tmp" && mv "$GEN/$app.tmp" "$GEN/$app"

LOG="$HOME/build/roc-apps/gen/web/$name-build.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$OUT/$name.wasm"
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark (✗) or
# a missing module, not the exit code.
(cd "$GEN" && "$ROC" build "$app" --target=wasm32 --opt=speed --output="$OUT/$name.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$OUT/$name.wasm" ]; then cat "$LOG"; echo "build failed"; exit 1; fi

cp "$HERE/web/blitter.js" "$OUT/"
cp "$src/page.html" "$OUT/index.html"
ls -la "$OUT"
echo "dev: http://143.244.172.148:9210/$name/   publish with site/publish.sh $name"
