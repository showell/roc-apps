## An opaque color, an `RgbColor`, shaded or blended toward another, channel by
## channel.
import Fraction
import lib.RgbColor

ColorShade :: [].{

	## A color with each channel scaled by `factor`, as `shade_channel` scales it.
	shade_color : RgbColor, F64 -> RgbColor
	shade_color = |color, factor|
		RgbColor.from_channels({
			red: shade_channel(color.red(), factor),
			green: shade_channel(color.green(), factor),
			blue: shade_channel(color.blue(), factor),
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
		RgbColor.from_channels({
			red: blend(RgbColor.red),
			green: blend(RgbColor.green),
			blue: blend(RgbColor.blue),
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
	blended.round_to_i64_try() ?? crash "ColorShade.channel_between: a blended channel is a finite number"
}

## One channel scaled by `factor`, rounded, and held at 255 at most.
shade_channel : I64, F64 -> I64
shade_channel = |channel, factor| {
	scaled =
		(channel.to_f64() * factor).round_to_i64_try()
			?? crash "ColorShade.shade_channel: a shaded channel is a finite number"
	if scaled > 255 {
		255
	} else {
		scaled
	}
}

sample_color : RgbColor
sample_color = RgbColor.of(0x804020)

expect shade_channel(128, 0.6) == 77
expect shade_channel(64, 0.6) == 38
expect shade_channel(32, 0.6) == 19
expect shade_channel(250, 1.25) == 255
expect shade_channel(255, 1.0) == 255
expect shade_channel(255, 2.0) == 255
expect shade_channel(0, 1.25) == 0
expect ColorShade.shade_color(sample_color, 0.6) == RgbColor.of(0x4D2613)

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
	ColorShade.color_between({
		from: blend_start,
		to: blend_end,
		fraction: Fraction.zero,
	})
		== blend_start

expect
	ColorShade.color_between({
		from: blend_start,
		to: blend_end,
		fraction: Fraction.whole,
	})
		== blend_end

expect
	ColorShade.color_between({
		from: blend_start,
		to: blend_end,
		fraction: Fraction.of(0.5),
	})
		== RgbColor.of(0x5982A2)
