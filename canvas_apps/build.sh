#!/bin/bash
# **AN APP'S PAGE.** Builds <app>/web.roc into the dev channel, beside the
# canvas_apps's game runner and the game's page.
#
#   canvas_apps/build.sh snake
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
name="${1:?usage: canvas_apps/build.sh <app>}"
app="$HERE/$name/web.roc"
[ -f "$app" ] || { echo "no app at $app"; exit 2; }
[ -f "$HERE/$name/page.html" ] || { echo "no page at $HERE/$name/page.html"; exit 2; }
[ -f "$HERE/$name/shot.env" ] || { echo "no shot at $HERE/$name/shot.env"; exit 2; }

OUT="$HOME/build/roc-apps/next/$name"
# Cleared, so yesterday's files cannot be served beside today's.
rm -rf "$OUT"; mkdir -p "$OUT"
(cd "$HERE/web" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

LOG="$HOME/build/roc-apps/gen/canvas_apps/$name-web.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$OUT/$name.wasm"
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark or a
# missing module, not the exit code.
(cd "$HERE/$name" && "$ROC" build web.roc --target=wasm32 --opt=speed --output="$OUT/$name.wasm") > "$LOG" 2>&1 || true
if grep -q "✗" "$LOG" || [ ! -s "$OUT/$name.wasm" ]; then cat "$LOG"; echo "build failed"; exit 1; fi

# **THE FRAME READER IS GENERATED**, from the platform's own type table, by
# the compiler that built the wasm. Not checked in, never edited.
"$ROC" glue "$HERE/../glue/JsGlue.roc" "$OUT" "$HERE/web/platform/main.roc" > "$LOG.glue" 2>&1 \
    || { cat "$LOG.glue"; echo "glue failed"; exit 1; }
cp "$HERE/web/shapewire.js" "$HERE/web/canvas_app_runner.js" "$OUT/"
# **WHICH COMPILER BUILT THIS**, recorded where the build happens rather than
# guessed later: these pin the nightly roc-ray pins, and the `roc` symlink
# points at a different one.
"$ROC" version | sed 's/Roc compiler version /roc /' > "$OUT/BUILT"
cp "$HERE/$name/page.html" "$OUT/index.html"

# **EVERY BUILD IS CHECKED AND PHOTOGRAPHED.** page_check runs the page as a
# browser would, with the keys and pointer <app>/shot.env scripts, and saves
# its last frame beside the page as shot.png -- the picture the landing page
# shows. A page that fails the check fails the build, and the picture is never
# older than the wasm it shows.
( set -a; . "$HERE/$name/shot.env"; set +a
  SHOT="$OUT/shot.png" node "$HERE/web/page_check.mjs" "$name" ) || { echo "page check failed"; exit 1; }
ls -la "$OUT"
echo "dev: http://143.244.172.148:9210/$name/"
