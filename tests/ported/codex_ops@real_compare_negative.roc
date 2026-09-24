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

import cdx.CceText

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

say_lt : CceText, F64, F64 -> CceText
say_lt = |label, a, b| CceText.concat(CceText.concat(CceText.concat(label, " "), CceText.show_int(fused_lt(a, b))), CceText.show_int(val_lt(a, b)))

say_gt : CceText, F64, F64 -> CceText
say_gt = |label, a, b| CceText.concat(CceText.concat(CceText.concat(label, " "), CceText.show_int(fused_gt(a, b))), CceText.show_int(val_gt(a, b)))

say_le : CceText, F64, F64 -> CceText
say_le = |label, a, b| CceText.concat(CceText.concat(CceText.concat(label, " "), CceText.show_int(fused_le(a, b))), CceText.show_int(val_le(a, b)))

say_ge : CceText, F64, F64 -> CceText
say_ge = |label, a, b| CceText.concat(CceText.concat(CceText.concat(label, " "), CceText.show_int(fused_ge(a, b))), CceText.show_int(val_ge(a, b)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(say_lt("neg-big lt neg-small want 11", neg_big, neg_small)))
	line!(CceText.printed(say_gt("neg-big gt neg-small want 00", neg_big, neg_small)))
	line!(CceText.printed(say_le("neg-big le neg-small want 11", neg_big, neg_small)))
	line!(CceText.printed(say_ge("neg-big ge neg-small want 00", neg_big, neg_small)))
	line!(CceText.printed(say_lt("neg-small lt neg-big want 00", neg_small, neg_big)))
	line!(CceText.printed(say_gt("neg-small gt neg-big want 11", neg_small, neg_big)))
	line!(CceText.printed(say_lt("neg-big lt neg-big want 00", neg_big, neg_big)))
	line!(CceText.printed(say_le("neg-big le neg-big want 11", neg_big, neg_big)))
	line!(CceText.printed(say_ge("neg-big ge neg-big want 11", neg_big, neg_big)))
	line!(CceText.printed(say_lt("pos-small lt pos-big want 11", pos_small, pos_big)))
	line!(CceText.printed(say_gt("pos-small gt pos-big want 00", pos_small, pos_big)))
	line!(CceText.printed(say_lt("neg-big lt pos-small want 11", neg_big, pos_small)))
	line!(CceText.printed(say_lt("pos-big lt neg-small want 00", pos_big, neg_small)))
	line!(CceText.printed(say_lt("neg-small lt zero want 11", neg_small, zero)))
	line!(CceText.printed(say_gt("neg-small gt zero want 00", neg_small, zero)))
	Ok({})
}
