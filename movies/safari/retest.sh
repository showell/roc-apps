#!/bin/bash
# The targeted sweep: after a rocemit change, only the units whose Roc changed.
#
#   safari/retest.sh
#
# Emits every unit into scratch (fast), compares each module against the
# tracked movies/safari/, and runs, through emitted.sh, exactly the specs whose
# app or imported modules differ. Nothing changed means nothing runs, and
# says so. A full sweep is still the gate before a commit of movies/safari.
set -u
# **RETIRED 2026-09-18, Steve's call: "the Roc program is the new program going
# forward. We should never re-emit Roc from Codex at this point. That's no
# longer worth the trouble."**
#
# movies/safari/*.roc is SOURCE now, hand-edited like any other Roc. This script
# would re-emit and compare, which at best undoes that work and at
# worst deletes it: the line further down removes every file whose header still
# says it was emitted. It refuses rather than explaining itself afterwards.
#
# The Codex program is still the Codex program, and safari-codex still emits
# the zig, the wasm and the C#. It just does not emit this any more.
echo "retired: movies/safari is the program now, not an emission. See the comment in $0." >&2
exit 2


HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
UNITS="${SAFARI_UNITS:-$HOME/showell_repos/safari-codex/units}"
OUT="$HOME/build/roc-apps/gen/retest"
ROC_DIR="$HERE/roc"
[ -x "$ROCEMIT" ] || { echo "no rocemit at $ROCEMIT"; exit 2; }
rm -rf "$OUT"; mkdir -p "$OUT"
declare -A changed
to_run=()
for u in "$UNITS"/*Spec.codex; do
    n="$(basename "$u" .codex)"
    d="$OUT/$n"
    if ! "$ROCEMIT" "$u" "$d" > /dev/null 2> "$OUT/$n.refused"; then
        echo "REFUSED $n  $(head -1 "$OUT/$n.refused")"; to_run+=("$n"); continue
    fi
    differs=""
    for f in "$d"/*.roc; do
        b="$(basename "$f")"
        if ! cmp -s "$f" "$ROC_DIR/$b"; then differs="$differs $b"; changed[$b]=1; fi
    done
    [ -z "$differs" ] || { echo "CHANGED $n:$differs"; to_run+=("$n"); }
done
if [ ${#to_run[@]} -eq 0 ]; then echo "nothing changed against movies/safari; nothing to run"; exit 0; fi
echo "${#changed[@]} module(s) changed; running ${#to_run[@]} unit(s)"
status=0
for n in "${to_run[@]}"; do
    ROCEMIT="$ROCEMIT" "$HERE/emitted.sh" "${n%Spec}" | grep -v " pass, " || status=1
done
exit $status
