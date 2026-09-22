#!/bin/bash
# THE GATE for the kernels: every Codex [Device] kernel chapter under
# $KERNELS_ROOT/apps/*/kernels emitted to Roc and checked by the nightly.
#
#   gpu/emitted.sh                 all 46 kernels; writes gpu/roc/ when green
#   gpu/emitted.sh Plasma Nbody    named kernels, no write
#
# Phase one: rocemit each kernel into ~/build/roc-apps/gen/gpu/<K>/ beside a
# copy of the hand-written Device module, and `roc check` the kernel's own
# module (its imports are checked with it). A chapter two kernels share
# (DeviceMath, ListUtils, Tuple) must emit to the same text from both, as a
# module's text must not depend on which kernel is attached. Phase two, on
# a full green run: the modules copied into gpu/roc/, where they are tracked.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
KERNELS_ROOT="${KERNELS_ROOT:-$HOME/showell_repos/cobblestone-u62}"
# rocemit resolves a kernel's cites (DeviceMath, DeviceEffect, ...) from the
# checkout the kernel sits in, so they come from $KERNELS_ROOT too.
GEN="$HOME/build/roc-apps/gen/gpu"
mkdir -p "$GEN"
if [ $# -gt 0 ]; then
    kernels=()
    for k in "$@"; do kernels+=("$(ls "$KERNELS_ROOT"/apps/*/kernels/"$k"Kernel*.codex | head -1)"); done
    write=no
else
    mapfile -t kernels < <(ls "$KERNELS_ROOT"/apps/*/kernels/*.codex | sort)
    write=yes
fi
declare -A seen
pass=0; fail=0; failed=()
for src in "${kernels[@]}"; do
    k="$(basename "$src" .codex)"
    dir="$GEN/$k"
    rm -rf "$dir"; mkdir -p "$dir"
    if ! err=$("$ROCEMIT" "$src" "$dir" 2>&1 >/dev/null); then
        echo "FAIL $k: $err"; fail=$((fail+1)); failed+=("$k"); continue
    fi
    cp "$HERE/roc/Device.roc" "$dir/"
    for m in "$dir"/*.roc; do
        c="$(basename "$m" .roc)"
        [ "$c" = Device ] && continue
        h="$(sha256sum "$m" | cut -c1-16)"
        if [ -n "${seen[$c]:-}" ] && [ "${seen[$c]}" != "$h" ]; then
            echo "FAIL $k: chapter $c differs from its earlier emission"; fail=$((fail+1)); failed+=("$k"); continue 2
        fi
        seen[$c]="$h"
    done
    # The nightly says "0 errors and 0 warnings" when clean and marks a
    # diagnostic with ✗; only the mark, or a non-zero exit, is a failure.
    # Every module, not just the kernel: `roc check` reports only the file
    # it was given, and a broken import compiles to a crash at its own site.
    # Warnings (●) are tolerated, errors (✗) are not, and roc exits 2 for
    # either -- so the marker is the judge, as safari's gate has it.
    out=""
    for m in "$dir"/*.roc; do
        [ "$(basename "$m")" = Device.roc ] && continue
        out="$out$(cd "$dir" && "$ROC" check --no-cache "$(basename "$m")" 2>&1)"
    done
    if echo "$out" | grep -q '✗'; then
        echo "FAIL $k: $(echo "$out" | grep -m1 -A2 '✗' | tr '\n' ' ' | cut -c1-200)"; fail=$((fail+1)); failed+=("$k"); continue
    fi
    pass=$((pass+1))
done
echo "$pass pass, $fail fail${failed:+: ${failed[*]}} -- kernels from $KERNELS_ROOT"
if [ "$write" = yes ] && [ "$fail" -eq 0 ]; then
    for src in "${kernels[@]}"; do
        k="$(basename "$src" .codex)"
        for m in "$GEN/$k"/*.roc; do
            [ "$(basename "$m")" = Device.roc ] && continue
            cp "$m" "$HERE/roc/"
        done
    done
    echo "written to gpu/roc/"
fi
[ "$fail" -eq 0 ]
