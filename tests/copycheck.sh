#!/bin/bash
# **IS ROC WRITING IN PLACE, OR COPYING?** There is no diagnostic for this
# and the type system says nothing, so the only way to know is to measure
# the SHAPE: hold the number of writes fixed and vary the size of the
# thing being written into.
#
#   in place -> the time is FLAT in the size
#   copying  -> the time is LINEAR in the size
#
# A single number tells you nothing; the slope tells you everything. Roc
# writes into a list when its reference count is one, and the two ways we
# have lost that are worth a standing probe because both are invisible:
#
#   naming    `List.set(l, i, v) ?? l` keeps `l` live past the set
#   nesting   the page handed to List.update's closure is not unique
#
#   tests/copycheck.sh          every probe
#   tests/copycheck.sh naming   one
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROC="${ROC:-$HOME/build/roc-nightly/roc}"
W="$HOME/build/roc-apps/gen/copycheck"
mkdir -p "$W"
WRITES=${WRITES:-8192}
SIZES=${SIZES:-"4096 16384 65536"}

# One probe at one size: print the CPU seconds.
cpu() { /usr/bin/time -f "%U %S" "$@" 2>&1 >/dev/null | tail -1 | awk '{printf "%.2f", $1 + $2}'; }

# A probe is a template with @SIZE@ in it. The bound is derived from the
# argument list so the run happens in the backend, not in the compiler.
probe() {
    name="$1"; body="$2"
    printf '%-10s' "$name"
    first=""; last=""
    for sz in $SIZES; do
        printf '%s' "$body" | sed "s/@SIZE@/$sz/g; s/@WRITES@/$WRITES/g" > "$W/P.roc"
        t=$(cpu "$ROC" run "$W/P.roc")
        printf ' %7ss@%-7s' "$t" "$sz"
        [ -z "$first" ] && first="$t"
        last="$t"
    done
    # Linear in size is a copy; flat is in place. The sizes span 16x, so
    # a ratio near one is flat and a ratio near sixteen is a full copy.
    r=$(awk -v a="$first" -v b="$last" 'BEGIN{ if (a <= 0.02) a = 0.02; printf "%.1f", b / a }')
    if awk -v r="$r" 'BEGIN{exit !(r < 2.0)}'; then echo "   FLAT (x$r) -- in place"; else echo "   LINEAR (x$r) -- COPYING"; fi
}

NAMING='spin : List(U8), I64, I64 -> List(U8)
spin = |l, i, n| if i >= n { l } else { spin(List.set(l, I64.to_u64_wrap(I64.rem_by(i, @SIZE@)), 7.U8) ?? l, i + 1, n) }
main! = |args| {
	n = @WRITES@ + (List.len(args) |> U64.to_i64_wrap)
	l = spin(List.repeat(0.U8, @SIZE@), 0, n)
	echo!(Str.concat(I64.to_str(U8.to_i64(List.get(l, 100) ?? 0)), "\n"))
	Ok({})
}
'
CRASHING='spin : List(U8), I64, I64 -> List(U8)
spin = |l, i, n| if i >= n { l } else { spin(List.set(l, I64.to_u64_wrap(I64.rem_by(i, @SIZE@)), 7.U8) ?? crash("oob"), i + 1, n) }
main! = |args| {
	n = @WRITES@ + (List.len(args) |> U64.to_i64_wrap)
	l = spin(List.repeat(0.U8, @SIZE@), 0, n)
	echo!(Str.concat(I64.to_str(U8.to_i64(List.get(l, 100) ?? 0)), "\n"))
	Ok({})
}
'
UPDATE='spin : List(List(U8)), I64, I64 -> List(List(U8))
spin = |ps, i, n|
	if i >= n { ps } else {
		spin(List.update(ps, 1, |p| List.set(p, I64.to_u64_wrap(I64.rem_by(i, @SIZE@)), 7.U8) ?? crash("oob")) ?? crash("oob"), i + 1, n)
	}
main! = |args| {
	n = @WRITES@ + (List.len(args) |> U64.to_i64_wrap)
	ps = spin([[], List.repeat(0.U8, @SIZE@)], 0, n)
	echo!(Str.concat(I64.to_str(U8.to_i64(List.get(List.get(ps, 1) ?? [], 100) ?? 0)), "\n"))
	Ok({})
}
'
TAKE='spin : List(List(U8)), I64, I64 -> List(List(U8))
spin = |ps, i, n|
	if i >= n { ps } else {
		taken = List.replace(ps, 1, []) ?? crash("oob")
		page = List.set(taken.prev, I64.to_u64_wrap(I64.rem_by(i, @SIZE@)), 7.U8) ?? crash("oob")
		spin(List.set(taken.list, 1, page) ?? crash("oob"), i + 1, n)
	}
main! = |args| {
	n = @WRITES@ + (List.len(args) |> U64.to_i64_wrap)
	ps = spin([[], List.repeat(0.U8, @SIZE@)], 0, n)
	echo!(Str.concat(I64.to_str(U8.to_i64(List.get(List.get(ps, 1) ?? [], 100) ?? 0)), "\n"))
	Ok({})
}
'
echo "$WRITES writes, list sizes: $SIZES"
want="${1:-all}"
[ "$want" = all ] || [ "$want" = naming ] && probe naming "$NAMING"
[ "$want" = all ] || [ "$want" = crashing ] && probe crashing "$CRASHING"
[ "$want" = all ] || [ "$want" = update ] && probe update "$UPDATE"
[ "$want" = all ] || [ "$want" = take ] && probe take "$TAKE"
exit 0
