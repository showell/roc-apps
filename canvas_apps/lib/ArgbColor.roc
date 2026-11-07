# ArgbColor -- a colour with its alpha, as one whole number, 0xAARRGGBB: eight
# bits each of alpha, red, green and blue, alpha highest. A gradient's colours
# are these, and so is any fill that is part way see-through.
#
# The colour with no alpha, 0xRRGGBB, is an `RgbColor`, a different type, so
# neither can be passed where the other belongs. A 0xRRGGBB read as 0xAARRGGBB
# has alpha 0 and paints nothing.
import Brush

ArgbColor :: I64.{

	of : I64 -> ArgbColor
	of = |argb| ArgbColor.(argb)

	to_i64 : ArgbColor -> I64
	to_i64 = |ArgbColor.(argb)| argb

	## The colour as a brush paints it: each channel 0 to 255, alpha 0 to 1.
	to_rgba : ArgbColor -> Brush.Rgba
	to_rgba = |ArgbColor.(argb)| {
		r: Brush.chan(argb, 16),
		g: Brush.chan(argb, 8),
		b: Brush.chan(argb, 0),
		a: Brush.chan(argb, 24) / 255.0,
	}

	is_eq : _
}

expect ArgbColor.to_rgba(ArgbColor.of(0x80FFE9A8)) == { r: 255.0, g: 233.0, b: 168.0, a: 128.0 / 255.0 }
expect ArgbColor.to_rgba(ArgbColor.of(0xFF000000)) == { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }

# A colour with no alpha byte is invisible.
expect ArgbColor.to_rgba(ArgbColor.of(0x00FFE9A8)).a == 0.0
