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

import cdx.Text

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
	line!(Text.printed(List.concat([18, 22, 2, 5, 2, 7, 2, 77, 2], Text.show_int(nd(2, 4)))))
	line!(Text.printed(List.concat([18, 22, 2, 12, 2, 7, 2, 77, 2], Text.show_int(nd(9, 4)))))
	line!(Text.printed(List.concat([18, 22, 2, 3, 2, 4, 2, 77, 2], Text.show_int(nd(0, 1)))))
	Ok({})
}
