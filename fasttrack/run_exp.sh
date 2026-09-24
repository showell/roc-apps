#!/bin/bash
# Builds an experiment app (exp_*.roc, on the cli/ platform) with LLVM and
# runs it detached, each line of its log stamped with the time. Prints the
# log's path.
#
#   fasttrack/run_exp.sh exp_duplicate
#
# The build lands in ~/build/roc-apps/gen/fasttrack/<name>/, the log beside it
# as log.md: a line a game while it plays, the report at the end, and last
# "[exit N]" -- anything but 0 means the program stopped early. An earlier
# log is kept, renamed by the time it was last written. To compare two logs,
# drop the times: diff <(cut -c11- a.md) <(cut -c11- b.md).
set -euo pipefail
NAME="${1:?usage: run_exp.sh exp_name}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/$(cat "$HERE/../roc-nightly.txt")/roc}"
OUT="$HOME/build/roc-apps/gen/fasttrack/$NAME"
mkdir -p "$OUT"
# The platform's host, rebuilt when its source is newer than the library.
host="$HERE/cli/platform/targets/x64musl/libhost.a"
if [ ! -f "$host" ] || [ -n "$(find "$HERE/cli/platform/host.zig" "$HERE/cli/build.zig" -newer "$host")" ]; then "$HERE/cli/build.sh"; fi
(cd "$HERE" && "$ROC" build "$NAME.roc" --opt=speed --output="$OUT/$NAME") > "$OUT/build.log" 2>&1 || true
if grep -q "✗" "$OUT/build.log" || [ ! -x "$OUT/$NAME" ]; then cat "$OUT/build.log"; echo "build failed"; exit 1; fi
head -1 "$OUT/build.log"
cd "$OUT"
if [ -s log.md ]; then mv log.md "log-$(date -r log.md +%Y%m%d-%H%M%S).md"; fi
setsid nohup bash -c "(./$NAME 2>&1; echo \"[exit \$?]\") | while IFS= read -r line; do printf '%s  %s\n' \"\$(date +%H:%M:%S)\" \"\$line\"; done > log.md" < /dev/null > /dev/null 2>&1 &
echo "$OUT/log.md"
