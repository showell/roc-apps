#!/bin/bash
# The fast path held to the full evaluator. Every corpus program, and every
# control at 1,000 iterations, runs through basic-check and through basic-run
# (both built by basic/build-run.sh).
#
#   basic/check-fast.sh
#
# basic-check runs a LET, an IF or an array store both ways from the same
# machine wherever the fast path answers, and stops the program with
# `fast differs` when the two machines disagree. Reported:
#
#   - how many fast answers were compared: a check that never ran checked
#     nothing;
#   - each program where fast differed, with the two machines;
#   - each transcript basic-check printed that basic-run did not. The check's
#     run loop is its own, and must run the program basic-run runs.
#
# Transcripts land in ~/build/roc-apps/gen/basic-check/<executable>/.
# Exits 1 when anything differs.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$HOME/build/roc-apps/gen/basic"
OUT="$HOME/build/roc-apps/gen/basic-check"
for b in basic-run basic-check; do
    [ -x "$GEN/$b" ] || { echo "no $GEN/$b -- run basic/build-run.sh"; exit 2; }
done
rm -rf "$OUT"
for b in basic-run basic-check; do
    mkdir -p "$OUT/$b/controls"
    for suite in nbs games; do
        BIN="$GEN/$b" OUT="$OUT/$b" LIMIT=120 "$HERE/run.sh" "$suite" > "$OUT/$b/$suite.log"
    done
    # A control with an INPUT gets one reply line, 7, per iteration.
    for f in "$HERE"/controls/*.bas; do
        n="$(basename "$f" .bas)"
        src="$(cat "$f")"
        replies=""
        [[ "$src" == *INPUT* ]] && replies="$(yes 7 | head -n 1000)"
        timeout 120 "$GEN/$b" micro "${src//@N@/1000}" "$replies" > "$OUT/$b/controls/$n.out" 2> "$OUT/$b/controls/$n.err"
        rc=$?
        [ $rc -eq 0 ] || echo "$n EXIT $rc" >> "$OUT/$b/controls.log"
    done
done
C="$OUT/basic-check"
R="$OUT/basic-run"
bad=0

checked=$(cat "$C"/*/*.err | grep -oE 'checked: [0-9]+' | awk '{ s += $2 } END { print s + 0 }')
echo "fast answers compared: $checked"
[ "$checked" -gt 0 ] || bad=1

differs=$(grep -l 'fast differs' "$C"/*/*.out)
echo "programs where fast differed: $(printf '%s' "$differs" | grep -c .)"
for f in $differs; do
    rel="${f#"$C"/}"
    # The report ends the transcript, and the output it quotes may hold
    # newlines: everything from it to the end, a newline shown as ⏎.
    echo "  ${rel%.out}: $(sed -n '/fast differs/,$p' "$f" | sed 's/^.*\(fast differs\)/\1/' | awk '{ printf "%s⏎", $0 }' | cut -c1-700)"
    bad=1
done

unlike=$(for f in "$R"/*/*.out; do rel="${f#"$R"/}"; cmp -s "$f" "$C/$rel" || echo "${rel%.out}"; done)
echo "transcripts basic-check printed that basic-run did not: $(printf '%s' "$unlike" | grep -c .)"
if [ -n "$unlike" ]; then echo "$unlike" | sed 's/^/  /'; bad=1; fi

stopped=$(grep -hE 'TIMEOUT|EXIT' "$R"/*.log "$C"/*.log 2>/dev/null)
echo "timeouts and failed exits, both executables: $(printf '%s' "$stopped" | grep -c .)"
[ -z "$stopped" ] || echo "$stopped" | sed 's/^/  /'
exit $bad
