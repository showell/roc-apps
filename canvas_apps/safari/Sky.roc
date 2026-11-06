## The sky through the ride: the sun sinks a little with every step, the
## sky darkens toward dusk as it goes, and the horizon warms red while the
## sun is near it. The sun is drawn only while the rider faces it.
import Pixels
import Angle
import Clock
import Fraction
import Lens
import Screen

Sky :: [].{
	Rgb : {
		r : F64,
		g : F64,
		b : F64,
	}

	## Where the sun stands on the screen, and how large it is drawn beside
	## its size at rest. The lens only ever widens, so that is never larger.
	SunPlace : {
		x : Pixels,
		y : Pixels,
		scale : Fraction,
	}

	## The sun in a frame: in view at its place, or out of view, too far to
	## the side of where the rider faces.
	SunSighting : [InView(Sky.SunPlace), OutOfView]

	sun_bearing : Angle.Bearing
	sun_bearing = Angle.Bearing.radians(0.0 - 2.2176)

	sun_radius_px : Pixels
	sun_radius_px = Pixels.of(46.0)

	sun_start_px : Pixels
	sun_start_px = Pixels.of(244.0)

	sun_drop_px_per_step : Pixels
	sun_drop_px_per_step = sun_radius_px.times(2.0).times(0.41616).divided_by(625.0)

	sun_fully_set_px : Pixels
	sun_fully_set_px = sun_radius_px.opposite()

	warmth_falloff_px : Pixels
	warmth_falloff_px = Pixels.of(110.0)

	visible_turn_limit : Angle.Turn
	visible_turn_limit = Angle.Turn.radians(1.4)

	## How high the sun stands above the horizon at `clock`, in pixels at
	## rest; below it once negative.
	sun_height_px : Clock -> Pixels
	sun_height_px = |clock| sun_start_px.minus(sun_drop_px_per_step.times(clock.to_f64()))

	## How far toward dusk the sky is when the sun has just set.
	dusk_at_set : Fraction
	dusk_at_set = Fraction.of(
		sun_start_px.minus(sun_fully_set_px).times(0.5).ratio_to(sun_start_px),
	)

	## How far toward dusk the sky is at `clock`, from 0 (day) to 1 (dusk).
	dusk_at : Clock -> Fraction
	dusk_at = |clock| {
		height = sun_height_px(clock)
		if height >= sun_fully_set_px {
			dusk_while_up(height)
		} else {
			dusk_after_set(height)
		}
	}

	## How warm the horizon is at `clock`: most while the sun touches it, none
	## once the sun is `warmth_falloff_px` above or below.
	sunset_warmth : Clock -> Fraction
	sunset_warmth = |clock| Fraction.clamp(
		(1.0 - sun_height_px(clock).abs().ratio_to(warmth_falloff_px)),
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
			r: whole_channel(from.r + ((to.r - from.r) * share)),
			g: whole_channel(from.g + ((to.g - from.g) * share)),
			b: whole_channel(from.b + ((to.b - from.b) * share)),
		}
	}

	## A colour as 0xRRGGBB.
	pack : Sky.Rgb -> I64
	pack = |c| {
		red_bits = c.r.to_i64_wrap().shl_wrap(16)
		green_bits = c.g.to_i64_wrap().shl_wrap(8)
		red_bits.bitwise_or(green_bits).bitwise_or(c.b.to_i64_wrap())
	}

	## The sky's colour at the top of the frame, as 0xRRGGBB.
	sky_top_color : Clock -> I64
	sky_top_color = |clock| pack(sky_at(clock))

	## The sky's colour at the horizon, as 0xRRGGBB: the sky warmed toward
	## sunset red.
	sky_horizon_color : Clock -> I64
	sky_horizon_color = |clock| pack(
		color_between({
			from: sky_at(clock),
			to: sunset_red,
			fraction: sunset_warmth(clock).times(sunset_glow),
		}),
	)

	## The sun in a frame, for a rider facing `heading`.
	sun_sighting : {
		heading : Angle.Bearing,
		clock : Clock,
		cam_focal : Pixels,
	} -> Sky.SunSighting
	sun_sighting = |{ heading, clock, cam_focal }| {
		turn_from_view = sun_bearing.turn_from(heading)
		if turn_from_view.abs() >= visible_turn_limit {
			OutOfView
		} else {
			InView(sun_place({ turn_from_view, clock, cam_focal }))
		}
	}
}

