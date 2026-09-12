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

app [main!] {}

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
	line!(Str.concat("arg-lit: ", I64.to_str(two(1, (-2)))))
	line!(Str.concat("arg-only: ", I64.to_str(one((-5)))))
	line!(Str.concat("arg-var: ", I64.to_str(neg_var(3))))
	line!(Str.concat("three-args: ", I64.to_str(three(1, (-2), 3))))
	line!(Str.concat("sub: ", I64.to_str((7 - 2))))
	line!(Str.concat("left-abut: ", I64.to_str(a_(2))))
	line!(Str.concat("hyphen-digit: ", I64.to_str(x_2)))
	line!(Str.concat("paren: ", I64.to_str(two(1, (-2)))))
	line!(Str.concat("arrow: ", I64.to_str(arrowed(4))))
	Ok({})
}
