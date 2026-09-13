M : { num : List(F64), scr : List(U8), out : List(Str), pc : U64 }
R : { m : M, v : F64, at : U64 }

eval : List(U8), U64, F64 -> { v : F64, at : U64 }
eval = |b, i, acc|
	if i >= List.len(b) { { v: acc, at: i } } else { eval(b, i + 1, acc + U8.to_f64(List.get(b, i) ?? 0)) }

spin : M, List(U8), U64, U64 -> M
spin = |m, b, i, n|
	if i >= n {
		m
	} else {
		r = eval(b, 0, 0.0)
		spin({ ..m, num: List.set(m.num, 7, r.v) ?? crash("oob"), pc: r.at }, b, i + 1, n)
	}

main! = |args| {
	n = 10000 + List.len(args)
	m0 = { num: List.repeat(0.0, 286), scr: List.repeat(32.U8, 1000), out: [], pc: 0 }
	final = spin(m0, Str.to_utf8("X=X+1 AND SOME MORE TEXT"), 0, n)
	echo!(F64.to_str(List.get(final.num, 7) ?? 0.0))
	Ok({})
}
