# text-eq-branches
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/text-eq-branches.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     eq-int same    1
#     eq-int differ  0
#     ne-int same    0
#     ne-int differ  1
#     eq-txt same    equal
#     eq-txt differ  differs
#     eq-bool same   yes
#     eq-bool differ no
#     control int    10

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TextEqBranches -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mk : I64 -> CceText
mk = |n| CceText.concat("x", CceText.show_int(n))

eq_int : CceText, CceText -> I64
eq_int = |n, p| (if (n == p) { 1 } else { 0 })

ne_int : CceText, CceText -> I64
ne_int = |n, p| (if (n != p) { 1 } else { 0 })

eq_txt : CceText, CceText -> CceText
eq_txt = |n, p| (if (n == p) { "equal" } else { "differs" })

eq_bool : CceText, CceText -> Bool
eq_bool = |n, p| (n == p)

eq_int_int : I64, I64 -> I64
eq_int_int = |a, b| (if (a == b) { 1 } else { 0 })

yn : Bool -> CceText
yn = |b| (if b { "yes" } else { "no" })

c1 : CceText
c1 = CceText.concat("eq-int same    ", CceText.show_int(eq_int(mk(5), mk(5))))

c2 : CceText
c2 = CceText.concat("eq-int differ  ", CceText.show_int(eq_int(mk(5), mk(6))))

c3 : CceText
c3 = CceText.concat("ne-int same    ", CceText.show_int(ne_int(mk(5), mk(5))))

c4 : CceText
c4 = CceText.concat("ne-int differ  ", CceText.show_int(ne_int(mk(5), mk(6))))

c5 : CceText
c5 = CceText.concat("eq-txt same    ", eq_txt(mk(5), mk(5)))

c6 : CceText
c6 = CceText.concat("eq-txt differ  ", eq_txt(mk(5), mk(6)))

c7 : CceText
c7 = CceText.concat("eq-bool same   ", yn(eq_bool(mk(5), mk(5))))

c8 : CceText
c8 = CceText.concat("eq-bool differ ", yn(eq_bool(mk(5), mk(6))))

c9 : CceText
c9 = CceText.concat(CceText.concat("control int    ", CceText.show_int(eq_int_int(5, 5))), CceText.show_int(eq_int_int(5, 6)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(c1))
	line!(CceText.printed(c2))
	line!(CceText.printed(c3))
	line!(CceText.printed(c4))
	line!(CceText.printed(c5))
	line!(CceText.printed(c6))
	line!(CceText.printed(c7))
	line!(CceText.printed(c8))
	line!(CceText.printed(c9))
	Ok({})
}
