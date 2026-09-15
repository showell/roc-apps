# threaded-record-copy's h_recursive_returns_m, with the written list's size
# from the command line: a recursive walk hands the machine back, then one
# element of `num` is written. 10,000 writes.
M : { num : List(F64), scr : List(U8), out : List(Str), pc : U64 }

walk : M, List(U8), U64 -> M
walk = |m, b, i|
	if i >= List.len(b) { m } else { walk(m, b, i + 1) }

spin : M, List(U8), U64, U64 -> M
spin = |m, b, i, n|
	if i >= n {
		m
	} else {
		m1 = walk(m, b, 0)
		spin({ ..m1, num: List.set(m1.num, 7, 1.0) ?? crash("oob"), pc: i }, b, i + 1, n)
	}

main! = |args| {
	size = I64.to_u64_wrap(I64.from_str(List.get(args, 0) ?? "286") ?? 286)
	m0 = { num: List.repeat(0.0, size), scr: List.repeat(32.U8, 1000), out: [], pc: 0 }
	final = spin(m0, Str.to_utf8("X=X+1 AND SOME MORE TEXT"), 0, 10000)
	echo!(F64.to_str(List.get(final.num, 7) ?? 0.0))
	Ok({})
}
