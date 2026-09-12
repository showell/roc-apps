# Grade -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Grade :: [].{

	g_abs : F64 -> F64
	g_abs = |x| (if (x < 0.0) { (0.0 - x) } else { x })

	g_finite : F64 -> Bool
	g_finite = |x| (I64.bitwise_and(U64.to_i64_wrap(F64.to_bits(x)), 9223372036854775807) < 9218868437227405312)

	first_real_diff : List(F64), List(F64), F64, I64 -> I64
	first_real_diff = |got, want, tol, i| (if (i >= U64.to_i64_wrap(List.len(got))) { (0 - 1) } else { (if g_finite((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { (if (g_abs(((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - (List.get(want, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) > tol) { i } else { first_real_diff(got, want, tol, (i + 1)) }) } else { i }) })

	grade_reals : Str, List(F64), List(F64), F64 -> Str
	grade_reals = |name, got, want, tol| (if (U64.to_i64_wrap(List.len(got)) != U64.to_i64_wrap(List.len(want))) { Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD length "), I64.to_str(U64.to_i64_wrap(List.len(got)))), " want "), I64.to_str(U64.to_i64_wrap(List.len(want)))) } else { ({
		i = first_real_diff(got, want, tol, 0)
		(if (i < 0) { Str.concat(Str.concat(name, " ok "), I64.to_str(U64.to_i64_wrap(List.len(got)))) } else { Str.concat(Str.concat(name, " BAD at "), I64.to_str(i)) })
	}) })

	g_max : F64, F64 -> F64
	g_max = |a, b| (if (a > b) { a } else { b })

	first_rel_diff : List(F64), List(F64), F64, I64 -> I64
	first_rel_diff = |got, want, tol, i| (if (i >= U64.to_i64_wrap(List.len(got))) { (0 - 1) } else { (if g_finite((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { ({
		w = (List.get(want, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (g_abs(((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - w)) > (tol * g_max(1.0, g_abs(w)))) { i } else { first_rel_diff(got, want, tol, (i + 1)) })
	}) } else { i }) })

	grade_rel : Str, List(F64), List(F64), F64 -> Str
	grade_rel = |name, got, want, tol| (if (U64.to_i64_wrap(List.len(got)) != U64.to_i64_wrap(List.len(want))) { Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD length "), I64.to_str(U64.to_i64_wrap(List.len(got)))), " want "), I64.to_str(U64.to_i64_wrap(List.len(want)))) } else { ({
		i = first_rel_diff(got, want, tol, 0)
		(if (i < 0) { Str.concat(Str.concat(name, " ok "), I64.to_str(U64.to_i64_wrap(List.len(got)))) } else { Str.concat(Str.concat(name, " BAD at "), I64.to_str(i)) })
	}) })

	grade_px : Str, List(F64), List(F64), F64, F64 -> Str
	grade_px = |name, got, want, atol, rtol| (if (U64.to_i64_wrap(List.len(got)) != U64.to_i64_wrap(List.len(want))) { Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD length "), I64.to_str(U64.to_i64_wrap(List.len(got)))), " want "), I64.to_str(U64.to_i64_wrap(List.len(want)))) } else { ({
		i = first_px_diff(got, want, atol, rtol, 0)
		(if (i < 0) { Str.concat(Str.concat(name, " ok "), I64.to_str(U64.to_i64_wrap(List.len(got)))) } else { Str.concat(Str.concat(name, " BAD at "), I64.to_str(i)) })
	}) })

	first_px_diff : List(F64), List(F64), F64, F64, I64 -> I64
	first_px_diff = |got, want, atol, rtol, i| (if (i >= U64.to_i64_wrap(List.len(got))) { (0 - 1) } else { (if g_finite((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { ({
		w = (List.get(want, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (g_abs(((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - w)) > (atol + (rtol * g_abs(w)))) { i } else { first_px_diff(got, want, atol, rtol, (i + 1)) })
	}) } else { i }) })

	first_int_diff : List(I64), List(I64), I64 -> I64
	first_int_diff = |got, want, i| (if (i >= U64.to_i64_wrap(List.len(got))) { (0 - 1) } else { (if ((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(want, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { i } else { first_int_diff(got, want, (i + 1)) }) })

	grade_ints : Str, List(I64), List(I64) -> Str
	grade_ints = |name, got, want| (if (U64.to_i64_wrap(List.len(got)) != U64.to_i64_wrap(List.len(want))) { Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD length "), I64.to_str(U64.to_i64_wrap(List.len(got)))), " want "), I64.to_str(U64.to_i64_wrap(List.len(want)))) } else { ({
		i = first_int_diff(got, want, 0)
		(if (i < 0) { Str.concat(Str.concat(name, " ok "), I64.to_str(U64.to_i64_wrap(List.len(got)))) } else { Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD at "), I64.to_str(i)), " got "), I64.to_str((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))), " want "), I64.to_str((List.get(want, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })
	}) })

	bool_eq : Bool, Bool -> Bool
	bool_eq = |a, b| (if a { b } else { (if b { False } else { True }) })

	first_bool_diff : List(Bool), List(Bool), I64 -> I64
	first_bool_diff = |got, want, i| (if (i >= U64.to_i64_wrap(List.len(got))) { (0 - 1) } else { (if bool_eq((List.get(got, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(want, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { first_bool_diff(got, want, (i + 1)) } else { i }) })

	grade_bools : Str, List(Bool), List(Bool) -> Str
	grade_bools = |name, got, want| (if (U64.to_i64_wrap(List.len(got)) != U64.to_i64_wrap(List.len(want))) { Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD length "), I64.to_str(U64.to_i64_wrap(List.len(got)))), " want "), I64.to_str(U64.to_i64_wrap(List.len(want)))) } else { ({
		i = first_bool_diff(got, want, 0)
		(if (i < 0) { Str.concat(Str.concat(name, " ok "), I64.to_str(U64.to_i64_wrap(List.len(got)))) } else { Str.concat(Str.concat(name, " BAD at "), I64.to_str(i)) })
	}) })
}
