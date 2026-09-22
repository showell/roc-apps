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

mk : I64 -> List(U8)
mk = |n| List.concat([36], Text.show_int(n))

eq_int : List(U8), List(U8) -> I64
eq_int = |n, p| (if (n == p) { 1 } else { 0 })

ne_int : List(U8), List(U8) -> I64
ne_int = |n, p| (if (n != p) { 1 } else { 0 })

eq_txt : List(U8), List(U8) -> List(U8)
eq_txt = |n, p| (if (n == p) { [13, 37, 25, 15, 23] } else { [22, 17, 28, 28, 13, 21, 19] })

eq_bool : List(U8), List(U8) -> Bool
eq_bool = |n, p| (n == p)

eq_int_int : I64, I64 -> I64
eq_int_int = |a, b| (if (a == b) { 1 } else { 0 })

yn : Bool -> List(U8)
yn = |b| (if b { [30, 13, 19] } else { [18, 16] })

c1 : List(U8)
c1 = List.concat([13, 37, 73, 17, 18, 14, 2, 19, 15, 26, 13, 2, 2, 2, 2], Text.show_int(eq_int(mk(5), mk(5))))

c2 : List(U8)
c2 = List.concat([13, 37, 73, 17, 18, 14, 2, 22, 17, 28, 28, 13, 21, 2, 2], Text.show_int(eq_int(mk(5), mk(6))))

c3 : List(U8)
c3 = List.concat([18, 13, 73, 17, 18, 14, 2, 19, 15, 26, 13, 2, 2, 2, 2], Text.show_int(ne_int(mk(5), mk(5))))

c4 : List(U8)
c4 = List.concat([18, 13, 73, 17, 18, 14, 2, 22, 17, 28, 28, 13, 21, 2, 2], Text.show_int(ne_int(mk(5), mk(6))))

c5 : List(U8)
c5 = List.concat([13, 37, 73, 14, 36, 14, 2, 19, 15, 26, 13, 2, 2, 2, 2], eq_txt(mk(5), mk(5)))

c6 : List(U8)
c6 = List.concat([13, 37, 73, 14, 36, 14, 2, 22, 17, 28, 28, 13, 21, 2, 2], eq_txt(mk(5), mk(6)))

c7 : List(U8)
c7 = List.concat([13, 37, 73, 32, 16, 16, 23, 2, 19, 15, 26, 13, 2, 2, 2], yn(eq_bool(mk(5), mk(5))))

c8 : List(U8)
c8 = List.concat([13, 37, 73, 32, 16, 16, 23, 2, 22, 17, 28, 28, 13, 21, 2], yn(eq_bool(mk(5), mk(6))))

c9 : List(U8)
c9 = List.concat(List.concat([24, 16, 18, 14, 21, 16, 23, 2, 17, 18, 14, 2, 2, 2, 2], Text.show_int(eq_int_int(5, 5))), Text.show_int(eq_int_int(5, 6)))

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
