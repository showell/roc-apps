#!/bin/bash
# Every corpus program through basic-run, instrumented. For each: its wall
# time, the process alone; the statements it executed, which basic-run reports
# on stderr; the time a statement; the statements the program has; and, from a
# second run under strace, its mmap calls (one per heap allocation on Roc's
# default platform).
#
#   basic/timings.sh              both suites
#   basic/timings.sh nbs P134     named programs
#
# Tables land in ~/build/roc-apps/gen/basic-timings/<suite>.tsv, transcripts
# beside them; the slowest programs are printed.
set -u
BASIC_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$BASIC_HERE/corpus.sh"
BIN="${BIN:-$HOME/build/roc-apps/gen/basic/basic-run}"
LIMIT="${LIMIT:-60}"
OUT="$HOME/build/roc-apps/gen/basic-timings"
suites=(nbs games)
names=()
if [ $# -gt 0 ]; then suites=("$1"); shift; names=("$@"); fi
for suite in "${suites[@]}"; do
    dialect=micro; [ "$suite" = nbs ] && dialect=ecma
    mkdir -p "$OUT/$suite"
    list=("${names[@]}")
    [ ${#list[@]} -gt 0 ] || mapfile -t list < <(names_of "$suite")
    tsv="$OUT/$suite.tsv"
    printf 'name\tms\tstatements_run\tus_per_statement\tmmap\tbytes\tprogram_statements\tmark\n' > "$tsv"
    for n in "${list[@]}"; do
        read_text text "$(listing_of "$suite" "$n")"
        keys=""
        replies="$(replies_of "$suite" "$n")"
        [ -n "$replies" ] && read_text keys "$replies"
        t0=$EPOCHREALTIME
        timeout "$LIMIT" "$BIN" "$dialect" "$text" "$keys" > "$OUT/$suite/$n.out" 2> "$OUT/$suite/$n.err"
        rc=$?
        t1=$EPOCHREALTIME
        ms=$(echo "($t1 - $t0) * 1000" | bc)
        mark=""
        if [ $rc -eq 124 ]; then mark=TIMEOUT; elif [ $rc -ne 0 ]; then mark="EXIT $rc"; fi
        steps=$(grep -oE 'steps: [0-9]+' "$OUT/$suite/$n.err" | grep -oE '[0-9]+' | tail -1)
        size=$(grep -oE 'statements: [0-9]+' "$OUT/$suite/$n.err" | grep -oE '[0-9]+' | tail -1)
        per="-"
        [ -n "$steps" ] && [ "$steps" -gt 0 ] && per=$(echo "scale=2; $ms * 1000 / $steps" | bc)
        mm="-"
        if [ -z "$mark" ]; then
            strace -c -f -o "$OUT/$suite/$n.st" timeout "$LIMIT" "$BIN" "$dialect" "$text" "$keys" > /dev/null 2>&1
            mm=$(awk '$NF=="mmap"{print $4}' "$OUT/$suite/$n.st")
        fi
        printf '%s\t%.1f\t%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$ms" "${steps:--}" "$per" "${mm:--}" "$(wc -c < "$OUT/$suite/$n.out")" "${size:--}" "$mark" >> "$tsv"
    done
done
echo "slowest:"
for suite in "${suites[@]}"; do tail -n +2 "$OUT/$suite.tsv" | sed "s/^/$suite\t/"; done | sort -t$'\t' -k3 -gr | head -25 |
    awk -F'\t' '{ printf "  %-6s %-14s %9s ms %11s statements %8s us/statement %9s mmap  %s\n", $1, $2, $3, $4, $5, $6, $9 }'
