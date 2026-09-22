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

import cdx.Text

# IntMinLiteral -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

b2i : Bool -> I64
b2i = |x| (if x { 1 } else { 0 })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([26, 17, 18, 2, 2, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 2, 29, 16, 14, 2], Text.show_int((-9223372036854775808)))))
	line!(Text.printed(List.concat([26, 17, 18, 76, 4, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 2, 29, 16, 14, 2], Text.show_int((-9223372036854775807)))))
	line!(Text.printed(List.concat([26, 17, 18, 76, 5, 8, 7, 2, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 8, 8, 7, 2, 29, 16, 14, 2], Text.show_int((-9223372036854775554)))))
	line!(Text.printed(List.concat([26, 17, 18, 76, 5, 8, 8, 2, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 8, 8, 6, 2, 29, 16, 14, 2], Text.show_int((-9223372036854775553)))))
	line!(Text.printed(List.concat([26, 17, 18, 76, 5, 8, 9, 2, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 8, 8, 5, 2, 29, 16, 14, 2], Text.show_int((-9223372036854775552)))))
	line!(Text.printed(List.concat([26, 15, 36, 2, 2, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 2, 29, 16, 14, 2], Text.show_int(9223372036854775807))))
	line!(Text.printed(List.concat([15, 23, 23, 28, 2, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 73, 4, 2, 29, 16, 14, 2], Text.show_int((-1)))))
	line!(Text.printed(List.concat([24, 3, 3, 3, 2, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 73, 7, 9, 4, 4, 9, 11, 9, 3, 4, 11, 7, 5, 10, 6, 11, 10, 12, 3, 7, 2, 29, 16, 14, 2], Text.show_int((-4611686018427387904)))))
	line!(Text.printed(List.concat([26, 17, 18, 25, 19, 17, 18, 28, 2, 2, 27, 15, 18, 14, 2, 73, 7, 8, 3, 6, 8, 12, 12, 9, 5, 10, 6, 10, 3, 7, 12, 9, 2, 29, 16, 14, 2], Text.show_int((-4503599627370496)))))
	line!(Text.printed(List.concat([19, 20, 23, 9, 6, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 4, 2, 29, 16, 14, 2], Text.show_int(b2i(((-9223372036854775808) == I64.shl_wrap(1, I64.to_u8_wrap(63))))))))
	line!(Text.printed(List.concat([18, 13, 29, 38, 13, 21, 16, 2, 2, 2, 27, 15, 18, 14, 2, 4, 2, 29, 16, 14, 2], Text.show_int(b2i((U64.to_i64_wrap(F64.to_bits(F64.from_bits(I64.to_u64_wrap((-9223372036854775808))))) == I64.shl_wrap(1, I64.to_u8_wrap(63))))))))
	line!(Text.printed(List.concat([18, 13, 29, 38, 13, 21, 16, 80, 77, 2, 27, 15, 18, 14, 2, 4, 2, 29, 16, 14, 2], Text.show_int(b2i((F64.from_bits(I64.to_u64_wrap((-9223372036854775808))) >= 0.0))))))
	line!(Text.printed(List.concat([18, 13, 29, 38, 13, 21, 16, 79, 77, 2, 27, 15, 18, 14, 2, 4, 2, 29, 16, 14, 2], Text.show_int(b2i((F64.from_bits(I64.to_u64_wrap((-9223372036854775808))) <= 0.0))))))
	Ok({})
}
