#!/bin/bash
# This builds an app's page: <app>/web.roc into the dev channel, beside the
# canvas_apps's game runner and the game's page.
#
#   canvas_apps/build.sh snake            the dev build: --opt=dev wasm
#   canvas_apps/build.sh snake release    what publishes: --opt=speed wasm
#
# Nothing is staged and nothing is rewritten. Every file compiles where it is
# written. A game's whole self is its own directory, app files included; what
# is outside it -- the vocabulary and the two platform ends -- is reached as a
# package, because a relative import may not climb above an app file and a
# package reference may.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The compiler every roc-apps build uses, so both ends of a game are built
# by one.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../pinned-roc.sh"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
name="${1:?usage: canvas_apps/build.sh <app> [release]}"
case "${2:-}" in
    "") opt=dev ;;
    release) opt=speed ;;
    *) echo "usage: canvas_apps/build.sh <app> [release]"; exit 2 ;;
esac
app="$HERE/$name/web.roc"
[ -f "$app" ] || { echo "no app at $app"; exit 2; }
[ -f "$HERE/$name/page.html" ] || { echo "no page at $HERE/$name/page.html"; exit 2; }
[ -f "$HERE/$name/shot.env" ] || { echo "no shot at $HERE/$name/shot.env"; exit 2; }

# The page is replaced only by a build that passed. Everything is built into a
# staging directory beside DEST, which takes its place at the end, so a failed
# build leaves the page as it was. A caller that gives OUT, as the merge gate
# does, builds into a folder of its own, not the dev channel.
OUT_GIVEN="${OUT:-}"
DEST="${OUT:-$HOME/build/roc-apps/next/$name}"
OUT="$DEST.staging"
rm -rf "$OUT"; mkdir -p "$OUT"
# A release build always starts from an empty cache. A dev build uses the
# caller's, as the merge gate gives it, or else an empty one, and never the
# user's default cache.
MADE_CACHE=""
if [ "$opt" = speed ] || [ -z "${XDG_CACHE_HOME:-}" ]; then
    MADE_CACHE="$(mktemp -d)"
    export XDG_CACHE_HOME="$MADE_CACHE"
fi
trap 'rm -rf "$OUT" $MADE_CACHE' EXIT
(cd "$HERE/web" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")

# The logs live in the staging folder, so two builds at once never read each
# other's. A failure prints its log before the trap removes the folder.
LOG="$OUT/web.log"
GLUE_LOG="$OUT/glue.log"
rm -f "$OUT/$name.wasm"
# Roc exits non-zero for a warning, so the verdict is an error mark or a
# missing module, not the exit code.
(cd "$HERE/$name" && "$ROC" build web.roc --target=wasm32 --opt="$opt" --output="$OUT/$name.wasm") > "$LOG" 2>&1 || true
if grep -q -e "✗" -e "●" "$LOG" || [ ! -s "$OUT/$name.wasm" ]; then cat "$LOG"; echo "build failed"; exit 1; fi

# The frame reader is generated, from the platform's own type table, by the
# compiler that built the wasm. It isn't checked in, and it's never edited.
"$ROC" glue "$HERE/../glue/JsGlue.roc" "$OUT" "$HERE/web/platform/main.roc" > "$GLUE_LOG" 2>&1 \
    || { cat "$GLUE_LOG"; echo "glue failed"; exit 1; }
rm -f "$LOG" "$GLUE_LOG"
cp "$HERE/web/shapes_canvas.js" "$HERE/web/canvas_app_runner.js" "$OUT/"
# Which compiler built this is recorded where the build happens rather than
# guessed later: these pin the nightly roc-ray pins, and the `roc` symlink
# points at a different one.
"$ROC" version | sed 's/Roc compiler version /roc /' > "$OUT/BUILT"
echo "opt $opt" >> "$OUT/BUILT"
cp "$HERE/$name/page.html" "$OUT/index.html"

# A widget's words are real type, so its shot needs the fonts mini_font.mjs
# names, and its check looks at the ink. Other pages paint no type.
case "$name" in
    *_widget) node "$HERE/web/text_check.mjs" raster ;;
    *) node "$HERE/web/text_check.mjs" ;;
esac

# Every build is checked and photographed. page_check runs the page as a
# browser would, with the keys and pointer <app>/shot.env scripts, and saves
# its last frame beside the page as shot.png -- the picture the landing page
# shows. A page that fails the check fails the build, and the picture is never
# older than the wasm it shows.
( set -a; . "$HERE/$name/shot.env"; set +a
  DIR="$OUT" SHOT="$OUT/shot.png" node "$HERE/web/page_check.mjs" "$name" ) || { echo "page check failed"; exit 1; }
rm -rf "$DEST.old"; [ -d "$DEST" ] && mv "$DEST" "$DEST.old"; mv "$OUT" "$DEST"; rm -rf "$DEST.old"
ls -la "$DEST"
if [ -z "$OUT_GIVEN" ]; then echo "dev: http://143.244.172.148:9210/$name/"; fi
