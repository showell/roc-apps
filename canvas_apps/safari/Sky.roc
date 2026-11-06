## The sky through the ride: the sun sinks a little with every step, the
## sky darkens toward dusk as it goes, and the horizon warms red while the
## sun is near it. The sun is drawn only while the rider faces it.
import Angle
import Clock
import Fraction
import lib.DeviceMath
import Lens
import Num_
import Screen
import lib.Trig

Sky :: [].{
	Rgb : {
		r : F64,
		g : F64,
		b : F64,
	}

	## Where the sun stands on the screen, and how large it is drawn beside
	## its size at rest.
	SunPlace : {
		x : F64,
		y : F64,
		scale : F64,
	}

	## The sun in a frame: in view at its place, or out of view, too far to
	## the side of where the rider faces.
	SunSighting : [InView(Sky.SunPlace), OutOfView]

	sun_bearing : Angle.Bearing
	sun_bearing = Angle.Bearing.radians(0.0 - 2.2176)

	sun_radius_px : F64
	sun_radius_px = 46.0

	sun_start_px : F64
	sun_start_px = 244.0

	sun_drop_px_per_step : F64
	sun_drop_px_per_step = ((0.41616 * (2.0 * sun_radius_px)) / 625.0)

	sun_fully_set_px : F64
	sun_fully_set_px = (0.0 - sun_radius_px)

	warmth_falloff_px : F64
	warmth_falloff_px = 110.0

	visible_turn_limit : Angle.Turn
	visible_turn_limit = Angle.Turn.radians(1.4)

	## How high the sun stands above the horizon at `clock`, in pixels at
	## rest; below it once negative.
	sun_height_px : Clock -> F64
	sun_height_px = |clock| sun_start_px - (sun_drop_px_per_step * clock.to_f64())

	## How far toward dusk the sky is when the sun has just set.
	dusk_at_set : Fraction
	dusk_at_set = Fraction.of(((0.5 * (sun_start_px - sun_fully_set_px)) / sun_start_px))

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
		(1.0 - (DeviceMath.real_abs(sun_height_px(clock)) / warmth_falloff_px)),
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
			r: Num_.round_real((from.r + ((to.r - from.r) * share))),
			g: Num_.round_real((from.g + ((to.g - from.g) * share))),
			b: Num_.round_real((from.b + ((to.b - from.b) * share))),
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
	sky_color : Clock -> I64
	sky_color = |clock| pack(sky_at(clock))

	## The sky's colour at the horizon, as 0xRRGGBB: the sky warmed toward
	## sunset red.
	horizon_color : Clock -> I64
	horizon_color = |clock| pack(
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
		cam_focal : F64,
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
dusk_while_up : F64 -> Fraction
dusk_while_up = |height| {
	whole_fall = (Sky.sun_start_px - Sky.sun_fully_set_px)
	set_so_far = Fraction.of(((Sky.sun_start_px - height) / whole_fall))
	Sky.dusk_at_set.times(set_so_far).times(set_so_far)
}

## How far toward dusk the sky is once the sun has fully set, darkening on
## to full dusk as it sinks a further radius.
dusk_after_set : F64 -> Fraction
dusk_after_set = |height| {
	sunk_past_set = ((Sky.sun_fully_set_px - height) / Sky.sun_radius_px)
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
	cam_focal : F64,
} -> Sky.SunPlace
sun_place = |{ turn_from_view, clock, cam_focal }| {
	scale = (cam_focal / Lens.focal)
	{
		x: (Screen.center_x + (Trig.r_tan(turn_from_view.to_radians()) * cam_focal)),
		y: (Screen.horizon_y - (Sky.sun_height_px(clock) * scale)),
		scale,
	}
}

expect Sky.sun_height_px(Clock.at_step(0)) == 244.0
expect Sky.sun_start_px == 244.0
expect Sky.sun_radius_px == 46.0
expect Sky.sun_fully_set_px == -46.0
expect Sky.warmth_falloff_px == 110.0
expect Sky.visible_turn_limit.to_radians() == 1.4
expect Sky.dusk_at(Clock.at_step(0)).to_f64() == 0.0
expect Sky.sunset_warmth(Clock.at_step(0)).to_f64() == 0.0
expect Sky.dusk_at(Clock.at_step(6000)).to_f64() == 1.0
expect Sky.sunset_warmth(Clock.at_step(6000)).to_f64() == 0.0
expect Sky.sunset_glow.to_f64() == 0.85

# The sky and the horizon at each thousandth step of the ride.
expect Sky.sky_color(Clock.at_step(0)) == 9358054
expect Sky.sky_color(Clock.at_step(1000)) == 9160418
expect Sky.sky_color(Clock.at_step(2000)) == 8633304
expect Sky.sky_color(Clock.at_step(3000)) == 7710918
expect Sky.sky_color(Clock.at_step(4000)) == 6393260
expect Sky.sky_color(Clock.at_step(5000)) == 4219010
expect Sky.sky_color(Clock.at_step(6000)) == 2374238
expect Sky.horizon_color(Clock.at_step(0)) == 9358054
expect Sky.horizon_color(Clock.at_step(1000)) == 9160418
expect Sky.horizon_color(Clock.at_step(2000)) == 8633304
expect Sky.horizon_color(Clock.at_step(3000)) == 10324366
expect Sky.horizon_color(Clock.at_step(4000)) == 13262919
expect Sky.horizon_color(Clock.at_step(5000)) == 8019301
expect Sky.horizon_color(Clock.at_step(6000)) == 2374238
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
			x: 480.0,
			y: 56.0,
			scale: 1.0,
		})

expect
	Sky.sun_sighting({
		heading: Angle.north,
		clock: Clock.start,
		cam_focal: Lens.focal,
	})
		== OutOfView
