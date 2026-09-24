# lir-join-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-join-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     3
#     4
#     11
#     21
#     60
#     80
#     11
#     12
#     13
#     57
#     58
#     68

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# LirJoinCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sel_let : I64 -> I64
sel_let = |c| (if (c > 0) { 3 } else { 4 })

sel_add : I64 -> I64
sel_add = |c| ((if (c > 0) { 10 } else { 20 }) + 1)

sel_reg : I64, I64, I64 -> I64
sel_reg = |c, x, y| ({
	v : I64
	v = (if (c > 0) { x } else { y })
	(v * 2)
})

sel_nest : I64, I64 -> I64
sel_nest = |a, b| ((if (a > 0) { (if (b > 0) { 1 } else { 2 }) } else { 3 }) + 10)

sel_seq : I64, I64 -> I64
sel_seq = |a, b| ({
	p : I64
	p = (if (a > 0) { 5 } else { 6 })
	q : I64
	q = (if (b > 0) { 7 } else { 8 })
	((p * 10) + q)
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(sel_let(1))))
	line!(CceText.printed(CceText.show_int(sel_let((-1)))))
	line!(CceText.printed(CceText.show_int(sel_add(1))))
	line!(CceText.printed(CceText.show_int(sel_add((-1)))))
	line!(CceText.printed(CceText.show_int(sel_reg(1, 30, 40))))
	line!(CceText.printed(CceText.show_int(sel_reg((-1), 30, 40))))
	line!(CceText.printed(CceText.show_int(sel_nest(1, 1))))
	line!(CceText.printed(CceText.show_int(sel_nest(1, (-1)))))
	line!(CceText.printed(CceText.show_int(sel_nest((-1), 5))))
	line!(CceText.printed(CceText.show_int(sel_seq(1, 1))))
	line!(CceText.printed(CceText.show_int(sel_seq(1, (-1)))))
	line!(CceText.printed(CceText.show_int(sel_seq((-1), (-1)))))
	Ok({})
}
