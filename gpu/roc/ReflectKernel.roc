# ReflectKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ReflectKernel :: [].{

	rf_width : I32
	rf_width = 1024

	rf_half_w : I32
	rf_half_w = 512

	rf_half_h : I32
	rf_half_h = 384

	rf_nobj : I32
	rf_nobj = 4

	rf_cx : I32 -> F32
	rf_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.7) } else { 1.6 }) })

	rf_cy : I32 -> F32
	rf_cy = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 0.35) } else { (0.0 - 0.45) }) })

	rf_cz : I32 -> F32
	rf_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.5 } else { (0.0 - 0.4) }) })

	rf_rad : I32 -> F32
	rf_rad = |i| (if (i == 0) { 1.0 } else { (if (i == 1) { 0.65 } else { 0.55 }) })

	rf_col_r : I32 -> F32
	rf_col_r = |i| (if (i == 0) { 0.95 } else { (if (i == 1) { 0.25 } else { 0.75 }) })

	rf_col_g : I32 -> F32
	rf_col_g = |i| (if (i == 0) { 0.55 } else { (if (i == 1) { 0.85 } else { 0.4 }) })

	rf_col_b : I32 -> F32
	rf_col_b = |i| (if (i == 0) { 0.3 } else { (if (i == 1) { 0.8 } else { 0.98 }) })

	rf_refl : I32 -> F32
	rf_refl = |i| (if (i == 3) { 0.3 } else { 0.55 })

	rf_sphere_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	rf_sphere_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - rf_cx(i))
		ly = (oy - rf_cy(i))
		lz = (oz - rf_cz(i))
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r = rf_rad(i)
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	rf_plane_hit : F32, F32 -> F32
	rf_plane_hit = |oy, dy| (if (dy > (0.0 - 0.0001)) { (0.0 - 1.0) } else { ({
		t = (((0.0 - 1.0) - oy) / dy)
		(if (t > 0.001) { t } else { (0.0 - 1.0) })
	}) })

	rf_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	rf_hit = |ox, oy, oz, dx, dy, dz, id| (if (id == 3) { rf_plane_hit(oy, dy) } else { rf_sphere_hit(ox, oy, oz, dx, dy, dz, id) })

	rf_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	rf_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= rf_nobj) { best_id } else { ({
		t = rf_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { rf_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { rf_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), best_id, best_t) })
	}) })

	rf_shadowed : F32, F32, F32, F32, F32, F32, I32 -> I32
	rf_shadowed = |ox, oy, oz, dx, dy, dz, i| (if (i >= 3) { 0 } else { ({
		t = rf_sphere_hit(ox, oy, oz, dx, dy, dz, i)
		(if (t > 0.001) { 1 } else { rf_shadowed(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1)) })
	}) })

	rf_clamp01 : F32 -> F32
	rf_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	rf_pack : F32, F32, F32 -> I32
	rf_pack = |r, g, b| ({
		ri = F32.to_i32_wrap((rf_clamp01(r) * 255.0))
		gi = F32.to_i32_wrap((rf_clamp01(g) * 255.0))
		bi = F32.to_i32_wrap((rf_clamp01(b) * 255.0))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	rf_sky : F32 -> I32
	rf_sky = |dy| ({
		h = rf_clamp01(((dy * 0.5) + 0.5))
		rf_pack((0.05 + (h * 0.06)), (0.1 + (h * 0.16)), (0.24 + (h * 0.4)))
	})

	rf_checker : F32, F32 -> F32
	rf_checker = |hx, hz| ({
		ix = F32.to_i32_wrap((hx + 64.0))
		iz = F32.to_i32_wrap((hz + 64.0))
		s = I32.plus_wrap(ix, iz)
		(if (I32.minus_wrap(s, I32.times_wrap(Device.div(s, 2), 2)) == 0) { 0.35 } else { 0.65 })
	})

	rf_un_r : I32 -> F32
	rf_un_r = |p| (I32.to_f32(Device.div(p, 65536)) / 255.0)

	rf_un_g : I32 -> F32
	rf_un_g = |p| (I32.to_f32(I32.minus_wrap(Device.div(p, 256), I32.times_wrap(Device.div(p, 65536), 256))) / 255.0)

	rf_un_b : I32 -> F32
	rf_un_b = |p| (I32.to_f32(I32.minus_wrap(p, I32.times_wrap(Device.div(p, 256), 256))) / 255.0)

	rf_local : F32, F32, F32, F32, F32, F32, I32, I32 -> I32
	rf_local = |ox, oy, oz, dx, dy, dz, id, frame| ({
		t = rf_hit(ox, oy, oz, dx, dy, dz, id)
		hx = (ox + (dx * t))
		hy = (oy + (dy * t))
		hz = (oz + (dz * t))
		nx = (if (id == 3) { 0.0 } else { ((hx - rf_cx(id)) / rf_rad(id)) })
		ny = (if (id == 3) { 1.0 } else { ((hy - rf_cy(id)) / rf_rad(id)) })
		nz = (if (id == 3) { 0.0 } else { ((hz - rf_cz(id)) / rf_rad(id)) })
		br = (if (id == 3) { rf_checker(hx, hz) } else { rf_col_r(id) })
		bg = (if (id == 3) { rf_checker(hx, hz) } else { rf_col_g(id) })
		bb = (if (id == 3) { rf_checker(hx, hz) } else { rf_col_b(id) })
		ang = (I32.to_f32(frame) / 24.0)
		lx = (DeviceMath.real_cos(ang) * 0.6)
		ly = 0.9
		lz = (DeviceMath.real_sin(ang) * 0.6)
		ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
		ux = (lx / ll)
		uy = (ly / ll)
		uz = (lz / ll)
		ndl = DeviceMath.real_max(0.0, (((nx * ux) + (ny * uy)) + (nz * uz)))
		sh = rf_shadowed((hx + (nx * 0.002)), (hy + (ny * 0.002)), (hz + (nz * 0.002)), ux, uy, uz, 0)
		lit = (if (sh == 1) { 0.22 } else { (0.22 + (ndl * 0.9)) })
		rf_pack((br * lit), (bg * lit), (bb * lit))
	})

	rf_render : I32, I32 -> I32
	rf_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, rf_width), rf_width))
		py = Device.div(gid, rf_width)
		fx = (I32.to_f32(I32.minus_wrap(px, rf_half_w)) / 384.0)
		fy = (I32.to_f32(I32.minus_wrap(rf_half_h, py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.89))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.7 / rl)
		ox = 0.0
		oy = 0.7
		oz = (0.0 - 4.0)
		id0 = rf_nearest(ox, oy, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		(if (id0 < 0) { rf_sky(dy) } else { ({
			t0 = rf_hit(ox, oy, oz, dx, dy, dz, id0)
			hx = (ox + (dx * t0))
			hy = (oy + (dy * t0))
			hz = (oz + (dz * t0))
			nx = (if (id0 == 3) { 0.0 } else { ((hx - rf_cx(id0)) / rf_rad(id0)) })
			ny = (if (id0 == 3) { 1.0 } else { ((hy - rf_cy(id0)) / rf_rad(id0)) })
			nz = (if (id0 == 3) { 0.0 } else { ((hz - rf_cz(id0)) / rf_rad(id0)) })
			p0 = rf_local(ox, oy, oz, dx, dy, dz, id0, frame)
			dn = (((dx * nx) + (dy * ny)) + (dz * nz))
			rx = (dx - ((2.0 * dn) * nx))
			ry = (dy - ((2.0 * dn) * ny))
			rz = (dz - ((2.0 * dn) * nz))
			sx = (hx + (nx * 0.003))
			sy = (hy + (ny * 0.003))
			sz = (hz + (nz * 0.003))
			id1 = rf_nearest(sx, sy, sz, rx, ry, rz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
			pr = (if (id1 < 0) { rf_sky(ry) } else { rf_local(sx, sy, sz, rx, ry, rz, id1, frame) })
			k = rf_refl(id0)
			cr = ((rf_un_r(p0) * (1.0 - k)) + (rf_un_r(pr) * k))
			cg = ((rf_un_g(p0) * (1.0 - k)) + (rf_un_g(pr) * k))
			cb = ((rf_un_b(p0) * (1.0 - k)) + (rf_un_b(pr) * k))
			rf_pack(cr, cg, cb)
		}) })
	})

	reflect_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	reflect_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, rf_render(gid, frame))
	})
}
