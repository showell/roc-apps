# ops@real-saturating
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-saturating.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     finite-add 4619567317775286272
#     finite-div 4615063718147915776
#     ovf-add 9218868437227405311
#     ovf-mul 9218868437227405311
#     ovf-neg -4503599627370497
#     ovf-sub -4503599627370497
#     ovf-div 9218868437227405311
#     nan-zero 0
#     nan-safe 4607182418800017408

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealSaturating -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

real_max : F64
real_max = F64.from_bits(I64.to_u64_wrap(9218868437227405311))

real_min : F64
real_min = F64.from_bits(I64.to_u64_wrap((-4503599627370497)))

add_sat : F64, F64 -> F64
add_sat = |a, b| Prelude.sat_f64((a + b))

sub_sat : F64, F64 -> F64
sub_sat = |a, b| Prelude.sat_f64((a - b))

mul_sat : F64, F64 -> F64
mul_sat = |a, b| Prelude.sat_f64((a * b))

div_sat : F64, F64 -> F64
div_sat = |a, b| Prelude.sat_f64((a / b))

sat_bits : F64 -> I64
sat_bits = |x| U64.to_i64_wrap(F64.to_bits(x))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("finite-add ", CceText.show_int(sat_bits(add_sat(3.0, 4.0))))))
	line!(CceText.printed(CceText.concat("finite-div ", CceText.show_int(sat_bits(div_sat(7.0, 2.0))))))
	line!(CceText.printed(CceText.concat("ovf-add ", CceText.show_int(sat_bits(add_sat(real_max, real_max))))))
	line!(CceText.printed(CceText.concat("ovf-mul ", CceText.show_int(sat_bits(mul_sat(real_max, 2.0))))))
	line!(CceText.printed(CceText.concat("ovf-neg ", CceText.show_int(sat_bits(add_sat(real_min, real_min))))))
	line!(CceText.printed(CceText.concat("ovf-sub ", CceText.show_int(sat_bits(sub_sat(real_min, real_max))))))
	line!(CceText.printed(CceText.concat("ovf-div ", CceText.show_int(sat_bits(div_sat(real_max, 0.5))))))
	line!(CceText.printed(CceText.concat("nan-zero ", CceText.show_int(sat_bits(div_sat(0.0, 0.0))))))
	line!(CceText.printed(CceText.concat("nan-safe ", CceText.show_int(sat_bits(add_sat(div_sat(0.0, 0.0), 1.0))))))
	Ok({})
}
