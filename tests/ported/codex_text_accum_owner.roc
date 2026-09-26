# text-accum-owner
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/text-accum-owner.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     ab7|ab7xyxyxy
#     qxyxyxyxy/qxyxy
#     2000

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TextAccumOwner -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

grow : I64, CceText -> CceText
grow = |n, acc| (if (n <= 0) { acc } else { grow((n - 1), CceText.concat(acc, "xy")) })

make_base : I64 -> CceText
make_base = |k| CceText.concat("ab", CceText.show_int(k))

kept : I64 -> CceText
kept = |k| ({
	base : CceText
	base = make_base(k)
	r : CceText
	r = grow(3, base)
	CceText.concat(CceText.concat(base, "|"), r)
})

reused : I64 -> CceText
reused = |k| ({
	s : CceText
	s = grow(k, "q")
	r : CceText
	r = grow(k, s)
	CceText.concat(CceText.concat(r, "/"), s)
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(kept(7)))
	line!(CceText.printed(reused(2)))
	line!(CceText.printed(CceText.show_int(CceText.len(grow(1000, "")))))
	Ok({})
}
