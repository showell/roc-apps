#!/bin/bash
# THE SIGN-OFF: move what the dev channel shows into staging, one app at a time.
#
#   site/publish.sh safari      an app: basic, machine, framebuffer, gpu, games; or a
#                               canvas app: safari, snake, pong, breakout, camera,
#                               workshop, particles, trick_or_treat
#   site/publish.sh tutorial    the Safari Ride book, with every widget and app it
#                               frames (each published first, if staging differs)
#   site/publish.sh home        the landing page and shared/
#
# An app: copies ~/build/roc-apps/next/<app>/ (what <app>'s build.sh last wrote,
# and what :9210/<app>/ shows) over site/live/<app>/ whole, writes a PROVENANCE
# beside it, and commits and pushes that directory alone. A canvas app must be a
# release build (`canvas_apps/build.sh <app> release`). `home` does the same
# for the landing page and shared/; dev's `channel` file stays behind, so
# staging holds exactly what prod will. Staging on :9200 serves site/live/ per
# request with no-store, so it is live at once. Nothing else writes site/live/.
#
# PROVENANCE records what the build read: the Roc compiler, the roc-apps
# commit (marked when the app's own tree has uncommitted changes), a hash of
# each module, and for an app built from emitted Codex (gpu, games, machine,
# framebuffer) the rocemit commit and the Cobblestone checkout the emitter
# resolved against. A canvas app and basic read neither, so record neither.
# A checkout an app needs and that is missing stops the publish before
# site/live/ is touched.
#
# PUBLISH_DRY_RUN=1 writes the PROVENANCE and stops before git; with NEXT and
# LIVE pointed at scratch copies it touches nothing tracked.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
NEXT="${NEXT:-$HOME/build/roc-apps/next}"
LIVE="${LIVE:-$HERE/live}"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../pinned-roc.sh"
ROCEMIT_REPO="${ROCEMIT_REPO:-$HOME/showell_repos/rust-codex-compiler}"
COBBLESTONE="${COBBLESTONE:-$HOME/showell_repos/cobblestone-u66rel}"

# Whether an app's build read rocemit and Cobblestone. A canvas app never does,
# so it passes unnamed; any other app this doesn't name is refused, so a new
# one gets a decision rather than a blank line.
reads_emitted_codex() {
    case "$1" in
        gpu|games|machine|framebuffer) return 0 ;;
        basic|tutorial) return 1 ;;
        *) [ "$2" = "canvas_apps/$1" ] && return 1
           echo "publish.sh doesn't know whether $1 reads rocemit and Cobblestone; name it in reads_emitted_codex"; exit 2 ;;
    esac
}

