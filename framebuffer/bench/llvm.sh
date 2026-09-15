#!/bin/bash
# The framebuffer programs built with LLVM, one at a time, and measured. For
# each program build.sh last built, from the modules it emitted:
#   - the dev build and the speed (LLVM) build for the page's wasm32 target,
#     each under GNU time: wall seconds, CPU seconds, peak memory;
#   - each wasm's size;
#   - its frames in Node for both builds (frames.mjs, at verify.tsv's count),
#     the median frame time, and whether the last frame's hash is verify.tsv's.
# Nothing here writes the dev channel: the wasm goes to ~/build/roc-apps/gen/llvm/.
#
#   framebuffer/bench/llvm.sh [program...]     default: every built program, smallest first
#
# LIMIT (seconds, default 1200) bounds one build; a build past it is recorded
# as a timeout and the chain goes on. Each program's logs are in
# gen/llvm/<program>/, and the table is gen/llvm/summary.tsv.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FB="$(cd "$HERE/.." && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
LIMIT="${LIMIT:-1200}"
GEN="$HOME/build/roc-apps/gen/framebuffer"
NEXT="$HOME/build/roc-apps/next/framebuffer"
OUT="$HOME/build/roc-apps/gen/llvm"
mkdir -p "$OUT/dev" "$OUT/speed"

if [ $# -gt 0 ]; then
    progs=("$@")
else
    mapfile -t progs < <(ls -S -r "$NEXT"/*.wasm | xargs -n1 basename | sed 's/\.wasm$//')
fi

# verify.tsv's row for a program: `<how far> <hash>`.
row_of() {
    awk -v p="$1" '$1 !~ /^#/ && NF >= 3 { n = $1; sub(/.*\//, "", n); sub(/\.codex$/, "", n); if (n == p) { print $2, $3; exit } }' "$FB/verify.tsv"
}

# build <program> <opt>: the wasm under GNU time; prints "<exit> <wall s> <cpu s> <peak MB> <bytes>".
build() {
    local p=$1 opt=$2 log="$OUT/$1/$2.build.log" app
    app="$(head -1 "$NEXT/$p.files")"
    rm -f "$OUT/$opt/$p.wasm"
    (cd "$GEN/$p/roc" && timeout "$LIMIT" /usr/bin/time -v "$ROC" build "$app" --target=wasm32 --opt="$opt" --verbose --output="$OUT/$opt/$p.wasm") > "$log" 2>&1
    local code=$?
    # roc exits 2 for warnings alone; a build with a wasm and no error counts.
    [ $code -eq 2 ] && [ -f "$OUT/$opt/$p.wasm" ] && ! grep -q "✗" "$log" && code=0
    grep -q "✗" "$log" && code=2
    [ -f "$OUT/$opt/$p.wasm" ] || { [ $code -eq 0 ] && code=3; }
    python3 - "$log" "$code" "$OUT/$opt/$p.wasm" <<'EOF'
import os, re, sys
log, code, wasm = open(sys.argv[1], errors="replace").read(), sys.argv[2], sys.argv[3]
def field(name):
    m = re.search(re.escape(name) + r": (.*)", log)
    return m.group(1).strip() if m else ""
wall = field("Elapsed (wall clock) time (h:mm:ss or m:ss)")
secs = "-"
if wall:
    parts = [float(x) for x in wall.split(":")]
    secs = f"{sum(v * 60 ** i for i, v in enumerate(reversed(parts))):.1f}"
cpu = "-"
if field("User time (seconds)"):
    cpu = f"{float(field('User time (seconds)')) + float(field('System time (seconds)')):.1f}"
peak = f"{int(field('Maximum resident set size (kbytes)')) / 1024:.0f}" if field("Maximum resident set size (kbytes)") else "-"
size = str(os.path.getsize(wasm)) if os.path.exists(wasm) else "-"
print(code, secs, cpu, peak, size)
EOF
}

# frames <program> <how far> <opt>: prints "<median ms> <frames> <last hash>".
frames() {
    local p=$1 arg=$2 opt=$3 log="$OUT/$1/$3.frames.log"
    case "$arg" in runs=*) arg="${arg#runs=}" ;; flushes=*) arg="flushes:${arg#flushes=}" ;; esac
    (cd "$FB/.." && WASM_DIR="$OUT/$opt" timeout 900 node framebuffer/frames.mjs "$p" "$arg") > "$log" 2>&1
    python3 - "$log" <<'EOF'
import re, statistics, sys
rows = [(float(m.group(1)), m.group(2)) for m in re.finditer(r"^frame \d+: ([\d.]+) ms, .*?hash (\w+)", open(sys.argv[1]).read(), re.M)]
if not rows:
    print("- 0 -")
else:
    steady = [ms for ms, _ in rows[1:]] or [rows[0][0]]
    print(f"{statistics.median(steady):.0f}", len(rows), rows[-1][1])
EOF
}

printf 'program\tdev_build_s\tspeed_build_s\tspeed_cpu_s\tspeed_peak_mb\tdev_bytes\tspeed_bytes\tdev_frame_ms\tspeed_frame_ms\tframes\tdev_hash\tspeed_hash\twant_hash\tstatus\n' > "$OUT/summary.tsv"
echo "llvm chain $(date -u +%FT%TZ): ${#progs[@]} programs, limit ${LIMIT} s a build, $("$ROC" version)"
for p in "${progs[@]}"; do
    mkdir -p "$OUT/$p"
    read -r far want <<< "$(row_of "$p")"
    read -r dcode dwall dcpu dpeak dsize <<< "$(build "$p" dev)"
    echo "$(date -u +%T) $p: dev built in ${dwall} s; LLVM build starting"
    read -r scode swall scpu speak ssize <<< "$(build "$p" speed)"
    status=ok
    [ "$dcode" != 0 ] && status="dev build exit $dcode"
    [ "$scode" = 124 ] && status="LLVM build timed out at ${LIMIT} s"
    [ "$scode" != 0 ] && [ "$scode" != 124 ] && status="LLVM build exit $scode"
    dms=- sms=- n=- dhash=- shash=-
    if [ -n "${far:-}" ] && [ "$dcode" = 0 ] && [ "$scode" = 0 ]; then
        read -r dms n dhash <<< "$(frames "$p" "$far" dev)"
        read -r sms n shash <<< "$(frames "$p" "$far" speed)"
        [ "$shash" != "$want" ] && status="speed hash $shash, want $want"
        [ "$dhash" != "$want" ] && status="dev hash $dhash, want $want"
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$p" "$dwall" "$swall" "$scpu" "$speak" "$dsize" "$ssize" "$dms" "$sms" "$n" "$dhash" "$shash" "${want:--}" "$status" >> "$OUT/summary.tsv"
    echo "$(date -u +%T) $p: LLVM ${swall} s wall, ${scpu} s CPU, ${speak} MB peak; wasm ${dsize} -> ${ssize} bytes; frame ${dms} -> ${sms} ms; $status"
done
echo "done $(date -u +%FT%TZ)"
column -t -s $'\t' "$OUT/summary.tsv"
