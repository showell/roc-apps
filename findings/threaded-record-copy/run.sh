#!/bin/bash
# Each variant built by the nightly Roc compiler and run once under strace.
# The number is the app's mmap calls: 2 is startup alone, about 10,000 is one
# copy per write (on the default platform every heap value is its own mmap).
#
#   findings/threaded-record-copy/run.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
for d in "$HERE"/*/; do
    v="$(basename "$d")"
    mkdir -p "$T/$v" && cp "$d/App.roc" "$T/$v/"
    (cd "$T/$v" && "$ROC" build App.roc --output=app > build.log 2>&1)
    if [ -x "$T/$v/app" ]; then
        strace -c -f -o "$T/$v/st" "$T/$v/app" > "$T/$v/out" 2>&1
        printf '%-24s mmap %6s   prints %s\n' "$v" "$(awk '$NF=="mmap"{print $4}' "$T/$v/st")" "$(tr '\n' ' ' < "$T/$v/out")"
    else
        printf '%-24s build failed\n' "$v"
    fi
done
