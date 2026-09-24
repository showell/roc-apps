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
			line!(Text.printed(Text.concat(Text.concat("perimeter mm+yard: ", Text.show_int(p)), "mm")))
			line!(Text.printed(Text.concat("  in cm: ", Text.show_int(length_to_Centimeter(p)))))
			line!(Text.printed(Text.concat("  in inches: ", Text.show_int(length_to_Inch(p)))))
			line!(Text.printed(Text.concat(Text.concat("fence: ", Text.show_int(fence)), "mm")))
			line!(Text.printed(Text.concat("  in meters: ", Text.show_int(length_to_Meter(fence)))))
			line!(Text.printed(Text.concat("  in feet: ", Text.show_int(length_to_Foot(fence)))))
		})
	})
	Ok({})
}
