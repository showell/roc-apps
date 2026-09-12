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
	line!(Str.concat("mn: ", I64.to_str(mn(3, 9))))
	line!(Str.concat("mn-rev: ", I64.to_str(mn(9, 3))))
	line!(Str.concat("mn-eq: ", I64.to_str(mn(5, 5))))
	line!(Str.concat("mx: ", I64.to_str(mx(3, 9))))
	line!(Str.concat("mx-eq: ", I64.to_str(mx(5, 5))))
	line!(Str.concat("le-lt: ", I64.to_str(le_pick(3, 9))))
	line!(Str.concat("le-eq: ", I64.to_str(le_pick(5, 5))))
	line!(Str.concat("le-gt: ", I64.to_str(le_pick(9, 3))))
	line!(Str.concat("ge-eq: ", I64.to_str(ge_pick(5, 5))))
	line!(Str.concat("ge-lt: ", I64.to_str(ge_pick(3, 9))))
	line!(Str.concat("ne-same: ", I64.to_str(ne_pick(5, 5))))
	line!(Str.concat("ne-diff: ", I64.to_str(ne_pick(5, 6))))
	line!(Str.concat("sgn-pos: ", I64.to_str(sgn(4))))
	line!(Str.concat("sgn-zero: ", I64.to_str(sgn(0))))
	line!(Str.concat("far-lo: ", I64.to_str(far_cmp(5))))
	line!(Str.concat("far-hi: ", I64.to_str(far_cmp(200000))))
	line!(Str.concat("nest-hi: ", I64.to_str(nest(9))))
	line!(Str.concat("nest-mid: ", I64.to_str(nest(3))))
	line!(Str.concat("nest-lo: ", I64.to_str(nest(0))))
	line!(Str.concat("even: ", I64.to_str(bit_even(4))))
	line!(Str.concat("odd: ", I64.to_str(bit_even(5))))
	line!(Str.concat("even-neg: ", I64.to_str(bit_even((-4)))))
	line!(Str.concat("odd-neg: ", I64.to_str(bit_even((-5)))))
	line!(Str.concat("mod4: ", I64.to_str(bit_mod4(8))))
	line!(Str.concat("mod4-no: ", I64.to_str(bit_mod4(6))))
	line!(Str.concat("wide-t: ", I64.to_str(wide_branch(9, 8, 1, 1, 1, 1, 1, 1))))
	line!(Str.concat("wide-f: ", I64.to_str(wide_branch(1, 2, 3, 4, 5, 6, 7, 8))))
	line!(Str.concat("via-call: ", I64.to_str(via_call(7))))
	Ok({})
}
