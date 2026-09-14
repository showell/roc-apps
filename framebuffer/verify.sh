#!/bin/bash
# Screen mode 2: the framebuffer platform's native host checks every program in
# verify.tsv. Each is built by build.sh, which also refreshes the page's
# preview, then natively in the same directory, and run for its frames with the
# screen its -gop flags name (320 x 240 when it names none). The last frame's
# hash must be the table's, and a Cobblestone test's console must match its
# verdict as tests/ladder.sh cleaned it.
#
#   framebuffer/verify.sh
#
# Prints a line a program and exits 1 when any fails. Each program's native
# build log, output and errors stay in ~/build/roc-apps/gen/framebuffer/<program>/.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
CHECKOUT="${CHECKOUT:-$HOME/showell_repos/cobblestone-u60rel}"
GEN="$HOME/build/roc-apps/gen/framebuffer"
NEXT="$HOME/build/roc-apps/next/framebuffer"
VERDICTS="$HOME/build/roc-apps/gen/verdicts"
mkdir -p "$GEN"

rows=()
paths=()
while read -r prog frames want; do
    case "$prog" in ''|'#'*) continue ;; esac
    case "$prog" in
        cobblestone:*) path="$CHECKOUT/${prog#cobblestone:}" ;;
        roc-apps:*) path="$REPO/${prog#roc-apps:}" ;;
        *) echo "verify.tsv: $prog is neither cobblestone: nor roc-apps:"; exit 2 ;;
    esac
    rows+=("$path $frames $want")
    paths+=("$path")
done < "$HERE/verify.tsv"

if ! "$HERE/build.sh" "${paths[@]}" > "$GEN/verify-build.log" 2>&1; then
    tail -20 "$GEN/verify-build.log"
    echo "build.sh failed; its log is $GEN/verify-build.log"
    exit 1
fi

# Trailing blank lines are not part of a console's text.
trimmed() { sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'; }

failed=0
for row in "${rows[@]}"; do
    read -r path frames want <<< "$row"
    n="$(basename "$path" .codex)"
    d="$GEN/$n"
    app="$(head -1 "$NEXT/$n.files")"
    rm -f "$d/native"
    (cd "$d/roc" && "$ROC" build "$app" --opt=dev --output="$d/native") > "$d/native.log" 2>&1
    if grep -q "✗" "$d/native.log" || [ ! -x "$d/native" ]; then
        echo "FAIL $n | the native build failed; see $d/native.log"
        failed=1
        continue
    fi
    screen=(320 240 320)
    [ -f "$NEXT/$n.screen" ] && read -ra screen < "$NEXT/$n.screen"
    "$d/native" -screen "${screen[@]}" -frames "$frames" > "$d/native.out" 2> "$d/native.err"
    code=$?
    last="$(grep '^-- frame' "$d/native.out" | tail -1)"
    got="${last##*hash }"
    ms="$(printf '%s' "$last" | sed -n 's/^-- frame [0-9]*: \([0-9]*\) ms.*/\1/p')"
    why=""
    if [ $code -ne 0 ]; then
        why="exit $code: $(head -1 "$d/native.err")"
    elif [ "$got" != "$want" ]; then
        why="hash $got, want $want"
    fi
    unit=""
    case "$path" in "$CHECKOUT/codex/test/"*) rel="${path#"$CHECKOUT/codex/test/"}"; unit="${rel%.codex}"; unit="${unit//\//@}" ;; esac
    if [ -z "$why" ] && [ -n "$unit" ] && [ -f "$VERDICTS/$unit.expected" ]; then
        if [ "$(grep -v '^-- frame' "$d/native.out" | trimmed)" != "$(trimmed < "$VERDICTS/$unit.expected")" ]; then
            why="the console differs from its verdict; see $d/native.out"
        fi
    fi
    if [ -n "$why" ]; then
        echo "FAIL $n | $why"
        failed=1
    else
        echo "PASS $n | hash $got, $frames frame(s), the last in $ms ms${unit:+, console matches its verdict}"
    fi
done
exit $failed
