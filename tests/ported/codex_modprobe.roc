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

import cdx.CceText
import cdx.Prelude

# ModProbe -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mline : CceText, I64, I64 -> CceText
mline = |tag, x, y| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(tag, " "), CceText.show_int(x)), ","), CceText.show_int(y)), " div="), CceText.show_int(I64.div_trunc_by(x, y))), " mod="), CceText.show_int(Prelude.int_mod(x, y)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(mline("pp", 7, 3)))
	line!(CceText.printed(mline("np", (0 - 7), 3)))
	line!(CceText.printed(mline("pn", 7, (0 - 3))))
	line!(CceText.printed(mline("nn", (0 - 7), (0 - 3))))
	line!(CceText.printed(mline("pp2", 8, 4)))
	line!(CceText.printed(mline("np2", (0 - 8), 4)))
	line!(CceText.printed(mline("np3", (0 - 1), 8)))
	line!(CceText.printed(mline("pn3", 1, (0 - 8))))
	Ok({})
}
