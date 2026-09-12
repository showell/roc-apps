#!/bin/bash
# THE BASIC LADDER: every program in the corpus run by our Roc interpreter
# and diffed against the output a real BASIC produced.
#
#   basic/ladder.sh                 the games corpus (99 programs)
#   basic/ladder.sh nbs             the NBS conformance suite (219)
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
# Roc has no file or stdin effect on the default platform, so each program
# becomes its own app with the listing and the keystrokes as literals; the
# generator is basic/gen.py.
#
# Outcomes: PASS, FAIL (output differs, or the NBS program said so), CRASH,
# TIMEOUT, KILLED (a signal -- 9 is the OOM killer stopping compile-time
# evaluation).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
CORPUS="${BASIC_CORPUS:-$HOME/build/basic-corpus}"
GEN="$HOME/build/roc-apps/gen/basic"
suite="${1:-games}"; shift || true
mkdir -p "$GEN"
[ -d "$CORPUS/$suite" ] || { echo "no corpus at $CORPUS/$suite -- run basic/fetch.sh"; exit 2; }
if [ $# -gt 0 ]; then names=("$@"); else
    mapfile -t names < <(cd "$CORPUS/$suite" && ls *.bas *.BAS 2>/dev/null | sed 's/\.[bB][aA][sS]$//' | sort)
fi
one() {
    n="$1"; d="$GEN/$suite/$n"
    mkdir -p "$d"
    if ! "$HERE/gen.py" "$suite" "$n" "$d" 2> "$d/gen.err"; then
        echo "FAIL $n | generate: $(head -1 "$d/gen.err" | cut -c1-90)" > "$d/verdict"; return
    fi
    cp "$HERE/roc/Basic.roc" "$d/Basic.roc"
    ( cd "$d" && timeout 120 "$ROC" run Run.roc > out 2> err ); rc=$?
    if [ $rc -ge 128 ]; then echo "KILLED $n | signal $((rc - 128))" > "$d/verdict"
    elif [ $rc -eq 124 ]; then echo "TIMEOUT $n |" > "$d/verdict"
    elif grep -q "✗" "$d/err"; then echo "CRASH $n | compile: $(grep -m1 -A2 '✗' "$d/err" | tr '\n' ' ' | cut -c1-90)" > "$d/verdict"
    elif [ "$suite" = nbs ]; then
        if grep -q "TEST FAILED\|TEST FAILS" "$d/out"; then
            echo "FAIL $n | $(grep -m1 'TEST FAIL' "$d/out" | cut -c1-90)" > "$d/verdict"
        elif grep -q "UNSUPPORTED" "$d/out"; then
            echo "FAIL $n | $(grep -m1 'UNSUPPORTED' "$d/out" | cut -c1-90)" > "$d/verdict"
        else echo "PASS $n |" > "$d/verdict"; fi
    elif cmp -s "$d/out" "$CORPUS/$suite/$n.output"; then echo "PASS $n |" > "$d/verdict"
    else echo "FAIL $n | $(diff "$d/out" "$CORPUS/$suite/$n.output" | grep -m1 '^[<>]' | cut -c1-90)" > "$d/verdict"; fi
}
export -f one; export ROC CORPUS GEN HERE suite
printf '%s\n' "${names[@]}" | xargs -P "${JOBS:-3}" -I{} bash -c 'one {}'
ledger="$( for n in "${names[@]}"; do cat "$GEN/$suite/$n/verdict"; done )"
echo "$ledger" > "$HERE/ledger-$suite.txt"
echo "$ledger" | grep -v '^PASS' | sort | head -40
echo "--- by outcome:"; echo "$ledger" | cut -d' ' -f1 | sort | uniq -c | sort -rn
echo "$(echo "$ledger" | grep -c '^PASS') pass of ${#names[@]} -- $suite"
