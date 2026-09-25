# ops@real-approx-equality
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-approx-equality.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     f32 -0 ~0 +0 (want True)  = True
#     f32 -0 ~  +0 (want True)  = True
#     f32 tiny straddle (True)  = True
#     f64 -0 ~0 +0 (want True)  = True
#     f64 -0 ~  +0 (want True)  = True

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealApproxEquality -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

neg_zero : F32
neg_zero = F32.from_bits(I64.to_u32_wrap(2147483648))

pos_zero : F32
pos_zero = F32.from_bits(I64.to_u32_wrap(0))

tiny_pos : F32
tiny_pos = F32.from_bits(I64.to_u32_wrap(1))

tiny_neg : F32
tiny_neg = F32.from_bits(I64.to_u32_wrap(2147483649))

d_neg_zero : F64
d_neg_zero = F64.from_bits(I64.to_u64_wrap((-9223372036854775808)))

d_pos_zero : F64
d_pos_zero = F64.from_bits(I64.to_u64_wrap(0))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("f32 -0 ~0 +0 (want True)  = ", (if (Prelude.ordinal32(neg_zero) == Prelude.ordinal32(pos_zero)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("f32 -0 ~  +0 (want True)  = ", (if Prelude.approx_eq32(neg_zero, pos_zero) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("f32 tiny straddle (True)  = ", (if Prelude.approx_eq32(tiny_neg, tiny_pos) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("f64 -0 ~0 +0 (want True)  = ", (if (Prelude.ordinal(d_neg_zero) == Prelude.ordinal(d_pos_zero)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("f64 -0 ~  +0 (want True)  = ", (if Prelude.approx_eq(d_neg_zero, d_pos_zero) { "True" } else { "False" }))))
	Ok({})
}
