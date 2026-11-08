#!/bin/bash
# This builds the canvas_apps' wasm host, platform/host.zig, into
# platform/targets/wasm32/host.wasm, where every app's wasm links against it.
# canvas_apps/build.sh runs it before each page, and the safari gate's widgets
# part runs it before building the widgets.
#
#   canvas_apps/web/build_host.sh
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIG="${ZIG:-$HOME/zig-0.16.0/zig}"
cd "$HERE" && "$ZIG" build --cache-dir "$HOME/build/roc-apps/zig-cache" --global-cache-dir "$HOME/build/zig-global"
