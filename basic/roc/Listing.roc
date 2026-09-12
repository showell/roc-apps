# The load-time check of a listing in ECMA-55: the faults of a program,
# found before its first statement runs.
#
# ECMA-55 rejects a program for these rather than running the part above
# the fault, and the NBS suite's ERROR programs exist to check that it
# does. A microcomputer BASIC sorted what was typed and ran it, so only the
# ECMA-55 door asks; 26 of the 99 game listings would not get past it.
#
# Two passes. The first reads the raw text line by line, before
# `Basic.load` sorts the lines and drops what it cannot number, because
# those are exactly its faults. The second recognizes each statement
# without running it: **THE TYPE OF AN ECMA-55 EXPRESSION IS IN ITS TEXT**
# -- a string is a `$` name or a quoted literal, nothing computes one -- so
# a string where a number belongs is as visible as a missing parenthesis.
#
# Accepted past the standard, and documented in basic/README.md: a sign
# after an operator, no space before a keyword, lowercase, `<` and `>`
# between strings, THEN followed by a statement, an INPUT prompt, and the
# extension statements and functions, which are not checked at all.

Listing :: [].{
	Rejection : { why : Str, num : I64 }

	# What a recognizer answers: where it stopped, why it refused (empty
	# when it did not), and whether what it read was a string.
	Sc : { at : U64, why : Str, str : Bool }

	# A user function's letter, and whether its DEF takes a parameter.
	Def : { k : U8, param : Bool }

	# The first fault in a listing, `why` empty when there is none. `num` is
	# the line it concerns, or the line before it; -1 before any line.
	check : Str -> Rejection
	check = |src| {
		b = Str.to_utf8(src)
		first = Listing.lines(b, 0, -1, False)
		if first.why != "" { first } else { Listing.statements(b, 0, Listing.defs(b, 0, [])) }
	}

	# ---- the lines ---------------------------------------------------------

	# `prev` is the last line number seen, `ended` that its line was END.
	lines : List(U8), U64, I64, Bool -> Rejection
	lines = |b, i, prev, ended|
		if i >= List.len(b) {
			if ended { { why: "", num: -1 } } else { { why: "The last line is not END", num: prev } }
		} else {
			e = Listing.eol(b, i)
			# A DOS listing's carriage return is not part of the line.
			stop = if e > i and Listing.byte(b, e - 1) == 13 { e - 1 } else { e }
			s = Listing.skip_ws(b, i)
			d = Listing.digits_end(b, s)
			g = Listing.skip_ws(b, d)
			if s >= stop {
				Listing.lines(b, e + 1, prev, ended)
			} else if d == s {
				{ why: "A line has no line number", num: prev }
			} else {
				n = Listing.digits_val(b, s, d, 0)
				# `2 40 PRINT` would otherwise be line 2 with a statement
				# that starts "40".
				if g > d and g < stop and Listing.is_digit(Listing.byte(b, g)) {
					{ why: "A space inside a line number", num: n }
				} else if d - s > 4 {
					{ why: "A line number longer than four digits", num: n }
				} else if n == 0 {
					{ why: "Line number 0", num: n }
				} else if n == prev {
					{ why: "A line number used twice", num: n }
				} else if n < prev {
					{ why: "A line number out of order", num: n }
				} else if stop - i > 72 {
					{ why: "A line longer than 72 characters", num: n }
				} else if ended {
					{ why: "END is not the last line", num: prev }
				} else {
					Listing.lines(b, e + 1, n, Listing.is_end(b, g, stop))
				}
			}
		}

	is_end : List(U8), U64, U64 -> Bool
	is_end = |b, g, stop| {
		spelled = Listing.upper(Listing.byte(b, g)) == 69 and Listing.upper(Listing.byte(b, g + 1)) == 78 and Listing.upper(Listing.byte(b, g + 2)) == 68
		spelled and (g + 3 >= stop or !Listing.is_alpha(Listing.byte(b, g + 3)))
	}

	# ---- the statements ----------------------------------------------------

	# Every line has a number by now; each statement is read on its own,
	# upper-cased outside its quotes.
	statements : List(U8), U64, List(Def) -> Rejection
	statements = |b, i, fns|
		if i >= List.len(b) {
			{ why: "", num: -1 }
		} else {
			e = Listing.eol(b, i)
			stop = if e > i and Listing.byte(b, e - 1) == 13 { e - 1 } else { e }
			s = Listing.skip_ws(b, i)
			if s >= stop {
				Listing.statements(b, e + 1, fns)
			} else {
				d = Listing.digits_end(b, s)
				body = Listing.upper_body(b, Listing.skip_ws(b, d), stop, False, [])
				r = Listing.statement(body, 0, fns)
				if r.why != "" { { why: r.why, num: Listing.digits_val(b, s, d, 0) } } else { Listing.statements(b, e + 1, fns) }
			}
		}

	# The DEFs of the whole listing, so a call can be held to its DEF's arity
	# wherever the DEF is.
	defs : List(U8), U64, List(Def) -> List(Def)
	defs = |b, i, acc|
		if i >= List.len(b) {
			acc
		} else {
			e = Listing.eol(b, i)
			s = Listing.skip_ws(b, i)
			body = Listing.upper_body(b, Listing.skip_ws(b, Listing.digits_end(b, s)), e, False, [])
			j = Listing.skip_ws(body, 0)
			k = Listing.skip_ws(body, j + 3)
			found = Listing.starts(body, j, "DEF") and Listing.starts(body, k, "FN") and Listing.is_alpha(Listing.byte(body, k + 2))
			Listing.defs(b, e + 1, if found { List.append(acc, { k: Listing.byte(body, k + 2), param: Listing.next(body, k + 3) == 40 }) } else { acc })
		}

	upper_body : List(U8), U64, U64, Bool, List(U8) -> List(U8)
	upper_body = |b, i, stop, quoted, acc|
		if i >= stop {
			acc
		} else {
			c = Listing.byte(b, i)
			flip = if c == 34 { !quoted } else { quoted }
			Listing.upper_body(b, i + 1, stop, flip, List.append(acc, if quoted or c == 34 { c } else { Listing.upper(c) }))
		}

	statement : List(U8), U64, List(Def) -> Sc
	statement = |b, i, fns| {
		j = Listing.skip_ws(b, i)
		kw = Listing.first_kw(b, j, Listing.keywords, 0)
		at = j + List.len(Str.to_utf8(kw))
		if kw == "" {
			Listing.no("A statement with no keyword")
		} else if kw != "GO" and kw != "REM" and kw != "DATA" and Listing.is_alpha(Listing.byte(b, at)) {
			Listing.no("A keyword run together with the word after it")
		} else if kw == "REM" or kw == "POKE" or kw == "PLOT" or kw == "SLEEP" or kw == "PAUSE" {
			Listing.ok(List.len(b), False)
		} else if kw == "END" or kw == "STOP" or kw == "RETURN" or kw == "RESTORE" or kw == "RANDOMIZE" {
			Listing.end(b, at)
		} else if kw == "GOTO" or kw == "GOSUB" {
			Listing.then_end(b, Listing.target(b, at))
		} else if kw == "GO" {
			to = Listing.word(b, at, "TO")
			sub = Listing.word(b, at, "SUB")
			if to != 0 { Listing.then_end(b, Listing.target(b, to)) } else if sub != 0 { Listing.then_end(b, Listing.target(b, sub)) } else { Listing.no("A keyword run together with the word after it") }
		} else if kw == "LET" {
			Listing.st_let(b, at, fns)
		} else if kw == "PRINT" {
			Listing.print_items(b, at, False, fns)
		} else if kw == "IF" {
			Listing.st_if(b, at, fns)
		} else if kw == "ON" {
			Listing.st_on(b, at, fns)
		} else if kw == "FOR" {
			Listing.st_for(b, at, fns)
		} else if kw == "NEXT" {
			k = Listing.skip_ws(b, at)
			if !Listing.is_alpha(Listing.byte(b, k)) { Listing.no("Expected a variable") } else { Listing.end(b, Listing.name_end(b, k)) }
		} else if kw == "DIM" {
			Listing.dim_items(b, at)
		} else if kw == "OPTION" {
			w = Listing.word(b, at, "BASE")
			k = Listing.skip_ws(b, w)
			if w == 0 { Listing.no("Expected BASE") } else if Listing.byte(b, k) != 48 and Listing.byte(b, k) != 49 { Listing.no("OPTION BASE must be 0 or 1") } else { Listing.end(b, k + 1) }
		} else if kw == "DEF" {
			Listing.st_def(b, at, fns)
		} else if kw == "READ" {
			Listing.var_list(b, at, "READ", fns)
		} else if kw == "INPUT" {
			k = Listing.skip_ws(b, at)
			# EXT: a quoted prompt and its separator.
			past = if Listing.byte(b, k) == 34 { Listing.skip_ws(b, Listing.quote_close(b, k + 1) + 1) } else { at }
			Listing.var_list(b, if past != at and (Listing.byte(b, past) == 59 or Listing.byte(b, past) == 44) { past + 1 } else { past }, "INPUT", fns)
		} else {
			Listing.data_items(b, at)
		}
	}

	# GOSUB before GOTO before GO, and every keyword before a word it starts.
	keywords : List(Str)
	keywords = ["DATA", "DEF", "DIM", "END", "FOR", "GOSUB", "GOTO", "GO", "IF", "INPUT", "LET", "NEXT", "ON", "OPTION", "PRINT", "RANDOMIZE", "READ", "REM", "RESTORE", "RETURN", "STOP", "POKE", "PLOT", "SLEEP", "PAUSE"]

	first_kw : List(U8), U64, List(Str), U64 -> Str
	first_kw = |b, j, kws, n|
		if n >= List.len(kws) {
			""
		} else {
			w = List.get(kws, n) ?? ""
			if Listing.starts(b, j, w) { w } else { Listing.first_kw(b, j, kws, n + 1) }
		}

	st_let : List(U8), U64, List(Def) -> Sc
	st_let = |b, at, fns| {
		v = Listing.variable(b, at, "LET", fns)
		k = Listing.skip_ws(b, v.at)
		if v.why != "" {
			v
		} else if Listing.byte(b, k) != 61 {
			Listing.no("Expected =")
		} else {
			e = Listing.expr(b, k + 1, fns)
			if e.why != "" {
				e
			} else if e.str != v.str {
				Listing.no(if v.str { "A number where a string is expected" } else { "A string where a number is expected" })
			} else {
				Listing.end(b, e.at)
			}
		}
	}

	# Items with separators between them; a separator may stand alone.
	print_items : List(U8), U64, Bool, List(Def) -> Sc
	print_items = |b, i, need_sep, fns| {
		j = Listing.skip_ws(b, i)
		c = Listing.byte(b, j)
		if j >= List.len(b) {
			Listing.ok(j, False)
		} else if c == 44 or c == 59 {
			Listing.print_items(b, j + 1, False, fns)
		} else if need_sep {
			Listing.no(if c == 34 { "Two PRINT items with nothing between them" } else { "Text after a PRINT item" })
		} else if Listing.starts(b, j, "TAB") and Listing.next(b, j + 3) == 40 {
			e = Listing.num_expr(b, Listing.skip_ws(b, j + 3) + 1, fns)
			k = Listing.skip_ws(b, e.at)
			if e.why != "" { e } else if Listing.byte(b, k) != 41 { Listing.no("An unmatched parenthesis") } else { Listing.print_items(b, k + 1, True, fns) }
		} else {
			e = Listing.expr(b, j, fns)
			if e.why != "" { e } else { Listing.print_items(b, e.at, True, fns) }
		}
	}

	st_if : List(U8), U64, List(Def) -> Sc
	st_if = |b, at, fns| {
		l = Listing.expr(b, at, fns)
		k = Listing.skip_ws(b, l.at)
		op = Listing.relop_end(b, k)
		if l.why != "" {
			l
		} else if op == k {
			Listing.no("Expected a relational operator")
		} else {
			r = Listing.expr(b, op, fns)
			w = Listing.word(b, r.at, "THEN")
			if r.why != "" {
				r
			} else if r.str != l.str {
				Listing.no("A string compared with a number")
			} else if w == 0 {
				Listing.no("Expected THEN")
			} else if Listing.is_digit(Listing.next(b, w)) {
				Listing.then_end(b, Listing.target(b, w))
			} else {
				# EXT: THEN a statement.
				Listing.statement(b, w, fns)
			}
		}
	}

	relop_end : List(U8), U64 -> U64
	relop_end = |b, k| {
		c = Listing.byte(b, k)
		c2 = Listing.byte(b, k + 1)
		if c == 60 and (c2 == 62 or c2 == 61) { k + 2 } else if c == 62 and c2 == 61 { k + 2 } else if c == 61 or c == 60 or c == 62 { k + 1 } else { k }
	}

	st_on : List(U8), U64, List(Def) -> Sc
	st_on = |b, at, fns| {
		e = Listing.num_expr(b, at, fns)
		go = Listing.word(b, e.at, "GO")
		jump = if go == 0 { 0 } else if Listing.word(b, go, "TO") != 0 { Listing.word(b, go, "TO") } else if Listing.word(b, go, "SUB") != 0 { Listing.word(b, go, "SUB") } else { 0 }
		if e.why != "" { e } else if jump == 0 { Listing.no("Expected GOTO") } else { Listing.jump_targets(b, jump) }
	}

	# `targets` is a reserved word in Roc.
	jump_targets : List(U8), U64 -> Sc
	jump_targets = |b, i| {
		t = Listing.target(b, i)
		k = Listing.skip_ws(b, t.at)
		if t.why != "" { t } else if Listing.byte(b, k) == 44 { Listing.jump_targets(b, k + 1) } else { Listing.end(b, t.at) }
	}

	st_for : List(U8), U64, List(Def) -> Sc
	st_for = |b, at, fns| {
		v = Listing.variable(b, at, "FOR", fns)
		k = Listing.skip_ws(b, v.at)
		if v.why != "" {
			v
		} else if v.str {
			Listing.no("A string where a number is expected")
		} else if Listing.byte(b, k) != 61 {
			Listing.no("Expected =")
		} else {
			from = Listing.num_expr(b, k + 1, fns)
			to = Listing.word(b, from.at, "TO")
			if from.why != "" {
				from
			} else if to == 0 {
				Listing.no("Expected TO")
			} else {
				lim = Listing.num_expr(b, to, fns)
				st = Listing.word(b, lim.at, "STEP")
				if lim.why != "" { lim } else if st == 0 { Listing.end(b, lim.at) } else { Listing.then_end(b, Listing.num_expr(b, st, fns)) }
			}
		}
	}

	dim_items : List(U8), U64 -> Sc
	dim_items = |b, i| {
		j = Listing.skip_ws(b, i)
		if !Listing.is_alpha(Listing.byte(b, j)) {
			Listing.no("Expected an array")
		} else if Listing.is_digit(Listing.byte(b, j + 1)) {
			Listing.no("An array name that is not a single letter")
		} else if Listing.next(b, j + 1) != 40 {
			Listing.no("Expected ( after an array name")
		} else {
			one = Listing.bound(b, Listing.skip_ws(b, j + 1) + 1)
			k = Listing.skip_ws(b, one.at)
			two = if one.why == "" and Listing.byte(b, k) == 44 { Listing.bound(b, k + 1) } else { one }
			c = Listing.skip_ws(b, two.at)
			if two.why != "" {
				two
			} else if Listing.byte(b, c) != 41 {
				Listing.no("An unmatched parenthesis")
			} else if Listing.next(b, c + 1) == 44 {
				Listing.dim_items(b, Listing.skip_ws(b, c + 1) + 1)
			} else {
				Listing.end(b, c + 1)
			}
		}
	}

	bound : List(U8), U64 -> Sc
	bound = |b, i| {
		j = Listing.skip_ws(b, i)
		if Listing.is_digit(Listing.byte(b, j)) { Listing.ok(Listing.number_end(b, j), False) } else { Listing.no("A DIM bound that is not a number") }
	}

	st_def : List(U8), U64, List(Def) -> Sc
	st_def = |b, at, fns| {
		j = Listing.skip_ws(b, at)
		if !(Listing.starts(b, j, "FN") and Listing.is_alpha(Listing.byte(b, j + 2))) {
			Listing.no("Expected FN and a letter after DEF")
		} else {
			k = Listing.skip_ws(b, j + 3)
			if Listing.byte(b, k) != 40 {
				Listing.def_body(b, k, fns)
			} else {
				p = Listing.skip_ws(b, k + 1)
				e = Listing.name_end(b, p)
				r = Listing.skip_ws(b, e)
				if !Listing.is_alpha(Listing.byte(b, p)) {
					Listing.no("Expected a parameter")
				} else if Listing.byte(b, e) == 36 {
					Listing.no("A DEF whose parameter is a string")
				} else if Listing.byte(b, r) == 44 {
					Listing.no("A DEF with more than one parameter")
				} else if Listing.byte(b, r) != 41 {
					Listing.no("An unmatched parenthesis")
				} else {
					Listing.def_body(b, Listing.skip_ws(b, r + 1), fns)
				}
			}
		}
	}

	def_body : List(U8), U64, List(Def) -> Sc
	def_body = |b, k, fns| if Listing.byte(b, k) != 61 { Listing.no("Expected =") } else { Listing.then_end(b, Listing.num_expr(b, k + 1, fns)) }

	var_list : List(U8), U64, Str, List(Def) -> Sc
	var_list = |b, i, what, fns| {
		v = Listing.variable(b, i, what, fns)
		k = Listing.skip_ws(b, v.at)
		if v.why != "" { v } else if Listing.byte(b, k) == 44 { Listing.var_list(b, k + 1, what, fns) } else { Listing.end(b, v.at) }
	}

	# A target of LET, FOR, READ or INPUT: a name, a string name, or an
	# array element.
	variable : List(U8), U64, Str, List(Def) -> Sc
	variable = |b, i, what, fns| {
		j = Listing.skip_ws(b, i)
		c = Listing.byte(b, j)
		if j >= List.len(b) or c == 44 {
			Listing.no(Str.concat(Str.concat("An empty entry in the ", what), " list"))
		} else if !Listing.is_alpha(c) {
			Listing.no("Expected a variable")
		} else {
			Listing.name_ref(b, j, fns)
		}
	}

	data_items : List(U8), U64 -> Sc
	data_items = |b, i| {
		j = Listing.skip_ws(b, i)
		if Listing.byte(b, j) == 34 {
			q = Listing.quote_close(b, j + 1)
			k = Listing.skip_ws(b, q + 1)
			if q >= List.len(b) {
				Listing.no("A quoted string with no closing quote")
			} else if k >= List.len(b) {
				Listing.ok(k, False)
			} else if Listing.byte(b, k) == 44 {
				Listing.data_items(b, k + 1)
			} else {
				Listing.no("Text after a quoted datum")
			}
		} else {
			e = Listing.item_end(b, j)
			if Listing.skip_ws(b, j) >= e {
				Listing.no("An empty datum in DATA")
			} else if !Listing.plain(b, j, e) {
				Listing.no("A character not allowed in an unquoted datum")
			} else if Listing.byte(b, e) == 44 {
				Listing.data_items(b, e + 1)
			} else {
				Listing.ok(e, False)
			}
		}
	}

	item_end : List(U8), U64 -> U64
	item_end = |b, i| if i >= List.len(b) or Listing.byte(b, i) == 44 { i } else { Listing.item_end(b, i + 1) }

	# An unquoted datum is letters, digits, spaces, `+`, `-` and `.`.
	plain : List(U8), U64, U64 -> Bool
	plain = |b, i, e|
		if i >= e {
			True
		} else {
			c = Listing.byte(b, i)
			if Listing.is_alpha(c) or Listing.is_digit(c) or c == 32 or c == 43 or c == 45 or c == 46 { Listing.plain(b, i + 1, e) } else { False }
		}

	# ---- expressions -------------------------------------------------------

	expr : List(U8), U64, List(Def) -> Sc
	expr = |b, i, fns| {
		t = Listing.term(b, i, fns)
		if t.why != "" { t } else { Listing.expr_rest(b, t, fns) }
	}

	expr_rest : List(U8), Sc, List(Def) -> Sc
	expr_rest = |b, t, fns| {
		j = Listing.skip_ws(b, t.at)
		c = Listing.byte(b, j)
		if c != 43 and c != 45 {
			t
		} else {
			u = Listing.term(b, j + 1, fns)
			if u.why != "" {
				u
			} else if c == 45 and (t.str or u.str) {
				Listing.no("A string where a number is expected")
			} else if t.str != u.str {
				Listing.no(if t.str { "A number where a string is expected" } else { "A string where a number is expected" })
			} else {
				# EXT: `+` joins two strings.
				Listing.expr_rest(b, { at: u.at, why: "", str: t.str }, fns)
			}
		}
	}

	num_expr : List(U8), U64, List(Def) -> Sc
	num_expr = |b, i, fns| {
		e = Listing.expr(b, i, fns)
		if e.why == "" and e.str { Listing.no("A string where a number is expected") } else { e }
	}

	term : List(U8), U64, List(Def) -> Sc
	term = |b, i, fns| {
		f = Listing.factor(b, i, fns)
		if f.why != "" { f } else { Listing.term_rest(b, f, fns) }
	}

	term_rest : List(U8), Sc, List(Def) -> Sc
	term_rest = |b, t, fns| {
		j = Listing.skip_ws(b, t.at)
		c = Listing.byte(b, j)
		if c == 42 and Listing.byte(b, j + 1) == 42 {
			Listing.no("The ** operator")
		} else if c != 42 and c != 47 {
			t
		} else {
			u = Listing.factor(b, j + 1, fns)
			if u.why != "" { u } else if t.str or u.str { Listing.no("A string where a number is expected") } else { Listing.term_rest(b, u, fns) }
		}
	}

	factor : List(U8), U64, List(Def) -> Sc
	factor = |b, i, fns| {
		p = Listing.primary(b, i, fns)
		if p.why != "" { p } else { Listing.factor_rest(b, p, fns) }
	}

	factor_rest : List(U8), Sc, List(Def) -> Sc
	factor_rest = |b, t, fns| {
		j = Listing.skip_ws(b, t.at)
		if Listing.byte(b, j) != 94 {
			t
		} else {
			u = Listing.primary(b, j + 1, fns)
			if u.why != "" { u } else if t.str or u.str { Listing.no("A string where a number is expected") } else { Listing.factor_rest(b, u, fns) }
		}
	}

	primary : List(U8), U64, List(Def) -> Sc
	primary = |b, i, fns| {
		j = Listing.skip_ws(b, i)
		c = Listing.byte(b, j)
		if c == 43 or c == 45 {
			# EXT: a sign after an operator, `4 ^ -2`.
			p = Listing.primary(b, j + 1, fns)
			if p.why == "" and p.str { Listing.no("A string where a number is expected") } else { p }
		} else if c == 40 {
			e = Listing.expr(b, j + 1, fns)
			k = Listing.skip_ws(b, e.at)
			if e.why != "" { e } else if Listing.byte(b, k) != 41 { Listing.no("An unmatched parenthesis") } else { { at: k + 1, why: "", str: e.str } }
		} else if c == 34 {
			q = Listing.quote_close(b, j + 1)
			if q >= List.len(b) { Listing.no("A quoted string with no closing quote") } else { Listing.ok(q + 1, True) }
		} else if Listing.is_digit(c) or c == 46 {
			Listing.ok(Listing.number_end(b, j), False)
		} else if !Listing.is_alpha(c) {
			Listing.no("Expected an expression")
		} else if Listing.starts(b, j, "FN") and Listing.is_alpha(Listing.byte(b, j + 2)) {
			Listing.call_fn(b, j + 3, Listing.byte(b, j + 2), fns)
		} else {
			w = Listing.word_end(b, j)
			name = Listing.text(b, j, w)
			if Listing.byte(b, w) == 36 and (name == "CHR" or name == "STR" or name == "LEFT" or name == "RIGHT" or name == "MID") {
				Listing.ok(Listing.loose_args(b, w + 1), True)
			} else if name == "LEN" or name == "ASC" or name == "VAL" or name == "PEEK" {
				Listing.ok(Listing.loose_args(b, w), False)
			} else if Listing.is_builtin(name) {
				Listing.call_builtin(b, w, name, fns)
			} else {
				Listing.name_ref(b, j, fns)
			}
		}
	}

	# A letter and an optional digit, then `$` for a string, or `(` for an
	# array element, whose name is one letter.
	name_ref : List(U8), U64, List(Def) -> Sc
	name_ref = |b, j, fns| {
		e = Listing.name_end(b, j)
		if Listing.byte(b, e) == 36 {
			Listing.ok(e + 1, True)
		} else if Listing.next(b, e) != 40 {
			Listing.ok(e, False)
		} else if e > j + 1 {
			Listing.no("An array name that is not a single letter")
		} else {
			s1 = Listing.num_expr(b, Listing.skip_ws(b, e) + 1, fns)
			k = Listing.skip_ws(b, s1.at)
			s2 = if s1.why == "" and Listing.byte(b, k) == 44 { Listing.num_expr(b, k + 1, fns) } else { s1 }
			c = Listing.skip_ws(b, s2.at)
			if s2.why != "" { s2 } else if Listing.byte(b, c) != 41 { Listing.no("An unmatched parenthesis") } else { Listing.ok(c + 1, False) }
		}
	}

	name_end : List(U8), U64 -> U64
	name_end = |b, j| if Listing.is_digit(Listing.byte(b, j + 1)) { j + 2 } else { j + 1 }

	is_builtin : Str -> Bool
	is_builtin = |k| k == "ABS" or k == "ATN" or k == "COS" or k == "EXP" or k == "INT" or k == "LOG" or k == "SGN" or k == "SIN" or k == "SQR" or k == "TAN" or k == "RND"

	# ECMA-55's RND takes no argument; the rest take one.
	call_builtin : List(U8), U64, Str, List(Def) -> Sc
	call_builtin = |b, w, name, fns| {
		a = Listing.count_args(b, w, name, fns)
		takes_one = name != "RND"
		# `a.str` is whether there was an argument, not a type: the call
		# itself is a number.
		if a.why != "" { a } else if a.str != takes_one { Listing.wrong_args(name) } else { Listing.ok(a.at, False) }
	}

	# A user function takes one argument when its DEF has a parameter and
	# none when it does not. One with no DEF anywhere is the next pass's.
	call_fn : List(U8), U64, U8, List(Def) -> Sc
	call_fn = |b, at, letter, fns| {
		name = Str.concat("FN", Str.from_utf8([letter]) ?? "")
		a = Listing.count_args(b, at, name, fns)
		want = Listing.fn_arity(fns, letter, 0)
		if a.why != "" { a } else if want < 2 and a.str != (want == 1) { Listing.wrong_args(name) } else { Listing.ok(a.at, False) }
	}

	# 0 or 1 from the DEF, 2 when there is no DEF.
	fn_arity : List(Def), U8, U64 -> U8
	fn_arity = |fns, letter, n|
		if n >= List.len(fns) {
			2
		} else {
			f = List.get(fns, n) ?? { k: 0, param: False }
			if f.k == letter { if f.param { 1 } else { 0 } } else { Listing.fn_arity(fns, letter, n + 1) }
		}

	# Reads an argument list and answers, in `str`, whether there was one:
	# exactly one numeric argument, or nothing at all. `()` and two or more
	# are refused here, so a caller only has to compare presence.
	count_args : List(U8), U64, Str, List(Def) -> Sc
	count_args = |b, w, name, fns| {
		j = Listing.skip_ws(b, w)
		if Listing.byte(b, j) != 40 {
			Listing.ok(w, False)
		} else if Listing.next(b, j + 1) == 41 {
			Listing.wrong_args(name)
		} else {
			e = Listing.num_expr(b, j + 1, fns)
			k = Listing.skip_ws(b, e.at)
			if e.why != "" { e } else if Listing.byte(b, k) == 44 { Listing.wrong_args(name) } else if Listing.byte(b, k) != 41 { Listing.no("An unmatched parenthesis") } else { Listing.ok(k + 1, True) }
		}
	}

	wrong_args : Str -> Sc
	wrong_args = |name| Listing.no(Str.concat(name, " given the wrong number of arguments"))

	# The extension functions are not checked: skip a balanced `( ... )`.
	loose_args : List(U8), U64 -> U64
	loose_args = |b, w| {
		j = Listing.skip_ws(b, w)
		if Listing.byte(b, j) != 40 { w } else { Listing.skip_parens(b, j + 1, 1) }
	}

	skip_parens : List(U8), U64, U64 -> U64
	skip_parens = |b, i, depth|
		if depth == 0 or i >= List.len(b) {
			i
		} else {
			c = Listing.byte(b, i)
			if c == 34 {
				Listing.skip_parens(b, Listing.quote_close(b, i + 1) + 1, depth)
			} else if c == 40 {
				Listing.skip_parens(b, i + 1, depth + 1)
			} else if c == 41 {
				Listing.skip_parens(b, i + 1, depth - 1)
			} else {
				Listing.skip_parens(b, i + 1, depth)
			}
		}

	# ---- small pieces ------------------------------------------------------

	ok : U64, Bool -> Sc
	ok = |at, s| { at: at, why: "", str: s }

	no : Str -> Sc
	no = |why| { at: 0, why: why, str: False }

	end : List(U8), U64 -> Sc
	end = |b, i| if Listing.skip_ws(b, i) < List.len(b) { Listing.no("Text after the end of a statement") } else { Listing.ok(i, False) }

	then_end : List(U8), Sc -> Sc
	then_end = |b, r| if r.why != "" { r } else { Listing.end(b, r.at) }

	target : List(U8), U64 -> Sc
	target = |b, i| {
		j = Listing.skip_ws(b, i)
		if Listing.is_digit(Listing.byte(b, j)) { Listing.ok(Listing.digits_end(b, j), False) } else { Listing.no("Expected a line number") }
	}

	# Where a keyword inside a statement ends, or 0 when it is not there.
	word : List(U8), U64, Str -> U64
	word = |b, i, w| {
		j = Listing.skip_ws(b, i)
		if Listing.starts(b, j, w) { j + List.len(Str.to_utf8(w)) } else { 0 }
	}

	number_end : List(U8), U64 -> U64
	number_end = |b, j| {
		a = Listing.digits_end(b, j)
		p = if Listing.byte(b, a) == 46 { Listing.digits_end(b, a + 1) } else { a }
		s = if Listing.byte(b, p + 1) == 43 or Listing.byte(b, p + 1) == 45 { p + 2 } else { p + 1 }
		if Listing.byte(b, p) == 69 and Listing.is_digit(Listing.byte(b, s)) { Listing.digits_end(b, s) } else { p }
	}

	quote_close : List(U8), U64 -> U64
	quote_close = |b, i| if i >= List.len(b) or Listing.byte(b, i) == 34 { i } else { Listing.quote_close(b, i + 1) }

	word_end : List(U8), U64 -> U64
	word_end = |b, i| if Listing.is_alpha(Listing.byte(b, i)) { Listing.word_end(b, i + 1) } else { i }

	text : List(U8), U64, U64 -> Str
	text = |b, i, e| Str.from_utf8(List.sublist(b, { start: i, len: e - i })) ?? ""

	starts : List(U8), U64, Str -> Bool
	starts = |b, i, w| Listing.starts_from(b, i, Str.to_utf8(w), 0)

	starts_from : List(U8), U64, List(U8), U64 -> Bool
	starts_from = |b, i, w, k|
		if k >= List.len(w) {
			True
		} else if Listing.byte(b, i + k) != (List.get(w, k) ?? 0) {
			False
		} else {
			Listing.starts_from(b, i, w, k + 1)
		}

	# The byte at the next non-blank.
	next : List(U8), U64 -> U8
	next = |b, i| Listing.byte(b, Listing.skip_ws(b, i))

	byte : List(U8), U64 -> U8
	byte = |b, i| List.get(b, i) ?? 0

	eol : List(U8), U64 -> U64
	eol = |b, i| if i >= List.len(b) or Listing.byte(b, i) == 10 { i } else { Listing.eol(b, i + 1) }

	skip_ws : List(U8), U64 -> U64
	skip_ws = |b, i| if Listing.byte(b, i) == 32 or Listing.byte(b, i) == 9 { Listing.skip_ws(b, i + 1) } else { i }

	is_digit : U8 -> Bool
	is_digit = |c| c >= 48 and c <= 57

	is_alpha : U8 -> Bool
	is_alpha = |c| (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

	upper : U8 -> U8
	upper = |c| if c >= 97 and c <= 122 { c - 32 } else { c }

	digits_end : List(U8), U64 -> U64
	digits_end = |b, i| if Listing.is_digit(Listing.byte(b, i)) { Listing.digits_end(b, i + 1) } else { i }

	# Only the first nine digits count: a line number past four is refused
	# by length, and an I64 that `*` overflows is a crash in Roc.
	digits_val : List(U8), U64, U64, I64 -> I64
	digits_val = |b, i, e, acc|
		if i >= e or acc > 99999999 { acc } else { Listing.digits_val(b, i + 1, e, acc * 10 + U8.to_i64(Listing.byte(b, i)) - 48) }
}
