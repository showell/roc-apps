#!/bin/bash
# Every row of verify.tsv built on the floor and run, its console compared with
# what the row expects.
#
#   floor/verify.sh
#
# A row is three tab-separated columns: the program, the host flags to run it
# with (`-` for none), and what its console must be -- either `verdict`, the
# unit's own cleaned .expected from the ladder, or a path in this repo.
#
# The fault rows are the point of the table. A run with a fault in it is still
# a run whose console is pinned, so the floor breaking its promises is a
# regression test rather than an anecdote: if the Roc above starts coping
# differently, this says so.
#
# Prints a line a row and exits 1 when any fails. Each program's build log and
# output stay in ~/build/roc-apps/gen/floor/<program>/.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CHECKOUT="${CHECKOUT:-$HOME/showell_repos/cobblestone-u61}"
GEN="$HOME/build/roc-apps/gen/floor"
VERDICTS="$HOME/build/roc-apps/gen/verdicts"
mkdir -p "$GEN"

progs=()
rows=()
while IFS=$'\t' read -r prog flags want; do
    case "$prog" in ''|'#'*) continue ;; esac
    case "$prog" in
        cobblestone:*) path="$CHECKOUT/${prog#cobblestone:}" ;;
        roc-apps:*) path="$REPO/${prog#roc-apps:}" ;;
        *) echo "verify.tsv: $prog is neither cobblestone: nor roc-apps:"; exit 2 ;;
    esac
    [ -f "$path" ] || { echo "verify.tsv: no such program, $path"; exit 2; }
    rows+=("$path"$'\t'"$flags"$'\t'"$want")
    case " ${progs[*]-} " in *" $path "*) ;; *) progs+=("$path") ;; esac
done < "$HERE/verify.tsv"

if ! "$HERE/build.sh" "${progs[@]}" > "$GEN/verify-build.log" 2>&1; then
    tail -20 "$GEN/verify-build.log"
    echo "build.sh failed; its log is $GEN/verify-build.log"
    exit 1
fi

# Trailing blank lines are not part of a console's text.
trimmed() { sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'; }

failed=0
i=0
while IFS=$'\t' read -r path flags want; do
    i=$((i + 1))
    n="$(basename "$path" .codex)"
    case "$want" in
        verdict) expect="$VERDICTS/$n.expected" ;;
        *) expect="$REPO/$want" ;;
    esac
    if [ ! -f "$expect" ]; then
        echo "FAIL $n | nothing to compare with at $expect"
        failed=1
        continue
    fi
    args=()
    [ "$flags" != "-" ] && read -ra args <<< "$flags"
    [ -f "${path%.codex}.disk" ] && args=(-disk "${path%.codex}.disk" "${args[@]}")
    [ -f "${path%.codex}.disk2" ] && args=(-disk2 "${path%.codex}.disk2" "${args[@]}")
    out="$GEN/$n.$i.out"
    (cd "$CHECKOUT" && "$GEN/$n/native" "${args[@]}") > "$out" 2> "$GEN/$n.$i.err"
    code=$?
    label="$n${flags:+ | }$([ "$flags" = "-" ] && echo "clean" || echo "$flags")"
    if [ $code -ne 0 ]; then
        echo "FAIL $label | exit $code: $(head -1 "$GEN/$n.$i.err")"
        failed=1
    elif [ "$(trimmed < "$out")" != "$(trimmed < "$expect")" ]; then
        echo "FAIL $label | the console differs from $want; see $out"
        failed=1
    else
        echo "PASS $label"
    fi
done < <(printf '%s\n' "${rows[@]}")
exit $failed
