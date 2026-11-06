# Color -- roc-ray's Color surface, for a world that stores one.
#
# Hand-written, the same trick as Math, Keys and Random. Pong's flash is
# presentation state carried in the world -- `color : Color.Rgba` -- and its
# palette is written as `Color.from_hex_rgb(0x38e8ff)`, so its rules mention
# colours even though they never draw. With this, they port with their import
# line changed and nothing else.
#
# Eight bits a channel, as roc-ray has it. `brush` is the one addition: what
# the canvas apps' own painting wants, where a channel is a float and alpha is
# nought to one.
import Brush

Color :: [].{
	Rgba : { r : U8, g : U8, b : U8, a : U8 }

	rgba : U8, U8, U8, U8 -> Color.Rgba
	rgba = |r, g, b, a| { r, g, b, a }

	from_hex_rgb : I64 -> Color.Rgba
	from_hex_rgb = |hex| {
		r: hex.shr_wrap(16).bitwise_and(255).to_u8_wrap(),
		g: hex.shr_wrap(8).bitwise_and(255).to_u8_wrap(),
		b: hex.bitwise_and(255).to_u8_wrap(),
		a: 255,
	}

	with_alpha : Color.Rgba, U8 -> Color.Rgba
	with_alpha = |c, a| { ..c, a }

	white : Color.Rgba
	white = { r: 255, g: 255, b: 255, a: 255 }

	## As the canvas apps' painting wants it.
	brush : Color.Rgba -> Brush.Rgba
	brush = |c| { r: c.r.to_f64(), g: c.g.to_f64(), b: c.b.to_f64(), a: c.a.to_f64() / 255.0 }
}
