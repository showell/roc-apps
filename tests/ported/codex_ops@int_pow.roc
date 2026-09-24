# ops@int-pow
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@int-pow.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     two-cubed 8
#     two-fourth 16
#     three-fifth 243
#     ten-third 1000
#     any-zero 1
#     any-one 7
#     one-big 1
#     neg-base-even 81
#     neg-base-odd -27
#     neg-exponent 0
#     zero-base 0
#     past-double-down 16677181699666569
#     past-double-up 11398895185373143

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# IntPow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ipow : I64, I64 -> I64
ipow = |a, b| Prelude.int_pow(a, b)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("two-cubed ", Text.show_int(ipow(2, 3)))))
	line!(Text.printed(Text.concat("two-fourth ", Text.show_int(ipow(2, 4)))))
	line!(Text.printed(Text.concat("three-fifth ", Text.show_int(ipow(3, 5)))))
	line!(Text.printed(Text.concat("ten-third ", Text.show_int(ipow(10, 3)))))
	line!(Text.printed(Text.concat("any-zero ", Text.show_int(ipow(7, 0)))))
	line!(Text.printed(Text.concat("any-one ", Text.show_int(ipow(7, 1)))))
	line!(Text.printed(Text.concat("one-big ", Text.show_int(ipow(1, 62)))))
	line!(Text.printed(Text.concat("neg-base-even ", Text.show_int(ipow((0 - 3), 4)))))
	line!(Text.printed(Text.concat("neg-base-odd ", Text.show_int(ipow((0 - 3), 3)))))
	line!(Text.printed(Text.concat("neg-exponent ", Text.show_int(ipow(5, (0 - 2))))))
	line!(Text.printed(Text.concat("zero-base ", Text.show_int(ipow(0, 5)))))
	line!(Text.printed(Text.concat("past-double-down ", Text.show_int(ipow(3, 34)))))
	line!(Text.printed(Text.concat("past-double-up ", Text.show_int(ipow(7, 19)))))
	Ok({})
}
