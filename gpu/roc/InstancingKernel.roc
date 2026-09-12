# InstancingKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

InstancingKernel :: [].{

	in_width : I64
	in_width = 1024

	in_half_w : I64
	in_half_w = 512

	in_half_h : I64
	in_half_h = 384

	in_count : I64
	in_count = 25

	in_cols : I64
	in_cols = 5

	in_gx : I64 -> F64
	in_gx = |i| (I64.to_f64(((i - (I64.div_trunc_by(i, in_cols) * in_cols)) - 2)) * 1.25)

	in_gz : I64 -> F64
	in_gz = |i| (I64.to_f64((I64.div_trunc_by(i, in_cols) - 2)) * 1.25)

	in_half : F64
	in_half = 0.42

	in_col_r : I64 -> F64
	in_col_r = |i| (0.55 + (I64.to_f64((i - (I64.div_trunc_by(i, in_cols) * in_cols))) * 0.09))

	in_col_g : I64 -> F64
	in_col_g = |i| (0.45 + (I64.to_f64(I64.div_trunc_by(i, in_cols)) * 0.1))

	in_col_b : I64 -> F64
	in_col_b = |i| (0.85 - (I64.to_f64((i - (I64.div_trunc_by(i, in_cols) * in_cols))) * 0.06))

	in_box_t : F64, F64, F64, F64, F64, F64 -> F64
	in_box_t = |ox, oy, oz, dx, dy, dz| ({
		s = in_half
		t1x = (((0.0 - s) - ox) / dx)
		t2x = ((s - ox) / dx)
		nx = DeviceMath.real_min(t1x, t2x)
		fx = DeviceMath.real_max(t1x, t2x)
		t1y = (((0.0 - s) - oy) / dy)
		t2y = ((s - oy) / dy)
		ny = DeviceMath.real_min(t1y, t2y)
		fy = DeviceMath.real_max(t1y, t2y)
		t1z = (((0.0 - s) - oz) / dz)
		t2z = ((s - oz) / dz)
		nz = DeviceMath.real_min(t1z, t2z)
		fz = DeviceMath.real_max(t1z, t2z)
		tmin = DeviceMath.real_max(nx, DeviceMath.real_max(ny, nz))
		tmax = DeviceMath.real_min(fx, DeviceMath.real_min(fy, fz))
		(if (tmin > tmax) { (0.0 - 1.0) } else { (if (tmax < 0.001) { (0.0 - 1.0) } else { (if (tmin < 0.001) { (0.0 - 1.0) } else { tmin }) }) })
	})

	in_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	in_hit = |ox, oy, oz, dx, dy, dz, i| in_box_t((ox - in_gx(i)), oy, (oz - in_gz(i)), dx, dy, dz)

	in_nearest : F64, F64, F64, F64, F64, F64, I64, I64, F64 -> I64
	in_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= in_count) { best_id } else { ({
		t = in_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { in_nearest(ox, oy, oz, dx, dy, dz, (i + 1), i, t) } else { in_nearest(ox, oy, oz, dx, dy, dz, (i + 1), best_id, best_t) })
	}) })

	in_clamp01 : F64 -> F64
	in_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	in_pack : F64, F64, F64 -> I64
	in_pack = |r, g, b| ({
		ri = F64.to_i64_wrap((in_clamp01(r) * 255.0))
		gi = F64.to_i64_wrap((in_clamp01(g) * 255.0))
		bi = F64.to_i64_wrap((in_clamp01(b) * 255.0))
		(((ri * 65536) + (gi * 256)) + bi)
	})

	in_bg : I64 -> I64
	in_bg = |py| ({
		h = (I64.to_f64(py) / 768.0)
		in_pack((0.05 + (h * 0.06)), (0.06 + (h * 0.09)), (0.1 + (h * 0.18)))
	})

	in_render : I64, I64 -> I64
	in_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, in_width) * in_width))
		py = I64.div_trunc_by(gid, in_width)
		fx = (I64.to_f64((px - in_half_w)) / 384.0)
		fy = (I64.to_f64((in_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + ((fy - 0.35) * (fy - 0.35))) + 2.25))
		dx0 = (fx / rl)
		dy0 = ((fy - 0.35) / rl)
		dz0 = (1.5 / rl)
		ay = (I64.to_f64(frame) / 40.0)
		cy = DeviceMath.real_cos(ay)
		sy = DeviceMath.real_sin(ay)
		ox0 = 0.0
		oy0 = 2.2
		oz0 = (0.0 - 6.2)
		ox = ((ox0 * cy) + (oz0 * sy))
		oz = ((0.0 - (ox0 * sy)) + (oz0 * cy))
		dx = ((dx0 * cy) + (dz0 * sy))
		dz = ((0.0 - (dx0 * sy)) + (dz0 * cy))
		id = in_nearest(ox, oy0, oz, dx, dy0, dz, 0, (0 - 1), (0.0 - 1.0))
		(if (id < 0) { in_bg(py) } else { ({
			lx = (ox - in_gx(id))
			lz = (oz - in_gz(id))
			t = in_box_t(lx, oy0, lz, dx, dy0, dz)
			hx = (lx + (dx * t))
			hy = (oy0 + (dy0 * t))
			hz = (lz + (dz * t))
			ax = (if (hx < 0.0) { (0.0 - hx) } else { hx })
			aay = (if (hy < 0.0) { (0.0 - hy) } else { hy })
			az = (if (hz < 0.0) { (0.0 - hz) } else { hz })
			nlx = (if ((ax >= aay) and (ax >= az)) { (if (hx > 0.0) { 1.0 } else { (0.0 - 1.0) }) } else { 0.0 })
			nly = (if ((aay >= ax) and (aay >= az)) { (if (hy > 0.0) { 1.0 } else { (0.0 - 1.0) }) } else { 0.0 })
			nlz = (if ((az >= ax) and (az >= aay)) { (if (hz > 0.0) { 1.0 } else { (0.0 - 1.0) }) } else { 0.0 })
			ndl = DeviceMath.real_max(0.0, (((nlx * 0.4) + (nly * 0.78)) + (nlz * (0.0 - 0.48))))
			sh = (0.22 + (ndl * 0.88))
			in_pack((in_col_r(id) * sh), (in_col_g(id) * sh), (in_col_b(id) * sh))
		}) })
	})

	instancing_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	instancing_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, in_render(gid, frame))
	})
}
