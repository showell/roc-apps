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
	line!(Text.printed(List.concat([14, 27, 16, 73, 24, 25, 32, 13, 22, 2], Text.show_int(ipow(2, 3)))))
	line!(Text.printed(List.concat([14, 27, 16, 73, 28, 16, 25, 21, 14, 20, 2], Text.show_int(ipow(2, 4)))))
	line!(Text.printed(List.concat([14, 20, 21, 13, 13, 73, 28, 17, 28, 14, 20, 2], Text.show_int(ipow(3, 5)))))
	line!(Text.printed(List.concat([14, 13, 18, 73, 14, 20, 17, 21, 22, 2], Text.show_int(ipow(10, 3)))))
	line!(Text.printed(List.concat([15, 18, 30, 73, 38, 13, 21, 16, 2], Text.show_int(ipow(7, 0)))))
	line!(Text.printed(List.concat([15, 18, 30, 73, 16, 18, 13, 2], Text.show_int(ipow(7, 1)))))
	line!(Text.printed(List.concat([16, 18, 13, 73, 32, 17, 29, 2], Text.show_int(ipow(1, 62)))))
	line!(Text.printed(List.concat([18, 13, 29, 73, 32, 15, 19, 13, 73, 13, 33, 13, 18, 2], Text.show_int(ipow((0 - 3), 4)))))
	line!(Text.printed(List.concat([18, 13, 29, 73, 32, 15, 19, 13, 73, 16, 22, 22, 2], Text.show_int(ipow((0 - 3), 3)))))
	line!(Text.printed(List.concat([18, 13, 29, 73, 13, 36, 31, 16, 18, 13, 18, 14, 2], Text.show_int(ipow(5, (0 - 2))))))
	line!(Text.printed(List.concat([38, 13, 21, 16, 73, 32, 15, 19, 13, 2], Text.show_int(ipow(0, 5)))))
	line!(Text.printed(List.concat([31, 15, 19, 14, 73, 22, 16, 25, 32, 23, 13, 73, 22, 16, 27, 18, 2], Text.show_int(ipow(3, 34)))))
	line!(Text.printed(List.concat([31, 15, 19, 14, 73, 22, 16, 25, 32, 23, 13, 73, 25, 31, 2], Text.show_int(ipow(7, 19)))))
	Ok({})
}
