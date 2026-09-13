#!/bin/bash
# The BASIC corpora, into ~/build/basic-corpus. Third-party; not vendored.
#
#   games/  the 1978 Creative Computing listings (Unlicense), each with an
#           .input of keystrokes and an .output of what basic101 printed for
#           them, from basic101's own tests (github.com/wconrad/basic101, at
#           146312a). The captures are basic101's output, so the listings are
#           basic101's listings. A game with a .options file names
#           max_output_lines: it does not end, and its capture is its first
#           that many lines.
#   nbs/    the National Bureau of Standards Minimal BASIC test programs,
#           compiled by John Gatewood Ham, from sehugg/nbs-ecma55-test.
#
# The NBS programs grade themselves.
set -eu
OUT="${BASIC_CORPUS:-$HOME/build/basic-corpus}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone -q --depth 1 https://github.com/sehugg/nbs-ecma55-test.git "$TMP/nbs"
git clone -q https://github.com/wconrad/basic101.git "$TMP/basic101"
git -C "$TMP/basic101" checkout -q 146312a
mkdir -p "$OUT"
rm -rf "$OUT/nbs" "$OUT/games"
cp -r "$TMP/nbs/NBS" "$OUT/nbs"
cp -r "$TMP/basic101/test/integration/tests/basic_computer_games" "$OUT/games"
cp "$TMP/nbs/expected.txt" "$OUT/known-deviations.txt"
echo "$(ls "$OUT"/nbs/*.BAS | wc -l) NBS programs, $(ls "$OUT"/games/*.bas | wc -l) games -> $OUT"
