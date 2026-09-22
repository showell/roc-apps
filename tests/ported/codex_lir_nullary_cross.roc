# lir-nullary-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-nullary-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     ident: 7
#     konst: 42
#     neg-konst: -7
#     big-konst: 123456789
#     pick2: 9
#     pick-mid: 2
#     pick-last: 3
#     deep: 8
#     via-call: 15

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# LirNullaryCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ident : I64 -> I64
ident = |x| x

konst : I64
konst = 42

neg_konst : I64
neg_konst = (0 - 7)

big_konst : I64
big_konst = 123456789

pick2 : I64, I64 -> I64
pick2 = |_a, b| b

pick_mid : I64, I64, I64 -> I64
pick_mid = |_a, b, _c| b

pick_last : I64, I64, I64 -> I64
pick_last = |_a, _b, c| c

deep : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
deep = |_a, _b, _c, _d, _e, _f, _g, h| h

via_call : I64 -> I64
via_call = |n| (ident(n) + pick2(n, 5))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([17, 22, 13, 18, 14, 69, 2], Text.show_int(ident(7)))))
	line!(Text.printed(List.concat([34, 16, 18, 19, 14, 69, 2], Text.show_int(konst))))
	line!(Text.printed(List.concat([18, 13, 29, 73, 34, 16, 18, 19, 14, 69, 2], Text.show_int(neg_konst))))
	line!(Text.printed(List.concat([32, 17, 29, 73, 34, 16, 18, 19, 14, 69, 2], Text.show_int(big_konst))))
	line!(Text.printed(List.concat([31, 17, 24, 34, 5, 69, 2], Text.show_int(pick2(3, 9)))))
	line!(Text.printed(List.concat([31, 17, 24, 34, 73, 26, 17, 22, 69, 2], Text.show_int(pick_mid(1, 2, 3)))))
	line!(Text.printed(List.concat([31, 17, 24, 34, 73, 23, 15, 19, 14, 69, 2], Text.show_int(pick_last(1, 2, 3)))))
	line!(Text.printed(List.concat([22, 13, 13, 31, 69, 2], Text.show_int(deep(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(Text.printed(List.concat([33, 17, 15, 73, 24, 15, 23, 23, 69, 2], Text.show_int(via_call(10)))))
	Ok({})
}
