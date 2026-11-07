# ArgbColor -- a colour with its alpha, as one whole number, 0xAARRGGBB: eight
# bits each of alpha, red, green and blue, alpha highest. A gradient's colours
# are these, and so is any fill that is part way see-through.
# `Brush.translucent` turns one into a brush colour.
#
# The colour with no alpha, 0xRRGGBB, is an `RgbColor`, a different type, so
# neither can be passed where the other belongs. A 0xRRGGBB read as 0xAARRGGBB
# has alpha 0 and paints nothing.

ArgbColor :: I64.{

	of : I64 -> ArgbColor
	of = |argb|
		if argb < 0 or argb > 0xFFFFFFFF {
			crash "ArgbColor.of: a colour outside 0 to 0xFFFFFFFF"
		} else {
			ArgbColor.(argb)
		}

	to_i64 : ArgbColor -> I64
	to_i64 = |ArgbColor.(argb)| argb

	is_eq : _
}

expect ArgbColor.of(0x80FFE9A8).to_i64() == 0x80FFE9A8
expect ArgbColor.of(0).to_i64() == 0
expect ArgbColor.of(0xFFFFFFFF).to_i64() == 0xFFFFFFFF
