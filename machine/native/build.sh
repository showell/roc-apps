#!/bin/bash
# Build the machine's native platform: the host library (zig, against the roc
# checkout) into platform/targets/x64musl/, beside the musl C runtime `roc run`
# links it with, copied from the roc checkout's fx test platform. Nothing under
# targets/ is committed.
#
#   machine/native/build.sh
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
ROC_CHECKOUT="${ROC_CHECKOUT:-$HOME/showell_repos/roc}"
(cd "$HERE" && "$ZIG" build -Droc="$ROC_CHECKOUT" --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global")
T="$HERE/platform/targets/x64musl"
cp "$ROC_CHECKOUT/test/fx/platform/targets/x64musl/crt1.o" "$ROC_CHECKOUT/test/fx/platform/targets/x64musl/libc.a" "$T/"
ls -la "$T"
