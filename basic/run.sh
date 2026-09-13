#!/bin/bash
# Corpus programs through basic-run, the interpreter built once by
# basic/build-run.sh. Each program is one process; its time is that process
# alone -- the BASIC interpreter reading the listing and running it -- with
# nothing of the Roc compiler in it.
#
#   basic/run.sh nbs P005 P007
#   basic/run.sh games bunny
#   basic/run.sh nbs              every program in the suite
#
# **A SECOND IS A LONG TIME.** A program over one is marked SLOW, and one
# still running at LIMIT seconds (2) is stopped and marked TIMEOUT.
# Transcripts land in OUT/<suite>/<name>.out, OUT being
# ~/build/roc-apps/gen/basic-native unless set; BIN is the interpreter.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BIN:-$HOME/build/roc-apps/gen/basic/basic-run}"
CORPUS="${BASIC_CORPUS:-$HOME/build/basic-corpus}"
LIMIT="${LIMIT:-2}"
suite="$1"; shift
OUT="${OUT:-$HOME/build/roc-apps/gen/basic-native}/$suite"
mkdir -p "$OUT"
[ -x "$BIN" ] || { echo "no $BIN -- run basic/build-run.sh"; exit 2; }
dialect=micro; [ "$suite" = nbs ] && dialect=ecma
names=("$@")
[ ${#names[@]} -gt 0 ] || mapfile -t names < <(ls "$CORPUS/$suite" | grep -iE '\.bas$' | sed 's/\.[^.]*$//' | sort -u)
for n in "${names[@]}"; do
    listing=""
    for ext in bas BAS; do [ -f "$CORPUS/$suite/$n.$ext" ] && listing="$CORPUS/$suite/$n.$ext"; done
    [ -n "$listing" ] || { printf '%-16s no listing\n' "$n"; continue; }
    # The replies basic/gen.py chose: ours for an NBS program, then the
    # corpus's .input, then its .in.
    replies=""
    if [ "$suite" = nbs ] && [ -s "$HERE/nbs-input/$n.in" ]; then replies="$HERE/nbs-input/$n.in"
    elif [ -f "$CORPUS/$suite/$n.input" ]; then replies="$CORPUS/$suite/$n.input"
    elif [ -f "$CORPUS/$suite/$n.in" ]; then replies="$CORPUS/$suite/$n.in"
    fi
    # **A COMMAND SUBSTITUTION DROPS TRAILING NEWLINES**, and a reply file that
    # ends in an empty line (banner's answer to SET PAGE is Enter) would lose
    # its last reply: each text is read with a marker after it, then cut.
    text="$(cat "$listing"; printf x)"; text="${text%x}"
    keys=""
    if [ -n "$replies" ]; then keys="$(cat "$replies"; printf x)"; keys="${keys%x}"; fi
    t0=$EPOCHREALTIME
    timeout "$LIMIT" "$BIN" "$dialect" "$text" "$keys" > "$OUT/$n.out" 2> "$OUT/$n.err"
    rc=$?
    t1=$EPOCHREALTIME
    ms=$(echo "($t1 - $t0) * 1000" | bc)
    mark=""
    if [ $rc -eq 124 ]; then mark="TIMEOUT"
    elif [ $rc -ne 0 ]; then mark="EXIT $rc: $(head -c 80 "$OUT/$n.err" | tr '\n' ' ')"
    elif [ "$(echo "$ms > 1000" | bc)" = 1 ]; then mark="SLOW"
    fi
    printf '%-16s %9.1f ms %7s bytes  %s\n' "$n" "$ms" "$(wc -c < "$OUT/$n.out")" "$mark"
done
