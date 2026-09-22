#!/bin/bash
# Every row of verify.tsv built on the floor and run, its console compared with
# what the row expects.
#
#   floor/verify.sh
#
# A row is four tab-separated columns: the program, the host flags to run it
# with (`-` for none), what its console must be -- either `verdict`, the unit's
# own cleaned .expected from the ladder, or a path in this repo -- and, for a
# program with a screen, the hash its last frame must draw (`-` for none).
#
# A hash here is the one the framebuffer platform and the machine page's
# MachineGpu both drew, so a screen row is a check that this floor draws the
# same image as the two things that came before it.
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
CHECKOUT="${CHECKOUT:-$HOME/showell_repos/cobblestone-u62}"
GEN="$HOME/build/roc-apps/gen/floor"
VERDICTS="$HOME/build/roc-apps/gen/verdicts"
mkdir -p "$GEN"

progs=()
rows=()
while IFS=$'\t' read -r prog flags want hash; do
    case "$prog" in ''|'#'*) continue ;; esac
    case "$prog" in
        cobblestone:*) path="$CHECKOUT/${prog#cobblestone:}" ;;
        roc-apps:*) path="$REPO/${prog#roc-apps:}" ;;
        *) echo "verify.tsv: $prog is neither cobblestone: nor roc-apps:"; exit 2 ;;
    esac
    [ -f "$path" ] || { echo "verify.tsv: no such program, $path"; exit 2; }
    rows+=("$path"$'\t'"$flags"$'\t'"$want"$'\t'"$hash")
    case " ${progs[*]-} " in *" $path "*) ;; *) progs+=("$path") ;; esac
done < "$HERE/verify.tsv"

if ! "$HERE/build.sh" "${progs[@]}" > "$GEN/verify-build.log" 2>&1; then
    tail -20 "$GEN/verify-build.log"
    echo "build.sh failed; its log is $GEN/verify-build.log"
    exit 1
fi

# A console is what the program printed: the host's own lines, which all begin
# `-- `, are not part of it, and trailing blank lines are not either.
trimmed() { grep -v '^-- ' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'; }

failed=0
i=0
while IFS=$'\t' read -r path flags want hash; do
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
    label="$n | $([ "$flags" = "-" ] && echo "clean" || echo "$flags")"
    got="-"
    [ "$hash" != "-" ] && got="$(grep '^-- frame' "$out" | tail -1)" && got="${got##*hash }"
    if [ $code -ne 0 ]; then
        echo "FAIL $label | exit $code: $(head -1 "$GEN/$n.$i.err")"
        failed=1
    elif [ "$(trimmed < "$out")" != "$(trimmed < "$expect")" ]; then
        echo "FAIL $label | the console differs from $want; see $out"
        failed=1
    elif [ "$hash" != "-" ] && [ "$got" != "$hash" ]; then
        echo "FAIL $label | hash $got, want $hash"
        failed=1
    else
        echo "PASS $label${got:+$([ "$hash" != "-" ] && echo " | hash $got")}"
    fi
done < <(printf '%s\n' "${rows[@]}")
exit $failed
