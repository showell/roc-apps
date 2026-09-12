# rv-param-bind
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/rv-param-bind.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     first: 1
#     second: 2
#     of3-first: 1
#     of3-mid: 2
#     of3-last: 3

app [main!] {}

# RvParamBind -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

take_first : I64, I64 -> I64
take_first = |a, _b| a

take_second : I64, I64 -> I64
take_second = |_a, b| b

of_three_first : I64, I64, I64 -> I64
of_three_first = |a, _b, _c| a

of_three_mid : I64, I64, I64 -> I64
of_three_mid = |_a, b, _c| b

of_three_last : I64, I64, I64 -> I64
of_three_last = |_a, _b, c| c

# --- Entry ---

main! = |_args| {
	line!(Str.concat("first: ", I64.to_str(take_first(1, 2))))
	line!(Str.concat("second: ", I64.to_str(take_second(1, 2))))
	line!(Str.concat("of3-first: ", I64.to_str(of_three_first(1, 2, 3))))
	line!(Str.concat("of3-mid: ", I64.to_str(of_three_mid(1, 2, 3))))
	line!(Str.concat("of3-last: ", I64.to_str(of_three_last(1, 2, 3))))
	Ok({})
}
