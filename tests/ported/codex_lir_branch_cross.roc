# lir-branch-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-branch-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     mn: 3
#     mn-rev: 3
#     mn-eq: 5
#     mx: 9
#     mx-eq: 5
#     le-lt: 10
#     le-eq: 10
#     le-gt: 20
#     ge-eq: 30
#     ge-lt: 40
#     ne-same: 60
#     ne-diff: 50
#     sgn-pos: 1
#     sgn-zero: 0
#     far-lo: 8
#     far-hi: 7
#     nest-hi: 2
#     nest-mid: 1
#     nest-lo: 0
#     even: 1
#     odd: 0
#     even-neg: 1
#     odd-neg: 0
#     mod4: 1
#     mod4-no: 0
#     wide-t: 75
#     wide-f: -4
#     via-call: 13

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.MathLib

# LirBranchCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mn : I64, I64 -> I64
mn = |a, b| (if (a < b) { a } else { b })

mx : I64, I64 -> I64
mx = |a, b| (if (a > b) { a } else { b })

le_pick : I64, I64 -> I64
le_pick = |a, b| (if (a <= b) { 10 } else { 20 })

ge_pick : I64, I64 -> I64
ge_pick = |a, b| (if (a >= b) { 30 } else { 40 })

ne_pick : I64, I64 -> I64
ne_pick = |a, b| (if (a != b) { 50 } else { 60 })

sgn : I64 -> I64
sgn = |n| (if (n > 0) { 1 } else { 0 })

far_cmp : I64 -> I64
far_cmp = |n| (if (n > 100000) { 7 } else { 8 })

nest : I64 -> I64
nest = |n| (if (n > 0) { (if (n > 5) { 2 } else { 1 }) } else { 0 })

bit_even : I64 -> I64
bit_even = |n| (if (MathLib.math_mod(n, 2) == 0) { 1 } else { 0 })

bit_mod4 : I64 -> I64
bit_mod4 = |n| (if (MathLib.math_mod(n, 4) == 0) { 1 } else { 0 })

wide_branch : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
wide_branch = |a, b, c, d, e, f, g, h| (if (((a + b) + (c + d)) > ((e + f) + (g + h))) { (((a * b) + (c * d)) + ((e * f) + (g * h))) } else { (((a - b) + (c - d)) + ((e - f) + (g - h))) })

via_call : I64 -> I64
via_call = |n| ((mn(n, 4) + mx(n, 4)) + nest(n))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("mn: ", CceText.show_int(mn(3, 9)))))
	line!(CceText.printed(CceText.concat("mn-rev: ", CceText.show_int(mn(9, 3)))))
	line!(CceText.printed(CceText.concat("mn-eq: ", CceText.show_int(mn(5, 5)))))
	line!(CceText.printed(CceText.concat("mx: ", CceText.show_int(mx(3, 9)))))
	line!(CceText.printed(CceText.concat("mx-eq: ", CceText.show_int(mx(5, 5)))))
	line!(CceText.printed(CceText.concat("le-lt: ", CceText.show_int(le_pick(3, 9)))))
	line!(CceText.printed(CceText.concat("le-eq: ", CceText.show_int(le_pick(5, 5)))))
	line!(CceText.printed(CceText.concat("le-gt: ", CceText.show_int(le_pick(9, 3)))))
	line!(CceText.printed(CceText.concat("ge-eq: ", CceText.show_int(ge_pick(5, 5)))))
	line!(CceText.printed(CceText.concat("ge-lt: ", CceText.show_int(ge_pick(3, 9)))))
	line!(CceText.printed(CceText.concat("ne-same: ", CceText.show_int(ne_pick(5, 5)))))
	line!(CceText.printed(CceText.concat("ne-diff: ", CceText.show_int(ne_pick(5, 6)))))
	line!(CceText.printed(CceText.concat("sgn-pos: ", CceText.show_int(sgn(4)))))
	line!(CceText.printed(CceText.concat("sgn-zero: ", CceText.show_int(sgn(0)))))
	line!(CceText.printed(CceText.concat("far-lo: ", CceText.show_int(far_cmp(5)))))
	line!(CceText.printed(CceText.concat("far-hi: ", CceText.show_int(far_cmp(200000)))))
	line!(CceText.printed(CceText.concat("nest-hi: ", CceText.show_int(nest(9)))))
	line!(CceText.printed(CceText.concat("nest-mid: ", CceText.show_int(nest(3)))))
	line!(CceText.printed(CceText.concat("nest-lo: ", CceText.show_int(nest(0)))))
	line!(CceText.printed(CceText.concat("even: ", CceText.show_int(bit_even(4)))))
	line!(CceText.printed(CceText.concat("odd: ", CceText.show_int(bit_even(5)))))
	line!(CceText.printed(CceText.concat("even-neg: ", CceText.show_int(bit_even((-4))))))
	line!(CceText.printed(CceText.concat("odd-neg: ", CceText.show_int(bit_even((-5))))))
	line!(CceText.printed(CceText.concat("mod4: ", CceText.show_int(bit_mod4(8)))))
	line!(CceText.printed(CceText.concat("mod4-no: ", CceText.show_int(bit_mod4(6)))))
	line!(CceText.printed(CceText.concat("wide-t: ", CceText.show_int(wide_branch(9, 8, 1, 1, 1, 1, 1, 1)))))
	line!(CceText.printed(CceText.concat("wide-f: ", CceText.show_int(wide_branch(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(CceText.printed(CceText.concat("via-call: ", CceText.show_int(via_call(7)))))
	Ok({})
}
