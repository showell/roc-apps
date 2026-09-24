#!/bin/bash
# **A GAME AS A NATIVE PROGRAM**, on roc-ray, from the same files the page runs.
#
#   canvas_apps/native.sh snake
#   TARGET=x64win canvas_apps/native.sh snake     Windows; links only where the SDK is
#
# **NOTHING IS STAGED AND NOTHING IS REWRITTEN**, as with the page. The one
# thing this needs from outside the repository is roc-ray, which
# <app>/main.roc names as a sibling of roc-apps. That is a
# path in the source rather than something a script edits, so it has to be true.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/$(cat "$HERE/../roc-nightly.txt")/roc}"
OUT="${OUT:-$HOME/build/roc-apps/canvas_apps}"
TARGET="${TARGET:-x64glibc}"
OPT="${OPT:-dev}"
name="${1:?usage: canvas_apps/native.sh <app>}"
app="$HERE/$name/main.roc"
[ -f "$app" ] || { echo "no app at $app"; exit 2; }
ray="$HERE/../../roc-ray"
[ -d "$ray" ] || { echo "no roc-ray beside roc-apps at $ray; $name/main.roc names that path"; exit 2; }
case "$TARGET" in
    x64win) host=host.lib; suffix=.exe ;;
    *) host=libhost.a; suffix= ;;
esac
[ -f "$ray/platform/targets/$TARGET/$host" ] \
    || { echo "no $TARGET host in $ray/platform/targets; run zig build there"; exit 2; }

mkdir -p "$OUT/$name"
dest="$(cd "$OUT/$name" && pwd)"
exe="$dest/$name$suffix"
rm -f "$exe"
log="$dest/build-$TARGET-$OPT.log"
t0=$(date +%s)
(cd "$HERE/$name" && "$ROC" build main.roc --target="$TARGET" --opt="$OPT" --output="$exe") > "$log" 2>&1 || true
secs=$(( $(date +%s) - t0 ))
if grep -q "✗" "$log" || [ ! -s "$exe" ]; then cat "$log"; echo "build failed after ${secs}s"; exit 1; fi
echo "built $exe ($OPT) in ${secs}s"
