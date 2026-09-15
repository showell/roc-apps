#!/bin/bash
# Build an app on roc-ray (raylib) from the platform's source, for one target.
#
#   ray/build.sh hello                    native Linux, into ~/build/roc-apps/ray/hello/
#   TARGET=x64win ray/build.sh hello      Windows; links only where the Windows SDK is
#                                         installed (.github/workflows/windows.yml)
#
# An app is ray/apps/<name>/: its main.roc and any sibling modules. The app's
# modules are staged into the output directory with the platform reference
# rewritten to the roc-ray checkout's platform/main.roc, as a RELATIVE path
# (`roc run` refuses an absolute one). The checkout must have run `zig build`,
# which writes the host libraries platform/targets/ names.
#
# The environment names everything that differs between this box and a CI
# runner: ROC (the compiler roc-ray pins, nightly-2026-09-07-14d9829), ROC_RAY
# (the checkout), OUT (where outputs go) and TARGET.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-07-14d9829/roc}"
ROC_RAY="$(cd "${ROC_RAY:-$HOME/showell_repos/roc-ray}" && pwd)"
OUT="${OUT:-$HOME/build/roc-apps/ray}"
TARGET="${TARGET:-x64glibc}"
name="${1:?usage: ray/build.sh <app>, an app under ray/apps/}"
app="$HERE/apps/$name"
[ -f "$app/main.roc" ] || { echo "no app at $app/main.roc"; exit 2; }
case "$TARGET" in
    x64win) host=host.lib; suffix=.exe ;;
    *) host=libhost.a; suffix= ;;
esac
[ -f "$ROC_RAY/platform/targets/$TARGET/$host" ] \
    || { echo "no $TARGET host in $ROC_RAY/platform/targets; run zig build there"; exit 2; }

mkdir -p "$OUT/$name"
dest="$(cd "$OUT/$name" && pwd)"
stage="$dest/src"
rm -rf "$stage"
mkdir -p "$stage"
cp "$app"/*.roc "$stage/"
platform="$(realpath --relative-to="$stage" "$ROC_RAY/platform/main.roc")"
sed -i -E "0,/platform \"[^\"]*\"/s##platform \"$platform\"#" "$stage/main.roc"
grep -q "platform \"$platform\"" "$stage/main.roc" || { echo "no platform reference to rewrite in $app/main.roc"; exit 2; }

exe="$dest/$name$suffix"
rm -f "$exe"
log="$dest/build-$TARGET.log"
# **ROC EXITS NON-ZERO FOR A WARNING**, so the verdict is an error mark (✗) or
# a missing executable, not the exit code.
t0=$(date +%s)
"$ROC" build "$stage/main.roc" --target="$TARGET" --opt=dev --output="$exe" > "$log" 2>&1 || true
secs=$(( $(date +%s) - t0 ))
if grep -q "✗" "$log" || [ ! -s "$exe" ]; then
    cat "$log"; echo "build failed after ${secs}s"; exit 1
fi
echo "built $exe in ${secs}s ($(grep -c "●" "$log" || true) warnings)"
