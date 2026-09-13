# The BASIC machine: a parsed program (Parse) and the state it runs in.
#
# The dialect is ECMA-55 Minimal BASIC, graded by the National Bureau of
# Standards' test programs; the extensions past it are the ones the 1978
# Creative Computing games need, each marked EXT.
#
# **THE EVALUATOR READS THE MACHINE AND NEVER HANDS IT BACK.** An expression
# answers a value and its effects -- the next random seed, the exceptions it
# reported, the reason it stopped, the arrays it used before they existed --
# and the statement that asked applies them and makes its own write. Roc
# writes a list in place only while nothing else refers to it, and a
# machine passed down a recursion and handed back is referred to twice.
#
# **NO LOOP TAKES THE MACHINE AND HANDS IT BACK, EXCEPT THE RUN LOOP.** A
# loop inside a statement works on a piece of the machine -- the screen's
# bytes, a string being built -- or only reads it. A function that rebuilds
# the machine in a loop and returns it makes the next store copy.
#
# **EVERY STRUCTURE A STATEMENT WRITES HAS A BOUNDED COPY.** Variables,
# arrays and memory are persistent vectors (Vec), so when Roc does copy, it
# copies a path of 32-entry nodes and never a whole table.

import Listing
import Parse
import Program
import Twister
import Vec

