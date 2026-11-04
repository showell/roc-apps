## A pixel's colour as a U32, 0xRRGGBB, and a colour with an alpha laid over
## one. Each channel rounds to the nearest whole number and is held to 0..255.
import lib.Brush

PixelColor :: [].{

	## A pixel's red, green and blue, each 0 to 255.
	Rgb : { r : F64, g : F64, b : F64 }

	pack : PixelColor.Rgb -> U32
	pack = |{ r, g, b }| {
		red = channel_byte(r).shl_wrap(16)
		green = channel_byte(g).shl_wrap(8)
		red.bitwise_or(green).bitwise_or(channel_byte(b))
	}

	## `color` laid over the opaque `pixel`.
	over : U32, Brush.Rgba -> U32
	over = |pixel, color|
		if color.a >= 1.0 {
			PixelColor.pack({ r: color.r, g: color.g, b: color.b })
		} else if color.a <= 0.0 {
			pixel
		} else {
			kept = 1.0 - color.a
			under = unpack(pixel)
			PixelColor.pack({
				r: color.r * color.a + under.r * kept,
				g: color.g * color.a + under.g * kept,
				b: color.b * color.a + under.b * kept,
			})
		}
}

channel_byte : F64 -> U32
channel_byte = |v| {
	n = F64.to_i64_wrap(v + 0.5)
	I64.to_u32_wrap(
		if n < 0 {
			0
		} else if n > 255 {
			255
		} else {
			n
		},
	)
}

## A pixel's channels: the mirror of `pack`.
unpack : U32 -> PixelColor.Rgb
unpack = |pixel| {
	r: pixel.shr_wrap(16).bitwise_and(255).to_f64(),
	g: pixel.shr_wrap(8).bitwise_and(255).to_f64(),
	b: pixel.bitwise_and(255).to_f64(),
}
