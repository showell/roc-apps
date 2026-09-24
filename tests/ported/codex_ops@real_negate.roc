# ops@real-negate
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-negate.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     neg-param   -25
#     neg-call    -50
#     neg-field   -15
#     neg-nested  -80
#     neg-multi   -110
#     mixed       -190

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RealNegate -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Vec : { vx : F64, vy : F64 }

scale_by_two : F64 -> F64
scale_by_two = |x| (x * 2.0)

dot : Vec, Vec -> F64
dot = |a, b| ((a.vx * b.vx) + (a.vy * b.vy))

neg_param : F64 -> F64
neg_param = |x| (-x)

neg_call : F64 -> F64
neg_call = |x| (-scale_by_two(x))

neg_call_multi : Vec, Vec -> F64
neg_call_multi = |a, b| (-dot(a, b))

neg_field : Vec -> F64
neg_field = |v| (-v.vx)

neg_nested : F64 -> F64
neg_nested = |x| (-scale_by_two(scale_by_two(x)))

mixed : Vec, Vec -> F64
mixed = |a, b| ((((-dot(a, b)) * 2.0) + a.vx) * 10.0)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("neg-param   ", CceText.show_int(F64.to_i64_wrap((neg_param(2.5) * 10.0))))))
	line!(CceText.printed(CceText.concat("neg-call    ", CceText.show_int(F64.to_i64_wrap((neg_call(2.5) * 10.0))))))
	line!(CceText.printed(CceText.concat("neg-field   ", CceText.show_int(F64.to_i64_wrap((neg_field({ vx: 1.5, vy: 0.0 }) * 10.0))))))
	line!(CceText.printed(CceText.concat("neg-nested  ", CceText.show_int(F64.to_i64_wrap((neg_nested(2.0) * 10.0))))))
	line!(CceText.printed(CceText.concat("neg-multi   ", CceText.show_int(F64.to_i64_wrap((neg_call_multi({ vx: 3.0, vy: 4.0 }, { vx: 1.0, vy: 2.0 }) * 10.0))))))
	line!(CceText.printed(CceText.concat("mixed       ", CceText.show_int(F64.to_i64_wrap(mixed({ vx: 3.0, vy: 4.0 }, { vx: 1.0, vy: 2.0 }))))))
	Ok({})
}
