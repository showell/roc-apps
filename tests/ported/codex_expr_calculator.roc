# expr-calculator
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/expr-calculator.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     === Expression Calculator ===
#     
#     PASS: 42 = 42 (expected 42)  tree: 42
#     PASS: 2 + 3 = 5 (expected 5)  tree: (2 + 3)
#     PASS: 10 - 4 = 6 (expected 6)  tree: (10 - 4)
#     PASS: 3 * 7 = 21 (expected 21)  tree: (3 * 7)
#     PASS: 100 / 5 = 20 (expected 20)  tree: (100 / 5)
#     PASS: 2 + 3 * 4 = 14 (expected 14)  tree: (2 + (3 * 4))
#     PASS: 10 - 2 * 3 = 4 (expected 4)  tree: (10 - (2 * 3))
#     PASS: (2 + 3) * 4 = 20 (expected 20)  tree: ((2 + 3) * 4)
#     PASS: 1 + 2 + 3 + 4 = 10 (expected 10)  tree: (((1 + 2) + 3) + 4)
#     PASS: 2 * 3 + 4 * 5 = 26 (expected 26)  tree: ((2 * 3) + (4 * 5))
#     
#     All PASS = compiler correctly compiles a recursive descent parser.
#     QED: not a quine.

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ExprCalculator -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Expr := [Lit(I64), Add(Expr, Expr), Sub(Expr, Expr), Mul(Expr, Expr), Div(Expr, Expr)].{
	is_eq : Expr, Expr -> Bool
	is_eq = |a, b| eq_Expr(a, b)
}
ParseResult : { expr : Expr, pos : I64 }

skip_ws : List(U8), I64 -> I64
skip_ws = |input, pos| (if (pos >= Text.len(input)) { pos } else { (if (Text.char_at(input, pos) >= 1 and Text.char_at(input, pos) <= 2) { skip_ws(input, (pos + 1)) } else { pos }) })

collect_digits : List(U8), I64, I64, I64 -> I64
collect_digits = |input, pos, len, acc| (if (pos >= len) { acc } else { (if (Text.char_at(input, pos) >= 3 and Text.char_at(input, pos) <= 12) { ({
	d = (Text.char_at(input, pos) - 3)
	collect_digits(input, (pos + 1), len, ((acc * 10) + d))
}) } else { acc }) })

digit_count : List(U8), I64, I64 -> I64
digit_count = |input, pos, len| (if (pos >= len) { 0 } else { (if (Text.char_at(input, pos) >= 3 and Text.char_at(input, pos) <= 12) { (1 + digit_count(input, (pos + 1), len)) } else { 0 }) })

parse_atom : List(U8), I64 -> ParseResult
parse_atom = |input, start| ({
	pos = skip_ws(input, start)
	len = Text.len(input)
	(if (pos >= len) { { expr: Lit(0), pos: pos } } else { (if (Text.char_to_text(Text.char_at(input, pos)) == [74]) { ({
		inner = parse_additive(input, (pos + 1))
		after = skip_ws(input, inner.pos)
		(if (after < len) { { expr: inner.expr, pos: (after + 1) } } else { { expr: inner.expr, pos: after } })
	}) } else { ({
		digits = digit_count(input, pos, len)
		(if (digits > 0) { ({
			value = collect_digits(input, pos, len, 0)
			{ expr: Lit(value), pos: (pos + digits) }
		}) } else { { expr: Lit(0), pos: pos } })
	}) }) })
})

parse_multiplicative : List(U8), I64 -> ParseResult
parse_multiplicative = |input, start| ({
	left = parse_atom(input, start)
	continue_multiplicative(input, left)
})

continue_multiplicative : List(U8), ParseResult -> ParseResult
continue_multiplicative = |input, current| ({
	pos = skip_ws(input, current.pos)
	len = Text.len(input)
	(if (pos >= len) { current } else { (if (Text.char_to_text(Text.char_at(input, pos)) == [78]) { ({
		right = parse_atom(input, (pos + 1))
		continue_multiplicative(input, { expr: Mul(current.expr, right.expr), pos: right.pos })
	}) } else { (if (Text.char_to_text(Text.char_at(input, pos)) == [81]) { ({
		right = parse_atom(input, (pos + 1))
		continue_multiplicative(input, { expr: Div(current.expr, right.expr), pos: right.pos })
	}) } else { current }) }) })
})

parse_additive : List(U8), I64 -> ParseResult
parse_additive = |input, start| ({
	left = parse_multiplicative(input, start)
	continue_additive(input, left)
})

continue_additive : List(U8), ParseResult -> ParseResult
continue_additive = |input, current| ({
	pos = skip_ws(input, current.pos)
	len = Text.len(input)
	(if (pos >= len) { current } else { (if (Text.char_to_text(Text.char_at(input, pos)) == [76]) { ({
		right = parse_multiplicative(input, (pos + 1))
		continue_additive(input, { expr: Add(current.expr, right.expr), pos: right.pos })
	}) } else { (if (Text.char_to_text(Text.char_at(input, pos)) == [73]) { ({
		right = parse_multiplicative(input, (pos + 1))
		continue_additive(input, { expr: Sub(current.expr, right.expr), pos: right.pos })
	}) } else { current }) }) })
})

