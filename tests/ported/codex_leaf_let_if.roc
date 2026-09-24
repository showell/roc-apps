# leaf-let-if
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/leaf-let-if.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     nd 2 4 = 3
#     nd 9 4 = 0
#     nd 0 1 = 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# LeafLetIf -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

nd : I64, I64 -> I64
nd = |current, total| ({
	next = (current + 1)
	(if (next >= total) { 0 } else { next })
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("nd 2 4 = ", CceText.show_int(nd(2, 4)))))
	line!(CceText.printed(CceText.concat("nd 9 4 = ", CceText.show_int(nd(9, 4)))))
	line!(CceText.printed(CceText.concat("nd 0 1 = ", CceText.show_int(nd(0, 1)))))
	Ok({})
}
