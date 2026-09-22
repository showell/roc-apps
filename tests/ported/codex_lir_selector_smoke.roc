# lir-selector-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-selector-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     7
#     6
#     7
#     7
#     -7
#     8
#     0
#     120
#     240
#     6
#     6

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# LirSelectorSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

s_sub : I64, I64 -> I64
s_sub = |a, b| (a - b)

s_add : I64, I64 -> I64
s_add = |a, b| (a + b)

s_apply : (I64, I64 -> I64), I64, I64 -> I64
s_apply = |s_sub_, x, y| s_sub_(x, y)

s_join : I64 -> I64
s_join = |n| (({
	v = (if (n > 0) { (n + 1) } else { (n - 1) })
	(if (n == 0) { v } else { 0 })
}) + 7)

s_tail : I64, I64 -> I64
s_tail = |n, acc| (if (n <= 0) { acc } else { s_tail((n - 1), ((acc - n) + 2)) })

s_clash : I64, I64, I64, I64, I64 -> I64
s_clash = |a, b, c, d, e| (if (d == a) { I64.div_trunc_by(((b - c) * 6), e) } else { (if (d == b) { (I64.div_trunc_by(((c - a) * 6), e) + 120) } else { (I64.div_trunc_by(((a - b) * 6), e) + 240) }) })

s_result : I64, I64 -> I64
s_result = |a, b| ({
	s = (a + 1)
	_y = (if (b > 0) { s } else { I64.div_trunc_by(100, ((b * b) + 1)) })
	s
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(s_apply(s_add, 3, 4))))
	line!(Text.printed(Text.show_int(s_join(0))))
	line!(Text.printed(Text.show_int(s_join(5))))
	line!(Text.printed(Text.show_int(s_join((-2)))))
	line!(Text.printed(Text.show_int(s_tail(5, (-2)))))
	line!(Text.printed(Text.show_int(s_tail(1, 7))))
	line!(Text.printed(Text.show_int(s_clash(9, 0, 0, 9, 3))))
	line!(Text.printed(Text.show_int(s_clash(0, 9, 0, 9, 3))))
	line!(Text.printed(Text.show_int(s_clash(0, 0, 9, 9, 3))))
	line!(Text.printed(Text.show_int(s_result(5, (-2)))))
	line!(Text.printed(Text.show_int(s_result(5, 3))))
	Ok({})
}
