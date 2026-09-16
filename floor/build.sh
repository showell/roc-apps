#!/bin/bash
# Codex units, emitted by rocemit and built for the floor: the zig host
# (against the roc checkout), then each unit's emitted modules with this
# platform's Machine (roc/Machine.roc) in place of the one rocemit writes,
# wired to the platform and built natively.
#
#   floor/build.sh <unit.codex>...
#
# Each unit lands in ~/build/roc-apps/gen/floor/<unit>/ with its executable at
# <unit>/native. Run one with run.sh, which passes the host's own flags
# (-disk, -fault, -report) through.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
ROC_CHECKOUT="${ROC_CHECKOUT:-$HOME/showell_repos/roc}"
GEN="$HOME/build/roc-apps/gen/floor"
mkdir -p "$GEN" "$HERE/platform/targets/x64musl"
# **THE HOST IS BUILT FAST, NOT DEBUG**: every read and write of the program's
# memory is a call into it. It links with musl's C runtime, copied from the roc
# checkout's fx test platform.
(cd "$HERE" && "$ZIG" build -Droc="$ROC_CHECKOUT" --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
cp "$ROC_CHECKOUT/test/fx/platform/targets/x64musl/crt1.o" "$ROC_CHECKOUT/test/fx/platform/targets/x64musl/libc.a" "$HERE/platform/targets/x64musl/"
for src in "$@"; do
    src="$(realpath "$src")"
    n="$(basename "$src" .codex)"
    d="$GEN/$n"
    rm -rf "$d"; mkdir -p "$d"
    said="$("$ROCEMIT" --by-reach "$src" "$d")"
    app="${said%%$'\n'*}"
    if [ "$app" = library ]; then echo "$n has no opening to run"; exit 2; fi
    grep -qx 'import Machine' "$d"/*.roc || { echo "$n never reaches a device, so it does not need the floor"; exit 2; }
    # The floor's Machine in place of the one rocemit writes, and the
    # capability table it reads, which is the machine's own and pure Roc.
    cp "$HERE/roc/Machine.roc" "$HERE/../machine/roc/MachineCaps.roc" "$d/"
    # Roc takes a platform only by a relative path.
    rel="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$HERE/platform/main.roc" "$d")"
    { printf 'app [main!] { pf: platform "%s" }\n\nimport pf.Echo\n\necho! = |msg| Echo.line!(msg)\n\n' "$rel"; cat "$d/$app"; } > "$d/$app.wired"
    mv "$d/$app.wired" "$d/$app"
    # **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is
    # not the verdict: an error is marked ✗, and a failed build leaves no
    # executable.
    rm -f "$d/native"
    (cd "$d" && "$ROC" build "$app" --opt=dev --output="$d/native") > "$d/build.log" 2>&1 || true
    if grep -q "✗" "$d/build.log" || [ ! -x "$d/native" ]; then
        grep -a -m3 -A3 "✗" "$d/build.log" || tail -20 "$d/build.log"
        echo "$n: build failed"; exit 1
    fi
    echo "built $n: $d/native"
done
