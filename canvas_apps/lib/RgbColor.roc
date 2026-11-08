## RgbColor is an opaque colour as one whole number, 0xRRGGBB: eight bits each
## of red, green and blue, red highest. A flat fill's colour is one of these, and
## `Brush.opaque_rgba` is what turns it into a brush colour.
##
## A colour with alpha is an `ArgbColor`, a different type, so neither can be
## passed where the other belongs.

RgbColor :: I64.{

	## Crashes outside 0..0xFFFFFF.
	of : I64 -> RgbColor
	of = |rgb|
		if rgb < 0 or rgb > 0xFFFFFF {
			crash "RgbColor.of: a colour outside 0 to 0xFFFFFF"
		} else {
			RgbColor.(rgb)
		}

	## A colour from its three channels. Crashes, naming the channel, on one
	## outside 0..255, which would spill into its neighbour.
	from_channels : {
		red : I64,
		green : I64,
		blue : I64,
	} -> RgbColor
	from_channels = |channels|
		if !is_channel(channels.red) {
			crash "RgbColor.from_channels: red outside 0 to 255"
		} else if !is_channel(channels.green) {
			crash "RgbColor.from_channels: green outside 0 to 255"
		} else if !is_channel(channels.blue) {
			crash "RgbColor.from_channels: blue outside 0 to 255"
		} else {
			red_bits = channels.red.shl_wrap(16)
			green_bits = channels.green.shl_wrap(8)
			RgbColor.(red_bits.bitwise_or(green_bits).bitwise_or(channels.blue))
		}

	to_i64 : RgbColor -> I64
	to_i64 = |RgbColor.(rgb)| rgb

	## The red channel, 0..255.
	red : RgbColor -> I64
	red = |RgbColor.(rgb)| rgb.shr_wrap(16).bitwise_and(255)

	## The green channel, 0..255.
	green : RgbColor -> I64
	green = |RgbColor.(rgb)| rgb.shr_wrap(8).bitwise_and(255)

	## The blue channel, 0..255.
	blue : RgbColor -> I64
	blue = |RgbColor.(rgb)| rgb.bitwise_and(255)

	is_eq : _
}

## Whether a number fits in one eight-bit channel, `from_channels`' check.
is_channel : I64 -> Bool
is_channel = |value| value >= 0 and value <= 255

expect RgbColor.of(0xFFE9A8).to_i64() == 0xFFE9A8
expect RgbColor.of(0).to_i64() == 0
expect RgbColor.of(0xFFFFFF).to_i64() == 0xFFFFFF
expect RgbColor.of(0x8ECAE6) == RgbColor.of(0x8ECAE6)
expect RgbColor.of(0x8ECAE6) != RgbColor.of(0x8ECAE7)

sample_color : RgbColor
sample_color = RgbColor.of(0x804020)

expect sample_color.red() == 128
expect sample_color.green() == 64
expect sample_color.blue() == 32
expect [RgbColor.of(0xFFFFFF).red(), RgbColor.of(0xFFFFFF).green(), RgbColor.of(0xFFFFFF).blue()].all(|channel| channel == 255)
expect [RgbColor.of(0).red(), RgbColor.of(0).green(), RgbColor.of(0).blue()].all(|channel| channel == 0)

# Each channel lands in its own byte, at either end and between.
expect
	[
		({ red: 128, green: 64, blue: 32 }, 0x804020),
		({ red: 0, green: 0, blue: 0 }, 0),
		({ red: 255, green: 255, blue: 255 }, 0xFFFFFF),
		({ red: 0, green: 0, blue: 255 }, 0x0000FF),
		({ red: 0, green: 255, blue: 0 }, 0x00FF00),
	].all(|(channels, rgb)| RgbColor.from_channels(channels) == RgbColor.of(rgb))

# A channel fits from 0 to 255, and not just past either end.
expect [0, 1, 254, 255].all(is_channel)
expect [-1, 256, 0x10000].all(|value| !is_channel(value))
