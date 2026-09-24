# inline-single-caller
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/inline-single-caller.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     wide 5
#     arity4 10
#     free 101
#     shadowed 101

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# InlineSingleCaller -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

isc_g : I64
isc_g = 100

isc_add_g : I64 -> I64
isc_add_g = |x| (x + isc_g)

isc_add_h : I64 -> I64
isc_add_h = |x| (x + isc_g)

isc_pick : I64, I64 -> I64
isc_pick = |a, b| (if (a > b) { (a - b) } else { (b - a) })

isc_four : I64, I64, I64, I64 -> I64
isc_four = |a, b, c, d| (((a + b) + c) + d)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("wide ", CceText.show_int(isc_pick(9, 4)))))
	line!(CceText.printed(CceText.concat("arity4 ", CceText.show_int(isc_four(1, 2, 3, 4)))))
	line!(CceText.printed(CceText.concat("free ", CceText.show_int(isc_add_g(1)))))
	line!(CceText.printed(CceText.concat("shadowed ", CceText.show_int(({
		_isc_g_1 = 7
		isc_add_h(1)
	})))))
	Ok({})
}
