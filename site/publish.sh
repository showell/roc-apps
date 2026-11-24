#!/bin/bash
# THE SIGN-OFF: move what the dev channel shows into staging, one app at a time.
#
#   site/publish.sh safari      an app: any folder at the repository's top
#                               (basic, fasttrack, js, delivery, dog-park) or
#                               under canvas_apps/ (safari, snake, pong,
#                               breakout, camera, workshop, particles,
#                               trick_or_treat, thanksgiving, knights_tour,
#                               eight_queens, and the book's *_widget pages),
#                               published at site/live/<app>/
#   site/publish.sh tutorial    the Safari Ride book, with every widget and app it
#                               frames (each published first, if staging differs)
#   site/publish.sh shale-book  the Shale book, as book/build.shale built it
#   site/publish.sh home        the landing page and the site's own folders
#                               (shared/, notes/, syntax-color/, roc-on-shale/,
#                               security-idioms/, release-candidate-compiles/,
#                               chess/)
#
# An app: copies ~/build/roc-apps/next/<app>/ (what <app>'s build.sh last wrote,
# and what :9210/<app>/ shows) over site/live/<app>/ whole, writes a PROVENANCE
# inside it, and commits that directory alone, then pushes (below). A canvas app
# must be a release build (`canvas_apps/build.sh <app> release`). `home` does
# the same for the landing page and the site's own folders, whose list is
# `site_dirs` here and the loop in site/build.sh, kept the same by hand; dev's
# `channel` file stays behind, so staging holds exactly what prod will.
# Staging on :9200 serves the site/live/ of ~/showell_repos/roc-apps per
# request with no-store, so a publish there is live at once (a publish from
# another worktree is not on staging until it is merged there). Two other
# scripts write site/live/: site/publish_screensavers.shale writes
# roc-screensaver's folders (welcome-to-roc/, bubbles/, tides/), and
# site/publish_safari_walk.shale writes safari-walk/. markdown/ and
# user_uploads/ are roc-markdown's playground build, copied in and committed by
# hand (roc-markdown's TESTING.md says which files).
#
# PROVENANCE records what the build read: the Roc compiler, the roc-apps
# commit (marked when the app's own tree has uncommitted changes), and a hash
# of each wasm. A checkout an app needs and that is missing stops the publish
# before site/live/ is touched.
#
# PUBLISH_DRY_RUN=1 still copies the app over site/live/<app>/ and writes the
# PROVENANCE, then stops before git, leaving site/live/ changed and
# uncommitted; with NEXT and LIVE pointed at scratch copies it touches nothing
# tracked.
#
# On the development box, publish with `shale site/publish.shale app=<app>`.
# It runs this script with PUBLISH_NO_PUSH=1, which commits and leaves the
# push out, and then pushes with Shale's git_push, unconfined to a remote of
# the box's remotes file. This script's own `git push` runs confined under
# Shale and cannot read ssh's key ("Load key ... Permission denied"), so run
# without PUBLISH_NO_PUSH it fails after the commit has landed; push that
# commit with git_push. Outside Shale, on a machine whose git reaches its key,
# the script's own push works.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
NEXT="${NEXT:-$HOME/build/roc-apps/next}"
LIVE="${LIVE:-$HERE/live}"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../pinned-roc.sh"
# The Shale book is built by book/build.shale on the shale repository's book
# branch, not from a directory here, so its PROVENANCE names that checkout.
SHALE_BOOK="${SHALE_BOOK:-$HOME/showell_repos/lanes/shale-book}"

