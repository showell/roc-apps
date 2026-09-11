#!/bin/bash
# Every safari spec through rocemit, then roc, against the Codex verdict.
#
#   safari/emitted.sh             all 54 units; rewrites safari/roc/ whole
#   safari/emitted.sh ViewYaw     one; rewrites only what that unit emits
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
# THE STILLS ARE BAKED, NOT EMITTED. rocemit forwards a data table to
# `<Chapter>Data.name`; safari/bake_stills.py writes those modules and the
# decoder into safari/roc/ beside the chapters.
#
# Three outcomes, counted apart: PASS and FAIL are roc's output against the
# verdict; REFUSED is rocemit declining a form it has not built, with the
# reason -- not a failure and not a pass.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc/out/bin/roc}"
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
[ $# -eq 0 ] && grep -l -m1 "emitted from Codex by rocemit\|baked by roc-apps" "$ROC_DIR"/*.roc 2>/dev/null | xargs -r rm -f
"$HERE/bake_stills.py" > /dev/null || { echo "bake_stills.py failed"; exit 2; }
declare -A wrote
pass=0; fail=0; refused=0
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
    "$ROC" run "$ROC_DIR/$app" > "$OUT/$n.out" 2> "$OUT/$n.err"
    if diff -q "$OUT/$n.out" "$UNITS/$n.expected" > /dev/null; then
        pass=$((pass + 1)); echo "PASS $n"
    else
        fail=$((fail + 1)); echo "FAIL $n"; grep -m1 -E "✗|crashed" -A3 "$OUT/$n.err" | head -4; diff "$OUT/$n.out" "$UNITS/$n.expected" | head -4
    fi
done
echo "$pass pass, $fail fail, $refused refused"
[ $fail -eq 0 ] && [ $refused -eq 0 ]
