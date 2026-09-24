# unit-family
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/unit-family.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     2400
#     240
#     2
#     100

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnitFamily -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Length : I64

perimeter : Length, Length -> Length
perimeter = |w, h| ((w + h) * 2)

double_length : Length -> Length
double_length = |x| (x * 2)

millimeter : I64 -> Length
millimeter = |fv| fv

length_to_Millimeter : Length -> I64
length_to_Millimeter = |fv| fv

centimeter : I64 -> Length
centimeter = |fv| (fv * 10)

length_to_Centimeter : Length -> I64
length_to_Centimeter = |fv| I64.div_trunc_by(fv, 10)

meter : I64 -> Length
meter = |fv| (fv * 1000)

length_to_Meter : Length -> I64
length_to_Meter = |fv| I64.div_trunc_by(fv, 1000)

kilometer : I64 -> Length
kilometer = |fv| (fv * 1000000)

length_to_Kilometer : Length -> I64
length_to_Kilometer = |fv| I64.div_trunc_by(fv, 1000000)

# --- Entry ---

main! = |_args| {
	({
		w = centimeter(20)
		h = meter(1)
		p = perimeter(w, h)
		({
			line!(CceText.printed(CceText.show_int(p)))
			line!(CceText.printed(CceText.show_int(length_to_Centimeter(p))))
			line!(CceText.printed(CceText.show_int(length_to_Meter(p))))
			line!(CceText.printed(CceText.show_int(double_length(millimeter(50)))))
		})
	})
	Ok({})
}
