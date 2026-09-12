#!/bin/bash
# THE LADDER for rocemit: Cobblestone's own test corpus, codex/test/, every
# program beside an .expected verdict emitted to Roc, run on the Echo
# platform, and its output diffed against the verdict.
#
#   tests/ladder.sh                 the whole corpus (~600 units)
#   tests/ladder.sh effect-smoke    named units
#
# Cites resolve from $TESTS_ROOT (exported as CODEX_ROOT for rocemit; the
# box's own CODEX_ROOT names another tree). A unit with a .diag beside it
# expects a diagnostic, not output, and is skipped by name. Outputs land in
# ~/build/roc-apps/gen/tests/<unit>/ and nothing here is tracked: the
# ledger is the summary this prints, by outcome and refusal reason, and
# tests/ledger.txt when a full run writes it.
#
# A verdict is compared as text: a leading 0x01 byte and carriage returns in
# an .expected file are the console capture's, not the program's.
#
# A unit whose verdict pins a semantics Roc does not have is DIVERGES, by
# name and with the reason, never a silent FAIL: see DIVERGE below.
#
# Outcomes: PASS (output equals the verdict), FAIL (it does not, or roc
# printed ✗), CRASH (roc run died), REFUSED (rocemit said no, by reason),
# TIMEOUT.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
TESTS_ROOT="${TESTS_ROOT:-$HOME/showell_repos/cobblestone-u58}"
export CODEX_ROOT="$TESTS_ROOT"
SRC="$TESTS_ROOT/codex/test"
GEN="$HOME/build/roc-apps/gen/tests"
mkdir -p "$GEN"
if [ $# -gt 0 ]; then units=("$@"); full=no; else
    mapfile -t units < <(cd "$SRC" && ls *.expected | sed 's/\.expected$//' | sort); full=yes
fi
# **THE VERDICT PINS A SEMANTICS ROC DOES NOT HAVE.** Codex's list-set-at
# mutates in place, so two names for one list see each other's writes;
# Roc's List.set answers a new list and the old name keeps its value. A
# program that reads a list it has already written THROUGH ANOTHER NAME
# therefore cannot be ported, and this one exists to pin that behaviour.
# (A case, not an array: the runner is `bash -c` per unit and an array
# does not cross that.)
diverges() {
    case "$1" in
        edalias) echo "list-set-at mutates in place; Roc's List.set answers a new list" ;;
        ui-event-test) echo "list-push mutates a list two siblings share; Roc's List.append answers a new one" ;;
    esac
}
one() {
    n="$1"; d="$GEN/$n"; rm -rf "$d"; mkdir -p "$d"
    if [ -f "$SRC/$n.diag" ]; then echo "SKIP $n | expects a diagnostic" > "$d/verdict"; return; fi
    why="$(diverges "$n")"
    if [ -n "$why" ]; then echo "DIVERGES $n | $why" > "$d/verdict"; return; fi
    if ! app=$("$ROCEMIT" "$SRC/$n.codex" "$d" 2> "$d/emit.err"); then
        echo "REFUSED $n | $(head -1 "$d/emit.err" | sed 's/^REFUSED: //' | cut -c1-110)" > "$d/verdict"; return
    fi
    app="$(echo "$app" | head -1)"
    if [ "$app" = library ]; then echo "REFUSED $n | no opening" > "$d/verdict"; return; fi
    ( cd "$d" && timeout 120 "$ROC" run "$app" > out 2> err ); rc=$?
    if [ $rc -eq 124 ]; then echo "TIMEOUT $n |" > "$d/verdict"
    elif grep -q "✗" "$d/err"; then echo "FAIL $n | compile: $(grep -m1 -A2 '✗' "$d/err" | tr '\n' ' ' | cut -c1-110)" > "$d/verdict"
    elif diff -q "$d/out" <(verdict_text "$n") > /dev/null; then echo "PASS $n |" > "$d/verdict"
    elif grep -q "crashed\|Backtrace\|overflowed" "$d/err"; then echo "CRASH $n | $(grep -m1 -hoE 'crashed[^\n]*|overflowed[^\n]*' "$d/err" | head -1 | cut -c1-100)" > "$d/verdict"
    else echo "FAIL $n | output: $(diff "$d/out" <(verdict_text "$n") | grep -m1 '^[<>]' | cut -c1-100)" > "$d/verdict"; fi
}
# The verdict as text: 86 of the 597 .expected files start with a 0x01 byte
# and 46 carry carriage returns, the console capture's, not the program's.
verdict_text() { sed '1s/^\x01//' "$SRC/$1.expected" | tr -d '\r'; }
export -f verdict_text
export -f one verdict_text diverges; export ROC ROCEMIT SRC GEN
printf '%s\n' "${units[@]}" | xargs -P "${JOBS:-2}" -I{} bash -c 'one {}'
ledger="$( for n in "${units[@]}"; do cat "$GEN/$n/verdict"; done )"
[ "$full" = yes ] && echo "$ledger" > "$HERE/ledger.txt"
echo "$ledger" | grep -v '^PASS' | sort
echo "--- by outcome:"; echo "$ledger" | cut -d' ' -f1 | sort | uniq -c | sort -rn
echo "--- refusals by reason:"; echo "$ledger" | grep '^REFUSED' | cut -d'|' -f2 | sed 's/`[^`]*`/`_`/g' | sort | uniq -c | sort -rn | head -20
echo "$(echo "$ledger" | grep -c '^PASS') pass of ${#units[@]} -- tests from $TESTS_ROOT"
