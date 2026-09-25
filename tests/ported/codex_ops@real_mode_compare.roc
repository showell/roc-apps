# ops@real-mode-compare
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-mode-compare.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     plain  neg lt neg want 11: 11
#     trap   neg lt neg want 11: 11
#     sat    neg lt neg want 11: 11
#     approx neg lt neg want 11: 11
#     trap   neg ge neg want 00: 00
#     trap   neg lt pos want 11: 11
#     sat    neg lt pos want 11: 11

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RealModeCompare -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

neg_big : F64
neg_big = (0.0 - 2.9)

neg_small : F64
neg_small = (0.0 - 1.5)

pos_small : F64
pos_small = 1.5

b2i : Bool -> I64
b2i = |b| (if b { 1 } else { 0 })

plain_fused : F64, F64 -> I64
plain_fused = |a, b| (if (a < b) { 1 } else { 0 })

plain_val : F64, F64 -> I64
plain_val = |a, b| b2i((a < b))

trap_fused : F64, F64 -> I64
trap_fused = |a, b| (if (a < b) { 1 } else { 0 })

trap_val : F64, F64 -> I64
trap_val = |a, b| b2i((a < b))

trap_ge_fused : F64, F64 -> I64
trap_ge_fused = |a, b| (if (a >= b) { 1 } else { 0 })

sat_fused : F64, F64 -> I64
sat_fused = |a, b| (if (a < b) { 1 } else { 0 })

sat_val : F64, F64 -> I64
sat_val = |a, b| b2i((a < b))

approx_fused : F32, F32 -> I64
approx_fused = |a, b| (if (a < b) { 1 } else { 0 })

approx_val : F32, F32 -> I64
approx_val = |a, b| b2i((a < b))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat(CceText.concat("plain  neg lt neg want 11: ", CceText.show_int(plain_fused(neg_big, neg_small))), CceText.show_int(plain_val(neg_big, neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("trap   neg lt neg want 11: ", CceText.show_int(trap_fused(neg_big, neg_small))), CceText.show_int(trap_val(neg_big, neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("sat    neg lt neg want 11: ", CceText.show_int(sat_fused(neg_big, neg_small))), CceText.show_int(sat_val(neg_big, neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("approx neg lt neg want 11: ", CceText.show_int(approx_fused(F64.to_f32_wrap(neg_big), F64.to_f32_wrap(neg_small)))), CceText.show_int(approx_val(F64.to_f32_wrap(neg_big), F64.to_f32_wrap(neg_small))))))
	line!(CceText.printed(CceText.concat(CceText.concat("trap   neg ge neg want 00: ", CceText.show_int(trap_ge_fused(neg_big, neg_small))), CceText.show_int(trap_ge_fused(neg_big, neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("trap   neg lt pos want 11: ", CceText.show_int(trap_fused(neg_big, pos_small))), CceText.show_int(trap_val(neg_big, pos_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("sat    neg lt pos want 11: ", CceText.show_int(sat_fused(neg_big, pos_small))), CceText.show_int(sat_val(neg_big, pos_small)))))
	Ok({})
}
