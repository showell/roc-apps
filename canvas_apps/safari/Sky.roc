## The sky through the ride: it darkens toward dusk as the sun sinks, and the
## horizon warms red while the sun is near it.
import Pixels
import Clock
import Fraction
import HexColor
import Sun

Sky :: [].{

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

	day_sky : HexColor.Rgb
	day_sky = {
		r: 142.0,
		g: 202.0,
		b: 230.0,
	}

	dusk_sky : HexColor.Rgb
	dusk_sky = {
		r: 36.0,
		g: 58.0,
		b: 94.0,
	}

	sunset_red : HexColor.Rgb
	sunset_red = {
		r: 222.0,
		g: 88.0,
		b: 52.0,
	}

	sunset_glow : Fraction
	sunset_glow = Fraction.of(0.85)

	## The sky's colour at the top of the frame.
	sky_top_color : Clock -> HexColor.Rgb
	sky_top_color = |clock| HexColor.color_between({
		from: day_sky,
		to: dusk_sky,
		fraction: dusk_at(clock),
	})

	## The sky's colour at the horizon: the sky warmed toward sunset red.
	sky_horizon_color : Clock -> HexColor.Rgb
	sky_horizon_color = |clock| HexColor.color_between({
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

expect Sky.warmth_falloff_px.to_f64() == 110.0
expect Sky.dusk_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.sunset_warmth(Clock.at_step(0)).to_f64() == 0.0
expect Sky.dusk_at(Clock.at_step(6000)).to_f64() == 1.0
expect Sky.sunset_warmth(Clock.at_step(6000)).to_f64() == 0.0
expect Sky.sunset_glow.to_f64() == 0.85

# The sky and the horizon at each thousandth step of the ride.
expect HexColor.pack(Sky.sky_top_color(Clock.at_step(0))) == 0x8ECAE6
expect HexColor.pack(Sky.sky_top_color(Clock.at_step(1000))) == 0x8BC6E2
expect HexColor.pack(Sky.sky_top_color(Clock.at_step(2000))) == 0x83BBD8
expect HexColor.pack(Sky.sky_top_color(Clock.at_step(3000))) == 0x75A8C6
expect HexColor.pack(Sky.sky_top_color(Clock.at_step(4000))) == 0x618DAC
expect HexColor.pack(Sky.sky_top_color(Clock.at_step(5000))) == 0x406082
expect HexColor.pack(Sky.sky_top_color(Clock.at_step(6000))) == 0x243A5E
expect HexColor.pack(Sky.sky_horizon_color(Clock.at_step(0))) == 0x8ECAE6
expect HexColor.pack(Sky.sky_horizon_color(Clock.at_step(1000))) == 0x8BC6E2
expect HexColor.pack(Sky.sky_horizon_color(Clock.at_step(2000))) == 0x83BBD8
expect HexColor.pack(Sky.sky_horizon_color(Clock.at_step(3000))) == 0x9D898E
expect HexColor.pack(Sky.sky_horizon_color(Clock.at_step(4000))) == 0xCA6047
expect HexColor.pack(Sky.sky_horizon_color(Clock.at_step(5000))) == 0x7A5D65
expect HexColor.pack(Sky.sky_horizon_color(Clock.at_step(6000))) == 0x243A5E
expect HexColor.pack(Sky.day_sky) == 0x8ECAE6
expect HexColor.pack(Sky.dusk_sky) == 0x243A5E
expect HexColor.pack(Sky.sunset_red) == 0xDE5834
