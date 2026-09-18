#!/bin/bash
# Every safari spec through rocemit, then roc, against the Codex verdict.
#
#   safari/emitted.sh             all 54 units; rewrites safari/roc/ whole
#   safari/emitted.sh ViewYaw     one; rewrites only what that unit emits
#   JOBS=1 safari/emitted.sh      serial (the default runs two units at a time)
#
# The units are safari-codex's `units/<Spec>.codex` (the resolved program) and
# `units/<Spec>.expected` (the verdict the Rust interpreter froze). rocemit is
# rust-codex-compiler's Roc emitter: ONE TYPE MODULE PER CODEX CHAPTER, whole,
# as written, plus the spec's app.
#
# THE ROC IS TRACKED. `safari/roc/` is generated and committed -- the one
# exception to "outputs live outside the repo", because the Roc files are the
# point: the chapter modules are the code the screensaver will import, and the
# spec apps grade them. Every unit re-emits the chapters it reaches, and a
# chapter's text must not depend on which spec is attached: a unit whose copy
# of a chapter differs from the copy already written this run is a FAIL naming
# both units. Roc output (stdout, stderr) stays under ~/build/roc-apps/gen.
#
# Three outcomes, counted apart: PASS and FAIL are roc's output against the
# verdict; REFUSED is rocemit declining a form it has not built, with the
# reason -- not a failure and not a pass.
set -u
# **RETIRED 2026-09-18, Steve's call: "the Roc program is the new program going
# forward. We should never re-emit Roc from Codex at this point. That's no
# longer worth the trouble."**
#
# safari/roc/*.roc is SOURCE now, hand-edited like any other Roc. This script
# would emit the Roc from Codex, which at best undoes that work and at
# worst deletes it: the line further down removes every file whose header still
# says it was emitted. It refuses rather than explaining itself afterwards.
#
# The Codex program is still the Codex program, and safari-codex still emits
# the zig, the wasm and the C#. It just does not emit this any more.
echo "retired: safari/roc is the program now, not an emission. See the comment in $0." >&2
exit 2


HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The compiler is roc-lang/nightlies' build of the new compiler (README);
# ROC=~/build/roc/out/bin/roc runs the debug build from the checkout.
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
UNITS="${SAFARI_UNITS:-$HOME/showell_repos/safari-codex/units}"
OUT="$HOME/build/roc-apps/gen"
mkdir -p "$OUT"
[ -x "$ROC" ] || { echo "no roc at $ROC"; exit 2; }
[ -x "$ROCEMIT" ] || { echo "no rocemit at $ROCEMIT; cargo build --release --bin rocemit, or set ROCEMIT"; exit 2; }
[ -d "$UNITS" ] || { echo "no units at $UNITS"; exit 2; }
ROC_DIR="$HERE/roc"
mkdir -p "$ROC_DIR"
# A full run starts clean, but only of what a tool wrote: the hand-written
# app (SafariApp.roc) lives here too, beside the modules it imports.
[ $# -eq 0 ] && grep -l -m1 "emitted from Codex by rocemit" "$ROC_DIR"/*.roc 2>/dev/null | xargs -r rm -f
declare -A wrote
pass=0; fail=0; refused=0
units=()
# PHASE ONE, serial: emit every unit, check chapter identity, fill safari/roc.
for u in "$UNITS"/*Spec.codex; do
    n="$(basename "$u" .codex)"
    [ $# -eq 0 ] || [ "$n" = "$1Spec" ] || continue
    d="$OUT/emit/$n"
    if ! app="$("$ROCEMIT" "$u" "$d" 2> "$OUT/$n.refused")"; then
        refused=$((refused + 1)); echo "REFUSED $n  $(head -1 "$OUT/$n.refused")"; continue
    fi
    rm -f "$OUT/$n.refused"
    clash=""
    for f in "$d"/*.roc; do
        b="$(basename "$f")"
        if [ "$b" != "$app" ] && [ -n "${wrote[$b]:-}" ] && ! cmp -s "$f" "$ROC_DIR/$b"; then
            clash="$clash $b(vs ${wrote[$b]})"; continue
        fi
        cp "$f" "$ROC_DIR/$b"; wrote[$b]="$n"
    done
    [ -z "$clash" ] || { fail=$((fail + 1)); echo "FAIL $n  chapter text differs:$clash"; continue; }
    # rocemit prints the app's name and then a digest of what it wrote.
    echo "${app%%$'\n'*}" > "$OUT/$n.app"
    units+=("$n")
done
# PHASE TWO, two at a time: roc on every unit, each timed. The box has two
# cores and a unit's roc is a few hundred MB; this halves the wall clock.
run_one() {
    n="$1"; app="$(cat "$OUT/$n.app")"
    t0=$(date +%s)
    "$ROC" run "$ROC_DIR/$app" > "$OUT/$n.out" 2> "$OUT/$n.err"
    echo "$(( $(date +%s) - t0 ))" > "$OUT/$n.secs"
}
export -f run_one; export ROC ROC_DIR OUT
printf '%s\n' "${units[@]}" | xargs -P "${JOBS:-2}" -I{} bash -c 'run_one {}'
# PHASE THREE: the verdicts, in unit order.
for n in "${units[@]}"; do
    secs="$(cat "$OUT/$n.secs")"
    # A COMPILE ERROR IS A FAIL EVEN WHEN THE OUTPUT MATCHES: roc compiles a
    # type error into a crash at its site and runs the rest, so a spec that
    # never reaches the broken definition prints its verdict regardless.
    # Warnings (●) are tolerated; errors (✗) are not.
    if grep -q "✗" "$OUT/$n.err"; then
        fail=$((fail + 1)); echo "FAIL $n  ${secs}s  compile error"; grep -m1 "✗" -A3 "$OUT/$n.err" | head -4
    elif diff -q "$OUT/$n.out" "$UNITS/$n.expected" > /dev/null; then
        pass=$((pass + 1)); echo "PASS $n  ${secs}s"
    else
        fail=$((fail + 1)); echo "FAIL $n  ${secs}s"; grep -m1 -E "✗|crashed" -A3 "$OUT/$n.err" | head -4; diff "$OUT/$n.out" "$UNITS/$n.expected" | head -4
    fi
done
echo "$pass pass, $fail fail, $refused refused"
[ $fail -eq 0 ] && [ $refused -eq 0 ]
