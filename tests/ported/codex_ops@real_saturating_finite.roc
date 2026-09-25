# ops@real-saturating-finite
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-saturating-finite.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     add 8 3 11
#     add 3 8 11
#     sub 8 3 5
#     sub 3 8 -5
#     mul 8 3 24
#     mul 3 8 24
#     div 8 4 2
#     div 24 8 3
#     mul 5 0 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealSaturatingFinite -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sat_add : F64, F64 -> F64
sat_add = |a, b| Prelude.sat_f64((a + b))

sat_sub : F64, F64 -> F64
sat_sub = |a, b| Prelude.sat_f64((a - b))

sat_mul : F64, F64 -> F64
sat_mul = |a, b| Prelude.sat_f64((a * b))

sat_div : F64, F64 -> F64
sat_div = |a, b| Prelude.sat_f64((a / b))

sat_int : F64 -> I64
sat_int = |x| F64.to_i64_wrap(x)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("add 8 3 ", CceText.show_int(sat_int(sat_add(I64.to_f64(8), I64.to_f64(3)))))))
	line!(CceText.printed(CceText.concat("add 3 8 ", CceText.show_int(sat_int(sat_add(I64.to_f64(3), I64.to_f64(8)))))))
	line!(CceText.printed(CceText.concat("sub 8 3 ", CceText.show_int(sat_int(sat_sub(I64.to_f64(8), I64.to_f64(3)))))))
	line!(CceText.printed(CceText.concat("sub 3 8 ", CceText.show_int(sat_int(sat_sub(I64.to_f64(3), I64.to_f64(8)))))))
	line!(CceText.printed(CceText.concat("mul 8 3 ", CceText.show_int(sat_int(sat_mul(I64.to_f64(8), I64.to_f64(3)))))))
	line!(CceText.printed(CceText.concat("mul 3 8 ", CceText.show_int(sat_int(sat_mul(I64.to_f64(3), I64.to_f64(8)))))))
	line!(CceText.printed(CceText.concat("div 8 4 ", CceText.show_int(sat_int(sat_div(I64.to_f64(8), I64.to_f64(4)))))))
	line!(CceText.printed(CceText.concat("div 24 8 ", CceText.show_int(sat_int(sat_div(I64.to_f64(24), I64.to_f64(8)))))))
	line!(CceText.printed(CceText.concat("mul 5 0 ", CceText.show_int(sat_int(sat_mul(I64.to_f64(5), I64.to_f64(0)))))))
	Ok({})
}
