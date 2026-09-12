# The same program with the bound derived from the argument list, so the
# loop runs at run time instead. Identical work, identical garbage.
spin : List(U8), I64, I64 -> List(U8)
spin = |l, i, n| if i >= n { l } else { spin(List.set(l, I64.to_u64_wrap(I64.rem_by(i, 65536)), 7.U8) ?? l, i + 1, n) }

main! = |args| {
	n = 40000 + (List.len(args) |> U64.to_i64_wrap)
	l = spin(List.repeat(0.U8, 65536), 0, n)
	echo!(Str.concat(I64.to_str(U8.to_i64(List.get(l, 100) ?? 0)), "\n"))
	Ok({})
}