parse : List(U8) -> Expr
parse = |input| parse_additive(input, 0).expr

eval : Expr -> I64
eval = |e| (match e {
	Lit(n) => n
	Add(a, b) => (eval(a) + eval(b))
	Sub(a, b) => (eval(a) - eval(b))
	Mul(a, b) => (eval(a) * eval(b))
	Div(a, b) => I64.div_trunc_by(eval(a), eval(b))
})

format : Expr -> List(U8)
format = |e| (match e {
	Lit(n) => Text.show_int(n)
	Add(a, b) => List.concat(List.concat(List.concat(List.concat([74], format(a)), [2, 76, 2]), format(b)), [75])
	Sub(a, b) => List.concat(List.concat(List.concat(List.concat([74], format(a)), [2, 73, 2]), format(b)), [75])
	Mul(a, b) => List.concat(List.concat(List.concat(List.concat([74], format(a)), [2, 78, 2]), format(b)), [75])
	Div(a, b) => List.concat(List.concat(List.concat(List.concat([74], format(a)), [2, 81, 2]), format(b)), [75])
})

test_expr : List(U8), I64 -> List(U8)
test_expr = |input, expected| ({
	tree = parse(input)
	result = eval(tree)
	status = (if (result == expected) { [57, 41, 45, 45] } else { [54, 41, 43, 49] })
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(status, [69, 2]), input), [2, 77, 2]), Text.show_int(result)), [2, 74, 13, 36, 31, 13, 24, 14, 13, 22, 2]), Text.show_int(expected)), [75, 2, 2, 14, 21, 13, 13, 69, 2]), format(tree))
})

eq_Expr : Expr, Expr -> Bool
eq_Expr = |ex, ey| (match ex {
	Lit(exf0) => (match ey {
		Lit(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Add(exf0, exf1) => (match ey {
		Add(eyf0, eyf1) => (eq_Expr(exf0, eyf0) and eq_Expr(exf1, eyf1))
		_ => False
	})
	Sub(exf0, exf1) => (match ey {
		Sub(eyf0, eyf1) => (eq_Expr(exf0, eyf0) and eq_Expr(exf1, eyf1))
		_ => False
	})
	Mul(exf0, exf1) => (match ey {
		Mul(eyf0, eyf1) => (eq_Expr(exf0, eyf0) and eq_Expr(exf1, eyf1))
		_ => False
	})
	Div(exf0, exf1) => (match ey {
		Div(eyf0, eyf1) => (eq_Expr(exf0, eyf0) and eq_Expr(exf1, eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed([77, 77, 77, 2, 39, 36, 31, 21, 13, 19, 19, 17, 16, 18, 2, 50, 15, 23, 24, 25, 23, 15, 14, 16, 21, 2, 77, 77, 77]))
	line!(Text.printed([]))
	line!(Text.printed(test_expr([7, 5], 42)))
	line!(Text.printed(test_expr([5, 2, 76, 2, 6], 5)))
	line!(Text.printed(test_expr([4, 3, 2, 73, 2, 7], 6)))
	line!(Text.printed(test_expr([6, 2, 78, 2, 10], 21)))
	line!(Text.printed(test_expr([4, 3, 3, 2, 81, 2, 8], 20)))
	line!(Text.printed(test_expr([5, 2, 76, 2, 6, 2, 78, 2, 7], 14)))
	line!(Text.printed(test_expr([4, 3, 2, 73, 2, 5, 2, 78, 2, 6], 4)))
	line!(Text.printed(test_expr([74, 5, 2, 76, 2, 6, 75, 2, 78, 2, 7], 20)))
	line!(Text.printed(test_expr([4, 2, 76, 2, 5, 2, 76, 2, 6, 2, 76, 2, 7], 10)))
	line!(Text.printed(test_expr([5, 2, 78, 2, 6, 2, 76, 2, 7, 2, 78, 2, 8], 26)))
	line!(Text.printed([]))
	line!(Text.printed([41, 23, 23, 2, 57, 41, 45, 45, 2, 77, 2, 24, 16, 26, 31, 17, 23, 13, 21, 2, 24, 16, 21, 21, 13, 24, 14, 23, 30, 2, 24, 16, 26, 31, 17, 23, 13, 19, 2, 15, 2, 21, 13, 24, 25, 21, 19, 17, 33, 13, 2, 22, 13, 19, 24, 13, 18, 14, 2, 31, 15, 21, 19, 13, 21, 65]))
	line!(Text.printed([63, 39, 48, 69, 2, 18, 16, 14, 2, 15, 2, 37, 25, 17, 18, 13, 65]))
	Ok({})
}
