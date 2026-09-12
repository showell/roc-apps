# The faults of an ECMA-55 program as a whole, which no one line shows: a
# jump to a line that is not there, a FOR and a NEXT that do not pair, a
# function used before or without its DEF, and an array whose DIM, OPTION
# BASE and uses disagree.
#
# It runs after Listing has accepted every line, so the text is well formed
# and a plain tokenizer reads it: the facts are collected in line order
# (Listing has already refused lines out of order), then judged.

import Listing

Program :: [].{
	# k: 1 number, 2 known word, 3 FN name, 4 name, 5 operator, 6 quoted.
	Tok : { k : U8, v : Str }

	Jump : { from : I64, to : I64 }
	Loop : { n : I64, open : Bool, v : Str }
	Named : { name : Str, n : I64 }
	Dim : { name : Str, n : I64, arity : U64, low : I64 }
	Use : { name : Str, n : I64, arity : U64 }

	Facts : {
		nums : List(I64),
		jumps : List(Jump),
		loops : List(Loop),
		defs : List(Named),
		fn_uses : List(Named),
		dims : List(Dim),
		options : List(Named),
		arrays : List(Use),
		simples : List(Named),
		why : Str,
		at : I64,
	}

	check : Str -> Listing.Rejection
	check = |src| {
		f = Program.collect(Str.to_utf8(src), 0, { nums: [], jumps: [], loops: [], defs: [], fn_uses: [], dims: [], options: [], arrays: [], simples: [], why: "", at: -1 })
		if f.why != "" { { why: f.why, num: f.at } } else { Program.judge(f) }
	}

	# ---- the facts ---------------------------------------------------------

	collect : List(U8), U64, Facts -> Facts
	collect = |b, i, f|
		if i >= List.len(b) or f.why != "" {
			f
		} else {
			e = Listing.eol(b, i)
			stop = if e > i and Listing.byte(b, e - 1) == 13 { e - 1 } else { e }
			s = Listing.skip_ws(b, i)
			if s >= stop {
				Program.collect(b, e + 1, f)
			} else {
				d = Listing.digits_end(b, s)
				n = Listing.digits_val(b, s, d, 0)
				body = Listing.upper_body(b, Listing.skip_ws(b, d), stop, False, [])
				Program.collect(b, e + 1, Program.line_facts({ ..f, nums: List.append(f.nums, n) }, n, Program.tokens(body, 0, [])))
			}
		}

	line_facts : Facts, I64, List(Tok) -> Facts
	line_facts = |f, n, ts| {
		kw = Program.tok_v(ts, 0)
		if Program.tok_k(ts, 0) != 2 or kw == "REM" or kw == "DATA" {
			f
		} else {
			f1 = { ..f, jumps: Program.jumps_in(ts, 0, n, f.jumps) }
			if kw == "DIM" {
				Program.dim_facts(f1, n, ts, 1)
			} else if kw == "DEF" {
				name = Program.tok_v(ts, 1)
				body_from = if Program.tok_v(ts, 2) == "(" { 6 } else { 3 }
				if Program.named_line(f1.defs, name, 0) >= 0 {
					{ ..f1, why: "A function defined twice", at: n }
				} else if Program.has_tok(ts, body_from, 3, name) {
					{ ..f1, why: "A function that refers to itself", at: n }
				} else {
					Program.refs({ ..f1, defs: List.append(f1.defs, { name: name, n: n }) }, n, ts, body_from)
				}
			} else {
				f2 = if kw == "FOR" or kw == "NEXT" { { ..f1, loops: List.append(f1.loops, { n: n, open: kw == "FOR", v: Program.tok_v(ts, 1) }) } } else { f1 }
				f3 = if kw == "OPTION" { { ..f2, options: List.append(f2.options, { name: Program.tok_v(ts, 2), n: n }) } } else { f2 }
				Program.refs(f3, n, ts, 1)
			}
		}
	}

	# GOTO, GOSUB and THEN, and TO and SUB after GO, each followed by line
	# numbers -- a list of them, after ON.
	jumps_in : List(Tok), U64, I64, List(Jump) -> List(Jump)
	jumps_in = |ts, idx, n, acc|
		if idx >= List.len(ts) {
			acc
		} else {
			v = Program.tok_v(ts, idx)
			after_go = idx > 0 and Program.tok_v(ts, idx - 1) == "GO"
			jumping = Program.tok_k(ts, idx) == 2 and (v == "GOTO" or v == "GOSUB" or v == "THEN" or (after_go and (v == "TO" or v == "SUB")))
			Program.jumps_in(ts, idx + 1, n, if jumping { Program.jump_list(ts, idx + 1, n, acc) } else { acc })
		}

	jump_list : List(Tok), U64, I64, List(Jump) -> List(Jump)
	jump_list = |ts, j, n, acc|
		if Program.tok_k(ts, j) != 1 {
			acc
		} else {
			more = List.append(acc, { from: n, to: Program.int_of(Program.tok_v(ts, j)) })
			if Program.tok_v(ts, j + 1) == "," { Program.jump_list(ts, j + 2, n, more) } else { more }
		}

	# `DIM A(n), B(n, m)`: the arity and the smallest bound of each.
	dim_facts : Facts, I64, List(Tok), U64 -> Facts
	dim_facts = |f, n, ts, j|
		if j >= List.len(ts) {
			f
		} else {
			name = Program.tok_v(ts, j)
			one = Program.int_of(Program.tok_v(ts, j + 2))
			two = Program.tok_v(ts, j + 3) == ","
			low = if two and Program.int_of(Program.tok_v(ts, j + 4)) < one { Program.int_of(Program.tok_v(ts, j + 4)) } else { one }
			past = if two { j + 6 } else { j + 4 }
			if Program.dim_index(f.dims, name, 0) >= 0 {
				{ ..f, why: "An array dimensioned twice", at: n }
			} else {
				Program.dim_facts({ ..f, dims: List.append(f.dims, { name: name, n: n, arity: if two { 2 } else { 1 }, low: low }) }, n, ts, if Program.tok_v(ts, past) == "," { past + 1 } else { past })
			}
		}

	# Every use of a user function, an array element or a simple numeric
	# variable from token `from` on.
	refs : Facts, I64, List(Tok), U64 -> Facts
	refs = |f, n, ts, idx|
		if idx >= List.len(ts) {
			f
		} else {
			k = Program.tok_k(ts, idx)
			v = Program.tok_v(ts, idx)
			f1 = if k == 3 {
				{ ..f, fn_uses: List.append(f.fn_uses, { name: v, n: n }) }
			} else if k == 4 and !Str.ends_with(v, "$") {
				if Program.tok_v(ts, idx + 1) == "(" {
					{ ..f, arrays: List.append(f.arrays, { name: v, n: n, arity: Program.arity(ts, idx + 1, 0, 1) }) }
				} else {
					{ ..f, simples: List.append(f.simples, { name: v, n: n }) }
				}
			} else {
				f
			}
			Program.refs(f1, n, ts, idx + 1)
		}

	# Top-level commas inside the parenthesis at `j`, plus one.
	arity : List(Tok), U64, U64, U64 -> U64
	arity = |ts, j, depth, count|
		if j >= List.len(ts) {
			count
		} else {
			v = Program.tok_v(ts, j)
			if Program.tok_k(ts, j) != 5 {
				Program.arity(ts, j + 1, depth, count)
			} else if v == "(" {
				Program.arity(ts, j + 1, depth + 1, count)
			} else if v == ")" {
				if depth == 1 { count } else { Program.arity(ts, j + 1, depth - 1, count) }
			} else if v == "," and depth == 1 {
				Program.arity(ts, j + 1, depth, count + 1)
			} else {
				Program.arity(ts, j + 1, depth, count)
			}
		}

	# ---- the judgement -----------------------------------------------------

	judge : Facts -> Listing.Rejection
	judge = |f| {
		missing = Program.missing_target(f.jumps, f.nums, 0)
		if missing.why != "" { missing } else {
			loops = Program.pair_loops(f.loops, 0, [], [])
			if loops.why != "" { { why: loops.why, num: loops.at } } else {
				into = Program.jump_into(f.jumps, loops.blocks, 0)
				if into.why != "" { into } else {
					fns = Program.fn_order(f.fn_uses, f.defs, 0)
					if fns.why != "" { fns } else { Program.arrays_judged(f) }
				}
			}
		}
	}

	fine : Listing.Rejection
	fine = { why: "", num: -1 }

	missing_target : List(Jump), List(I64), U64 -> Listing.Rejection
	missing_target = |js, nums, i|
		if i >= List.len(js) {
			Program.fine
		} else {
			j = List.get(js, i) ?? { from: 0, to: 0 }
			if List.contains(nums, j.to) { Program.missing_target(js, nums, i + 1) } else { { why: "A jump to a line that does not exist", num: j.from } }
		}

	Paired : { why : Str, at : I64, blocks : List(Jump) }

	# A stack of open FORs; a block is a FOR's line and its NEXT's.
	pair_loops : List(Loop), U64, List(Loop), List(Jump) -> Paired
	pair_loops = |ls, i, stack, blocks|
		if i >= List.len(ls) {
			if List.is_empty(stack) { { why: "", at: -1, blocks: blocks } } else { { why: "A FOR without a NEXT", at: (List.last(stack) ?? { n: -1, open: True, v: "" }).n, blocks: blocks } }
		} else {
			l = List.get(ls, i) ?? { n: -1, open: True, v: "" }
			top = List.last(stack) ?? { n: -1, open: True, v: "" }
			if l.open and Program.loop_open(stack, l.v, 0) {
				{ why: "A FOR inside a FOR with the same variable", at: l.n, blocks: blocks }
			} else if l.open {
				Program.pair_loops(ls, i + 1, List.append(stack, l), blocks)
			} else if List.is_empty(stack) {
				{ why: "A NEXT without a FOR", at: l.n, blocks: blocks }
			} else if top.v != l.v {
				{ why: "A NEXT that does not match its FOR", at: l.n, blocks: blocks }
			} else {
				Program.pair_loops(ls, i + 1, List.drop_last(stack, 1), List.append(blocks, { from: top.n, to: l.n }))
			}
		}

	loop_open : List(Loop), Str, U64 -> Bool
	loop_open = |stack, v, i|
		if i >= List.len(stack) { False } else if (List.get(stack, i) ?? { n: -1, open: True, v: "" }).v == v { True } else { Program.loop_open(stack, v, i + 1) }

	# A jump from outside a FOR block to a line inside it, past the FOR.
	jump_into : List(Jump), List(Jump), U64 -> Listing.Rejection
	jump_into = |js, blocks, i|
		if i >= List.len(js) {
			Program.fine
		} else {
			j = List.get(js, i) ?? { from: 0, to: 0 }
			if Program.enters(blocks, j, 0) { { why: "A jump into a FOR block", num: j.from } } else { Program.jump_into(js, blocks, i + 1) }
		}

	enters : List(Jump), Jump, U64 -> Bool
	enters = |blocks, j, i|
		if i >= List.len(blocks) {
			False
		} else {
			bl = List.get(blocks, i) ?? { from: 0, to: 0 }
			if bl.from < j.to and j.to <= bl.to and !(bl.from <= j.from and j.from <= bl.to) { True } else { Program.enters(blocks, j, i + 1) }
		}

	fn_order : List(Named), List(Named), U64 -> Listing.Rejection
	fn_order = |uses, defs, i|
		if i >= List.len(uses) {
			Program.fine
		} else {
			u = List.get(uses, i) ?? { name: "", n: 0 }
			at = Program.named_line(defs, u.name, 0)
			if at < 0 {
				{ why: "A function with no DEF", num: u.n }
			} else if u.n < at {
				{ why: "A function used before its DEF", num: u.n }
			} else {
				Program.fn_order(uses, defs, i + 1)
			}
		}

	arrays_judged : Facts -> Listing.Rejection
	arrays_judged = |f| {
		first = List.get(f.options, 0) ?? { name: "0", n: -1 }
		base = Program.int_of(first.name)
		if List.len(f.options) > 1 {
			{ why: "OPTION BASE twice", num: (List.get(f.options, 1) ?? first).n }
		} else if first.n >= 0 and Program.any_dim_before(f.dims, first.n, 0) {
			{ why: "OPTION BASE after a DIM", num: first.n }
		} else if first.n >= 0 and Program.any_use_before(f.arrays, first.n, 0) {
			{ why: "OPTION BASE after an array is used", num: first.n }
		} else {
			low = Program.low_dim(f.dims, base, 0)
			if low.why != "" { low } else {
				uses = Program.array_uses(f.arrays, f.dims, 0, [])
				if uses.why != "" { uses } else { Program.clash(f.simples, f.dims, f.arrays, 0) }
			}
		}
	}

	any_dim_before : List(Dim), I64, U64 -> Bool
	any_dim_before = |ds, n, i|
		if i >= List.len(ds) { False } else if (List.get(ds, i) ?? { name: "", n: n, arity: 1, low: 0 }).n < n { True } else { Program.any_dim_before(ds, n, i + 1) }

	any_use_before : List(Use), I64, U64 -> Bool
	any_use_before = |us, n, i|
		if i >= List.len(us) { False } else if (List.get(us, i) ?? { name: "", n: n, arity: 1 }).n < n { True } else { Program.any_use_before(us, n, i + 1) }

	low_dim : List(Dim), I64, U64 -> Listing.Rejection
	low_dim = |ds, base, i|
		if i >= List.len(ds) {
			Program.fine
		} else {
			d = List.get(ds, i) ?? { name: "", n: 0, arity: 1, low: base }
			if d.low < base { { why: "A DIM bound below OPTION BASE", num: d.n } } else { Program.low_dim(ds, base, i + 1) }
		}

	# `seen` is the first arity of each array with no DIM.
	array_uses : List(Use), List(Dim), U64, List(Use) -> Listing.Rejection
	array_uses = |us, ds, i, seen|
		if i >= List.len(us) {
			Program.fine
		} else {
			u = List.get(us, i) ?? { name: "", n: 0, arity: 1 }
			di = Program.dim_index(ds, u.name, 0)
			d = List.get(ds, I64.to_u64_wrap(di)) ?? { name: "", n: 0, arity: u.arity, low: 0 }
			si = Program.use_index(seen, u.name, 0)
			s = List.get(seen, I64.to_u64_wrap(si)) ?? u
			if di >= 0 and u.n < d.n {
				{ why: "An array used before its DIM", num: u.n }
			} else if di >= 0 and u.arity != d.arity {
				{ why: "An array used with different numbers of subscripts", num: u.n }
			} else if di < 0 and si >= 0 and s.arity != u.arity {
				{ why: "An array used with different numbers of subscripts", num: u.n }
			} else {
				Program.array_uses(us, ds, i + 1, if di < 0 and si < 0 { List.append(seen, u) } else { seen })
			}
		}

	clash : List(Named), List(Dim), List(Use), U64 -> Listing.Rejection
	clash = |ss, ds, us, i|
		if i >= List.len(ss) {
			Program.fine
		} else {
			s = List.get(ss, i) ?? { name: "", n: 0 }
			if Program.dim_index(ds, s.name, 0) >= 0 or Program.use_index(us, s.name, 0) >= 0 {
				{ why: "A name used for both an array and a simple variable", num: s.n }
			} else {
				Program.clash(ss, ds, us, i + 1)
			}
		}

	# ---- lookups -----------------------------------------------------------

	named_line : List(Named), Str, U64 -> I64
	named_line = |xs, name, i|
		if i >= List.len(xs) { -1 } else if (List.get(xs, i) ?? { name: "", n: -1 }).name == name { (List.get(xs, i) ?? { name: "", n: -1 }).n } else { Program.named_line(xs, name, i + 1) }

	dim_index : List(Dim), Str, U64 -> I64
	dim_index = |ds, name, i|
		if i >= List.len(ds) { -1 } else if (List.get(ds, i) ?? { name: "", n: 0, arity: 1, low: 0 }).name == name { U64.to_i64_wrap(i) } else { Program.dim_index(ds, name, i + 1) }

	use_index : List(Use), Str, U64 -> I64
	use_index = |us, name, i|
		if i >= List.len(us) { -1 } else if (List.get(us, i) ?? { name: "", n: 0, arity: 1 }).name == name { U64.to_i64_wrap(i) } else { Program.use_index(us, name, i + 1) }

	has_tok : List(Tok), U64, U8, Str -> Bool
	has_tok = |ts, i, k, v|
		if i >= List.len(ts) { False } else if Program.tok_k(ts, i) == k and Program.tok_v(ts, i) == v { True } else { Program.has_tok(ts, i + 1, k, v) }

	tok_k : List(Tok), U64 -> U8
	tok_k = |ts, i| (List.get(ts, i) ?? { k: 0, v: "" }).k

	tok_v : List(Tok), U64 -> Str
	tok_v = |ts, i| (List.get(ts, i) ?? { k: 0, v: "" }).v

	int_of : Str -> I64
	int_of = |v| {
		b = Str.to_utf8(v)
		Listing.digits_val(b, 0, Listing.digits_end(b, 0), 0)
	}

	# ---- the tokenizer -----------------------------------------------------

	tokens : List(U8), U64, List(Tok) -> List(Tok)
	tokens = |b, i, acc| {
		j = Listing.skip_ws(b, i)
		c = Listing.byte(b, j)
		if j >= List.len(b) {
			acc
		} else if c == 34 {
			q = Listing.quote_close(b, j + 1)
			e = if q >= List.len(b) { q } else { q + 1 }
			Program.tokens(b, e, List.append(acc, { k: 6, v: Listing.text(b, j, e) }))
		} else if Listing.is_digit(c) or (c == 46 and Listing.is_digit(Listing.byte(b, j + 1))) {
			e = Listing.number_end(b, j)
			Program.tokens(b, e, List.append(acc, { k: 1, v: Listing.text(b, j, e) }))
		} else if Listing.starts(b, j, "FN") and Listing.is_alpha(Listing.byte(b, j + 2)) {
			Program.tokens(b, j + 3, List.append(acc, { k: 3, v: Listing.text(b, j, j + 3) }))
		} else if Listing.is_alpha(c) {
			w = Listing.first_kw(b, j, Program.known, 0)
			if w != "" {
				e = j + List.len(Str.to_utf8(w))
				Program.tokens(b, e, List.append(acc, { k: 2, v: w }))
			} else {
				e0 = Listing.name_end(b, j)
				e = if Listing.byte(b, e0) == 36 { e0 + 1 } else { e0 }
				Program.tokens(b, e, List.append(acc, { k: 4, v: Listing.text(b, j, e) }))
			}
		} else {
			Program.tokens(b, j + 1, List.append(acc, { k: 5, v: Listing.text(b, j, j + 1) }))
		}
	}

	# Every word a well-formed line can hold, longest first, so a word is
	# never read as a shorter one it starts with.
	known : List(Str)
	known = ["RANDOMIZE", "RESTORE", "OPTION", "RETURN", "RIGHT$", "GOSUB", "INPUT", "PRINT", "PAUSE", "SLEEP", "LEFT$", "DATA", "GOTO", "NEXT", "STOP", "POKE", "PLOT", "THEN", "STEP", "BASE", "PEEK", "CHR$", "STR$", "MID$", "DEF", "DIM", "END", "FOR", "LET", "REM", "ABS", "ATN", "COS", "EXP", "INT", "LOG", "SGN", "SIN", "SQR", "TAN", "RND", "SUB", "TAB", "LEN", "ASC", "VAL", "GO", "IF", "ON", "TO"]
}
