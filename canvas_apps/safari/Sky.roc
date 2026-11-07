## The sky through the ride: it darkens toward dusk as the sun sinks, and the
## horizon warms red while the sun is near it.
import Pixels
import Clock
import Fraction
import HexColor
import Sun
import lib.RgbColor

Sky :: [].{

	## The sky's two colors in a frame: at the top of the frame, and at the
	## horizon.
	Colors : { top : RgbColor, horizon : RgbColor }

	## How far toward dusk the sky is when the sun has just set: a little over
	## half, so the sky goes on darkening after the sun has gone.
	dusk_at_set : Fraction
	dusk_at_set = Fraction.of(0.6)

	## How far toward dusk the sky is at `clock`, from 0 (day) to 1 (dusk).
	dusk_at : Clock -> Fraction
	dusk_at = |clock| {
		height = Sun.height(clock)
		if height >= Sun.height_when_set {
			dusk_while_up(height)
		} else {
			dusk_after_set(height)
		}
	}

	## How warm the horizon is at `clock`: most while the sun touches it, none
	## once the sun is `warmth_reach` above or below.
	sunset_warmth : Clock -> Fraction
	sunset_warmth = |clock| Fraction.clamp(Sun.height(clock).abs().portion(warmth_reach)).less()

	## The sky's two colors at `clock`.
	colors_at : Clock -> Sky.Colors
	colors_at = |clock| { top: sky_top_color(clock), horizon: sky_horizon_color(clock) }
}

## How far above or below the horizon the sun warms it. Once the sun is
## further away than this, the horizon has the sky's own color.
warmth_reach : Pixels
warmth_reach = Pixels.of(110.0)

day_sky : RgbColor
day_sky = RgbColor.of(0x8ECAE6)

dusk_sky : RgbColor
dusk_sky = RgbColor.of(0x243A5E)

sunset_red : RgbColor
sunset_red = RgbColor.of(0xDE5834)

## How far the horizon goes toward sunset red at its warmest, with the sun on
## it: most of the way, so a little of the sky's own color still shows.
horizon_warmth_at_most : Fraction
horizon_warmth_at_most = Fraction.of(0.85)

## The sky's color at the top of the frame.
sky_top_color : Clock -> RgbColor
sky_top_color = |clock| HexColor.color_between({
	from: day_sky,
	to: dusk_sky,
	fraction: Sky.dusk_at(clock),
})

## The sky's color at the horizon: the sky warmed toward sunset red.
sky_horizon_color : Clock -> RgbColor
sky_horizon_color = |clock| HexColor.color_between({
	from: sky_top_color(clock),
	to: sunset_red,
	fraction: Sky.sunset_warmth(clock).times(horizon_warmth_at_most),
})

## How far toward dusk the sky is while the sun, `height` pixels up, is
## still above the line where it has fully set.
dusk_while_up : Pixels -> Fraction
dusk_while_up = |height| {
	whole_fall = Sun.height_at_start.minus(Sun.height_when_set)
	set_so_far = Fraction.of(Sun.height_at_start.minus(height).portion(whole_fall))
	Sky.dusk_at_set.times(set_so_far).times(set_so_far)
}

## How far toward dusk the sky is once the sun has fully set, darkening on
## to full dusk as it sinks a further radius.
dusk_after_set : Pixels -> Fraction
dusk_after_set = |height| {
	sunk_past_set = Sun.height_when_set.minus(height).portion(Sun.radius)
	Fraction.clamp(Sky.dusk_at_set.to_f64() + sunk_past_set * Sky.dusk_at_set.less().to_f64())
}

# The sky is at dusk_at_set as the sun fully sets, and darker a step later.
expect Sky.dusk_at(Sun.fully_set_at.previous()) < Sky.dusk_at_set
expect Sky.dusk_at(Sun.fully_set_at) == Sky.dusk_at_set
expect Sky.dusk_at_set < Sky.dusk_at(Sun.fully_set_at.next())
expect Sky.dusk_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.sunset_warmth(Clock.at_step(0)).to_f64() == 0.0
expect Sky.dusk_at(Clock.at_step(6000)).to_f64() == 1.0
expect Sky.sunset_warmth(Clock.at_step(6000)).to_f64() == 0.0

# The sky and the horizon at each thousandth step of the ride.
expect
	[
		(0, RgbColor.of(0x8ECAE6), RgbColor.of(0x8ECAE6)),
		(1000, RgbColor.of(0x8BC6E2), RgbColor.of(0x8BC6E2)),
		(2000, RgbColor.of(0x83BBD7), RgbColor.of(0x83BBD7)),
		(3000, RgbColor.of(0x74A7C5), RgbColor.of(0x9D898D)),
		(4000, RgbColor.of(0x618CAC), RgbColor.of(0xCA6047)),
		(5000, RgbColor.of(0x3F5F81), RgbColor.of(0x7A5C65)),
		(6000, RgbColor.of(0x243A5E), RgbColor.of(0x243A5E)),
	].all(|(step, top, horizon)| Sky.colors_at(Clock.at_step(step)) == { top, horizon })
