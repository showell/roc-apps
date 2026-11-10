## The sky through the ride: it darkens toward dusk as the sun sinks, and the
## horizon warms red while the sun is near it. Its colors are worked out each
## frame from the clock.
import Clock
import FarHeight
import FarRise
import lib.Fraction
import lib.ColorShade
import Screen
import SunPath
import lib.Brush
import lib.Pixels
import lib.RgbColor
import lib.Shapes

Sky :: [].{

	## The sky's two colors in a frame: at the top of the frame, and at the
	## horizon.
	Colors : { top : RgbColor, horizon : RgbColor }

	## How dark the sky is at `clock`, from 0 (day) to 1 (night).
	darkness_at : Clock -> Fraction
	darkness_at = |clock| {
		height = SunPath.height_at(clock)
		if height >= SunPath.height_when_set {
			darkness_while_up(height)
		} else {
			darkness_after_set(height)
		}
	}

	## How warm the horizon is at `clock`: most while the sun touches it, none
	## once the sun is `warmth_reach` above or below.
	horizon_warmth_at : Clock -> Fraction
	horizon_warmth_at = |clock| {
		from_horizon = SunPath.height_at(clock).minus(FarHeight.zero).abs()
		Fraction.clamp(from_horizon.ratio_to(warmth_reach)).complement()
	}

	## `color` under a sky `darkness` dark: itself by day, and losing up to
	## `night_dim` of its light as night falls. Everything the sky lights,
	## from the rock and the grass to the truck, is dimmed here.
	color_at_darkness : RgbColor, Fraction -> RgbColor
	color_at_darkness = |color, darkness|
		ColorShade.shade_color(color, Darkened(night_dim.times(darkness)))

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
					start_color: Brush.opaque_rgba(colors.top),
					end_color: Brush.opaque_rgba(colors.horizon),
					start_offset: sky_top_stop.to_f64(),
					end_offset: 1.0,
				},
				start_point: { x: Pixels.zero, y: Pixels.zero },
				end_point: { x: Pixels.zero, y: Screen.horizon_y },
			}),
		)
}

## How dark the sky is when the sun has just set: a little over half, so
## the sky goes on darkening after the sun has gone.
darkness_at_set : Fraction
darkness_at_set = Fraction.of(0.6)

## How far above or below the horizon the sun warms it. Once the sun is
## further away than this, the horizon has the sky's own color.
warmth_reach : FarRise
warmth_reach = FarRise.of(110.0)

## How much of its light a thing the sky lights loses at full night: half.
## Night then reads as night, and the trees, the truck and the rails stay
## dark shapes on darker ground, under a sky lighter than either.
night_dim : Fraction
night_dim = Fraction.of(0.5)

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
sky_top_color = |clock| ColorShade.color_between({
	from: day_sky,
	to: night_sky,
	fraction: Sky.darkness_at(clock),
})

## The sky's color at the horizon: the sky warmed toward sunset red.
sky_horizon_color : Clock -> RgbColor
sky_horizon_color = |clock| ColorShade.color_between({
	from: sky_top_color(clock),
	to: sunset_red,
	fraction: Sky.horizon_warmth_at(clock).times(horizon_warmth_at_most),
})

## How dark the sky is while the sun, `height` up, is
## still above the line where it has fully set.
darkness_while_up : FarHeight -> Fraction
darkness_while_up = |height| {
	whole_fall = SunPath.height_at_start.minus(SunPath.height_when_set)
	set_so_far = Fraction.of(SunPath.height_at_start.minus(height).ratio_to(whole_fall))
	darkness_at_set.times(set_so_far).times(set_so_far)
}

## How far below fully set the sun sinks before the sky is full night.
night_depth : FarRise
night_depth = FarRise.of(46.0)

## How dark the sky is once the sun has fully set, darkening on to full
## night as it sinks a further `night_depth`.
darkness_after_set : FarHeight -> Fraction
darkness_after_set = |height| {
	sunk_past_set = SunPath.height_when_set.minus(height).ratio_to(night_depth)
	Fraction.clamp(darkness_at_set.to_f64() + sunk_past_set * darkness_at_set.complement().to_f64())
}

# The sky is at least at darkness_at_set as the sun fully sets, and darker a
# step later. A step earlier is in gates/expects/RideExpects.roc, which counts
# steps.
expect Sky.darkness_at(SunPath.fully_set_at) >= darkness_at_set
expect darkness_at_set < Sky.darkness_at(SunPath.fully_set_at.next())
expect Sky.darkness_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.horizon_warmth_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.darkness_at(Clock.at_step(6000)).to_f64() == 1.0
expect Sky.horizon_warmth_at(Clock.at_step(6000)).to_f64() == 0.0

# A color is itself by day, half itself at full night, and between at dusk.
expect
	[
		(0.0, RgbColor.of(0x4A8F43)),
		(0.5, RgbColor.of(0x386B32)),
		(1.0, RgbColor.of(0x254822)),
	].all(
		|(darkness, want)| Sky.color_at_darkness(
			RgbColor.of(0x4A8F43),
			Fraction.of(darkness),
		) == want,
	)

# The sky and the horizon at each thousandth step of the ride.
expect
	[
		(0, RgbColor.of(0x8ECAE6), RgbColor.of(0x8ECAE6)),
		(1000, RgbColor.of(0x8DC8E5), RgbColor.of(0x8DC8E5)),
		(2000, RgbColor.of(0x86BFDB), RgbColor.of(0x86BFDB)),
		(3000, RgbColor.of(0x73A6C4), RgbColor.of(0x9A898F)),
		(4000, RgbColor.of(0x517697), RgbColor.of(0x9C6662)),
		(5000, RgbColor.of(0x243A5E), RgbColor.of(0x243A5E)),
		(6000, RgbColor.of(0x243A5E), RgbColor.of(0x243A5E)),
	].all(|(step, top, horizon)| Sky.colors_at(Clock.at_step(step)) == { top, horizon })
