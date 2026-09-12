# ShadowKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ShadowKernel :: [].{

	sd_width : I32
	sd_width = 1024

	sd_half_w : I32
	sd_half_w = 512

	sd_half_h : I32
	sd_half_h = 384

	sd_nobj : I32
	sd_nobj = 4

	sd_samples : I32
	sd_samples = 9

	sd_cx : I32 -> F32
	sd_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.7) } else { 1.6 }) })

	sd_cy : I32 -> F32
	sd_cy = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 0.35) } else { (0.0 - 0.45) }) })

	sd_cz : I32 -> F32
	sd_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.5 } else { (0.0 - 0.4) }) })

	sd_rad : I32 -> F32
	sd_rad = |i| (if (i == 0) { 1.0 } else { (if (i == 1) { 0.65 } else { 0.55 }) })

	sd_col_r : I32 -> F32
	sd_col_r = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.35 } else { 0.8 }) })

	sd_col_g : I32 -> F32
	sd_col_g = |i| (if (i == 0) { 0.55 } else { (if (i == 1) { 0.75 } else { 0.45 }) })

	sd_col_b : I32 -> F32
	sd_col_b = |i| (if (i == 0) { 0.35 } else { (if (i == 1) { 0.55 } else { 0.95 }) })

	sd_sphere_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
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

	sd_plane_hit : F32, F32 -> F32
	sd_plane_hit = |oy, dy| (if (dy > (0.0 - 0.0001)) { (0.0 - 1.0) } else { ({
		t = (((0.0 - 1.0) - oy) / dy)
		(if (t > 0.001) { t } else { (0.0 - 1.0) })
	}) })

	sd_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	sd_hit = |ox, oy, oz, dx, dy, dz, id| (if (id == 3) { sd_plane_hit(oy, dy) } else { sd_sphere_hit(ox, oy, oz, dx, dy, dz, id) })

	sd_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	sd_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= sd_nobj) { best_id } else { ({
		t = sd_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { sd_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { sd_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), best_id, best_t) })
	}) })

	sd_occluded : F32, F32, F32, F32, F32, F32, I32 -> I32
	sd_occluded = |ox, oy, oz, dx, dy, dz, i| (if (i >= 3) { 0 } else { ({
		t = sd_sphere_hit(ox, oy, oz, dx, dy, dz, i)
		(if (t > 0.001) { 1 } else { sd_occluded(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1)) })
	}) })

	sd_off_x : I32 -> F32
	sd_off_x = |i| (I32.to_f32(I32.minus_wrap(I32.minus_wrap(i, I32.times_wrap(Device.div(i, 3), 3)), 1)) * 1.1)

	sd_off_z : I32 -> F32
	sd_off_z = |i| (I32.to_f32(I32.minus_wrap(Device.div(i, 3), 1)) * 1.1)

	sd_soft : F32, F32, F32, F32, F32, I32, I32 -> I32
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
		sd_soft(hx, hy, hz, lx, lz, I32.plus_wrap(i, 1), I32.plus_wrap(acc, vis))
	}) })

	sd_clamp01 : F32 -> F32
	sd_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	sd_pack : F32, F32, F32 -> I32
	sd_pack = |r, g, b| ({
		ri = F32.to_i32_wrap((sd_clamp01(r) * 255.0))
		gi = F32.to_i32_wrap((sd_clamp01(g) * 255.0))
		bi = F32.to_i32_wrap((sd_clamp01(b) * 255.0))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	sd_sky : F32 -> I32
	sd_sky = |dy| ({
		h = sd_clamp01(((dy * 0.5) + 0.5))
		sd_pack((0.06 + (h * 0.07)), (0.1 + (h * 0.15)), (0.24 + (h * 0.4)))
	})

	sd_checker : F32, F32 -> F32
	sd_checker = |hx, hz| ({
		ix = F32.to_i32_wrap((hx + 64.0))
		iz = F32.to_i32_wrap((hz + 64.0))
		s = I32.plus_wrap(ix, iz)
		(if (I32.minus_wrap(s, I32.times_wrap(Device.div(s, 2), 2)) == 0) { 0.38 } else { 0.66 })
	})

	sd_render : I32, I32 -> I32
	sd_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, sd_width), sd_width))
		py = Device.div(gid, sd_width)
		fx = (I32.to_f32(I32.minus_wrap(px, sd_half_w)) / 384.0)
		fy = (I32.to_f32(I32.minus_wrap(sd_half_h, py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.89))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.7 / rl)
		ox = 0.0
		oy = 0.7
		oz = (0.0 - 4.0)
		id = sd_nearest(ox, oy, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
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
			ang = (I32.to_f32(frame) / 30.0)
			lx = (DeviceMath.real_cos(ang) * 3.0)
			lz = (DeviceMath.real_sin(ang) * 3.0)
			lcx = (lx - hx)
			lcy = (6.0 - hy)
			lcz = (lz - hz)
			lcl = DeviceMath.real_sqrt((((lcx * lcx) + (lcy * lcy)) + (lcz * lcz)))
			ndl = DeviceMath.real_max(0.0, ((((nx * lcx) / lcl) + ((ny * lcy) / lcl)) + ((nz * lcz) / lcl)))
			vis = (I32.to_f32(sd_soft(hx, hy, hz, lx, lz, 0, 0)) / 9.0)
			lit = (0.18 + ((ndl * 0.92) * vis))
			sd_pack((br * lit), (bg * lit), (bb * lit))
		}) })
	})

	shadow_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	shadow_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, sd_render(gid, frame))
	})
}
