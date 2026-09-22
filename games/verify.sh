#!/bin/bash
# THE ORACLE: Damian's own grader for each game, run against OUR module.
# apps/games/<xx>-verify.mjs plays whole games through the export contract
# and checks the game's invariants (2048's sum, Minesweeper's adjacency
# and flood fill); a Roc module that passes is the game by the rules
# Damian wrote down, not by our reading of them.
#
#   games/verify.sh                 every game
#   games/verify.sh minesweeper     named games
set -u
GAMES_ROOT="${GAMES_ROOT:-$HOME/showell_repos/cobblestone-u62}"
declare -A GRADER=([2048]=g2 [minesweeper]=ms [klondike]=kd)
games=("$@"); [ ${#games[@]} -eq 0 ] && games=(2048 minesweeper klondike)
fail=0
for g in "${games[@]}"; do
    node "$GAMES_ROOT/apps/games/${GRADER[$g]}-verify.mjs" "$HOME/build/roc-apps/next/games/$g.wasm" || fail=1
done
exit $fail
