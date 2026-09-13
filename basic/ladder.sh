#!/bin/bash
# THE BASIC LADDER: every program in the corpus run by our Roc interpreter
# and graded against what it must show.
#
#   basic/ladder.sh                 the games corpus (99 programs)
#   basic/ladder.sh nbs             the NBS conformance suite (208)
#   basic/ladder.sh games 23-match  named programs
#
# The corpus is ~/build/basic-corpus, fetched by basic/fetch.sh:
#
#   games/  the 1978 Creative Computing listings (Unlicense), each with
#           an .input of the keystrokes and an .output of what a real
#           BASIC printed. Byte-exact grading.
#   nbs/    the National Bureau of Standards Minimal BASIC test programs.
#           These GRADE THEMSELVES: a conformant interpreter never prints
#           the words TEST FAILED. **A PROGRAM THAT STOPS ON AN EXCEPTION
#           MAY STILL HAVE PASSED** -- seven of them exist to check that a
#           subscript out of range DOES stop it -- so the interpreter says
#           HALTED for an ECMA-55 exception and UNSUPPORTED for a form it
#           has not built, and only the second is a failure here.
#
# Each program runs through basic-run (basic/build-run.sh builds it once),
# one process each, by basic/run.sh; this script grades the transcripts.
#
# Outcomes: PASS, FAIL (output differs, or the NBS program said so), CRASH,
# TIMEOUT, KILLED (a signal), UNJUDGED (an NBS ERROR program with no row in
# nbs-reports.txt: it is malformed on purpose and prints no verdict, so
# running clean says nothing either way).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORPUS="${BASIC_CORPUS:-$HOME/build/basic-corpus}"
RUNS="$HOME/build/roc-apps/gen/basic-ladder"
suite="${1:-games}"; shift || true
[ -d "$CORPUS/$suite" ] || { echo "no corpus at $CORPUS/$suite -- run basic/fetch.sh"; exit 2; }
if [ $# -gt 0 ]; then names=("$@"); else
    mapfile -t names < <(cd "$CORPUS/$suite" && ls *.bas *.BAS 2>/dev/null | sed 's/\.[bB][aA][sS]$//' | sort)
fi
mkdir -p "$RUNS"
OUT="$RUNS" LIMIT="${LIMIT:-60}" "$HERE/run.sh" "$suite" "${names[@]}" > "$RUNS/$suite.log"

# What run.sh said of a program after its name, time and size: TIMEOUT,
# EXIT n: ..., SLOW, or nothing.
mark_of() { awk -v n="$1" '$1==n { $1=$2=$3=$4=$5=""; sub(/^ +/, ""); print; exit }' "$RUNS/$suite.log"; }

grade() {
    n="$1"; out="$RUNS/$suite/$n.out"; err="$RUNS/$suite/$n.err"
    mark="$(mark_of "$n")"
    rc=0
    case "$mark" in EXIT\ *) rc="${mark#EXIT }"; rc="${rc%%:*}";; esac
    if [ "$mark" = TIMEOUT ]; then echo "TIMEOUT $n |"
    elif [ "$rc" -ge 128 ]; then echo "KILLED $n | signal $((rc - 128))"
    # **AN EMPTY TRANSCRIPT IS A CRASH.** A stack overflow prints no TEST
    # FAILED, so without this it grades as a pass.
    elif [ ! -s "$out" ] || { [ "$rc" -ne 0 ] && grep -q 'Roc application\|crashed' "$err"; }; then
        echo "CRASH $n | exit $rc: $(grep -v '^$' "$err" | head -1 | cut -c1-80)"
    elif [ "$suite" = nbs ]; then
        row="$(grep "^$n |" "$HERE/nbs-reports.txt")"
        kind="$(echo "$row" | cut -s -d'|' -f2 | tr -d ' ')"
        missing=""
        while IFS= read -r want; do
            [ -n "$want" ] && ! grep -qF -- "$want" "$out" && missing="$want"
        done < <(echo "$row" | cut -s -d'|' -f3- | tr '|' '\n' | sed 's/^ *//; s/ *$//')
        error_program=""
        grep -m1 'PROGRAM FILE' "$CORPUS/$suite/$n.BAS" | grep -q ': *ERROR' && error_program=1
        # A row of kind `ignores` names instruction lines that read as verdicts.
        verdicts="$out"
        if [ "$kind" = ignores ]; then
            verdicts="$RUNS/$suite/$n.verdicts"
            sed 's/^ *//; s/ *$//' "$out" | grep -vxF -f <(echo "$row" | cut -s -d'|' -f3- | tr '|' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$') > "$verdicts"
        fi
        if grep -q '^\*\*\* REJECTED' "$out" && [ "$kind" != rejects ]; then
            echo "FAIL $n | $(grep -m1 'REJECTED' "$out" | cut -c1-90)"
        elif [ "$kind" != judged ] && [ "$kind" != rejects ] && [ "$kind" != reader ] && grep -q "TEST FAILED\|TEST FAILS" "$verdicts"; then
            echo "FAIL $n | $(grep -m1 'TEST FAIL' "$verdicts" | cut -c1-90)"
        elif grep -q "UNSUPPORTED" "$out"; then
            echo "FAIL $n | $(grep -m1 'UNSUPPORTED' "$out" | cut -c1-90)"
        # **A HALT PASSES ONLY WHERE THE ROW REQUIRES ONE.** A program stopped
        # before its verdict prints no TEST FAILED either.
        elif grep -q '^\*\*\* HALTED' "$out" && ! echo "$row" | grep -qF '*** HALTED'; then
            echo "FAIL $n | $(grep -m1 'HALTED' "$out" | cut -c1-90)"
        elif [ -n "$missing" ]; then
            echo "FAIL $n | no report: $missing"
        elif [ "$kind" = reader ]; then
            echo "UNJUDGED $n | a reader compares its output; no grep can"
        elif [ -n "$error_program" ] && [ -z "$row" ]; then
            echo "UNJUDGED $n | an ERROR program with no row in nbs-reports.txt"
        else echo "PASS $n |"; fi
    # **A GAME WITH max_output_lines DOES NOT END** (its .options): the
    # capture is what basic101 printed until its test harness stopped it,
    # then the harness's own line. The game passes when the capture without
    # that line is where the transcript starts.
    elif [ -f "$CORPUS/$suite/$n.options" ]; then
        want="$RUNS/$suite/$n.want"
        sed -E '$ s/Error on line [0-9]+: Maximum output lines reached$//' "$CORPUS/$suite/$n.output" | head -c -1 > "$want"
        if [ "$(wc -c < "$out")" -ge "$(wc -c < "$want")" ] && cmp -s -n "$(wc -c < "$want")" "$want" "$out"; then echo "PASS $n | the capture's first $(wc -l < "$want") lines"
        else echo "FAIL $n | $(diff <(head -n "$(wc -l < "$want")" "$out") "$want" | grep -m1 '^[<>]' | cut -c1-90)"; fi
    elif cmp -s "$out" "$CORPUS/$suite/$n.output"; then echo "PASS $n |"
    else echo "FAIL $n | $(diff "$out" "$CORPUS/$suite/$n.output" | grep -m1 '^[<>]' | cut -c1-90)"; fi
}
ledger="$( for n in "${names[@]}"; do grade "$n"; done )"
echo "$ledger" > "$HERE/ledger-$suite.txt"
echo "$ledger" | grep -v '^PASS' | sort | head -40
echo "--- by outcome:"; echo "$ledger" | cut -d' ' -f1 | sort | uniq -c | sort -rn
echo "$(echo "$ledger" | grep -c '^PASS') pass of ${#names[@]} -- $suite"
