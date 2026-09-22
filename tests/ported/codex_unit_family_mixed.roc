# unit-family-mixed
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/unit-family-mixed.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     perimeter mm+yard: 2828mm
#       in cm: 282
#       in inches: 113
#     fence: 8478mm
#       in meters: 8
#       in feet: 27

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# UnitFamilyMixed -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Length : I64

area : Length, Length -> Length
area = |w, h| (w * I64.div_trunc_by(h, w))

perimeter : Length, Length -> Length
perimeter = |w, h| ((w + h) * 2)

total_fence : Length, Length, Length, Length -> Length
total_fence = |a, b, c, d| (((a + b) + c) + d)

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

inch : I64 -> Length
inch = |fv| (fv * 25)

length_to_Inch : Length -> I64
length_to_Inch = |fv| I64.div_trunc_by(fv, 25)

foot : I64 -> Length
foot = |fv| (fv * 305)

length_to_Foot : Length -> I64
length_to_Foot = |fv| I64.div_trunc_by(fv, 305)

yard : I64 -> Length
yard = |fv| (fv * 914)

length_to_Yard : Length -> I64
length_to_Yard = |fv| I64.div_trunc_by(fv, 914)

mile : I64 -> Length
mile = |fv| (fv * 1609344)

length_to_Mile : Length -> I64
length_to_Mile = |fv| I64.div_trunc_by(fv, 1609344)

# --- Entry ---

main! = |_args| {
	({
		w = millimeter(500)
		h = yard(1)
		p = perimeter(w, h)
		fence = total_fence(meter(3), foot(10), inch(24), yard(2))
		({
			line!(Text.printed(List.concat(List.concat([31, 13, 21, 17, 26, 13, 14, 13, 21, 2, 26, 26, 76, 30, 15, 21, 22, 69, 2], Text.show_int(p)), [26, 26])))
			line!(Text.printed(List.concat([2, 2, 17, 18, 2, 24, 26, 69, 2], Text.show_int(length_to_Centimeter(p)))))
			line!(Text.printed(List.concat([2, 2, 17, 18, 2, 17, 18, 24, 20, 13, 19, 69, 2], Text.show_int(length_to_Inch(p)))))
			line!(Text.printed(List.concat(List.concat([28, 13, 18, 24, 13, 69, 2], Text.show_int(fence)), [26, 26])))
			line!(Text.printed(List.concat([2, 2, 17, 18, 2, 26, 13, 14, 13, 21, 19, 69, 2], Text.show_int(length_to_Meter(fence)))))
			line!(Text.printed(List.concat([2, 2, 17, 18, 2, 28, 13, 13, 14, 69, 2], Text.show_int(length_to_Foot(fence)))))
		})
	})
	Ok({})
}
