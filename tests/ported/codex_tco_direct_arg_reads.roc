# tco-direct-arg-reads
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tco-direct-arg-reads.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     acc=101

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TcoDirectArgReads -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_ : { v : I64 }

mk : I64 -> Box_
mk = |x| { v: x }

loop4 : I64, Box_, I64, I64 -> I64
loop4 = |i, s, acc, n| (if (i >= n) { acc } else { ({
	s2 = mk((s.v * 10))
	loop4((i + 1), s2, (s.v + 1), n)
}) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("acc=", CceText.show_int(loop4(0, { v: 1 }, 0, 3)))))
	Ok({})
}
