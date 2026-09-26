# stack-args-spill-overlap
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/stack-args-spill-overlap.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     19018

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# StackArgsSpillOverlap -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

last_two : I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> I64
last_two = |_p0, _p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12, _p13, _p14, _p15, _p16, p17, p18| ((p18 * 1000) + p17)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(last_two(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19))))
	Ok({})
}
