# RaytraceKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

RaytraceKernel :: [].{

	rt_width : I64
	rt_width = 1024

	rt_half_w : I64
	rt_half_w = 512

	rt_half_h : I64
	rt_half_h = 384

	rt_nobj : I64
	rt_nobj = 4

	rt_cx : I64 -> F64
	rt_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.7) } else { 1.6 }) })

	rt_cy : I64 -> F64
	rt_cy = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 0.35) } else { (0.0 - 0.45) }) })

	rt_cz : I64 -> F64
	rt_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.5 } else { (0.0 - 0.4) }) })

	rt_rad : I64 -> F64
	rt_rad = |i| (if (i == 0) { 1.0 } else { (if (i == 1) { 0.65 } else { 0.55 }) })

	rt_col_r : I64 -> F64
	rt_col_r = |i| (if (i == 0) { 0.95 } else { (if (i == 1) { 0.2 } else { 0.7 }) })

	rt_col_g : I64 -> F64
	rt_col_g = |i| (if (i == 0) { 0.45 } else { (if (i == 1) { 0.8 } else { 0.35 }) })

	rt_col_b : I64 -> F64
	rt_col_b = |i| (if (i == 0) { 0.22 } else { (if (i == 1) { 0.75 } else { 0.95 }) })

	rt_sphere_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	rt_sphere_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - rt_cx(i))
		ly = (oy - rt_cy(i))
		lz = (oz - rt_cz(i))
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r = rt_rad(i)
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	rt_plane_hit : F64, F64 -> F64
	rt_plane_hit = |oy, dy| (if (dy > (0.0 - 0.0001)) { (0.0 - 1.0) } else { ({
		t = (((0.0 - 1.0) - oy) / dy)
		(if (t > 0.001) { t } else { (0.0 - 1.0) })
	}) })

	rt_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	rt_hit = |ox, oy, oz, dx, dy, dz, id| (if (id == 3) { rt_plane_hit(oy, dy) } else { rt_sphere_hit(ox, oy, oz, dx, dy, dz, id) })

	rt_nearest : F64, F64, F64, F64, F64, F64, I64, I64, F64 -> I64
	rt_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= rt_nobj) { best_id } else { ({
		t = rt_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { rt_nearest(ox, oy, oz, dx, dy, dz, (i + 1), i, t) } else { rt_nearest(ox, oy, oz, dx, dy, dz, (i + 1), best_id, best_t) })
	}) })

	rt_shadowed : F64, F64, F64, F64, F64, F64, I64 -> I64
	rt_shadowed = |ox, oy, oz, dx, dy, dz, i| (if (i >= 3) { 0 } else { ({
		t = rt_sphere_hit(ox, oy, oz, dx, dy, dz, i)
		(if (t > 0.001) { 1 } else { rt_shadowed(ox, oy, oz, dx, dy, dz, (i + 1)) })
	}) })

	rt_clamp01 : F64 -> F64
	rt_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	rt_pack : F64, F64, F64 -> I64
	rt_pack = |r, g, b| ({
		ri = F64.to_i64_wrap((rt_clamp01(r) * 255.0))
		gi = F64.to_i64_wrap((rt_clamp01(g) * 255.0))
		bi = F64.to_i64_wrap((rt_clamp01(b) * 255.0))
		(((ri * 65536) + (gi * 256)) + bi)
	})

	rt_sky : F64 -> I64
	rt_sky = |dy| ({
		h = rt_clamp01(((dy * 0.5) + 0.5))
		rt_pack((0.05 + (h * 0.06)), (0.09 + (h * 0.14)), (0.22 + (h * 0.34)))
	})

	rt_checker : F64, F64 -> F64
	rt_checker = |hx, hz| ({
		ix = F64.to_i64_wrap((hx + 64.0))
		iz = F64.to_i64_wrap((hz + 64.0))
		s = (ix + iz)
		(if ((s - (I64.div_trunc_by(s, 2) * 2)) == 0) { 0.32 } else { 0.62 })
	})

	rt_render : I64, I64 -> I64
	rt_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, rt_width) * rt_width))
		py = I64.div_trunc_by(gid, rt_width)
		fx = (I64.to_f64((px - rt_half_w)) / 384.0)
		fy = (I64.to_f64((rt_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.89))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.7 / rl)
		ox = 0.0
		oy = 0.7
		oz = (0.0 - 4.0)
		id = rt_nearest(ox, oy, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
		(if (id < 0) { rt_sky(dy) } else { ({
			t = rt_hit(ox, oy, oz, dx, dy, dz, id)
			hx = (ox + (dx * t))
			hy = (oy + (dy * t))
			hz = (oz + (dz * t))
			nx = (if (id == 3) { 0.0 } else { ((hx - rt_cx(id)) / rt_rad(id)) })
			ny = (if (id == 3) { 1.0 } else { ((hy - rt_cy(id)) / rt_rad(id)) })
			nz = (if (id == 3) { 0.0 } else { ((hz - rt_cz(id)) / rt_rad(id)) })
			br = (if (id == 3) { rt_checker(hx, hz) } else { rt_col_r(id) })
			bg = (if (id == 3) { rt_checker(hx, hz) } else { rt_col_g(id) })
			bb = (if (id == 3) { rt_checker(hx, hz) } else { rt_col_b(id) })
			ang = (I64.to_f64(frame) / 24.0)
			lx = (DeviceMath.real_cos(ang) * 0.6)
			ly = 0.9
			lz = (DeviceMath.real_sin(ang) * 0.6)
			ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
			ux = (lx / ll)
			uy = (ly / ll)
			uz = (lz / ll)
			ndl = DeviceMath.real_max(0.0, (((nx * ux) + (ny * uy)) + (nz * uz)))
			sx = (hx + (nx * 0.002))
			sy = (hy + (ny * 0.002))
			sz = (hz + (nz * 0.002))
			sh = rt_shadowed(sx, sy, sz, ux, uy, uz, 0)
			lit = (if (sh == 1) { 0.2 } else { (0.2 + (ndl * 0.9)) })
			rt_pack((br * lit), (bg * lit), (bb * lit))
		}) })
	})

	raytrace_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	raytrace_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, rt_render(gid, frame))
	})
}
