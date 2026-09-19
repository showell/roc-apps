#!/bin/bash
# **A GAME AS A NATIVE PROGRAM**, on roc-ray, from the same files the page runs.
#
#   arcade/native.sh snake
#   TARGET=x64win arcade/native.sh snake     Windows; links only where the SDK is
#
# Stages lib/, ray/ and the game's own directory into a flat directory and
# builds main.roc, with the platform reference rewritten to the roc-ray
# checkout as a RELATIVE path (`roc run` refuses an absolute one).
#
# **ONLY main.roc IS EDITED, AND ONLY ITS PLATFORM LINE.** Every other file is
# staged byte for byte, which is what lets the game's rules be one file that
# both builds use; `arcade/portable.sh` is the check that says so.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-07-14d9829/roc}"
ROC_RAY="$(cd "${ROC_RAY:-$HOME/showell_repos/roc-ray}" && pwd)"
OUT="${OUT:-$HOME/build/roc-apps/arcade}"
TARGET="${TARGET:-x64glibc}"
OPT="${OPT:-dev}"
name="${1:?usage: arcade/native.sh <game>, a directory under arcade/}"
app="$HERE/$name"
[ -f "$app/main.roc" ] || { echo "no app at $app/main.roc"; exit 2; }
case "$TARGET" in
    x64win) host=host.lib; suffix=.exe ;;
    *) host=libhost.a; suffix= ;;
esac
[ -f "$ROC_RAY/platform/targets/$TARGET/$host" ] \
    || { echo "no $TARGET host in $ROC_RAY/platform/targets; run zig build there"; exit 2; }

mkdir -p "$OUT/$name"
dest="$(cd "$OUT/$name" && pwd)"
stage="$dest/src"
rm -rf "$stage"; mkdir -p "$stage"
cp "$HERE/lib"/*.roc "$HERE/ray"/*.roc "$stage/"
cp "$app"/*.roc "$stage/"
# The wasm app is the other platform's edge and has no place in this build.
rm -f "$stage"/*App.roc

platform="$(perl -MFile::Spec -e 'print File::Spec->abs2rel($ARGV[0], $ARGV[1])' "$ROC_RAY/platform/main.roc" "$stage")"
PLATFORM="$platform" perl -0pi -e 's/platform "[^"]*"/platform "$ENV{PLATFORM}"/' "$stage/main.roc"
grep -q "platform \"$platform\"" "$stage/main.roc" || { echo "no platform reference to rewrite in $app/main.roc"; exit 2; }

exe="$dest/$name$suffix"
rm -f "$exe"
log="$dest/build-$TARGET-$OPT.log"
t0=$(date +%s)
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark or a
# missing executable, not the exit code.
"$ROC" build "$stage/main.roc" --target="$TARGET" --opt="$OPT" --output="$exe" > "$log" 2>&1 || true
secs=$(( $(date +%s) - t0 ))
if grep -q "✗" "$log" || [ ! -s "$exe" ]; then cat "$log"; echo "build failed after ${secs}s"; exit 1; fi
echo "built $exe ($OPT) in ${secs}s"
