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

import Listing
import Program

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
		# **AN EXCEPTION IS NOT A GAP.** ECMA-55 defines exceptions that
		# stop a program, and seven of the NBS tests exist to check that a
		# subscript out of range DOES stop it -- so halting there is the
		# program behaving correctly. A form this interpreter has not
		# built is a different thing, and counting the two together would
		# let every unbuilt form read as a pass.
		gap : Bool,
		# **A SUSPENDED MACHINE.** An INPUT with nothing left to read does
		# not fail: it stops, having printed its prompt, and `resume` hands
		# it a line and carries on. `asked` is how it knows, on the way
		# back in, that the prompt is already on the screen -- the
		# statement re-executes from its start, which keeps `step` a
		# dispatch on a keyword and nothing more.
		waiting : Bool,
		asked : Bool,
		# **SLEEP SUSPENDS THE SAME WAY INPUT DOES.** A program that draws
		# a frame and then sleeps is a program the page can animate: it
		# hands back a machine, the page paints and waits, and resumes.
		# Milliseconds, and zero means the machine is not sleeping.
		pause : I64,
		# **AN INFINITE LOOP IS A FEATURE.** `10 PRINT ...` / `20 GOTO 10`
		# is the canonical BASIC one-liner and it never ends on purpose.
		# So running out of fuel is a YIELD, not a death: the machine hands
		# itself back with what it has drawn so far and the page decides
		# whether to carry on. `steps` is the count across every resume,
		# which is the honest measure of how long a program has run.
		steps : I64,
		seed : U64,
		fuel : I64,
		# The fuel one resume gets. The batch door runs a tankful at a time;
		# the page hands the tab back far more often.
		tank : I64,
		# **A LIVE MACHINE PRINTS LIKE A TERMINAL.** On the page every PRINT
		# ends in a millisecond's sleep, so the machine hands itself back a
		# line at a time and the page paints each one as it comes.
		live : Bool,
		# OPTION BASE: the lowest subscript an array has. ECMA-55 allows
		# 0 or 1 and one OPTION statement, before any DIM.
		base : U64,
		# **TWO DIALECTS.** ECMA-55 is what the NBS suite grades; the 1978
		# listings and the captures beside them are a microcomputer BASIC,
		# and the two disagree where the microcomputers did not follow the
		# standard: TAB(30) is column 30 in ECMA-55 and thirty spaces in
		# the captures. True is ECMA-55.
		ecma : Bool,
		# A listing ECMA-55 refuses before its first statement (Listing).
		rejected : Bool,
		# **THE ADDRESS SPACE.** ECMA-55 has no PEEK and no POKE -- it is a
		# teletype language and its only output is PRINT. Every
		# microcomputer BASIC added them, and on a Commodore the screen IS
		# memory: 40x25 screen codes at 1024, colour at 55296. So a
		# program draws by writing bytes, and the page reads those bytes
		# back out. Sixteen pages of 4 KB is the 64 KB such a machine had.
		mem : List(List(U8)),
		# **THE SCREEN IS A FLAT THOUSAND BYTES, AND STILL MEMORY.**
		# Addresses 1024..2023 and 55296..56295 route here rather than
		# into the page table: PRINT draws a character at a time, so the
		# hot path has to be one List.set on a short list rather than five
		# levels of trie. PEEK and POKE see exactly these bytes, which is
		# what makes `POKE 1024+P, 81` and `PRINT "X"` the same display.
		scr : List(U8),
		col_ram : List(U8),
		# Where PRINT writes next. A C64 screen is forty wide and
		# twenty-five tall, and the twenty-sixth line scrolls the rest up.
		crow : I64,
		ccol : I64,
		# **A LINEAR FRAMEBUFFER, WHICH NO REAL MACHINE HAD.** 40x25 is a
		# Commodore's constraint, not the standard's -- ECMA-55 has no
		# screen at all -- so this one is 320x200 at one byte a pixel from
		# 16384, laid out the obvious way: the pixel at (x, y) is at
		# 16384 + y*320 + x. A C64's bitmap is interleaved by character
		# cell and a listing has to compute its way in; this one is a POKE
		# and nothing else. Flat, for the same reason the text screen is.
		pix : List(U8),
		drew : Bool,
		# DEF FNx(v) = expr, kept as the parameter's name and the bytes of
		# the body, so calling one is just evaluating that expression with
		# the parameter bound.
		fns : List({ k : Str, p : Str, body : List(U8) }),
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

	# An array not named by DIM has subscripts from the OPTION BASE
	# through 10, which is what ECMA-55 says and what every listing
	# assumes. `hi` is the declared upper bound; cells are indexed from
	# the base.
	arr_index : List({ k : Str, w : U64, cells : List(F64) }), Str, U64 -> I64
	arr_index = |xs, k, i|
		if i >= List.len(xs) {
			-1
		} else if (List.get(xs, i) ?? { k: "", w: 0, cells: [] }).k == k {
			U64.to_i64_wrap(i)
		} else {
			Basic.arr_index(xs, k, i + 1)
		}

	dim : M, Str, I64, I64 -> M
	dim = |m, k, d1, d2| {
		base = U64.to_i64_wrap(m.base)
		rows = d1 - base + 1
		cols = d2 - base + 1
		w = if d2 < 0 { 0 } else { I64.to_u64_wrap(cols) }
		n = if d2 < 0 { rows } else { rows * cols }
		if rows <= 0 or (d2 >= 0 and cols <= 0) or n <= 0 {
			{ ..m, done: True, err: Str.concat("Bad DIM bound: ", k), gap: False}
		} else {
			# **A DIM IS A DECLARATION** (ECMA-55 15): control may pass through
			# one again, in a loop or a subroutine, and the array keeps its
			# values. A second DIM for the same array is rejected at load.
			if Basic.arr_index(m.arr, k, 0) >= 0 {
				m
			} else {
				{ ..m, arr: List.append(m.arr, { k: k, w: w, cells: List.repeat(0.0, I64.to_u64_wrap(n)) }) }
			}
		}
	}

	# ECMA-55: an array with no DIM has a bound of 10 in each dimension its
	# first use gives it.
	ensure_arr : M, Str, Bool -> M
	ensure_arr = |m, k, two| if Basic.arr_index(m.arr, k, 0) < 0 { Basic.dim(m, k, 10, if two { 10 } else { -1 }) } else { m }

	# Where a subscript pair lands, or -1 when it is outside the array.
	cell_at : M, Str, I64, I64 -> I64
	cell_at = |m, k, i, j| {
		a = List.get(m.arr, I64.to_u64_wrap(Basic.arr_index(m.arr, k, 0))) ?? { k: "", w: 0, cells: [] }
		base = U64.to_i64_wrap(m.base)
		r = i - base
		c = j - base
		if r < 0 or c < 0 {
			-1
		} else if a.w == 0 {
			if j != base and j != 0 { -1 } else { r }
		} else {
			if c >= U64.to_i64_wrap(a.w) { -1 } else { r * U64.to_i64_wrap(a.w) + c }
		}
	}

	get_arr : M, Str, I64, I64 -> { m : M, v : F64 }
	get_arr = |m, k, i, j| {
		a = List.get(m.arr, I64.to_u64_wrap(Basic.arr_index(m.arr, k, 0))) ?? { k: "", w: 0, cells: [] }
		c = Basic.cell_at(m, k, i, j)
		if c < 0 or I64.to_u64_wrap(c) >= List.len(a.cells) {
			{ m: { ..m, done: True, err: Str.concat("Subscript out of range: ", k), gap: False}, v: 0.0 }
		} else {
			{ m: m, v: List.get(a.cells, I64.to_u64_wrap(c)) ?? 0.0 }
		}
	}

	set_arr : M, Str, I64, I64, F64 -> M
	set_arr = |m, k, i, j, v| {
		at = I64.to_u64_wrap(Basic.arr_index(m.arr, k, 0))
		c = Basic.cell_at(m, k, i, j)
		a = List.get(m.arr, at) ?? { k: "", w: 0, cells: [] }
		if c < 0 or I64.to_u64_wrap(c) >= List.len(a.cells) {
			{ ..m, done: True, err: Str.concat("Subscript out of range: ", k), gap: False}
		} else {
			{ ..m, arr: List.set(m.arr, at, { k: a.k, w: a.w, cells: List.set(a.cells, I64.to_u64_wrap(c), v) ?? crash("set_arr") }) ?? crash("set_arr") }
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

	# The largest number this BASIC has, which a reported exception
	# continues with (ECMA-55 12.4).
	huge : F64
	huge = 1.7976931348623157e308

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

	# **ECMA-55 PRINTS SIX SIGNIFICANT DIGITS**, an integer with no point,
	# and a value below one with no leading zero: one third is `.333333`,
	# not `0.3333333333333333`. Outside the fixed-point range it is one
	# digit, a point, the rest, and an exponent.
	sig : I64
	sig = 6

	fmt_mag : F64 -> Str
	fmt_mag = |a|
		if a == 0.0 {
			"0"
		} else if !(a <= Basic.huge) {
			# Normalising an infinity or a NaN by tens never ends, and Roc
			# evaluates a literal program at compile time with no step
			# limit, so this shows instead of hanging the build.
			"INF"
		} else if a == Basic.floor(a) and a < 1000000000.0 {
			I64.to_str(F64.to_i64_wrap(a))
		} else {
			n = Basic.normal(a, 0)
			d = Basic.round_to(n.m * 100000.0)
			r = if d >= 1000000 { { d: 100000, e: n.e + 1 } } else { { d: d, e: n.e } }
			Basic.lay_out(I64.to_str(r.d), r.e)
		}

	normal : F64, I64 -> { m : F64, e : I64 }
	normal = |a, e|
		if a >= 10.0 {
			Basic.normal(a / 10.0, e + 1)
		} else if a < 1.0 {
			Basic.normal(a * 10.0, e - 1)
		} else {
			{ m: a, e: e }
		}

	round_to : F64 -> I64
	round_to = |x| F64.to_i64_wrap(Basic.floor(x + 0.5))

	# `ds` is exactly `sig` digits and `e` is the power of ten the first
	# of them stands for.
	lay_out : Str, I64 -> Str
	lay_out = |ds, e|
		if e >= 0 and e < Basic.sig {
			whole = Basic.take(ds, I64.to_u64_wrap(e + 1))
			frac = Basic.no_zeros(Basic.drop(ds, I64.to_u64_wrap(e + 1)))
			if frac == "" { whole } else { Str.concat(Str.concat(whole, "."), frac) }
		} else if e == -1 {
			Str.concat(".", Basic.no_zeros(ds))
		} else {
			frac = Basic.no_zeros(Basic.drop(ds, 1))
			mant = if frac == "" { Basic.take(ds, 1) } else { Str.concat(Str.concat(Basic.take(ds, 1), "."), frac) }
			Str.concat(Str.concat(mant, if e < 0 { "E-" } else { "E+" }), I64.to_str(I64.abs(e)))
		}

	take : Str, U64 -> Str
	take = |t, n| Str.from_utf8(List.sublist(Str.to_utf8(t), { start: 0, len: n })) ?? ""

	drop : Str, U64 -> Str
	drop = |t, n| {
		b = Str.to_utf8(t)
		if n >= List.len(b) { "" } else { Str.from_utf8(List.sublist(b, { start: n, len: List.len(b) - n })) ?? "" }
	}

	no_zeros : Str -> Str
	no_zeros = |t| {
		b = Str.to_utf8(t)
		if List.len(b) > 0 and Basic.byte(b, U64.minus_wrap(List.len(b), 1)) == 48 {
			Basic.no_zeros(Basic.take(t, U64.minus_wrap(List.len(b), 1)))
		} else {
			t
		}
	}

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

	# Every reason `fail` is reached is a form the expression grammar does
	# not know, which is this interpreter's gap and not the program's.
	fail : M, Str, U64 -> R
	fail = |m, why, at| { m: { ..m, done: True, err: why, gap: True }, v: N(0.0), at: at }

	# A FATAL EXCEPTION is the program's, not the interpreter's: ECMA-55
	# stops on it, and the suite checks that it does.
	halt : M, Str, U64 -> R
	halt = |m, why, at| { m: { ..m, done: True, err: why, gap: False }, v: N(0.0), at: at }

	# ECMA-55 7.4: an overflow is reported and the program continues with
	# the largest number of the right sign. An infinity is never a value.
	finite : M, F64, U64 -> R
	finite = |m, x, at|
		if x > Basic.huge {
			{ m: Basic.emit(m, "\n?Overflow\n"), v: N(Basic.huge), at: at }
		} else if x < 0.0 - Basic.huge {
			{ m: Basic.emit(m, "\n?Overflow\n"), v: N(0.0 - Basic.huge), at: at }
		} else {
			{ m: m, v: N(x), at: at }
		}

	# ECMA-55 7.5: a negative number to a non-integral power stops the
	# program; zero to a negative power is reported and continues with the
	# largest number. Above 2^52 every F64 is an integer, and `floor`
	# truncates through I64, so it is not asked there.
	raise : M, F64, F64, U64 -> R
	raise = |m, x, y, at|
		if x < 0.0 and F64.abs(y) < 4503599627370496.0 and y != Basic.floor(y) {
			Basic.halt(m, "Negative number raised to a non-integral power", at)
		} else if x == 0.0 and y < 0.0 {
			{ m: Basic.emit(m, "\n?Zero raised to a negative power\n"), v: N(Basic.huge), at: at }
		} else {
			Basic.finite(m, F64.pow(x, y), at)
		}

	# **THE STRING PATH IS DECIDED FIRST.** A string literal, a `$`
	# variable and a `$` function all answer text, and everything else
	# goes down the numeric grammar. Taking the numeric path with a string
	# in hand silently reads it as zero, which is the failure this shape
	# exists to prevent.
	expr : M, List(U8), U64 -> R
	expr = |m, b, i| {
		j = Basic.skip_ws(b, i)
		if Basic.byte(b, j) == 34 {
			e = Basic.quote_end(b, j + 1, List.len(b))
			Basic.str_sum(m, b, e, Basic.text_of(b, j + 1, U64.minus_wrap(e, 1)))
		} else {
			w = Basic.word_end(b, j)
			k = Basic.text_of(b, j, w)
			if Basic.is_str_fn(k) and Basic.byte(b, w) == 36 {
				r = Basic.call_str_fn(m, b, w + 1, k)
				if r.m.done { r } else { Basic.str_sum(r.m, b, r.at, Basic.str_of(r.v)) }
			} else {
				nm = Basic.name_at(b, j)
				if nm.k != "" and Basic.is_str_name(nm.k) {
					Basic.str_sum(m, b, nm.at, Basic.get_str(m, nm.k))
				} else {
					Basic.sum(m, b, j)
				}
			}
		}
	}

	sum : M, List(U8), U64 -> R
	sum = |m, b, i| {
		r = Basic.term(m, b, i)
		if r.m.done { r } else { Basic.sum_rest(r.m, b, r.at, Basic.num_of(r.v)) }
	}

	# **`+` JOINS TWO STRINGS.** ECMA-55 has no string operator at all; the
	# listings all assume the microcomputer one.
	str_sum : M, List(U8), U64, Str -> R
	str_sum = |m, b, i, acc| {
		j = Basic.skip_ws(b, i)
		if Basic.byte(b, j) != 43 {
			{ m: m, v: S(acc), at: i }
		} else {
			r = Basic.expr(m, b, j + 1)
			if r.m.done { r } else { { m: r.m, v: S(Str.concat(acc, Basic.str_of(r.v))), at: r.at } }
		}
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
				s = Basic.finite(r.m, if c == 43 { acc + Basic.num_of(r.v) } else { acc - Basic.num_of(r.v) }, r.at)
				Basic.sum_rest(s.m, b, s.at, Basic.num_of(s.v))
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
					# ECMA-55 12.4: a division by zero is reported and the
					# program continues with the largest number, so a test
					# for it can go on to test the next thing.
					big = if acc < 0.0 { 0.0 - Basic.huge } else { Basic.huge }
					Basic.term_rest(Basic.emit(r.m, "\n?Division by zero\n"), b, r.at, big)
				} else {
					p = Basic.finite(r.m, if c == 42 { acc * d } else { acc / d }, r.at)
					Basic.term_rest(p.m, b, p.at, Basic.num_of(p.v))
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
				if e.m.done { e } else { Basic.raise(e.m, Basic.num_of(r.v), Basic.num_of(e.v), e.at) }
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
			if r.m.done { r } else if Basic.byte(b, k) != 41 { Basic.fail(r.m, "Expected )", k) } else { { m: r.m, v: r.v, at: k + 1 } }
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
			# `0E99999` is zero, not zero times infinity.
			Basic.finite(m, if f.v == 0.0 { 0.0 } else { f.v * e }, x.at)
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
		if Basic.is_str_fn(k) and Basic.byte(b, w) == 36 {
			Basic.call_str_fn(m, b, w + 1, k)
		} else if Basic.is_fn(k) {
			Basic.call_fn(m, b, w, k)
		} else if Basic.kw(Str.to_utf8(k), 0, "FN") == 2 and List.len(Str.to_utf8(k)) == 3 {
			Basic.call_def(m, b, w, k)
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
						m1 = Basic.ensure_arr(s.m, nm.k, s.two)
						g = Basic.get_arr(m1, nm.k, s.i, s.j)
						{ m: g.m, v: N(g.v), at: s.at }
					}
				}
			}
		}
	}

	word_end : List(U8), U64 -> U64
	word_end = |b, i| if Basic.is_alpha(Basic.byte(b, i)) { Basic.word_end(b, i + 1) } else { i }

	is_fn : Str -> Bool
	is_fn = |k| k == "ABS" or k == "ATN" or k == "COS" or k == "EXP" or k == "INT" or k == "LOG" or k == "RND" or k == "SGN" or k == "SIN" or k == "SQR" or k == "TAN" or k == "PEEK" or k == "LEN" or k == "ASC" or k == "VAL"

	# The functions that answer a string. Not ECMA-55; the 1978 listings
	# are full of them.
	is_str_fn : Str -> Bool
	is_str_fn = |k| k == "CHR" or k == "STR" or k == "LEFT" or k == "RIGHT" or k == "MID"

	call_fn : M, List(U8), U64, Str -> R
	call_fn = |m, b, i, k| {
		j = Basic.skip_ws(b, i)
		if Basic.byte(b, j) != 40 {
			if k == "RND" { Basic.rnd(m, j) } else { Basic.fail(m, Str.concat("Expected ( after ", k), j) }
		} else {
			# LEN, ASC and VAL take a STRING, so their argument goes down
			# the string path; everything else is numeric.
			r = if k == "LEN" or k == "ASC" or k == "VAL" { Basic.expr(m, b, j + 1) } else { Basic.sum(m, b, j + 1) }
			e = Basic.skip_ws(b, r.at)
			if r.m.done {
				r
			} else if Basic.byte(b, e) != 41 {
				Basic.fail(r.m, "Expected )", e)
			} else if k == "RND" {
				Basic.rnd(r.m, e + 1)
			} else if k == "PEEK" {
				{ m: r.m, v: N(I64.to_f64(U8.to_i64(Basic.peek(r.m, Basic.addr_of(Basic.num_of(r.v)))))), at: e + 1 }
			} else if k == "LEN" {
				{ m: r.m, v: N(I64.to_f64(U64.to_i64_wrap(List.len(Str.to_utf8(Basic.str_of(r.v)))))), at: e + 1 }
			} else if k == "ASC" {
				{ m: r.m, v: N(I64.to_f64(U8.to_i64(Basic.byte(Str.to_utf8(Basic.str_of(r.v)), 0)))), at: e + 1 }
			} else if k == "VAL" {
				vb = Str.to_utf8(Basic.str_of(r.v))
				n = Basic.number(r.m, vb, Basic.skip_ws(vb, 0))
				{ m: n.m, v: n.v, at: e + 1 }
			} else if k == "LOG" and Basic.num_of(r.v) <= 0.0 {
				Basic.halt(r.m, "LOG of a number that is not positive", e + 1)
			} else if k == "SQR" and Basic.num_of(r.v) < 0.0 {
				Basic.halt(r.m, "SQR of a negative number", e + 1)
			} else {
				Basic.finite(r.m, Basic.apply_fn(k, Basic.num_of(r.v)), e + 1)
			}
		}
	}

	call_str_fn : M, List(U8), U64, Str -> R
	call_str_fn = |m, b, i, k| {
		j = Basic.skip_ws(b, i)
		if Basic.byte(b, j) != 40 {
			Basic.fail(m, Str.concat("Expected ( after ", k), j)
		} else {
			a = Basic.expr(m, b, j + 1)
			if a.m.done {
				a
			} else {
				c = Basic.skip_ws(b, a.at)
				if k == "CHR" or k == "STR" {
					if Basic.byte(b, c) != 41 {
						Basic.fail(a.m, "Expected )", c)
					} else if k == "CHR" {
						code = I64.bitwise_and(F64.to_i64_wrap(Basic.floor(Basic.num_of(a.v))), 255)
						{ m: a.m, v: S(Str.from_utf8([U64.to_u8_wrap(I64.to_u64_wrap(code))]) ?? "?"), at: c + 1 }
					} else {
						{ m: a.m, v: S(Basic.fmt_num(Basic.num_of(a.v))), at: c + 1 }
					}
				} else if Basic.byte(b, c) != 44 {
					Basic.fail(a.m, "Expected , ", c)
				} else {
					n1 = Basic.sum(a.m, b, c + 1)
					src = Str.to_utf8(Basic.str_of(a.v))
					len = List.len(src)
					cut = Basic.clamp(Basic.idx(Basic.num_of(n1.v)), len)
					d = Basic.skip_ws(b, n1.at)
					if k == "LEFT" {
						{ m: n1.m, v: S(Basic.slice(src, 0, cut)), at: if Basic.byte(b, d) == 41 { d + 1 } else { d } }
					} else if k == "RIGHT" {
						{ m: n1.m, v: S(Basic.slice(src, len - cut, cut)), at: if Basic.byte(b, d) == 41 { d + 1 } else { d } }
					} else if Basic.byte(b, d) != 44 {
						# MID$(s, from) runs to the end.
						from = if cut == 0 { 0 } else { cut - 1 }
						{ m: n1.m, v: S(Basic.slice(src, from, len - from)), at: if Basic.byte(b, d) == 41 { d + 1 } else { d } }
					} else {
						n2 = Basic.sum(n1.m, b, d + 1)
						e = Basic.skip_ws(b, n2.at)
						from = if cut == 0 { 0 } else { cut - 1 }
						span = Basic.clamp(Basic.idx(Basic.num_of(n2.v)), len - from)
						{ m: n2.m, v: S(Basic.slice(src, from, span)), at: if Basic.byte(b, e) == 41 { e + 1 } else { e } }
					}
				}
			}
		}
	}

	clamp : I64, U64 -> U64
	clamp = |n, hi| if n <= 0 { 0 } else if I64.to_u64_wrap(n) > hi { hi } else { I64.to_u64_wrap(n) }

	slice : List(U8), U64, U64 -> Str
	slice = |b, from, n|
		if from >= List.len(b) or n == 0 {
			""
		} else {
			fit = if from + n > List.len(b) { List.len(b) - from } else { n }
			Str.from_utf8(List.sublist(b, { start: from, len: fit })) ?? ""
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
		else if k == "SQR" { F64.sqrt(x) }
		else { F64.tan(x) }

	# A linear congruential generator, so a run is reproducible and a
	# verdict is a verdict. The constants are Numerical Recipes'.
	rnd : M, U64 -> R
	rnd = |m, at| {
		s = U64.plus_wrap(U64.times_wrap(m.seed, 1664525), 1013904223)
		{ m: { ..m, seed: s }, v: N(I64.to_f64(U64.to_i64_wrap(U64.rem_by(U64.div_trunc_by(s, 65536), 32768))) / 32768.0), at: at }
	}

	# Subscripts: `(i)` or `(i,j)`, each rounded as ECMA-55 says.
	subscripts : M, List(U8), U64 -> { m : M, i : I64, j : I64, at : U64, two : Bool }
	subscripts = |m, b, i| {
		r = Basic.sum(m, b, i + 1)
		if r.m.done {
			{ m: r.m, i: 0, j: 0, at: r.at, two: False }
		} else {
			k = Basic.skip_ws(b, r.at)
			if Basic.byte(b, k) == 44 {
				r2 = Basic.sum(r.m, b, k + 1)
				e = Basic.skip_ws(b, r2.at)
				{ m: r2.m, i: Basic.idx(Basic.num_of(r.v)), j: Basic.idx(Basic.num_of(r2.v)), at: if Basic.byte(b, e) == 41 { e + 1 } else { e }, two: True }
			} else {
				{ m: r.m, i: Basic.idx(Basic.num_of(r.v)), j: U64.to_i64_wrap(r.m.base), at: if Basic.byte(b, k) == 41 { k + 1 } else { k }, two: False }
			}
		}
	}

	# ECMA-55 rounds a subscript to the nearest integer. It does NOT clamp
	# it: a subscript outside the array's bounds is an exception, and the
	# suite has seven programs that check exactly that.
	# A subscript too big for an I64 stays out of range rather than
	# wrapping into it: `Z(9999^9999)` is not `Z(0)`.
	idx : F64 -> I64
	idx = |x|
		if x >= 1.0e12 {
			1000000000000
		} else if x <= -1.0e12 {
			-1000000000000
		} else {
			F64.to_i64_wrap(Basic.floor(x + 0.5))
		}

	# ---- output ---------------------------------------------------------

	# ECMA-55 prints in zones; a comma moves to the next one. The width is
	# what the 1978 listings assume and what the games' captured output
	# shows.
	zone : I64
	zone = 14

	# **PRINT AND POKE SHARE ONE DISPLAY.** A character goes into the
	# transcript and onto the text screen at the cursor, which is what a
	# terminal is: forty columns, twenty-five rows, and the twenty-sixth
	# line scrolls the rest up.
	emit : M, Str -> M
	emit = |m, t| {
		b = Str.to_utf8(t)
		{ ..Basic.draw(m, b, 0), out: Basic.append_out(m.out, t), col: Basic.col_after(b, 0, m.col) }
	}

	# **A PROGRAM THAT PRINTS FOREVER MUST NOT GROW FOREVER.** The maze
	# one-liner runs until it is stopped, so the transcript is a window on
	# the end of it rather than all of it -- which is what a terminal's
	# scrollback is, and the screen shows the live part anyway.
	scrollback : U64
	scrollback = 8000

	# Trimmed when it has grown to twice the window, not on every
	# character: otherwise a program that prints forever pays the whole
	# window's length per character printed, which is 132 microseconds a
	# step where it should be under one.
	append_out : List(Str), Str -> List(Str)
	append_out = |out, t|
		if List.len(out) < Basic.scrollback * 2 {
			List.append(out, t)
		} else {
			List.append(List.sublist(out, { start: Basic.scrollback, len: List.len(out) - Basic.scrollback }), t)
		}

	screen_w : I64
	screen_w = 40

	screen_h : I64
	screen_h = 25

	draw : M, List(U8), U64 -> M
	draw = |m, b, i|
		if i >= List.len(b) {
			m
		} else {
			c = Basic.byte(b, i)
			Basic.draw(if c == 10 { Basic.line_feed(m) } else { Basic.put_char(m, c) }, b, i + 1)
		}

	put_char : M, U8 -> M
	put_char = |m, c| {
		at = I64.to_u64_wrap(m.crow * Basic.screen_w + m.ccol)
		m1 = if at >= Basic.screen_cells {
			m
		} else {
			{ ..m, scr: List.set(m.scr, at, Basic.screen_code(c)) ?? crash("draw: outside the screen") }
		}
		if m1.ccol + 1 >= Basic.screen_w { Basic.line_feed(m1) } else { { ..m1, ccol: m1.ccol + 1 } }
	}

	line_feed : M -> M
	line_feed = |m|
		if m.crow + 1 >= Basic.screen_h {
			{ ..Basic.scroll(m), ccol: 0 }
		} else {
			{ ..m, crow: m.crow + 1, ccol: 0 }
		}

	# Rows one upward, and a blank row at the foot.
	scroll : M -> M
	scroll = |m| {
		keep = I64.to_u64_wrap((Basic.screen_h - 1) * Basic.screen_w)
		{
			..m,
			scr: List.concat(List.sublist(m.scr, { start: I64.to_u64_wrap(Basic.screen_w), len: keep }), List.repeat(32.U8, I64.to_u64_wrap(Basic.screen_w))),
			col_ram: List.concat(List.sublist(m.col_ram, { start: I64.to_u64_wrap(Basic.screen_w), len: keep }), List.repeat(14.U8, I64.to_u64_wrap(Basic.screen_w))),
		}
	}

	# A Commodore screen code from a character. 64..95 are the letters
	# and 32..63 are themselves; lower case shows as upper, since this
	# screen has the upper-case set; 128 and up are the graphics, which
	# is where CHR$(205) -- the one in the maze one-liner -- comes from.
	screen_code : U8 -> U8
	screen_code = |c|
		if c >= 64 and c <= 95 { c - 64 }
		else if c >= 97 and c <= 122 { c - 96 }
		else if c >= 32 and c <= 63 { c }
		else if c >= 128 { c - 128 }
		else { 32 }

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
			{ ..m, done: True, err: Str.concat("No such line: ", I64.to_str(n)), gap: False }
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
		} else if (k == "DIM" or k == "OPTION") and m.ecma {
			Basic.advance(m, Basic.stmt_end(b, w))
		} else if k == "DIM" {
			Basic.do_dim(m, b, w)
		} else if k == "READ" {
			Basic.do_read(m, b, w)
		} else if k == "RESTORE" {
			Basic.advance({ ..m, dp: 0 }, w)
		} else if k == "INPUT" {
			Basic.do_input(m, b, w)
		} else if k == "SLEEP" or k == "PAUSE" {
			Basic.do_sleep(m, b, w)
		} else if k == "PLOT" {
			Basic.do_plot(m, b, w)
		} else if k == "POKE" {
			Basic.do_poke(m, b, w)
		} else if k == "ON" {
			Basic.do_on(m, b, w)
		} else if k == "OPTION" {
			Basic.do_option(m, b, w)
		} else if k == "DEF" {
			Basic.do_def(m, b, w)
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
			{ ..m, done: True, err: "RETURN without GOSUB", gap: False}
		} else {
			{ ..m, pc: List.get(m.ret, n - 1) ?? 0, at: 0, ret: List.drop_last(m.ret, 1) }
		}
	}

	do_let : M, List(U8), U64 -> M
	do_let = |m, b, w| {
		nm = Basic.name_at(b, w)
		if nm.k == "" {
			{ ..m, done: True, err: "Expected a variable", gap: True}
		} else {
			j = Basic.skip_ws(b, nm.at)
			if Basic.byte(b, j) == 40 {
				sub = Basic.subscripts(m, b, j)
				e = Basic.skip_ws(b, sub.at)
				if Basic.byte(b, e) != 61 {
					{ ..sub.m, done: True, err: "Expected =", gap: True}
				} else {
					r = Basic.expr(Basic.ensure_arr(sub.m, nm.k, sub.two), b, e + 1)
					if r.m.done { r.m } else { Basic.advance(Basic.set_arr(r.m, nm.k, sub.i, sub.j, Basic.num_of(r.v)), r.at) }
				}
			} else if Basic.byte(b, j) != 61 {
				{ ..m, done: True, err: "Expected =", gap: True}
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
				{ ..l.m, done: True, err: "Expected a relational operator", gap: True}
			} else {
				r = Basic.expr(l.m, b, op.at)
				if r.m.done {
					r.m
				} else {
					yes = Basic.compare(op.k, l.v, r.v)
					t = Basic.kw(b, r.at, "THEN")
					if t == r.at {
						{ ..r.m, done: True, err: "Expected THEN", gap: True}
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
			{ ..m, done: True, err: "Malformed FOR", gap: True}
		} else {
			from = Basic.sum(m, b, j + 1)
			t = Basic.kw(b, from.at, "TO")
			if from.m.done {
				from.m
			} else if t == from.at {
				{ ..from.m, done: True, err: "Expected TO", gap: True}
			} else {
				lim = Basic.sum(from.m, b, t)
				st = Basic.kw(b, lim.at, "STEP")
				stepped = if st == lim.at { { m: lim.m, v: N(1.0), at: lim.at } } else { Basic.sum(lim.m, b, st) }
				m1 = Basic.set_num(stepped.m, nm.k, Basic.num_of(from.v))
				after = Basic.advance(m1, stepped.at)
				frame = { v: nm.k, limit: Basic.num_of(lim.v), step: Basic.num_of(stepped.v), pc: after.pc, at: after.at }
				Basic.enter_for({ ..after, loops: List.append(Basic.loops_outside(after.loops, after.pc, after.at, 0), frame) })
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

	# **A LOOP BODY MAY CONTAIN LOOPS.** Scanning forward for the word
	# NEXT finds the inner one first, so the scan counts FORs on the way.
	skip_to_next : M, Str -> M
	skip_to_next = |m, v| Basic.skip_scan(m, v, 0)

	skip_scan : M, Str, I64 -> M
	skip_scan = |m, v, depth|
		if m.pc >= List.len(m.prog) {
			{ ..m, done: True, err: Str.concat("FOR without NEXT: ", v), gap: False}
		} else {
			b = Basic.cur(m)
			i = Basic.skip_ws(b, m.at)
			if i >= List.len(b) {
				Basic.skip_scan({ ..m, pc: m.pc + 1, at: 0 }, v, depth)
			} else {
				e = Basic.stmt_end(b, i)
				w = Basic.word_end(b, i)
				k = Basic.text_of(b, i, w)
				at = { ..m, at: if e < List.len(b) { e + 1 } else { e } }
				if k == "FOR" {
					Basic.skip_scan(at, v, depth + 1)
				} else if k != "NEXT" {
					Basic.skip_scan(at, v, depth)
				} else if depth > 0 {
					Basic.skip_scan(at, v, depth - 1)
				} else {
					at
				}
			}
		}

	# **A LOOP IS ITS FOR STATEMENT, NOT ITS VARIABLE.** A subroutine called
	# from a loop may loop on the same variable (the outer loop carries on
	# from the value the inner one left), and a loop left by a jump stays
	# until something closes it. A FOR run again restarts its own loop and
	# abandons the loops entered inside it.
	loops_outside : List(Frame), U64, U64, U64 -> List(Frame)
	loops_outside = |fs, pc, at, i|
		if i >= List.len(fs) {
			fs
		} else {
			f = List.get(fs, i) ?? { v: "", limit: 0.0, step: 1.0, pc: 0, at: 0 }
			if f.pc == pc and f.at == at { List.sublist(fs, { start: 0, len: i }) } else { Basic.loops_outside(fs, pc, at, i + 1) }
		}

	# The innermost loop on `v`, counting down from `i`; -1 when none is open.
	loop_on : List(Frame), Str, I64 -> I64
	loop_on = |fs, v, i|
		if i < 0 {
			-1
		} else if (List.get(fs, I64.to_u64_wrap(i)) ?? { v: "", limit: 0.0, step: 1.0, pc: 0, at: 0 }).v == v {
			i
		} else {
			Basic.loop_on(fs, v, i - 1)
		}

	# NEXT closes the innermost loop on its variable, or the innermost loop
	# when it names none; the loops above that one were left by a jump.
	do_next : M, List(U8), U64 -> M
	do_next = |m, b, w| {
		nm = Basic.name_at(b, w)
		top = U64.to_i64_wrap(List.len(m.loops)) - 1
		found = if nm.k == "" { top } else { Basic.loop_on(m.loops, nm.k, top) }
		if found < 0 {
			{ ..m, done: True, err: "NEXT without FOR", gap: False}
		} else {
			k = I64.to_u64_wrap(found)
			f = List.get(m.loops, k) ?? { v: "", limit: 0.0, step: 1.0, pc: 0, at: 0 }
			x = Basic.get_num(m, f.v) + f.step
			m1 = Basic.set_num(m, f.v, x)
			if (f.step >= 0.0 and x > f.limit) or (f.step < 0.0 and x < f.limit) {
				Basic.advance({ ..m1, loops: List.sublist(m1.loops, { start: 0, len: k }) }, if nm.k == "" { w } else { nm.at })
			} else {
				{ ..m1, loops: List.sublist(m1.loops, { start: 0, len: k + 1 }), pc: f.pc, at: f.at }
			}
		}
	}

	# SLEEP <seconds>, fractions allowed. PAUSE is the same thing, since
	# half the listings spell it that way. The statement is stepped past
	# BEFORE the machine suspends, so waking it carries on rather than
	# sleeping again.
	do_sleep : M, List(U8), U64 -> M
	do_sleep = |m, b, w| {
		r = Basic.sum(m, b, w)
		if r.m.done {
			r.m
		} else {
			ms = F64.to_i64_wrap(Basic.floor(Basic.num_of(r.v) * 1000.0 + 0.5))
			stepped = Basic.advance(r.m, r.at)
			{ ..stepped, pause: if ms < 0 { 0 } else { ms } }
		}
	}

	# PLOT <x>, <y>, <colour>: a pixel in the framebuffer, which is the
	# same POKE with the address worked out. Off the edge is ignored
	# rather than an error, as every plotting BASIC did.
	do_plot : M, List(U8), U64 -> M
	do_plot = |m, b, w| {
		xr = Basic.sum(m, b, w)
		if xr.m.done { return_early(xr.m) } else {
			cx = Basic.skip_ws(b, xr.at)
			if Basic.byte(b, cx) != 44 {
				{ ..xr.m, done: True, err: "Expected , after the PLOT x", gap: True }
			} else {
				yr = Basic.sum(xr.m, b, cx + 1)
				cy = Basic.skip_ws(b, yr.at)
				if Basic.byte(b, cy) != 44 {
					{ ..yr.m, done: True, err: "Expected , after the PLOT y", gap: True }
				} else {
					cr = Basic.sum(yr.m, b, cy + 1)
					x = Basic.idx(Basic.num_of(xr.v))
					y = Basic.idx(Basic.num_of(yr.v))
					c = U64.to_u8_wrap(I64.to_u64_wrap(I64.bitwise_and(F64.to_i64_wrap(Basic.floor(Basic.num_of(cr.v))), 255)))
					inside = x >= 0 and y >= 0 and I64.to_u64_wrap(x) < Basic.hires_w and I64.to_u64_wrap(y) < Basic.hires_h
					m2 = if inside {
						Basic.poke_at(cr.m, Basic.hires_base + I64.to_u64_wrap(y) * Basic.hires_w + I64.to_u64_wrap(x), c)
					} else {
						cr.m
					}
					Basic.advance(m2, cr.at)
				}
			}
		}
	}

	return_early : M -> M
	return_early = |m| m

	# POKE <address>, <value>. Not ECMA-55 -- every microcomputer BASIC had
	# it, and on a Commodore it is how a program draws.
	do_poke : M, List(U8), U64 -> M
	do_poke = |m, b, w| {
		a = Basic.sum(m, b, w)
		if a.m.done {
			a.m
		} else {
			c = Basic.skip_ws(b, a.at)
			if Basic.byte(b, c) != 44 {
				{ ..a.m, done: True, err: "Expected , after the POKE address", gap: True}
			} else {
				v = Basic.sum(a.m, b, c + 1)
				if v.m.done {
					v.m
				} else {
					cell = U64.to_u8_wrap(I64.to_u64_wrap(I64.bitwise_and(F64.to_i64_wrap(Basic.floor(Basic.num_of(v.v))), 255)))
					Basic.advance(Basic.poke_at(v.m, Basic.addr_of(Basic.num_of(a.v)), cell), v.at)
				}
			}
		}
	}

	# ON <expr> GOTO n1,n2,... picks the nth line, counting from one. An
	# index outside the list is an error in ECMA-55 rather than a fall
	# through, and the suite checks that it is reported.
	do_on : M, List(U8), U64 -> M
	do_on = |m, b, w| {
		r = Basic.sum(m, b, w)
		if r.m.done {
			r.m
		} else {
			g = Basic.kw(b, r.at, "GOTO")
			sub = if g == r.at { Basic.kw(b, r.at, "GOSUB") } else { g }
			if sub == r.at {
				{ ..r.m, done: True, err: "Expected GOTO or GOSUB", gap: True}
			} else {
				n = Basic.idx(Basic.num_of(r.v))
				pick = if n < 1 { { n: -1, at: sub } } else { Basic.nth_line(b, sub, I64.to_u64_wrap(n), 1) }
				if pick.n < 0 {
					{ ..r.m, done: True, err: "ON index out of range", gap: False}
				} else if g == r.at {
					back = Basic.advance(r.m, pick.at)
					Basic.jump({ ..back, ret: List.append(back.ret, back.pc) }, pick.n)
				} else {
					Basic.jump(r.m, pick.n)
				}
			}
		}
	}

	nth_line : List(U8), U64, U64, U64 -> { n : I64, at : U64 }
	nth_line = |b, i, want, k| {
		j = Basic.skip_ws(b, i)
		e = Basic.digits_end(b, j)
		if e == j {
			{ n: -1, at: j }
		} else if k == want {
			{ n: Basic.digits_val(b, j, e, 0), at: Basic.line_list_end(b, e) }
		} else {
			c = Basic.skip_ws(b, e)
			if Basic.byte(b, c) != 44 { { n: -1, at: c } } else { Basic.nth_line(b, c + 1, want, k + 1) }
		}
	}

	line_list_end : List(U8), U64 -> U64
	line_list_end = |b, i| {
		c = Basic.skip_ws(b, i)
		if Basic.byte(b, c) != 44 { c } else { Basic.line_list_end(b, Basic.digits_end(b, Basic.skip_ws(b, c + 1))) }
	}

	# OPTION BASE 0 or 1. More than one is an error in ECMA-55 and the
	# suite checks that it is reported.
	do_option : M, List(U8), U64 -> M
	do_option = |m, b, w| {
		j = Basic.kw(b, w, "BASE")
		if j == w {
			{ ..m, done: True, err: "Expected BASE", gap: True}
		} else {
			r = Basic.sum(m, b, j)
			n = Basic.idx(Basic.num_of(r.v))
			if n > 1 or n < 0 {
				{ ..r.m, done: True, err: "OPTION BASE must be 0 or 1", gap: False}
			} else if List.len(r.m.arr) > 0 {
				{ ..r.m, done: True, err: "OPTION BASE after an array is used", gap: False}
			} else {
				Basic.advance({ ..r.m, base: I64.to_u64_wrap(n) }, r.at)
			}
		}
	}

	# DEF FNx(v) = expr. The body is kept as bytes and evaluated at the
	# call, which is what a one-line definition means.
	do_def : M, List(U8), U64 -> M
	do_def = |m, b, w| {
		j = Basic.skip_ws(b, w)
		e = Basic.word_end(b, j)
		k = Basic.text_of(b, j, e)
		q = Basic.skip_ws(b, e)
		if Basic.byte(b, q) == 61 {
			stop = Basic.stmt_end(b, q + 1)
			body = List.sublist(b, { start: q + 1, len: stop - (q + 1) })
			Basic.advance({ ..m, fns: List.append(m.fns, { k: k, p: "", body: body }) }, stop)
		} else if Basic.byte(b, q) != 40 {
			{ ..m, done: True, err: "Expected ( after DEF", gap: True}
		} else {
			pm = Basic.name_at(b, q + 1)
			c = Basic.skip_ws(b, pm.at)
			eq = Basic.skip_ws(b, c + 1)
			if Basic.byte(b, c) != 41 or Basic.byte(b, eq) != 61 {
				{ ..m, done: True, err: "Malformed DEF", gap: True}
			} else {
				stop = Basic.stmt_end(b, eq + 1)
				body = List.sublist(b, { start: eq + 1, len: stop - (eq + 1) })
				Basic.advance({ ..m, fns: List.append(m.fns, { k: k, p: pm.k, body: body }) }, stop)
			}
		}
	}

	fn_index : List({ k : Str, p : Str, body : List(U8) }), Str, U64 -> I64
	fn_index = |fs, k, i|
		if i >= List.len(fs) {
			-1
		} else if (List.get(fs, i) ?? { k: "", p: "", body: [] }).k == k {
			U64.to_i64_wrap(i)
		} else {
			Basic.fn_index(fs, k, i + 1)
		}

	call_def : M, List(U8), U64, Str -> R
	call_def = |m, b, i, k| {
		at = Basic.fn_index(m.fns, k, 0)
		if at < 0 {
			Basic.fail(m, Str.concat("Undefined function: ", k), i)
		} else {
			f = List.get(m.fns, I64.to_u64_wrap(at)) ?? { k: "", p: "", body: [] }
			j = Basic.skip_ws(b, i)
			if f.p == "" {
				inner = Basic.expr(m, f.body, 0)
				{ m: inner.m, v: inner.v, at: if Basic.byte(b, j) == 40 and Basic.byte(b, j + 1) == 41 { j + 2 } else { i } }
			} else if Basic.byte(b, j) != 40 {
				Basic.fail(m, Str.concat("Expected ( after ", k), j)
			} else {
				a = Basic.sum(m, b, j + 1)
				e = Basic.skip_ws(b, a.at)
				if a.m.done {
					a
				} else if Basic.byte(b, e) != 41 {
					Basic.fail(a.m, "Expected )", e)
				} else {
					# The parameter shadows the variable of the same name
					# for the length of the call and is put back after.
					saved = Basic.get_num(a.m, f.p)
					inner = Basic.expr(Basic.set_num(a.m, f.p, Basic.num_of(a.v)), f.body, 0)
					{ m: Basic.set_num(inner.m, f.p, saved), v: inner.v, at: e + 1 }
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
			{ ..m, done: True, err: "Out of DATA", gap: False}
		} else {
			raw = List.get(m.data, m.dp) ?? ""
			s = Basic.store({ ..m, dp: m.dp + 1 }, b, nm, raw)
			j = Basic.skip_ws(b, s.at)
			if s.m.done { s.m } else if Basic.byte(b, j) == 44 { Basic.do_read(s.m, b, j + 1) } else { Basic.advance(s.m, s.at) }
		}
	}

	# **INPUT PRINTS `? ` AND ECHOES THE LINE.** That is what a terminal
	# running BASIC looked like, and it is what the captured game output
	# has in it: the prompt, the typed characters, and a newline. One
	# INPUT statement consumes one line, however many variables it names,
	# and the line is split on commas between them.
	do_input : M, List(U8), U64 -> M
	do_input = |m, b, w| {
		j = Basic.skip_ws(b, w)
		quoted = Basic.byte(b, j) == 34
		e = if quoted { Basic.quote_end(b, j + 1, List.len(b)) } else { j }
		k = Basic.skip_ws(b, e)
		vars = if quoted and (Basic.byte(b, k) == 59 or Basic.byte(b, k) == 44) { k + 1 } else { k }
		# The prompt goes out once, even though a suspended statement runs
		# again from its start when the line arrives.
		m0 = if m.asked {
			m
		} else {
			shown = if quoted { Basic.emit(m, Basic.text_of(b, j + 1, U64.minus_wrap(e, 1))) } else { m }
			{ ..Basic.emit(shown, "? "), asked: True }
		}
		if m0.ip >= List.len(m0.inp) {
			{ ..m0, waiting: True }
		} else {
			line = List.get(m0.inp, m0.ip) ?? ""
			m1 = Basic.emit(Basic.emit(m0, line), "\n")
			Basic.input_vars({ ..m1, ip: m1.ip + 1, asked: False }, b, vars, Basic.split_commas(Str.to_utf8(line), 0, []), 0)
		}
	}

	input_vars : M, List(U8), U64, List(Str), U64 -> M
	input_vars = |m, b, at, vals, k| {
		nm = Basic.name_at(b, at)
		if nm.k == "" {
			Basic.advance(m, Basic.stmt_end(b, at))
		} else {
			raw = List.get(vals, k) ?? ""
			s = Basic.store(m, b, nm, raw)
			c = Basic.skip_ws(b, s.at)
			if s.m.done { s.m } else if Basic.byte(b, c) == 44 { Basic.input_vars(s.m, b, c + 1, vals, k + 1) } else { Basic.advance(s.m, s.at) }
		}
	}

	# **A READ OR INPUT TARGET MAY BE AN ARRAY ELEMENT**, and its subscripts
	# are evaluated when it is reached, after the targets before it have
	# been stored: `INPUT A(I),I,A(I)` stores into the old I, then I, then
	# the new I.
	store : M, List(U8), { k : Str, at : U64 }, Str -> { m : M, at : U64 }
	store = |m, b, nm, raw| {
		j = Basic.skip_ws(b, nm.at)
		if Basic.is_str_name(nm.k) {
			{ m: Basic.set_str(m, nm.k, raw), at: nm.at }
		} else {
			rb = Str.to_utf8(raw)
			n = Basic.number(m, rb, Basic.skip_ws(rb, 0))
			if Basic.byte(b, j) == 40 {
				sub = Basic.subscripts(n.m, b, j)
				if sub.m.done {
					{ m: sub.m, at: sub.at }
				} else {
					# **THE FRESH RECORD IS LOAD-BEARING.** Handed the machine
					# straight from `ensure_arr`, `set_arr` overflows the stack on
					# the nightly, for READ and INPUT alike; handed a copy, it does
					# not. Not yet reduced: findings/store-overflow/.
					ready = Basic.ensure_arr(sub.m, nm.k, sub.two)
					{ m: Basic.set_arr({ ..ready, steps: ready.steps }, nm.k, sub.i, sub.j, Basic.num_of(n.v)), at: sub.at }
				}
			} else {
				{ m: Basic.set_num(n.m, nm.k, Basic.num_of(n.v)), at: nm.at }
			}
		}
	}

	split_commas : List(U8), U64, List(Str) -> List(Str)
	split_commas = |b, i, acc| {
		e = Basic.item_end(b, i)
		next = List.append(acc, Basic.trim_right(b, Basic.skip_ws(b, i), e))
		if e >= List.len(b) { next } else { Basic.split_commas(b, e + 1, next) }
	}

	# ---- PRINT -----------------------------------------------------------

	do_print : M, List(U8), U64 -> M
	do_print = |m, b, w| {
		p = Basic.print_items(m, b, w, True)
		if p.live and !p.done and !p.waiting { { ..p, pause: 1 } } else { p }
	}

	print_items : M, List(U8), U64, Bool -> M
	print_items = |m, b, i, newline| {
		j = Basic.skip_ws(b, i)
		if j >= List.len(b) or Basic.byte(b, j) == 58 {
			Basic.advance(if newline { Basic.emit(m, "\n") } else { m }, j)
		} else if Basic.byte(b, j) == 59 {
			Basic.print_items(m, b, j + 1, False)
		} else if Basic.byte(b, j) == 44 {
			Basic.print_items(Basic.comma(m), b, j + 1, False)
		} else {
			t = Basic.kw(b, j, "TAB")
			if t != j {
				r = Basic.sum(m, b, t + 1)
				e = Basic.skip_ws(b, r.at)
				past = if Basic.byte(b, e) == 41 { e + 1 } else { e }
				if r.m.done {
					r.m
				} else if r.m.ecma {
					Basic.print_items(Basic.tab_ecma(r.m, Basic.num_of(r.v)), b, past, True)
				} else {
					Basic.print_items(Basic.emit(r.m, Basic.spaces(F64.to_i64_wrap(Basic.num_of(r.v)) - r.m.col)), b, past, True)
				}
			} else {
				r = Basic.expr(m, b, j)
				if r.m.done { r.m } else { Basic.print_items(Basic.item(r.m, Basic.str_of(r.v)), b, r.at, True) }
			}
		}
	}

	# **PRINT WRAPS AT A MARGIN** where there is one: ECMA-55's (12.4), or the
	# page's forty-column screen. A microcomputer's batch run has none -- the
	# game captures come from a wider terminal. An item that does not fit in
	# the rest of the line starts a new one first, and one that fills it
	# exactly does not; a comma whose next zone would start at or past the
	# margin starts a new line.
	wrap_at : M -> I64
	wrap_at = |m| if m.ecma { Basic.margin } else if m.live { Basic.screen_w } else { 0 }

	comma : M -> M
	comma = |m| {
		next = m.col + Basic.zone - I64.rem_by(m.col, Basic.zone)
		w = Basic.wrap_at(m)
		if w > 0 and next >= w { Basic.emit(m, "\n") } else { Basic.emit(m, Basic.spaces(next - m.col)) }
	}

	item : M, Str -> M
	item = |m, t| {
		width = U64.to_i64_wrap(List.len(Str.to_utf8(t)))
		w = Basic.wrap_at(m)
		if w > 0 and m.col > 0 and m.col + width > w { Basic.emit(Basic.emit(m, "\n"), t) } else { Basic.emit(m, t) }
	}

	# **ECMA-55 COUNTS COLUMNS FROM ONE** (12.4): TAB(n) moves to column n,
	# so the next character is the n-th on the line. The argument is
	# rounded; below one it is an exception, reported and taken as one;
	# past the margin it is reduced by the margin; and a column already
	# passed starts a new line.
	margin : I64
	margin = 80

	tab_ecma : M, F64 -> M
	tab_ecma = |m, x| {
		n = Basic.idx(x)
		m1 = if n < 1 { Basic.emit(m, "\n?TAB argument less than one\n") } else { m }
		want = if n < 1 { 1 } else { I64.rem_by(n - 1, Basic.margin) + 1 }
		m2 = if m1.col > want - 1 { Basic.emit(m1, "\n") } else { m1 }
		Basic.emit(m2, Basic.spaces(want - 1 - m2.col))
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

	# **DIM AND OPTION ARE DECLARATIONS IN ECMA-55** (15): an array has its
	# bounds wherever control goes, even past a DIM it jumped over. They are
	# applied before the first statement, in line order, and passing through
	# one does nothing. A microcomputer runs a DIM where it stands, and its
	# bounds may be computed.
	declared : M -> M
	declared = |m| if m.ecma { Basic.declare(m, 0) } else { m }

	declare : M, U64 -> M
	declare = |m, i|
		if i >= List.len(m.prog) or m.done {
			m
		} else {
			b = (List.get(m.prog, i) ?? { num: -1, src: [] }).src
			d = Basic.kw(b, 0, "DIM")
			o = Basic.kw(b, 0, "OPTION")
			r = if d != 0 { Basic.do_dim({ ..m, pc: i, at: 0 }, b, d) } else if o != 0 { Basic.do_option({ ..m, pc: i, at: 0 }, b, o) } else { m }
			Basic.declare({ ..r, pc: 0, at: 0 }, i + 1)
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
		gap: False,
		waiting: False,
		asked: False,
		pause: 0,
		steps: 0,
		seed: seed,
		fuel: Basic.full_tank,
		tank: Basic.full_tank,
		live: False,
		base: 0,
		ecma: False,
		rejected: False,
		mem: List.repeat([], 4096),
		scr: List.repeat(32.U8, 1000),
		col_ram: List.repeat(14.U8, 1000),
		crow: 0,
		ccol: 0,
		pix: [],
		drew: False,
		fns: [],
	}

	# A tankful is what one resume runs before handing the machine back.
	# Small enough that an animation is smooth and a runaway loop is seen
	# quickly; ten tankfuls is what the batch door allows before it calls
	# a program non-terminating.
	full_tank : I64
	full_tank = 250000

	# **THE PAGE'S TANK IS SMALL.** A resume runs inside the tab's one
	# thread, and a tankful of PRINT-heavy statements held it for ten
	# seconds. Five thousand is milliseconds even at PRINT's cost, so Stop
	# and the screen answer promptly whatever the program is doing.
	page_tank : I64
	page_tank = 5000

	# **FUEL, NOT FAITH.** A BASIC listing loops forever on purpose often
	# enough, and a subject that hangs the harness is worse than one that
	# reports a bound.
	loop : M -> M
	loop = |m|
		if m.done or m.waiting or m.pause > 0 or m.fuel <= 0 {
			m
		} else {
			Basic.loop(Basic.step({ ..m, fuel: m.fuel - 1, steps: m.steps + 1 }))
		}

	# ---- the suspended machine -------------------------------------------

	# A program that has not been fed anything yet. It runs until it wants
	# a line, or until it is done.
	start : Str, U64 -> M
	start = |src, seed| Basic.loop({ ..Basic.new(Basic.load(src), [], seed), fuel: Basic.page_tank, tank: Basic.page_tank, live: True })

	# One more line, and on until the next time it wants one. A line given
	# to a machine that is not waiting is kept for the next INPUT rather
	# than dropped, so a page that types ahead does not lose it.
	# A machine that was SLEEPING wakes; one that was waiting for a line
	# is given this one. The two are told apart here so that waking a
	# sleeper does not push an empty line into its INPUT queue.
	# **THE FUEL IS PER RESUME, NOT PER PROGRAM.** It exists so that a
	# listing which loops forever cannot hang whatever is driving it, and
	# a suspended machine is already chunked into pieces the driver can
	# see between. An animation of a thousand frames is a thousand short
	# runs, and each one is bounded on its own.
	resume : M, Str -> M
	resume = |m, line|
		if m.done {
			m
		} else if m.pause > 0 or (m.fuel <= 0 and !m.waiting) {
			Basic.loop({ ..m, pause: 0, fuel: m.tank })
		} else {
			Basic.loop({ ..m, inp: List.append(m.inp, line), waiting: False, fuel: m.tank })
		}

	pause_ms : M -> I64
	pause_ms = |m| m.pause

	steps_taken : M -> I64
	steps_taken = |m| m.steps

	# 0 finished, 1 waiting for a line, 2 stopped on an exception,
	# 3 stopped on a form this interpreter has not built, 4 sleeping,
	# 5 yielded with fuel spent and more to do, 6 rejected before it ran.
	status : M -> I64
	status = |m|
		if m.rejected { 6 } else if m.waiting { 1 } else if m.pause > 0 { 4 } else if m.fuel <= 0 { 5 } else if m.gap { 3 } else if m.err != "" { 2 } else { 0 }

	# **THE BATCH DOOR.** Every keystroke up front and the transcript back:
	# what the corpus ladder grades. A machine that runs dry here has no
	# page to ask, so suspending is a gap rather than a pause -- the
	# interactive door (`start`/`resume`) is where waiting means waiting.
	run : Str, List(Str), U64 -> Str
	run = |src, inp, seed| Basic.run_in(src, inp, seed, False)

	# The same door in ECMA-55, where the microcomputers differ from it:
	# what the NBS suite grades.
	run_ecma : Str, List(Str), U64 -> Str
	run_ecma = |src, inp, seed| Basic.run_in(src, inp, seed, True)

	# A listing refused before it runs: nothing has executed, so nothing
	# has printed, and the reason is the whole transcript.
	refuse : Listing.Rejection -> M
	refuse = |bad| {
		why = if bad.num < 0 { bad.why } else { Str.concat(Str.concat(Str.concat(bad.why, " (line "), I64.to_str(bad.num)), ")") }
		{ ..Basic.new([], [], 1), done: True, rejected: True, err: why }
	}

	run_in : Str, List(Str), U64, Bool -> Str
	run_in = |src, inp, seed, ecma| {
		# The lines and statements first; the program as a whole only when
		# every line is well formed.
		line_fault = if ecma { Listing.check(src) } else { { why: "", num: -1 } }
		bad = if ecma and line_fault.why == "" { Program.check(src) } else { line_fault }
		m = if bad.why != "" { Basic.refuse(bad) } else { Basic.batch(Basic.loop(Basic.declared({ ..Basic.new(Basic.load(src), inp, seed), ecma: ecma })), 10) }
		Basic.transcript(
			if m.waiting {
				{ ..m, done: True, gap: True, err: "Out of input" }
			} else if m.fuel <= 0 {
				{ ..m, done: True, gap: True, err: "Did not terminate" }
			} else {
				m
			},
		)
	}

	# A yield has nobody to ask in batch, so it is refuelled a bounded
	# number of times and then reported as a program that did not stop --
	# which is what the suite calls it too.
	batch : M, I64 -> M
	batch = |m, tanks|
		if tanks <= 0 or m.done or m.waiting or m.fuel > 0 {
			m
		} else {
			Basic.batch(Basic.loop({ ..m, fuel: m.tank, pause: 0 }), tanks - 1)
		}

	transcript : M -> Str
	transcript = |m| {
		body = Str.join_with(m.out, "")
		# **A REPORTED EXCEPTION IS NOT A HALT.** ECMA-55 has exceptions
		# that are printed and carried on from -- a division by zero is
		# one -- and those print with the `?` a BASIC uses. What stops the
		# program gets a marker of its own so a harness can tell them
		# apart.
		if m.rejected {
			Str.concat("*** REJECTED: ", m.err)
		} else if m.err != "" and m.gap {
			Str.concat(Str.concat(body, "\n*** UNSUPPORTED: "), m.err)
		} else if m.err != "" {
			Str.concat(Str.concat(body, "\n*** HALTED: "), m.err)
		} else {
			body
		}
	}

	# A Str as its lines, which is how keystrokes arrive from a page or a
	# file. A trailing newline does not make an empty last line.
	lines : Str -> List(Str)
	lines = |t| {
		b = Str.to_utf8(t)
		if List.len(b) == 0 { [] } else { Basic.lines_from(b, 0, []) }
	}

	lines_from : List(U8), U64, List(Str) -> List(Str)
	lines_from = |b, i, acc|
		if i >= List.len(b) {
			acc
		} else {
			e = Basic.eol(b, i)
			t = if e > i and Basic.byte(b, U64.minus_wrap(e, 1)) == 13 { U64.minus_wrap(e, 1) } else { e }
			Basic.lines_from(b, e + 1, List.append(acc, Basic.text_of(b, i, t)))
		}

	# ---- the machine's memory -------------------------------------------

	page_bytes : U64
	page_bytes = 4096

	# **WIDER THAN A REAL MACHINE, BECAUSE THE FRAMEBUFFER IS.** A C64
	# masked to sixteen bits; 320x200 at a byte a pixel does not fit under
	# 64 KB, so this masks to twenty-four. A listing that relied on POKE
	# wrapping at 65536 would notice, and none does.
	addr_of : F64 -> U64
	addr_of = |x| I64.to_u64_wrap(I64.bitwise_and(F64.to_i64_wrap(Basic.floor(x)), 16777215))

	# **ABOVE EVERYTHING ELSE, AND CHECKED LAST.** The first home for this
	# was 16384, which put 16384..80383 straight across the colour cells
	# at 55296: every colour POKE landed in the framebuffer around row 121
	# and the picture was three lit rows in the middle of a black screen.
	# The small windows are matched before this one as well, so an overlap
	# cannot silently win again.
	hires_base : U64
	hires_base = 131072

	hires_w : U64
	hires_w = 320

	hires_h : U64
	hires_h = 200

	hires_cells : U64
	hires_cells = 64000

	screen_base : U64
	screen_base = 1024

	colour_base : U64
	colour_base = 55296

	screen_cells : U64
	screen_cells = 1000

	peek : M, U64 -> U8
	peek = |m, a|
		if a >= Basic.screen_base and a < Basic.screen_base + Basic.screen_cells {
			List.get(m.scr, a - Basic.screen_base) ?? 0
		} else if a >= Basic.colour_base and a < Basic.colour_base + Basic.screen_cells {
			List.get(m.col_ram, a - Basic.colour_base) ?? 0
		} else if a >= Basic.hires_base and a < Basic.hires_base + Basic.hires_cells {
			List.get(m.pix, a - Basic.hires_base) ?? 0
		} else {
			List.get(List.get(m.mem, a / Basic.page_bytes) ?? [], I64.to_u64_wrap(I64.rem_by(U64.to_i64_wrap(a), 4096))) ?? 0
		}

	# **THE PAGE COMES OUT OF THE TABLE BEFORE IT IS WRITTEN.** The list
	# handed to a List.update closure is not uniquely owned, so writing
	# through one copies the whole page on every byte. Taking it out with
	# List.replace, leaving an empty placeholder, writes in place.
	# `tests/copycheck.sh` is the instrument that tells the two apart.
	poke_at : M, U64, U8 -> M
	poke_at = |m, a, v|
		if a >= Basic.screen_base and a < Basic.screen_base + Basic.screen_cells {
			{ ..m, scr: List.set(m.scr, a - Basic.screen_base, v) ?? crash("poke: screen") }
		} else if a >= Basic.colour_base and a < Basic.colour_base + Basic.screen_cells {
			{ ..m, col_ram: List.set(m.col_ram, a - Basic.colour_base, v) ?? crash("poke: colour") }
		} else if a >= Basic.hires_base and a < Basic.hires_base + Basic.hires_cells {
			# The framebuffer is only made when something draws on it, so
			# a text program costs nothing for having one available.
			lit = if m.drew { m.pix } else { List.repeat(0.U8, Basic.hires_cells) }
			{ ..m, pix: List.set(lit, a - Basic.hires_base, v) ?? crash("poke: hires"), drew: True }
		} else {
			Basic.poke_mem(m, a, v)
		}

	poke_mem : M, U64, U8 -> M
	poke_mem = |m, a, v| {
		p = a / Basic.page_bytes
		off = I64.to_u64_wrap(I64.rem_by(U64.to_i64_wrap(a), 4096))
		taken = List.replace(m.mem, p, []) ?? crash("poke: address outside the 64 KB space")
		page = if List.is_empty(taken.prev) { List.repeat(0.U8, 4096) } else { taken.prev }
		{ ..m, mem: List.set(taken.list, p, List.set(page, off, v) ?? crash("poke: offset outside a page")) ?? crash("poke: address outside the 64 KB space") }
	}

	# The screen and its colour, as a page wants them: the thousand screen
	# codes then the thousand colour cells.
	# The thousand screen codes, the thousand colour cells, then the
	# framebuffer -- empty when nothing drew on it, so a text program
	# ships 2,000 bytes and a plotting one ships 66,000.
	screen : M -> List(U8)
	screen = |m| List.concat(List.concat(m.scr, m.col_ram), m.pix)
}
