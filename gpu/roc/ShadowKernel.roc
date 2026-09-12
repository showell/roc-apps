# ShadowKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ShadowKernel :: [].{

	sd_width : I64
	sd_width = 1024

	sd_half_w : I64
	sd_half_w = 512

	sd_half_h : I64
	sd_half_h = 384

	sd_nobj : I64
	sd_nobj = 4

	sd_samples : I64
	sd_samples = 9

	sd_cx : I64 -> F64
	sd_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.7) } else { 1.6 }) })

	sd_cy : I64 -> F64
	sd_cy = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 0.35) } else { (0.0 - 0.45) }) })

	sd_cz : I64 -> F64
	sd_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.5 } else { (0.0 - 0.4) }) })

	sd_rad : I64 -> F64
	sd_rad = |i| (if (i == 0) { 1.0 } else { (if (i == 1) { 0.65 } else { 0.55 }) })

	sd_col_r : I64 -> F64
	sd_col_r = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.35 } else { 0.8 }) })

	sd_col_g : I64 -> F64
	sd_col_g = |i| (if (i == 0) { 0.55 } else { (if (i == 1) { 0.75 } else { 0.45 }) })

	sd_col_b : I64 -> F64
	sd_col_b = |i| (if (i == 0) { 0.35 } else { (if (i == 1) { 0.55 } else { 0.95 }) })

	sd_sphere_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	sd_sphere_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - sd_cx(i))
		ly = (oy - sd_cy(i))
		lz = (oz - sd_cz(i))
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r = sd_rad(i)
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	sd_plane_hit : F64, F64 -> F64
	sd_plane_hit = |oy, dy| (if (dy > (0.0 - 0.0001)) { (0.0 - 1.0) } else { ({
		t = (((0.0 - 1.0) - oy) / dy)
		(if (t > 0.001) { t } else { (0.0 - 1.0) })
	}) })

	sd_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	sd_hit = |ox, oy, oz, dx, dy, dz, id| (if (id == 3) { sd_plane_hit(oy, dy) } else { sd_sphere_hit(ox, oy, oz, dx, dy, dz, id) })

	sd_nearest : F64, F64, F64, F64, F64, F64, I64, I64, F64 -> I64
	sd_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= sd_nobj) { best_id } else { ({
		t = sd_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { sd_nearest(ox, oy, oz, dx, dy, dz, (i + 1), i, t) } else { sd_nearest(ox, oy, oz, dx, dy, dz, (i + 1), best_id, best_t) })
	}) })

	sd_occluded : F64, F64, F64, F64, F64, F64, I64 -> I64
	sd_occluded = |ox, oy, oz, dx, dy, dz, i| (if (i >= 3) { 0 } else { ({
		t = sd_sphere_hit(ox, oy, oz, dx, dy, dz, i)
		(if (t > 0.001) { 1 } else { sd_occluded(ox, oy, oz, dx, dy, dz, (i + 1)) })
	}) })

	sd_off_x : I64 -> F64
	sd_off_x = |i| (I64.to_f64(((i - (I64.div_trunc_by(i, 3) * 3)) - 1)) * 1.1)

	sd_off_z : I64 -> F64
	sd_off_z = |i| (I64.to_f64((I64.div_trunc_by(i, 3) - 1)) * 1.1)

	sd_soft : F64, F64, F64, F64, F64, I64, I64 -> I64
	sd_soft = |hx, hy, hz, lx, lz, i, acc| (if (i >= sd_samples) { acc } else { ({
		ddx = ((lx + sd_off_x(i)) - hx)
		ddy = (6.0 - hy)
		ddz = ((lz + sd_off_z(i)) - hz)
		dl = DeviceMath.real_sqrt((((ddx * ddx) + (ddy * ddy)) + (ddz * ddz)))
		ux = (ddx / dl)
		uy = (ddy / dl)
		uz = (ddz / dl)
		occ = sd_occluded((hx + (ux * 0.003)), (hy + (uy * 0.003)), (hz + (uz * 0.003)), ux, uy, uz, 0)
		vis = (if (occ == 1) { 0 } else { 1 })
		sd_soft(hx, hy, hz, lx, lz, (i + 1), (acc + vis))
	}) })

	sd_clamp01 : F64 -> F64
	sd_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	sd_pack : F64, F64, F64 -> I64
	sd_pack = |r, g, b| ({
		ri = F64.to_i64_wrap((sd_clamp01(r) * 255.0))
		gi = F64.to_i64_wrap((sd_clamp01(g) * 255.0))
		bi = F64.to_i64_wrap((sd_clamp01(b) * 255.0))
		(((ri * 65536) + (gi * 256)) + bi)
	})

	sd_sky : F64 -> I64
	sd_sky = |dy| ({
		h = sd_clamp01(((dy * 0.5) + 0.5))
		sd_pack((0.06 + (h * 0.07)), (0.1 + (h * 0.15)), (0.24 + (h * 0.4)))
	})

	sd_checker : F64, F64 -> F64
	sd_checker = |hx, hz| ({
		ix = F64.to_i64_wrap((hx + 64.0))
		iz = F64.to_i64_wrap((hz + 64.0))
		s = (ix + iz)
		(if ((s - (I64.div_trunc_by(s, 2) * 2)) == 0) { 0.38 } else { 0.66 })
	})

	sd_render : I64, I64 -> I64
	sd_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, sd_width) * sd_width))
		py = I64.div_trunc_by(gid, sd_width)
		fx = (I64.to_f64((px - sd_half_w)) / 384.0)
		fy = (I64.to_f64((sd_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.89))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.7 / rl)
		ox = 0.0
		oy = 0.7
		oz = (0.0 - 4.0)
		id = sd_nearest(ox, oy, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
		(if (id < 0) { sd_sky(dy) } else { ({
			t = sd_hit(ox, oy, oz, dx, dy, dz, id)
			hx = (ox + (dx * t))
			hy = (oy + (dy * t))
			hz = (oz + (dz * t))
			nx = (if (id == 3) { 0.0 } else { ((hx - sd_cx(id)) / sd_rad(id)) })
			ny = (if (id == 3) { 1.0 } else { ((hy - sd_cy(id)) / sd_rad(id)) })
			nz = (if (id == 3) { 0.0 } else { ((hz - sd_cz(id)) / sd_rad(id)) })
			br = (if (id == 3) { sd_checker(hx, hz) } else { sd_col_r(id) })
			bg = (if (id == 3) { sd_checker(hx, hz) } else { sd_col_g(id) })
			bb = (if (id == 3) { sd_checker(hx, hz) } else { sd_col_b(id) })
			ang = (I64.to_f64(frame) / 30.0)
			lx = (DeviceMath.real_cos(ang) * 3.0)
			lz = (DeviceMath.real_sin(ang) * 3.0)
			lcx = (lx - hx)
			lcy = (6.0 - hy)
			lcz = (lz - hz)
			lcl = DeviceMath.real_sqrt((((lcx * lcx) + (lcy * lcy)) + (lcz * lcz)))
			ndl = DeviceMath.real_max(0.0, ((((nx * lcx) / lcl) + ((ny * lcy) / lcl)) + ((nz * lcz) / lcl)))
			vis = (I64.to_f64(sd_soft(hx, hy, hz, lx, lz, 0, 0)) / 9.0)
			lit = (0.18 + ((ndl * 0.92) * vis))
			sd_pack((br * lit), (bg * lit), (bb * lit))
		}) })
	})

	shadow_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	shadow_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, sd_render(gid, frame))
	})
}
