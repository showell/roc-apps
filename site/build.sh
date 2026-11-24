#!/bin/bash
# The site's own files into the DEV channel: the landing page, the site's own
# folders of site/web/ (site/site_folders.txt lists them and says what each
# is; `shale site/publish.shale app=home` reads the same list), each copied
# whole, and the channel's name.
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
while read -r dir; do
    case "$dir" in ''|'#'*) continue ;; esac
    rm -rf "${NEXT:?}/$dir"
    cp -r "$HERE/web/$dir" "$NEXT/"
done < "$HERE/site_folders.txt"
echo dev > "$NEXT/channel"
echo "dev: http://localhost:9210/"
