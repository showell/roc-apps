# InstancingKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

InstancingKernel :: [].{

	in_width : I32
	in_width = 1024

	in_half_w : I32
	in_half_w = 512

	in_half_h : I32
	in_half_h = 384

	in_count : I32
	in_count = 25

	in_cols : I32
	in_cols = 5

	in_gx : I32 -> F32
	in_gx = |i| (I32.to_f32(I32.minus_wrap(I32.minus_wrap(i, I32.times_wrap(Device.div(i, in_cols), in_cols)), 2)) * 1.25)

	in_gz : I32 -> F32
	in_gz = |i| (I32.to_f32(I32.minus_wrap(Device.div(i, in_cols), 2)) * 1.25)

	in_half : F32
	in_half = 0.42

	in_col_r : I32 -> F32
	in_col_r = |i| (0.55 + (I32.to_f32(I32.minus_wrap(i, I32.times_wrap(Device.div(i, in_cols), in_cols))) * 0.09))

	in_col_g : I32 -> F32
	in_col_g = |i| (0.45 + (I32.to_f32(Device.div(i, in_cols)) * 0.1))

	in_col_b : I32 -> F32
	in_col_b = |i| (0.85 - (I32.to_f32(I32.minus_wrap(i, I32.times_wrap(Device.div(i, in_cols), in_cols))) * 0.06))

	in_box_t : F32, F32, F32, F32, F32, F32 -> F32
	in_box_t = |ox, oy, oz, dx, dy, dz| ({
		s : F32
		s = in_half
		t1x : F32
		t1x = (((0.0 - s) - ox) / dx)
		t2x : F32
		t2x = ((s - ox) / dx)
		nx : F32
		nx = DeviceMath.real_min(t1x, t2x)
		fx : F32
		fx = DeviceMath.real_max(t1x, t2x)
		t1y : F32
		t1y = (((0.0 - s) - oy) / dy)
		t2y : F32
		t2y = ((s - oy) / dy)
		ny : F32
		ny = DeviceMath.real_min(t1y, t2y)
		fy : F32
		fy = DeviceMath.real_max(t1y, t2y)
		t1z : F32
		t1z = (((0.0 - s) - oz) / dz)
		t2z : F32
		t2z = ((s - oz) / dz)
		nz : F32
		nz = DeviceMath.real_min(t1z, t2z)
		fz : F32
		fz = DeviceMath.real_max(t1z, t2z)
		tmin : F32
		tmin = DeviceMath.real_max(nx, DeviceMath.real_max(ny, nz))
		tmax : F32
		tmax = DeviceMath.real_min(fx, DeviceMath.real_min(fy, fz))
		(if (tmin > tmax) { (0.0 - 1.0) } else { (if (tmax < 0.001) { (0.0 - 1.0) } else { (if (tmin < 0.001) { (0.0 - 1.0) } else { tmin }) }) })
	})

	in_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	in_hit = |ox, oy, oz, dx, dy, dz, i| in_box_t((ox - in_gx(i)), oy, (oz - in_gz(i)), dx, dy, dz)

	in_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	in_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= in_count) { best_id } else { ({
		t : F32
		t = in_hit(ox, oy, oz, dx, dy, dz, i)
		take : I32
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { in_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { in_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), best_id, best_t) })
	}) })

	in_clamp01 : F32 -> F32
	in_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	in_pack : F32, F32, F32 -> I32
	in_pack = |r, g, b| ({
		ri : I32
		ri = F32.to_i32_wrap((in_clamp01(r) * 255.0))
		gi : I32
		gi = F32.to_i32_wrap((in_clamp01(g) * 255.0))
		bi : I32
		bi = F32.to_i32_wrap((in_clamp01(b) * 255.0))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	in_bg : I32 -> I32
	in_bg = |py| ({
		h : F32
		h = (I32.to_f32(py) / 768.0)
		in_pack((0.05 + (h * 0.06)), (0.06 + (h * 0.09)), (0.1 + (h * 0.18)))
	})

	in_render : I32, I32 -> I32
	in_render = |gid, frame| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, in_width), in_width))
		py : I32
		py = Device.div(gid, in_width)
		fx : F32
		fx = (I32.to_f32(I32.minus_wrap(px, in_half_w)) / 384.0)
		fy : F32
		fy = (I32.to_f32(I32.minus_wrap(in_half_h, py)) / 384.0)
		rl : F32
		rl = DeviceMath.real_sqrt((((fx * fx) + ((fy - 0.35) * (fy - 0.35))) + 2.25))
		dx0 : F32
		dx0 = (fx / rl)
		dy0 : F32
		dy0 = ((fy - 0.35) / rl)
		dz0 : F32
		dz0 = (1.5 / rl)
		ay : F32
		ay = (I32.to_f32(frame) / 40.0)
		cy : F32
		cy = DeviceMath.real_cos(ay)
		sy : F32
		sy = DeviceMath.real_sin(ay)
		ox0 : F32
		ox0 = 0.0
		oy0 : F32
		oy0 = 2.2
		oz0 : F32
		oz0 = (0.0 - 6.2)
		ox : F32
		ox = ((ox0 * cy) + (oz0 * sy))
		oz : F32
		oz = ((0.0 - (ox0 * sy)) + (oz0 * cy))
		dx : F32
		dx = ((dx0 * cy) + (dz0 * sy))
		dz : F32
		dz = ((0.0 - (dx0 * sy)) + (dz0 * cy))
		id : I32
		id = in_nearest(ox, oy0, oz, dx, dy0, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		(if (id < 0) { in_bg(py) } else { ({
			lx : F32
			lx = (ox - in_gx(id))
			lz : F32
			lz = (oz - in_gz(id))
			t : F32
			t = in_box_t(lx, oy0, lz, dx, dy0, dz)
			hx : F32
			hx = (lx + (dx * t))
			hy : F32
			hy = (oy0 + (dy0 * t))
			hz : F32
			hz = (lz + (dz * t))
			ax : F32
			ax = (if (hx < 0.0) { (0.0 - hx) } else { hx })
			aay : F32
			aay = (if (hy < 0.0) { (0.0 - hy) } else { hy })
			az : F32
			az = (if (hz < 0.0) { (0.0 - hz) } else { hz })
			nlx : F32
			nlx = (if ((ax >= aay) and (ax >= az)) { (if (hx > 0.0) { 1.0 } else { (0.0 - 1.0) }) } else { 0.0 })
			nly : F32
			nly = (if ((aay >= ax) and (aay >= az)) { (if (hy > 0.0) { 1.0 } else { (0.0 - 1.0) }) } else { 0.0 })
			nlz : F32
			nlz = (if ((az >= ax) and (az >= aay)) { (if (hz > 0.0) { 1.0 } else { (0.0 - 1.0) }) } else { 0.0 })
			ndl : F32
			ndl = DeviceMath.real_max(0.0, (((nlx * 0.4) + (nly * 0.78)) + (nlz * (0.0 - 0.48))))
			sh : F32
			sh = (0.22 + (ndl * 0.88))
			in_pack((in_col_r(id) * sh), (in_col_g(id) * sh), (in_col_b(id) * sh))
		}) })
	})

	instancing_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	instancing_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, in_render(gid, frame))
	})
}
