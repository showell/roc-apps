## The sky through the ride: the sun sinks a little with every step, the
## sky darkens toward dusk as it goes, and the horizon warms red while the
## sun is near it. The sun is drawn only while the rider faces it.
import Camera
import lib.DeviceMath
import Lens
import Num_
import Screen
import lib.Trig

Sky :: [].{
	Rgb : { r : F64, g : F64, b : F64 }

	## Where the sun stands on the screen, and how large it is drawn beside
	## its size at rest.
	SunPlace : { x : F64, y : F64, scale : F64 }

	## The sun in a frame: in view at its place, or out of view, too far to
	## the side of where the rider faces.
	SunPos : [InView(Sky.SunPlace), OutOfView]

	sun_bearing : F64
	sun_bearing = (0.0 - 2.2176)

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

	visible_bearing_limit : F64
	visible_bearing_limit = 1.4

	## How high the sun stands above the horizon at a step, in pixels at
	## rest; below it once negative.
	sun_height_px : F64 -> F64
	sun_height_px = |step| (sun_start_px - (sun_drop_px_per_step * step))

	## How far toward dusk the sky is when the sun has just set.
	dusk_at_set : F64
	dusk_at_set = ((0.5 * (sun_start_px - sun_fully_set_px)) / sun_start_px)

	## How far toward dusk the sky is at a step, from 0 (day) to 1 (dusk).
	sun_set_fraction : F64 -> F64
	sun_set_fraction = |step| {
		height = sun_height_px(step)
		if (height >= sun_fully_set_px) dusk_while_up(height) else dusk_after_set(height)
	}

	## How warm the horizon is at a step: most while the sun touches it, none
	## once the sun is `warmth_falloff_px` above or below.
	sunset_warmth : F64 -> F64
	sunset_warmth = |step| DeviceMath.real_max(0.0, (1.0 - (DeviceMath.real_abs(sun_height_px(step)) / warmth_falloff_px)))

	day_sky : Sky.Rgb
	day_sky = { r: 142.0, g: 202.0, b: 230.0 }

	dusk_sky : Sky.Rgb
	dusk_sky = { r: 36.0, g: 58.0, b: 94.0 }

	sunset_red : Sky.Rgb
	sunset_red = { r: 222.0, g: 88.0, b: 52.0 }

	sunset_glow : F64
	sunset_glow = 0.85

	## The colour `fraction` of the way from `from` to `to`, each channel
	## rounded to a whole value.
	color_between : { from : Sky.Rgb, to : Sky.Rgb, fraction : F64 } -> Sky.Rgb
	color_between = |{ from, to, fraction }| {
		r: Num_.round_real((from.r + ((to.r - from.r) * fraction))),
		g: Num_.round_real((from.g + ((to.g - from.g) * fraction))),
		b: Num_.round_real((from.b + ((to.b - from.b) * fraction))),
	}

	## A colour as 0xRRGGBB.
	pack : Sky.Rgb -> I64
	pack = |c| {
		red_bits = I64.shl_wrap(F64.to_i64_wrap(c.r), 16)
		green_bits = I64.shl_wrap(F64.to_i64_wrap(c.g), 8)
		I64.bitwise_or(I64.bitwise_or(red_bits, green_bits), F64.to_i64_wrap(c.b))
	}

	## The sky's colour at the top of the frame, as 0xRRGGBB.
	sky_color : F64 -> I64
	sky_color = |step| pack(sky_at(step))

	## The sky's colour at the horizon, as 0xRRGGBB: the sky warmed toward
	## sunset red.
	horizon_color : F64 -> I64
	horizon_color = |step| pack(color_between({ from: sky_at(step), to: sunset_red, fraction: (sunset_warmth(step) * sunset_glow) }))

	## The sun in a frame, for a rider facing `heading`.
	sun_pos : { heading : F64, step : F64, view : Camera.View } -> Sky.SunPos
	sun_pos = |{ heading, step, view }| {
		bearing_from_view = Trig.wrap((sun_bearing - heading), 64)
		if DeviceMath.real_abs(bearing_from_view) >= visible_bearing_limit {
			OutOfView
		} else {
			InView(sun_place({ bearing_from_view, step, view }))
		}
	}
}

## How far toward dusk the sky is while the sun, `height` pixels up, is
## still above the line where it has fully set.
dusk_while_up : F64 -> F64
dusk_while_up = |height| {
	set_so_far = ((Sky.sun_start_px - height) / (Sky.sun_start_px - Sky.sun_fully_set_px))
	DeviceMath.real_max(0.0, ((Sky.dusk_at_set * set_so_far) * set_so_far))
}

## How far toward dusk the sky is once the sun has fully set, darkening on
## to full dusk as it sinks a further radius.
dusk_after_set : F64 -> F64
dusk_after_set = |height| DeviceMath.real_min(1.0, (Sky.dusk_at_set + (((Sky.sun_fully_set_px - height) / Sky.sun_radius_px) * (1.0 - Sky.dusk_at_set))))

sky_at : F64 -> Sky.Rgb
sky_at = |step| Sky.color_between({ from: Sky.day_sky, to: Sky.dusk_sky, fraction: Sky.sun_set_fraction(step) })

sun_place : { bearing_from_view : F64, step : F64, view : Camera.View } -> Sky.SunPlace
sun_place = |{ bearing_from_view, step, view }| {
	scale = (view.cam_focal / Lens.focal)
	{
		x: ((view.view_w / 2.0) + (Trig.r_tan(bearing_from_view) * view.cam_focal)),
		y: (Screen.horizon_y - (Sky.sun_height_px(step) * scale)),
		scale,
	}
}
