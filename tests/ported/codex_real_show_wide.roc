# real-show-wide
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/real-show-wide.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     d09 : 123456789.0
#     d15 : 123456789012345.0
#     d16 : 1234567890123456.0
#     d17 : 12345678901234568.0
#     d18 : 123456789012345680.0
#     frac: 1.5
#     half: 0.5
#     p63 : 9.22337203685478e+18
#     n63 : -9.22337203685478e+18
#     e20 : 1.0e+20
#     e300: 1.0e+300
#     max : 1.79769313486232e+308
#     inf : inf
#     ninf: -inf
#     nan : nan

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealShowWide -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("d09 : ", CceText.of_str(Prelude.real_to_str(123456789.0)))))
	line!(CceText.printed(CceText.concat("d15 : ", CceText.of_str(Prelude.real_to_str(123456789012345.0)))))
	line!(CceText.printed(CceText.concat("d16 : ", CceText.of_str(Prelude.real_to_str(1234567890123456.0)))))
	line!(CceText.printed(CceText.concat("d17 : ", CceText.of_str(Prelude.real_to_str(F64.from_bits(4847542438873900484))))))
	line!(CceText.printed(CceText.concat("d18 : ", CceText.of_str(Prelude.real_to_str(F64.from_bits(4862596447618666293))))))
	line!(CceText.printed(CceText.concat("frac: ", CceText.of_str(Prelude.real_to_str(1.5)))))
	line!(CceText.printed(CceText.concat("half: ", CceText.of_str(Prelude.real_to_str(0.5)))))
	line!(CceText.printed(CceText.concat("p63 : ", CceText.of_str(Prelude.real_to_str(F64.from_bits(I64.to_u64_wrap(4890909195324358656)))))))
	line!(CceText.printed(CceText.concat("n63 : ", CceText.of_str(Prelude.real_to_str((0.0 - F64.from_bits(I64.to_u64_wrap(4890909195324358656))))))))
	line!(CceText.printed(CceText.concat("e20 : ", CceText.of_str(Prelude.real_to_str(F64.from_bits(I64.to_u64_wrap(4906019910204099648)))))))
	line!(CceText.printed(CceText.concat("e300: ", CceText.of_str(Prelude.real_to_str(F64.from_bits(I64.to_u64_wrap(9094988921128908188)))))))
	line!(CceText.printed(CceText.concat("max : ", CceText.of_str(Prelude.real_to_str(F64.from_bits(I64.to_u64_wrap(9218868437227405311)))))))
	line!(CceText.printed(CceText.concat("inf : ", CceText.of_str(Prelude.real_to_str(F64.from_bits(I64.to_u64_wrap(9218868437227405312)))))))
	line!(CceText.printed(CceText.concat("ninf: ", CceText.of_str(Prelude.real_to_str((0.0 - F64.from_bits(I64.to_u64_wrap(9218868437227405312))))))))
	line!(CceText.printed(CceText.concat("nan : ", CceText.of_str(Prelude.real_to_str(F64.from_bits(I64.to_u64_wrap(9221120237041090560)))))))
	Ok({})
}
