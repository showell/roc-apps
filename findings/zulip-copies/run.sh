#!/bin/bash
# The copy probes, built with LLVM (--opt=speed) and with the dev backend, and
# measured by how their time scales.
#
#   findings/zulip-copies/run.sh
#
# thread/*: 10,000 writes into a list inside a record, at three list sizes.
# Each variant prints CPU seconds and mmap calls from strace (on the default
# platform every heap value is its own mmap, so a copy per write is about
# 10,000). A time flat in the size means the writes are in place; one that
# grows with the size, beside a large mmap count, means the list is copied.
#
# RecordWidth: 20 million steps carrying one record of 4, 32 and 256 F64
# fields (record_width.py writes it). Flat in the width means the record is
# not copied a step.
#
# Every build prints its time. Nothing is written outside a temporary directory.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
SIZES=${SIZES:-"286 4096 65536"}
WIDTHS=${WIDTHS:-"4 32 256"}
STEPS=${STEPS:-20000000}
# A run past this many seconds is cut off and shows as its limit.
RUN_LIMIT=${RUN_LIMIT:-120}

cpu() { /usr/bin/time -f "%U %S" timeout "$RUN_LIMIT" "$@" 2>&1 >/dev/null | tail -1 | awk '{printf "%.2f", $1 + $2}'; }
mmaps() { timeout "$RUN_LIMIT" strace -c -f -o "$T/st" "$@" > /dev/null 2>&1; awk '$NF=="mmap"{print $4}' "$T/st"; }
build() {  # build <dir> <file> <opt>
    local start=$SECONDS
    (cd "$1" && "$ROC" build "$2" --opt="$3" --output="bin-$3") > "$1/build-$3.log" 2>&1 || true
    if [ -x "$1/bin-$3" ]; then echo "  built $(basename "$1") --opt=$3 in $((SECONDS - start)) s"; else echo "  $(basename "$1") --opt=$3 FAILED to build"; tail -5 "$1/build-$3.log"; fi
}

echo "zulip-copies $(date -u +%FT%TZ), $("$ROC" version)"
variants=()
for d in "$HERE"/thread/*/; do
    v="$(basename "$d")"
    variants+=("$v")
    mkdir -p "$T/$v" && cp "$d/App.roc" "$T/$v/"
    for opt in speed dev; do build "$T/$v" App.roc $opt; done
done
for opt in speed dev; do
    echo "thread --opt=$opt (10,000 writes)"
    for v in "${variants[@]}"; do
        line="$(printf '  %-20s' "$v")"
        for sz in $SIZES; do
            line="$line $(printf '%6ss %6s mmap @%-6s' "$(cpu "$T/$v/bin-$opt" "$sz")" "$(mmaps "$T/$v/bin-$opt" "$sz")" "$sz")"
        done
        echo "$line"
    done
done

for k in $WIDTHS; do
    mkdir -p "$T/width$k"
    python3 "$HERE/record_width.py" "$k" > "$T/width$k/RecordWidth.roc"
    for opt in speed dev; do build "$T/width$k" RecordWidth.roc $opt; done
done
for opt in speed dev; do
    line="$(printf 'RecordWidth --opt=%-6s (%s steps)' "$opt" "$STEPS")"
    for k in $WIDTHS; do
        line="$line $(printf '%6ss @%-4s' "$(cpu "$T/width$k/bin-$opt" "$STEPS")" "$k")"
    done
    echo "$line"
done
