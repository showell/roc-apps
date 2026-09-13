#!/bin/bash
# A Codex unit, emitted by rocemit, on the machine's native platform: the block
# device is the host's, over the files codex-vm's own flags name.
#
#   machine/native/run.sh <unit.codex> [-disk image] [-disk2 image] [codex-vm flags]
#
# The emitted modules land in ~/build/roc-apps/gen/native/<unit>/ beside the
# machine: machine/roc's modules, with this directory's MachineDisk in place of
# the modelled one. The app gets the wiring Roc gives a headerless app, pointed
# at this platform instead of Echo. The images are opened read-write and
# written in place, so give it copies.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
src="$1"; shift
n="$(basename "$src" .codex)"
d="$HOME/build/roc-apps/gen/native/$n"
[ -f "$HERE/platform/targets/x64musl/libhost.a" ] || { echo "no host library; run machine/native/build.sh"; exit 2; }
rm -rf "$d"; mkdir -p "$d"
said="$("$ROCEMIT" "$src" "$d")"
app="${said%%$'\n'*}"
grep -qx 'import Machine' "$d"/*.roc || { echo "$n does not run on the machine"; exit 2; }
cp "$HERE/../roc/"{Machine,MachineMem,MachinePci}.roc "$d/"
cp "$HERE/MachineDisk.roc" "$d/"
# Roc takes a platform only by a relative path.
rel="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$HERE/platform/main.roc" "$d")"
{ printf 'app [main!] { pf: platform "%s" }\n\nimport pf.Echo\n\necho! = |msg| Echo.line!(msg)\n\n' "$rel"; cat "$d/$app"; } > "$d/$app.wired"
mv "$d/$app.wired" "$d/$app"
# The run happens in the unit's directory, so an image is named absolutely.
args=()
while [ $# -gt 0 ]; do
    case "$1" in
        -disk|-disk2) args+=("$1" "$(realpath "$2")"); shift 2 ;;
        *) args+=("$1"); shift ;;
    esac
done
cd "$d" && exec "$ROC" run "$app" -- "${args[@]}"
