#!/bin/bash
# The stack overflow in Basic.store, both ways: the machine handed to
# set_arr straight from ensure_arr (overflows), and as a fresh copy (prints 9).
#
#   findings/store-overflow/repro.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
# The old interpreter is no longer in the tree; its modules come from 33e04d7,
# the last commit that has them.
for way in direct fresh; do
    mkdir -p "$T/$way"
    for m in Basic Listing Pages Program; do
        git -C "$HERE/../.." show "33e04d7:basic/roc/$m.roc" > "$T/$way/$m.roc"
    done
    cp "$HERE/Run.roc" "$T/$way/"
done
python3 - "$T/direct/Basic.roc" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
old = "Basic.set_arr({ ..ready, steps: ready.steps }, "
assert s.count(old) == 1, "the fresh-copy line is not in basic/roc/Basic.roc"
p.write_text(s.replace(old, "Basic.set_arr(ready, "))
PY
for way in direct fresh; do
    (cd "$T/$way" && "$ROC" run Run.roc > out 2> err); rc=$?
    echo "$way: exit $rc, output '$(tr '\n' ' ' < "$T/$way/out")' $(grep -o 'overflowed its stack memory' "$T/$way/err")"
done
