# negation-abutment
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/negation-abutment.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     arg-lit: -1
#     arg-only: -5
#     arg-var: -2
#     three-args: 83
#     sub: 5
#     left-abut: 3
#     hyphen-digit: 7
#     paren: -1
#     arrow: 8

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# NegationAbutment -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

one : I64 -> I64
one = |n| n

two : I64, I64 -> I64
two = |a, b| (a + b)

three : I64, I64, I64 -> I64
three = |a, b, c| (((a * 100) + (b * 10)) + c)

neg_var : I64 -> I64
neg_var = |x| two(1, (-x))

a_ : I64 -> I64
a_ = |n| (n + 1)

x_2 : I64
x_2 = 7

arrowed : I64 -> I64
arrowed = |n| (n * 2)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([15, 21, 29, 73, 23, 17, 14, 69, 2], Text.show_int(two(1, (-2))))))
	line!(Text.printed(List.concat([15, 21, 29, 73, 16, 18, 23, 30, 69, 2], Text.show_int(one((-5))))))
	line!(Text.printed(List.concat([15, 21, 29, 73, 33, 15, 21, 69, 2], Text.show_int(neg_var(3)))))
	line!(Text.printed(List.concat([14, 20, 21, 13, 13, 73, 15, 21, 29, 19, 69, 2], Text.show_int(three(1, (-2), 3)))))
	line!(Text.printed(List.concat([19, 25, 32, 69, 2], Text.show_int((7 - 2)))))
	line!(Text.printed(List.concat([23, 13, 28, 14, 73, 15, 32, 25, 14, 69, 2], Text.show_int(a_(2)))))
	line!(Text.printed(List.concat([20, 30, 31, 20, 13, 18, 73, 22, 17, 29, 17, 14, 69, 2], Text.show_int(x_2))))
	line!(Text.printed(List.concat([31, 15, 21, 13, 18, 69, 2], Text.show_int(two(1, (-2))))))
	line!(Text.printed(List.concat([15, 21, 21, 16, 27, 69, 2], Text.show_int(arrowed(4)))))
	Ok({})
}
