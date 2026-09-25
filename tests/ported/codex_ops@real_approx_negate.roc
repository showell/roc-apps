# ops@real-approx-negate
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-approx-negate.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     neg pos is negative   want 1: 1
#     neg 2.5 lt neg 1.5    want 1: 1
#     double negate not lt  want 0: 0
#     neg neg is positive   want 0: 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RealApproxNegate -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ran_pos : F64
ran_pos = 2.5

ran_small : F64
ran_small = 1.5

b2i : Bool -> I64
b2i = |b| (if b { 1 } else { 0 })

approx_neg : F32 -> F32
approx_neg = |a| (-a)

approx_lt : F32, F32 -> I64
approx_lt = |a, b| b2i((a < b))

approx_round_trip : F32 -> I64
approx_round_trip = |a| b2i(((-(-a)) < a))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("neg pos is negative   want 1: ", CceText.show_int(approx_lt(approx_neg(F64.to_f32_wrap(ran_pos)), F64.to_f32_wrap(0.0))))))
	line!(CceText.printed(CceText.concat("neg 2.5 lt neg 1.5    want 1: ", CceText.show_int(approx_lt(approx_neg(F64.to_f32_wrap(ran_pos)), approx_neg(F64.to_f32_wrap(ran_small)))))))
	line!(CceText.printed(CceText.concat("double negate not lt  want 0: ", CceText.show_int(approx_round_trip(F64.to_f32_wrap(ran_pos))))))
	line!(CceText.printed(CceText.concat("neg neg is positive   want 0: ", CceText.show_int(approx_lt(approx_neg(approx_neg(F64.to_f32_wrap(ran_pos))), F64.to_f32_wrap(0.0))))))
	Ok({})
}
