#!/bin/bash
# **TUNING THE COMPUTER**, one factor at a time, by racing (race.mjs).
#
#   fasttrack/web/tune.sh ~/build/roc-apps/next/fasttrack
#
# Each stage races every candidate value of one factor, added to the champion
# so far, against the champion: DEALS deals (default 100), each played abab
# and baba. A candidate takes over only if it wins by more than one standard
# error above 50%, and the best of those does. Then a confirmation race on
# deals no stage has seen (FIRST=1001): the final champion against where it
# started.
#
# Every race line and every stage's verdict goes to stdout.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:?usage: tune.sh <build-dir>}"
DEALS="${DEALS:-100}"
START="${START:-hop=1}"
best="$START"

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

stage hop 4 8 14
stage danger 10 20 40 80
stage out 10 20 40 80
stage home 10 20 40 80

echo "== confirming on fresh deals"
A="$best" B="$START" DEALS="$DEALS" FIRST=1001 node "$HERE/race.mjs" "$DIR"
echo "== champion: {$best}"
