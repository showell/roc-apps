# ops@int-min-literal
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@int-min-literal.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     min       want -9223372036854775808 got -9223372036854775808
#     min+1     want -9223372036854775807 got -9223372036854775807
#     min+254   want -9223372036854775554 got -9223372036854775554
#     min+255   want -9223372036854775553 got -9223372036854775553
#     min+256   want -9223372036854775552 got -9223372036854775552
#     max       want 9223372036854775807 got 9223372036854775807
#     allf      want -1 got -1
#     c000      want -4611686018427387904 got -4611686018427387904
#     minusinf  want -4503599627370496 got -4503599627370496
#     shl63     want 1 got 1
#     negzero   want 1 got 1
#     negzero>= want 1 got 1
#     negzero<= want 1 got 1

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# IntMinLiteral -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

b2i : Bool -> I64
b2i = |x| (if x { 1 } else { 0 })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("min       want -9223372036854775808 got ", CceText.show_int((-9223372036854775808)))))
	line!(CceText.printed(CceText.concat("min+1     want -9223372036854775807 got ", CceText.show_int((-9223372036854775807)))))
	line!(CceText.printed(CceText.concat("min+254   want -9223372036854775554 got ", CceText.show_int((-9223372036854775554)))))
	line!(CceText.printed(CceText.concat("min+255   want -9223372036854775553 got ", CceText.show_int((-9223372036854775553)))))
	line!(CceText.printed(CceText.concat("min+256   want -9223372036854775552 got ", CceText.show_int((-9223372036854775552)))))
	line!(CceText.printed(CceText.concat("max       want 9223372036854775807 got ", CceText.show_int(9223372036854775807))))
	line!(CceText.printed(CceText.concat("allf      want -1 got ", CceText.show_int((-1)))))
	line!(CceText.printed(CceText.concat("c000      want -4611686018427387904 got ", CceText.show_int((-4611686018427387904)))))
	line!(CceText.printed(CceText.concat("minusinf  want -4503599627370496 got ", CceText.show_int((-4503599627370496)))))
	line!(CceText.printed(CceText.concat("shl63     want 1 got ", CceText.show_int(b2i(((-9223372036854775808) == I64.shl_wrap(1, I64.to_u8_wrap(63))))))))
	line!(CceText.printed(CceText.concat("negzero   want 1 got ", CceText.show_int(b2i((U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap((-9223372036854775808))))) == I64.shl_wrap(1, I64.to_u8_wrap(63))))))))
	line!(CceText.printed(CceText.concat("negzero>= want 1 got ", CceText.show_int(b2i((F64.from_bits(I64.to_u64_wrap((-9223372036854775808))) >= 0.0))))))
	line!(CceText.printed(CceText.concat("negzero<= want 1 got ", CceText.show_int(b2i((F64.from_bits(I64.to_u64_wrap((-9223372036854775808))) <= 0.0))))))
	Ok({})
}
