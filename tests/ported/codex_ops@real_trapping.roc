# ops@real-trapping
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-trapping.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     sum 4619567317775286272
#     diff -4616189618054758400
#     at-max 9218868437227405311
#     half-max 9214364837600034815
#     max-cancels 0
#     min-at-edge -4503599627370497
#     div-small 9214364837600034815

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealTrapping -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

real_max : F64
real_max = F64.from_bits(I64.to_u64_wrap(9218868437227405311))

real_min : F64
real_min = F64.from_bits(I64.to_u64_wrap((-4503599627370497)))

add_trap : F64, F64 -> F64
add_trap = |a, b| Prelude.trap_f64((a + b))

sub_trap : F64, F64 -> F64
sub_trap = |a, b| Prelude.trap_f64((a - b))

mul_trap : F64, F64 -> F64
mul_trap = |a, b| Prelude.trap_f64((a * b))

div_trap : F64, F64 -> F64
div_trap = |a, b| Prelude.trap_f64((a / b))

trap_bits : F64 -> I64
trap_bits = |x| U64.to_i64_wrap(F64.to_bits(x))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("sum ", CceText.show_int(trap_bits(add_trap(3.0, 4.0))))))
	line!(CceText.printed(CceText.concat("diff ", CceText.show_int(trap_bits(sub_trap(3.0, 4.0))))))
	line!(CceText.printed(CceText.concat("at-max ", CceText.show_int(trap_bits(add_trap(real_max, 0.0))))))
	line!(CceText.printed(CceText.concat("half-max ", CceText.show_int(trap_bits(mul_trap(real_max, 0.5))))))
	line!(CceText.printed(CceText.concat("max-cancels ", CceText.show_int(trap_bits(sub_trap(real_max, real_max))))))
	line!(CceText.printed(CceText.concat("min-at-edge ", CceText.show_int(trap_bits(sub_trap(real_min, 0.0))))))
	line!(CceText.printed(CceText.concat("div-small ", CceText.show_int(trap_bits(div_trap(real_max, 2.0))))))
	Ok({})
}
