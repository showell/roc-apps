# ops@real-bitcast-f64
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-bitcast-f64.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     bits 0.0 0
#     bits 1.0 4607182418800017408
#     bits 0.5 4602678819172646912
#     bits 42.5 4631178160564600832
#     bits -1.0 -4616189618054758400
#     bits -2.0 -4611686018427387904
#     negzero -9223372036854775808
#     poszero 0
#     nan 9221120237041090560
#     inf 9218868437227405312
#     maxfinite 9218868437227405311
#     roundtrip 42.5 4631178160564600832

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RealBitcastF64 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("bits 0.0 ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(0.0))))))
	line!(CceText.printed(CceText.concat("bits 1.0 ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(1.0))))))
	line!(CceText.printed(CceText.concat("bits 0.5 ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(0.5))))))
	line!(CceText.printed(CceText.concat("bits 42.5 ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(42.5))))))
	line!(CceText.printed(CceText.concat("bits -1.0 ", CceText.show_int(U64.to_i64_wrap(F64.to_bits((0.0 - 1.0)))))))
	line!(CceText.printed(CceText.concat("bits -2.0 ", CceText.show_int(U64.to_i64_wrap(F64.to_bits((0.0 - 2.0)))))))
	line!(CceText.printed(CceText.concat("negzero ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap((-9223372036854775808)))))))))
	line!(CceText.printed(CceText.concat("poszero ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap(0))))))))
	line!(CceText.printed(CceText.concat("nan ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap(9221120237041090560))))))))
	line!(CceText.printed(CceText.concat("inf ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap(9218868437227405312))))))))
	line!(CceText.printed(CceText.concat("maxfinite ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap(9218868437227405311))))))))
	line!(CceText.printed(CceText.concat("roundtrip 42.5 ", CceText.show_int(U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap(U64.to_i64_wrap(F64.to_bits(42.5))))))))))
	Ok({})
}
