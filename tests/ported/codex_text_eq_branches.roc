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

app [main!] {}

# TextEqBranches -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mk : I64 -> Str
mk = |n| Str.concat("x", I64.to_str(n))

eq_int : Str, Str -> I64
eq_int = |n, p| (if (n == p) { 1 } else { 0 })

ne_int : Str, Str -> I64
ne_int = |n, p| (if (n != p) { 1 } else { 0 })

eq_txt : Str, Str -> Str
eq_txt = |n, p| (if (n == p) { "equal" } else { "differs" })

eq_bool : Str, Str -> Bool
eq_bool = |n, p| (n == p)

eq_int_int : I64, I64 -> I64
eq_int_int = |a, b| (if (a == b) { 1 } else { 0 })

yn : Bool -> Str
yn = |b| (if b { "yes" } else { "no" })

c1 : Str
c1 = Str.concat("eq-int same    ", I64.to_str(eq_int(mk(5), mk(5))))

c2 : Str
c2 = Str.concat("eq-int differ  ", I64.to_str(eq_int(mk(5), mk(6))))

c3 : Str
c3 = Str.concat("ne-int same    ", I64.to_str(ne_int(mk(5), mk(5))))

c4 : Str
c4 = Str.concat("ne-int differ  ", I64.to_str(ne_int(mk(5), mk(6))))

c5 : Str
c5 = Str.concat("eq-txt same    ", eq_txt(mk(5), mk(5)))

c6 : Str
c6 = Str.concat("eq-txt differ  ", eq_txt(mk(5), mk(6)))

c7 : Str
c7 = Str.concat("eq-bool same   ", yn(eq_bool(mk(5), mk(5))))

c8 : Str
c8 = Str.concat("eq-bool differ ", yn(eq_bool(mk(5), mk(6))))

c9 : Str
c9 = Str.concat(Str.concat("control int    ", I64.to_str(eq_int_int(5, 5))), I64.to_str(eq_int_int(5, 6)))

# --- Entry ---

main! = |_args| {
	line!(c1)
	line!(c2)
	line!(c3)
	line!(c4)
	line!(c5)
	line!(c6)
	line!(c7)
	line!(c8)
	line!(c9)
	Ok({})
}
