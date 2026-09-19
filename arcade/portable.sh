#!/bin/bash
# **WHICH FILES DO BOTH BUILDS USE, BYTE FOR BYTE?**
#
#   arcade/portable.sh snake        after building the game both ways
#
# A game's rules should be ONE file that the page and the native program both
# run -- not two copies, and not one copy rewritten on its way into a build.
# This compares what each build actually staged against the source in the
# repository and says which files survived untouched, which were edited, and
# which only one build saw.
#
# Only the two platform edges may be edited or one-sided: <Name>App.roc names
# the wasm platform and main.roc names roc-ray, and a build rewrites that one
# line. Anything else appearing here is the seam leaking.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
name="${1:?usage: arcade/portable.sh <game>}"
web="$HOME/build/roc-apps/gen/arcade/$name"
native="$HOME/build/roc-apps/arcade/$name/src"
[ -d "$web" ] || { echo "no page build; run arcade/build.sh $name"; exit 2; }
[ -d "$native" ] || { echo "no native build; run arcade/native.sh $name"; exit 2; }

same=0; edited=0; oneside=0
printf '%-22s %-10s %-10s\n' FILE PAGE NATIVE
for src in "$HERE/lib"/*.roc "$HERE/ray"/*.roc "$HERE/$name"/*.roc; do
    f="$(basename "$src")"
    w="absent"; n="absent"
    [ -f "$web/$f" ] && { cmp -s "$src" "$web/$f" && w="verbatim" || w="EDITED"; }
    [ -f "$native/$f" ] && { cmp -s "$src" "$native/$f" && n="verbatim" || n="EDITED"; }
    if [ "$w" = verbatim ] && [ "$n" = verbatim ]; then
        same=$((same + 1)); continue            # the portable set: not listed, counted
    fi
    printf '%-22s %-10s %-10s\n' "$f" "$w" "$n"
    if [ "$w" = EDITED ] || [ "$n" = EDITED ]; then edited=$((edited + 1)); else oneside=$((oneside + 1)); fi
done
echo
echo "$same files run by both builds byte for byte; $edited edited by a build; $oneside seen by one."
