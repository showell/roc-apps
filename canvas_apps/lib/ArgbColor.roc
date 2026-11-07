## ArgbColor is a colour with its alpha, as one whole number, 0xAARRGGBB: eight
## bits each of alpha, red, green and blue, alpha highest. A gradient's colours
## are these, and so is any fill that is part way see-through.
## `Brush.translucent` turns one into a brush colour.
##
## The colour with no alpha, 0xRRGGBB, is an `RgbColor`, a different type, so
## neither can be passed where the other belongs. A 0xRRGGBB read as 0xAARRGGBB
## has alpha 0 and paints nothing, so `from_rgb` is the way from one to the
## other.
import RgbColor

ArgbColor :: I64.{

	## Crashes outside 0..0xFFFFFFFF.
	of : I64 -> ArgbColor
	of = |argb|
		if argb < 0 or argb > 0xFFFFFFFF {
			crash "ArgbColor.of: a colour outside 0 to 0xFFFFFFFF"
		} else {
			ArgbColor.(argb)
		}

	## An opaque colour given an alpha byte, 0 for none and 255 for whole.
	from_rgb : RgbColor, { alpha : U8 } -> ArgbColor
	from_rgb = |color, { alpha }| ArgbColor.(alpha.to_i64().shl_wrap(24).bitwise_or(color.to_i64()))

	to_i64 : ArgbColor -> I64
	to_i64 = |ArgbColor.(argb)| argb

	is_eq : _
}

expect ArgbColor.of(0x80FFE9A8).to_i64() == 0x80FFE9A8
expect ArgbColor.of(0).to_i64() == 0
expect ArgbColor.of(0xFFFFFFFF).to_i64() == 0xFFFFFFFF

# The alpha byte lands on top of the colour, at either end and between.
expect
	[
		(0, 0x00FF2A18),
		(1, 0x01FF2A18),
		(254, 0xFEFF2A18),
		(255, 0xFFFF2A18),
	].all(|(alpha, argb)| ArgbColor.from_rgb(RgbColor.of(0xFF2A18), { alpha: alpha }) == ArgbColor.of(argb))
