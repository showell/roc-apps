# ops@record-closure-field-poly
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@record-closure-field-poly.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     wrap 21
#     wrap-let 8
#     wrap-map 42
#     wrap-text seven

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RecordClosureFieldPoly -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_(a) : { get : (I64 -> a) }

wrap : a -> Box_(a)
wrap = |x| { get: ({
	dev__1 = x
	|dev__2| lam_0(dev__1, dev__2)
}) }

wrap_let : a -> Box_(a)
wrap_let = |x| { get: ({
	dev__1 = x
	|dev__2| lam_1(dev__1, dev__2)
}) }

wrap_map : Box_(a), (a -> b) -> Box_(b)
wrap_map = |bx, f| { get: ({
	dev__1 = f
	dev__2 = bx
	|dev__3| lam_2(dev__1, dev__2, dev__3)
}) }

lam_0 : a, I64 -> a
lam_0 = |x, _i| x

lam_1 : a, I64 -> a
lam_1 = |x, _i| x

lam_2 : (a -> b), Box_(a), I64 -> b
lam_2 = |f, bx, i| f((bx.get)(i))

lam_3 : I64 -> I64
lam_3 = |n| (n * 2)

lam_4 : I64 -> CceText
lam_4 = |_n| "seven"

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("wrap ", CceText.show_int((wrap(21).get)(0)))))
	line!(CceText.printed(CceText.concat("wrap-let ", CceText.show_int((wrap_let(8).get)(0)))))
	line!(CceText.printed(CceText.concat("wrap-map ", CceText.show_int((wrap_map(wrap(21), lam_3).get)(0)))))
	line!(CceText.printed(CceText.concat("wrap-text ", (wrap_map(wrap(7), lam_4).get)(0))))
	Ok({})
}
