#!/bin/bash
# **RUN THIS ON THE WINDOWS BOX (WSL), NOT ON THE BUILD BOX.** It pulls the
# movie executables the Windows workflow built -- and that the build box
# downloaded from the run -- into ~/roc-ray, and makes them executable.
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
echo "run one, from $DEST:"
echo "  ./halloween.exe      a child walks up to a house  (SPACE pause, up/down step, J a second, P screenshot)"
echo "  ./safari.exe         the drive"
echo "  ./particles.exe      the fountain"
echo "  ./capture_plot.exe   the plot drawing itself"
