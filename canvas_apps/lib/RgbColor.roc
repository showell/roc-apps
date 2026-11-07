# RgbColor is an opaque colour as one whole number, 0xRRGGBB: eight bits each
# of red, green and blue, red highest. A flat fill's colour is one of these, and
# `Brush.opaque` is what turns it into a brush colour.
#
# A colour with alpha is an `ArgbColor`, a different type, so neither can be
# passed where the other belongs.

RgbColor :: I64.{

	of : I64 -> RgbColor
	of = |rgb|
		if rgb < 0 or rgb > 0xFFFFFF {
			crash "RgbColor.of: a colour outside 0 to 0xFFFFFF"
		} else {
			RgbColor.(rgb)
		}

	to_i64 : RgbColor -> I64
	to_i64 = |RgbColor.(rgb)| rgb

	is_eq : _
}

expect RgbColor.of(0xFFE9A8).to_i64() == 0xFFE9A8
expect RgbColor.of(0).to_i64() == 0
expect RgbColor.of(0xFFFFFF).to_i64() == 0xFFFFFF
expect RgbColor.of(0x8ECAE6) == RgbColor.of(0x8ECAE6)
expect RgbColor.of(0x8ECAE6) != RgbColor.of(0x8ECAE7)
