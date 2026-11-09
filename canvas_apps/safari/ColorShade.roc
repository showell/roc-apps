## An opaque color, an `RgbColor`, shaded or blended toward another, channel by
## channel.
import lib.Fraction
import lib.RgbColor

ColorShade :: [].{

	## How a color is shaded: darkened by a fraction of each channel, or
	## lightened by one.
	Shade : [Darkened(Fraction), Lightened(Fraction)]

	## A color with each channel shaded, as `shade_channel` shades it.
	shade_color : RgbColor, ColorShade.Shade -> RgbColor
	shade_color = |color, shade|
		RgbColor.from_channels({
			red: shade_channel(color.red(), shade),
			green: shade_channel(color.green(), shade),
			blue: shade_channel(color.blue(), shade),
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
	from : U8,
	to : U8,
	fraction : Fraction,
} -> U8
channel_between = |{ from, to, fraction }| {
	start = from.to_f64()
	blended = start + (to.to_f64() - start) * fraction.to_f64()
	rounded = blended.round_to_i64_try() ?? crash "ColorShade.channel_between: a blended channel is a finite number"
	# A fraction lies from 0 to 1, so the blend lies between two channels.
	rounded.to_u8_try() ?? crash "ColorShade.channel_between: a blend lies between its two channels"
}

## One channel shaded and rounded. Darkened by `f`, it is scaled by the
## whole less `f`; lightened by `f`, by one and `f`, and held at 255 at most.
shade_channel : U8, ColorShade.Shade -> U8
shade_channel = |channel, shade|
	match shade {
		Darkened(darkening) => {
			scaled =
				(channel.to_f64() * darkening.complement().to_f64()).round_to_i64_try()
					?? crash "ColorShade.shade_channel: a darkened channel is a finite number"
			# The scale lies from 0 to 1, so the channel can only fall.
			scaled.to_u8_try() ?? crash "ColorShade.shade_channel: a darkened channel lies from 0 to its own value"
		}
		Lightened(lightening) => {
			scaled =
				(channel.to_f64() * (1.0 + lightening.to_f64())).round_to_i64_try()
					?? crash "ColorShade.shade_channel: a lightened channel is a finite number"
			if scaled > 255 {
				255
			} else {
				scaled.to_u8_wrap()
			}
		}
	}

sample_color : RgbColor
sample_color = RgbColor.of(0x804020)

expect
	[
		((128, 0.4), 77),
		((64, 0.4), 38),
		((32, 0.4), 19),
		((255, 0.0), 255),
		((0, 0.0), 0),
		((200, 1.0), 0),
		((255, 1.0), 0),
	].all(|((channel, share), want)| shade_channel(channel, Darkened(Fraction.of(share))) == want)

# Lightened by a quarter, 203 rounds to 254, 204 lands on 255, and 205 and past
# are held there.
expect
	[
		((203, 0.25), 254),
		((204, 0.25), 255),
		((205, 0.25), 255),
		((250, 0.25), 255),
		((255, 0.0), 255),
		((0, 1.0), 0),
		((127, 1.0), 254),
		((128, 1.0), 255),
		((255, 1.0), 255),
	].all(|((channel, share), want)| shade_channel(channel, Lightened(Fraction.of(share))) == want)

expect ColorShade.shade_color(sample_color, Darkened(Fraction.of(0.4))) == RgbColor.of(0x4D2613)
expect ColorShade.shade_color(sample_color, Lightened(Fraction.of(0.25))) == RgbColor.of(0xA05028)

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
