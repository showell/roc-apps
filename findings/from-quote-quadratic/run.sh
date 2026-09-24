#!/bin/bash
# roc check and an LLVM build of one constant holding N literals, as plain
# Str and as T (a nominal with from_quote). Fresh cache each time.
set -u
cd "$(dirname "$0")"
ROC="${ROC:-$HOME/build/roc-nightly/$(cat ../../roc-nightly.txt)/roc}"
W="$(mktemp -d)"; cp T.roc "$W/"
for kind in str quote; do for n in 100 200 400 800; do
    python3 gen.py $kind $n > "$W/p.roc"
    rm -rf "$W/cache"; XDG_CACHE_HOME="$W/cache" /usr/bin/time -f %e -o "$W/t" "$ROC" check "$W/p.roc" >/dev/null 2>&1; c=$(tail -1 "$W/t")
    rm -rf "$W/cache"; XDG_CACHE_HOME="$W/cache" /usr/bin/time -f %e -o "$W/t" "$ROC" build --opt=speed "$W/p.roc" --output="$W/b" >/dev/null 2>&1
    printf '%-6s %4d literals   check %6s s   LLVM build %6s s\n' $kind $n $c "$(tail -1 "$W/t")"
done; done
rm -rf "$W"
