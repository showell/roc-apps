# Sky -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Camera
import lib.DeviceMath
import Lens
import Num_
import lib.Trig

Sky :: [].{
	Rgb : { r : F64, g : F64, b : F64 }
	SunPos : { visible : Bool, x : F64, y : F64, scale : F64 }

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

	sun_height_px : F64 -> F64
	sun_height_px = |step| (sun_start_px - (sun_drop_px_per_step * step))

	dusk_at_set : F64
	dusk_at_set = ((0.5 * (sun_start_px - sun_fully_set_px)) / sun_start_px)

	dusk_while_up : F64 -> F64
	dusk_while_up = |h| ({
		p = ((sun_start_px - h) / (sun_start_px - sun_fully_set_px))
		DeviceMath.real_max(0.0, ((dusk_at_set * p) * p))
	})

	dusk_after_set : F64 -> F64
	dusk_after_set = |h| DeviceMath.real_min(1.0, (dusk_at_set + (((sun_fully_set_px - h) / sun_radius_px) * (1.0 - dusk_at_set))))

	sun_set_fraction : F64 -> F64
	sun_set_fraction = |step| ({
		h = sun_height_px(step)
		(if (h >= sun_fully_set_px) { dusk_while_up(h) } else { dusk_after_set(h) })
	})

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

	lerp3 : Sky.Rgb, Sky.Rgb, F64 -> Sky.Rgb
	lerp3 = |a, b, t| { r: Num_.round_real((a.r + ((b.r - a.r) * t))), g: Num_.round_real((a.g + ((b.g - a.g) * t))), b: Num_.round_real((a.b + ((b.b - a.b) * t))) }

	pack : Sky.Rgb -> I64
	pack = |c| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(F64.to_i64_wrap(c.r), I64.to_u8_wrap(16)), I64.shl_wrap(F64.to_i64_wrap(c.g), I64.to_u8_wrap(8))), F64.to_i64_wrap(c.b))

	sky_color : F64 -> I64
	sky_color = |step| pack(lerp3(day_sky, dusk_sky, sun_set_fraction(step)))

	horizon_color : F64 -> I64
	horizon_color = |step| ({
		sky = lerp3(day_sky, dusk_sky, sun_set_fraction(step))
		pack(lerp3(sky, sunset_red, (sunset_warmth(step) * sunset_glow)))
	})

	sun_pos_visible : F64, F64, F64, F64 -> Sky.SunPos
	sun_pos_visible = |rel, step, cam_focal, view_w| ({
		v_scale = (cam_focal / Lens.focal)
		{ visible: True, x: ((view_w / 2.0) + (Trig.r_tan(rel) * cam_focal)), y: ((Camera.camera_h / 2.0) - (sun_height_px(step) * v_scale)), scale: v_scale }
	})

	sun_pos : F64, F64, F64, F64 -> Sky.SunPos
	sun_pos = |heading, step, cam_focal, view_w| ({
		rel = Trig.wrap((sun_bearing - heading), 64)
		(if (DeviceMath.real_abs(rel) >= visible_bearing_limit) { { visible: False, x: 0.0, y: 0.0, scale: 0.0 } } else { sun_pos_visible(rel, step, cam_focal, view_w) })
	})
}
