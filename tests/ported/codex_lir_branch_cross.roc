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

import cdx.MathLib
import cdx.Text

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
	line!(Text.printed(List.concat([26, 18, 69, 2], Text.show_int(mn(3, 9)))))
	line!(Text.printed(List.concat([26, 18, 73, 21, 13, 33, 69, 2], Text.show_int(mn(9, 3)))))
	line!(Text.printed(List.concat([26, 18, 73, 13, 37, 69, 2], Text.show_int(mn(5, 5)))))
	line!(Text.printed(List.concat([26, 36, 69, 2], Text.show_int(mx(3, 9)))))
	line!(Text.printed(List.concat([26, 36, 73, 13, 37, 69, 2], Text.show_int(mx(5, 5)))))
	line!(Text.printed(List.concat([23, 13, 73, 23, 14, 69, 2], Text.show_int(le_pick(3, 9)))))
	line!(Text.printed(List.concat([23, 13, 73, 13, 37, 69, 2], Text.show_int(le_pick(5, 5)))))
	line!(Text.printed(List.concat([23, 13, 73, 29, 14, 69, 2], Text.show_int(le_pick(9, 3)))))
	line!(Text.printed(List.concat([29, 13, 73, 13, 37, 69, 2], Text.show_int(ge_pick(5, 5)))))
	line!(Text.printed(List.concat([29, 13, 73, 23, 14, 69, 2], Text.show_int(ge_pick(3, 9)))))
	line!(Text.printed(List.concat([18, 13, 73, 19, 15, 26, 13, 69, 2], Text.show_int(ne_pick(5, 5)))))
	line!(Text.printed(List.concat([18, 13, 73, 22, 17, 28, 28, 69, 2], Text.show_int(ne_pick(5, 6)))))
	line!(Text.printed(List.concat([19, 29, 18, 73, 31, 16, 19, 69, 2], Text.show_int(sgn(4)))))
	line!(Text.printed(List.concat([19, 29, 18, 73, 38, 13, 21, 16, 69, 2], Text.show_int(sgn(0)))))
	line!(Text.printed(List.concat([28, 15, 21, 73, 23, 16, 69, 2], Text.show_int(far_cmp(5)))))
	line!(Text.printed(List.concat([28, 15, 21, 73, 20, 17, 69, 2], Text.show_int(far_cmp(200000)))))
	line!(Text.printed(List.concat([18, 13, 19, 14, 73, 20, 17, 69, 2], Text.show_int(nest(9)))))
	line!(Text.printed(List.concat([18, 13, 19, 14, 73, 26, 17, 22, 69, 2], Text.show_int(nest(3)))))
	line!(Text.printed(List.concat([18, 13, 19, 14, 73, 23, 16, 69, 2], Text.show_int(nest(0)))))
	line!(Text.printed(List.concat([13, 33, 13, 18, 69, 2], Text.show_int(bit_even(4)))))
	line!(Text.printed(List.concat([16, 22, 22, 69, 2], Text.show_int(bit_even(5)))))
	line!(Text.printed(List.concat([13, 33, 13, 18, 73, 18, 13, 29, 69, 2], Text.show_int(bit_even((-4))))))
	line!(Text.printed(List.concat([16, 22, 22, 73, 18, 13, 29, 69, 2], Text.show_int(bit_even((-5))))))
	line!(Text.printed(List.concat([26, 16, 22, 7, 69, 2], Text.show_int(bit_mod4(8)))))
	line!(Text.printed(List.concat([26, 16, 22, 7, 73, 18, 16, 69, 2], Text.show_int(bit_mod4(6)))))
	line!(Text.printed(List.concat([27, 17, 22, 13, 73, 14, 69, 2], Text.show_int(wide_branch(9, 8, 1, 1, 1, 1, 1, 1)))))
	line!(Text.printed(List.concat([27, 17, 22, 13, 73, 28, 69, 2], Text.show_int(wide_branch(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(Text.printed(List.concat([33, 17, 15, 73, 24, 15, 23, 23, 69, 2], Text.show_int(via_call(7)))))
	Ok({})
}
