# lir-binop-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-binop-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     diff: 5
#     diff-neg: -5
#     addup: 6
#     chain-sub: 12
#     scale: 21
#     offset: 107
#     poly: 30
#     reuse: 18
#     wide: 36
#     wide-sub: 73
#     via-call: 36

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# LirBinopCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

diff : I64, I64 -> I64
diff = |a, b| (a - b)

addup : I64, I64, I64 -> I64
addup = |a, b, c| ((a + b) + c)

chain_sub : I64, I64, I64 -> I64
chain_sub = |a, b, c| ((a - b) - c)

scale : I64 -> I64
scale = |a| (a * 3)

offset : I64 -> I64
offset = |a| (a + 100)

poly : I64 -> I64
poly = |x| ((x * x) + x)

reuse : I64, I64 -> I64
reuse = |a, b| ((a * b) - a)

wide : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
wide = |a, b, c, d, e, f, g, h| (((((((a + b) + c) + d) + e) + f) + g) + h)

wide_sub : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
wide_sub = |a, b, c, d, e, f, g, h| (((((a - b) - c) + (d * e)) - (f * g)) - h)

via_call : I64 -> I64
via_call = |n| (diff(n, 4) + scale(n))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("diff: ", CceText.show_int(diff(9, 4)))))
	line!(CceText.printed(CceText.concat("diff-neg: ", CceText.show_int(diff(4, 9)))))
	line!(CceText.printed(CceText.concat("addup: ", CceText.show_int(addup(1, 2, 3)))))
	line!(CceText.printed(CceText.concat("chain-sub: ", CceText.show_int(chain_sub(20, 5, 3)))))
	line!(CceText.printed(CceText.concat("scale: ", CceText.show_int(scale(7)))))
	line!(CceText.printed(CceText.concat("offset: ", CceText.show_int(offset(7)))))
	line!(CceText.printed(CceText.concat("poly: ", CceText.show_int(poly(5)))))
	line!(CceText.printed(CceText.concat("reuse: ", CceText.show_int(reuse(6, 4)))))
	line!(CceText.printed(CceText.concat("wide: ", CceText.show_int(wide(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(CceText.printed(CceText.concat("wide-sub: ", CceText.show_int(wide_sub(100, 3, 5, 2, 7, 4, 6, 9)))))
	line!(CceText.printed(CceText.concat("via-call: ", CceText.show_int(via_call(10)))))
	Ok({})
}
