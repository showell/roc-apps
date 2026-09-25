# ops@real-bitcast
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-bitcast.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     f64-bits: 5/5
#     f32-bits: 5/5
#     roundtrip-f64: 2/2
#     roundtrip-f32: 2/2

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RealBitcast -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

b2i : Bool -> I64
b2i = |x| (if x { 1 } else { 0 })

# --- Entry ---

main! = |_args| {
	({
		f64ok : I64
		f64ok = ((((b2i((U64.to_i64_wrap(F64.to_bits(0.0)) == 0)) + b2i((U64.to_i64_wrap(F64.to_bits(1.0)) == 4607182418800017408))) + b2i((U64.to_i64_wrap(F64.to_bits((-2.0))) == (-4611686018427387904)))) + b2i((U64.to_i64_wrap(F64.to_bits(0.5)) == 4602678819172646912))) + b2i((U64.to_i64_wrap(F64.to_bits(42.5)) == 4631178160564600832)))
		f32ok : I64
		f32ok = ((((b2i((U32.to_i64(F32.to_bits(F64.to_f32_wrap(0.0))) == 0)) + b2i((U32.to_i64(F32.to_bits(F64.to_f32_wrap(1.0))) == 1065353216))) + b2i((U32.to_i64(F32.to_bits(F64.to_f32_wrap((-2.0)))) == 3221225472))) + b2i((U32.to_i64(F32.to_bits(F64.to_f32_wrap(0.5))) == 1056964608))) + b2i((U32.to_i64(F32.to_bits(F64.to_f32_wrap(42.5))) == 1110048768)))
		rt64 : I64
		rt64 = (b2i((U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap(4607182418800017408)))) == 4607182418800017408)) + b2i((U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap(4631178160564600832)))) == 4631178160564600832)))
		rt32 : I64
		rt32 = (b2i((U32.to_i64(F32.to_bits(F32.from_bits(I64.to_u32_wrap(1065353216)))) == 1065353216)) + b2i((U32.to_i64(F32.to_bits(F32.from_bits(I64.to_u32_wrap(1110048768)))) == 1110048768)))
		({
			line!(CceText.printed(CceText.concat(CceText.concat("f64-bits: ", CceText.show_int(f64ok)), "/5")))
			line!(CceText.printed(CceText.concat(CceText.concat("f32-bits: ", CceText.show_int(f32ok)), "/5")))
			line!(CceText.printed(CceText.concat(CceText.concat("roundtrip-f64: ", CceText.show_int(rt64)), "/2")))
			line!(CceText.printed(CceText.concat(CceText.concat("roundtrip-f32: ", CceText.show_int(rt32)), "/2")))
		})
	})
	Ok({})
}
