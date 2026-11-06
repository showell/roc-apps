## The sky through the ride: it darkens toward dusk as the sun sinks, and the
## horizon warms red while the sun is near it.
import Pixels
import Clock
import Fraction
import Sun

Sky :: [].{
	Rgb : {
		r : F64,
		g : F64,
		b : F64,
	}

	warmth_falloff_px : Pixels
	warmth_falloff_px = Pixels.of(110.0)

	## How far toward dusk the sky is when the sun has just set.
	dusk_at_set : Fraction
	dusk_at_set = Fraction.of(
		Sun.start_px.minus(Sun.fully_set_px).times(0.5).ratio_to(Sun.start_px),
	)

	## How far toward dusk the sky is at `clock`, from 0 (day) to 1 (dusk).
	dusk_at : Clock -> Fraction
	dusk_at = |clock| {
		height = Sun.height_px(clock)
		if height >= Sun.fully_set_px {
			dusk_while_up(height)
		} else {
			dusk_after_set(height)
		}
	}

	## How warm the horizon is at `clock`: most while the sun touches it, none
	## once the sun is `warmth_falloff_px` above or below.
	sunset_warmth : Clock -> Fraction
	sunset_warmth = |clock| Fraction.clamp(
		1.0 - Sun.height_px(clock).abs().ratio_to(warmth_falloff_px),
	)

	day_sky : Sky.Rgb
	day_sky = {
		r: 142.0,
		g: 202.0,
		b: 230.0,
	}

	dusk_sky : Sky.Rgb
	dusk_sky = {
		r: 36.0,
		g: 58.0,
		b: 94.0,
	}

	sunset_red : Sky.Rgb
	sunset_red = {
		r: 222.0,
		g: 88.0,
		b: 52.0,
	}

	sunset_glow : Fraction
	sunset_glow = Fraction.of(0.85)

	## A colour channel rounded to a whole value, half up. The channel stays a
	## float, because a blend reads it again, and F64's builtins round only into
	## an integer type.
	whole_channel : F64 -> F64
	whole_channel = |channel| {
		rounded = channel.round_to_i64_try() ?? crash "Sky.whole_channel: a channel is a finite number"
		rounded.to_f64()
	}

	## The colour `fraction` of the way from `from` to `to`, each channel
	## rounded to a whole value.
	color_between : {
		from : Sky.Rgb,
		to : Sky.Rgb,
		fraction : Fraction,
	} -> Sky.Rgb
	color_between = |{ from, to, fraction }| {
		share = fraction.to_f64()
		{
			r: whole_channel(from.r + (to.r - from.r) * share),
			g: whole_channel(from.g + (to.g - from.g) * share),
			b: whole_channel(from.b + (to.b - from.b) * share),
		}
	}

	## A colour as 0xRRGGBB.
	pack : Sky.Rgb -> I64
	pack = |c| {
		red_bits = c.r.to_i64_wrap().shl_wrap(16)
		green_bits = c.g.to_i64_wrap().shl_wrap(8)
		red_bits.bitwise_or(green_bits).bitwise_or(c.b.to_i64_wrap())
	}

	## The sky's colour at the top of the frame.
	sky_top_color : Clock -> Sky.Rgb
	sky_top_color = |clock| color_between({
		from: day_sky,
		to: dusk_sky,
		fraction: dusk_at(clock),
	})

	## The sky's colour at the horizon: the sky warmed toward sunset red.
	sky_horizon_color : Clock -> Sky.Rgb
	sky_horizon_color = |clock| color_between({
		from: sky_top_color(clock),
		to: sunset_red,
		fraction: sunset_warmth(clock).times(sunset_glow),
	})

}

## How far toward dusk the sky is while the sun, `height` pixels up, is
## still above the line where it has fully set.
dusk_while_up : Pixels -> Fraction
dusk_while_up = |height| {
	whole_fall = Sun.start_px.minus(Sun.fully_set_px)
	set_so_far = Fraction.of(Sun.start_px.minus(height).ratio_to(whole_fall))
	Sky.dusk_at_set.times(set_so_far).times(set_so_far)
}

## How far toward dusk the sky is once the sun has fully set, darkening on
## to full dusk as it sinks a further radius.
dusk_after_set : Pixels -> Fraction
dusk_after_set = |height| {
	sunk_past_set = Sun.fully_set_px.minus(height).ratio_to(Sun.radius_px)
	Fraction.clamp(Sky.dusk_at_set.to_f64() + sunk_past_set * Sky.dusk_at_set.complement().to_f64())
}

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
	].all(|(channel, want)| Sky.whole_channel(channel) == want)

expect Sky.warmth_falloff_px.to_f64() == 110.0
expect Sky.dusk_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.sunset_warmth(Clock.at_step(0)).to_f64() == 0.0
expect Sky.dusk_at(Clock.at_step(6000)).to_f64() == 1.0
expect Sky.sunset_warmth(Clock.at_step(6000)).to_f64() == 0.0
expect Sky.sunset_glow.to_f64() == 0.85

# The sky and the horizon at each thousandth step of the ride.
expect Sky.pack(Sky.sky_top_color(Clock.at_step(0))) == 0x8ECAE6
expect Sky.pack(Sky.sky_top_color(Clock.at_step(1000))) == 0x8BC6E2
expect Sky.pack(Sky.sky_top_color(Clock.at_step(2000))) == 0x83BBD8
expect Sky.pack(Sky.sky_top_color(Clock.at_step(3000))) == 0x75A8C6
expect Sky.pack(Sky.sky_top_color(Clock.at_step(4000))) == 0x618DAC
expect Sky.pack(Sky.sky_top_color(Clock.at_step(5000))) == 0x406082
expect Sky.pack(Sky.sky_top_color(Clock.at_step(6000))) == 0x243A5E
expect Sky.pack(Sky.sky_horizon_color(Clock.at_step(0))) == 0x8ECAE6
expect Sky.pack(Sky.sky_horizon_color(Clock.at_step(1000))) == 0x8BC6E2
expect Sky.pack(Sky.sky_horizon_color(Clock.at_step(2000))) == 0x83BBD8
expect Sky.pack(Sky.sky_horizon_color(Clock.at_step(3000))) == 0x9D898E
expect Sky.pack(Sky.sky_horizon_color(Clock.at_step(4000))) == 0xCA6047
expect Sky.pack(Sky.sky_horizon_color(Clock.at_step(5000))) == 0x7A5D65
expect Sky.pack(Sky.sky_horizon_color(Clock.at_step(6000))) == 0x243A5E
expect Sky.pack(Sky.day_sky) == 0x8ECAE6
expect Sky.pack(Sky.dusk_sky) == 0x243A5E
expect Sky.pack(Sky.sunset_red) == 0xDE5834

expect
	Sky.color_between({
		from: Sky.day_sky,
		to: Sky.dusk_sky,
		fraction: Fraction.zero,
	})
		== {
			r: 142.0,
			g: 202.0,
			b: 230.0,
		}

expect
	Sky.color_between({
		from: Sky.day_sky,
		to: Sky.dusk_sky,
		fraction: Fraction.whole,
	})
		== {
			r: 36.0,
			g: 58.0,
			b: 94.0,
		}

expect
	Sky.color_between({
		from: Sky.day_sky,
		to: Sky.dusk_sky,
		fraction: Fraction.of(0.5),
	})
		== {
			r: 89.0,
			g: 130.0,
			b: 162.0,
		}
