#!/bin/bash
# **RUN THIS ON THE WINDOWS BOX (WSL), NOT ON THE BUILD BOX.** It pulls the
# executables the Windows workflow built -- and that the build box downloaded
# from the run -- into ~/roc-ray, and makes them executable: the eight canvas
# apps.
#
#   scp steve@143.244.172.148:showell_repos/roc-apps/ray/fetch_exes.sh ~/
#   chmod u+x ~/fetch_exes.sh && ~/fetch_exes.sh
#
# The environment names everything that could differ: BOX (the build box),
# SRC (where its download landed), DEST (where they go here).
set -eu
BOX="${BOX:-steve@143.244.172.148}"
SRC="${SRC:-/home/steve/build/roc-apps/ray/windows}"
DEST="${DEST:-$HOME/roc-ray}"

mkdir -p "$DEST"
# One executable per directory in the artifact; they land flat here, because
# each is named after its movie already.
scp "$BOX:$SRC/*/*.exe" "$DEST/"
chmod u+x "$DEST"/*.exe
ls -l "$DEST"/*.exe
echo
echo "run one, from $DEST.  ESC quits, F shows the frame rate."
echo "  ./safari.exe            the drive: SPACE pauses, left/right step, J next intersection, R restarts"
echo "  ./snake.exe             arrows turn, SPACE starts again"
echo "  ./pong.exe              W and S, or hold the left button to aim"
echo "  ./breakout.exe          left and right, or the pointer; SPACE serves"
echo "  ./camera.exe            WASD move, wheel zooms, Q/E turn, R levels"
echo "  ./workshop.exe          drag to paint, 1-4 or click a swatch, C resets"
echo "  ./particles.exe         the pointer steers the fountain, SPACE widens it"
echo "  ./trick_or_treat.exe    SPACE pauses, left/right scrub, J skips a second, R restarts"
