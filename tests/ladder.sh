#!/bin/bash
# THE LADDER for rocemit: Cobblestone's own test corpus, codex/test/, every
# program beside an .expected verdict emitted to Roc, run on the Echo
# platform, and its output diffed against the verdict.
#
#   tests/ladder.sh                 the corpus, apps/ left out (1,032 units)
#   tests/ladder.sh effect-smoke    named units
#   tests/ladder.sh --like 'unit type'   the units whose last verdict says that
#
# The corpus is every .expected under codex/test, the top level and the
# subdirectories alike; a unit is named by its path with '/' written as
# '@'.
#
# **apps/ IS LEFT OUT**, 499 of the 1,516: it was a rabbit hole the last
# time we worked this corpus (Steve, 2026-09-13), and the rest is not
# asymptotic yet. `SKIP_DIRS= tests/ladder.sh` puts it back.
#
# rocemit resolves each program's cites from the checkout it sits in,
# $TESTS_ROOT. A unit with a .diag beside it
# expects a diagnostic, not output, and is skipped by name. Outputs land in
# ~/build/roc-apps/gen/tests/<unit>/ and nothing here is tracked: the
# ledger is the summary this prints, by outcome and refusal reason, and
# tests/ledger.txt when a full run writes it.
#
# The verdicts are CLEANED ONCE by tests/verdicts.sh, which explains what it
# strips and why; the comparison here is then byte for byte.
#
# A unit whose verdict pins a semantics Roc does not have is DIVERGES, by
# name and with the reason, never a silent FAIL: see DIVERGE below.
#
# Outcomes: PASS (output equals the verdict), FAIL (it does not, or roc
# printed ✗), CRASH (roc run died), KILLED (a signal -- 9 is the OOM
# killer stopping compile-time evaluation), REFUSED (rocemit said no, by
# reason), TIMEOUT.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
ROCEMIT="${ROCEMIT:-$HOME/build/rust-target/release/rocemit}"
TESTS_ROOT="${TESTS_ROOT:-$HOME/showell_repos/cobblestone-u60rel}"
SRC="$TESTS_ROOT/codex/test"
GEN="$HOME/build/roc-apps/gen/tests"
VERDICTS="$HOME/build/roc-apps/gen/verdicts"
# The verdicts change when Cobblestone's tree does, which is rarely, so
# they are cleaned only when one is newer than the copy, or when the copy was
# cleaned from another checkout: an older checkout's files are never newer,
# so a switch alone would compare against the wrong verdicts.
if [ ! -d "$VERDICTS" ] || [ "$(cat "$VERDICTS/.root" 2>/dev/null)" != "$TESTS_ROOT" ] || [ -n "$(find "$SRC" -name '*.expected' -newer "$VERDICTS" -print -quit)" ]; then
    TESTS_ROOT="$TESTS_ROOT" "$HERE/verdicts.py" > "$GEN/.verdicts.log" 2>&1 || { echo "verdicts.py failed"; exit 2; }
    echo "$TESTS_ROOT" > "$VERDICTS/.root"
fi
mkdir -p "$GEN"
if [ "${1:-}" = --like ]; then
    # Rerun one family: the units whose last verdict says this. The whole
    # sweep is a minute and a half, and most of that is the emit; picking
    # a family off the ledger is how to iterate on one refusal.
    mapfile -t units < <(LC_ALL=C grep -a -- "$2" "$HERE/ledger.txt" | cut -d' ' -f2)
    full=no
    echo "${#units[@]} units whose verdict says: $2"
