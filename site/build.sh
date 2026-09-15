#!/bin/bash
# The site's own files into the DEV channel: the landing page, the script every
# page loads for its way home, and the channel's name.
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
rm -rf "$NEXT/shared"
cp -r "$HERE/web/shared" "$NEXT/"
echo dev > "$NEXT/channel"
echo "dev: http://143.244.172.148:9210/"
