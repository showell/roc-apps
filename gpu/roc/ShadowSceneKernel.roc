# ShadowSceneKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ShadowSceneKernel :: [].{

	sc_width : I32
	sc_width = 1024

	sc_half_w : I32
	sc_half_w = 512

	sc_half_h : I32
	sc_half_h = 384

	sc_count : I32
	sc_count = 3

	sc_far : I32
	sc_far = 8000000

	sc_size : F32
	sc_size = 7.0

	sc_dist : F32
	sc_dist = 7.0

	sc_cx : I32 -> F32
	sc_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.5) } else { 1.4 }) })

	sc_cy : I32 -> F32
	sc_cy = |i| (if (i == 0) { 1.05 } else { (if (i == 1) { 0.6 } else { 0.75 }) })

	sc_cz : I32 -> F32
	sc_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.6 } else { (0.0 - 0.5) }) })

	sc_rad : I32 -> F32
	sc_rad = |i| (if (i == 0) { 0.85 } else { (if (i == 1) { 0.6 } else { 0.65 }) })

	sc_colr : I32 -> F32
	sc_colr = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.35 } else { 0.75 }) })

	sc_colg : I32 -> F32
	sc_colg = |i| (if (i == 0) { 0.55 } else { (if (i == 1) { 0.75 } else { 0.4 }) })

	sc_colb : I32 -> F32
	sc_colb = |i| (if (i == 0) { 0.3 } else { (if (i == 1) { 0.55 } else { 0.95 }) })

	sc_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	sc_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - sc_cx(i))
		ly = (oy - sc_cy(i))
		lz = (oz - sc_cz(i))
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r = sc_rad(i)
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	sc_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	sc_nearest = |ox, oy, oz, dx, dy, dz, i, bid, bt| (if (i >= sc_count) { bid } else { ({
		t = sc_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (bt < 0.0) { 1 } else { (if (t < bt) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { sc_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { sc_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), bid, bt) })
	}) })

	sc_clampi : I32, I32, I32 -> I32
	sc_clampi = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	sc_pack : F32, F32, F32 -> I32
	sc_pack = |r, g, b| ({
		ri = sc_clampi(F32.to_i32_wrap((r * 255.0)), 0, 255)
		gi = sc_clampi(F32.to_i32_wrap((g * 255.0)), 0, 255)
		bi = sc_clampi(F32.to_i32_wrap((b * 255.0)), 0, 255)
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	sc_checker : F32, F32 -> F32
	sc_checker = |x, z| ({
		ix = F32.to_i32_wrap((x + 64.0))
		iz = F32.to_i32_wrap((z + 64.0))
		s = I32.plus_wrap(ix, iz)
		(if (I32.minus_wrap(s, I32.times_wrap(Device.div(s, 2), 2)) == 0) { 0.3 } else { 0.55 })
	})

	shadowmain_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	shadowmain_step = |dev, shadowbuf, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, sc_width), sc_width))
		py = Device.div(gid, sc_width)
		fx = (I32.to_f32(I32.minus_wrap(px, sc_half_w)) / 384.0)
		fy = ((I32.to_f32(I32.minus_wrap(sc_half_h, py)) / 384.0) - 0.12)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.6 / rl)
		ox = 0.0
		oy = 1.7
		oz = (0.0 - 6.0)
		sid = sc_nearest(ox, oy, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		st = (if (sid < 0) { 1000.0 } else { sc_hit(ox, oy, oz, dx, dy, dz, sid) })
		ft = (if (dy < (0.0 - 0.0001)) { (((0.0 - 1.0) - oy) / dy) } else { (0.0 - 1.0) })
		usefloor = (if (ft > 0.001) { (if (sid < 0) { 1 } else { (if (ft < st) { 1 } else { 0 }) }) } else { 0 })
		hitany = (if (usefloor == 1) { 1 } else { (if (sid >= 0) { 1 } else { 0 }) })
		(if (hitany == 0) { (dev, I32.plus_wrap(I32.plus_wrap(I32.times_wrap(6, 65536), I32.times_wrap(10, 256)), 20)) } else { ({
			t = (if (usefloor == 1) { ft } else { st })
			hx = (ox + (dx * t))
			hy = (oy + (dy * t))
			hz = (oz + (dz * t))
			nx = (if (usefloor == 1) { 0.0 } else { ((hx - sc_cx(sid)) / sc_rad(sid)) })
			ny = (if (usefloor == 1) { 1.0 } else { ((hy - sc_cy(sid)) / sc_rad(sid)) })
			nz = (if (usefloor == 1) { 0.0 } else { ((hz - sc_cz(sid)) / sc_rad(sid)) })
			ar = (if (usefloor == 1) { sc_checker(hx, hz) } else { sc_colr(sid) })
			ag = (if (usefloor == 1) { sc_checker(hx, hz) } else { sc_colg(sid) })
			ab = (if (usefloor == 1) { sc_checker(hx, hz) } else { sc_colb(sid) })
			la = (I32.to_f32(frame) / 40.0)
			rlx = (DeviceMath.real_cos(la) * 0.62)
			rlz = (DeviceMath.real_sin(la) * 0.62)
			ll = DeviceMath.real_sqrt((((rlx * rlx) + 0.6084) + (rlz * rlz)))
			lx = (rlx / ll)
			ly = ((0.0 - 0.78) / ll)
			lz = (rlz / ll)
			rgl = DeviceMath.real_sqrt(((lz * lz) + (lx * lx)))
			rx = (lz / rgl)
			rz = (0.0 - (lx / rgl))
			ux = (ly * rz)
			uy = ((lz * rx) - (lx * rz))
			uz = (0.0 - (ly * rx))
			rcx = (hx - 0.0)
			rcy = (hy - 0.35)
			rcz = (hz - 0.0)
			lu = ((((rcx * rx) + (rcz * rz)) / sc_size) + 0.5)
			lv = (((((rcx * ux) + (rcy * uy)) + (rcz * uz)) / sc_size) + 0.5)
			ld = ((((rcx * lx) + (rcy * ly)) + (rcz * lz)) + sc_dist)
			({
				(dev1, stored) = Device.load(dev, shadowbuf, I32.plus_wrap(I32.times_wrap(sc_clampi(F32.to_i32_wrap((lv * 1024.0)), 0, 1023), 1024), sc_clampi(F32.to_i32_wrap((lu * 1024.0)), 0, 1023)))
				({
					inmap = (if (lu > 0.0) { (if (lu < 1.0) { (if (lv > 0.0) { (if (lv < 1.0) { 1 } else { 0 }) } else { 0 }) } else { 0 }) } else { 0 })
					shadowed = (if (inmap == 1) { (if (stored < sc_far) { (if (F32.to_i32_wrap((ld * 256.0)) > I32.plus_wrap(stored, 500)) { 1 } else { 0 }) } else { 0 }) } else { 0 })
					ndl = DeviceMath.real_max(0.0, (0.0 - (((nx * lx) + (ny * ly)) + (nz * lz))))
					vis = (if (shadowed == 1) { 0.18 } else { 1.0 })
					sh = (0.2 + ((ndl * 0.85) * vis))
					Device.store(dev1, outb, gid, sc_pack((ar * sh), (ag * sh), (ab * sh)))
				})
			})
		}) })
	})
}