# A checkout the PROVENANCE must name; missing, the publish stops.
require_checkout() {
    local what="$1" dir="$2" var="$3"
    git -C "$dir" rev-parse --short HEAD > /dev/null 2>&1 || {
        echo "$app reads $what, and there is no git checkout at $dir; set $var= to the checkout the build used"; exit 2
    }
}
# The book publishes only a build of book.shale. A page staging has is never
# taken away, since its address is published. The widgets and apps the book
# frames ship with it: each one whose staged copy isn't the build the book was
# checked with is published first, from the dev channel, by this same script.
# The list comes from the built pages' own frames, so it can't go stale.
publish_book_frames() {
    local book="$NEXT/tutorial" page folder
    [ -f "$book/BUILT" ] || { echo "$book is not a build of canvas_apps/safari/tutorial/book.shale"; exit 2; }
    for page in "$LIVE"/tutorial/*.html; do
        [ -e "$page" ] || continue
        [ -f "$book/${page##*/}" ] || { echo "staging has tutorial/${page##*/} and this book doesn't: a published page never goes away"; exit 2; }
    done
    for folder in $(grep -oh 'src="\.\./[a-z_]*/' "$book"/*.html | sed 's|^src="\.\./||; s|/$||' | sort -u); do
        if [ -d "$LIVE/$folder" ] && diff -rq -x BUILT -x PROVENANCE -x BOOK_INPUTS "$NEXT/$folder" "$LIVE/$folder" > /dev/null; then
            echo "the book frames $folder, as staged"
        else
            echo "the book frames $folder; publishing it first"
            "$HERE/publish.sh" "$folder" || { echo "publishing $folder failed, so the book waits"; exit 2; }
        fi
    done
}
[ $# -eq 1 ] || { echo "usage: site/publish.sh <app> | home"; exit 2; }
app="$1"
mkdir -p "$LIVE"
if [ "$app" = home ]; then
    [ -f "$NEXT/index.html" ] || { echo "no landing page at $NEXT; run site/build.sh first"; exit 2; }
    # Dev must show the landing page as site/web has it, or this would publish
    # an older one and say nothing.
    if ! diff -q "$HERE/web/index.html" "$NEXT/index.html" > /dev/null || ! diff -rq "$HERE/web/shared" "$NEXT/shared" > /dev/null; then
        echo "dev's landing page is older than site/web/; run site/build.sh, look at http://143.244.172.148:9210/, then publish"; exit 2
    fi
    cp "$NEXT/index.html" "$LIVE/"
    rm -rf "$LIVE/shared"
    cp -r "$NEXT/shared" "$LIVE/"
    paths=("$LIVE/index.html" "$LIVE/shared")
    what="the landing page"
else
    # An app is a directory of this repository -- at the top for the older
    # ones, under canvas_apps/ for a canvas app.
    src="$app"
    # The book is built from safari's tutorial folder.
    if [ "$app" = tutorial ]; then src=canvas_apps/safari/tutorial; publish_book_frames; fi
    [ -d "$REPO/$src" ] || src="canvas_apps/$app"
    [ -d "$REPO/$src" ] || { echo "$app is neither an app nor a canvas app in $REPO"; exit 2; }
    [ -d "$NEXT/$app" ] || { echo "no dev build at $NEXT/$app; run $app's build.sh first"; exit 2; }
    if [ "$src" = "canvas_apps/$app" ] && ! grep -qxF "opt speed" "$NEXT/$app/BUILT"; then
        echo "$NEXT/$app is not a release build; run canvas_apps/build.sh $app release first"; exit 2
    fi
    emitted=no
    if reads_emitted_codex "$app" "$src"; then
        emitted=yes
        require_checkout rocemit "$ROCEMIT_REPO" ROCEMIT_REPO
        require_checkout Cobblestone "$COBBLESTONE" COBBLESTONE
    fi
    rm -rf "$LIVE/$app"
    cp -r "$NEXT/$app" "$LIVE/$app"
    {
        echo "published $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        # A build that recorded its own compiler is believed; the older apps
        # record none and are built by whatever `roc` points at.
        if [ -f "$LIVE/$app/BUILT" ]; then cat "$LIVE/$app/BUILT"; else
            echo "roc $("$ROC" version | sed 's/Roc compiler version //')"
        fi
        echo "roc-apps $(git -C "$REPO" rev-parse --short HEAD)$(git -C "$REPO" diff --quiet HEAD -- "$src" || echo ' +uncommitted')"
        if [ "$emitted" = yes ]; then
            echo "rocemit $(git -C "$ROCEMIT_REPO" rev-parse --short HEAD)$(git -C "$ROCEMIT_REPO" diff --quiet HEAD || echo ' +uncommitted')"
            echo "cobblestone $(git -C "$COBBLESTONE" rev-parse --short HEAD) $(git -C "$COBBLESTONE" branch --show-current)"
        fi
        (cd "$LIVE/$app" && find . -name '*.wasm' | sort | while read -r w; do
            echo "sha256 $(sha256sum "$w" | cut -c1-16)  $(stat -c %s "$w") bytes  ${w#./}"
        done)
    } > "$LIVE/$app/PROVENANCE"
    # Folded into PROVENANCE above; one record, not two. BOOK_INPUTS is
    # book.shale's stamp on a widget's dev build, and means nothing in staging.
    rm -f "$LIVE/$app/BUILT" "$LIVE/$app/BOOK_INPUTS"
    cat "$LIVE/$app/PROVENANCE"
    paths=("$LIVE/$app")
    what="$app"
fi
[ "${PUBLISH_DRY_RUN:-}" = 1 ] && { echo "dry run: nothing committed"; exit 0; }
git -C "$REPO" add -A -- "${paths[@]}"
if git -C "$REPO" diff --cached --quiet -- "${paths[@]}"; then
    echo "staging already has $what as dev shows it; nothing to publish"; exit 0
fi
git -C "$REPO" commit -q -m "site: publish $what to staging

$([ "$app" = home ] || cat "$LIVE/$app/PROVENANCE")" -- "${paths[@]}"
git -C "$REPO" push -q
echo "published $what to staging: http://143.244.172.148:9200/"
