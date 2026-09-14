#!/bin/bash
# Codex units, emitted by rocemit, built for the machine's batch page: the
# wasm host (zig, against the roc checkout), then each unit's emitted modules
# beside the machine's, wired to this platform and built for wasm into the
# preview root with the unit's disk images and cleaned verdict.
#
#   machine/batch/build.sh <unit.codex>...
#
# The modules land in ~/build/roc-apps/gen/batch/<unit>/ with the native
# platform's MachineDisk, which asks the platform's Drive for its sectors.
# The wasm lands in ~/build/roc-apps/next/machine/batch/, served on :9203.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
NEXT="$HOME/build/roc-apps/next/machine/batch"
VERDICTS="$HOME/build/roc-apps/gen/verdicts"
mkdir -p "$NEXT"
(cd "$HERE" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
for src in "$@"; do
    src="$(realpath "$src")"
    n="$(basename "$src" .codex)"
    d="$HOME/build/roc-apps/gen/batch/$n"
    rm -rf "$d"; mkdir -p "$d"
    said="$("$ROCEMIT" "$src" "$d")"
    app="${said%%$'\n'*}"
    grep -qx 'import Machine' "$d"/*.roc || { echo "$n does not run on the machine"; exit 2; }
    # The modules rocemit wrote, the app first, which the page shows.
    emitted=("$app" $(cd "$d" && ls *.roc | grep -vx "$app" || true))
    cp "$HERE/../roc/"{Machine,MachineApic,MachineCaps,MachineE1000,MachineHpet,MachineIde,MachineMedia,MachineMem,MachineNat,MachineNe2k,MachinePci,MachinePorts}.roc "$d/"
    cp "$HERE/../native/MachineDisk.roc" "$HERE/MachineWire.roc" "$d/"
    # Roc takes a platform only by a relative path.
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
    base="${src%.codex}"
    for ext in disk disk2; do
        if [ -f "$base.$ext" ]; then cp "$base.$ext" "$NEXT/$n.$ext"; else rm -f "$NEXT/$n.$ext"; fi
    done
    if [ -f "$VERDICTS/$n.expected" ]; then cp "$VERDICTS/$n.expected" "$NEXT/$n.expected"; else rm -f "$NEXT/$n.expected"; fi
    rm -rf "$NEXT/$n.roc"; mkdir -p "$NEXT/$n.roc"
    for f in "${emitted[@]}"; do cp "$d/$f" "$NEXT/$n.roc/"; done
    printf '%s\n' "${emitted[@]}" > "$NEXT/$n.files"
    ls -la "$NEXT/$n.wasm"
done
# The page, and its list of every unit built here: the images each brings,
# whether its verdict came with it, and the Roc modules rocemit wrote for it.
cp "$HERE/web/index.html" "$NEXT/index.html"
(cd "$NEXT" && python3 -c '
import glob, json, os
def unit(n):
    return {
        "name": n,
        "disks": [e for e in ("disk", "disk2") if os.path.exists(n + "." + e)],
        "expected": os.path.exists(n + ".expected"),
        "roc": open(n + ".files").read().split() if os.path.exists(n + ".files") else [],
    }
print(json.dumps([unit(w[:-5]) for w in sorted(glob.glob("*.wasm"))]))
' > units.json)
echo "page: http://143.244.172.148:9203/machine/batch/"
