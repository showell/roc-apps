#!/bin/bash
# Build an app on roc-ray (raylib) from the platform's source, for one target.
#
#   ray/build.sh halloween                native Linux, into ~/build/roc-apps/ray/halloween/
#   TARGET=x64win ray/build.sh safari     Windows; links only where the Windows SDK is
#                                         installed (.github/workflows/windows.yml)
#
# An app is a movie -- movies/<name>/, whose main.roc plays it on roc-ray, with
# movie/ and ray/player/ staged beside it -- or a plain app under ray/apps/,
# which brings whatever its `modules` file names. Either way the Roc is staged
# into the output directory with the platform reference rewritten to the
# roc-ray checkout's platform/main.roc, as a RELATIVE path (`roc run` refuses
# an absolute one). The checkout must have run
# `zig build -Doptimize=ReleaseFast` (276 s here, every target), which writes the
# host libraries platform/targets/ names. A plain `zig build` is a Debug host:
# Safari's headless frame is 65 ms on it and 34 ms on ReleaseFast.
#
# The environment names everything that differs between this box and a CI
# runner: ROC (the compiler roc-ray pins, nightly-2026-09-07-14d9829), ROC_RAY
# (the checkout), OUT (where outputs go), TARGET, and OPT: `dev` (the default,
# seconds to build) or `speed` (LLVM; Safari builds in 12 s here and paints a
# frame in about 65 ms against 255 ms on dev).
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-07-14d9829/roc}"
ROC_RAY="$(cd "${ROC_RAY:-$HOME/showell_repos/roc-ray}" && pwd)"
OUT="${OUT:-$HOME/build/roc-apps/ray}"
TARGET="${TARGET:-x64glibc}"
OPT="${OPT:-dev}"
name="${1:?usage: ray/build.sh <app>, a movie under movies/ or an app under ray/apps/}"
if [ -f "$HERE/../movies/$name/main.roc" ]; then
    app="$(cd "$HERE/../movies/$name" && pwd)"; movie=yes
elif [ -f "$HERE/apps/$name/main.roc" ]; then
    app="$HERE/apps/$name"; movie=no
else
    echo "no main.roc at movies/$name or ray/apps/$name"; exit 2
fi
case "$TARGET" in
    x64win) host=host.lib; suffix=.exe ;;
    *) host=libhost.a; suffix= ;;
esac
[ -f "$ROC_RAY/platform/targets/$TARGET/$host" ] \
    || { echo "no $TARGET host in $ROC_RAY/platform/targets; run zig build there"; exit 2; }

mkdir -p "$OUT/$name"
dest="$(cd "$OUT/$name" && pwd)"
stage="$dest/src"
rm -rf "$stage"
mkdir -p "$stage"
# What the app imports from elsewhere is staged first, so the app's own files
# win a name clash. A movie brings the shared vocabulary and the player; a
# plain app names its directories in a `modules` file, one a line.
if [ "$movie" = yes ]; then
    cp "$HERE/../movie"/*.roc "$HERE/player"/*.roc "$stage/"
elif [ -f "$app/modules" ]; then
    while read -r dir; do
        [ -z "$dir" ] || cp "$HERE/../$dir"/*.roc "$stage/"
    done < "$app/modules"
fi
cp "$app"/*.roc "$stage/"
# Perl for the relative path and the rewrite: macOS has neither GNU realpath's
# --relative-to nor GNU sed, and Perl is on macOS, Linux and the Windows
# runner's Git Bash alike. The substitution replaces the first reference only.
platform="$(perl -MFile::Spec -e 'print File::Spec->abs2rel($ARGV[0], $ARGV[1])' "$ROC_RAY/platform/main.roc" "$stage")"
PLATFORM="$platform" perl -0pi -e 's/platform "[^"]*"/platform "$ENV{PLATFORM}"/' "$stage/main.roc"
grep -q "platform \"$platform\"" "$stage/main.roc" || { echo "no platform reference to rewrite in $app/main.roc"; exit 2; }

exe="$dest/$name$suffix"
rm -f "$exe"
log="$dest/build-$TARGET-$OPT.log"
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark (✗) or
# a missing executable, not the exit code.
t0=$(date +%s)
"$ROC" build "$stage/main.roc" --target="$TARGET" --opt="$OPT" --output="$exe" > "$log" 2>&1 || true
secs=$(( $(date +%s) - t0 ))
if grep -q "✗" "$log" || [ ! -s "$exe" ]; then
    cat "$log"; echo "build failed after ${secs}s"; exit 1
fi
echo "built $exe ($OPT) in ${secs}s ($(grep -c "●" "$log" || true) warnings)"
