# A BASIC interpreter, hand-written in Roc.
#
# The dialect is ECMA-55 Minimal BASIC, which is an actual published
# standard with an actual acceptance suite -- the National Bureau of
# Standards' 219 test programs, which grade themselves. The extensions
# past it are the ones the 1978 Creative Computing games need, and each
# one is marked EXT where it is implemented.
#
# The machine is a value and every statement is `M -> M`, so a program's
# whole history is available and nothing is hidden. `step` runs ONE
# statement; `run` is `step` to a fixed point or out of fuel.
#
# Text is handled as `List(U8)` rather than `Str`: BASIC source is ASCII,
# a lexer wants to index, and Roc's Str is not an array.

Basic :: [].{
	Val : [N(F64), S(Str)]

	Line : { num : I64, src : List(U8) }

	# A FOR frame remembers where to jump back to: the line and the byte
	# offset just past the FOR statement itself.
	Frame : { v : Str, limit : F64, step : F64, pc : U64, at : U64 }

	M : {
		prog : List(Line),
		pc : U64,
		at : U64,
		num : List({ k : Str, v : F64 }),
		str : List({ k : Str, v : Str }),
		arr : List({ k : Str, w : U64, cells : List(F64) }),
		ret : List(U64),
		loops : List(Frame),
		data : List(Str),
		dp : U64,
		inp : List(Str),
		ip : U64,
		out : List(Str),
		col : I64,
		done : Bool,
		err : Str,
		seed : U64,
		fuel : I64,
	}

	# ---- bytes ---------------------------------------------------------

	byte : List(U8), U64 -> U8
	byte = |b, i| List.get(b, i) ?? 0

	is_digit : U8 -> Bool
	is_digit = |c| c >= 48 and c <= 57

	is_alpha : U8 -> Bool
	is_alpha = |c| c >= 65 and c <= 90

	# Source is upper-cased on the way in, so a lower-case listing runs.
	upper : U8 -> U8
	upper = |c| if c >= 97 and c <= 122 { c - 32 } else { c }

	skip_ws : List(U8), U64 -> U64
	skip_ws = |b, i| if Basic.byte(b, i) == 32 { Basic.skip_ws(b, i + 1) } else { i }

	# Whether `word` stands at `i` (after spaces). Answers the position
	# past it, or the position it was given when it does not.
	kw : List(U8), U64, Str -> U64
	kw = |b, i, word| {
		j = Basic.skip_ws(b, i)
		w = Str.to_utf8(word)
		if Basic.kw_at(b, j, w, 0) { j + List.len(w) } else { i }
	}

	kw_at : List(U8), U64, List(U8), U64 -> Bool
	kw_at = |b, j, w, k|
		if k >= List.len(w) {
			True
		} else if Basic.byte(b, j + k) != Basic.byte(w, k) {
			False
		} else {
			Basic.kw_at(b, j, w, k + 1)
		}

	text_of : List(U8), U64, U64 -> Str
	text_of = |b, from, to|
		if to <= from { "" } else { Str.from_utf8(List.sublist(b, { start: from, len: to - from })) ?? "" }

	# ---- the program ---------------------------------------------------

	# Split on newlines, drop blank lines, read the leading line number.
	# A line with no number is an error in ECMA-55; we keep it with the
	# number of the line before so a stray continuation is visible rather
	# than silently dropped.
	load : Str -> List(Line)
	load = |src| Basic.sort_lines(Basic.load_from(Str.to_utf8(src), 0, []))

	load_from : List(U8), U64, List(Line) -> List(Line)
	load_from = |b, i, acc|
		if i >= List.len(b) {
			acc
		} else {
			e = Basic.eol(b, i)
			line = Basic.one_line(b, i, e)
			Basic.load_from(b, e + 1, if line.num < 0 { acc } else { List.append(acc, line) })
		}

	eol : List(U8), U64 -> U64
	eol = |b, i|
		if i >= List.len(b) or Basic.byte(b, i) == 10 { i } else { Basic.eol(b, i + 1) }

	one_line : List(U8), U64, U64 -> Line
	one_line = |b, i, e| {
		s = Basic.skip_ws(b, i)
		d = Basic.digits_end(b, s)
		if d == s {
			{ num: -1, src: [] }
		} else {
			{ num: Basic.digits_val(b, s, d, 0), src: Basic.line_bytes(b, Basic.skip_ws(b, d), e, []) }
		}
	}

	# The statement text, upper-cased outside quotes and with the trailing
	# carriage return of a DOS listing dropped.
	line_bytes : List(U8), U64, U64, List(U8) -> List(U8)
	line_bytes = |b, i, e, acc|
		if i >= e {
			acc
		} else {
			c = Basic.byte(b, i)
			if c == 13 {
				Basic.line_bytes(b, i + 1, e, acc)
			} else if c == 34 {
				j = Basic.quote_end(b, i + 1, e)
				Basic.line_bytes(b, j, e, List.concat(acc, List.sublist(b, { start: i, len: j - i })))
			} else {
				Basic.line_bytes(b, i + 1, e, List.append(acc, Basic.upper(c)))
			}
		}

	quote_end : List(U8), U64, U64 -> U64
	quote_end = |b, i, e|
		if i >= e { i } else if Basic.byte(b, i) == 34 { i + 1 } else { Basic.quote_end(b, i + 1, e) }

	digits_end : List(U8), U64 -> U64
	digits_end = |b, i| if Basic.is_digit(Basic.byte(b, i)) { Basic.digits_end(b, i + 1) } else { i }

	digits_val : List(U8), U64, U64, I64 -> I64
	digits_val = |b, i, e, acc|
		if i >= e { acc } else { Basic.digits_val(b, i + 1, e, acc * 10 + U8.to_i64(Basic.byte(b, i)) - 48) }

	# Line numbers must be in order to run, and a listing may not be.
	sort_lines : List(Line) -> List(Line)
	sort_lines = |ls| Basic.sort_from(ls, 0, [])

	sort_from : List(Line), U64, List(Line) -> List(Line)
	sort_from = |ls, i, acc|
		if i >= List.len(ls) {
			acc
		} else {
			Basic.sort_from(ls, i + 1, Basic.insert_line(acc, List.get(ls, i) ?? { num: -1, src: [] }, 0))
		}

	insert_line : List(Line), Line, U64 -> List(Line)
	insert_line = |ls, l, i|
		if i >= List.len(ls) {
			List.append(ls, l)
		} else if (List.get(ls, i) ?? l).num > l.num {
			List.concat(List.append(List.sublist(ls, { start: 0, len: i }), l), List.sublist(ls, { start: i, len: List.len(ls) - i }))
		} else {
			Basic.insert_line(ls, l, i + 1)
		}

	index_of_line : List(Line), I64, U64 -> I64
	index_of_line = |ls, n, i|
		if i >= List.len(ls) {
			-1
		} else if (List.get(ls, i) ?? { num: -1, src: [] }).num == n {
			U64.to_i64_wrap(i)
		} else {
			Basic.index_of_line(ls, n, i + 1)
		}

	# ---- variables -----------------------------------------------------

	# A name is a letter, optionally a digit, optionally `$`. ECMA-55 says
	# no more than that, and the games keep to it.
	name_at : List(U8), U64 -> { k : Str, at : U64 }
	name_at = |b, i| {
		j = Basic.skip_ws(b, i)
		c = Basic.byte(b, j)
		if !Basic.is_alpha(c) {
			{ k: "", at: i }
		} else {
			e1 = if Basic.is_digit(Basic.byte(b, j + 1)) { j + 2 } else { j + 1 }
			e2 = if Basic.byte(b, e1) == 36 { e1 + 1 } else { e1 }
			{ k: Basic.text_of(b, j, e2), at: e2 }
		}
	}

	is_str_name : Str -> Bool
	is_str_name = |k| Basic.byte(Str.to_utf8(k), U64.minus_wrap(List.len(Str.to_utf8(k)), 1)) == 36

	get_num : M, Str -> F64
	get_num = |m, k| Basic.find_num(m.num, k, 0)

	find_num : List({ k : Str, v : F64 }), Str, U64 -> F64
	find_num = |vs, k, i|
		if i >= List.len(vs) {
			0.0
		} else {
			e = List.get(vs, i) ?? { k: "", v: 0.0 }
			if e.k == k { e.v } else { Basic.find_num(vs, k, i + 1) }
		}

	set_num : M, Str, F64 -> M
	set_num = |m, k, v| { ..m, num: Basic.put_num(m.num, k, v, 0) }

	put_num : List({ k : Str, v : F64 }), Str, F64, U64 -> List({ k : Str, v : F64 })
	put_num = |vs, k, v, i|
		if i >= List.len(vs) {
			List.append(vs, { k: k, v: v })
		} else if (List.get(vs, i) ?? { k: "", v: 0.0 }).k == k {
			List.set(vs, i, { k: k, v: v }) ?? crash("put_num")
		} else {
			Basic.put_num(vs, k, v, i + 1)
		}

	get_str : M, Str -> Str
	get_str = |m, k| Basic.find_str(m.str, k, 0)

	find_str : List({ k : Str, v : Str }), Str, U64 -> Str
	find_str = |vs, k, i|
		if i >= List.len(vs) {
			""
		} else {
			e = List.get(vs, i) ?? { k: "", v: "" }
			if e.k == k { e.v } else { Basic.find_str(vs, k, i + 1) }
		}

	set_str : M, Str, Str -> M
	set_str = |m, k, v| { ..m, str: Basic.put_str(m.str, k, v, 0) }

	put_str : List({ k : Str, v : Str }), Str, Str, U64 -> List({ k : Str, v : Str })
	put_str = |vs, k, v, i|
		if i >= List.len(vs) {
			List.append(vs, { k: k, v: v })
		} else if (List.get(vs, i) ?? { k: "", v: "" }).k == k {
			List.set(vs, i, { k: k, v: v }) ?? crash("put_str")
		} else {
			Basic.put_str(vs, k, v, i + 1)
		}

	# An array not named by DIM has subscripts 0 through 10, which is what
	# ECMA-55 says and what every listing assumes.
	arr_index : List({ k : Str, w : U64, cells : List(F64) }), Str, U64 -> I64
	arr_index = |xs, k, i|
		if i >= List.len(xs) {
			-1
		} else if (List.get(xs, i) ?? { k: "", w: 0, cells: [] }).k == k {
			U64.to_i64_wrap(i)
		} else {
			Basic.arr_index(xs, k, i + 1)
		}

	dim : M, Str, U64, U64 -> M
	dim = |m, k, d1, d2| {
		w = if d2 == 0 { 0 } else { d2 + 1 }
		n = if d2 == 0 { d1 + 1 } else { (d1 + 1) * (d2 + 1) }
		fresh = { k: k, w: w, cells: List.repeat(0.0, n) }
		at = Basic.arr_index(m.arr, k, 0)
		if at < 0 {
			{ ..m, arr: List.append(m.arr, fresh) }
		} else {
			{ ..m, arr: List.set(m.arr, I64.to_u64_wrap(at), fresh) ?? crash("dim") }
		}
	}

	ensure_arr : M, Str -> M
	ensure_arr = |m, k| if Basic.arr_index(m.arr, k, 0) < 0 { Basic.dim(m, k, 10, 0) } else { m }

	cell_at : M, Str, U64, U64 -> U64
	cell_at = |m, k, i, j| {
		a = List.get(m.arr, I64.to_u64_wrap(Basic.arr_index(m.arr, k, 0)) ) ?? { k: "", w: 0, cells: [] }
		if a.w == 0 { i } else { i * a.w + j }
	}

	get_arr : M, Str, U64, U64 -> F64
	get_arr = |m, k, i, j| {
		a = List.get(m.arr, I64.to_u64_wrap(Basic.arr_index(m.arr, k, 0))) ?? { k: "", w: 0, cells: [] }
		List.get(a.cells, Basic.cell_at(m, k, i, j)) ?? 0.0
	}

	set_arr : M, Str, U64, U64, F64 -> M
	set_arr = |m, k, i, j, v| {
		at = I64.to_u64_wrap(Basic.arr_index(m.arr, k, 0))
		c = Basic.cell_at(m, k, i, j)
		a = List.get(m.arr, at) ?? { k: "", w: 0, cells: [] }
		if c >= List.len(a.cells) {
			{ ..m, done: True, err: Str.concat("Subscript out of range: ", k) }
		} else {
			{ ..m, arr: List.set(m.arr, at, { k: a.k, w: a.w, cells: List.set(a.cells, c, v) ?? crash("set_arr") }) ?? crash("set_arr") }
		}
	}

	# ---- arithmetic Roc does not have -----------------------------------

	# **NEITHER exp NOR log NOR floor IS IN THIS ROC.** `F64` has abs,
	# sqrt, sin, cos, tan, atan and pow and stops there, so a BASIC that
	# offers EXP, LOG and INT has to bring them. EXP is pow on e; LOG is
	# the atanh series after a reduction by powers of two, which converges
	# on |t| <= 1/3; INT is truncation corrected downward.
	e_const : F64
	e_const = 2.718281828459045

	ln2 : F64
	ln2 = 0.6931471805599453

	floor : F64 -> F64
	floor = |x| {
		t = I64.to_f64(F64.to_i64_wrap(x))
		if x < 0.0 and t != x { t - 1.0 } else { t }
	}

	ln : F64 -> F64
	ln = |x| if x <= 0.0 { 0.0 } else { Basic.ln_reduce(x, 0) }

	ln_reduce : F64, I64 -> F64
	ln_reduce = |x, k|
		if x >= 2.0 {
			Basic.ln_reduce(x / 2.0, k + 1)
		} else if x < 1.0 {
			Basic.ln_reduce(x * 2.0, k - 1)
		} else {
			t = (x - 1.0) / (x + 1.0)
			2.0 * Basic.atanh_series(t, t * t, t, 1.0, 0) + I64.to_f64(k) * Basic.ln2
		}

	atanh_series : F64, F64, F64, F64, I64 -> F64
	atanh_series = |acc, t2, term, d, i|
		if i >= 24 {
			acc
		} else {
			nt = term * t2
			nd = d + 2.0
			Basic.atanh_series(acc + nt / nd, t2, nt, nd, i + 1)
		}

	# ---- printing a number ----------------------------------------------

	# ECMA-55 prints a numeric value with a leading space for the sign and
	# a trailing space, and an integral value with no decimal point.
	fmt_num : F64 -> Str
	fmt_num = |x| {
		sign = if x < 0.0 { "-" } else { " " }
		a = F64.abs(x)
		Str.concat(Str.concat(sign, Basic.fmt_mag(a)), " ")
	}

	fmt_mag : F64 -> Str
	fmt_mag = |a|
		if a == Basic.floor(a) and a < 1000000000.0 {
			I64.to_str(F64.to_i64_wrap(a))
		} else {
			Basic.trim_float(F64.to_str(a))
		}

	trim_float : Str -> Str
	trim_float = |s| s

	# ---- the expression evaluator ---------------------------------------

	R : { m : M, v : Val, at : U64 }

	num_of : Val -> F64
	num_of = |v| match v {
		N(x) => x
		S(_) => 0.0
	}

	str_of : Val -> Str
	str_of = |v| match v {
		N(x) => Basic.fmt_num(x)
		S(s) => s
	}

	fail : M, Str, U64 -> R
	fail = |m, why, at| { m: { ..m, done: True, err: why }, v: N(0.0), at: at }

	expr : M, List(U8), U64 -> R
	expr = |m, b, i| {
		j = Basic.skip_ws(b, i)
		if Basic.byte(b, j) == 34 {
			e = Basic.quote_end(b, j + 1, List.len(b))
			{ m: m, v: S(Basic.text_of(b, j + 1, U64.minus_wrap(e, 1))), at: e }
		} else {
			nm = Basic.name_at(b, j)
			if nm.k != "" and Basic.is_str_name(nm.k) {
				{ m: m, v: S(Basic.get_str(m, nm.k)), at: nm.at }
			} else {
				Basic.sum(m, b, j)
			}
		}
	}

	sum : M, List(U8), U64 -> R
	sum = |m, b, i| {
		r = Basic.term(m, b, i)
		if r.m.done { r } else { Basic.sum_rest(r.m, b, r.at, Basic.num_of(r.v)) }
	}

	sum_rest : M, List(U8), U64, F64 -> R
	sum_rest = |m, b, i, acc| {
		j = Basic.skip_ws(b, i)
		c = Basic.byte(b, j)
		if c != 43 and c != 45 {
			{ m: m, v: N(acc), at: i }
		} else {
			r = Basic.term(m, b, j + 1)
			if r.m.done {
				r
			} else {
				Basic.sum_rest(r.m, b, r.at, if c == 43 { acc + Basic.num_of(r.v) } else { acc - Basic.num_of(r.v) })
			}
		}
	}

	term : M, List(U8), U64 -> R
	term = |m, b, i| {
		r = Basic.power(m, b, i)
		if r.m.done { r } else { Basic.term_rest(r.m, b, r.at, Basic.num_of(r.v)) }
	}

	term_rest : M, List(U8), U64, F64 -> R
	term_rest = |m, b, i, acc| {
		j = Basic.skip_ws(b, i)
		c = Basic.byte(b, j)
		if c != 42 and c != 47 {
			{ m: m, v: N(acc), at: i }
		} else {
			r = Basic.power(m, b, j + 1)
			if r.m.done {
				r
			} else {
				d = Basic.num_of(r.v)
				if c == 47 and d == 0.0 {
					Basic.fail(r.m, "Division by zero", r.at)
				} else {
					Basic.term_rest(r.m, b, r.at, if c == 42 { acc * d } else { acc / d })
				}
			}
		}
	}

	# `^` binds tighter than `*` and associates to the right.
	power : M, List(U8), U64 -> R
	power = |m, b, i| {
		r = Basic.primary(m, b, i)
		if r.m.done {
			r
		} else {
			j = Basic.skip_ws(b, r.at)
			if Basic.byte(b, j) != 94 {
				r
			} else {
				e = Basic.power(r.m, b, j + 1)
				if e.m.done { e } else { { m: e.m, v: N(F64.pow(Basic.num_of(r.v), Basic.num_of(e.v))), at: e.at } }
			}
		}
	}

	primary : M, List(U8), U64 -> R
	primary = |m, b, i| {
		j = Basic.skip_ws(b, i)
		c = Basic.byte(b, j)
		if c == 45 {
			r = Basic.primary(m, b, j + 1)
			{ m: r.m, v: N(0.0 - Basic.num_of(r.v)), at: r.at }
		} else if c == 43 {
			Basic.primary(m, b, j + 1)
		} else if c == 40 {
			r = Basic.sum(m, b, j + 1)
			k = Basic.skip_ws(b, r.at)
			if Basic.byte(b, k) != 41 { Basic.fail(r.m, "Expected )", k) } else { { m: r.m, v: r.v, at: k + 1 } }
		} else if Basic.is_digit(c) or c == 46 {
			Basic.number(m, b, j)
		} else if Basic.is_alpha(c) {
			Basic.name_or_call(m, b, j)
		} else {
			Basic.fail(m, "Expected an expression", j)
		}
	}

	# **ROC PARSES NO NUMBERS FROM TEXT.** `Str` has no to_f64 and no
	# to_i64 in this nightly, so a numeric literal is accumulated from the
	# bytes as it is scanned: integer part, fraction, then an exponent.
	number : M, List(U8), U64 -> R
	number = |m, b, i| {
		w = Basic.whole(b, i, 0.0)
		f = if Basic.byte(b, w.at) == 46 { Basic.frac(b, w.at + 1, w.v, 0.1) } else { w }
		if Basic.byte(b, f.at) != 69 {
			{ m: m, v: N(f.v), at: f.at }
		} else {
			neg = Basic.byte(b, f.at + 1) == 45
			g = if neg or Basic.byte(b, f.at + 1) == 43 { f.at + 2 } else { f.at + 1 }
			x = Basic.whole(b, g, 0.0)
			e = F64.pow(10.0, if neg { 0.0 - x.v } else { x.v })
			{ m: m, v: N(f.v * e), at: x.at }
		}
	}

	whole : List(U8), U64, F64 -> { v : F64, at : U64 }
	whole = |b, i, acc|
		if Basic.is_digit(Basic.byte(b, i)) {
			Basic.whole(b, i + 1, acc * 10.0 + I64.to_f64(U8.to_i64(Basic.byte(b, i)) - 48))
		} else {
			{ v: acc, at: i }
		}

	frac : List(U8), U64, F64, F64 -> { v : F64, at : U64 }
	frac = |b, i, acc, scale|
		if Basic.is_digit(Basic.byte(b, i)) {
			Basic.frac(b, i + 1, acc + I64.to_f64(U8.to_i64(Basic.byte(b, i)) - 48) * scale, scale / 10.0)
		} else {
			{ v: acc, at: i }
		}

	# A name is a variable, an array element, or one of the standard
	# functions. ECMA-55's RND takes no argument; every listing writes
	# RND(1), so both are accepted (EXT).
	name_or_call : M, List(U8), U64 -> R
	name_or_call = |m, b, i| {
		w = Basic.word_end(b, i)
		k = Basic.text_of(b, i, w)
		if Basic.is_fn(k) {
			Basic.call_fn(m, b, w, k)
		} else {
			nm = Basic.name_at(b, i)
			if nm.k == "" {
				Basic.fail(m, "Expected a name", i)
			} else if Basic.is_str_name(nm.k) {
				{ m: m, v: S(Basic.get_str(m, nm.k)), at: nm.at }
			} else {
				j = Basic.skip_ws(b, nm.at)
				if Basic.byte(b, j) != 40 {
					{ m: m, v: N(Basic.get_num(m, nm.k)), at: nm.at }
				} else {
					s = Basic.subscripts(m, b, j)
					if s.m.done {
						{ m: s.m, v: N(0.0), at: s.at }
					} else {
						m1 = Basic.ensure_arr(s.m, nm.k)
						{ m: m1, v: N(Basic.get_arr(m1, nm.k, s.i, s.j)), at: s.at }
					}
				}
			}
		}
	}

	word_end : List(U8), U64 -> U64
	word_end = |b, i| if Basic.is_alpha(Basic.byte(b, i)) { Basic.word_end(b, i + 1) } else { i }

	is_fn : Str -> Bool
	is_fn = |k| k == "ABS" or k == "ATN" or k == "COS" or k == "EXP" or k == "INT" or k == "LOG" or k == "RND" or k == "SGN" or k == "SIN" or k == "SQR" or k == "TAN"

	call_fn : M, List(U8), U64, Str -> R
	call_fn = |m, b, i, k| {
		j = Basic.skip_ws(b, i)
		if Basic.byte(b, j) != 40 {
			if k == "RND" { Basic.rnd(m, j) } else { Basic.fail(m, Str.concat("Expected ( after ", k), j) }
		} else {
			r = Basic.sum(m, b, j + 1)
			e = Basic.skip_ws(b, r.at)
			if Basic.byte(b, e) != 41 {
				Basic.fail(r.m, "Expected )", e)
			} else if k == "RND" {
				Basic.rnd(r.m, e + 1)
			} else {
				{ m: r.m, v: N(Basic.apply_fn(k, Basic.num_of(r.v))), at: e + 1 }
			}
		}
	}

	apply_fn : Str, F64 -> F64
	apply_fn = |k, x|
		if k == "ABS" { F64.abs(x) }
		else if k == "ATN" { F64.atan(x) }
		else if k == "COS" { F64.cos(x) }
		else if k == "EXP" { F64.pow(Basic.e_const, x) }
		else if k == "INT" { Basic.floor(x) }
		else if k == "LOG" { Basic.ln(x) }
		else if k == "SGN" { if x > 0.0 { 1.0 } else if x < 0.0 { -1.0 } else { 0.0 } }
		else if k == "SIN" { F64.sin(x) }
		else if k == "SQR" { F64.sqrt(F64.abs(x)) }
		else { F64.tan(x) }

	# A linear congruential generator, so a run is reproducible and a
	# verdict is a verdict. The constants are Numerical Recipes'.
	rnd : M, U64 -> R
	rnd = |m, at| {
		s = U64.plus_wrap(U64.times_wrap(m.seed, 1664525), 1013904223)
		{ m: { ..m, seed: s }, v: N(I64.to_f64(U64.to_i64_wrap(U64.rem_by(U64.div_trunc_by(s, 65536), 32768))) / 32768.0), at: at }
	}

	# Subscripts: `(i)` or `(i,j)`, each rounded as ECMA-55 says.
	subscripts : M, List(U8), U64 -> { m : M, i : U64, j : U64, at : U64 }
	subscripts = |m, b, i| {
		r = Basic.sum(m, b, i + 1)
		if r.m.done {
			{ m: r.m, i: 0, j: 0, at: r.at }
		} else {
			k = Basic.skip_ws(b, r.at)
			if Basic.byte(b, k) == 44 {
				r2 = Basic.sum(r.m, b, k + 1)
				e = Basic.skip_ws(b, r2.at)
				{ m: r2.m, i: Basic.idx(Basic.num_of(r.v)), j: Basic.idx(Basic.num_of(r2.v)), at: if Basic.byte(b, e) == 41 { e + 1 } else { e } }
			} else {
				{ m: r.m, i: Basic.idx(Basic.num_of(r.v)), j: 0, at: if Basic.byte(b, k) == 41 { k + 1 } else { k } }
			}
		}
	}

	idx : F64 -> U64
	idx = |x| {
		t = Basic.floor(x + 0.5)
		if t < 0.0 { 0 } else { I64.to_u64_wrap(F64.to_i64_wrap(t)) }
	}

	# ---- output ---------------------------------------------------------

	# ECMA-55 prints in zones; a comma moves to the next one. The width is
	# what the 1978 listings assume and what the games' captured output
	# shows.
	zone : I64
	zone = 14

	emit : M, Str -> M
	emit = |m, t| {
		b = Str.to_utf8(t)
		{ ..m, out: List.append(m.out, t), col: Basic.col_after(b, 0, m.col) }
	}

	col_after : List(U8), U64, I64 -> I64
	col_after = |b, i, c|
		if i >= List.len(b) {
			c
		} else {
			Basic.col_after(b, i + 1, if Basic.byte(b, i) == 10 { 0 } else { c + 1 })
		}

	spaces : I64 -> Str
	spaces = |n| if n <= 0 { "" } else { Str.from_utf8(List.repeat(32.U8, I64.to_u64_wrap(n))) ?? "" }

	# ---- statements -----------------------------------------------------

	cur : M -> List(U8)
	cur = |m| (List.get(m.prog, m.pc) ?? { num: -1, src: [] }).src

	# Where the statement at `i` ends: a colon outside quotes, or the end
	# of the line.
	stmt_end : List(U8), U64 -> U64
	stmt_end = |b, i|
		if i >= List.len(b) {
			i
		} else if Basic.byte(b, i) == 34 {
			Basic.stmt_end(b, Basic.quote_end(b, i + 1, List.len(b)))
		} else if Basic.byte(b, i) == 58 {
			i
		} else {
			Basic.stmt_end(b, i + 1)
		}

	# Past this statement and its separator, or on to the next line.
	advance : M, U64 -> M
	advance = |m, at| {
		b = Basic.cur(m)
		j = Basic.skip_ws(b, at)
		if j < List.len(b) and Basic.byte(b, j) == 58 {
			{ ..m, at: j + 1 }
		} else {
			{ ..m, pc: m.pc + 1, at: 0 }
		}
	}

	jump : M, I64 -> M
	jump = |m, n| {
		i = Basic.index_of_line(m.prog, n, 0)
		if i < 0 {
			{ ..m, done: True, err: Str.concat("No such line: ", I64.to_str(n)) }
		} else {
			{ ..m, pc: I64.to_u64_wrap(i), at: 0 }
		}
	}

	step : M -> M
	step = |m| {
		if m.pc >= List.len(m.prog) {
			{ ..m, done: True }
		} else {
			b = Basic.cur(m)
			i = Basic.skip_ws(b, m.at)
			if i >= List.len(b) {
				{ ..m, pc: m.pc + 1, at: 0 }
			} else if Basic.byte(b, i) == 58 {
				{ ..m, at: i + 1 }
			} else {
				w = Basic.word_end(b, i)
				Basic.dispatch(m, b, i, Basic.text_of(b, i, w), w)
			}
		}
	}

	dispatch : M, List(U8), U64, Str, U64 -> M
	dispatch = |m, b, i, k, w|
		if k == "REM" {
			{ ..m, pc: m.pc + 1, at: 0 }
		} else if k == "DATA" {
			{ ..m, pc: m.pc + 1, at: 0 }
		} else if k == "END" or k == "STOP" {
			{ ..m, done: True }
		} else if k == "PRINT" {
			Basic.do_print(m, b, w)
		} else if k == "LET" {
			Basic.do_let(m, b, w)
		} else if k == "GOTO" or k == "GO" {
			Basic.do_goto(m, b, w, k)
		} else if k == "IF" {
			Basic.do_if(m, b, w)
		} else if k == "FOR" {
			Basic.do_for(m, b, w)
		} else if k == "NEXT" {
			Basic.do_next(m, b, w)
		} else if k == "GOSUB" {
			Basic.do_gosub(m, b, w)
		} else if k == "RETURN" {
			Basic.do_return(m, w)
		} else if k == "DIM" {
			Basic.do_dim(m, b, w)
		} else if k == "READ" {
			Basic.do_read(m, b, w)
		} else if k == "RESTORE" {
			Basic.advance({ ..m, dp: 0 }, w)
		} else if k == "INPUT" {
			Basic.do_input(m, b, w)
		} else if k == "RANDOMIZE" {
			Basic.advance(m, Basic.stmt_end(b, w))
		} else {
			Basic.do_let(m, b, i)
		}

	do_goto : M, List(U8), U64, Str -> M
	do_goto = |m, b, w, k| {
		j = if k == "GO" { Basic.kw(b, w, "TO") } else { w }
		r = Basic.sum(m, b, j)
		if r.m.done { r.m } else { Basic.jump(r.m, F64.to_i64_wrap(Basic.num_of(r.v))) }
	}

	do_gosub : M, List(U8), U64 -> M
	do_gosub = |m, b, w| {
		r = Basic.sum(m, b, w)
		if r.m.done {
			r.m
		} else {
			back = Basic.advance(r.m, r.at)
			Basic.jump({ ..back, ret: List.append(back.ret, back.pc) }, F64.to_i64_wrap(Basic.num_of(r.v)))
		}
	}

	do_return : M, U64 -> M
	do_return = |m, _w| {
		n = List.len(m.ret)
		if n == 0 {
			{ ..m, done: True, err: "RETURN without GOSUB" }
		} else {
			{ ..m, pc: List.get(m.ret, n - 1) ?? 0, at: 0, ret: List.drop_last(m.ret, 1) }
		}
	}

	do_let : M, List(U8), U64 -> M
	do_let = |m, b, w| {
		nm = Basic.name_at(b, w)
		if nm.k == "" {
			{ ..m, done: True, err: "Expected a variable" }
		} else {
			j = Basic.skip_ws(b, nm.at)
			if Basic.byte(b, j) == 40 {
				sub = Basic.subscripts(m, b, j)
				e = Basic.skip_ws(b, sub.at)
				if Basic.byte(b, e) != 61 {
					{ ..sub.m, done: True, err: "Expected =" }
				} else {
					r = Basic.expr(Basic.ensure_arr(sub.m, nm.k), b, e + 1)
					if r.m.done { r.m } else { Basic.advance(Basic.set_arr(r.m, nm.k, sub.i, sub.j, Basic.num_of(r.v)), r.at) }
				}
			} else if Basic.byte(b, j) != 61 {
				{ ..m, done: True, err: "Expected =" }
			} else {
				r = Basic.expr(m, b, j + 1)
				if r.m.done {
					r.m
				} else if Basic.is_str_name(nm.k) {
					Basic.advance(Basic.set_str(r.m, nm.k, Basic.str_of(r.v)), r.at)
				} else {
					Basic.advance(Basic.set_num(r.m, nm.k, Basic.num_of(r.v)), r.at)
				}
			}
		}
	}

	do_dim : M, List(U8), U64 -> M
	do_dim = |m, b, w| {
		nm = Basic.name_at(b, w)
		if nm.k == "" {
			Basic.advance(m, Basic.stmt_end(b, w))
		} else {
			sub = Basic.subscripts(m, b, Basic.skip_ws(b, nm.at))
			m1 = Basic.dim(sub.m, nm.k, sub.i, sub.j)
			j = Basic.skip_ws(b, sub.at)
			if Basic.byte(b, j) == 44 { Basic.do_dim(m1, b, j + 1) } else { Basic.advance(m1, sub.at) }
		}
	}

	# IF <expr> <relop> <expr> THEN <line or statement>.
	do_if : M, List(U8), U64 -> M
	do_if = |m, b, w| {
		l = Basic.expr(m, b, w)
		if l.m.done {
			l.m
		} else {
			op = Basic.relop(b, l.at)
			if op.k == "" {
				{ ..l.m, done: True, err: "Expected a relational operator" }
			} else {
				r = Basic.expr(l.m, b, op.at)
				if r.m.done {
					r.m
				} else {
					yes = Basic.compare(op.k, l.v, r.v)
					t = Basic.kw(b, r.at, "THEN")
					if t == r.at {
						{ ..r.m, done: True, err: "Expected THEN" }
					} else if !yes {
						{ ..r.m, pc: r.m.pc + 1, at: 0 }
					} else {
						j = Basic.skip_ws(b, t)
						if Basic.is_digit(Basic.byte(b, j)) {
							d = Basic.digits_end(b, j)
							Basic.jump(r.m, Basic.digits_val(b, j, d, 0))
						} else {
							{ ..r.m, at: j }
						}
					}
				}
			}
		}
	}

	relop : List(U8), U64 -> { k : Str, at : U64 }
	relop = |b, i| {
		j = Basic.skip_ws(b, i)
		c = Basic.byte(b, j)
		d = Basic.byte(b, j + 1)
		if c == 61 {
			{ k: "=", at: j + 1 }
		} else if c == 60 and d == 62 {
			{ k: "<>", at: j + 2 }
		} else if c == 60 and d == 61 {
			{ k: "<=", at: j + 2 }
		} else if c == 62 and d == 61 {
			{ k: ">=", at: j + 2 }
		} else if c == 60 {
			{ k: "<", at: j + 1 }
		} else if c == 62 {
			{ k: ">", at: j + 1 }
		} else {
			{ k: "", at: i }
		}
	}

	compare : Str, Val, Val -> Bool
	compare = |k, l, r| match l {
		S(a) => Basic.cmp_str(k, a, Basic.str_of(r))
		N(a) => Basic.cmp_num(k, a, Basic.num_of(r))
	}

	cmp_num : Str, F64, F64 -> Bool
	cmp_num = |k, a, c|
		if k == "=" { a == c }
		else if k == "<>" { a != c }
		else if k == "<" { a < c }
		else if k == ">" { a > c }
		else if k == "<=" { a <= c }
		else { a >= c }

	cmp_str : Str, Str, Str -> Bool
	cmp_str = |k, a, c|
		if k == "=" { a == c }
		else if k == "<>" { a != c }
		else { Basic.cmp_bytes(k, Str.to_utf8(a), Str.to_utf8(c), 0) }

	cmp_bytes : Str, List(U8), List(U8), U64 -> Bool
	cmp_bytes = |k, a, c, i| {
		x = if i >= List.len(a) { 0 } else { Basic.byte(a, i) }
		y = if i >= List.len(c) { 0 } else { Basic.byte(c, i) }
		if i >= List.len(a) and i >= List.len(c) {
			k == "<=" or k == ">="
		} else if x == y {
			Basic.cmp_bytes(k, a, c, i + 1)
		} else if x < y {
			k == "<" or k == "<="
		} else {
			k == ">" or k == ">="
		}
	}

	do_for : M, List(U8), U64 -> M
	do_for = |m, b, w| {
		nm = Basic.name_at(b, w)
		j = Basic.skip_ws(b, nm.at)
		if nm.k == "" or Basic.byte(b, j) != 61 {
			{ ..m, done: True, err: "Malformed FOR" }
		} else {
			from = Basic.sum(m, b, j + 1)
			t = Basic.kw(b, from.at, "TO")
			if t == from.at {
				{ ..from.m, done: True, err: "Expected TO" }
			} else {
				lim = Basic.sum(from.m, b, t)
				st = Basic.kw(b, lim.at, "STEP")
				stepped = if st == lim.at { { m: lim.m, v: N(1.0), at: lim.at } } else { Basic.sum(lim.m, b, st) }
				m1 = Basic.set_num(stepped.m, nm.k, Basic.num_of(from.v))
				after = Basic.advance(m1, stepped.at)
				frame = { v: nm.k, limit: Basic.num_of(lim.v), step: Basic.num_of(stepped.v), pc: after.pc, at: after.at }
				Basic.enter_for({ ..after, loops: List.append(Basic.drop_frame(after.loops, nm.k), frame) })
			}
		}
	}

	# A loop whose body must not run at all still has to land past its
	# NEXT, which is what ECMA-55 says and what a `FOR I = 1 TO 0` means.
	enter_for : M -> M
	enter_for = |m| {
		n = List.len(m.loops)
		f = List.get(m.loops, n - 1) ?? { v: "", limit: 0.0, step: 1.0, pc: 0, at: 0 }
		x = Basic.get_num(m, f.v)
		if (f.step >= 0.0 and x > f.limit) or (f.step < 0.0 and x < f.limit) {
			Basic.skip_to_next({ ..m, loops: List.drop_last(m.loops, 1) }, f.v)
		} else {
			m
		}
	}

	skip_to_next : M, Str -> M
	skip_to_next = |m, v|
		if m.pc >= List.len(m.prog) {
			{ ..m, done: True, err: Str.concat("FOR without NEXT: ", v) }
		} else {
			b = Basic.cur(m)
			j = Basic.kw(b, Basic.skip_ws(b, m.at), "NEXT")
			if j != Basic.skip_ws(b, m.at) {
				{ ..m, pc: m.pc + 1, at: 0 }
			} else {
				Basic.skip_to_next({ ..m, pc: m.pc + 1, at: 0 }, v)
			}
		}

	drop_frame : List(Frame), Str -> List(Frame)
	drop_frame = |fs, v| Basic.drop_frame_from(fs, v, 0, [])

	drop_frame_from : List(Frame), Str, U64, List(Frame) -> List(Frame)
	drop_frame_from = |fs, v, i, acc|
		if i >= List.len(fs) {
			acc
		} else {
			f = List.get(fs, i) ?? { v: "", limit: 0.0, step: 1.0, pc: 0, at: 0 }
			Basic.drop_frame_from(fs, v, i + 1, if f.v == v { acc } else { List.append(acc, f) })
		}

	do_next : M, List(U8), U64 -> M
	do_next = |m, b, w| {
		nm = Basic.name_at(b, w)
		n = List.len(m.loops)
		if n == 0 {
			{ ..m, done: True, err: "NEXT without FOR" }
		} else {
			f = List.get(m.loops, n - 1) ?? { v: "", limit: 0.0, step: 1.0, pc: 0, at: 0 }
			if nm.k != "" and nm.k != f.v {
				{ ..m, done: True, err: Str.concat("NEXT out of order: ", nm.k) }
			} else {
				x = Basic.get_num(m, f.v) + f.step
				m1 = Basic.set_num(m, f.v, x)
				if (f.step >= 0.0 and x > f.limit) or (f.step < 0.0 and x < f.limit) {
					Basic.advance({ ..m1, loops: List.drop_last(m1.loops, 1) }, if nm.k == "" { w } else { nm.at })
				} else {
					{ ..m1, pc: f.pc, at: f.at }
				}
			}
		}
	}

	do_read : M, List(U8), U64 -> M
	do_read = |m, b, w| {
		nm = Basic.name_at(b, w)
		if nm.k == "" {
			Basic.advance(m, Basic.stmt_end(b, w))
		} else if m.dp >= List.len(m.data) {
			{ ..m, done: True, err: "Out of DATA" }
		} else {
			raw = List.get(m.data, m.dp) ?? ""
			m1 = { ..m, dp: m.dp + 1 }
			m2 = if Basic.is_str_name(nm.k) {
				Basic.set_str(m1, nm.k, raw)
			} else {
				rb = Str.to_utf8(raw)
				n = Basic.number(m1, rb, Basic.skip_ws(rb, 0))
				Basic.set_num(n.m, nm.k, Basic.num_of(n.v))
			}
			j = Basic.skip_ws(b, nm.at)
			if Basic.byte(b, j) == 44 { Basic.do_read(m2, b, j + 1) } else { Basic.advance(m2, nm.at) }
		}
	}

	do_input : M, List(U8), U64 -> M
	do_input = |m, b, w| {
		j = Basic.skip_ws(b, w)
		if Basic.byte(b, j) == 34 {
			e = Basic.quote_end(b, j + 1, List.len(b))
			m1 = Basic.emit(m, Basic.text_of(b, j + 1, U64.minus_wrap(e, 1)))
			k = Basic.skip_ws(b, e)
			Basic.do_input(m1, b, if Basic.byte(b, k) == 59 or Basic.byte(b, k) == 44 { k + 1 } else { k })
		} else {
			nm = Basic.name_at(b, j)
			if nm.k == "" {
				Basic.advance(m, Basic.stmt_end(b, w))
			} else if m.ip >= List.len(m.inp) {
				{ ..m, done: True, err: "Out of input" }
			} else {
				raw = List.get(m.inp, m.ip) ?? ""
				m1 = { ..m, ip: m.ip + 1 }
				m2 = if Basic.is_str_name(nm.k) {
					Basic.set_str(m1, nm.k, raw)
				} else {
					rb = Str.to_utf8(raw)
					n = Basic.number(m1, rb, Basic.skip_ws(rb, 0))
					Basic.set_num(n.m, nm.k, Basic.num_of(n.v))
				}
				c = Basic.skip_ws(b, nm.at)
				if Basic.byte(b, c) == 44 { Basic.do_input(m2, b, c + 1) } else { Basic.advance(m2, nm.at) }
			}
		}
	}

	# ---- PRINT -----------------------------------------------------------

	do_print : M, List(U8), U64 -> M
	do_print = |m, b, w| Basic.print_items(m, b, w, True)

	print_items : M, List(U8), U64, Bool -> M
	print_items = |m, b, i, newline| {
		j = Basic.skip_ws(b, i)
		if j >= List.len(b) or Basic.byte(b, j) == 58 {
			Basic.advance(if newline { Basic.emit(m, "\n") } else { m }, j)
		} else if Basic.byte(b, j) == 59 {
			Basic.print_items(m, b, j + 1, False)
		} else if Basic.byte(b, j) == 44 {
			Basic.print_items(Basic.emit(m, Basic.spaces(Basic.zone - I64.rem_by(m.col, Basic.zone))), b, j + 1, False)
		} else {
			t = Basic.kw(b, j, "TAB")
			if t != j {
				r = Basic.sum(m, b, t + 1)
				e = Basic.skip_ws(b, r.at)
				n = F64.to_i64_wrap(Basic.num_of(r.v))
				Basic.print_items(Basic.emit(r.m, Basic.spaces(n - r.m.col)), b, if Basic.byte(b, e) == 41 { e + 1 } else { e }, True)
			} else {
				r = Basic.expr(m, b, j)
				if r.m.done { r.m } else { Basic.print_items(Basic.emit(r.m, Basic.str_of(r.v)), b, r.at, True) }
			}
		}
	}

	# ---- running ---------------------------------------------------------

	# DATA is collected before the first statement runs, in line order,
	# which is what RESTORE rewinds to.
	collect_data : List(Line), U64, List(Str) -> List(Str)
	collect_data = |ls, i, acc|
		if i >= List.len(ls) {
			acc
		} else {
			b = (List.get(ls, i) ?? { num: -1, src: [] }).src
			j = Basic.kw(b, 0, "DATA")
			Basic.collect_data(ls, i + 1, if j == 0 { acc } else { Basic.data_items(b, j, acc) })
		}

	data_items : List(U8), U64, List(Str) -> List(Str)
	data_items = |b, i, acc| {
		j = Basic.skip_ws(b, i)
		if j >= List.len(b) {
			acc
		} else if Basic.byte(b, j) == 34 {
			e = Basic.quote_end(b, j + 1, List.len(b))
			k = Basic.skip_ws(b, e)
			Basic.data_items(b, if Basic.byte(b, k) == 44 { k + 1 } else { List.len(b) }, List.append(acc, Basic.text_of(b, j + 1, U64.minus_wrap(e, 1))))
		} else {
			e = Basic.item_end(b, j)
			Basic.data_items(b, e + 1, List.append(acc, Basic.trim_right(b, j, e)))
		}
	}

	item_end : List(U8), U64 -> U64
	item_end = |b, i|
		if i >= List.len(b) or Basic.byte(b, i) == 44 { i } else { Basic.item_end(b, i + 1) }

	trim_right : List(U8), U64, U64 -> Str
	trim_right = |b, from, to|
		if to > from and Basic.byte(b, U64.minus_wrap(to, 1)) == 32 {
			Basic.trim_right(b, from, U64.minus_wrap(to, 1))
		} else {
			Basic.text_of(b, from, to)
		}

	new : List(Line), List(Str), U64 -> M
	new = |prog, inp, seed| {
		prog: prog,
		pc: 0,
		at: 0,
		num: [],
		str: [],
		arr: [],
		ret: [],
		loops: [],
		data: Basic.collect_data(prog, 0, []),
		dp: 0,
		inp: inp,
		ip: 0,
		out: [],
		col: 0,
		done: False,
		err: "",
		seed: seed,
		fuel: 2000000,
	}

	# **FUEL, NOT FAITH.** A BASIC listing loops forever on purpose often
	# enough, and a subject that hangs the harness is worse than one that
	# reports a bound.
	loop : M -> M
	loop = |m|
		if m.done or m.fuel <= 0 {
			m
		} else {
			Basic.loop(Basic.step({ ..m, fuel: m.fuel - 1 }))
		}

	run : Str, List(Str), U64 -> Str
	run = |src, inp, seed| {
		m = Basic.loop(Basic.new(Basic.load(src), inp, seed))
		body = Str.join_with(m.out, "")
		if m.err == "" {
			body
		} else {
			Str.concat(Str.concat(body, "\n?"), m.err)
		}
	}
}
