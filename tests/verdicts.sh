#!/bin/bash
# Clean the verdicts once, into a copy we own.
#
#   tests/verdicts.sh            writes ~/build/roc-apps/gen/verdicts/ and says what it changed
#   tests/verdicts.sh --report   says what it would change, writes nothing
#
# Two kinds of byte in codex/test's .expected files are the console
# capture's and not the program's, and Cobblestone's own harness strips
# both (build/test.ps1: the run output is `-replace "`r", '' -replace
# "^\x01", ''` and the expected is `-replace "`r", ''`):
#
#   * a leading 0x01, in 86 of the 597 files, always exactly one, at byte 0;
#   * carriage returns, in 46 of them, always at a line end;
#   * a trailing EMPTY LINE, which the capture drops: two programs end by
#     printing a blank line, the verdict does not have it, and the same
#     blank line inside the output is there. The ladder strips trailing
#     blank lines from both sides for that reason.
#
# No Codex source in the corpus prints either: none contains a \r escape
# and none writes character code 1. So the cleaning is sound, and doing it
# ONCE here rather than inside the diff means the ladder compares bytes
# with cmp and this script is the only place that touches a verdict.
set -eu
TESTS_ROOT="${TESTS_ROOT:-$HOME/showell_repos/cobblestone-u58}"
SRC="$TESTS_ROOT/codex/test"
OUT="$HOME/build/roc-apps/gen/verdicts"
report_only=no; [ "${1:-}" = --report ] && report_only=yes
soh=0; cr=0; n=0
[ "$report_only" = yes ] || { rm -rf "$OUT"; mkdir -p "$OUT"; }
for f in "$SRC"/*.expected; do
    b="$(basename "$f")"
    n=$((n + 1))
    [ "$(head -c1 "$f" | od -An -tx1 | tr -d ' ')" = 01 ] && soh=$((soh + 1))
    LC_ALL=C grep -qa $'\r' "$f" && cr=$((cr + 1))
    [ "$report_only" = yes ] && continue
    sed '1s/^\x01//' "$f" | tr -d '\r' | awk 'BEGIN{n=0} /^$/{n++; next} {while (n-- > 0) print ""; n=0; print} END{}' > "$OUT/$b"
done
echo "$n verdicts: $soh carry a leading 0x01, $cr carry carriage returns"
[ "$report_only" = yes ] || echo "cleaned into $OUT"
