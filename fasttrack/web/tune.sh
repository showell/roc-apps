#!/bin/bash
# **TUNING THE COMPUTER**, one factor at a time, by racing (race.mjs).
#
#   fasttrack/web/tune.sh ~/build/roc-apps/next/fasttrack                    web/schedules/weights.txt
#   fasttrack/web/tune.sh ~/build/roc-apps/next/fasttrack web/schedules/regions.txt
#
# A schedule is a file of lines (# starts a comment):
#
#   start <spec>                 the champion to begin from (race.mjs's weight spec)
#   stage <factor> <v> <v> ...   race each value of one factor against the champion
#   versus <spec>                at the end, also race the champion against this
#
# Each stage races every candidate value, added to the champion so far,
# against the champion: DEALS deals (default 100), each played abab and baba.
# A candidate takes over only if it wins by more than one standard error above
# 50%, and the best of those does. Then, on deals no stage has seen, the
# champion races where it started (FIRST=1001) and, with `versus`, that
# computer too (FIRST=2001).
#
# Every race line and every stage's verdict goes to stdout.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:?usage: tune.sh <build-dir> [schedule]}"
SCHEDULE="${2:-$HERE/schedules/weights.txt}"
DEALS="${DEALS:-100}"

start=""
versus=""
best=""

stage() {
    local factor=$1; shift
    local champion=$best top=0
    for v in "$@"; do
        local cand="$best,$factor=$v"
        local line pct se
        line=$(A="$cand" B="$best" DEALS="$DEALS" node "$HERE/race.mjs" "$DIR")
        echo "$line"
        pct=$(sed -n 's/.* -- A \([0-9.]*\)% +- \([0-9.]*\).*/\1/p' <<<"$line")
        se=$(sed -n 's/.* -- A \([0-9.]*\)% +- \([0-9.]*\).*/\2/p' <<<"$line")
        if awk -v p="$pct" -v s="$se" -v t="$top" 'BEGIN { exit !(p > 50 + s && p > t) }'; then
            champion=$cand; top=$pct
        fi
    done
    best=$champion
    echo "== after $factor: {$best}"
}

while read -r word rest; do
    case "$word" in
        ""|\#*) ;;
        start) start="$rest"; best="$rest"; echo "== start: {$best}" ;;
        stage) stage $rest ;;
        versus) versus="$rest" ;;
        *) echo "tune.sh: no such schedule line: $word $rest"; exit 2 ;;
    esac
done < "$SCHEDULE"

echo "== confirming on fresh deals"
A="$best" B="$start" DEALS="$DEALS" FIRST=1001 node "$HERE/race.mjs" "$DIR"
if [ -n "$versus" ]; then
    A="$best" B="$versus" DEALS="$DEALS" FIRST=2001 node "$HERE/race.mjs" "$DIR"
fi
echo "== champion: {$best}"
