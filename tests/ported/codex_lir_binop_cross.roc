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

import cdx.Text

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
	line!(Text.printed(List.concat([22, 17, 28, 28, 69, 2], Text.show_int(diff(9, 4)))))
	line!(Text.printed(List.concat([22, 17, 28, 28, 73, 18, 13, 29, 69, 2], Text.show_int(diff(4, 9)))))
	line!(Text.printed(List.concat([15, 22, 22, 25, 31, 69, 2], Text.show_int(addup(1, 2, 3)))))
	line!(Text.printed(List.concat([24, 20, 15, 17, 18, 73, 19, 25, 32, 69, 2], Text.show_int(chain_sub(20, 5, 3)))))
	line!(Text.printed(List.concat([19, 24, 15, 23, 13, 69, 2], Text.show_int(scale(7)))))
	line!(Text.printed(List.concat([16, 28, 28, 19, 13, 14, 69, 2], Text.show_int(offset(7)))))
	line!(Text.printed(List.concat([31, 16, 23, 30, 69, 2], Text.show_int(poly(5)))))
	line!(Text.printed(List.concat([21, 13, 25, 19, 13, 69, 2], Text.show_int(reuse(6, 4)))))
	line!(Text.printed(List.concat([27, 17, 22, 13, 69, 2], Text.show_int(wide(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(Text.printed(List.concat([27, 17, 22, 13, 73, 19, 25, 32, 69, 2], Text.show_int(wide_sub(100, 3, 5, 2, 7, 4, 6, 9)))))
	line!(Text.printed(List.concat([33, 17, 15, 73, 24, 15, 23, 23, 69, 2], Text.show_int(via_call(10)))))
	Ok({})
}
