# Each step copies the 64 KB list, because the `??` fallback names the
# list being set, so `l` is still live when List.set runs. The copies are
# dead the moment the next step is taken.
#
# The bound is a literal, so the whole loop is evaluated at compile time.
spin : List(U8), I64, I64 -> List(U8)
spin = |l, i, n| if i >= n { l } else { spin(List.set(l, I64.to_u64_wrap(I64.rem_by(i, 65536)), 7.U8) ?? l, i + 1, n) }

main! = |_args| {
	l = spin(List.repeat(0.U8, 65536), 0, 40000)
	echo!(Str.concat(I64.to_str(U8.to_i64(List.get(l, 100) ?? 0)), "\n"))
	Ok({})
}
