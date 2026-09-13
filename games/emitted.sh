#!/bin/bash
# THE GATE for the games: a game's wasm shell chapter (and everything it
# cites) emitted to Roc from Cobblestone's apps/games/classic and checked by
# the nightly; on green, written to games/roc/.
#
#   games/emitted.sh                     the games in GAMES below
#   games/emitted.sh Game2048Wasm        named shell chapters, no write
#
# Cites resolve from $GAMES_ROOT, the checkout the games sit in.
# A chapter two games share (Rng, List, ListUtils, Tuple) must emit to the
# same text from both.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
GAMES_ROOT="${GAMES_ROOT:-$HOME/showell_repos/cobblestone-u60rel}"
GEN="$HOME/build/roc-apps/gen/games"
GAMES=(Game2048Wasm MinesweeperWasm KlondikeWasm)
if [ $# -gt 0 ]; then shells=("$@"); write=no; else shells=("${GAMES[@]}"); write=yes; fi
mkdir -p "$GEN"
declare -A seen
pass=0; fail=0; failed=()
for k in "${shells[@]}"; do
    src="$GAMES_ROOT/apps/games/classic/$k.codex"
    dir="$GEN/$k"
    rm -rf "$dir"; mkdir -p "$dir"
    if ! err=$("$ROCEMIT" "$src" "$dir" 2>&1 >/dev/null); then
        echo "FAIL $k: $err"; fail=$((fail+1)); failed+=("$k"); continue
    fi
    for m in "$dir"/*.roc; do
        c="$(basename "$m" .roc)"
        h="$(sha256sum "$m" | cut -c1-16)"
        if [ -n "${seen[$c]:-}" ] && [ "${seen[$c]}" != "$h" ]; then
            echo "FAIL $k: chapter $c differs from its earlier emission"; fail=$((fail+1)); failed+=("$k"); continue 2
        fi
        seen[$c]="$h"
    done
    # **EVERY MODULE, NOT JUST THE SHELL.** `roc check` reports only the
    # file it was given; a broken import compiles to a runtime crash at its
    # own site and says nothing here. Two real defects in the emitted List
    # sat under a green gate that checked the shell alone (2026-09-12).
    # Warnings (●) are tolerated, errors (✗) are not, and roc exits 2 for
    # either -- so the marker is the judge, as safari's gate has it.
    out=""
    for m in "$dir"/*.roc; do
        out="$out$(cd "$dir" && "$ROC" check --no-cache "$(basename "$m")" 2>&1)"
    done
    if echo "$out" | grep -q '✗'; then
        echo "FAIL $k: $(echo "$out" | grep -m1 -A2 '✗' | tr '\n' ' ' | cut -c1-200)"; fail=$((fail+1)); failed+=("$k"); continue
    fi
    pass=$((pass+1))
done
echo "$pass pass, $fail fail${failed:+: ${failed[*]}} -- games from $GAMES_ROOT"
if [ "$write" = yes ] && [ "$fail" -eq 0 ]; then
    for k in "${shells[@]}"; do cp "$GEN/$k"/*.roc "$HERE/roc/"; done
    echo "written to games/roc/"
fi
[ "$fail" -eq 0 ]
