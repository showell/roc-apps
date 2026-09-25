# ops@real-approx
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-approx.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     sum: 7.0
#     prod: 12.0
#     show-f32: 7.0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealApprox -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

add_f32 : F32, F32 -> F32
add_f32 = |a, b| (a + b)

mul_f32 : F32, F32 -> F32
mul_f32 = |a, b| (a * b)

# --- Entry ---

main! = |_args| {
	({
		a : F32
		a = F64.to_f32_wrap(3.0)
		b : F32
		b = F64.to_f32_wrap(4.0)
		sum : F32
		sum = add_f32(a, b)
		prod : F32
		prod = mul_f32(a, b)
		({
			line!(CceText.printed(CceText.concat("sum: ", CceText.of_str(Prelude.real_to_str(F32.to_f64(sum))))))
			line!(CceText.printed(CceText.concat("prod: ", CceText.of_str(Prelude.real_to_str(F32.to_f64(prod))))))
			line!(CceText.printed(CceText.concat("show-f32: ", CceText.of_str(Prelude.real_to_str(F32.to_f64(sum))))))
		})
	})
	Ok({})
}
