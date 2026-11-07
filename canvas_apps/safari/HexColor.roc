## An opaque color, an `RgbColor`: its channels read out, put back together,
## shaded, and blended.
import Fraction
import lib.RgbColor

HexColor :: [].{

	red_of : RgbColor -> I64
	red_of = |color| color.to_i64().shr_wrap(16).bitwise_and(255)

	green_of : RgbColor -> I64
	green_of = |color| color.to_i64().shr_wrap(8).bitwise_and(255)

	blue_of : RgbColor -> I64
	blue_of = |color| color.to_i64().bitwise_and(255)

	## A color from its three channels.
	pack_rgb : {
		red : I64,
		green : I64,
		blue : I64,
	} -> RgbColor
	pack_rgb = |{ red, green, blue }| {
		red_bits = red.shl_wrap(16)
		green_bits = green.shl_wrap(8)
		RgbColor.of(red_bits.bitwise_or(green_bits).bitwise_or(blue))
	}

	## A color with each channel scaled by `factor`, as `shade_channel` scales it.
	shade_color : RgbColor, F64 -> RgbColor
	shade_color = |color, factor|
		pack_rgb({
			red: shade_channel(red_of(color), factor),
			green: shade_channel(green_of(color), factor),
			blue: shade_channel(blue_of(color), factor),
		})

	## The color `fraction` of the way from `from` to `to`, each channel
	## rounded to a whole value as `channel_between` rounds it.
	color_between : {
		from : RgbColor,
		to : RgbColor,
		fraction : Fraction,
	} -> RgbColor
	color_between = |{ from, to, fraction }| {
		blend = |channel_of|
			channel_between({
				from: channel_of(from),
				to: channel_of(to),
				fraction,
			})
		pack_rgb({
			red: blend(red_of),
			green: blend(green_of),
			blue: blend(blue_of),
		})
	}
}

## One channel `fraction` of the way from `from` to `to`, rounded to a whole
## value, half up.
channel_between : {
	from : I64,
	to : I64,
	fraction : Fraction,
} -> I64
channel_between = |{ from, to, fraction }| {
	start = from.to_f64()
	blended = start + (to.to_f64() - start) * fraction.to_f64()
	blended.round_to_i64_try() ?? crash "HexColor.channel_between: a blended channel is a finite number"
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

sample_color : RgbColor
sample_color = RgbColor.of(0x804020)

expect HexColor.red_of(sample_color) == 128
expect HexColor.green_of(sample_color) == 64
expect HexColor.blue_of(sample_color) == 32
expect HexColor.pack_rgb({
	red: 128,
	green: 64,
	blue: 32,
}) == sample_color
expect HexColor.red_of(RgbColor.of(0xFFFFFF)) == 255
expect HexColor.green_of(RgbColor.of(0xFFFFFF)) == 255
expect HexColor.blue_of(RgbColor.of(0xFFFFFF)) == 255
expect HexColor.red_of(RgbColor.of(0)) == 0
expect HexColor.pack_rgb({
	red: 0,
	green: 0,
	blue: 0,
}) == RgbColor.of(0)
expect HexColor.pack_rgb({
	red: 255,
	green: 255,
	blue: 255,
}) == RgbColor.of(0xFFFFFF)

expect shade_channel(128, 0.6) == 77
expect shade_channel(64, 0.6) == 38
expect shade_channel(32, 0.6) == 19
expect shade_channel(250, 1.25) == 255
expect shade_channel(255, 1.0) == 255
expect shade_channel(255, 2.0) == 255
expect shade_channel(0, 1.25) == 0
expect HexColor.shade_color(sample_color, 0.6) == RgbColor.of(0x4D2613)

# A channel part way rounds half up, and lands on each end exactly.
expect
	[
		((0, 1, 0.0), 0),
		((0, 1, 0.25), 0),
		((0, 1, 0.5), 1),
		((0, 3, 0.5), 2),
		((0, 5, 0.5), 3),
		((0, 99, 0.5), 50),
		((0, 255, 0.5), 128),
		((0, 255, 1.0), 255),
		((255, 0, 0.5), 128),
		((255, 255, 0.5), 255),
	].all(
		|((from, to, share), want)| {
			fraction = Fraction.of(share)
			channel_between({ from, to, fraction }) == want
		},
	)

blend_start : RgbColor
blend_start = RgbColor.of(0x8ECAE6)

blend_end : RgbColor
blend_end = RgbColor.of(0x243A5E)

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
		== RgbColor.of(0x5982A2)
