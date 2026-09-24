# ops@unit-real-compare
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@unit-real-compare.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     neg-big lt neg-small want 11 got 11
#     neg-big gt neg-small want 00 got 00
#     neg-big le neg-small want 11 got 11
#     neg-big ge neg-small want 00 got 00
#     neg-small lt neg-big want 00 got 00
#     neg-small gt neg-big want 11 got 11
#     neg-big lt neg-big want 00 got 00
#     neg-big le neg-big want 11 got 11
#     neg-big ge neg-big want 11 got 11
#     pos-small lt pos-big want 11 got 11
#     pos-big lt pos-small want 00 got 00
#     neg-big lt pos-small want 11 got 11
#     pos-big lt neg-small want 00 got 00
#     neg-small lt zero want 11 got 11
#     neg-small gt zero want 00 got 00
#     hertz lo lt hi want 1 got 1
#     hertz hi lt lo want 0 got 0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnitRealCompare -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Metre : F64
Hertz : F64

m_neg_big : Metre
m_neg_big = (0.0 - 2.9)

m_neg_small : Metre
m_neg_small = (0.0 - 1.5)

m_zero : Metre
m_zero = 0.0

m_pos_small : Metre
m_pos_small = 1.5

m_pos_big : Metre
m_pos_big = 2.9

h_lo : Hertz
h_lo = 0.0016

h_hi : Hertz
h_hi = 0.0045

b2i : Bool -> I64
b2i = |b| (if b { 1 } else { 0 })

mf_lt : Metre, Metre -> I64
mf_lt = |a, b| (if (a < b) { 1 } else { 0 })

mv_lt : Metre, Metre -> I64
mv_lt = |a, b| b2i((a < b))

mf_gt : Metre, Metre -> I64
mf_gt = |a, b| (if (a > b) { 1 } else { 0 })

mv_gt : Metre, Metre -> I64
mv_gt = |a, b| b2i((a > b))

mf_le : Metre, Metre -> I64
mf_le = |a, b| (if (a <= b) { 1 } else { 0 })

mv_le : Metre, Metre -> I64
mv_le = |a, b| b2i((a <= b))

mf_ge : Metre, Metre -> I64
mf_ge = |a, b| (if (a >= b) { 1 } else { 0 })

mv_ge : Metre, Metre -> I64
mv_ge = |a, b| b2i((a >= b))

hv_lt : Hertz, Hertz -> I64
hv_lt = |a, b| b2i((a < b))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big lt neg-small want 11 got ", CceText.show_int(mf_lt(m_neg_big, m_neg_small))), CceText.show_int(mv_lt(m_neg_big, m_neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big gt neg-small want 00 got ", CceText.show_int(mf_gt(m_neg_big, m_neg_small))), CceText.show_int(mv_gt(m_neg_big, m_neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big le neg-small want 11 got ", CceText.show_int(mf_le(m_neg_big, m_neg_small))), CceText.show_int(mv_le(m_neg_big, m_neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big ge neg-small want 00 got ", CceText.show_int(mf_ge(m_neg_big, m_neg_small))), CceText.show_int(mv_ge(m_neg_big, m_neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-small lt neg-big want 00 got ", CceText.show_int(mf_lt(m_neg_small, m_neg_big))), CceText.show_int(mv_lt(m_neg_small, m_neg_big)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-small gt neg-big want 11 got ", CceText.show_int(mf_gt(m_neg_small, m_neg_big))), CceText.show_int(mv_gt(m_neg_small, m_neg_big)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big lt neg-big want 00 got ", CceText.show_int(mf_lt(m_neg_big, m_neg_big))), CceText.show_int(mv_lt(m_neg_big, m_neg_big)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big le neg-big want 11 got ", CceText.show_int(mf_le(m_neg_big, m_neg_big))), CceText.show_int(mv_le(m_neg_big, m_neg_big)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big ge neg-big want 11 got ", CceText.show_int(mf_ge(m_neg_big, m_neg_big))), CceText.show_int(mv_ge(m_neg_big, m_neg_big)))))
	line!(CceText.printed(CceText.concat(CceText.concat("pos-small lt pos-big want 11 got ", CceText.show_int(mf_lt(m_pos_small, m_pos_big))), CceText.show_int(mv_lt(m_pos_small, m_pos_big)))))
	line!(CceText.printed(CceText.concat(CceText.concat("pos-big lt pos-small want 00 got ", CceText.show_int(mf_lt(m_pos_big, m_pos_small))), CceText.show_int(mv_lt(m_pos_big, m_pos_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-big lt pos-small want 11 got ", CceText.show_int(mf_lt(m_neg_big, m_pos_small))), CceText.show_int(mv_lt(m_neg_big, m_pos_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("pos-big lt neg-small want 00 got ", CceText.show_int(mf_lt(m_pos_big, m_neg_small))), CceText.show_int(mv_lt(m_pos_big, m_neg_small)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-small lt zero want 11 got ", CceText.show_int(mf_lt(m_neg_small, m_zero))), CceText.show_int(mv_lt(m_neg_small, m_zero)))))
	line!(CceText.printed(CceText.concat(CceText.concat("neg-small gt zero want 00 got ", CceText.show_int(mf_gt(m_neg_small, m_zero))), CceText.show_int(mv_gt(m_neg_small, m_zero)))))
	line!(CceText.printed(CceText.concat("hertz lo lt hi want 1 got ", CceText.show_int(hv_lt(h_lo, h_hi)))))
	line!(CceText.printed(CceText.concat("hertz hi lt lo want 0 got ", CceText.show_int(hv_lt(h_hi, h_lo)))))
	Ok({})
}
