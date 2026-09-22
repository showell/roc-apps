# ops@real-compare-negative
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-compare-negative.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     neg-big lt neg-small want 11 11
#     neg-big gt neg-small want 00 00
#     neg-big le neg-small want 11 11
#     neg-big ge neg-small want 00 00
#     neg-small lt neg-big want 00 00
#     neg-small gt neg-big want 11 11
#     neg-big lt neg-big want 00 00
#     neg-big le neg-big want 11 11
#     neg-big ge neg-big want 11 11
#     pos-small lt pos-big want 11 11
#     pos-small gt pos-big want 00 00
#     neg-big lt pos-small want 11 11
#     pos-big lt neg-small want 00 00
#     neg-small lt zero want 11 11
#     neg-small gt zero want 00 00

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RealCompareNegative -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

neg_big : F64
neg_big = (0.0 - 2.9)

neg_small : F64
neg_small = (0.0 - 1.5)

pos_big : F64
pos_big = 2.9

pos_small : F64
pos_small = 1.5

zero : F64
zero = 0.0

b2i : Bool -> I64
b2i = |b| (if b { 1 } else { 0 })

fused_lt : F64, F64 -> I64
fused_lt = |a, b| (if (a < b) { 1 } else { 0 })

fused_gt : F64, F64 -> I64
fused_gt = |a, b| (if (a > b) { 1 } else { 0 })

fused_le : F64, F64 -> I64
fused_le = |a, b| (if (a <= b) { 1 } else { 0 })

fused_ge : F64, F64 -> I64
fused_ge = |a, b| (if (a >= b) { 1 } else { 0 })

val_lt : F64, F64 -> I64
val_lt = |a, b| b2i((a < b))

val_gt : F64, F64 -> I64
val_gt = |a, b| b2i((a > b))

val_le : F64, F64 -> I64
val_le = |a, b| b2i((a <= b))

val_ge : F64, F64 -> I64
val_ge = |a, b| b2i((a >= b))

say_lt : List(U8), F64, F64 -> List(U8)
say_lt = |label, a, b| List.concat(List.concat(List.concat(label, [2]), Text.show_int(fused_lt(a, b))), Text.show_int(val_lt(a, b)))

say_gt : List(U8), F64, F64 -> List(U8)
say_gt = |label, a, b| List.concat(List.concat(List.concat(label, [2]), Text.show_int(fused_gt(a, b))), Text.show_int(val_gt(a, b)))

say_le : List(U8), F64, F64 -> List(U8)
say_le = |label, a, b| List.concat(List.concat(List.concat(label, [2]), Text.show_int(fused_le(a, b))), Text.show_int(val_le(a, b)))

say_ge : List(U8), F64, F64 -> List(U8)
say_ge = |label, a, b| List.concat(List.concat(List.concat(label, [2]), Text.show_int(fused_ge(a, b))), Text.show_int(val_ge(a, b)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(say_lt([18, 13, 29, 73, 32, 17, 29, 2, 23, 14, 2, 18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 27, 15, 18, 14, 2, 4, 4], neg_big, neg_small)))
	line!(Text.printed(say_gt([18, 13, 29, 73, 32, 17, 29, 2, 29, 14, 2, 18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 27, 15, 18, 14, 2, 3, 3], neg_big, neg_small)))
	line!(Text.printed(say_le([18, 13, 29, 73, 32, 17, 29, 2, 23, 13, 2, 18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 27, 15, 18, 14, 2, 4, 4], neg_big, neg_small)))
	line!(Text.printed(say_ge([18, 13, 29, 73, 32, 17, 29, 2, 29, 13, 2, 18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 27, 15, 18, 14, 2, 3, 3], neg_big, neg_small)))
	line!(Text.printed(say_lt([18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 23, 14, 2, 18, 13, 29, 73, 32, 17, 29, 2, 27, 15, 18, 14, 2, 3, 3], neg_small, neg_big)))
	line!(Text.printed(say_gt([18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 29, 14, 2, 18, 13, 29, 73, 32, 17, 29, 2, 27, 15, 18, 14, 2, 4, 4], neg_small, neg_big)))
	line!(Text.printed(say_lt([18, 13, 29, 73, 32, 17, 29, 2, 23, 14, 2, 18, 13, 29, 73, 32, 17, 29, 2, 27, 15, 18, 14, 2, 3, 3], neg_big, neg_big)))
	line!(Text.printed(say_le([18, 13, 29, 73, 32, 17, 29, 2, 23, 13, 2, 18, 13, 29, 73, 32, 17, 29, 2, 27, 15, 18, 14, 2, 4, 4], neg_big, neg_big)))
	line!(Text.printed(say_ge([18, 13, 29, 73, 32, 17, 29, 2, 29, 13, 2, 18, 13, 29, 73, 32, 17, 29, 2, 27, 15, 18, 14, 2, 4, 4], neg_big, neg_big)))
	line!(Text.printed(say_lt([31, 16, 19, 73, 19, 26, 15, 23, 23, 2, 23, 14, 2, 31, 16, 19, 73, 32, 17, 29, 2, 27, 15, 18, 14, 2, 4, 4], pos_small, pos_big)))
	line!(Text.printed(say_gt([31, 16, 19, 73, 19, 26, 15, 23, 23, 2, 29, 14, 2, 31, 16, 19, 73, 32, 17, 29, 2, 27, 15, 18, 14, 2, 3, 3], pos_small, pos_big)))
	line!(Text.printed(say_lt([18, 13, 29, 73, 32, 17, 29, 2, 23, 14, 2, 31, 16, 19, 73, 19, 26, 15, 23, 23, 2, 27, 15, 18, 14, 2, 4, 4], neg_big, pos_small)))
	line!(Text.printed(say_lt([31, 16, 19, 73, 32, 17, 29, 2, 23, 14, 2, 18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 27, 15, 18, 14, 2, 3, 3], pos_big, neg_small)))
	line!(Text.printed(say_lt([18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 23, 14, 2, 38, 13, 21, 16, 2, 27, 15, 18, 14, 2, 4, 4], neg_small, zero)))
	line!(Text.printed(say_gt([18, 13, 29, 73, 19, 26, 15, 23, 23, 2, 29, 14, 2, 38, 13, 21, 16, 2, 27, 15, 18, 14, 2, 3, 3], neg_small, zero)))
	Ok({})
}
