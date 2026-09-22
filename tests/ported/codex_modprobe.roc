# modprobe
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/modprobe.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     pp 7,3 div=2 mod=1
#     np -7,3 div=-2 mod=2
#     pn 7,-3 div=-2 mod=1
#     nn -7,-3 div=2 mod=2
#     pp2 8,4 div=2 mod=0
#     np2 -8,4 div=-2 mod=0
#     np3 -1,8 div=0 mod=7
#     pn3 1,-8 div=0 mod=1

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# ModProbe -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mline : List(U8), I64, I64 -> List(U8)
mline = |tag, x, y| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(tag, [2]), Text.show_int(x)), [66]), Text.show_int(y)), [2, 22, 17, 33, 77]), Text.show_int(I64.div_trunc_by(x, y))), [2, 26, 16, 22, 77]), Text.show_int(Prelude.int_mod(x, y)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(mline([31, 31], 7, 3)))
	line!(Text.printed(mline([18, 31], (0 - 7), 3)))
	line!(Text.printed(mline([31, 18], 7, (0 - 3))))
	line!(Text.printed(mline([18, 18], (0 - 7), (0 - 3))))
	line!(Text.printed(mline([31, 31, 5], 8, 4)))
	line!(Text.printed(mline([18, 31, 5], (0 - 8), 4)))
	line!(Text.printed(mline([18, 31, 6], (0 - 1), 8)))
	line!(Text.printed(mline([31, 18, 6], 1, (0 - 8))))
	Ok({})
}
