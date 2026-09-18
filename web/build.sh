#!/bin/bash
# **A MOVIE'S PAGE.** Stages the modules a movie needs, builds its wasm app,
# and puts it beside the blitter and a page that names it.
#
#   web/build.sh safari
#   web/build.sh capture_plot
#   web/build.sh particles
#
# A movie is a directory of Roc with an `<Name>App.roc` beside it; the shared
# vocabulary -- Movie, Shapes, Brush, ShapeWire, Font and what they cite --
# lives in safari/roc until a second home earns itself. The platform is
# safari/wasm/platform, which asks for nothing about any particular movie.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
name="${1:?usage: web/build.sh <movie>}"

case "$name" in
    safari)       dirs="safari/roc"; app="SafariApp.roc" ;;
    capture_plot) dirs="safari/roc movies/capture_plot"; app="CapturePlotApp.roc" ;;
    particles)    dirs="safari/roc movies/particles"; app="ParticlesApp.roc" ;;
    *) echo "no movie called $name"; exit 2 ;;
esac

OUT="$HOME/build/roc-apps/next/$name"
GEN="$HOME/build/roc-apps/gen/web/$name"
mkdir -p "$OUT"
rm -rf "$GEN"; mkdir -p "$GEN"

# The host is the same for every movie.
(cd "$HERE/safari/wasm" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

for d in $dirs; do cp "$HERE/$d"/*.roc "$GEN/"; done
# The staged app is not where it was written, so its platform reference is
# rewritten to where the platform actually is.
platform="$(cd "$HERE/safari/wasm/platform" && pwd)/main.roc"
sed "s|platform \"[^\"]*\"|platform \"$platform\"|" "$GEN/$app" > "$GEN/$app.tmp" && mv "$GEN/$app.tmp" "$GEN/$app"

LOG="$HOME/build/roc-apps/gen/web/$name-build.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$OUT/$name.wasm"
(cd "$GEN" && "$ROC" build "$app" --target=wasm32 --opt=speed --output="$OUT/$name.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$OUT/$name.wasm" ]; then cat "$LOG"; echo "build failed"; exit 1; fi

cp "$HERE/safari/web/blitter.js" "$OUT/"
cp "$HERE/web/$name.html" "$OUT/index.html"
ls -la "$OUT"
echo "dev: http://143.244.172.148:9210/$name/"
