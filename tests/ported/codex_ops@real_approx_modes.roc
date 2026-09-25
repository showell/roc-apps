# ops@real-approx-modes
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-approx-modes.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     f32 max bits 2139095039
#     sat mul overflow 2139095039
#     sat add overflow 2139095039
#     sat finite stays 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealApproxModes -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

f32_max : F32
f32_max = F32.from_bits(I64.to_u32_wrap(2139095039))

f32_two : F32
f32_two = I64.to_f32(2)

sat : F32, F32 -> F32
sat = |a, b| Prelude.sat_f32((a * b))

sat_add : F32, F32 -> F32
sat_add = |a, b| Prelude.sat_f32((a + b))

sat_bits : F32 -> I64
sat_bits = |x| U32.to_i64(F32.to_bits(x))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("f32 max bits ", CceText.show_int(U32.to_i64(F32.to_bits(f32_max))))))
	line!(CceText.printed(CceText.concat("sat mul overflow ", CceText.show_int(sat_bits(sat(f32_max, f32_two))))))
	line!(CceText.printed(CceText.concat("sat add overflow ", CceText.show_int(sat_bits(sat_add(f32_max, f32_max))))))
	line!(CceText.printed(CceText.concat("sat finite stays ", CceText.show_int(sat_bits(sat(f32_max, I64.to_f32(0)))))))
	Ok({})
}
