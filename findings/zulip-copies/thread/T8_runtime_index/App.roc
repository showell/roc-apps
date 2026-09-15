# T1 with the written index from the command line, so no range proof can
# remove the bounds check. 10,000 writes.
#
#   App <size> <index>
M : { num : List(F64), scr : List(U8), out : List(Str), pc : U64 }

walk : M, List(U8), U64 -> M
walk = |m, b, i|
	if i >= List.len(b) { m } else { walk(m, b, i + 1) }

spin : M, List(U8), U64, U64, U64 -> M
spin = |m, b, k, i, n|
	if i >= n {
		m
	} else {
		m1 = walk(m, b, 0)
		spin({ ..m1, num: List.set(m1.num, k, 1.0) ?? crash("oob"), pc: i }, b, k, i + 1, n)
	}

main! = |args| {
	size = I64.to_u64_wrap(I64.from_str(List.get(args, 0) ?? "286") ?? 286)
	k = I64.to_u64_wrap(I64.from_str(List.get(args, 1) ?? "7") ?? 7)
	m0 = { num: List.repeat(0.0, size), scr: List.repeat(32.U8, 1000), out: [], pc: 0 }
	final = spin(m0, Str.to_utf8("X=X+1 AND SOME MORE TEXT"), k, 0, 10000)
	echo!(F64.to_str(List.get(final.num, k) ?? 0.0))
	Ok({})
}
