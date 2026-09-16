#!/bin/bash
# The floor's page: each named unit emitted, wired to this platform and built
# for wasm into the dev channel, with its disk image, its screen and the console
# it is supposed to print.
#
#   floor/page.sh <unit.codex>...
#   floor/page.sh $(awk -F'\t' '/^[^#]/ { print $1 }' floor/verify.tsv | sort -u | sed ...)
#
# **THIS NEEDS A COMPILER BUILT FROM SOURCE** for anything that builds a
# constant record with two pointers (roc-lang/roc#11419), and a nightly with
# that fix does not run on this box: see floor/README.md.
#
#     ROC=~/build/roc/fast/bin/roc floor/page.sh <unit.codex>...
#
# The wasm, the images and the page land in ~/build/roc-apps/next/floor/,
# served on :9210.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
ROC_CHECKOUT="${ROC_CHECKOUT:-$HOME/showell_repos/roc}"
CHECKOUT="${CHECKOUT:-$HOME/showell_repos/cobblestone-u61}"
GEN="$HOME/build/roc-apps/gen/floor-web"
NEXT="$HOME/build/roc-apps/next/floor"
VERDICTS="$HOME/build/roc-apps/gen/verdicts"
mkdir -p "$GEN" "$NEXT" "$HERE/platform/targets/x64musl" "$HERE/platform/targets/wasm32"
(cd "$HERE" && "$ZIG" build -Droc="$ROC_CHECKOUT" --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
for src in "$@"; do
    src="$(realpath "$src")"
    n="$(basename "$src" .codex)"
    [ "$n" = opening ] && n="$(basename "$(dirname "$src")")"
    d="$GEN/$n"
    rm -rf "$d"; mkdir -p "$d"
    said="$("$ROCEMIT" --by-reach "$src" "$d")"
    app="${said%%$'\n'*}"
    if [ "$app" = library ]; then echo "$n has no opening to run"; exit 2; fi
    grep -qx 'import Machine' "$d"/*.roc || { echo "$n never reaches a device, so it does not need the floor"; exit 2; }
    emitted=("$app" $(cd "$d" && ls *.roc | grep -vx "$app" || true) Machine.roc)
    cp "$HERE/roc/Machine.roc" "$HERE/../machine/roc/MachineCaps.roc" "$d/"
    rel="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$HERE/platform/main.roc" "$d")"
    { printf 'app [main!] { pf: platform "%s" }\n\nimport pf.Echo\n\necho! = |msg| Echo.line!(msg)\n\n' "$rel"; cat "$d/$app"; } > "$d/$app.wired"
    mv "$d/$app.wired" "$d/$app"
    # **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is
    # not the verdict: an error is marked ✗, and a failed build leaves no wasm.
    rm -f "$NEXT/$n.wasm"
    (cd "$d" && "$ROC" build "$app" --target=wasm32 --opt=dev --output="$NEXT/$n.wasm") > "$d/build.log" 2>&1 || true
    if grep -q "✗" "$d/build.log" || [ ! -s "$NEXT/$n.wasm" ]; then
        grep -a -m3 -A3 "✗" "$d/build.log" || tail -20 "$d/build.log"
        echo "$n: build failed"; exit 1
    fi
    # What the page needs beside the wasm: the image it runs on, the screen its
    # -gop flags ask for, and the console it is supposed to print.
    rm -f "$NEXT/$n.disk" "$NEXT/$n.screen" "$NEXT/$n.expected"
    [ -f "${src%.codex}.disk" ] && cp "${src%.codex}.disk" "$NEXT/$n.disk"
    if [ -f "${src%.codex}.vmargs" ] && grep -q -- '-gop' "${src%.codex}.vmargs"; then
        python3 -c '
import sys
words = [w for line in open(sys.argv[1]) if not line.startswith("#") for w in line.split()]
flag = lambda name, default: int(words[words.index(name) + 1]) if name in words else default
w, h = flag("-gop-width", 640), flag("-gop-height", 480)
s = flag("-gop-stride", w)
print(w, h, w if s < w else min(s, 2048))
' "${src%.codex}.vmargs" > "$NEXT/$n.screen"
    fi
    # The console a clean run must print: the unit's own cleaned verdict, or an
    # expectation kept in floor/expect/.
    if [ -f "$VERDICTS/$n.expected" ]; then
        cp "$VERDICTS/$n.expected" "$NEXT/$n.expected"
    elif [ -f "$HERE/expect/$n.console" ]; then
        cp "$HERE/expect/$n.console" "$NEXT/$n.expected"
    fi
    ls -la "$NEXT/$n.wasm"
done
cp "$HERE/web/index.html" "$NEXT/"
(cd "$NEXT" && python3 -c '
import glob, json, os
def program(n):
    return {
        "name": n,
        "disk": os.path.exists(n + ".disk"),
        "screen": [int(v) for v in open(n + ".screen").read().split()] if os.path.exists(n + ".screen") else None,
        "expected": open(n + ".expected").read() if os.path.exists(n + ".expected") else None,
    }
print(json.dumps([program(w[:-5]) for w in sorted(glob.glob("*.wasm"))], indent=1))
' > programs.json)
echo "dev: http://143.244.172.148:9210/floor/"
