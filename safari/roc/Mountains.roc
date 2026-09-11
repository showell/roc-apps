# Mountains -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import DeviceMath
import Lens
import Num
import Paint
import Sky
import Trig

Mountains :: [].{

	rock : I64
	rock = 5991055

	rock_west : I64
	rock_west = 3752799

	land : I64
	land = 4886339

	rock_night_dim : F64
	rock_night_dim = 0.5

	snow_day : Sky.Rgb
	snow_day = { r: 238.0, g: 243.0, b: 248.0 }

	snow_night : Sky.Rgb
	snow_night = { r: 70.0, g: 84.0, b: 104.0 }

	chan : I64, I64 -> F64
	chan = |color, sh| I64.to_f64(I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(color), U64.pow(2, I64.to_u64_wrap(sh)))), 255))

	dimmed : I64, F64 -> I64
	dimmed = |color, dusk| ({
		f = (1.0 - (rock_night_dim * dusk))
		r = F64.to_i64_wrap(Num.round_real((chan(color, 16) * f)))
		g = F64.to_i64_wrap(Num.round_real((chan(color, 8) * f)))
		b = F64.to_i64_wrap(Num.round_real((chan(color, 0) * f)))
		I64.bitwise_or(I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(r), U64.pow(2, I64.to_u64_wrap(16)))), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(g), U64.pow(2, I64.to_u64_wrap(8))))), b)
	})

	snow_color : F64 -> I64
	snow_color = |dusk| Sky.pack(Sky.lerp3(snow_day, snow_night, dusk))

	west_range_bearing : F64
	west_range_bearing = (0.0 - 2.0416)

	snow_threshold : F64
	snow_threshold = 124.0

	snow_dip : F64
	snow_dip = 10.0

	col_step : F64
	col_step = 2.0

	roll_margin : F64
	roll_margin = 200.0

	range_at : F64, F64, F64, F64, F64, F64 -> F64
	range_at = |bearing, center, half, peak, freq_a, freq_b| ({
		b = Trig.wrap((bearing - center), 64)
		t = (b / half)
		(if (DeviceMath.real_abs(t) >= 1.0) { 0.0 } else { range_body(b, t, peak, freq_a, freq_b) })
	})

	range_body : F64, F64, F64, F64, F64 -> F64
	range_body = |b, t, peak, freq_a, freq_b| ({
		envelope = Trig.r_cos(((t * Trig.pi) / 2.0))
		ridge = ((0.6 + (0.24 * Trig.r_cos((b * freq_a)))) + (0.16 * Trig.r_cos(((b * freq_b) + 1.0))))
		((peak * envelope) * ridge)
	})

	ground_base : F64 -> F64
	ground_base = |bearing| (18.0 + (12.0 * Trig.r_sin(((Trig.wrap(bearing, 64) * 0.9) + 1.9))))

	north_range : F64 -> F64
	north_range = |bearing| range_at(bearing, 0.0, 0.95, 150.0, 8.0, 21.0)

	west_range : F64 -> F64
	west_range = |bearing| range_at(bearing, west_range_bearing, 0.72, 120.0, 11.0, 27.0)

	snow_peak_loop : F64, F64 -> F64
	snow_peak_loop = |b, vm| (if (b > 0.5) { vm } else { snow_peak_loop((b + 0.01), DeviceMath.real_max(vm, north_range(b))) })

	snow_peak_height : F64
	snow_peak_height = snow_peak_loop((0.0 - 0.5), (0.0 - 1.0))

	snowline_at : F64, F64 -> F64
	snowline_at = |bearing, peak| ({
		num = (north_range(bearing) - snow_threshold)
		above_frac = DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, (num / (peak - snow_threshold))))
		(snow_threshold - (snow_dip * above_frac))
	})

	bearing_at : F64, F64, F64, F64 -> F64
	bearing_at = |x, heading, cam_focal, view_w| (heading + Trig.r_atan(((x - (view_w / 2.0)) / cam_focal)))

	horizon_crest_px : F64 -> F64
	horizon_crest_px = |bearing| DeviceMath.real_max(west_range(bearing), DeviceMath.real_max(north_range(bearing), ground_base(bearing)))

	sun_behind_mountains : F64 -> Bool
	sun_behind_mountains = |step| ((Sky.sun_height_px(step) + Sky.sun_radius_px) < horizon_crest_px(Sky.sun_bearing))

	# crest_pts builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	crest_pts : (F64 -> F64), F64, F64, F64, F64, F64 -> List(Camera.ScreenPt)
	crest_pts = |f, heading, cam_focal, view_w, v_scale, x| crest_pts_acc(f, heading, cam_focal, view_w, v_scale, x, [])

	crest_pts_acc : (F64 -> F64), F64, F64, F64, F64, F64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	crest_pts_acc = |f, heading, cam_focal, view_w, v_scale, x, acc| (if (x > (view_w + roll_margin)) { acc } else { crest_pts_acc(f, heading, cam_focal, view_w, v_scale, (x + col_step), List.append(acc, { x: x, y: ((Camera.camera_h / 2.0) - (f(bearing_at(x, heading, cam_focal, view_w)) * v_scale)) })) })

	silhouette : (F64 -> F64), F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	silhouette = |f, heading, cam_focal, view_w, v_scale, color| ({
		top = crest_pts(f, heading, cam_focal, view_w, v_scale, (0.0 - roll_margin))
		close = [{ x: (view_w + roll_margin), y: (Camera.camera_h / 2.0) }, { x: (0.0 - roll_margin), y: (Camera.camera_h / 2.0) }]
		Paint.push_poly(color, List.concat(top, close))
	})

	snow_columns : F64, F64, F64, F64, F64 -> List(F64)
	snow_columns = |heading, cam_focal, view_w, peak, x| (if (x > view_w) { [] } else { snow_columns_at(heading, cam_focal, view_w, peak, x) })

	snow_columns_at : F64, F64, F64, F64, F64 -> List(F64)
	snow_columns_at = |heading, cam_focal, view_w, peak, x| ({
		b = bearing_at(x, heading, cam_focal, view_w)
		rest = snow_columns(heading, cam_focal, view_w, peak, (x + col_step))
		(if (north_range(b) > (snowline_at(b, peak) + 0.01)) { List.concat([x], rest) } else { rest })
	})

	# snow_top builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	snow_top : List(F64), F64, F64, F64, F64, I64 -> List(Camera.ScreenPt)
	snow_top = |xs, heading, cam_focal, view_w, v_scale, i| snow_top_acc(xs, heading, cam_focal, view_w, v_scale, i, [])

	snow_top_acc : List(F64), F64, F64, F64, F64, I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	snow_top_acc = |xs, heading, cam_focal, view_w, v_scale, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { snow_top_acc(xs, heading, cam_focal, view_w, v_scale, (i + 1), List.append(acc, { x: (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), y: ((Camera.camera_h / 2.0) - (north_range(bearing_at((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), heading, cam_focal, view_w)) * v_scale)) })) })

	# snow_bottom builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	snow_bottom : List(F64), F64, F64, F64, F64, F64, I64 -> List(Camera.ScreenPt)
	snow_bottom = |xs, heading, cam_focal, view_w, v_scale, peak, i| snow_bottom_acc(xs, heading, cam_focal, view_w, v_scale, peak, i, [])

	snow_bottom_acc : List(F64), F64, F64, F64, F64, F64, I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	snow_bottom_acc = |xs, heading, cam_focal, view_w, v_scale, peak, i, acc| (if (i < 0) { acc } else { snow_bottom_acc(xs, heading, cam_focal, view_w, v_scale, peak, (i - 1), List.append(acc, { x: (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), y: ((Camera.camera_h / 2.0) - (snowline_at(bearing_at((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), heading, cam_focal, view_w), peak) * v_scale)) })) })

	draw_snow : F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	draw_snow = |heading, cam_focal, view_w, v_scale, snow| ({
		peak = snow_peak_height
		xs = snow_columns(heading, cam_focal, view_w, peak, 0.0)
		(if (U64.to_i64_wrap(List.len(xs)) < 2) { [] } else { Paint.push_poly(snow, List.concat(snow_top(xs, heading, cam_focal, view_w, v_scale, 0), snow_bottom(xs, heading, cam_focal, view_w, v_scale, peak, (U64.to_i64_wrap(List.len(xs)) - 1)))) })
	})

	draw : F64, F64, F64, F64 -> List(Paint.DrawCmd)
	draw = |heading, dusk, cam_focal, view_w| ({
		v_scale = (cam_focal / Lens.focal)
		west = silhouette(west_range, heading, cam_focal, view_w, v_scale, dimmed(rock_west, dusk))
		north = silhouette(north_range, heading, cam_focal, view_w, v_scale, dimmed(rock, dusk))
		cap = draw_snow(heading, cam_focal, view_w, v_scale, snow_color(dusk))
		ground = silhouette(ground_base, heading, cam_focal, view_w, v_scale, land)
		List.concat(List.concat(List.concat(west, north), cap), ground)
	})
}
