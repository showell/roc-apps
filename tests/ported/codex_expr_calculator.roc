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

import cdx.CceChar
import cdx.CceText

# ExprCalculator -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Expr := [Lit(I64), Add(Expr, Expr), Sub(Expr, Expr), Mul(Expr, Expr), Div(Expr, Expr)].{
	is_eq : Expr, Expr -> Bool
	is_eq = |a, b| eq_Expr(a, b)
}
ParseResult : { expr : Expr, pos : I64 }

skip_ws : CceText, I64 -> I64
skip_ws = |input, pos| (if (pos >= CceText.len(input)) { pos } else { (if CceChar.is_whitespace(CceText.char_at(input, pos)) { skip_ws(input, (pos + 1)) } else { pos }) })

collect_digits : CceText, I64, I64, I64 -> I64
collect_digits = |input, pos, len, acc| (if (pos >= len) { acc } else { (if CceChar.is_digit(CceText.char_at(input, pos)) { ({
	d = (CceChar.code(CceText.char_at(input, pos)) - 3)
	collect_digits(input, (pos + 1), len, ((acc * 10) + d))
}) } else { acc }) })

digit_count : CceText, I64, I64 -> I64
digit_count = |input, pos, len| (if (pos >= len) { 0 } else { (if CceChar.is_digit(CceText.char_at(input, pos)) { (1 + digit_count(input, (pos + 1), len)) } else { 0 }) })

parse_atom : CceText, I64 -> ParseResult
parse_atom = |input, start| ({
	pos = skip_ws(input, start)
	len = CceText.len(input)
	(if (pos >= len) { { expr: Lit(0), pos: pos } } else { (if (CceText.char_to_text(CceText.char_at(input, pos)) == "(") { ({
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

parse_multiplicative : CceText, I64 -> ParseResult
parse_multiplicative = |input, start| ({
	left = parse_atom(input, start)
	continue_multiplicative(input, left)
})

continue_multiplicative : CceText, ParseResult -> ParseResult
continue_multiplicative = |input, current| ({
	pos = skip_ws(input, current.pos)
	len = CceText.len(input)
	(if (pos >= len) { current } else { (if (CceText.char_to_text(CceText.char_at(input, pos)) == "*") { ({
		right = parse_atom(input, (pos + 1))
		continue_multiplicative(input, { expr: Mul(current.expr, right.expr), pos: right.pos })
	}) } else { (if (CceText.char_to_text(CceText.char_at(input, pos)) == "/") { ({
		right = parse_atom(input, (pos + 1))
		continue_multiplicative(input, { expr: Div(current.expr, right.expr), pos: right.pos })
	}) } else { current }) }) })
})

parse_additive : CceText, I64 -> ParseResult
parse_additive = |input, start| ({
	left = parse_multiplicative(input, start)
	continue_additive(input, left)
})

continue_additive : CceText, ParseResult -> ParseResult
continue_additive = |input, current| ({
	pos = skip_ws(input, current.pos)
	len = CceText.len(input)
	(if (pos >= len) { current } else { (if (CceText.char_to_text(CceText.char_at(input, pos)) == "+") { ({
		right = parse_multiplicative(input, (pos + 1))
		continue_additive(input, { expr: Add(current.expr, right.expr), pos: right.pos })
	}) } else { (if (CceText.char_to_text(CceText.char_at(input, pos)) == "-") { ({
		right = parse_multiplicative(input, (pos + 1))
		continue_additive(input, { expr: Sub(current.expr, right.expr), pos: right.pos })
	}) } else { current }) }) })
})

parse : CceText -> Expr
parse = |input| parse_additive(input, 0).expr

eval : Expr -> I64
eval = |e| (match e {
	Lit(n) => n
	Add(a, b) => (eval(a) + eval(b))
	Sub(a, b) => (eval(a) - eval(b))
	Mul(a, b) => (eval(a) * eval(b))
	Div(a, b) => I64.div_trunc_by(eval(a), eval(b))
})

format : Expr -> CceText
format = |e| (match e {
	Lit(n) => CceText.show_int(n)
	Add(a, b) => CceText.concat(CceText.concat(CceText.concat(CceText.concat("(", format(a)), " + "), format(b)), ")")
	Sub(a, b) => CceText.concat(CceText.concat(CceText.concat(CceText.concat("(", format(a)), " - "), format(b)), ")")
	Mul(a, b) => CceText.concat(CceText.concat(CceText.concat(CceText.concat("(", format(a)), " * "), format(b)), ")")
	Div(a, b) => CceText.concat(CceText.concat(CceText.concat(CceText.concat("(", format(a)), " / "), format(b)), ")")
})

test_expr : CceText, I64 -> CceText
test_expr = |input, expected| ({
	tree = parse(input)
	result = eval(tree)
	status = (if (result == expected) { "PASS" } else { "FAIL" })
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(status, ": "), input), " = "), CceText.show_int(result)), " (expected "), CceText.show_int(expected)), ")  tree: "), format(tree))
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
	line!(CceText.printed("=== Expression Calculator ==="))
	line!(CceText.printed(""))
	line!(CceText.printed(test_expr("42", 42)))
	line!(CceText.printed(test_expr("2 + 3", 5)))
	line!(CceText.printed(test_expr("10 - 4", 6)))
	line!(CceText.printed(test_expr("3 * 7", 21)))
	line!(CceText.printed(test_expr("100 / 5", 20)))
	line!(CceText.printed(test_expr("2 + 3 * 4", 14)))
	line!(CceText.printed(test_expr("10 - 2 * 3", 4)))
	line!(CceText.printed(test_expr("(2 + 3) * 4", 20)))
	line!(CceText.printed(test_expr("1 + 2 + 3 + 4", 10)))
	line!(CceText.printed(test_expr("2 * 3 + 4 * 5", 26)))
	line!(CceText.printed(""))
	line!(CceText.printed("All PASS = compiler correctly compiles a recursive descent parser."))
	line!(CceText.printed("QED: not a quine."))
	Ok({})
}