# A checkout the PROVENANCE must name; missing, the publish stops.
require_checkout() {
    local what="$1" dir="$2" var="$3"
    git -C "$dir" rev-parse --short HEAD > /dev/null 2>&1 || {
        echo "$app reads $what, and there is no git checkout at $dir; set $var= to the checkout the build used"; exit 2
    }
}
# The book publishes only a build of canvas_apps/safari/tutorial/book.shale,
# whose BUILT says which chapters it holds. A page staging has is never
# taken away, since its address is published. The widgets and apps the book
# frames ship with it: each one whose staged copy isn't the build the book was
# checked with is published first, from the dev channel, by this same script.
# The list comes from the built pages' own frames, so it can't go stale.
publish_book_frames() {
    local book="$NEXT/tutorial" page folder
    grep -q '^book: ' "$book/BUILT" 2>/dev/null || { echo "$book has no BUILT saying which chapters it holds, so it is not a book that canvas_apps/safari/tutorial/book.shale built"; exit 2; }
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
    site_dirs=(shared notes syntax-color roc-on-shale security-idioms release-candidate-compiles chess)
    diff -q "$HERE/web/index.html" "$NEXT/index.html" > /dev/null || stale=1
    for dir in "${site_dirs[@]}"; do diff -rq "$HERE/web/$dir" "$NEXT/$dir" > /dev/null || stale=1; done
    if [ -n "${stale:-}" ]; then
        echo "dev's landing page is older than site/web/; run site/build.sh, look at http://localhost:9210/, then publish"; exit 2
    fi
    cp "$NEXT/index.html" "$LIVE/"
    paths=("$LIVE/index.html")
    for dir in "${site_dirs[@]}"; do
        rm -rf "${LIVE:?}/$dir"
        cp -r "$NEXT/$dir" "$LIVE/"
        paths+=("$LIVE/$dir")
    done
    what="the landing page"
else
    # An app is a directory of this repository: at the top (basic/, js/), or
    # under canvas_apps/ for a canvas app. Any such directory is taken, so
    # the name must be one whose build wrote $NEXT/<app>.
    src="$app"
    # The book is built from safari's tutorial folder.
    if [ "$app" = tutorial ]; then src=canvas_apps/safari/tutorial; publish_book_frames; fi
    if [ "$app" = shale-book ]; then
        src=
        require_checkout "the Shale book" "$SHALE_BOOK" SHALE_BOOK
    else
        [ -d "$REPO/$src" ] || src="canvas_apps/$app"
        [ -d "$REPO/$src" ] || { echo "$app is neither an app nor a canvas app in $REPO"; exit 2; }
    fi
    [ -d "$NEXT/$app" ] || { echo "no dev build at $NEXT/$app; run $app's build.sh first"; exit 2; }
    if [ "$src" = "canvas_apps/$app" ] && ! grep -qxF "opt speed" "$NEXT/$app/BUILT"; then
        echo "$NEXT/$app is not a release build; run canvas_apps/build.sh $app release first"; exit 2
    fi
    rm -rf "$LIVE/$app"
    cp -r "$NEXT/$app" "$LIVE/$app"
    {
        echo "published $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        # A build that recorded its own compiler (its BUILT) is believed; for
        # an app whose build records none (basic, js), the compiler named is
        # the pin, pinned-roc.sh's ROC, which that app's build also runs.
        if [ "$app" = shale-book ]; then
            echo "shale $(git -C "$SHALE_BOOK" rev-parse --short HEAD) $(git -C "$SHALE_BOOK" branch --show-current)$(git -C "$SHALE_BOOK" diff --quiet HEAD -- book || echo ' +uncommitted')"
        else
            if [ -f "$LIVE/$app/BUILT" ]; then cat "$LIVE/$app/BUILT"; else
                echo "roc $("$ROC" version | sed 's/Roc compiler version //')"
            fi
            echo "roc-apps $(git -C "$REPO" rev-parse --short HEAD)$(git -C "$REPO" diff --quiet HEAD -- "$src" || echo ' +uncommitted')"
        fi
        (cd "$LIVE/$app" && find . -name '*.wasm' | sort | while read -r w; do
            echo "sha256 $(sha256sum "$w" | cut -c1-16)  $(stat -c %s "$w") bytes  ${w#./}"
        done)
    } > "$LIVE/$app/PROVENANCE"
    # Folded into PROVENANCE above; one record, not two. BOOK_INPUTS is
    # canvas_apps/safari/tutorial/build_widgets.shale's stamp on a page's dev
    # build, and means nothing in staging.
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
if [ "${PUBLISH_NO_PUSH:-}" = 1 ]; then
    echo "committed $what; the push is the caller's (site/publish.shale's git_push)"
else
    git -C "$REPO" push -q
fi
echo "published $what to staging: http://localhost:9200/"
