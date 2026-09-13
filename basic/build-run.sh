#!/bin/bash
# basic-run and basic-check, built once: basic/roc/BasicRun.roc and
# basic/roc/BasicCheck.roc compiled by the Roc compiler into native
# executables on the default platform, with the dev backend.
# **NO LLVM BUILDS.** The speed backend spent 650 s in LLVM on this
# interpreter; what is slow here is the interpreter's shape, which the dev
# backend shows as well. The times reported are the Roc compiler's alone.
#
#   basic/build-run.sh
#
# Lands at ~/build/roc-apps/gen/basic/, where basic/run.sh and
# basic/check-fast.sh read it.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
OUT="$HOME/build/roc-apps/gen/basic"
mkdir -p "$OUT/tmp"
# The Roc compiler keeps its build files under TMPDIR; a build of its own
# there cannot collide with another build running at the same time.
export TMPDIR="$OUT/tmp"
for app in BasicRun:basic-run BasicCheck:basic-check; do
    src="${app%%:*}.roc"; exe="${app##*:}"
    rm -f "$OUT/$exe"
    t0=$EPOCHREALTIME
    # **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is
    # not the verdict: an error is marked ✗, and a failed build leaves no
    # executable.
    (cd "$HERE/roc" && "$ROC" build "$src" --opt=dev --output="$OUT/$exe") > "$OUT/build-$exe.log" 2>&1
    t1=$EPOCHREALTIME
    if grep -q "✗" "$OUT/build-$exe.log" || [ ! -x "$OUT/$exe" ]; then
        cat "$OUT/build-$exe.log"; echo "build of $exe failed"; exit 1
    fi
    printf 'Roc compiler, %s -> %s: %.2f s\n' "$src" "$exe" "$(echo "$t1 - $t0" | bc)"
done
