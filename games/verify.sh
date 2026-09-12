#!/bin/bash
# THE ORACLE: Damian's own grader for the game, run against OUR module.
# apps/games/g2-verify.mjs plays 25 games through the export contract and
# checks the sum invariant after every move; a Roc module that passes it
# is 2048 by the rules Damian wrote down, not by our reading of them.
#
#   games/verify.sh            the previewed module
set -eu
GAMES_ROOT="${GAMES_ROOT:-$HOME/showell_repos/cobblestone-u58}"
node "$GAMES_ROOT/apps/games/g2-verify.mjs" "$HOME/build/roc-apps/next/games/2048.wasm"
