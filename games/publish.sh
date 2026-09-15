#!/bin/bash
# THE MANUAL STEP: promote the previewed games to the demo.
#
#   games/publish.sh
#
# Copies ~/build/roc-apps/next/games/ (what games/build.sh last built: each
# game's page and module, and what :9203/games/ shows) into games/live/,
# writes its provenance beside them, and commits and pushes. The demo on
# :9205 serves games/live/ per request with no-store, so it is live at
# once. Nothing else writes that directory. A page and its module go
# together because the page reads the module's view words.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT="$HOME/build/roc-apps/next/games"
ls "$NEXT"/*.wasm >/dev/null 2>&1 || { echo "no previewed games at $NEXT; run games/build.sh first"; exit 2; }
mkdir -p "$HERE/live"
cp "$NEXT"/*.html "$NEXT"/*.wasm "$HERE/live/"
{
    echo "published $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "roc $("${ROC:-$HOME/build/roc-nightly/roc}" version | sed 's/Roc compiler version //')"
    echo "roc-apps $(git -C "$HERE" rev-parse --short HEAD)$(git -C "$HERE" diff --quiet -- games/roc games/wasm games/web games/gen.py || echo ' +uncommitted')"
    echo "rocemit $(git -C "$HOME/showell_repos/rust-codex-compiler" rev-parse --short HEAD)"
    echo "games $(git -C "${GAMES_ROOT:-$HOME/showell_repos/cobblestone-u61}" rev-parse --short HEAD) ${GAMES_ROOT:-$HOME/showell_repos/cobblestone-u61}"
    for w in "$HERE"/live/*.wasm; do echo "sha256 $(sha256sum "$w" | cut -c1-16)  $(stat -c %s "$w") bytes  $(basename "$w")"; done
} > "$HERE/live/PROVENANCE"
cat "$HERE/live/PROVENANCE"
git -C "$HERE" add live
git -C "$HERE" commit -q -m "games: publish to the demo

$(cat "$HERE/live/PROVENANCE")"
git -C "$HERE" push -q
echo "live: http://143.244.172.148:9205/<game>.html for $(ls "$HERE"/live/*.wasm | xargs -n1 basename | sed "s/.wasm//" | tr "\n" " ")"
