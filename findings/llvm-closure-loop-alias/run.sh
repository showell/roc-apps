#!/bin/bash
# Builds App.roc with the dev backend and with LLVM, and runs both. They
# should print the same line: ten passes, 0 to 9.
#
#   findings/llvm-closure-loop-alias/run.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-07-14d9829/roc}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export TMPDIR="$T/tmp" ROC_CACHE_DIR="$T/cache"
mkdir -p "$TMPDIR" "$ROC_CACHE_DIR"
cp "$HERE/App.roc" "$T/"
for opt in dev speed; do
    (cd "$T" && "$ROC" build App.roc --opt=$opt --output=app-$opt > build-$opt.log 2>&1)
    printf '%-6s %s\n' "$opt" "$("$T/app-$opt")"
done
