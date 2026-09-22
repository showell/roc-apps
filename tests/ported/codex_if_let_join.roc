# if-let-join
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/if-let-join.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5
#     5
#     5
#     5
#     1
#     6
#     5
#     5
#     1
#     6
#     3

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# IfLetJoin -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

w6 : I64, I64, I64, I64, I64, I64 -> I64
w6 = |op, x, y, _p4, _p5, _p6| (if (op == 1) { (x + y) } else { 999 })

w7 : I64, I64, I64, I64, I64, I64, I64 -> I64
w7 = |op, x, y, _p4, _p5, _p6, _p7| (if (op == 1) { (x + y) } else { 999 })

w8 : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
w8 = |op, x, y, _p4, _p5, _p6, _p7, _p8| (if (op == 1) { (x + y) } else { 999 })

w9 : I64, I64, I64, I64, I64, I64, I64, I64, I64 -> I64
w9 = |op, x, y, _p4, _p5, _p6, _p7, _p8, _p9| (if (op == 1) { (x + y) } else { 999 })

s7 : I64, I64, I64, I64, I64, I64, I64 -> I64
s7 = |op, x, y, _p4, _p5, _p6, _p7| (if (op == 1) { (x - y) } else { 999 })

m7 : I64, I64, I64, I64, I64, I64, I64 -> I64
m7 = |op, x, y, _p4, _p5, _p6, _p7| (if (op == 1) { (x * y) } else { 999 })

n7 : I64, I64, I64, I64, I64, I64, I64 -> I64
n7 = |op, x, y, _p4, _p5, _p6, _p7| (if (op == 1) { (if (x >= y) { (x + y) } else { x }) } else { 999 })

chain : I64, I64, I64, I64, I64, I64, I64 -> I64
chain = |op, x, y, _p4, _p5, _p6, _p7| (if (op == 1) { (x + y) } else { (if (op == 2) { (x - y) } else { (if (op == 3) { (x * y) } else { (if (x >= y) { x } else { y }) }) }) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(w6(1, 3, 2, 0, 0, 0))))
	line!(Text.printed(Text.show_int(w7(1, 3, 2, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(w8(1, 3, 2, 0, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(w9(1, 3, 2, 0, 0, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(s7(1, 3, 2, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(m7(1, 3, 2, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(n7(1, 3, 2, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(chain(1, 3, 2, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(chain(2, 3, 2, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(chain(3, 3, 2, 0, 0, 0, 0))))
	line!(Text.printed(Text.show_int(chain(9, 3, 2, 0, 0, 0, 0))))
	Ok({})
}