Machine :: [].{
	Val : [N(F64), S(Str)]

	# An array: its width (0 for one dimension), how many cells it has, the
	# cells. `n` is 0 for an array that does not exist yet.
	Arr : { w : U64, n : U64, cells : Vec.V(F64) }

	# A FOR loop: its variable's slot, limit, step, and the statement after
	# the FOR, where each pass starts.
	Frame : { v : U64, limit : F64, step : F64, after : U64 }

	M : {
		pc : U64,
		# The item of a READ, INPUT or DIM next to store, and INPUT's reply.
		part : U64,
		reply : List(Str),
		nums : Vec.V(F64),
		strs : Vec.V(Str),
		arrs : Vec.V(Arr),
		# How many arrays exist: OPTION BASE comes before any.
		arr_count : U64,
		# Which DEF FNx have run, by letter.
		defined : List(Bool),
		# **A STACK IS A LIST AND A DEPTH**: the return points and the open loops
		# below `rdepth` and `ldepth` are live, and the entries above are reused.
		ret : List(U64),
		rdepth : U64,
		loops : List(Frame),
		ldepth : U64,
		dp : U64,
		inp : List(Str),
		ip : U64,
		out : List(Str),
		col : I64,
		done : Bool,
		err : Str,
		# **AN EXCEPTION IS NOT A GAP.** An ECMA-55 exception stops a program
		# correctly; a form this interpreter has not built is a gap.
		gap : Bool,
		# **A SUSPENDED MACHINE.** An INPUT with no line to read stops, having
		# printed its prompt; `asked` keeps the prompt from printing twice
		# when the statement runs again with the line.
		waiting : Bool,
		asked : Bool,
		# Milliseconds a SLEEP asked for; zero when not sleeping.
		pause : I64,
		# **RUNNING OUT OF FUEL IS A YIELD.** `steps` counts across resumes.
		steps : I64,
		seed : U64,
		# **A MICROCOMPUTER'S RND IS basic101's**: the Mersenne Twister of Ruby's
		# `Random.new(0)`, its position, and the last number drawn.
		mt : List(U32),
		mtat : U64,
		rlast : F64,
		fuel : I64,
		base : U64,
		rejected : Bool,
		# **THE ADDRESS SPACE**, 16 MB, which costs nothing until written.
		mem : Vec.V(U8),
		# **THE SCREEN IS A FLAT THOUSAND BYTES, AND STILL MEMORY**: 40x25 at
		# 1024, colour at 55296. Its rows are a ring: `top` is the row shown
		# first, so a scroll moves `top` and blanks one row.
		scr : List(U8),
		col_ram : List(U8),
		top : I64,
		crow : I64,
		ccol : I64,
		# **A LINEAR FRAMEBUFFER**, 320x200 from 131072, made when first drawn.
		pix : List(U8),
		drew : Bool,
	}

	# What an evaluation did besides its value: the seed it leaves, the
	# reports it printed, and why it stopped (empty when it did not).
	# `made` is each array it used before one existed, with whether it was
	# used with two subscripts.
	# **THE PROGRAM IS NOT STATE.** What no statement writes (Parse.Program) is
	# passed beside the machine rather than kept in it: every record update
	# copies the whole machine, and it was 728 bytes with the program in it.
	Run : { pg : Parse.Program, m : M }

	Fx : { seed : U64, said : Str, stop : Str, gap : Bool, made : List({ slot : U64, pair : Bool }), drew : Bool, mt : List(U32), mtat : U64, rlast : F64 }

	Ev : { v : Val, fx : Fx }

	# A DEF's parameter bound for the length of a call; the innermost last.
	Env : List({ slot : U64, v : F64 })

	no_arr : Arr
	no_arr = { w: 0, n: 0, cells: Vec.repeat(0, 0.0) }

	new : List(Str), U64 -> M
	new = |inp, seed| {
		pc: 0,
		part: 0,
		reply: [],
		nums: Vec.repeat(Parse.names, 0.0),
		strs: Vec.repeat(Parse.names, ""),
		arrs: Vec.repeat(Parse.names, Machine.no_arr),
		arr_count: 0,
		defined: List.repeat(False, 26),
		ret: [],
		rdepth: 0,
		loops: [],
		ldepth: 0,
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
		mt: Twister.by_seed(0),
		mtat: 624,
		rlast: 0.0,
		fuel: Machine.full_tank,
		base: 0,
		rejected: False,
		mem: Vec.repeat(16777216, 0),
		scr: List.repeat(32, 1000),
		col_ram: List.repeat(14, 1000),
		top: 0,
		crow: 0,
		ccol: 0,
		pix: [],
		drew: False,
	}

	full_tank : I64
	full_tank = 250000

	# **THE PAGE'S TANK IS SMALL**, so Stop and the screen answer promptly.
	page_tank : I64
	page_tank = 5000

	# ---- arithmetic Roc does not have ---------------------------------------

	e_const : F64
	e_const = 2.718281828459045

	ln2 : F64
	ln2 = 0.6931471805599453

	# The largest number, which a reported exception continues with.
	huge : F64
	huge = 1.7976931348623157e308

	floor : F64 -> F64
	floor = |x| {
		t = I64.to_f64(F64.to_i64_wrap(x))
		if x < 0.0 and t != x { t - 1.0 } else { t }
	}

	# LOG: the atanh series after a reduction by powers of two.
	ln : F64 -> F64
	ln = |x| if x <= 0.0 { 0.0 } else { Machine.ln_reduce(x, 0) }

	ln_reduce : F64, I64 -> F64
	ln_reduce = |x, k|
		if x >= 2.0 {
			Machine.ln_reduce(x / 2.0, k + 1)
		} else if x < 1.0 {
			Machine.ln_reduce(x * 2.0, k - 1)
		} else {
			t = (x - 1.0) / (x + 1.0)
			2.0 * Machine.atanh_series(t, t * t, t, 1.0, 0) + I64.to_f64(k) * Machine.ln2
		}

	atanh_series : F64, F64, F64, F64, I64 -> F64
	atanh_series = |acc, t2, term, d, i|
		if i >= 24 {
			acc
		} else {
			nt = term * t2
			nd = d + 2.0
			Machine.atanh_series(acc + nt / nd, t2, nt, nd, i + 1)
		}

	# A subscript rounds to the nearest integer and is not clamped; one too
	# big for an I64 stays out of range rather than wrapping into it.
	idx : F64 -> I64
	idx = |x|
		if x >= 1.0e12 {
			1000000000000
		} else if x <= -1.0e12 {
			-1000000000000
		} else {
			F64.to_i64_wrap(Machine.floor(x + 0.5))
		}

	# ---- printing a number ----------------------------------------------------

	# **ECMA-55 PRINTS SIX SIGNIFICANT DIGITS**, a sign place, and a
	# trailing space.
	fmt_num : F64 -> Str
	fmt_num = |x| {
		sign = if x < 0.0 { "-" } else { " " }
		Str.concat(Str.concat(sign, Machine.fmt_mag(F64.abs(x))), " ")
	}

	# What PRINT shows for a value: a number in its dialect's format.
	shown : Parse.Program, Val -> Str
	shown = |pg, v| match v {
		N(x) => if pg.ecma { Machine.fmt_num(x) } else { Machine.fmt_g7(x) }
		S(t) => t
	}

	# **A MICROCOMPUTER PRINTS SEVEN DIGITS.** The games' captures are the
	# expected output of basic101, a BASIC-80 interpreter: an integer prints
	# its digits, and any other number C's `%.7g` -- seven significant digits,
	# a zero before the point below one, an exponent below 1e-4 and from 1e7 --
	# with a space for the sign before it and a space after.
	fmt_g7 : F64 -> Str
	fmt_g7 = |x| {
		sign = if x < 0.0 { "-" } else { " " }
		a = F64.abs(x)
		mag =
			if !(a <= Machine.huge) {
				"INF"
			} else if a == Machine.floor(a) and a < 9.0e18 {
				I64.to_str(F64.to_i64_wrap(a))
			} else {
				Machine.g7(a)
			}
		Str.concat(Str.concat(sign, mag), " ")
	}

	g7 : F64 -> Str
	g7 = |a| {
		e0 = Machine.normal(a, 0).e
		scaled = if e0 >= 0 { a / F64.pow(10.0, I64.to_f64(e0)) } else { a * F64.pow(10.0, I64.to_f64(0 - e0)) }
		d0 = F64.to_i64_wrap(Machine.floor(scaled * 1000000.0 + 0.5))
		r = if d0 >= 10000000 { { d: 1000000, e: e0 + 1 } } else { { d: d0, e: e0 } }
		ds = I64.to_str(r.d)
		if r.e < -4 or r.e >= 7 {
			frac = Machine.no_zeros(Machine.drop(ds, 1))
			mant = if frac == "" { Machine.take(ds, 1) } else { Str.concat(Str.concat(Machine.take(ds, 1), "."), frac) }
			power = I64.abs(r.e)
			digits = if power < 10 { Str.concat("0", I64.to_str(power)) } else { I64.to_str(power) }
			Str.concat(Str.concat(mant, if r.e < 0 { "e-" } else { "e+" }), digits)
		} else if r.e >= 0 {
			whole = Machine.take(ds, I64.to_u64_wrap(r.e + 1))
			frac = Machine.no_zeros(Machine.drop(ds, I64.to_u64_wrap(r.e + 1)))
			if frac == "" { whole } else { Str.concat(Str.concat(whole, "."), frac) }
		} else {
			Str.concat(Str.concat("0.", Str.repeat("0", I64.to_u64_wrap(0 - r.e - 1))), Machine.no_zeros(ds))
		}
	}

	fmt_mag : F64 -> Str
	fmt_mag = |a|
		if a == 0.0 {
			"0"
		} else if !(a <= Machine.huge) {
			"INF"
		} else if a == Machine.floor(a) and a < 1000000000.0 {
			I64.to_str(F64.to_i64_wrap(a))
		} else {
			n = Machine.normal(a, 0)
			d = F64.to_i64_wrap(Machine.floor(n.m * 100000.0 + 0.5))
			r = if d >= 1000000 { { d: 100000, e: n.e + 1 } } else { { d: d, e: n.e } }
			Machine.lay_out(I64.to_str(r.d), r.e)
		}

	normal : F64, I64 -> { m : F64, e : I64 }
	normal = |a, e|
		if a >= 10.0 {
			Machine.normal(a / 10.0, e + 1)
		} else if a < 1.0 {
			Machine.normal(a * 10.0, e - 1)
		} else {
			{ m: a, e: e }
		}

	lay_out : Str, I64 -> Str
	lay_out = |ds, e|
		if e >= 0 and e < 6 {
			whole = Machine.take(ds, I64.to_u64_wrap(e + 1))
			frac = Machine.no_zeros(Machine.drop(ds, I64.to_u64_wrap(e + 1)))
			if frac == "" { whole } else { Str.concat(Str.concat(whole, "."), frac) }
		} else if e == -1 {
			Str.concat(".", Machine.no_zeros(ds))
		} else {
			frac = Machine.no_zeros(Machine.drop(ds, 1))
			mant = if frac == "" { Machine.take(ds, 1) } else { Str.concat(Str.concat(Machine.take(ds, 1), "."), frac) }
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
	no_zeros = |t| if Str.ends_with(t, "0") { Machine.no_zeros(Machine.take(t, Str.count_utf8_bytes(t) - 1)) } else { t }

	# ---- the evaluator ----------------------------------------------------------

	num_of : Val -> F64
	num_of = |v| match v {
		N(x) => x
		S(_) => 0.0
	}

	str_of : Val -> Str
	str_of = |v| match v {
		N(x) => Machine.fmt_num(x)
		S(s) => s
	}

	stopped : Fx -> Bool
	stopped = |fx| fx.stop != ""

	# ECMA-55 7.4: an overflow is reported and continues with the largest
	# number of its sign. An infinity is never a value.
	finite : Fx, F64 -> Ev
	finite = |fx, x|
		if x > Machine.huge {
			{ v: N(Machine.huge), fx: { ..fx, said: Str.concat(fx.said, "\n?Overflow\n") } }
		} else if x < 0.0 - Machine.huge {
			{ v: N(0.0 - Machine.huge), fx: { ..fx, said: Str.concat(fx.said, "\n?Overflow\n") } }
		} else {
			{ v: N(x), fx: fx }
		}

	# A FATAL EXCEPTION is the program's; a gap is this interpreter's.
	halt : Fx, Str -> Ev
	halt = |fx, why| { v: N(0.0), fx: { ..fx, stop: why, gap: False } }

	gap_stop : Fx, Str -> Ev
	gap_stop = |fx, why| { v: N(0.0), fx: { ..fx, stop: why, gap: True } }

	eval : Parse.Program, M, Env, Fx, Parse.Expr -> Ev
	eval = |pg, m, env, fx, e| match e {
		Num(x) => Machine.finite(fx, x)
		Text(s) => { v: S(s), fx: fx }
		NumVar(s) => { v: N(Machine.num_var(m, env, s)), fx: fx }
		StrVar(s) => { v: S(Vec.get(m.strs, s, "")), fx: fx }
		Elem(s, one, two, pair) => {
			at = Machine.subs(pg, m, env, fx, one, two, pair)
			if Machine.stopped(at.fx) { { v: N(0.0), fx: at.fx } } else { Machine.elem(m, at.fx, s, at.i, at.j, pair) }
		}
		AsNum(a) => {
			r = Machine.eval(pg, m, env, fx, a)
			{ v: N(Machine.num_of(r.v)), fx: r.fx }
		}
		Neg(a) => {
			r = Machine.eval(pg, m, env, fx, a)
			{ v: N(0.0 - Machine.num_of(r.v)), fx: r.fx }
		}
		Add(a, b) => Machine.arith(pg, m, env, fx, a, b, 1)
		Sub(a, b) => Machine.arith(pg, m, env, fx, a, b, 2)
		Mul(a, b) => Machine.arith(pg, m, env, fx, a, b, 3)
		Div(a, b) => Machine.arith(pg, m, env, fx, a, b, 4)
		Pow(a, b) => Machine.arith(pg, m, env, fx, a, b, 5)
		Cat(a, b) => {
			l = Machine.eval(pg, m, env, fx, a)
			if Machine.stopped(l.fx) {
				l
			} else {
				r = Machine.eval(pg, m, env, l.fx, b)
				if Machine.stopped(r.fx) { r } else { { v: S(Str.concat(Machine.str_of(l.v), Machine.str_of(r.v))), fx: r.fx } }
			}
		}
		Call(code, a) => {
			r = Machine.eval(pg, m, env, fx, a)
			if Machine.stopped(r.fx) { r } else { Machine.call(m, r.fx, code, r.v) }
		}
		Rnd => Machine.draw_rnd(pg, m, fx)
		RndOf(a) => {
			r = Machine.eval(pg, m, env, fx, a)
			if Machine.stopped(r.fx) {
				r
			} else if pg.ecma or Machine.num_of(r.v) > 0.0 {
				Machine.draw_rnd(pg, m, r.fx)
			} else {
				{ v: N(if r.fx.drew { r.fx.rlast } else { m.rlast }), fx: r.fx }
			}
		}
		Chr(a) => {
			r = Machine.eval(pg, m, env, fx, a)
			code = I64.bitwise_and(F64.to_i64_wrap(Machine.floor(Machine.num_of(r.v))), 255)
			if Machine.stopped(r.fx) { r } else { { v: S(List.get(Machine.chars, I64.to_u64_wrap(code)) ?? "?"), fx: r.fx } }
		}
		StrOf(a) => {
			r = Machine.eval(pg, m, env, fx, a)
			if Machine.stopped(r.fx) { r } else { { v: S(Machine.fmt_num(Machine.num_of(r.v))), fx: r.fx } }
		}
		Left(a, n) => Machine.cut(pg, m, env, fx, a, n, Parse.zero, 1)
		Right(a, n) => Machine.cut(pg, m, env, fx, a, n, Parse.zero, 2)
		Mid(a, n) => Machine.cut(pg, m, env, fx, a, n, Parse.zero, 3)
		Mid3(a, n, k) => Machine.cut(pg, m, env, fx, a, n, k, 4)
		CallDef(letter, param, arg) => Machine.call_def(pg, m, env, fx, letter, param, arg)
		Seq(a, b) => {
			r = Machine.eval(pg, m, env, fx, a)
			if Machine.stopped(r.fx) { r } else { Machine.eval(pg, m, env, r.fx, b) }
		}
		Fail(why) => Machine.gap_stop(fx, why)
	}

	# **CHR$ INDEXES A TABLE.** The one-character strings are made once, so a
	# CHR$ in a loop makes no list to turn into a string. A byte that is not
	# UTF-8 on its own is `?`.
	chars : List(Str)
	chars = Machine.char_table(0, [])

	char_table : U64, List(Str) -> List(Str)
	char_table = |c, acc| if c >= 256 { acc } else { Machine.char_table(c + 1, List.append(acc, Str.from_utf8([U64.to_u8_wrap(c)]) ?? "?")) }

	# A parameter bound by a call hides the variable of its name.
	num_var : M, Env, U64 -> F64
	num_var = |m, env, s| {
		var $v = Vec.get(m.nums, s, 0.0)
		for b in env {
			if b.slot == s { $v = b.v } else { {} }
		}
		$v
	}

	# 1 +, 2 -, 3 *, 4 /, 5 ^.
	arith : Parse.Program, M, Env, Fx, Parse.Expr, Parse.Expr, U8 -> Ev
	arith = |pg, m, env, fx, a, b, op| {
		l = Machine.eval(pg, m, env, fx, a)
		if Machine.stopped(l.fx) {
			l
		} else {
			r = Machine.eval(pg, m, env, l.fx, b)
			x = Machine.num_of(l.v)
			d = Machine.num_of(r.v)
			if Machine.stopped(r.fx) {
				r
			} else if op == 1 {
				Machine.finite(r.fx, x + d)
			} else if op == 2 {
				Machine.finite(r.fx, x - d)
			} else if op == 3 {
				Machine.finite(r.fx, x * d)
			} else if op == 4 {
				if d == 0.0 {
					# ECMA-55 12.4: reported, and continues with the largest number.
					{ v: N(if x < 0.0 { 0.0 - Machine.huge } else { Machine.huge }), fx: { ..r.fx, said: Str.concat(r.fx.said, "\n?Division by zero\n") } }
				} else {
					Machine.finite(r.fx, x / d)
				}
			} else {
				Machine.raise(r.fx, x, d)
			}
		}
	}

	# ECMA-55 7.5. Above 2^52 every F64 is an integer, and `floor` truncates
	# through I64, so it is not asked there.
	raise : Fx, F64, F64 -> Ev
	raise = |fx, x, y|
		if x < 0.0 and F64.abs(y) < 4503599627370496.0 and y != Machine.floor(y) {
			Machine.halt(fx, "Negative number raised to a non-integral power")
		} else if x == 0.0 and y < 0.0 {
			{ v: N(Machine.huge), fx: { ..fx, said: Str.concat(fx.said, "\n?Zero raised to a negative power\n") } }
		} else {
			Machine.finite(fx, F64.pow(x, y))
		}

	# ECMA-55's RND is the LCG below; a microcomputer's draws from the Twister,
	# continuing from what this evaluation has drawn already.
	draw_rnd : Parse.Program, M, Fx -> Ev
	draw_rnd = |pg, m, fx|
		if pg.ecma {
			Machine.rnd(fx)
		} else {
			d = if fx.drew { Twister.res53(fx.mt, fx.mtat) } else { Twister.res53(m.mt, m.mtat) }
			{ v: N(d.v), fx: { ..fx, drew: True, mt: d.mt, mtat: d.at, rlast: d.v } }
		}

	# A 64-bit LCG (Knuth's MMIX constants); **THE NUMBER IS THE TOP 53 BITS.**
	rnd : Fx -> Ev
	rnd = |fx| {
		s = U64.plus_wrap(U64.times_wrap(fx.seed, 6364136223846793005), 1442695040888963407)
		{ v: N(I64.to_f64(U64.to_i64_wrap(U64.div_trunc_by(s, 2048))) / 9007199254740992.0), fx: { ..fx, seed: s } }
	}

	call : M, Fx, U8, Val -> Ev
	call = |m, fx, code, v| {
		x = Machine.num_of(v)
		if code == 11 {
			{ v: N(I64.to_f64(U8.to_i64(Machine.peek(m, Machine.addr_of(x))))), fx: fx }
		} else if code == 12 {
			{ v: N(U64.to_f64(Str.count_utf8_bytes(Machine.str_of(v)))), fx: fx }
		} else if code == 13 {
			{ v: N(I64.to_f64(U8.to_i64(List.first(Str.to_utf8(Machine.str_of(v))) ?? 0))), fx: fx }
		} else if code == 14 {
			vb = Str.to_utf8(Machine.str_of(v))
			Machine.signed(fx, vb, Parse.skip_ws(vb, 0))
		} else if code == 6 and x <= 0.0 {
			Machine.halt(fx, "LOG of a number that is not positive")
		} else if code == 9 and x < 0.0 {
			Machine.halt(fx, "SQR of a negative number")
		} else {
			Machine.finite(fx, Machine.apply_fn(code, x))
		}
	}

	apply_fn : U8, F64 -> F64
	apply_fn = |code, x|
		if code == 1 { F64.abs(x) }
		else if code == 2 { F64.atan(x) }
		else if code == 3 { F64.cos(x) }
		else if code == 4 { F64.pow(Machine.e_const, x) }
		else if code == 5 { Machine.floor(x) }
		else if code == 6 { Machine.ln(x) }
		else if code == 7 { if x > 0.0 { 1.0 } else if x < 0.0 { -1.0 } else { 0.0 } }
		else if code == 8 { F64.sin(x) }
		else if code == 9 { F64.sqrt(x) }
		else { F64.tan(x) }

	# **A DATUM OR A REPLY MAY CARRY A SIGN** (ECMA-55 14, 13); so may VAL's.
	signed : Fx, List(U8), U64 -> Ev
	signed = |fx, b, i| {
		c = Parse.byte(b, i)
		n = Parse.numeral(b, if c == 45 or c == 43 { i + 1 } else { i })
		r = Machine.finite(fx, n.v)
		if c == 45 { { v: N(0.0 - Machine.num_of(r.v)), fx: r.fx } } else { r }
	}

	# LEFT$ 1, RIGHT$ 2, MID$ to the end 3, MID$ with a length 4.
	cut : Parse.Program, M, Env, Fx, Parse.Expr, Parse.Expr, Parse.Expr, U8 -> Ev
	cut = |pg, m, env, fx, a, n, k, which| {
		s = Machine.eval(pg, m, env, fx, a)
		c = if Machine.stopped(s.fx) { s } else { Machine.eval(pg, m, env, s.fx, n) }
		l = if which == 4 and !Machine.stopped(c.fx) { Machine.eval(pg, m, env, c.fx, k) } else { c }
		if Machine.stopped(l.fx) {
			l
		} else {
			src = Str.to_utf8(Machine.str_of(s.v))
			len = List.len(src)
			at = Machine.clamp(Machine.idx(Machine.num_of(c.v)), len)
			from = if at == 0 { 0 } else { at - 1 }
			text =
				if which == 1 {
					Machine.slice(src, 0, at)
				} else if which == 2 {
					Machine.slice(src, len - at, at)
				} else if which == 3 {
					Machine.slice(src, from, len - from)
				} else {
					Machine.slice(src, from, Machine.clamp(Machine.idx(Machine.num_of(l.v)), len - from))
				}
			{ v: S(text), fx: l.fx }
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

	# The body is evaluated with the parameter bound; a call before its DEF
	# has run is an unsupported form.
	call_def : Parse.Program, M, Env, Fx, U64, Bool, Parse.Expr -> Ev
	call_def = |pg, m, env, fx, letter, param, arg| {
		f = List.get(pg.fns, letter) ?? Parse.no_fn
		if !(List.get(m.defined, letter) ?? False) {
			Machine.gap_stop(fx, Str.concat("Undefined function: FN", Str.from_utf8([U64.to_u8_wrap(65 + letter)]) ?? ""))
		} else if !param {
			Machine.eval(pg, m, env, fx, f.body)
		} else {
			a = Machine.eval(pg, m, env, fx, arg)
			if Machine.stopped(a.fx) { a } else { Machine.eval(pg, m, List.append(env, { slot: f.pslot, v: Machine.num_of(a.v) }), a.fx, f.body) }
		}
	}

	# Subscripts: the second is the OPTION BASE when there is one.
	subs : Parse.Program, M, Env, Fx, Parse.Expr, Parse.Expr, Bool -> { i : I64, j : I64, fx : Fx }
	subs = |pg, m, env, fx, one, two, pair| {
		r = Machine.eval(pg, m, env, fx, one)
		r2 = if pair and !Machine.stopped(r.fx) { Machine.eval(pg, m, env, r.fx, two) } else { r }
		{ i: Machine.idx(Machine.num_of(r.v)), j: if pair { Machine.idx(Machine.num_of(r2.v)) } else { U64.to_i64_wrap(m.base) }, fx: r2.fx }
	}

	# ECMA-55: an array with no DIM has a bound of 10 in each dimension its
	# first use gives it. Read before it exists, it is that array, all zeros,
	# and the statement makes it.
	elem : M, Fx, U64, I64, I64, Bool -> Ev
	elem = |m, fx, slot, i, j, pair| {
		a = Vec.at(m.arrs, slot)
		shape = if a.n == 0 { Machine.default_shape(m.base, pair) } else { { w: a.w, n: a.n } }
		c = Machine.cell_at(shape.w, m.base, i, j)
		fx1 = if a.n == 0 { { ..fx, made: List.append(fx.made, { slot: slot, pair: pair }) } } else { fx }
		if c < 0 or I64.to_u64_wrap(c) >= shape.n {
			Machine.halt(fx1, Str.concat("Subscript out of range: ", Parse.name_of(slot)))
		} else if a.n == 0 {
			{ v: N(0.0), fx: fx1 }
		} else {
			{ v: N(Vec.at(a.cells, I64.to_u64_wrap(c))), fx: fx1 }
		}
	}

	default_shape : U64, Bool -> { w : U64, n : U64 }
	default_shape = |base, pair| {
		rows = 11 - base
		if pair { { w: rows, n: rows * rows } } else { { w: 0, n: rows } }
	}

	# Where a subscript pair lands, or -1 outside the array.
	cell_at : U64, U64, I64, I64 -> I64
	cell_at = |w, base64, i, j| {
		base = U64.to_i64_wrap(base64)
		r = i - base
		c = j - base
		if r < 0 or c < 0 {
			-1
		} else if w == 0 {
			if j != base and j != 0 { -1 } else { r }
		} else if c >= U64.to_i64_wrap(w) {
			-1
		} else {
			r * U64.to_i64_wrap(w) + c
		}
	}

	# ---- output -------------------------------------------------------------------

	# **PRINT AND POKE SHARE ONE DISPLAY.** Text goes into the transcript and
	# onto the screen at the cursor; the twenty-sixth line scrolls.
	emit : M, Str -> M
	emit = |m, t|
		if t == "" {
			m
		} else {
			b = Str.to_utf8(t)
			d = Machine.draw(m.scr, m.col_ram, m.top, m.crow, m.ccol, b)
			{ ..m, scr: d.scr, col_ram: d.col_ram, top: d.top, crow: d.crow, ccol: d.ccol, out: Machine.append_out(m.out, t), col: Machine.col_after(b, m.col) }
		}

	Drawn : { scr : List(U8), col_ram : List(U8), top : I64, crow : I64, ccol : I64 }

	draw : List(U8), List(U8), I64, I64, I64, List(U8) -> Drawn
	draw = |scr, col_ram, top, crow, ccol, b| {
		var $scr = scr
		var $col_ram = col_ram
		var $top = top
		var $row = crow
		var $col = ccol
		for c in b {
			if c != 10 {
				$scr = List.set($scr, Machine.cell(Machine.row_at($top, $row), $col), Machine.screen_code(c)) ?? crash("draw: outside the screen")
			} else {
				{}
			}
			if c == 10 or $col + 1 >= Machine.screen_w {
				$col = 0
				if $row + 1 >= Machine.screen_h {
					# The row at the top becomes the blank row at the foot.
					bottom = Machine.row_at($top, 0)
					$scr = Machine.fill_row($scr, bottom, 32)
					$col_ram = Machine.fill_row($col_ram, bottom, 14)
					$top = I64.rem_by($top + 1, Machine.screen_h)
				} else {
					$row = $row + 1
				}
			} else {
				$col = $col + 1
			}
		}
		{ scr: $scr, col_ram: $col_ram, top: $top, crow: $row, ccol: $col }
	}

	screen_w : I64
	screen_w = 40

	screen_h : I64
	screen_h = 25

	# Where a screen row is kept, given the row shown first.
	row_at : I64, I64 -> I64
	row_at = |top, row| I64.rem_by(top + row, Machine.screen_h)

	cell : I64, I64 -> U64
	cell = |kept_row, col| I64.to_u64_wrap(kept_row * Machine.screen_w + col)

	fill_row : List(U8), I64, U8 -> List(U8)
	fill_row = |bytes, kept_row, v| {
		var $b = bytes
		var $c = 0
		while $c < Machine.screen_w {
			$b = List.set($b, Machine.cell(kept_row, $c), v) ?? crash("fill_row: outside the screen")
			$c = $c + 1
		}
		$b
	}

	# A Commodore screen code: letters from 64, lower case as upper, 32..63
	# themselves, graphics from 128.
	screen_code : U8 -> U8
	screen_code = |c|
		if c >= 64 and c <= 95 { c - 64 }
		else if c >= 97 and c <= 122 { c - 96 }
		else if c >= 32 and c <= 63 { c }
		else if c >= 128 { c - 128 }
		else { 32 }

	col_after : List(U8), I64 -> I64
	col_after = |b, col| {
		var $c = col
		for x in b {
			$c = if x == 10 { 0 } else { $c + 1 }
		}
		$c
	}

	# The column after text, without making its bytes when it has no newline.
	col_after_text : Str, I64 -> I64
	col_after_text = |t, col| if Str.contains(t, "\n") { Machine.col_after(Str.to_utf8(t), col) } else { col + U64.to_i64_wrap(Str.count_utf8_bytes(t)) }

	# **A PROGRAM THAT PRINTS FOREVER MUST NOT GROW FOREVER**: the transcript
	# is trimmed to its last 8,000 pieces once it has twice that.
	scrollback : U64
	scrollback = 8000

	append_out : List(Str), Str -> List(Str)
	append_out = |out, t|
		if List.len(out) < Machine.scrollback * 2 {
			List.append(out, t)
		} else {
			List.append(List.sublist(out, { start: Machine.scrollback, len: List.len(out) - Machine.scrollback }), t)
		}

	spaces : I64 -> Str
	spaces = |n| if n <= 0 { "" } else { Str.repeat(" ", I64.to_u64_wrap(n)) }

	zone : I64
	zone = 14

	margin : I64
	margin = 80

	# **PRINT WRAPS AT A MARGIN** where there is one: ECMA-55's, or the
	# page's forty columns. A microcomputer's batch run has none.
	wrap_at : Parse.Program, M -> I64
	wrap_at = |pg, m| if pg.ecma { Machine.margin } else if pg.live { Machine.screen_w } else { 0 }

	# A PRINT's text, reports and all, built without touching the machine:
	# its items are evaluated in order against the column they move.
	print_text : Parse.Program, M, List(Parse.Item), Bool -> { text : Str, fx : Fx }
	print_text = |pg, m, items, newline| {
		w = Machine.wrap_at(pg, m)
		var $text = ""
		var $col = m.col
		var $fx = Machine.fresh(m)
		for it in items {
			if Machine.stopped($fx) {
				{}
			} else {
				piece = match it {
					Semi => { said: "", t: "", fx: $fx }
					Comma => {
						next = $col + Machine.zone - I64.rem_by($col, Machine.zone)
						{ said: "", t: if w > 0 and next >= w { "\n" } else { Machine.spaces(next - $col) }, fx: $fx }
					}
					Tab(e) => {
						r = Machine.eval(pg, m, [], $fx, e)
						x = Machine.num_of(r.v)
						{ said: r.fx.said, t: if Machine.stopped(r.fx) { "" } else if pg.ecma { Machine.tab_ecma(x, Machine.col_after_text(r.fx.said, $col)) } else { Machine.spaces(F64.to_i64_wrap(x) - Machine.col_after_text(r.fx.said, $col)) }, fx: r.fx }
					}
					Show(e) => {
						r = Machine.eval(pg, m, [], $fx, e)
						t = Machine.shown(pg, r.v)
						c = Machine.col_after_text(r.fx.said, $col)
						wrapped = w > 0 and c > 0 and c + U64.to_i64_wrap(Str.count_utf8_bytes(t)) > w
						{ said: r.fx.said, t: if Machine.stopped(r.fx) { "" } else if wrapped { Str.concat("\n", t) } else { t }, fx: r.fx }
					}
				}
				both = Str.concat(piece.said, piece.t)
				$text = Str.concat($text, both)
				$col = Machine.col_after_text(both, $col)
				$fx = { ..piece.fx, said: "" }
			}
		}
		{ text: if newline and !Machine.stopped($fx) { Str.concat($text, "\n") } else { $text }, fx: $fx }
	}

	# **ECMA-55 COUNTS COLUMNS FROM ONE** (12.4): TAB(n) moves to column n.
	# Below one it is reported and taken as one; past the margin it wraps;
	# a column already passed starts a new line.
	tab_ecma : F64, I64 -> Str
	tab_ecma = |x, col| {
		n = Machine.idx(x)
		said = if n < 1 { "\n?TAB argument less than one\n" } else { "" }
		c = if n < 1 { 0 } else { col }
		want = if n < 1 { 1 } else { I64.rem_by(n - 1, Machine.margin) + 1 }
		down = if c > want - 1 { "\n" } else { "" }
		Str.concat(Str.concat(said, down), Machine.spaces(want - 1 - (if c > want - 1 { 0 } else { c })))
	}

	# ---- applying an evaluation ---------------------------------------------------

	fresh : M -> Fx
	fresh = |m| { seed: m.seed, said: "", stop: "", gap: False, made: [], drew: False, mt: [], mtat: 0, rlast: 0.0 }

	# What an evaluation did, applied once: its reports printed, its seed
	# kept, the arrays it used made, and its stop.
	# **A PLAIN EVALUATION IS APPLIED BY NOT APPLYING IT.** One that printed
	# nothing, stopped nothing, made no array and drew no random number leaves
	# the machine as it was, so a statement can write the machine it was given.
	# POKE writing the machine `settle` answered copied the whole path of
	# memory it wrote, every time (measured; the mechanism is Roc's).
	plain : M, Fx -> Bool
	plain = |m, fx| fx.said == "" and fx.stop == "" and List.is_empty(fx.made) and fx.seed == m.seed and !fx.drew

	# Nothing to apply but random numbers drawn: no report, no stop, no array.
	quiet : Fx -> Bool
	quiet = |fx| fx.said == "" and fx.stop == "" and List.is_empty(fx.made)

	settle : M, Fx -> M
	settle = |m, fx| {
		shown = Machine.emit(m, fx.said)
		drawn = if fx.drew { { ..shown, mt: fx.mt, mtat: fx.mtat, rlast: fx.rlast } } else { shown }
		made = if List.is_empty(fx.made) { { arrs: drawn.arrs, count: drawn.arr_count } } else { Machine.make_arrays(drawn.arrs, drawn.arr_count, drawn.base, fx.made) }
		if Machine.stopped(fx) {
			{ ..drawn, seed: fx.seed, arrs: made.arrs, arr_count: made.count, done: True, err: fx.stop, gap: fx.gap }
		} else {
			{ ..drawn, seed: fx.seed, arrs: made.arrs, arr_count: made.count }
		}
	}

	make_arrays : Vec.V(Arr), U64, U64, List({ slot : U64, pair : Bool }) -> { arrs : Vec.V(Arr), count : U64 }
	make_arrays = |arrs, count, base, made| {
		var $arrs = arrs
		var $count = count
		for x in made {
			if (Vec.get($arrs, x.slot, Machine.no_arr)).n == 0 {
				a = Machine.shaped(base, 10, if x.pair { 10 } else { -1 })
				$arrs = Vec.set($arrs, x.slot, a.arr)
				$count = $count + 1
			} else {
				{}
			}
		}
		{ arrs: $arrs, count: $count }
	}

	# An array's bounds from the OPTION BASE; `ok` False when they leave no cells.
	shaped : U64, I64, I64 -> { arr : Arr, ok : Bool }
	shaped = |base64, d1, d2| {
		b = Machine.bounds(base64, d1, d2)
		if !b.ok { { arr: Machine.no_arr, ok: False } } else { { arr: { w: b.w, n: b.n, cells: Vec.repeat(b.n, 0.0) }, ok: True } }
	}

	# An array's width and cell count from its bounds, without its cells.
	bounds : U64, I64, I64 -> { w : U64, n : U64, ok : Bool }
	bounds = |base64, d1, d2| {
		base = U64.to_i64_wrap(base64)
		rows = d1 - base + 1
		cols = d2 - base + 1
		n = if d2 < 0 { rows } else { rows * cols }
		if rows <= 0 or (d2 >= 0 and cols <= 0) or n <= 0 {
			{ w: 0, n: 0, ok: False }
		} else {
			{ w: if d2 < 0 { 0 } else { I64.to_u64_wrap(cols) }, n: I64.to_u64_wrap(n), ok: True }
		}
	}

	# **THE ARRAY COMES OUT OF ITS VECTOR BEFORE IT IS WRITTEN**, and goes back.
	set_arr : M, U64, I64, I64, F64 -> M
	set_arr = |m, slot, i, j, x| {
		c = Machine.cell_of(m.arrs, m.base, slot, i, j)
		if c < 0 {
			Machine.fail(m, Str.concat("Subscript out of range: ", Parse.name_of(slot)))
		} else {
			{ ..m, arrs: Machine.arr_store(m.arrs, slot, I64.to_u64_wrap(c), x) }
		}
	}

	# The cell a subscript pair names, or -1 outside the array.
	cell_of : Vec.V(Arr), U64, U64, I64, I64 -> I64
	cell_of = |arrs, base, slot, i, j| {
		a = Vec.get(arrs, slot, Machine.no_arr)
		c = Machine.cell_at(a.w, base, i, j)
		if c < 0 or I64.to_u64_wrap(c) >= a.n { -1 } else { c }
	}

	# **THE ARRAY COMES OUT OF ITS VECTOR BEFORE IT IS WRITTEN**, and goes back.
	arr_store : Vec.V(Arr), U64, U64, F64 -> Vec.V(Arr)
	arr_store = |arrs, slot, c, x| {
		r = Vec.replace(arrs, slot, Machine.no_arr, Machine.no_arr)
		{ w, n, cells } = r.prev
		Vec.set(r.v, slot, { w: w, n: n, cells: Vec.set(cells, c, x) })
	}

	# ---- control ------------------------------------------------------------------

	next : M -> M
	next = |m| { ..m, pc: m.pc + 1 }

	fail : M, Str -> M
	fail = |m, why| { ..m, done: True, err: why, gap: False }

	# Where a jump lands: the statement index, or -1 with the line it wanted.
	Landing : { at : I64, n : I64, fx : Fx }

	landing : Parse.Program, M, Parse.Jump -> Landing
	landing = |pg, m, jump| match jump {
		To(i) => { at: U64.to_i64_wrap(i), n: 0, fx: Machine.fresh(m) }
		Missing(n) => { at: -1, n: n, fx: Machine.fresh(m) }
		Line(n) => { at: -1, n: n, fx: Machine.fresh(m) }
		Computed(e) => {
			r = Machine.eval(pg, m, [], Machine.fresh(m), e)
			n = F64.to_i64_wrap(Machine.num_of(r.v))
			k = Parse.find_line(pg.lines, n)
			{ at: if k < 0 { -1 } else { U64.to_i64_wrap(List.get(pg.firsts, I64.to_u64_wrap(k)) ?? 0) }, n: n, fx: r.fx }
		}
	}

	go : M, Landing, U64 -> M
	go = |m, l, back|
		if Machine.plain(m, l.fx) {
			Machine.land(m, l, back)
		} else {
			s = Machine.settle(m, l.fx)
			if s.done { s } else { Machine.land(s, l, back) }
		}

	# Taken, with the return point pushed first when `back` is not `none`.
	land : M, Landing, U64 -> M
	land = |m, l, back|
		if l.at < 0 {
			Machine.fail(m, Str.concat("No such line: ", I64.to_str(l.n)))
		} else if back == Parse.none {
			{ ..m, pc: I64.to_u64_wrap(l.at) }
		} else {
			{ ..m, pc: I64.to_u64_wrap(l.at), ret: Machine.push(m.ret, m.rdepth, back), rdepth: m.rdepth + 1 }
		}

	# **POPPING LOWERS THE DEPTH AND KEEPS THE ENTRY; PUSHING OVERWRITES IT.**
	# A GOSUB and its RETURN, or a loop entered and left, reuse the same cells:
	# a list pushed and popped back to empty allocated every time.
	push : List(a), U64, a -> List(a)
	push = |xs, depth, x| if depth < List.len(xs) { List.set(xs, depth, x) ?? crash("push: inside the list") } else { List.append(xs, x) }

	next_line : Parse.Program, M, U64 -> U64
	next_line = |pg, m, line| List.get(pg.firsts, line + 1) ?? List.len(pg.prog)

	# Both sides, then the comparison.
	condition : Parse.Program, M, Parse.Expr, U8, Parse.Expr -> { yes : Bool, fx : Fx }
	condition = |pg, m, a, op, b| {
		l = Machine.eval(pg, m, [], Machine.fresh(m), a)
		r = if Machine.stopped(l.fx) { l } else { Machine.eval(pg, m, [], l.fx, b) }
		yes = match l.v {
			S(x) => Machine.cmp_str(op, x, Machine.str_of(r.v))
			N(x) => Machine.cmp_num(op, x, Machine.num_of(r.v))
		}
		{ yes: yes, fx: r.fx }
	}

	cmp_num : U8, F64, F64 -> Bool
	cmp_num = |op, a, c|
		if op == 1 { a == c }
		else if op == 2 { a != c }
		else if op == 3 { a <= c }
		else if op == 4 { a >= c }
		else if op == 5 { a < c }
		else { a > c }

	cmp_str : U8, Str, Str -> Bool
	cmp_str = |op, a, c|
		if op == 1 {
			a == c
		} else if op == 2 {
			a != c
		} else {
			o = Machine.order(Str.to_utf8(a), Str.to_utf8(c))
			if op == 3 { o <= 0 } else if op == 4 { o >= 0 } else if op == 5 { o < 0 } else { o > 0 }
		}

	# -1, 0 or 1, byte by byte; a missing byte is a zero.
	order : List(U8), List(U8) -> I64
	order = |a, c| {
		n = if List.len(a) > List.len(c) { List.len(a) } else { List.len(c) }
		var $o = 0
		var $i = 0
		while $o == 0 and $i < n {
			x = List.get(a, $i) ?? 0
			y = List.get(c, $i) ?? 0
			$o = if x < y { -1 } else if x > y { 1 } else { 0 }
			$i = $i + 1
		}
		$o
	}

	# **A LOOP IS ITS FOR STATEMENT, NOT ITS VARIABLE.** A FOR run again
	# restarts its own loop and abandons the loops entered inside it.
	do_for : Parse.Program, M, U64, Parse.Expr, Parse.Expr, Parse.Expr -> M
	do_for = |pg, m, v, from, lim, st| {
		f = Machine.eval(pg, m, [], Machine.fresh(m), from)
		l = if Machine.stopped(f.fx) { f } else { Machine.eval(pg, m, [], f.fx, lim) }
		s = if Machine.stopped(l.fx) { l } else { Machine.eval(pg, m, [], l.fx, st) }
		x = Machine.num_of(f.v)
		limit = Machine.num_of(l.v)
		step = Machine.num_of(s.v)
		if Machine.plain(m, s.fx) {
			Machine.enter_for(pg, m, v, limit, step, x)
		} else {
			d = Machine.settle(m, s.fx)
			if d.done { d } else { Machine.enter_for(pg, d, v, limit, step, x) }
		}
	}

	# A loop whose body must not run lands past the NEXT that closes it.
	# **A HELPER GIVEN THE MACHINE IS NOT GIVEN WHAT WAS READ FROM IT.** The
	# statement after the FOR is read here, from the machine itself: passed
	# in beside it, it made every store in here copy (findings/helper-arg-copy).
	enter_for : Parse.Program, M, U64, F64, F64, F64 -> M
	enter_for = |pg, m, v, limit, step, x| {
		f = { v: v, limit: limit, step: step, after: m.pc + 1 }
		keep = Machine.outside(m.loops, m.ldepth, f.after)
		if (f.step >= 0.0 and x > f.limit) or (f.step < 0.0 and x < f.limit) {
			skip = List.get(pg.skips, m.pc) ?? Parse.none
			if skip == Parse.none {
				Machine.fail({ ..m, nums: Vec.set(m.nums, f.v, x), ldepth: keep }, Str.concat("FOR without NEXT: ", Parse.name_of(f.v)))
			} else {
				{ ..m, nums: Vec.set(m.nums, f.v, x), ldepth: keep, pc: skip }
			}
		} else {
			{ ..m, nums: Vec.set(m.nums, f.v, x), loops: Machine.push(m.loops, keep, f), ldepth: keep + 1, pc: f.after }
		}
	}

	# How many open loops lie outside the one whose body starts at `after`.
	outside : List(Frame), U64, U64 -> U64
	outside = |fs, depth, after| {
		var $keep = depth
		var $i = 0
		for fr in fs {
			if $i < depth and fr.after == after and $keep == depth { $keep = $i } else { {} }
			$i = $i + 1
		}
		$keep
	}


	# NEXT closes the innermost loop on its variable, or the innermost loop
	# when it names none; the loops above that one were left by a jump.
	do_next : M, U64, Bool -> M
	do_next = |m, v, named| {
		found = Machine.loop_on(m.loops, m.ldepth, v, named)
		if found < 0 {
			Machine.fail(m, "NEXT without FOR")
		} else {
			k = I64.to_u64_wrap(found)
			f = List.get(m.loops, k) ?? { v: 0, limit: 0.0, step: 1.0, after: 0 }
			x = Vec.get(m.nums, f.v, 0.0) + f.step
			if (f.step >= 0.0 and x > f.limit) or (f.step < 0.0 and x < f.limit) {
				{ ..m, nums: Vec.set(m.nums, f.v, x), ldepth: k, pc: m.pc + 1 }
			} else {
				{ ..m, nums: Vec.set(m.nums, f.v, x), ldepth: k + 1, pc: f.after }
			}
		}
	}

	# The innermost open loop on `v`, or the innermost of all when NEXT names
	# none; -1 when there is none.
	loop_on : List(Frame), U64, U64, Bool -> I64
	loop_on = |fs, depth, v, named| {
		var $found = -1
		var $i = 0
		for f in fs {
			if $i < depth and (!named or f.v == v) { $found = U64.to_i64_wrap($i) } else { {} }
			$i = $i + 1
		}
		$found
	}

	# ---- statements ---------------------------------------------------------------

	step : Parse.Program, M -> M
	step = |pg, m| match List.get(pg.prog, m.pc) {
		Ok(s) => Machine.exec(pg, m, s)
		Err(_) => { ..m, done: True }
	}

	# **EXEC IS A TABLE OF CALLS.** With the statements' bodies written in its
	# arms, every store after it copied a path of the vector it wrote (two
	# allocations a NEXT); with each body its own function, none does. Measured
	# by mmap count on a FOR/NEXT loop; the mechanism is Roc's, not known.
	exec : Parse.Program, M, Parse.Stmt -> M
	exec = |pg, m, s| match s {
		Nop => Machine.next(m)
		End => Machine.do_end(m)
		Stop => Machine.do_stop(pg, m)
		Bad(e, why) => Machine.do_bad(pg, m, e, why)
		Print(items, newline) => Machine.do_print(pg, m, items, newline)
		SetNum(slot, e) => Machine.do_set_num(pg, m, slot, e)
		SetStr(slot, e) => Machine.do_set_str(pg, m, slot, e)
		SetElem(slot, one, two, pair, e) => Machine.do_set_elem(pg, m, slot, one, two, pair, e)
		Goto(j) => Machine.go(m, Machine.landing(pg, m, j), Parse.none)
		Gosub(j) => Machine.go(m, Machine.landing(pg, m, j), m.pc + 1)
		Return => Machine.do_return(m)
		IfGo(l, op, r, j, line) => Machine.do_if_go(pg, m, l, op, r, j, line)
		IfThen(l, op, r, line) => Machine.do_if_then(pg, m, l, op, r, line)
		For(v, from, lim, st) => Machine.do_for(pg, m, v, from, lim, st)
		Next(v, named) => Machine.do_next(m, v, named)
		Dim(items) => Machine.parted(Machine.dim_one(pg, m, List.get(items, m.part) ?? Machine.no_item), List.len(items))
		Read(ts) => Machine.parted(Machine.read_one(pg, m, List.get(ts, m.part) ?? Machine.no_target), List.len(ts))
		Restore => Machine.do_restore(m)
		Input(prompt, ts) => Machine.do_input(pg, m, prompt, ts)
		Sleep(e) => Machine.do_sleep(pg, m, e)
		Plot(x, y, c) => Machine.do_plot(pg, m, x, y, c)
		Poke(a, v) => Machine.do_poke(pg, m, a, v)
		OnGo(e, js) => Machine.do_on(pg, m, e, js, Parse.none)
		OnGosub(e, js) => Machine.do_on(pg, m, e, js, m.pc + 1)
		Option(e) => Machine.do_option(pg, m, e)
		Def(letter) => Machine.do_def(m, letter)
	}

	# **A MICROCOMPUTER'S STOP SAYS WHERE**, as basic101 does: `Break in line N`.
	do_stop : Parse.Program, M -> M
	do_stop = |pg, m|
		if pg.ecma {
			{ ..m, done: True }
		} else {
			said = Machine.emit(m, Str.concat(Str.concat("Break in line ", I64.to_str(Machine.line_of(pg, m.pc))), "\n"))
			{ ..said, done: True }
		}

	do_end : M -> M
	do_end = |m|
		{ ..m, done: True }

	do_bad : Parse.Program, M, Parse.Expr, Str -> M
	do_bad = |pg, m, e, why| {
		r = Machine.eval(pg, m, [], Machine.fresh(m), e)
		d = Machine.settle(m, r.fx)
		if d.done { d } else { { ..d, done: True, err: why, gap: True } }
	}

	do_print : Parse.Program, M, List(Parse.Item), Bool -> M
	do_print = |pg, m, items, newline| {
		p = Machine.print_text(pg, m, items, newline)
		d = Machine.settle(Machine.emit(m, p.text), p.fx)
		if d.done { d } else if pg.live { { ..d, pc: d.pc + 1, pause: 1 } } else { Machine.next(d) }
	}

	do_set_num : Parse.Program, M, U64, Parse.Expr -> M
	do_set_num = |pg, m, slot, e| {
		r = Machine.eval(pg, m, [], Machine.fresh(m), e)
		v = Machine.num_of(r.v)
		if Machine.quiet(r.fx) and !r.fx.drew {
			{ ..m, nums: Vec.set(m.nums, slot, v), seed: r.fx.seed, pc: m.pc + 1 }
		} else if Machine.quiet(r.fx) {
			{ ..m, nums: Vec.set(m.nums, slot, v), seed: r.fx.seed, mt: r.fx.mt, mtat: r.fx.mtat, rlast: r.fx.rlast, pc: m.pc + 1 }
		} else {
			d = Machine.settle(m, r.fx)
			if d.done { d } else { { ..d, nums: Vec.set(d.nums, slot, v), pc: d.pc + 1 } }
		}
	}

	do_set_str : Parse.Program, M, U64, Parse.Expr -> M
	do_set_str = |pg, m, slot, e| {
		r = Machine.eval(pg, m, [], Machine.fresh(m), e)
		v = Machine.str_of(r.v)
		if Machine.quiet(r.fx) and !r.fx.drew {
			{ ..m, strs: Vec.set(m.strs, slot, v), seed: r.fx.seed, pc: m.pc + 1 }
		} else if Machine.quiet(r.fx) {
			{ ..m, strs: Vec.set(m.strs, slot, v), seed: r.fx.seed, mt: r.fx.mt, mtat: r.fx.mtat, rlast: r.fx.rlast, pc: m.pc + 1 }
		} else {
			d = Machine.settle(m, r.fx)
			if d.done { d } else { { ..d, strs: Vec.set(d.strs, slot, v), pc: d.pc + 1 } }
		}
	}

	do_set_elem : Parse.Program, M, U64, Parse.Expr, Parse.Expr, Bool, Parse.Expr -> M
	do_set_elem = |pg, m, slot, one, two, pair, e| {
		at = Machine.subs(pg, m, [], Machine.fresh(m), one, two, pair)
		# The array is made before the value is evaluated.
		exists = (Vec.at(m.arrs, slot)).n > 0
		fx = if exists { at.fx } else { { ..at.fx, made: List.append(at.fx.made, { slot: slot, pair: pair }) } }
		r = if Machine.stopped(fx) { { v: N(0.0), fx: fx } } else { Machine.eval(pg, m, [], fx, e) }
		x = Machine.num_of(r.v)
		if Machine.plain(m, r.fx) {
			Machine.next(Machine.set_arr(m, slot, at.i, at.j, x))
		} else {
			d = Machine.settle(m, r.fx)
			if d.done { d } else { Machine.next(Machine.set_arr(d, slot, at.i, at.j, x)) }
		}
	}

	do_return : M -> M
	do_return = |m|
		if m.rdepth == 0 {
			Machine.fail(m, "RETURN without GOSUB")
		} else {
			{ ..m, pc: List.get(m.ret, m.rdepth - 1) ?? 0, rdepth: m.rdepth - 1 }
		}

	do_if_go : Parse.Program, M, Parse.Expr, U8, Parse.Expr, Parse.Jump, U64 -> M
	do_if_go = |pg, m, l, op, r, j, line| {
		c = Machine.condition(pg, m, l, op, r)
		if Machine.plain(m, c.fx) and c.yes {
			Machine.go(m, Machine.landing(pg, m, j), Parse.none)
		} else if Machine.plain(m, c.fx) {
			{ ..m, pc: List.get(pg.firsts, line + 1) ?? List.len(pg.prog) }
		} else {
			d = Machine.settle(m, c.fx)
			if d.done { d } else if !c.yes { { ..d, pc: Machine.next_line(pg, d, line) } } else { Machine.go(d, Machine.landing(pg, d, j), Parse.none) }
		}
	}

	do_if_then : Parse.Program, M, Parse.Expr, U8, Parse.Expr, U64 -> M
	do_if_then = |pg, m, l, op, r, line| {
		c = Machine.condition(pg, m, l, op, r)
		if Machine.plain(m, c.fx) {
			{ ..m, pc: if c.yes { m.pc + 1 } else { List.get(pg.firsts, line + 1) ?? List.len(pg.prog) } }
		} else {
			d = Machine.settle(m, c.fx)
			if d.done { d } else if !c.yes { { ..d, pc: Machine.next_line(pg, d, line) } } else { Machine.next(d) }
		}
	}

	do_restore : M -> M
	do_restore = |m|
		{ ..m, dp: 0, pc: m.pc + 1 }

	do_sleep : Parse.Program, M, Parse.Expr -> M
	do_sleep = |pg, m, e| {
		r = Machine.eval(pg, m, [], Machine.fresh(m), e)
		d = Machine.settle(m, r.fx)
		ms = F64.to_i64_wrap(Machine.floor(Machine.num_of(r.v) * 1000.0 + 0.5))
		if d.done { d } else { { ..d, pc: d.pc + 1, pause: if ms < 0 { 0 } else { ms } } }
	}

	do_plot : Parse.Program, M, Parse.Expr, Parse.Expr, Parse.Expr -> M
	do_plot = |pg, m, x, y, c| {
		rx = Machine.eval(pg, m, [], Machine.fresh(m), x)
		ry = if Machine.stopped(rx.fx) { rx } else { Machine.eval(pg, m, [], rx.fx, y) }
		rc = if Machine.stopped(ry.fx) { ry } else { Machine.eval(pg, m, [], ry.fx, c) }
		d = Machine.settle(m, rc.fx)
		px = Machine.idx(Machine.num_of(rx.v))
		py = Machine.idx(Machine.num_of(ry.v))
		# Off the edge is ignored, as every plotting BASIC did.
		inside = px >= 0 and py >= 0 and I64.to_u64_wrap(px) < Machine.hires_w and I64.to_u64_wrap(py) < Machine.hires_h
		if d.done {
			d
		} else if inside {
			Machine.next(Machine.poke_at(d, Machine.hires_base + I64.to_u64_wrap(py) * Machine.hires_w + I64.to_u64_wrap(px), Machine.byte_of(Machine.num_of(rc.v))))
		} else {
			Machine.next(d)
		}
	}

	do_poke : Parse.Program, M, Parse.Expr, Parse.Expr -> M
	do_poke = |pg, m, a, v| {
		ra = Machine.eval(pg, m, [], Machine.fresh(m), a)
		rv = if Machine.stopped(ra.fx) { ra } else { Machine.eval(pg, m, [], ra.fx, v) }
		addr = Machine.addr_of(Machine.num_of(ra.v))
		byte = Machine.byte_of(Machine.num_of(rv.v))
		if Machine.plain(m, rv.fx) {
			Machine.next(Machine.poke_at(m, addr, byte))
		} else {
			d = Machine.settle(m, rv.fx)
			if d.done { d } else { Machine.next(Machine.poke_at(d, addr, byte)) }
		}
	}

	do_def : M, U64 -> M
	do_def = |m, letter|
		{ ..m, defined: List.set(m.defined, letter, True) ?? crash("DEF: no such letter"), pc: m.pc + 1 }

	byte_of : F64 -> U8
	byte_of = |x| U64.to_u8_wrap(I64.to_u64_wrap(I64.bitwise_and(F64.to_i64_wrap(Machine.floor(x)), 255)))

	# **A STATEMENT WITH A LIST STORES ONE ITEM A STEP.** READ, INPUT and DIM
	# write the machine once per variable, and a loop over the machine would
	# make the next store copy; `part` is the item next to store.
	parted : M, U64 -> M
	parted = |m, count|
		if m.done or m.waiting {
			m
		} else if m.part + 1 >= count {
			{ ..m, part: 0, pc: m.pc + 1 }
		} else {
			{ ..m, part: m.part + 1 }
		}

	no_item : Parse.DimItem
	no_item = { slot: 0, one: Parse.zero, two: Parse.zero, pair: False }

	no_target : Parse.Target
	no_target = { kind: 3, slot: 0, one: Parse.zero, two: Parse.zero, pair: False }

	# **A DIM IS A DECLARATION** (ECMA-55 15): an array that exists keeps
	# its values when control passes through its DIM again. Bounds are
	# judged first.
	dim_one : Parse.Program, M, Parse.DimItem -> M
	dim_one = |pg, m, item| {
		at = Machine.subs(pg, m, [], Machine.fresh(m), item.one, item.two, item.pair)
		d = Machine.settle(m, at.fx)
		b = Machine.bounds(d.base, at.i, at.j)
		if d.done {
			d
		} else if !b.ok {
			Machine.fail(d, Str.concat("Bad DIM bound: ", Parse.name_of(item.slot)))
		} else if (Vec.at(d.arrs, item.slot)).n > 0 {
			d
		} else {
			{ ..d, arrs: Vec.set(d.arrs, item.slot, { w: b.w, n: b.n, cells: Vec.repeat(b.n, 0.0) }), arr_count: d.arr_count + 1 }
		}
	}

	read_one : Parse.Program, M, Parse.Target -> M
	read_one = |pg, m, t|
		if t.kind == 3 {
			m
		} else if m.dp >= List.len(pg.data) {
			Machine.fail(m, "Out of DATA")
		} else {
			# ECMA-55 14.5: a string read into a numeric variable is fatal.
			raw = List.get(pg.data, m.dp) ?? ""
			if pg.ecma and t.kind != 1 and !Machine.is_numeric_datum(Str.to_utf8(raw)) {
				Machine.fail(m, "A string read into a numeric variable")
			} else {
				Machine.store(pg, { ..m, dp: m.dp + 1 }, t, Machine.unquote(raw))
			}
		}

	# **A TARGET MAY BE AN ARRAY ELEMENT**, its subscripts evaluated when it
	# is reached, after the targets before it are stored.
	store : Parse.Program, M, Parse.Target, Str -> M
	store = |pg, m, t, raw|
		if t.kind == 1 {
			{ ..m, strs: Vec.set(m.strs, t.slot, raw) }
		} else {
			rb = Str.to_utf8(raw)
			n = Machine.signed(Machine.fresh(m), rb, Parse.skip_ws(rb, 0))
			x = Machine.num_of(n.v)
			if t.kind == 0 {
				if Machine.plain(m, n.fx) {
					{ ..m, nums: Vec.set(m.nums, t.slot, x) }
				} else {
					d = Machine.settle(m, n.fx)
					if d.done { d } else { { ..d, nums: Vec.set(d.nums, t.slot, x) } }
				}
			} else {
				at = Machine.subs(pg, m, [], n.fx, t.one, t.two, t.pair)
				exists = (Vec.at(m.arrs, t.slot)).n > 0
				fx = if exists { at.fx } else { { ..at.fx, made: List.append(at.fx.made, { slot: t.slot, pair: t.pair }) } }
				if Machine.plain(m, fx) {
					Machine.set_arr(m, t.slot, at.i, at.j, x)
				} else {
					d = Machine.settle(m, fx)
					if d.done { d } else { Machine.set_arr(d, t.slot, at.i, at.j, x) }
				}
			}
		}

	# **INPUT PRINTS `? ` AND ECHOES THE LINE**, as the captured games show.
	# One INPUT takes one line, split on commas between its variables.
	do_input : Parse.Program, M, Str, List(Parse.Target) -> M
	do_input = |pg, m, prompt, ts|
		if m.part > 0 {
			Machine.parted(Machine.store(pg, m, List.get(ts, m.part) ?? Machine.no_target, Machine.reply_value(pg, m, m.part)), List.len(ts))
		} else {
			# The prompt goes out once, though the statement runs again when
			# its line arrives.
			m0 = if m.asked { m } else { { ..Machine.emit(Machine.emit(m, prompt), "? "), asked: True } }
			if m0.ip >= List.len(m0.inp) {
				{ ..m0, waiting: True }
			} else {
				line = List.get(m0.inp, m0.ip) ?? ""
				m1 = Machine.emit(Machine.emit(m0, line), "\n")
				vals = if pg.ecma { Machine.reply_items(Str.to_utf8(line), 0, []) } else { Machine.split_commas(Str.to_utf8(line), 0, []) }
				# **NOTHING IS ASSIGNED UNTIL THE WHOLE REPLY FITS** (ECMA-55
				# 13.5); a reply that does not is reported and asked again.
				why = if pg.ecma { Machine.reply_fault(ts, vals) } else { "" }
				taken = { ..m1, ip: m1.ip + 1, asked: False, reply: vals }
				if why != "" {
					Machine.emit(taken, Str.concat(Str.concat("?", why), "\n"))
				} else if List.is_empty(ts) {
					Machine.next(taken)
				} else {
					Machine.parted(Machine.store(pg, taken, List.get(ts, 0) ?? Machine.no_target, Machine.reply_value(pg, taken, 0)), List.len(ts))
				}
			}
		}

	reply_value : Parse.Program, M, U64 -> Str
	reply_value = |pg, m, k| {
		raw = List.get(m.reply, k) ?? ""
		if pg.ecma { Machine.unquote(raw) } else { raw }
	}

	# ON <expr> GOTO or GOSUB picks the nth line from one; outside the list
	# is an exception.
	do_on : Parse.Program, M, Parse.Expr, List(Parse.Jump), U64 -> M
	do_on = |pg, m, e, js, back| {
		r = Machine.eval(pg, m, [], Machine.fresh(m), e)
		d = Machine.settle(m, r.fx)
		n = Machine.idx(Machine.num_of(r.v))
		if d.done {
			d
		} else if n < 1 or I64.to_u64_wrap(n) > List.len(js) {
			Machine.fail(d, "ON index out of range")
		} else {
			Machine.go(d, Machine.landing(pg, d, List.get(js, I64.to_u64_wrap(n - 1)) ?? Missing(0)), back)
		}
	}

	do_option : Parse.Program, M, Parse.Expr -> M
	do_option = |pg, m, e| {
		r = Machine.eval(pg, m, [], Machine.fresh(m), e)
		d = Machine.settle(m, r.fx)
		n = Machine.idx(Machine.num_of(r.v))
		if d.done {
			d
		} else if n > 1 or n < 0 {
			Machine.fail(d, "OPTION BASE must be 0 or 1")
		} else if d.arr_count > 0 {
			Machine.fail(d, "OPTION BASE after an array is used")
		} else {
			{ ..d, base: I64.to_u64_wrap(n), pc: d.pc + 1 }
		}
	}

	# ---- an INPUT reply, as ECMA-55 13 reads it -------------------------------------

	# Split on the commas outside quotes, outer spaces dropped, quotes kept.
	reply_items : List(U8), U64, List(Str) -> List(Str)
	reply_items = |b, i, acc| {
		s = Parse.skip_ws(b, i)
		e = Parse.item_end(b, if Parse.byte(b, s) == 34 { Parse.quote_end(b, s + 1, List.len(b)) } else { s })
		more = List.append(acc, Parse.trim_right(b, s, e))
		if e >= List.len(b) { more } else { Machine.reply_items(b, e + 1, more) }
	}

	split_commas : List(U8), U64, List(Str) -> List(Str)
	split_commas = |b, i, acc| {
		e = Parse.item_end(b, i)
		more = List.append(acc, Parse.trim_right(b, Parse.skip_ws(b, i), e))
		if e >= List.len(b) { more } else { Machine.split_commas(b, e + 1, more) }
	}

	# Why a reply does not fit the variables, or "" when it does.
	reply_fault : List(Parse.Target), List(Str) -> Str
	reply_fault = |ts, vals| {
		var $why = ""
		var $k = 0
		for t in ts {
			if $why == "" {
				datum = Str.to_utf8(List.get(vals, $k) ?? "")
				item =
					if $k >= List.len(vals) {
						"Too few items in the reply"
					} else if t.kind == 1 {
						if Machine.is_string_datum(datum) { "" } else { "A reply item is not a string" }
					} else if !Machine.is_numeric_datum(datum) {
						"A reply item is not a number"
					} else if Machine.datum_overflows(datum) {
						"Overflow in a reply item"
					} else {
						""
					}
				# After the last variable, whatever its kind: items left over.
				$why = if item == "" and $k + 1 == List.len(ts) and $k + 1 < List.len(vals) { "Too many items in the reply" } else { item }
			} else {
				{}
			}
			$k = $k + 1
		}
		$why
	}

	# A numeric constant and nothing else.
	is_numeric_datum : List(U8) -> Bool
	is_numeric_datum = |b| {
		s = Machine.sign_len(b)
		w = Parse.digits_end(b, s)
		f = if Parse.byte(b, w) == 46 { Parse.digits_end(b, w + 1) } else { w }
		past =
			if Parse.byte(b, f) != 69 {
				f
			} else {
				g = if Parse.byte(b, f + 1) == 45 or Parse.byte(b, f + 1) == 43 { f + 2 } else { f + 1 }
				d = Parse.digits_end(b, g)
				if d > g { d } else { 0 }
			}
		(w > s or f > w + 1) and past > 0 and past == List.len(b)
	}

	sign_len : List(U8) -> U64
	sign_len = |b| if Parse.byte(b, 0) == 45 or Parse.byte(b, 0) == 43 { 1 } else { 0 }

	datum_overflows : List(U8) -> Bool
	datum_overflows = |b| Parse.numeral(b, Machine.sign_len(b)).v > Machine.huge

	# Quoted with no quote inside, or letters, digits, `+ - .` and spaces.
	is_string_datum : List(U8) -> Bool
	is_string_datum = |b| {
		n = List.len(b)
		if n >= 2 and Parse.byte(b, 0) == 34 and Parse.byte(b, n - 1) == 34 {
			!List.contains(List.sublist(b, { start: 1, len: n - 2 }), 34)
		} else {
			n > 0 and List.all(b, |c| Parse.is_alpha(c) or Parse.is_digit(c) or c == 43 or c == 45 or c == 46 or c == 32)
		}
	}

	unquote : Str -> Str
	unquote = |t|
		if Str.starts_with(t, "\"") and Str.ends_with(t, "\"") and Str.count_utf8_bytes(t) >= 2 {
			b = Str.to_utf8(t)
			Parse.text_of(b, 1, List.len(b) - 1)
		} else {
			t
		}

	# ---- running --------------------------------------------------------------------

	# **THE RUN LOOP AS ONE PURE FUNCTION.** Statements run until one needs
	# the world -- a line of input, a SLEEP, the end, a stop -- or the fuel
	# runs out, and the machine is answered as it stands there.
	machine_state_at_next_effect : Parse.Program, M -> M
	machine_state_at_next_effect = |pg, m| {
		var $m = m
		while !($m.done or $m.waiting or $m.pause > 0 or $m.fuel <= 0) {
			$m = Machine.step(pg, { ..$m, fuel: $m.fuel - 1, steps: $m.steps + 1 })
		}
		$m
	}

	# **DIM AND OPTION ARE DECLARATIONS IN ECMA-55** (15), applied in line
	# order before the first statement. This loop runs once, before the run.
	declared : Parse.Program, M -> M
	declared = |pg, m|
		if !pg.ecma {
			m
		} else {
			var $m = m
			for d in pg.decls {
				if $m.done {
					{}
				} else {
					match d {
						DeclDim(items) => {
							for item in items {
								$m = if $m.done { $m } else { Machine.dim_one(pg, $m, item) }
							}
						}
						DeclOption(e) => {
							$m = { ..Machine.do_option(pg, $m, e), pc: 0 }
						}
						DeclBad(why) => {
							$m = { ..$m, done: True, err: why, gap: True }
						}
					}
				}
			}
			$m
		}

	# **THE BATCH DOOR.** A SLEEP takes no time, and a yield is refuelled a
	# bounded number of times before the program is called non-terminating.
	batch : Parse.Program, M, I64 -> M
	batch = |pg, m, tanks| {
		var $m = m
		var $t = tanks
		while ($m.pause > 0 and !$m.done) or ($t > 0 and !$m.done and !$m.waiting and $m.fuel <= 0) {
			if $m.pause > 0 {
				$m = Machine.machine_state_at_next_effect(pg, { ..$m, pause: 0 })
			} else {
				$m = Machine.machine_state_at_next_effect(pg, { ..$m, fuel: pg.tank })
				$t = $t - 1
			}
		}
		$m
	}

	run : Str, List(Str), U64 -> Str
	run = |src, inp, seed| Machine.run_in(src, inp, seed, False)

	run_ecma : Str, List(Str), U64 -> Str
	run_ecma = |src, inp, seed| Machine.run_in(src, inp, seed, True)

	refuse : Listing.Rejection -> M
	refuse = |bad| {
		why = if bad.num < 0 { bad.why } else { Str.concat(Str.concat(Str.concat(bad.why, " (line "), I64.to_str(bad.num)), ")") }
		{ ..Machine.new([], 1), done: True, rejected: True, err: why }
	}

	run_in : Str, List(Str), U64, Bool -> Str
	run_in = |src, inp, seed, ecma| Machine.run_measured(src, inp, seed, ecma).transcript

	# The transcript, the statements the run executed, and how many statements
	# the program has.
	run_measured : Str, List(Str), U64, Bool -> { transcript : Str, steps : I64, statements : U64 }
	run_measured = |src, inp, seed, ecma| {
		line_fault = if ecma { Listing.check(src) } else { { why: "", num: -1 } }
		bad = if ecma and line_fault.why == "" { Program.check(src) } else { line_fault }
		pg = Parse.load(if bad.why != "" { "" } else { src }, ecma)
		m = if bad.why != "" { Machine.refuse(bad) } else { Machine.batch(pg, Machine.machine_state_at_next_effect(pg, Machine.declared(pg, Machine.new(inp, seed))), 10) }
		text =
			if !ecma and !m.gap and Str.starts_with(m.err, "No such line: ") {
				# basic101's words for a jump to a line that is not there.
				Str.concat(Machine.transcript({ ..m, err: "" }), Str.concat(Str.concat(Str.concat("Error on line ", I64.to_str(Machine.line_of(pg, m.pc))), Str.concat(": Undefined line number ", Str.drop_prefix(m.err, "No such line: "))), "\n"))
			} else if m.waiting and !ecma {
				# **A MICROCOMPUTER'S BATCH RUN ENDS AS basic101's DOES** when its
				# replies run out: the games' captures are basic101's output.
				Str.concat(Machine.transcript(m), Str.concat(Str.concat("\nError on line ", I64.to_str(Machine.line_of(pg, m.pc))), ": No more input\n"))
			} else {
			Machine.transcript(
				if m.waiting {
					{ ..m, done: True, gap: True, err: "Out of input" }
				} else if m.fuel <= 0 {
					{ ..m, done: True, gap: True, err: "Did not terminate" }
				} else {
					m
				},
			)
			}
		{ transcript: text, steps: m.steps, statements: List.len(pg.prog) }
	}

	# The line number of the statement at `pc`: the last line whose first
	# statement is at or before it.
	line_of : Parse.Program, U64 -> I64
	line_of = |pg, pc| {
		var $k = 0
		var $i = 0
		for first in pg.firsts {
			if first <= pc { $k = $i } else { {} }
			$i = $i + 1
		}
		List.get(pg.lines, $k) ?? 0
	}

	# **A REPORTED EXCEPTION IS NOT A HALT**; what stops gets its own marker.
	transcript : M -> Str
	transcript = |m| {
		body = Str.join_with(m.out, "")
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

	# ---- the suspended machine, for the page ------------------------------------------

	start : Str, U64 -> Run
	start = |src, seed| {
		pg = { ..Parse.load(src, False), live: True, tank: Machine.page_tank }
		{ pg: pg, m: Machine.machine_state_at_next_effect(pg, { ..Machine.new([], seed), fuel: Machine.page_tank }) }
	}

	# **THE FUEL IS PER RESUME.** A sleeper wakes; a machine waiting for a
	# line is given this one; a line typed ahead is kept.
	resume : Run, Str -> Run
	resume = |r, line| {
		{ pg, m } = r
		resumed =
			if m.done {
				m
			} else if m.pause > 0 or (m.fuel <= 0 and !m.waiting) {
				Machine.machine_state_at_next_effect(pg, { ..m, pause: 0, fuel: pg.tank })
			} else {
				Machine.machine_state_at_next_effect(pg, { ..m, inp: List.append(m.inp, line), waiting: False, fuel: pg.tank })
			}
		{ pg: pg, m: resumed }
	}

	pause_ms : M -> I64
	pause_ms = |m| m.pause

	steps_taken : M -> I64
	steps_taken = |m| m.steps

	# 0 finished, 1 waiting for a line, 2 exception, 3 unbuilt form,
	# 4 sleeping, 5 yielded, 6 rejected before it ran.
	status : M -> I64
	status = |m|
		if m.rejected { 6 } else if m.waiting { 1 } else if m.pause > 0 { 4 } else if m.fuel <= 0 { 5 } else if m.gap { 3 } else if m.err != "" { 2 } else { 0 }

	# The screen codes and colours in the order shown, then the framebuffer.
	screen : M -> List(U8)
	screen = |m| {
		var $codes = List.with_capacity(2000)
		var $colours = List.with_capacity(1000)
		var $row = 0
		while $row < Machine.screen_h {
			start_at = Machine.cell(Machine.row_at(m.top, $row), 0)
			$codes = List.concat($codes, List.sublist(m.scr, { start: start_at, len: 40 }))
			$colours = List.concat($colours, List.sublist(m.col_ram, { start: start_at, len: 40 }))
			$row = $row + 1
		}
		List.concat(List.concat($codes, $colours), m.pix)
	}

	# ---- memory -----------------------------------------------------------------------

	# **WIDER THAN A REAL MACHINE, BECAUSE THE FRAMEBUFFER IS**: 24 bits.
	addr_of : F64 -> U64
	addr_of = |x| I64.to_u64_wrap(I64.bitwise_and(F64.to_i64_wrap(Machine.floor(x)), 16777215))

	# **THE SMALL WINDOWS ARE MATCHED FIRST**, the framebuffer last.
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

	# A screen address as the cell it is kept in.
	kept : M, U64 -> U64
	kept = |m, i| Machine.cell(Machine.row_at(m.top, U64.to_i64_wrap(U64.div_trunc_by(i, 40))), U64.to_i64_wrap(U64.rem_by(i, 40)))

	peek : M, U64 -> U8
	peek = |m, a|
		if a >= Machine.screen_base and a < Machine.screen_base + Machine.screen_cells {
			List.get(m.scr, Machine.kept(m, a - Machine.screen_base)) ?? 0
		} else if a >= Machine.colour_base and a < Machine.colour_base + Machine.screen_cells {
			List.get(m.col_ram, Machine.kept(m, a - Machine.colour_base)) ?? 0
		} else if a >= Machine.hires_base and a < Machine.hires_base + Machine.hires_cells {
			List.get(m.pix, a - Machine.hires_base) ?? 0
		} else {
			Vec.get(m.mem, a, 0)
		}

	poke_at : M, U64, U8 -> M
	poke_at = |m, a, v|
		if a >= Machine.screen_base and a < Machine.screen_base + Machine.screen_cells {
			{ ..m, scr: List.set(m.scr, Machine.kept(m, a - Machine.screen_base), v) ?? crash("poke: screen") }
		} else if a >= Machine.colour_base and a < Machine.colour_base + Machine.screen_cells {
			{ ..m, col_ram: List.set(m.col_ram, Machine.kept(m, a - Machine.colour_base), v) ?? crash("poke: colour") }
		} else if a >= Machine.hires_base and a < Machine.hires_base + Machine.hires_cells {
			lit = if m.drew { m.pix } else { List.repeat(0, Machine.hires_cells) }
			{ ..m, pix: List.set(lit, a - Machine.hires_base, v) ?? crash("poke: hires"), drew: True }
		} else {
			{ ..m, mem: Vec.set(m.mem, a, v) }
		}
}
