#!/bin/bash
# Build the games into the PREVIEW root: per game its host (zig, against
# the roc checkout) and its app on the nightly compiler, then the pages.
#
#   games/build.sh              every game in games/gen.py's table
#   games/build.sh 2048         named games
#
# Lands at ~/build/roc-apps/next/games/, served on :9203 by safari-web-next.
# The platforms and hosts are written by games/gen.py, which runs first.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/games"
mkdir -p "$NEXT"
python3 "$HERE/gen.py" >/dev/null
games=("$@"); [ ${#games[@]} -eq 0 ] && games=(2048 minesweeper)
declare -A APP=([2048]=G2048App [minesweeper]=MinesweeperApp)
for g in "${games[@]}"; do
    (cd "$HERE/wasm/$g" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
    (cd "$HERE/roc" && "$ROC" build "${APP[$g]}.roc" --target=wasm32 --opt=speed --output="$NEXT/$g.wasm")
    cp "$HERE/web/$g.html" "$NEXT/"
    ls -la "$NEXT/$g.wasm"
done
echo "preview: http://143.244.172.148:9203/games/<game>.html"
