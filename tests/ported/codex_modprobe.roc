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

# ModProbe -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mline : Str, I64, I64 -> Str
mline = |tag, x, y| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(tag, " "), I64.to_str(x)), ","), I64.to_str(y)), " div="), I64.to_str(I64.div_trunc_by(x, y))), " mod="), I64.to_str(Prelude.int_mod(x, y)))

# --- Entry ---

main! = |_args| {
	line!(mline("pp", 7, 3))
	line!(mline("np", (0 - 7), 3))
	line!(mline("pn", 7, (0 - 3)))
	line!(mline("nn", (0 - 7), (0 - 3)))
	line!(mline("pp2", 8, 4))
	line!(mline("np2", (0 - 8), 4))
	line!(mline("np3", (0 - 1), 8))
	line!(mline("pn3", 1, (0 - 8)))
	Ok({})
}
