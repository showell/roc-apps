## A color as one whole number, 0xRRGGBB, eight bits to a channel: its channels
## read out, put back together, and shaded.
HexColor :: [].{

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
