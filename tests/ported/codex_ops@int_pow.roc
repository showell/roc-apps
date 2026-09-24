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

import cdx.CceText
import cdx.Prelude

# IntPow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ipow : I64, I64 -> I64
ipow = |a, b| Prelude.int_pow(a, b)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("two-cubed ", CceText.show_int(ipow(2, 3)))))
	line!(CceText.printed(CceText.concat("two-fourth ", CceText.show_int(ipow(2, 4)))))
	line!(CceText.printed(CceText.concat("three-fifth ", CceText.show_int(ipow(3, 5)))))
	line!(CceText.printed(CceText.concat("ten-third ", CceText.show_int(ipow(10, 3)))))
	line!(CceText.printed(CceText.concat("any-zero ", CceText.show_int(ipow(7, 0)))))
	line!(CceText.printed(CceText.concat("any-one ", CceText.show_int(ipow(7, 1)))))
	line!(CceText.printed(CceText.concat("one-big ", CceText.show_int(ipow(1, 62)))))
	line!(CceText.printed(CceText.concat("neg-base-even ", CceText.show_int(ipow((0 - 3), 4)))))
	line!(CceText.printed(CceText.concat("neg-base-odd ", CceText.show_int(ipow((0 - 3), 3)))))
	line!(CceText.printed(CceText.concat("neg-exponent ", CceText.show_int(ipow(5, (0 - 2))))))
	line!(CceText.printed(CceText.concat("zero-base ", CceText.show_int(ipow(0, 5)))))
	line!(CceText.printed(CceText.concat("past-double-down ", CceText.show_int(ipow(3, 34)))))
	line!(CceText.printed(CceText.concat("past-double-up ", CceText.show_int(ipow(7, 19)))))
	Ok({})
}