## How far toward dusk the sky is while the sun, `height` pixels up, is
## still above the line where it has fully set.
dusk_while_up : Pixels -> Fraction
dusk_while_up = |height| {
	whole_fall = Sky.sun_start_px.minus(Sky.sun_fully_set_px)
	set_so_far = Fraction.of(Sky.sun_start_px.minus(height).ratio_to(whole_fall))
	Sky.dusk_at_set.times(set_so_far).times(set_so_far)
}

## How far toward dusk the sky is once the sun has fully set, darkening on
## to full dusk as it sinks a further radius.
dusk_after_set : Pixels -> Fraction
dusk_after_set = |height| {
	sunk_past_set = Sky.sun_fully_set_px.minus(height).ratio_to(Sky.sun_radius_px)
	Fraction.clamp(
		(Sky.dusk_at_set.to_f64() + (sunk_past_set * Sky.dusk_at_set.complement().to_f64())),
	)
}

sky_at : Clock -> Sky.Rgb
sky_at = |clock| Sky.color_between({
	from: Sky.day_sky,
	to: Sky.dusk_sky,
	fraction: Sky.dusk_at(clock),
})

sun_place : {
	turn_from_view : Angle.Turn,
	clock : Clock,
	cam_focal : Pixels,
} -> Sky.SunPlace
sun_place = |{ turn_from_view, clock, cam_focal }| {
	scale = Fraction.of(cam_focal.ratio_to(Lens.focal))
	slope = turn_from_view.to_radians().tan()
	{
		x: Screen.center_x.plus(cam_focal.times(slope)),
		y: Screen.horizon_y.minus(Sky.sun_height_px(clock).times(scale.to_f64())),
		scale,
	}
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

expect Sky.sun_height_px(Clock.at_step(0)).to_f64() == 244.0
expect Sky.sun_start_px.to_f64() == 244.0
expect Sky.sun_radius_px.to_f64() == 46.0
expect Sky.sun_fully_set_px.to_f64() == -46.0
expect Sky.warmth_falloff_px.to_f64() == 110.0
expect Sky.visible_turn_limit.to_radians() == 1.4
expect Sky.dusk_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.sunset_warmth(Clock.at_step(0)).to_f64() == 0.0
expect Sky.dusk_at(Clock.at_step(6000)).to_f64() == 1.0
expect Sky.sunset_warmth(Clock.at_step(6000)).to_f64() == 0.0
expect Sky.sunset_glow.to_f64() == 0.85

# The sky and the horizon at each thousandth step of the ride.
expect Sky.sky_top_color(Clock.at_step(0)) == 9358054
expect Sky.sky_top_color(Clock.at_step(1000)) == 9160418
expect Sky.sky_top_color(Clock.at_step(2000)) == 8633304
expect Sky.sky_top_color(Clock.at_step(3000)) == 7710918
expect Sky.sky_top_color(Clock.at_step(4000)) == 6393260
expect Sky.sky_top_color(Clock.at_step(5000)) == 4219010
expect Sky.sky_top_color(Clock.at_step(6000)) == 2374238
expect Sky.sky_horizon_color(Clock.at_step(0)) == 9358054
expect Sky.sky_horizon_color(Clock.at_step(1000)) == 9160418
expect Sky.sky_horizon_color(Clock.at_step(2000)) == 8633304
expect Sky.sky_horizon_color(Clock.at_step(3000)) == 10324366
expect Sky.sky_horizon_color(Clock.at_step(4000)) == 13262919
expect Sky.sky_horizon_color(Clock.at_step(5000)) == 8019301
expect Sky.sky_horizon_color(Clock.at_step(6000)) == 2374238
expect Sky.pack(Sky.day_sky) == 9358054
expect Sky.pack(Sky.dusk_sky) == 2374238
expect Sky.pack(Sky.sunset_red) == 14571572

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

# The rider faces the sun, then away from it.
expect
	Sky.sun_sighting({
		heading: Angle.Bearing.radians(0.0 - 2.2176),
		clock: Clock.start,
		cam_focal: Lens.focal,
	})
		== InView({
			x: Pixels.of(480.0),
			y: Pixels.of(56.0),
			scale: Fraction.whole,
		})

# A lens at half its focal length draws the sun at half its size.
expect
	Sky.sun_sighting({
		heading: Angle.Bearing.radians(0.0 - 2.2176),
		clock: Clock.start,
		cam_focal: Lens.focal.times(0.5),
	})
		== InView({
			x: Pixels.of(480.0),
			y: Pixels.of(178.0),
			scale: Fraction.of(0.5),
		})

expect
	Sky.sun_sighting({
		heading: Angle.north,
		clock: Clock.start,
		cam_focal: Lens.focal,
	})
		== OutOfView
