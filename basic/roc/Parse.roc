# A BASIC listing as the program the machine runs.
#
# **EACH STATEMENT IS PARSED ONCE.** The machine never reads source text: a
# statement is a `Stmt`, its expressions are trees, its numerals are
# numbers, and a jump to a constant line is a statement index -- all made
# before the first statement runs.
#
# **A STATEMENT'S POSITION IS ITS INDEX.** The statements of every line are
# one list, so the statement after a GOSUB is the next index, whether it
# follows a colon or starts the next line. An IF whose condition fails goes
# to the first statement of the next line.
#
# **A VARIABLE'S NAME IS ITS SLOT.** A name is a letter, an optional digit
# and an optional `$`: 26 x 11 x 2 = 572 names of each kind, and each one's
# slot is computed from its letters, so no dictionary is built or consulted.
#
# **A FAULT PARSES TO WHAT RUNS BEFORE IT.** A malformed statement or
# expression becomes the evaluations ahead of the fault, then a node that
# stops the machine with the reason, so what a program prints before an
# unsupported form still prints.

Parse :: [].{
	Expr := [
		Num(F64),
		Text(Str),
		NumVar(U64),
		StrVar(U64),
		# An array element: the array's slot, the subscripts, whether there are two.
		Elem(U64, Expr, Expr, Bool),
		# A string where a number is read is zero.
		AsNum(Expr),
		Neg(Expr),
		Add(Expr, Expr),
		Sub(Expr, Expr),
		Mul(Expr, Expr),
		Div(Expr, Expr),
		Pow(Expr, Expr),
		# EXT: `+` joins two strings; the right side is any expression, as text.
		Cat(Expr, Expr),
		# A numeric function by its code (`fn_code`) and its argument.
		Call(U8, Expr),
		Rnd,
		Chr(Expr),
		StrOf(Expr),
		Left(Expr, Expr),
		Right(Expr, Expr),
		Mid(Expr, Expr),
		Mid3(Expr, Expr, Expr),
		# DEF FNx: the letter (0..25), whether it takes an argument, the argument.
		CallDef(U64, Bool, Expr),
		# The first evaluated for what it does, then the second.
		Seq(Expr, Expr),
		# An unsupported form: the machine stops here.
		Fail(Str),
	]

	Item : [Semi, Comma, Tab(Expr), Show(Expr)]

	# `Line` is a line number as written; loading resolves it to `To` (a
	# statement index) or `Missing`.
	Jump : [To(U64), Missing(I64), Line(I64), Computed(Expr)]

	# kind 0 a number, 1 a string, 2 an array element.
	Target : { kind : U8, slot : U64, one : Expr, two : Expr, pair : Bool }

	DimItem : { slot : U64, one : Expr, two : Expr, pair : Bool }

	# The relational operators, by code: 1 =, 2 <>, 3 <=, 4 >=, 5 <, 6 >.
	Stmt : [
		Nop,
		End,
		# The expression runs, then the machine stops for the reason (the
		# expression's own, when it stops first).
		Bad(Expr, Str),
		# The items, and whether the line ends with a newline.
		Print(List(Item), Bool),
		SetNum(U64, Expr),
		SetStr(U64, Expr),
		SetElem(U64, Expr, Expr, Bool, Expr),
		Goto(Jump),
		Gosub(Jump),
		Return,
		# The line index rides along: a failed condition goes to the next line.
		IfGo(Expr, U8, Expr, Jump, U64),
		IfThen(Expr, U8, Expr, U64),
		# The loop variable's slot, from, to, step.
		For(U64, Expr, Expr, Expr),
		# The variable's slot, and whether NEXT names one.
		Next(U64, Bool),
		Dim(List(DimItem)),
		Read(List(Target)),
		Restore,
		# The prompt, empty when there is none.
		Input(Str, List(Target)),
		Sleep(Expr),
		Plot(Expr, Expr, Expr),
		Poke(Expr, Expr),
		OnGo(Expr, List(Jump)),
		OnGosub(Expr, List(Jump)),
		Option(Expr),
		# DEF FNx runs: the letter.
		Def(U64),
	]

	# ECMA-55's declarations, in line order: applied before the first
	# statement runs.
	Decl : [DeclDim(List(DimItem)), DeclOption(Expr), DeclBad(Str)]

	# A user function by letter. `known` when a DEF for it is in the listing.
	FnDef : { known : Bool, param : Bool, pslot : U64, body : Expr }

	Program : {
		prog : List(Stmt),
		# Line numbers in order, and each line's first statement.
		lines : List(I64),
		firsts : List(U64),
		# For a FOR statement, the index past the NEXT that closes it;
		# `none` for every other statement and for a FOR with no NEXT.
		skips : List(U64),
		data : List(Str),
		decls : List(Decl),
		fns : List(FnDef),
	}

	Line : { num : I64, src : List(U8) }

	# What an expression parses to: the tree, where it ended, and whether it
	# ended cleanly. When it did not, the tree stops the machine.
	P : { e : Expr, at : U64, ok : Bool }

	Subs : { one : Expr, two : Expr, pair : Bool, at : U64, ok : Bool }

	# One statement: where it ended, whether its line ends with it, and
	# whether an IF's THEN statement follows at `at`.
	St : { stmt : Stmt, at : U64, stop : Bool, then : Bool, letter : U64, def : FnDef }

	Cx : { ecma : Bool, fns : List(FnDef) }

	names : U64
	names = 572

	none : U64
	none = 18446744073709551615

	zero : Expr
	zero = Num(0.0)

	no_fn : FnDef
	no_fn = { known: False, param: False, pslot: 0, body: Num(0.0) }

	# ---- the listing --------------------------------------------------------

	load : Str, Bool -> Program
	load = |src, ecma| {
		ls = Parse.sort_lines(Parse.load_from(Str.to_utf8(src), 0, []))
		cx = { ecma: ecma, fns: Parse.def_heads(ls) }
		var $prog = []
		var $marks = []
		var $firsts = []
		var $lines = []
		var $fns = cx.fns
		var $bodied = List.repeat(False, 26)
		var $data = []
		var $decls = []
		var $line = 0
		for l in ls {
			$firsts = List.append($firsts, List.len($prog))
			$lines = List.append($lines, l.num)
			got = Parse.line_from(l.src, 0, $line, True, cx, { stmts: [], marks: [], defs: [] })
			$prog = if List.is_empty(got.stmts) { List.append($prog, Nop) } else { List.concat($prog, got.stmts) }
			$marks = if List.is_empty(got.marks) { List.append($marks, 0) } else { List.concat($marks, got.marks) }
			for d in got.defs {
				if !(List.get($bodied, d.letter) ?? True) {
					$fns = List.set($fns, d.letter, d.def) ?? $fns
					$bodied = List.set($bodied, d.letter, True) ?? $bodied
				} else {
					{}
				}
			}
			$data = Parse.collect_data(l.src, $data)
			$decls = Parse.declaration(l.src, cx, $decls)
			$line = $line + 1
		}
		lines = $lines
		firsts = $firsts
		{
			prog: List.map($prog, |s| Parse.resolve(s, lines, firsts)),
			lines: lines,
			firsts: firsts,
			skips: Parse.skips_of($marks),
			data: $data,
			decls: $decls,
			fns: $fns,
		}
	}

	# Split on newlines, drop lines with no number, read the number.
	load_from : List(U8), U64, List(Line) -> List(Line)
	load_from = |b, i, acc|
		if i >= List.len(b) {
			acc
		} else {
			e = Parse.eol(b, i)
			line = Parse.one_line(b, i, e)
			Parse.load_from(b, e + 1, if line.num < 0 { acc } else { List.append(acc, line) })
		}

	eol : List(U8), U64 -> U64
	eol = |b, i| if i >= List.len(b) or Parse.byte(b, i) == 10 { i } else { Parse.eol(b, i + 1) }

	one_line : List(U8), U64, U64 -> Line
	one_line = |b, i, e| {
		s = Parse.skip_ws(b, i)
		d = Parse.digits_end(b, s)
		if d == s {
			{ num: -1, src: [] }
		} else {
			{ num: Parse.digits_val(b, s, d, 0), src: Parse.line_bytes(b, Parse.skip_ws(b, d), e, []) }
		}
	}

	# The statement text, upper-cased outside quotes, with a DOS listing's
	# carriage return dropped.
	line_bytes : List(U8), U64, U64, List(U8) -> List(U8)
	line_bytes = |b, i, e, acc|
		if i >= e {
			acc
		} else {
			c = Parse.byte(b, i)
			if c == 13 {
				Parse.line_bytes(b, i + 1, e, acc)
			} else if c == 34 {
				j = Parse.quote_end(b, i + 1, e)
				Parse.line_bytes(b, j, e, List.concat(acc, List.sublist(b, { start: i, len: j - i })))
			} else {
				Parse.line_bytes(b, i + 1, e, List.append(acc, Parse.upper(c)))
			}
		}

	# Lines in number order; equal numbers keep their order.
	sort_lines : List(Line) -> List(Line)
	sort_lines = |ls| if Parse.in_order(ls, 1) { ls } else { Parse.sort_from(ls, 0, []) }

	in_order : List(Line), U64 -> Bool
	in_order = |ls, i|
		if i >= List.len(ls) {
			True
		} else if (List.get(ls, i - 1) ?? { num: -1, src: [] }).num > (List.get(ls, i) ?? { num: -1, src: [] }).num {
			False
		} else {
			Parse.in_order(ls, i + 1)
		}

	sort_from : List(Line), U64, List(Line) -> List(Line)
	sort_from = |ls, i, acc|
		if i >= List.len(ls) {
			acc
		} else {
			Parse.sort_from(ls, i + 1, Parse.insert_line(acc, List.get(ls, i) ?? { num: -1, src: [] }, 0))
		}

	insert_line : List(Line), Line, U64 -> List(Line)
	insert_line = |ls, l, i|
		if i >= List.len(ls) {
			List.append(ls, l)
		} else if (List.get(ls, i) ?? l).num > l.num {
			List.concat(List.append(List.sublist(ls, { start: 0, len: i }), l), List.sublist(ls, { start: i, len: List.len(ls) - i }))
		} else {
			Parse.insert_line(ls, l, i + 1)
		}

	# The first line numbered `n`, or -1: `lines` is in order.
	find_line : List(I64), I64 -> I64
	find_line = |lines, n| {
		k = Parse.lower_bound(lines, n, 0, List.len(lines))
		if (List.get(lines, k) ?? (n - 1)) == n { U64.to_i64_wrap(k) } else { -1 }
	}

	lower_bound : List(I64), I64, U64, U64 -> U64
	lower_bound = |xs, n, lo, hi|
		if lo >= hi {
			lo
		} else {
			mid = lo + U64.div_trunc_by(hi - lo, 2)
			if (List.get(xs, mid) ?? n) < n { Parse.lower_bound(xs, n, mid + 1, hi) } else { Parse.lower_bound(xs, n, lo, mid) }
		}

	resolve : Stmt, List(I64), List(U64) -> Stmt
	resolve = |s, lines, firsts| match s {
		Goto(j) => Goto(Parse.to(j, lines, firsts))
		Gosub(j) => Gosub(Parse.to(j, lines, firsts))
		IfGo(l, op, r, j, line) => IfGo(l, op, r, Parse.to(j, lines, firsts), line)
		OnGo(e, js) => OnGo(e, List.map(js, |j| Parse.to(j, lines, firsts)))
		OnGosub(e, js) => OnGosub(e, List.map(js, |j| Parse.to(j, lines, firsts)))
		_ => s
	}

	to : Jump, List(I64), List(U64) -> Jump
	to = |j, lines, firsts| match j {
		Line(n) => {
			k = Parse.find_line(lines, n)
			if k < 0 { Missing(n) } else { To(List.get(firsts, I64.to_u64_wrap(k)) ?? 0) }
		}
		_ => j
	}

	# **A FOR IS PAIRED WITH A NEXT BY COUNTING, NOT BY NAME.** A loop whose
	# body must not run lands past the NEXT that closes it: FORs and NEXTs
	# that begin a line or follow a colon, matched like brackets. Mark 1 is
	# such a FOR, 2 such a NEXT.
	skips_of : List(U8) -> List(U64)
	skips_of = |marks| {
		var $skips = List.repeat(Parse.none, List.len(marks))
		var $open = []
		var $i = 0
		for mark in marks {
			if mark == 1 {
				$open = List.append($open, $i)
			} else if mark == 2 and !List.is_empty($open) {
				f = List.last($open) ?? 0
				$skips = List.set($skips, f, $i + 1) ?? $skips
				$open = List.drop_last($open, 1)
			} else {
				{}
			}
			$i = $i + 1
		}
		$skips
	}

	# DATA is collected in line order, from the DATA that begins a line.
	collect_data : List(U8), List(Str) -> List(Str)
	collect_data = |b, acc| {
		j = Parse.kw(b, 0, "DATA")
		if j == 0 { acc } else { Parse.data_items(b, j, acc) }
	}

	# A datum keeps its quotes, so READ can tell a string from a number.
	data_items : List(U8), U64, List(Str) -> List(Str)
	data_items = |b, i, acc| {
		j = Parse.skip_ws(b, i)
		if j >= List.len(b) {
			acc
		} else if Parse.byte(b, j) == 34 {
			e = Parse.quote_end(b, j + 1, List.len(b))
			k = Parse.skip_ws(b, e)
			Parse.data_items(b, if Parse.byte(b, k) == 44 { k + 1 } else { List.len(b) }, List.append(acc, Parse.text_of(b, j, e)))
		} else {
			e = Parse.item_end(b, j)
			Parse.data_items(b, e + 1, List.append(acc, Parse.trim_right(b, j, e)))
		}
	}

	item_end : List(U8), U64 -> U64
	item_end = |b, i| if i >= List.len(b) or Parse.byte(b, i) == 44 { i } else { Parse.item_end(b, i + 1) }

	trim_right : List(U8), U64, U64 -> Str
	trim_right = |b, from, to|
		if to > from and Parse.byte(b, U64.minus_wrap(to, 1)) == 32 {
			Parse.trim_right(b, from, U64.minus_wrap(to, 1))
		} else {
			Parse.text_of(b, from, to)
		}

	# The DIM or OPTION that begins a line.
	declaration : List(U8), Cx, List(Decl) -> List(Decl)
	declaration = |b, cx, acc| {
		d = Parse.kw(b, 0, "DIM")
		o = Parse.kw(b, 0, "OPTION")
		if d != 0 {
			List.append(acc, DeclDim(Parse.dim_items(b, d, cx, []).items))
		} else if o != 0 {
			j = Parse.kw(b, o, "BASE")
			if j == o { List.append(acc, DeclBad("Expected BASE")) } else { List.append(acc, DeclOption(Parse.sum(b, j, cx).e)) }
		} else {
			acc
		}
	}

	# ---- user functions -------------------------------------------------------

	# The first DEF of each letter, read before anything else is parsed, so a
	# call knows whether its function takes an argument wherever the DEF is.
	def_heads : List(Line) -> List(FnDef)
	def_heads = |ls| {
		var $fns = List.repeat(Parse.no_fn, 26)
		for l in ls {
			$fns = Parse.heads_in(l.src, 0, $fns)
		}
		$fns
	}

	heads_in : List(U8), U64, List(FnDef) -> List(FnDef)
	heads_in = |b, i, fns| {
		j = Parse.skip_ws(b, i)
		if j >= List.len(b) {
			fns
		} else {
			w = Parse.word_end(b, j)
			h = if Parse.text_of(b, j, w) == "DEF" { Parse.def_head(b, w) } else { Parse.no_head }
			first = h.letter < 26 and !(List.get(fns, h.letter) ?? Parse.no_fn).known
			next = if first { List.set(fns, h.letter, { known: True, param: h.param, pslot: h.pslot, body: Parse.zero }) ?? fns } else { fns }
			e = Parse.stmt_end(b, j)
			if e >= List.len(b) { next } else { Parse.heads_in(b, e + 1, next) }
		}
	}

	# A DEF's head: the letter (26 when the name is not FN and a letter, or
	# the DEF is malformed), its parameter, and where its body starts. `why`
	# is the fault.
	Head : { letter : U64, param : Bool, pslot : U64, body : U64, why : Str }

	no_head : Head
	no_head = { letter: 26, param: False, pslot: 0, body: 0, why: "" }

	def_head : List(U8), U64 -> Head
	def_head = |b, w| {
		j = Parse.skip_ws(b, w)
		e = Parse.word_end(b, j)
		k = Parse.text_of(b, j, e)
		letter = if Str.starts_with(k, "FN") and Str.count_utf8_bytes(k) == 3 { Parse.u64(Parse.byte(b, j + 2)) - 65 } else { 26 }
		q = Parse.skip_ws(b, e)
		if Parse.byte(b, q) == 61 {
			{ letter: letter, param: False, pslot: 0, body: q + 1, why: "" }
		} else if Parse.byte(b, q) != 40 {
			{ ..Parse.no_head, why: "Expected ( after DEF" }
		} else {
			pm = Parse.name_at(b, q + 1)
			c = Parse.skip_ws(b, pm.at)
			eq = Parse.skip_ws(b, c + 1)
			if Parse.byte(b, c) != 41 or Parse.byte(b, eq) != 61 {
				{ ..Parse.no_head, why: "Malformed DEF" }
			} else {
				{ letter: letter, param: pm.found, pslot: pm.slot, body: eq + 1, why: "" }
			}
		}
	}

	# ---- a line's statements --------------------------------------------------

	Got : { stmts : List(Stmt), marks : List(U8), defs : List({ letter : U64, def : FnDef }) }

	# `lead` when the statement at `at` begins the line or follows a colon.
	line_from : List(U8), U64, U64, Bool, Cx, Got -> Got
	line_from = |b, at, line, lead, cx, acc| {
		i = Parse.skip_ws(b, at)
		if i >= List.len(b) {
			acc
		} else if Parse.byte(b, i) == 58 {
			Parse.line_from(b, i + 1, line, True, cx, acc)
		} else {
			w = Parse.word_end(b, i)
			k = Parse.text_of(b, i, w)
			s = Parse.statement(b, i, k, w, line, cx)
			mark = if !lead { 0 } else if k == "FOR" { 1 } else if k == "NEXT" { 2 } else { 0 }
			got = {
				stmts: List.append(acc.stmts, s.stmt),
				marks: List.append(acc.marks, mark),
				defs: if s.letter < 26 { List.append(acc.defs, { letter: s.letter, def: s.def }) } else { acc.defs },
			}
			if s.then {
				Parse.line_from(b, s.at, line, False, cx, got)
			} else if s.stop {
				got
			} else {
				j = Parse.skip_ws(b, s.at)
				if Parse.byte(b, j) == 58 { Parse.line_from(b, j + 1, line, True, cx, got) } else { got }
			}
		}
	}

	# A statement that goes on to the next one, and one that ends its line.
	on : Stmt, U64 -> St
	on = |stmt, at| { stmt: stmt, at: at, stop: False, then: False, letter: 26, def: Parse.no_fn }

	last : Stmt -> St
	last = |stmt| { stmt: stmt, at: 0, stop: True, then: False, letter: 26, def: Parse.no_fn }

	statement : List(U8), U64, Str, U64, U64, Cx -> St
	statement = |b, i, k, w, line, cx|
		if k == "REM" or k == "DATA" {
			Parse.last(Nop)
		} else if k == "END" or k == "STOP" {
			Parse.last(End)
		} else if k == "PRINT" {
			p = Parse.print_items(b, w, True, cx, [])
			Parse.on(Print(p.items, p.newline), p.at)
		} else if k == "LET" {
			Parse.st_let(b, w, cx)
		} else if k == "GOTO" or k == "GO" {
			r = Parse.sum(b, if k == "GO" { Parse.kw(b, w, "TO") } else { w }, cx)
			if !r.ok { Parse.last(Bad(r.e, "")) } else { Parse.last(Goto(Parse.jump_of(r.e))) }
		} else if k == "IF" {
			Parse.st_if(b, w, line, cx)
		} else if k == "FOR" {
			Parse.st_for(b, w, cx)
		} else if k == "NEXT" {
			nm = Parse.name_at(b, w)
			Parse.on(Next(nm.slot, nm.found), if nm.found { nm.at } else { w })
		} else if k == "GOSUB" {
			r = Parse.sum(b, w, cx)
			if !r.ok { Parse.last(Bad(r.e, "")) } else { Parse.on(Gosub(Parse.jump_of(r.e)), r.at) }
		} else if k == "RETURN" {
			Parse.last(Return)
		} else if (k == "DIM" or k == "OPTION") and cx.ecma {
			Parse.on(Nop, Parse.stmt_end(b, w))
		} else if k == "DIM" {
			d = Parse.dim_items(b, w, cx, [])
			if !d.ok { Parse.last(Dim(d.items)) } else { Parse.on(if List.is_empty(d.items) { Nop } else { Dim(d.items) }, d.at) }
		} else if k == "READ" {
			t = Parse.target_list(b, w, cx, [])
			if !t.ok { Parse.last(Read(t.items)) } else { Parse.on(Read(t.items), t.at) }
		} else if k == "RESTORE" {
			Parse.on(Restore, w)
		} else if k == "INPUT" {
			Parse.st_input(b, w, cx)
		} else if k == "SLEEP" or k == "PAUSE" {
			r = Parse.sum(b, w, cx)
			if !r.ok { Parse.last(Bad(r.e, "")) } else { Parse.on(Sleep(r.e), r.at) }
		} else if k == "PLOT" {
			Parse.st_plot(b, w, cx)
		} else if k == "POKE" {
			a = Parse.sum(b, w, cx)
			c = Parse.skip_ws(b, a.at)
			if !a.ok {
				Parse.last(Bad(a.e, ""))
			} else if Parse.byte(b, c) != 44 {
				Parse.last(Bad(a.e, "Expected , after the POKE address"))
			} else {
				v = Parse.sum(b, c + 1, cx)
				if !v.ok { Parse.last(Bad(Seq(a.e, v.e), "")) } else { Parse.on(Poke(a.e, v.e), v.at) }
			}
		} else if k == "ON" {
			Parse.st_on(b, w, cx)
		} else if k == "OPTION" {
			j = Parse.kw(b, w, "BASE")
			if j == w {
				Parse.last(Bad(Parse.zero, "Expected BASE"))
			} else {
				r = Parse.sum(b, j, cx)
				if !r.ok { Parse.last(Bad(r.e, "")) } else { Parse.on(Option(r.e), r.at) }
			}
		} else if k == "DEF" {
			Parse.st_def(b, w, cx)
		} else if k == "RANDOMIZE" {
			Parse.on(Nop, Parse.stmt_end(b, w))
		} else {
			Parse.st_let(b, i, cx)
		}

	# A constant line number is resolved when the listing is loaded; any
	# other expression is looked up when the jump is taken.
	jump_of : Expr -> Jump
	jump_of = |e| match e {
		Num(x) => if F64.abs(x) <= Parse.huge { Line(F64.to_i64_wrap(x)) } else { Computed(e) }
		_ => Computed(e)
	}

	huge : F64
	huge = 1.7976931348623157e308

	st_let : List(U8), U64, Cx -> St
	st_let = |b, w, cx| {
		nm = Parse.name_at(b, w)
		j = Parse.skip_ws(b, nm.at)
		if !nm.found {
			Parse.last(Bad(Parse.zero, "Expected a variable"))
		} else if Parse.byte(b, j) == 40 {
			s = Parse.subscripts(b, j, cx)
			e = Parse.skip_ws(b, s.at)
			if !s.ok {
				Parse.last(Bad(Seq(s.one, s.two), ""))
			} else if Parse.byte(b, e) != 61 {
				Parse.last(Bad(Seq(s.one, s.two), "Expected ="))
			} else {
				r = Parse.expr(b, e + 1, cx)
				if !r.ok { Parse.last(Bad(Seq(Seq(s.one, s.two), r.e), "")) } else { Parse.on(SetElem(nm.slot, s.one, s.two, s.pair, r.e), r.at) }
			}
		} else if Parse.byte(b, j) != 61 {
			Parse.last(Bad(Parse.zero, "Expected ="))
		} else {
			r = Parse.expr(b, j + 1, cx)
			if !r.ok {
				Parse.last(Bad(r.e, ""))
			} else if nm.str {
				Parse.on(SetStr(nm.slot, r.e), r.at)
			} else {
				Parse.on(SetNum(nm.slot, r.e), r.at)
			}
		}
	}

	st_if : List(U8), U64, U64, Cx -> St
	st_if = |b, w, line, cx| {
		l = Parse.expr(b, w, cx)
		op = Parse.relop(b, l.at)
		if !l.ok {
			Parse.last(Bad(l.e, ""))
		} else if op.code == 0 {
			Parse.last(Bad(l.e, "Expected a relational operator"))
		} else {
			r = Parse.expr(b, op.at, cx)
			t = Parse.kw(b, r.at, "THEN")
			j = Parse.skip_ws(b, t)
			if !r.ok {
				Parse.last(Bad(Seq(l.e, r.e), ""))
			} else if t == r.at {
				Parse.last(Bad(Seq(l.e, r.e), "Expected THEN"))
			} else if Parse.is_digit(Parse.byte(b, j)) {
				Parse.last(IfGo(l.e, op.code, r.e, Line(Parse.digits_val(b, j, Parse.digits_end(b, j), 0)), line))
			} else {
				{ ..Parse.on(IfThen(l.e, op.code, r.e, line), j), then: True }
			}
		}
	}

	relop : List(U8), U64 -> { code : U8, at : U64 }
	relop = |b, i| {
		j = Parse.skip_ws(b, i)
		c = Parse.byte(b, j)
		d = Parse.byte(b, j + 1)
		if c == 61 {
			{ code: 1, at: j + 1 }
		} else if c == 60 and d == 62 {
			{ code: 2, at: j + 2 }
		} else if c == 60 and d == 61 {
			{ code: 3, at: j + 2 }
		} else if c == 62 and d == 61 {
			{ code: 4, at: j + 2 }
		} else if c == 60 {
			{ code: 5, at: j + 1 }
		} else if c == 62 {
			{ code: 6, at: j + 1 }
		} else {
			{ code: 0, at: i }
		}
	}

	st_for : List(U8), U64, Cx -> St
	st_for = |b, w, cx| {
		nm = Parse.name_at(b, w)
		j = Parse.skip_ws(b, nm.at)
		if !nm.found or Parse.byte(b, j) != 61 {
			Parse.last(Bad(Parse.zero, "Malformed FOR"))
		} else {
			from = Parse.sum(b, j + 1, cx)
			t = Parse.kw(b, from.at, "TO")
			if !from.ok {
				Parse.last(Bad(from.e, ""))
			} else if t == from.at {
				Parse.last(Bad(from.e, "Expected TO"))
			} else {
				lim = Parse.sum(b, t, cx)
				st = Parse.kw(b, lim.at, "STEP")
				stepped = if st == lim.at { { e: Num(1.0), at: lim.at, ok: True } } else { Parse.sum(b, st, cx) }
				if !lim.ok {
					Parse.last(Bad(Seq(from.e, lim.e), ""))
				} else if !stepped.ok {
					Parse.last(Bad(Seq(Seq(from.e, lim.e), stepped.e), ""))
				} else {
					Parse.on(For(nm.slot, from.e, lim.e, stepped.e), stepped.at)
				}
			}
		}
	}

	# DIM's arrays, up to the first that is not one. `ok` is False when a
	# subscript is malformed; that item is last, and stops the machine.
	dim_items : List(U8), U64, Cx, List(DimItem) -> { items : List(DimItem), at : U64, ok : Bool }
	dim_items = |b, w, cx, acc| {
		nm = Parse.name_at(b, w)
		if !nm.found {
			{ items: acc, at: Parse.stmt_end(b, w), ok: True }
		} else {
			s = Parse.subscripts(b, Parse.skip_ws(b, nm.at), cx)
			items = List.append(acc, { slot: nm.slot, one: s.one, two: s.two, pair: s.pair })
			j = Parse.skip_ws(b, s.at)
			if !s.ok {
				{ items: items, at: s.at, ok: False }
			} else if Parse.byte(b, j) == 44 {
				Parse.dim_items(b, j + 1, cx, items)
			} else {
				{ items: items, at: s.at, ok: True }
			}
		}
	}

	# The variables of a READ or INPUT, up to the first that is not one. A
	# string variable followed by a subscript ends the list there.
	target_list : List(U8), U64, Cx, List(Target) -> { items : List(Target), at : U64, ok : Bool }
	target_list = |b, w, cx, acc| {
		nm = Parse.name_at(b, w)
		j = Parse.skip_ws(b, nm.at)
		if !nm.found {
			{ items: acc, at: Parse.stmt_end(b, w), ok: True }
		} else if nm.str {
			Parse.more_targets(b, nm.at, cx, List.append(acc, { kind: 1, slot: nm.slot, one: Parse.zero, two: Parse.zero, pair: False }))
		} else if Parse.byte(b, j) == 40 {
			s = Parse.subscripts(b, j, cx)
			items = List.append(acc, { kind: 2, slot: nm.slot, one: s.one, two: s.two, pair: s.pair })
			if !s.ok { { items: items, at: s.at, ok: False } } else { Parse.more_targets(b, s.at, cx, items) }
		} else {
			Parse.more_targets(b, nm.at, cx, List.append(acc, { kind: 0, slot: nm.slot, one: Parse.zero, two: Parse.zero, pair: False }))
		}
	}

	more_targets : List(U8), U64, Cx, List(Target) -> { items : List(Target), at : U64, ok : Bool }
	more_targets = |b, at, cx, acc| {
		j = Parse.skip_ws(b, at)
		if Parse.byte(b, j) == 44 { Parse.target_list(b, j + 1, cx, acc) } else { { items: acc, at: at, ok: True } }
	}

	st_input : List(U8), U64, Cx -> St
	st_input = |b, w, cx| {
		j = Parse.skip_ws(b, w)
		quoted = Parse.byte(b, j) == 34
		e = if quoted { Parse.quote_end(b, j + 1, List.len(b)) } else { j }
		k = Parse.skip_ws(b, e)
		vars = if quoted and (Parse.byte(b, k) == 59 or Parse.byte(b, k) == 44) { k + 1 } else { k }
		prompt = if quoted { Parse.text_of(b, j + 1, U64.minus_wrap(e, 1)) } else { "" }
		t = Parse.target_list(b, vars, cx, [])
		if !t.ok { Parse.last(Input(prompt, t.items)) } else { Parse.on(Input(prompt, t.items), t.at) }
	}

	st_plot : List(U8), U64, Cx -> St
	st_plot = |b, w, cx| {
		x = Parse.sum(b, w, cx)
		cx1 = Parse.skip_ws(b, x.at)
		if !x.ok {
			Parse.last(Bad(x.e, ""))
		} else if Parse.byte(b, cx1) != 44 {
			Parse.last(Bad(x.e, "Expected , after the PLOT x"))
		} else {
			y = Parse.sum(b, cx1 + 1, cx)
			cy = Parse.skip_ws(b, y.at)
			if !y.ok {
				Parse.last(Bad(Seq(x.e, y.e), ""))
			} else if Parse.byte(b, cy) != 44 {
				Parse.last(Bad(Seq(x.e, y.e), "Expected , after the PLOT y"))
			} else {
				c = Parse.sum(b, cy + 1, cx)
				if !c.ok { Parse.last(Bad(Seq(Seq(x.e, y.e), c.e), "")) } else { Parse.on(Plot(x.e, y.e, c.e), c.at) }
			}
		}
	}

	# ON <expr> GOTO or GOSUB, then line numbers: as many as follow one
	# another with commas between.
	st_on : List(U8), U64, Cx -> St
	st_on = |b, w, cx| {
		r = Parse.sum(b, w, cx)
		g = Parse.kw(b, r.at, "GOTO")
		sub = if g == r.at { Parse.kw(b, r.at, "GOSUB") } else { g }
		if !r.ok {
			Parse.last(Bad(r.e, ""))
		} else if sub == r.at {
			Parse.last(Bad(r.e, "Expected GOTO or GOSUB"))
		} else {
			js = Parse.line_list(b, sub, [])
			if g != r.at {
				Parse.last(OnGo(r.e, js))
			} else {
				Parse.on(OnGosub(r.e, js), Parse.line_list_end(b, Parse.digits_end(b, Parse.skip_ws(b, sub))))
			}
		}
	}

	line_list : List(U8), U64, List(Jump) -> List(Jump)
	line_list = |b, i, acc| {
		j = Parse.skip_ws(b, i)
		e = Parse.digits_end(b, j)
		if e == j {
			acc
		} else {
			more = List.append(acc, Line(Parse.digits_val(b, j, e, 0)))
			c = Parse.skip_ws(b, e)
			if Parse.byte(b, c) != 44 { more } else { Parse.line_list(b, c + 1, more) }
		}
	}

	line_list_end : List(U8), U64 -> U64
	line_list_end = |b, i| {
		c = Parse.skip_ws(b, i)
		if Parse.byte(b, c) != 44 { c } else { Parse.line_list_end(b, Parse.digits_end(b, Parse.skip_ws(b, c + 1))) }
	}

	st_def : List(U8), U64, Cx -> St
	st_def = |b, w, cx| {
		h = Parse.def_head(b, w)
		if h.why != "" {
			Parse.last(Bad(Parse.zero, h.why))
		} else {
			stop = Parse.stmt_end(b, h.body)
			body = Parse.expr(List.sublist(b, { start: h.body, len: stop - h.body }), 0, cx).e
			if h.letter >= 26 {
				Parse.on(Nop, stop)
			} else {
				{ ..Parse.on(Def(h.letter), stop), letter: h.letter, def: { known: True, param: h.param, pslot: h.pslot, body: body } }
			}
		}
	}

	# ---- PRINT ----------------------------------------------------------------

	print_items : List(U8), U64, Bool, Cx, List(Item) -> { items : List(Item), newline : Bool, at : U64 }
	print_items = |b, i, newline, cx, acc| {
		j = Parse.skip_ws(b, i)
		if j >= List.len(b) or Parse.byte(b, j) == 58 {
			{ items: acc, newline: newline, at: j }
		} else if Parse.byte(b, j) == 59 {
			Parse.print_items(b, j + 1, False, cx, List.append(acc, Semi))
		} else if Parse.byte(b, j) == 44 {
			Parse.print_items(b, j + 1, False, cx, List.append(acc, Comma))
		} else {
			t = Parse.kw(b, j, "TAB")
			if t != j {
				r = Parse.sum(b, t + 1, cx)
				e = Parse.skip_ws(b, r.at)
				items = List.append(acc, Tab(r.e))
				if !r.ok { { items: items, newline: True, at: r.at } } else { Parse.print_items(b, if Parse.byte(b, e) == 41 { e + 1 } else { e }, True, cx, items) }
			} else {
				r = Parse.expr(b, j, cx)
				items = List.append(acc, Show(r.e))
				if !r.ok { { items: items, newline: True, at: r.at } } else { Parse.print_items(b, r.at, True, cx, items) }
			}
		}
	}

	# ---- expressions ----------------------------------------------------------

	# **THE STRING PATH IS DECIDED FIRST.** A string literal, a `$` variable
	# and a `$` function begin a string expression; everything else is the
	# numeric grammar.
	expr : List(U8), U64, Cx -> P
	expr = |b, i, cx| {
		j = Parse.skip_ws(b, i)
		if Parse.byte(b, j) == 34 {
			e = Parse.quote_end(b, j + 1, List.len(b))
			Parse.str_sum(b, e, Text(Parse.text_of(b, j + 1, U64.minus_wrap(e, 1))), cx)
		} else {
			w = Parse.word_end(b, j)
			k = Parse.text_of(b, j, w)
			nm = Parse.name_at(b, j)
			if Parse.is_str_fn(k) and Parse.byte(b, w) == 36 {
				r = Parse.call_str_fn(b, w + 1, k, cx)
				if !r.ok { r } else { Parse.str_sum(b, r.at, r.e, cx) }
			} else if nm.found and nm.str {
				Parse.str_sum(b, nm.at, StrVar(nm.slot), cx)
			} else {
				Parse.sum(b, j, cx)
			}
		}
	}

	str_sum : List(U8), U64, Expr, Cx -> P
	str_sum = |b, i, acc, cx| {
		j = Parse.skip_ws(b, i)
		if Parse.byte(b, j) != 43 {
			{ e: acc, at: i, ok: True }
		} else {
			r = Parse.expr(b, j + 1, cx)
			if !r.ok { { e: Seq(acc, r.e), at: r.at, ok: False } } else { { e: Cat(acc, r.e), at: r.at, ok: True } }
		}
	}

	# **A LEADING SIGN NEGATES THE FIRST TERM** (ECMA-55 7): `-2^2` is -4.
	sum : List(U8), U64, Cx -> P
	sum = |b, i, cx| {
		j = Parse.skip_ws(b, i)
		c = Parse.byte(b, j)
		r = Parse.term(b, if c == 45 or c == 43 { j + 1 } else { i }, cx)
		if !r.ok { r } else { Parse.sum_rest(b, r.at, if c == 45 { Neg(r.e) } else { r.e }, cx) }
	}

	sum_rest : List(U8), U64, Expr, Cx -> P
	sum_rest = |b, i, acc, cx| {
		j = Parse.skip_ws(b, i)
		c = Parse.byte(b, j)
		if c != 43 and c != 45 {
			{ e: acc, at: i, ok: True }
		} else {
			r = Parse.term(b, j + 1, cx)
			if !r.ok { { e: Seq(acc, r.e), at: r.at, ok: False } } else { Parse.sum_rest(b, r.at, if c == 43 { Add(acc, r.e) } else { Sub(acc, r.e) }, cx) }
		}
	}

	term : List(U8), U64, Cx -> P
	term = |b, i, cx| {
		r = Parse.power(b, i, cx)
		if !r.ok { r } else { Parse.term_rest(b, r.at, Parse.numeric(r.e), cx) }
	}

	term_rest : List(U8), U64, Expr, Cx -> P
	term_rest = |b, i, acc, cx| {
		j = Parse.skip_ws(b, i)
		c = Parse.byte(b, j)
		if c != 42 and c != 47 {
			{ e: acc, at: i, ok: True }
		} else {
			r = Parse.power(b, j + 1, cx)
			if !r.ok { { e: Seq(acc, r.e), at: r.at, ok: False } } else { Parse.term_rest(b, r.at, if c == 42 { Mul(acc, r.e) } else { Div(acc, r.e) }, cx) }
		}
	}

	# A term is a number: a string read there is zero.
	numeric : Expr -> Expr
	numeric = |e| match e {
		StrVar(_) => AsNum(e)
		Chr(_) => AsNum(e)
		StrOf(_) => AsNum(e)
		Left(_, _) => AsNum(e)
		Right(_, _) => AsNum(e)
		Mid(_, _) => AsNum(e)
		Mid3(_, _, _) => AsNum(e)
		CallDef(_, _, _) => AsNum(e)
		_ => e
	}

	# `^` binds tighter than `*` and groups to the LEFT (ECMA-55 7).
	power : List(U8), U64, Cx -> P
	power = |b, i, cx| {
		r = Parse.primary(b, i, cx)
		if !r.ok { r } else { Parse.power_rest(b, r, cx) }
	}

	power_rest : List(U8), P, Cx -> P
	power_rest = |b, r, cx| {
		j = Parse.skip_ws(b, r.at)
		if Parse.byte(b, j) != 94 {
			r
		} else {
			e = Parse.primary(b, j + 1, cx)
			if !e.ok { { e: Seq(r.e, e.e), at: e.at, ok: False } } else { Parse.power_rest(b, { e: Pow(r.e, e.e), at: e.at, ok: True }, cx) }
		}
	}

	# The sign here is the microcomputer's, for `X^-1` and `A*-B`.
	primary : List(U8), U64, Cx -> P
	primary = |b, i, cx| {
		j = Parse.skip_ws(b, i)
		c = Parse.byte(b, j)
		if c == 45 {
			r = Parse.primary(b, j + 1, cx)
			if !r.ok { r } else { { e: Neg(r.e), at: r.at, ok: True } }
		} else if c == 43 {
			Parse.primary(b, j + 1, cx)
		} else if c == 40 {
			r = Parse.sum(b, j + 1, cx)
			k = Parse.skip_ws(b, r.at)
			if !r.ok {
				r
			} else if Parse.byte(b, k) != 41 {
				{ e: Seq(r.e, Fail("Expected )")), at: k, ok: False }
			} else {
				{ e: r.e, at: k + 1, ok: True }
			}
		} else if Parse.is_digit(c) or c == 46 {
			n = Parse.numeral(b, j)
			{ e: Num(n.v), at: n.at, ok: True }
		} else if Parse.is_alpha(c) {
			Parse.name_or_call(b, j, cx)
		} else {
			{ e: Fail("Expected an expression"), at: j, ok: False }
		}
	}

	fail : Str, U64 -> P
	fail = |why, at| { e: Fail(why), at: at, ok: False }

	name_or_call : List(U8), U64, Cx -> P
	name_or_call = |b, i, cx| {
		w = Parse.word_end(b, i)
		k = Parse.text_of(b, i, w)
		if Parse.is_str_fn(k) and Parse.byte(b, w) == 36 {
			Parse.call_str_fn(b, w + 1, k, cx)
		} else if Parse.fn_code(k) > 0 {
			Parse.call_fn(b, w, k, cx)
		} else if Str.starts_with(k, "FN") and Str.count_utf8_bytes(k) == 3 {
			Parse.call_def(b, w, Parse.byte(b, i + 2), cx)
		} else {
			nm = Parse.name_at(b, i)
			j = Parse.skip_ws(b, nm.at)
			if nm.str {
				{ e: StrVar(nm.slot), at: nm.at, ok: True }
			} else if Parse.byte(b, j) != 40 {
				{ e: NumVar(nm.slot), at: nm.at, ok: True }
			} else {
				s = Parse.subscripts(b, j, cx)
				if !s.ok { { e: Seq(s.one, s.two), at: s.at, ok: False } } else { { e: Elem(nm.slot, s.one, s.two, s.pair), at: s.at, ok: True } }
			}
		}
	}

	# `(i)` or `(i, j)`, from the `(` at `i`. A missing `)` is let pass.
	subscripts : List(U8), U64, Cx -> Subs
	subscripts = |b, i, cx| {
		r = Parse.sum(b, i + 1, cx)
		k = Parse.skip_ws(b, r.at)
		if !r.ok {
			{ one: r.e, two: Parse.zero, pair: False, at: r.at, ok: False }
		} else if Parse.byte(b, k) == 44 {
			r2 = Parse.sum(b, k + 1, cx)
			e = Parse.skip_ws(b, r2.at)
			if !r2.ok {
				{ one: r.e, two: r2.e, pair: True, at: r2.at, ok: False }
			} else {
				{ one: r.e, two: r2.e, pair: True, at: if Parse.byte(b, e) == 41 { e + 1 } else { e }, ok: True }
			}
		} else {
			{ one: r.e, two: Parse.zero, pair: False, at: if Parse.byte(b, k) == 41 { k + 1 } else { k }, ok: True }
		}
	}

	# The numeric functions by code; 0 is not one.
	fn_code : Str -> U8
	fn_code = |k|
		if k == "ABS" { 1 }
		else if k == "ATN" { 2 }
		else if k == "COS" { 3 }
		else if k == "EXP" { 4 }
		else if k == "INT" { 5 }
		else if k == "LOG" { 6 }
		else if k == "SGN" { 7 }
		else if k == "SIN" { 8 }
		else if k == "SQR" { 9 }
		else if k == "TAN" { 10 }
		else if k == "PEEK" { 11 }
		else if k == "LEN" { 12 }
		else if k == "ASC" { 13 }
		else if k == "VAL" { 14 }
		else if k == "RND" { 15 }
		else { 0 }

	is_str_fn : Str -> Bool
	is_str_fn = |k| k == "CHR" or k == "STR" or k == "LEFT" or k == "RIGHT" or k == "MID"

	# ECMA-55's RND takes no argument; every listing writes RND(1), so both
	# are accepted (EXT), and the argument is evaluated and not used.
	call_fn : List(U8), U64, Str, Cx -> P
	call_fn = |b, i, k, cx| {
		j = Parse.skip_ws(b, i)
		if Parse.byte(b, j) != 40 {
			if k == "RND" { { e: Rnd, at: j, ok: True } } else { Parse.fail(Str.concat("Expected ( after ", k), j) }
		} else {
			# LEN, ASC and VAL take a string.
			r = if k == "LEN" or k == "ASC" or k == "VAL" { Parse.expr(b, j + 1, cx) } else { Parse.sum(b, j + 1, cx) }
			e = Parse.skip_ws(b, r.at)
			if !r.ok {
				r
			} else if Parse.byte(b, e) != 41 {
				{ e: Seq(r.e, Fail("Expected )")), at: e, ok: False }
			} else if k == "RND" {
				{ e: Seq(r.e, Rnd), at: e + 1, ok: True }
			} else {
				{ e: Call(Parse.fn_code(k), r.e), at: e + 1, ok: True }
			}
		}
	}

	call_str_fn : List(U8), U64, Str, Cx -> P
	call_str_fn = |b, i, k, cx| {
		j = Parse.skip_ws(b, i)
		if Parse.byte(b, j) != 40 {
			Parse.fail(Str.concat("Expected ( after ", k), j)
		} else {
			a = Parse.expr(b, j + 1, cx)
			c = Parse.skip_ws(b, a.at)
			if !a.ok {
				a
			} else if k == "CHR" or k == "STR" {
				if Parse.byte(b, c) != 41 {
					{ e: Seq(a.e, Fail("Expected )")), at: c, ok: False }
				} else {
					{ e: if k == "CHR" { Chr(a.e) } else { StrOf(a.e) }, at: c + 1, ok: True }
				}
			} else if Parse.byte(b, c) != 44 {
				{ e: Seq(a.e, Fail("Expected , ")), at: c, ok: False }
			} else {
				n1 = Parse.sum(b, c + 1, cx)
				d = Parse.skip_ws(b, n1.at)
				past_d = if Parse.byte(b, d) == 41 { d + 1 } else { d }
				if !n1.ok {
					{ e: Seq(a.e, n1.e), at: n1.at, ok: False }
				} else if k == "LEFT" {
					{ e: Left(a.e, n1.e), at: past_d, ok: True }
				} else if k == "RIGHT" {
					{ e: Right(a.e, n1.e), at: past_d, ok: True }
				} else if Parse.byte(b, d) != 44 {
					# MID$(s, from) runs to the end.
					{ e: Mid(a.e, n1.e), at: past_d, ok: True }
				} else {
					n2 = Parse.sum(b, d + 1, cx)
					e = Parse.skip_ws(b, n2.at)
					if !n2.ok {
						{ e: Seq(Seq(a.e, n1.e), n2.e), at: n2.at, ok: False }
					} else {
						{ e: Mid3(a.e, n1.e, n2.e), at: if Parse.byte(b, e) == 41 { e + 1 } else { e }, ok: True }
					}
				}
			}
		}
	}

	# A call of FNx takes an argument when the function's first DEF has a
	# parameter. With no DEF anywhere, the call is an unsupported form.
	call_def : List(U8), U64, U8, Cx -> P
	call_def = |b, i, c, cx| {
		letter = Parse.u64(c) - 65
		f = List.get(cx.fns, letter) ?? Parse.no_fn
		name = Str.concat("FN", Str.from_utf8([c]) ?? "")
		j = Parse.skip_ws(b, i)
		if !f.known {
			Parse.fail(Str.concat("Undefined function: ", name), i)
		} else if !f.param {
			{ e: CallDef(letter, False, Parse.zero), at: if Parse.byte(b, j) == 40 and Parse.byte(b, j + 1) == 41 { j + 2 } else { i }, ok: True }
		} else if Parse.byte(b, j) != 40 {
			{ e: CallDef(letter, True, Fail(Str.concat("Expected ( after ", name))), at: j, ok: False }
		} else {
			a = Parse.sum(b, j + 1, cx)
			e = Parse.skip_ws(b, a.at)
			if !a.ok {
				{ e: CallDef(letter, True, a.e), at: a.at, ok: False }
			} else if Parse.byte(b, e) != 41 {
				{ e: CallDef(letter, True, Seq(a.e, Fail("Expected )"))), at: e, ok: False }
			} else {
				{ e: CallDef(letter, True, a.e), at: e + 1, ok: True }
			}
		}
	}

	# ---- numerals ---------------------------------------------------------------

	# **A NUMERAL IS ITS DIGITS AS ONE INTEGER, SCALED ONCE.** Summing tenths
	# drifts: `0.7E1` came out a hair over 7.
	numeral : List(U8), U64 -> { v : F64, at : U64 }
	numeral = |b, i| {
		w = Parse.whole(b, i, 0.0)
		point = Parse.byte(b, w.at) == 46
		f = if point { Parse.whole(b, w.at + 1, w.v) } else { w }
		places = if point { I64.to_f64(U64.to_i64_wrap(f.at - w.at - 1)) } else { 0.0 }
		if Parse.byte(b, f.at) != 69 {
			{ v: Parse.scaled(f.v, 0.0 - places), at: f.at }
		} else {
			neg = Parse.byte(b, f.at + 1) == 45
			g = if neg or Parse.byte(b, f.at + 1) == 43 { f.at + 2 } else { f.at + 1 }
			x = Parse.whole(b, g, 0.0)
			{ v: Parse.scaled(f.v, (if neg { 0.0 - x.v } else { x.v }) - places), at: x.at }
		}
	}

	# `digits` times ten to the `e`, dividing where `e` is negative: ten to a
	# negative power has no exact F64.
	scaled : F64, F64 -> F64
	scaled = |digits, e|
		if digits == 0.0 or e == 0.0 {
			digits
		} else if e > 0.0 {
			digits * F64.pow(10.0, e)
		} else {
			digits / F64.pow(10.0, 0.0 - e)
		}

	whole : List(U8), U64, F64 -> { v : F64, at : U64 }
	whole = |b, i, acc|
		if Parse.is_digit(Parse.byte(b, i)) {
			Parse.whole(b, i + 1, acc * 10.0 + I64.to_f64(U8.to_i64(Parse.byte(b, i)) - 48))
		} else {
			{ v: acc, at: i }
		}

	# ---- names and bytes ------------------------------------------------------

	# A name is a letter, optionally a digit, optionally `$`. Its slot is
	# the letter's 11 places (bare, then each digit), past the first 286 when
	# it ends in `$`.
	name_at : List(U8), U64 -> { found : Bool, str : Bool, slot : U64, at : U64 }
	name_at = |b, i| {
		j = Parse.skip_ws(b, i)
		c = Parse.byte(b, j)
		if !Parse.is_alpha(c) {
			{ found: False, str: False, slot: 0, at: i }
		} else {
			d = Parse.byte(b, j + 1)
			digit = Parse.is_digit(d)
			e1 = if digit { j + 2 } else { j + 1 }
			dollar = Parse.byte(b, e1) == 36
			slot = (Parse.u64(c) - 65) * 11 + (if digit { Parse.u64(d) - 47 } else { 0 }) + (if dollar { 286 } else { 0 })
			{ found: True, str: dollar, slot: slot, at: if dollar { e1 + 1 } else { e1 } }
		}
	}

	# The name a slot stands for.
	name_of : U64 -> Str
	name_of = |slot| {
		s = U64.rem_by(slot, 286)
		letter = Str.from_utf8([U64.to_u8_wrap(65 + U64.div_trunc_by(s, 11))]) ?? "?"
		d = U64.rem_by(s, 11)
		digit = if d == 0 { "" } else { Str.from_utf8([U64.to_u8_wrap(47 + d)]) ?? "" }
		Str.concat(Str.concat(letter, digit), if slot >= 286 { "$" } else { "" })
	}

	u64 : U8 -> U64
	u64 = |c| I64.to_u64_wrap(U8.to_i64(c))

	byte : List(U8), U64 -> U8
	byte = |b, i| List.get(b, i) ?? 0

	is_digit : U8 -> Bool
	is_digit = |c| c >= 48 and c <= 57

	is_alpha : U8 -> Bool
	is_alpha = |c| c >= 65 and c <= 90

	upper : U8 -> U8
	upper = |c| if c >= 97 and c <= 122 { c - 32 } else { c }

	skip_ws : List(U8), U64 -> U64
	skip_ws = |b, i| if Parse.byte(b, i) == 32 { Parse.skip_ws(b, i + 1) } else { i }

	word_end : List(U8), U64 -> U64
	word_end = |b, i| if Parse.is_alpha(Parse.byte(b, i)) { Parse.word_end(b, i + 1) } else { i }

	# Whether `word` stands at `i` (after spaces): the position past it, or
	# the position given when it does not.
	kw : List(U8), U64, Str -> U64
	kw = |b, i, word| {
		j = Parse.skip_ws(b, i)
		n = Str.count_utf8_bytes(word)
		if Parse.text_of(b, j, j + n) == word { j + n } else { i }
	}

	text_of : List(U8), U64, U64 -> Str
	text_of = |b, from, to|
		if to <= from { "" } else { Str.from_utf8(List.sublist(b, { start: from, len: to - from })) ?? "" }

	quote_end : List(U8), U64, U64 -> U64
	quote_end = |b, i, e|
		if i >= e { i } else if Parse.byte(b, i) == 34 { i + 1 } else { Parse.quote_end(b, i + 1, e) }

	# A colon outside quotes, or the end of the line.
	stmt_end : List(U8), U64 -> U64
	stmt_end = |b, i|
		if i >= List.len(b) {
			i
		} else if Parse.byte(b, i) == 34 {
			Parse.stmt_end(b, Parse.quote_end(b, i + 1, List.len(b)))
		} else if Parse.byte(b, i) == 58 {
			i
		} else {
			Parse.stmt_end(b, i + 1)
		}

	digits_end : List(U8), U64 -> U64
	digits_end = |b, i| if Parse.is_digit(Parse.byte(b, i)) { Parse.digits_end(b, i + 1) } else { i }

	# Only the first nine digits count: an I64 that `*` overflows is a crash.
	digits_val : List(U8), U64, U64, I64 -> I64
	digits_val = |b, i, e, acc|
		if i >= e or acc > 99999999 { acc } else { Parse.digits_val(b, i + 1, e, acc * 10 + U8.to_i64(Parse.byte(b, i)) - 48) }
}
