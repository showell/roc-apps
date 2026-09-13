#!/bin/bash
# Each variant built by the nightly Roc compiler (dev backend) and run once
# under strace. The number is its mmap calls: about 10 is startup and no copy;
# about 10,000 times k is k allocations per store (on the default platform
# every heap value is its own mmap).
#
#   findings/helper-arg-copy/run.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export TMPDIR="$T/tmp" ROC_CACHE_DIR="$T/cache"
mkdir -p "$TMPDIR" "$ROC_CACHE_DIR"
for d in "$HERE"/*/; do
    v="$(basename "$d")"
    mkdir -p "$T/$v" && cp "$d"/*.roc "$T/$v/" && cp "$HERE/Vec.roc" "$T/$v/"
    (cd "$T/$v" && "$ROC" build App.roc --opt=dev --output=app > build.log 2>&1)
    if [ -x "$T/$v/app" ]; then
        strace -c -f -o "$T/$v/st" "$T/$v/app" > "$T/$v/out" 2>&1
        printf '%-18s mmap %6s   prints %s\n' "$v" "$(awk '$NF=="mmap"{print $4}' "$T/$v/st")" "$(tr '\n' ' ' < "$T/$v/out")"
    else
        printf '%-18s build failed\n' "$v"
    fi
done
