#!/bin/bash
# The site's own files into the DEV channel: the landing page, the script every
# page loads for its way home, the site's own pages (notes/, short pages the
# landing page links at its foot, and syntax-color/, roc-syntax-color's
# showcase) and the channel's name. Each folder of site/web/ is copied whole.
#
#   site/build.sh
#
# Lands at the root of ~/build/roc-apps/next/, served on :9210 by roc-site.
# Each app's build.sh writes its own directory beside them.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT="$HOME/build/roc-apps/next"
mkdir -p "$NEXT"
cp "$HERE/web/index.html" "$NEXT/"
for dir in shared notes syntax-color; do
    rm -rf "${NEXT:?}/$dir"
    cp -r "$HERE/web/$dir" "$NEXT/"
done
echo dev > "$NEXT/channel"
echo "dev: http://localhost:9210/"
