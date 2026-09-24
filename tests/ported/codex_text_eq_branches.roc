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

import cdx.Text

# TextEqBranches -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mk : I64 -> Text
mk = |n| Text.concat("x", Text.show_int(n))

eq_int : Text, Text -> I64
eq_int = |n, p| (if (n == p) { 1 } else { 0 })

ne_int : Text, Text -> I64
ne_int = |n, p| (if (n != p) { 1 } else { 0 })

eq_txt : Text, Text -> Text
eq_txt = |n, p| (if (n == p) { "equal" } else { "differs" })

eq_bool : Text, Text -> Bool
eq_bool = |n, p| (n == p)

eq_int_int : I64, I64 -> I64
eq_int_int = |a, b| (if (a == b) { 1 } else { 0 })

yn : Bool -> Text
yn = |b| (if b { "yes" } else { "no" })

c1 : Text
c1 = Text.concat("eq-int same    ", Text.show_int(eq_int(mk(5), mk(5))))

c2 : Text
c2 = Text.concat("eq-int differ  ", Text.show_int(eq_int(mk(5), mk(6))))

c3 : Text
c3 = Text.concat("ne-int same    ", Text.show_int(ne_int(mk(5), mk(5))))

c4 : Text
c4 = Text.concat("ne-int differ  ", Text.show_int(ne_int(mk(5), mk(6))))

c5 : Text
c5 = Text.concat("eq-txt same    ", eq_txt(mk(5), mk(5)))

c6 : Text
c6 = Text.concat("eq-txt differ  ", eq_txt(mk(5), mk(6)))

c7 : Text
c7 = Text.concat("eq-bool same   ", yn(eq_bool(mk(5), mk(5))))

c8 : Text
c8 = Text.concat("eq-bool differ ", yn(eq_bool(mk(5), mk(6))))

c9 : Text
c9 = Text.concat(Text.concat("control int    ", Text.show_int(eq_int_int(5, 5))), Text.show_int(eq_int_int(5, 6)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(c1))
	line!(Text.printed(c2))
	line!(Text.printed(c3))
	line!(Text.printed(c4))
	line!(Text.printed(c5))
	line!(Text.printed(c6))
	line!(Text.printed(c7))
	line!(Text.printed(c8))
	line!(Text.printed(c9))
	Ok({})
}
