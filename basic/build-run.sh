#!/bin/bash
# basic-run, built once: basic/roc/BasicRun.roc compiled by the Roc compiler
# into a native executable on the default platform, with the dev backend.
# **NO LLVM BUILDS.** The speed backend spent 650 s in LLVM on this
# interpreter; what is slow here is the interpreter's shape, which the dev
# backend shows as well. The time reported is
# the Roc compiler's alone.
#
#   basic/build-run.sh
#
# Lands at ~/build/roc-apps/gen/basic/basic-run, where basic/run.sh reads it.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
OUT="$HOME/build/roc-apps/gen/basic"
mkdir -p "$OUT/tmp"
rm -f "$OUT/basic-run"
# The Roc compiler keeps its build files under TMPDIR; a build of its own
# there cannot collide with another build running at the same time.
export TMPDIR="$OUT/tmp"
t0=$EPOCHREALTIME
# **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is not
# the verdict: an error is marked ✗, and a failed build leaves no executable.
(cd "$HERE/roc" && "$ROC" build BasicRun.roc --opt=dev --output="$OUT/basic-run") > "$OUT/build-run.log" 2>&1
t1=$EPOCHREALTIME
if grep -q "✗" "$OUT/build-run.log" || [ ! -x "$OUT/basic-run" ]; then
    cat "$OUT/build-run.log"; echo "build failed"; exit 1
fi
printf 'Roc compiler, BasicRun.roc -> basic-run: %.2f s\n' "$(echo "$t1 - $t0" | bc)"
