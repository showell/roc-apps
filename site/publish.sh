#!/bin/bash
# THE SIGN-OFF: move what the dev channel shows into staging, one app at a time.
#
#   site/publish.sh safari      an app: safari, basic, machine, framebuffer, gpu, games;
#                               a movie: capture_plot, particles, halloween; or a canvas
#                               app: snake, pong, breakout, camera, workshop, trick_or_treat
#   site/publish.sh home        the landing page and shared/
#
# An app: copies ~/build/roc-apps/next/<app>/ (what <app>'s build.sh last wrote,
# and what :9210/<app>/ shows) over site/live/<app>/ whole, writes a PROVENANCE
# beside it, and commits and pushes that directory alone. `home` does the same
# for the landing page and shared/; dev's `channel` file stays behind, so
# staging holds exactly what prod will. Staging on :9200 serves site/live/ per
# request with no-store, so it is live at once. Nothing else writes site/live/.
#
# PROVENANCE records what the build read: the Roc compiler, the roc-apps and
# rocemit commits (marked when the app's own tree has uncommitted changes), the
# Cobblestone checkout the emitters resolve against, and a hash of each module.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
NEXT="$HOME/build/roc-apps/next"
LIVE="$HERE/live"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT_REPO="$HOME/showell_repos/rust-codex-compiler"
COBBLESTONE="${COBBLESTONE:-$HOME/showell_repos/cobblestone-u61}"
[ $# -eq 1 ] || { echo "usage: site/publish.sh <app> | home"; exit 2; }
app="$1"
mkdir -p "$LIVE"
if [ "$app" = home ]; then
    [ -f "$NEXT/index.html" ] || { echo "no landing page at $NEXT; run site/build.sh first"; exit 2; }
    cp "$NEXT/index.html" "$LIVE/"
    rm -rf "$LIVE/shared"
    cp -r "$NEXT/shared" "$LIVE/"
    paths=("$LIVE/index.html" "$LIVE/shared")
    what="the landing page"
else
    # An app is a directory of this repository -- at the top for the older
    # ones, under movies/ for a movie, under canvas_apps/ for a canvas app.
    src="$app"
    [ -d "$REPO/$src" ] || src="movies/$app"
    [ -d "$REPO/$src" ] || src="canvas_apps/$app"
    [ -d "$REPO/$src" ] || { echo "$app is not an app, a movie or a canvas app in $REPO"; exit 2; }
    [ -d "$NEXT/$app" ] || { echo "no dev build at $NEXT/$app; run $app's build.sh first"; exit 2; }
    rm -rf "$LIVE/$app"
    cp -r "$NEXT/$app" "$LIVE/$app"
    {
        echo "published $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "roc $("$ROC" version | sed 's/Roc compiler version //')"
        echo "roc-apps $(git -C "$REPO" rev-parse --short HEAD)$(git -C "$REPO" diff --quiet HEAD -- "$src" || echo ' +uncommitted')"
        echo "rocemit $(git -C "$ROCEMIT_REPO" rev-parse --short HEAD)$(git -C "$ROCEMIT_REPO" diff --quiet HEAD || echo ' +uncommitted')"
        echo "cobblestone $(git -C "$COBBLESTONE" rev-parse --short HEAD) $(git -C "$COBBLESTONE" branch --show-current)"
        (cd "$LIVE/$app" && find . -name '*.wasm' | sort | while read -r w; do
            echo "sha256 $(sha256sum "$w" | cut -c1-16)  $(stat -c %s "$w") bytes  ${w#./}"
        done)
    } > "$LIVE/$app/PROVENANCE"
    cat "$LIVE/$app/PROVENANCE"
    paths=("$LIVE/$app")
    what="$app"
fi
git -C "$REPO" add -A -- "${paths[@]}"
git -C "$REPO" commit -q -m "site: publish $what to staging

$([ "$app" = home ] || cat "$LIVE/$app/PROVENANCE")" -- "${paths[@]}"
git -C "$REPO" push -q
echo "published $what to staging: http://143.244.172.148:9200/"
