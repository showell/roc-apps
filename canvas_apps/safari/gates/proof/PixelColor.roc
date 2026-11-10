## A pixel's colour as a U32, 0xRRGGBB, and a colour with an alpha laid over
## one. Each channel rounds to the nearest whole number and is held to 0..255.
import lib.Brush

PixelColor :: [].{

	## A pixel's red, green and blue, each 0 to 255.
	Rgb : {
		r : F64,
		g : F64,
		b : F64,
	}

	pack : PixelColor.Rgb -> U32
	pack = |{ r, g, b }| {
		red = channel_byte(r).shl_wrap(16)
		green = channel_byte(g).shl_wrap(8)
		red.bitwise_or(green).bitwise_or(channel_byte(b))
	}

	## `color` laid over the opaque `pixel`.
	blended_pixel : U32, Brush.Rgba -> U32
	blended_pixel = |pixel, color|
		if color.a >= 1.0 {
			PixelColor.pack({
				r: color.r,
				g: color.g,
				b: color.b,
			})
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

	## `color`'s light added to the opaque `pixel`, in proportion to its alpha,
	## as a canvas's 'lighter' adds it: each channel the sum, held to 255.
	added_pixel : U32, Brush.Rgba -> U32
	added_pixel = |pixel, color| {
		under = unpack(pixel)
		PixelColor.pack({
			r: under.r + color.r * color.a,
			g: under.g + color.g * color.a,
			b: under.b + color.b * color.a,
		})
	}
}

# Light adds to what is there in proportion to its alpha, and none adds
# nothing.
expect PixelColor.added_pixel(
	0x204060,
	{
		r: 128.0,
		g: 64.0,
		b: 32.0,
		a: 0.5,
	},
) == 0x606070
expect PixelColor.added_pixel(
	0x204060,
	{
		r: 255.0,
		g: 255.0,
		b: 255.0,
		a: 0.0,
	},
) == 0x204060

# A channel that the light would take past full is held at 255, and one just
# under it is not.
expect PixelColor.added_pixel(
	0xF0F0F0,
	{
		r: 255.0,
		g: 255.0,
		b: 255.0,
		a: 1.0,
	},
) == 0xFFFFFF
expect PixelColor.added_pixel(
	0xF00000,
	{
		r: 14.0,
		g: 15.0,
		b: 16.0,
		a: 1.0,
	},
) == 0xFE0F10
expect PixelColor.added_pixel(
	0xF00000,
	{
		r: 15.0,
		g: 0.0,
		b: 0.0,
		a: 1.0,
	},
) == 0xFF0000
expect PixelColor.added_pixel(
	0xF00000,
	{
		r: 16.0,
		g: 0.0,
		b: 0.0,
		a: 1.0,
	},
) == 0xFF0000

channel_byte : F64 -> U32
channel_byte = |v| (v + 0.5).to_i64_wrap().max(0).min(255).to_u32_wrap()

## A pixel's channels: the mirror of `pack`.
unpack : U32 -> PixelColor.Rgb
unpack = |pixel| {
	r: pixel.shr_wrap(16).bitwise_and(255).to_f64(),
	g: pixel.shr_wrap(8).bitwise_and(255).to_f64(),
	b: pixel.bitwise_and(255).to_f64(),
}
