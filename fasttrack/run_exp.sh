#!/bin/bash
# Builds an experiment app (exp_*.roc) with LLVM and runs it detached, each
# line of its log stamped with the time. Prints the log's path.
#
#   fasttrack/run_exp.sh exp_win_focus
#
# The build lands in ~/build/roc-apps/gen/fasttrack/<name>/, the log beside it
# as log.md: a line a game while it plays, the report at the end. An earlier
# log is kept, renamed by the time it was last written.
set -euo pipefail
NAME="${1:?usage: run_exp.sh exp_name}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc_nightly-linux_x86_64-2026-09-07-14d9829/roc}"
OUT="$HOME/build/roc-apps/gen/fasttrack/$NAME"
mkdir -p "$OUT"
(cd "$HERE" && "$ROC" build "$NAME.roc" --opt=speed --output="$OUT/$NAME") > "$OUT/build.log" 2>&1 || true
if grep -q "✗" "$OUT/build.log" || [ ! -x "$OUT/$NAME" ]; then cat "$OUT/build.log"; echo "build failed"; exit 1; fi
head -1 "$OUT/build.log"
cd "$OUT"
if [ -s log.md ]; then mv log.md "log-$(date -r log.md +%Y%m%d-%H%M%S).md"; fi
setsid nohup bash -c "./$NAME 2>&1 | while IFS= read -r line; do printf '%s  %s\n' \"\$(date +%H:%M:%S)\" \"\$line\"; done > log.md" < /dev/null > /dev/null 2>&1 &
echo "$OUT/log.md"
