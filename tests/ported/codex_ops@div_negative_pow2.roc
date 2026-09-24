# ops@div-negative-pow2
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@div-negative-pow2.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     -7 / 2 = -3
#     -7 / 3 = -2
#     -13 / 4 = -3
#     -13 / 5 = -2
#     -1 / 2 = 0
#     -1 / 8 = 0
#     -8 / 8 = -1
#     -9 / 8 = -1
#     7 / 2 = 3
#     13 / 4 = 3
#     -7 mod 2 = 1
#     -7 mod 3 = 2

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# DivNegativePow2 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

d2 : I64 -> I64
d2 = |a| I64.div_trunc_by(a, 2)

d3 : I64 -> I64
d3 = |a| I64.div_trunc_by(a, 3)

d4 : I64 -> I64
d4 = |a| I64.div_trunc_by(a, 4)

d5 : I64 -> I64
d5 = |a| I64.div_trunc_by(a, 5)

d8 : I64 -> I64
d8 = |a| I64.div_trunc_by(a, 8)

m2 : I64 -> I64
m2 = |a| Prelude.int_mod(a, 2)

m3 : I64 -> I64
m3 = |a| Prelude.int_mod(a, 3)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("-7 / 2 = ", Text.show_int(d2((0 - 7))))))
	line!(Text.printed(Text.concat("-7 / 3 = ", Text.show_int(d3((0 - 7))))))
	line!(Text.printed(Text.concat("-13 / 4 = ", Text.show_int(d4((0 - 13))))))
	line!(Text.printed(Text.concat("-13 / 5 = ", Text.show_int(d5((0 - 13))))))
	line!(Text.printed(Text.concat("-1 / 2 = ", Text.show_int(d2((0 - 1))))))
	line!(Text.printed(Text.concat("-1 / 8 = ", Text.show_int(d8((0 - 1))))))
	line!(Text.printed(Text.concat("-8 / 8 = ", Text.show_int(d8((0 - 8))))))
	line!(Text.printed(Text.concat("-9 / 8 = ", Text.show_int(d8((0 - 9))))))
	line!(Text.printed(Text.concat("7 / 2 = ", Text.show_int(d2(7)))))
	line!(Text.printed(Text.concat("13 / 4 = ", Text.show_int(d4(13)))))
	line!(Text.printed(Text.concat("-7 mod 2 = ", Text.show_int(m2((0 - 7))))))
	line!(Text.printed(Text.concat("-7 mod 3 = ", Text.show_int(m3((0 - 7))))))
	Ok({})
}
