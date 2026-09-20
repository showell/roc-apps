# Color -- roc-ray's Color surface, for a world that stores one.
#
# Hand-written, the same trick as Math, Keys and Random. Pong's flash is
# presentation state carried in the world -- `color : Color.Rgba` -- and its
# palette is written as `Color.from_hex_rgb(0x38e8ff)`, so its rules mention
# colours even though they never draw. With this, they port with their import
# line changed and nothing else.
#
# Eight bits a channel, as roc-ray has it. `brush` is the one addition: what
# the arcade's own painting wants, where a channel is a float and alpha is
# nought to one.
import Brush

Color :: [].{
	Rgba : { r : U8, g : U8, b : U8, a : U8 }

	rgba : U8, U8, U8, U8 -> Color.Rgba
	rgba = |r, g, b, a| { r, g, b, a }

	from_hex_rgb : I64 -> Color.Rgba
	from_hex_rgb = |hex| {
		r: I64.to_u8_wrap(I64.bitwise_and(I64.shr_wrap(hex, 16), 255)),
		g: I64.to_u8_wrap(I64.bitwise_and(I64.shr_wrap(hex, 8), 255)),
		b: I64.to_u8_wrap(I64.bitwise_and(hex, 255)),
		a: 255,
	}

	with_alpha : Color.Rgba, U8 -> Color.Rgba
	with_alpha = |c, a| { ..c, a }

	white : Color.Rgba
	white = { r: 255, g: 255, b: 255, a: 255 }

	## As the arcade's painting wants it.
	brush : Color.Rgba -> Brush.Rgba
	brush = |c| { r: U8.to_f64(c.r), g: U8.to_f64(c.g), b: U8.to_f64(c.b), a: U8.to_f64(c.a) / 255.0 }
}
