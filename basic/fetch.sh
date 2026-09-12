#!/bin/bash
# The BASIC corpora, into ~/build/basic-corpus. Third-party; not vendored.
#
#   games/  the 1978 Creative Computing listings, from
#           github.com/coding-horror/basic-computer-games (Unlicense),
#           as mirrored with .input/.output captures by sehugg.
#   nbs/    the National Bureau of Standards Minimal BASIC test programs,
#           compiled by John Gatewood Ham, from sehugg/nbs-ecma55-test.
#
# The NBS programs grade themselves; the games carry a capture of what a
# real BASIC printed for the keystrokes in the .input beside them.
set -eu
OUT="${BASIC_CORPUS:-$HOME/build/basic-corpus}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone -q --depth 1 https://github.com/sehugg/nbs-ecma55-test.git "$TMP/src"
mkdir -p "$OUT"
rm -rf "$OUT/nbs" "$OUT/games"
cp -r "$TMP/src/NBS" "$OUT/nbs"
cp -r "$TMP/src/basic_computer_games" "$OUT/games"
cp "$TMP/src/expected.txt" "$OUT/known-deviations.txt"
echo "$(ls "$OUT"/nbs/*.BAS | wc -l) NBS programs, $(ls "$OUT"/games/*.bas | wc -l) games -> $OUT"
