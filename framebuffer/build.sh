#!/bin/bash
# Codex programs, emitted by rocemit, built for the framebuffer platform: the
# wasm host (zig, against the roc checkout), then each program's modules with
# this platform's Mem (roc/Mem.roc) in place of the one rocemit writes, wired
# to the platform and built for wasm into the preview root.
#
#   framebuffer/build.sh <program.codex>...
#
# A program is emitted from a copy in ~/build/roc-apps/gen/framebuffer/<program>/codex/,
# so a .vmargs beside the original (which asks rocemit for the machine) stays
# behind; the screen size in it still reaches the page. The wasm, the modules
# the page shows and the page land in ~/build/roc-apps/next/framebuffer/,
# served on :9203.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/framebuffer"
mkdir -p "$NEXT"
# **THE HOST IS BUILT FAST, NOT DEBUG**: every read and write of the program's
# memory is a call into it.
(cd "$HERE" && "$ZIG" build -Drelease --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
for src in "$@"; do
    src="$(realpath "$src")"
    n="$(basename "$src" .codex)"
    d="$HOME/build/roc-apps/gen/framebuffer/$n"
    rm -rf "$d"; mkdir -p "$d/codex" "$d/roc"
    # The copy resolves its cites where the original does: in the Cobblestone
    # checkout it sits in (the directory holding codex/compiler/opening.codex),
    # or in the checkout the nearest quires.tsv above it names.
    cp "$src" "$d/codex/"
    q="$(dirname "$src")"
    while [ "$q" != / ] && [ ! -f "$q/codex/compiler/opening.codex" ] && [ ! -f "$q/quires.tsv" ]; do q="$(dirname "$q")"; done
    if [ -f "$q/codex/compiler/opening.codex" ]; then
        printf 'checkout %s\n' "$q" > "$d/codex/quires.tsv"
    elif grep -q '^checkout ' "$q/quires.tsv" 2>/dev/null; then
        cp "$q/quires.tsv" "$d/codex/"
    else
        echo "$n: neither in a Cobblestone checkout nor under a quires.tsv that names one"; exit 2
    fi
    # The host stops at an address it does not back, so the state can follow
    # what the opening reaches (rocemit's --by-reach).
    said="$("$ROCEMIT" --by-reach "$d/codex/$n.codex" "$d/roc")"
    app="${said%%$'\n'*}"
    if [ "$app" = library ]; then echo "$n has no opening to run"; exit 2; fi
    # A program that reaches a device threads the machine, and gets this
    # platform's (memory and the GPU); one that reaches only memory gets its Mem.
    if grep -qx 'import Machine' "$d/roc"/*.roc; then
        state=Machine
    elif [ -f "$d/roc/Mem.roc" ]; then
        state=Mem
    else
        echo "$n never touches memory, so it cannot draw on the screen"; exit 2
    fi
    # The modules the page shows: the app first, then its chapters, then the
    # platform's Mem or Machine.
    emitted=("$app" $(cd "$d/roc" && ls *.roc | grep -vx "$app" | grep -vx "$state.roc" || true) "$state.roc")
    cp "$HERE/roc/$state.roc" "$d/roc/$state.roc"
    # A screen size the program brings as codex-vm's -gop flags, which the page
    # and frames.mjs then use: a stride below the width is the width, and one
    # past 2048 is 2048, as codex-vm has it.
    rm -f "$NEXT/$n.screen"
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
    # Roc takes a platform only by a relative path.
    rel="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$HERE/platform/main.roc" "$d/roc")"
    { printf 'app [main!] { pf: platform "%s" }\n\nimport pf.Echo\n\necho! = |msg| Echo.line!(msg)\n\n' "$rel"; cat "$d/roc/$app"; } > "$d/roc/$app.wired"
    mv "$d/roc/$app.wired" "$d/roc/$app"
    # **THE ROC COMPILER EXITS NON-ZERO FOR A WARNING**, so its exit code is
    # not the verdict: an error is marked ✗, and a failed build leaves no wasm.
    rm -f "$NEXT/$n.wasm"
    (cd "$d/roc" && "$ROC" build "$app" --target=wasm32 --opt=dev --output="$NEXT/$n.wasm") > "$d/build.log" 2>&1 || true
    if grep -q "✗" "$d/build.log" || [ ! -s "$NEXT/$n.wasm" ]; then
        grep -a -m3 -A3 "✗" "$d/build.log" || tail -20 "$d/build.log"
        echo "$n: build failed"; exit 1
    fi
    rm -rf "$NEXT/$n.roc"; mkdir -p "$NEXT/$n.roc"
    for f in "${emitted[@]}"; do cp "$d/roc/$f" "$NEXT/$n.roc/"; done
    printf '%s\n' "${emitted[@]}" > "$NEXT/$n.files"
    ls -la "$NEXT/$n.wasm"
done
# The page, and its list of every program built here with the Roc modules it
# shows.
cp "$HERE/web/index.html" "$NEXT/"
(cd "$NEXT" && python3 -c '
import glob, json, os
def program(n):
    screen = [int(v) for v in open(n + ".screen").read().split()] if os.path.exists(n + ".screen") else None
    return {"name": n, "roc": open(n + ".files").read().split(), "screen": screen}
print(json.dumps([program(w[:-5]) for w in sorted(glob.glob("*.wasm"))]))
' > programs.json)
echo "page: http://143.244.172.148:9203/framebuffer/"
