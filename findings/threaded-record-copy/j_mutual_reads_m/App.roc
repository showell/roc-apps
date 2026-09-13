M : { num : List(F64), scr : List(U8), out : List(Str), pc : U64 }

sum : M, List(U8), U64, F64 -> { v : F64, at : U64 }
sum = |m, b, i, acc|
	if i >= List.len(b) { { v: acc + (List.get(m.num, 7) ?? 0.0), at: i } } else { term(m, b, i, acc) }

term : M, List(U8), U64, F64 -> { v : F64, at : U64 }
term = |m, b, i, acc| sum(m, b, i + 1, acc + U8.to_f64(List.get(b, i) ?? 0))

spin : M, List(U8), U64, U64 -> M
spin = |m, b, i, n|
	if i >= n {
		m
	} else {
		r = sum(m, b, 0, 0.0)
		spin({ ..m, num: List.set(m.num, 7, r.v - (List.get(m.num, 7) ?? 0.0)) ?? crash("oob"), pc: r.at }, b, i + 1, n)
	}

main! = |args| {
	n = 10000 + List.len(args)
	m0 = { num: List.repeat(0.0, 286), scr: List.repeat(32.U8, 1000), out: [], pc: 0 }
	final = spin(m0, Str.to_utf8("X=X+1 AND SOME MORE TEXT"), 0, n)
	echo!(F64.to_str(List.get(final.num, 7) ?? 0.0))
	Ok({})
}
