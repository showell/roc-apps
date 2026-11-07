## A color as one whole number, 0xRRGGBB, eight bits to a channel: its channels
## read out, put back together, and shaded. A color part way through a blend is
## an `Rgb`, with a float for each channel, and `pack` turns it into a whole number.
import Fraction

HexColor :: [].{

	Rgb : {
		r : F64,
		g : F64,
		b : F64,
	}

	red_of : I64 -> I64
	red_of = |color| color.shr_wrap(16).bitwise_and(255)

	green_of : I64 -> I64
	green_of = |color| color.shr_wrap(8).bitwise_and(255)

	blue_of : I64 -> I64
	blue_of = |color| color.bitwise_and(255)

	## A color as 0xRRGGBB from its three channels.
	pack_rgb : {
		red : I64,
		green : I64,
		blue : I64,
	} -> I64
	pack_rgb = |{ red, green, blue }| {
		red_bits = red.shl_wrap(16)
		green_bits = green.shl_wrap(8)
		red_bits.bitwise_or(green_bits).bitwise_or(blue)
	}

	## A color with each channel scaled by `factor`, as `shade_channel` scales it.
	shade_color : I64, F64 -> I64
	shade_color = |color, factor|
		pack_rgb({
			red: shade_channel(red_of(color), factor),
			green: shade_channel(green_of(color), factor),
			blue: shade_channel(blue_of(color), factor),
		})

	## A colour channel rounded to a whole value, half up. The channel stays a
	## float, because a blend reads it again, and F64's builtins round only into
	## an integer type.
	whole_channel : F64 -> F64
	whole_channel = |channel| {
		rounded = channel.round_to_i64_try() ?? crash "HexColor.whole_channel: a channel is a finite number"
		rounded.to_f64()
	}

	## The colour `fraction` of the way from `from` to `to`, each channel
	## rounded to a whole value.
	color_between : {
		from : HexColor.Rgb,
		to : HexColor.Rgb,
		fraction : Fraction,
	} -> HexColor.Rgb
	color_between = |{ from, to, fraction }| {
		share = fraction.to_f64()
		{
			r: whole_channel(from.r + (to.r - from.r) * share),
			g: whole_channel(from.g + (to.g - from.g) * share),
			b: whole_channel(from.b + (to.b - from.b) * share),
		}
	}

	## A colour as 0xRRGGBB.
	pack : HexColor.Rgb -> I64
	pack = |c|
		pack_rgb({
			red: c.r.to_i64_wrap(),
			green: c.g.to_i64_wrap(),
			blue: c.b.to_i64_wrap(),
		})
}

## One channel scaled by `factor`, rounded, and held at 255 at most.
shade_channel : I64, F64 -> I64
shade_channel = |channel, factor| {
	scaled =
		(channel.to_f64() * factor).round_to_i64_try()
			?? crash "HexColor.shade_channel: a shaded channel is a finite number"
	if scaled > 255 {
		255
	} else {
		scaled
	}
}

sample_color : I64
sample_color = 0x804020

expect HexColor.red_of(sample_color) == 128
expect HexColor.green_of(sample_color) == 64
expect HexColor.blue_of(sample_color) == 32
expect HexColor.pack_rgb({
	red: 128,
	green: 64,
	blue: 32,
}) == sample_color
expect HexColor.red_of(0xFFFFFF) == 255
expect HexColor.green_of(0xFFFFFF) == 255
expect HexColor.blue_of(0xFFFFFF) == 255
expect HexColor.red_of(0) == 0
expect HexColor.pack_rgb({
	red: 0,
	green: 0,
	blue: 0,
}) == 0
expect HexColor.pack_rgb({
	red: 255,
	green: 255,
	blue: 255,
}) == 0xFFFFFF

expect shade_channel(128, 0.6) == 77
expect shade_channel(64, 0.6) == 38
expect shade_channel(32, 0.6) == 19
expect shade_channel(250, 1.25) == 255
expect shade_channel(255, 1.0) == 255
expect shade_channel(255, 2.0) == 255
expect shade_channel(0, 1.25) == 0
expect HexColor.shade_color(sample_color, 0.6) == 0x4D2613

expect
	[
		(0.0, 0.0),
		(0.25, 0.0),
		(0.5, 1.0),
		(1.5, 2.0),
		(2.5, 3.0),
		(49.5, 50.0),
		(127.5, 128.0),
		(254.5, 255.0),
		(255.0, 255.0),
	].all(|(channel, want)| HexColor.whole_channel(channel) == want)

blend_start : HexColor.Rgb
blend_start = {
	r: 142.0,
	g: 202.0,
	b: 230.0,
}

blend_end : HexColor.Rgb
blend_end = {
	r: 36.0,
	g: 58.0,
	b: 94.0,
}

expect HexColor.pack(blend_start) == 0x8ECAE6
expect HexColor.pack(blend_end) == 0x243A5E

expect
	HexColor.color_between({
		from: blend_start,
		to: blend_end,
		fraction: Fraction.zero,
	})
		== blend_start

expect
	HexColor.color_between({
		from: blend_start,
		to: blend_end,
		fraction: Fraction.whole,
	})
		== blend_end

expect
	HexColor.color_between({
		from: blend_start,
		to: blend_end,
		fraction: Fraction.of(0.5),
	})
		== {
			r: 89.0,
			g: 130.0,
			b: 162.0,
		}
