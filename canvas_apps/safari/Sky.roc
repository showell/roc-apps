## The sky through the ride: it darkens toward dusk as the sun sinks, and the
## horizon warms red while the sun is near it.
import Clock
import FarHeight
import Fraction
import HexColor
import Screen
import Sun
import lib.Brush
import lib.RgbColor
import lib.Shapes

Sky :: [].{

	## The sky's two colors in a frame: at the top of the frame, and at the
	## horizon.
	Colors : { top : RgbColor, horizon : RgbColor }

	## How dark the sky is at `clock`, from 0 (day) to 1 (night).
	darkness_at : Clock -> Fraction
	darkness_at = |clock| {
		height = Sun.height_at(clock)
		if height >= Sun.height_when_set {
			darkness_while_up(height)
		} else {
			darkness_after_set(height)
		}
	}

	## How warm the horizon is at `clock`: most while the sun touches it, none
	## once the sun is `warmth_reach` above or below.
	horizon_warmth_at : Clock -> Fraction
	horizon_warmth_at = |clock| {
		from_horizon = Sun.height_at(clock).abs()
		Fraction.clamp(from_horizon.portion(warmth_reach)).less()
	}

	## The sky's two colors at `clock`.
	colors_at : Clock -> Sky.Colors
	colors_at = |clock| { top: sky_top_color(clock), horizon: sky_horizon_color(clock) }

	## How far down to the horizon the sky holds its top colour before it
	## fades to the horizon's.
	sky_top_stop : Fraction
	sky_top_stop = Fraction.of(0.2)

	## The sky in `colors`: a gradient from the top colour down to the
	## horizon's, over the rectangle above the horizon.
	sky_shape : Sky.Colors -> Shapes.Shape
	sky_shape = |colors|
		Screen.above_horizon_rect(
			Linear({
				stops: {
					start_color: Brush.opaque(colors.top),
					end_color: Brush.opaque(colors.horizon),
					start_offset: sky_top_stop.to_f64(),
					end_offset: 1.0,
				},
				start_point: { x: 0.0, y: 0.0 },
				end_point: { x: 0.0, y: Screen.horizon_y.to_f64() },
			}),
		)
}

## How dark the sky is when the sun has just set: a little over half, so
## the sky goes on darkening after the sun has gone.
darkness_at_set : Fraction
darkness_at_set = Fraction.of(0.6)

## How far above or below the horizon the sun warms it. Once the sun is
## further away than this, the horizon has the sky's own color.
warmth_reach : FarHeight
warmth_reach = FarHeight.of(110.0)

day_sky : RgbColor
day_sky = RgbColor.of(0x8ECAE6)

night_sky : RgbColor
night_sky = RgbColor.of(0x243A5E)

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
	to: night_sky,
	fraction: Sky.darkness_at(clock),
})

## The sky's color at the horizon: the sky warmed toward sunset red.
sky_horizon_color : Clock -> RgbColor
sky_horizon_color = |clock| HexColor.color_between({
	from: sky_top_color(clock),
	to: sunset_red,
	fraction: Sky.horizon_warmth_at(clock).times(horizon_warmth_at_most),
})

## How dark the sky is while the sun, `height` up, is
## still above the line where it has fully set.
darkness_while_up : FarHeight -> Fraction
darkness_while_up = |height| {
	whole_fall = Sun.height_at_start.minus(Sun.height_when_set)
	set_so_far = Fraction.of(Sun.height_at_start.minus(height).portion(whole_fall))
	darkness_at_set.times(set_so_far).times(set_so_far)
}

## How dark the sky is once the sun has fully set, darkening on to full
## night as it sinks a further radius.
darkness_after_set : FarHeight -> Fraction
darkness_after_set = |height| {
	sunk_past_set = Sun.height_when_set.minus(height).portion(Sun.radius_as_height)
	Fraction.clamp(darkness_at_set.to_f64() + sunk_past_set * darkness_at_set.less().to_f64())
}

# The sky is at darkness_at_set as the sun fully sets, and darker a step later.
expect Sky.darkness_at(Sun.fully_set_at.previous()) < darkness_at_set
expect Sky.darkness_at(Sun.fully_set_at) == darkness_at_set
expect darkness_at_set < Sky.darkness_at(Sun.fully_set_at.next())
expect Sky.darkness_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.horizon_warmth_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.darkness_at(Clock.at_step(6000)).to_f64() == 1.0
expect Sky.horizon_warmth_at(Clock.at_step(6000)).to_f64() == 0.0

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