elif [ $# -gt 0 ]; then units=("$@"); full=no; else
    skip="${SKIP_DIRS-apps}"
    mapfile -t units < <(cd "$SRC" && find . -name '*.expected' | sed 's|^\./||; s/\.expected$//' | tr '/' '@' | sort | { [ -n "$skip" ] && grep -v "^\($(echo "$skip" | tr ' ' '|')\)@" || cat; }); full=yes
fi
# **THE VERDICT PINS A SEMANTICS ROC DOES NOT HAVE.** Codex's list-set-at
# mutates in place, so two names for one list see each other's writes;
# Roc's List.set answers a new list and the old name keeps its value. A
# program that reads a list it has already written THROUGH ANOTHER NAME
# therefore cannot be ported, and this one exists to pin that behaviour.
# (A case, not an array: the runner is `bash -c` per unit and an array
# does not cross that.)
diverges() {
    case "$1" in
        edalias|db-row-update) echo "list-set-at mutates in place; Roc's List.set answers a new list" ;;
        ui-event-test) echo "list-push mutates a list two siblings share; Roc's List.append answers a new one" ;;
        real-show-wide) echo "the verdict pins Codex's own printer: it reads 12345678901234567.0 as ...566, we print the double" ;;
        cost@accumulator-corpus|ops@list-growth|heap-scrub|engine-culling-cost|engine-render-heap) echo "measures Codex's bump pointer with __heap-save; Roc counts references and has none, so every measurement reads zero" ;;
        gop-padded-stride) echo "reads its geometry from cells codex-vm publishes at fixed addresses at boot; on any other host those addresses were never written" ;;
    esac
}
# The drives a machine unit boots with, as a Roc module: a program on the
# Echo platform reads no files, so an attached image is a file IMPORT, and the
# position with nothing on it is Absent. Arguments: yes/no for drive0.disk and
# drive1.disk.
media() {
    echo "# MachineMedia -- the drives attached for this unit, written by tests/ladder.sh."
    [ "$1" = yes ] && echo 'import "drive0.disk" as drive0 : List(U8)'
    [ "$2" = yes ] && echo 'import "drive1.disk" as drive1 : List(U8)'
    echo
    echo 'MachineMedia :: [].{'
    echo '	drives : List([Attached(List(U8)), Absent])'
    printf '\tdrives = [%s, %s]\n' "$( [ "$1" = yes ] && echo 'Attached(drive0)' || echo Absent )" "$( [ "$2" = yes ] && echo 'Attached(drive1)' || echo Absent )"
    echo '}'
}
# **THE RUN IS THE EXPENSIVE PART, THE EMIT IS NOT.** rocemit is a Rust
# binary and takes milliseconds; `roc run` takes a compile. So a unit
# whose emitted text is byte for byte what it was when we last ran it
# keeps that verdict, and only what the emitter now writes differently is
# run again. `FRESH=1` ignores the cache; `EMIT_ONLY=1` stops after the
# emit, which is the fast way to see the refusal queue.
one() {
    n="$1"; d="$GEN/$n"; old=""
    [ -f "$GEN/$n.stamp" ] && old="$(cat "$GEN/$n.stamp")"
    mkdir -p "$d"
    src="$SRC/$(echo "$n" | tr '@' '/')"
    if [ -f "$src.diag" ]; then echo "SKIP $n | expects a diagnostic" > "$d/verdict"; return; fi
    # A .skip is upstream's claim that its own battery cannot run the test
    # (a cross-architecture boot, say); its first line is the reason.
    if [ -f "$src.skip" ]; then echo "SKIP $n | $(head -1 "$src.skip" | cut -c1-100)" > "$d/verdict"; return; fi
    # A .disk-src names a program upstream's harness compiles onto the disk at
    # test time; with no Cobblestone compiler here there is no such disk.
    if [ -f "$src.disk-src" ]; then echo "SKIP $n | its disk is compiled from $(grep -v '^#' "$src.disk-src" | head -1 | cut -c1-60) by the Cobblestone compiler at test time" > "$d/verdict"; return; fi
    why="$(diverges "$n")"
    if [ -n "$why" ]; then echo "DIVERGES $n | $why" > "$d/verdict"; return; fi
    # rocemit prints the app's name and a digest of everything it wrote,
    # so telling "this is what it was last time" costs no processes.
    if ! said=$("$ROCEMIT" "$src.codex" "$d" 2> "$d/emit.err"); then
        echo "REFUSED $n | $(head -1 "$d/emit.err" | sed 's/^REFUSED: //' | cut -c1-110)" > "$d/verdict"; return
    fi
    app="${said%%$'\n'*}"; stamp="${said##*$'\n'}"
    # A kept verdict was judged against one checkout's verdicts.
    stamp="$stamp $TESTS_ROOT"
    if [ "$app" = library ]; then echo "REFUSED $n | no opening" > "$d/verdict"; return; fi
    # **A UNIT THAT REACHES A DEVICE RUNS ON THE MACHINE.** rocemit threads
    # Machine through it and writes no Machine module: the machine is
    # machine/roc, copied in beside the emitted modules, and the test's
    # .vmargs are its command line, as they are codex-vm's. Its .disk and
    # .disk2 are the primary master and slave, linked in and imported by a
    # generated MachineMedia. All of it is part of what the verdict came
    # from, so all of it joins the stamp.
    vmargs=()
    if grep -qx 'import Machine' "$d"/*.roc; then
        cp "$MACHINE"/{Machine,MachineMem,MachinePci,MachineDisk}.roc "$d/"
        [ -f "$src.vmargs" ] && read -ra vmargs <<< "$(grep -v '^#' "$src.vmargs" | tr '\n' ' ')"
        rm -f "$d/drive0.disk" "$d/drive1.disk"
        a0=no; a1=no
        [ -f "$src.disk" ] && { ln -s "$src.disk" "$d/drive0.disk"; a0=yes; }
        [ -f "$src.disk2" ] && { ln -s "$src.disk2" "$d/drive1.disk"; a1=yes; }
        media $a0 $a1 > "$d/MachineMedia.roc"
        stamp="$stamp machine $( { cat "$MACHINE"/{Machine,MachineMem,MachinePci,MachineDisk}.roc "$d/MachineMedia.roc"; echo "${vmargs[*]}"; stat -L -c '%s %Y' "$d"/drive*.disk 2>/dev/null; } | md5sum | cut -c1-16)"
    fi
    if [ -n "$old" ] && [ "$old" = "$stamp" ] && [ -f "$GEN/$n.verdict" ] && [ -z "${FRESH:-}" ]; then
        cp "$GEN/$n.verdict" "$d/verdict"; return
    fi
    [ -n "${EMIT_ONLY:-}" ] && { echo "EMITTED $n |" > "$d/verdict"; return; }
    run=("$ROC" run "$app"); [ ${#vmargs[@]} -gt 0 ] && run+=(-- "${vmargs[@]}")
    ( cd "$d" && timeout 120 "${run[@]}" > out 2> err ); rc=$?
    # The capture behind a verdict drops a trailing blank line, so the
    # comparison strips them from our side too (tests/verdicts.sh).
    awk 'BEGIN{n=0} /^$/{n++; next} {while (n-- > 0) print ""; n=0; print}' "$d/out" > "$d/out.cmp"
    # **THE COMPILER RUNS THE PROGRAM, AND NOTHING BOUNDS IT.** A call
    # whose arguments are known is evaluated at compile time with no step
    # limit (roc-lang/roc#11334) and no memory limit either: a software
    # renderer reaches the OOM killer, which is signal 9, which is 137.
    if [ $rc -ge 128 ]; then echo "KILLED $n | signal $((rc - 128))$(grep -m1 -oE 'Evaluating .{0,60}' "$d/err" | sed 's/^/ while /')" > "$d/verdict"
    elif [ $rc -eq 124 ]; then echo "TIMEOUT $n |" > "$d/verdict"
    elif grep -q "✗" "$d/err"; then echo "FAIL $n | compile: $(grep -a -m1 -A2 '✗' "$d/err" | tr '\n' ' ' | sed 's/─//g; s/  */ /g' | cut -c1-110)" > "$d/verdict"
    elif cmp -s "$d/out.cmp" "$VERDICTS/$n.expected"; then echo "PASS $n |" > "$d/verdict"
    elif grep -q "crashed\|Backtrace\|overflowed" "$d/err"; then echo "CRASH $n | $( { awk '/crashed with this message:/ {f=1; next} f && NF {sub(/^[ \t]+/, ""); print; exit}' "$d/err"; grep -m1 -hoE 'crashed[^\n]*|overflowed[^\n]*' "$d/err"; } | head -1 | cut -c1-100)" > "$d/verdict"
    else echo "FAIL $n | output: $(diff "$d/out.cmp" "$VERDICTS/$n.expected" | grep -m1 '^[<>]' | cut -c1-100)" > "$d/verdict"; fi
    cp "$d/verdict" "$GEN/$n.verdict"
    # The stamp is written WITH the verdict it names. Written at the emit, an
    # EMIT_ONLY run left a new stamp beside an old verdict, and the next full
    # run reused that verdict for text it had never run.
    echo "$stamp" > "$GEN/$n.stamp"
}

MACHINE="$(cd "$HERE/../machine/roc" && pwd)"
export -f one diverges media; export ROC ROCEMIT SRC GEN VERDICTS MACHINE TESTS_ROOT
printf '%s\n' "${units[@]}" | xargs -P "${JOBS:-2}" -I{} bash -c 'one {}'
ledger="$( for n in "${units[@]}"; do cat "$GEN/$n/verdict"; done )"
[ "$full" = yes ] && echo "$ledger" > "$HERE/ledger.txt"
echo "$ledger" | grep -av '^PASS' | sort
echo "--- by outcome:"; echo "$ledger" | cut -d' ' -f1 | sort | uniq -c | sort -rn
echo "--- refusals by reason:"; echo "$ledger" | grep -a '^REFUSED' | cut -d'|' -f2 | sed 's/`[^`]*`/`_`/g' | sort | uniq -c | sort -rn | head -20
echo "$(echo "$ledger" | grep -ac '^PASS') pass of ${#units[@]} -- tests from $TESTS_ROOT"
